package com.lagcheck.catalog

import com.google.common.truth.Truth.assertThat
import com.lagcheck.catalog.CatalogTestSupport.NOW
import com.lagcheck.catalog.CatalogTestSupport.realEnvelopeBytes
import com.lagcheck.domain.model.MeasurementConfidence
import com.lagcheck.domain.model.QualityProfileId
import java.time.Instant
import org.junit.Assert.assertThrows
import org.junit.Test

/** Resolução contra o catálogo v3 real publicado. */
class RemoteCatalogResolverTest {
    private val payload = RemoteCatalogVerifier.verifyAndDecode(realEnvelopeBytes(), NOW)

    private fun available(game: String, platform: Platform): ResolvedMeasurementContext =
        (RemoteCatalogResolver.resolve(GameContext(game, "BR", platform), payload, NOW) as RemoteCatalogResolution.Available).context

    @Test fun fortniteOnMobileUsesAwsFallbackWithGameLiftBeacon() {
        val r = available("fortnite", Platform.MOBILE)
        assertThat(r.destination).isEqualTo(ProbeDestination("gamelift-ping.sa-east-1.api.aws", 7770, ProbeProtocolKind.GAMELIFT_PING))
        assertThat(r.routeKind).isEqualTo(RouteKind.AWS_FALLBACK)
        assertThat(r.routeId).isEqualTo("fortnite-iphone-aws")
        assertThat(r.confidence).isEqualTo(MeasurementConfidence.MEDIUM)
        assertThat(r.strategy).isEqualTo(MeasurementStrategy.GENERIC_REGION)
        assertThat(r.profileId).isEqualTo(QualityProfileId.BATTLE_ROYALE_COMPETITIVE)
        assertThat(r.profileRuleVersion).isEqualTo("pilot-2026.09.08.1")
        assertThat(r.regionId).isEqualTo("sa-east-1")
    }

    @Test fun fortniteOnConsolesAndPcResolve() {
        for (p in listOf(Platform.PLAYSTATION, Platform.XBOX, Platform.PC, Platform.NINTENDO)) {
            assertThat(available("fortnite", p).destination.host).isEqualTo("gamelift-ping.sa-east-1.api.aws")
        }
    }

    @Test fun profilesFollowTheCatalog() {
        assertThat(available("roblox", Platform.MOBILE).profileId).isEqualTo(QualityProfileId.CASUAL_REALTIME)
        assertThat(available("brawl-stars", Platform.MOBILE).profileId).isEqualTo(QualityProfileId.MOBILE_REALTIME)
        assertThat(available("valorant", Platform.PC).profileId).isEqualTo(QualityProfileId.BATTLE_ROYALE_COMPETITIVE)
    }

    @Test fun gameWithoutMobileContextIsUnsupported() {
        // Valorant só tem contexto de console/PC no catálogo.
        assertThrows(CatalogResolutionException::class.java) {
            RemoteCatalogResolver.resolve(GameContext("valorant", "BR", Platform.MOBILE), payload, NOW)
        }
    }

    @Test fun unknownGameIsUnsupported() {
        assertThrows(CatalogResolutionException::class.java) {
            RemoteCatalogResolver.resolve(GameContext("nope", "BR", Platform.MOBILE), payload, NOW)
        }
    }

    @Test fun invalidRequestStructureIsRejected() {
        assertThrows(CatalogResolutionException::class.java) { RemoteCatalogResolver.resolve(GameContext("Fortnite", "BR"), payload, NOW) }
        assertThrows(CatalogResolutionException::class.java) { RemoteCatalogResolver.resolve(GameContext("fortnite", "br"), payload, NOW) }
    }

    @Test fun genericGamingUsesCompetitiveProfileAndSaoPaulo() {
        val r = (RemoteCatalogResolver.resolve(GameContext.genericGaming(), payload, NOW) as RemoteCatalogResolution.Available).context
        assertThat(r.regionId).isEqualTo("sa-east-1")
        assertThat(r.profileId).isEqualTo(QualityProfileId.BATTLE_ROYALE_COMPETITIVE)
        assertThat(r.confidence).isEqualTo(MeasurementConfidence.MEDIUM)
    }

    @Test fun genericGamingPreReadsOnlyThePrimaryRouteForItsMarket() {
        val brazil = RemoteCatalogResolver.resolveCandidates(GameContext.genericGaming("BR"), payload, NOW)
        val unitedStates = RemoteCatalogResolver.resolveCandidates(GameContext.genericGaming("US"), payload, NOW)
        assertThat(brazil.map { it.regionId }).containsExactly("sa-east-1")
        // O catálogo publicado só contém SA; US usa o primeiro destino assinado.
        assertThat(unitedStates.map { it.regionId }).containsExactly("sa-east-1")
    }

    @Test fun excludingTheOnlyActiveRouteMakesItUnavailableInsteadOfInventingOne() {
        val r = RemoteCatalogResolver.resolve(
            GameContext("fortnite", "BR", Platform.MOBILE), payload, NOW, excludingRouteIds = setOf("fortnite-iphone-aws")
        )
        assertThat(r).isEqualTo(RemoteCatalogResolution.Unavailable)
    }

    @Test fun pendingOwnedRoutesAreNeverMeasured() {
        for (game in payload.games) for (ctx in game.contexts) {
            val owned = ctx.routes!!.filter { it.kind == RouteKind.GAME_OWNED }
            assertThat(owned.all { it.status == RouteStatus.PENDING }).isTrue()
        }
    }

    @Test fun everyMobileGameInTheCatalogResolvesOrIsExplicitlyAbsent() {
        val resolvable = payload.games.mapNotNull { g ->
            runCatching { RemoteCatalogResolver.resolve(GameContext(g.id, "BR", Platform.MOBILE), payload, NOW) }.getOrNull()?.let { g.id }
        }
        assertThat(resolvable).containsAtLeast(
            "fortnite", "call-of-duty-mobile", "free-fire", "pubg-mobile", "brawl-stars", "wild-rift",
            "roblox", "minecraft", "blood-strike", "eafc", "rainbow-six-mobile", "rocket-league-sideswipe"
        )
    }

    @Test fun routeWithExpiredValidityIsSkipped() {
        val expired = payload.copy(
            games = payload.games.map { g ->
                if (g.id != "fortnite") g else g.copy(contexts = g.contexts.map { c ->
                    c.copy(routes = c.routes!!.map { r -> if (r.kind == RouteKind.AWS_FALLBACK) r.copy(validUntil = "2026-10-01T00:00:00Z") else r })
                })
            }
        )
        assertThat(RemoteCatalogResolver.resolve(GameContext("fortnite", "BR", Platform.MOBILE), expired, NOW))
            .isEqualTo(RemoteCatalogResolution.Unavailable)
        assertThat(RemoteCatalogResolver.resolve(GameContext("fortnite", "BR", Platform.MOBILE), expired, Instant.parse("2026-09-30T00:00:00Z")))
            .isInstanceOf(RemoteCatalogResolution.Available::class.java)
    }
}
