import XCTest
@testable import NolaggyInfrastructure

final class PlayFabQoSPayloadCodecTests: XCTestCase {
    private let sampleSessionID = UUID(uuidString: "00112233-4455-6677-8899-AABBCCDDEEFF")!
    private let sampleSequence: UInt32 = 0x0102_0304
    private let sampleNonce: UInt64 = 0x0102_0304_0506_0708
    private let sampleFlags: UInt8 = 0x00

    private var expectedEncodedBytes: [UInt8] {
        [
            0xFF, 0xFF, 0x50, 0x01,
            0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
            0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF,
            0x01, 0x02, 0x03, 0x04,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x00
        ]
    }

    private var expectedFlippedEchoBytes: [UInt8] {
        [
            0x00, 0x00, 0x50, 0x01,
            0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
            0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF,
            0x01, 0x02, 0x03, 0x04,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x00
        ]
    }

    func testEncodePlayFabPayloadMatchesExpected33Bytes() throws {
        let payload = PlayFabQoSPayload(
            sessionID: sampleSessionID,
            sequence: sampleSequence,
            nonce: sampleNonce,
            flags: sampleFlags
        )

        let encoded = PlayFabQoSPayloadCodec.encode(payload)

        XCTAssertEqual(encoded.count, 33)
        XCTAssertEqual(Array(encoded), expectedEncodedBytes)

        let decoded = try PlayFabQoSPayloadCodec.decode(encoded)
        XCTAssertEqual(decoded, payload)
    }

    func testValidatePlayFabEchoSucceedsWithFlippedZeroHeader() {
        let request = Data(expectedEncodedBytes)
        let validResponse = Data(expectedFlippedEchoBytes)

        XCTAssertTrue(PlayFabQoSPayloadCodec.isValidEcho(of: request, response: validResponse))
    }

    func testValidatePlayFabEchoFailsIfHeaderIsNotFlipped() {
        let request = Data(expectedEncodedBytes)

        // Exact reflection without bit-flip (0xFFFF header)
        XCTAssertFalse(PlayFabQoSPayloadCodec.isValidEcho(of: request, response: request))

        // Partial flip (0x00FF or 0xFF00)
        var partialFlip1 = expectedFlippedEchoBytes
        partialFlip1[0] = 0xFF
        XCTAssertFalse(PlayFabQoSPayloadCodec.isValidEcho(of: request, response: Data(partialFlip1)))

        var partialFlip2 = expectedFlippedEchoBytes
        partialFlip2[1] = 0xFF
        XCTAssertFalse(PlayFabQoSPayloadCodec.isValidEcho(of: request, response: Data(partialFlip2)))
    }

    func testValidatePlayFabEchoFailsIfPayloadBodyIsTampered() {
        let request = Data(expectedEncodedBytes)
        let validResponse = Data(expectedFlippedEchoBytes)

        // Tamper with sessionID (offset 4)
        var tamperedUUID = validResponse
        tamperedUUID[4] ^= 0x01
        XCTAssertFalse(PlayFabQoSPayloadCodec.isValidEcho(of: request, response: tamperedUUID))

        // Tamper with sequence (offset 20)
        var tamperedSequence = validResponse
        tamperedSequence[20] ^= 0xFF
        XCTAssertFalse(PlayFabQoSPayloadCodec.isValidEcho(of: request, response: tamperedSequence))

        // Tamper with nonce (offset 24)
        var tamperedNonce = validResponse
        tamperedNonce[24] ^= 0x42
        XCTAssertFalse(PlayFabQoSPayloadCodec.isValidEcho(of: request, response: tamperedNonce))

        // Tamper with flags (offset 32)
        var tamperedFlags = validResponse
        tamperedFlags[32] = 0x01
        XCTAssertFalse(PlayFabQoSPayloadCodec.isValidEcho(of: request, response: tamperedFlags))

        // Truncated response (32 bytes)
        XCTAssertFalse(PlayFabQoSPayloadCodec.isValidEcho(of: request, response: validResponse.dropLast()))

        // Extended response (34 bytes)
        var extended = validResponse
        extended.append(0x00)
        XCTAssertFalse(PlayFabQoSPayloadCodec.isValidEcho(of: request, response: extended))
    }
}
