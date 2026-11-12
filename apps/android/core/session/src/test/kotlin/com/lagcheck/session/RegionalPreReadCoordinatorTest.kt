package com.lagcheck.session

import com.lagcheck.catalog.GameContext
import com.lagcheck.catalog.Platform
import com.lagcheck.catalog.ProbeDestination
import com.lagcheck.catalog.ProbeProtocolKind
import com.lagcheck.catalog.ResolvedMeasurementContext
import com.lagcheck.domain.rules.RegionalPreReadSample
import com.lagcheck.domain.rules.RegionalSelectionSnapshot
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlinx.coroutines.CancellationException

class RegionalPreReadCoordinatorTest {

    class FakeCollector(val block: suspend () -> List<RegionalPreReadSample> = { emptyList() }) : RegionalPreReadCollecting {
        var started = false
        var completed = false
        override suspend fun collect(candidate: ResolvedCandidate): List<RegionalPreReadSample> {
            started = true
            try {
                return block()
            } finally {
                completed = true
            }
        }
    }

    private val defaultContext = GameContext("test", "BR", Platform.MOBILE)
    private val defaultDest = ProbeDestination("127.0.0.1", 1234, ProbeProtocolKind.GAMELIFT_PING)
    private val defaultResolved = ResolvedMeasurementContext(
        context = defaultContext,
        catalogVersion = "v1",
        profileId = com.lagcheck.domain.model.QualityProfileId.MOBILE_REALTIME,
        profileRuleVersion = "v1",
        regionId = "test-region",
        destination = defaultDest,
        strategy = com.lagcheck.catalog.MeasurementStrategy.GENERIC_REGION,
        confidence = com.lagcheck.domain.model.MeasurementConfidence.HIGH,
        precisionKey = "key"
    )

    private fun candidate(id: String, priority: Int = 1) = ResolvedCandidate(
        regionId = id,
        priority = priority,
        catalogVersion = "v1",
        context = defaultContext,
        resolvedContext = defaultResolved.copy(regionId = id)
    )

    private fun snapshot(vararg candidates: ResolvedCandidate) = RegionalSelectionSnapshot(
        catalogVersion = "v1",
        context = defaultContext,
        candidates = candidates.toList()
    )

    @Test
    fun `cancellation of coordinator propagates to collector`() = runTest {
        var cancelled = false
        val collector = FakeCollector {
            try {
                delay(10000)
                emptyList()
            } catch (e: CancellationException) {
                cancelled = true
                throw e
            }
        }
        val coordinator = RegionalPreReadCoordinator(collector)
        val snap = snapshot(candidate("us-east"))

        val job = launch {
            coordinator.select(snap)
        }

        delay(100)
        assertTrue(collector.started)

        job.cancelAndJoin()

        assertTrue(cancelled)
        assertTrue(collector.completed)
    }
}
