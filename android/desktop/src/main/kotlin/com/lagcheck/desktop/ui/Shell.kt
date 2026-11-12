package com.lagcheck.desktop.ui

import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.lagcheck.desktop.*
import com.lagcheck.desktop.ds.*
import com.lagcheck.desktop.update.UpdateState

/** Estados de foco usados somente pela bateria de capturas de acessibilidade. */
enum class CaptureFocusTarget { HomeTest, GamesSearch }

/** Casca desktop portada do artefato OpenDesign Cloud: lateral, barra de contexto e área de trabalho. */
@Composable
fun AppShell(
    state: AppState,
    showComponents: Boolean,
    initialScrollOffset: Int = 0,
    captureFocusTarget: CaptureFocusTarget? = null
) {
    BoxWithConstraints(Modifier.fillMaxSize().background(LcColor.Background)) {
        val compact = maxWidth < 950.dp
        val sidebarWidth = if (compact) 190.dp else LcSize.sidebar
        Row(Modifier.fillMaxSize()) {
            Sidebar(state, showComponents, sidebarWidth, compact)
            Column(Modifier.weight(1f).fillMaxHeight()) {
                WorkspaceTopbar(state.route, compact)
                if (state.route == Route.Home) {
                    Column(
                        Modifier.weight(1f).fillMaxWidth()
                            .widthIn(max = LcSize.contentMax)
                            .padding(horizontal = if (compact) 26.dp else 38.dp)
                    ) {
                        UpdateBanner(state)
                        if (state.showAnalyticsNotice) AnalyticsNotice(state)
                        HomeScreen(
                            state,
                            captureFocusTarget == CaptureFocusTarget.HomeTest,
                            Modifier.weight(1f).fillMaxWidth()
                        )
                    }
                } else {
                Box(Modifier.weight(1f).fillMaxWidth().verticalScroll(rememberScrollState(initialScrollOffset)), contentAlignment = Alignment.TopCenter) {
                    Column(
                        Modifier.widthIn(max = LcSize.contentMax).fillMaxWidth()
                            .padding(horizontal = if (compact) 26.dp else 38.dp, vertical = if (compact) 28.dp else 30.dp)
                    ) {
                        UpdateBanner(state)
                        if (state.showAnalyticsNotice) AnalyticsNotice(state)
                        Crossfade(
                            targetState = state.route,
                            animationSpec = tween(durationMillis = if (state.reduceMotion) 0 else 200, easing = CubicBezierEasing(.2f, 0f, 0f, 1f)),
                            label = "screenTransition"
                        ) { targetRoute ->
                            when (targetRoute) {
                                Route.Home -> HomeScreen(state, captureFocusTarget == CaptureFocusTarget.HomeTest)
                                Route.Games -> GamesScreen(state, captureFocusTarget == CaptureFocusTarget.GamesSearch)
                                Route.History -> HistoryScreen(state)
                                Route.Settings -> SettingsScreen(state)
                                Route.Components -> ComponentsScreen(state)
                                is Route.Check -> CheckScreen(state, targetRoute)
                                is Route.Result -> ResultScreen(state, targetRoute.entry)
                            }
                        }
                    }
                }
                }
            }
        }
    }
}

@Composable
private fun WorkspaceTopbar(route: Route, compact: Boolean) {
    val page = when (route) {
        Route.Home -> "Biblioteca"
        Route.Games -> "Catálogo"
        Route.History -> "Histórico"
        Route.Settings -> "Ajustes"
        Route.Components -> "Componentes"
        is Route.Check -> "Check"
        is Route.Result -> "Resultado"
    }
    Row(
        Modifier.fillMaxWidth().height(76.dp)
            .border(1.dp, LcColor.BorderHairline)
            .padding(horizontal = if (compact) 26.dp else 38.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text("ÁREA DE JOGO", style = LcType.Section, color = LcColor.TextSecondary)
        Text("/", style = LcType.Body, color = LcColor.TextTertiary, modifier = Modifier.padding(horizontal = LcSpace.sm))
        Text(page, style = LcType.Section, color = LcColor.TextPrimary)
        Spacer(Modifier.weight(1f))
        Text(
            "PROTÓTIPO INTERNO\nDADOS REAIS QUANDO HOUVER",
            style = LcType.Section,
            color = LcColor.TextTertiary,
            maxLines = 2,
            textAlign = androidx.compose.ui.text.style.TextAlign.End,
            modifier = Modifier.widthIn(max = if (compact) 230.dp else 320.dp)
        )
    }
}

@Composable
private fun AnalyticsNotice(state: AppState) {
    Row(Modifier.fillMaxWidth().padding(bottom = LcSpace.xl).heightIn(min = 44.dp)
        .background(LcColor.Surface).border(1.dp, LcColor.BorderHairline).padding(horizontal = LcSpace.md), verticalAlignment = Alignment.CenterVertically) {
        Text("O lagcheck envia dados de uso anônimos (jogo, resultado, duração). Nunca IP, rede, local ou nome. Dá para desligar em Ajustes.", style = LcType.Body, color = LcColor.TextSecondary, modifier = Modifier.weight(1f))
        SecondaryButton("OK", { state.dismissAnalyticsNotice() })
    }
}

@Composable
private fun UpdateBanner(state: AppState) {
    val available = state.updates.state as? UpdateState.Disponivel ?: return
    Row(Modifier.fillMaxWidth().padding(bottom = LcSpace.lg).heightIn(min = 44.dp)
        .background(LcColor.AccentSubtle).padding(horizontal = LcSpace.md), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.width(3.dp).fillMaxHeight().background(LcColor.AccentLight))
        Column(Modifier.padding(start = LcSpace.md).weight(1f)) {
            Text("Nova versão ${available.release.version}", style = LcType.BodyStrong, color = LcColor.TextPrimary)
            if (available.release.notes.isNotBlank()) Text(available.release.notes.take(120), style = LcType.Body, color = LcColor.TextSecondary, maxLines = 1)
        }
        SecondaryButton("DEPOIS", { state.updates.dismiss() })
        Spacer(Modifier.width(LcSpace.sm))
        PrimaryButton("ATUALIZAR AGORA", { state.downloadUpdate() })
    }
}

@Composable
private fun Sidebar(state: AppState, showComponents: Boolean, width: Dp, compact: Boolean) {
    val route = state.route
    val locked = state.checking
    Column(
        Modifier.width(width).fillMaxHeight().background(LcColor.Surface)
            .border(1.dp, LcColor.BorderHairline).padding(vertical = if (compact) LcSpace.lg else LcSpace.xl)
    ) {
        Column(Modifier.padding(start = if (compact) 16.dp else 20.dp, bottom = LcSpace.xl)) {
            OfficialWordmark(Modifier.width(if (compact) 156.dp else 174.dp).height(30.dp))
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(top = LcSpace.sm)) {
                Text("WINDOWS", style = LcType.Section, color = LcColor.TextTertiary)
            }
        }
        Spacer(Modifier.height(if (compact) 38.dp else 55.dp))
        SidebarItem("Biblioteca", SidebarIcon.Home, route == Route.Home || route is Route.Check || route is Route.Result, !locked) { state.navigate(Route.Home) }
        SidebarItem("Catálogo", SidebarIcon.Games, route == Route.Games, !locked) { state.navigate(Route.Games) }
        SidebarItem("Histórico", SidebarIcon.History, route == Route.History, !locked) { state.navigate(Route.History) }
        SidebarItem("Ajustes", SidebarIcon.Settings, route == Route.Settings, !locked) { state.navigate(Route.Settings) }
        if (showComponents) SidebarItem("Componentes", SidebarIcon.Components, route == Route.Components, !locked) { state.navigate(Route.Components) }
        Spacer(Modifier.weight(1f))
        Column(Modifier.padding(horizontal = if (compact) 16.dp else 20.dp)) {
            Box(Modifier.width(28.dp).height(1.dp).background(LcColor.BorderStrong))
            Text("Antes de entrar na fila.", style = LcType.BodyStrong, color = LcColor.TextPrimary, modifier = Modifier.padding(top = LcSpace.md))
            Text("Um check.\nUma decisão mais clara.", style = LcType.Body, color = LcColor.TextSecondary, modifier = Modifier.padding(top = LcSpace.xs))
        }
    }
}
