package com.lagcheck.network.worker

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.URL

/** Funil mínimo e anônimo aceito pelo Worker (`ALLOWED_EVENTS`). */
enum class TelemetryEvent(val wire: String) {
    APP_OPEN("app_open"), CHECK_STARTED("check_started"), VERDICT_VIEWED("verdict_viewed"), RETEST_STARTED("retest_started")
}

enum class TelemetryVerdict(val wire: String) { READY("ready"), CAUTION("caution"), NOT_READY("not_ready"), INCONCLUSIVE("inconclusive") }

/** O Worker só aceita `iphone|playstation|xbox|pc`. Celular Android não tem valor próprio: o campo é omitido. */
enum class TelemetryPlatform(val wire: String) { PLAYSTATION("playstation"), XBOX("xbox"), PC("pc") }

/**
 * `POST /v1/telemetry`. UUID anônimo de instalação, zero PII, zero IP. Fire-and-forget com timeout de 3 s:
 * telemetria jamais bloqueia medição, score, resultado ou histórico.
 */
class TelemetryClient(private val url: String = WorkerEndpoints().telemetryUrl) {

    suspend fun send(
        installationId: String,
        event: TelemetryEvent,
        gameId: String? = null,
        platform: TelemetryPlatform? = null,
        verdict: TelemetryVerdict? = null
    ): Boolean {
        val json = buildPayload(installationId, event, gameId, platform, verdict) ?: return false
        return withContext(Dispatchers.IO) {
            val connection = (URL(url).openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                doOutput = true
                setRequestProperty("Content-Type", "application/json; charset=UTF-8")
                connectTimeout = 3_000
                readTimeout = 3_000
            }
            try {
                connection.outputStream.use { it.write(json.toByteArray(Charsets.UTF_8)) }
                connection.responseCode in 200..299
            } catch (_: Exception) {
                false
            } finally {
                connection.disconnect()
            }
        }
    }

    companion object {
        private const val MAX_GAME_ID = 64

        /** Mesmo regex do Worker (`UUID_REGEX`, case-insensitive, versões 1 a 5). */
        private val UUID_REGEX = Regex("^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$", RegexOption.IGNORE_CASE)

        /** Valida do lado do cliente o mesmo contrato do Worker; payload inválido nunca sai do aparelho. */
        fun buildPayload(
            installationId: String,
            event: TelemetryEvent,
            gameId: String?,
            platform: TelemetryPlatform?,
            verdict: TelemetryVerdict?
        ): String? {
            if (!UUID_REGEX.matches(installationId)) return null
            if (gameId != null && (gameId.isEmpty() || gameId.length > MAX_GAME_ID)) return null
            val fields = mutableListOf(
                "\"installationId\":\"${installationId.lowercase()}\"",
                "\"event\":\"${event.wire}\""
            )
            gameId?.let { fields += "\"gameId\":\"${escape(it.lowercase())}\"" }
            platform?.let { fields += "\"platform\":\"${it.wire}\"" }
            verdict?.let { fields += "\"verdict\":\"${it.wire}\"" }
            return fields.joinToString(prefix = "{", postfix = "}", separator = ",")
        }

        private fun escape(s: String) = s.replace("\\", "\\\\").replace("\"", "\\\"")
    }
}
