import XCTest
@testable import NolaggyApplication
@testable import NolaggyInfrastructure

final class URLSessionLoadTransportTests: XCTestCase {
    override func tearDown() {
        HangingLoadURLProtocol.setOnStop(nil)
        MockLoadURLProtocol.reset()
        super.tearDown()
    }

    func testUsesPublishedPilotEndpointAndBinaryTenMegabyteLimit() {
        XCTAssertEqual(DeepCheckLoadEndpoint.pilot.absoluteString, "https://nolaggy-deep-check.buildealabs.workers.dev/v1/load")
        let request = LoadRequest(url: DeepCheckLoadEndpoint.pilot)
        XCTAssertEqual(request.maximumBytes, 10 * 1024 * 1024)
    }

    func testDurationCancellationCancelsTheUnderlyingURLSessionTask() async {
        let stopped = expectation(description: "URLSession task was cancelled")
        // No Wi-Fi a carga abre 2 downloads paralelos; cancelar encerra todos, então pode haver mais de um stop.
        stopped.assertForOverFulfill = false
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

    func testDeadlineWithBytesReturnsCompleted() async {
        MockLoadURLProtocol.reset(responseData: Data(repeating: 5, count: 500), statusCode: 200, hangForever: true)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockLoadURLProtocol.self]
        let transport = URLSessionLoadTransport(session: URLSession(configuration: configuration))

        let outcome = await transport.transfer(
            LoadRequest(url: URL(string: "https://nolaggy.test/load")!, maximumDuration: .milliseconds(500), isWiFi: false)
        )

        XCTAssertEqual(MockLoadURLProtocol.getRequestCount(), 1)
        XCTAssertEqual(outcome, .completed(bytesTransferred: 500))
    }

    func testZeroBytesReturnsUnavailable() async {
        MockLoadURLProtocol.reset(responseData: Data(), statusCode: 500, hangForever: false)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockLoadURLProtocol.self]
        let transport = URLSessionLoadTransport(session: URLSession(configuration: configuration))

        let outcome = await transport.transfer(
            LoadRequest(url: URL(string: "https://nolaggy.test/load")!, maximumDuration: .milliseconds(100), isWiFi: false)
        )

        XCTAssertEqual(outcome, .unavailable)
    }

    func testWiFiCapsAtSixRequests() async {
        MockLoadURLProtocol.reset(responseData: Data(repeating: 1, count: 100), statusCode: 200, hangForever: false)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockLoadURLProtocol.self]
        let transport = URLSessionLoadTransport(session: URLSession(configuration: configuration))

        let outcome = await transport.transfer(
            LoadRequest(url: URL(string: "https://nolaggy.test/load")!, maximumBytes: 10_000, maximumDuration: .seconds(2), isWiFi: true)
        )

        XCTAssertEqual(MockLoadURLProtocol.getRequestCount(), 6)
        XCTAssertEqual(outcome, .completed(bytesTransferred: 600))
    }

    func testCellularCapsAtOneRequestWithoutRestart() async {
        MockLoadURLProtocol.reset(responseData: Data(repeating: 1, count: 100), statusCode: 200, hangForever: false)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockLoadURLProtocol.self]
        let transport = URLSessionLoadTransport(session: URLSession(configuration: configuration))

        let outcome = await transport.transfer(
            LoadRequest(url: URL(string: "https://nolaggy.test/load")!, maximumBytes: 10_000, maximumDuration: .seconds(2), isWiFi: false)
        )

        XCTAssertEqual(MockLoadURLProtocol.getRequestCount(), 1)
        XCTAssertEqual(outcome, .completed(bytesTransferred: 100))
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

private final class MockLoadURLProtocol: URLProtocol, @unchecked Sendable {
    private static let store = MockStore()

    static func reset(responseData: Data = Data(repeating: 1, count: 1024), statusCode: Int = 200, hangForever: Bool = false) {
        store.reset(responseData: responseData, statusCode: statusCode, hangForever: hangForever)
    }

    static func getRequestCount() -> Int {
        store.getRequestCount()
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let (_, data, status, hang) = Self.store.incrementAndGetConfig()
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: ["Content-Type": "application/octet-stream"]) else {
            return
        }
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if !data.isEmpty {
                self.client?.urlProtocol(self, didLoad: data)
            }
            if !hang {
                self.client?.urlProtocolDidFinishLoading(self)
            }
        }
    }

    override func stopLoading() {}
}

private final class MockStore: @unchecked Sendable {
    private let lock = NSLock()
    private var requestCount: Int = 0
    private var responseData: Data = Data(repeating: 1, count: 1024)
    private var statusCode: Int = 200
    private var hangForever: Bool = false

    func reset(responseData: Data = Data(repeating: 1, count: 1024), statusCode: Int = 200, hangForever: Bool = false) {
        lock.withLock {
            requestCount = 0
            self.responseData = responseData
            self.statusCode = statusCode
            self.hangForever = hangForever
        }
    }

    func incrementAndGetConfig() -> (Int, Data, Int, Bool) {
        lock.withLock {
            requestCount += 1
            return (requestCount, responseData, statusCode, hangForever)
        }
    }

    func getRequestCount() -> Int {
        lock.withLock { requestCount }
    }
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
