package com.lagcheck.android.data

import com.google.common.truth.Truth.assertThat
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.rules.StabilitySummaryEvaluator.MetricTone
import org.junit.Test

class StabilityHistoryAdapterTest {
    @Test
    fun mapsLoadDeltaFromLoadAndIdleP50AndSeparatesNetworks() {
        val now = 2_000_000_000L
        val entries = listOf(
            sample(now - 3 * DAY, ping = 18.0, idleP50 = 18.0, loadP50 = 26.0, network = "WIFI"),
            sample(now - 2 * DAY, ping = 22.0, idleP50 = 22.0, loadP50 = 30.0, network = "WIFI"),
            sample(now - 1 * DAY, ping = 20.0, idleP50 = 20.0, loadP50 = 32.0, network = "WIFI"),
            sample(now, ping = 55.0, idleP50 = 55.0, loadP50 = 85.0, network = "CELLULAR")
        )

        val wifiSummary = StabilityHistoryAdapter.evaluate(
            entries = entries,
            windowDays = 7,
            networkFilter = "WIFI",
            nowEpochMs = now
        )

        assertThat(wifiSummary.canDrawCurve).isTrue()
        assertThat(wifiSummary.hasSummary).isTrue()
        assertThat(wifiSummary.totalComparableCount).isEqualTo(3)
        assertThat(wifiSummary.avgPingMs).isEqualTo(20.0)
        assertThat(wifiSummary.rings?.load?.value).isWithin(0.01).of(9.333)
        assertThat(wifiSummary.rings?.load?.tone).isEqualTo(MetricTone.OK)
        assertThat(wifiSummary.availableNetworks).containsExactly("WIFI", "CELLULAR").inOrder()
    }

    @Test
    fun isolatesInconclusiveChecksAndKeepsLoadNullWithoutLoadPhase() {
        val now = 2_000_000_000L
        val entries = listOf(
            sample(now - 3 * DAY, ping = 20.0, idleP50 = 20.0, loadP50 = null),
            sample(now - 2 * DAY, ping = 22.0, idleP50 = 22.0, loadP50 = null),
            sample(now - 1 * DAY, ping = 24.0, idleP50 = 24.0, loadP50 = null),
            sample(now, ping = 999.0, verdict = GameReadinessVerdict.INCONCLUSIVE, validResponses = 5)
        )

        val result = StabilityHistoryAdapter.evaluate(
            entries = entries,
            windowDays = 14,
            gameIdFilter = "fortnite",
            nowEpochMs = now
        )

        assertThat(result.totalComparableCount).isEqualTo(3)
        assertThat(result.inconclusiveCount).isEqualTo(1)
        assertThat(result.rings?.load?.value).isNull()
        assertThat(result.rings?.load?.tone).isEqualTo(MetricTone.UNKNOWN)
    }

    private fun sample(
        timestamp: Long,
        ping: Double,
        idleP50: Double? = ping,
        loadP50: Double? = null,
        network: String = "WIFI",
        verdict: GameReadinessVerdict = GameReadinessVerdict.READY,
        validResponses: Int = 60
    ) = CheckHistoryItem(
        gameId = "fortnite",
        gameName = "Fortnite",
        platform = "MOBILE",
        connectionType = network,
        declaredExternalLink = null,
        profileRuleVersion = "readiness-v3.0",
        regionId = "sa-east-1",
        observedNetwork = network,
        validResponseCount = validResponses,
        timestamp = timestamp,
        verdict = verdict,
        score = 90,
        pingMs = ping,
        jitterMs = 3.0,
        packetLossPercentage = 0.0,
        worstSpikeMs = ping,
        primaryWeight = "Rota estável",
        suitableUses = emptyList(),
        latencySeries = emptyList(),
        findings = emptyList(),
        idleP50 = idleP50,
        loadP50 = loadP50
    )

    private companion object {
        const val DAY = 86_400_000L
    }
}
