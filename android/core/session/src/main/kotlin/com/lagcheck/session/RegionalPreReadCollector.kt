package com.lagcheck.session

import com.lagcheck.domain.model.ProbeOutcome
import com.lagcheck.domain.rules.RegionalPreReadSample
import com.lagcheck.network.transport.ProbePlan
import com.lagcheck.network.transport.UdpProbeTransport

interface RegionalPreReadCollecting {
    suspend fun collect(candidate: ResolvedCandidate): List<RegionalPreReadSample>
}

class RegionalPreReadCollector(
    private val transport: UdpProbeTransport = UdpProbeTransport()
) : RegionalPreReadCollecting {

    override suspend fun collect(candidate: ResolvedCandidate): List<RegionalPreReadSample> {
        val plan = ProbePlan(
            count = 3,
            intervalMillis = 1000L,
            closureMillis = 4000L,
            probeTimeoutMillis = 2000L,
            abortOnPoorQuality = false
        )
        val collection = transport.collect(candidate.resolvedContext.destination, plan)
        return collection.samples.filter { it.sequence >= 0 }.map { sample ->
            RegionalPreReadSample(
                outcome = sample.outcome,
                roundTripMilliseconds = sample.roundTripMilliseconds
            )
        }
    }
}
