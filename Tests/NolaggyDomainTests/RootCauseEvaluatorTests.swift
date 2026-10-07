import XCTest
@testable import NolaggyDomain

final class RootCauseEvaluatorTests: XCTestCase {

    func testLocalWiFiCulpritWhenGatewayRTTIsElevated() {
        let metrics = QualityMetrics(
            validResponseCount: 30,
            timeoutCount: 0,
            invalidResponseCount: 0,
            p50Milliseconds: 18.0,
            p95Milliseconds: 25.0,
            p99Milliseconds: 30.0,
            jitterMilliseconds: 2.0,
            packetLossPercentage: 0.0,
            spikeCount: 0,
            severeSpikeCount: 0,
            spikeRatePercentage: 0.0,
            p95ToP50Ratio: 1.3,
            worstSpikeMilliseconds: 30.0,
            components: nil
        )

        let report = RootCauseEvaluator.evaluate(
            gatewayOutcome: .degraded(rttMilliseconds: 28.0, lossPercentage: 0.0),
            wanMetrics: metrics,
            platformDegraded: false
        )

        XCTAssertEqual(report.primaryCulprit, CulpritEntity.localWiFi)
        XCTAssertTrue(report.localGatewayObservable)
        XCTAssertEqual(report.localGatewayRTTMs, 28.0)
    }

    func testInternetProviderCulpritWhenGatewayIsCleanButWanHasHighJitter() {
        let metrics = QualityMetrics(
            validResponseCount: 30,
            timeoutCount: 0,
            invalidResponseCount: 0,
            p50Milliseconds: 35.0,
            p95Milliseconds: 75.0,
            p99Milliseconds: 120.0,
            jitterMilliseconds: 22.0, // Jitter alto na WAN
            packetLossPercentage: 0.0,
            spikeCount: 1,
            severeSpikeCount: 0,
            spikeRatePercentage: 3.3,
            p95ToP50Ratio: 2.1,
            worstSpikeMilliseconds: 120.0,
            components: nil
        )

        let report = RootCauseEvaluator.evaluate(
            gatewayOutcome: .stable(rttMilliseconds: 2.5),
            wanMetrics: metrics,
            platformDegraded: false
        )

        XCTAssertEqual(report.primaryCulprit, CulpritEntity.internetProvider)
        XCTAssertEqual(report.localGatewayRTTMs, 2.5)
        XCTAssertEqual(report.wanJitterMs, 22.0)
    }

    func testPlatformCulpritWhenNetworkIsCleanButPlatformReportsIssue() {
        let metrics = QualityMetrics(
            validResponseCount: 30,
            timeoutCount: 0,
            invalidResponseCount: 0,
            p50Milliseconds: 14.0,
            p95Milliseconds: 18.0,
            p99Milliseconds: 20.0,
            jitterMilliseconds: 1.5,
            packetLossPercentage: 0.0,
            spikeCount: 0,
            severeSpikeCount: 0,
            spikeRatePercentage: 0.0,
            p95ToP50Ratio: 1.2,
            worstSpikeMilliseconds: 20.0,
            components: nil
        )

        let report = RootCauseEvaluator.evaluate(
            gatewayOutcome: .stable(rttMilliseconds: 1.8),
            wanMetrics: metrics,
            platformDegraded: true,
            platformServiceName: "PlayStation Network"
        )

        XCTAssertEqual(report.primaryCulprit, CulpritEntity.gamePlatform)
        XCTAssertEqual(report.platformServiceName, "PlayStation Network")
    }

    func testAllClearWhenEverythingIsOptimal() {
        let metrics = QualityMetrics(
            validResponseCount: 30,
            timeoutCount: 0,
            invalidResponseCount: 0,
            p50Milliseconds: 12.0,
            p95Milliseconds: 15.0,
            p99Milliseconds: 16.0,
            jitterMilliseconds: 1.0,
            packetLossPercentage: 0.0,
            spikeCount: 0,
            severeSpikeCount: 0,
            spikeRatePercentage: 0.0,
            p95ToP50Ratio: 1.2,
            worstSpikeMilliseconds: 16.0,
            components: nil
        )

        let report = RootCauseEvaluator.evaluate(
            gatewayOutcome: .stable(rttMilliseconds: 1.5),
            wanMetrics: metrics,
            platformDegraded: false
        )

        XCTAssertEqual(report.primaryCulprit, CulpritEntity.allClear)
    }

    func testNeverBlamesWiFiWhenGatewayIsUnobservable() {
        // Decisão 50: Proibido acusar Wi-Fi se gateway não responder (firewall fechado)
        let metrics = QualityMetrics(
            validResponseCount: 30,
            timeoutCount: 0,
            invalidResponseCount: 0,
            p50Milliseconds: 45.0,
            p95Milliseconds: 90.0,
            p99Milliseconds: 150.0,
            jitterMilliseconds: 25.0,
            packetLossPercentage: 2.0,
            spikeCount: 2,
            severeSpikeCount: 1,
            spikeRatePercentage: 6.6,
            p95ToP50Ratio: 2.0,
            worstSpikeMilliseconds: 150.0,
            components: nil
        )

        let report = RootCauseEvaluator.evaluate(
            gatewayOutcome: .unobservable,
            wanMetrics: metrics,
            platformDegraded: false
        )

        // Deve culpar a operadora/rota WAN, NUNCA o Wi-Fi
        XCTAssertEqual(report.primaryCulprit, CulpritEntity.internetProvider)
        XCTAssertFalse(report.localGatewayObservable)
        XCTAssertNil(report.localGatewayRTTMs)
    }

    func testUnobservableWhenGatewayUnobservableAndWanIsClean() {
        let metrics = QualityMetrics(
            validResponseCount: 30,
            timeoutCount: 0,
            invalidResponseCount: 0,
            p50Milliseconds: 15.0,
            p95Milliseconds: 18.0,
            p99Milliseconds: 20.0,
            jitterMilliseconds: 2.0,
            packetLossPercentage: 0.0,
            spikeCount: 0,
            severeSpikeCount: 0,
            spikeRatePercentage: 0.0,
            p95ToP50Ratio: 1.2,
            worstSpikeMilliseconds: 20.0,
            components: nil
        )

        let report = RootCauseEvaluator.evaluate(
            gatewayOutcome: .unobservable,
            wanMetrics: metrics,
            platformDegraded: false
        )

        // Gateway não respondeu, mas WAN está limpa -> Sem evidência local, unobservable
        XCTAssertEqual(report.primaryCulprit, CulpritEntity.unobservable)
        XCTAssertFalse(report.localGatewayObservable)
    }

    func testUnobservableWhenGatewayInIntermediateRangeAndWanUnstable() {
        // Gateway entre 5ms e 15ms com perda 0%, mas WAN instável
        // Integridade diagnóstica (Decisão 50/75): Sem evidência clara se o atraso inicial é no Wi-Fi ou na rota externa -> unobservable
        let metrics = QualityMetrics(
            validResponseCount: 30,
            timeoutCount: 0,
            invalidResponseCount: 0,
            p50Milliseconds: 40.0,
            p95Milliseconds: 65.0,
            p99Milliseconds: 80.0,
            jitterMilliseconds: 18.0,
            packetLossPercentage: 3.0,
            spikeCount: 1,
            severeSpikeCount: 0,
            spikeRatePercentage: 3.3,
            p95ToP50Ratio: 1.6,
            worstSpikeMilliseconds: 80.0,
            components: nil
        )

        let report = RootCauseEvaluator.evaluate(
            gatewayOutcome: .stable(rttMilliseconds: 10.0), // Intermediário (5 < rtt <= 15)
            wanMetrics: metrics,
            platformDegraded: false
        )

        XCTAssertEqual(report.primaryCulprit, CulpritEntity.unobservable)
        XCTAssertTrue(report.localGatewayObservable)
        XCTAssertEqual(report.localGatewayRTTMs, 10.0)
    }


    func testWidgetTelemetrySnapshotFreshness() {
        let now = Date()
        let freshSnapshot = WidgetTelemetrySnapshot(
            gameID: "valorant",
            gameName: "Valorant",
            regionLabel: "São Paulo",
            verdict: .ready,
            rttMedianMs: 14.0,
            jitterMs: 1.2,
            packetLossPercentage: 0.0,
            capturedAt: now.addingTimeInterval(-3600) // 1 hora atrás
        )
        XCTAssertTrue(freshSnapshot.isFresh(referenceDate: now))

        let staleSnapshot = WidgetTelemetrySnapshot(
            gameID: "valorant",
            gameName: "Valorant",
            regionLabel: "São Paulo",
            verdict: .ready,
            rttMedianMs: 14.0,
            jitterMs: 1.2,
            packetLossPercentage: 0.0,
            capturedAt: now.addingTimeInterval(-18000) // 5 horas atrás
        )
        XCTAssertFalse(staleSnapshot.isFresh(referenceDate: now))
    }
}
