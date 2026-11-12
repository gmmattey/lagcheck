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

    func testType1OpenWhenLocalIPMatchesPublicIP() async {
        let transport = MockStunUDPTransport()
        transport.stub(host: primaryHost, port: primaryPort, ip: "177.136.20.10", responsePort: 54321)
        transport.stub(host: secondaryServer.host, port: secondaryServer.port, ip: "177.136.20.10", responsePort: 54321)

        let client = makeClient(transport: transport, localIP: "177.136.20.10")
        let snapshot = await client.probeTopology()

        XCTAssertEqual(snapshot.natType, .type1Open)
        XCTAssertEqual(snapshot.cgnatStatus, .notDetected)
        XCTAssertEqual(snapshot.doubleNATStatus, .notDetected)
        XCTAssertFalse(snapshot.hasAnyMultiplayerIssue)
    }

    func testType2ModerateWhenBothProbesAgreeOnDifferentLocalIP() async {
        let transport = MockStunUDPTransport()
        transport.stub(host: primaryHost, port: primaryPort, ip: "177.136.20.10", responsePort: 54321)
        transport.stub(host: secondaryServer.host, port: secondaryServer.port, ip: "177.136.20.10", responsePort: 54321)

        let client = makeClient(transport: transport, localIP: "192.168.1.50")
        let snapshot = await client.probeTopology()

        XCTAssertEqual(snapshot.natType, .type2Moderate)
        XCTAssertEqual(snapshot.cgnatStatus, .notDetected)
        XCTAssertEqual(snapshot.doubleNATStatus, .notDetected)
        XCTAssertFalse(snapshot.hasAnyMultiplayerIssue)
    }

    func testType3StrictWhenPublicIPIsCGNAT() async {
        let transport = MockStunUDPTransport()
        transport.stub(host: primaryHost, port: primaryPort, ip: "100.70.10.5", responsePort: 54321)
        transport.stub(host: secondaryServer.host, port: secondaryServer.port, ip: "100.70.10.5", responsePort: 54321)

        let client = makeClient(transport: transport, localIP: "192.168.1.50")
        let snapshot = await client.probeTopology()

        XCTAssertEqual(snapshot.natType, .type3Strict)
        XCTAssertEqual(snapshot.cgnatStatus, .detected)
        XCTAssertTrue(NATTopologyEvaluator.isRFC6598CGNAT(ip: "100.70.10.5"))
        XCTAssertTrue(snapshot.hasAnyMultiplayerIssue)
    }

    func testDoubleNATSuspectedWhenServersDisagreeOnPublicIP() async {
        let transport = MockStunUDPTransport()
        transport.stub(host: primaryHost, port: primaryPort, ip: "177.136.20.10", responsePort: 54321)
        transport.stub(host: secondaryServer.host, port: secondaryServer.port, ip: "203.0.113.55", responsePort: 60000)

        let client = makeClient(transport: transport, localIP: "192.168.1.50")
        let snapshot = await client.probeTopology()

        XCTAssertEqual(snapshot.doubleNATStatus, .suspectOrDetected)
        XCTAssertEqual(snapshot.natType, .type3Strict)
        XCTAssertTrue(snapshot.hasAnyMultiplayerIssue)
    }

    func testInconsistentPortMappingWhenSameIPDifferentExternalPort() async {
        let transport = MockStunUDPTransport()
        transport.stub(host: primaryHost, port: primaryPort, ip: "177.136.20.10", responsePort: 54321)
        transport.stub(host: secondaryServer.host, port: secondaryServer.port, ip: "177.136.20.10", responsePort: 60000)

        let client = makeClient(transport: transport, localIP: "192.168.1.50")
        let snapshot = await client.probeTopology()

        // Porta externa inconsistente entre sondagens independentes força NAT Estrito,
        // mesmo sem indício de duplo hop (IP público idêntico nas duas sondagens).
        XCTAssertEqual(snapshot.natType, .type3Strict)
        XCTAssertEqual(snapshot.doubleNATStatus, .notDetected)
    }

    func testDegradesGracefullyWhenOnlySecondaryProbeFails() async {
        let transport = MockStunUDPTransport()
        transport.stub(host: primaryHost, port: primaryPort, ip: "177.136.20.10", responsePort: 54321)
        transport.fail(host: secondaryServer.host, port: secondaryServer.port)

        let client = makeClient(transport: transport, localIP: "192.168.1.50")
        let snapshot = await client.probeTopology()

        // Sem segunda amostra, não há evidência de inconsistência: usa o caso
        // conservador (mapeamento consistente, sem duplo hop) em vez de
        // hardcodar um resultado positivo ou negativo arbitrário.
        XCTAssertEqual(snapshot.natType, .type2Moderate)
        XCTAssertEqual(snapshot.doubleNATStatus, .notDetected)
        XCTAssertNotEqual(snapshot.natType, .inconclusive)
    }

    func testInconclusiveWhenPrimaryProbeFails() async {
        let transport = MockStunUDPTransport()
        transport.fail(host: primaryHost, port: primaryPort)
        transport.stub(host: secondaryServer.host, port: secondaryServer.port, ip: "177.136.20.10", responsePort: 54321)

        let client = makeClient(transport: transport, localIP: "192.168.1.50")
        let snapshot = await client.probeTopology()

        XCTAssertEqual(snapshot.natType, .inconclusive)
    }

    func testExplicitLocalIPParameterOverridesResolver() async {
        let transport = MockStunUDPTransport()
        transport.stub(host: primaryHost, port: primaryPort, ip: "177.136.20.10", responsePort: 54321)
        transport.stub(host: secondaryServer.host, port: secondaryServer.port, ip: "177.136.20.10", responsePort: 54321)

        // Resolver mockado devolveria um IP diferente, mas o parâmetro explícito deve prevalecer.
        let client = makeClient(transport: transport, localIP: "10.0.0.5")
        let snapshot = await client.probeTopology(localIP: "177.136.20.10")

        XCTAssertEqual(snapshot.natType, .type1Open)
    }
}
