package com.lagcheck.network.transport

import com.lagcheck.domain.model.ProbeOutcome
import com.lagcheck.domain.model.ProbeSample

/**
 * Livro-razão de probes: correlaciona cada resposta com o probe enviado mais antigo ainda sem resultado,
 * dentro de 2 s, e só aceita eco íntegro segundo o validador do protocolo (port de `ProbeLedger`, Swift).
 */
class ProbeLedger(
    probes: List<Pair<Int, ByteArray>>,
    private val timeoutNanos: Long = 2_000_000_000L,
    private val isCorrelatedResponse: (request: ByteArray, response: ByteArray) -> Boolean
) {
    private class Pending(var payload: ByteArray, var sentAt: Long? = null, var result: ProbeSample? = null)

    private val lock = Any()
    private val probes: MutableMap<Int, Pending> = probes.associate { it.first to Pending(it.second) }.toMutableMap()
    private var invalidResponseCount = 0
    private var receivedCount = 0

    fun register(sequence: Int, payload: ByteArray, sentAtNanos: Long) = synchronized(lock) {
        probes[sequence]?.let { it.payload = payload; it.sentAt = sentAtNanos }
        Unit
    }

    /** Devolve a amostra correlacionada, ou null (resposta inválida, tardia ou duplicada conta como diagnóstico). */
    fun accept(response: ByteArray, receivedAtNanos: Long): ProbeSample? = synchronized(lock) {
        val match = probes.entries
            .filter { (_, p) ->
                val sent = p.sentAt
                sent != null && p.result == null && receivedAtNanos >= sent && receivedAtNanos - sent < timeoutNanos
            }
            .sortedBy { it.value.sentAt }
            .firstOrNull { isCorrelatedResponse(it.value.payload, response) }
        if (match == null) {
            invalidResponseCount += 1
            return null
        }
        val arrival = receivedCount++
        val sample = ProbeSample(
            sequence = match.key,
            roundTripMilliseconds = (receivedAtNanos - match.value.sentAt!!) / 1_000_000.0,
            outcome = ProbeOutcome.RECEIVED,
            arrivalIndex = arrival
        )
        match.value.result = sample
        sample
    }

    fun markTransportError(sequence: Int) = synchronized(lock) {
        val p = probes[sequence] ?: return@synchronized
        if (p.sentAt != null && p.result == null) p.result = ProbeSample(sequence, outcome = ProbeOutcome.TRANSPORT_ERROR)
    }

    /** Estado parcial para o watchdog: probes sem resposta e já vencidos viram timeout; os recentes ainda não contam. */
    fun snapshot(nowNanos: Long): List<ProbeSample> = synchronized(lock) {
        probes.keys.sorted().mapNotNull { seq ->
            val p = probes.getValue(seq)
            val sent = p.sentAt ?: return@mapNotNull null
            p.result ?: if (nowNanos - sent >= timeoutNanos) ProbeSample(seq, outcome = ProbeOutcome.TIMEOUT) else null
        }
    }

    /** Fecha a medição: o que não respondeu é timeout. Respostas inválidas viram diagnóstico separado (sequence = -1). */
    fun finish(): List<ProbeSample> = synchronized(lock) {
        val planned = probes.keys.sorted().map { seq -> probes.getValue(seq).result ?: ProbeSample(seq, outcome = ProbeOutcome.TIMEOUT) }
        planned + List(invalidResponseCount) { ProbeSample(-1, outcome = ProbeOutcome.INVALID_RESPONSE) }
    }
}
