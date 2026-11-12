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
}
