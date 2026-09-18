import Foundation

/// Codificador e decodificador de datagramas binários do protocolo STUN (RFC 5389 / RFC 8489).
/// Utilizado para descoberta determinística de IP público, porta externa e topologia de NAT.
public enum StunPacketCodec {
    public static let magicCookie: UInt32 = 0x2112A442
    public static let bindingRequestType: UInt16 = 0x0001
    public static let bindingResponseType: UInt16 = 0x0101
    public static let attrXorMappedAddress: UInt16 = 0x0020
    public static let attrMappedAddress: UInt16 = 0x0001

    public struct StunBindingResult: Equatable, Sendable {
        public let publicIP: String
        public let externalPort: UInt16
    }

    /// Constrói um datagrama de STUN Binding Request conforme RFC 5389 (20 bytes).
    public static func buildBindingRequest(transactionID: Data? = nil) -> (packet: Data, transactionID: Data) {
        var packet = Data(capacity: 20)

        // 1. STUN Message Type: 0x0001 (Binding Request)
        var msgType = bindingRequestType.bigEndian
        packet.append(Data(bytes: &msgType, count: 2))

        // 2. Message Length: 0x0000 (Sem atributos no request)
        var length: UInt16 = 0
        packet.append(Data(bytes: &length, count: 2))

        // 3. Magic Cookie: 0x2112A442
        var cookie = magicCookie.bigEndian
        packet.append(Data(bytes: &cookie, count: 4))

        // 4. Transaction ID: 12 bytes
        let txID: Data
        if let transactionID, transactionID.count == 12 {
            txID = transactionID
        } else {
            var randomBytes = [UInt8](repeating: 0, count: 12)
            _ = SecRandomCopyBytes(kSecRandomDefault, 12, &randomBytes)
            txID = Data(randomBytes)
        }
        packet.append(txID)

        return (packet, txID)
    }

    /// Decodifica a resposta STUN e extrai o IP público e a porta externa mapeada.
    public static func parseBindingResponse(data: Data, expectedTransactionID: Data? = nil) -> StunBindingResult? {
        guard data.count >= 20 else { return nil }

        let msgType = data.prefix(2).withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
        guard msgType == bindingResponseType else { return nil }

        let msgLength = Int(data.subdata(in: 2..<4).withUnsafeBytes { $0.load(as: UInt16.self).bigEndian })
        let cookie = data.subdata(in: 4..<8).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        guard cookie == magicCookie else { return nil }

        let txID = data.subdata(in: 8..<20)
        if let expectedTransactionID {
            guard txID == expectedTransactionID else { return nil }
        }

        guard data.count >= 20 + msgLength else { return nil }

        var offset = 20
        while offset + 4 <= 20 + msgLength {
            let attrType = data.subdata(in: offset..<offset+2).withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
            let attrLen = Int(data.subdata(in: offset+2..<offset+4).withUnsafeBytes { $0.load(as: UInt16.self).bigEndian })
            offset += 4

            if offset + attrLen > data.count { break }

            if attrType == attrXorMappedAddress && attrLen >= 8 {
                let attrData = data.subdata(in: offset..<offset+attrLen)
                let family = attrData[1]
                if family == 0x01 { // IPv4
                    let xorPort = attrData.subdata(in: 2..<4).withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
                    let port = xorPort ^ UInt16((magicCookie >> 16) & 0xFFFF)

                    let xorIP = attrData.subdata(in: 4..<8).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
                    let ipInt = xorIP ^ magicCookie

                    let ipString = "\(UInt8((ipInt >> 24) & 0xFF)).\(UInt8((ipInt >> 16) & 0xFF)).\(UInt8((ipInt >> 8) & 0xFF)).\(UInt8(ipInt & 0xFF))"
                    return StunBindingResult(publicIP: ipString, externalPort: port)
                }
            } else if attrType == attrMappedAddress && attrLen >= 8 {
                let attrData = data.subdata(in: offset..<offset+attrLen)
                let family = attrData[1]
                if family == 0x01 { // IPv4
                    let port = attrData.subdata(in: 2..<4).withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
                    let ipInt = attrData.subdata(in: 4..<8).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
                    let ipString = "\(UInt8((ipInt >> 24) & 0xFF)).\(UInt8((ipInt >> 16) & 0xFF)).\(UInt8((ipInt >> 8) & 0xFF)).\(UInt8(ipInt & 0xFF))"
                    return StunBindingResult(publicIP: ipString, externalPort: port)
                }
            }

            // Alinhamento STUN para múltiplos de 4 bytes
            let padding = (4 - (attrLen % 4)) % 4
            offset += attrLen + padding
        }

        return nil
    }
}
