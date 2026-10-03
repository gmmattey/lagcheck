package com.lagcheck.session

import com.lagcheck.domain.model.CgnatStatus
import com.lagcheck.domain.model.DoubleNatStatus
import com.lagcheck.domain.model.NatTopologySnapshot
import com.lagcheck.domain.model.NatType
import com.lagcheck.domain.model.RadioTelemetrySnapshot
import com.lagcheck.domain.model.WiFiBandDiagnosticResult
import com.lagcheck.domain.model.WiFiLocalTelemetry
import com.lagcheck.domain.presentation.ReadinessLanguage
import com.lagcheck.domain.presentation.ReadinessPresenter
import com.lagcheck.domain.presentation.UiStrings
import com.lagcheck.domain.rules.VoiceChatSuitabilityEvaluator
import com.lagcheck.domain.rules.WiFiBandEvaluator

/** Leitura local pontual para o Cockpit. Cada campo é medido ou fica nulo. Nada é suposto. */
data class LocalNetworkReport(
    val telemetry: WiFiLocalTelemetry?,
    val nat: NatTopologySnapshot?,
    val wifiBand: WiFiBandDiagnosticResult?
) {
    val voice: VoiceChatSuitabilityEvaluator.Assessment
        get() = VoiceChatSuitabilityEvaluator.assess(telemetry?.gatewayRttMedianMs)
}

/** Mede gateway e NAT sob demanda (ao abrir o Cockpit), como o `capture` do iOS. */
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
 * Monta o Cockpit só com o que foi observado. Campo sem dado vira "—". Nunca há valor padrão "bonito":
 * o protótipo antigo mostrava NAT, CGNAT, UPnP, voz e gateway (`192.168.1.1`) que ninguém tinha medido.
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
        val natType = when {
            report == null -> tr("Medindo…")
            nat == null || nat.natType == NatType.INCONCLUSIVE -> tr("Inconclusivo")
            else -> ReadinessPresenter.natLabel(nat.natType, lang)
        }
        val cgnat = when (nat?.cgnatStatus) {
            CgnatStatus.DETECTED -> tr("Detectado")
            CgnatStatus.NOT_DETECTED -> tr("Não detectado")
            else -> if (report == null) tr("Medindo…") else DASH
        }
        val doubleNat = when (nat?.doubleNatStatus) {
            DoubleNatStatus.SUSPECT_OR_DETECTED -> tr("Suspeito")
            DoubleNatStatus.NOT_DETECTED -> tr("Não detectado")
            else -> if (report == null) tr("Medindo…") else DASH
        }

        val rttInt = localRtt?.let { Math.round(it).toInt() }
        val isConfirmed5GHz = wifi?.band == RadioTelemetrySnapshot.WifiBand.BAND_5_GHZ
        val isConfirmed24GHz = wifi?.band == RadioTelemetrySnapshot.WifiBand.BAND_2_4_GHZ

        val cg = when {
            rttInt == null -> tr("Não avaliado")
            isConfirmed5GHz && rttInt <= 4 -> UiStrings.translateFormat("Favorável · 5 GHz, roteador %d ms", lang, rttInt)
            isConfirmed24GHz -> tr("Atenção · 2.4 GHz detectado")
            rttInt > 10 -> UiStrings.translateFormat("Atenção · roteador %d ms", lang, rttInt)
            else -> tr("Não avaliado")
        }

        val voice = when (val v = report?.voice) {
            null -> tr("Medindo…")
            is VoiceChatSuitabilityEvaluator.Assessment.Favorable -> UiStrings.translateFormat("Favorável · roteador %d ms", lang, v.localGatewayRttMs)
            is VoiceChatSuitabilityEvaluator.Assessment.Attention -> UiStrings.translateFormat("Atenção · roteador %d ms", lang, v.localGatewayRttMs)
            VoiceChatSuitabilityEvaluator.Assessment.NotAssessed -> tr("Não avaliado")
        }

        val multi = when {
            rttInt == null || nat == null -> tr("Não avaliado")
            nat.natType == NatType.TYPE_3_STRICT -> tr("Atenção · NAT restrito")
            nat.doubleNatStatus == DoubleNatStatus.SUSPECT_OR_DETECTED -> tr("Atenção · Duplo NAT")
            rttInt > 15 -> UiStrings.translateFormat("Atenção · roteador %d ms", lang, rttInt)
            nat.natType != NatType.INCONCLUSIVE && nat.doubleNatStatus == DoubleNatStatus.NOT_DETECTED && rttInt <= 5 -> UiStrings.translateFormat("Favorável · NAT ok, roteador %d ms", lang, rttInt)
            else -> tr("Não avaliado")
        }

        val stream = when {
            rttInt == null -> tr("Não avaliado")
            isConfirmed5GHz && rttInt <= 6 -> UiStrings.translateFormat("Favorável · 5 GHz, roteador %d ms", lang, rttInt)
            isConfirmed24GHz -> tr("Atenção · 2.4 GHz detectado")
            rttInt > 15 -> UiStrings.translateFormat("Atenção · roteador %d ms", lang, rttInt)
            else -> tr("Não avaliado")
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
                    CockpitRow(tr("Latência do roteador"), gatewayRtt)
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
                    CockpitRow(tr("Cloud Gaming"), if (report == null) tr("Medindo…") else cg),
                    CockpitRow(tr("Voz (Discord)"), voice),
                    CockpitRow(tr("Multiplayer"), if (report == null) tr("Medindo…") else multi),
                    CockpitRow(tr("Live Stream"), if (report == null) tr("Medindo…") else stream)
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
