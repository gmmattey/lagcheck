package com.lagcheck.android.data

import com.google.common.truth.Truth.assertThat
import com.lagcheck.domain.model.GameReadinessVerdict
import org.junit.Test

class HistoryRitualSummaryTest {
    @Test fun countsOnlyComparableFactsAndKeepsInconclusiveSeparate() {
        val now = 2_000_000_000L
        val summary = HistoryRitualSummary.forEntries(
            listOf(
                item(GameReadinessVerdict.READY, now),
                item(GameReadinessVerdict.CAUTION, now - DAY),
                item(GameReadinessVerdict.NOT_READY, now - 2 * DAY),
                item(GameReadinessVerdict.INCONCLUSIVE, now - 3 * DAY, validResponses = 9),
                item(GameReadinessVerdict.INCONCLUSIVE, now - 3 * DAY, validResponses = 9, ruleVersion = "rule-2"),
                item(GameReadinessVerdict.READY, now - 4 * DAY, region = "us-east-1")
            ),
            windowDays = 7,
            now = now
        )!!

        assertThat(summary.readyCount).isEqualTo(1)
        assertThat(summary.cautionCount).isEqualTo(1)
        assertThat(summary.notReadyCount).isEqualTo(1)
        assertThat(summary.inconclusiveCount).isEqualTo(1)
        assertThat(summary.comparableCount).isEqualTo(3)
        assertThat(summary.hasEnoughEvidence).isTrue()
    }

    @Test fun legacyItemsAreVisibleButCannotClaimAPattern() {
        val now = 2_000_000_000L
        val legacy = item(GameReadinessVerdict.READY, now).copy(profileRuleVersion = null, regionId = null, observedNetwork = null, validResponseCount = null)
        assertThat(HistoryRitualSummary.forEntries(listOf(legacy), windowDays = 7, now = now)).isNull()
    }

    @Test fun retentionExpiresOldEntriesAndKeepsOneHundredPerGame() {
        val now = 10_000 * DAY
        val manyForOneGame = (0..100).map { item(GameReadinessVerdict.READY, now - it).copy(gameId = "fortnite") }
        val expiredOtherGame = item(GameReadinessVerdict.READY, now - 91 * DAY).copy(gameId = "valorant")
        val retained = HistoryRetentionPolicy.apply(manyForOneGame + expiredOtherGame, now)

        assertThat(retained).hasSize(100)
        assertThat(retained.map { it.gameId }.toSet()).containsExactly("fortnite")
    }

    private fun item(
        verdict: GameReadinessVerdict,
        timestamp: Long,
        region: String = "sa-east-1",
        validResponses: Int = 30,
        ruleVersion: String = "rule-1"
    ) = CheckHistoryItem(
        gameId = "fortnite", gameName = "Fortnite", platform = "PC", connectionType = "Wi-Fi",
        declaredExternalLink = "ETHERNET", profileRuleVersion = ruleVersion, regionId = region,
        observedNetwork = "WIFI", validResponseCount = validResponses, timestamp = timestamp, verdict = verdict,
        score = 80, pingMs = 30.0, jitterMs = 2.0, packetLossPercentage = 0.0, worstSpikeMs = 30.0,
        primaryWeight = "Rota estável", suitableUses = emptyList(), latencySeries = emptyList(), findings = emptyList()
    )

    private companion object { const val DAY = 86_400_000L }
}
