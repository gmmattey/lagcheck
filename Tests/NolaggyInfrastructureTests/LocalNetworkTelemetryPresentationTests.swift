import XCTest
@testable import NolaggyInfrastructure
@testable import NolaggyDomain

final class LocalNetworkTelemetryPresentationTests: XCTestCase {
    func testWiFiPresentationDoesNotInferFrequencyAndKeepsGateway() {
        let snapshot = LocalNetworkTelemetrySnapshot(
            localIP: "192.168.1.20",
            gatewayIP: "192.168.1.1",
            telemetry: WiFiLocalTelemetry(
                gatewayRTTMedianMs: 2.3,
                gatewayJitterMs: 0.8,
                validSampleCount: 3,
                plannedSampleCount: 3,
                detectedSSID: "Casa_5G",
                isWiFi: true
            )
        )

        let presentation = LocalNetworkTelemetryPresentation(snapshot: snapshot)

        XCTAssertEqual(presentation.connectionKind, "Wi-Fi")
        XCTAssertEqual(presentation.wifiBand, "Não confirmada")
        XCTAssertEqual(presentation.gateway, "192.168.1.1")
        XCTAssertEqual(presentation.gatewayRTT, "2 ms")
        XCTAssertTrue(presentation.shortcutSummary.contains("Gateway: 192.168.1.1"))
    }
}
