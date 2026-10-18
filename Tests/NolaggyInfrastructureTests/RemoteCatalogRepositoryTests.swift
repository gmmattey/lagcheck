import XCTest
@testable import NolaggyInfrastructure
@testable import NolaggyDomain

final class RemoteCatalogRepositoryTests: XCTestCase {
    func testBundledCatalogIsAvailableToTheInfrastructureBundle() throws {
        let data = try XCTUnwrap(DebugCatalogBase.envelopeData())
        let payload = try BundledCatalogRepository(envelopeData: data).load()

        XCTAssertEqual(payload.schemaVersion, 3)
        XCTAssertEqual(payload.catalogVersion, "catalog-v3-2026.10.17.3")
        XCTAssertEqual(payload.games.count, 48)
        XCTAssertFalse(payload.regions.isEmpty)
    }

    func testEveryBundledGameContextKeepsAnActiveAWSGameLiftReference() throws {
        let data = try XCTUnwrap(DebugCatalogBase.envelopeData())
        let payload = try BundledCatalogRepository(envelopeData: data).load()

        for game in payload.games {
            XCTAssertFalse(game.contexts.isEmpty, "\\(game.id) must retain a measurement reference")
            for context in game.contexts {
                XCTAssertTrue(
                    context.routes?.contains(where: {
                        $0.kind == .awsFallback && $0.status == .active
                    }) == true,
                    "\\(game.id) must retain its active AWS GameLift reference"
                )
            }
        }
    }

    func testExpiredBundledCatalogFailsClosed() throws {
        let data = try XCTUnwrap(DebugCatalogBase.envelopeData())
        let afterExpiry = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-12-01T00:00:00Z"))
        XCTAssertThrowsError(
            try BundledCatalogRepository(envelopeData: data, now: { afterExpiry }).load()
        )
    }
}
