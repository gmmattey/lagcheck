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

public protocol RemoteCatalogFetching: Sendable {
    func fetchCatalog() async throws -> Data
}

public protocol RemoteCatalogCaching: Sendable {
    func load() async -> StoredRemoteCatalog?
    func save(_ catalog: StoredRemoteCatalog) async
}

public struct StoredRemoteCatalog: Codable, Equatable, Sendable {
    public let envelopeData: Data
    public let refreshedAt: Date

    public init(envelopeData: Data, refreshedAt: Date) {
        self.envelopeData = envelopeData
        self.refreshedAt = refreshedAt
    }
}

public protocol RemoteCatalogValidating: Sendable {
    func validate(_ envelopeData: Data, now: Date) throws -> RemoteCatalogPayload
}

/// A origem é apresentada sem expor envelope ou JSON à UI. A base assinada é
/// um fallback funcional, não uma autorização para iniciar uma medição sem
/// contexto validado.
public enum RemoteCatalogSource: Equatable, Sendable {
    case bundledBase
    case cachedRemote
}

public struct LoadedRemoteCatalog: Equatable, Sendable {
    public let payload: RemoteCatalogPayload
    public let source: RemoteCatalogSource

    public init(payload: RemoteCatalogPayload, source: RemoteCatalogSource) {
        self.payload = payload
        self.source = source
    }
}

public struct DebugRemoteCatalogValidator: RemoteCatalogValidating {
    public init() {}

    public func validate(_ envelopeData: Data, now: Date) throws -> RemoteCatalogPayload {
        try RemoteCatalogVerifier.verifyAndDecode(envelopeData: envelopeData, now: now)
    }
}

/// Mantém somente catálogos que já passaram por assinatura, validade e regras
/// de negócio do domínio. A Home usa o `base` imediatamente; a atualização é
/// deliberadamente assíncrona e nunca é requisito para abrir o app.
public actor RemoteCatalogRepository {
    public static let refreshInterval: TimeInterval = 24 * 60 * 60

    private let baseEnvelopeData: Data
    private let fetcher: any RemoteCatalogFetching
    private let cache: any RemoteCatalogCaching
    private let validator: any RemoteCatalogValidating
    private let now: @Sendable () -> Date

    public init(
        baseEnvelopeData: Data,
        fetcher: any RemoteCatalogFetching,
        cache: any RemoteCatalogCaching,
        validator: any RemoteCatalogValidating = DebugRemoteCatalogValidator(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.baseEnvelopeData = baseEnvelopeData
        self.fetcher = fetcher
        self.cache = cache
        self.validator = validator
        self.now = now
    }

    /// Retorna a base assinada se não houver um cache remoto ainda válido.
    public func catalogForLaunch() async throws -> RemoteCatalogPayload {
        try await loadedCatalogForLaunch().payload
    }

    /// Retorna também a proveniência para a composição apresentar fallback sem
    /// deixar a Home depender da atualização remota.
    public func loadedCatalogForLaunch() async throws -> LoadedRemoteCatalog {
        let date = now()
        let base = try? validator.validate(baseEnvelopeData, now: date)
        guard let stored = await cache.load(),
              let cached = try? validator.validate(stored.envelopeData, now: date),
              base == nil || cached.schemaVersion >= base!.schemaVersion else {
            return LoadedRemoteCatalog(payload: try validator.validate(baseEnvelopeData, now: date), source: .bundledBase)
        }
        return LoadedRemoteCatalog(payload: cached, source: .cachedRemote)
    }

    /// Faz no máximo uma tentativa diária. Toda falha mantém o catálogo que já
    /// estava válido; dados remotos só entram no cache depois da validação.
    public func refreshIfDue() async {
        let date = now()
        if let stored = await cache.load(),
           date.timeIntervalSince(stored.refreshedAt) < Self.refreshInterval,
           let cached = try? validator.validate(stored.envelopeData, now: date),
           cached.schemaVersion >= ((try? validator.validate(baseEnvelopeData, now: date))?.schemaVersion ?? 0) {
            return
        }
        guard let data = try? await fetcher.fetchCatalog(),
              (try? validator.validate(data, now: date)) != nil else {
            return
        }
        await cache.save(StoredRemoteCatalog(envelopeData: data, refreshedAt: date))
    }
}

public struct URLSessionRemoteCatalogFetcher: RemoteCatalogFetching {
    private let url: URL
    private let session: URLSession

    public init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    public func fetchCatalog() async throws -> Data {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}

public actor UserDefaultsRemoteCatalogCache: RemoteCatalogCaching {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "nolaggy.remoteCatalog.debug") {
        self.defaults = defaults
        self.key = key
    }

    public func load() -> StoredRemoteCatalog? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(StoredRemoteCatalog.self, from: data)
    }

    public func save(_ catalog: StoredRemoteCatalog) {
        guard let data = try? JSONEncoder().encode(catalog) else { return }
        defaults.set(data, forKey: key)
    }
}
