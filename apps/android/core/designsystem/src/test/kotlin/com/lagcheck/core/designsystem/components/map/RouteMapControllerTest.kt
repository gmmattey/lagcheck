package com.lagcheck.core.designsystem.components.map

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Paridade com `RouteMap` do site e com `RouteMapControllerTests` do iOS. */
class RouteMapControllerTest {
    private val br = MapGeoPoint(-15.79, -47.88)

    private fun mapWithUser(animate: Boolean = true) = RouteMapController(animate).apply { setUser(br, nowMs = 0) }

    @Test
    fun nothingMovesWithoutRealEvents() {
        val map = mapWithUser()
        assertTrue(map.packets.isEmpty())
        assertNull(map.selectedId)
    }

    @Test
    fun sweepNeedsUserLikeTheSite() {
        val map = RouteMapController()
        map.regionSent("sa-east-1", 0)
        assertTrue(map.packets.isEmpty())
        // A sonda já enviada parte quando "Você" chega (trySweep do site).
        map.setUser(br, nowMs = 0)
        assertEquals(1, map.packets.size)
    }

    @Test
    fun sweepBurstIsStaggered45msAndFlies620ms() {
        val map = mapWithUser()
        listOf("sa-east-1", "us-east-1", "eu-west-1").forEach { map.regionSent(it, 10_000) }
        assertEquals(listOf(10_000L, 10_045L, 10_090L), map.packets.map { it.startMs })
        assertTrue(map.packets.all { it.kind == RouteMapPacket.Kind.SWEEP_OUT && it.durationMs == 620L })
        map.regionSent("sa-east-1", 11_000)
        assertEquals(11_000L, map.packets.last().startMs)
    }

    @Test
    fun regionSampleTracksMinimumAndLeader() {
        val map = mapWithUser()
        map.regionSample("sa-east-1", 30.0, 0)
        map.regionSample("sa-east-1", 22.0, 0)
        map.regionSample("us-east-1", 120.0, 0)
        map.regionSample("eu-west-1", null, 0)
        assertEquals(RouteMapRegionState(22.0, true, 2), map.regions["sa-east-1"])
        assertEquals(RouteMapRegionState(null, false, 1), map.regions["eu-west-1"])
        assertEquals("sa-east-1", map.leaderId)
        assertEquals(3, map.packets.count { it.kind == RouteMapPacket.Kind.SWEEP_IN })
        assertEquals(300L, map.packets.first().durationMs)
    }

    @Test
    fun selectRegionDropsSweepAndKeepsSweepLatency() {
        val map = mapWithUser()
        map.regionSent("sa-east-1", 0)
        map.regionSample("sa-east-1", 24.0, 100)
        map.selectRegion("sa-east-1", nowMs = 200)
        assertEquals("sa-east-1", map.selectedId)
        assertTrue(map.packets.isEmpty())
        assertEquals(24.0, map.selectedMs!!, 0.0)
        assertNull(map.leaderId)
        map.regionSent("us-east-1", 300)
        assertTrue(map.packets.isEmpty())
    }

    @Test
    fun probeGoesOutIn420msAndComesBackByRtt() {
        val map = mapWithUser()
        map.probe(50.0, 0)
        assertTrue(map.packets.isEmpty())
        map.selectRegion("sa-east-1", nowMs = 0)
        map.probe(50.0, 1_000)
        val packet = map.packets.single()
        assertEquals(420L, packet.durationMs)
        assertEquals(400L, packet.returnDurationMs)
        assertEquals(true, packet.flight(1_200)?.outbound)
        assertEquals(false, packet.flight(1_500)?.outbound)
        assertNull(packet.flight(1_820))
    }

    @Test
    fun probePacketsAreCappedAtSix() {
        val map = mapWithUser()
        map.selectRegion("sa-east-1", nowMs = 0)
        repeat(10) { map.probe(20.0, 1_000) }
        assertEquals(RouteMapController.MAX_PACKETS, map.packets.size)
    }

    @Test
    fun ingestAnimatesEachNewResponseOnce() {
        val map = mapWithUser()
        map.selectRegion("sa-east-1", nowMs = 0)
        map.ingestProbeResponses(listOf(20.0, 21.0), "rest", 1_000)
        map.ingestProbeResponses(listOf(20.0, 21.0), "rest", 1_100)
        assertEquals(2, map.packets.size)
        map.ingestProbeResponses(listOf(20.0, 21.0, null), "rest", 1_200)
        assertEquals(2, map.packets.size)
        map.ingestProbeResponses(listOf(40.0), "load", 5_000)
        assertEquals(1, map.packets.size)
    }

    @Test
    fun staticMapNeverAnimates() {
        val map = mapWithUser(animate = false)
        map.regionSent("sa-east-1", 0)
        map.regionSample("sa-east-1", 20.0, 0)
        map.selectRegion("sa-east-1", nowMs = 0)
        map.probe(20.0, 0)
        assertTrue(map.packets.isEmpty())
        assertEquals(map.targetCamera(340f, 255f), map.advanceCamera(340f, 255f, 0, false))
    }

    @Test
    fun cameraStartsOnOverviewAndEasesToRoute() {
        val map = mapWithUser()
        map.selectRegion("sa-east-1", nowMs = 0)
        assertEquals(map.overviewCamera(340f, 255f), map.advanceCamera(340f, 255f, 0, false))
        var cam = map.overviewCamera(340f, 255f)
        var t = 0L
        while (t < 3_000) { t += 16; cam = map.advanceCamera(340f, 255f, t, false) }
        val target = map.targetCamera(340f, 255f)
        assertEquals(target.zoom, cam.zoom, 0.01)
        assertTrue(target.zoom <= RouteMapProjection.ROUTE_MAX_ZOOM)
    }

    @Test
    fun reduceMotionJumpsCamera() {
        val map = mapWithUser()
        map.selectRegion("sa-east-1", nowMs = 0)
        assertEquals(map.targetCamera(340f, 255f), map.advanceCamera(340f, 255f, 0, true))
    }

    @Test
    fun sweepWaitsForLocationAndFansOutWhenItArrives() {
        val map = RouteMapController()
        map.clearUser(0)
        listOf("sa-east-1", "us-east-1", "sa-east-1").forEach { map.regionSent(it, 100) }
        assertTrue(map.packets.isEmpty())
        map.setUser(br, "Rio de Janeiro", nowMs = 2_000)
        assertEquals("Rio de Janeiro", map.userCity)
        assertEquals(listOf(2_000L, 2_045L), map.packets.map { it.startMs })
        assertEquals(listOf("sa-east-1", "us-east-1"), map.packets.map { it.regionId })
    }

    @Test
    fun pendingSweepIsDroppedWhenRegionIsChosenFirst() {
        val map = RouteMapController()
        map.clearUser(0)
        map.regionSent("sa-east-1", 100)
        map.selectRegion("sa-east-1", nowMs = 200)
        map.setUser(br, nowMs = 300)
        assertTrue(map.packets.isEmpty())
        assertNull(map.userCity)
    }

    @Test
    fun unavailableLocationFlag() {
        val map = RouteMapController()
        map.setUser(null, nowMs = 0)
        assertTrue(map.locationUnavailable)
        map.regionSent("sa-east-1", 0)
        assertTrue(map.packets.isEmpty())
    }

    @Test
    fun motionDeadlineCoversPacketsAndCamera() {
        val map = RouteMapController()
        map.setUser(br, nowMs = 100_000)
        assertEquals(100_000 + RouteMapController.CAMERA_SETTLE_MS, map.motionDeadlineMs)
        map.selectRegion("sa-east-1", nowMs = 200_000)
        map.probe(1_000.0, 205_000)
        assertEquals(205_000L + 420 + 700, map.motionDeadlineMs)
    }

    @Test
    fun resetReturnsToOverview() {
        val map = mapWithUser()
        map.regionSample("sa-east-1", 20.0, 0)
        map.selectRegion("sa-east-1", nowMs = 0)
        map.reset(1_000)
        assertNull(map.selectedId)
        assertTrue(map.regions.isEmpty())
        assertTrue(map.packets.isEmpty())
        assertEquals(br, map.user)
    }

    @Test
    fun fitCameraUsesWidthForBothAxesLikeTheSite() {
        val camera = RouteMapProjection.fitCamera(
            listOf(MapGeoPoint(-40.0, 0.0), MapGeoPoint(40.0, 1.0)), 400f, 200f, padX = 0.0, padY = 0.0
        )
        assertEquals((200.0 * 360.0) / (400.0 * 80.0), camera.zoom, 0.0001)
    }

    @Test
    fun originIsApproximatedOnlyForKnownCountries() {
        assertEquals(MapGeoPoint(-15.79, -47.88), RouteMapOrigin.approximatePoint("br"))
        assertNull(RouteMapOrigin.approximatePoint(null))
        assertNull(RouteMapOrigin.approximatePoint("ZZ"))
        assertNull(RouteMapOrigin.approximatePoint("BRA"))
        assertEquals(35, RouteMapOrigin.COUNTRY_POINTS.size)
    }
}
