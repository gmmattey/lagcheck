package com.lagcheck.desktop.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.lagcheck.desktop.*
import com.lagcheck.desktop.ds.*
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.session.CheckPhase
import java.time.format.DateTimeFormatter

private val timeFmt = DateTimeFormatter.ofPattern("dd/MM HH:mm")
private fun ms(v: Double?) = v?.let { "%.0f ms".format(it) }
private fun pct(v: Double?) = v?.let { "%.1f%%".format(it) }

@Composable
fun HomeScreen(state: AppState) {
    Column(Modifier.fillMaxWidth()) {
        Box(Modifier.fillMaxWidth().height(356.dp).clip(RoundedCornerShape(LcRadius.panel))) {
            ApprovedArtwork("hero_top_games.jpg", null, Modifier.fillMaxSize())
            Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0f to LcColor.Background.copy(alpha = .22f), .62f to LcColor.Background.copy(alpha = .80f), 1f to LcColor.Background)))
            Column(Modifier.fillMaxSize().padding(LcSpace.xl), horizontalAlignment = Alignment.CenterHorizontally) {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    SectionLabel("Conexão geral", Modifier.weight(1f))
                    StatusChip("ESTE PC · CONEXÃO GERAL", LcColor.AccentLight)
                }
                Spacer(Modifier.weight(1f))
                CircularGauge(null, state.reduceMotion, Modifier.size(266.dp)) {
                    Interactive({ state.start(null) }, Modifier.size(164.dp), shape = androidx.compose.foundation.shape.CircleShape, description = "Testar conexão geral") { hovered ->
                        Box(Modifier.matchParentSize().background(if (hovered) LcColor.HoverOverlay else Color.Transparent))
                        Text("TESTAR", style = LcType.PageTitle, color = LcColor.TextPrimary, modifier = Modifier.align(Alignment.Center))
                    }
                }
                Spacer(Modifier.height(LcSpace.sm))
            }
        }
        LastCheckLine(state.lastEntry)
        Spacer(Modifier.height(LcSpace.xxl))
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            SectionLabel("Testar por jogo", Modifier.weight(1f))
            Interactive({ state.navigate(Route.Games) }, description = "Ver todos os jogos") { hovered ->
                Text("VER TODOS ›", style = LcType.Section, color = if (hovered) LcColor.TextPrimary else LcColor.AccentLight,
                    modifier = Modifier.padding(vertical = LcSpace.sm))
            }
        }
        Spacer(Modifier.height(LcSpace.md))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(LcSpace.md)) {
            Measurement.games.take(4).forEach { game -> GameQuickTile(game, Modifier.weight(1f)) { state.start(game) } }
        }
    }
}

@Composable
private fun LastCheckLine(last: HistoryEntry?) {
    Column(Modifier.fillMaxWidth()) {
        Row(Modifier.fillMaxWidth().padding(horizontal = LcSpace.sm, vertical = LcSpace.md), verticalAlignment = Alignment.CenterVertically) {
            if (last == null) {
                Text("Ainda sem leitura", style = LcType.BodyStrong, color = LcColor.TextPrimary, modifier = Modifier.weight(1f))
                Text("Testa antes de entrar na fila.", style = LcType.Body, color = LcColor.TextSecondary)
            } else {
                val style = last.verdict.style()
                Column(Modifier.weight(1f)) {
                    SectionLabel("Último check")
                    Text(last.title, style = LcType.BodyStrong, color = LcColor.TextPrimary)
                }
                Text(ms(last.ping) ?: "—", style = LcType.DataSmall, color = LcColor.TextSecondary, modifier = Modifier.padding(end = LcSpace.lg))
                Column(horizontalAlignment = Alignment.End) {
                    Text(style.label, style = LcType.Section, color = style.color)
                    Text(last.time.format(timeFmt), style = LcType.Body, color = LcColor.TextSecondary)
                }
            }
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(LcColor.BorderHairline))
    }
}

@Composable
private fun GameQuickTile(game: GameEntry, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Interactive(onClick, modifier.heightIn(min = 104.dp), description = "Testar ${game.name}") { hovered ->
        Box(Modifier.matchParentSize().clip(RoundedCornerShape(LcRadius.control)).border(1.dp, if (hovered) LcColor.AccentLight else LcColor.BorderHairline, RoundedCornerShape(LcRadius.control))) {
            ApprovedArtwork(game.artworkResource, game.name, Modifier.fillMaxSize())
            Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0f to Color.Transparent, .48f to LcColor.Background.copy(alpha = .24f), 1f to LcColor.Background)))
            Column(Modifier.fillMaxSize().padding(LcSpace.md), verticalArrangement = Arrangement.SpaceBetween) {
                SectionLabel("PC")
                Column {
                    Text(game.name, style = LcType.BodyStrong, color = LcColor.TextPrimary, maxLines = 2)
                    Text("TESTAR ›", style = LcType.Section, color = LcColor.AccentLight, modifier = Modifier.padding(top = LcSpace.xs))
                }
            }
        }
    }
}

@Composable
private fun GameRow(game: GameEntry, onClick: () -> Unit, modifier: Modifier = Modifier) = ListRow(onClick, modifier) {
    Box(Modifier.size(width = 72.dp, height = 48.dp).clip(RoundedCornerShape(LcRadius.control))) { ApprovedArtwork(game.artworkResource, game.name, Modifier.fillMaxSize()) }
    Text(game.name, style = LcType.BodyStrong, color = LcColor.TextPrimary, modifier = Modifier.weight(1f).padding(horizontal = LcSpace.md))
    Text("PC", style = LcType.Section, color = LcColor.TextTertiary, modifier = Modifier.padding(end = LcSpace.lg))
    Text("TESTAR ›", style = LcType.Section, color = LcColor.AccentLight)
}

@Composable
fun GamesScreen(state: AppState) {
    var query by remember { mutableStateOf("") }
    PageHeader("Jogos") { SearchField(query, { query = it }) }
    Spacer(Modifier.height(LcSpace.xl))
    val list = Measurement.games.filter { it.name.contains(query, ignoreCase = true) }
    if (list.isEmpty()) EmptyState("Nada por aqui", if (query.isEmpty()) "O catálogo não liberou jogos para medir deste PC." else "Nenhum jogo com “$query”.")
    else if (query.isBlank()) GameArtworkGrid(list) { state.start(it) }
    else GameGrid(list) { state.start(it) }
}

@Composable
private fun GameArtworkGrid(games: List<GameEntry>, onClick: (GameEntry) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(LcSpace.md)) {
        games.chunked(3).forEach { row ->
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(LcSpace.md)) {
                row.forEach { game ->
                    Interactive({ onClick(game) }, Modifier.weight(1f).height(168.dp), description = "Testar ${game.name}") { hovered ->
                        Box(Modifier.matchParentSize().clip(RoundedCornerShape(LcRadius.panel)).border(1.dp, if (hovered) LcColor.AccentLight else LcColor.BorderHairline, RoundedCornerShape(LcRadius.panel))) {
                            ApprovedArtwork(game.artworkResource, game.name, Modifier.fillMaxSize())
                            Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0f to Color.Transparent, .55f to LcColor.Background.copy(alpha = .32f), 1f to LcColor.Background)))
                            Column(Modifier.fillMaxSize().padding(LcSpace.md), verticalArrangement = Arrangement.SpaceBetween) {
                                SectionLabel("PC")
                                Column {
                                    Text(game.name, style = LcType.BodyStrong, color = LcColor.TextPrimary, maxLines = 2)
                                    Text("TESTAR ›", style = LcType.Section, color = LcColor.AccentLight, modifier = Modifier.padding(top = LcSpace.xs))
                                }
                            }
                        }
                    }
                }
                repeat(3 - row.size) { Spacer(Modifier.weight(1f)) }
            }
        }
    }
}

@Composable
private fun GameGrid(games: List<GameEntry>, onClick: (GameEntry) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(LcSpace.sm)) {
        games.chunked(2).forEach { row ->
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(LcSpace.sm)) {
                row.forEach { game -> GameRow(game, { onClick(game) }, Modifier.weight(1f)) }
                if (row.size == 1) Spacer(Modifier.weight(1f))
            }
        }
    }
}

@Composable
fun CheckScreen(state: AppState, route: Route.Check) {
    val title = route.game?.name ?: "Conexão geral"
    if (state.failed) {
        Column(Modifier.fillMaxWidth().padding(top = 80.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            VerdictHeadline(GameReadinessVerdict.INCONCLUSIVE)
            Spacer(Modifier.height(LcSpace.xl))
            Row(horizontalArrangement = Arrangement.spacedBy(LcSpace.md)) {
                PrimaryButton("TENTAR DE NOVO", { state.start(route.game) })
                SecondaryButton("VOLTAR", { state.route = Route.Home })
            }
        }
        return
    }
    val message = when {
        state.phase == CheckPhase.LOAD -> "Testando sob uso..."
        state.ratio < 0.25f -> "Verificando estabilidade..."
        else -> "Procurando perda de pacotes..."
    }
    Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
        SectionLabel(title)
        Spacer(Modifier.height(LcSpace.xl))
        CircularGauge(state.ratio.coerceAtLeast(0.02f), state.reduceMotion, Modifier.size(280.dp)) {
            Column(Modifier.align(Alignment.Center), horizontalAlignment = Alignment.CenterHorizontally) {
                Text(ms(state.livePing) ?: "-- ms", style = LcType.DataHero.copy(fontSize = androidx.compose.ui.unit.TextUnit(40f, androidx.compose.ui.unit.TextUnitType.Sp)), color = LcColor.TextPrimary)
                Text("${(state.ratio * 100).toInt()}%", style = LcType.DataSmall, color = LcColor.TextSecondary)
            }
        }
        Spacer(Modifier.height(LcSpace.lg))
        Text(message, style = LcType.BodyStrong, color = LcColor.TextSecondary)
        Spacer(Modifier.height(LcSpace.xl))
        Panel(padding = LcSpace.lg) { LatencyChart(state.series.toList(), Modifier.fillMaxWidth().height(120.dp), state.loadStart) }
        Spacer(Modifier.height(LcSpace.xl))
        SecondaryButton("CANCELAR", { state.cancel() })
    }
}

@Composable
fun ResultScreen(state: AppState, e: HistoryEntry) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        SecondaryButton("‹ VOLTAR", { state.route = Route.Home })
        Spacer(Modifier.width(LcSpace.lg))
        SectionLabel("${e.title} · ${e.region}")
    }
    Spacer(Modifier.height(LcSpace.xxl))
    VerdictHeadline(e.verdict)
    Spacer(Modifier.height(LcSpace.xl))
    Row(horizontalArrangement = Arrangement.spacedBy(LcSpace.md)) {
        ResultMetric("Ping", ms(e.ping), Modifier.weight(1f)); ResultMetric("Jitter", ms(e.jitter), Modifier.weight(1f)); ResultMetric("Perda", pct(e.loss), Modifier.weight(1f))
    }
    Spacer(Modifier.height(LcSpace.xl))
    Panel(padding = LcSpace.lg) {
        SectionLabel("Latência ao longo do teste")
        Spacer(Modifier.height(LcSpace.md))
        LatencyChart(e.series, Modifier.fillMaxWidth().height(160.dp), e.loadStart)
        if (!e.loadMeasured) Text("Sem leitura sob carga.", style = LcType.Body, color = LcColor.TextSecondary, modifier = Modifier.padding(top = LcSpace.md))
    }
    Spacer(Modifier.height(LcSpace.xl))
    Row(horizontalArrangement = Arrangement.spacedBy(LcSpace.md)) {
        PrimaryButton("TESTAR DE NOVO", { state.start(Measurement.games.firstOrNull { it.name == e.title }) })
        SecondaryButton("HISTÓRICO", { state.route = Route.History })
    }
}

@Composable
private fun ResultMetric(label: String, value: String?, modifier: Modifier = Modifier) {
    Column(modifier.padding(vertical = LcSpace.sm)) {
        SectionLabel(label)
        Spacer(Modifier.height(LcSpace.xs))
        Text(value ?: "—", style = LcType.DataLarge, color = if (value == null) LcColor.TextTertiary else LcColor.TextPrimary)
    }
}

@Composable
fun HistoryScreen(state: AppState) {
    PageHeader("Histórico") { Text("SÓ NESTA SESSÃO", style = LcType.Section, color = LcColor.TextTertiary) }
    Spacer(Modifier.height(LcSpace.lg))
    if (state.history.isEmpty()) EmptyState("Sem testes ainda", "Faça um teste e ele aparece aqui.") { PrimaryButton("TESTAR AGORA", { state.start(null) }) }
    else Column(Modifier.fillMaxWidth()) {
        state.history.forEach { e ->
            val s = e.verdict.style()
            ListRow({ state.route = Route.Result(e) }) {
                val artwork = Measurement.games.firstOrNull { it.name.equals(e.title, ignoreCase = true) }?.artworkResource
                Box(Modifier.size(width = 52.dp, height = 40.dp).clip(RoundedCornerShape(LcRadius.control))) { ApprovedArtwork(artwork, e.title, Modifier.fillMaxSize()) }
                Column(Modifier.weight(1f)) {
                    Text(e.title, style = LcType.BodyStrong, color = LcColor.TextPrimary, modifier = Modifier.padding(start = LcSpace.md))
                    Text(e.time.format(timeFmt), style = LcType.Body, color = LcColor.TextSecondary, modifier = Modifier.padding(start = LcSpace.md))
                }
                Text(ms(e.ping) ?: "—", style = LcType.DataSmall, color = LcColor.TextSecondary, modifier = Modifier.padding(end = LcSpace.lg))
                Text(s.label, style = LcType.Section, color = s.color)
            }
            Box(Modifier.fillMaxWidth().height(1.dp).background(LcColor.BorderHairline))
        }
    }
}

@Composable
fun SettingsScreen(state: AppState) {
    PageHeader("Ajustes")
    Spacer(Modifier.height(LcSpace.xl))
    Column(Modifier.widthIn(max = 560.dp), verticalArrangement = Arrangement.spacedBy(LcSpace.lg)) {
        Panel {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text("Reduzir movimento", style = LcType.BodyStrong, color = LcColor.TextPrimary)
                    Text("Para o pulso do anel e as transições.", style = LcType.Body, color = LcColor.TextSecondary)
                }
                SecondaryButton(if (state.reduceMotion) "LIGADO" else "DESLIGADO", { state.reduceMotion = !state.reduceMotion })
            }
        }
        Panel {
            SectionLabel("Sobre")
            Spacer(Modifier.height(LcSpace.sm))
            Text("Protótipo interno do LagCheck para Windows. Sem conta, sem IP, sem anúncio.", style = LcType.Body, color = LcColor.TextSecondary)
        }
    }
}
