package com.lagcheck.android.data

import com.lagcheck.domain.rules.StabilitySummaryEvaluator

/**
 * Converte o histórico persistido no Android para o avaliador único no motor KMP (Decisão 143).
 */
object StabilityHistoryAdapter {
    fun evaluate(
        entries: List<CheckHistoryItem>,
        windowDays: Int = 14,
        gameIdFilter: String? = null,
        networkFilter: String? = null,
        nowEpochMs: Long = System.currentTimeMillis(),
        maxPoints: Int = 30
    ): StabilitySummaryEvaluator.Result {
        val mapped = entries.map { item ->
            val loadDelta = if (item.loadP50 != null && item.idleP50 != null) {
                item.loadP50 - item.idleP50
            } else {
                null
            }
            StabilitySummaryEvaluator.EntryInput(
                capturedAtEpochMs = item.timestamp,
                pingMs = item.pingMs,
                jitterMs = item.jitterMs,
                packetLossPercentage = item.packetLossPercentage,
                loadDeltaMs = loadDelta,
                verdict = item.verdict.name,
                validResponseCount = item.validResponseCount,
                gameId = item.gameId,
                gameTitle = item.gameName,
                platform = item.platform,
                declaredExternalLink = item.declaredExternalLink,
                networkType = item.observedNetwork,
                regionId = item.regionId,
                ruleVersion = item.profileRuleVersion
            )
        }
        return StabilitySummaryEvaluator.evaluate(
            StabilitySummaryEvaluator.Request(
                entries = mapped,
                windowDays = windowDays,
                nowEpochMs = nowEpochMs,
                gameIdFilter = gameIdFilter,
                networkFilter = networkFilter,
                maxPoints = maxPoints
            )
        )
    }
}
