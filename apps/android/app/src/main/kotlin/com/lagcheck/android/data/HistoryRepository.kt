package com.lagcheck.android.data

import android.content.Context
import com.lagcheck.domain.model.CatalogGame
import com.lagcheck.domain.model.GameReadinessEvaluation
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.NetworkFinding
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/**
 * Repositório local de histórico de checks do Lagcheck.
 * Mantém os checks persistidos no armazenamento do dispositivo (JSON em filesDir).
 * Inicia 100% limpo em nova instalação (Integridade Diagnóstica / Sem dados inventados).
 */
class HistoryRepository(private val context: Context) {

    private val historyFile = File(context.filesDir, "measurement_history.json")
    private val _history = MutableStateFlow<List<CheckHistoryItem>>(emptyList())
    val history: StateFlow<List<CheckHistoryItem>> = _history.asStateFlow()

    init {
        loadHistoryFromDisk()
    }

    private fun loadHistoryFromDisk() {
        if (!historyFile.exists()) {
            _history.value = emptyList()
            return
        }

        try {
            val jsonText = historyFile.readText()
            val loaded = HistoryMapper.fromJson(jsonText)
            val retained = applyRetention(loaded)
            _history.value = retained
            if (retained != loaded) saveHistoryToDisk(retained)
        } catch (e: Exception) {
            _history.value = emptyList()
        }
    }

    fun recordCheck(
        game: CatalogGame,
        evaluation: GameReadinessEvaluation,
        profileRuleVersion: String,
        regionId: String,
        observedNetwork: String?,
        validResponseCount: Int?
    ) {
        val newItem = CheckHistoryItem(
            gameId = game.id,
            gameName = game.name,
            platform = evaluation.platform,
            connectionType = evaluation.connectionType,
            declaredExternalLink = evaluation.declaredExternalLink?.name,
            profileRuleVersion = profileRuleVersion,
            regionId = regionId,
            observedNetwork = observedNetwork,
            validResponseCount = validResponseCount,
            timestamp = evaluation.timestamp,
            verdict = evaluation.verdict,
            score = evaluation.score,
            pingMs = evaluation.pingMs,
            jitterMs = evaluation.jitterMs,
            packetLossPercentage = evaluation.packetLossPercentage,
            worstSpikeMs = evaluation.worstSpikeMs,
            primaryWeight = evaluation.primaryWeight,
            suitableUses = evaluation.suitableUses,
            latencySeries = evaluation.latencySeries,
            findings = evaluation.findings,
            idleP50 = evaluation.metrics?.rest?.p50Milliseconds,
            idleP95 = evaluation.metrics?.rest?.p95Milliseconds,
            idleP99 = evaluation.metrics?.rest?.p99Milliseconds,
            idleSpikeCount = evaluation.metrics?.rest?.spikeCount,
            loadP50 = evaluation.metrics?.load?.p50Milliseconds,
            loadP95 = evaluation.metrics?.load?.p95Milliseconds,
            loadP99 = evaluation.metrics?.load?.p99Milliseconds,
            loadSpikeCount = evaluation.metrics?.load?.spikeCount
        )
        val updated = applyRetention(listOf(newItem) + _history.value, now = newItem.timestamp)
        _history.value = updated
        saveHistoryToDisk(updated)
    }

    fun clearAll() {
        _history.value = emptyList()
        if (historyFile.exists()) {
            historyFile.delete()
        }
    }

    private fun saveHistoryToDisk(items: List<CheckHistoryItem>) {
        try {
            val jsonText = HistoryMapper.toJson(items)
            historyFile.writeText(jsonText)
        } catch (e: Exception) {
            // Ignora falha de gravação sem travar a UI
        }
    }

    /** A política de retenção é de dado local, não da UI: 90 dias e 100 checks por jogo. */
    private fun applyRetention(items: List<CheckHistoryItem>, now: Long = System.currentTimeMillis()): List<CheckHistoryItem> {
        return HistoryRetentionPolicy.apply(items, now)
    }
}

internal object HistoryRetentionPolicy {
    private const val RETENTION_DAYS = 90L
    private const val DAY_MILLIS = 86_400_000L
    private const val MAX_CHECKS_PER_GAME = 100

    fun apply(items: List<CheckHistoryItem>, now: Long): List<CheckHistoryItem> {
        val cutoff = now - RETENTION_DAYS * DAY_MILLIS
        val retainedByGame = mutableMapOf<String, Int>()
        return items.asSequence()
            .filter { it.timestamp >= cutoff }
            .sortedByDescending { it.timestamp }
            .filter { item ->
                val count = retainedByGame[item.gameId] ?: 0
                if (count >= MAX_CHECKS_PER_GAME) false else {
                    retainedByGame[item.gameId] = count + 1
                    true
                }
            }
            .toList()
    }
}

object HistoryMapper {
    private fun optionalMilliseconds(obj: JSONObject, key: String): Double? =
        obj.opt(key)?.toString()?.toDoubleOrNull()?.takeIf { it.isFinite() && it >= 0.0 }

    private fun optionalCount(obj: JSONObject, key: String): Int? =
        obj.opt(key)?.toString()?.toIntOrNull()?.takeIf { it >= 0 }

    fun fromJson(jsonText: String): List<CheckHistoryItem> {
        val jsonArray = JSONArray(jsonText)
        val items = mutableListOf<CheckHistoryItem>()

        for (i in 0 until jsonArray.length()) {
            val obj = jsonArray.getJSONObject(i)
            val findingsArray = obj.optJSONArray("findings") ?: JSONArray()
            val findings = mutableListOf<NetworkFinding>()
            for (j in 0 until findingsArray.length()) {
                val fObj = findingsArray.getJSONObject(j)
                findings.add(
                    NetworkFinding(
                        kind = NetworkFinding.Kind.valueOf(fObj.getString("kind")),
                        severity = NetworkFinding.Severity.valueOf(fObj.getString("severity")),
                        label = fObj.getString("label"),
                        detail = if (fObj.has("detail") && !fObj.isNull("detail")) fObj.getString("detail") else null
                    )
                )
            }

            val usesArray = obj.optJSONArray("suitableUses") ?: JSONArray()
            val uses = mutableListOf<String>()
            for (j in 0 until usesArray.length()) {
                uses.add(usesArray.getString(j))
            }

            val seriesArray = obj.optJSONArray("latencySeries") ?: JSONArray()
            val series = mutableListOf<Double>()
            for (j in 0 until seriesArray.length()) {
                series.add(seriesArray.getDouble(j))
            }

            items.add(
                CheckHistoryItem(
                    id = obj.getString("id"),
                    gameId = obj.getString("gameId"),
                    gameName = obj.getString("gameName"),
                    platform = obj.getString("platform"),
                    connectionType = obj.getString("connectionType"),
                    declaredExternalLink = obj.optString("declaredExternalLink").takeIf { it == "WIFI" || it == "ETHERNET" },
                    profileRuleVersion = obj.optString("profileRuleVersion").takeIf { it.isNotBlank() },
                    regionId = obj.optString("regionId").takeIf { it.isNotBlank() },
                    observedNetwork = obj.optString("observedNetwork").takeIf { it.isNotBlank() },
                    validResponseCount = optionalCount(obj, "validResponseCount"),
                    timestamp = obj.getLong("timestamp"),
                    verdict = GameReadinessVerdict.valueOf(obj.getString("verdict")),
                    score = obj.getInt("score"),
                    pingMs = if (obj.has("pingMs") && !obj.isNull("pingMs")) obj.getDouble("pingMs") else null,
                    jitterMs = if (obj.has("jitterMs") && !obj.isNull("jitterMs")) obj.getDouble("jitterMs") else null,
                    packetLossPercentage = if (obj.has("packetLossPercentage") && !obj.isNull("packetLossPercentage")) obj.getDouble("packetLossPercentage") else null,
                    worstSpikeMs = if (obj.has("worstSpikeMs") && !obj.isNull("worstSpikeMs")) obj.getDouble("worstSpikeMs") else null,
                    primaryWeight = obj.getString("primaryWeight"),
                    suitableUses = uses,
                    latencySeries = series,
                    findings = findings,
                    idleP50 = optionalMilliseconds(obj, "idleP50"),
                    idleP95 = optionalMilliseconds(obj, "idleP95"),
                    idleP99 = optionalMilliseconds(obj, "idleP99"),
                    idleSpikeCount = optionalCount(obj, "idleSpikeCount"),
                    loadP50 = optionalMilliseconds(obj, "loadP50"),
                    loadP95 = optionalMilliseconds(obj, "loadP95"),
                    loadP99 = optionalMilliseconds(obj, "loadP99"),
                    loadSpikeCount = optionalCount(obj, "loadSpikeCount")
                )
            )
        }
        return items
    }

    fun toJson(items: List<CheckHistoryItem>): String {
        val jsonArray = JSONArray()
        items.forEach { item ->
            val obj = JSONObject().apply {
                put("id", item.id)
                put("gameId", item.gameId)
                put("gameName", item.gameName)
                put("platform", item.platform)
                put("connectionType", item.connectionType)
                put("declaredExternalLink", item.declaredExternalLink ?: JSONObject.NULL)
                put("profileRuleVersion", item.profileRuleVersion ?: JSONObject.NULL)
                put("regionId", item.regionId ?: JSONObject.NULL)
                put("observedNetwork", item.observedNetwork ?: JSONObject.NULL)
                put("validResponseCount", item.validResponseCount ?: JSONObject.NULL)
                put("timestamp", item.timestamp)
                put("verdict", item.verdict.name)
                put("score", item.score)
                put("pingMs", item.pingMs ?: JSONObject.NULL)
                put("jitterMs", item.jitterMs ?: JSONObject.NULL)
                put("packetLossPercentage", item.packetLossPercentage ?: JSONObject.NULL)
                put("worstSpikeMs", item.worstSpikeMs ?: JSONObject.NULL)
                put("primaryWeight", item.primaryWeight)

                val usesArr = JSONArray()
                item.suitableUses.forEach { usesArr.put(it) }
                put("suitableUses", usesArr)

                val seriesArr = JSONArray()
                item.latencySeries.forEach { seriesArr.put(it) }
                put("latencySeries", seriesArr)

                val findingsArr = JSONArray()
                item.findings.forEach { f ->
                    findingsArr.put(JSONObject().apply {
                        put("kind", f.kind.name)
                        put("severity", f.severity.name)
                        put("label", f.label)
                        put("detail", f.detail ?: JSONObject.NULL)
                    })
                }
                put("findings", findingsArr)

                put("idleP50", item.idleP50 ?: JSONObject.NULL)
                put("idleP95", item.idleP95 ?: JSONObject.NULL)
                put("idleP99", item.idleP99 ?: JSONObject.NULL)
                put("idleSpikeCount", item.idleSpikeCount ?: JSONObject.NULL)
                put("loadP50", item.loadP50 ?: JSONObject.NULL)
                put("loadP95", item.loadP95 ?: JSONObject.NULL)
                put("loadP99", item.loadP99 ?: JSONObject.NULL)
                put("loadSpikeCount", item.loadSpikeCount ?: JSONObject.NULL)
            }
            jsonArray.put(obj)
        }
        return jsonArray.toString()
    }
}
