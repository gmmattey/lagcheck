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
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.lagcheck.desktop.*
import com.lagcheck.desktop.ds.*
import com.lagcheck.desktop.update.UpdateState

@Composable
fun AppShell(state: AppState, showComponents: Boolean) {
    Row(Modifier.fillMaxSize().background(LcColor.Background)) {
        Sidebar(state, showComponents)
        Box(Modifier.weight(1f).fillMaxHeight().verticalScroll(rememberScrollState()), contentAlignment = Alignment.TopCenter) {
            Column(Modifier.widthIn(max = LcSize.contentMax).fillMaxWidth().padding(horizontal = 40.dp, vertical = 32.dp)) {
                UpdateBanner(state)
                if (state.showAnalyticsNotice) AnalyticsNotice(state)
                Crossfade(
                    targetState = state.route,
                    animationSpec = tween(durationMillis = if (state.reduceMotion) 0 else 200, easing = CubicBezierEasing(.2f, 0f, 0f, 1f)),
                    label = "screenTransition"
                ) { targetRoute ->
                    when (targetRoute) {
                        Route.Home -> HomeScreen(state)
                        Route.Games -> GamesScreen(state)
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
    val update = state.updates.state
    val available = update as? UpdateState.Disponivel ?: return
    Row(Modifier.fillMaxWidth().padding(bottom = LcSpace.lg).heightIn(min = 44.dp)
        .background(LcColor.AccentSubtle, androidx.compose.foundation.shape.RoundedCornerShape(4.dp))
        .padding(horizontal = LcSpace.md), verticalAlignment = Alignment.CenterVertically) {
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
private fun Sidebar(state: AppState, showComponents: Boolean) {
    val r = state.route
    val locked = state.checking
    Column(Modifier.width(LcSize.sidebar).fillMaxHeight().background(LcColor.Surface).border(1.dp, LcColor.BorderHairline).padding(vertical = LcSpace.xl)) {
        Box(Modifier.padding(start = 20.dp, bottom = LcSpace.xl)) {
            OfficialWordmark(Modifier.width(144.dp).height(30.dp))
        }
        SidebarItem("Início", SidebarIcon.Home, r == Route.Home || (r is Route.Check) || (r is Route.Result), !locked) { state.navigate(Route.Home) }
        SidebarItem("Jogos", SidebarIcon.Games, r == Route.Games, !locked) { state.navigate(Route.Games) }
        SidebarItem("Histórico", SidebarIcon.History, r == Route.History, !locked) { state.navigate(Route.History) }
        Spacer(Modifier.weight(1f))
        if (showComponents) SidebarItem("Componentes", SidebarIcon.Components, r == Route.Components, !locked) { state.navigate(Route.Components) }
        SidebarItem("Ajustes", SidebarIcon.Settings, r == Route.Settings, !locked) { state.navigate(Route.Settings) }
        Text("Mede a rota deste PC", style = LcType.Section, color = LcColor.TextTertiary, modifier = Modifier.padding(start = 20.dp, top = LcSpace.lg))
    }
}
