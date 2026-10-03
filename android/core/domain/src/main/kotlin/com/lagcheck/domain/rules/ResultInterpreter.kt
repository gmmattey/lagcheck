package com.lagcheck.domain.rules

import com.lagcheck.domain.model.QualityMetrics
import com.lagcheck.domain.model.QualityProfileId
import com.lagcheck.domain.model.QualityResult
import com.lagcheck.domain.model.ResultClass
import com.lagcheck.domain.model.SpikePattern

enum class PrimaryCause {
    STABLE_CONNECTION, PACKET_LOSS, HIGH_LATENCY, SEVERE_SPIKES, HIGH_JITTER,
    LOAD_DEGRADATION, LOAD_INSTABILITY, TAIL_LATENCY, OUT_OF_ORDER
}

enum class ResultConclusion { READY_TO_PLAY, LAG_MAY_OCCUR, INVESTIGATE_BEFORE_PLAYING }

data class ResultInterpretation(
    val score: Int,
    val scoreBand: ResultClass,
    val conclusion: ResultConclusion,
    val primaryCause: PrimaryCause,
    val secondaryCauses: List<PrimaryCause>
)

/** Escolhe a causa única de destaque. Prioridade: perda, P50, spikes severos, jitter, ordem, carga. */
object ResultInterpreter {
    fun interpret(
        result: QualityResult,
        profile: QualityProfileId,
        loadTier: LoadDegradationTier? = null,
        spikePattern: SpikePattern? = null
    ): ResultInterpretation {
        val (primary, secondaries) = evaluateCauses(
            result.metrics, QualityEvaluator.causeGuardrails(profile), loadTier, spikePattern
        )
        val conclusion = when (result.resultClass) {
            ResultClass.EXCELLENT, ResultClass.GREAT -> ResultConclusion.READY_TO_PLAY
            ResultClass.UNSTABLE -> ResultConclusion.LAG_MAY_OCCUR
            ResultClass.LAG_RISK -> ResultConclusion.INVESTIGATE_BEFORE_PLAYING
        }
        return ResultInterpretation(result.finalScore, result.resultClass, conclusion, primary, secondaries)
    }

    private fun evaluateCauses(
        metrics: QualityMetrics,
        guardrails: QualityEvaluator.CauseGuardrails,
        loadTier: LoadDegradationTier?,
        spikePattern: SpikePattern?
    ): Pair<PrimaryCause, List<PrimaryCause>> {
        val causes = mutableListOf<PrimaryCause>()
        val isLoss = metrics.packetLossPercentage > guardrails.lossGuardrailPercentage
        val isLatency = (metrics.p50Milliseconds ?: 0.0) > guardrails.latencyGuardrailMilliseconds
        val isSevereSpikes = if (spikePattern != null) {
            spikePattern.severeSpikes >= guardrails.severeSpikeGuardrailCount
        } else {
            metrics.severeSpikeCount >= guardrails.severeSpikeGuardrailCount
        }
        val isJitter = (metrics.jitterMilliseconds ?: 0.0) > guardrails.jitterRiskMilliseconds
        val isLoad = loadTier == LoadDegradationTier.MATERIAL || loadTier == LoadDegradationTier.SEVERE
        val isTail = (metrics.p95ToP50Ratio ?: 0.0) >= 1.8
        val isOutOfOrder = metrics.outOfOrderCount >= 2 || metrics.outOfOrderRatePercentage >= 5.0

        if (isJitter && isLoad) {
            causes += PrimaryCause.LOAD_INSTABILITY
            if (isLoss) causes += PrimaryCause.PACKET_LOSS
            if (isLatency) causes += PrimaryCause.HIGH_LATENCY
            if (isSevereSpikes) causes += PrimaryCause.SEVERE_SPIKES
            if (isOutOfOrder) causes += PrimaryCause.OUT_OF_ORDER
        } else {
            if (isLoss) causes += PrimaryCause.PACKET_LOSS
            if (isLatency) causes += PrimaryCause.HIGH_LATENCY
            if (isSevereSpikes) causes += PrimaryCause.SEVERE_SPIKES
            if (isJitter) causes += PrimaryCause.HIGH_JITTER
            if (isOutOfOrder) causes += PrimaryCause.OUT_OF_ORDER
            if (isLoad) causes += PrimaryCause.LOAD_DEGRADATION
        }

        val primary = causes.firstOrNull() ?: PrimaryCause.STABLE_CONNECTION
        val secondaries = causes.drop(1).take(2).toMutableList()
        if (isTail && PrimaryCause.TAIL_LATENCY !in causes && secondaries.size < 2) secondaries += PrimaryCause.TAIL_LATENCY
        return primary to secondaries
    }
}
