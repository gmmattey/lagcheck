package com.lagcheck.android.data

import com.google.common.truth.Truth.assertThat
import com.lagcheck.domain.model.GameReadinessVerdict
import org.junit.Test

class CheckHistoryItemTest {

    @Test
    fun testMetricsStringFormatting() {
        val item = CheckHistoryItem(
            gameId = "fortnite",
            gameName = "Fortnite",
            platform = "PlayStation",
            connectionType = "Wi-Fi",
            timestamp = System.currentTimeMillis(),
            verdict = GameReadinessVerdict.READY,
            score = 86,
            pingMs = 31.0,
            jitterMs = 3.0,
            packetLossPercentage = 0.4,
            worstSpikeMs = 47.0,
            primaryWeight = "Rota estável sob carga",
            suitableUses = listOf("Ranked", "Casual", "Party"),
            latencySeries = listOf(31.0, 32.0),
            findings = emptyList()
        )

        assertThat(item.metricsString).contains("31 ms")
        assertThat(item.metricsString).contains("3 ms jitter")
        assertThat(item.metricsString).contains("perda")
    }

    @Test
    fun testFormattedDateRecent() {
        val now = System.currentTimeMillis()
        val item = CheckHistoryItem(
            gameId = "valorant",
            gameName = "Valorant",
            platform = "PC",
            connectionType = "Cabo",
            timestamp = now - 30000, // 30s atrás
            verdict = GameReadinessVerdict.CAUTION,
            score = 72,
            pingMs = 35.0,
            jitterMs = 18.0,
            packetLossPercentage = 0.4,
            worstSpikeMs = 82.0,
            primaryWeight = "Variação de latência (jitter)",
            suitableUses = listOf("Casual", "Party"),
            latencySeries = emptyList(),
            findings = emptyList()
        )

        assertThat(item.formattedDate).isEqualTo("Agora")
    }
}
