import Foundation

/// Localização aproximada pelo IP, só para posicionar "Você" no mapa de medição.
public struct ApproxLocation: Equatable, Sendable {
    public let city: String?
    public let country: String?
    public let lat: Double
    public let lon: Double

    public init(city: String?, country: String?, lat: Double, lon: Double) {
        self.city = city
        self.country = country
        self.lat = lat
        self.lon = lon
    }
}

/// Consulta o endpoint público do site (`/v1/approx-location`), o mesmo usado
/// pelo site e pelo Windows. O servidor devolve cidade e coordenadas
/// arredondadas a 0,5° (cerca de 50 km), sem GPS e sem guardar nada.
///
/// No app: sessão efêmera (sem cookies nem cache em disco), sem cabeçalho de
/// identificação, limite de 3 s e resultado mantido só em memória enquanto o
/// app roda. Falha ou demora nunca afeta a medição: o mapa segue sem cidade.
public actor ApproxLocationClient {
    public static let shared = ApproxLocationClient()
    public static let endpoint = URL(string: "https://lagcheck.signallq.com/v1/approx-location")!
    public static let timeoutSeconds: TimeInterval = 3

    private let session: URLSession
    private let endpoint: URL
    private var cached: ApproxLocation?
    private var inFlight: Task<ApproxLocation?, Never>?

    public init(session: URLSession? = nil, endpoint: URL = ApproxLocationClient.endpoint) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = Self.timeoutSeconds
            configuration.timeoutIntervalForResource = Self.timeoutSeconds
            configuration.httpShouldSetCookies = false
            configuration.httpCookieAcceptPolicy = .never
            configuration.urlCache = nil
            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            self.session = URLSession(configuration: configuration)
        }
        self.endpoint = endpoint
    }

    /// Último resultado obtido nesta execução do app, sem rede.
    public func cachedLocation() -> ApproxLocation? { cached }

    /// Resultado em memória ou uma consulta nova (uma por vez). Nil quando falha.
    public func location() async -> ApproxLocation? {
        if let cached { return cached }
        if let inFlight { return await inFlight.value }
        let session = session
        let endpoint = endpoint
        let task = Task<ApproxLocation?, Never> {
            var request = URLRequest(url: endpoint, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: Self.timeoutSeconds)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            guard let (data, response) = try? await session.data(for: request),
                  let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
                  data.count <= 4096 else { return nil }
            return Self.decode(data)
        }
        inFlight = task
        let result = await task.value
        inFlight = nil
        if let result { cached = result }
        return result
    }

    /// Mesmas regras de `parseApproxLocation` do site.
    public static func decode(_ data: Data) -> ApproxLocation? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let lat = (object["lat"] as? NSNumber)?.doubleValue,
              let lon = (object["lon"] as? NSNumber)?.doubleValue,
              lat.isFinite, lon.isFinite, (-90...90).contains(lat), (-180...180).contains(lon) else { return nil }
        func text(_ key: String) -> String? {
            guard let value = object[key] as? String else { return nil }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        return ApproxLocation(city: text("city"), country: text("country"), lat: lat, lon: lon)
    }
}
