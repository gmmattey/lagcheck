package com.lagcheck.desktop

import androidx.compose.runtime.*
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.session.CheckPhase
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
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
    val ping: Double?, val jitter: Double?, val loss: Double?, val series: List<Double>, val loadStart: Int?, val loadMeasured: Boolean
)

/** Estado único do protótipo. Uma sessão de medição por vez; cancelar descarta tudo (sem resultado parcial). */
class AppState(private val scope: CoroutineScope) {
    var route by mutableStateOf<Route>(Route.Home)
    var reduceMotion by mutableStateOf(false)
    val history = mutableStateListOf<HistoryEntry>()
    var ratio by mutableStateOf(0f)
    var livePing by mutableStateOf<Double?>(null)
    var phase by mutableStateOf(CheckPhase.REST)
    val series = mutableStateListOf<Double>()
    var loadStart by mutableStateOf<Int?>(null)
    var failed by mutableStateOf(false)
    private var job: Job? = null

    val checking get() = route is Route.Check && job?.isActive == true
    val lastEntry get() = history.firstOrNull()

    fun navigate(r: Route) { if (!checking) route = r }

    fun start(game: GameEntry?) {
        job?.cancel()
        ratio = 0f; livePing = null; phase = CheckPhase.REST; series.clear(); loadStart = null; failed = false
        route = Route.Check(game)
        job = scope.launch {
            try {
                val outcome = Measurement.run(game?.id) { p ->
                    ratio = p.ratio.coerceIn(0f, 1f); phase = p.phase
                    p.latestPingMs?.let { livePing = it; series.add(it); if (p.phase == CheckPhase.LOAD && loadStart == null) loadStart = series.size - 1 }
                }
                if (outcome == null || outcome.result.abortReason != null) { failed = true; return@launch }
                val a = outcome.result.assessment
                val entry = HistoryEntry(LocalDateTime.now(), game?.name ?: "Conexão geral", outcome.regionLabel, a.verdict,
                    a.pingMs, a.jitterMs, a.packetLossPercentage, outcome.result.latencySeries, loadStart, outcome.result.loadMeasured)
                history.add(0, entry)
                route = Route.Result(entry)
            } catch (e: CancellationException) { throw e } catch (e: Exception) { failed = true }
        }
    }

    fun cancel() { job?.cancel(); job = null; route = Route.Home }
}
