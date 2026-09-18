import Foundation

public enum PlayFabQoSPayloadError: Error, Equatable, Sendable {
    case invalidLength
    case invalidHeader
    case invalidMagic
    case unsupportedVersion
}

/// Contrato binário do probe Azure PlayFab QoS (33 bytes).
/// Exige cabeçalho 0xFFFF na requisição e valida a resposta com bit-flip para 0x0000.
public struct PlayFabQoSPayload: Equatable, Sendable {
    public static let header = Data([0xFF, 0xFF])
    public static let flippedHeader = Data([0x00, 0x00])
    public static let magic: UInt8 = 0x50 // ASCII: 'P'
    public static let version: UInt8 = 0x01
    public static let byteCount = 33

    public let sessionID: UUID
    public let sequence: UInt32
    public let nonce: UInt64
    public let flags: UInt8

    public init(sessionID: UUID, sequence: UInt32, nonce: UInt64, flags: UInt8 = 0x00) {
        self.sessionID = sessionID
        self.sequence = sequence
        self.nonce = nonce
        self.flags = flags
    }
}

public enum PlayFabQoSPayloadCodec {
    public static func encode(_ payload: PlayFabQoSPayload) -> Data {
        var data = PlayFabQoSPayload.header
        data.append(PlayFabQoSPayload.magic)
        data.append(PlayFabQoSPayload.version)
        var uuid = payload.sessionID.uuid
        withUnsafeBytes(of: &uuid) { data.append(contentsOf: $0) }
        appendBigEndian(payload.sequence, to: &data)
        appendBigEndian(payload.nonce, to: &data)
        data.append(payload.flags)
        return data
    }

    public static func decode(_ data: Data) throws -> PlayFabQoSPayload {
        guard data.count == PlayFabQoSPayload.byteCount else { throw PlayFabQoSPayloadError.invalidLength }
        let s = data.startIndex
        guard data[s] == 0xFF && data[s + 1] == 0xFF else { throw PlayFabQoSPayloadError.invalidHeader }
        guard data[s + 2] == PlayFabQoSPayload.magic else { throw PlayFabQoSPayloadError.invalidMagic }
        guard data[s + 3] == PlayFabQoSPayload.version else { throw PlayFabQoSPayloadError.unsupportedVersion }

        let uuidBytes = Array(data[(s + 4)..<(s + 20)])
        let uuid = UUID(uuid: (
            uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
            uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
            uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
            uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]
        ))
        return PlayFabQoSPayload(
            sessionID: uuid,
            sequence: readUInt32(data, at: s + 20),
            nonce: readUInt64(data, at: s + 24),
            flags: data[s + 32]
        )
    }

    /// Valida se a resposta do Azure PlayFab QoS é um eco válido:
    /// 1. Contagem idêntica (33 bytes).
    /// 2. Primeiros 2 bytes invertidos para 0x0000.
    /// 3. Sufixo dos 31 bytes restantes idêntico ao transmitido.
    public static func isValidEcho(of request: Data, response: Data) -> Bool {
        guard request.count == PlayFabQoSPayload.byteCount,
              response.count == PlayFabQoSPayload.byteCount else {
            return false
        }
        let r = response.startIndex
        guard response[r] == 0x00, response[r + 1] == 0x00 else {
            return false
        }
        return response.dropFirst(2) == request.dropFirst(2)
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
