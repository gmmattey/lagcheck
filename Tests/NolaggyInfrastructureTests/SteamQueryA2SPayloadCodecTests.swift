import XCTest
@testable import NolaggyDomain
@testable import NolaggyInfrastructure

final class SteamQueryA2SPayloadCodecTests: XCTestCase {
    private let expectedInitialRequestBytes: [UInt8] = [
        0xFF, 0xFF, 0xFF, 0xFF, 0x54, 0x53, 0x6F, 0x75, 0x72, 0x63, 0x65, 0x20, 0x45, 0x6E, 0x67, 0x69, 0x6E, 0x65, 0x20, 0x51, 0x75, 0x65, 0x72, 0x79, 0x00
    ]

    private let sampleChallengeResponseBytes: [UInt8] = [
        0xFF, 0xFF, 0xFF, 0xFF, 0x41, 0x78, 0x56, 0x34, 0x12
    ]

    private let expectedAuthenticatedBytes: [UInt8] = [
        0xFF, 0xFF, 0xFF, 0xFF, 0x54, 0x53, 0x6F, 0x75, 0x72, 0x63, 0x65, 0x20, 0x45, 0x6E, 0x67, 0x69, 0x6E, 0x65, 0x20, 0x51, 0x75, 0x65, 0x72, 0x79, 0x00, 0x78, 0x56, 0x34, 0x12
    ]

    func testEncodeInitialA2SRequestProduces25BytesSourceEngineQuery() {
        let request = SteamQueryA2SPayloadCodec.encodeInitialRequest()

        XCTAssertEqual(request.count, 25)
        XCTAssertEqual(Array(request), expectedInitialRequestBytes)
    }

    func testDecodeS2CChallengeExtracts4ByteLittleEndianToken() throws {
        let challengeData = Data(sampleChallengeResponseBytes)
        let token = try SteamQueryA2SPayloadCodec.decodeChallenge(challengeData)

        XCTAssertEqual(token, 0x1234_5678)
        XCTAssertTrue(SteamQueryA2SPayloadCodec.isChallengeResponse(challengeData))

        // Malformed lengths
        XCTAssertThrowsError(try SteamQueryA2SPayloadCodec.decodeChallenge(Data([0xFF, 0xFF, 0xFF, 0xFF, 0x41, 0x01, 0x02]))) { error in
            XCTAssertEqual(error as? SteamQueryA2SError, .invalidLength)
        }

        // Malformed header
        XCTAssertThrowsError(try SteamQueryA2SPayloadCodec.decodeChallenge(Data([0x00, 0xFF, 0xFF, 0xFF, 0x41, 0x78, 0x56, 0x34, 0x12]))) { error in
            XCTAssertEqual(error as? SteamQueryA2SError, .invalidHeader)
        }

        // Unexpected response type (not 'A')
        XCTAssertThrowsError(try SteamQueryA2SPayloadCodec.decodeChallenge(Data([0xFF, 0xFF, 0xFF, 0xFF, 0x49, 0x78, 0x56, 0x34, 0x12]))) { error in
            XCTAssertEqual(error as? SteamQueryA2SError, .unexpectedResponseType)
        }
    }

    func testEncodeAuthenticatedA2SRequestAppendsChallengeToken() {
        let token: UInt32 = 0x1234_5678
        let request = SteamQueryA2SPayloadCodec.encodeAuthenticatedRequest(challengeToken: token)

        XCTAssertEqual(request.count, 29)
        XCTAssertEqual(Array(request), expectedAuthenticatedBytes)
    }

    func testAcceptsValidA2SInfoResponseAndRejectsMalformedPackets() {
        let validResponse = Data([0xFF, 0xFF, 0xFF, 0xFF, 0x49, 0x11, 0x52, 0x75, 0x73, 0x74, 0x20, 0x53, 0x65, 0x72, 0x76, 0x65, 0x72, 0x00])
        XCTAssertTrue(SteamQueryA2SPayloadCodec.isValidInfoResponse(validResponse))

        // Reject packets shorter than 5 bytes
        XCTAssertFalse(SteamQueryA2SPayloadCodec.isValidInfoResponse(Data([0xFF, 0xFF, 0xFF, 0xFF])))
        XCTAssertFalse(SteamQueryA2SPayloadCodec.isValidInfoResponse(Data()))

        // Reject wrong header
        XCTAssertFalse(SteamQueryA2SPayloadCodec.isValidInfoResponse(Data([0xFE, 0xFF, 0xFF, 0xFF, 0x49])))

        // Reject wrong type byte (e.g. 'A' challenge or random byte)
        XCTAssertFalse(SteamQueryA2SPayloadCodec.isValidInfoResponse(Data(sampleChallengeResponseBytes)))
        XCTAssertFalse(SteamQueryA2SPayloadCodec.isValidInfoResponse(Data([0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x01])))
    }

    func testDecodesIdentityFieldsFromA2SInfoResponse() throws {
        var packet = Data([0xFF, 0xFF, 0xFF, 0xFF, 0x49, 0x11])
        packet.append("SP Community #1\0de_dust2\0csgo\0Counter-Strike 2\0".data(using: .utf8)!)
        packet.append(contentsOf: [0xDA, 0x02]) // AppID 730, little-endian

        let info = try SteamQueryA2SPayloadCodec.decodeInfo(packet)

        XCTAssertEqual(info.name, "SP Community #1")
        XCTAssertEqual(info.gameDirectory, "csgo")
        XCTAssertEqual(info.appID, 730)
    }
    // MARK: - Pré-validação de identidade (vetores compartilhados com Android)

    func testPreflightMachineMatchesSharedVectors() throws {
        let vectors = try SharedA2SVectors.load()
        XCTAssertEqual(vectors.preflightVectors.count, 15)
        for vector in vectors.preflightVectors {
            var machine = SteamA2SPreflightMachine(identity: RemoteCatalogRouteIdentity(
                expectedAppID: vector.identity.appID,
                expectedGameDirectory: vector.identity.gameDirectory,
                expectedServerNamePrefix: vector.identity.namePrefix
            ))
            var sends = [machine.initialRequest]
            var decision: String?
            for event in vector.events {
                switch machine.receive(try event.map(SharedA2SVectors.data(fromHex:))) {
                case let .send(payload): sends.append(payload)
                case .accept: decision = "accept"
                case .reject: decision = "reject"
                }
                if decision != nil { break }
            }
            XCTAssertEqual(decision, vector.expectedDecision, vector.id)
            XCTAssertEqual(sends.map(SharedA2SVectors.hex), vector.expectedSends, vector.id)
        }
    }

    func testPreflightMachineNeverAcceptsAfterRejecting() {
        var machine = SteamA2SPreflightMachine(identity: RemoteCatalogRouteIdentity(expectedAppID: 730, expectedGameDirectory: "csgo"))
        XCTAssertEqual(machine.receive(nil), .reject)
        var info = Data([0xFF, 0xFF, 0xFF, 0xFF, 0x49, 0x11])
        info.append("host\0map\0csgo\0game\0".data(using: .utf8)!)
        info.append(contentsOf: [0xDA, 0x02])
        XCTAssertEqual(machine.receive(info), .reject)
    }
}

struct SharedA2SVectors: Decodable {
    struct Identity: Decodable { let appID: UInt16; let gameDirectory: String; let namePrefix: String? }
    struct Preflight: Decodable {
        let id: String
        let identity: Identity
        let events: [String?]
        let expectedSends: [String]
        let expectedDecision: String
    }
    let preflightVectors: [Preflight]

    static func load(file: StaticString = #filePath) throws -> SharedA2SVectors {
        var url = URL(fileURLWithPath: "\(file)")
        for _ in 0..<3 { url.deleteLastPathComponent() }
        url.appendPathComponent("tools/vectors/steam-a2s-preflight-vectors.json")
        return try JSONDecoder().decode(SharedA2SVectors.self, from: Data(contentsOf: url))
    }

    static func data(fromHex hex: String) throws -> Data {
        var data = Data()
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<next], radix: 16) else { throw CocoaError(.coderInvalidValue) }
            data.append(byte)
            index = next
        }
        return data
    }

    static func hex(_ data: Data) -> String { data.map { String(format: "%02x", $0) }.joined() }
}
