import XCTest
@testable import NolaggyDomain

final class WidgetTelemetrySnapshotTests: XCTestCase {
    func testRetainsMeasurementContextForWidgetReturn() {
        let snapshot = WidgetTelemetrySnapshot(
            gameID: "valorant",
            gameName: "VALORANT",
            regionLabel: "São Paulo",
            verdict: .ready,
            rttMedianMs: 18,
            jitterMs: 2,
            packetLossPercentage: 0,
            platform: .pc,
            declaredExternalLink: .ethernet
        )

        XCTAssertEqual(snapshot.platform, .pc)
        XCTAssertEqual(snapshot.declaredExternalLink, .ethernet)
    }

    func testDecodesSnapshotWrittenBeforeContextFieldsExisted() throws {
        let legacy = """
        {"gameID":"valorant","gameName":"VALORANT","regionLabel":"São Paulo","verdict":"ready","rttMedianMs":18,"jitterMs":2,"packetLossPercentage":0,"capturedAt":0}
        """.data(using: .utf8)!

        let snapshot = try JSONDecoder().decode(WidgetTelemetrySnapshot.self, from: legacy)
        XCTAssertNil(snapshot.platform)
        XCTAssertNil(snapshot.declaredExternalLink)
    }
}
