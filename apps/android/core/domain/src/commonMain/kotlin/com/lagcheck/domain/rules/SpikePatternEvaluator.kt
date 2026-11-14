package com.lagcheck.domain.rules

import com.lagcheck.domain.model.ProbeSample
import com.lagcheck.domain.model.QualityProfileId
import com.lagcheck.domain.model.SpikePattern

/** Distribuição temporal de spikes (spike-pattern-v2), sempre na ordem de envio. */
object SpikePatternEvaluator {
    const val VERSION = "spike-pattern-v2"

    fun evaluate(samples: List<ProbeSample>, p50Milliseconds: Double, profile: QualityProfileId): SpikePattern {
        val limits = QualityEvaluator.spikeLimits(profile)
        return evaluate(
            samples = samples,
            p50Milliseconds = p50Milliseconds,
            spikeDelta = limits.offset,
            spikeAbsoluteMin = limits.floor,
            severeDelta = limits.severeOffset,
            severeAbsoluteMin = limits.severeFloor
        )
    }

    fun evaluate(
        samples: List<ProbeSample>,
        p50Milliseconds: Double,
        spikeDelta: Double = 30.0,
        spikeAbsoluteMin: Double = 80.0,
        severeDelta: Double = 80.0,
        severeAbsoluteMin: Double = 150.0
    ): SpikePattern {
        if (samples.none { it.isValidResponse }) return SpikePattern.None

        var totalSpikes = 0
        var totalSevere = 0
        val flags = mutableListOf<Boolean>()
        for (sample in samples.sortedBy { it.sequence }) {
            val rtt = sample.roundTripMilliseconds
            if (!sample.isValidResponse || rtt == null) { flags += false; continue }
            val isSevere = rtt > p50Milliseconds + severeDelta && rtt >= severeAbsoluteMin
            val isSpike = isSevere || (rtt > p50Milliseconds + spikeDelta && rtt >= spikeAbsoluteMin)
            if (isSpike) totalSpikes += 1
            if (isSevere) totalSevere += 1
            flags += isSpike
        }
        if (totalSpikes == 0) return SpikePattern.None
        if (totalSpikes >= 3) return SpikePattern.Recurring(totalSpikes, totalSevere)

        if (flags.size >= 2) {
            for (i in flags.indices) {
                val end = minOf(i + 5, flags.size)
                if (flags.subList(i, end).count { it } >= 2) return SpikePattern.Recurring(totalSpikes, totalSevere)
            }
        }
        return SpikePattern.Isolated(totalSpikes, totalSevere)
    }
}
