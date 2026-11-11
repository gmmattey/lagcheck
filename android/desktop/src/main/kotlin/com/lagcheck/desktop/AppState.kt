package com.lagcheck.desktop

import androidx.compose.runtime.*
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.session.CheckPhase
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withTimeoutOrNull
import com.lagcheck.desktop.update.UpdateCoordinator
import com.lagcheck.desktop.analytics.*
import com.lagcheck.desktop.location.*
import com.lagcheck.desktop.library.model.GameNetworkSupport
import com.lagcheck.desktop.library.model.PcGame
import com.lagcheck.desktop.library.repository.LibraryRepository
import com.lagcheck.desktop.ui.map.RouteMapState
import com.lagcheck.desktop.ui.map.MapPoint
import com.lagcheck.desktop.ds.MotionPreferences
import java.nio.file.Files
import java.time.LocalDateTime

sealed interface Route {
    data object Home : Route
    data object Games : Route
    data object History : Route
    data object Settings : Route
    data object Components : Route
    data class Check(val game: GameEntry?) : Route
    data class Result(val entry: HistoryEntry) : Route
}

data class HistoryEntry(
    val time: LocalDateTime, val title: String, val region: String, val verdict: GameReadinessVerdict,
    val ping: Double?, val jitter: Double?, val loss: Double?, val series: List<Double>, val loadStart: Int?, val loadMeasured: Boolean,
    /** Pontos capturados apenas para a sessão atual; nulos quando a origem não foi obtida. */
    val origin: MapPoint? = null,
    val routeRegion: MapPoint? = null,
)

/** Estado único do protótipo. Uma sessão de medição por vez; cancelar descarta tudo (sem resultado parcial). */
class AppState(private val scope: CoroutineScope, val library: LibraryRepository = LibraryRepository(scope)) {
    val updates = UpdateCoordinator()
    var route by mutableStateOf<Route>(Route.Home)
    var reduceMotion by mutableStateOf(false)
    val history = mutableStateListOf<HistoryEntry>()
    var ratio by mutableStateOf(0f)
    var livePing by mutableStateOf<Double?>(null)
    var phase by mutableStateOf(CheckPhase.REST)
    val series = mutableStateListOf<Double>()
    var loadStart by mutableStateOf<Int?>(null)
    var failed by mutableStateOf(false)
    var approximateLocationEnabled by mutableStateOf(DesktopPreferences.locationEnabled())
    var approximateLocation by mutableStateOf<ApproxLocation?>(null)
    var locationLoading by mutableStateOf(false)
    var analyticsEnabled by mutableStateOf(DesktopPreferences.analyticsEnabled())
    var showAnalyticsNotice by mutableStateOf(Ga4Config.load().enabled && !DesktopPreferences.analyticsNoticeSeen())
    val routeMap = RouteMapState()
    var measuredRegion by mutableStateOf<MapPoint?>(null)
    var measuredRegionId by mutableStateOf<String?>(null)
    var measuredRegionLabel by mutableStateOf<String?>(null)
    private val locationClient = IpLocationClient()
    private val analytics = Ga4Client()
    private var measurementStartedAt: Long? = null
    private var terminalSent = false
    private var job: Job? = null
    private var locationJob: Job? = null

    init {
        MotionPreferences.reduced = reduceMotion
        scope.launch(Dispatchers.IO) { updates.check() }
        if (approximateLocationEnabled) loadApproximateLocation()
    }

    val checking get() = route is Route.Check && job?.isActive == true
    val lastEntry get() = history.firstOrNull()

    fun navigate(r: Route) { if (!checking) route = r }

    fun start(game: GameEntry?) = start(game, selectedNow = true)
    fun startForPcGame(pcGame: PcGame) {
        val entry = when (val net = pcGame.networkSupport) {
            is GameNetworkSupport.LagcheckSupported -> GameEntry(net.catalogId, pcGame.title, pcGame.localArtworkRes)
            else -> null
        }
        start(entry, selectedNow = true)
    }
    private fun start(game: GameEntry?, selectedNow: Boolean) {
        job?.cancel()
        ratio = 0f; livePing = null; phase = CheckPhase.REST; series.clear(); loadStart = null; failed = false
        if (selectedNow && game != null) track(ProductAnalyticsEvent.GameSelected(game.id))
        route = Route.Check(game); routeMap.reset(); terminalSent = false; measurementStartedAt = null
        val selectedRegion = Measurement.measuredRegion(game?.id)
        measuredRegionId = selectedRegion?.id
        measuredRegionLabel = selectedRegion?.label
        measuredRegion = selectedRegion?.let { RegionCoordinates.forRegion(it.id) }
        // A rota de um resultado só usa a origem realmente disponível quando o
        // check começou. Resultado salvo não é reconstituído com a localização atual.
        val originAtStart = approximateLocation?.let {
            MapPoint(it.city ?: it.country ?: "local aproximado", it.lat, it.lon)
        }
        job = scope.launch {
            try {
                val outcome = Measurement.run(game?.id) { p ->
                    ratio = p.ratio.coerceIn(0f, 1f); phase = p.phase
                    val index = ((p.ratio - if (p.phase == CheckPhase.LOAD) .5f else 0f) * 60f).toInt().coerceAtLeast(1) - 1 + if (p.phase == CheckPhase.LOAD) 30 else 0
                    if (measurementStartedAt == null) {
                        measurementStartedAt = System.nanoTime()
                        track(ProductAnalyticsEvent.LagcheckStarted(game?.id ?: "generic-gaming", "pc", "unknown", measuredRegionId ?: "unknown"))
                    }
                    val ping = p.latestPingMs
                    if (ping == null) routeMap.onProbeSent(index) else {
                        livePing = ping; series.add(ping)
                        if (p.phase == CheckPhase.LOAD && loadStart == null) loadStart = series.size - 1
                        routeMap.onProbeReturned(index, ping)
                    }
                }
                if (outcome == null || outcome.result.abortReason != null) { terminalInconclusive(game, outcome?.result?.abortReason?.name?.lowercase() ?: "unavailable"); failed = true; return@launch }
                val a = outcome.result.assessment
                val resultClass = a.verdict.name.lowercase()
                if (a.verdict == com.lagcheck.domain.model.GameReadinessVerdict.INCONCLUSIVE) {
                    terminalInconclusive(game, "insufficient_data")
                } else {
                    terminalCompleted(game, outcome.result.context.regionId, resultClass)
                }
                measuredRegion = RegionCoordinates.forRegion(outcome.region.id)
                measuredRegionId = outcome.region.id
                measuredRegionLabel = outcome.region.label
                val entry = HistoryEntry(LocalDateTime.now(), game?.name ?: "Conexão geral", outcome.region.label, a.verdict,
                    a.pingMs, a.jitterMs, a.packetLossPercentage, outcome.result.latencySeries, loadStart, outcome.result.loadMeasured,
                    originAtStart, measuredRegion)
                history.add(0, entry)
                route = Route.Result(entry)
            } catch (e: CancellationException) { throw e } catch (e: Exception) { terminalInconclusive(game, "error"); failed = true }
        }
    }

    fun cancel() {
        terminalCancelled((route as? Route.Check)?.game, "cancelled")
        job?.cancel()
        job = null
        // Cancelar encerra a sessão por inteiro: nenhuma leitura, rota ou pacote
        // parcial permanece no estado que poderá alimentar a próxima tela.
        ratio = 0f
        livePing = null
        phase = CheckPhase.REST
        series.clear()
        loadStart = null
        failed = false
        measuredRegion = null
        measuredRegionId = null
        measuredRegionLabel = null
        routeMap.reset()
        route = Route.Home
    }

    fun retry(game: GameEntry?) { track(ProductAnalyticsEvent.RetestStarted(game?.id ?: "generic-gaming", "pc")); start(game, selectedNow = false) }
    fun onResultViewed(entry: HistoryEntry) { track(ProductAnalyticsEvent.ResultViewed(Measurement.games.firstOrNull { it.name == entry.title }?.id ?: "generic-gaming", "pc", entry.verdict.name.lowercase())) }
    fun changeReduceMotion(enabled: Boolean) { reduceMotion = enabled; MotionPreferences.reduced = enabled; routeMap.reducedMotion = enabled }
    fun setApproximateLocation(enabled: Boolean) { approximateLocationEnabled = enabled; DesktopPreferences.setLocationEnabled(enabled); locationJob?.cancel(); if (!enabled) { locationLoading = false; approximateLocation = null; locationClient.clearCache() } else loadApproximateLocation() }
    fun changeAnalyticsEnabled(enabled: Boolean) { analyticsEnabled = enabled; DesktopPreferences.changeAnalyticsEnabled(enabled) }
    fun dismissAnalyticsNotice() { showAnalyticsNotice = false; DesktopPreferences.setAnalyticsNoticeSeen() }
    fun newAnalyticsId() { InstallationId.renew() }
    private fun track(event: ProductAnalyticsEvent) { scope.launch(Dispatchers.IO) { analytics.send(event, analyticsEnabled) } }
    private fun duration() = ((System.nanoTime() - (measurementStartedAt ?: System.nanoTime())) / 1_000_000_000).coerceAtLeast(0)
    private fun terminalCompleted(game: GameEntry?, region: String, result: String) { if (!terminalSent) { terminalSent = true; track(ProductAnalyticsEvent.LagcheckCompleted(game?.id ?: "generic-gaming", "pc", "unknown", region, result, duration())) } }
    private fun terminalInconclusive(game: GameEntry?, reason: String) { if (!terminalSent && measurementStartedAt != null) { terminalSent = true; track(ProductAnalyticsEvent.LagcheckInconclusive(game?.id ?: "generic-gaming", "pc", "unknown", measuredRegionId ?: "unknown", reason)) } }
    private fun terminalCancelled(game: GameEntry?, reason: String) { if (!terminalSent && measurementStartedAt != null) { terminalSent = true; track(ProductAnalyticsEvent.LagcheckCancelled(game?.id ?: "generic-gaming", "pc", "unknown", measuredRegionId ?: "unknown", reason)) } }
    fun checkForUpdates(force: Boolean = false) { scope.launch(Dispatchers.IO) { updates.check(force) } }
    fun downloadUpdate() { scope.launch(Dispatchers.IO) { updates.download() } }

    /** Usado pelas capturas e testes: cancela a consulta de localização para o estado não ser sobrescrito. */
    fun stopLocationLoading() { locationJob?.cancel(); locationLoading = false }

    private fun loadApproximateLocation() {
        locationJob = scope.launch(Dispatchers.IO) {
            locationLoading = true
            try {
                approximateLocation = locationClient.cached() ?: withTimeoutOrNull(3_000) { locationClient.fetch() }
            } finally {
                locationLoading = false
            }
        }
    }
}

private object DesktopPreferences {
    private val file get() = LocalData.directory.resolve("desktop-preferences.properties")
    private fun values() = java.util.Properties().apply { runCatching { Files.newInputStream(file).use { load(it) } } }
    private fun write(key: String, value: String) { values().apply { setProperty(key, value); Files.newOutputStream(file).use { store(it, null) } } }
    fun locationEnabled() = values().getProperty("approximateLocation", "true").toBoolean()
    fun setLocationEnabled(value: Boolean) = write("approximateLocation", value.toString())
    fun analyticsEnabled() = !values().getProperty("analyticsExcluded", "false").toBoolean()
    fun changeAnalyticsEnabled(value: Boolean) = write("analyticsExcluded", (!value).toString())
    fun analyticsNoticeSeen() = values().getProperty("analyticsNoticeSeen", "false").toBoolean()
    fun setAnalyticsNoticeSeen() = write("analyticsNoticeSeen", "true")
}
