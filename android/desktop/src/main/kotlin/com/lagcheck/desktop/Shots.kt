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
import java.io.File
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
    val shots = linkedMapOf<String, (AppState) -> Unit>(
        "notice" to { it.history.add(entry(GameReadinessVerdict.READY, "Conexão geral")) },
        "home" to { it.history.add(entry(GameReadinessVerdict.READY, "Conexão geral")) },
        "games" to { it.route = Route.Games },
        "check" to ::checkState,
        "check-map" to { mapCheckState(it, animated = true) },
        "check-map-reduced" to { mapCheckState(it, animated = false) },
        "result" to { state ->
            val region = requireNotNull(RegionCoordinates.forRegion("sa-east-1"))
            state.measuredRegion = region
            state.measuredRegionLabel = "São Paulo"
            state.approximateLocationEnabled = false
            state.route = Route.Result(entry(GameReadinessVerdict.CAUTION, "Conexão geral").copy(routeRegion = region))
        },
        "history" to { s -> s.history.add(entry(GameReadinessVerdict.READY, "Conexão geral")); s.history.add(entry(GameReadinessVerdict.NOT_READY, "Valorant")); s.route = Route.History },
        "history-empty" to { it.route = Route.History },
        "settings" to { it.route = Route.Settings },
        "components" to { it.route = Route.Components },
    )
    for ((name, setup) in shots) {
        val sizes = if (name == "components") listOf(1120 to 1500) else listOf(1120 to 740, 900 to 600)
        sizes.forEach { (width, height) ->
            val variants = when (name) {
                "result" -> listOf(ShotVariant(), ShotVariant(scrollOffset = 420, suffix = "-details"))
                "home" -> listOf(ShotVariant(), ShotVariant(suffix = "-focus", focusTarget = CaptureFocusTarget.HomeTest))
                "games" -> listOf(ShotVariant(), ShotVariant(suffix = "-focus", focusTarget = CaptureFocusTarget.GamesSearch))
                else -> listOf(ShotVariant())
            }
            variants.forEach { variant ->
                val state = AppState(CoroutineScope(Dispatchers.Unconfined)).also {
                    it.stopLocationLoading()
                    it.changeReduceMotion(true)
                    it.showAnalyticsNotice = name == "notice"
                    setup(it)
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
