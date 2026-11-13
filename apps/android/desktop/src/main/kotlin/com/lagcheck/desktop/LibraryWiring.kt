package com.lagcheck.desktop

import com.lagcheck.desktop.library.artwork.ArtworkDiskCache
import com.lagcheck.desktop.library.artwork.GameArtworkResolver
import com.lagcheck.desktop.library.artwork.HttpArtworkFetcher
import com.lagcheck.desktop.library.artwork.SteamCdnSource
import com.lagcheck.desktop.library.artwork.SteamLibraryCacheSource
import com.lagcheck.desktop.library.artwork.EpicCatalogSource
import com.lagcheck.desktop.library.artwork.XboxPackageArtSource
import com.lagcheck.desktop.library.artwork.StoreCatalogArtSource
import com.lagcheck.desktop.library.scanner.StoreCatalog
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

/** Catálogo da Microsoft Store: só consulta a rede com o download de imagens ligado e guarda as respostas em disco. */
object DesktopStoreCatalog {
    val catalog: StoreCatalog by lazy {
        StoreCatalog(LocalData.directory.resolve("store-catalog.json").toFile(), enabled = { DesktopArtwork.downloadEnabled })
    }
}

/** Descrição, estúdio, lançamento, gêneros e modos de jogo; mesma regra de rede das imagens (opção de Ajustes). */
object DesktopGameInfo {
    val service: com.lagcheck.desktop.library.info.GameInfoService by lazy {
        com.lagcheck.desktop.library.info.GameInfoService(
            cacheDir = LocalData.directory.resolve("info-cache").toFile(),
            enabled = { DesktopArtwork.downloadEnabled },
            epic = EpicCatalogSource(),
            store = DesktopStoreCatalog.catalog,
        )
    }
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
            localSources = listOf(SteamLibraryCacheSource { steamRoot }, XboxPackageArtSource()),
            remoteSources = listOf(SteamCdnSource(), EpicCatalogSource(), StoreCatalogArtSource(DesktopStoreCatalog.catalog)),
            cache = ArtworkDiskCache(LocalData.directory.resolve("artwork-cache")),
            fetcher = HttpArtworkFetcher(),
            remoteEnabled = { downloadEnabled },
        )
    }
}
