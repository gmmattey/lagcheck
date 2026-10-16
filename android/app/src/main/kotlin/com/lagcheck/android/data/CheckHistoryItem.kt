package com.lagcheck.android.data

import com.lagcheck.domain.model.CatalogGame
import com.lagcheck.domain.model.GameReadinessEvaluation
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.NetworkFinding
import com.lagcheck.android.ui.tr
import com.lagcheck.android.ui.trf

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
    val declaredExternalLink: String? = null,
    /** Campos de comparabilidade. Ausentes em snapshots antigos, que seguem visíveis mas não viram resumo. */
    val profileRuleVersion: String? = null,
    val regionId: String? = null,
    val observedNetwork: String? = null,
    val validResponseCount: Int? = null,
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
    val findings: List<NetworkFinding>,
    val idleP50: Double? = null,
    val idleP95: Double? = null,
    val idleP99: Double? = null,
    val idleSpikeCount: Int? = null,
    val loadP50: Double? = null,
    val loadP95: Double? = null,
    val loadP99: Double? = null,
    val loadSpikeCount: Int? = null
) {
    val formattedDate: String
        get() {
            val now = System.currentTimeMillis()
            val diffMs = now - timestamp
            val diffMin = diffMs / 60000
            val diffHours = diffMin / 60
            return when {
                diffMin < 1 -> tr("Agora")
                diffMin < 60 -> trf("%d min atrás", diffMin)
                diffHours < 24 -> trf("Hoje, %s", java.text.SimpleDateFormat("HH:mm", java.util.Locale.getDefault()).format(java.util.Date(timestamp)))
                diffHours < 48 -> trf("Ontem, %s", java.text.SimpleDateFormat("HH:mm", java.util.Locale.getDefault()).format(java.util.Date(timestamp)))
                else -> java.text.SimpleDateFormat("dd MMM · HH:mm", java.util.Locale.getDefault()).format(java.util.Date(timestamp))
            }
        }

    val metricsString: String
        get() {
            val ping = pingMs?.let { "%.0f ms".format(java.util.Locale.ROOT, it) } ?: "— ms"
            val jitter = jitterMs?.let { trf("%.0f ms jitter", it) } ?: tr("— ms jitter")
            // Sem leitura de perda, "—". Antes aparecia "0% perda", que é uma afirmação que ninguém mediu.
            val loss = packetLossPercentage?.let { trf("%.1f%% perda", it) } ?: tr("— perda")
            return "$ping · $jitter · $loss"
        }
}
