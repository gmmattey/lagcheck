package com.lagcheck.network.health

import com.lagcheck.catalog.Platform
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull

/** Estado operacional de uma rede de console. `Unknown` = não deu para ler (fail-open: nunca vira alerta). */
sealed class PlatformHealthStatus {
    data object Operational : PlatformHealthStatus()
    data class Degraded(val summary: String) : PlatformHealthStatus()
    data class MajorOutage(val summary: String) : PlatformHealthStatus()
    data object Unknown : PlatformHealthStatus()
}

data class PlatformHealth(
    val platform: Platform,
    val status: PlatformHealthStatus,
    val serviceName: String,
    val affectedServices: List<String> = emptyList(),
    val details: String? = null
) {
    val isIssueReported: Boolean
        get() = status is PlatformHealthStatus.Degraded || status is PlatformHealthStatus.MajorOutage

    val isMajorOutage: Boolean get() = status is PlatformHealthStatus.MajorOutage

    companion object {
        fun operational(platform: Platform, serviceName: String) = PlatformHealth(platform, PlatformHealthStatus.Operational, serviceName)
        fun unknown(platform: Platform, serviceName: String) = PlatformHealth(platform, PlatformHealthStatus.Unknown, serviceName)
    }
}

/**
 * Parsers dos três status públicos de console (port de `DirectPlatformHealthClient`, Decisão 30). Entrada fora do formato
 * esperado vira `Unknown`: o app nunca inventa uma queda nem um "tudo certo" que não leu.
 */
object PlatformHealthParsers {
    const val PSN = "PlayStation Network"
    const val XBOX = "Xbox Network"
    const val NINTENDO = "Nintendo Switch Online"
    const val STEAM = "Steam"
    const val EPIC_GAMES = "Epic Games"
    const val PC_SERVICES = "Steam / Epic Games"

    private const val STATUS_MAX_AGE_MILLIS = 5 * 60 * 1000L
    private const val STATUS_MAX_FUTURE_SKEW_MILLIS = 60 * 1000L

    private val json = Json { ignoreUnknownKeys = true }

    private fun root(data: ByteArray): JsonObject? =
        runCatching { json.parseToJsonElement(String(data, Charsets.UTF_8)) as? JsonObject }.getOrNull()

    private fun JsonElement?.obj() = this as? JsonObject
    private fun JsonElement?.arr() = this as? JsonArray
    private fun JsonElement?.str(): String? = (this as? JsonPrimitive)?.takeIf { it.isString }?.contentOrNull
    private fun JsonArray?.objects(): List<JsonObject> = this?.mapNotNull { it as? JsonObject } ?: emptyList()

    fun parsePlayStation(data: ByteArray, market: String): PlatformHealth {
        val unknown = PlatformHealth.unknown(Platform.PLAYSTATION, PSN)
        val countries = root(data)?.get("countries").arr().objects().ifEmpty { return unknown }
        val country = countries.firstOrNull { it["countryCode"].str()?.uppercase() == market.uppercase() } ?: countries.first()

        val affected = mutableListOf<String>()
        var outage = false
        var degraded = false
        val messages = mutableListOf<String>()

        fun scan(item: JsonObject) {
            when (item["statusType"].str()?.lowercase()) {
                "outage" -> outage = true
                "degraded", "maintenance" -> degraded = true
            }
        }

        for (item in country["status"].arr().objects()) {
            scan(item)
            item["message"].obj()?.get("message").str()?.takeIf { it.isNotEmpty() }?.let(messages::add)
        }
        for (svc in country["services"].arr().objects()) {
            val statuses = svc["status"].arr().objects()
            if (statuses.isEmpty()) continue
            affected += svc["serviceName"].str() ?: svc["serviceId"].str().orEmpty()
            statuses.forEach(::scan)
        }

        val status = when {
            outage -> PlatformHealthStatus.MajorOutage(messages.firstOrNull() ?: "Interrupção nos serviços da PlayStation Network")
            degraded || affected.isNotEmpty() -> PlatformHealthStatus.Degraded(messages.firstOrNull() ?: "Instabilidade em serviços da PlayStation Network")
            else -> PlatformHealthStatus.Operational
        }
        return PlatformHealth(Platform.PLAYSTATION, status, PSN, affected, messages.joinToString(" "))
    }

    fun parseXbox(data: ByteArray): PlatformHealth {
        val obj = root(data) ?: return PlatformHealth.unknown(Platform.XBOX, XBOX)
        val state = obj["Status"].obj()?.get("Overall").obj()?.get("State").str()?.lowercase() ?: "none"

        val affected = mutableListOf<String>()
        val messages = mutableListOf<String>()
        for (svc in obj["CoreServices"].arr().objects()) {
            val statusName = svc["Status"].obj()?.get("Name").str() ?: "None"
            if (statusName.lowercase() != "none") affected += svc["Name"].str().orEmpty()
            for (scn in svc["Scenarios"].arr().objects()) {
                val scnStatus = scn["Status"].obj()?.get("Name").str() ?: "None"
                if (scnStatus.lowercase() != "none") scn["Description"].str()?.takeIf { it.isNotEmpty() }?.let(messages::add)
            }
        }

        val status = when (state) {
            "major" -> PlatformHealthStatus.MajorOutage(messages.firstOrNull() ?: "Interrupção geral nos serviços da Xbox Network")
            "minor", "limited" -> PlatformHealthStatus.Degraded(messages.firstOrNull() ?: "Instabilidade temporária na Xbox Network")
            "none" -> PlatformHealthStatus.Operational
            else -> if (affected.isNotEmpty()) PlatformHealthStatus.Degraded("Instabilidade em serviços do Xbox") else PlatformHealthStatus.Operational
        }
        return PlatformHealth(Platform.XBOX, status, XBOX, affected, messages.joinToString(" "))
    }

    fun parseNintendo(data: ByteArray): PlatformHealth {
        val obj = root(data) ?: return PlatformHealth.unknown(Platform.NINTENDO, NINTENDO)
        val messages = obj["operational_statuses"].arr().objects().mapNotNull { it["message"].str() }
        val hasOutage = obj["operational_statuses"].arr()?.isNotEmpty() == true
        if (hasOutage) {
            return PlatformHealth(
                Platform.NINTENDO,
                PlatformHealthStatus.MajorOutage(messages.firstOrNull() ?: "Interrupção no serviço da Nintendo"),
                NINTENDO, listOf("Online Services"), messages.joinToString(" ")
            )
        }
        return PlatformHealth.operational(Platform.NINTENDO, NINTENDO)
    }

    /**
     * Parser do endpoint unificado `https://lagcheck.signallq.com/api/status`.
     * Retorna `null` quando o payload não é válido ou quando o console solicitado veio como `unknown`/expirado,
     * permitindo fallback direto para o CDN da fabricante. Para `PC`, avalia Steam e Epic Games.
     */
    fun parseStatusApi(data: ByteArray, platform: Platform, nowMillis: Long = System.currentTimeMillis()): PlatformHealth? {
        val obj = root(data) ?: return null
        val entries = obj["platforms"].arr()?.objects() ?: return null
        val byId = HashMap<String, Pair<String, PlatformHealthStatus>>()
        for (item in entries) {
            val id = item["id"].str() ?: continue
            if (byId.containsKey(id)) continue
            val defaultName = when (id) {
                "playstation" -> PSN
                "xbox" -> XBOX
                "nintendo" -> NINTENDO
                "steam" -> STEAM
                "epicgames" -> EPIC_GAMES
                else -> continue
            }
            val rawName = item["name"].str()?.trim()?.takeIf { it.isNotEmpty() && it.length <= 80 } ?: defaultName
            val checkedAtMillis = item["checkedAt"].str()?.let { runCatching { java.time.Instant.parse(it).toEpochMilli() }.getOrNull() }
            val isFresh = checkedAtMillis != null &&
                checkedAtMillis <= nowMillis + STATUS_MAX_FUTURE_SKEW_MILLIS &&
                nowMillis - checkedAtMillis <= STATUS_MAX_AGE_MILLIS
            val status = if (!isFresh) {
                PlatformHealthStatus.Unknown
            } else {
                when (item["status"].str()) {
                    "operational" -> PlatformHealthStatus.Operational
                    "degraded" -> PlatformHealthStatus.Degraded("")
                    "outage" -> PlatformHealthStatus.MajorOutage("")
                    else -> PlatformHealthStatus.Unknown
                }
            }
            byId[id] = rawName to status
        }

        return when (platform) {
            Platform.PLAYSTATION -> byId["playstation"]?.second?.takeIf { it !is PlatformHealthStatus.Unknown }?.let { PlatformHealth(platform, it, PSN) }
            Platform.XBOX -> byId["xbox"]?.second?.takeIf { it !is PlatformHealthStatus.Unknown }?.let { PlatformHealth(platform, it, XBOX) }
            Platform.NINTENDO -> byId["nintendo"]?.second?.takeIf { it !is PlatformHealthStatus.Unknown }?.let { PlatformHealth(platform, it, NINTENDO) }
            Platform.PC -> {
                val pcEntries = listOfNotNull(byId["steam"], byId["epicgames"])
                val affected = pcEntries.filter { it.second is PlatformHealthStatus.Degraded || it.second is PlatformHealthStatus.MajorOutage }
                when {
                    affected.isNotEmpty() -> {
                        val isOutage = affected.any { it.second is PlatformHealthStatus.MajorOutage }
                        val affectedNames = affected.map { it.first }
                        val serviceName = if (affectedNames.size == 1) affectedNames.first() else PC_SERVICES
                        val status = if (isOutage) PlatformHealthStatus.MajorOutage("") else PlatformHealthStatus.Degraded("")
                        PlatformHealth(platform, status, serviceName, affectedNames)
                    }
                    pcEntries.any { it.second is PlatformHealthStatus.Operational } ->
                        PlatformHealth.operational(platform, PC_SERVICES)
                    else -> PlatformHealth.unknown(platform, PC_SERVICES)
                }
            }
            else -> null
        }
    }
}
