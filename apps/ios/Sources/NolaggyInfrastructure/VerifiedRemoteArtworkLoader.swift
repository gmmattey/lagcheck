import CryptoKit
import Foundation
import ImageIO
import NolaggyDomain

/// Signed reference, unverified image bytes (Decision 71).
public actor VerifiedRemoteArtworkLoader {
    public static let shared = VerifiedRemoteArtworkLoader()
    public static let maximumArtworkBytes = 8 * 1024 * 1024
    private let session: URLSession
    private let directory: URL
    private var enabled = true
    private var transfers: [UUID: Task<Data?, Never>] = [:]

    public init(session: URLSession = .shared, cacheDirectory: URL? = nil) {
        self.session = session
        directory = cacheDirectory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("lagcheck-artwork", isDirectory: true)
    }
    public func setDownloadsEnabled(_ enabled: Bool) {
        self.enabled = enabled
        if !enabled { transfers.values.forEach { $0.cancel() } }
    }
    public func imageData(artwork: RemoteCatalogArtwork?, assetBaseURL: String?) async -> Data? {
        guard let artwork, let assetBaseURL, let url = Self.resolvedURL(baseURL: assetBaseURL, artwork: artwork) else { return nil }
        // Digest used only to name a cache file, never to verify content.
        let filename = SHA256.hash(data: Data(url.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined()
        let file = directory.appendingPathComponent(filename)
        let cached = (try? Data(contentsOf: file)).flatMap { Self.isValidImage($0) ? $0 : nil }
        let modified = (try? file.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
        if let cached, let modified, Date().timeIntervalSince(modified) < 86400 { return cached }
        guard enabled, !Task.isCancelled else { return cached }
        let id = UUID()
        let session = self.session
        let transfer = Task<Data?, Never> {
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 10
                request.cachePolicy = .reloadIgnoringLocalCacheData
                request.setValue("image/png,image/jpeg,image/webp", forHTTPHeaderField: "Accept")
                let (bytes, response) = try await session.bytes(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                      http.url?.scheme == "https", http.url?.host == url.host,
                      ["image/png", "image/jpeg", "image/webp"].contains(http.mimeType ?? ""),
                      http.expectedContentLength <= Int64(Self.maximumArtworkBytes) else { return nil }
                var data = Data()
                for try await byte in bytes {
                    try Task.checkCancellation()
                    guard data.count < Self.maximumArtworkBytes else { return nil }
                    data.append(byte)
                }
                return Self.isValidImage(data) ? data : nil
            } catch { return nil }
        }
        transfers[id] = transfer
        let data = await withTaskCancellationHandler(operation: { await transfer.value }, onCancel: { transfer.cancel() })
        transfers[id] = nil
        guard let data, enabled, !Task.isCancelled else { return cached }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: file, options: .atomic)
        trimCache()
        return data
    }
    private func trimCache() {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey])) ?? []
        let entries = files.compactMap { url -> (URL, Int, Date)? in
            guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]) else { return nil }
            return (url, values.fileSize ?? 0, values.contentModificationDate ?? .distantPast)
        }.sorted { $0.2 < $1.2 }
        var size = entries.reduce(0) { $0 + $1.1 }
        for (url, bytes, _) in entries where size > 50 * 1024 * 1024 {
            try? FileManager.default.removeItem(at: url)
            size -= bytes
        }
    }
    private static func isValidImage(_ data: Data) -> Bool {
        guard !data.isEmpty, data.count <= maximumArtworkBytes,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else { return false }
        return width > 0 && height > 0 && width <= 4096 && height <= 4096
    }
    private static func resolvedURL(baseURL: String, artwork: RemoteCatalogArtwork) -> URL? {
        guard artwork.path.range(of: #"^artwork/games/[a-zA-Z0-9_-]+\.(jpg|jpeg|png|webp)$"#, options: .regularExpression) != nil,
              let base = URLComponents(string: baseURL), base.scheme == "https", base.host != nil,
              base.user == nil, base.password == nil, base.query == nil, base.fragment == nil,
              let url = base.url else { return nil }
        var components = URLComponents(url: url.appendingPathComponent(artwork.path), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "revision", value: artwork.sha256)]
        return components?.url
    }
}
