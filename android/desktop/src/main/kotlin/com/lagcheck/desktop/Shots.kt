package com.lagcheck.desktop

import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.ImageComposeScene
import androidx.compose.ui.unit.Density
import com.lagcheck.desktop.ds.LagCheckTheme
import com.lagcheck.desktop.ui.AppShell
import com.lagcheck.domain.model.GameReadinessVerdict
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import org.jetbrains.skia.EncodedImageFormat
import java.io.File
import java.time.LocalDateTime

/** Renderiza as telas em PNG sem janela nem rede (dados fictícios só para inspeção visual). */
@OptIn(ExperimentalComposeUiApi::class)
fun renderShots(dir: String) {
    File(dir).mkdirs()
    val series = listOf(20.0, 22.0, 19.0, 21.0, 85.0, 24.0, 20.0, 19.0, 23.0, 30.0, 52.0, 61.0, 44.0, 38.0, 27.0, 25.0)
    fun entry(v: GameReadinessVerdict, t: String) = HistoryEntry(LocalDateTime.now(), t, "São Paulo", v, 21.0, 4.5, 0.0, series, 10, true)
    val shots = linkedMapOf<String, (AppState) -> Unit>(
        "home" to { it.history.add(entry(GameReadinessVerdict.READY, "Conexão geral")) },
        "games" to { it.route = Route.Games },
        "check" to { s -> s.route = Route.Check(null); s.ratio = 0.62f; s.livePing = 23.0; s.series.addAll(series); s.loadStart = 10 },
        "result" to { it.route = Route.Result(entry(GameReadinessVerdict.CAUTION, "Conexão geral")) },
        "history" to { s -> s.history.add(entry(GameReadinessVerdict.READY, "Conexão geral")); s.history.add(entry(GameReadinessVerdict.NOT_READY, "Valorant")); s.route = Route.History },
        "history-empty" to { it.route = Route.History },
        "settings" to { it.route = Route.Settings },
        "components" to { it.route = Route.Components },
    )
    for ((name, setup) in shots) {
        val state = AppState(CoroutineScope(Dispatchers.Unconfined)).also(setup)
        val scene = ImageComposeScene(1120, if (name == "components") 1500 else 740, Density(1f)) { LagCheckTheme { AppShell(state, name == "components") } }
        val data = scene.render().encodeToData(EncodedImageFormat.PNG)!!
        File(dir, "$name.png").writeBytes(data.bytes); scene.close()
    }
}
