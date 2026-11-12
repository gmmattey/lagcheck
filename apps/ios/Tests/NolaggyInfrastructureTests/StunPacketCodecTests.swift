import XCTest
@testable import NolaggyInfrastructure

final class StunPacketCodecTests: XCTestCase {

    func testBuildBindingRequestHasExact20Bytes() {
        let (packet, txID) = StunPacketCodec.buildBindingRequest()

        XCTAssertEqual(packet.count, 20)
        XCTAssertEqual(txID.count, 12)

        // Type: 0x0001
        let msgType = packet.prefix(2).withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
        XCTAssertEqual(msgType, 0x0001)

        // Length: 0x0000
        let msgLen = packet.subdata(in: 2..<4).withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
        XCTAssertEqual(msgLen, 0)

        // Magic Cookie: 0x2112A442
        let cookie = packet.subdata(in: 4..<8).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        XCTAssertEqual(cookie, 0x2112A442)

        // Transaction ID
        let txSub = packet.subdata(in: 8..<20)
        XCTAssertEqual(txSub, txID)
    }

    func testParseBindingResponseWithXorMappedAddress() {
        let txID = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C])
        
        // Monta resposta simulada de servidor STUN (RFC 5389)
        // IP público real: 177.136.25.10
        // Porta real: 54321
        var response = Data()
        var msgType = UInt16(0x0101).bigEndian
        response.append(Data(bytes: &msgType, count: 2))

        var attrTotalLen = UInt16(12).bigEndian
        response.append(Data(bytes: &attrTotalLen, count: 2))

        var cookie = UInt32(0x2112A442).bigEndian
        response.append(Data(bytes: &cookie, count: 4))
        response.append(txID)

        // Atributo XOR-MAPPED-ADDRESS (Type 0x0020, Len 8)
        var attrType = UInt16(0x0020).bigEndian
        response.append(Data(bytes: &attrType, count: 2))
        var attrLen = UInt16(8).bigEndian
        response.append(Data(bytes: &attrLen, count: 2))

        response.append(0x00) // Reserved
        response.append(0x01) // Family IPv4

        var xorPort = UInt16(54321 ^ 0x2112).bigEndian
        response.append(Data(bytes: &xorPort, count: 2))

        let originalIPInt: UInt32 = (177 << 24) | (136 << 16) | (25 << 8) | 10
        var xorIP = UInt32(originalIPInt ^ 0x2112A442).bigEndian
        response.append(Data(bytes: &xorIP, count: 4))

        let result = StunPacketCodec.parseBindingResponse(data: response, expectedTransactionID: txID)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.publicIP, "177.136.25.10")
        XCTAssertEqual(result?.externalPort, 54321)
    }

    func testParseRejectsMismatchedTransactionID() {
        let (request, _) = StunPacketCodec.buildBindingRequest()
        let wrongTxID = Data([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])

        var response = request
        response[0] = 0x01
        response[1] = 0x01

        let result = StunPacketCodec.parseBindingResponse(data: response, expectedTransactionID: wrongTxID)
        XCTAssertNil(result)
    }
}
