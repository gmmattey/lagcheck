package com.lagcheck.core.designsystem.components.map

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameMillis
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.core.designsystem.theme.LagCheckColors
import kotlin.math.roundToInt

/**
 * Mapa de medição plano (grade 1,5° Natural Earth 110m, arcos de rota e sondas reais),
 * espelhado de `pages/lagcheck/src/lib/map/route-map.ts`.
 */
@Composable
fun RouteMeasurementMap(
    modifier: Modifier = Modifier,
    userPoint: MapGeoPoint? = null,
    userLabel: String = "Você",
    regions: List<MapRegionSample> = emptyList(),
    selectedRegionId: String? = null,
    probeFlights: List<MapProbeFlight> = emptyList(),
    animate: Boolean = true,
    reduceMotion: Boolean = false
) {
    var frameTimeMs by remember { mutableLongStateOf(System.currentTimeMillis()) }
    val textMeasurer = rememberTextMeasurer()

    LaunchedEffect(animate, reduceMotion, probeFlights) {
        if (!animate || reduceMotion || probeFlights.isEmpty()) return@LaunchedEffect
        while (true) {
            withFrameMillis {
                frameTimeMs = System.currentTimeMillis()
            }
        }
    }

    val summary = remember(userLabel, regions, selectedRegionId) {
        val selected = regions.firstOrNull { it.id == selectedRegionId }
        if (selected != null) {
            val ms = selected.latencyMs?.roundToInt()
            if (ms != null) "Mapa de rota: $userLabel até ${selected.label}, $ms milissegundos"
            else "Mapa de rota: $userLabel até ${selected.label}"
        } else {
            "Mapa de medição com ${regions.size} regiões"
        }
    }

    val shape = RoundedCornerShape(12.dp)
    Box(
        modifier = modifier
            .clip(shape)
            .background(LagCheckColors.Background)
            .border(1.dp, LagCheckColors.BorderHairline, shape)
            .semantics { contentDescription = summary }
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            drawRouteMap(
                nowMs = frameTimeMs,
                userPoint = userPoint,
                userLabel = userLabel,
                regions = regions,
                selectedRegionId = selectedRegionId,
                probeFlights = probeFlights,
                animate = animate && !reduceMotion,
                textMeasurer = textMeasurer
            )
        }
    }
}

private fun DrawScope.drawRouteMap(
    nowMs: Long,
    userPoint: MapGeoPoint?,
    userLabel: String,
    regions: List<MapRegionSample>,
    selectedRegionId: String?,
    probeFlights: List<MapProbeFlight>,
    animate: Boolean,
    textMeasurer: TextMeasurer
) {
    val width = size.width
    val height = size.height
    if (width <= 0f || height <= 0f) return

    val camera = resolveCamera(userPoint, regions, selectedRegionId, width, height)
    val dotRadius = if (camera.zoom > 2.0) 1.35.dp.toPx() else 1.05.dp.toPx()
    val landColor = LagCheckColors.TextSecondary.copy(alpha = 0.34f)

    // 1. Grade de pontos de terra (Natural Earth 110m)
    for (point in RouteMapProjection.landPoints) {
        val p = RouteMapProjection.project(point.lat, point.lon, camera, width, height)
        if (p.x < -2f || p.x > width + 2f || p.y < -2f || p.y > height + 2f) continue
        drawCircle(color = landColor, radius = dotRadius, center = Offset(p.x, p.y))
    }

    // 2. Pontos das regiões candidatas
    for (region in regions) {
        if (region.id == selectedRegionId) continue
        val coord = RouteMapProjection.regionPoint(region.id) ?: continue
        val p = RouteMapProjection.project(coord.lat, coord.lon, camera, width, height)
        val r = if (region.answered) 3.dp.toPx() else 2.2.dp.toPx()
        val color = if (region.answered) LagCheckColors.TextSecondary else LagCheckColors.TextTertiary
        drawCircle(color = color, radius = r, center = Offset(p.x, p.y))
    }

    // 3. Arcos de rota e sondas em voo (apenas medições reais)
    val userScreen = userPoint?.let { RouteMapProjection.project(it.lat, it.lon, camera, width, height) }
    if (userScreen != null) {
        if (selectedRegionId != null) {
            val targetCoord = RouteMapProjection.regionPoint(selectedRegionId)
            if (targetCoord != null) {
                val target = RouteMapProjection.project(targetCoord.lat, targetCoord.lon, camera, width, height)
                val arc = RouteMapProjection.computeArc(userScreen, target)
                val path = Path().apply {
                    moveTo(arc.x0.toFloat(), arc.y0.toFloat())
                    quadraticTo(arc.cx.toFloat(), arc.cy.toFloat(), arc.x1.toFloat(), arc.y1.toFloat())
                }
                drawPath(path = path, color = LagCheckColors.AccentPrimary, style = Stroke(width = 1.6.dp.toPx()))
            }
        }

        if (animate) {
            for (flight in probeFlights) {
                val elapsed = nowMs - flight.startedAtMs
                if (elapsed < 0L || elapsed > flight.durationMs) continue
                val targetCoord = RouteMapProjection.regionPoint(flight.regionId) ?: continue
                val target = RouteMapProjection.project(targetCoord.lat, targetCoord.lon, camera, width, height)
                val arc = RouteMapProjection.computeArc(userScreen, target)

                if (flight.isSweep && flight.regionId != selectedRegionId) {
                    val sweepPath = Path().apply {
                        moveTo(arc.x0.toFloat(), arc.y0.toFloat())
                        quadraticTo(arc.cx.toFloat(), arc.cy.toFloat(), arc.x1.toFloat(), arc.y1.toFloat())
                    }
                    drawPath(
                        path = sweepPath,
                        color = LagCheckColors.AccentPrimary.copy(alpha = 0.22f),
                        style = Stroke(width = 1.dp.toPx())
                    )
                }

                val progress = RouteMapProjection.ease(elapsed.toDouble() / flight.durationMs.coerceAtLeast(1L).toDouble())
                val t = if (flight.isInbound) 1.0 - progress else progress
                val pos = RouteMapProjection.bezierPoint(arc, t)
                val packetColor = if (flight.isInbound) LagCheckColors.TextPrimary else LagCheckColors.AccentPrimary
                val packetRadius = if (flight.isInbound) 3.2.dp.toPx() else 2.6.dp.toPx()
                drawCircle(color = packetColor, radius = packetRadius, center = Offset(pos.x, pos.y))
            }
        }
    }

    // 4. Pinos principais e rótulos sem sobreposição
    val placedLabels = mutableListOf<MapBox>()
    if (selectedRegionId != null) {
        val targetCoord = RouteMapProjection.regionPoint(selectedRegionId)
        if (targetCoord != null) {
            val target = RouteMapProjection.project(targetCoord.lat, targetCoord.lon, camera, width, height)
            val pinRadius = 4.5.dp.toPx()
            drawCircle(color = LagCheckColors.AccentPrimary, radius = pinRadius, center = Offset(target.x, target.y))
            drawCircle(
                color = LagCheckColors.TextPrimary,
                radius = pinRadius,
                center = Offset(target.x, target.y),
                style = Stroke(width = 1.2.dp.toPx())
            )
            val region = regions.firstOrNull { it.id == selectedRegionId }
            if (region != null) {
                val label = region.latencyMs?.let { "${region.label} ${it.roundToInt()} ms" } ?: region.label
                drawLabel(label, target, width, height, placedLabels, accent = true, textMeasurer = textMeasurer)
            }
        }
    }

    if (userScreen != null) {
        drawCircle(
            color = LagCheckColors.TextPrimary,
            radius = 4.dp.toPx(),
            center = Offset(userScreen.x, userScreen.y)
        )
        drawLabel(userLabel, userScreen, width, height, placedLabels, accent = false, textMeasurer = textMeasurer)
    }
}

private fun resolveCamera(
    userPoint: MapGeoPoint?,
    regions: List<MapRegionSample>,
    selectedRegionId: String?,
    width: Float,
    height: Float
): MapCamera {
    val focusPoints = mutableListOf<MapGeoPoint>()
    if (userPoint != null) focusPoints.add(userPoint)
    if (selectedRegionId != null) {
        val selected = RouteMapProjection.regionPoint(selectedRegionId)
        if (selected != null) {
            focusPoints.add(selected)
            return RouteMapProjection.fitCamera(
                points = focusPoints,
                width = width,
                height = height,
                maxZoom = RouteMapProjection.ROUTE_MAX_ZOOM
            )
        }
    }
    if (regions.isEmpty()) return MapCamera.WORLD
    val allPoints = focusPoints + regions.mapNotNull { RouteMapProjection.regionPoint(it.id) }
    return RouteMapProjection.fitCamera(
        points = allPoints,
        width = width,
        height = height,
        maxZoom = RouteMapProjection.ROUTE_MAX_ZOOM
    )
}

private fun DrawScope.drawLabel(
    text: String,
    point: MapPoint2D,
    canvasWidth: Float,
    canvasHeight: Float,
    placed: MutableList<MapBox>,
    accent: Boolean,
    textMeasurer: TextMeasurer
) {
    val style = TextStyle(
        color = if (accent) LagCheckColors.AccentPrimaryLight else LagCheckColors.TextPrimary,
        fontSize = 11.sp,
        fontWeight = FontWeight.SemiBold,
        fontFamily = if (accent) FontFamily.Monospace else FontFamily.Default
    )
    val measured = textMeasurer.measure(text = text, style = style)
    val padX = 6.dp.toPx()
    val padY = 3.dp.toPx()
    val boxW = measured.size.width + padX * 2f
    val boxH = measured.size.height + padY * 2f
    val gap = 8.dp.toPx()

    val candidates = listOf(
        MapBox(point.x - boxW / 2f, point.y - boxH - gap, boxW, boxH),
        MapBox(point.x - boxW / 2f, point.y + gap, boxW, boxH),
        MapBox(point.x + gap, point.y - boxH / 2f, boxW, boxH),
        MapBox(point.x - boxW - gap, point.y - boxH / 2f, boxW, boxH)
    )

    val margin = 6.dp.toPx()
    val chosen = candidates.firstOrNull { box ->
        box.x >= margin &&
            box.x + box.width <= canvasWidth - margin &&
            box.y >= margin &&
            box.y + box.height <= canvasHeight - margin &&
            placed.none { it.overlaps(box) }
    } ?: return

    placed.add(chosen)
    val radius = 6.dp.toPx()
    drawRoundRect(
        color = LagCheckColors.Background.copy(alpha = 0.86f),
        topLeft = Offset(chosen.x, chosen.y),
        size = Size(chosen.width, chosen.height),
        cornerRadius = CornerRadius(radius, radius)
    )
    drawRoundRect(
        color = LagCheckColors.BorderHairline,
        topLeft = Offset(chosen.x, chosen.y),
        size = Size(chosen.width, chosen.height),
        cornerRadius = CornerRadius(radius, radius),
        style = Stroke(width = 1.dp.toPx())
    )
    drawText(
        textLayoutResult = measured,
        topLeft = Offset(chosen.x + padX, chosen.y + padY)
    )
}
