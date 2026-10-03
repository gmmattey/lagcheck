package com.lagcheck.domain.rules

import com.google.common.truth.Truth.assertThat
import com.lagcheck.domain.model.InconclusiveReason
import com.lagcheck.domain.model.MeasurementEvaluation
import com.lagcheck.domain.model.ProbeAcceptancePolicy
import com.lagcheck.domain.model.ProbeOutcome
import com.lagcheck.domain.model.ProbeSample
import com.lagcheck.domain.model.QualityProfileId
import com.lagcheck.domain.model.ResultClass
import com.lagcheck.domain.model.ScoreGuardrail
import org.junit.Test

/** Vetores portados de QualityEvaluatorPilotTests.swift e QualityEvaluatorExpandedProfileTests.swift. */
class QualityEvaluatorTest {
    private val tol = 1e-6

    @Test fun br001_stable() {
        val r = completed(received(30, 30.0))
        assertThat(r.metrics.p50Milliseconds).isEqualTo(30.0)
        assertThat(r.metrics.p95Milliseconds).isEqualTo(30.0)
        assertThat(r.metrics.p99Milliseconds).isEqualTo(30.0)
        assertThat(r.metrics.jitterMilliseconds).isEqualTo(0.0)
        assertThat(r.metrics.packetLossPercentage).isEqualTo(0.0)
        assertThat(r.metrics.spikeCount).isEqualTo(0)
        assertThat(r.metrics.components?.consistency).isEqualTo(100.0)
        assertThat(r.rawScore).isEqualTo(100)
        assertThat(r.finalScore).isEqualTo(100)
        assertThat(r.resultClass).isEqualTo(ResultClass.EXCELLENT)
    }

    @Test fun br002_lossGuardrail() {
        val r = completed(received(20, 30.0) + timeouts(10, 20))
        assertThat(r.metrics.packetLossPercentage).isWithin(tol).of(33.333333333333336)
        assertThat(r.metrics.components?.consistency).isEqualTo(90.0)
        assertThat(r.rawScore).isEqualTo(69)
        assertThat(r.finalScore).isEqualTo(59)
        assertThat(r.resultClass).isEqualTo(ResultClass.LAG_RISK)
        assertThat(r.appliedGuardrails).containsExactly(ScoreGuardrail.EXCESSIVE_LOSS_OR_LATENCY)
    }

    @Test fun br003_severeSpikes() {
        val r = completed(
            received(28, 30.0) + listOf(
                ProbeSample(28, 160.0, ProbeOutcome.RECEIVED),
                ProbeSample(29, 160.0, ProbeOutcome.RECEIVED)
            )
        )
        assertThat(r.metrics.p50Milliseconds).isEqualTo(30.0)
        assertThat(r.metrics.p95Milliseconds!!).isWithin(tol).of(101.5)
        assertThat(r.metrics.p99Milliseconds).isEqualTo(160.0)
        assertThat(r.metrics.jitterMilliseconds!!).isWithin(tol).of(4.482758620689655)
        assertThat(r.metrics.severeSpikeCount).isEqualTo(2)
        assertThat(r.metrics.spikeRatePercentage).isWithin(tol).of(6.666666666666667)
        assertThat(r.metrics.components!!.spikes).isWithin(tol).of(69.52380952380952)
        assertThat(r.metrics.components!!.consistency).isWithin(tol).of(63.904761904761905)
        assertThat(r.rawScore).isEqualTo(95)
        assertThat(r.finalScore).isEqualTo(74)
        assertThat(r.resultClass).isEqualTo(ResultClass.UNSTABLE)
        assertThat(r.appliedGuardrails).containsExactly(ScoreGuardrail.SEVERE_SPIKES)
    }

    @Test fun br004_insufficientResponsesIsInconclusive() {
        val e = QualityEvaluator.evaluate(received(9, 30.0) + timeouts(21, 9), QualityProfileId.BATTLE_ROYALE_COMPETITIVE)
        e as MeasurementEvaluation.Inconclusive
        assertThat(e.reason).isEqualTo(InconclusiveReason.INSUFFICIENT_UDP_RESPONSES)
        assertThat(e.diagnostics.validResponseCount).isEqualTo(9)
        assertThat(e.diagnostics.packetLossPercentage).isEqualTo(70.0)
        assertThat(e.diagnostics.components).isNull()
    }

    @Test fun br005_responseBeforeDeadlineIsReceived() {
        assertThat(ProbeAcceptancePolicy.outcome(14.5, 16.499)).isEqualTo(ProbeOutcome.RECEIVED)
    }

    @Test fun br006_responseAfterTimeoutIsTimeout() {
        assertThat(ProbeAcceptancePolicy.outcome(14.5, 16.501)).isEqualTo(ProbeOutcome.TIMEOUT)
    }

    @Test fun br007_invalidResponseNeverBecomesRttOrSuccess() {
        val r = completed(received(29, 30.0) + ProbeSample(29, null, ProbeOutcome.INVALID_RESPONSE))
        assertThat(r.metrics.validResponseCount).isEqualTo(29)
        assertThat(r.metrics.invalidResponseCount).isEqualTo(1)
        assertThat(r.metrics.p50Milliseconds).isEqualTo(30.0)
        assertThat(r.metrics.jitterMilliseconds).isEqualTo(0.0)
    }

    @Test fun br008_latencyInterpolationIsReproducible() {
        val r = completed(received(30, 50.0))
        assertThat(r.metrics.components?.latency).isEqualTo(90.0)
        assertThat(r.rawScore).isEqualTo(97)
        assertThat(r.finalScore).isEqualTo(97)
        assertThat(r.resultClass).isEqualTo(ResultClass.EXCELLENT)
    }

    @Test fun br009_oneTimeoutAppliesLossGuardrail() {
        val r = completed(received(29, 30.0) + timeouts(1, 29))
        assertThat(r.metrics.validResponseCount).isEqualTo(29)
        assertThat(r.metrics.packetLossPercentage).isWithin(tol).of(3.3333333333333335)
        assertThat(r.rawScore).isEqualTo(84)
        assertThat(r.finalScore).isEqualTo(59)
        assertThat(r.appliedGuardrails).containsExactly(ScoreGuardrail.EXCESSIVE_LOSS_OR_LATENCY)
    }

    @Test fun br010_p50AtHundredDoesNotApplyLatencyGuardrail() {
        val r = completed(received(30, 100.0))
        assertThat(r.rawScore).isEqualTo(65)
        assertThat(r.finalScore).isEqualTo(65)
        assertThat(r.appliedGuardrails).isEmpty()
    }

    @Test fun br011_p50AboveHundredAppliesLatencyGuardrail() {
        val r = completed(received(30, 101.0))
        assertThat(r.rawScore).isEqualTo(65)
        assertThat(r.finalScore).isEqualTo(59)
        assertThat(r.appliedGuardrails).containsExactly(ScoreGuardrail.EXCESSIVE_LOSS_OR_LATENCY)
    }

    @Test fun br012_jitterUsesConsecutiveRttsInSequence() {
        val samples = listOf(
            ProbeSample(0, 30.0, ProbeOutcome.RECEIVED),
            ProbeSample(1, 60.0, ProbeOutcome.RECEIVED)
        ) + received(28, 30.0, startingAt = 2)
        assertThat(completed(samples).metrics.jitterMilliseconds!!).isWithin(tol).of(60.0 / 29.0)
    }

    @Test fun mr001_mobileStable() {
        val r = completed(received(30, 50.0), QualityProfileId.MOBILE_REALTIME)
        assertThat(r.finalScore).isEqualTo(100)
        assertThat(r.resultClass).isEqualTo(ResultClass.EXCELLENT)
    }

    @Test fun mr002_mobileLossAboveFivePercent() {
        val r = completed(received(28, 50.0) + timeouts(2, 28), QualityProfileId.MOBILE_REALTIME)
        assertThat(r.metrics.packetLossPercentage).isWithin(tol).of(6.666666666666667)
        assertThat(r.finalScore).isEqualTo(59)
        assertThat(r.appliedGuardrails).containsExactly(ScoreGuardrail.EXCESSIVE_LOSS_OR_LATENCY)
    }

    @Test fun cr001_casualStable() {
        val r = completed(received(30, 70.0), QualityProfileId.CASUAL_REALTIME)
        assertThat(r.finalScore).isEqualTo(100)
        assertThat(r.resultClass).isEqualTo(ResultClass.EXCELLENT)
    }

    @Test fun cr002_casualLatencyAbove180() {
        val r = completed(received(30, 181.0), QualityProfileId.CASUAL_REALTIME)
        assertThat(r.finalScore).isEqualTo(59)
        assertThat(r.appliedGuardrails).containsExactly(ScoreGuardrail.EXCESSIVE_LOSS_OR_LATENCY)
    }

    @Test fun ruleVersionsAreStable() {
        assertThat(QualityEvaluator.ruleVersion(QualityProfileId.BATTLE_ROYALE_COMPETITIVE)).isEqualTo("pilot-2026.09.08.1")
        assertThat(QualityEvaluator.ruleVersion(QualityProfileId.MOBILE_REALTIME)).isEqualTo("mobile-realtime-2026.09.08.1")
        assertThat(QualityEvaluator.ruleVersion(QualityProfileId.CASUAL_REALTIME)).isEqualTo("casual-realtime-2026.09.08.1")
    }
}
