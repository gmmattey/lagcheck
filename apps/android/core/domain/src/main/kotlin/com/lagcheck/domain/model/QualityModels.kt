package com.lagcheck.domain.model

enum class QualityProfileId(val rawValue: String) {
    BATTLE_ROYALE_COMPETITIVE("BATTLE_ROYALE_COMPETITIVE"),
    MOBILE_REALTIME("MOBILE_REALTIME"),
    CASUAL_REALTIME("CASUAL_REALTIME");

    companion object {
        fun fromRaw(raw: String): QualityProfileId? = entries.firstOrNull { it.rawValue == raw }
    }
}

enum class MeasurementConfidence { MEDIUM, HIGH }

enum class ResultClass { EXCELLENT, GREAT, UNSTABLE, LAG_RISK }

enum class InconclusiveReason { INSUFFICIENT_UDP_RESPONSES, POOR_SAMPLE_QUALITY }

enum class ScoreGuardrail { EXCESSIVE_LOSS_OR_LATENCY, SEVERE_SPIKES }

data class QualityComponents(
    val latency: Double,
    val loss: Double,
    val jitter: Double,
    val tail: Double,
    val spikes: Double,
    val consistency: Double,
    val stability: Double
)

data class QualityMetrics(
    val validResponseCount: Int,
    val timeoutCount: Int,
    val invalidResponseCount: Int,
    val p50Milliseconds: Double?,
    val p95Milliseconds: Double?,
    val p99Milliseconds: Double?,
    val jitterMilliseconds: Double?,
    val packetLossPercentage: Double,
    val spikeCount: Int,
    val severeSpikeCount: Int,
    val spikeRatePercentage: Double,
    val p95ToP50Ratio: Double?,
    val worstSpikeMilliseconds: Double? = null,
    val outOfOrderCount: Int = 0,
    val outOfOrderRatePercentage: Double = 0.0,
    val components: QualityComponents? = null
)

data class QualityResult(
    val metrics: QualityMetrics,
    val rawScore: Int,
    val finalScore: Int,
    val resultClass: ResultClass,
    val appliedGuardrails: Set<ScoreGuardrail>
)

sealed class MeasurementEvaluation {
    data class Completed(val result: QualityResult) : MeasurementEvaluation()
    data class Inconclusive(val reason: InconclusiveReason, val diagnostics: QualityMetrics) : MeasurementEvaluation()
}

/** Resultado de um gateway probe local. Sem probe, o enlace local é `Unobservable` (Decisão 50). */
sealed class GatewayProbeOutcome {
    data class Stable(val rttMilliseconds: Double) : GatewayProbeOutcome()
    data class Degraded(val rttMilliseconds: Double, val lossPercentage: Double) : GatewayProbeOutcome()
    data object Unobservable : GatewayProbeOutcome()

    val isDegraded: Boolean get() = this is Degraded
    val isStable: Boolean get() = this is Stable
}

sealed class SpikePattern {
    data object None : SpikePattern()
    data class Isolated(val count: Int, val severeCount: Int) : SpikePattern()
    data class Recurring(val count: Int, val severeCount: Int) : SpikePattern()

    val isRecurring: Boolean get() = this is Recurring
    val severeSpikes: Int
        get() = when (this) {
            None -> 0
            is Isolated -> severeCount
            is Recurring -> severeCount
        }
}
