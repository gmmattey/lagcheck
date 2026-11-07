package com.lagcheck.desktop.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.lagcheck.desktop.*
import com.lagcheck.desktop.ds.*

@Composable
fun AppShell(state: AppState, showComponents: Boolean) {
    Row(Modifier.fillMaxSize().background(LcColor.Background)) {
        Sidebar(state, showComponents)
        Box(Modifier.weight(1f).fillMaxHeight().verticalScroll(rememberScrollState()), contentAlignment = Alignment.TopCenter) {
            Column(Modifier.widthIn(max = LcSize.contentMax).fillMaxWidth().padding(horizontal = 40.dp, vertical = 32.dp)) {
                when (val r = state.route) {
                    Route.Home -> HomeScreen(state)
                    Route.Games -> GamesScreen(state)
                    Route.History -> HistoryScreen(state)
                    Route.Settings -> SettingsScreen(state)
                    Route.Components -> ComponentsScreen(state)
                    is Route.Check -> CheckScreen(state, r)
                    is Route.Result -> ResultScreen(state, r.entry)
                }
            }
        }
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
