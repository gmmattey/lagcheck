package com.lagcheck.domain.rules

import com.google.common.truth.Truth.assertThat
import com.lagcheck.domain.model.ActionableRecommendation
import com.lagcheck.domain.model.CgnatStatus
import com.lagcheck.domain.model.DoubleNatStatus
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.GameServerArchitecture
import com.lagcheck.domain.model.GatewayProbeOutcome
import com.lagcheck.domain.model.NatTopologySnapshot
import com.lagcheck.domain.model.NatType
import com.lagcheck.domain.model.NetworkFinding
import com.lagcheck.domain.model.QualityProfileId
import com.lagcheck.domain.model.RadioTelemetrySnapshot
import com.lagcheck.domain.model.RecommendationKey
import com.lagcheck.domain.model.SpikePattern
import com.lagcheck.domain.model.WiFiBandConfidence
import com.lagcheck.domain.model.WiFiBandDiagnostic
import com.lagcheck.domain.model.WiFiBandInconclusiveReason
import com.lagcheck.domain.model.WiFiLocalTelemetry
import com.lagcheck.domain.presentation.ReadinessLanguage
import com.lagcheck.domain.presentation.ReadinessPresenter
import org.junit.Test

/** Vetores portados de WiFiBandEvaluatorTests, NATTopologyTests, EvidenceRecommendationEngineTests e VoiceChat (Swift). */
class Phase2DomainTest {

    // region WiFiBand
    @Test fun nonWifiIsInconclusive() {
        val r = WiFiBandEvaluator.evaluate(WiFiLocalTelemetry(1.2, 0.5, isWiFi = false))
        assertThat(r.diagnostic).isEqualTo(WiFiBandDiagnostic.Inconclusive(WiFiBandInconclusiveReason.NON_WIFI_INTERFACE))
        assertThat(r.confidence).isEqualTo(WiFiBandConfidence.NONE)
    }

    @Test fun ssidNeverClaimsFrequency() {
        for (ssid in listOf("MinhaCasa_5G", "Apartamento-5GHz", "Studio_6E", "MinhaCasa_2.4G", "Roteador_2G", "Home_2_4GHz")) {
            val r = WiFiBandEvaluator.evaluate(WiFiLocalTelemetry(detectedSsid = ssid))
            assertThat(r.confidence).isEqualTo(WiFiBandConfidence.NONE)
            assertThat(r.diagnostic.isSuspectOrConfirmed24GHz).isFalse()
            assertThat(r.diagnostic).isNotInstanceOf(WiFiBandDiagnostic.Confirmed5GHzOrHigher::class.java)
        }
    }

    @Test fun unresponsiveGatewayNeverInventsState() {
        val r = WiFiBandEvaluator.evaluate(WiFiLocalTelemetry(validSampleCount = 0, plannedSampleCount = 10))
        assertThat(r.diagnostic).isEqualTo(WiFiBandDiagnostic.Inconclusive(WiFiBandInconclusiveReason.GATEWAY_UNRESPONSIVE))
    }

    @Test fun insufficientSamples() {
        val r = WiFiBandEvaluator.evaluate(WiFiLocalTelemetry(5.0, 2.0, validSampleCount = 2, plannedSampleCount = 10))
        assertThat(r.diagnostic).isEqualTo(WiFiBandDiagnostic.Inconclusive(WiFiBandInconclusiveReason.INSUFFICIENT_SAMPLES))
    }

    @Test fun highLocalJitterSuspectsContentionButDoesNotConfirm24() {
        val r = WiFiBandEvaluator.evaluate(WiFiLocalTelemetry(12.0, 24.0, 1.2, validSampleCount = 10, plannedSampleCount = 10))
        assertThat(r.diagnostic).isEqualTo(WiFiBandDiagnostic.Suspected24GHzContention)
        assertThat(r.confidence).isEqualTo(WiFiBandConfidence.MEDIUM)
        assertThat(r.diagnostic.isSuspectOrConfirmed24GHz).isFalse()
        assertThat(r.actionKey).isEqualTo("network.band.action.deep_check")
    }

    @Test fun asymmetricTailSuspectsContention() {
        val r = WiFiBandEvaluator.evaluate(WiFiLocalTelemetry(22.0, 6.0, 1.8, validSampleCount = 10, plannedSampleCount = 10))
        assertThat(r.diagnostic).isEqualTo(WiFiBandDiagnostic.Suspected24GHzContention)
    }

    @Test fun wanLoadAloneNeverAccusesWifi() {
        val r = WiFiBandEvaluator.evaluate(WiFiLocalTelemetry(loadDeltaP50Ms = 42.0))
        assertThat(r.diagnostic).isEqualTo(WiFiBandDiagnostic.StableWiFi)
        assertThat(r.confidence).isEqualTo(WiFiBandConfidence.NONE)
    }

    @Test fun cleanFastHopIsStableEvenWithHighWanLoad() {
        val r = WiFiBandEvaluator.evaluate(WiFiLocalTelemetry(1.5, 0.8, 1.05, loadDeltaP50Ms = 50.0, validSampleCount = 10, plannedSampleCount = 10))
        assertThat(r.diagnostic).isEqualTo(WiFiBandDiagnostic.StableWiFi)
        assertThat(r.confidence).isEqualTo(WiFiBandConfidence.HIGH)
    }

    private fun wifi(freq: Int) = RadioTelemetrySnapshot.WifiDetails(freq, -50, 866, 866, "Wi-Fi 6")

    @Test fun realFrequencyConfirmsTheBandOnAndroid() {
        val t = WiFiLocalTelemetry(validSampleCount = 5, plannedSampleCount = 5, gatewayRttMedianMs = 2.0, gatewayJitterMs = 1.0)
        val r24 = WiFiBandEvaluator.evaluate(t, wifi(2437))
        assertThat(r24.diagnostic).isEqualTo(WiFiBandDiagnostic.Confirmed24GHz())
        assertThat(r24.confidence).isEqualTo(WiFiBandConfidence.HIGH)
        assertThat(r24.actionKey).isEqualTo("network.band.action.settings")
        assertThat(WiFiBandEvaluator.evaluate(t, wifi(5180)).diagnostic).isEqualTo(WiFiBandDiagnostic.Confirmed5GHzOrHigher())
        assertThat(WiFiBandEvaluator.evaluate(t, wifi(6115)).diagnostic).isEqualTo(WiFiBandDiagnostic.Confirmed5GHzOrHigher())
    }

    @Test fun unknownFrequencyFallsBackToTelemetryNeverGuesses() {
        val t = WiFiLocalTelemetry(validSampleCount = 0, plannedSampleCount = 5)
        assertThat(WiFiBandEvaluator.evaluate(t, wifi(0)).diagnostic)
            .isEqualTo(WiFiBandDiagnostic.Inconclusive(WiFiBandInconclusiveReason.GATEWAY_UNRESPONSIVE))
    }

    @Test fun frequencyOnCellularIsIgnored() {
        val r = WiFiBandEvaluator.evaluate(WiFiLocalTelemetry(isWiFi = false), wifi(2437))
        assertThat(r.diagnostic).isEqualTo(WiFiBandDiagnostic.Inconclusive(WiFiBandInconclusiveReason.NON_WIFI_INTERFACE))
    }
    // endregion

    // region Gateway outcome
    @Test fun gatewayOutcomeFromTelemetry() {
        assertThat(WiFiLocalTelemetry(isWiFi = false).gatewayOutcome).isEqualTo(GatewayProbeOutcome.Unobservable)
        assertThat(WiFiLocalTelemetry(validSampleCount = 0, plannedSampleCount = 5).gatewayOutcome).isEqualTo(GatewayProbeOutcome.Unobservable)
        val stable = WiFiLocalTelemetry(gatewayRttMedianMs = 2.1, gatewayJitterMs = 0.8, validSampleCount = 5, plannedSampleCount = 5)
        assertThat(stable.gatewayOutcome).isEqualTo(GatewayProbeOutcome.Stable(2.1))
        val degraded = WiFiLocalTelemetry(gatewayRttMedianMs = 22.5, gatewayJitterMs = 14.0, validSampleCount = 4, plannedSampleCount = 5)
        assertThat(degraded.gatewayOutcome).isEqualTo(GatewayProbeOutcome.Degraded(22.5, 20.0))
    }
    // endregion

    // region Voice
    @Test fun voiceSuitability() {
        for (rtt in listOf(0.0, 8.0, 9.0, 15.0)) assertThat(VoiceChatSuitabilityEvaluator.assess(rtt)).isEqualTo(VoiceChatSuitabilityEvaluator.Assessment.Favorable(rtt.toInt()))
        for (rtt in listOf(16.0, 20.0, 21.0)) assertThat(VoiceChatSuitabilityEvaluator.assess(rtt)).isEqualTo(VoiceChatSuitabilityEvaluator.Assessment.Attention(rtt.toInt()))
        assertThat(VoiceChatSuitabilityEvaluator.assess(null)).isEqualTo(VoiceChatSuitabilityEvaluator.Assessment.NotAssessed)
        assertThat(VoiceChatSuitabilityEvaluator.assess(Double.NaN)).isEqualTo(VoiceChatSuitabilityEvaluator.Assessment.NotAssessed)
        assertThat(VoiceChatSuitabilityEvaluator.assess(-1.0)).isEqualTo(VoiceChatSuitabilityEvaluator.Assessment.NotAssessed)
    }
    // endregion

    // region NAT
    @Test fun cgnatRange() {
        for (ip in listOf("100.64.0.1", "100.100.50.1", "100.127.255.254")) assertThat(NatTopologyEvaluator.isRfc6598Cgnat(ip)).isTrue()
        for (ip in listOf("100.63.255.255", "100.128.0.0", "177.136.20.10", "192.168.1.1", "100.64.1")) assertThat(NatTopologyEvaluator.isRfc6598Cgnat(ip)).isFalse()
    }

    @Test fun openWhenLocalEqualsPublic() {
        val s = NatTopologyEvaluator.evaluate("177.136.20.10", "177.136.20.10", 54321)
        assertThat(s.natType).isEqualTo(NatType.TYPE_1_OPEN)
        assertThat(s.hasAnyMultiplayerIssue).isFalse()
    }

    @Test fun moderateBehindStandardRouter() {
        val s = NatTopologyEvaluator.evaluate("192.168.1.50", "177.136.20.10", 54321)
        assertThat(s.natType).isEqualTo(NatType.TYPE_2_MODERATE)
        assertThat(s.hasAnyMultiplayerIssue).isFalse()
    }

    @Test fun strictOnCgnatAndDoubleNatAndInconsistentMapping() {
        val cg = NatTopologyEvaluator.evaluate("192.168.1.50", "100.70.15.22", 54321)
        assertThat(cg.natType).isEqualTo(NatType.TYPE_3_STRICT)
        assertThat(cg.cgnatStatus).isEqualTo(CgnatStatus.DETECTED)
        val dn = NatTopologyEvaluator.evaluate("192.168.1.50", "177.136.20.10", 54321, detectedDoubleHop = true)
        assertThat(dn.natType).isEqualTo(NatType.TYPE_3_STRICT)
        assertThat(dn.doubleNatStatus).isEqualTo(DoubleNatStatus.SUSPECT_OR_DETECTED)
        assertThat(NatTopologyEvaluator.evaluate("192.168.1.50", "177.136.20.10", 1, isPortMappingConsistent = false).natType).isEqualTo(NatType.TYPE_3_STRICT)
    }

    @Test fun inconclusiveWithoutPublicIp() {
        val s = NatTopologyEvaluator.evaluate("192.168.1.50", null, null)
        assertThat(s.natType).isEqualTo(NatType.INCONCLUSIVE)
        assertThat(s.cgnatStatus).isEqualTo(CgnatStatus.INCONCLUSIVE)
    }

    @Test fun ipsAreOnlyEverStoredMasked() {
        assertThat(NatTopologyEvaluator.maskIp("177.136.25.100")).isEqualTo("177.136.***.***")
        assertThat(NatTopologyEvaluator.maskIp("lixo")).isEqualTo("***.***.***.***")
        val s = NatTopologyEvaluator.evaluate("192.168.1.50", "177.136.20.10", 54321)
        assertThat(s.publicIpMasked).isEqualTo("177.136.***.***")
        assertThat(s.toString()).doesNotContain("177.136.20.10")
        assertThat(s.toString()).doesNotContain("192.168.1.50")
    }
    // endregion

    // region Recomendações e NAT no veredito
    private fun gen(e: DiagnosticEvidence) = EvidenceRecommendationEngine.generate(e).map { it.key }

    @Test fun degradedGatewayRecommendsGettingCloser() {
        assertThat(gen(DiagnosticEvidence(gatewayOutcome = GatewayProbeOutcome.Degraded(25.0, 5.0)))).contains(RecommendationKey.APPROACH_ROUTER)
    }

    @Test fun confirmed24NeedsConfidence() {
        val e = DiagnosticEvidence(GatewayProbeOutcome.Stable(1.5), WiFiBandDiagnostic.Confirmed24GHz("x"), WiFiBandConfidence.HIGH)
        assertThat(gen(e)).contains(RecommendationKey.SWITCH_TO_5GHZ)
        assertThat(gen(e.copy(wifiBand = WiFiBandDiagnostic.Suspected24GHzContention, wifiBandConfidence = WiFiBandConfidence.NONE))).doesNotContain(RecommendationKey.SWITCH_TO_5GHZ)
    }

    @Test fun suspectedContentionAloneNeverRecommendsBandSwitch() {
        // iOS: isSuspectOrConfirmed24GHz só é verdadeiro para o 2.4 confirmado; contenção suspeita não vira "troque de banda".
        val e = DiagnosticEvidence(GatewayProbeOutcome.Stable(1.5), WiFiBandDiagnostic.Suspected24GHzContention, WiFiBandConfidence.MEDIUM)
        assertThat(gen(e)).doesNotContain(RecommendationKey.SWITCH_TO_5GHZ)
    }

    @Test fun loadLossNatSpikesAndOutOfOrder() {
        val stable = GatewayProbeOutcome.Stable(1.5)
        assertThat(gen(DiagnosticEvidence(stable, loadTier = LoadDegradationTier.MATERIAL))).contains(RecommendationKey.PAUSE_DOWNLOADS)
        assertThat(gen(DiagnosticEvidence(stable, packetLossPercentage = 3.5))).contains(RecommendationKey.AVOID_RANKED)
        assertThat(gen(DiagnosticEvidence(stable, natType = NatType.TYPE_3_STRICT, serverArchitecture = GameServerArchitecture.PEER_TO_PEER))).contains(RecommendationKey.ENABLE_UPNP)
        assertThat(gen(DiagnosticEvidence(stable, natType = NatType.TYPE_3_STRICT, serverArchitecture = GameServerArchitecture.DEDICATED_SERVER))).doesNotContain(RecommendationKey.ENABLE_UPNP)
        assertThat(gen(DiagnosticEvidence(stable, spikePattern = SpikePattern.Recurring(3, 0)))).contains(RecommendationKey.CHECK_LOCAL_INTERFERENCE)
        assertThat(gen(DiagnosticEvidence(stable, outOfOrderCount = 3))).contains(RecommendationKey.ROUTE_INSTABILITY)
    }

    @Test fun neverBlamesTheRouteOrProviderWithoutAnIsolatedLocalProbe() {
        val unobservable = DiagnosticEvidence(GatewayProbeOutcome.Unobservable, outOfOrderCount = 5)
        assertThat(gen(unobservable)).doesNotContain(RecommendationKey.ROUTE_INSTABILITY)
        assertThat(gen(DiagnosticEvidence(GatewayProbeOutcome.Unobservable, spikePattern = SpikePattern.Recurring(3, 0))))
            .doesNotContain(RecommendationKey.CHECK_LOCAL_INTERFERENCE)
    }

    @Test fun recommendationsAreCappedAtThreeAndOrderedByPriority() {
        val all = DiagnosticEvidence(
            GatewayProbeOutcome.Degraded(25.0, 5.0), WiFiBandDiagnostic.Confirmed24GHz("n"), WiFiBandConfidence.HIGH,
            LoadDegradationTier.SEVERE, 5.0, SpikePattern.Recurring(4, 2), natType = NatType.TYPE_3_STRICT,
            serverArchitecture = GameServerArchitecture.PEER_TO_PEER
        )
        val r: List<ActionableRecommendation> = EvidenceRecommendationEngine.generate(all)
        assertThat(r.size).isAtMost(3)
        assertThat(r.map { it.priority }).isInOrder()
    }

    @Test fun architectureRegistryCoversTheCatalogIdForEaFc() {
        for (id in listOf("minecraft", "roblox", "ea-sports-fc-mobile", "eafc")) assertThat(GameArchitectureRegistry.serverArchitecture(id)).isEqualTo(GameServerArchitecture.HYBRID)
        for (id in listOf("fortnite", "valorant")) assertThat(GameArchitectureRegistry.serverArchitecture(id)).isEqualTo(GameServerArchitecture.DEDICATED_SERVER)
    }

    @Test fun natFindingOnlyAppearsForP2pOrHybridGames() {
        val q = completed(received(30, 25.0))
        val strict = NatTopologySnapshot(NatType.TYPE_3_STRICT, CgnatStatus.NOT_DETECTED, DoubleNatStatus.NOT_DETECTED)
        val p2p = GameReadinessEvaluator.evaluate(q, null, QualityProfileId.BATTLE_ROYALE_COMPETITIVE, serverArchitecture = GameServerArchitecture.PEER_TO_PEER, natSnapshot = strict)
        val f = p2p.findings.first { it.kind == NetworkFinding.Kind.NAT_TOPOLOGY }
        assertThat(f.severity).isEqualTo(NetworkFinding.Severity.NEGATIVE)
        assertThat(f.labelKey).isEqualTo("nat.type3.strict.title")
        val dedicated = GameReadinessEvaluator.evaluate(q, null, QualityProfileId.BATTLE_ROYALE_COMPETITIVE, natSnapshot = strict)
        assertThat(dedicated.findings.none { it.kind == NetworkFinding.Kind.NAT_TOPOLOGY }).isTrue()
    }

    @Test fun natStrictDoesNotChangeTheVerdict() {
        val q = completed(received(30, 25.0))
        val strict = NatTopologySnapshot(NatType.TYPE_3_STRICT, CgnatStatus.DETECTED, DoubleNatStatus.NOT_DETECTED)
        val r = GameReadinessEvaluator.evaluate(q, null, QualityProfileId.BATTLE_ROYALE_COMPETITIVE, serverArchitecture = GameServerArchitecture.HYBRID, natSnapshot = strict)
        assertThat(r.verdict).isEqualTo(GameReadinessVerdict.READY)
        assertThat(r.recommendations.map { it.key }).contains(RecommendationKey.ENABLE_UPNP)
    }

    @Test fun presenterLocalizesRecommendationsAndNatInEveryLanguage() {
        val q = completed(received(30, 25.0))
        val strict = NatTopologySnapshot(NatType.TYPE_3_STRICT, CgnatStatus.NOT_DETECTED, DoubleNatStatus.NOT_DETECTED)
        val a = GameReadinessEvaluator.evaluate(q, null, QualityProfileId.BATTLE_ROYALE_COMPETITIVE, serverArchitecture = GameServerArchitecture.HYBRID, natSnapshot = strict)
        val titles = ReadinessLanguage.entries.map { lang ->
            val ui = ReadinessPresenter.present(a, lang, platform = "PC", connectionType = "Wi-Fi", destinationName = "x")
            assertThat(ui.recommendations).isNotEmpty()
            assertThat(ui.findings.first { it.kind == NetworkFinding.Kind.NAT_TOPOLOGY }.label).doesNotContain("nat.")
            ui.recommendations.first().title
        }
        assertThat(titles.toSet()).hasSize(3)
    }
    // endregion
}
