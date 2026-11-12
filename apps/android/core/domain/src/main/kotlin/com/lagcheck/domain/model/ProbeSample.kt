package com.lagcheck.domain.model

enum class ProbeOutcome { RECEIVED, TIMEOUT, TRANSPORT_ERROR, INVALID_RESPONSE }

/**
 * Amostra já classificada pelo transporte. Port de `ProbeSample` (Swift).
 * `arrivalIndex` é a ordem de chegada; `sequence` é a ordem de envio (RFC 4737).
 */
data class ProbeSample(
    val sequence: Int,
    val roundTripMilliseconds: Double? = null,
    val outcome: ProbeOutcome,
    val arrivalIndex: Int? = null
) {
    val isValidResponse: Boolean
        get() = outcome == ProbeOutcome.RECEIVED && roundTripMilliseconds != null
}

object ProbeAcceptancePolicy {
    const val PLANNED_PROBE_COUNT = 30
    const val SEND_INTERVAL_MILLIS = 500L
    const val TIMEOUT_MILLIS = 2_000L
    const val CLOSURE_MILLIS = 17_000L
    const val MINIMUM_VALID_RESPONSES = 10

    /** Classifica somente tempo. A correlação do payload pertence ao transporte. */
    fun outcome(sentAtSeconds: Double, receivedAtSeconds: Double): ProbeOutcome {
        val elapsed = receivedAtSeconds - sentAtSeconds
        return if (elapsed >= 0 && elapsed < TIMEOUT_MILLIS / 1000.0 && receivedAtSeconds <= CLOSURE_MILLIS / 1000.0)
            ProbeOutcome.RECEIVED else ProbeOutcome.TIMEOUT
    }
}
