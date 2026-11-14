import Foundation
import NolaggyDomain

public enum DebugCatalogBase {
    /// O recurso pertence ao framework de infraestrutura, não ao bundle da UI.
    /// A composição só recebe bytes do envelope; validação continua no domínio.
    public static func envelopeData() -> Data? {
        Bundle(for: InfrastructureBundleMarker.self).url(forResource: "DebugCatalogBase", withExtension: "json")
            .flatMap { try? Data(contentsOf: $0) }
    }
}

private final class InfrastructureBundleMarker {}

/// Fonte de verdade local do catálogo. O arquivo acompanha cada build e é
/// sempre validado (tamanho, schema e regras de negócio) antes de a UI conhecer
/// jogos, regiões ou rotas. Não há atualização HTTP, cache persistente,
/// assinatura nem validade (Decisão 106): uma versão antiga do Worker jamais
/// pode reduzir a cobertura global do app para São Paulo.
public struct BundledCatalogRepository: Sendable {
    private let catalogData: Data

    public init(envelopeData: Data) {
        self.catalogData = envelopeData
    }

    public func load() throws -> RemoteCatalogPayload {
        try RemoteCatalogVerifier.decodeBundled(catalogData)
    }
}

public protocol CatalogHTTPTransport: Sendable {
    func fetch(url: URL, etag: String?) async throws -> (statusCode: Int, data: Data, etag: String?)
}

public struct URLSessionCatalogHTTPTransport: CatalogHTTPTransport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetch(url: URL, etag: String?) async throws -> (statusCode: Int, data: Data, etag: String?) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData
        if let etag, !etag.isEmpty {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (http.statusCode, data, http.value(forHTTPHeaderField: "ETag"))
    }
}

/// Sincroniza o catálogo remoto (jogos, capas, rotas e regiões UDP) com fallback
/// imediato no `BundledCatalogRepository` e proteção contra downgrade de cobertura.
public actor RemoteSyncedCatalogRepository {
    public static let defaultCatalogURL = URL(string: "https://lagcheck.signallq.com/api/catalog-v3.json")!
    public static let minimumRegionCount = 20
    public static let defaultRefreshInterval: TimeInterval = 6 * 60 * 60

    private let bundled: BundledCatalogRepository
    private let cacheURL: URL
    private let etagKey: String
    private let lastCheckedKey: String
    private let defaults: UserDefaults
    private let remoteURL: URL
    private let transport: any CatalogHTTPTransport
    private let refreshInterval: TimeInterval

    public init(
        bundled: BundledCatalogRepository,
        cacheURL: URL? = nil,
        remoteURL: URL = RemoteSyncedCatalogRepository.defaultCatalogURL,
        transport: any CatalogHTTPTransport = URLSessionCatalogHTTPTransport(),
        defaultsSuiteName: String? = nil,
        refreshInterval: TimeInterval = RemoteSyncedCatalogRepository.defaultRefreshInterval,
        storageKeyPrefix: String = "lagcheck.catalog.v3"
    ) {
        self.bundled = bundled
        if let cacheURL {
            self.cacheURL = cacheURL
        } else {
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            self.cacheURL = support.appendingPathComponent("LagCheck", isDirectory: true)
                .appendingPathComponent("catalog-v3.json")
        }
        self.remoteURL = remoteURL
        self.transport = transport
        self.defaults = defaultsSuiteName.flatMap { UserDefaults(suiteName: $0) } ?? .standard
        self.refreshInterval = refreshInterval
        self.etagKey = "\(storageKeyPrefix).etag"
        self.lastCheckedKey = "\(storageKeyPrefix).lastCheckedAt"
    }

    public func loadLocal() throws -> RemoteCatalogPayload {
        if let cachedData = try? Data(contentsOf: cacheURL),
           let cached = try? decodeAndValidate(cachedData) {
            return cached
        }
        return try bundled.load()
    }

    public func syncIfNeeded(now: Date = Date(), force: Bool = false) async -> RemoteCatalogPayload? {
        if !force {
            let lastChecked = defaults.double(forKey: lastCheckedKey)
            if lastChecked > 0, now.timeIntervalSince1970 - lastChecked < refreshInterval {
                return nil
            }
        }
        let savedETag = defaults.string(forKey: etagKey)
        guard let result = try? await transport.fetch(url: remoteURL, etag: savedETag) else {
            return nil
        }
        if result.statusCode == 304 {
            defaults.set(now.timeIntervalSince1970, forKey: lastCheckedKey)
            return nil
        }
        guard result.statusCode == 200,
              let payload = try? decodeAndValidate(result.data) else {
            return nil
        }
        let dir = cacheURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? result.data.write(to: cacheURL, options: .atomic)
        if let newETag = result.etag, !newETag.isEmpty {
            defaults.set(newETag, forKey: etagKey)
        }
        defaults.set(now.timeIntervalSince1970, forKey: lastCheckedKey)
        return payload
    }

    private func decodeAndValidate(_ data: Data) throws -> RemoteCatalogPayload {
        let payload = try RemoteCatalogVerifier.decodeBundled(data)
        guard payload.regions.count >= Self.minimumRegionCount, !payload.games.isEmpty else {
            throw RemoteCatalogError.malformedPayload
        }
        return payload
    }
}
