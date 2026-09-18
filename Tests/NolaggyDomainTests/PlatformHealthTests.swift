import XCTest
@testable import NolaggyDomain

final class PlatformHealthTests: XCTestCase {
    func testPlatformHealthStatusOperationalProperties() {
        let health = PlatformHealth.operational(for: .playstation, serviceName: "PlayStation Network")
        XCTAssertEqual(health.platform, .playstation)
        XCTAssertEqual(health.serviceName, "PlayStation Network")
        XCTAssertEqual(health.status, .operational)
        XCTAssertFalse(health.isIssueReported)
        XCTAssertTrue(health.affectedServices.isEmpty)
        XCTAssertNil(health.details)
    }

    func testPlatformHealthStatusDegradedAndOutage() {
        let degraded = PlatformHealth(
            platform: .xbox,
            status: .degraded(summary: "Instabilidade no matchmaking"),
            serviceName: "Xbox Network",
            affectedServices: ["Jogos multijogador"],
            details: "Alguns jogadores podem notar demora para encontrar partidas."
        )
        XCTAssertTrue(degraded.isIssueReported)
        if case .degraded(let summary) = degraded.status {
            XCTAssertEqual(summary, "Instabilidade no matchmaking")
        } else {
            XCTFail("Esperava status degraded")
        }

        let outage = PlatformHealth(
            platform: .playstation,
            status: .majorOutage(summary: "Falha geral de autenticação"),
            serviceName: "PlayStation Network",
            affectedServices: ["Account Management", "Gaming And Social"],
            details: "Serviço indisponível."
        )
        XCTAssertTrue(outage.isIssueReported)
        if case .majorOutage(let summary) = outage.status {
            XCTAssertEqual(summary, "Falha geral de autenticação")
        } else {
            XCTFail("Esperava status majorOutage")
        }
    }

    func testPlatformHealthCodableRoundTrip() throws {
        let original = PlatformHealth(
            platform: .playstation,
            status: .degraded(summary: "Lentidão na PS Store"),
            serviceName: "PlayStation Network",
            affectedServices: ["PlayStation Store"],
            details: "Compras temporariamente indisponíveis."
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PlatformHealth.self, from: data)

        XCTAssertEqual(original.platform, decoded.platform)
        XCTAssertEqual(original.status, decoded.status)
        XCTAssertEqual(original.serviceName, decoded.serviceName)
        XCTAssertEqual(original.affectedServices, decoded.affectedServices)
        XCTAssertEqual(original.details, decoded.details)
    }
}
