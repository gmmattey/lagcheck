package com.lagcheck.android.ui.history

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.android.ui.AppLocale
import com.lagcheck.android.ui.tr
import com.lagcheck.android.ui.trf
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckRadius
import com.lagcheck.core.designsystem.theme.LagCheckSpacing
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.domain.rules.StabilitySummaryEvaluator
import com.lagcheck.domain.rules.StabilitySummaryEvaluator.MetricTone
import com.lagcheck.domain.rules.StabilitySummaryEvaluator.Point
import com.lagcheck.domain.rules.StabilitySummaryEvaluator.RingMetric
import com.lagcheck.domain.rules.StabilitySummaryEvaluator.VerdictKind
import java.util.Locale
import kotlin.math.abs
import kotlin.math.hypot
import kotlin.math.roundToInt

/**
 * Chips sem contorno e com cantos contidos (8 dp), diferenciados por profundidade de superfície.
 */
@Composable
internal fun StabilityChipRow(
    options: List<Pair<String?, String>>,
    selectedKey: String?,
    onSelected: (String?) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(LagCheckSpacing.space2)
    ) {
        options.forEach { (key, label) ->
            val selected = key == selectedKey
            val shape = RoundedCornerShape(LagCheckRadius.sm)
            Box(
                modifier = Modifier
                    .defaultMinSize(minHeight = 44.dp)
                    .shadow(elevation = if (selected) 4.dp else 1.dp, shape = shape)
                    .clip(shape)
                    .background(if (selected) LagCheckColors.Panel else LagCheckColors.Surface)
                    .clickable { onSelected(key) }
                    .padding(horizontal = LagCheckSpacing.space3_5, vertical = LagCheckSpacing.space2_5),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = label,
                    style = LagCheckTypography.MonoSmall,
                    color = if (selected) LagCheckColors.TextPrimary else LagCheckColors.TextSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

/**
 * Bloco único de estabilidade (sem bordas, sem card dentro de card e sem #7C3AED):
 * cabeçalho factual, curva de ping segmentada e os 4 anéis abaixo.
 */
@Composable
internal fun StabilityEvolutionBlock(
    summary: StabilitySummaryEvaluator.Result,
    selectedGameTitle: String?,
    modifier: Modifier = Modifier
) {
    if (summary.points.isEmpty() && summary.inconclusiveCount == 0) return

    val blockShape = RoundedCornerShape(LagCheckRadius.md)
    val toneColor = metricToneColor(summary.stabilityTone)
    var selectedPointIndex by remember(summary) { mutableStateOf<Int?>(null) }

    val headline = when (summary.headlineKey) {
        "stability.headline.stable" -> tr("Rede estável")
        "stability.headline.never_ready" -> tr("Instável em todos os checks")
        "stability.headline.moderate" -> tr("Condições instáveis")
        "stability.headline.unstable" -> tr("Rede instável")
        "stability.headline.insufficient" -> tr("Poucas medições ainda")
        else -> tr("Sem medições")
    }
    val eyebrow = if (selectedGameTitle != null) {
        "${tr("ESTABILIDADE NO JOGO")} · ${selectedGameTitle.uppercase(Locale.ROOT)}"
    } else {
        tr("ESTABILIDADE DA REDE")
    }
    val contextTag = listOfNotNull(
        networkDisplayLabel(summary.summaryNetworkType),
        summary.summaryRegionId
    ).joinToString(" · ").takeIf { it.isNotBlank() }

    val a11ySummary = buildString {
        append(trf("Gráfico de estabilidade: %s", headline))
        if (summary.hasSummary) {
            append(". ")
            append(trf("Pronto em %d de %d checks", summary.readyCount, summary.totalComparableCount))
        }
    }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .shadow(elevation = 6.dp, shape = blockShape)
            .clip(blockShape)
            .background(LagCheckColors.Surface)
            .padding(LagCheckSpacing.space4_5)
            .semantics(mergeDescendants = false) { contentDescription = a11ySummary }
    ) {
        // Cabeçalho factual
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.Top
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(LagCheckSpacing.space2)
                ) {
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .clip(CircleShape)
                            .background(toneColor)
                    )
                    Text(
                        text = eyebrow,
                        style = LagCheckTypography.MonoKicker,
                        color = LagCheckColors.TextTertiary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
                Spacer(modifier = Modifier.height(LagCheckSpacing.space1))
                Text(
                    text = headline,
                    style = LagCheckTypography.SectionHeader,
                    color = LagCheckColors.TextPrimary
                )
                if (contextTag != null) {
                    Text(
                        text = contextTag,
                        style = LagCheckTypography.Subtext,
                        color = LagCheckColors.TextSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }

            summary.latest?.let { latest ->
                Column(horizontalAlignment = Alignment.End) {
                    val minP = summary.minPingMs
                    val maxP = summary.maxPingMs
                    val rangeText = if (summary.hasSummary && minP != null && maxP != null) {
                        if (abs(maxP - minP) < 0.5) {
                            trf("%.0f ms", summary.avgPingMs ?: latest.pingMs)
                        } else {
                            trf("%.0f–%.0f ms", minP, maxP)
                        }
                    } else {
                        trf("%.0f ms", latest.pingMs)
                    }
                    Text(
                        text = rangeText,
                        style = LagCheckTypography.StatusCopy,
                        color = toneColor
                    )
                    val subtitleText = if (summary.hasSummary) {
                        trf("Pronto em %d de %d checks", summary.readyCount, summary.totalComparableCount)
                    } else {
                        tr("Último check")
                    }
                    Text(
                        text = subtitleText,
                        style = LagCheckTypography.Subtext,
                        color = LagCheckColors.TextSecondary,
                        textAlign = TextAlign.End
                    )
                }
            }
        }

        if (summary.points.isNotEmpty()) {
            Spacer(modifier = Modifier.height(LagCheckSpacing.space3_5))

            StabilityPingChart(
                points = summary.points,
                lineColor = if (!summary.hasSummary || summary.hasMixedContexts) LagCheckColors.TextSecondary else toneColor,
                selectedIndex = selectedPointIndex,
                onSelectIndex = { idx ->
                    selectedPointIndex = if (selectedPointIndex == idx) null else idx
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(116.dp)
            )

            val inspectedPoint = selectedPointIndex?.let { summary.points.getOrNull(it) }
            if (inspectedPoint != null) {
                Spacer(modifier = Modifier.height(LagCheckSpacing.space2))
                Text(
                    text = formatPointInspection(inspectedPoint),
                    style = LagCheckTypography.MonoSmall,
                    color = LagCheckColors.TextPrimary,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            } else if (!summary.canDrawCurve) {
                Spacer(modifier = Modifier.height(LagCheckSpacing.space2))
                Text(
                    text = tr("Faça pelo menos 3 checks na mesma rede para ver a evolução."),
                    style = LagCheckTypography.Subtext,
                    color = LagCheckColors.TextSecondary
                )
            }
        }

        val rings = summary.rings
        if (summary.hasSummary && rings != null) {
            Spacer(modifier = Modifier.height(LagCheckSpacing.space4))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(LagCheckColors.BorderHairline)
            )
            Spacer(modifier = Modifier.height(LagCheckSpacing.space4))
            StabilityRingsRow(rings = rings)
        }

        val breakdownParts = buildList {
            if (summary.hasSummary && (summary.cautionCount > 0 || summary.badCount > 0)) {
                add(trf("Instável: %d · Evitaria: %d · Inconclusivos: %d", summary.cautionCount, summary.badCount, summary.inconclusiveCount))
            } else if (summary.inconclusiveCount > 0) {
                add(
                    if (summary.inconclusiveCount == 1) tr("1 inconclusivo")
                    else trf("%d inconclusivos", summary.inconclusiveCount)
                )
            }
        }
        if (breakdownParts.isNotEmpty()) {
            Spacer(modifier = Modifier.height(LagCheckSpacing.space3))
            Text(
                text = breakdownParts.joinToString(" · "),
                style = LagCheckTypography.MonoSmall,
                color = LagCheckColors.TextTertiary
            )
        }
    }
}

@Composable
private fun StabilityPingChart(
    points: List<Point>,
    lineColor: Color,
    selectedIndex: Int?,
    onSelectIndex: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    val density = LocalDensity.current
    val hitRadiusPx = with(density) { 22.dp.toPx() }
    val guideColor = LagCheckColors.BorderHairline
    val lastHaloColor = Color.White.copy(alpha = 0.8f)

    val coords = remember { mutableListOf<Offset>() }

    Canvas(
        modifier = modifier.pointerInput(points) {
            detectTapGestures { tap ->
                if (coords.isEmpty()) return@detectTapGestures
                var bestIdx = -1
                var bestDist = Float.MAX_VALUE
                coords.forEachIndexed { idx, pos ->
                    val d = hypot(tap.x - pos.x, tap.y - pos.y)
                    if (d <= hitRadiusPx && d < bestDist) {
                        bestDist = d
                        bestIdx = idx
                    }
                }
                if (bestIdx >= 0) onSelectIndex(bestIdx)
            }
        }
    ) {
        coords.clear()
        if (points.isEmpty() || size.width <= 16f || size.height <= 16f) return@Canvas

        val padX = 10.dp.toPx()
        val padY = 10.dp.toPx()
        val usableW = size.width - padX * 2f
        val usableH = size.height - padY * 2f

        // Linhas-guia horizontais discretas (topo, meio e base — paridade com iOS)
        val dashEffect = PathEffect.dashPathEffect(floatArrayOf(4.dp.toPx(), 4.dp.toPx()), 0f)
        for (fraction in floatArrayOf(0f, 0.5f, 1f)) {
            val yLine = padY + usableH * fraction
            drawLine(guideColor, Offset(padX, yLine), Offset(size.width - padX, yLine), strokeWidth = 1.dp.toPx(), pathEffect = dashEffect)
        }

        // Piso mínimo de 10 ms + respiro de 15% (paridade 1:1 com iOS) para variações de poucos ms não parecerem queda brusca.
        val minPing = points.minOf { it.pingMs }
        val maxPing = points.maxOf { it.pingMs }
        val span = maxOf(maxPing - minPing, 10.0)
        val baseline = maxOf(0.0, minPing - span * 0.15)
        val top = maxPing + span * 0.15
        val effectiveSpan = maxOf(top - baseline, 1.0)

        points.forEachIndexed { index, pt ->
            val x = if (points.size == 1) {
                padX + usableW / 2f
            } else {
                padX + usableW * (index.toFloat() / (points.size - 1).toFloat())
            }
            val normY = ((pt.pingMs - baseline) / effectiveSpan).toFloat().coerceIn(0f, 1f)
            val y = padY + usableH * (1f - normY)
            coords.add(Offset(x, y))
        }

        // Conecta somente pontos contíguos do mesmo contexto com >= 3 medições
        val lineStroke = 2.dp.toPx()
        val resolvedLineColor = lineColor.copy(alpha = 0.65f)
        for (i in 1 until points.size) {
            if (points[i].connectToPrevious) {
                drawLine(
                    color = resolvedLineColor,
                    start = coords[i - 1],
                    end = coords[i],
                    strokeWidth = lineStroke,
                    cap = StrokeCap.Round
                )
            }
        }

        // Pontos coloridos por veredito
        points.forEachIndexed { index, pt ->
            val center = coords[index]
            val dotColor = verdictColor(pt.verdict)
            val isLast = index == points.lastIndex
            val isSelected = index == selectedIndex
            val radius = when {
                isSelected -> 6.dp.toPx()
                isLast -> 4.5.dp.toPx()
                else -> 3.2.dp.toPx()
            }

            if (isSelected || isLast) {
                drawCircle(
                    color = if (isSelected) dotColor.copy(alpha = 0.3f) else lastHaloColor,
                    radius = radius + 3.dp.toPx(),
                    center = center,
                    style = Stroke(width = 1.5.dp.toPx())
                )
            }
            drawCircle(
                color = dotColor,
                radius = radius,
                center = center
            )
        }
    }
}

@Composable
private fun StabilityRingsRow(rings: StabilitySummaryEvaluator.Rings) {
    BoxWithConstraints(modifier = Modifier.fillMaxWidth()) {
        val density = LocalDensity.current
        val useTwoByTwo = maxWidth < 240.dp || density.fontScale > 1.25f
        val ringSize = if (maxWidth < 285.dp) 50.dp else 54.dp

        val items = listOf(
            Triple(tr("PING MÉD"), rings.ping, "ms"),
            Triple(tr("JITTER"), rings.jitter, "ms"),
            Triple(tr("PERDA"), rings.loss, "%"),
            Triple(tr("SOB CARGA"), rings.load, "ms")
        )

        if (useTwoByTwo) {
            Column(verticalArrangement = Arrangement.spacedBy(LagCheckSpacing.space3)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    RingGaugeItem(items[0].first, items[0].second, items[0].third, isSignedLoad = false, modifier = Modifier.weight(1f), ringSize = ringSize)
                    RingGaugeItem(items[1].first, items[1].second, items[1].third, isSignedLoad = false, modifier = Modifier.weight(1f), ringSize = ringSize)
                }
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    RingGaugeItem(items[2].first, items[2].second, items[2].third, isSignedLoad = false, modifier = Modifier.weight(1f), ringSize = ringSize)
                    RingGaugeItem(items[3].first, items[3].second, items[3].third, isSignedLoad = true, modifier = Modifier.weight(1f), ringSize = ringSize)
                }
            }
        } else {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                items.forEachIndexed { idx, (label, metric, unit) ->
                    RingGaugeItem(
                        label = label,
                        metric = metric,
                        unit = unit,
                        isSignedLoad = idx == 3,
                        modifier = Modifier.weight(1f),
                        ringSize = ringSize
                    )
                }
            }
        }
    }
}

@Composable
private fun RingGaugeItem(
    label: String,
    metric: RingMetric,
    unit: String,
    isSignedLoad: Boolean,
    modifier: Modifier = Modifier,
    ringSize: Dp = 54.dp
) {
    val toneColor = metricToneColor(metric.tone)
    val valueText = when (val v = metric.value) {
        null -> "—"
        else -> {
            val rounded = if (abs(v - v.roundToInt()) < 0.05) {
                v.roundToInt().toString()
            } else {
                String.format(AppLocale.javaLocale, "%.1f", v)
            }
            if (isSignedLoad && v >= 0.0) "+$rounded" else rounded
        }
    }

    Column(
        modifier = modifier.padding(horizontal = 2.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            modifier = Modifier.size(ringSize),
            contentAlignment = Alignment.Center
        ) {
            Canvas(modifier = Modifier.fillMaxSize()) {
                val strokePx = 3.5.dp.toPx()
                val inset = strokePx / 2f
                val arcSize = Size(size.width - strokePx, size.height - strokePx)

                if (metric.tone != MetricTone.UNKNOWN && metric.fillRatio > 0.0) {
                    drawCircle(
                        color = toneColor.copy(alpha = 0.08f),
                        radius = (size.minDimension - strokePx * 2f) / 2f
                    )
                }

                // Trilha neutra
                drawArc(
                    color = Color.White.copy(alpha = 0.14f),
                    startAngle = 0f,
                    sweepAngle = 360f,
                    useCenter = false,
                    topLeft = Offset(inset, inset),
                    size = arcSize,
                    style = Stroke(width = strokePx)
                )

                // Arco colorido proporcional
                if (metric.tone != MetricTone.UNKNOWN && metric.fillRatio > 0.0) {
                    val sweep = (metric.fillRatio.coerceIn(0.14, 1.0) * 360.0).toFloat()
                    drawArc(
                        color = toneColor,
                        startAngle = -90f,
                        sweepAngle = sweep,
                        useCenter = false,
                        topLeft = Offset(inset, inset),
                        size = arcSize,
                        style = Stroke(width = strokePx, cap = StrokeCap.Round)
                    )
                }
            }

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = valueText,
                    style = LagCheckTypography.MonoData.copy(fontSize = 14.sp, lineHeight = 15.sp),
                    color = if (metric.value == null) LagCheckColors.TextTertiary else LagCheckColors.TextPrimary,
                    maxLines = 1
                )
                if (metric.value != null) {
                    Text(
                        text = unit,
                        style = LagCheckTypography.MonoSmall.copy(fontSize = 9.sp, lineHeight = 10.sp),
                        color = LagCheckColors.TextSecondary,
                        maxLines = 1
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(LagCheckSpacing.space1_5))

        Text(
            text = label,
            style = LagCheckTypography.MonoKicker.copy(fontSize = 10.sp, lineHeight = 12.sp),
            color = LagCheckColors.TextTertiary,
            textAlign = TextAlign.Center,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}

private fun formatPointInspection(pt: Point): String {
    val game = pt.gameTitle ?: pt.gameId ?: tr("Conexão geral")
    val net = networkDisplayLabel(pt.networkType)
    val ping = String.format(AppLocale.javaLocale, "%.0f ms", pt.pingMs)
    val jitter = pt.jitterMs?.let { String.format(AppLocale.javaLocale, " · jitter %.0f ms", it) }.orEmpty()
    val loss = pt.packetLossPercentage?.let { String.format(AppLocale.javaLocale, " · perda %.1f%%", it) }.orEmpty()
    val time = AppLocale.dayAndClock(pt.capturedAtEpochMs)
    return listOfNotNull(game, net, "$ping$jitter$loss", time).joinToString(" · ")
}

internal fun networkDisplayLabel(networkType: String?): String? = when (networkType) {
    "WIFI" -> tr("Wi-Fi")
    "CELLULAR" -> tr("Dados móveis")
    "ETHERNET" -> tr("Ethernet")
    "OTHER" -> tr("Outro")
    else -> null
}

private fun verdictColor(verdict: VerdictKind): Color = when (verdict) {
    VerdictKind.READY -> LagCheckColors.Good
    VerdictKind.CAUTION -> LagCheckColors.SemanticCaution
    VerdictKind.NOT_READY -> LagCheckColors.CoralWarning
    VerdictKind.INCONCLUSIVE, VerdictKind.UNKNOWN -> LagCheckColors.Inconclusive
}

private fun metricToneColor(tone: MetricTone): Color = when (tone) {
    MetricTone.OK -> LagCheckColors.Good
    MetricTone.WARN -> LagCheckColors.SemanticCaution
    MetricTone.BAD -> LagCheckColors.CoralWarning
    MetricTone.UNKNOWN -> LagCheckColors.Inconclusive
}
