package com.lagcheck.domain.model

/**
 * Amostra individual de probe UDP (STUN / Game Beacon).
 */
data class ProbeSample(
    val sequenceNumber: Int,
    val roundTripMillis: Double?,
    val outcome: Outcome,
    val isOutOfOrder: Boolean = false
) {
    enum class Outcome {
        SUCCESS,
        TIMEOUT,
        INVALID_RESPONSE,
        SOCKET_ERROR
    }

    val isValidResponse: Boolean
        get() = outcome == Outcome.SUCCESS && roundTripMillis != null && roundTripMillis > 0
}
