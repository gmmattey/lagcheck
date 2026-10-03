package com.lagcheck.android.data

import com.lagcheck.domain.model.CatalogGame
import com.lagcheck.domain.model.GameReadinessEvaluation
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.NetworkFinding

/**
 * Item persistido de histórico de medição (Decisões 50 e 66).
 * Representa um teste gravado no dispositivo.
 */
data class CheckHistoryItem(
    val id: String = java.util.UUID.randomUUID().toString(),
    val gameId: String,
    val gameName: String,
    val platform: String,
    val connectionType: String,
    val timestamp: Long,
    val verdict: GameReadinessVerdict,
    val score: Int,
    val pingMs: Double?,
    val jitterMs: Double?,
    val packetLossPercentage: Double?,
    val worstSpikeMs: Double?,
    val primaryWeight: String,
    val suitableUses: List<String>,
    val latencySeries: List<Double>,
    val findings: List<NetworkFinding>
) {
    val formattedDate: String
        get() {
            val now = System.currentTimeMillis()
            val diffMs = now - timestamp
            val diffMin = diffMs / 60000
            val diffHours = diffMin / 60
            return when {
                diffMin < 1 -> "Agora"
                diffMin < 60 -> "${diffMin} min atrás"
                diffHours < 24 -> "Hoje, ${java.text.SimpleDateFormat("HH:mm", java.util.Locale.getDefault()).format(java.util.Date(timestamp))}"
                diffHours < 48 -> "Ontem, ${java.text.SimpleDateFormat("HH:mm", java.util.Locale.getDefault()).format(java.util.Date(timestamp))}"
                else -> java.text.SimpleDateFormat("dd MMM · HH:mm", java.util.Locale.getDefault()).format(java.util.Date(timestamp))
            }
        }

    val metricsString: String
        get() {
            val ping = pingMs?.let { "%.0f ms".format(it) } ?: "— ms"
            val jitter = jitterMs?.let { "%.0f ms jitter".format(it) } ?: "— ms jitter"
            val loss = packetLossPercentage?.let { "%.1f%% perda".format(it) } ?: "0% perda"
            return "$ping · $jitter · $loss"
        }
}
