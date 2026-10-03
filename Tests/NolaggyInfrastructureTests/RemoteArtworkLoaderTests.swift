import XCTest
import Foundation
import NolaggyDomain
@testable import NolaggyInfrastructure

final class RemoteArtworkLoaderTests: XCTestCase {
    func testImageWithDifferentDigestIsAcceptedAndCachedOffline() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ArtworkProtocol.self]
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let loader = VerifiedRemoteArtworkLoader(session: URLSession(configuration: configuration), cacheDirectory: directory)
        let artwork = RemoteCatalogArtwork(path: "artwork/games/test.png", sha256: String(repeating: "0", count: 64))
        let data = await loader.imageData(artwork: artwork, assetBaseURL: "https://example.com/")
        XCTAssertEqual(data, ArtworkProtocol.png)
        let offline = VerifiedRemoteArtworkLoader(cacheDirectory: directory)
        await offline.setDownloadsEnabled(false)
        let cached = await offline.imageData(artwork: artwork, assetBaseURL: "https://example.com/")
        XCTAssertEqual(cached, data)
    }

    func testUnsafePathsAndPlainHTTPAreRejected() async {
        let loader = VerifiedRemoteArtworkLoader()
        for path in ["../test.png", "artwork/games/../test.png", "artwork/games/test.png?x=1"] {
            let data = await loader.imageData(artwork: RemoteCatalogArtwork(path: path, sha256: ""), assetBaseURL: "https://example.com/")
            XCTAssertNil(data)
        }
        let data = await loader.imageData(artwork: RemoteCatalogArtwork(path: "artwork/games/test.png", sha256: ""), assetBaseURL: "http://example.com/")
        XCTAssertNil(data)
    }
}

private final class ArtworkProtocol: URLProtocol, @unchecked Sendable {
    static let png = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=")!
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "image/png"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.png)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
