package com.lagcheck.domain.rules

import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.ReviewPromptState

/**
 * Política de negócio pura para elegibilidade do prompt de review na Google Play Store (Decisão 77).
 * Garante momento de delight estrito (READY), contagem mínima e proteção contra fadiga do jogador.
 * Paridade determinística estrita com o iOS (Decisões 67 e 68).
 */
object ReviewPromptPolicy {
    /** Mínimo de medições completas com veredito positivo para demonstrar valor real. */
    const val REQUIRED_SUCCESSFUL_READY_CHECKS: Int = 3

    /** Intervalo de cooldown entre prompts (90 dias em milissegundos). */
    const val COOLDOWN_MILLIS: Long = 90L * 24L * 3600L * 1000L

    fun shouldPrompt(
        verdict: GameReadinessVerdict,
        state: ReviewPromptState,
        currentAppVersion: String,
        currentEpochMillis: Long
    ): Boolean {
        // 1. Momento de delight obrigatório: estritamente READY (Pronto para Ranked)
        if (verdict != GameReadinessVerdict.READY) return false

        // 2. Prova de valor: acúmulo mínimo de 3 medições bem-sucedidas
        if (state.successfulReadyChecksCount < REQUIRED_SUCCESSFUL_READY_CHECKS) return false

        // 3. Proteção de versão: no máximo 1 solicitação por versão/build do app
        if (state.lastPromptedVersion != null && state.lastPromptedVersion == currentAppVersion) {
            return false
        }

        // 4. Cooldown de 90 dias entre solicitações
        val lastPrompt = state.lastPromptedEpochMillis
        if (lastPrompt != null && (currentEpochMillis - lastPrompt) < COOLDOWN_MILLIS) {
            return false
        }

        return true
    }
}
