package com.lagcheck.session

import com.google.common.truth.Truth.assertThat
import com.lagcheck.catalog.GameContext
import com.lagcheck.catalog.MeasurementStrategy
import com.lagcheck.catalog.Platform
import com.lagcheck.catalog.ProbeDestination
import com.lagcheck.catalog.ProbeProtocolKind
import com.lagcheck.catalog.ResolvedMeasurementContext
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.GatewayProbeOutcome
import com.lagcheck.domain.model.InconclusiveReason
import com.lagcheck.domain.model.MeasurementConfidence
import com.lagcheck.domain.model.NatType
import com.lagcheck.domain.model.NetworkFinding
import com.lagcheck.domain.model.ProbeOutcome
import com.lagcheck.domain.model.ProbeSample
import com.lagcheck.domain.model.QualityProfileId
import com.lagcheck.domain.model.RadioTelemetrySnapshot
import com.lagcheck.domain.model.RecommendationKey
import com.lagcheck.domain.model.WiFiBandDiagnostic
import com.lagcheck.network.local.GatewayExchange
import com.lagcheck.network.local.GatewayProber
import com.lagcheck.network.local.StunExchange
import com.lagcheck.network.local.StunTopologyProbe
import com.lagcheck.network.stun.StunPacketCodec
import com.lagcheck.network.transport.ProbeCollection
import com.lagcheck.network.worker.LoadOutcome
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicInteger
import kotlinx.coroutines.runBlocking
import org.junit.Test

class Phase2OrchestratorTest {
    private fun ctx(game: String) = ResolvedMeasurementContext(
        context = GameContext(game, "BR", Platform.MOBILE), catalogVersion = "t",
        profileId = QualityProfileId.BATTLE_ROYALE_COMPETITIVE, profileRuleVersion = "pilot-2026.09.08.1", regionId = "sa-east-1",
        destination = ProbeDestination("h", 7770, ProbeProtocolKind.GAMELIFT_PING), strategy = MeasurementStrategy.GENERIC_REGION,
        confidence = MeasurementConfidence.MEDIUM, precisionKey = "regionalReference"
    )

    private fun good(rtt: Double) = ProbeCollection(List(30) { ProbeSample(it, rtt, ProbeOutcome.RECEIVED) }, null)
    private fun collector(vararg phases: ProbeCollection, order: MutableList<String>? = null): ProbeCollector {
        val i = AtomicInteger()
        return ProbeCollector { _, _, _ -> order?.add("probes"); phases[i.getAndIncrement()] }
    }

    private fun gateway(vararg rtts: Double?, order: MutableList<String>? = null): GatewayProber {
        val it = rtts.iterator()
        return GatewayProber(GatewayExchange { _, _ -> order?.add("gateway"); if (it.hasNext()) it.next() else null })
    }

    private fun stun(ip: String = "177.136.20.10", localPort: Int = 40000, counter: AtomicInteger? = null) = StunTopologyProbe(
        exchange = StunExchange { req, _, _ ->
            counter?.incrementAndGet()
            val b = ByteBuffer.allocate(32)
            b.putShort(StunPacketCodec.BINDING_RESPONSE_TYPE).putShort(12).putInt(StunPacketCodec.MAGIC_COOKIE).put(req, 8, 12)
            b.putShort(StunPacketCodec.ATTR_XOR_MAPPED_ADDRESS).putShort(8).put(0).put(1)
            b.putShort((localPort xor (StunPacketCodec.MAGIC_COOKIE ushr 16)).toShort())
            val o = ip.split('.').map { x -> x.toInt() }
            b.putInt(((o[0] shl 24) or (o[1] shl 16) or (o[2] shl 8) or o[3]) xor StunPacketCodec.MAGIC_COOKIE)
            b.array()
        }
    )

    private fun wifi(freq: Int) = RadioTelemetrySnapshot.WifiDetails(freq, -50, 866, 866, "Wi-Fi 6")
    private val load = LoadTransfer { LoadOutcome.Completed(1) }

    @Test fun withoutLocalDiagnosticsNothingLocalIsReported() = runBlocking {
        val r = CheckOrchestrator(collector(good(30.0), good(30.0)), load).run(ctx("fortnite"), CheckEnvironment(isWiFi = true, gatewayAddress = "192.168.0.1"))
        assertThat(r.localTelemetry).isNull()
        assertThat(r.wifiBand).isNull()
        assertThat(r.nat).isNull()
    }

    @Test fun gatewayIsProbedBeforeTheRestPhaseOnWifiOnly() = runBlocking {
        val order = mutableListOf<String>()
        val diag = LocalDiagnostics(gateway(2.0, 2.0, 2.0, 2.0, 2.0, order = order), stun())
        val r = CheckOrchestrator(collector(good(30.0), good(30.0), order = order), load, local = diag)
            .run(ctx("fortnite"), CheckEnvironment(isWiFi = true, gatewayAddress = "192.168.0.1"))
        assertThat(order.first()).isEqualTo("gateway")
        assertThat(order.indexOf("probes")).isGreaterThan(order.lastIndexOf("gateway"))
        assertThat(r.localTelemetry!!.validSampleCount).isEqualTo(5)

        val cellular = CheckOrchestrator(collector(good(30.0), good(30.0)), load, local = diag)
            .run(ctx("fortnite"), CheckEnvironment(isWiFi = false))
        assertThat(cellular.localTelemetry).isNull()
        assertThat(cellular.wifiBand).isNull()
    }

    @Test fun realFrequencyConfirms24GhzAndRecommends5Ghz() = runBlocking {
        val diag = LocalDiagnostics(gateway(2.0, 2.0, 2.0, 2.0, 2.0), stun())
        val r = CheckOrchestrator(collector(good(30.0), good(30.0)), load, local = diag)
            .run(ctx("fortnite"), CheckEnvironment(isWiFi = true, gatewayAddress = "g", wifiRadio = wifi(2437)))
        assertThat(r.wifiBand!!.diagnostic).isEqualTo(WiFiBandDiagnostic.Confirmed24GHz())
        assertThat(r.assessment.recommendations.map { it.key }).contains(RecommendationKey.SWITCH_TO_5GHZ)
        assertThat(r.assessment.verdict).isEqualTo(GameReadinessVerdict.READY) // banda é fato observado, não condena sozinha
    }

    @Test fun degradedGatewayDoesNotTouchTheVerdictByDefault() = runBlocking {
        val diag = LocalDiagnostics(gateway(40.0, 45.0, 38.0, 50.0, 42.0), stun())
        val r = CheckOrchestrator(collector(good(30.0), good(30.0)), load, local = diag)
            .run(ctx("fortnite"), CheckEnvironment(isWiFi = true, gatewayAddress = "g"))
        assertThat(r.localTelemetry!!.gatewayOutcome).isInstanceOf(GatewayProbeOutcome.Degraded::class.java) // medido e exibível
        assertThat(r.assessment.verdict).isEqualTo(GameReadinessVerdict.READY)
        assertThat(r.assessment.findings.none { it.kind == NetworkFinding.Kind.LOCAL_GATEWAY }).isTrue()
        assertThat(r.assessment.recommendations.map { it.key }).doesNotContain(RecommendationKey.APPROACH_ROUTER)
    }

    @Test fun degradedGatewayDemotesTheVerdictOnlyWhenExplicitlyEnabled() = runBlocking {
        val diag = LocalDiagnostics(gateway(40.0, 45.0, 38.0, 50.0, 42.0), stun(), gatewayInfluencesVerdict = true)
        val r = CheckOrchestrator(collector(good(30.0), good(30.0)), load, local = diag)
            .run(ctx("fortnite"), CheckEnvironment(isWiFi = true, gatewayAddress = "g"))
        assertThat(r.assessment.verdict).isEqualTo(GameReadinessVerdict.CAUTION)
        assertThat(r.assessment.recommendations.map { it.key }).contains(RecommendationKey.APPROACH_ROUTER)
    }

    @Test fun silentGatewayStaysUnobservableAndNeverAccusesTheWifi() = runBlocking {
        val diag = LocalDiagnostics(gateway(null, null, null, null, null), stun(), gatewayInfluencesVerdict = true)
        val r = CheckOrchestrator(collector(good(30.0), good(30.0)), load, local = diag)
            .run(ctx("fortnite"), CheckEnvironment(isWiFi = true, gatewayAddress = "g"))
        assertThat(r.localTelemetry!!.gatewayOutcome).isEqualTo(GatewayProbeOutcome.Unobservable)
        assertThat(r.assessment.verdict).isEqualTo(GameReadinessVerdict.READY)
        assertThat(r.assessment.findings.none { it.kind == NetworkFinding.Kind.LOCAL_GATEWAY }).isTrue()
    }

    @Test fun natIsOnlyProbedForP2pOrHybridGames() = runBlocking {
        val probes = AtomicInteger()
        val diag = LocalDiagnostics(gateway(2.0, 2.0, 2.0, 2.0, 2.0), stun(counter = probes))
        val env = CheckEnvironment(isWiFi = true, gatewayAddress = "g", localIp = "192.168.1.50")

        val dedicated = CheckOrchestrator(collector(good(30.0), good(30.0)), load, local = diag).run(ctx("fortnite"), env)
        assertThat(dedicated.nat).isNull()
        assertThat(probes.get()).isEqualTo(0)

        val hybrid = CheckOrchestrator(collector(good(30.0), good(30.0)), load, local = diag).run(ctx("roblox"), env)
        assertThat(hybrid.nat!!.natType).isEqualTo(NatType.TYPE_2_MODERATE)
        assertThat(probes.get()).isEqualTo(2)
        assertThat(hybrid.assessment.findings.any { it.kind == NetworkFinding.Kind.NAT_TOPOLOGY }).isTrue()
    }

    @Test fun strictNatOnAHybridGameRecommendsUpnpWithoutChangingTheVerdict() = runBlocking {
        val diag = LocalDiagnostics(gateway(2.0, 2.0, 2.0, 2.0, 2.0), stun(ip = "100.70.1.1"))
        val r = CheckOrchestrator(collector(good(30.0), good(30.0)), load, local = diag)
            .run(ctx("eafc"), CheckEnvironment(isWiFi = true, gatewayAddress = "g", localIp = "192.168.1.50"))
        assertThat(r.nat!!.natType).isEqualTo(NatType.TYPE_3_STRICT)
        assertThat(r.assessment.recommendations.map { it.key }).contains(RecommendationKey.ENABLE_UPNP)
        assertThat(r.assessment.verdict).isEqualTo(GameReadinessVerdict.READY)
    }

    @Test fun abortedRestStillReportsWhatWasObservedLocally() = runBlocking {
        val aborted = ProbeCollection(List(6) { ProbeSample(it, outcome = ProbeOutcome.TIMEOUT) }, InconclusiveReason.POOR_SAMPLE_QUALITY)
        val diag = LocalDiagnostics(gateway(2.0, 2.0, 2.0, 2.0, 2.0), stun())
        val r = CheckOrchestrator(collector(aborted), load, local = diag)
            .run(ctx("roblox"), CheckEnvironment(isWiFi = true, gatewayAddress = "g"))
        assertThat(r.assessment.verdict).isEqualTo(GameReadinessVerdict.INCONCLUSIVE)
        assertThat(r.localTelemetry).isNotNull()
        assertThat(r.nat).isNull() // sessão cancelada: nada de NAT
    }
}
