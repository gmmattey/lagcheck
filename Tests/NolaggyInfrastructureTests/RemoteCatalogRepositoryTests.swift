import XCTest
@testable import NolaggyInfrastructure
@testable import NolaggyDomain

final class RemoteCatalogRepositoryTests: XCTestCase {
    func testValidRemoteCacheSurvivesInvalidBundledBase() async throws {
        let cache = MemoryCache(value: StoredRemoteCatalog(envelopeData: Data([3]), refreshedAt: Date(timeIntervalSince1970: 990)))
        let fetcher = CountingFetcher(data: Data([3]))
        let repository = RemoteCatalogRepository(baseEnvelopeData: Data([9]), fetcher: fetcher, cache: cache,
            validator: FixtureValidator(), now: { Date(timeIntervalSince1970: 1_000) })
        let loaded = try await repository.loadedCatalogForLaunch()
        XCTAssertEqual(loaded.source, .cachedRemote)
        await repository.refreshIfDue()
        let calls = await fetcher.calls
        XCTAssertEqual(calls, 0)
    }
    func testBundledDebugCatalogIsAvailableToTheInfrastructureBundle() throws {
        let data = try XCTUnwrap(DebugCatalogBase.envelopeData())
        let payload = try RemoteCatalogVerifier.verifyAndDecode(envelopeData: data, now: Date())
        XCTAssertEqual(payload.schemaVersion, 3)
        XCTAssertEqual(payload.catalogVersion, "catalog-v3-2026.10.17.3")
    }

    func testRenewedBundledCatalogStartsWithoutCacheAfterPreviousExpiry() throws {
        let data = try XCTUnwrap(DebugCatalogBase.envelopeData())
        let afterPreviousExpiry = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-20T00:00:00Z"))
        let payload = try RemoteCatalogVerifier.verifyAndDecode(envelopeData: data, now: afterPreviousExpiry)
        XCTAssertEqual(payload.catalogVersion, "catalog-v3-2026.10.17.3")
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

    func testLaunchRejectsLegacyCachedCatalogWhenBundledBaseUsesNewerSchema() async throws {
        let cache = MemoryCache(value: StoredRemoteCatalog(envelopeData: Data([2]), refreshedAt: Date()))
        let repository = RemoteCatalogRepository(
            baseEnvelopeData: Data([3]), fetcher: FixedFetcher(data: nil), cache: cache,
            validator: FixtureValidator(), now: { Date(timeIntervalSince1970: 1_000) }
        )

        let loaded = try await repository.loadedCatalogForLaunch()
        XCTAssertEqual(loaded.payload.catalogVersion, "base-v3")
        XCTAssertEqual(loaded.source, .bundledBase)
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

    func testRefreshDoesNotDelayMigrationFromLegacyCachedSchema() async throws {
        let cache = MemoryCache(value: StoredRemoteCatalog(envelopeData: Data([2]), refreshedAt: Date(timeIntervalSince1970: 990)))
        let fetcher = CountingFetcher(data: Data([3]))
        let repository = RemoteCatalogRepository(
            baseEnvelopeData: Data([3]), fetcher: fetcher, cache: cache,
            validator: FixtureValidator(), now: { Date(timeIntervalSince1970: 1_000) }
        )

        await repository.refreshIfDue()
        let calls = await fetcher.calls
        let cachedEnvelope = await cache.value?.envelopeData
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(cachedEnvelope, Data([3]))
    }

    func testRefreshFailureDoesNotOverwriteValidatedCache() async throws {
        let cached = StoredRemoteCatalog(envelopeData: Data([2]), refreshedAt: Date(timeIntervalSince1970: 0))
        let cache = MemoryCache(value: cached)
        let fetcher = CountingFetcher(data: nil)
        let repository = RemoteCatalogRepository(
            baseEnvelopeData: Data([1]), fetcher: fetcher, cache: cache,
            validator: FixtureValidator(), now: { Date(timeIntervalSince1970: 90_000) }
        )

        await repository.refreshIfDue()

        let calls = await fetcher.calls
        XCTAssertEqual(calls, 1)
        let resultingCache = await cache.value
        XCTAssertEqual(resultingCache, cached)
    }

    func testInvalidRemoteResponseDoesNotOverwriteValidatedCache() async throws {
        let cached = StoredRemoteCatalog(envelopeData: Data([2]), refreshedAt: Date(timeIntervalSince1970: 0))
        let cache = MemoryCache(value: cached)
        let fetcher = CountingFetcher(data: Data([9]))
        let repository = RemoteCatalogRepository(
            baseEnvelopeData: Data([1]), fetcher: fetcher, cache: cache,
            validator: FixtureValidator(), now: { Date(timeIntervalSince1970: 90_000) }
        )

        await repository.refreshIfDue()

        let calls = await fetcher.calls
        XCTAssertEqual(calls, 1)
        let resultingCache = await cache.value
        XCTAssertEqual(resultingCache, cached)
    }

    func testLaunchThrowsWhenBundledBaseIsInvalid() async {
        let repository = RemoteCatalogRepository(
            baseEnvelopeData: Data([9]), fetcher: FixedFetcher(data: nil), cache: MemoryCache(),
            validator: FixtureValidator(), now: { Date(timeIntervalSince1970: 1_000) }
        )

        do {
            _ = try await repository.loadedCatalogForLaunch()
            XCTFail("A base inválida deve impedir a carga do catálogo.")
        } catch {
            XCTAssertEqual(error as? RemoteCatalogError, .invalidSignature)
        }
    }
}

private struct FixtureValidator: RemoteCatalogValidating {
    func validate(_ envelopeData: Data, now: Date) throws -> RemoteCatalogPayload {
        switch envelopeData {
        case Data([1]):
            return RemoteCatalogPayload(schemaVersion: 1, catalogVersion: "base", profiles: [], regions: [], games: [])
        case Data([2]):
            return RemoteCatalogPayload(schemaVersion: 1, catalogVersion: "remote", profiles: [], regions: [], games: [])
        case Data([3]):
            return RemoteCatalogPayload(schemaVersion: 3, catalogVersion: "base-v3", profiles: [], regions: [], games: [])
        default:
            throw RemoteCatalogError.invalidSignature
        }
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
    let data: Data?
    var calls = 0
    init(data: Data?) { self.data = data }
    func fetchCatalog() async throws -> Data {
        calls += 1
        guard let data else { throw URLError(.notConnectedToInternet) }
        return data
    }
}
