import XCTest
@testable import NolaggyInfrastructure

final class PingBeaconPayloadCodecTests: XCTestCase {
    func testEncodesTheDocumented33ByteBigEndianPayload() throws {
        let payload = PingBeaconPayload(
            sessionID: UUID(uuidString: "00112233-4455-6677-8899-AABBCCDDEEFF")!,
            sequence: 0x0102_0304,
            nonce: 0x0102_0304_0506_0708
        )

        let encoded = PingBeaconPayloadCodec.encode(payload)

        XCTAssertEqual(encoded.count, 33)
        XCTAssertEqual(
            Array(encoded),
            [
                0x4E, 0x4C, 0x50, 0x47, 0x01,
                0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
                0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF,
                0x01, 0x02, 0x03, 0x04,
                0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08
            ]
        )
        XCTAssertEqual(try PingBeaconPayloadCodec.decode(encoded), payload)
    }

    func testRejectsMalformedPayloadsAndRequiresAnExactEcho() throws {
        let payload = PingBeaconPayload(sessionID: UUID(), sequence: 3, nonce: 7)
        let encoded = PingBeaconPayloadCodec.encode(payload)
        var different = encoded
        different[different.startIndex] = 0

        XCTAssertThrowsError(try PingBeaconPayloadCodec.decode(Data(encoded.dropLast()))) { error in
            XCTAssertEqual(error as? PingBeaconPayloadError, .invalidLength)
        }
        XCTAssertThrowsError(try PingBeaconPayloadCodec.decode(different)) { error in
            XCTAssertEqual(error as? PingBeaconPayloadError, .invalidMagic)
        }
        XCTAssertTrue(PingBeaconPayloadCodec.isExactEcho(of: encoded, response: encoded))
        XCTAssertFalse(PingBeaconPayloadCodec.isExactEcho(of: encoded, response: different))
    }
}
