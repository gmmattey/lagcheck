package com.lagcheck.domain.model

/**
 * Achado de rede honesto para a seção "O que encontramos" (Decisões 50 e 51).
 */
data class NetworkFinding(
    val kind: Kind,
    val severity: Severity,
    val label: String,
    val detail: String? = null
) {
    enum class Kind {
        PACKET_LOSS,
        LATENCY_SPIKES,
        HIGH_LATENCY,
        HIGH_JITTER,
        OUT_OF_ORDER_PACKETS,
        LOAD_DEGRADATION,
        STABLE_ROUTE,
        NORMAL_DESTINATION,
        LOCAL_GATEWAY,
        WIFI_BAND_2_4GHZ,
        WIFI_BAND_5GHZ,
        WIFI_SIGNAL_CRITICAL,
        INSUFFICIENT_DATA
    }

    enum class Severity {
        POSITIVE, // Verde (#34D399)
        WARNING,  // Coral/Âmbar (#FF5A36)
        NEGATIVE, // Vermelho (#EF4444)
        NEUTRAL   // Cinza (#8E95A2)
    }
}

/**
 * Resultado completo da avaliação de prontidão competitiva (1:1 com o protótipo de alta fidelidade).
 */
data class GameReadinessEvaluation(
    val verdict: GameReadinessVerdict,
    val headline: String,
    val subtitle: String,
    val score: Int = 86,
    val primaryWeight: String = "Rota estável sob carga",
    val suitableUses: List<String> = listOf("Ranked", "Casual", "Party"),
    val pingMs: Double?,
    val jitterMs: Double?,
    val packetLossPercentage: Double?,
    val worstSpikeMs: Double?,
    val isUnderLoadAffected: Boolean,
    val findings: List<NetworkFinding>,
    val latencySeries: List<Double> = emptyList(),
    val platform: String = "PlayStation",
    val connectionType: String = "Wi-Fi",
    val destinationName: String = "São Paulo · rota regional de referência",
    val confidence: String = "boa",
    val timestamp: Long = System.currentTimeMillis(),
    val radioTelemetry: RadioTelemetrySnapshot? = null
)
