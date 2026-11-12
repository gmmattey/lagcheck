package com.lagcheck.desktop

import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.ImageComposeScene
import androidx.compose.ui.unit.Density
import com.lagcheck.desktop.ds.LagCheckTheme
import com.lagcheck.desktop.location.ApproxLocation
import com.lagcheck.desktop.location.RegionCoordinates
import com.lagcheck.desktop.ui.AppShell
import com.lagcheck.desktop.ui.CaptureFocusTarget
import com.lagcheck.desktop.ui.map.MapPoint
import com.lagcheck.domain.model.GameReadinessVerdict
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import org.jetbrains.skia.EncodedImageFormat
import com.lagcheck.desktop.library.artwork.ArtworkDiskCache
import com.lagcheck.desktop.library.artwork.GameArtworkResolver
import com.lagcheck.desktop.library.artwork.HttpArtworkFetcher
import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import com.lagcheck.desktop.library.repository.LibraryRepository
import com.lagcheck.desktop.library.repository.LibraryStore
import com.lagcheck.desktop.library.network.CatalogGame
import com.lagcheck.desktop.library.network.NetworkSupportResolver
import com.lagcheck.desktop.library.scanner.LibraryScanner
import com.lagcheck.desktop.library.scanner.ScanResult
import java.io.File
import java.nio.file.Files
import java.time.LocalDateTime

/** Renderiza as telas em PNG sem janela nem rede (dados fictícios só para inspeção visual). */
@OptIn(ExperimentalComposeUiApi::class)
fun renderShots(dir: String) {
    data class ShotVariant(
        val scrollOffset: Int = 0,
        val suffix: String = "",
        val focusTarget: CaptureFocusTarget? = null
    )

    File(dir).mkdirs()
    // Estado efêmero e isolado: capturas não podem herdar jogos/favoritos de
    // outro cenário, nem gravar as preferências reais do usuário.
    val shotStateRoot = Files.createTempDirectory("lagcheck-shots-")
    val series = listOf(20.0, 22.0, 19.0, 21.0, 85.0, 24.0, 20.0, 19.0, 23.0, 30.0, 52.0, 61.0, 44.0, 38.0, 27.0, 25.0)
    fun entry(v: GameReadinessVerdict, t: String) = HistoryEntry(LocalDateTime.now(), t, "São Paulo", v, 21.0, 4.5, 0.0, series, 10, true)
    fun checkState(s: AppState) {
        s.route = Route.Check(null)
        s.ratio = 0.62f
        s.livePing = 23.0
        s.series.addAll(series)
        s.loadStart = 10
        s.approximateLocationEnabled = false
        s.locationLoading = false
        s.measuredRegionId = "sa-east-1"
        s.measuredRegion = requireNotNull(RegionCoordinates.forRegion("sa-east-1"))
        s.measuredRegionLabel = "São Paulo"
    }
    fun mapCheckState(s: AppState, animated: Boolean) {
        checkState(s)
        // Dado de exemplo exclusivo das capturas: nenhuma localização é inventada no app.
        val user = MapPoint("Fortaleza", -3.73, -38.52)
        val region = requireNotNull(RegionCoordinates.forRegion("sa-east-1"))
        s.approximateLocationEnabled = true
        s.approximateLocation = ApproxLocation(city = "Fortaleza", country = "BR", lat = user.lat, lon = user.lon)
        s.measuredRegionId = "sa-east-1"
        s.measuredRegion = region
        s.measuredRegionLabel = "São Paulo"
        s.routeMap.reset()
        if (animated) {
            s.changeReduceMotion(false)
            // RTTs já recebidos iluminam os dois extremos; a última sonda fica em voo.
            s.routeMap.onProbeReturned(1, 21.0)
            s.routeMap.onProbeReturned(2, 23.0)
            s.routeMap.onProbeReturned(3, 24.0)
            s.routeMap.onProbeSent(4)
            s.routeMap.updateTime(System.nanoTime() + 120_000_000L, user, region)
        } else {
            s.routeMap.onProbeReturned(1, 21.0)
            s.routeMap.onProbeReturned(2, 23.0)
            s.routeMap.onProbeReturned(3, 24.0)
        }
    }
    data class ShotSpec(
        val setup: (AppState) -> Unit,
        val scanner: LibraryScanner = ShotsLibraryScanner,
    )

    val shots = linkedMapOf<String, ShotSpec>(
        "notice" to ShotSpec({ it.history.add(entry(GameReadinessVerdict.READY, "Conexão geral")) }),
        "home" to ShotSpec({ it.history.add(entry(GameReadinessVerdict.READY, "Conexão geral")) }),
        // Estados de revisão exclusivos do --shots. Os jogos abaixo nunca são lidos pelo app.
        "library-empty" to ShotSpec({}, scanner = EmptyShotsLibraryScanner),
        "library-favorites" to ShotSpec({ state ->
            state.library.games.take(2).forEach(state.library::toggleFavorite)
            state.library.filter = com.lagcheck.desktop.library.repository.LibraryFilter.FAVORITES
        }),
        "library-steam" to ShotSpec({ state ->
            state.library.filter = com.lagcheck.desktop.library.repository.LibraryFilter.STEAM
        }),
        "library-recent" to ShotSpec({ state ->
            state.library.filter = com.lagcheck.desktop.library.repository.LibraryFilter.RECENT
        }),
        "library-search" to ShotSpec({ state ->
            state.library.searchQuery = "rocket"
        }),
        "library-no-match" to ShotSpec({ state ->
            state.library.searchQuery = "inexistente"
        }),
        "games" to ShotSpec({ it.route = Route.Games }),
        "check" to ShotSpec(::checkState),
        "check-map" to ShotSpec({ mapCheckState(it, animated = true) }),
        "check-map-reduced" to ShotSpec({ mapCheckState(it, animated = false) }),
        "result" to ShotSpec({ state ->
            val region = requireNotNull(RegionCoordinates.forRegion("sa-east-1"))
            state.measuredRegion = region
            state.measuredRegionLabel = "São Paulo"
            state.approximateLocationEnabled = false
            state.route = Route.Result(entry(GameReadinessVerdict.CAUTION, "Conexão geral").copy(routeRegion = region))
        }),
        "history" to ShotSpec({ s -> s.history.add(entry(GameReadinessVerdict.READY, "Conexão geral")); s.history.add(entry(GameReadinessVerdict.NOT_READY, "Valorant")); s.route = Route.History }),
        "history-empty" to ShotSpec({ it.route = Route.History }),
        "settings" to ShotSpec({ it.route = Route.Settings }),
        "components" to ShotSpec({ it.route = Route.Components }),
    )
    for ((name, spec) in shots) {
        val sizes = if (name == "components") listOf(1120 to 1500) else listOf(1120 to 740, 900 to 600)
        sizes.forEach { (width, height) ->
            val variants = when (name) {
                "result" -> listOf(ShotVariant(), ShotVariant(scrollOffset = 420, suffix = "-details"))
                "home" -> listOf(ShotVariant(), ShotVariant(suffix = "-focus", focusTarget = CaptureFocusTarget.HomeTest))
                "games" -> listOf(ShotVariant(), ShotVariant(suffix = "-focus", focusTarget = CaptureFocusTarget.GamesSearch))
                else -> listOf(ShotVariant())
            }
            variants.forEach { variant ->
                val shotScope = CoroutineScope(Dispatchers.Unconfined)
                val stateKey = "$name-${width}x$height${variant.suffix}"
                val stateDir = shotStateRoot.resolve(stateKey)
                val library = LibraryRepository(
                    shotScope,
                    scanners = listOf(spec.scanner),
                    store = LibraryStore(stateDir.resolve("library-state.properties")),
                    networkResolver = NetworkSupportResolver(catalog = { listOf(CatalogGame("cs2", "Counter-Strike 2")) }, regionLabel = { "São Paulo" }),
                    ioDispatcher = Dispatchers.Unconfined,
                )
                val artwork = GameArtworkResolver(
                    localSources = emptyList(), remoteSources = emptyList(),
                    cache = ArtworkDiskCache(stateDir.resolve("artwork")), fetcher = HttpArtworkFetcher(),
                    remoteEnabled = { false }, ioDispatcher = Dispatchers.Unconfined,
                )
                val state = AppState(shotScope, library, artwork).also {
                    it.stopLocationLoading()
                    it.changeReduceMotion(true)
                    it.showAnalyticsNotice = name == "notice"
                    spec.setup(it)
                }
                val scene = ImageComposeScene(width, height, Density(1f)) {
                    LagCheckTheme {
                        AppShell(
                            state,
                            name == "components",
                            initialScrollOffset = variant.scrollOffset,
                            captureFocusTarget = variant.focusTarget
                        )
                    }
                }
                scene.render()
                val data = scene.render().encodeToData(EncodedImageFormat.PNG)!!
                val suffix = if (width == 1120) "" else "-compact"
                File(dir, "$name${variant.suffix}$suffix.png").writeBytes(data.bytes); scene.close()
            }
        }
    }
}

/** Jogos de exemplo exclusivos das capturas (`--shots`). Nunca entram na biblioteca do app. */
private object ShotsLibraryScanner : LibraryScanner {
    override val name = "Capturas"
    override val platform = GamePlatform.STEAM
    override fun scan() = ScanResult.Found(listOf(
        PcGame("steam_730", "Counter-Strike 2", GamePlatform.STEAM, lastPlayedEpochMs = 1_731_000_000_000, tags = listOf("competitivo", "fps")),
        PcGame("steam_shot_2", "Cities: Skylines II", GamePlatform.STEAM, tags = listOf("estratégia")),
        PcGame("steam_shot_3", "Fall Guys", GamePlatform.STEAM, tags = listOf("party")),
        PcGame("steam_shot_4", "Rocket League", GamePlatform.STEAM, lastPlayedEpochMs = 1_730_900_000_000, tags = listOf("competitivo", "esporte")),
        PcGame("steam_shot_5", "Hades II", GamePlatform.STEAM, tags = listOf("solo")),
        PcGame("epic_shot_1", "Fortnite", GamePlatform.EPIC_GAMES, lastPlayedEpochMs = 1_730_800_000_000, tags = listOf("competitivo", "battle royale")),
        PcGame("epic_shot_2", "Alan Wake 2", GamePlatform.EPIC_GAMES, tags = listOf("aventura")),
    ))
}

private object EmptyShotsLibraryScanner : LibraryScanner {
    override val name = "Capturas vazias"
    override val platform = GamePlatform.STEAM
    override fun scan() = ScanResult.Found(emptyList())
}
