package com.lagcheck.domain.rules

import com.lagcheck.domain.model.InconclusiveReason
import com.lagcheck.domain.model.MeasurementEvaluation
import com.lagcheck.domain.model.ProbeAcceptancePolicy
import com.lagcheck.domain.model.ProbeSample
import com.lagcheck.domain.model.QualityComponents
import com.lagcheck.domain.model.QualityMetrics
import com.lagcheck.domain.model.QualityProfileId
import com.lagcheck.domain.model.QualityResult
import com.lagcheck.domain.model.ResultClass
import com.lagcheck.domain.model.ScoreGuardrail
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.ceil

/**
 * Port de `QualityEvaluator` (Swift). Regras determinísticas e versionadas por perfil.
 * Qualquer mudança de número aqui exige nova versão de regra, vetores e revisão do Iury.
 */
object QualityEvaluator {

    fun ruleVersion(profile: QualityProfileId): String = when (profile) {
        QualityProfileId.BATTLE_ROYALE_COMPETITIVE -> "pilot-2026.09.08.1"
        QualityProfileId.MOBILE_REALTIME -> "mobile-realtime-2026.09.08.1"
        QualityProfileId.CASUAL_REALTIME -> "casual-realtime-2026.09.08.1"
    }

    fun supports(profile: QualityProfileId, ruleVersion: String): Boolean =
        ruleVersion == ruleVersion(profile)

    /** Guardrails usados para escolher a causa principal. Único ponto de verdade. */
    data class CauseGuardrails(
        val lossGuardrailPercentage: Double,
        val latencyGuardrailMilliseconds: Double,
        val severeSpikeGuardrailCount: Int,
        val jitterRiskMilliseconds: Double
    )

    fun causeGuardrails(profile: QualityProfileId): CauseGuardrails {
        val rule = ProfileRule.of(profile)
        return CauseGuardrails(
            lossGuardrailPercentage = rule.lossGuardrail,
            latencyGuardrailMilliseconds = rule.latencyGuardrail,
            severeSpikeGuardrailCount = rule.severeSpikeGuardrailCount,
            jitterRiskMilliseconds = rule.jitter.unstable
        )
    }

    fun evaluate(samples: List<ProbeSample>, profile: QualityProfileId): MeasurementEvaluation {
        val rule = ProfileRule.of(profile)
        val validRTTs = samples.filter { it.isValidResponse }.mapNotNull { it.roundTripMilliseconds }
        val timeoutCount = samples.count { it.outcome == com.lagcheck.domain.model.ProbeOutcome.TIMEOUT }
        val invalidResponseCount = samples.count { it.outcome == com.lagcheck.domain.model.ProbeOutcome.INVALID_RESPONSE }
        val loss = timeoutCount.toDouble() / ProbeAcceptancePolicy.PLANNED_PROBE_COUNT * 100.0

        if (validRTTs.size < ProbeAcceptancePolicy.MINIMUM_VALID_RESPONSES) {
            return MeasurementEvaluation.Inconclusive(
                reason = InconclusiveReason.INSUFFICIENT_UDP_RESPONSES,
                diagnostics = diagnosticMetrics(validRTTs, timeoutCount, invalidResponseCount, loss, rule)
            )
        }

        val p50 = percentile(validRTTs, 0.50)
        val p95 = percentile(validRTTs, 0.95)
        val p99 = percentile(validRTTs, 0.99)
        val jitter = averageAdjacentDifference(validRTTs)
        val ratio = if (p50 == 0.0) (if (p95 == 0.0) 1.0 else Double.POSITIVE_INFINITY) else p95 / p50
        val spikeCount = validRTTs.count { it > p50 + rule.spikeOffset && it >= rule.spikeFloor }
        val severeSpikeCount = validRTTs.count { it > p50 + rule.severeSpikeOffset && it >= rule.severeSpikeFloor }
        val spikeRate = spikeCount.toDouble() / validRTTs.size * 100.0

        val latencyC = component(p50, rule.latency)
        val lossC = component(loss, rule.loss)
        val jitterC = component(jitter, rule.jitter)
        val tailC = component(ratio, rule.tail)
        val spikesC = component(spikeRate, rule.spikeRate)
        val consistency = (0.40 * jitterC + 0.30 * tailC + 0.20 * spikesC + 0.10 * lossC).coerceIn(0.0, 100.0)
        val components = QualityComponents(
            latency = latencyC,
            loss = lossC,
            jitter = jitterC,
            tail = tailC,
            spikes = spikesC,
            consistency = consistency,
            stability = minOf(spikesC, consistency)
        )

        // Reordenação (RFC 4737): chegou com sequência menor que o maior já visto.
        val byArrival = samples
            .filter { it.isValidResponse && it.arrivalIndex != null }
            .sortedBy { it.arrivalIndex ?: 0 }
        var outOfOrderCount = 0
        var maxSeq = -1
        for (sample in byArrival) {
            if (maxSeq >= 0 && sample.sequence < maxSeq) outOfOrderCount += 1 else maxSeq = maxOf(maxSeq, sample.sequence)
        }
        val outOfOrderRate = if (validRTTs.isEmpty()) 0.0 else outOfOrderCount.toDouble() / validRTTs.size * 100.0

        val metrics = QualityMetrics(
            validResponseCount = validRTTs.size,
            timeoutCount = timeoutCount,
            invalidResponseCount = invalidResponseCount,
            p50Milliseconds = p50,
            p95Milliseconds = p95,
            p99Milliseconds = p99,
            jitterMilliseconds = jitter,
            packetLossPercentage = loss,
            spikeCount = spikeCount,
            severeSpikeCount = severeSpikeCount,
            spikeRatePercentage = spikeRate,
            p95ToP50Ratio = ratio,
            worstSpikeMilliseconds = validRTTs.max(),
            outOfOrderCount = outOfOrderCount,
            outOfOrderRatePercentage = outOfOrderRate,
            components = components
        )

        val rawScore = roundHalfAwayFromZero(
            0.35 * components.latency + 0.30 * components.loss + 0.20 * components.jitter + 0.15 * components.stability
        )

        val guardrails = mutableSetOf<ScoreGuardrail>()
        var finalScore = rawScore
        if (loss > rule.lossGuardrail || p50 > rule.latencyGuardrail) {
            guardrails += ScoreGuardrail.EXCESSIVE_LOSS_OR_LATENCY
            finalScore = minOf(finalScore, 59)
        }
        if (severeSpikeCount >= rule.severeSpikeGuardrailCount) {
            guardrails += ScoreGuardrail.SEVERE_SPIKES
            finalScore = minOf(finalScore, 74)
        }

        return MeasurementEvaluation.Completed(
            QualityResult(metrics, rawScore, finalScore, resultClass(finalScore), guardrails)
        )
    }

    // region Perfis

    private data class Thresholds(val excellent: Double, val great: Double, val unstable: Double, val risk: Double)

    private class ProfileRule(
        val latency: Thresholds,
        val loss: Thresholds,
        val jitter: Thresholds,
        val tail: Thresholds,
        val spikeRate: Thresholds,
        val spikeOffset: Double,
        val spikeFloor: Double,
        val severeSpikeOffset: Double,
        val severeSpikeFloor: Double,
        val lossGuardrail: Double,
        val latencyGuardrail: Double,
        val severeSpikeGuardrailCount: Int
    ) {
        companion object {
            fun of(profile: QualityProfileId): ProfileRule = when (profile) {
                QualityProfileId.BATTLE_ROYALE_COMPETITIVE -> ProfileRule(
                    latency = Thresholds(40.0, 60.0, 90.0, 100.0),
                    loss = Thresholds(0.0, 1.0, 3.0, 5.0),
                    jitter = Thresholds(8.0, 15.0, 25.0, 40.0),
                    tail = Thresholds(1.10, 1.35, 1.75, 2.50),
                    spikeRate = Thresholds(0.0, 3.0, 10.0, 20.0),
                    spikeOffset = 30.0, spikeFloor = 80.0, severeSpikeOffset = 80.0, severeSpikeFloor = 150.0,
                    lossGuardrail = 3.0, latencyGuardrail = 100.0, severeSpikeGuardrailCount = 2
                )
                QualityProfileId.MOBILE_REALTIME -> ProfileRule(
                    latency = Thresholds(50.0, 80.0, 120.0, 120.0),
                    loss = Thresholds(0.0, 1.0, 5.0, 8.0),
                    jitter = Thresholds(12.0, 20.0, 35.0, 50.0),
                    tail = Thresholds(1.15, 1.50, 2.00, 2.75),
                    spikeRate = Thresholds(0.0, 4.0, 12.0, 25.0),
                    spikeOffset = 40.0, spikeFloor = 100.0, severeSpikeOffset = 100.0, severeSpikeFloor = 200.0,
                    lossGuardrail = 5.0, latencyGuardrail = 130.0, severeSpikeGuardrailCount = 2
                )
                QualityProfileId.CASUAL_REALTIME -> ProfileRule(
                    latency = Thresholds(70.0, 110.0, 170.0, 170.0),
                    loss = Thresholds(0.0, 1.0, 3.0, 5.0),
                    jitter = Thresholds(20.0, 35.0, 50.0, 65.0),
                    tail = Thresholds(1.20, 1.60, 2.20, 3.00),
                    spikeRate = Thresholds(0.0, 5.0, 15.0, 30.0),
                    spikeOffset = 60.0, spikeFloor = 140.0, severeSpikeOffset = 140.0, severeSpikeFloor = 300.0,
                    lossGuardrail = 3.0, latencyGuardrail = 180.0, severeSpikeGuardrailCount = 3
                )
            }
        }
    }

    // endregion

    private fun diagnosticMetrics(
        validRTTs: List<Double>,
        timeoutCount: Int,
        invalidResponseCount: Int,
        loss: Double,
        rule: ProfileRule
    ): QualityMetrics {
        val hasData = validRTTs.isNotEmpty()
        val p50 = if (hasData) percentile(validRTTs, 0.50) else null
        val p95 = if (hasData) percentile(validRTTs, 0.95) else null
        val p99 = if (hasData) percentile(validRTTs, 0.99) else null
        val jitter = if (hasData) averageAdjacentDifference(validRTTs) else null
        val ratio = if (p50 != null && p95 != null) {
            if (p50 == 0.0) (if (p95 == 0.0) 1.0 else Double.POSITIVE_INFINITY) else p95 / p50
        } else null
        val spikes = p50?.let { m -> validRTTs.count { it > m + rule.spikeOffset && it >= rule.spikeFloor } } ?: 0
        val severe = p50?.let { m -> validRTTs.count { it > m + rule.severeSpikeOffset && it >= rule.severeSpikeFloor } } ?: 0
        return QualityMetrics(
            validResponseCount = validRTTs.size,
            timeoutCount = timeoutCount,
            invalidResponseCount = invalidResponseCount,
            p50Milliseconds = p50,
            p95Milliseconds = p95,
            p99Milliseconds = p99,
            jitterMilliseconds = jitter,
            packetLossPercentage = loss,
            spikeCount = spikes,
            severeSpikeCount = severe,
            spikeRatePercentage = if (hasData) spikes.toDouble() / validRTTs.size * 100.0 else 0.0,
            p95ToP50Ratio = ratio,
            worstSpikeMilliseconds = validRTTs.maxOrNull(),
            components = null
        )
    }

    /** Interpolação linear entre vizinhos, idêntica ao Swift. */
    internal fun percentile(values: List<Double>, percentile: Double): Double {
        val sorted = values.sorted()
        val position = (sorted.size - 1) * percentile
        val lower = floor(position).toInt()
        val upper = ceil(position).toInt()
        return sorted[lower] + (sorted[upper] - sorted[lower]) * (position - lower)
    }

    internal fun averageAdjacentDifference(values: List<Double>): Double {
        if (values.size <= 1) return 0.0
        var total = 0.0
        for (i in 1 until values.size) total += abs(values[i] - values[i - 1])
        return total / (values.size - 1)
    }

    private fun component(value: Double, t: Thresholds): Double = when {
        value <= t.excellent -> 100.0
        value <= t.great -> interpolate(value, t.excellent, t.great, 100.0, 80.0)
        value <= t.unstable -> interpolate(value, t.great, t.unstable, 80.0, 60.0)
        value < t.risk -> interpolate(value, t.unstable, t.risk, 60.0, 0.0)
        else -> 0.0
    }

    private fun interpolate(value: Double, from: Double, to: Double, start: Double, end: Double): Double {
        val progress = (value - from) / (to - from)
        return start + (end - start) * progress
    }

    private fun roundHalfAwayFromZero(value: Double): Int =
        if (value >= 0) floor(value + 0.5).toInt() else -floor(-value + 0.5).toInt()

    private fun resultClass(score: Int): ResultClass = when {
        score >= 90 -> ResultClass.EXCELLENT
        score >= 75 -> ResultClass.GREAT
        score >= 60 -> ResultClass.UNSTABLE
        else -> ResultClass.LAG_RISK
    }
}
