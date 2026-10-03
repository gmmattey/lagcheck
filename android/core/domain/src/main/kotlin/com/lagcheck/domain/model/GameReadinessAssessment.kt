package com.lagcheck.domain.model

import com.lagcheck.domain.rules.PrimaryCause

/** Achado sem copy: o domínio emite chave, a apresentação localiza (mesmo contrato do Swift). */
data class ReadinessFinding(
    val kind: NetworkFinding.Kind,
    val severity: NetworkFinding.Severity,
    val labelKey: String,
    val detail: String? = null
)

/** Port de `GameReadinessEvaluation` (Swift, readiness-v2.0). */
data class GameReadinessAssessment(
    val verdict: GameReadinessVerdict,
    val headlineKey: String,
    val subtitleKey: String,
    /** 0.0–1.0 para a barra contínua de estabilidade. */
    val stabilityRatio: Double,
    val stabilitySummaryKey: String,
    val findings: List<ReadinessFinding>,
    val pingMs: Double?,
    val jitterMs: Double?,
    val packetLossPercentage: Double?,
    val isUnderLoadAffected: Boolean,
    val worstSpikeMs: Double? = null,
    /** Score numérico de repouso, subordinado ao veredito (Decisão 51). Nulo se inconclusivo. */
    val score: Int? = null,
    val primaryCause: PrimaryCause? = null
) {
    companion object {
        val INCONCLUSIVE = GameReadinessAssessment(
            verdict = GameReadinessVerdict.INCONCLUSIVE,
            headlineKey = "game_readiness.verdict.inconclusive.headline",
            subtitleKey = "game_readiness.verdict.inconclusive.subtitle",
            stabilityRatio = 0.0,
            stabilitySummaryKey = "game_readiness.stability.inconclusive",
            findings = listOf(
                ReadinessFinding(
                    NetworkFinding.Kind.INSUFFICIENT_DATA,
                    NetworkFinding.Severity.NEUTRAL,
                    "game_readiness.finding.insufficient_samples"
                )
            ),
            pingMs = null,
            jitterMs = null,
            packetLossPercentage = null,
            isUnderLoadAffected = false
        )
    }
}
