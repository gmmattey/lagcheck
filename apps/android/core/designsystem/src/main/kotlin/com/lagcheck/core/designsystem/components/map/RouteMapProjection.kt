package com.lagcheck.core.designsystem.components.map

import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

/** Ponto geográfico (latitude/longitude em graus decimais). */
data class MapGeoPoint(val lat: Double, val lon: Double)

/** Câmera equiretangular do mapa de medição. */
data class MapCamera(val lon: Double, val lat: Double, val zoom: Double) {
    companion object {
        val WORLD = MapCamera(lon = 0.0, lat = 12.0, zoom = 1.0)
    }
}

/** Ponto bidimensional na tela. */
data class MapPoint2D(val x: Float, val y: Float)

/** Retângulo para detecção de colisão de rótulos. */
data class MapBox(val x: Float, val y: Float, val width: Float, val height: Float) {
    fun overlaps(other: MapBox, margin: Float = 4f): Boolean =
        x < other.x + other.width + margin &&
            x + width + margin > other.x &&
            y < other.y + other.height + margin &&
            y + height + margin > other.y
}

/** Arco quadrático de Bézier entre origem e destino na tela. */
data class MapArc(
    val x0: Double,
    val y0: Double,
    val x1: Double,
    val y1: Double,
    val cx: Double,
    val cy: Double
)

/** Estado observado de uma região candidata no mapa. */
data class MapRegionSample(
    val id: String,
    val label: String,
    val latencyMs: Double? = null,
    val answered: Boolean = false
)

/** Evento real de sonda para animar pacotes ao longo do arco da rota. */
data class MapProbeFlight(
    val id: String,
    val regionId: String,
    val isSweep: Boolean = false,
    val isInbound: Boolean,
    val startedAtMs: Long,
    val durationMs: Long
)

/** Regras determinísticas de projeção, câmera, arcos e movimento espelhadas de `pages/lagcheck/src/lib/map/`. */
object RouteMapProjection {
    const val OUT_FLIGHT_MS: Long = 420L
    const val SWEEP_STAGGER_MS: Long = 45L
    const val SWEEP_FLIGHT_MS: Long = 620L
    const val ROUTE_MAX_ZOOM: Double = 3.4
    const val MIN_ZOOM: Double = 1.0
    const val MAX_ZOOM: Double = 7.0
    private const val MIN_LON_SPAN: Double = 8.0
    private const val MIN_LAT_SPAN: Double = 5.0

    val REGION_COORDINATES: Map<String, MapGeoPoint> = mapOf(
        "sa-east-1" to MapGeoPoint(-23.55, -46.63),
        "us-east-1" to MapGeoPoint(38.95, -77.45),
        "us-east-2" to MapGeoPoint(39.96, -83.00),
        "us-west-1" to MapGeoPoint(37.34, -121.89),
        "us-west-2" to MapGeoPoint(45.52, -122.68),
        "ca-central-1" to MapGeoPoint(45.42, -75.70),
        "eu-central-1" to MapGeoPoint(50.11, 8.68),
        "eu-west-1" to MapGeoPoint(53.35, -6.26),
        "eu-west-2" to MapGeoPoint(51.51, -0.13),
        "eu-west-3" to MapGeoPoint(48.86, 2.35),
        "eu-north-1" to MapGeoPoint(59.33, 18.07),
        "eu-south-1" to MapGeoPoint(45.46, 9.19),
        "ap-northeast-1" to MapGeoPoint(35.68, 139.69),
        "ap-northeast-2" to MapGeoPoint(37.57, 126.98),
        "ap-northeast-3" to MapGeoPoint(34.69, 135.50),
        "ap-southeast-1" to MapGeoPoint(1.35, 103.82),
        "ap-southeast-2" to MapGeoPoint(-33.87, 151.21),
        "ap-south-1" to MapGeoPoint(19.08, 72.88),
        "ap-east-1" to MapGeoPoint(22.32, 114.17),
        "me-south-1" to MapGeoPoint(26.22, 50.59),
        "af-south-1" to MapGeoPoint(-33.92, 18.42)
    )

    val landPoints: List<MapGeoPoint> by lazy {
        val points = ArrayList<MapGeoPoint>(5200)
        RouteMapGridData.ROWS.forEachIndexed { rowIndex, line ->
            val lat = RouteMapGridData.LAT_TOP - (rowIndex + 0.5) * RouteMapGridData.STEP
            line.forEachIndexed { colIndex, ch ->
                if (ch == '1') {
                    val lon = -180.0 + (colIndex + 0.5) * RouteMapGridData.STEP
                    points.add(MapGeoPoint(lat = lat, lon = lon))
                }
            }
        }
        points
    }

    fun regionPoint(id: String): MapGeoPoint? = REGION_COORDINATES[id]

    /** Zoom 1 mostra 360° de longitude na largura do mapa. */
    fun project(lat: Double, lon: Double, camera: MapCamera, width: Float, height: Float): MapPoint2D {
        val k = (width / 360.0) * camera.zoom
        return MapPoint2D(
            x = (width / 2.0 + (lon - camera.lon) * k).toFloat(),
            y = (height / 2.0 - (lat - camera.lat) * k).toFloat()
        )
    }

    fun fitCamera(
        points: List<MapGeoPoint>,
        width: Float,
        height: Float,
        padX: Double = 56.0,
        padY: Double = 40.0,
        maxZoom: Double = MAX_ZOOM
    ): MapCamera {
        if (points.isEmpty() || width <= 0f || height <= 0f) return MapCamera.WORLD
        val minLon = points.minOf { it.lon }
        val maxLon = points.maxOf { it.lon }
        val minLat = points.minOf { it.lat }
        val maxLat = points.maxOf { it.lat }
        val lonSpan = max(maxLon - minLon, MIN_LON_SPAN)
        val latSpan = max(maxLat - minLat, MIN_LAT_SPAN)
        val availX = max(width - padX * 2.0, 20.0)
        val availY = max(height - padY * 2.0, 20.0)
        val zoomByLon = (availX * 360.0) / (width * lonSpan)
        val zoomByLat = (availY * 360.0) / (height * latSpan)
        val zoom = min(maxZoom, max(MIN_ZOOM, min(zoomByLon, zoomByLat)))
        return MapCamera(
            lon = (maxLon + minLon) / 2.0,
            lat = (maxLat + minLat) / 2.0,
            zoom = zoom
        )
    }

    /** Arco quadrático entre dois pontos de tela, abaulado para cima. */
    fun computeArc(p0: MapPoint2D, p1: MapPoint2D, maxHeight: Double = 170.0): MapArc {
        val dx = (p1.x - p0.x).toDouble()
        val dy = (p1.y - p0.y).toDouble()
        val d = max(hypot(dx, dy), 1.0)
        val h = min(max(d * 0.3, 24.0), maxHeight)
        var nx = -dy / d
        var ny = dx / d
        if (ny > 0.0) {
            nx = -nx
            ny = -ny
        }
        return MapArc(
            x0 = p0.x.toDouble(),
            y0 = p0.y.toDouble(),
            x1 = p1.x.toDouble(),
            y1 = p1.y.toDouble(),
            cx = (p0.x + p1.x) / 2.0 + nx * h,
            cy = (p0.y + p1.y) / 2.0 + ny * h
        )
    }

    fun bezierPoint(arc: MapArc, t: Double): MapPoint2D {
        val c = min(max(t, 0.0), 1.0)
        val u = 1.0 - c
        return MapPoint2D(
            x = (u * u * arc.x0 + 2.0 * u * c * arc.cx + c * c * arc.x1).toFloat(),
            y = (u * u * arc.y0 + 2.0 * u * c * arc.cy + c * c * arc.y1).toFloat()
        )
    }

    /** Easing cúbico simétrico. */
    fun ease(t: Double): Double {
        val c = min(max(t, 0.0), 1.0)
        return if (c < 0.5) 4.0 * c * c * c else 1.0 - (-2.0 * c + 2.0).pow(3.0) / 2.0
    }

    /** Duração do voo de volta de uma sonda: proporcional ao RTT, entre 300 e 700 ms. */
    fun returnFlightMs(rttMs: Double): Long =
        min(max(rttMs * 8.0, 300.0), 700.0).toLong()
}
