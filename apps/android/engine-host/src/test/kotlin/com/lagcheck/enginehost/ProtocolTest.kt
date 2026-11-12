package com.lagcheck.enginehost

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import java.nio.charset.StandardCharsets
import com.lagcheck.desktop.library.model.GameNetworkSupport
import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame

class ProtocolTest {
    @Test fun `aborted measurement is never classified as completed`() {
        assertEquals(TerminalKind.INCONCLUSIVE, terminalKind("insufficient_udp_responses"))
        assertEquals(TerminalKind.COMPLETED, terminalKind(null))
    }

    @Test fun `hello advertises a stable protocol`() {
        val out = mutableListOf<String>()
        val lines = ArrayDeque(listOf("{\"type\":\"hello\",\"requestId\":\"r1\"}"))
        EngineHost(input = { lines.removeFirstOrNull() }, output = out::add).run()
        assertEquals(1, out.size)
        assertTrue(out.single().contains("\"type\":\"hello\""))
        assertTrue(out.single().contains("\"protocol\":\"lagcheck-engine-v1\""))
        assertTrue(out.single().contains("\"requestId\":\"r1\""))
    }

    @Test fun `unknown command returns structured error`() {
        val out = mutableListOf<String>()
        val lines = ArrayDeque(listOf("{\"type\":\"nope\",\"requestId\":\"r2\"}"))
        EngineHost(input = { lines.removeFirstOrNull() }, output = out::add).run()
        assertTrue(out.single().contains("\"code\":\"UNKNOWN_COMMAND\""))
    }

    @Test fun `cancel error remains valid UTF-8 with Portuguese accents`() {
        val out = mutableListOf<String>()
        val lines = ArrayDeque(listOf("{\"type\":\"cancel\",\"requestId\":\"r3\",\"sessionId\":\"s1\"}"))
        EngineHost(input = { lines.removeFirstOrNull() }, output = out::add).run()
        val wire = out.single().toByteArray(StandardCharsets.UTF_8).toString(StandardCharsets.UTF_8)
        assertTrue(wire.contains("Nenhuma medição ativa"))
        assertTrue(wire.contains("\"code\":\"SESSION_NOT_FOUND\""))
    }

    @Test fun `library diagnostic id uses only the homologated catalog id`() {
        val supported = PcGame(
            id = "steam_1938090",
            title = "Call of Duty",
            platform = GamePlatform.STEAM,
            networkSupport = GameNetworkSupport.LagcheckSupported("warzone")
        )
        val general = PcGame(
            id = "steam_123",
            title = "Jogo geral",
            platform = GamePlatform.STEAM,
            networkSupport = GameNetworkSupport.GeneralConnectionOnly()
        )

        assertEquals("warzone", supported.diagnosticGameId())
        assertNull(general.diagnosticGameId())
    }
}
