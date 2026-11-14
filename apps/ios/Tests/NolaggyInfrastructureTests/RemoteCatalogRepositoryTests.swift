import XCTest
@testable import NolaggyInfrastructure
@testable import NolaggyDomain

final class RemoteCatalogRepositoryTests: XCTestCase {
    func testBundledCatalogIsAvailableToTheInfrastructureBundle() throws {
        let data = try XCTUnwrap(DebugCatalogBase.envelopeData())
        let payload = try BundledCatalogRepository(envelopeData: data).load()

        XCTAssertEqual(payload.schemaVersion, 3)
        XCTAssertFalse(payload.catalogVersion.isEmpty)
        XCTAssertGreaterThanOrEqual(payload.games.count, 56)
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

    func testRemoteSyncedCatalogUpdatesFromRemoteAndRejectsDegradedPayload() async throws {
        let baseData = try XCTUnwrap(DebugCatalogBase.envelopeData())
        let bundled = BundledCatalogRepository(envelopeData: baseData)
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let cacheURL = dir.appendingPathComponent("catalog-v3.json")
        let suiteName = "RemoteSyncedCatalogTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let updatedData = try makeEnvelope(from: baseData, version: "v1-remote-test", regionCount: nil)
        let transport = MockCatalogHTTPTransport(responses: [
            (200, updatedData, "\"etag-1\""),
            (304, Data(), nil),
            (200, try makeEnvelope(from: baseData, version: "v1-shrunk", regionCount: 1), "\"etag-2\"")
        ])

        let repo = RemoteSyncedCatalogRepository(
            bundled: bundled,
            cacheURL: cacheURL,
            transport: transport,
            defaultsSuiteName: suiteName,
            refreshInterval: 0
        )

        let initial = try await repo.loadLocal()
        XCTAssertFalse(initial.catalogVersion.isEmpty)
        XCTAssertNotEqual(initial.catalogVersion, "v1-remote-test")

        let synced = await repo.syncIfNeeded(force: true)
        XCTAssertEqual(synced?.catalogVersion, "v1-remote-test")
        let afterSync = try await repo.loadLocal()
        XCTAssertEqual(afterSync.catalogVersion, "v1-remote-test")

        let notModified = await repo.syncIfNeeded(force: true)
        XCTAssertNil(notModified)

        let rejected = await repo.syncIfNeeded(force: true)
        XCTAssertNil(rejected)
        let afterReject = try await repo.loadLocal()
        XCTAssertEqual(afterReject.catalogVersion, "v1-remote-test")
    }

    private func makeEnvelope(from baseData: Data, version: String, regionCount: Int?) throws -> Data {
        let envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: baseData) as? [String: Any])
        var payload: [String: Any]
        if let b64 = envelope["payloadBase64"] as? String, let raw = Data(base64Encoded: b64) {
            payload = try XCTUnwrap(JSONSerialization.jsonObject(with: raw) as? [String: Any])
        } else {
            payload = envelope
        }
        payload["catalogVersion"] = version
        if let regionCount, let regions = payload["regions"] as? [Any] {
            payload["regions"] = Array(regions.prefix(regionCount))
        }
        return try JSONSerialization.data(withJSONObject: payload)
    }
}

private actor MockCatalogHTTPTransport: CatalogHTTPTransport {
    private var responses: [(Int, Data, String?)]
    private var index = 0

    init(responses: [(Int, Data, String?)]) {
        self.responses = responses
    }

    func fetch(url: URL, etag: String?) async throws -> (statusCode: Int, data: Data, etag: String?) {
        let current = responses[min(index, responses.count - 1)]
        index += 1
        return current
    }
}
