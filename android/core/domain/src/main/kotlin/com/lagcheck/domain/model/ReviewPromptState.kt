package com.lagcheck.domain.model

/**
 * Estado persistido para avaliação de disparo do prompt de review no Android (Decisão 77).
 * Mantém paridade determinística 1:1 com a implementação iOS.
 */
data class ReviewPromptState(
    val successfulReadyChecksCount: Int = 0,
    val lastPromptedEpochMillis: Long? = null,
    val lastPromptedVersion: String? = null
)
