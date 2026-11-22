package com.lagcheck.session

import com.google.common.truth.Truth.assertThat
import com.lagcheck.domain.model.CgnatStatus
import com.lagcheck.domain.model.DoubleNatStatus
import com.lagcheck.domain.model.NatTopologySnapshot
import com.lagcheck.domain.model.NatType
import com.lagcheck.domain.model.RadioTelemetrySnapshot
import com.lagcheck.domain.model.WiFiLocalTelemetry
import com.lagcheck.domain.presentation.ReadinessLanguage
import com.lagcheck.network.local.GatewayExchange
import com.lagcheck.network.local.GatewayProber
import com.lagcheck.network.local.StunExchange
import com.lagcheck.network.local.StunTopologyProbe
import kotlinx.coroutines.runBlocking
import org.junit.Test

class CockpitPresenterTest {
    private val pt = ReadinessLanguage.PT_BR
    private fun rows(radio: RadioTelemetrySnapshot?, report: LocalNetworkReport?, lang: ReadinessLanguage = pt) =
        CockpitPresenter.sections(radio, report, lang).flatMap { it.rows }.associate { it.label to it.value }

    private val wifiRadio = RadioTelemetrySnapshot(
        transportType = RadioTelemetrySnapshot.TransportType.WIFI,
        wifiDetails = RadioTelemetrySnapshot.WifiDetails(5180, -47, 866, 866, "Wi-Fi 6"),
        gatewayAddress = "10.0.0.1"
    )

    @Test fun noDataMeansDashesNeverInventedValues() {
        val r = rows(null, null)
        assertThat(r["Banda"]).isEqualTo("—")
        assertThat(r["Frequência"]).isEqualTo("—")
        assertThat(r["Sinal (RSSI)"]).isEqualTo("—")
        assertThat(r["Velocidade do link"]).isEqualTo("—")
        assertThat(r["Gateway"]).isEqualTo("—") // antes: "192.168.1.1" assumido
        val all = CockpitPresenter.sections(null, null, pt).flatMap { it.rows }.joinToString { it.value }
        for (invented in listOf("192.168.1.1", "-54 dBm", "866 Mbps", "5240 MHz", "Moderado", "Habilitado", "Ótimo", "Pronto")) {
            assertThat(all).doesNotContain(invented)
        }
    }

    @Test fun realRadioValuesAreShownAsMeasured() {
        val r = rows(wifiRadio, null)
        assertThat(r["Conexão"]).isEqualTo("Wi-Fi")
        assertThat(r["Banda"]).isEqualTo("5 GHz")
        assertThat(r["Frequência"]).isEqualTo("5180 MHz")
        assertThat(r["Sinal (RSSI)"]).isEqualTo("-47 dBm")
        assertThat(r["Velocidade do link"]).isEqualTo("866 Mbps")
        assertThat(r["Gateway"]).isEqualTo("10.0.0.1")
    }

    @Test fun androidSentinelsForUnknownRadioReadingsBecomeDashes() {
        val unknown = wifiRadio.copy(wifiDetails = RadioTelemetrySnapshot.WifiDetails(0, -127, -1, -1, "Wi-Fi"))
        val r = rows(unknown, null)
        assertThat(r["Frequência"]).isEqualTo("—")
        assertThat(r["Sinal (RSSI)"]).isEqualTo("—")
        assertThat(r["Velocidade do link"]).isEqualTo("—")
        assertThat(r["Banda"]).isEqualTo("—")
    }

    @Test fun beforeTheProbesFinishItSaysMeasuringNotAGuess() {
        val r = rows(wifiRadio, null)
        assertThat(r["Tipo de NAT"]).isEqualTo("Medindo…")
        assertThat(r["Resposta DNS do gateway"]).isEqualTo("Medindo…")
        assertThat(r["Voz (Discord)"]).isEqualTo("Medindo…")
    }

    @Test fun gatewayResponseIsFactualAndNatNeverClaimsTopology() {
        val strict = NatTopologySnapshot(NatType.TYPE_3_STRICT, CgnatStatus.DETECTED, DoubleNatStatus.NOT_DETECTED)
        val report = LocalNetworkReport(WiFiLocalTelemetry(8.4, 1.0, 1.1, validSampleCount = 3, plannedSampleCount = 3), strict, null)
        val r = rows(wifiRadio, report)
        assertThat(r["Tipo de NAT"]).isEqualTo("Inconclusivo")
        assertThat(r["CGNAT"]).isEqualTo("—")
        assertThat(r["NAT duplo"]).isEqualTo("—")
        assertThat(r["Resposta DNS do gateway"]).isEqualTo("8 ms")
        assertThat(r["Voz (Discord)"]).isEqualTo("Não avaliado")
    }

    @Test fun silentRouterIsReportedAsNoResponseAndVoiceNotAssessed() {
        val report = LocalNetworkReport(WiFiLocalTelemetry(validSampleCount = 0, plannedSampleCount = 3), NatTopologySnapshot.INCONCLUSIVE, null)
        val r = rows(wifiRadio, report)
        assertThat(r["Resposta DNS do gateway"]).isEqualTo("Sem resposta")
        assertThat(r["Voz (Discord)"]).isEqualTo("Não avaliado")
        assertThat(r["Tipo de NAT"]).isEqualTo("Inconclusivo")
        assertThat(r["CGNAT"]).isEqualTo("—")
    }

    @Test fun dnsResponseDoesNotTurnIntoVoiceAdvice() {
        val report = LocalNetworkReport(WiFiLocalTelemetry(22.0, 3.0, 1.2, validSampleCount = 3, plannedSampleCount = 3), null, null)
        assertThat(rows(wifiRadio, report)["Voz (Discord)"]).isEqualTo("Não avaliado")
    }

    @Test fun useCasesStayUnassessedWithoutTheirOwnEvidence() {
        val report = LocalNetworkReport(
            WiFiLocalTelemetry(3.0, 0.4, 0.5, validSampleCount = 3, plannedSampleCount = 3),
            NatTopologySnapshot(NatType.TYPE_2_MODERATE, CgnatStatus.NOT_DETECTED, DoubleNatStatus.NOT_DETECTED),
            null
        )
        val on5Ghz = rows(wifiRadio, report)
        assertThat(on5Ghz["Cloud Gaming"]).isEqualTo("Não avaliado")
        assertThat(on5Ghz["Multiplayer"]).isEqualTo("Não avaliado")

        val on6Ghz = rows(wifiRadio.copy(wifiDetails = RadioTelemetrySnapshot.WifiDetails(6055, -47, 866, 866, "Wi-Fi 6E")), report)
        assertThat(on6Ghz["Cloud Gaming"]).isEqualTo("Não avaliado")
        assertThat(on6Ghz["Live Stream"]).isEqualTo("Não avaliado")

        val noGateway = rows(wifiRadio, report.copy(telemetry = null))
        assertThat(noGateway["Cloud Gaming"]).isEqualTo("Não avaliado")
        assertThat(noGateway["Multiplayer"]).isEqualTo("Não avaliado")
    }

    @Test fun everyRowIsLocalizedInEnglishAndSpanish() {
        val strict = NatTopologySnapshot(NatType.TYPE_3_STRICT, CgnatStatus.DETECTED, DoubleNatStatus.SUSPECT_OR_DETECTED)
        val report = LocalNetworkReport(WiFiLocalTelemetry(8.0, 1.0, 1.1, validSampleCount = 3, plannedSampleCount = 3), strict, null)
        val en = rows(wifiRadio, report, ReadinessLanguage.EN)
        assertThat(en["NAT type"]).isEqualTo("Inconclusive")
        assertThat(en["Gateway DNS response"]).isEqualTo("8 ms")
        assertThat(en["Voice chat (Discord)"]).isEqualTo("Not assessed")
        assertThat(en["CGNAT"]).isEqualTo("—")
        val es = rows(wifiRadio, report, ReadinessLanguage.ES)
        assertThat(es["Tipo de NAT"]).isEqualTo("No concluyente")
        assertThat(es["NAT doble"]).isEqualTo("—")
        assertThat(es["Voz (Discord)"]).isEqualTo("No evaluado")
    }

    @Test fun shareTextIsBuiltFromTheSameRowsAsTheScreen() {
        val text = CockpitPresenter.shareText(wifiRadio, null, pt)
        assertThat(text).contains("Frequência: 5180 MHz")
        assertThat(text).doesNotContain("NAT Tipo 2")
        assertThat(text).doesNotContain("Aberto/Moderado")
    }

    // region Reporter (probes reais com troca injetada)
    @Test fun reporterMeasuresGatewayAndNatOnWifiAndSkipsGatewayOnCellular() = runBlocking {
        var stunCalls = 0
        val stun = StunTopologyProbe(exchange = StunExchange { _, _, _ -> stunCalls += 1; null })
        val diag = LocalDiagnostics(GatewayProber(GatewayExchange { _, _ -> 3.0 }), stun)
        val reporter = LocalNetworkReporter(diag)
        val onWifi = reporter.capture(CheckEnvironment(isWiFi = true, gatewayAddress = "10.0.0.1"))
        assertThat(onWifi.telemetry!!.validSampleCount).isEqualTo(3)
        assertThat(onWifi.nat!!.natType).isEqualTo(NatType.INCONCLUSIVE)
        assertThat(stunCalls).isEqualTo(0)
        val cellular = reporter.capture(CheckEnvironment(isWiFi = false))
        assertThat(cellular.telemetry).isNull()
        assertThat(cellular.wifiBand).isNull()
    }
    // endregion
}
