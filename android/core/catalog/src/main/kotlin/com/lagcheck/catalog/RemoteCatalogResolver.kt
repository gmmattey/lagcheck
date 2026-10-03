package com.lagcheck.catalog

import com.lagcheck.domain.model.MeasurementConfidence
import com.lagcheck.domain.model.QualityProfileId
import com.lagcheck.domain.rules.QualityEvaluator
import java.time.Instant

/** Resolve jogo + plataforma em um destino de medição, só a partir de payload já verificado. */
object RemoteCatalogResolver {

    fun resolve(
        context: GameContext,
        payload: CatalogPayload,
        now: Instant = Instant.now(),
        excludingRouteIds: Set<String> = emptySet()
    ): RemoteCatalogResolution {
        validateStructure(context)
        if (context.isGenericGaming) return resolveGenericGaming(context, payload)

        val game = payload.games.firstOrNull { it.id == context.gameId }
            ?: throw CatalogResolutionException("unsupportedGame")
        val gameContext = selectContext(game, context)
            ?: throw CatalogResolutionException("unsupportedGame")
        if (!gameContext.availableForMeasurement) return RemoteCatalogResolution.Unavailable

        val profile = payload.profiles.firstOrNull { it.id == gameContext.profileId }
        val profileId = QualityProfileId.fromRaw(gameContext.profileId)
        if (profile == null || profileId == null) throw CatalogResolutionException("unknownProfile")

        val route = selectRoute(gameContext, payload.regions, now, excludingRouteIds) ?: return RemoteCatalogResolution.Unavailable
        val destination = resolvedDestination(route, payload.regions) ?: return RemoteCatalogResolution.Unavailable
        return RemoteCatalogResolution.Available(
            ResolvedMeasurementContext(
                context = context,
                catalogVersion = payload.catalogVersion,
                profileId = profileId,
                profileRuleVersion = profile.ruleVersion,
                regionId = route.regionId,
                destination = destination,
                strategy = route.strategy,
                confidence = route.confidence,
                precisionKey = route.precisionKey,
                routeId = route.id,
                routeKind = route.kind
            )
        )
    }

    /** Prefere o contexto de chave exata da plataforma (ex.: "android"), depois as chaves legadas na ordem declarada. */
    private fun selectContext(game: CatalogGame, request: GameContext): CatalogGameContext? {
        for (key in request.platform.catalogKeys) {
            game.contexts.firstOrNull { it.market == request.market && key in it.platformKeys }?.let { return it }
        }
        return null
    }

    private fun validateStructure(c: GameContext) {
        if (c.gameId.isEmpty() || c.gameId != c.gameId.lowercase()) throw CatalogResolutionException("invalidGameID")
        if (c.market.length != 2 || c.market != c.market.uppercase() || !c.market.all { it.isLetter() }) {
            throw CatalogResolutionException("invalidMarket")
        }
    }

    private fun resolveGenericGaming(context: GameContext, payload: CatalogPayload): RemoteCatalogResolution {
        val profileId = QualityProfileId.BATTLE_ROYALE_COMPETITIVE
        val ruleVersion = payload.profiles.firstOrNull { it.id == profileId.rawValue }?.ruleVersion
            ?: QualityEvaluator.ruleVersion(profileId)
        val preferred = when (context.market) { "US" -> "us-east-1"; else -> "sa-east-1" }
        val region = payload.regions.firstOrNull { it.id == preferred } ?: payload.regions.firstOrNull()
            ?: throw CatalogResolutionException("unknownRegion")
        return RemoteCatalogResolution.Available(
            ResolvedMeasurementContext(
                context = context,
                catalogVersion = payload.catalogVersion,
                profileId = profileId,
                profileRuleVersion = ruleVersion,
                regionId = region.id,
                destination = region.probe,
                strategy = MeasurementStrategy.GENERIC_REGION,
                confidence = MeasurementConfidence.MEDIUM,
                precisionKey = "regionalReference"
            )
        )
    }

    /**
     * Primeira rota ativa e vigente. Rota própria com candidatos A2S exige pré-validação de identidade que o
     * Android ainda não faz (nenhuma está ativa no catálogo atual); nesse caso cai na AWS, igual ao `resolve` do iOS.
     */
    private fun selectRoute(
        ctx: CatalogGameContext,
        regions: List<CatalogRegion>,
        now: Instant,
        excluding: Set<String>
    ): CatalogRoute? = ctx.routes?.firstOrNull { r ->
        r.id !in excluding && r.status == RouteStatus.ACTIVE && isCurrent(r, now) &&
            !(r.kind == RouteKind.GAME_OWNED && r.candidates != null) &&
            resolvedDestination(r, regions) != null
    }

    private fun isCurrent(route: CatalogRoute, now: Instant): Boolean {
        val until = route.validUntil ?: return true
        val date = until.toInstantOrNull() ?: return false
        return date.isAfter(now)
    }

    private fun resolvedDestination(route: CatalogRoute, regions: List<CatalogRegion>): ProbeDestination? =
        route.destination
            ?: route.candidates?.sortedWith(compareBy({ it.priority }, { it.id }))?.firstOrNull()?.destination
            ?: regions.firstOrNull { it.id == route.regionId }?.probe
}
