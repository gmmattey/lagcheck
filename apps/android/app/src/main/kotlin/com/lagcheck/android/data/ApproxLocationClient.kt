package com.lagcheck.android.data

import java.net.HttpURLConnection
import java.net.URL
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext

/** Localização aproximada pelo IP, só para posicionar "Você" no mapa de medição. */
data class ApproxLocation(val city: String?, val country: String?, val lat: Double, val lon: Double)

/**
 * Consulta o endpoint público do site (`/v1/approx-location`), o mesmo usado pelo site, pelo Windows e pelo iOS. O
 * servidor devolve cidade e coordenadas arredondadas a 0,5° (cerca de 50 km), sem GPS e sem guardar nada.
 *
 * No app: sem cookies nem cache HTTP, sem cabeçalho de identificação, limite de 3 s e resultado mantido só em memória
 * enquanto o processo vive. Falha ou demora nunca afeta a medição: o mapa segue com o país do aparelho.
 */
object ApproxLocationClient {
    const val ENDPOINT = "https://lagcheck.signallq.com/v1/approx-location"
    private const val TIMEOUT_MS = 3_000
    private const val MAX_BYTES = 4_096

    private val mutex = Mutex()
    @Volatile private var cached: ApproxLocation? = null
    private var inFlight: CompletableDeferred<ApproxLocation?>? = null

    /** Último resultado obtido nesta execução do app, sem rede. */
    fun cachedLocation(): ApproxLocation? = cached

    /** Resultado em memória ou uma consulta nova (uma por vez). Nulo quando falha. */
    suspend fun location(): ApproxLocation? {
        cached?.let { return it }
        val (deferred, owner) = mutex.withLock {
            inFlight?.let { it to false } ?: CompletableDeferred<ApproxLocation?>().also { inFlight = it }.let { it to true }
        }
        if (!owner) return deferred.await()
        val result = runCatching { fetch() }.getOrNull()
        if (result != null) cached = result
        mutex.withLock { inFlight = null }
        deferred.complete(result)
        return result
    }

    private suspend fun fetch(): ApproxLocation? = withContext(Dispatchers.IO) {
        val connection = URL(ENDPOINT).openConnection() as HttpURLConnection
        try {
            connection.connectTimeout = TIMEOUT_MS
            connection.readTimeout = TIMEOUT_MS
            connection.instanceFollowRedirects = false
            connection.useCaches = false
            connection.setRequestProperty("Accept", "application/json")
            if (connection.responseCode !in 200..299) return@withContext null
            // `readNBytes` só existe a partir da API 33; o app vai até a 26.
            val output = java.io.ByteArrayOutputStream()
            connection.inputStream.use { input ->
                val buffer = ByteArray(1024)
                while (true) {
                    val count = input.read(buffer)
                    if (count < 0) break
                    if (output.size() + count > MAX_BYTES) return@withContext null
                    output.write(buffer, 0, count)
                }
            }
            decode(String(output.toByteArray(), Charsets.UTF_8))
        } finally {
            connection.disconnect()
        }
    }

    /** Mesmas regras de `parseApproxLocation` do site (objeto JSON plano e pequeno). */
    fun decode(body: String): ApproxLocation? {
        fun number(name: String) = Regex("\"$name\"\\s*:\\s*(-?\\d+(?:\\.\\d+)?(?:[eE][-+]?\\d+)?)")
            .find(body)?.groupValues?.get(1)?.toDoubleOrNull()
        fun text(name: String): String? {
            val raw = Regex("\"$name\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"").find(body)?.groupValues?.get(1) ?: return null
            return unescape(raw).trim().ifEmpty { null }
        }
        val lat = number("lat") ?: return null
        val lon = number("lon") ?: return null
        if (!lat.isFinite() || !lon.isFinite() || lat !in -90.0..90.0 || lon !in -180.0..180.0) return null
        return ApproxLocation(text("city"), text("country"), lat, lon)
    }

    private fun unescape(value: String): String {
        val out = StringBuilder(value.length)
        var i = 0
        while (i < value.length) {
            val c = value[i]
            if (c != '\\' || i + 1 >= value.length) { out.append(c); i++; continue }
            when (val next = value[i + 1]) {
                'u' -> {
                    val hex = value.substring(i + 2, minOf(i + 6, value.length))
                    hex.toIntOrNull(16)?.let { out.append(it.toChar()) }
                    i += 6
                }
                'n' -> { out.append('\n'); i += 2 }
                't' -> { out.append('\t'); i += 2 }
                else -> { out.append(next); i += 2 }
            }
        }
        return out.toString()
    }
}
