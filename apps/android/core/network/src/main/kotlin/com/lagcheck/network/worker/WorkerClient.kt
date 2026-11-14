package com.lagcheck.network.worker

import com.lagcheck.domain.model.ProbeAcceptancePolicy
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

sealed class LoadOutcome {
    data class Completed(val bytesTransferred: Long) : LoadOutcome()
    data object Unavailable : LoadOutcome()
}

/**
 * Carga de download contínua do Deep Check (`GET /v1/load`, load-transfer-v2).
 * Encerra por volume ou por tempo, o que ocorrer primeiro.
 */
class HttpLoadTransport(
    private val url: String = WorkerEndpoints().loadUrl,
    private val maximumBytes: Long = 10L * 1024 * 1024,
    private val maximumDurationMillis: Long = ProbeAcceptancePolicy.CLOSURE_MILLIS - ProbeAcceptancePolicy.TIMEOUT_MILLIS
) {
    suspend fun transfer(): LoadOutcome = transfer(isWiFi = true)

    suspend fun transfer(isWiFi: Boolean): LoadOutcome = withContext(Dispatchers.IO) {
        val maxRequests = if (isWiFi) 6 else 1
        val concurrency = if (isWiFi) 2 else 1
        val totalMaxBytes = if (isWiFi) 60L * 1024 * 1024 else maximumBytes

        val totalBytes = AtomicLong(0L)
        val requestCount = AtomicInteger(0)
        val activeConnections = ConcurrentHashMap.newKeySet<HttpURLConnection>()

        try {
            coroutineScope {
                val workers = List(concurrency) {
                    launch {
                        while (isActive) {
                            if (requestCount.getAndIncrement() >= maxRequests) break
                            if (totalBytes.get() >= totalMaxBytes) break

                            val conn = try {
                                (URL(url).openConnection() as HttpURLConnection).apply {
                                    requestMethod = "GET"
                                    useCaches = false
                                    setRequestProperty("Cache-Control", "no-store")
                                    connectTimeout = 5_000
                                    readTimeout = 5_000
                                }
                            } catch (_: Exception) {
                                break
                            }

                            activeConnections.add(conn)
                            try {
                                downloadSingle(conn, totalBytes, maximumBytes, totalMaxBytes)
                            } finally {
                                activeConnections.remove(conn)
                                runCatching { conn.disconnect() }
                            }
                        }
                    }
                }

                val deadlineGuard = launch {
                    delay(maximumDurationMillis)
                    workers.forEach { it.cancel() }
                    activeConnections.forEach { runCatching { it.disconnect() } }
                }

                workers.joinAll()
                deadlineGuard.cancel()
            }
        } catch (e: CancellationException) {
            activeConnections.forEach { runCatching { it.disconnect() } }
            throw e
        } catch (_: Exception) {
        } finally {
            activeConnections.forEach { runCatching { it.disconnect() } }
        }

        val transferred = totalBytes.get()
        if (transferred > 0L) LoadOutcome.Completed(transferred) else LoadOutcome.Unavailable
    }

    private fun downloadSingle(
        connection: HttpURLConnection,
        totalBytes: AtomicLong,
        singleMaxBytes: Long,
        totalMaxBytes: Long
    ) {
        try {
            if (connection.responseCode !in 200..299) return
            var currentTaskBytes = 0L
            connection.inputStream.use { input ->
                val buffer = ByteArray(16 * 1024)
                while (true) {
                    val n = input.read(buffer)
                    if (n < 0) break
                    currentTaskBytes += n
                    totalBytes.addAndGet(n.toLong())
                    if (currentTaskBytes >= singleMaxBytes || totalBytes.get() >= totalMaxBytes) break
                }
            }
        } catch (_: IOException) {
        }
    }
}
