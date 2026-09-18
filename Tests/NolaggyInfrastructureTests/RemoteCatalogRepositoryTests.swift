import XCTest
@testable import NolaggyInfrastructure
@testable import NolaggyDomain

final class RemoteCatalogRepositoryTests: XCTestCase {
    func testBundledDebugCatalogIsAvailableToTheInfrastructureBundle() throws {
        let data = try XCTUnwrap(DebugCatalogBase.envelopeData())
        let payload = try RemoteCatalogVerifier.verifyAndDecode(envelopeData: data, now: Date())
        XCTAssertEqual(payload.catalogVersion, "debug-2026.09.18.1")
    }

    func testLaunchFallsBackToBaseWhenCacheIsInvalid() async throws {
        let cache = MemoryCache(value: StoredRemoteCatalog(envelopeData: Data([9]), refreshedAt: Date()))
        let repository = RemoteCatalogRepository(
            baseEnvelopeData: Data([1]), fetcher: FixedFetcher(data: nil), cache: cache,
            validator: FixtureValidator(), now: { Date(timeIntervalSince1970: 1_000) }
        )

        let loaded = try await repository.loadedCatalogForLaunch()
        XCTAssertEqual(loaded.payload.catalogVersion, "base")
        XCTAssertEqual(loaded.source, .bundledBase)
    }

    func testLaunchUsesValidatedCachedRemoteCatalog() async throws {
        let cache = MemoryCache(value: StoredRemoteCatalog(envelopeData: Data([2]), refreshedAt: Date()))
        let repository = RemoteCatalogRepository(
            baseEnvelopeData: Data([1]), fetcher: FixedFetcher(data: nil), cache: cache,
            validator: FixtureValidator(), now: { Date(timeIntervalSince1970: 1_000) }
        )

        let loaded = try await repository.loadedCatalogForLaunch()
        XCTAssertEqual(loaded.payload.catalogVersion, "remote")
        XCTAssertEqual(loaded.source, .cachedRemote)
    }

    func testRefreshStoresOnlyValidatedResponseAndRespectsDailyWindow() async throws {
        let cache = MemoryCache()
        let repository = RemoteCatalogRepository(
            baseEnvelopeData: Data([1]), fetcher: FixedFetcher(data: Data([2])), cache: cache,
            validator: FixtureValidator(), now: { Date(timeIntervalSince1970: 1_000) }
        )
        await repository.refreshIfDue()
        let cachedEnvelope = await cache.value?.envelopeData
        XCTAssertEqual(cachedEnvelope, Data([2]))

        let fetcher = CountingFetcher(data: Data([2]))
        let withinWindow = RemoteCatalogRepository(
            baseEnvelopeData: Data([1]), fetcher: fetcher, cache: cache,
            validator: FixtureValidator(), now: { Date(timeIntervalSince1970: 1_100) }
        )
        await withinWindow.refreshIfDue()
        let calls = await fetcher.calls
        XCTAssertEqual(calls, 0)
    }
}

private struct FixtureValidator: RemoteCatalogValidating {
    func validate(_ envelopeData: Data, now: Date) throws -> RemoteCatalogPayload {
        guard envelopeData == Data([1]) || envelopeData == Data([2]) else { throw RemoteCatalogError.invalidSignature }
        return RemoteCatalogPayload(schemaVersion: 1, catalogVersion: envelopeData == Data([1]) ? "base" : "remote", profiles: [], regions: [], games: [])
    }
}

private actor MemoryCache: RemoteCatalogCaching {
    var value: StoredRemoteCatalog?
    init(value: StoredRemoteCatalog? = nil) { self.value = value }
    func load() -> StoredRemoteCatalog? { value }
    func save(_ catalog: StoredRemoteCatalog) { value = catalog }
}

private struct FixedFetcher: RemoteCatalogFetching {
    let data: Data?
    func fetchCatalog() async throws -> Data { guard let data else { throw URLError(.notConnectedToInternet) }; return data }
}

private actor CountingFetcher: RemoteCatalogFetching {
    let data: Data
    var calls = 0
    init(data: Data) { self.data = data }
    func fetchCatalog() async throws -> Data { calls += 1; return data }
}
