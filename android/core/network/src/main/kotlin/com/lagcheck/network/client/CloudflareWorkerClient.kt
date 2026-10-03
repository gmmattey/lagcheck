package com.lagcheck.network.client

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL

/**
 * Cliente HTTP nativo para o Cloudflare Worker do LagCheck (Decisões 12, 14, 50 e 67).
 * Custo operacional zero e sem dependências pesadas de terceiros.
 */
class CloudflareWorkerClient(
    private val baseUrl: String = "https://nolaggy-deep-check.buildea.workers.dev"
) {

    /**
     * Realiza download de buffer estático para estresse de saturação (Bufferbloat).
     */
    suspend fun downloadLoadPayload(maxBytes: Int = 5 * 1024 * 1024): Long = withContext(Dispatchers.IO) {
        val url = URL("$baseUrl/v1/load")
        val connection = url.openConnection() as HttpURLConnection
        connection.requestMethod = "GET"
        connection.connectTimeout = 5000
        connection.readTimeout = 10000

        var totalBytesRead = 0L
        try {
            if (connection.responseCode == HttpURLConnection.HTTP_OK) {
                val inputStream: InputStream = connection.inputStream
                val buffer = ByteArray(8192)
                var bytesRead: Int

                while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                    totalBytesRead += bytesRead
                    if (totalBytesRead >= maxBytes) break
                }
            }
        } finally {
            connection.disconnect()
        }
        totalBytesRead
    }

    /**
     * Envia evento anônimo de telemetria de retenção (sem IP, sem PII).
     */
    suspend fun sendAnonymousTelemetry(eventPayloadJson: String): Boolean = withContext(Dispatchers.IO) {
        val url = URL("$baseUrl/v1/telemetry")
        val connection = url.openConnection() as HttpURLConnection
        connection.requestMethod = "POST"
        connection.setRequestProperty("Content-Type", "application/json; charset=UTF-8")
        connection.doOutput = true
        connection.connectTimeout = 4000
        connection.readTimeout = 4000

        try {
            connection.outputStream.use { os ->
                val input = eventPayloadJson.toByteArray(Charsets.UTF_8)
                os.write(input, 0, input.size)
            }
            connection.responseCode in 200..299
        } catch (e: Exception) {
            false
        } finally {
            connection.disconnect()
        }
    }
}
