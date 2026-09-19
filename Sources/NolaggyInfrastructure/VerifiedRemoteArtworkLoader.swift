import CryptoKit
import Foundation
import NolaggyDomain

/// Baixa somente uma arte cuja referência chegou em catálogo assinado e só a
/// libera à UI depois de conferir os bytes contra o SHA-256 assinado.
/// Falha de rede, MIME, tamanho ou hash é tratada como ausência de arte remota.
public actor VerifiedRemoteArtworkLoader {
    public static let shared = VerifiedRemoteArtworkLoader()

    public static let maximumArtworkBytes = 8 * 1024 * 1024

    private let session: URLSession
    private var cache: [ArtworkCacheKey: Data] = [:]

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func imageData(
        artwork: RemoteCatalogArtwork?,
        assetBaseURL: String?
    ) async -> Data? {
        guard let artwork,
              let assetBaseURL,
              let url = Self.resolvedURL(baseURL: assetBaseURL, artwork: artwork),
              let expectedDigest = Data(hexadecimalString: artwork.sha256) else {
            return nil
        }

        let key = ArtworkCacheKey(url: url, digest: expectedDigest)
        if let cached = cache[key] {
            return cached
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.setValue("image/*", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  let contentType = http.value(forHTTPHeaderField: "Content-Type")?.lowercased(),
                  contentType.hasPrefix("image/"),
                  data.count <= Self.maximumArtworkBytes,
                  Data(SHA256.hash(data: data)) == expectedDigest else {
                return nil
            }
            cache[key] = data
            return data
        } catch {
            return nil
        }
    }

    private static func resolvedURL(baseURL: String, artwork: RemoteCatalogArtwork) -> URL? {
        guard artwork.path.hasPrefix("artwork/"),
              !artwork.path.contains(".."),
              var components = URLComponents(string: baseURL),
              components.scheme == "https",
              components.host != nil,
              components.query == nil,
              components.fragment == nil,
              let base = components.url else {
            return nil
        }
        return base.appendingPathComponent(artwork.path)
    }
}

private struct ArtworkCacheKey: Hashable, Sendable {
    let url: URL
    let digest: Data
}

private extension Data {
    init?(hexadecimalString value: String) {
        guard value.count == 64 else { return nil }
        var bytes = [UInt8]()
        bytes.reserveCapacity(value.count / 2)
        var index = value.startIndex
        while index < value.endIndex {
            let next = value.index(index, offsetBy: 2)
            guard let byte = UInt8(value[index..<next], radix: 16) else { return nil }
            bytes.append(byte)
            index = next
        }
        self.init(bytes)
    }
}
