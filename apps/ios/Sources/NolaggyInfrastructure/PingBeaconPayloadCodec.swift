import Foundation

public enum PingBeaconPayloadError: Error, Equatable, Sendable {
    case invalidLength
    case invalidMagic
    case unsupportedVersion
}

/// Contrato binário do beacon do piloto. A correlação exige igualdade integral dos 33 bytes.
public struct PingBeaconPayload: Equatable, Sendable {
    public static let magic = Data([0x4E, 0x4C, 0x50, 0x47]) // NLPG
    public static let version: UInt8 = 0x01
    public static let byteCount = 33

    public let sessionID: UUID
    public let sequence: UInt32
    public let nonce: UInt64

    public init(sessionID: UUID, sequence: UInt32, nonce: UInt64) {
        self.sessionID = sessionID
        self.sequence = sequence
        self.nonce = nonce
    }
}

public enum PingBeaconPayloadCodec {
    public static func encode(_ payload: PingBeaconPayload) -> Data {
        var data = PingBeaconPayload.magic
        data.append(PingBeaconPayload.version)
        var uuid = payload.sessionID.uuid
        withUnsafeBytes(of: &uuid) { data.append(contentsOf: $0) }
        appendBigEndian(payload.sequence, to: &data)
        appendBigEndian(payload.nonce, to: &data)
        return data
    }

    public static func decode(_ data: Data) throws -> PingBeaconPayload {
        guard data.count == PingBeaconPayload.byteCount else { throw PingBeaconPayloadError.invalidLength }
        guard data.prefix(4) == PingBeaconPayload.magic else { throw PingBeaconPayloadError.invalidMagic }
        guard data[4] == PingBeaconPayload.version else { throw PingBeaconPayloadError.unsupportedVersion }

        let uuidBytes = Array(data[5..<21])
        let uuid = UUID(uuid: (
            uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
            uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
            uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
            uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]
        ))
        return PingBeaconPayload(
            sessionID: uuid,
            sequence: readUInt32(data, at: 21),
            nonce: readUInt64(data, at: 25)
        )
    }

    public static func isExactEcho(of payload: Data, response: Data) -> Bool {
        payload.count == PingBeaconPayload.byteCount && response == payload
    }

    private static func appendBigEndian<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var bigEndian = value.bigEndian
        withUnsafeBytes(of: &bigEndian) { data.append(contentsOf: $0) }
    }

    private static func readUInt32(_ data: Data, at offset: Int) -> UInt32 {
        data[offset..<(offset + 4)].reduce(0) { ($0 << 8) | UInt32($1) }
    }

    private static func readUInt64(_ data: Data, at offset: Int) -> UInt64 {
        data[offset..<(offset + 8)].reduce(0) { ($0 << 8) | UInt64($1) }
    }
}
