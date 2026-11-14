package com.lagcheck.domain.rules

import com.lagcheck.domain.model.ProbeAcceptancePolicy

import com.lagcheck.domain.model.InconclusiveReason
import com.lagcheck.domain.model.MeasurementEvaluation
import com.lagcheck.domain.model.ProbeSample
import com.lagcheck.domain.model.QualityMetrics
import com.lagcheck.domain.model.QualityProfileId
import com.lagcheck.domain.model.QualityResult
import com.lagcheck.domain.model.MeasurementSource

enum class LoadDegradationTier { NONE, LIGHT, MATERIAL, SEVERE }

enum class LoadImpactClassification { DESCRIPTIVE, MATERIAL }


object BufferbloatRuleV1 {
    const val VERSION: String = "bufferbloat-grade-v1"
    const val A_PLUS_THRESHOLD: Double = 2.0
    const val A_THRESHOLD: Double = 5.0
    const val B_THRESHOLD: Double = 15.0
    const val C_THRESHOLD: Double = 35.0
    const val D_THRESHOLD: Double = 60.0

    fun evaluate(increaseMilliseconds: Double): BufferbloatGrade {
        return when {
            increaseMilliseconds <= A_PLUS_THRESHOLD -> BufferbloatGrade.A_PLUS
            increaseMilliseconds <= A_THRESHOLD -> BufferbloatGrade.A
            increaseMilliseconds <= B_THRESHOLD -> BufferbloatGrade.B
            increaseMilliseconds <= C_THRESHOLD -> BufferbloatGrade.C
            increaseMilliseconds <= D_THRESHOLD -> BufferbloatGrade.D
            else -> BufferbloatGrade.F
        }
    }
}

enum class BufferbloatGrade(val value: String) {
    A_PLUS("A+"),
    A("A"),
    B("B"),
    C("C"),
    D("D"),
    F("F");

    companion object {
        fun fromIncrease(increaseMilliseconds: Double): BufferbloatGrade {
            return BufferbloatRuleV1.evaluate(increaseMilliseconds)
        }

        fun fromValue(value: String): BufferbloatGrade? {
            return entries.firstOrNull { it.value == value }
        }
    }
}

/** Comparação observada repouso × carga. Não é score nem classe de qualidade. */
data class DeepCheckLoadImpact(
    val restP50Milliseconds: Double,
    val loadP50Milliseconds: Double,
    val tier: LoadDegradationTier,
    val deltaJitterMilliseconds: Double? = null,
    val deltaLossPercentage: Double? = null,
    val deltaSpikesCount: Int? = null,
    val ruleVersion: String = DeepCheckLoadImpactRuleV4.VERSION,
    val bufferbloatGrade: BufferbloatGrade = BufferbloatGrade.fromIncrease(loadP50Milliseconds - restP50Milliseconds)
) {
    val increaseMilliseconds: Double get() = loadP50Milliseconds - restP50Milliseconds

    companion object {
        /** Sem perfil e sem métricas complementares, +20 ms só descreve bufferbloat; não classifica impacto. */
        fun fromP50(restP50Milliseconds: Double, loadP50Milliseconds: Double): DeepCheckLoadImpact {
            return DeepCheckLoadImpact(restP50Milliseconds, loadP50Milliseconds, LoadDegradationTier.NONE)
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

/**
 * Regra multidimensional calibrada por perfil (deep-load-impact-v4, Decisão 136).
 * A perda sob carga é contada em pacotes do plano de 60: 1 pacote isolado é ruído
 * estatístico (aparece em 26% dos checks de uma conexão com 0,5% de perda real), então
 * o material exige 2 pacotes a mais que o repouso e o severo, 3 ou 4.
 */
object DeepCheckLoadImpactRuleV4 {
    const val VERSION = "deep-load-impact-v4"

    /** Pacotes perdidos a mais sob carga, a partir do Δperda em % sobre o plano de 60. */
    fun extraLostPackets(deltaLossPercentage: Double): Int =
        kotlin.math.round(deltaLossPercentage * ProbeAcceptancePolicy.PLANNED_PROBE_COUNT / 100.0).toInt()

    fun classify(
        profile: QualityProfileId,
        deltaP50: Double,
        deltaJitter: Double,
        deltaLoss: Double,
        deltaSpikes: Int
    ): LoadDegradationTier {
        val lost = extraLostPackets(deltaLoss)
        return when (profile) {
            QualityProfileId.BATTLE_ROYALE_COMPETITIVE -> when {
                deltaP50 >= 35 || deltaJitter >= 20 || lost >= 3 || deltaSpikes >= 4 -> LoadDegradationTier.SEVERE
                deltaP50 >= 15 || deltaJitter >= 10 || lost >= 2 || deltaSpikes >= 2 -> LoadDegradationTier.MATERIAL
                deltaP50 >= 5 -> LoadDegradationTier.LIGHT
                else -> LoadDegradationTier.NONE
            }
            QualityProfileId.MOBILE_REALTIME -> when {
                deltaP50 >= 50 || deltaJitter >= 25 || lost >= 4 || deltaSpikes >= 5 -> LoadDegradationTier.SEVERE
                deltaP50 >= 25 || deltaJitter >= 15 || lost >= 2 || deltaSpikes >= 2 -> LoadDegradationTier.MATERIAL
                deltaP50 >= 5 -> LoadDegradationTier.LIGHT
                else -> LoadDegradationTier.NONE
            }
            QualityProfileId.CASUAL_REALTIME -> when {
                deltaP50 >= 80 || deltaJitter >= 35 || lost >= 4 || deltaSpikes >= 6 -> LoadDegradationTier.SEVERE
                deltaP50 >= 40 || deltaJitter >= 20 || lost >= 2 || deltaSpikes >= 2 -> LoadDegradationTier.MATERIAL
                deltaP50 >= 5 -> LoadDegradationTier.LIGHT
                else -> LoadDegradationTier.NONE
            }
        }
    }
}

/** Aliases legados; os consumidores devem usar a regra v4. */
@Deprecated("Use DeepCheckLoadImpactRuleV4")
object DeepCheckLoadImpactRuleV3 {
    const val VERSION = DeepCheckLoadImpactRuleV4.VERSION
    fun classify(profile: QualityProfileId, deltaP50: Double, deltaJitter: Double, deltaLoss: Double, deltaSpikes: Int) =
        DeepCheckLoadImpactRuleV4.classify(profile, deltaP50, deltaJitter, deltaLoss, deltaSpikes)
}

@Deprecated("Use DeepCheckLoadImpactRuleV4")
object DeepCheckLoadImpactRuleV2 {
    const val VERSION = DeepCheckLoadImpactRuleV4.VERSION
    fun classify(profile: QualityProfileId, deltaP50: Double, deltaJitter: Double, deltaLoss: Double, deltaSpikes: Int) =
        DeepCheckLoadImpactRuleV4.classify(profile, deltaP50, deltaJitter, deltaLoss, deltaSpikes)
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
        profile: QualityProfileId,
        source: MeasurementSource = MeasurementSource.APP_UDP
    ): DeepCheckEvaluation {
        val rest = when (val e = QualityEvaluator.evaluate(restSamples, profile, source)) {
            is MeasurementEvaluation.Inconclusive -> return DeepCheckEvaluation.Inconclusive(e.reason, e.diagnostics)
            is MeasurementEvaluation.Completed -> e.result
        }
        val withoutLoad = DeepCheckEvaluation.Completed(
            DeepCheckResult(rest, DeepCheckMetrics(rest.metrics, null, null))
        )
        if (loadSamples == null) return withoutLoad
        val loadEvaluation = QualityEvaluator.evaluate(loadSamples, profile, source)
        val load = (loadEvaluation as? MeasurementEvaluation.Completed)?.result
            ?: return DeepCheckEvaluation.Inconclusive(InconclusiveReason.POOR_SAMPLE_QUALITY, when (loadEvaluation) {
                is MeasurementEvaluation.Inconclusive -> loadEvaluation.diagnostics
                else -> rest.metrics
            })
        val restP50 = rest.metrics.p50Milliseconds ?: return withoutLoad
        val loadP50 = load.metrics.p50Milliseconds ?: return withoutLoad

        val deltaP50 = maxOf(0.0, loadP50 - restP50)
        val deltaJitter = maxOf(0.0, (load.metrics.jitterMilliseconds ?: 0.0) - (rest.metrics.jitterMilliseconds ?: 0.0))
        val deltaLoss = maxOf(0.0, load.metrics.packetLossPercentage - rest.metrics.packetLossPercentage)
        val deltaSpikes = maxOf(0, load.metrics.spikeCount - rest.metrics.spikeCount)
        val tier = DeepCheckLoadImpactRuleV4.classify(profile, deltaP50, deltaJitter, deltaLoss, deltaSpikes)

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
