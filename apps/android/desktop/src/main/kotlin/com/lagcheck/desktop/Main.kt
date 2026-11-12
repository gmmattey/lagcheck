package com.lagcheck.desktop

import androidx.compose.runtime.*
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import androidx.compose.ui.window.rememberWindowState
import com.lagcheck.desktop.ds.LagCheckTheme
import com.lagcheck.desktop.ui.AppShell
import kotlinx.coroutines.runBlocking
import java.awt.Dimension
import com.lagcheck.desktop.update.UpdateState

fun main(args: Array<String>) {
    if ("--cli" in args) {
        // Validação sem janela: imprime o resultado do mesmo núcleo.
        val o = runBlocking { Measurement.run(null) { p -> System.err.print("\r%.0f%%".format(p.ratio * 100)) } }
        System.err.println()
        if (o == null) { println("sem contexto de medição"); return }
        val a = o.result.assessment
        println("verdict=${a.verdict} ping=${a.pingMs} jitter=${a.jitterMs} loss=${a.packetLossPercentage} abort=${o.result.abortReason} loadMeasured=${o.result.loadMeasured} games=${Measurement.games.size}")
        return
    }
    if ("--shots" in args) { renderShots(args[args.indexOf("--shots") + 1]); return }
    val showComponents = "--ds" in args
    application {
        var activeState by remember { mutableStateOf<AppState?>(null) }
        Window(onCloseRequest = {
            activeState?.let { app -> if (app.updates.automatic && !app.checking) app.updates.installReady() }
            exitApplication()
        }, title = "LagCheck", state = rememberWindowState(width = 1120.dp, height = 740.dp)) {
            LaunchedEffect(Unit) { window.minimumSize = Dimension(900, 600) }
            val scope = rememberCoroutineScope()
            val state = remember { AppState(scope).also { if (showComponents) it.route = Route.Components } }
            SideEffect { activeState = state }
            LaunchedEffect(state.updates.state, state.updates.automatic) {
                if (state.updates.state is UpdateState.Pronta && !state.updates.automatic) {
                    if (state.updates.installReady()) exitApplication()
                }
            }
            LagCheckTheme { AppShell(state, showComponents) }
        }
    }
}
