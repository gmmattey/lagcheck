package com.lagcheck.desktop.ui.map

import androidx.compose.ui.geometry.Offset
import kotlin.math.abs
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.pow

/**
 * Estado da câmera do mapa: centro geográfico (lon, lat) e nível de zoom.
 */
data class Camera(
    val lon: Double,
    val lat: Double,
    val zoom: Double
)

/**
 * Arco quadrático de rota entre dois pontos em coordenadas de tela.
 */
data class MapArc(
    val x0: Float,
    val y0: Float,
    val x1: Float,
    val y1: Float,
    val cx: Float,
    val cy: Float
)

/**
 * Projeta latitude e longitude geográficas para coordenadas de tela (x, y)
 * usando a projeção cilíndrica equiretangular (Plate Carrée).
 */
fun project(lat: Double, lon: Double, cam: Camera, width: Float, height: Float): Offset {
    val k = (width / 360.0) * cam.zoom
    val x = width / 2.0 + (lon - cam.lon) * k
    val y = height / 2.0 - (lat - cam.lat) * k
    return Offset(x.toFloat(), y.toFloat())
}

/**
 * Projeção inversa: de coordenadas de tela (x, y) de volta para geográficas (lat, lon).
 */
fun unproject(x: Float, y: Float, cam: Camera, width: Float, height: Float): Pair<Double, Double> {
    val k = (width / 360.0) * cam.zoom
    val lon = cam.lon + (x - width / 2.0) / k
    val lat = cam.lat - (y - height / 2.0) / k
    return Pair(lat, lon)
}

/**
 * Calcula o enquadramento ideal da câmera entre dois pontos geográficos ou centrado
 * na região quando o usuário não estiver disponível (modo "só a região").
 * Respeita a proporção de aspecto da tela e limita o zoom máximo em [maxZoom] (padrão 2.2).
 */
fun frameCamera(
    a: MapPoint?,
    b: MapPoint,
    width: Float,
    height: Float,
    maxZoom: Double = 2.2
): Camera {
    if (a == null) {
        return Camera(lon = b.lon, lat = b.lat, zoom = maxZoom)
    }
    val aspect = if (height > 0f) width.toDouble() / height.toDouble() else 1.0
    val span = max(
        max(abs(a.lon - b.lon), abs(a.lat - b.lat) * aspect),
        6.0
    )
    val centerLon = (a.lon + b.lon) / 2.0
    val centerLat = (a.lat + b.lat) / 2.0
    val rawZoom = 360.0 / (span * 2.1)
    val clampedZoom = rawZoom.coerceIn(1.0, maxZoom)
    return Camera(lon = centerLon, lat = centerLat, zoom = clampedZoom)
}

/**
 * Calcula a geometria do arco quadrático apontando para cima (y negativo na tela)
 * entre o ponto de partida [p0] e de chegada [p1].
 * Altura do arco: clamp(distância * 0.3, 34.0, 170.0).
 */
fun computeArc(p0: Offset, p1: Offset): MapArc {
    val dx = p1.x - p0.x
    val dy = p1.y - p0.y
    val d = hypot(dx.toDouble(), dy.toDouble()).toFloat().coerceAtLeast(1f)
    val h = (d * 0.3f).coerceIn(34f, 170f)
    var nx = -dy / d
    var ny = dx / d
    if (ny > 0f) {
        nx = -nx
        ny = -ny
    }
    val cx = (p0.x + p1.x) / 2f + nx * h
    val cy = (p0.y + p1.y) / 2f + ny * h
    return MapArc(p0.x, p0.y, p1.x, p1.y, cx, cy)
}

/**
 * Avalia um ponto ao longo do arco quadrático de Bézier no parâmetro [t] in 0.0..1.0.
 * B(t) = (1-t)^2 * P0 + 2*(1-t)*t * Pc + t^2 * P1
 */
fun bezierPoint(arc: MapArc, t: Float): Offset {
    val clampedT = t.coerceIn(0f, 1f)
    val u = 1f - clampedT
    val x = u * u * arc.x0 + 2f * u * clampedT * arc.cx + clampedT * clampedT * arc.x1
    val y = u * u * arc.y0 + 2f * u * clampedT * arc.cy + clampedT * clampedT * arc.y1
    return Offset(x, y)
}

/**
 * Função de easing cúbica simétrica (idêntica ao protótipo):
 * t < 0.5 ? 4*t^3 : 1 - (-2*t + 2)^3 / 2
 */
fun ease(t: Float): Float {
    val c = t.coerceIn(0f, 1f)
    return if (c < 0.5f) {
        4f * c * c * c
    } else {
        1f - (-2f * c + 2f).pow(3) / 2f
    }
}

/**
 * Função de easing out cúbica (para expansão suave de ondas):
 * 1 - (1 - t)^3
 */
fun easeOut(t: Float): Float {
    val c = t.coerceIn(0f, 1f)
    return 1f - (1f - c).pow(3)
}
