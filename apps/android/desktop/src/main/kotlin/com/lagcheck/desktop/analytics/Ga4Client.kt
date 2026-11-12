package com.lagcheck.desktop.analytics

import com.lagcheck.desktop.LocalData
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.nio.file.Files
import java.time.Duration
import java.util.Properties
import java.util.UUID

sealed interface ProductAnalyticsEvent {
    data class GameSelected(val gameId: String) : ProductAnalyticsEvent
    data class LagcheckStarted(val gameId: String, val gamePlatform: String, val networkType: String, val regionId: String) : ProductAnalyticsEvent
    data class LagcheckCompleted(val gameId: String, val gamePlatform: String, val networkType: String, val regionId: String, val resultClass: String, val durationSeconds: Long) : ProductAnalyticsEvent
    data class LagcheckInconclusive(val gameId: String, val gamePlatform: String, val networkType: String, val regionId: String, val reason: String) : ProductAnalyticsEvent
    data class LagcheckCancelled(val gameId: String, val gamePlatform: String, val networkType: String, val regionId: String, val reason: String) : ProductAnalyticsEvent
    data class ResultViewed(val gameId: String, val gamePlatform: String, val resultClass: String) : ProductAnalyticsEvent
    data class RetestStarted(val gameId: String, val gamePlatform: String) : ProductAnalyticsEvent
}

data class Ga4Payload(val name: String, val parameters: Map<String, Any>)
fun ProductAnalyticsEvent.toGa4Payload(): Ga4Payload {
    fun context(game: String, platform: String, network: String, region: String) = mapOf("game_id" to game, "game_platform" to platform, "network_type" to network, "region_id" to region)
    return when (this) {
        is ProductAnalyticsEvent.GameSelected -> Ga4Payload("game_selected", mapOf("game_id" to gameId))
        is ProductAnalyticsEvent.LagcheckStarted -> Ga4Payload("lagcheck_started", context(gameId, gamePlatform, networkType, regionId))
        is ProductAnalyticsEvent.LagcheckCompleted -> Ga4Payload("lagcheck_completed", context(gameId, gamePlatform, networkType, regionId) + mapOf("result_class" to resultClass, "duration_seconds" to durationSeconds.coerceAtLeast(0)))
        is ProductAnalyticsEvent.LagcheckInconclusive -> Ga4Payload("lagcheck_inconclusive", context(gameId, gamePlatform, networkType, regionId) + mapOf("inconclusive_reason" to reason))
        is ProductAnalyticsEvent.LagcheckCancelled -> Ga4Payload("lagcheck_cancelled", context(gameId, gamePlatform, networkType, regionId) + mapOf("cancellation_reason" to reason))
        is ProductAnalyticsEvent.ResultViewed -> Ga4Payload("result_viewed", mapOf("game_id" to gameId, "game_platform" to gamePlatform, "result_class" to resultClass))
        is ProductAnalyticsEvent.RetestStarted -> Ga4Payload("retest_started", mapOf("game_id" to gameId, "game_platform" to gamePlatform))
    }
}

fun interface Ga4Transport { fun post(uri: URI, body: String) }
class Ga4Client(private val config: Ga4Config = Ga4Config.load(), private val transport: Ga4Transport = NetworkTransport) {
    fun send(event: ProductAnalyticsEvent, enabled: Boolean): Boolean {
        if (!enabled || !config.enabled) return false
        val payload = event.toGa4Payload(); val body = payloadJson(InstallationId.current(), payload)
        return runCatching { transport.post(URI.create("https://www.google-analytics.com/mp/collect?measurement_id=${config.measurementId}&api_secret=${config.apiSecret}"), body); true }.getOrDefault(false)
    }
    internal fun payloadJson(clientId: String, payload: Ga4Payload): String = "{\"client_id\":\"${escape(clientId)}\",\"events\":[{\"name\":\"${escape(payload.name)}\",\"params\":{${payload.parameters.entries.joinToString(",") { (key, value) -> "\"${escape(key)}\":${if (value is Number) value else "\"${escape(value.toString())}\""}" }}}]}"
    private fun escape(value: String): String = buildString {
        value.forEach { character ->
            when (character) {
                '\\' -> append("\\\\")
                '"' -> append("\\\"")
                '\b' -> append("\\b")
                '\u000C' -> append("\\f")
                '\n' -> append("\\n")
                '\r' -> append("\\r")
                '\t' -> append("\\t")
                else -> if (character.code <= 0x1F) append("\\u%04x".format(character.code)) else append(character)
            }
        }
    }
}
data class Ga4Config(val enabled: Boolean, val measurementId: String, val apiSecret: String) {
    companion object { fun load(): Ga4Config = Properties().let { p -> Ga4Config(Ga4Config::class.java.getResourceAsStream("/lagcheck-runtime.properties")?.use { p.load(it); p.getProperty("analytics.enabled") == "true" } ?: false, p.getProperty("analytics.measurementId", ""), p.getProperty("analytics.apiSecret", "")) } }
}
object InstallationId {
    private val file get() = LocalData.directory.resolve("analytics-client-id")
    fun current(): String = runCatching { Files.readString(file).trim().takeIf { it.isNotEmpty() } ?: renew() }.getOrElse { UUID.randomUUID().toString() }
    fun renew(): String = UUID.randomUUID().toString().also { runCatching { Files.writeString(file, it) } }
}
private object NetworkTransport : Ga4Transport {
    private val client = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(3)).build()
    override fun post(uri: URI, body: String) { client.send(HttpRequest.newBuilder(uri).timeout(Duration.ofSeconds(3)).header("Content-Type", "application/json").POST(HttpRequest.BodyPublishers.ofString(body)).build(), HttpResponse.BodyHandlers.discarding()) }
}
