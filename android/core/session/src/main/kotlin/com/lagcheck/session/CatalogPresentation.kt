package com.lagcheck.session

import com.lagcheck.catalog.CatalogPayload
import com.lagcheck.domain.model.CatalogGame
import com.lagcheck.domain.model.OfficialGameCatalog
import java.net.URI

/** Presentation metadata only. Measurement always resolves the verified payload. */
object CatalogPresentation {
    fun games(payload: CatalogPayload): List<CatalogGame> = payload.games.mapNotNull { game ->
        val platforms = game.contexts.filter { it.market == "BR" && it.availableForMeasurement }
            .flatMap { it.platformKeys }.mapNotNull(PlatformLabels::labelForCatalogKey).distinct()
        if (platforms.isEmpty()) return@mapNotNull null
        val local = (OfficialGameCatalog.games + OfficialGameCatalog.pendingExpansion).firstOrNull { it.id == game.id }
        val url = game.artwork?.let { art -> payload.assetBaseUrl?.let { base ->
            runCatching { URI(base).resolve(art.path).toString() }.getOrNull()
        } }
        CatalogGame(game.id, game.name, local?.category ?: "Online", platforms,
            drawableResName = local?.drawableResName ?: "", artworkUrl = url,
            artworkRevision = payload.catalogVersion)
    }
}
