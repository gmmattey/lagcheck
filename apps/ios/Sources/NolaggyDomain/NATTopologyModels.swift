import Foundation

/// Classificação do tipo de NAT para experiência em jogos multiplayer (Decisão 32).
public enum NATType: String, Codable, CaseIterable, Hashable, Sendable {
    case type1Open = "type_1_open"
    case type2Moderate = "type_2_moderate"
    case type3Strict = "type_3_strict"
    case inconclusive = "inconclusive"

    public var titleKey: String {
        switch self {
        case .type1Open: return "nat.type1.open.title"
        case .type2Moderate: return "nat.type2.moderate.title"
        case .type3Strict: return "nat.type3.strict.title"
        case .inconclusive: return "nat.inconclusive.title"
        }
    }

    public var shortLabel: String {
        switch self {
        case .type1Open: return "Type 1 (Open)"
        case .type2Moderate: return "Type 2 (Moderate)"
        case .type3Strict: return "Type 3 (Strict)"
        case .inconclusive: return "Inconclusive"
        }
    }

    public var isMultiplayerRestricted: Bool {
        self == .type3Strict
    }
}

/// Estado de detecção de Carrier-Grade NAT (RFC 6598 - 100.64.0.0/10).
public enum CGNATStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case notDetected = "not_detected"
    case detected = "detected"
    case inconclusive = "inconclusive"

    public var isImpacted: Bool {
        self == .detected
    }
}

/// Estado de detecção de NAT Duplo na rede local (múltiplos roteadores encadeados).
public enum DoubleNATStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case notDetected = "not_detected"
    case suspectOrDetected = "suspect_detected"
    case inconclusive = "inconclusive"

    public var isImpacted: Bool {
        self == .suspectOrDetected
    }
}

/// Snapshot imutável da topologia de rede aferida via STUN RFC 5389.
public struct NATTopologySnapshot: Codable, Hashable, Sendable {
    public let natType: NATType
    public let cgnatStatus: CGNATStatus
    public let doubleNATStatus: DoubleNATStatus
    public let publicIPMasked: String?
    public let localIPMasked: String?
    public let externalPort: UInt16?
    public let serverHost: String
    public let checkedAt: Date
    public let publicIP: String?

    public init(
        natType: NATType,
        cgnatStatus: CGNATStatus,
        doubleNATStatus: DoubleNATStatus,
        publicIPMasked: String? = nil,
        localIPMasked: String? = nil,
        externalPort: UInt16? = nil,
        serverHost: String = "stun.l.google.com",
        checkedAt: Date = Date(),
        publicIP: String? = nil
    ) {
        self.natType = natType
        self.cgnatStatus = cgnatStatus
        self.doubleNATStatus = doubleNATStatus
        self.publicIPMasked = publicIPMasked
        self.localIPMasked = localIPMasked
        self.externalPort = externalPort
        self.serverHost = serverHost
        self.checkedAt = checkedAt
        self.publicIP = publicIP
    }

    public static let inconclusive = NATTopologySnapshot(
        natType: .inconclusive,
        cgnatStatus: .inconclusive,
        doubleNATStatus: .inconclusive
    )

    /// Os estados legados não são evidência suficiente para afetar compatibilidade,
    /// recomendações ou UPnP. A sondagem iOS fica inconclusiva até haver método
    /// validado de topologia e alcançabilidade.
    public var hasAnyMultiplayerIssue: Bool {
        false
    }
}

/// Avaliador determinístico da topologia de NAT.
public enum NATTopologyEvaluator {

    /// Não classifica topologia a partir de respostas STUN isoladas.
    ///
    /// O IP e a porta observados por um servidor não demonstram se o cliente está
    /// aberto, moderado ou restrito, nem descartam CGNAT ou NAT duplo. Mantemos a
    /// API para leitura de históricos, mas toda nova avaliação é inconclusiva.
    public static func evaluate(
        localIP: String?,
        publicIP: String?,
        externalPort: UInt16?,
        isPortMappingConsistent: Bool = true,
        detectedDoubleHop: Bool = false
    ) -> NATTopologySnapshot {
        _ = (localIP, publicIP, externalPort, isPortMappingConsistent, detectedDoubleHop)
        return .inconclusive
    }

    /// Verifica se o endereço IPv4 está dentro do bloco IANA reservado para CGNAT (100.64.0.0/10).
    /// Faixa: 100.64.0.0 a 100.127.255.255.
    public static func isRFC6598CGNAT(ip: String) -> Bool {
        let parts = ip.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 4 else { return false }
        return parts[0] == 100 && (parts[1] >= 64 && parts[1] <= 127)
    }

    /// Mascara o endereço IP preservando apenas o primeiro e segundo octetos para privacidade.
    public static func maskIP(_ ip: String) -> String {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return "***.***.***.***" }
        return "\(parts[0]).\(parts[1]).***.***"
    }
}
