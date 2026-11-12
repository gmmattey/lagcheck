package com.lagcheck.desktop.ds

import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.foundation.selection.toggleable
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.interaction.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** Preferência compartilhada para componentes que não recebem AppState diretamente. */
object MotionPreferences { var reduced by mutableStateOf(false) }

/** Base interativa: hover, foco visível por teclado (Tab, Enter, Espaço) e estado desabilitado. */
@Composable
fun Interactive(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    forceFocus: Boolean = false,
    shape: Shape = RoundedCornerShape(LcRadius.control),
    enabled: Boolean = true,
    role: Role = Role.Button,
    description: String? = null,
    content: @Composable BoxScope.(hovered: Boolean) -> Unit
) {
    val source = remember { MutableInteractionSource() }
    val hovered by source.collectIsHoveredAsState()
    val focused by source.collectIsFocusedAsState()
    val pressed by source.collectIsPressedAsState()
    val scale by animateFloatAsState(if (pressed) .98f else 1f, tween(durationMillis = if (MotionPreferences.reduced) 0 else 180, easing = CubicBezierEasing(.2f, 0f, 0f, 1f)), label = "pressScale")
    Box(
        modifier
            .semantics { if (description != null) contentDescription = description }
            .clip(shape)
            .hoverable(source, enabled)
            .clickable(source, null, enabled, role = role, onClick = onClick)
            .graphicsLayer(scaleX = scale, scaleY = scale)
            .then(if (focused || forceFocus) Modifier.border(LcSize.focusRing, LcColor.AccentLight, shape) else Modifier),
        content = { content(hovered && enabled) }
    )
}

@Composable
fun PrimaryButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true) {
    Interactive(onClick, modifier.heightIn(min = 44.dp), enabled = enabled) { hovered ->
        val shimmer = rememberInfiniteTransition(label = "primarySweep")
        val sweep by shimmer.animateFloat(
            initialValue = -1f,
            targetValue = 2f,
            animationSpec = infiniteRepeatable(
                animation = tween(durationMillis = 900, easing = CubicBezierEasing(.2f, 0f, 0f, 1f)),
                repeatMode = RepeatMode.Restart
            ),
            label = "primarySweepPosition"
        )
        Box(
            Modifier.matchParentSize().background(if (!enabled) LcColor.Panel else if (hovered) LcColor.AccentHover else LcColor.Accent)
        )
        if (enabled && hovered && !MotionPreferences.reduced) Canvas(Modifier.matchParentSize()) {
            drawRect(Brush.linearGradient(listOf(Color.Transparent, Color.White.copy(alpha = .20f), Color.Transparent),
                start = Offset(size.width * (sweep - 1f), 0f), end = Offset(size.width * sweep, 0f)))
        }
        Text(text, style = LcType.Button, color = if (enabled) Color.White else LcColor.TextTertiary,
            modifier = Modifier.align(Alignment.Center).padding(horizontal = 28.dp, vertical = 14.dp))
    }
}

@Composable
fun SecondaryButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Interactive(onClick, modifier.heightIn(min = 44.dp)) { hovered ->
        Box(Modifier.matchParentSize().background(if (hovered) LcColor.HoverOverlay else Color.Transparent)
            .border(1.dp, LcColor.BorderStrong, RoundedCornerShape(LcRadius.control)))
        Text(text, style = LcType.Button, color = LcColor.TextPrimary,
            modifier = Modifier.align(Alignment.Center).padding(horizontal = 24.dp, vertical = 14.dp))
    }
}

/** Chave desktop: foco visível e Enter/Espaço vêm de toggleable. */
@Composable
fun SettingSwitch(checked: Boolean, onCheckedChange: (Boolean) -> Unit, modifier: Modifier = Modifier) {
    val source = remember { MutableInteractionSource() }
    val focused by source.collectIsFocusedAsState()
    val track by animateColorAsState(
        targetValue = if (checked) LcColor.Accent else LcColor.Panel,
        animationSpec = tween(durationMillis = if (MotionPreferences.reduced) 0 else 180, easing = CubicBezierEasing(.2f, 0f, 0f, 1f)),
        label = "switchTrack"
    )
    val offset by animateDpAsState(
        targetValue = if (checked) 22.dp else 4.dp,
        animationSpec = tween(durationMillis = if (MotionPreferences.reduced) 0 else 180, easing = CubicBezierEasing(.2f, 0f, 0f, 1f)),
        label = "switchThumb"
    )
    Box(
        modifier
            .size(width = 48.dp, height = 28.dp)
            .clip(RoundedCornerShape(6.dp))
            .background(track)
            .border(if (focused) LcSize.focusRing else 1.dp, if (focused) LcColor.AccentLight else LcColor.BorderStrong, RoundedCornerShape(6.dp))
            .toggleable(value = checked, interactionSource = source, indication = null, role = Role.Switch, onValueChange = onCheckedChange)
            .semantics { stateDescription = if (checked) "Ligado" else "Desligado" }
    ) {
        Box(Modifier.padding(start = offset).align(Alignment.CenterStart).size(22.dp).clip(RoundedCornerShape(4.dp)).background(Color.White))
    }
}

/** Painel amplo com borda de 1 px. Hierarquia por contraste tonal, sem sombra. */
@Composable
fun Panel(modifier: Modifier = Modifier, padding: Dp = LcSpace.xl, content: @Composable ColumnScope.() -> Unit) {
    Column(
        modifier.fillMaxWidth().clip(RoundedCornerShape(LcRadius.panel)).background(LcColor.Surface)
            .border(1.dp, LcColor.BorderHairline, RoundedCornerShape(LcRadius.panel)).padding(padding),
        content = content
    )
}

@Composable
fun SectionLabel(text: String, modifier: Modifier = Modifier) =
    Text(text.uppercase(), style = LcType.Section, color = LcColor.TextSecondary, modifier = modifier)

@Composable
fun PageHeader(title: String, modifier: Modifier = Modifier, trailing: @Composable () -> Unit = {}) {
    Row(modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Text(title, style = LcType.PageTitle, color = LcColor.TextPrimary, modifier = Modifier.weight(1f))
        trailing()
    }
}

/** Número de telemetria com rótulo. Uma frase curta falada na call: "ping 19". */
@Composable
fun MetricTile(label: String, value: String?, modifier: Modifier = Modifier, tone: Color = LcColor.TextPrimary) {
    Column(
        modifier.clip(RoundedCornerShape(LcRadius.control)).background(LcColor.Panel).padding(horizontal = LcSpace.lg, vertical = LcSpace.md)
            .semantics(mergeDescendants = true) {}
    ) {
        SectionLabel(label)
        Spacer(Modifier.height(LcSpace.xs))
        Text(value ?: "—", style = LcType.DataLarge, color = if (value == null) LcColor.TextTertiary else tone)
    }
}

@Composable
fun VerdictHeadline(verdict: com.lagcheck.domain.model.GameReadinessVerdict, modifier: Modifier = Modifier) {
    val s = verdict.style()
    Column(modifier) {
        Text(s.label, style = LcType.VerdictHero, color = s.color)
        Spacer(Modifier.height(LcSpace.sm))
        Text(s.phrase, style = LcType.BodyStrong, color = LcColor.TextSecondary)
    }
}

@Composable
fun StatusMarker(text: String, color: Color, modifier: Modifier = Modifier) {
    Row(
        modifier.height(IntrinsicSize.Min).heightIn(min = 28.dp).clip(RoundedCornerShape(4.dp))
            .background(Brush.horizontalGradient(listOf(color.copy(alpha = .16f), Color.Transparent)))
            .padding(end = LcSpace.md), verticalAlignment = Alignment.CenterVertically
    ) {
        Box(Modifier.width(3.dp).fillMaxHeight().background(color))
        Text(text, style = LcType.Section, color = color, modifier = Modifier.padding(start = LcSpace.sm))
    }
}

enum class SidebarIcon { Home, Games, History, Settings, Components }

@Composable
fun SidebarItem(label: String, icon: SidebarIcon, selected: Boolean, enabled: Boolean, onClick: () -> Unit) {
    Interactive(onClick, Modifier.fillMaxWidth().height(44.dp), enabled = enabled, role = Role.Tab) { hovered ->
        val bg = when { selected -> LcColor.Accent; hovered -> LcColor.HoverOverlay; else -> Color.Transparent }
        Box(Modifier.matchParentSize().background(bg))
        Row(Modifier.align(Alignment.CenterStart).padding(start = 18.dp), verticalAlignment = Alignment.CenterVertically) {
            SidebarGlyph(icon, if (selected) Color.White else LcColor.TextSecondary, Modifier.size(24.dp))
            Text(label, style = LcType.BodyStrong, color = if (selected) LcColor.TextPrimary else if (enabled) LcColor.TextSecondary else LcColor.TextTertiary)
        }
    }
}

/** Mesma linguagem dos ícones de navegação Android; Games e Histórico repetem a geometria nativa. */
@Composable
private fun SidebarGlyph(icon: SidebarIcon, color: Color, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val stroke = 2.dp.toPx()
        when (icon) {
            SidebarIcon.Games -> {
                drawRoundRect(color, Offset(size.width * .08f, size.height * .25f), Size(size.width * .84f, size.height * .55f), CornerRadius(size.height * .22f), Stroke(stroke))
                drawLine(color, Offset(size.width * .28f, size.height * .44f), Offset(size.width * .28f, size.height * .65f), stroke)
                drawLine(color, Offset(size.width * .18f, size.height * .55f), Offset(size.width * .38f, size.height * .55f), stroke)
                drawCircle(color, stroke * .75f, Offset(size.width * .68f, size.height * .47f))
                drawCircle(color, stroke * .75f, Offset(size.width * .78f, size.height * .60f))
            }
            SidebarIcon.History -> {
                drawCircle(color, size.width * .4f, center, style = Stroke(stroke))
                drawLine(color, center, Offset(center.x, size.height * .28f), stroke, cap = StrokeCap.Round)
                drawLine(color, center, Offset(size.width * .66f, size.height * .58f), stroke, cap = StrokeCap.Round)
            }
            SidebarIcon.Home -> {
                val roof = Path().apply { moveTo(size.width * .15f, size.height * .48f); lineTo(size.width * .5f, size.height * .16f); lineTo(size.width * .85f, size.height * .48f); lineTo(size.width * .76f, size.height * .48f); lineTo(size.width * .76f, size.height * .82f); lineTo(size.width * .57f, size.height * .82f); lineTo(size.width * .57f, size.height * .61f); lineTo(size.width * .43f, size.height * .61f); lineTo(size.width * .43f, size.height * .82f); lineTo(size.width * .24f, size.height * .82f); lineTo(size.width * .24f, size.height * .48f); close() }
                drawPath(roof, color)
            }
            SidebarIcon.Settings -> {
                drawCircle(color, size.width * .20f, center, style = Stroke(stroke))
                repeat(8) { i ->
                    val a = Math.PI * 2 * i / 8
                    val x1 = center.x + kotlin.math.cos(a).toFloat() * size.width * .28f
                    val y1 = center.y + kotlin.math.sin(a).toFloat() * size.width * .28f
                    val x2 = center.x + kotlin.math.cos(a).toFloat() * size.width * .40f
                    val y2 = center.y + kotlin.math.sin(a).toFloat() * size.width * .40f
                    drawLine(color, Offset(x1, y1), Offset(x2, y2), stroke, cap = StrokeCap.Round)
                }
            }
            SidebarIcon.Components -> {
                drawCircle(color, size.width * .28f, center, style = Stroke(stroke))
                drawCircle(color, size.width * .07f, center)
            }
        }
    }
}

@Composable
fun EmptyState(title: String, body: String, modifier: Modifier = Modifier, action: (@Composable () -> Unit)? = null) {
    Column(modifier.fillMaxWidth().padding(vertical = 48.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Text(title, style = LcType.PageTitle.copy(fontSize = androidx.compose.ui.unit.TextUnit(20f, androidx.compose.ui.unit.TextUnitType.Sp)), color = LcColor.TextPrimary, textAlign = TextAlign.Center)
        Spacer(Modifier.height(LcSpace.sm))
        Text(body, style = LcType.Body, color = LcColor.TextSecondary, textAlign = TextAlign.Center)
        if (action != null) { Spacer(Modifier.height(LcSpace.xl)); action() }
    }
}

/** Linha de lista (jogo, histórico): hover, foco e seta. */
@Composable
fun ListRow(onClick: () -> Unit, modifier: Modifier = Modifier, content: @Composable RowScope.() -> Unit) {
    Interactive(onClick, modifier.fillMaxWidth().heightIn(min = 56.dp), role = Role.Button) { hovered ->
        Box(Modifier.matchParentSize().background(if (hovered) LcColor.HoverOverlay else Color.Transparent))
        Row(Modifier.fillMaxWidth().padding(horizontal = LcSpace.lg, vertical = LcSpace.sm), verticalAlignment = Alignment.CenterVertically, content = content)
    }
}

/** Anel de medição. `progress` nulo = repouso (anel cheio pulsando; parado com movimento reduzido). */
@Composable
fun CircularGauge(
    progress: Float?,
    reduceMotion: Boolean,
    modifier: Modifier = Modifier,
    color: Color = LcColor.Accent,
    center: @Composable BoxScope.() -> Unit
) {
    val pulse = if (reduceMotion || progress != null) 1f else {
        val t = rememberInfiniteTransition()
        t.animateFloat(0.55f, 1f, infiniteRepeatable(tween(1800, easing = FastOutSlowInEasing), RepeatMode.Reverse)).value
    }
    val shown by animateFloatAsState(progress ?: 1f, tween(durationMillis = if (reduceMotion) 0 else 250))
    Box(modifier, contentAlignment = Alignment.Center) {
        Canvas(Modifier.matchParentSize().padding(10.dp)) {
            val stroke = 14.dp.toPx()
            val inset = stroke / 2
            val arcSize = Size(size.width - stroke, size.height - stroke)
            drawArc(LcColor.Panel, 135f, 270f, false, Offset(inset, inset), arcSize, style = Stroke(stroke, cap = StrokeCap.Round))
            drawArc(color.copy(alpha = pulse), 135f, 270f * shown, false, Offset(inset, inset), arcSize, style = Stroke(stroke, cap = StrokeCap.Round))
        }
        center()
    }
}

/** Gráfico de latência: linha, preenchimento, grade e marcador de início da carga. Picos ≥ 80 ms em âmbar. */
@Composable
fun LatencyChart(values: List<Double>, modifier: Modifier = Modifier, loadStartIndex: Int? = null, reduceMotion: Boolean = false) {
    var visible by remember { mutableStateOf(reduceMotion || values.isNotEmpty()) }
    LaunchedEffect(values, reduceMotion) { visible = true }
    val reveal by animateFloatAsState(
        targetValue = if (reduceMotion) 1f else if (visible) 1f else 0f,
        animationSpec = tween(durationMillis = if (reduceMotion) 0 else 220, easing = CubicBezierEasing(.2f, 0f, 0f, 1f)),
        label = "chartReveal"
    )
    val summary = if (values.isEmpty()) "Sem amostras" else "Mediana %.0f ms, pior %.0f ms".format(values.sorted()[values.size / 2], values.max())
    Canvas(modifier.semantics { contentDescription = "Gráfico de latência. $summary" }) {
        val top = (values.maxOrNull() ?: 100.0).coerceAtLeast(60.0) * 1.15
        fun x(i: Int) = if (values.size <= 1) 0f else size.width * i / (values.size - 1)
        fun y(v: Double) = (size.height * (1 - v / top)).toFloat()
        for (g in 1..3) drawLine(LcColor.BorderHairline, Offset(0f, size.height * g / 4), Offset(size.width, size.height * g / 4), 1.dp.toPx())
        if (values.size < 2) return@Canvas
        clipRect(right = size.width * reveal) {
        val line = Path().apply { values.forEachIndexed { i, v -> if (i == 0) moveTo(x(i), y(v)) else lineTo(x(i), y(v)) } }
        val fill = Path().apply { addPath(line); lineTo(size.width, size.height); lineTo(0f, size.height); close() }
        drawPath(fill, Brush.verticalGradient(listOf(LcColor.Accent.copy(alpha = 0.35f), Color.Transparent)))
        drawPath(line, LcColor.AccentLight, style = Stroke(2.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round))
        values.forEachIndexed { i, v -> if (v >= 80) drawCircle(LcColor.Caution, 3.5.dp.toPx(), Offset(x(i), y(v))) }
        loadStartIndex?.takeIf { it in 1 until values.size }?.let {
            drawLine(LcColor.BorderStrong, Offset(x(it), 0f), Offset(x(it), size.height), 1.dp.toPx(),
                pathEffect = PathEffect.dashPathEffect(floatArrayOf(8f, 8f)))
        }
        }
    }
}
