package com.lagcheck.domain.rules

import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.ReviewPromptState
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ReviewPromptPolicyTest {
    private val baseEpochMillis = 1700000000000L

    @Test
    fun nonReadyVerdictNeverPrompts() {
        val nonReadyVerdicts = listOf(
            GameReadinessVerdict.CAUTION,
            GameReadinessVerdict.NOT_READY,
            GameReadinessVerdict.INCONCLUSIVE
        )
        val readyState = ReviewPromptState(
            successfulReadyChecksCount = 5,
            lastPromptedEpochMillis = null,
            lastPromptedVersion = null
        )

        for (verdict in nonReadyVerdicts) {
            val shouldPrompt = ReviewPromptPolicy.shouldPrompt(
                verdict = verdict,
                state = readyState,
                currentAppVersion = "1.0.0",
                currentEpochMillis = baseEpochMillis
            )
            assertFalse("Veredito $verdict nunca deve disparar review prompt", shouldPrompt)
        }
    }

    @Test
    fun requiresAtLeastThreeSuccessfulReadyChecks() {
        for (count in 0 until 3) {
            val state = ReviewPromptState(
                successfulReadyChecksCount = count,
                lastPromptedEpochMillis = null,
                lastPromptedVersion = null
            )
            val shouldPrompt = ReviewPromptPolicy.shouldPrompt(
                verdict = GameReadinessVerdict.READY,
                state = state,
                currentAppVersion = "1.0.0",
                currentEpochMillis = baseEpochMillis
            )
            assertFalse("Não deve disparar com menos de 3 checks concluídos (count: $count)", shouldPrompt)
        }

        val eligibleState = ReviewPromptState(
            successfulReadyChecksCount = 3,
            lastPromptedEpochMillis = null,
            lastPromptedVersion = null
        )
        val shouldPrompt = ReviewPromptPolicy.shouldPrompt(
            verdict = GameReadinessVerdict.READY,
            state = eligibleState,
            currentAppVersion = "1.0.0",
            currentEpochMillis = baseEpochMillis
        )
        assertTrue("Deve autorizar no 3º check concluído com veredito READY", shouldPrompt)
    }

    @Test
    fun blocksSameVersionIfAlreadyPrompted() {
        val hundredDaysMillis = 100L * 24L * 3600L * 1000L
        val state = ReviewPromptState(
            successfulReadyChecksCount = 10,
            lastPromptedEpochMillis = baseEpochMillis - hundredDaysMillis,
            lastPromptedVersion = "1.0.0"
        )

        val shouldPromptSameVersion = ReviewPromptPolicy.shouldPrompt(
            verdict = GameReadinessVerdict.READY,
            state = state,
            currentAppVersion = "1.0.0",
            currentEpochMillis = baseEpochMillis
        )
        assertFalse("Não pode disparar na mesma versão onde já houve prompt", shouldPromptSameVersion)

        val shouldPromptNewVersion = ReviewPromptPolicy.shouldPrompt(
            verdict = GameReadinessVerdict.READY,
            state = state,
            currentAppVersion = "1.1.0",
            currentEpochMillis = baseEpochMillis
        )
        assertTrue("Deve permitir na nova versão após expirar o cooldown de 90 dias", shouldPromptNewVersion)
    }

    @Test
    fun respectsNinetyDaysCooldownBetweenPrompts() {
        val thirtyDaysMillis = 30L * 24L * 3600L * 1000L
        val lastPrompt = baseEpochMillis - thirtyDaysMillis
        val state = ReviewPromptState(
            successfulReadyChecksCount = 10,
            lastPromptedEpochMillis = lastPrompt,
            lastPromptedVersion = "0.9.0"
        )

        val shouldPromptBeforeCooldown = ReviewPromptPolicy.shouldPrompt(
            verdict = GameReadinessVerdict.READY,
            state = state,
            currentAppVersion = "1.0.0",
            currentEpochMillis = baseEpochMillis
        )
        assertFalse("Não pode disparar antes de completar 90 dias de cooldown", shouldPromptBeforeCooldown)

        val ninetyOneDaysMillis = 91L * 24L * 3600L * 1000L
        val shouldPromptAfterCooldown = ReviewPromptPolicy.shouldPrompt(
            verdict = GameReadinessVerdict.READY,
            state = state,
            currentAppVersion = "1.0.0",
            currentEpochMillis = lastPrompt + ninetyOneDaysMillis
        )
        assertTrue("Deve autorizar após 90 dias de cooldown em versão diferente", shouldPromptAfterCooldown)
    }
}
