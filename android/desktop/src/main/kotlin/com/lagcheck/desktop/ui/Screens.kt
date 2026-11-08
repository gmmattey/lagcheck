package com.lagcheck.desktop.ui

import androidx.compose.animation.core.animateFloat
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.tween
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.desktop.*
import com.lagcheck.desktop.ds.*
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.session.CheckPhase
import com.lagcheck.desktop.update.UpdateState
import com.lagcheck.desktop.ui.map.MapPoint
import com.lagcheck.desktop.ui.map.RouteMap
import java.time.Duration
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

private val timeFmt = DateTimeFormatter.ofPattern("dd/MM HH:mm", Locale("pt", "BR"))
private val settingsTimeFmt = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm", Locale("pt", "BR"))
private fun localDateTime(instant: java.time.Instant): String = instant.atZone(ZoneId.systemDefault()).format(settingsTimeFmt)
private fun ms(v: Double?) = v?.let { "%.0f ms".format(it) }
private fun pct(v: Double?) = v?.let { "%.1f%%".format(it) }
private fun safeArtwork(resourceName: String?): String? = resourceName?.takeUnless { it == "game_crossfar" || it == "game_crossfar.png" }
private fun relativeTime(time: java.time.LocalDateTime): String {
    val minutes = Duration.between(time, java.time.LocalDateTime.now()).toMinutes().coerceAtLeast(0)
    return when {
        minutes == 0L -> "agora"
        minutes == 1L -> "há 1 min"
        minutes < 60L -> "há $minutes min"
        minutes < 120L -> "há 1 h"
        minutes < 24 * 60L -> "há ${minutes / 60} h"
        else -> time.format(timeFmt)
    }
}

@Composable
fun HomeScreen(state: AppState, captureTestFocus: Boolean = false) {
    Column(Modifier.fillMaxWidth()) {
        PageHeader("Início") { Text("CONEXÃO GERAL", style = LcType.Section, color = LcColor.TextTertiary) }
        Text("Sua conexão, antes da partida.", style = LcType.Body, color = LcColor.TextSecondary, modifier = Modifier.padding(top = LcSpace.xs))
        Spacer(Modifier.height(LcSpace.lg))
        HomeCommand(state, captureTestFocus)
        Spacer(Modifier.height(LcSpace.xxl))
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            SectionLabel("Testar por jogo", Modifier.weight(1f))
            Interactive({ state.navigate(Route.Games) }, description = "Ver todos os jogos") { hovered ->
                Text("VER TODOS ›", style = LcType.Section, color = if (hovered) LcColor.TextPrimary else LcColor.AccentLight,
                    modifier = Modifier.padding(vertical = LcSpace.sm))
            }
        }
        Spacer(Modifier.height(LcSpace.md))
        BoxWithConstraints(Modifier.fillMaxWidth()) {
            val columns = if (maxWidth < 800.dp) 2 else 4
            Column(verticalArrangement = Arrangement.spacedBy(LcSpace.md)) {
                Measurement.games.take(4).chunked(columns).forEach { row ->
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(LcSpace.md)) {
                        row.forEach { game -> GameQuickTile(game, state.reduceMotion, Modifier.weight(1f)) { state.start(game) } }
                        repeat(columns - row.size) { Spacer(Modifier.weight(1f)) }
                    }
                }
            }
        }
        Spacer(Modifier.height(LcSpace.xxl))
        HomeRecentHistory(state)
        Spacer(Modifier.height(LcSpace.xxl))
        Text("O check mede a rota deste PC até uma região de referência. Não mede o ping exato de um servidor do jogo.", style = LcType.Body, color = LcColor.TextTertiary)
    }
}

@Composable
private fun HomeCommand(state: AppState, captureTestFocus: Boolean) {
    Panel(padding = 0.dp) {
        BoxWithConstraints(Modifier.fillMaxWidth()) {
            val compact = maxWidth < 800.dp
            if (compact) {
                Column(Modifier.fillMaxWidth()) {
                    HomeCommandMain(state, Modifier.fillMaxWidth().height(302.dp).padding(LcSpace.xl), captureTestFocus)
                    Box(Modifier.fillMaxWidth().height(1.dp).background(LcColor.BorderHairline))
                    HomeLastCheck(state.lastEntry, Modifier.fillMaxWidth().padding(22.dp)) { state.lastEntry?.let { state.route = Route.Result(it) } }
                }
            } else {
                Row(Modifier.fillMaxWidth().height(302.dp)) {
                    HomeCommandMain(state, Modifier.weight(1f).fillMaxHeight().padding(LcSpace.xl), captureTestFocus)
                    Box(Modifier.width(1.dp).fillMaxHeight().background(LcColor.BorderHairline))
                    HomeLastCheck(state.lastEntry, Modifier.width(300.dp).fillMaxHeight().padding(horizontal = 24.dp, vertical = 22.dp)) { state.lastEntry?.let { state.route = Route.Result(it) } }
                }
            }
        }
    }
}

@Composable
private fun HomeCommandMain(state: AppState, modifier: Modifier, captureTestFocus: Boolean) {
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text("Check da conexão", style = LcType.BodyStrong, color = LcColor.TextPrimary, modifier = Modifier.weight(1f))
            Text("REGIÃO DE REFERÊNCIA", style = LcType.Section, color = LcColor.TextTertiary)
        }
        CircularGauge(null, state.reduceMotion, Modifier.padding(top = LcSpace.md).size(194.dp)) {
            Interactive(
                { state.start(null) },
                Modifier.size(158.dp),
                forceFocus = captureTestFocus,
                shape = androidx.compose.foundation.shape.CircleShape,
                description = "Testar conexão geral"
            ) { hovered ->
                Box(Modifier.matchParentSize().background(if (hovered) LcColor.HoverOverlay else LcColor.Panel))
                Column(Modifier.align(Alignment.Center), horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("TESTAR", style = LcType.PageTitle.copy(fontSize = 23.sp), color = LcColor.TextPrimary)
                    Text("Iniciar check", style = LcType.Section, color = LcColor.TextSecondary, modifier = Modifier.padding(top = LcSpace.xs))
                }
            }
        }
        Text("Um check antes do próximo jogo.", style = LcType.Body, color = LcColor.TextSecondary)
    }
}

@Composable
private fun HomeLastCheck(last: HistoryEntry?, modifier: Modifier, onOpen: () -> Unit) {
    Column(modifier) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text("Último check", style = LcType.Body, color = LcColor.TextSecondary, modifier = Modifier.weight(1f))
            if (last != null) Text(last.time.format(timeFmt), style = LcType.Section, color = LcColor.TextTertiary)
        }
        if (last == null) {
            Spacer(Modifier.height(LcSpace.lg))
            Text("Ainda sem leitura", style = LcType.BodyStrong, color = LcColor.TextPrimary)
            Spacer(Modifier.height(LcSpace.sm))
            Text("Teste antes de entrar na fila.", style = LcType.Body, color = LcColor.TextSecondary)
        } else {
            val verdict = last.verdict.style()
            Spacer(Modifier.height(LcSpace.xl))
            Text(verdict.label, style = LcType.Section, color = verdict.color)
            Text("${last.title} · ${last.region}", style = LcType.Body, color = LcColor.TextSecondary, modifier = Modifier.padding(top = LcSpace.xs))
            Spacer(Modifier.height(LcSpace.lg))
            Row(Modifier.fillMaxWidth()) {
                HomeMetric("PING", ms(last.ping), Modifier.weight(1f))
                HomeMetric("JITTER", ms(last.jitter), Modifier.weight(1f))
                HomeMetric("PERDA", pct(last.loss), Modifier.weight(1f))
            }
            Spacer(Modifier.weight(1f))
            SecondaryButton("VER RESULTADO", onOpen, Modifier.fillMaxWidth())
        }
    }
}

@Composable
private fun HomeMetric(label: String, value: String?, modifier: Modifier) {
    Column(modifier) { SectionLabel(label); Text(value ?: "—", style = LcType.DataSmall, color = LcColor.TextPrimary, modifier = Modifier.padding(top = LcSpace.xs)) }
}

@Composable
private fun HomeRecentHistory(state: AppState) {
    Column(Modifier.fillMaxWidth()) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            SectionLabel("Histórico recente", Modifier.weight(1f))
            Interactive({ state.navigate(Route.History) }, description = "Ver histórico") { hovered -> Text("VER HISTÓRICO ›", style = LcType.Section, color = if (hovered) LcColor.TextPrimary else LcColor.AccentLight, modifier = Modifier.padding(vertical = LcSpace.sm)) }
        }
        state.history.take(3).forEach { entry ->
            ListRow({ state.route = Route.Result(entry) }) {
                Text(entry.title, style = LcType.BodyStrong, color = LcColor.TextPrimary, modifier = Modifier.weight(1f))
                Text(ms(entry.ping) ?: "—", style = LcType.DataSmall, color = LcColor.TextSecondary, modifier = Modifier.padding(end = LcSpace.lg))
                Text(entry.verdict.style().label, style = LcType.Section, color = entry.verdict.style().color)
            }
            Box(Modifier.fillMaxWidth().height(1.dp).background(LcColor.BorderHairline))
        }
        if (state.history.isEmpty()) Text("As próximas medições aparecem aqui.", style = LcType.Body, color = LcColor.TextSecondary, modifier = Modifier.padding(vertical = LcSpace.lg))
    }
}

@Composable
private fun GameQuickTile(game: GameEntry, reduceMotion: Boolean, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Interactive(onClick, modifier.heightIn(min = 104.dp), description = "Testar ${game.name}") { hovered ->
        val elevation by animateFloatAsState(if (hovered) 10f else 0f, tween(durationMillis = if (reduceMotion) 0 else 180, easing = CubicBezierEasing(.2f, 0f, 0f, 1f)), label = "quickTileElevation")
        Box(Modifier.matchParentSize().graphicsLayer(shadowElevation = elevation).clip(RoundedCornerShape(LcRadius.control)).border(1.dp, if (hovered) LcColor.AccentLight else LcColor.BorderHairline, RoundedCornerShape(LcRadius.control))) {
            ApprovedArtwork(safeArtwork(game.artworkResource), game.name, Modifier.fillMaxSize())
            Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0f to Color.Transparent, .48f to LcColor.Background.copy(alpha = .24f), 1f to LcColor.Background)))
            Column(Modifier.fillMaxSize().padding(LcSpace.md), verticalArrangement = Arrangement.SpaceBetween) {
                Spacer(Modifier.height(1.dp))
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
    Box(Modifier.size(width = 72.dp, height = 48.dp).clip(RoundedCornerShape(LcRadius.control))) { ApprovedArtwork(safeArtwork(game.artworkResource), game.name, Modifier.fillMaxSize()) }
    Text(game.name, style = LcType.BodyStrong, color = LcColor.TextPrimary, modifier = Modifier.weight(1f).padding(horizontal = LcSpace.md))
    Text("PC", style = LcType.Section, color = LcColor.TextTertiary, modifier = Modifier.padding(end = LcSpace.lg))
    Text("TESTAR ›", style = LcType.Section, color = LcColor.AccentLight)
}

@Composable
fun GamesScreen(state: AppState, captureSearchFocus: Boolean = false) {
    var query by remember { mutableStateOf("") }
    Column(Modifier.fillMaxWidth()) {
        PageHeader("Jogos") { Text("${Measurement.games.size} JOGOS", style = LcType.Section, color = LcColor.TextTertiary) }
        Text("Escolha o contexto antes de medir.", style = LcType.Body, color = LcColor.TextSecondary, modifier = Modifier.padding(top = LcSpace.xs))
        Spacer(Modifier.height(LcSpace.lg))
        SearchField(query, { query = it }, Modifier.fillMaxWidth(), forceFocus = captureSearchFocus)
        Spacer(Modifier.height(LcSpace.lg))
        GameLimitNote()
        Spacer(Modifier.height(LcSpace.xl))
        val list = Measurement.games.filter { it.name.contains(query, ignoreCase = true) }
        if (list.isEmpty()) EmptyState("Nada por aqui", if (query.isEmpty()) "O catálogo não liberou jogos para medir deste PC." else "Nenhum jogo com “$query”.")
        else if (query.isBlank()) GameArtworkGrid(list, state.reduceMotion) { state.start(it) }
        else GameGrid(list) { state.start(it) }
        Spacer(Modifier.height(LcSpace.xxl))
        Text("Artes editoriais locais do catálogo. Sem busca externa.", style = LcType.Body, color = LcColor.TextTertiary, modifier = Modifier.padding(top = LcSpace.sm))
    }
}

@Composable
private fun GameLimitNote() {
    Column(Modifier.fillMaxWidth()) {
        Box(Modifier.fillMaxWidth().height(1.dp).background(LcColor.BorderHairline))
        Spacer(Modifier.height(LcSpace.md))
        Text("O jogo define o contexto do check.", style = LcType.BodyStrong, color = LcColor.TextPrimary)
        Text("Não mede o ping exato do servidor do jogo.", style = LcType.Body, color = LcColor.TextSecondary, modifier = Modifier.padding(top = LcSpace.xs))
    }
}

@Composable
private fun GameArtworkGrid(games: List<GameEntry>, reduceMotion: Boolean, onClick: (GameEntry) -> Unit) {
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        val columns = if (maxWidth < 800.dp) 2 else 3
        Column(verticalArrangement = Arrangement.spacedBy(LcSpace.md)) {
            games.chunked(columns).forEach { row ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(LcSpace.md)) {
                    row.forEach { game ->
                        Interactive({ onClick(game) }, Modifier.weight(1f).height(if (columns == 2) 150.dp else 156.dp), description = "Testar ${game.name}") { hovered ->
                            val elevation by animateFloatAsState(if (hovered) 10f else 0f, tween(durationMillis = if (reduceMotion) 0 else 180, easing = CubicBezierEasing(.2f, 0f, 0f, 1f)), label = "gameTileElevation")
                            Box(Modifier.matchParentSize().graphicsLayer(shadowElevation = elevation).clip(RoundedCornerShape(LcRadius.panel)).border(1.dp, if (hovered) LcColor.AccentLight else LcColor.BorderHairline, RoundedCornerShape(LcRadius.panel))) {
                                ApprovedArtwork(safeArtwork(game.artworkResource), game.name, Modifier.fillMaxSize())
                                Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0f to Color.Transparent, .55f to LcColor.Background.copy(alpha = .32f), 1f to LcColor.Background)))
                                Column(Modifier.fillMaxSize().padding(LcSpace.md), verticalArrangement = Arrangement.SpaceBetween) {
                                    Spacer(Modifier.height(1.dp))
                                    Column {
                                        Text(game.name, style = LcType.BodyStrong, color = LcColor.TextPrimary, maxLines = 2)
                                        Text("TESTAR ›", style = LcType.Section, color = LcColor.AccentLight, modifier = Modifier.padding(top = LcSpace.xs))
                                    }
                                }
                            }
                        }
                    }
                    repeat(columns - row.size) { Spacer(Modifier.weight(1f)) }
                }
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
        state.phase == CheckPhase.LOAD -> "Medindo sob uso"
        state.ratio < 0.25f -> "Iniciando as sondas"
        else -> "Confirmando estabilidade"
    }
    Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
        Panel(Modifier.widthIn(max = 850.dp), padding = LcSpace.xl) {
            BoxWithConstraints(Modifier.fillMaxWidth()) {
                val compactCheck = maxWidth < 700.dp
                val mapHeight = if (compactCheck) 150.dp else 175.dp
                val mapModifier = Modifier.fillMaxWidth().height(mapHeight)
                Column(Modifier.fillMaxWidth()) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            SecondaryButton("‹ VOLTAR", { state.cancel() })
            Spacer(Modifier.width(LcSpace.md))
            Column(Modifier.weight(1f)) {
                Text("Check", style = LcType.PageTitle, color = LcColor.TextPrimary)
                Text(title, style = LcType.Body, color = LcColor.TextSecondary)
            }
            Text("${(state.ratio * 100).toInt()}%", style = LcType.DataSmall, color = LcColor.TextSecondary)
        }
        Spacer(Modifier.height(LcSpace.xl))
        val region = state.measuredRegion
        val location = state.approximateLocation
        if (region != null) {
            StatusMarker("REGIÃO DE REFERÊNCIA · ${state.measuredRegionLabel ?: region.name}", LcColor.AccentLight)
            Text("A rota só aparece se houver localização aproximada disponível.", style = LcType.Body, color = LcColor.TextTertiary, modifier = Modifier.padding(top = LcSpace.xs))
            Spacer(Modifier.height(LcSpace.md))
            if (location != null) {
                RouteMap(
                    state = state.routeMap,
                    user = MapPoint(location.city ?: location.country ?: "local aproximado", location.lat, location.lon),
                    region = region,
                    modifier = mapModifier
                )
            } else if (state.locationLoading && state.approximateLocationEnabled) {
                RouteLoadingSkeleton(state.reduceMotion, mapModifier)
            } else {
                RouteMap(state = state.routeMap, user = null, region = region, modifier = mapModifier)
            }
            Spacer(Modifier.height(LcSpace.md))
        }
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            CircularGauge(state.ratio.coerceAtLeast(0.02f), state.reduceMotion, Modifier.size(if (compactCheck) 124.dp else 140.dp)) {
                Column(Modifier.align(Alignment.Center), horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(ms(state.livePing) ?: "-- ms", style = LcType.DataLarge, color = LcColor.TextPrimary)
                    Text("PING", style = LcType.Section, color = LcColor.TextSecondary)
                }
            }
            Column(Modifier.padding(start = LcSpace.xl).weight(1f)) {
                Text(message, style = LcType.BodyStrong, color = LcColor.TextPrimary)
                Text("Sondas reais em andamento. Nada é estimado enquanto o check não termina.", style = LcType.Body, color = LcColor.TextSecondary, modifier = Modifier.padding(top = LcSpace.xs))
                Spacer(Modifier.height(LcSpace.lg))
                CheckStages(state)
            }
        }
        Spacer(Modifier.height(LcSpace.lg))
        SecondaryButton("CANCELAR MEDIÇÃO", { state.cancel() })
        Spacer(Modifier.height(LcSpace.lg))
        LatencyChart(state.series.toList(), Modifier.fillMaxWidth().height(if (compactCheck) 54.dp else 64.dp), state.loadStart, state.reduceMotion)
                }
            }
        }
    }
}

@Composable
private fun CheckStages(state: AppState) {
    val active = when (state.phase) { CheckPhase.REST -> 1; CheckPhase.LOAD -> 2; else -> 3 }
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(LcSpace.md)) {
        listOf("01 · BASE", "02 · CARGA", "03 · RESULTADO").forEachIndexed { index, label ->
            Text(label, style = LcType.Section, color = if (index + 1 <= active) LcColor.AccentLight else LcColor.TextTertiary)
        }
    }
}

@Composable
private fun RouteLoadingSkeleton(reduceMotion: Boolean, modifier: Modifier) {
    val transition = rememberInfiniteTransition(label = "routeSkeleton")
    val alpha = if (reduceMotion) .42f else transition.animateFloat(
        initialValue = .24f,
        targetValue = .56f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 700, easing = CubicBezierEasing(.2f, 0f, 0f, 1f)),
            repeatMode = RepeatMode.Reverse
        ),
        label = "routeSkeletonAlpha"
    ).value
    Column(modifier.clip(RoundedCornerShape(LcRadius.panel)).background(LcColor.Surface).padding(LcSpace.lg)) {
        Box(Modifier.fillMaxWidth(.38f).height(12.dp).background(LcColor.Panel.copy(alpha = alpha), RoundedCornerShape(4.dp)))
        Spacer(Modifier.height(LcSpace.lg))
        Box(Modifier.fillMaxWidth().height(1.dp).background(LcColor.Panel.copy(alpha = alpha)))
        Spacer(Modifier.weight(1f))
        Box(Modifier.fillMaxWidth(.62f).height(12.dp).background(LcColor.Panel.copy(alpha = alpha), RoundedCornerShape(4.dp)))
    }
}

@Composable
fun ResultScreen(state: AppState, e: HistoryEntry) {
    LaunchedEffect(e) { state.onResultViewed(e) }
    Column(Modifier.fillMaxWidth()) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            SecondaryButton("‹ VOLTAR", { state.route = Route.Home })
            Spacer(Modifier.width(LcSpace.lg))
            Column(Modifier.weight(1f)) {
                Text("Resultado do check", style = LcType.PageTitle, color = LcColor.TextPrimary)
                Text("${e.title} · ${e.region}", style = LcType.Body, color = LcColor.TextSecondary, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
        Spacer(Modifier.height(LcSpace.xl))
        Panel(Modifier.widthIn(max = 850.dp).align(Alignment.CenterHorizontally), padding = LcSpace.xl) {
            SectionLabel("Resultado da medição")
            Spacer(Modifier.height(LcSpace.xl))
            VerdictHeadline(e.verdict)
            Spacer(Modifier.height(LcSpace.md))
            Text("${e.title} · Região de referência em ${e.region}", style = LcType.Body, color = LcColor.TextSecondary)
            Spacer(Modifier.height(LcSpace.xl))
            ResultRoute(state, e)
            Spacer(Modifier.height(LcSpace.xl))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(LcSpace.md)) {
                ResultMetric("Ping", e.ping, "ms", Modifier.weight(1f), state.reduceMotion)
                ResultMetric("Jitter", e.jitter, "ms", Modifier.weight(1f), state.reduceMotion)
                ResultMetric("Perda de pacotes", e.loss, "%", Modifier.weight(1f), state.reduceMotion)
            }
            Spacer(Modifier.height(LcSpace.lg))
            Box(Modifier.fillMaxWidth().height(1.dp).background(LcColor.BorderHairline))
            Spacer(Modifier.height(LcSpace.lg))
            ResultExplanation(e)
            Spacer(Modifier.height(LcSpace.xl))
            Row(horizontalArrangement = Arrangement.spacedBy(LcSpace.md)) {
                PrimaryButton("RETESTAR", { state.retry(Measurement.games.firstOrNull { it.name == e.title }) })
                SecondaryButton("INÍCIO", { state.route = Route.Home })
                SecondaryButton("HISTÓRICO", { state.route = Route.History })
            }
        }
    }
}

@Composable
private fun ResultExplanation(entry: HistoryEntry) {
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        if (maxWidth < 700.dp) {
            Column(Modifier.fillMaxWidth()) {
                ResultNextStep(entry)
                Spacer(Modifier.height(LcSpace.lg))
                ResultLimitExplanation()
            }
        } else {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(LcSpace.xxl)) {
                Column(Modifier.weight(1f)) { ResultNextStep(entry) }
                Column(Modifier.weight(1f)) { ResultLimitExplanation() }
            }
        }
    }
}

@Composable
private fun ResultNextStep(entry: HistoryEntry) {
    Text("Seu próximo passo", style = LcType.BodyStrong, color = LcColor.TextPrimary)
    Text(entry.verdict.style().phrase, style = LcType.Body, color = LcColor.TextSecondary, modifier = Modifier.padding(top = LcSpace.sm))
}

@Composable
private fun ResultLimitExplanation() {
    Text("O que este resultado representa", style = LcType.BodyStrong, color = LcColor.TextPrimary)
    Text("Uma leitura da conexão deste PC até a região de referência. As condições da partida podem variar.", style = LcType.Body, color = LcColor.TextSecondary, modifier = Modifier.padding(top = LcSpace.sm))
}

@Composable
private fun ResultRoute(state: AppState, entry: HistoryEntry) {
    val region = entry.routeRegion
    if (region == null) {
        SectionLabel("Rota da medição")
        Text("A rota visual não está disponível neste resultado salvo.", style = LcType.Body, color = LcColor.TextSecondary, modifier = Modifier.padding(top = LcSpace.sm))
        return
    }
    Column(Modifier.fillMaxWidth()) {
        SectionLabel("Rota da medição")
        Spacer(Modifier.height(LcSpace.sm))
        RouteMap(
            state = state.routeMap,
            user = entry.origin,
            region = region,
            modifier = Modifier.fillMaxWidth().height(132.dp)
        )
    }
}

@Composable
private fun ResultMetric(label: String, value: Double?, unit: String, modifier: Modifier = Modifier, reduceMotion: Boolean) {
    val shown by animateFloatAsState(
        targetValue = value?.toFloat() ?: 0f,
        animationSpec = tween(durationMillis = if (reduceMotion) 0 else 220, easing = CubicBezierEasing(.2f, 0f, 0f, 1f)),
        label = "result$label"
    )
    val rendered = value?.let { "%.${if (unit == "%") 1 else 0}f %s".format(shown, unit) }
    Column(modifier.padding(vertical = LcSpace.sm)) {
        SectionLabel(label)
        Spacer(Modifier.height(LcSpace.xs))
        Text(rendered ?: "—", style = LcType.DataLarge, color = if (value == null) LcColor.TextTertiary else LcColor.TextPrimary)
    }
}

@Composable
fun HistoryScreen(state: AppState) {
    var query by remember { mutableStateOf("") }
    var verdictFilter by remember { mutableStateOf<GameReadinessVerdict?>(null) }
    val filtered = state.history.filter { entry ->
        (query.isBlank() || entry.title.contains(query, ignoreCase = true) || entry.region.contains(query, ignoreCase = true)) &&
            (verdictFilter == null || entry.verdict == verdictFilter)
    }
    Column(Modifier.fillMaxWidth()) {
        PageHeader("Histórico") { Text("SÓ NESTA SESSÃO", style = LcType.Section, color = LcColor.TextTertiary) }
        Spacer(Modifier.height(LcSpace.lg))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(LcSpace.md), verticalAlignment = Alignment.CenterVertically) {
            SearchField(query, { query = it }, Modifier.weight(1f), placeholder = "Buscar por jogo ou região")
            Interactive({ verdictFilter = when (verdictFilter) { null -> GameReadinessVerdict.READY; GameReadinessVerdict.READY -> GameReadinessVerdict.CAUTION; GameReadinessVerdict.CAUTION -> GameReadinessVerdict.NOT_READY; GameReadinessVerdict.NOT_READY -> GameReadinessVerdict.INCONCLUSIVE; else -> null } }, Modifier.heightIn(min = 44.dp), description = "Filtrar por veredito") { hovered ->
                Box(Modifier.matchParentSize().background(if (hovered) LcColor.HoverOverlay else LcColor.Surface).border(1.dp, LcColor.BorderStrong, RoundedCornerShape(LcRadius.control)))
                Text(verdictFilter?.style()?.label ?: "TODOS OS VEREDITOS", style = LcType.Section, color = LcColor.TextPrimary, modifier = Modifier.align(Alignment.Center).padding(horizontal = LcSpace.md))
            }
        }
        Spacer(Modifier.height(LcSpace.lg))
        if (state.history.isEmpty()) EmptyState("Sem testes ainda", "Faça um teste e ele aparece aqui.") { PrimaryButton("TESTAR AGORA", { state.start(null) }) }
        else if (filtered.isEmpty()) EmptyState("Nada nesse filtro", "Tente outro jogo, região ou veredito.")
        else BoxWithConstraints(Modifier.fillMaxWidth()) {
            val compact = maxWidth < 760.dp
            Column(Modifier.fillMaxWidth()) {
            Row(
                Modifier.fillMaxWidth().padding(horizontal = LcSpace.lg, vertical = LcSpace.sm),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Spacer(Modifier.width(52.dp + LcSpace.md))
                Text("CHECK", style = LcType.Section, color = LcColor.TextTertiary, modifier = Modifier.weight(1f))
                Text("PING", style = LcType.Section, color = LcColor.TextTertiary, modifier = Modifier.width(64.dp))
                if (!compact) {
                    Text("REGIÃO DE REFERÊNCIA", style = LcType.Section, color = LcColor.TextTertiary, modifier = Modifier.width(140.dp))
                    Text("JITTER", style = LcType.Section, color = LcColor.TextTertiary, modifier = Modifier.width(70.dp))
                    Text("PERDA", style = LcType.Section, color = LcColor.TextTertiary, modifier = Modifier.width(70.dp))
                    Text("VEREDITO", style = LcType.Section, color = LcColor.TextTertiary, modifier = Modifier.width(200.dp))
                }
            }
            Box(Modifier.fillMaxWidth().height(1.dp).background(LcColor.BorderHairline))
            if (compact) Text("Jitter e perda aparecem nos detalhes do resultado.", style = LcType.Body, color = LcColor.TextTertiary, modifier = Modifier.padding(horizontal = LcSpace.lg, vertical = LcSpace.sm))
            filtered.forEach { e ->
                val s = e.verdict.style()
                ListRow({ state.route = Route.Result(e) }) {
                    val artwork = Measurement.games.firstOrNull { it.name.equals(e.title, ignoreCase = true) }?.artworkResource
                    HistoryThumbnail(safeArtwork(artwork), e.title)
                    Column(Modifier.weight(1f)) {
                        Text(e.title, style = LcType.BodyStrong, color = LcColor.TextPrimary, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(start = LcSpace.md))
                        Text(if (compact) "${e.region} · ${relativeTime(e.time)}" else relativeTime(e.time), style = LcType.Body, color = LcColor.TextSecondary, modifier = Modifier.padding(start = LcSpace.md))
                        if (compact) Text(s.label, style = LcType.Section, color = s.color, maxLines = 2, overflow = TextOverflow.Clip, modifier = Modifier.padding(start = LcSpace.md, top = LcSpace.xs))
                    }
                    Text(ms(e.ping) ?: "—", style = LcType.DataSmall, color = LcColor.TextSecondary, modifier = Modifier.padding(end = LcSpace.lg))
                    if (!compact) {
                        Text(e.region, style = LcType.Body, color = LcColor.TextSecondary, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.width(140.dp))
                        Text(ms(e.jitter) ?: "—", style = LcType.DataSmall, color = LcColor.TextSecondary, modifier = Modifier.width(70.dp))
                        Text(pct(e.loss) ?: "—", style = LcType.DataSmall, color = LcColor.TextSecondary, modifier = Modifier.width(70.dp))
                        Text(s.label, style = LcType.Section, color = s.color, maxLines = 2, overflow = TextOverflow.Clip, modifier = Modifier.width(200.dp))
                    }
                    Text("›", style = LcType.DataLarge, color = LcColor.TextTertiary)
                }
                Box(Modifier.fillMaxWidth().height(1.dp).background(LcColor.BorderHairline))
            }
            }
        }
        Spacer(Modifier.height(LcSpace.xl))
        Text("Medições desta sessão ficam neste PC.", style = LcType.Body, color = LcColor.TextTertiary)
    }
}

@Composable
private fun HistoryThumbnail(artwork: String?, title: String) {
    Box(
        Modifier.size(width = 52.dp, height = 40.dp).clip(RoundedCornerShape(LcRadius.control)).background(LcColor.Panel),
        contentAlignment = Alignment.Center
    ) {
        if (artwork == null) Text("GERAL", style = LcType.Section, color = LcColor.TextSecondary)
        else ApprovedArtwork(artwork, title, Modifier.fillMaxSize())
    }
}

@Composable
fun SettingsScreen(state: AppState) {
    Column(Modifier.fillMaxWidth()) {
        PageHeader("Ajustes")
        Text("Controle como o protótipo se comporta neste PC.", style = LcType.Body, color = LcColor.TextSecondary, modifier = Modifier.padding(top = LcSpace.xs))
        Spacer(Modifier.height(LcSpace.xl))
        Column(Modifier.widthIn(max = 560.dp)) {
        SettingsToggle("Reduzir movimento", "Para câmera, pacotes, pulsos, gráficos e transições.", state.reduceMotion) { state.changeReduceMotion(it) }
        SettingsToggle("Localização aproximada", "Cidade aproximada pelo seu IP, só para posicionar o mapa. Nunca GPS e nunca enviada a lugar nenhum.", state.approximateLocationEnabled) { state.setApproximateLocation(it) }
            Column(Modifier.fillMaxWidth().padding(vertical = LcSpace.lg)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text("Enviar dados de uso anônimos", style = LcType.BodyStrong, color = LcColor.TextPrimary)
                    Text("Jogo, resultado e duração. Sem IP, rede, local ou nome.", style = LcType.Body, color = LcColor.TextSecondary)
                }
                SettingSwitch(checked = state.analyticsEnabled, onCheckedChange = { state.changeAnalyticsEnabled(it) })
            }
            Spacer(Modifier.height(LcSpace.md))
            SecondaryButton("GERAR NOVO ID", { state.newAnalyticsId() })
        }
            Box(Modifier.fillMaxWidth().height(1.dp).background(LcColor.BorderHairline))
            Column(Modifier.fillMaxWidth().padding(vertical = LcSpace.lg)) {
            SectionLabel("Atualizações")
            Spacer(Modifier.height(LcSpace.sm))
            Text("Versão instalada ${com.lagcheck.desktop.update.UpdateSource.installedVersion}", style = LcType.Body, color = LcColor.TextSecondary)
            Text(state.updates.lastChecked?.let { "Última verificação: ${localDateTime(it)}" } ?: "Ainda não verificado", style = LcType.Body, color = LcColor.TextSecondary)
            Spacer(Modifier.height(LcSpace.md))
            Row(horizontalArrangement = Arrangement.spacedBy(LcSpace.sm), verticalAlignment = Alignment.CenterVertically) {
                SecondaryButton("VERIFICAR AGORA", { state.checkForUpdates(force = true) })
                SecondaryButton(if (state.updates.automatic) "AUTOMÁTICO: LIGADO" else "AUTOMÁTICO: DESLIGADO", { state.updates.changeAutomatic(!state.updates.automatic) })
            }
            val ready = state.updates.state as? UpdateState.Pronta
            if (ready != null) Text("${ready.release.version} verificado por checksum. Instala ao fechar o app.", style = LcType.Body, color = LcColor.Good, modifier = Modifier.padding(top = LcSpace.md))
        }
            Box(Modifier.fillMaxWidth().height(1.dp).background(LcColor.BorderHairline))
            Column(Modifier.fillMaxWidth().padding(vertical = LcSpace.lg)) {
            SectionLabel("Sobre")
            Spacer(Modifier.height(LcSpace.sm))
            Text("Protótipo interno do lagcheck para Windows. Sem conta e sem anúncio. Localização aproximada e dados de uso anônimos podem ser desligados acima.", style = LcType.Body, color = LcColor.TextSecondary)
            }
        }
    }
}

@Composable
private fun SettingsToggle(title: String, body: String, checked: Boolean, onCheckedChange: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth().padding(vertical = LcSpace.lg), verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f)) {
            Text(title, style = LcType.BodyStrong, color = LcColor.TextPrimary)
            Text(body, style = LcType.Body, color = LcColor.TextSecondary)
        }
        SettingSwitch(checked = checked, onCheckedChange = onCheckedChange)
    }
    Box(Modifier.fillMaxWidth().height(1.dp).background(LcColor.BorderHairline))
}
