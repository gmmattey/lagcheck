package com.lagcheck.desktop.ui.map

import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.PointMode
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.lagcheck.desktop.ds.LcColor
import com.lagcheck.desktop.ds.LcType
import kotlin.math.abs
import kotlin.math.hypot
import kotlin.math.roundToInt

/**
 * Motor de renderização em lote para o RouteMap em Compose Desktop.
 */
object MapRenderer {

    private data class Light(val x: Float, val y: Float, val radius: Float, val alpha: Float)

    private val LabelTextStyle = TextStyle(
        fontFamily = LcType.Body.fontFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 12.sp,
        color = LcColor.TextPrimary
    )

    /**
     * Renderiza a grade de pontos da terra com iluminação e culling.
     */
    fun drawGrid(
        scope: DrawScope,
        grid: MapGrid,
        cam: Camera,
        userOffset: Offset?,
        regionOffset: Offset,
        state: RouteMapState,
        arc: MapArc?
    ) {
        val w = scope.size.width
        val h = scope.size.height
        val density = scope.density

        val k = (w / 360f) * cam.zoom.toFloat()
        val sp = k * grid.step.toFloat()
        val r0 = (sp * 0.30f).coerceIn(1.1f * density, 4.6f * density)

        // Coleta fontes de luz
        val lights = mutableListOf<Light>()

        // Luz do usuário (apenas se houver usuário)
        if (userOffset != null) {
            val userLightRadius = 46f * density * cam.zoom.toFloat().coerceIn(1f, 2f)
            lights.add(Light(userOffset.x, userOffset.y, userLightRadius, 0.55f))
        }

        // Luz da região
        val hasRtt = state.rttHistory.isNotEmpty()
        lights.add(Light(regionOffset.x, regionOffset.y, if (hasRtt) 60f * density else 28f * density, if (hasRtt) 0.8f else 0.3f))

        // Luzes de pacotes (apenas se houver arco ativo)
        if (!state.reducedMotion && arc != null) {
            for (p in state.packets) {
                val pos = bezierPoint(arc, p.progress)
                lights.add(Light(pos.x, pos.y, 58f * density, 0.95f))
            }
        }

        // Anéis de onda ativos convertidos para coordenadas de tela
        val activeScreenRings = if (!state.reducedMotion) {
            state.rings.mapNotNull { ring ->
                val center = project(ring.lat, ring.lon, cam, w, h)
                val e = ((System.nanoTime() - ring.startTimeNanos).toFloat() / ring.durationNanos.toFloat()).coerceIn(0f, 1f)
                val currentR = easeOut(e) * ring.maxRadiusPx * density
                val ringA = (1f - e) * 0.9f
                Triple(center, currentR, ringA)
            }
        } else {
            emptyList()
        }

        val normalPoints = ArrayList<Offset>(grid.pointCount)
        // Guardamos (x, y, boost) dos pontos iluminados
        val boostedPoints = ArrayList<Triple<Float, Float, Float>>(64)

        val totalPoints = grid.pointCount
        val lons = grid.landLons
        val lats = grid.landLats

        val camLon = cam.lon.toFloat()
        val camLat = cam.lat.toFloat()
        val halfW = w / 2f
        val halfH = h / 2f

        for (i in 0 until totalPoints) {
            val lon = lons[i]
            val lat = lats[i]
            val px = halfW + (lon - camLon) * k
            val py = halfH - (lat - camLat) * k

            // Culling fora da tela com margem de segurança
            if (px < -6f || px > w + 6f || py < -6f || py > h + 6f) continue

            var maxBoost = 0f

            // Verificação contra luzes pontuais
            for (light in lights) {
                val dx = px - light.x
                val dy = py - light.y
                val d2 = dx * dx + dy * dy
                val r2 = light.radius * light.radius
                if (d2 < r2) {
                    val dist = kotlin.math.sqrt(d2)
                    val v = (1f - dist / light.radius) * light.alpha
                    if (v > maxBoost) maxBoost = v
                }
            }

            // Verificação contra ondas expansivas
            for ((center, radius, ringAlpha) in activeScreenRings) {
                val dist = hypot((px - center.x).toDouble(), (py - center.y).toDouble()).toFloat()
                val delta = abs(dist - radius)
                if (delta < 16f * density) {
                    val v = (1f - delta / (16f * density)) * ringAlpha
                    if (v > maxBoost) maxBoost = v
                }
            }

            if (maxBoost > 0.04f) {
                boostedPoints.add(Triple(px, py, maxBoost))
            } else {
                normalPoints.add(Offset(px, py))
            }
        }

        // Desenha pontos normais em lote via GPU/Skia (PointMode.Points)
        if (normalPoints.isNotEmpty()) {
            scope.drawPoints(
                points = normalPoints,
                pointMode = PointMode.Points,
                color = LcColor.TextSecondary.copy(alpha = 0.30f),
                strokeWidth = r0 * 2f,
                cap = StrokeCap.Round
            )
        }

        // Desenha pontos iluminados
        for (boosted in boostedPoints) {
            val b = boosted.third
            val alpha = (0.3f + b * 0.7f).coerceIn(0f, 1f)
            val radius = r0 * (1f + b * 0.55f)
            scope.drawCircle(
                color = LcColor.AccentLight.copy(alpha = alpha),
                radius = radius,
                center = Offset(boosted.first, boosted.second)
            )
        }
    }

    /**
     * Renderiza o arco de rota com leve brilho e os anéis de ondas.
     */
    fun drawArcAndRings(
        scope: DrawScope,
        arc: MapArc,
        state: RouteMapState,
        cam: Camera,
        nowNanos: Long
    ) {
        val density = scope.density
        val w = scope.size.width
        val h = scope.size.height

        val hasRtt = state.rttHistory.isNotEmpty()
        val path = Path().apply {
            moveTo(arc.x0, arc.y0)
            quadraticTo(arc.cx, arc.cy, arc.x1, arc.y1)
        }

        // 1. Leve brilho halo sob o arco
        val glowColor = if (hasRtt) LcColor.Good.copy(alpha = 0.20f) else LcColor.TextSecondary.copy(alpha = 0.12f)
        scope.drawPath(
            path = path,
            color = glowColor,
            style = Stroke(width = 5.5f * density, cap = StrokeCap.Round)
        )

        // 2. Traçado do arco: animado se houver movimento, estático em repouso
        val dashPhase = if (state.reducedMotion || !state.hasActiveAnimations) {
            0f
        } else {
            -(nowNanos / 60_000_000f)
        }

        val dashIntervals = if (hasRtt) {
            floatArrayOf(3f * density, 6f * density)
        } else {
            floatArrayOf(3f * density, 7f * density)
        }

        val arcStrokeWidth = if (hasRtt) 2f * density else 1.2f * density
        val arcColor = if (hasRtt) LcColor.Good.copy(alpha = 0.90f) else LcColor.TextSecondary.copy(alpha = 0.55f)

        scope.drawPath(
            path = path,
            color = arcColor,
            style = Stroke(
                width = arcStrokeWidth,
                pathEffect = PathEffect.dashPathEffect(dashIntervals, phase = dashPhase)
            )
        )

        // 3. Renderiza ondas expansivas (rings)
        if (!state.reducedMotion) {
            for (ring in state.rings) {
                val center = project(ring.lat, ring.lon, cam, w, h)
                val elapsed = (nowNanos - ring.startTimeNanos).toFloat() / ring.durationNanos.toFloat()
                if (elapsed in 0f..1f) {
                    val r = (easeOut(elapsed) * ring.maxRadiusPx * density).coerceAtLeast(0.1f)
                    val alpha = ((1f - elapsed) * 0.8f).coerceIn(0f, 1f)
                    scope.drawCircle(
                        color = ring.color.copy(alpha = alpha),
                        radius = r,
                        center = center,
                        style = Stroke(width = 1.6f * density)
                    )
                }
            }
        }
    }

    /**
     * Renderiza os pacotes em trânsito com rastro de 22 segmentos e cabeça brilhante.
     */
    fun drawPackets(
        scope: DrawScope,
        arc: MapArc,
        state: RouteMapState
    ) {
        if (state.reducedMotion) return

        val density = scope.density
        val seg = 22
        val tail = 0.20f

        for (p in state.packets) {
            val progress = p.progress
            val col = p.color
            val isLost = p.lost
            val elapsed = p.elapsedFraction

            // Rastro com 22 segmentos decrescentes
            for (j in 0 until seg) {
                val t0: Float
                val t1: Float
                if (p.phase == PacketPhase.OUTBOUND) {
                    t1 = (progress - tail * (j + 1) / seg).coerceAtLeast(0f)
                    t0 = (progress - tail * j / seg).coerceAtLeast(0f)
                } else {
                    t1 = (progress + tail * (j + 1) / seg).coerceAtMost(1f)
                    t0 = (progress + tail * j / seg).coerceAtMost(1f)
                }

                val a = bezierPoint(arc, t0)
                val b = bezierPoint(arc, t1)

                val segFraction = 1f - j.toFloat() / seg
                val lostAlpha = if (isLost && elapsed > 0.4f) {
                    (1f - (elapsed - 0.4f) / 0.18f).coerceIn(0f, 1f)
                } else {
                    1f
                }
                val alpha = (segFraction * lostAlpha).coerceIn(0f, 1f)
                val strokeW = (3.4f * segFraction + 0.6f) * density

                scope.drawLine(
                    color = col.copy(alpha = alpha),
                    start = a,
                    end = b,
                    strokeWidth = strokeW,
                    cap = StrokeCap.Round
                )
            }

            // Cabeça do pacote
            val head = bezierPoint(arc, progress)
            val glowRadius = 16f * density
            scope.drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(col.copy(alpha = 0.9f), Color.Transparent),
                    center = head,
                    radius = glowRadius
                ),
                radius = glowRadius,
                center = head
            )

            // Ponto central branco
            scope.drawCircle(
                color = Color.White,
                radius = 3f * density,
                center = head
            )

            // Marca de perda em coral (X a partir de 50% até 58%)
            if (isLost && elapsed > 0.5f) {
                val coralAlpha = ((elapsed - 0.5f) / 0.08f).coerceIn(0f, 1f)
                val xSize = 6f * density
                val coralColor = LcColor.Coral.copy(alpha = coralAlpha)
                val xStroke = 2.4f * density

                scope.drawLine(
                    color = coralColor,
                    start = Offset(head.x - xSize, head.y - xSize),
                    end = Offset(head.x + xSize, head.y + xSize),
                    strokeWidth = xStroke,
                    cap = StrokeCap.Round
                )
                scope.drawLine(
                    color = coralColor,
                    start = Offset(head.x + xSize, head.y - xSize),
                    end = Offset(head.x - xSize, head.y + xSize),
                    strokeWidth = xStroke,
                    cap = StrokeCap.Round
                )
            }
        }
    }

    /**
     * Renderiza os pinos de "Você" (se presente) e da "Região" com rótulos de cantos retos (raio 5 dp).
     */
    fun drawPinsAndLabels(
        scope: DrawScope,
        userOffset: Offset?,
        regionOffset: Offset,
        user: MapPoint?,
        region: MapPoint,
        state: RouteMapState,
        textMeasurer: TextMeasurer,
        nowNanos: Long
    ) {
        val density = scope.density
        val w = scope.size.width
        val h = scope.size.height
        val tSec = nowNanos / 1_000_000_000.0

        val hasRtt = state.rttHistory.isNotEmpty()
        val medianRtt = state.medianRttMs

        // ---- PINO REGIÃO ----
        // Anel pulsante apenas se !reducedMotion e já houver medição/RTT
        if (!state.reducedMotion && hasRtt) {
            val ph = ((tSec * 0.9) % 1.0).toFloat()
            val pulseR = (6f + ph * 22f) * density
            val pulseA = ((1f - ph) * 0.7f).coerceIn(0f, 1f)
            scope.drawCircle(
                color = LcColor.Good.copy(alpha = pulseA),
                radius = pulseR,
                center = regionOffset,
                style = Stroke(width = 2f * density)
            )
        }

        // Brilho suave da região medida
        if (hasRtt) {
            scope.drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(LcColor.Good.copy(alpha = 0.45f), Color.Transparent),
                    center = regionOffset,
                    radius = 16f * density
                ),
                radius = 16f * density,
                center = regionOffset
            )
        }

        // Círculo central da região
        val regionRadius = (if (hasRtt) 7f else 5f) * density
        val regionFillColor = if (hasRtt) LcColor.Good else LcColor.Surface
        val regionBorderColor = if (hasRtt) LcColor.Good else LcColor.TextSecondary.copy(alpha = 0.9f)

        scope.drawCircle(
            color = regionFillColor,
            radius = regionRadius,
            center = regionOffset
        )
        scope.drawCircle(
            color = regionBorderColor,
            radius = regionRadius,
            center = regionOffset,
            style = Stroke(width = 2f * density)
        )

        // Rótulo da região: canto reto (5 dp, nunca pill)
        val regionLabelText = if (medianRtt != null) {
            "${region.name} · ${medianRtt.roundToInt()} ms"
        } else {
            region.name
        }
        drawLabelBox(
            scope = scope,
            textMeasurer = textMeasurer,
            text = regionLabelText,
            pinX = regionOffset.x,
            pinY = regionOffset.y,
            above = false,
            screenWidth = w,
            screenHeight = h
        )

        // ---- PINO VOCÊ (apenas se user != null) ----
        if (user != null && userOffset != null) {
            // Anel pulsante apenas se !reducedMotion
            if (!state.reducedMotion) {
                val ph = ((tSec * 0.8) % 1.0).toFloat()
                val pulseR = (7f + ph * 26f) * density
                val pulseA = ((1f - ph) * 0.7f).coerceIn(0f, 1f)
                scope.drawCircle(
                    color = LcColor.AccentLight.copy(alpha = pulseA),
                    radius = pulseR,
                    center = userOffset,
                    style = Stroke(width = 2f * density)
                )
            }

            // Brilho / sombra roxa (18 dp de blur como no protótipo)
            scope.drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(LcColor.Accent.copy(alpha = 0.55f), Color.Transparent),
                    center = userOffset,
                    radius = 18f * density
                ),
                radius = 18f * density,
                center = userOffset
            )

            // Círculo central "Você": roxo gamer com borda clara
            val userRadius = 7f * density
            scope.drawCircle(
                color = LcColor.Accent,
                radius = userRadius,
                center = userOffset
            )
            scope.drawCircle(
                color = LcColor.TextPrimary,
                radius = userRadius,
                center = userOffset,
                style = Stroke(width = 2.5f * density)
            )

            // Rótulo "Você · {cidade}": canto reto (5 dp) acima do pino
            val userLabelText = "Você · ${user.name}"
            drawLabelBox(
                scope = scope,
                textMeasurer = textMeasurer,
                text = userLabelText,
                pinX = userOffset.x,
                pinY = userOffset.y,
                above = true,
                screenWidth = w,
                screenHeight = h
            )
        }
    }

    private fun drawLabelBox(
        scope: DrawScope,
        textMeasurer: TextMeasurer,
        text: String,
        pinX: Float,
        pinY: Float,
        above: Boolean,
        screenWidth: Float,
        screenHeight: Float
    ) {
        val density = scope.density
        val textLayout = textMeasurer.measure(
            text = text,
            style = LabelTextStyle
        )

        val padH = 8f * density
        val boxW = textLayout.size.width + padH * 2f
        val boxH = 22f * density

        var lx = if (above) {
            pinX - boxW / 2f
        } else {
            pinX + 12f * density
        }

        var ly = if (above) {
            pinY - boxH - 14f * density
        } else {
            pinY - boxH / 2f
        }

        // Se passar da borda direita da tela, inverte para a esquerda do pino
        if (!above && lx + boxW > screenWidth - 8f * density) {
            lx = pinX - 12f * density - boxW
        }

        // Garante clamp dentro do viewport visível
        lx = lx.coerceIn(6f * density, screenWidth - boxW - 6f * density)
        ly = ly.coerceIn(6f * density, screenHeight - boxH - 6f * density)

        val corner = CornerRadius(5f * density, 5f * density)

        // Fundo do rótulo
        scope.drawRoundRect(
            color = LcColor.Background.copy(alpha = 0.90f),
            topLeft = Offset(lx, ly),
            size = Size(boxW, boxH),
            cornerRadius = corner
        )

        // Borda fina (1 px)
        scope.drawRoundRect(
            color = Color(0x24FFFFFF),
            topLeft = Offset(lx, ly),
            size = Size(boxW, boxH),
            cornerRadius = corner,
            style = Stroke(width = 1f * density)
        )

        // Texto centralizado verticalmente no rótulo
        val textY = ly + (boxH - textLayout.size.height) / 2f
        scope.drawText(
            textLayoutResult = textLayout,
            topLeft = Offset(lx + padH, textY)
        )
    }
}
