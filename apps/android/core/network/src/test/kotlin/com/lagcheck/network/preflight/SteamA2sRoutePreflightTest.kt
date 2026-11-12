package com.lagcheck.network.preflight

import com.google.common.truth.Truth.assertThat
import com.lagcheck.catalog.GameContext
import com.lagcheck.catalog.MeasurementStrategy
import com.lagcheck.catalog.ProbeDestination
import com.lagcheck.catalog.ProbeProtocolKind
import com.lagcheck.catalog.ResolvedMeasurementContext
import com.lagcheck.catalog.RouteIdentity
import com.lagcheck.catalog.RouteKind
import com.lagcheck.domain.model.MeasurementConfidence
import com.lagcheck.domain.model.QualityProfileId
import com.lagcheck.network.codec.SteamQueryA2sCodec
import com.lagcheck.network.transport.LoopbackUdpServer
import kotlinx.coroutines.runBlocking
import org.junit.Test

/** Transporte real em loopback; a decisão de identidade já é coberta pelos vetores compartilhados da máquina. */
class SteamA2sRoutePreflightTest {
    private val identity = RouteIdentity(730, "csgo", "Community")
    private val header = byteArrayOf(-1, -1, -1, -1)

    private fun info(appId: Int = 730, folder: String = "csgo", name: String = "Community BR") =
        header + byteArrayOf(0x49, 0x11) + "$name\u0000map\u0000$folder\u0000game\u0000".toByteArray() +
            byteArrayOf(appId.toByte(), (appId shr 8).toByte(), 5, 0, 0)

    private fun challenge() = header + byteArrayOf(0x41, 0x78, 0x56, 0x34, 0x12)

    private fun candidate(port: Int) = ResolvedMeasurementContext(
        context = GameContext("route-fixture", "BR"), catalogVersion = "t", profileId = QualityProfileId.CASUAL_REALTIME,
        profileRuleVersion = "r", regionId = "sa-east-1",
        destination = ProbeDestination("127.0.0.1", port, ProbeProtocolKind.STEAM_A2S),
        strategy = MeasurementStrategy.DEDICATED_SERVER, confidence = MeasurementConfidence.HIGH,
        precisionKey = "dedicatedServer", routeId = "owned-a", routeKind = RouteKind.GAME_OWNED
    )

    private fun validates(server: LoopbackUdpServer, timeout: Long = 600) =
        runBlocking { SteamA2sRoutePreflight(timeout).validates(candidate(server.port), identity) }

    /** Servidor que exige challenge, como os servidores Valve atuais. */
    private fun challengingServer(reply: ByteArray) = LoopbackUdpServer { req, _ ->
        if (req.size == 25) listOf(challenge()) else if (req.size == 29) listOf(reply) else emptyList()
    }

    @Test fun acceptsServerThatMatchesIdentityAfterChallenge() {
        challengingServer(info()).use { assertThat(validates(it)).isTrue() }
    }

    @Test fun acceptsServerThatAnswersInfoWithoutChallenge() {
        LoopbackUdpServer { _, _ -> listOf(info()) }.use { assertThat(validates(it)).isTrue() }
    }

    @Test fun rejectsWrongAppIdAndWrongDirectory() {
        challengingServer(info(appId = 440)).use { assertThat(validates(it)).isFalse() }
        challengingServer(info(folder = "tf")).use { assertThat(validates(it)).isFalse() }
    }

    @Test fun rejectsTruncatedInfoAndSilentServerWithinTimeout() {
        challengingServer(info().copyOf(10)).use { assertThat(validates(it)).isFalse() }
        LoopbackUdpServer { _, _ -> emptyList() }.use {
            val started = System.nanoTime()
            assertThat(validates(it, timeout = 300)).isFalse()
            assertThat((System.nanoTime() - started) / 1_000_000).isLessThan(1_500)
        }
    }

    @Test fun repeatedChallengeIsRejected() {
        LoopbackUdpServer { _, _ -> listOf(challenge()) }.use { assertThat(validates(it)).isFalse() }
    }

    @Test fun neverProbesNonSteamDestinations() {
        val gamelift = candidate(9).copy(destination = ProbeDestination("127.0.0.1", 9, ProbeProtocolKind.GAMELIFT_PING))
        assertThat(runBlocking { SteamA2sRoutePreflight(300).validates(gamelift, identity) }).isFalse()
        assertThat(SteamQueryA2sCodec.encodeInitialRequest().size).isEqualTo(25)
    }
}
