package com.lagcheck.domain.model

enum class WiFiBandInconclusiveReason { NON_WIFI_INTERFACE, GATEWAY_UNRESPONSIVE, INSUFFICIENT_SAMPLES }

enum class WiFiBandConfidence { HIGH, MEDIUM, NONE }

/** Diagnóstico da banda Wi-Fi e da estabilidade do enlace local. */
sealed class WiFiBandDiagnostic {
    /** 2.4 GHz confirmado pela frequência real reportada pelo sistema (só no Android). */
    data class Confirmed24GHz(val ssid: String? = null) : WiFiBandDiagnostic()
    /** 5 ou 6 GHz confirmado pela frequência real reportada pelo sistema (só no Android). */
    data class Confirmed5GHzOrHigher(val ssid: String? = null) : WiFiBandDiagnostic()
    /** Instabilidade de enlace local típica de contenção de canal. Não confirma a banda. */
    data object Suspected24GHzContention : WiFiBandDiagnostic()
    data object StableWiFi : WiFiBandDiagnostic()
    data class Inconclusive(val reason: WiFiBandInconclusiveReason) : WiFiBandDiagnostic()

    val isSuspectOrConfirmed24GHz: Boolean get() = this is Confirmed24GHz
}

/** Telemetria agregada do primeiro salto (roteador). Nunca inventada: sem resposta, não há RTT. */
data class WiFiLocalTelemetry(
    val gatewayRttMedianMs: Double? = null,
    val gatewayJitterMs: Double? = null,
    val tailRatioP95P50: Double? = null,
    val loadDeltaP50Ms: Double? = null,
    val validSampleCount: Int = 0,
    val plannedSampleCount: Int = 0,
    val detectedSsid: String? = null,
    val isWiFi: Boolean = true
) {
    /** Estado do gateway local segundo a Decisão 55. */
    val gatewayOutcome: GatewayProbeOutcome
        get() {
            if (!isWiFi || plannedSampleCount <= 0) return GatewayProbeOutcome.Unobservable
            val median = gatewayRttMedianMs
            if (validSampleCount <= 0 || median == null) return GatewayProbeOutcome.Unobservable
            val loss = (plannedSampleCount - validSampleCount).toDouble() / plannedSampleCount * 100.0
            val jitter = gatewayJitterMs ?: 0.0
            return if (median > 15.0 || loss > 0.0 || jitter > 10.0) GatewayProbeOutcome.Degraded(median, loss)
            else GatewayProbeOutcome.Stable(median)
        }
}

data class WiFiBandDiagnosticResult(
    val diagnostic: WiFiBandDiagnostic,
    val confidence: WiFiBandConfidence,
    val telemetry: WiFiLocalTelemetry,
    val titleKey: String,
    val messageKey: String,
    val actionKey: String? = null
)
