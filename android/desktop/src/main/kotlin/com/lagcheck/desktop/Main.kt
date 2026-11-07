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
        Window(onCloseRequest = ::exitApplication, title = "LagCheck", state = rememberWindowState(width = 1120.dp, height = 740.dp)) {
            LaunchedEffect(Unit) { window.minimumSize = Dimension(900, 600) }
            val scope = rememberCoroutineScope()
            val state = remember { AppState(scope).also { if (showComponents) it.route = Route.Components } }
            LagCheckTheme { AppShell(state, showComponents) }
        }
    }
}
