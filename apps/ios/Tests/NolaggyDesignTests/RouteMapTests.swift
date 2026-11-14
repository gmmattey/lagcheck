import XCTest
@testable import NolaggyDesign

/// Paridade com `RouteMap` do site (`pages/lagcheck/src/lib/map/route-map.ts`).
@MainActor
final class RouteMapControllerTests: XCTestCase {
    private let br = MapGeoPoint(lat: -15.79, lon: -47.88)

    func testNothingMovesWithoutRealEvents() {
        let map = RouteMapController()
        map.setUser(br, at: 0)
        XCTAssertTrue(map.packets.isEmpty)
        XCTAssertNil(map.selectedId)
    }

    func testSweepNeedsUserLikeTheSite() {
        let map = RouteMapController()
        map.regionSent("sa-east-1", at: 0)
        XCTAssertTrue(map.packets.isEmpty, "sem 'Você' a varredura espera, como trySweep()")
        map.setUser(br, at: 0)
        XCTAssertEqual(map.packets.count, 1, "a sonda já enviada parte quando 'Você' chega")
    }

    func testSweepBurstIsStaggered45msAndFlies620ms() {
        let map = RouteMapController()
        map.setUser(br, at: 0)
        for id in ["sa-east-1", "us-east-1", "eu-west-1"] { map.regionSent(id, at: 10) }
        XCTAssertEqual(map.packets.map(\.kind), [.sweepOut, .sweepOut, .sweepOut])
        XCTAssertEqual(map.packets.map(\.start), [10, 10.045, 10.09])
        XCTAssertTrue(map.packets.allSatisfy { $0.duration == 0.620 })
        // Leva seguinte (um segundo depois) recomeça o escalonamento.
        map.regionSent("sa-east-1", at: 11)
        XCTAssertEqual(map.packets.last?.start, 11)
    }

    func testRegionSampleTracksMinimumAndLeader() {
        let map = RouteMapController()
        map.setUser(br, at: 0)
        map.regionSample("sa-east-1", ms: 30, at: 0)
        map.regionSample("sa-east-1", ms: 22, at: 0)
        map.regionSample("us-east-1", ms: 120, at: 0)
        map.regionSample("eu-west-1", ms: nil, at: 0)
        XCTAssertEqual(map.regions["sa-east-1"], RouteMapRegionState(ms: 22, answered: true, count: 2))
        XCTAssertEqual(map.regions["eu-west-1"], RouteMapRegionState(ms: nil, answered: false, count: 1))
        XCTAssertEqual(map.leaderId, "sa-east-1")
        // Uma volta por resposta real; a falta de resposta não anima nada.
        XCTAssertEqual(map.packets.filter { $0.kind == .sweepIn }.count, 3)
        XCTAssertEqual(map.packets.first?.duration ?? 0, 0.3, accuracy: 0.0001)
    }

    func testSelectRegionDropsSweepAndKeepsSweepLatency() {
        let map = RouteMapController()
        map.setUser(br, at: 0)
        map.regionSent("sa-east-1", at: 0)
        map.regionSample("sa-east-1", ms: 24, at: 0.1)
        map.selectRegion("sa-east-1", at: 0.2)
        XCTAssertEqual(map.selectedId, "sa-east-1")
        XCTAssertTrue(map.packets.isEmpty)
        XCTAssertEqual(map.selectedMs, 24)
        XCTAssertNil(map.leaderId)
        // Depois da escolha, a varredura não volta.
        map.regionSent("us-east-1", at: 0.3)
        XCTAssertTrue(map.packets.isEmpty)
    }

    func testProbeGoesOutIn420msAndComesBackByRTT() {
        let map = RouteMapController()
        map.setUser(br, at: 0)
        map.probe(rttMs: 50, at: 0)
        XCTAssertTrue(map.packets.isEmpty, "sem região escolhida não há sonda")
        map.selectRegion("sa-east-1", at: 0)
        map.probe(rttMs: 50, at: 1)
        let packet = try! XCTUnwrap(map.packets.first)
        XCTAssertEqual(packet.duration, 0.420)
        XCTAssertEqual(packet.returnDuration, 0.4, accuracy: 0.0001)
        XCTAssertEqual(packet.flight(at: 1.2)?.outbound, true)
        XCTAssertEqual(packet.flight(at: 1.5)?.outbound, false)
        XCTAssertNil(packet.flight(at: 1.83))
    }

    func testProbePacketsAreCappedAtSix() {
        let map = RouteMapController()
        map.setUser(br, at: 0)
        map.selectRegion("sa-east-1", at: 0)
        for _ in 0..<10 { map.probe(rttMs: 20, at: 1) }
        XCTAssertEqual(map.packets.count, RouteMapController.maxPackets)
    }

    func testIngestAnimatesEachNewResponseOnce() {
        let map = RouteMapController()
        map.setUser(br, at: 0)
        map.selectRegion("sa-east-1", at: 0)
        map.ingestProbeResponses([20, 21], phase: "rest", at: 1)
        map.ingestProbeResponses([20, 21], phase: "rest", at: 1.1)
        XCTAssertEqual(map.packets.count, 2)
        map.ingestProbeResponses([20, 21, nil], phase: "rest", at: 1.2)
        XCTAssertEqual(map.packets.count, 2, "resposta sem RTT não vira sonda")
        map.ingestProbeResponses([40], phase: "load", at: 5)
        XCTAssertEqual(map.packets.count, 1, "nova fase: só a resposta nova, as antigas já terminaram")
    }

    func testStaticMapNeverAnimates() {
        let map = RouteMapController(animate: false)
        map.setUser(br, at: 0)
        map.regionSent("sa-east-1", at: 0)
        map.regionSample("sa-east-1", ms: 20, at: 0)
        map.selectRegion("sa-east-1", at: 0)
        map.probe(rttMs: 20, at: 0)
        XCTAssertTrue(map.packets.isEmpty)
        let cam = map.advanceCamera(width: 340, height: 255, now: 0, reduceMotion: false)
        XCTAssertEqual(cam, map.targetCamera(width: 340, height: 255))
    }

    func testCameraStartsOnOverviewAndEasesToRoute() {
        let map = RouteMapController()
        map.setUser(br, at: 0)
        map.selectRegion("sa-east-1", at: 0)
        let first = map.advanceCamera(width: 340, height: 255, now: 0, reduceMotion: false)
        XCTAssertEqual(first, map.overviewCamera(width: 340, height: 255))
        let target = map.targetCamera(width: 340, height: 255)
        var cam = first
        var t = 0.0
        while t < 3 { t += 0.016; cam = map.advanceCamera(width: 340, height: 255, now: t, reduceMotion: false) }
        XCTAssertEqual(cam.zoom, target.zoom, accuracy: 0.01)
        XCTAssertLessThanOrEqual(target.zoom, RouteMapProjection.routeMaxZoom)
    }

    func testReduceMotionJumpsCamera() {
        let map = RouteMapController()
        map.setUser(br, at: 0)
        map.selectRegion("sa-east-1", at: 0)
        let cam = map.advanceCamera(width: 340, height: 255, now: 0, reduceMotion: true)
        XCTAssertEqual(cam, map.targetCamera(width: 340, height: 255))
    }

    func testSweepWaitsForLocationAndFansOutWhenItArrives() {
        let map = RouteMapController()
        map.clearUser(at: 0)
        for id in ["sa-east-1", "us-east-1", "sa-east-1"] { map.regionSent(id, at: 0.1) }
        XCTAssertTrue(map.packets.isEmpty)
        map.setUser(br, city: "Rio de Janeiro", at: 2)
        XCTAssertEqual(map.userCity, "Rio de Janeiro")
        XCTAssertEqual(map.packets.map(\.start), [2, 2.045])
        XCTAssertEqual(map.packets.map(\.regionId), ["sa-east-1", "us-east-1"])
    }

    func testPendingSweepIsDroppedWhenRegionIsChosenFirst() {
        let map = RouteMapController()
        map.clearUser(at: 0)
        map.regionSent("sa-east-1", at: 0.1)
        map.selectRegion("sa-east-1", at: 0.2)
        map.setUser(br, at: 0.3)
        XCTAssertTrue(map.packets.isEmpty)
        XCTAssertNil(map.userCity)
    }

    func testUnavailableLocationFlag() {
        let map = RouteMapController()
        map.setUser(nil, at: 0)
        XCTAssertTrue(map.locationUnavailable)
        map.regionSent("sa-east-1", at: 0)
        XCTAssertTrue(map.packets.isEmpty)
    }

    func testMotionDeadlineCoversPacketsAndCamera() {
        let map = RouteMapController()
        map.setUser(br, at: 100)
        XCTAssertEqual(map.motionDeadline, 100 + RouteMapController.cameraSettleSeconds, accuracy: 0.0001)
        map.selectRegion("sa-east-1", at: 200)
        map.probe(rttMs: 1000, at: 205)
        XCTAssertEqual(map.motionDeadline, 205 + 0.42 + 0.7, accuracy: 0.0001)
    }

    func testResetReturnsToOverview() {
        let map = RouteMapController()
        map.setUser(br, at: 0)
        map.regionSample("sa-east-1", ms: 20, at: 0)
        map.selectRegion("sa-east-1", at: 0)
        map.reset(at: 1)
        XCTAssertNil(map.selectedId)
        XCTAssertTrue(map.regions.isEmpty)
        XCTAssertTrue(map.packets.isEmpty)
        XCTAssertEqual(map.user, br)
    }
}

final class RouteMapOriginTests: XCTestCase {
    func testKnownCountryHasApproximatePoint() {
        XCTAssertEqual(RouteMapOrigin.approximatePoint(countryCode: "BR"), MapGeoPoint(lat: -15.79, lon: -47.88))
        XCTAssertEqual(RouteMapOrigin.approximatePoint(countryCode: "us"), RouteMapOrigin.countryPoints["US"])
    }

    func testUnknownOrMissingCountryHasNoOrigin() {
        XCTAssertNil(RouteMapOrigin.approximatePoint(countryCode: nil))
        XCTAssertNil(RouteMapOrigin.approximatePoint(countryCode: "ZZ"))
        XCTAssertNil(RouteMapOrigin.approximatePoint(countryCode: "BRA"))
    }

    func testOriginTableMatchesAndroid() {
        XCTAssertEqual(RouteMapOrigin.countryPoints.count, 35)
    }
}

final class RouteMapProjectionTests: XCTestCase {
    func testWorldCameraProjectsCenter() {
        let p = RouteMapProjection.project(lat: 12, lon: 0, camera: .world, width: 360, height: 180)
        XCTAssertEqual(p.x, 180, accuracy: 0.001)
        XCTAssertEqual(p.y, 90, accuracy: 0.001)
    }

    func testFitCameraUsesWidthForBothAxesLikeTheSite() {
        // Site: zoomByLat = availY * 360 / (width * latSpan).
        let camera = RouteMapProjection.fitCamera(
            points: [MapGeoPoint(lat: -40, lon: 0), MapGeoPoint(lat: 40, lon: 1)],
            width: 400, height: 200, padX: 0, padY: 0
        )
        XCTAssertEqual(camera.zoom, (200.0 * 360.0) / (400.0 * 80.0), accuracy: 0.0001)
    }

    func testReturnFlightClamp() {
        XCTAssertEqual(RouteMapProjection.returnFlightSeconds(rttMs: 1), 0.3, accuracy: 0.0001)
        XCTAssertEqual(RouteMapProjection.returnFlightSeconds(rttMs: 50), 0.4, accuracy: 0.0001)
        XCTAssertEqual(RouteMapProjection.returnFlightSeconds(rttMs: 1000), 0.7, accuracy: 0.0001)
    }

    func testEveryCatalogRegionHasCoordinates() {
        let catalogRegions = [
            "af-south-1", "ap-east-1", "ap-northeast-1", "ap-northeast-2", "ap-northeast-3", "ap-south-1",
            "ap-southeast-1", "ap-southeast-2", "ca-central-1", "eu-central-1", "eu-north-1", "eu-south-1",
            "eu-west-1", "eu-west-2", "eu-west-3", "me-south-1", "sa-east-1", "us-east-1", "us-east-2",
            "us-west-1", "us-west-2"
        ]
        XCTAssertEqual(RouteMapProjection.regionCoordinates.count, catalogRegions.count)
        for id in catalogRegions {
            XCTAssertNotNil(RouteMapProjection.regionPoint(id: id), id)
        }
    }
}

