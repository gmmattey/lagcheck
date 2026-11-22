package com.lagcheck.session

import com.lagcheck.domain.model.NatTopologySnapshot
import com.lagcheck.domain.model.RadioTelemetrySnapshot
import com.lagcheck.domain.model.WiFiBandDiagnosticResult
import com.lagcheck.domain.model.WiFiLocalTelemetry
import com.lagcheck.domain.presentation.ReadinessLanguage
import com.lagcheck.domain.presentation.UiStrings
import com.lagcheck.domain.rules.WiFiBandEvaluator

/** Leitura local pontual para o Cockpit. Cada campo é medido ou fica nulo. Nada é suposto. */
data class LocalNetworkReport(
    val telemetry: WiFiLocalTelemetry?,
    val nat: NatTopologySnapshot?,
    val wifiBand: WiFiBandDiagnosticResult?
)

/** Observa a resposta DNS do gateway e mantém NAT inconclusivo até haver uma sonda válida. */
class LocalNetworkReporter(private val diagnostics: LocalDiagnostics = LocalDiagnostics()) {
    suspend fun capture(env: CheckEnvironment, gatewaySamples: Int = 3): LocalNetworkReport {
        val telemetry = if (env.isWiFi) diagnostics.probeGateway(env, gatewaySamples) else null
        val band = if (env.isWiFi && (telemetry != null || env.wifiRadio != null)) {
            WiFiBandEvaluator.evaluate(telemetry ?: WiFiLocalTelemetry(isWiFi = true), env.wifiRadio)
        } else null
        val nat = diagnostics.probeNat(env)
        return LocalNetworkReport(telemetry, nat, band)
    }
}

data class CockpitRow(val label: String, val value: String)
data class CockpitSection(val title: String, val rows: List<CockpitRow>)

/**
 * Monta o Cockpit só com o que foi observado. Campo sem dado vira "—". A resposta DNS do gateway
 * permanece uma observação; não comprova o primeiro salto nem a causa de uma partida ruim.
 */
object CockpitPresenter {
    private const val DASH = "—"

    fun sections(radio: RadioTelemetrySnapshot?, report: LocalNetworkReport?, lang: ReadinessLanguage): List<CockpitSection> {
        fun tr(pt: String) = UiStrings.translate(pt, lang)
        val wifi = radio?.wifiDetails

        val connection = when (radio?.transportType) {
            RadioTelemetrySnapshot.TransportType.WIFI -> tr("Wi-Fi")
            RadioTelemetrySnapshot.TransportType.CELLULAR -> tr("Dados móveis")
            RadioTelemetrySnapshot.TransportType.ETHERNET -> tr("Ethernet")
            else -> DASH
        }
        val band = when (wifi?.band) {
            RadioTelemetrySnapshot.WifiBand.BAND_2_4_GHZ -> "2.4 GHz"
            RadioTelemetrySnapshot.WifiBand.BAND_5_GHZ -> "5 GHz"
            RadioTelemetrySnapshot.WifiBand.BAND_6_GHZ -> "6 GHz"
            else -> DASH
        }
        val frequency = wifi?.frequencyMhz?.takeIf { it > 0 }?.let { "$it MHz" } ?: DASH
        // RSSI inválido do Android vem como -127 ou Int.MIN_VALUE; valor fora de faixa plausível não é leitura.
        val rssi = wifi?.rssiDbm?.takeIf { it in -126..0 }?.let { "$it dBm" } ?: DASH
        val link = wifi?.txLinkSpeedMbps?.takeIf { it > 0 }?.let { "$it Mbps" } ?: DASH

        val local = report?.telemetry
        val localRtt = local?.gatewayRttMedianMs
        val gatewayRtt = when {
            report == null -> tr("Medindo…")
            local == null -> DASH
            localRtt != null -> "${Math.round(localRtt)} ms"
            local.plannedSampleCount > 0 -> tr("Sem resposta")
            else -> DASH
        }

        val nat = report?.nat
        val natType = if (report == null) tr("Medindo…") else tr("Inconclusivo")
        val cgnat = if (report == null) tr("Medindo…") else DASH
        val doubleNat = if (report == null) tr("Medindo…") else DASH
        val notAssessed = if (report == null) tr("Medindo…") else tr("Não avaliado")
        val gatewayLabel = when (lang) {
            ReadinessLanguage.PT_BR -> "Resposta DNS do gateway"
            ReadinessLanguage.EN -> "Gateway DNS response"
            ReadinessLanguage.ES -> "Respuesta DNS del gateway"
        }

        return listOf(
            CockpitSection(
                tr("CONEXÃO LOCAL"),
                listOf(
                    CockpitRow(tr("Conexão"), connection),
                    CockpitRow(tr("Banda"), band),
                    CockpitRow(tr("Frequência"), frequency),
                    CockpitRow(tr("Sinal (RSSI)"), rssi),
                    CockpitRow(tr("Velocidade do link"), link),
                    CockpitRow(tr("IP Local"), radio?.localAddress ?: DASH),
                    CockpitRow(tr("Gateway"), radio?.gatewayAddress ?: DASH),
                    CockpitRow(gatewayLabel, gatewayRtt)
                )
            ),
            CockpitSection(
                tr("BORDA DA REDE"),
                listOf(
                    CockpitRow(tr("Tipo de NAT"), natType),
                    CockpitRow(tr("CGNAT"), cgnat),
                    CockpitRow(tr("NAT duplo"), doubleNat),
                    CockpitRow(tr("IP Público"), nat?.publicIpMasked ?: DASH)
                )
            ),
            CockpitSection(
                tr("CASOS DE USO"),
                listOf(
                    CockpitRow(tr("Cloud Gaming"), notAssessed),
                    CockpitRow(tr("Voz (Discord)"), notAssessed),
                    CockpitRow(tr("Multiplayer"), notAssessed),
                    CockpitRow(tr("Live Stream"), notAssessed)
                )
            )
        )
    }

    /** Texto para copiar/compartilhar, gerado das mesmas linhas da tela: o que se vê é o que se exporta. */
    fun shareText(radio: RadioTelemetrySnapshot?, report: LocalNetworkReport?, lang: ReadinessLanguage): String {
        val body = sections(radio, report, lang).joinToString("\n\n") { s ->
            s.title + "\n" + s.rows.joinToString("\n") { "${it.label}: ${it.value}" }
        }
        return "LAGCHECK · " + UiStrings.translate("Dados da Rede", lang).uppercase(java.util.Locale.ROOT) + "\n\n" + body
    }

}
