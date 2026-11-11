package com.lagcheck.desktop

import com.lagcheck.desktop.library.network.CatalogGame
import com.lagcheck.desktop.library.network.NetworkSupportResolver

/** Liga a biblioteca ao catálogo local embarcado, a mesma fonte que decide o que o Check consegue medir. */
object DesktopNetworkSupport {
    private val catalogGames: List<CatalogGame> by lazy { Measurement.games.map { CatalogGame(it.id, it.name) } }

    val resolver = NetworkSupportResolver(
        catalog = { catalogGames },
        regionLabel = { Measurement.measuredRegion(it)?.label },
    )
}
