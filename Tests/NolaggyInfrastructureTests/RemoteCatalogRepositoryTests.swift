import XCTest
@testable import NolaggyInfrastructure
@testable import NolaggyDomain

final class RemoteCatalogRepositoryTests: XCTestCase {
    func testBundledCatalogIsAvailableToTheInfrastructureBundle() throws {
        let data = try XCTUnwrap(DebugCatalogBase.envelopeData())
        let payload = try BundledCatalogRepository(envelopeData: data).load()

        XCTAssertEqual(payload.schemaVersion, 3)
        XCTAssertEqual(payload.catalogVersion, "catalog-v3-2026.10.18.1")
        XCTAssertEqual(payload.games.count, 54)
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

    /// Decisão 106: o catálogo acompanha o build e não expira. Uma data futura
    /// nunca pode deixar o app sem jogos.
    func testBundledCatalogHasNoSignatureOrExpiry() throws {
        let data = try XCTUnwrap(DebugCatalogBase.envelopeData())
        XCTAssertNoThrow(try BundledCatalogRepository(envelopeData: data).load())
        let text = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertFalse(text.contains("signatureBase64"), "o catálogo embutido não carrega assinatura")
        XCTAssertFalse(text.contains("expiresAt"), "o catálogo embutido não carrega validade")
    }

    func testBundledCatalogRejectsMalformedAndOversizedData() {
        XCTAssertThrowsError(try BundledCatalogRepository(envelopeData: Data("{}".utf8)).load())
        XCTAssertThrowsError(try BundledCatalogRepository(envelopeData: Data(count: 200 * 1024)).load())
    }
}
