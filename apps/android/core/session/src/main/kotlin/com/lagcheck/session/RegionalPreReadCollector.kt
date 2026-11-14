package com.lagcheck.session

import com.lagcheck.domain.model.ProbeOutcome
import com.lagcheck.domain.rules.RegionalPreReadSample
import com.lagcheck.network.transport.ProbePlan
import com.lagcheck.network.transport.ProbeProgress
import com.lagcheck.network.transport.UdpProbeTransport

/**
 * Evento de uma sonda da pré-leitura, emitido no instante em que acontece. Serve só para apresentação (mapa de
 * medição); a decisão continua vindo das amostras devolvidas por `collect`. Espelha `RegionalPreReadEvent` do iOS.
 */
sealed class RegionalPreReadEvent {
    data object Sent : RegionalPreReadEvent()
    data class Answered(val rttMs: Double) : RegionalPreReadEvent()
    data object Unanswered : RegionalPreReadEvent()
}

interface RegionalPreReadCollecting {
    suspend fun collect(candidate: ResolvedCandidate): List<RegionalPreReadSample>
}

class RegionalPreReadCollector(
    private val transport: UdpProbeTransport = UdpProbeTransport(),
    /** Recebe cada envio e cada resposta real (pode ser chamado fora da thread principal). */
    private val onEvent: ((regionId: String, event: RegionalPreReadEvent) -> Unit)? = null
) : RegionalPreReadCollecting {

    override suspend fun collect(candidate: ResolvedCandidate): List<RegionalPreReadSample> {
        val plan = ProbePlan(
            count = 3,
            intervalMillis = 1000L,
            closureMillis = 4000L,
            probeTimeoutMillis = 2000L,
            abortOnPoorQuality = false
        )
        val regionId = candidate.regionId
        val collection = transport.collect(candidate.resolvedContext.destination, plan) { event ->
            when (event) {
                is ProbeProgress.Sent -> onEvent?.invoke(regionId, RegionalPreReadEvent.Sent)
                is ProbeProgress.Received -> event.sample.roundTripMilliseconds
                    ?.takeIf { event.sample.isValidResponse }
                    ?.let { onEvent?.invoke(regionId, RegionalPreReadEvent.Answered(it)) }
            }
        }
        val samples = collection.samples.filter { it.sequence >= 0 }
        samples.filterNot { it.isValidResponse }.forEach { onEvent?.invoke(regionId, RegionalPreReadEvent.Unanswered) }
        return samples.map { sample ->
            RegionalPreReadSample(
                outcome = sample.outcome,
                roundTripMilliseconds = sample.roundTripMilliseconds
            )
        }
    }
}
