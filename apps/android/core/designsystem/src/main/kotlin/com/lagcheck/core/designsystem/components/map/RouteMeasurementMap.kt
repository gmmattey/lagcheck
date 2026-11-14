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
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckRadius
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

private val SweepTrail = Color(0x38A78BFA) // rgba(167, 139, 250, 0.22)
private val LabelFill = Color(0xE60B0D10) // rgba(11, 13, 16, 0.9)
private val LabelStroke = Color(0x29F4F5F7) // rgba(244, 245, 247, 0.16)

/**
 * Mapa de medição: mapa-múndi de pontos com "Você", as regiões medidas, o arco da rota e as sondas reais. Desenho
 * espelhado de `RouteMap.draw()` do site (`pages/lagcheck/src/lib/map/route-map.ts`) e de
 * `RouteMeasurementMapView.swift`. Plano, sem gradiente, brilho nem halo. Só roda quadros enquanto há movimento.
 */
@Composable
fun RouteMeasurementMap(
    controller: RouteMapController,
    userLabel: String,
    unavailableLabel: String,
    accessibilityText: String,
    regionName: (String) -> String,
    modifier: Modifier = Modifier,
    reduceMotion: Boolean = false
) {
    var frameMs by remember { mutableLongStateOf(RouteMapController.now()) }
    val textMeasurer = rememberTextMeasurer()
    val deadline = controller.motionDeadlineMs
    val moving = controller.animate && !reduceMotion

    LaunchedEffect(Unit) { controller.viewAppeared() }
    LaunchedEffect(deadline, moving) {
        if (!moving) return@LaunchedEffect
        while (RouteMapController.now() <= deadline + 50) {
            withFrameMillis { frameMs = RouteMapController.now() }
        }
        frameMs = RouteMapController.now()
    }

    // Lidos fora do desenho para o Compose observar as entradas do controlador.
    val user = controller.user
    val userCity = controller.userCity
    val unavailable = controller.locationUnavailable
    val selectedId = controller.selectedId
    val selectedMs = controller.selectedMs
    val regions = controller.regions
    val packets = controller.packets
    val leaderId = controller.leaderId

    val shape = RoundedCornerShape(LagCheckRadius.md)
    Box(
        modifier = modifier
            .clip(shape)
            .background(LagCheckColors.Background)
            .border(1.dp, LagCheckColors.BorderHairline, shape)
            .semantics {
                contentDescription = accessibilityText
                role = Role.Image
            }
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val now = if (moving) frameMs else RouteMapController.now()
            drawRouteMap(
                controller = controller,
                now = now,
                reduceMotion = reduceMotion,
                user = user,
                userCity = userCity,
                unavailable = unavailable,
                selectedId = selectedId,
                selectedMs = selectedMs,
                regions = regions,
                packets = packets,
                leaderId = leaderId,
                userLabel = userLabel,
                unavailableLabel = unavailableLabel,
                regionName = regionName,
                textMeasurer = textMeasurer
            )
        }
    }
}

private fun DrawScope.drawRouteMap(
    controller: RouteMapController,
    now: Long,
    reduceMotion: Boolean,
    user: MapGeoPoint?,
    userCity: String?,
    unavailable: Boolean,
    selectedId: String?,
    selectedMs: Double?,
    regions: Map<String, RouteMapRegionState>,
    packets: List<RouteMapPacket>,
    leaderId: String?,
    userLabel: String,
    unavailableLabel: String,
    regionName: (String) -> String,
    textMeasurer: TextMeasurer
) {
    // O site desenha em pixels CSS; aqui a mesma geometria é medida em dp.
    val density = density
    val w = size.width / density
    val h = size.height / density
    if (w <= 0f || h <= 0f) return
    val cam = controller.advanceCamera(w, h, now, reduceMotion)
    val showPackets = controller.animate && !reduceMotion
    fun p(geo: MapGeoPoint): Offset {
        val pt = RouteMapProjection.project(geo.lat, geo.lon, cam, w, h)
        return Offset(pt.x * density, pt.y * density)
    }
    fun px(v: Double): Float = (v * density).toFloat()

    drawRect(LagCheckColors.Background)

    // 1) Mapa de pontos
    val k = (w / 360.0) * cam.zoom
    val r = min(max(k * RouteMapGridData.STEP * 0.34, 0.8), 3.4)
    val rPx = px(r)
    val land = LagCheckColors.TextSecondary.copy(alpha = 0.34f)
    for (point in RouteMapProjection.landPoints) {
        val c = p(point)
        if (c.x < -rPx || c.x > size.width + rPx || c.y < -rPx || c.y > size.height + rPx) continue
        drawCircle(land, rPx, c)
    }

    val selectedGeo = selectedId?.let { RouteMapProjection.regionPoint(it) }
    val userPt = user?.let { p(it) }
    val selectedPt = selectedGeo?.let { p(it) }

    // 2) Regiões candidatas
    for ((id, geo) in RouteMapProjection.REGION_COORDINATES) {
        if (id == selectedId) continue
        val c = p(geo)
        when {
            id == leaderId -> drawCircle(LagCheckColors.AccentPrimaryLight, px(4.2), c)
            regions[id]?.answered == true -> drawCircle(LagCheckColors.TextSecondary, px(2.8), c)
            else -> drawCircle(LagCheckColors.TextTertiary, px(2.8), c, style = Stroke(px(1.2)))
        }
    }

    // 3) Arco e sondas em voo
    if (userPt != null && selectedPt != null) {
        val arc = arcOf(userPt, selectedPt, size.height * 0.38f)
        drawPath(arcPath(arc), LagCheckColors.AccentPrimary, style = Stroke(px(1.6)))
        if (showPackets) {
            for (packet in packets) {
                if (packet.isSweep) continue
                val flight = packet.flight(now) ?: continue
                val pos = RouteMapProjection.bezierPoint(arc, if (flight.outbound) flight.t else 1.0 - flight.t)
                drawCircle(
                    if (flight.outbound) LagCheckColors.AccentPrimaryLight else LagCheckColors.TextPrimary,
                    px(3.2),
                    Offset(pos.x, pos.y)
                )
            }
        }
    }

    // 3b) Varredura: uma sonda por servidor candidato, com um traço fino enquanto está em voo
    if (userPt != null && selectedPt == null && showPackets) {
        for (packet in packets) {
            if (!packet.isSweep) continue
            val flight = packet.flight(now) ?: continue
            val geo = RouteMapProjection.regionPoint(packet.regionId) ?: continue
            val arc = arcOf(userPt, p(geo), size.height * 0.38f)
            drawPath(arcPath(arc), SweepTrail, style = Stroke(px(1.0)))
            val pos = RouteMapProjection.bezierPoint(arc, if (flight.outbound) flight.t else 1.0 - flight.t)
            drawCircle(
                if (flight.outbound) LagCheckColors.AccentPrimaryLight else LagCheckColors.TextPrimary,
                px(2.6),
                Offset(pos.x, pos.y)
            )
        }
    }

    // 4) Pinos
    if (selectedPt != null) {
        drawCircle(LagCheckColors.AccentPrimary, px(5.6), selectedPt)
        drawCircle(LagCheckColors.Background, px(5.6), selectedPt, style = Stroke(px(2.0)))
    }
    if (userPt != null) {
        drawCircle(LagCheckColors.TextPrimary, px(5.0), userPt)
        drawCircle(LagCheckColors.Background, px(5.0), userPt, style = Stroke(px(2.0)))
    }

    // 5) Rótulos: sempre inteiros dentro do mapa e sem se sobrepor
    val placed = mutableListOf<MapBox>()
    if (userPt != null) {
        val youText = userCity?.let { "$userLabel · $it" } ?: userLabel
        placed += drawLabel(AnnotatedString(youText), userPt, above = true, others = placed, textMeasurer = textMeasurer)
    }
    val labelId = selectedId ?: leaderId
    val labelPt = selectedPt ?: leaderId?.let { RouteMapProjection.regionPoint(it) }?.let { p(it) }
    if (labelId != null && labelPt != null) {
        val ms = if (selectedId != null) selectedMs else regions[labelId]?.ms
        val text = buildAnnotatedString {
            append(regionName(labelId))
            if (ms != null) {
                withStyle(SpanStyle(fontFamily = com.lagcheck.core.designsystem.theme.LagCheckTypography.ChakraPetch, color = LagCheckColors.AccentPrimaryLight)) {
                    append(" · ${ms.roundToInt()} ms")
                }
            }
        }
        placed += drawLabel(text, labelPt, above = false, others = placed, textMeasurer = textMeasurer)
    }

    // 6) Sem localização: nota discreta
    if (unavailable && controller.animate) {
        val note = textMeasurer.measure(
            unavailableLabel,
            TextStyle(color = LagCheckColors.TextTertiary, fontSize = 11.sp)
        )
        drawText(note, topLeft = Offset(px(14.0), size.height - px(12.0) - note.size.height))
    }
}

/** Arco calculado em dp (unidade do site, inclusive o abaulamento mínimo de 24) e devolvido em pixels. */
private fun DrawScope.arcOf(from: Offset, to: Offset, maxHeight: Float): MapArc {
    val d = density
    val a = RouteMapProjection.computeArc(
        MapPoint2D(from.x / d, from.y / d),
        MapPoint2D(to.x / d, to.y / d),
        (maxHeight / d).toDouble()
    )
    return MapArc(a.x0 * d, a.y0 * d, a.x1 * d, a.y1 * d, a.cx * d, a.cy * d)
}

private fun arcPath(arc: MapArc) = Path().apply {
    moveTo(arc.x0.toFloat(), arc.y0.toFloat())
    quadraticTo(arc.cx.toFloat(), arc.cy.toFloat(), arc.x1.toFloat(), arc.y1.toFloat())
}

private fun DrawScope.drawLabel(
    text: AnnotatedString,
    anchor: Offset,
    above: Boolean,
    others: List<MapBox>,
    textMeasurer: TextMeasurer
): MapBox {
    val style = TextStyle(color = LagCheckColors.TextPrimary, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
    val measured = textMeasurer.measure(text, style)
    val unit = 1.dp.toPx()
    val padX = 8f * unit
    val boxW = measured.size.width + padX * 2f
    val boxH = 24f * unit
    val edge = 4f * unit
    val gap = 12f * unit
    var box = MapBox(0f, 0f, boxW, boxH)

    fun place(isAbove: Boolean): MapBox {
        val x = min(max(anchor.x - boxW / 2f, edge), max(size.width - boxW - edge, edge))
        val rawY = if (isAbove) anchor.y - gap - boxH else anchor.y + gap
        val y = min(max(rawY, edge), max(size.height - boxH - edge, edge))
        return MapBox(x, y, boxW, boxH)
    }
    box = place(above)
    if (others.any { it.overlaps(box, edge) }) box = place(!above)
    others.firstOrNull { it.overlaps(box, edge) }?.let { other ->
        // Ainda sobrepõe: empurra para o lado, sem sair do mapa.
        val side = 6f * unit
        val x = if (other.x + other.width + side + boxW <= size.width - edge) other.x + other.width + side
        else max(other.x - boxW - side, edge)
        box = box.copy(x = x)
    }

    val radius = CornerRadius(6f * unit, 6f * unit)
    val half = unit / 2f
    drawRoundRect(LabelFill, Offset(box.x + half, box.y + half), Size(box.width - unit, box.height - unit), radius)
    drawRoundRect(
        LabelStroke, Offset(box.x + half, box.y + half), Size(box.width - unit, box.height - unit), radius,
        style = Stroke(unit)
    )
    drawText(measured, topLeft = Offset(box.x + padX, box.y + (boxH - measured.size.height) / 2f + half))
    return box
}
