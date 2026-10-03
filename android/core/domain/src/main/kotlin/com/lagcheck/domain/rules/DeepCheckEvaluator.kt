package com.lagcheck.domain.rules

import com.lagcheck.domain.model.InconclusiveReason
import com.lagcheck.domain.model.MeasurementEvaluation
import com.lagcheck.domain.model.ProbeSample
import com.lagcheck.domain.model.QualityMetrics
import com.lagcheck.domain.model.QualityProfileId
import com.lagcheck.domain.model.QualityResult

enum class LoadDegradationTier { NONE, LIGHT, MATERIAL, SEVERE }

enum class LoadImpactClassification { DESCRIPTIVE, MATERIAL }

/** Comparação observada repouso × carga. Não é score nem classe de qualidade. */
data class DeepCheckLoadImpact(
    val restP50Milliseconds: Double,
    val loadP50Milliseconds: Double,
    val tier: LoadDegradationTier,
    val deltaJitterMilliseconds: Double? = null,
    val deltaLossPercentage: Double? = null,
    val deltaSpikesCount: Int? = null,
    val ruleVersion: String = DeepCheckLoadImpactRuleV2.VERSION
) {
    val increaseMilliseconds: Double get() = loadP50Milliseconds - restP50Milliseconds

    companion object {
        /** Equivalente ao init de conveniência do Swift: tier derivado só do delta de P50 (corte de 20 ms). */
        fun fromP50(restP50Milliseconds: Double, loadP50Milliseconds: Double): DeepCheckLoadImpact {
            val increase = loadP50Milliseconds - restP50Milliseconds
            val tier = if (increase >= DeepCheckLoadImpactRuleV1.MATERIAL_INCREASE_MILLISECONDS)
                LoadDegradationTier.MATERIAL else LoadDegradationTier.NONE
            return DeepCheckLoadImpact(restP50Milliseconds, loadP50Milliseconds, tier)
        }
    }
    val classification: LoadImpactClassification
        get() = if (increaseMilliseconds >= DeepCheckLoadImpactRuleV1.MATERIAL_INCREASE_MILLISECONDS)
            LoadImpactClassification.MATERIAL else LoadImpactClassification.DESCRIPTIVE
}

object DeepCheckLoadImpactRuleV1 {
    const val VERSION = "deep-load-impact-v1"
    const val MATERIAL_INCREASE_MILLISECONDS = 20.0
}

/** Regra multidimensional calibrada por perfil (deep-load-impact-v2). */
object DeepCheckLoadImpactRuleV2 {
    const val VERSION = "deep-load-impact-v2"

    fun classify(
        profile: QualityProfileId,
        deltaP50: Double,
        deltaJitter: Double,
        deltaLoss: Double,
        deltaSpikes: Int
    ): LoadDegradationTier = when (profile) {
        QualityProfileId.BATTLE_ROYALE_COMPETITIVE -> when {
            deltaP50 > 40 || deltaJitter > 20 || deltaLoss > 5.0 || deltaSpikes >= 4 -> LoadDegradationTier.SEVERE
            deltaP50 > 18 || deltaJitter > 8 || deltaLoss > 2.0 || deltaSpikes >= 2 -> LoadDegradationTier.MATERIAL
            deltaP50 > 8 || deltaJitter > 4 || deltaLoss > 1.0 || deltaSpikes >= 1 -> LoadDegradationTier.LIGHT
            else -> LoadDegradationTier.NONE
        }
        QualityProfileId.MOBILE_REALTIME -> when {
            deltaP50 > 55 || deltaJitter > 25 || deltaLoss > 7.0 || deltaSpikes >= 5 -> LoadDegradationTier.SEVERE
            deltaP50 > 25 || deltaJitter > 12 || deltaLoss > 3.0 || deltaSpikes >= 2 -> LoadDegradationTier.MATERIAL
            deltaP50 > 12 || deltaJitter > 6 || deltaLoss > 1.5 || deltaSpikes >= 1 -> LoadDegradationTier.LIGHT
            else -> LoadDegradationTier.NONE
        }
        QualityProfileId.CASUAL_REALTIME -> when {
            deltaP50 > 80 || deltaJitter > 35 || deltaLoss > 10.0 -> LoadDegradationTier.SEVERE
            deltaP50 > 40 || deltaJitter > 18 || deltaLoss > 5.0 -> LoadDegradationTier.MATERIAL
            deltaP50 > 20 || deltaJitter > 10 || deltaLoss > 2.0 -> LoadDegradationTier.LIGHT
            else -> LoadDegradationTier.NONE
        }
    }
}

data class DeepCheckMetrics(
    val rest: QualityMetrics,
    val load: QualityMetrics?,
    val loadImpact: DeepCheckLoadImpact?
)

data class DeepCheckResult(val restResult: QualityResult, val metrics: DeepCheckMetrics)

sealed class DeepCheckEvaluation {
    data class Completed(val result: DeepCheckResult) : DeepCheckEvaluation()
    data class Inconclusive(val reason: InconclusiveReason, val diagnostics: QualityMetrics) : DeepCheckEvaluation()
}

/**
 * Avalia repouso e carga sem misturar as séries nem recalcular o score de repouso.
 * Falha ou dados insuficientes na carga não invalidam o resultado de repouso.
 */
object DeepCheckEvaluator {
    fun evaluate(
        restSamples: List<ProbeSample>,
        loadSamples: List<ProbeSample>?,
        profile: QualityProfileId
    ): DeepCheckEvaluation {
        val rest = when (val e = QualityEvaluator.evaluate(restSamples, profile)) {
            is MeasurementEvaluation.Inconclusive -> return DeepCheckEvaluation.Inconclusive(e.reason, e.diagnostics)
            is MeasurementEvaluation.Completed -> e.result
        }
        val withoutLoad = DeepCheckEvaluation.Completed(
            DeepCheckResult(rest, DeepCheckMetrics(rest.metrics, null, null))
        )
        if (loadSamples == null) return withoutLoad
        val load = (QualityEvaluator.evaluate(loadSamples, profile) as? MeasurementEvaluation.Completed)?.result
            ?: return withoutLoad
        val restP50 = rest.metrics.p50Milliseconds ?: return withoutLoad
        val loadP50 = load.metrics.p50Milliseconds ?: return withoutLoad

        val deltaP50 = maxOf(0.0, loadP50 - restP50)
        val deltaJitter = maxOf(0.0, (load.metrics.jitterMilliseconds ?: 0.0) - (rest.metrics.jitterMilliseconds ?: 0.0))
        val deltaLoss = maxOf(0.0, load.metrics.packetLossPercentage - rest.metrics.packetLossPercentage)
        val deltaSpikes = maxOf(0, load.metrics.spikeCount - rest.metrics.spikeCount)
        val tier = DeepCheckLoadImpactRuleV2.classify(profile, deltaP50, deltaJitter, deltaLoss, deltaSpikes)

        return DeepCheckEvaluation.Completed(
            DeepCheckResult(
                rest,
                DeepCheckMetrics(
                    rest.metrics,
                    load.metrics,
                    DeepCheckLoadImpact(restP50, loadP50, tier, deltaJitter, deltaLoss, deltaSpikes)
                )
            )
        )
    }
}
