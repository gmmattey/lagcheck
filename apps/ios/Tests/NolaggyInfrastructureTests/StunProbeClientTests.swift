import XCTest
@testable import NolaggyDomain
@testable import NolaggyInfrastructure

/// Constrói uma resposta STUN Binding sintética (RFC 5389) com um atributo
/// XOR-MAPPED-ADDRESS IPv4, para alimentar o transporte UDP mockado sem rede real.
private func makeStunBindingResponse(txID: Data, ip: String, port: UInt16) -> Data {
    var response = Data()
    var msgType = UInt16(0x0101).bigEndian
    response.append(Data(bytes: &msgType, count: 2))

    var attrTotalLen = UInt16(12).bigEndian
    response.append(Data(bytes: &attrTotalLen, count: 2))

    var cookie = UInt32(0x2112A442).bigEndian
    response.append(Data(bytes: &cookie, count: 4))
    response.append(txID)

    var attrType = UInt16(0x0020).bigEndian
    response.append(Data(bytes: &attrType, count: 2))
    var attrLen = UInt16(8).bigEndian
    response.append(Data(bytes: &attrLen, count: 2))

    response.append(0x00)
    response.append(0x01)

    var xorPort = UInt16(port ^ 0x2112).bigEndian
    response.append(Data(bytes: &xorPort, count: 2))

    let parts = ip.split(separator: ".").compactMap { UInt32($0) }
    let ipInt: UInt32 = (parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8) | parts[3]
    var xorIP = UInt32(ipInt ^ 0x2112A442).bigEndian
    response.append(Data(bytes: &xorIP, count: 4))

    return response
}

/// Transporte UDP mockado: mapeia `host:port` para uma resposta sintética
/// (ou uma falha), permitindo testar a lógica de dupla sondagem STUN sem
/// tocar em rede real.
private final class MockStunUDPTransport: StunUDPTransport, @unchecked Sendable {
    struct StubResponse {
        let ip: String
        let port: UInt16
    }

    private var stubs: [String: StubResponse] = [:]
    private var failingKeys: Set<String> = []

    func stub(host: String, port: UInt16, ip: String, responsePort: UInt16) {
        stubs["\(host):\(port)"] = StubResponse(ip: ip, port: responsePort)
    }

    func fail(host: String, port: UInt16) {
        failingKeys.insert("\(host):\(port)")
    }

    func exchange(packet: Data, host: String, port: UInt16, timeoutSeconds: TimeInterval) async throws -> Data {
        let key = "\(host):\(port)"
        if failingKeys.contains(key) {
            throw URLError(.timedOut)
        }
        guard let stub = stubs[key] else {
            throw URLError(.timedOut)
        }
        let txID = packet.subdata(in: 8..<20)
        return makeStunBindingResponse(txID: txID, ip: stub.ip, port: stub.port)
    }
}

/// Resolver de IP local mockado, para controlar deterministicamente o
/// cenário de NAT Tipo 1 Aberto (local == público).
private struct MockLocalAddressResolver: LocalInterfaceAddressResolving {
    let ip: String?
    func resolveLocalIPv4() -> String? { ip }
}

final class StunProbeClientTests: XCTestCase {

    private let primaryHost = "stun.example.com"
    private let primaryPort: UInt16 = 3478
    private let secondaryServer = StunServerEndpoint(host: "stun2.example.com", port: 19302)

    private func makeClient(
        transport: MockStunUDPTransport,
        localIP: String?
    ) -> StunProbeClient {
        StunProbeClient(
            host: primaryHost,
            port: primaryPort,
            secondaryServer: secondaryServer,
            timeoutSeconds: 1.0,
            transport: transport,
            localAddressResolver: MockLocalAddressResolver(ip: localIP)
        )
    }

    func testSTUNResponsesDoNotClassifyNATTopology() async {
        let transport = MockStunUDPTransport()
        transport.stub(host: primaryHost, port: primaryPort, ip: "177.136.20.10", responsePort: 54321)
        transport.stub(host: secondaryServer.host, port: secondaryServer.port, ip: "177.136.20.10", responsePort: 54321)

        let client = makeClient(transport: transport, localIP: "177.136.20.10")
        let snapshot = await client.probeTopology()

        XCTAssertEqual(snapshot.natType, .inconclusive)
        XCTAssertEqual(snapshot.cgnatStatus, .inconclusive)
        XCTAssertEqual(snapshot.doubleNATStatus, .inconclusive)
        XCTAssertFalse(snapshot.hasAnyMultiplayerIssue)
    }

    func testSingleOrConflictingSTUNResponsesRemainInconclusive() async {
        let transport = MockStunUDPTransport()
        transport.stub(host: primaryHost, port: primaryPort, ip: "177.136.20.10", responsePort: 54321)
        transport.fail(host: secondaryServer.host, port: secondaryServer.port)

        let client = makeClient(transport: transport, localIP: "192.168.1.50")
        let snapshot = await client.probeTopology()

        XCTAssertEqual(snapshot.natType, .inconclusive)
        XCTAssertEqual(snapshot.cgnatStatus, .inconclusive)
        XCTAssertEqual(snapshot.doubleNATStatus, .inconclusive)
    }
}
