package com.lagcheck.network.worker

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.withContext
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

sealed class LoadOutcome {
    data class Completed(val bytesTransferred: Long) : LoadOutcome()
    data object Unavailable : LoadOutcome()
}

/**
 * Carga de download do Deep Check (`GET /v1/load`). Não envia identificação nem contexto, e encerra por volume ou por
 * tempo (10 MiB ou 15 s, o que ocorrer primeiro). Falha ou timeout = `Unavailable`: o resultado de repouso continua válido.
 */
class HttpLoadTransport(
    private val url: String = WorkerEndpoints().loadUrl,
    private val maximumBytes: Long = 10L * 1024 * 1024,
    private val maximumDurationMillis: Long = 15_000
) {
    suspend fun transfer(): LoadOutcome = withContext(Dispatchers.IO) {
        val connection = (URL(url).openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            useCaches = false
            setRequestProperty("Cache-Control", "no-store")
            connectTimeout = 5_000
            readTimeout = 5_000
        }
        try {
            coroutineScope {
                // E/S de socket bloqueante não obedece a timeout de coroutine nem a cancelamento: este guard fecha a
                // conexão no prazo (ou ao cancelar), o que destrava o read e devolve o controle.
                val guard = launch {
                    try { delay(maximumDurationMillis) } finally { connection.disconnect() }
                }
                try {
                    receive(connection)
                } finally {
                    guard.cancel()
                }
            }
        } finally {
            connection.disconnect()
        }
    }

    private suspend fun receive(connection: HttpURLConnection): LoadOutcome {
        return try {
            if (connection.responseCode !in 200..299) return LoadOutcome.Unavailable
            var total = 0L
            connection.inputStream.use { input ->
                val buffer = ByteArray(16 * 1024)
                while (true) {
                    currentCoroutineContext().ensureActive()
                    val n = input.read(buffer)
                    if (n < 0) break
                    total += n
                    if (total >= maximumBytes) break
                }
            }
            LoadOutcome.Completed(total)
        } catch (e: kotlinx.coroutines.CancellationException) {
            throw e
        } catch (_: IOException) {
            LoadOutcome.Unavailable
        }
    }
}
