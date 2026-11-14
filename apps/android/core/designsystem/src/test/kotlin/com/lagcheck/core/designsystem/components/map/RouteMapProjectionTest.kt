package com.lagcheck.core.designsystem.components.map

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class RouteMapProjectionTest {
    @Test
    fun gridAndRegionsMatchWebMapModule() {
        assertEquals(21, RouteMapProjection.REGION_COORDINATES.size)
        assertTrue(RouteMapProjection.landPoints.size > 4000)
        assertNotNull(RouteMapProjection.regionPoint("sa-east-1"))
    }

    @Test
    fun fitCameraRespectsRouteMaxZoomAndBezierEndpoints() {
        val user = MapGeoPoint(-23.55, -46.63)
        val region = RouteMapProjection.regionPoint("sa-east-1")!!
        val camera = RouteMapProjection.fitCamera(
            points = listOf(user, region),
            width = 400f,
            height = 250f,
            maxZoom = RouteMapProjection.ROUTE_MAX_ZOOM
        )
        assertTrue(camera.zoom <= RouteMapProjection.ROUTE_MAX_ZOOM)
        assertTrue(camera.zoom >= RouteMapProjection.MIN_ZOOM)

        val p0 = RouteMapProjection.project(user.lat, user.lon, camera, 400f, 250f)
        val p1 = RouteMapProjection.project(38.95, -77.45, camera, 400f, 250f)
        val arc = RouteMapProjection.computeArc(p0, p1)
        val start = RouteMapProjection.bezierPoint(arc, 0.0)
        val end = RouteMapProjection.bezierPoint(arc, 1.0)
        assertEquals(p0.x, start.x, 0.01f)
        assertEquals(p0.y, start.y, 0.01f)
        assertEquals(p1.x, end.x, 0.01f)
        assertEquals(p1.y, end.y, 0.01f)

        assertEquals(300L, RouteMapProjection.returnFlightMs(10.0))
        assertEquals(700L, RouteMapProjection.returnFlightMs(120.0))
    }
}
