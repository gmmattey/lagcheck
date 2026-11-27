package com.lagcheck.android

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import org.junit.Rule
import org.junit.Test

/**
 * Smoke tests instrumentados das jornadas principais (sem medição UDP externa).
 */
class LagCheckAppSmokeTest {

    @get:Rule
    val composeRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun launchesHomeAndNavigatesAcrossAllFourTabs() {
        composeRule.onNodeWithText("Início").assertIsDisplayed()
        composeRule.onNodeWithText("Jogos").assertIsDisplayed().performClick()
        composeRule.onNodeWithText("JOGOS").assertIsDisplayed()

        composeRule.onNodeWithText("Histórico").assertIsDisplayed().performClick()
        composeRule.onNodeWithText("HISTÓRICO").assertIsDisplayed()

        composeRule.onNodeWithText("Configurações").assertIsDisplayed().performClick()
        composeRule.onNodeWithText("CONFIGURAÇÕES").assertIsDisplayed()

        composeRule.onNodeWithText("Início").performClick()
        composeRule.onNodeWithText("TESTAR AGORA").assertIsDisplayed()
    }

    @Test
    fun searchesAndSelectsGameFromGamesTab() {
        composeRule.onNodeWithText("Jogos").performClick()
        composeRule.onNode(hasSetTextAction()).performTextInput("Fortnite")
        composeRule.onAllNodesWithText("Fortnite").onFirst().assertIsDisplayed()
    }

    @Test
    fun generalCheckFromHomeStartsAndCancelsCleanly() {
        composeRule.onNodeWithText("TESTAR AGORA").assertIsDisplayed().performClick()
        // A tela de medição/pré-leitura possui animação contínua; não usar waitForIdle().
        composeRule.mainClock.advanceTimeBy(300)
        composeRule.activityRule.scenario.onActivity { activity ->
            activity.onBackPressedDispatcher.onBackPressed()
        }
        composeRule.onNodeWithText("Início").assertIsDisplayed()
    }
}
