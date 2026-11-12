package com.lagcheck.domain.rules

import com.lagcheck.domain.model.AppDeepLink
import com.lagcheck.domain.model.DeepLinkParser
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.HostDuelPayload
import com.lagcheck.domain.model.HostDuelResolver
import com.lagcheck.domain.model.HostDuelWinner
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class HostDuelModelsTest {

    @Test
    fun testPayloadSerializationAndParsingRoundtrip() {
        val original = HostDuelPayload(
            gameId = "valorant",
            regionId = "sa-east-1",
            p50Ms = 18.4,
            packetLossPercent = 0.0,
            jitterMs = 1.2,
            verdict = GameReadinessVerdict.READY,
            timestamp = 1730848800L,
            challengerNick = "Luiz"
        )

        val webUrl = original.toWebUrl()
        assertTrue(webUrl.contains("https://lagcheck.signallq.com/vs"))
        assertTrue(webUrl.contains("g=valorant"))
        assertTrue(webUrl.contains("n=Luiz"))

        val parsed = HostDuelPayload.parse(webUrl)
        assertNotNull(parsed)
        assertEquals("valorant", parsed?.gameId)
        assertEquals("sa-east-1", parsed?.regionId)
        assertEquals(18.4, parsed?.p50Ms ?: 0.0, 0.1)
        assertEquals(0.0, parsed?.packetLossPercent ?: 0.0, 0.1)
        assertEquals(1.2, parsed?.jitterMs ?: 0.0, 0.1)
        assertEquals(GameReadinessVerdict.READY, parsed?.verdict)
        assertEquals(1730848800L, parsed?.timestamp)
        assertEquals("Luiz", parsed?.challengerNick)
    }

    @Test
    fun testParsesCustomSchemeDuelUrl() {
        val customUrl = "lagcheck://vs?g=cs2&r=sao_paulo&p=24.5&l=1.0&j=3.0&v=caution&t=1730848800&n=FalleN"
        val parsed = HostDuelPayload.parse(customUrl)

        assertNotNull(parsed)
        assertEquals("cs2", parsed?.gameId)
        assertEquals("FalleN", parsed?.challengerNick)
        assertEquals(GameReadinessVerdict.CAUTION, parsed?.verdict)
    }

    @Test
    fun testDeepLinkParserRecognizesHostDuel() {
        val url = "https://lagcheck.signallq.com/vs?g=valorant&r=sa-east-1&p=18.0&l=0.0&j=1.0&v=ready&t=1730848800&n=Luiz"
        val deepLink = DeepLinkParser.parse(url)

        assertTrue(deepLink is AppDeepLink.HostDuel)
        val payload = (deepLink as AppDeepLink.HostDuel).payload
        assertEquals("Luiz", payload.challengerNick)
        assertEquals(18.0, payload.p50Ms, 0.01)
    }

    @Test
    fun testTTLAndExpirationLogic() {
        val fixedTs = 1730848800L
        val fixedNowMs = fixedTs * 1000L

        val payload = HostDuelPayload(
            gameId = "valorant",
            regionId = "sa-east-1",
            p50Ms = 18.0,
            packetLossPercent = 0.0,
            jitterMs = 1.0,
            verdict = GameReadinessVerdict.READY,
            timestamp = fixedTs
        )

        // No instante de criação
        assertFalse(payload.isExpired(fixedNowMs))
        assertEquals(1800L, payload.remainingSeconds(fixedNowMs))

        // 15 minutos depois
        val midMs = (fixedTs + 900L) * 1000L
        assertFalse(payload.isExpired(midMs))
        assertEquals(900L, payload.remainingSeconds(midMs))

        // 31 minutos depois: expirado
        val expiredMs = (fixedTs + 1860L) * 1000L
        assertTrue(payload.isExpired(expiredMs))
        assertEquals(0L, payload.remainingSeconds(expiredMs))
    }

    @Test
    fun testResolutionReadyVsCautionFavorsReadyRegardlessOfPing() {
        val challengerReady = HostDuelPayload(
            gameId = "valorant",
            regionId = "sa-east-1",
            p50Ms = 35.0, // Maior ping
            packetLossPercent = 0.0,
            jitterMs = 1.0,
            verdict = GameReadinessVerdict.READY,
            challengerNick = "Luiz"
        )

        val opponentCaution = HostDuelPayload(
            gameId = "valorant",
            regionId = "sa-east-1",
            p50Ms = 20.0, // Menor ping bruto, mas oscilando
            packetLossPercent = 2.0,
            jitterMs = 15.0,
            verdict = GameReadinessVerdict.CAUTION,
            challengerNick = "Pedro"
        )

        val resolution = HostDuelResolver.resolve(challengerReady, opponentCaution)
        assertEquals(HostDuelWinner.CHALLENGER, resolution.winner)
        assertTrue(resolution.challengerLead)
        assertTrue(resolution.headline.contains("LUIZ PUXA A RANKED"))
    }

    @Test
    fun testResolutionTiebreakByP50WhenBothReady() {
        val luiz = HostDuelPayload(
            gameId = "valorant",
            regionId = "sa-east-1",
            p50Ms = 18.0,
            packetLossPercent = 0.0,
            jitterMs = 1.0,
            verdict = GameReadinessVerdict.READY,
            challengerNick = "Luiz"
        )

        val pedro = HostDuelPayload(
            gameId = "valorant",
            regionId = "sa-east-1",
            p50Ms = 46.0,
            packetLossPercent = 0.0,
            jitterMs = 1.5,
            verdict = GameReadinessVerdict.READY,
            challengerNick = "Pedro"
        )

        val resolution = HostDuelResolver.resolve(luiz, pedro)
        assertEquals(HostDuelWinner.CHALLENGER, resolution.winner)
        assertEquals(28.0, resolution.deltaMs, 0.1)
        assertTrue(resolution.headline.contains("LUIZ PUXA A RANKED"))
    }

    @Test
    fun testDiscordShareTextFormat() {
        val payload = HostDuelPayload(
            gameId = "valorant",
            regionId = "sa-east-1",
            p50Ms = 18.2,
            packetLossPercent = 0.0,
            jitterMs = 1.0,
            verdict = GameReadinessVerdict.READY,
            challengerNick = "Luiz"
        )

        val text = payload.generateDiscordShareText()
        assertTrue(text.contains("⚔️ [DUELO DE HOST] Luiz cravou 18ms no Valorant (0% perda)."))
        assertTrue(text.contains("https://lagcheck.signallq.com/vs?"))
    }
}
