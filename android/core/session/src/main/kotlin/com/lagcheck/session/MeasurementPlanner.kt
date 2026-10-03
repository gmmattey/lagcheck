package com.lagcheck.session

import com.lagcheck.catalog.CatalogPayload
import com.lagcheck.catalog.CatalogResolutionException
import com.lagcheck.catalog.GameContext
import com.lagcheck.catalog.Platform
import com.lagcheck.catalog.RemoteCatalogResolution
import com.lagcheck.catalog.RemoteCatalogResolver
import com.lagcheck.catalog.ResolvedMeasurementContext
import java.time.Instant

/** Por que não foi possível medir. Nunca vira nota inventada: a UI mostra estado indisponível. */
enum class PlanFailure { UNSUPPORTED_GAME_OR_PLATFORM, ROUTE_UNAVAILABLE }

sealed class PlanResult {
    data class Ready(val context: ResolvedMeasurementContext) : PlanResult()
    data class Failed(val reason: PlanFailure) : PlanResult()
}

object PlatformLabels {
    const val GENERIC_GAME_ID = "check-geral"

    /** Rótulo da UI → plataforma do catálogo. Celular (Android) usa o contexto de celular do catálogo. */
    fun toPlatform(label: String): Platform {
        val l = label.lowercase()
        return when {
            "playstation" in l || l == "ps" || l.startsWith("ps5") || l.startsWith("ps4") -> Platform.PLAYSTATION
            "xbox" in l -> Platform.XBOX
            "nintendo" in l || "switch" in l -> Platform.NINTENDO
            l == "pc" || "windows" in l -> Platform.PC
            else -> Platform.MOBILE // "Mobile", "Android", "iPhone"
        }
    }

    /** Plataforma do catálogo → rótulo da UI. O contexto de celular aparece como "Mobile". */
    fun toLabel(platform: Platform): String = when (platform) {
        Platform.MOBILE -> "Mobile"
        Platform.PLAYSTATION -> "PlayStation"
        Platform.XBOX -> "Xbox"
        Platform.PC -> "PC"
        Platform.NINTENDO -> "Nintendo"
    }

    fun labelForCatalogKey(key: String): String? = when (key) {
        "iphone", "android" -> "Mobile"
        "playstation" -> "PlayStation"
        "xbox" -> "Xbox"
        "pc" -> "PC"
        "nintendo" -> "Nintendo"
        else -> null
    }
}

/** Ponte entre o pedido da UI (jogo + plataforma) e o destino assinado do catálogo. */
object MeasurementPlanner {
    fun plan(
        payload: CatalogPayload,
        gameId: String,
        platformLabel: String,
        market: String = "BR",
        now: Instant = Instant.now()
    ): PlanResult {
        val platform = PlatformLabels.toPlatform(platformLabel)
        val context = if (gameId == PlatformLabels.GENERIC_GAME_ID) GameContext.genericGaming(market, platform)
        else GameContext(gameId, market, platform)
        return try {
            when (val r = RemoteCatalogResolver.resolve(context, payload, now)) {
                is RemoteCatalogResolution.Available -> PlanResult.Ready(r.context)
                RemoteCatalogResolution.Unavailable -> PlanResult.Failed(PlanFailure.ROUTE_UNAVAILABLE)
            }
        } catch (_: CatalogResolutionException) {
            PlanResult.Failed(PlanFailure.UNSUPPORTED_GAME_OR_PLATFORM)
        }
    }

    fun planRegional(
        payload: CatalogPayload,
        gameId: String,
        platformLabel: String,
        market: String = "BR",
        now: Instant = Instant.now()
    ): com.lagcheck.domain.rules.RegionalSelectionSnapshot<GameContext, ResolvedCandidate>? {
        val platform = PlatformLabels.toPlatform(platformLabel)
        val context = if (gameId == PlatformLabels.GENERIC_GAME_ID) GameContext.genericGaming(market, platform)
        else GameContext(gameId, market, platform)

        return try {
            val contexts = RemoteCatalogResolver.resolveCandidates(context, payload, now)
            if (contexts.isEmpty()) null
            else {
                val candidates = contexts.mapIndexed { index, ctx ->
                    ResolvedCandidate(
                        regionId = ctx.regionId,
                        priority = index,
                        catalogVersion = payload.catalogVersion,
                        context = context,
                        resolvedContext = ctx
                    )
                }
                com.lagcheck.domain.rules.RegionalSelectionSnapshot(
                    catalogVersion = payload.catalogVersion,
                    context = context,
                    candidates = candidates
                )
            }
        } catch (_: CatalogResolutionException) {
            null
        }
    }
}

data class ResolvedCandidate(
    override val regionId: String,
    override val priority: Int,
    override val catalogVersion: String,
    override val context: GameContext,
    val resolvedContext: ResolvedMeasurementContext
) : com.lagcheck.domain.rules.RegionalSelectionCandidate<GameContext>
