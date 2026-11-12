package com.lagcheck.desktop

import com.lagcheck.desktop.library.artwork.ArtworkDiskCache
import com.lagcheck.desktop.library.artwork.GameArtworkResolver
import com.lagcheck.desktop.library.artwork.HttpArtworkFetcher
import com.lagcheck.desktop.library.artwork.SteamCdnSource
import com.lagcheck.desktop.library.artwork.SteamLibraryCacheSource
import com.lagcheck.desktop.library.network.CatalogGame
import com.lagcheck.desktop.library.network.NetworkSupportResolver
import com.lagcheck.desktop.library.scanner.SteamScanner

/** Liga a biblioteca ao catálogo local embarcado, a mesma fonte que decide o que o Check consegue medir. */
object DesktopNetworkSupport {
    private val catalogGames: List<CatalogGame> by lazy { Measurement.games.map { CatalogGame(it.id, it.name) } }

    val resolver = NetworkSupportResolver(
        catalog = { catalogGames },
        regionLabel = { Measurement.measuredRegion(it)?.label },
    )
}

/**
 * Imagens dos jogos: cache do app, cache do cliente Steam neste PC e, se o usuário deixar ligado,
 * a imagem oficial no CDN da Steam. Nada é enviado além do pedido da imagem de um jogo.
 */
object DesktopArtwork {
    /** Espelha a opção "Baixar imagens dos jogos" de Ajustes. */
    @Volatile var downloadEnabled: Boolean = true

    // A pasta da Steam é procurada uma vez só: no Windows isso consulta o registro.
    private val steamRoot by lazy { SteamScanner().detectSteamRoot() }

    val resolver: GameArtworkResolver by lazy {
        GameArtworkResolver(
            localSources = listOf(SteamLibraryCacheSource { steamRoot }),
            remoteSources = listOf(SteamCdnSource()),
            cache = ArtworkDiskCache(LocalData.directory.resolve("artwork-cache")),
            fetcher = HttpArtworkFetcher(),
            remoteEnabled = { downloadEnabled },
        )
    }
}
