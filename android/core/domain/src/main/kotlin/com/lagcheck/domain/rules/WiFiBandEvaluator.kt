package com.lagcheck.domain.rules

import com.lagcheck.domain.model.RadioTelemetrySnapshot
import com.lagcheck.domain.model.WiFiBandConfidence
import com.lagcheck.domain.model.WiFiBandDiagnostic
import com.lagcheck.domain.model.WiFiBandDiagnosticResult
import com.lagcheck.domain.model.WiFiBandInconclusiveReason
import com.lagcheck.domain.model.WiFiLocalTelemetry

/**
 * Avaliação determinística de estabilidade do enlace Wi-Fi (port de `WiFiBandEvaluator`).
 *
 * Diferença deliberada em relação ao iOS: o iOS não recebe a frequência por API pública e por isso nunca afirma a
 * banda. O Android recebe `WifiInfo.getFrequency()`, que é evidência direta. Só ela confirma 2.4 GHz ou 5/6 GHz. SSID,
 * RTT e jitter continuam sem poder afirmar frequência (Decisão 50).
 */
object WiFiBandEvaluator {
    const val FAST_GATEWAY_MEDIAN_RTT_MAX_MS = 15.0
    const val FAST_GATEWAY_JITTER_MAX_MS = 8.0
    const val HIGH_JITTER_CONTENTION_MS = 22.0
    const val MIN_GATEWAY_RTT_FOR_CONTENTION_MS = 20.0
    const val TAIL_RATIO_CONTENTION_MIN = 1.6
    const val MINIMUM_SAMPLES_REQUIRED = 3

    /** Com a frequência real do rádio, quando o sistema a informa. */
    fun evaluate(telemetry: WiFiLocalTelemetry, radio: RadioTelemetrySnapshot.WifiDetails?): WiFiBandDiagnosticResult {
        if (telemetry.isWiFi && radio != null) {
            when (radio.band) {
                RadioTelemetrySnapshot.WifiBand.BAND_2_4_GHZ -> return result(WiFiBandDiagnostic.Confirmed24GHz(), WiFiBandConfidence.HIGH, telemetry)
                RadioTelemetrySnapshot.WifiBand.BAND_5_GHZ, RadioTelemetrySnapshot.WifiBand.BAND_6_GHZ ->
                    return result(WiFiBandDiagnostic.Confirmed5GHzOrHigher(), WiFiBandConfidence.HIGH, telemetry)
                RadioTelemetrySnapshot.WifiBand.UNKNOWN -> Unit
            }
        }
        return evaluate(telemetry)
    }

    fun evaluate(telemetry: WiFiLocalTelemetry): WiFiBandDiagnosticResult {
        if (!telemetry.isWiFi) {
            return result(WiFiBandDiagnostic.Inconclusive(WiFiBandInconclusiveReason.NON_WIFI_INTERFACE), WiFiBandConfidence.NONE, telemetry)
        }
        if (telemetry.plannedSampleCount > 0 && telemetry.validSampleCount == 0) {
            return result(WiFiBandDiagnostic.Inconclusive(WiFiBandInconclusiveReason.GATEWAY_UNRESPONSIVE), WiFiBandConfidence.NONE, telemetry)
        }
        if (telemetry.plannedSampleCount > 0 && telemetry.validSampleCount < MINIMUM_SAMPLES_REQUIRED) {
            return result(WiFiBandDiagnostic.Inconclusive(WiFiBandInconclusiveReason.INSUFFICIENT_SAMPLES), WiFiBandConfidence.NONE, telemetry)
        }

        val jitter = telemetry.gatewayJitterMs
        val median = telemetry.gatewayRttMedianMs
        if (jitter != null && median != null) {
            val highJitter = jitter > HIGH_JITTER_CONTENTION_MS
            val asymmetricTail = (telemetry.tailRatioP95P50 ?: 1.0) >= TAIL_RATIO_CONTENTION_MIN && median >= MIN_GATEWAY_RTT_FOR_CONTENTION_MS
            if (highJitter || asymmetricTail) {
                return result(WiFiBandDiagnostic.Suspected24GHzContention, WiFiBandConfidence.MEDIUM, telemetry)
            }
            if (median <= FAST_GATEWAY_MEDIAN_RTT_MAX_MS && jitter <= FAST_GATEWAY_JITTER_MAX_MS) {
                return result(WiFiBandDiagnostic.StableWiFi, WiFiBandConfidence.HIGH, telemetry)
            }
        }
        if (median != null) return result(WiFiBandDiagnostic.StableWiFi, WiFiBandConfidence.MEDIUM, telemetry)
        // Sem medição local válida: não se afirma nada (Decisões 50 e 55).
        return result(WiFiBandDiagnostic.StableWiFi, WiFiBandConfidence.NONE, telemetry)
    }

    private fun result(d: WiFiBandDiagnostic, c: WiFiBandConfidence, t: WiFiLocalTelemetry): WiFiBandDiagnosticResult = when (d) {
        is WiFiBandDiagnostic.Confirmed24GHz -> WiFiBandDiagnosticResult(d, c, t, "network.band.confirmed_24.title", "network.band.confirmed_24.message", "network.band.action.settings")
        is WiFiBandDiagnostic.Confirmed5GHzOrHigher -> WiFiBandDiagnosticResult(d, c, t, "network.band.confirmed_5.title", "network.band.confirmed_5.message", null)
        WiFiBandDiagnostic.Suspected24GHzContention -> WiFiBandDiagnosticResult(d, c, t, "network.band.suspected_24.title", "network.band.suspected_24.message", "network.band.action.deep_check")
        WiFiBandDiagnostic.StableWiFi -> WiFiBandDiagnosticResult(d, c, t, "network.band.stable.title", "network.band.stable.message", null)
        is WiFiBandDiagnostic.Inconclusive -> WiFiBandDiagnosticResult(d, c, t, "network.band.inconclusive.title", "network.band.inconclusive.message", null)
    }
}
