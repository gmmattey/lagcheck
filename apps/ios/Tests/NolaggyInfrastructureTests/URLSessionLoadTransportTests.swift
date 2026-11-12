import XCTest
@testable import NolaggyApplication
@testable import NolaggyInfrastructure

final class URLSessionLoadTransportTests: XCTestCase {
    override func tearDown() {
        HangingLoadURLProtocol.setOnStop(nil)
        super.tearDown()
    }

    func testUsesPublishedPilotEndpointAndBinaryTenMegabyteLimit() {
        XCTAssertEqual(DeepCheckLoadEndpoint.pilot.absoluteString, "https://nolaggy-deep-check.buildealabs.workers.dev/v1/load")
        let request = LoadRequest(url: DeepCheckLoadEndpoint.pilot)
        XCTAssertEqual(request.maximumBytes, 10 * 1024 * 1024)
    }

    func testDurationCancellationCancelsTheUnderlyingURLSessionTask() async {
        let stopped = expectation(description: "URLSession task was cancelled")
        HangingLoadURLProtocol.setOnStop { stopped.fulfill() }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [HangingLoadURLProtocol.self]
        let transport = URLSessionLoadTransport(session: URLSession(configuration: configuration))

        let outcome = await transport.transfer(
            LoadRequest(url: URL(string: "https://nolaggy.test/load")!, maximumDuration: .milliseconds(100))
        )

        XCTAssertEqual(outcome, .unavailable)
        await fulfillment(of: [stopped], timeout: 1)
    }
}

private final class HangingLoadURLProtocol: URLProtocol, @unchecked Sendable {
    private static let callbacks = CallbackStore()

    static func setOnStop(_ callback: (@Sendable () -> Void)?) {
        callbacks.set(callback)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {}
    override func stopLoading() { Self.callbacks.call() }
}

private final class CallbackStore: @unchecked Sendable {
    private let lock = NSLock()
    private var callback: (@Sendable () -> Void)?

    func set(_ callback: (@Sendable () -> Void)?) {
        lock.withLock { self.callback = callback }
    }

    func call() {
        lock.withLock { callback }?()
    }
}
