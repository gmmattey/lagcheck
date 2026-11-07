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
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.lagcheck.desktop.*
import com.lagcheck.desktop.ds.*
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.session.CheckPhase
import com.lagcheck.desktop.update.UpdateState
import com.lagcheck.desktop.ui.map.MapPoint
import com.lagcheck.desktop.ui.map.RouteMap
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

private val timeFmt = DateTimeFormatter.ofPattern("dd/MM HH:mm", Locale("pt", "BR"))
private val settingsTimeFmt = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm", Locale("pt", "BR"))
private fun localDateTime(instant: java.time.Instant): String = instant.atZone(ZoneId.systemDefault()).format(settingsTimeFmt)
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
                    StatusMarker("ESTE PC", LcColor.AccentLight)
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
            Measurement.games.take(4).forEach { game -> GameQuickTile(game, state.reduceMotion, Modifier.weight(1f)) { state.start(game) } }
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
private fun GameQuickTile(game: GameEntry, reduceMotion: Boolean, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Interactive(onClick, modifier.heightIn(min = 104.dp), description = "Testar ${game.name}") { hovered ->
        val elevation by animateFloatAsState(if (hovered) 10f else 0f, tween(durationMillis = if (reduceMotion) 0 else 180, easing = CubicBezierEasing(.2f, 0f, 0f, 1f)), label = "quickTileElevation")
        Box(Modifier.matchParentSize().graphicsLayer(shadowElevation = elevation).clip(RoundedCornerShape(LcRadius.control)).border(1.dp, if (hovered) LcColor.AccentLight else LcColor.BorderHairline, RoundedCornerShape(LcRadius.control))) {
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
    Column(Modifier.fillMaxWidth()) {
        PageHeader("Jogos") { SearchField(query, { query = it }) }
        Spacer(Modifier.height(LcSpace.xl))
        val list = Measurement.games.filter { it.name.contains(query, ignoreCase = true) }
        if (list.isEmpty()) EmptyState("Nada por aqui", if (query.isEmpty()) "O catálogo não liberou jogos para medir deste PC." else "Nenhum jogo com “$query”.")
        else if (query.isBlank()) GameArtworkGrid(list, state.reduceMotion) { state.start(it) }
        else GameGrid(list) { state.start(it) }
    }
}

@Composable
private fun GameArtworkGrid(games: List<GameEntry>, reduceMotion: Boolean, onClick: (GameEntry) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(LcSpace.md)) {
        games.chunked(3).forEach { row ->
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(LcSpace.md)) {
                row.forEach { game ->
                    Interactive({ onClick(game) }, Modifier.weight(1f).height(168.dp), description = "Testar ${game.name}") { hovered ->
                        val elevation by animateFloatAsState(if (hovered) 10f else 0f, tween(durationMillis = if (reduceMotion) 0 else 180, easing = CubicBezierEasing(.2f, 0f, 0f, 1f)), label = "gameTileElevation")
                        Box(Modifier.matchParentSize().graphicsLayer(shadowElevation = elevation).clip(RoundedCornerShape(LcRadius.panel)).border(1.dp, if (hovered) LcColor.AccentLight else LcColor.BorderHairline, RoundedCornerShape(LcRadius.panel))) {
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
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        val compactCheck = maxWidth < 700.dp
        val mapHeight = if (compactCheck) 240.dp else 280.dp
        val mapModifier = Modifier.fillMaxWidth().heightIn(min = 240.dp).height(mapHeight)
        Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
        SectionLabel(title)
        Spacer(Modifier.height(LcSpace.xl))
        val region = state.measuredRegion
        val location = state.approximateLocation
        if (region != null) {
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
        CircularGauge(state.ratio.coerceAtLeast(0.02f), state.reduceMotion, Modifier.size(if (compactCheck) 160.dp else 176.dp)) {
            Column(Modifier.align(Alignment.Center), horizontalAlignment = Alignment.CenterHorizontally) {
                Text(ms(state.livePing) ?: "-- ms", style = LcType.DataHero.copy(fontSize = androidx.compose.ui.unit.TextUnit(40f, androidx.compose.ui.unit.TextUnitType.Sp)), color = LcColor.TextPrimary)
                Text("${(state.ratio * 100).toInt()}%", style = LcType.DataSmall, color = LcColor.TextSecondary)
            }
        }
        Spacer(Modifier.height(LcSpace.md))
        Text(message, style = LcType.BodyStrong, color = LcColor.TextSecondary)
        Spacer(Modifier.height(LcSpace.lg))
        Panel(padding = LcSpace.md) { LatencyChart(state.series.toList(), Modifier.fillMaxWidth().height(if (compactCheck) 96.dp else 108.dp), state.loadStart, state.reduceMotion) }
        Spacer(Modifier.height(LcSpace.xl))
        SecondaryButton("CANCELAR", { state.cancel() })
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
            Text("${e.title} · ${e.region}", style = LcType.Section, color = LcColor.TextSecondary, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f))
        }
        Spacer(Modifier.height(LcSpace.xxl))
        VerdictHeadline(e.verdict)
        Spacer(Modifier.height(LcSpace.xl))
        Row(horizontalArrangement = Arrangement.spacedBy(LcSpace.md)) {
            ResultMetric("Ping", e.ping, "ms", Modifier.weight(1f), state.reduceMotion)
            ResultMetric("Jitter", e.jitter, "ms", Modifier.weight(1f), state.reduceMotion)
            ResultMetric("Perda", e.loss, "%", Modifier.weight(1f), state.reduceMotion)
        }
        Spacer(Modifier.height(LcSpace.xl))
        Panel(padding = LcSpace.lg) {
            SectionLabel("Latência ao longo do teste")
            Spacer(Modifier.height(LcSpace.md))
            LatencyChart(e.series, Modifier.fillMaxWidth().height(160.dp), e.loadStart, state.reduceMotion)
            if (!e.loadMeasured) Text("Sem leitura sob carga.", style = LcType.Body, color = LcColor.TextSecondary, modifier = Modifier.padding(top = LcSpace.md))
        }
        Spacer(Modifier.height(LcSpace.xl))
        Row(horizontalArrangement = Arrangement.spacedBy(LcSpace.md)) {
            PrimaryButton("TESTAR DE NOVO", { state.retry(Measurement.games.firstOrNull { it.name == e.title }) })
            SecondaryButton("HISTÓRICO", { state.route = Route.History })
        }
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
    Column(Modifier.fillMaxWidth()) {
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
                        Text(e.title, style = LcType.BodyStrong, color = LcColor.TextPrimary, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(start = LcSpace.md))
                        Text(e.time.format(timeFmt), style = LcType.Body, color = LcColor.TextSecondary, modifier = Modifier.padding(start = LcSpace.md))
                    }
                    Text(ms(e.ping) ?: "—", style = LcType.DataSmall, color = LcColor.TextSecondary, modifier = Modifier.padding(end = LcSpace.lg))
                    Text(s.label, style = LcType.Section, color = s.color, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.widthIn(max = 190.dp))
                }
                Box(Modifier.fillMaxWidth().height(1.dp).background(LcColor.BorderHairline))
            }
        }
    }
}

@Composable
fun SettingsScreen(state: AppState) {
    Column(Modifier.fillMaxWidth()) {
        PageHeader("Ajustes")
        Spacer(Modifier.height(LcSpace.xl))
        Column(Modifier.widthIn(max = 560.dp)) {
        SettingsToggle("Reduzir movimento", "Para o pulso do anel e as transições.", state.reduceMotion) { state.changeReduceMotion(it) }
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
