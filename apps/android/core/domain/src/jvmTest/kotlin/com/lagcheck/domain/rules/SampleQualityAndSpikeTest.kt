package com.lagcheck.domain.rules

import com.google.common.truth.Truth.assertThat
import com.lagcheck.domain.model.InconclusiveReason
import com.lagcheck.domain.model.ProbeOutcome
import com.lagcheck.domain.model.ProbeSample
import com.lagcheck.domain.model.SpikePattern
import org.junit.Test

/** Portado de SampleQualityEvaluatorTests.swift e SpikePatternEvaluatorTests.swift. */
class SampleQualityAndSpikeTest {
    private fun ok(seq: Int, rtt: Double) = ProbeSample(seq, rtt, ProbeOutcome.RECEIVED)
    private fun lost(seq: Int) = ProbeSample(seq, null, ProbeOutcome.TIMEOUT)

    @Test fun emptyIsNormal() {
        val a = SampleQualityEvaluator.assess(emptyList())
        assertThat(a.shouldAbort).isFalse()
        assertThat(a.consecutiveTimeouts).isEqualTo(0)
    }

    @Test fun healthyIsNormal() {
        val a = SampleQualityEvaluator.assess((1..15).map { ok(it, 25.0) })
        assertThat(a.shouldAbort).isFalse()
        assertThat(a.earlyLossPercentage).isEqualTo(0.0)
    }

    @Test fun fourConsecutiveTimeoutsInFirstSixAbort() {
        val a = SampleQualityEvaluator.assess(listOf(ok(1, 25.0), lost(2), lost(3), lost(4), lost(5)))
        assertThat(a.shouldAbort).isTrue()
        assertThat(a.abortReason).isEqualTo(InconclusiveReason.POOR_SAMPLE_QUALITY)
        assertThat(a.consecutiveTimeouts).isEqualTo(4)
    }

    @Test fun severeInitialLossAborts() {
        val a = SampleQualityEvaluator.assess(
            listOf(ok(1, 20.0), lost(2), lost(3), ok(4, 25.0), lost(5), lost(6), lost(7), lost(8), lost(9))
        )
        assertThat(a.shouldAbort).isTrue()
        assertThat(a.earlyLossPercentage).isAtLeast(70.0)
    }

    @Test fun suddenDisconnectWithSixTimeoutsAborts() {
        val samples = (1..12).map { ok(it, 22.0) } + (13..18).map { lost(it) }
        val a = SampleQualityEvaluator.assess(samples)
        assertThat(a.shouldAbort).isTrue()
        assertThat(a.consecutiveTimeouts).isEqualTo(6)
    }

    private fun base() = (0 until 30).map { ok(it, 25.0) }.toMutableList()

    @Test fun noSpikes() {
        assertThat(SpikePatternEvaluator.evaluate(base(), 25.0)).isEqualTo(SpikePattern.None)
    }

    @Test fun singleSpikeIsIsolated() {
        val s = base().also { it[10] = ok(10, 85.0) }
        assertThat(SpikePatternEvaluator.evaluate(s, 25.0)).isEqualTo(SpikePattern.Isolated(1, 0))
    }

    @Test fun twoDispersedSpikesAreIsolated() {
        val s = base().also { it[2] = ok(2, 85.0); it[20] = ok(20, 85.0) }
        assertThat(SpikePatternEvaluator.evaluate(s, 25.0)).isEqualTo(SpikePattern.Isolated(2, 0))
    }

    @Test fun twoSpikesInCloseWindowAreRecurring() {
        val s = base().also { it[10] = ok(10, 85.0); it[13] = ok(13, 90.0) }
        val p = SpikePatternEvaluator.evaluate(s, 25.0)
        assertThat(p).isEqualTo(SpikePattern.Recurring(2, 0))
        assertThat(p.isRecurring).isTrue()
    }

    @Test fun threeSpikesAreRecurringRegardlessOfSpacing() {
        val s = base().also { it[1] = ok(1, 85.0); it[15] = ok(15, 85.0); it[28] = ok(28, 85.0) }
        assertThat(SpikePatternEvaluator.evaluate(s, 25.0)).isEqualTo(SpikePattern.Recurring(3, 0))
    }

    @Test fun severeSpikesAreCounted() {
        val s = base().also { it[5] = ok(5, 160.0); it[7] = ok(7, 170.0) }
        val p = SpikePatternEvaluator.evaluate(s, 25.0)
        assertThat(p).isEqualTo(SpikePattern.Recurring(2, 2))
        assertThat(p.severeSpikes).isEqualTo(2)
    }
}
