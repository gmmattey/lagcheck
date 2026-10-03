package com.lagcheck.session

import com.lagcheck.domain.rules.RegionalSelectionDecision
import com.lagcheck.domain.rules.RegionalSelectionError
import com.lagcheck.domain.rules.RegionalSelectionRule
import com.lagcheck.domain.rules.RegionalSelectionSnapshot
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.ensureActive
import kotlin.coroutines.coroutineContext

class RegionalPreReadCoordinator(
    private val collector: RegionalPreReadCollecting = RegionalPreReadCollector()
) {
    suspend fun select(
        snapshot: RegionalSelectionSnapshot<com.lagcheck.catalog.GameContext, ResolvedCandidate>,
        manualRegionId: String? = null
    ): RegionalSelectionDecision<com.lagcheck.catalog.GameContext, ResolvedCandidate> = coroutineScope {
        val candidates = if (manualRegionId != null) {
            val c = snapshot.candidates.firstOrNull { it.regionId == manualRegionId }
                ?: throw RegionalSelectionError("manualCandidateNotAllowed")
            listOf(c)
        } else {
            snapshot.candidates
        }

        if (manualRegionId != null && candidates.isEmpty()) {
            throw RegionalSelectionError("manualCandidateNotAllowed")
        }

        val deferreds = candidates.map { candidate ->
            async {
                val samples = collector.collect(candidate)
                candidate.regionId to samples
            }
        }

        val results = deferreds.awaitAll()
        coroutineContext.ensureActive()

        val preReadSamples = results.toMap()
        RegionalSelectionRule.select(snapshot, preReadSamples, manualRegionId)
    }
}
