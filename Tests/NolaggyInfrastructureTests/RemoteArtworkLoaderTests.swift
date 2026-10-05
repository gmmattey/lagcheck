import XCTest
import Foundation
import CoreGraphics
import ImageIO
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

    func testRejectsInvalidMIMEHTTPStatusAndOversizedBodiesWithoutCaching() async throws {
        for scenario in ["mime", "http", "declared-size", "dimensions", "invalid-body"] {
            let directory = temporaryDirectory()
            defer { try? FileManager.default.removeItem(at: directory) }
            let loader = makeLoader(directory: directory)
            let result = await loader.imageData(artwork: artwork(scenario), assetBaseURL: "https://example.com/")
            XCTAssertNil(result, scenario)
            XCTAssertTrue(cacheFiles(directory).isEmpty, scenario)
        }
    }

    func testOversizedStreamStopsBeforeServerFinishesBody() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let loader = makeLoader(directory: directory)
        let host = UUID().uuidString.lowercased()
        let completed = expectation(description: "Oversized stream rejected without EOF")
        let stopped = expectation(forNotification: Notification.Name("artwork-stop-" + host), object: nil)
        let reference = artwork("stream-size")
        let task = Task {
            let result = await loader.imageData(artwork: reference, assetBaseURL: "https://" + host + "/")
            completed.fulfill()
            return result
        }
        // The protocol never emits EOF. A final image validation cannot make this pass.
        await fulfillment(of: [completed, stopped], timeout: 5)
        // Bound cleanup even if an implementation regresses and keeps waiting for EOF.
        task.cancel()
        let result = await task.value
        XCTAssertNil(result)
        XCTAssertTrue(cacheFiles(directory).isEmpty)
    }

    func testExpiredCacheSurvivesFailedRevalidationWithoutRefreshingItsAge() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let online = makeLoader(directory: directory)
        let original = await online.imageData(artwork: artwork("valid"), assetBaseURL: "https://example.com/")
        XCTAssertEqual(original, ArtworkProtocol.png)
        let file = try XCTUnwrap(cacheFiles(directory).first)
        let expired = Date(timeIntervalSinceNow: -90_000)
        try FileManager.default.setAttributes([.modificationDate: expired], ofItemAtPath: file.path)
        let initialAttributes = try FileManager.default.attributesOfItem(atPath: file.path)
        let initialModified = try XCTUnwrap(initialAttributes[.modificationDate] as? Date)
        XCTAssertEqual(initialModified.timeIntervalSince1970, expired.timeIntervalSince1970, accuracy: 1)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ArtworkFailureProtocol.self]
        let loader = VerifiedRemoteArtworkLoader(session: URLSession(configuration: configuration), cacheDirectory: directory)
        let requested = expectation(forNotification: ArtworkFailureProtocol.requested, object: nil)
        let result = await loader.imageData(artwork: artwork("valid"), assetBaseURL: "https://example.com/")
        await fulfillment(of: [requested], timeout: 2)
        XCTAssertEqual(result, original)
        let resultingAttributes = try FileManager.default.attributesOfItem(atPath: file.path)
        let modified = try XCTUnwrap(resultingAttributes[.modificationDate] as? Date)
        XCTAssertEqual(modified.timeIntervalSince1970, expired.timeIntervalSince1970, accuracy: 1)
    }

    func testPausingCancelsActiveTransferAndResumingAllowsNewDownload() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let loader = makeLoader(directory: directory)
        let host = UUID().uuidString.lowercased()
        let started = expectation(forNotification: Notification.Name("artwork-start-" + host), object: nil)
        let stopped = expectation(forNotification: Notification.Name("artwork-stop-" + host), object: nil)
        let reference = artwork("hold")
        let task = Task { await loader.imageData(artwork: reference, assetBaseURL: "https://" + host + "/") }
        await fulfillment(of: [started], timeout: 2)
        await loader.setDownloadsEnabled(false)
        let cancelled = await task.value
        XCTAssertNil(cancelled)
        await fulfillment(of: [stopped], timeout: 2)
        XCTAssertTrue(cacheFiles(directory).isEmpty)
        let paused = await loader.imageData(artwork: artwork("valid"), assetBaseURL: "https://example.com/")
        XCTAssertNil(paused)
        await loader.setDownloadsEnabled(true)
        let resumed = await loader.imageData(artwork: artwork("valid"), assetBaseURL: "https://example.com/")
        XCTAssertEqual(resumed, ArtworkProtocol.png)
    }

    func testCallerCancellationStopsTransferAndDoesNotPopulateCache() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let loader = makeLoader(directory: directory)
        let host = UUID().uuidString.lowercased()
        let started = expectation(forNotification: Notification.Name("artwork-start-" + host), object: nil)
        let stopped = expectation(forNotification: Notification.Name("artwork-stop-" + host), object: nil)
        let reference = artwork("hold")
        let task = Task { await loader.imageData(artwork: reference, assetBaseURL: "https://" + host + "/") }
        await fulfillment(of: [started], timeout: 2)
        task.cancel()
        let result = await task.value
        XCTAssertNil(result)
        await fulfillment(of: [stopped], timeout: 2)
        XCTAssertTrue(cacheFiles(directory).isEmpty)
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    private func makeLoader(directory: URL) -> VerifiedRemoteArtworkLoader {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ArtworkProtocol.self]
        return VerifiedRemoteArtworkLoader(session: URLSession(configuration: configuration), cacheDirectory: directory)
    }

    private func artwork(_ scenario: String) -> RemoteCatalogArtwork {
        RemoteCatalogArtwork(path: "artwork/games/\(scenario).png", sha256: "revision-1")
    }

    private func cacheFiles(_ directory: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
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
        let url = request.url!
        let scenario = url.deletingPathExtension().lastPathComponent
        var headers = ["Content-Type": scenario == "mime" ? "text/html" : "image/png"]
        if scenario == "declared-size" {
            headers["Content-Length"] = String(VerifiedRemoteArtworkLoader.maximumArtworkBytes + 1)
        }
        let response = HTTPURLResponse(url: url, statusCode: scenario == "http" ? 503 : 200, httpVersion: "HTTP/1.1", headerFields: headers)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        switch scenario {
        case "hold":
            client?.urlProtocol(self, didLoad: Self.png.prefix(24))
            NotificationCenter.default.post(name: Notification.Name("artwork-start-" + url.host!), object: nil)
            // Headers and a partial body have arrived; wait indefinitely for cancellation.
            return
        case "invalid-body":
            client?.urlProtocol(self, didLoad: Data("not an image".utf8))
        case "stream-size":
            // No Content-Length: enforce the bound while consuming the response body.
            client?.urlProtocol(self, didLoad: Data(repeating: 0, count: VerifiedRemoteArtworkLoader.maximumArtworkBytes + 1))
            // Never finish: rejection must happen while consuming the stream.
            return
        case "dimensions":
            let context = CGContext(data: nil, width: 4097, height: 1, bitsPerComponent: 8, bytesPerRow: 4097 * 4,
                                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
            let data = NSMutableData()
            let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil)!
            CGImageDestinationAddImage(destination, context.makeImage()!, nil)
            CGImageDestinationFinalize(destination)
            client?.urlProtocol(self, didLoad: data as Data)
        default:
            client?.urlProtocol(self, didLoad: Self.png)
        }
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {
        if let url = request.url, ["hold", "stream-size"].contains(url.deletingPathExtension().lastPathComponent) {
            NotificationCenter.default.post(name: Notification.Name("artwork-stop-" + url.host!), object: nil)
        }
    }
}

private final class ArtworkFailureProtocol: URLProtocol, @unchecked Sendable {
    static let requested = Notification.Name("artwork-failed-revalidation")
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        NotificationCenter.default.post(name: Self.requested, object: nil)
        client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
    }
    override func stopLoading() {}
}
