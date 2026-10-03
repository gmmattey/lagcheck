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
                        findings = findings
                    )
                )
            }
            _history.value = items
        } catch (e: Exception) {
            _history.value = emptyList()
        }
    }

    fun recordCheck(game: CatalogGame, evaluation: GameReadinessEvaluation) {
        val newItem = CheckHistoryItem(
            gameId = game.id,
            gameName = game.name,
            platform = evaluation.platform,
            connectionType = evaluation.connectionType,
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
            findings = evaluation.findings
        )
        // Mantém até 100 checks por jogo conforme especificação
        val updated = (listOf(newItem) + _history.value).take(100)
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
            val jsonArray = JSONArray()
            items.forEach { item ->
                val obj = JSONObject().apply {
                    put("id", item.id)
                    put("gameId", item.gameId)
                    put("gameName", item.gameName)
                    put("platform", item.platform)
                    put("connectionType", item.connectionType)
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
                }
                jsonArray.put(obj)
            }
            historyFile.writeText(jsonArray.toString())
        } catch (e: Exception) {
            // Ignora falha de gravação sem travar a UI
        }
    }
}
