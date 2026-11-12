package com.lagcheck.network.transport

import com.google.common.truth.Truth.assertThat
import com.lagcheck.catalog.ProbeDestination
import com.lagcheck.catalog.ProbeProtocolKind
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.InconclusiveReason
import com.lagcheck.domain.model.ProbeOutcome
import com.lagcheck.domain.model.QualityProfileId
import com.lagcheck.domain.rules.GameReadinessEvaluator
import com.lagcheck.network.codec.PingBeaconCodec
import com.lagcheck.network.codec.PlayFabQosCodec
import com.lagcheck.network.codec.SteamQueryA2sCodec
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.async
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import org.junit.Test

/** Exercita o transporte real (DatagramSocket) contra servidores em loopback, em escala de tempo reduzida. */
class UdpProbeTransportTest {
    private val fast = ProbePlan(count = 12, intervalMillis = 20, closureMillis = 600, probeTimeoutMillis = 200, abortOnPoorQuality = false)
    private fun dest(port: Int, kind: ProbeProtocolKind) = ProbeDestination("127.0.0.1", port, kind)

    @Test fun gameLiftExactEchoYieldsAllReceivedWithPlausibleRtt() = runBlocking {
        LoopbackUdpServer { req, _ -> listOf(req) }.use { server ->
            val sent = mutableListOf<Int>()
            val result = UdpProbeTransport().collect(dest(server.port, ProbeProtocolKind.GAMELIFT_PING), fast) {
                if (it is ProbeProgress.Sent) sent += it.sequence
            }
            assertThat(result.aborted).isFalse()
            assertThat(result.samples).hasSize(12)
            assertThat(result.samples.all { it.outcome == ProbeOutcome.RECEIVED }).isTrue()
            assertThat(result.samples.map { it.sequence }).containsExactlyElementsIn((0 until 12).toList()).inOrder()
            assertThat(result.samples.all { it.roundTripMilliseconds!! in 0.0..200.0 }).isTrue()
            assertThat(sent).containsExactlyElementsIn((0 until 12).toList()).inOrder()
        }
    }

    @Test fun everyBeaconCarriesTheSameSessionAndGrowingSequence() = runBlocking {
        val seen = java.util.Collections.synchronizedList(mutableListOf<ByteArray>())
        LoopbackUdpServer { req, _ -> seen += req; listOf(req) }.use { server ->
            UdpProbeTransport().collect(dest(server.port, ProbeProtocolKind.GAMELIFT_PING), fast)
        }
        val decoded = seen.map { PingBeaconCodec.decode(it)!! }
        assertThat(decoded).hasSize(12)
        assertThat(decoded.map { it.sessionId }.toSet()).hasSize(1)
        assertThat(decoded.map { it.sequence }).containsExactlyElementsIn((0L until 12L).toList()).inOrder()
        assertThat(decoded.map { it.nonce }.toSet().size).isGreaterThan(1)
    }

    @Test fun droppedProbesBecomeTimeoutsAndLossIsMeasuredNotInvented() = runBlocking {
        // Descarta 1 de cada 3 datagramas.
        LoopbackUdpServer { req, i -> if (i % 3 == 0) emptyList() else listOf(req) }.use { server ->
            val r = UdpProbeTransport().collect(dest(server.port, ProbeProtocolKind.GAMELIFT_PING), fast)
            val timeouts = r.samples.count { it.outcome == ProbeOutcome.TIMEOUT }
            assertThat(timeouts).isEqualTo(4)
            assertThat(r.samples.count { it.outcome == ProbeOutcome.RECEIVED }).isEqualTo(8)
        }
    }

    @Test fun silentServerTimesOutEverythingAndIsInconclusive() = runBlocking {
        LoopbackUdpServer { _, _ -> emptyList() }.use { server ->
            val r = UdpProbeTransport().collect(dest(server.port, ProbeProtocolKind.GAMELIFT_PING), fast)
            assertThat(r.samples.all { it.outcome == ProbeOutcome.TIMEOUT }).isTrue()
            val verdict = GameReadinessEvaluator.evaluate(r.samples, null, QualityProfileId.BATTLE_ROYALE_COMPETITIVE).verdict
            assertThat(verdict).isEqualTo(GameReadinessVerdict.INCONCLUSIVE)
        }
    }

    @Test fun garbageResponsesNeverBecomeRtt() = runBlocking {
        LoopbackUdpServer { _, _ -> listOf(ByteArray(33) { 7 }) }.use { server ->
            val r = UdpProbeTransport().collect(dest(server.port, ProbeProtocolKind.GAMELIFT_PING), fast)
            assertThat(r.samples.none { it.outcome == ProbeOutcome.RECEIVED }).isTrue()
            assertThat(r.samples.count { it.outcome == ProbeOutcome.INVALID_RESPONSE }).isAtLeast(1)
            assertThat(r.samples.count { it.outcome == ProbeOutcome.TIMEOUT }).isEqualTo(12)
        }
    }

    @Test fun truncatedEchoIsRejected() = runBlocking {
        LoopbackUdpServer { req, _ -> listOf(req.copyOf(32)) }.use { server ->
            val r = UdpProbeTransport().collect(dest(server.port, ProbeProtocolKind.GAMELIFT_PING), fast)
            assertThat(r.samples.none { it.outcome == ProbeOutcome.RECEIVED }).isTrue()
        }
    }

    @Test fun playFabRequiresTheFlippedHeader() = runBlocking {
        LoopbackUdpServer { req, _ -> listOf(req.copyOf().also { it[0] = 0; it[1] = 0 }) }.use { server ->
            val ok = UdpProbeTransport().collect(dest(server.port, ProbeProtocolKind.PLAYFAB_QOS), fast)
            assertThat(ok.samples.all { it.outcome == ProbeOutcome.RECEIVED }).isTrue()
        }
        LoopbackUdpServer { req, _ -> listOf(req) }.use { server -> // eco literal não é resposta de QoS
            val bad = UdpProbeTransport().collect(dest(server.port, ProbeProtocolKind.PLAYFAB_QOS), fast)
            assertThat(bad.samples.none { it.outcome == ProbeOutcome.RECEIVED }).isTrue()
        }
    }

    @Test fun steamPerformsChallengeHandshakeBeforeMeasuring() = runBlocking {
        val token = 0x1234ABCDL
        val authenticated = java.util.concurrent.atomic.AtomicInteger()
        val info = byteArrayOf(-1, -1, -1, -1, 0x49, 0x11, 'S'.code.toByte(), 0, 0, 0, 0, 0, 0, 0)
        LoopbackUdpServer { req, _ ->
            val hasToken = req.size == 29
            if (!hasToken) {
                val t = token.toInt()
                listOf(byteArrayOf(-1, -1, -1, -1, 0x41, t.toByte(), (t shr 8).toByte(), (t shr 16).toByte(), (t shr 24).toByte()))
            } else {
                authenticated.incrementAndGet()
                assertThat(req.copyOfRange(25, 29)).isEqualTo(
                    byteArrayOf(0xCD.toByte(), 0xAB.toByte(), 0x34, 0x12)
                )
                listOf(info)
            }
        }.use { server ->
            val r = UdpProbeTransport().collect(dest(server.port, ProbeProtocolKind.STEAM_A2S), fast)
            assertThat(r.samples.count { it.outcome == ProbeOutcome.RECEIVED }).isEqualTo(12)
            assertThat(authenticated.get()).isEqualTo(12)
            assertThat(SteamQueryA2sCodec.isValidInfoResponse(info)).isTrue()
        }
    }

    @Test fun unresolvableHostIsTransportErrorNotAFakeScore() = runBlocking {
        val r = UdpProbeTransport().collect(ProbeDestination("host.invalid", 7770, ProbeProtocolKind.GAMELIFT_PING), fast)
        assertThat(r.samples).hasSize(12)
        assertThat(r.samples.all { it.outcome == ProbeOutcome.TRANSPORT_ERROR }).isTrue()
    }

    @Test fun deadConnectionAbortsEarlyInsteadOfWaitingForTheFullWindow() = runBlocking {
        LoopbackUdpServer { _, _ -> emptyList() }.use { server ->
            val plan = ProbePlan(count = 30, intervalMillis = 20, closureMillis = 60_000, probeTimeoutMillis = 100, abortOnPoorQuality = true)
            val t0 = System.nanoTime()
            val r = UdpProbeTransport().collect(dest(server.port, ProbeProtocolKind.GAMELIFT_PING), plan)
            val elapsedMs = (System.nanoTime() - t0) / 1_000_000
            assertThat(r.aborted).isTrue()
            assertThat(r.abortReason).isEqualTo(InconclusiveReason.POOR_SAMPLE_QUALITY)
            assertThat(elapsedMs).isLessThan(5_000)
        }
    }

    @Test fun healthyConnectionIsNeverAbortedByTheWatchdog() = runBlocking {
        LoopbackUdpServer { req, _ -> listOf(req) }.use { server ->
            val r = UdpProbeTransport().collect(dest(server.port, ProbeProtocolKind.GAMELIFT_PING), fast.copy(abortOnPoorQuality = true))
            assertThat(r.aborted).isFalse()
            assertThat(r.samples.count { it.outcome == ProbeOutcome.RECEIVED }).isEqualTo(12)
        }
    }

    @Test fun cancellationStopsPromptlyAndReleasesTheSocket() = runBlocking {
        LoopbackUdpServer { req, _ -> listOf(req) }.use { server ->
            val slow = ProbePlan(count = 30, intervalMillis = 500, closureMillis = 17_000)
            val job = async(start = CoroutineStart.DEFAULT) { UdpProbeTransport().collect(dest(server.port, ProbeProtocolKind.GAMELIFT_PING), slow) }
            delay(300)
            val t0 = System.nanoTime()
            job.cancelAndJoin()
            assertThat((System.nanoTime() - t0) / 1_000_000).isLessThan(1_000)
            assertThat(job.isCancelled).isTrue()
            val before = server.received.get()
            delay(700) // nenhum envio depois do cancelamento
            assertThat(server.received.get()).isEqualTo(before)
        }
    }

    @Test fun fullPipelineProducesReadyVerdictOnACleanRoute() = runBlocking {
        LoopbackUdpServer { req, _ -> listOf(req) }.use { server ->
            val rest = UdpProbeTransport().collect(dest(server.port, ProbeProtocolKind.GAMELIFT_PING), ProbePlan(30, 10, 800, 200, false))
            val load = UdpProbeTransport().collect(dest(server.port, ProbeProtocolKind.GAMELIFT_PING), ProbePlan(30, 10, 800, 200, false))
            val a = GameReadinessEvaluator.evaluate(rest.samples, load.samples, QualityProfileId.BATTLE_ROYALE_COMPETITIVE)
            assertThat(a.verdict).isEqualTo(GameReadinessVerdict.READY)
            assertThat(a.packetLossPercentage).isEqualTo(0.0)
        }
    }
}
