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

    fun resolveCandidates(
        context: GameContext,
        payload: CatalogPayload,
        now: Instant = Instant.now(),
        excludingRouteIds: Set<String> = emptySet()
    ): List<ResolvedMeasurementContext> {
        validateStructure(context)
        if (context.isGenericGaming) {
            val profileId = QualityProfileId.BATTLE_ROYALE_COMPETITIVE
            val ruleVersion = payload.profiles.firstOrNull { it.id == profileId.rawValue }?.ruleVersion
                ?: QualityEvaluator.ruleVersion(profileId)
            return payload.regions.map { region ->
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
            }
        }

        val game = payload.games.firstOrNull { it.id == context.gameId } ?: return emptyList()
        val gameContext = selectContext(game, context) ?: return emptyList()
        if (!gameContext.availableForMeasurement) return emptyList()

        val profile = payload.profiles.firstOrNull { it.id == gameContext.profileId }
        val profileId = QualityProfileId.fromRaw(gameContext.profileId)
        if (profile == null || profileId == null) return emptyList()

        // Decisão 90: a AWS é referência regional. A rota ativa autoriza essa
        // classe de medição e cada região assinada entra na pré-leitura; o
        // vencedor vem da regra de P50, nunca do mercado ou da ordem da lista.
        val route = gameContext.routes?.firstOrNull { r ->
            r.id !in excludingRouteIds && r.kind == RouteKind.AWS_FALLBACK &&
                r.status == RouteStatus.ACTIVE && isCurrent(r, now)
        } ?: return emptyList()

        return payload.regions.map {
            ResolvedMeasurementContext(
                context = context,
                catalogVersion = payload.catalogVersion,
                profileId = profileId,
                profileRuleVersion = profile.ruleVersion,
                regionId = it.id,
                destination = it.probe,
                strategy = route.strategy,
                confidence = route.confidence,
                precisionKey = route.precisionKey,
                routeId = route.id,
                routeKind = route.kind
            )
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
     * Política automática de uma rota v3, sem abrir socket. Espelho de `automaticRoutePlan` do iOS: só candidatos
     * assinados entram, em ordem (prioridade, id), e a aplicação precisa pré-validá-los antes de usar qualquer um.
     * `null` quando não há contexto disponível ou AWS assinada vigente para voltar.
     */
    fun automaticRoutePlan(
        context: GameContext,
        payload: CatalogPayload,
        now: Instant = Instant.now()
    ): RoutePlan? {
        if (payload.schemaVersion != RemoteCatalogVerifier.ROUTED_SCHEMA_VERSION) return null
        validateStructure(context)
        if (context.isGenericGaming) return null
        val game = payload.games.firstOrNull { it.id == context.gameId } ?: return null
        val gameContext = selectContext(game, context)?.takeIf { it.availableForMeasurement } ?: return null
        val profile = payload.profiles.firstOrNull { it.id == gameContext.profileId } ?: return null
        val profileId = QualityProfileId.fromRaw(gameContext.profileId) ?: return null
        val routes = gameContext.routes ?: return null
        val fallbackRoute = routes.firstOrNull {
            it.kind == RouteKind.AWS_FALLBACK && it.status == RouteStatus.ACTIVE && isCurrent(it, now)
        } ?: return null
        val fallbackDestination = resolvedDestination(fallbackRoute, payload.regions) ?: return null

        fun resolved(route: CatalogRoute, destination: ProbeDestination, routeId: String) = ResolvedMeasurementContext(
            context = context,
            catalogVersion = payload.catalogVersion,
            profileId = profileId,
            profileRuleVersion = profile.ruleVersion,
            regionId = route.regionId,
            destination = destination,
            strategy = route.strategy,
            confidence = route.confidence,
            precisionKey = route.precisionKey,
            routeId = routeId,
            routeKind = route.kind
        )

        val owned = routes
            .filter { it.kind == RouteKind.GAME_OWNED && it.status == RouteStatus.ACTIVE && isCurrent(it, now) }
            .flatMap { route ->
                route.candidates.orEmpty().map { c ->
                    OwnedRouteCandidate(resolved(route, c.destination, route.id + "-" + c.id), c.identity, c.priority)
                }
            }
            .sortedWith(compareBy({ it.priority }, { it.context.routeId }))
        return RoutePlan(owned, resolved(fallbackRoute, fallbackDestination, fallbackRoute.id))
    }

    /**
     * Primeira rota ativa e vigente. Rota própria com candidatos A2S nunca sai daqui: exige a pré-validação de
     * identidade de `automaticRoutePlan`; sem ela, cai na AWS, igual ao `resolve` do iOS.
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
