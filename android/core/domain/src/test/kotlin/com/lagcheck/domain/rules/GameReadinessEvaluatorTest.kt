package com.lagcheck.domain.rules

import com.google.common.truth.Truth.assertThat
import com.lagcheck.domain.model.GameReadinessAssessment
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.GatewayProbeOutcome
import com.lagcheck.domain.model.MeasurementConfidence
import com.lagcheck.domain.model.MeasurementEvaluation
import com.lagcheck.domain.model.NetworkFinding
import com.lagcheck.domain.model.ProbeOutcome
import com.lagcheck.domain.model.ProbeSample
import com.lagcheck.domain.model.QualityProfileId
import com.lagcheck.domain.model.SpikePattern
import org.junit.Test

/** Portado de GameReadinessDomainTests.swift (readiness-v2.0). */
class GameReadinessEvaluatorTest {
    private val br = QualityProfileId.BATTLE_ROYALE_COMPETITIVE
    private fun samples(n: Int, rtt: Double) = received(n, rtt)

    private fun evalSamples(s: List<ProbeSample>, profile: QualityProfileId = br, loadDelta: Double? = null): GameReadinessAssessment {
        val q = (QualityEvaluator.evaluate(s, profile) as? MeasurementEvaluation.Completed)?.result
            ?: return GameReadinessEvaluator.evaluate(null, null, profile)
        val impact = loadDelta?.let { d -> q.metrics.p50Milliseconds?.let { DeepCheckLoadImpact.fromP50(it, it + d) } }
        return GameReadinessEvaluator.evaluate(q, impact, profile)
    }

    private fun GameReadinessAssessment.finding(kind: NetworkFinding.Kind) = findings.firstOrNull { it.kind == kind }

    @Test fun healthyIsReady() {
        val e = evalSamples(samples(30, 25.0), loadDelta = 5.0)
        assertThat(e.verdict).isEqualTo(GameReadinessVerdict.READY)
        assertThat(e.verdict.isReady).isTrue()
        assertThat(e.headlineKey).isEqualTo("game_readiness.verdict.ready.headline")
        assertThat(e.stabilityRatio).isAtLeast(0.85)
        assertThat(e.packetLossPercentage).isEqualTo(0.0)
        assertThat(e.isUnderLoadAffected).isFalse()
        assertThat(e.finding(NetworkFinding.Kind.PACKET_LOSS)?.severity).isEqualTo(NetworkFinding.Severity.POSITIVE)
        assertThat(e.finding(NetworkFinding.Kind.STABLE_ROUTE)?.severity).isEqualTo(NetworkFinding.Severity.POSITIVE)
    }

    @Test fun packetLossIsNotReady() {
        val e = evalSamples(samples(25, 25.0) + timeouts(5, 25))
        assertThat(e.verdict).isEqualTo(GameReadinessVerdict.NOT_READY)
        assertThat(e.headlineKey).isEqualTo("game_readiness.verdict.not_ready.headline")
        assertThat(e.subtitleKey).isEqualTo("game_readiness.verdict.not_ready.packet_loss")
        assertThat(e.stabilityRatio).isAtMost(0.45)
        assertThat(e.finding(NetworkFinding.Kind.PACKET_LOSS)?.severity).isEqualTo(NetworkFinding.Severity.NEGATIVE)
    }

    @Test fun highLatencyIsNotReady() {
        val e = evalSamples(samples(30, 140.0))
        assertThat(e.verdict).isEqualTo(GameReadinessVerdict.NOT_READY)
        assertThat(e.subtitleKey).isEqualTo("game_readiness.verdict.not_ready.high_latency")
        assertThat(e.finding(NetworkFinding.Kind.HIGH_LATENCY)?.severity).isEqualTo(NetworkFinding.Severity.NEGATIVE)
    }

    @Test fun severeSpikesAreNotReady() {
        val e = evalSamples(samples(28, 25.0) + listOf(ProbeSample(28, 180.0, ProbeOutcome.RECEIVED), ProbeSample(29, 180.0, ProbeOutcome.RECEIVED)))
        assertThat(e.verdict).isEqualTo(GameReadinessVerdict.NOT_READY)
        assertThat(e.subtitleKey).isEqualTo("game_readiness.verdict.not_ready.severe_spikes")
        assertThat(e.finding(NetworkFinding.Kind.LATENCY_SPIKES)?.severity).isEqualTo(NetworkFinding.Severity.NEGATIVE)
    }

    @Test fun materialLoadIsCaution() {
        val e = evalSamples(samples(30, 25.0), loadDelta = 35.0)
        assertThat(e.verdict).isEqualTo(GameReadinessVerdict.CAUTION)
        assertThat(e.isUnderLoadAffected).isTrue()
        assertThat(e.subtitleKey).isEqualTo("game_readiness.verdict.caution.load")
        assertThat(e.finding(NetworkFinding.Kind.LOAD_DEGRADATION)?.severity).isEqualTo(NetworkFinding.Severity.WARNING)
    }

    @Test fun moderateJitterIsCautionOrWorse() {
        val s = (0 until 30).map { ProbeSample(it, if (it % 2 == 0) 20.0 else 50.0, ProbeOutcome.RECEIVED) }
        assertThat(evalSamples(s).verdict).isAnyOf(GameReadinessVerdict.CAUTION, GameReadinessVerdict.NOT_READY)
    }

    @Test fun insufficientSamplesAreInconclusiveAndNeverFabricate() {
        assertThat(QualityEvaluator.evaluate(samples(8, 25.0), br)).isInstanceOf(MeasurementEvaluation.Inconclusive::class.java)
        val r = GameReadinessEvaluator.evaluate(null, null, br)
        assertThat(r.verdict).isEqualTo(GameReadinessVerdict.INCONCLUSIVE)
        assertThat(r.stabilityRatio).isEqualTo(0.0)
        assertThat(r.packetLossPercentage).isNull()
        assertThat(r.pingMs).isNull()
        assertThat(r.jitterMs).isNull()
        assertThat(r.score).isNull()
    }

    @Test fun pipelineWithoutEnoughUdpIsInconclusive() {
        val r = GameReadinessEvaluator.evaluate(samples(9, 20.0) + timeouts(21, 9), received(30, 30.0), br)
        assertThat(r.verdict).isEqualTo(GameReadinessVerdict.INCONCLUSIVE)
    }

    @Test fun highLatency120IsNotReadyWithFinding() {
        val e = evalSamples(samples(30, 120.0))
        assertThat(e.verdict).isEqualTo(GameReadinessVerdict.NOT_READY)
        assertThat(e.finding(NetworkFinding.Kind.HIGH_LATENCY)).isNotNull()
    }

    @Test fun allProfilesReadyWhenHealthy() {
        for (p in QualityProfileId.entries) assertThat(evalSamples(samples(30, 20.0), p).verdict).isEqualTo(GameReadinessVerdict.READY)
    }

    @Test fun mediumConfidenceTightensThresholdsByTenPercent() {
        val q = completed(samples(30, 95.0))
        assertThat(GameReadinessEvaluator.evaluate(q, null, br, MeasurementConfidence.HIGH).verdict).isEqualTo(GameReadinessVerdict.READY)
        assertThat(GameReadinessEvaluator.evaluate(q, null, br, MeasurementConfidence.MEDIUM).verdict).isEqualTo(GameReadinessVerdict.NOT_READY)
    }

    @Test fun recurringSevereSpikesTriggerNotReady() {
        val q = completed(samples(30, 25.0))
        val r = GameReadinessEvaluator.evaluate(q, null, br, spikePattern = SpikePattern.Recurring(2, 2))
        assertThat(r.verdict).isEqualTo(GameReadinessVerdict.NOT_READY)
    }

    @Test fun degradedGatewayIsCautionWithFinding() {
        val q = completed(samples(30, 25.0))
        val r = GameReadinessEvaluator.evaluate(q, null, br, gatewayOutcome = GatewayProbeOutcome.Degraded(25.0, 5.0))
        assertThat(r.verdict).isEqualTo(GameReadinessVerdict.CAUTION)
        assertThat(r.finding(NetworkFinding.Kind.LOCAL_GATEWAY)?.severity).isEqualTo(NetworkFinding.Severity.NEGATIVE)
    }

    @Test fun unobservableGatewayNeverBlamesTheRouter() {
        val r = GameReadinessEvaluator.evaluate(completed(samples(30, 25.0)), null, br)
        assertThat(r.finding(NetworkFinding.Kind.LOCAL_GATEWAY)).isNull()
    }

    @Test fun severeLoadTierIsNotReady() {
        val q = completed(samples(30, 25.0))
        val impact = DeepCheckLoadImpact(25.0, 80.0, LoadDegradationTier.SEVERE)
        val r = GameReadinessEvaluator.evaluate(q, impact, br)
        assertThat(r.verdict).isEqualTo(GameReadinessVerdict.NOT_READY)
        assertThat(r.finding(NetworkFinding.Kind.LOAD_DEGRADATION)?.severity).isEqualTo(NetworkFinding.Severity.NEGATIVE)
    }

    @Test fun fastFiberWithNormalVarianceIsReady() {
        val s = (0 until 20).map { ProbeSample(it, 13.0, ProbeOutcome.RECEIVED) } +
            (20 until 28).map { ProbeSample(it, 15.0, ProbeOutcome.RECEIVED) } +
            listOf(ProbeSample(28, 24.0, ProbeOutcome.RECEIVED), ProbeSample(29, 24.0, ProbeOutcome.RECEIVED))
        val r = GameReadinessEvaluator.evaluate(completed(s), null, br)
        assertThat(r.verdict).isEqualTo(GameReadinessVerdict.READY)
        assertThat(r.findings.any { it.labelKey == "game_readiness.finding.tail_latency_elevated" }).isFalse()
    }

    @Test fun elevatedTailLatencyDemotesToCaution() {
        val s = (0 until 26).map { ProbeSample(it, 35.0, ProbeOutcome.RECEIVED) } + (26 until 30).map { ProbeSample(it, 75.0, ProbeOutcome.RECEIVED) }
        val r = GameReadinessEvaluator.evaluate(completed(s), null, br)
        assertThat(r.verdict).isEqualTo(GameReadinessVerdict.CAUTION)
        assertThat(r.findings.any { it.labelKey == "game_readiness.finding.tail_latency_elevated" }).isTrue()
    }

    @Test fun outOfOrderDemotesToCaution() {
        val s = (0 until 30).map { i ->
            val seq = when (i) { 2 -> 3; 3 -> 2; 6 -> 7; 7 -> 6; else -> i }
            ProbeSample(seq, 25.0, ProbeOutcome.RECEIVED, arrivalIndex = i)
        }
        val q = completed(s)
        assertThat(q.metrics.outOfOrderCount).isEqualTo(2)
        val r = GameReadinessEvaluator.evaluate(q, null, br)
        assertThat(r.verdict).isEqualTo(GameReadinessVerdict.CAUTION)
        assertThat(r.subtitleKey).isEqualTo("game_readiness.verdict.caution.out_of_order")
        assertThat(r.finding(NetworkFinding.Kind.OUT_OF_ORDER_PACKETS)).isNotNull()
    }
}
