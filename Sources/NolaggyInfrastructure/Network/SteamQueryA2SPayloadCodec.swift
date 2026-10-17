import Foundation
import NolaggyDomain

public enum SteamQueryA2SError: Error, Equatable, Sendable {
    case invalidLength
    case invalidHeader
    case unexpectedResponseType
    case invalidString
}

public struct SteamA2SInfo: Equatable, Sendable {
    public let name: String
    public let gameDirectory: String
    public let appID: UInt16
}

/// Codec puro para o protocolo Valve A2S_INFO (Steam Query) na porta 27015 UDP.
/// Gerencia a query inicial de handshake (25 bytes), decodificação de challenge (9 bytes),
/// montagem da query autenticada (29 bytes) e validação de resposta A2S_INFO ('I').
public enum SteamQueryA2SPayloadCodec {
    public static let unfragmentedHeader = Data([0xFF, 0xFF, 0xFF, 0xFF])
    public static let requestTypeA2SInfo: UInt8 = 0x54 // ASCII: 'T'
    public static let responseTypeChallenge: UInt8 = 0x41 // ASCII: 'A'
    public static let responseTypeInfo: UInt8 = 0x49 // ASCII: 'I'
    public static let queryPayloadString = "Source Engine Query\0".data(using: .ascii)!

    /// Codifica a query inicial unauthenticated A2S_INFO (25 bytes).
    public static func encodeInitialRequest() -> Data {
        var data = unfragmentedHeader
        data.append(requestTypeA2SInfo)
        data.append(queryPayloadString)
        return data
    }

    /// Decodifica o pacote S2C_CHALLENGE (mínimo 9 bytes) extraindo o challengeToken de 4 bytes em Little-Endian.
    public static func decodeChallenge(_ data: Data) throws -> UInt32 {
        guard data.count >= 9 else { throw SteamQueryA2SError.invalidLength }
        let s = data.startIndex
        guard data[s] == 0xFF, data[s + 1] == 0xFF, data[s + 2] == 0xFF, data[s + 3] == 0xFF else {
            throw SteamQueryA2SError.invalidHeader
        }
        guard data[s + 4] == responseTypeChallenge else {
            throw SteamQueryA2SError.unexpectedResponseType
        }

        let b0 = UInt32(data[s + 5])
        let b1 = UInt32(data[s + 6]) << 8
        let b2 = UInt32(data[s + 7]) << 16
        let b3 = UInt32(data[s + 8]) << 24
        return b0 | b1 | b2 | b3
    }

    /// Codifica a query autenticada A2S_INFO adicionando o challenge token de 4 bytes (Little-Endian)
    /// ao final da query de 25 bytes, totalizando 29 bytes.
    public static func encodeAuthenticatedRequest(challengeToken: UInt32) -> Data {
        var data = encodeInitialRequest()
        let b0 = UInt8(challengeToken & 0xFF)
        let b1 = UInt8((challengeToken >> 8) & 0xFF)
        let b2 = UInt8((challengeToken >> 16) & 0xFF)
        let b3 = UInt8((challengeToken >> 24) & 0xFF)
        data.append(contentsOf: [b0, b1, b2, b3])
        return data
    }

    /// Valida se o datagrama de resposta é um pacote A2S_INFO válido com cabeçalho 0xFFFFFFFF seguido de 'I' (0x49).
    public static func isValidInfoResponse(_ data: Data) -> Bool {
        guard data.count >= 5 else { return false }
        let s = data.startIndex
        guard data[s] == 0xFF, data[s + 1] == 0xFF, data[s + 2] == 0xFF, data[s + 3] == 0xFF else {
            return false
        }
        return data[s + 4] == responseTypeInfo
    }

    /// Lê somente os campos A2S_INFO necessários para confirmar que um
    /// candidato assinado é o servidor esperado. Não usa nome de mapa, slots
    /// ou qualquer detalhe como sinal de qualidade de rede.
    public static func decodeInfo(_ data: Data) throws -> SteamA2SInfo {
        guard isValidInfoResponse(data), data.count >= 6 else {
            throw SteamQueryA2SError.invalidHeader
        }
        var index = 6 // header, tipo 'I' e byte de versão do protocolo
        let name = try readCString(data, index: &index)
        _ = try readCString(data, index: &index) // mapa
        let directory = try readCString(data, index: &index)
        _ = try readCString(data, index: &index) // nome do jogo
        guard index + 2 <= data.endIndex else { throw SteamQueryA2SError.invalidLength }
        let appID = UInt16(data[index]) | (UInt16(data[index + 1]) << 8)
        return SteamA2SInfo(name: name, gameDirectory: directory, appID: appID)
    }

    private static func readCString(_ data: Data, index: inout Int) throws -> String {
        let start = index
        while index < data.endIndex, data[index] != 0 { index += 1 }
        guard index < data.endIndex,
              let value = String(data: data[start..<index], encoding: .utf8) else {
            throw SteamQueryA2SError.invalidString
        }
        index += 1
        return value
    }

    /// Verifica se o datagrama é um pacote S2C_CHALLENGE (0xFFFFFFFF seguido de 'A').
    public static func isChallengeResponse(_ data: Data) -> Bool {
        guard data.count >= 9 else { return false }
        let s = data.startIndex
        guard data[s] == 0xFF, data[s + 1] == 0xFF, data[s + 2] == 0xFF, data[s + 3] == 0xFF else {
            return false
        }
        return data[s + 4] == responseTypeChallenge
    }
}

/// Máquina pura da pré-validação de identidade (`steam-a2s-preflight-1`).
/// Não abre socket: recebe datagramas ou timeout e diz qual é o próximo passo.
/// Uma única troca de challenge é aceita; qualquer resposta ambígua, truncada
/// ou com identidade divergente rejeita a rota e devolve a medição à AWS.
public struct SteamA2SPreflightMachine: Sendable {
    public enum Step: Equatable, Sendable {
        case send(Data)
        case accept
        case reject
    }

    private enum Phase { case awaitingFirstResponse, awaitingInfoAfterChallenge, finished }

    private let identity: RemoteCatalogRouteIdentity
    private var phase: Phase = .awaitingFirstResponse

    public init(identity: RemoteCatalogRouteIdentity) {
        self.identity = identity
    }

    /// Primeiro datagrama a enviar: A2S_INFO sem challenge.
    public var initialRequest: Data { SteamQueryA2SPayloadCodec.encodeInitialRequest() }

    /// `nil` representa timeout ou falha de transporte.
    public mutating func receive(_ datagram: Data?) -> Step {
        guard let datagram, phase != .finished else { return finish(false) }
        if phase == .awaitingFirstResponse, SteamQueryA2SPayloadCodec.isChallengeResponse(datagram) {
            guard let token = try? SteamQueryA2SPayloadCodec.decodeChallenge(datagram) else { return finish(false) }
            phase = .awaitingInfoAfterChallenge
            return .send(SteamQueryA2SPayloadCodec.encodeAuthenticatedRequest(challengeToken: token))
        }
        guard let info = try? SteamQueryA2SPayloadCodec.decodeInfo(datagram) else { return finish(false) }
        let nameMatches = identity.expectedServerNamePrefix.map { info.name.hasPrefix($0) } ?? true
        return finish(info.appID == identity.expectedAppID
            && info.gameDirectory == identity.expectedGameDirectory
            && nameMatches)
    }

    private mutating func finish(_ accepted: Bool) -> Step {
        phase = .finished
        return accepted ? .accept : .reject
    }
}
