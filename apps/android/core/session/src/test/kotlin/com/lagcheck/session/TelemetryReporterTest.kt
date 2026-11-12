package com.lagcheck.session

import com.google.common.truth.Truth.assertThat
import com.lagcheck.catalog.Platform
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.network.worker.TelemetryEvent
import com.lagcheck.network.worker.TelemetryPlatform
import com.lagcheck.network.worker.TelemetryVerdict
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import org.junit.Test

class TelemetryReporterTest {
    private data class Sent(val id: String, val event: TelemetryEvent, val game: String?, val platform: TelemetryPlatform?, val verdict: TelemetryVerdict?)

    private val ids = object : InstallationIdStore { override fun getOrCreate() = "123e4567-e89b-42d3-a456-426614174000" }

    @Test fun funnelEventsCarryOnlyAnonymousFields() = runTest(UnconfinedTestDispatcher()) {
        val sent = mutableListOf<Sent>()
        val r = TelemetryReporter(this, ids) { id, e, g, p, v -> sent += Sent(id, e, g, p, v); true }
        r.appOpen()
        r.checkStarted("Fortnite", Platform.PC)
        r.verdictViewed("fortnite", Platform.PC, GameReadinessVerdict.NOT_READY)
        r.retestStarted("fortnite", Platform.PLAYSTATION)
        assertThat(sent.map { it.event }).containsExactly(
            TelemetryEvent.APP_OPEN, TelemetryEvent.CHECK_STARTED, TelemetryEvent.VERDICT_VIEWED, TelemetryEvent.RETEST_STARTED
        ).inOrder()
        assertThat(sent.all { it.id == "123e4567-e89b-42d3-a456-426614174000" }).isTrue()
        assertThat(sent[0].game).isNull()
        assertThat(sent[1].game).isEqualTo("fortnite")
        assertThat(sent[2].verdict).isEqualTo(TelemetryVerdict.NOT_READY)
        assertThat(sent[3].platform).isEqualTo(TelemetryPlatform.PLAYSTATION)
    }

    @Test fun mobileAndNintendoOmitThePlatformBecauseTheWorkerRejectsThem() = runTest(UnconfinedTestDispatcher()) {
        val sent = mutableListOf<Sent>()
        val r = TelemetryReporter(this, ids) { id, e, g, p, v -> sent += Sent(id, e, g, p, v); true }
        r.checkStarted("free-fire", Platform.MOBILE)
        r.checkStarted("fortnite", Platform.NINTENDO)
        assertThat(sent.map { it.platform }).containsExactly(null, null)
    }

    @Test fun failureOrExceptionNeverReachesTheCaller() = runTest(UnconfinedTestDispatcher()) {
        val r = TelemetryReporter(this, ids) { _, _, _, _, _ -> throw java.io.IOException("offline") }
        r.appOpen() // não deve lançar
        val throwingIds = object : InstallationIdStore { override fun getOrCreate(): String = error("prefs corrompidas") }
        TelemetryReporter(this, throwingIds) { _, _, _, _, _ -> true }.appOpen()
    }
}
