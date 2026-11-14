package com.lagcheck.domain.rules

import com.google.common.truth.Truth.assertThat
import com.lagcheck.domain.model.ProbeOutcome
import com.lagcheck.domain.model.ProbeSample
import com.lagcheck.domain.model.QualityProfileId
import com.lagcheck.domain.model.ResultClass
import org.junit.Test

/** Portado de ResultInterpreterTests.swift. A causa usa os guardrails do perfil ativo. */
class ResultInterpreterTest {
    private val br = QualityProfileId.BATTLE_ROYALE_COMPETITIVE
    private fun interpret(samples: List<ProbeSample>, p: QualityProfileId = br) =
        ResultInterpreter.interpret(completed(samples, p), p)

    @Test fun healthyIsReadyAndStable() {
        val i = interpret(received(30, 30.0))
        assertThat(i.conclusion).isEqualTo(ResultConclusion.READY_TO_PLAY)
        assertThat(i.primaryCause).isEqualTo(PrimaryCause.STABLE_CONNECTION)
        assertThat(i.score).isEqualTo(100)
        assertThat(i.scoreBand).isEqualTo(ResultClass.EXCELLENT)
    }

    @Test fun lossHasPriority() {
        val i = interpret(received(20, 30.0) + timeouts(10, 20))
        assertThat(i.conclusion).isEqualTo(ResultConclusion.INVESTIGATE_BEFORE_PLAYING)
        assertThat(i.primaryCause).isEqualTo(PrimaryCause.PACKET_LOSS)
    }

    @Test fun p50AboveGuardrailIsPrimary() {
        val i = interpret(received(30, 101.0))
        assertThat(i.conclusion).isEqualTo(ResultConclusion.INVESTIGATE_BEFORE_PLAYING)
        assertThat(i.primaryCause).isEqualTo(PrimaryCause.HIGH_LATENCY)
    }

    @Test fun severeSpikesArePrimary() {
        val i = interpret(received(28, 30.0) + listOf(ProbeSample(28, 160.0, ProbeOutcome.RECEIVED), ProbeSample(29, 160.0, ProbeOutcome.RECEIVED)))
        assertThat(i.conclusion).isEqualTo(ResultConclusion.LAG_MAY_OCCUR)
        assertThat(i.primaryCause).isEqualTo(PrimaryCause.SEVERE_SPIKES)
    }

    @Test fun jitterAboveRiskBandIsPrimary() {
        val s = (0 until 30).map { ProbeSample(it, if (it % 2 == 0) 30.0 else 90.0, ProbeOutcome.RECEIVED) }
        val i = interpret(s)
        assertThat(i.conclusion).isEqualTo(ResultConclusion.LAG_MAY_OCCUR)
        assertThat(i.primaryCause).isEqualTo(PrimaryCause.HIGH_JITTER)
    }

    @Test fun mobileUsesItsOwnLatencyGuardrail() {
        assertThat(interpret(received(30, 110.0), QualityProfileId.MOBILE_REALTIME).primaryCause).isEqualTo(PrimaryCause.STABLE_CONNECTION)
        assertThat(interpret(received(30, 131.0), QualityProfileId.MOBILE_REALTIME).primaryCause).isEqualTo(PrimaryCause.HIGH_LATENCY)
    }

    @Test fun mobileUsesItsOwnLossGuardrail() {
        val i = interpret(received(29, 30.0) + timeouts(1, 29), QualityProfileId.MOBILE_REALTIME)
        assertThat(i.primaryCause).isEqualTo(PrimaryCause.STABLE_CONNECTION)
    }

    @Test fun casualRequiresThreeSevereSpikes() {
        val i = interpret(
            received(28, 30.0) + listOf(ProbeSample(28, 310.0, ProbeOutcome.RECEIVED), ProbeSample(29, 310.0, ProbeOutcome.RECEIVED)),
            QualityProfileId.CASUAL_REALTIME
        )
        assertThat(i.primaryCause).isEqualTo(PrimaryCause.STABLE_CONNECTION)
    }
}
