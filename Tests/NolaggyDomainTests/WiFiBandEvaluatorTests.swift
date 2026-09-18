import XCTest
@testable import NolaggyDomain

final class WiFiBandEvaluatorTests: XCTestCase {

    func testNonWiFiInterfaceIsImmediatelyInconclusive() {
        let telemetry = WiFiLocalTelemetry(
            gatewayRTTMedianMs: 1.2,
            gatewayJitterMs: 0.5,
            isWiFi: false
        )
        let result = WiFiBandEvaluator.evaluate(telemetry: telemetry)

        XCTAssertEqual(result.diagnostic, .inconclusive(reason: .nonWiFiInterface))
        XCTAssertEqual(result.confidence, .none)
    }

    func testExplicit5GHzSSIDReturnsConfirmed5GHzWithHighConfidence() {
        let testSSIDs = ["MinhaCasa_5G", "Apartamento-5GHz", "Roteador 5_GHz", "Office_WiFi6", "Studio_6E", "Gaming_WiFi7"]
        for ssid in testSSIDs {
            let telemetry = WiFiLocalTelemetry(
                detectedSSID: ssid,
                isWiFi: true
            )
            let result = WiFiBandEvaluator.evaluate(telemetry: telemetry)
            XCTAssertEqual(result.diagnostic, .confirmed5GHzOrHigher(ssid: ssid), "Falha para SSID: \(ssid)")
            XCTAssertEqual(result.confidence, .high)
            XCTAssertFalse(result.diagnostic.isSuspectOrConfirmed24GHz)
        }
    }

    func testExplicit24GHzSSIDReturnsConfirmed24GHzWithHighConfidence() {
        let testSSIDs = ["MinhaCasa_2.4G", "Apartamento-2.4GHz", "Roteador_2G", "Home_2_4GHz"]
        for ssid in testSSIDs {
            let telemetry = WiFiLocalTelemetry(
                detectedSSID: ssid,
                isWiFi: true
            )
            let result = WiFiBandEvaluator.evaluate(telemetry: telemetry)
            XCTAssertEqual(result.diagnostic, .confirmed24GHz(ssid: ssid), "Falha para SSID: \(ssid)")
            XCTAssertEqual(result.confidence, .high)
            XCTAssertTrue(result.diagnostic.isSuspectOrConfirmed24GHz)
            XEqual(result.actionKey, "network.band.action.settings")
        }
    }

    func testUnresponsiveGatewayProducesInconclusiveWithoutInventingState() {
        // Conforme auditoria do Claude Code: se o roteador não responder aos probes UDP,
        // o LagCheck NUNCA inventa uma suposição de rádio.
        let telemetry = WiFiLocalTelemetry(
            validSampleCount: 0,
            plannedSampleCount: 10,
            detectedSSID: nil,
            isWiFi: true
        )
        let result = WiFiBandEvaluator.evaluate(telemetry: telemetry)

        XCTAssertEqual(result.diagnostic, .inconclusive(reason: .gatewayUnresponsive))
        XCTAssertEqual(result.confidence, .none)
    }

    func testInsufficientSamplesProducesInconclusive() {
        let telemetry = WiFiLocalTelemetry(
            gatewayRTTMedianMs: 5.0,
            gatewayJitterMs: 2.0,
            validSampleCount: 2,
            plannedSampleCount: 10,
            isWiFi: true
        )
        let result = WiFiBandEvaluator.evaluate(telemetry: telemetry)

        XCTAssertEqual(result.diagnostic, .inconclusive(reason: .insufficientSamples))
        XCTAssertEqual(result.confidence, .none)
    }

    func testHighLocalJitterTriggersSuspected24GHzContention() {
        let telemetry = WiFiLocalTelemetry(
            gatewayRTTMedianMs: 12.0,
            gatewayJitterMs: 18.5, // > 15ms threshold
            tailRatioP95P50: 1.2,
            validSampleCount: 10,
            plannedSampleCount: 10,
            isWiFi: true
        )
        let result = WiFiBandEvaluator.evaluate(telemetry: telemetry)

        XCTAssertEqual(result.diagnostic, .suspected24GHzContention)
        XCTAssertEqual(result.confidence, .medium)
        XCTAssertTrue(result.diagnostic.isSuspectOrConfirmed24GHz)
        XCTAssertEqual(result.actionKey, "network.band.action.deep_check")
    }

    func testAsymmetricTailRatioTriggersSuspected24GHzContention() {
        let telemetry = WiFiLocalTelemetry(
            gatewayRTTMedianMs: 8.0,
            gatewayJitterMs: 6.0,
            tailRatioP95P50: 1.6, // >= 1.45 threshold
            validSampleCount: 10,
            plannedSampleCount: 10,
            isWiFi: true
        )
        let result = WiFiBandEvaluator.evaluate(telemetry: telemetry)

        XCTAssertEqual(result.diagnostic, .suspected24GHzContention)
        XCTAssertEqual(result.confidence, .medium)
    }

    func testSevereLoadDeltaInDeepCheckTriggersSuspected24GHzContention() {
        let telemetry = WiFiLocalTelemetry(
            loadDeltaP50Ms: 42.0, // >= 35ms threshold (airtime starvation)
            validSampleCount: 0,
            plannedSampleCount: 0,
            isWiFi: true
        )
        let result = WiFiBandEvaluator.evaluate(telemetry: telemetry)

        XCTAssertEqual(result.diagnostic, .suspected24GHzContention)
        XCTAssertEqual(result.confidence, .medium)
    }

    func testFastCleanLocalHopIsClassifiedAsStableWiFi() {
        let telemetry = WiFiLocalTelemetry(
            gatewayRTTMedianMs: 1.8,
            gatewayJitterMs: 0.9,
            tailRatioP95P50: 1.1,
            validSampleCount: 10,
            plannedSampleCount: 10,
            isWiFi: true
        )
        let result = WiFiBandEvaluator.evaluate(telemetry: telemetry)

        XCTAssertEqual(result.diagnostic, .stableWiFi)
        XCTAssertEqual(result.confidence, .high)
        XCTAssertFalse(result.diagnostic.isSuspectOrConfirmed24GHz)
    }
}

private func XEqual<T: Equatable>(_ a: T?, _ b: T?, file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(a, b, file: file, line: line)
}
