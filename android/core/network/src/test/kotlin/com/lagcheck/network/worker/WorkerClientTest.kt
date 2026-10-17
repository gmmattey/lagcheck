package com.lagcheck.network.worker

import com.google.common.truth.Truth.assertThat
import com.lagcheck.catalog.CatalogSource
import com.lagcheck.catalog.RemoteCatalogRepository
import com.lagcheck.catalog.StoredCatalog
import com.lagcheck.catalog.CatalogCache
import com.sun.net.httpserver.HttpServer
import java.net.InetSocketAddress
import java.time.Instant
import java.util.concurrent.atomic.AtomicReference
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Test
import org.junit.Assert.assertThrows

class WorkerClientTest {
    private val server = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0)
    private val base get() = "http://127.0.0.1:${server.address.port}"

    @After fun stop() = server.stop(0)

    private fun route(path: String, status: Int = 200, body: ByteArray = ByteArray(0), contentType: String = "application/octet-stream", capture: AtomicReference<String>? = null) {
        server.createContext(path) { ex ->
            capture?.set(ex.requestMethod + " " + ex.requestHeaders.getFirst("Content-Type") + " " + String(ex.requestBody.readBytes()))
            ex.responseHeaders.add("Content-Type", contentType)
            ex.sendResponseHeaders(status, if (body.isEmpty()) -1 else body.size.toLong())
            if (body.isNotEmpty()) ex.responseBody.use { it.write(body) }
            ex.close()
        }
        server.start()
    }

    @Test fun defaultTelemetryEndpointUsesTheActiveWorkerHost() {
        assertThat(WorkerEndpoints().telemetryUrl)
            .isEqualTo("https://nolaggy-deep-check.buildealabs.workers.dev/v1/telemetry")
    }

    @Test fun catalogFetchReturnsEnvelopeBytes() = runBlocking {
        route("/v1/catalog.json", body = """{"a":1}""".toByteArray(), contentType = "application/json")
        assertThat(HttpCatalogFetcher("$base/v1/catalog.json").fetchCatalog().toString(Charsets.UTF_8)).isEqualTo("""{"a":1}""")
    }

    @Test fun catalogFetchFailsOnHttpErrorSoTheCachedCatalogSurvives() {
        route("/v1/catalog.json", status = 503, body = "x".toByteArray())
        assertThrows(java.io.IOException::class.java) { runBlocking { HttpCatalogFetcher("$base/v1/catalog.json").fetchCatalog() } }
    }

    @Test fun catalogFetchRejectsOversizedBodies() {
        route("/v1/catalog.json", body = ByteArray(5_000))
        assertThrows(java.io.IOException::class.java) { runBlocking { HttpCatalogFetcher("$base/v1/catalog.json", maximumBytes = 1_000).fetchCatalog() } }
    }

    @Test fun loadStopsAtTheByteCap() = runBlocking {
        route("/v1/load", body = ByteArray(2 * 1024 * 1024))
        val out = HttpLoadTransport("$base/v1/load", maximumBytes = 512 * 1024).transfer()
        assertThat(out).isInstanceOf(LoadOutcome.Completed::class.java)
        assertThat((out as LoadOutcome.Completed).bytesTransferred).isAtLeast(512L * 1024)
    }

    @Test fun loadHttpErrorIsUnavailableNotAnException() = runBlocking {
        route("/v1/load", status = 500, body = "x".toByteArray())
        assertThat(HttpLoadTransport("$base/v1/load").transfer()).isEqualTo(LoadOutcome.Unavailable)
    }

    @Test fun loadUnreachableHostIsUnavailable() = runBlocking {
        server.start(); val dead = "http://127.0.0.1:1/v1/load"
        assertThat(HttpLoadTransport(dead).transfer()).isEqualTo(LoadOutcome.Unavailable)
    }

    @Test fun loadTimesOutAsUnavailable() = runBlocking {
        server.createContext("/v1/load") { ex -> Thread.sleep(2_000); ex.sendResponseHeaders(200, -1); ex.close() }
        server.start()
        val t0 = System.nanoTime()
        assertThat(HttpLoadTransport("$base/v1/load", maximumDurationMillis = 300).transfer()).isEqualTo(LoadOutcome.Unavailable)
        assertThat((System.nanoTime() - t0) / 1_000_000).isLessThan(1_500)
    }

    @Test fun telemetryPayloadMatchesTheWorkerContract() = runBlocking {
        val captured = AtomicReference<String>()
        route("/v1/telemetry", status = 200, body = """{"ok":true}""".toByteArray(), contentType = "application/json", capture = captured)
        val id = "123e4567-e89b-42d3-a456-426614174000"
        val ok = TelemetryClient("$base/v1/telemetry").send(id, TelemetryEvent.VERDICT_VIEWED, "Fortnite", TelemetryPlatform.PC, TelemetryVerdict.NOT_READY)
        assertThat(ok).isTrue()
        assertThat(captured.get()).isEqualTo(
            """POST application/json; charset=UTF-8 {"installationId":"$id","event":"verdict_viewed","gameId":"fortnite","platform":"pc","verdict":"not_ready"}"""
        )
    }

    @Test fun telemetryOmitsPlatformForAndroidMobile() {
        val id = "123e4567-e89b-42d3-a456-426614174000"
        val json = TelemetryClient.buildPayload(id, TelemetryEvent.CHECK_STARTED, "free-fire", null, null)!!
        assertThat(json).doesNotContain("platform")
        assertThat(json).doesNotContain("verdict")
    }

    @Test fun telemetryNeverLeavesTheDeviceWithAnInvalidPayload() {
        assertThat(TelemetryClient.buildPayload("not-a-uuid", TelemetryEvent.APP_OPEN, null, null, null)).isNull()
        assertThat(TelemetryClient.buildPayload("1-1-1-1-1", TelemetryEvent.APP_OPEN, null, null, null)).isNull()
        assertThat(TelemetryClient.buildPayload("123e4567-e89b-62d3-a456-426614174000", TelemetryEvent.APP_OPEN, null, null, null)).isNull() // versão 6
        assertThat(TelemetryClient.buildPayload("123E4567-E89B-42D3-A456-426614174000", TelemetryEvent.APP_OPEN, null, null, null))
            .contains("\"installationId\":\"123e4567-e89b-42d3-a456-426614174000\"")
        assertThat(TelemetryClient.buildPayload("123e4567-e89b-42d3-a456-426614174000", TelemetryEvent.APP_OPEN, "x".repeat(65), null, null)).isNull()
        assertThat(TelemetryClient.buildPayload("123e4567-e89b-42d3-a456-426614174000", TelemetryEvent.APP_OPEN, null, null, null))
            .isEqualTo("""{"installationId":"123e4567-e89b-42d3-a456-426614174000","event":"app_open"}""")
    }

    @Test fun telemetryFailureIsSwallowed() = runBlocking {
        route("/v1/telemetry", status = 400, body = """{"error":"x"}""".toByteArray())
        assertThat(TelemetryClient("$base/v1/telemetry").send("123e4567-e89b-42d3-a456-426614174000", TelemetryEvent.APP_OPEN)).isFalse()
        assertThat(TelemetryClient("http://127.0.0.1:1/v1/telemetry").send("123e4567-e89b-42d3-a456-426614174000", TelemetryEvent.APP_OPEN)).isFalse()
    }

    @Test fun catalogRefreshEndToEndThroughHttpAndRealSignatureCheck() = runBlocking {
        val real = java.io.File(findWorkerCatalog()).readBytes()
        route("/v1/catalog.json", body = real, contentType = "application/json")
        val cache = object : CatalogCache {
            var saved: StoredCatalog? = null
            override suspend fun load() = saved
            override suspend fun save(catalog: StoredCatalog) { saved = catalog }
        }
        val repo = RemoteCatalogRepository(real, HttpCatalogFetcher("$base/v1/catalog.json"), cache, { Instant.parse("2026-10-20T00:00:00Z") })
        assertThat(repo.refreshIfDue()).isTrue()
        assertThat(repo.loadedCatalogForLaunch().source).isEqualTo(CatalogSource.CACHED_REMOTE)
    }

    private fun findWorkerCatalog(): String {
        var dir: java.io.File? = java.io.File(System.getProperty("user.dir")).absoluteFile
        while (dir != null) {
            val f = java.io.File(dir, "worker/catalog/catalog-v3.envelope.json")
            if (f.exists()) return f.path
            dir = dir.parentFile
        }
        error("envelope não encontrado")
    }
}
