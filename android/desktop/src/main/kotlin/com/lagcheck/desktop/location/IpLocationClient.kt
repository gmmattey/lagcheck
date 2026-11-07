package com.lagcheck.desktop.location

import com.lagcheck.desktop.LocalData
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.nio.file.Files
import java.time.Duration
import java.time.Instant

data class ApproxLocation(val city: String?, val country: String?, val lat: Double, val lon: Double)

fun interface IpLocationTransport { fun get(uri: URI): HttpResponse<String> }

class IpLocationClient(
    private val transport: IpLocationTransport = HttpTransport,
    private val now: () -> Instant = { Instant.now() },
    private val cacheFile: java.nio.file.Path = LocalData.directory.resolve("approx-location.properties")
) {
    fun cached(): ApproxLocation? = runCatching {
        if (!Files.isRegularFile(cacheFile) || Files.getLastModifiedTime(cacheFile).toInstant().plus(CACHE_TTL).isBefore(now())) null
        else parseCache(Files.readString(cacheFile))
    }.getOrNull()

    fun fetch(): ApproxLocation? = runCatching {
        val response = transport.get(URI.create(ENDPOINT))
        if (response.statusCode() !in 200..299) null else decode(response.body())?.also { save(it) }
    }.getOrNull()

    fun clearCache() { runCatching { Files.deleteIfExists(cacheFile) } }

    private fun save(location: ApproxLocation) = runCatching {
        Files.writeString(cacheFile, listOf(location.city.orEmpty(), location.country.orEmpty(), location.lat, location.lon).joinToString("\n"))
    }

    private fun parseCache(text: String): ApproxLocation? {
        val parts = text.lines(); if (parts.size < 4) return null
        return valid(ApproxLocation(parts[0].ifBlank { null }, parts[1].ifBlank { null }, parts[2].toDouble(), parts[3].toDouble()))
    }

    internal fun decode(body: String): ApproxLocation? {
        fun string(name: String) = Regex("\\\"$name\\\"\\s*:\\s*(null|\\\"([^\\\"]*)\\\")").find(body)?.let { if (it.groupValues[1] == "null") null else it.groupValues[2] }
        fun number(name: String) = Regex("\\\"$name\\\"\\s*:\\s*(-?[0-9]+(?:\\.[0-9]+)?)").find(body)?.groupValues?.get(1)?.toDoubleOrNull()
        val lat = number("lat") ?: return null; val lon = number("lon") ?: return null
        return valid(ApproxLocation(string("city"), string("country"), lat, lon))
    }

    private fun valid(value: ApproxLocation) = value.takeIf { it.lat in -90.0..90.0 && it.lon in -180.0..180.0 }

    companion object {
        const val ENDPOINT = "https://lagcheck.signallq.com/v1/approx-location"
        private val CACHE_TTL: Duration = Duration.ofHours(24)
    }
}

private object HttpTransport : IpLocationTransport {
    private val client = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(3)).build()
    override fun get(uri: URI): HttpResponse<String> = client.send(HttpRequest.newBuilder(uri).timeout(Duration.ofSeconds(3))
        .header("User-Agent", "lagcheck-desktop/1.0").GET().build(), HttpResponse.BodyHandlers.ofString())
}
