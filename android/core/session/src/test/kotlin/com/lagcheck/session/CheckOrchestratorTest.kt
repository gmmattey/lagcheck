package com.lagcheck.session

import com.google.common.truth.Truth.assertThat
import com.lagcheck.catalog.GameContext
import com.lagcheck.catalog.MeasurementStrategy
import com.lagcheck.catalog.Platform
import com.lagcheck.catalog.ProbeDestination
import com.lagcheck.catalog.ProbeProtocolKind
import com.lagcheck.catalog.ResolvedMeasurementContext
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.InconclusiveReason
import com.lagcheck.domain.model.MeasurementConfidence
import com.lagcheck.domain.model.ProbeOutcome
import com.lagcheck.domain.model.ProbeSample
import com.lagcheck.domain.model.QualityProfileId
import com.lagcheck.network.transport.ProbeCollection
import com.lagcheck.network.transport.ProbeProgress
import com.lagcheck.network.worker.LoadOutcome
import java.util.concurrent.atomic.AtomicInteger
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import org.junit.Test

class CheckOrchestratorTest {
    private val ctx = ResolvedMeasurementContext(
        context = GameContext("fortnite", "BR", Platform.MOBILE),
        catalogVersion = "t", profileId = QualityProfileId.BATTLE_ROYALE_COMPETITIVE, profileRuleVersion = "pilot-2026.09.08.1",
        regionId = "sa-east-1", destination = ProbeDestination("h", 7770, ProbeProtocolKind.GAMELIFT_PING),
        strategy = MeasurementStrategy.GENERIC_REGION, confidence = MeasurementConfidence.MEDIUM, precisionKey = "regionalReference"
    )

    private fun good(rtt: Double) = ProbeCollection(List(30) { ProbeSample(it, rtt, ProbeOutcome.RECEIVED) }, null)
    private fun dead() = ProbeCollection(List(30) { ProbeSample(it, outcome = ProbeOutcome.TIMEOUT) }, null)
    private fun aborted() = ProbeCollection(List(6) { ProbeSample(it, outcome = ProbeOutcome.TIMEOUT) }, InconclusiveReason.POOR_SAMPLE_QUALITY)

    /** Entrega uma coleção por chamada, na ordem: repouso, depois carga. */
    private fun script(vararg phases: ProbeCollection): ProbeCollector {
        val i = AtomicInteger()
        return ProbeCollector { _, _, onProgress ->
            val c = phases[i.getAndIncrement()]
            c.samples.forEach { s ->
                onProgress(ProbeProgress.Sent(s.sequence, 30))
                if (s.isValidResponse) onProgress(ProbeProgress.Received(s))
            }
            c
        }
    }

    @Test fun cleanRouteIsReadyWithMeasuredLoad() = runBlocking {
        val r = CheckOrchestrator(script(good(30.0), good(32.0)), { LoadOutcome.Completed(10_000_000) }).run(ctx)
        assertThat(r.assessment.verdict).isEqualTo(GameReadinessVerdict.READY)
        assertThat(r.loadMeasured).isTrue()
        assertThat(r.abortReason).isNull()
        assertThat(r.latencySeries).hasSize(60)
        assertThat(r.assessment.score).isEqualTo(100)
    }

    @Test fun bufferbloatUnderLoadDemotesTheVerdict() = runBlocking {
        val r = CheckOrchestrator(script(good(30.0), good(95.0)), { LoadOutcome.Completed(10_000_000) }).run(ctx)
        assertThat(r.assessment.verdict).isEqualTo(GameReadinessVerdict.NOT_READY)
        assertThat(r.assessment.isUnderLoadAffected).isTrue()
    }

    @Test fun loadUnavailableKeepsTheRestVerdictAndDropsLoadSamples() = runBlocking {
        val r = CheckOrchestrator(script(good(30.0), good(500.0)), { LoadOutcome.Unavailable }).run(ctx)
        assertThat(r.assessment.verdict).isEqualTo(GameReadinessVerdict.READY)
        assertThat(r.loadSamples).isNull()
        assertThat(r.loadMeasured).isFalse()
    }

    @Test fun noUdpAnswersIsInconclusiveNeverAFallbackScore() = runBlocking {
        val r = CheckOrchestrator(script(dead(), good(30.0)), { LoadOutcome.Completed(1) }).run(ctx)
        assertThat(r.assessment.verdict).isEqualTo(GameReadinessVerdict.INCONCLUSIVE)
        assertThat(r.assessment.score).isNull()
        assertThat(r.assessment.pingMs).isNull()
    }

    @Test fun deadConnectionInRestSkipsTheLoadPhaseEntirely() = runBlocking {
        var loadCalls = 0
        val r = CheckOrchestrator(script(aborted()), { loadCalls++; LoadOutcome.Completed(1) }).run(ctx)
        assertThat(r.assessment.verdict).isEqualTo(GameReadinessVerdict.INCONCLUSIVE)
        assertThat(r.abortReason).isEqualTo(InconclusiveReason.POOR_SAMPLE_QUALITY)
        assertThat(loadCalls).isEqualTo(0)
    }

    @Test fun connectionThatDiesUnderLoadCancelsTheWholeSession() = runBlocking {
        val r = CheckOrchestrator(script(good(30.0), aborted()), { LoadOutcome.Completed(1) }).run(ctx)
        assertThat(r.assessment.verdict).isEqualTo(GameReadinessVerdict.INCONCLUSIVE)
        assertThat(r.abortReason).isEqualTo(InconclusiveReason.POOR_SAMPLE_QUALITY)
    }

    @Test fun progressIsMonotonicAcrossBothPhasesAndReportsPing() = runBlocking {
        val seen = mutableListOf<CheckProgress>()
        CheckOrchestrator(script(good(30.0), good(30.0)), { LoadOutcome.Completed(1) }).run(ctx) { seen += it }
        val ratios = seen.map { it.ratio }
        assertThat(ratios).isInOrder()
        assertThat(ratios.first()).isGreaterThan(0f)
        assertThat(ratios.last()).isWithin(1e-6f).of(1f)
        assertThat(seen.first().phase).isEqualTo(CheckPhase.REST)
        assertThat(seen.last().phase).isEqualTo(CheckPhase.LOAD)
        assertThat(seen.any { it.latestPingMs == 30.0 }).isTrue()
        assertThat(seen.filter { it.phase == CheckPhase.REST }.maxOf { it.ratio }).isAtMost(0.5f + 1e-6f)
    }

    @Test fun loadTransferRunsConcurrentlyWithTheLoadProbesNotTheRestProbes() = runBlocking {
        val order = java.util.Collections.synchronizedList(mutableListOf<String>())
        val collector = ProbeCollector { _, _, _ -> order += "probes"; delay(100); good(30.0) }
        val orchestrator = CheckOrchestrator(collector, { order += "load-start"; delay(50); order += "load-end"; LoadOutcome.Completed(1) })
        orchestrator.run(ctx)
        // repouso, depois (carga + probes de carga em paralelo)
        assertThat(order.first()).isEqualTo("probes")
        assertThat(order.indexOf("load-start")).isGreaterThan(0)
        assertThat(order.count { it == "probes" }).isEqualTo(2)
    }

    @Test fun cancellationDiscardsEverythingAndStopsLoad() = runBlocking {
        val loadCancelled = CompletableDeferred<Boolean>()
        val started = CompletableDeferred<Unit>()
        val i = AtomicInteger()
        val collector = ProbeCollector { _, _, _ ->
            if (i.getAndIncrement() == 0) good(30.0) else { started.complete(Unit); delay(60_000); good(30.0) }
        }
        val load = LoadTransfer { try { delay(60_000); LoadOutcome.Unavailable } catch (e: kotlinx.coroutines.CancellationException) { loadCancelled.complete(true); throw e } }
        val job = async { CheckOrchestrator(collector, load).run(ctx) }
        started.await()
        job.cancelAndJoin()
        assertThat(job.isCancelled).isTrue()
        assertThat(loadCancelled.await()).isTrue()
    }

    @Test fun orchestratorUsesTheProfileOfTheResolvedContext() = runBlocking {
        // 120 ms: guardrail do perfil competitivo (100) reprova; o do casual (180) aprova.
        val casual = ctx.copy(profileId = QualityProfileId.CASUAL_REALTIME)
        assertThat(CheckOrchestrator(script(good(120.0), good(120.0)), { LoadOutcome.Completed(1) }).run(ctx).assessment.verdict)
            .isEqualTo(GameReadinessVerdict.NOT_READY)
        assertThat(CheckOrchestrator(script(good(120.0), good(120.0)), { LoadOutcome.Completed(1) }).run(casual).assessment.verdict)
            .isEqualTo(GameReadinessVerdict.READY)
    }
}
