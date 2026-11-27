package com.lagcheck.android

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onLast
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import com.lagcheck.android.data.CheckHistoryItem
import com.lagcheck.android.ui.history.HistoryScreen
import com.lagcheck.android.ui.verdict.VerdictScreen
import androidx.compose.material3.MaterialTheme
import com.lagcheck.domain.model.GameReadinessEvaluation
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.OfficialGameCatalog
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

/**
 * Smoke tests controlados para Veredito, estado inconclusivo/erro e Histórico.
 */
class VerdictAndHistorySmokeTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun rendersReadyVerdictAndTriggersActions() {
        var retried = false
        var openedDetails = false
        val evaluation = GameReadinessEvaluation(
            verdict = GameReadinessVerdict.READY,
            headline = "PRONTO PARA RANKED",
            subtitle = "Sua conexão está estável para jogar agora.",
            pingMs = 24.0,
            jitterMs = 2.0,
            packetLossPercentage = 0.0,
            worstSpikeMs = 31.0,
            isUnderLoadAffected = false,
            findings = emptyList(),
            platform = "Mobile",
            connectionType = "Wi-Fi",
            regionLabel = "São Paulo"
        )

        composeRule.setContent {
            MaterialTheme {
                VerdictScreen(
                    game = OfficialGameCatalog.genericGaming,
                    evaluation = evaluation,
                    routeRegionId = null,
                    onRetry = { retried = true },
                    onDetails = { openedDetails = true },
                    onClose = {}
                )
            }
        }

        composeRule.onNodeWithText("PRONTO PARA RANKED").assertIsDisplayed()
        composeRule.onNodeWithText("Testar novamente").performClick()
        composeRule.onNodeWithText("Ver detalhes").performClick()
        assertTrue(retried)
        assertTrue(openedDetails)
    }

    @Test
    fun rendersInconclusiveVerdictSafely() {
        val evaluation = GameReadinessEvaluation(
            verdict = GameReadinessVerdict.INCONCLUSIVE,
            headline = "DADOS INSUFICIENTES",
            subtitle = "Não houve respostas suficientes para avaliar a conexão.",
            pingMs = null,
            jitterMs = null,
            packetLossPercentage = null,
            worstSpikeMs = null,
            isUnderLoadAffected = false,
            findings = emptyList(),
            platform = "Mobile",
            connectionType = "Wi-Fi"
        )

        composeRule.setContent {
            MaterialTheme {
                VerdictScreen(
                    game = OfficialGameCatalog.genericGaming,
                    evaluation = evaluation,
                    routeRegionId = null,
                    onRetry = {},
                    onDetails = {},
                    onClose = {}
                )
            }
        }

        composeRule.onNodeWithText("DADOS INSUFICIENTES").assertIsDisplayed()
        composeRule.onNodeWithText("Testar novamente").assertIsDisplayed()
    }

    @Test
    fun rendersHistoryListAndOpensSelectedItem() {
        var selectedItem: CheckHistoryItem? = null
        val sample = CheckHistoryItem(
            gameId = "fortnite",
            gameName = "Fortnite",
            platform = "Mobile",
            connectionType = "Wi-Fi",
            timestamp = System.currentTimeMillis(),
            verdict = GameReadinessVerdict.READY,
            score = 92,
            pingMs = 22.0,
            jitterMs = 2.0,
            packetLossPercentage = 0.0,
            worstSpikeMs = 28.0,
            primaryWeight = "Rota estável",
            suitableUses = listOf("Ranked"),
            latencySeries = listOf(22.0, 23.0, 21.0),
            findings = emptyList()
        )

        composeRule.setContent {
            MaterialTheme {
                HistoryScreen(
                    catalogGames = listOf(OfficialGameCatalog.findById("fortnite")),
                    historyItems = listOf(sample),
                    onBack = {},
                    onSelectCheck = { selectedItem = it },
                    onClearHistory = {},
                    onGoToHome = {}
                )
            }
        }

        composeRule.onNodeWithText("HISTÓRICO").assertIsDisplayed()
        composeRule.onAllNodesWithText("22 ms", substring = true).onLast().assertIsDisplayed().performClick()
        assertTrue(selectedItem?.gameId == "fortnite")
    }
}
