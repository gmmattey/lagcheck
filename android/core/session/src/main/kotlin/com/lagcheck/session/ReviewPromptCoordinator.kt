package com.lagcheck.session

import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.ReviewPromptState
import com.lagcheck.domain.rules.ReviewPromptPolicy

/**
 * Interface desacoplada de persistência para o estado de review na sessão Android (Decisão 77).
 */
interface ReviewPromptStore {
    fun loadState(): ReviewPromptState
    fun saveState(state: ReviewPromptState)
}

/**
 * Implementação em memória para testes e isolamento.
 */
class InMemoryReviewPromptStore(
    initialState: ReviewPromptState = ReviewPromptState()
) : ReviewPromptStore {
    private var state = initialState

    @Synchronized
    override fun loadState(): ReviewPromptState = state

    @Synchronized
    override fun saveState(state: ReviewPromptState) {
        this.state = state
    }
}

/**
 * Coordenador de sessão para avaliação in-app na Google Play Store (Decisão 77).
 * Mantém paridade de comportamento estrita com a versão iOS.
 */
class ReviewPromptCoordinator(
    private val store: ReviewPromptStore,
    private val appVersionProvider: () -> String
) {
    @Synchronized
    fun recordMeasurementCompleted(
        verdict: GameReadinessVerdict,
        nowEpochMillis: Long = System.currentTimeMillis()
    ): Boolean {
        var state = store.loadState()
        if (verdict == GameReadinessVerdict.READY) {
            state = state.copy(successfulReadyChecksCount = state.successfulReadyChecksCount + 1)
        }

        val currentVersion = appVersionProvider()
        val shouldPrompt = ReviewPromptPolicy.shouldPrompt(
            verdict = verdict,
            state = state,
            currentAppVersion = currentVersion,
            currentEpochMillis = nowEpochMillis
        )

        store.saveState(state)
        return shouldPrompt
    }

    /**
     * Registra que o diálogo de review foi de fato apresentado na Google Play Store.
     * Evita consumir o cooldown e limite de versão se o usuário sair da tela antes dos 1.5s.
     */
    @Synchronized
    fun recordPromptPresented(
        nowEpochMillis: Long = System.currentTimeMillis()
    ) {
        var state = store.loadState()
        state = state.copy(
            lastPromptedEpochMillis = nowEpochMillis,
            lastPromptedVersion = appVersionProvider()
        )
        store.saveState(state)
    }

    @Synchronized
    fun currentState(): ReviewPromptState = store.loadState()
}
