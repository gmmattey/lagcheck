package com.lagcheck.domain.model

import java.net.URI
import java.net.URLDecoder
import java.net.URLEncoder
import java.util.Locale
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * Payload canônico e imutável do Duelo de Host no Android (Decisão 112).
 * Trafega inteiramente codificado na URL sob o domínio https://lagcheck.signallq.com/vs
 * sem necessidade de servidor ou banco de dados externo (Custo Zero).
 */
data class HostDuelPayload(
    val gameId: String,
    val regionId: String,
    val p50Ms: Double,
    val packetLossPercent: Double,
    val jitterMs: Double,
    val verdict: GameReadinessVerdict,
    val timestamp: Long = System.currentTimeMillis() / 1000L,
    val challengerNick: String = "",
    val ttlSeconds: Long = STANDARD_TTL_SECONDS
) {
    companion object {
        const val STANDARD_TTL_SECONDS: Long = 1800L // 30 minutos

        fun parse(uriString: String): HostDuelPayload? {
            val uri = try {
                URI(uriString)
            } catch (_: Exception) {
                return null
            }

            val scheme = uri.scheme?.lowercase() ?: return null
            if (scheme != "https" && scheme != "lagcheck") return null

            val host = uri.host?.lowercase().orEmpty()
            val path = uri.path?.lowercase().orEmpty()

            val isDuelRoute = (scheme == "https" && host == "lagcheck.signallq.com" && (path == "/vs" || path == "/vs/")) ||
                    (scheme == "lagcheck" && (host == "vs" || path == "/vs" || path == "vs"))
            if (!isDuelRoute) return null

            val rawQuery = uri.rawQuery.orEmpty()
            val params = rawQuery.split("&").filter { it.contains("=") }.associate {
                val parts = it.split("=", limit = 2)
                val key = URLDecoder.decode(parts[0], "UTF-8").lowercase()
                val value = URLDecoder.decode(parts.getOrElse(1) { "" }, "UTF-8")
                key to value
            }

            fun value(vararg keys: String): String? {
                for (k in keys) {
                    val v = params[k]
                    if (!v.isNullOrBlank()) return v
                }
                return null
            }

            val game = value("g", "game", "gameid") ?: return null
            val region = value("r", "region", "reg") ?: return null
            val p50 = value("p", "ping", "p50")?.toDoubleOrNull() ?: return null
            val loss = value("l", "loss")?.toDoubleOrNull() ?: return null
            val jitter = value("j", "jitter")?.toDoubleOrNull() ?: return null
            val verdictStr = value("v", "verdict") ?: return null
            val verdict = when (verdictStr.lowercase()) {
                "ready" -> GameReadinessVerdict.READY
                "caution" -> GameReadinessVerdict.CAUTION
                "not_ready", "notready" -> GameReadinessVerdict.NOT_READY
                "inconclusive" -> GameReadinessVerdict.INCONCLUSIVE
                else -> return null
            }
            val ts = value("t", "ts", "timestamp")?.toLongOrNull() ?: return null
            val nick = value("n", "nick", "name").orEmpty().take(16)

            return HostDuelPayload(
                gameId = game.lowercase().trim(),
                regionId = region.lowercase().trim(),
                p50Ms = maxOf(0.0, p50),
                packetLossPercent = maxOf(0.0, minOf(100.0, loss)),
                jitterMs = maxOf(0.0, jitter),
                verdict = verdict,
                timestamp = ts,
                challengerNick = nick
            )
        }
    }

    fun isExpired(nowMs: Long = System.currentTimeMillis()): Boolean {
        val currentSeconds = nowMs / 1000L
        return (currentSeconds - timestamp) > ttlSeconds
    }

    fun remainingSeconds(nowMs: Long = System.currentTimeMillis()): Long {
        val currentSeconds = nowMs / 1000L
        val diff = (timestamp + ttlSeconds) - currentSeconds
        return maxOf(0L, diff)
    }

    fun toWebUrl(baseUrl: String = "https://lagcheck.signallq.com/vs"): String {
        val p50Formatted = String.format(Locale.US, "%.1f", p50Ms)
        val lossFormatted = String.format(Locale.US, "%.1f", packetLossPercent)
        val jitterFormatted = String.format(Locale.US, "%.1f", jitterMs)
        val verdictStr = when (verdict) {
            GameReadinessVerdict.READY -> "ready"
            GameReadinessVerdict.CAUTION -> "caution"
            GameReadinessVerdict.NOT_READY -> "not_ready"
            GameReadinessVerdict.INCONCLUSIVE -> "inconclusive"
        }

        val baseQuery = "g=${URLEncoder.encode(gameId, "UTF-8")}" +
                "&r=${URLEncoder.encode(regionId, "UTF-8")}" +
                "&p=$p50Formatted" +
                "&l=$lossFormatted" +
                "&j=$jitterFormatted" +
                "&v=$verdictStr" +
                "&t=$timestamp"

        val queryWithNick = if (challengerNick.isNotBlank()) {
            "$baseQuery&n=${URLEncoder.encode(challengerNick, "UTF-8")}"
        } else {
            baseQuery
        }

        return "$baseUrl?$queryWithNick"
    }

    fun toCustomSchemeUrl(): String = toWebUrl("lagcheck://vs")

    fun generateDiscordShareText(gameTitle: String? = null): String {
        val displayGame = gameTitle ?: gameId.replaceFirstChar { it.uppercase() }
        val name = challengerNick.ifBlank { "Alguém" }
        val pingInt = p50Ms.roundToInt()
        val lossInt = packetLossPercent.roundToInt()
        val link = toWebUrl()

        return "[DUELO DE HOST] $name cravou ${pingInt}ms no $displayGame (${lossInt}% perda).\nQuem cria a sala? Aceita o duelo pra ver sua rota:\n$link"
    }
}

enum class HostDuelWinner {
    CHALLENGER,
    OPPONENT,
    TIE
}

data class HostDuelResolution(
    val winner: HostDuelWinner,
    val deltaMs: Double,
    val headline: String,
    val subheadline: String,
    val challengerLead: Boolean
)

object HostDuelResolver {

    private fun rank(verdict: GameReadinessVerdict): Int = when (verdict) {
        GameReadinessVerdict.READY -> 3
        GameReadinessVerdict.CAUTION -> 2
        GameReadinessVerdict.NOT_READY -> 1
        GameReadinessVerdict.INCONCLUSIVE -> 0
    }

    fun resolve(
        challenger: HostDuelPayload,
        opponent: HostDuelPayload,
        challengerDisplayName: String? = null,
        opponentDisplayName: String? = null
    ): HostDuelResolution {
        val cName = challengerDisplayName ?: challenger.challengerNick.ifBlank { "Desafiante" }
        val oName = opponentDisplayName ?: opponent.challengerNick.ifBlank { "Você" }
        val delta = abs(challenger.p50Ms - opponent.p50Ms)
        val deltaRounded = delta.roundToInt()

        val cRank = rank(challenger.verdict)
        val oRank = rank(opponent.verdict)

        // 1. Desempate por Veredito
        if (cRank != oRank) {
            return if (cRank > oRank) {
                HostDuelResolution(
                    winner = HostDuelWinner.CHALLENGER,
                    deltaMs = delta,
                    headline = "${cName.uppercase()} PUXA A RANKED",
                    subheadline = "$cName tem rota mais estável sob carga.",
                    challengerLead = true
                )
            } else {
                HostDuelResolution(
                    winner = HostDuelWinner.OPPONENT,
                    deltaMs = delta,
                    headline = "${oName.uppercase()} PUXA A RANKED",
                    subheadline = "$oName tem rota mais estável sob carga.",
                    challengerLead = false
                )
            }
        }

        // 2. Mesmo veredito: avaliar perda de pacotes (se delta > 0.5%)
        val lossDiff = challenger.packetLossPercent - opponent.packetLossPercent
        if (abs(lossDiff) > 0.5) {
            return if (lossDiff < 0) {
                HostDuelResolution(
                    winner = HostDuelWinner.CHALLENGER,
                    deltaMs = delta,
                    headline = "${cName.uppercase()} PUXA A RANKED",
                    subheadline = "$cName sofreu menos perda de pacotes (${challenger.packetLossPercent.roundToInt()}% vs ${opponent.packetLossPercent.roundToInt()}%).",
                    challengerLead = true
                )
            } else {
                HostDuelResolution(
                    winner = HostDuelWinner.OPPONENT,
                    deltaMs = delta,
                    headline = "${oName.uppercase()} PUXA A RANKED",
                    subheadline = "$oName sofreu menos perda de pacotes (${opponent.packetLossPercent.roundToInt()}% vs ${challenger.packetLossPercent.roundToInt()}%).",
                    challengerLead = false
                )
            }
        }

        // 3. Mesma estabilidade: Menor latência P50 vence (se delta >= 1.0 ms)
        if (delta >= 1.0) {
            return if (challenger.p50Ms < opponent.p50Ms) {
                HostDuelResolution(
                    winner = HostDuelWinner.CHALLENGER,
                    deltaMs = delta,
                    headline = "${cName.uppercase()} PUXA A RANKED",
                    subheadline = "Rota $deltaRounded ms mais rápida e estável sob carga.",
                    challengerLead = true
                )
            } else {
                HostDuelResolution(
                    winner = HostDuelWinner.OPPONENT,
                    deltaMs = delta,
                    headline = "${oName.uppercase()} PUXA A RANKED",
                    subheadline = "Rota $deltaRounded ms mais rápida e estável sob carga.",
                    challengerLead = false
                )
            }
        }

        // 4. Empate técnico
        return HostDuelResolution(
            winner = HostDuelWinner.TIE,
            deltaMs = delta,
            headline = "EMPATE NO LOBBY",
            subheadline = "Ambas as conexões têm a mesma qualidade e latência.",
            challengerLead = false
        )
    }
}
