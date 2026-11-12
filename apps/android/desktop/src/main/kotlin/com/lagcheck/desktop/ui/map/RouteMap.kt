package com.lagcheck.desktop.ui.map

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import kotlinx.coroutines.delay
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.desktop.ds.LcColor
import com.lagcheck.desktop.ds.LcRadius
import com.lagcheck.desktop.ds.LcType
import kotlin.math.abs
import kotlin.math.exp
import kotlin.math.max

/**
 * Componente principal do Mapa de Rota com Ping Animado no Compose Desktop.
 *
 * Exibe a grade de pontos do mapa-múndi, o arco quadrático entre "Você" e a região
 * selecionada, pinos identificadores e animações de pacotes geradas por sondas reais.
 *
 * Suporta o modo "só a região" quando [user] for nulo (câmera centrada na região com
 * zoom 2.2, sem pino "Você", sem arco, sem pacotes, com legenda discreta no canto).
 */
@Composable
fun RouteMap(
    state: RouteMapState,
    user: MapPoint?,
    region: MapPoint,
    modifier: Modifier = Modifier
) {
    val grid = remember { MapGrid.loadFromResources() }
    val textMeasurer = rememberTextMeasurer()
    val mapShape = remember { RoundedCornerShape(LcRadius.panel) }

    BoxWithConstraints(
        modifier = modifier
            .clip(mapShape)
            .border(1.dp, LcColor.BorderHairline, mapShape)
            .background(LcColor.Background)
    ) {
        val widthPx = constraints.maxWidth.toFloat().coerceAtLeast(100f)
        val heightPx = constraints.maxHeight.toFloat().coerceAtLeast(100f)

        // Calcula o enquadramento desejado para a câmera (zoom max 2.2).
        // A abertura global só existe quando os dois pontos são válidos; ela não
        // cria origem, destino ou rota quando a localização aproximada falhou.
        val targetCam = remember(user, region, widthPx, heightPx) {
            frameCamera(user, region, widthPx, heightPx, maxZoom = 2.2)
        }
        val globalCam = remember { Camera(lon = 0.0, lat = 12.0, zoom = 1.0) }
        var routeFrameReady by remember(user, region) { mutableStateOf(user == null || state.reducedMotion) }
        val desiredCam = if (routeFrameReady) targetCam else globalCam

        var camLon by remember(user, region, widthPx, heightPx) { mutableDoubleStateOf(desiredCam.lon) }
        var camLat by remember(user, region, widthPx, heightPx) { mutableDoubleStateOf(desiredCam.lat) }
        var camZoom by remember(user, region, widthPx, heightPx) { mutableDoubleStateOf(desiredCam.zoom) }
        var currentFrameNanos by remember { mutableLongStateOf(System.nanoTime()) }

        val cameraSettled = abs(desiredCam.lon - camLon) < 0.0005 &&
            abs(desiredCam.lat - camLat) < 0.0005 &&
            abs(desiredCam.zoom - camZoom) < 0.0005

        val shouldAnimate = !state.reducedMotion && (state.hasActiveAnimations || !cameraSettled)

        LaunchedEffect(state.reducedMotion, user, region) {
            if (state.reducedMotion) {
                routeFrameReady = true
                camLon = targetCam.lon
                camLat = targetCam.lat
                camZoom = targetCam.zoom
            } else if (user != null) {
                routeFrameReady = false
                delay(180)
                routeFrameReady = true
            }
        }

        // Loop de renderização ativo apenas enquanto houver pacotes, ondas ou ajuste de câmera
        LaunchedEffect(shouldAnimate) {
            if (!shouldAnimate) return@LaunchedEffect

            var lastFrame = 0L
            while (true) {
                withFrameNanos { frameTimeNanos ->
                    currentFrameNanos = frameTimeNanos
                    if (lastFrame != 0L) {
                        val dt = ((frameTimeNanos - lastFrame).toDouble() / 1_000_000_000.0).coerceIn(0.0, 0.05)
                        val kc = 1.0 - exp(-dt * 3.2)
                        camLon += (desiredCam.lon - camLon) * kc
                        camLat += (desiredCam.lat - camLat) * kc
                        camZoom += (desiredCam.zoom - camZoom) * kc

                        state.updateTime(frameTimeNanos, user, region)
                    }
                    lastFrame = frameTimeNanos
                }
            }
        }

        val currentCam = if (state.reducedMotion) {
            targetCam
        } else {
            Camera(lon = camLon, lat = camLat, zoom = camZoom)
        }

        Canvas(modifier = Modifier.fillMaxSize()) {
            // 0. Leve gradiente radial discreto de fundo (sem vidro)
            val gradCenter = Offset(size.width * 0.50f, size.height * 0.40f)
            val gradRadius = max(size.width * 0.70f, size.height * 0.90f)
            drawRect(
                brush = Brush.radialGradient(
                    colors = listOf(
                        Color(0xFF151922),
                        LcColor.Background
                    ),
                    center = gradCenter,
                    radius = gradRadius
                ),
                size = size
            )

            val userOffset = user?.let { project(it.lat, it.lon, currentCam, size.width, size.height) }
            val regionOffset = project(region.lat, region.lon, currentCam, size.width, size.height)
            val arc = if (userOffset != null) computeArc(userOffset, regionOffset) else null

            // 1. Grade de pontos do mapa-múndi (dot-matrix)
            MapRenderer.drawGrid(
                scope = this,
                grid = grid,
                cam = currentCam,
                userOffset = userOffset,
                regionOffset = regionOffset,
                state = state,
                arc = arc
            )

            // 2. Arco tracejado e ondas expansivas (apenas quando houver rota com usuário)
            if (arc != null) {
                MapRenderer.drawArcAndRings(
                    scope = this,
                    arc = arc,
                    state = state,
                    cam = currentCam,
                    nowNanos = currentFrameNanos
                )

                // 3. Pacotes de sonda voando pelo arco
                MapRenderer.drawPackets(
                    scope = this,
                    arc = arc,
                    state = state
                )
            }

            // 4. Pinos e rótulos ("Você · {cidade}" se houver e Região)
            MapRenderer.drawPinsAndLabels(
                scope = this,
                userOffset = userOffset,
                regionOffset = regionOffset,
                user = user,
                region = region,
                state = state,
                textMeasurer = textMeasurer,
                nowNanos = currentFrameNanos
            )
        }

        // 5. Legenda discreta no canto inferior quando user == null
        if (user == null) {
            Text(
                text = "Localização aproximada indisponível",
                style = TextStyle(
                    fontFamily = LcType.Body.fontFamily,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Normal,
                    color = LcColor.TextTertiary
                ),
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(start = 16.dp, bottom = 12.dp)
            )
        }
    }
}
