import Foundation

public enum Platform: String, Codable, CaseIterable, Hashable, Sendable {
    case iphone
    case playstation
    case xbox
    case pc
    case nintendo

    public var displayName: String {
        switch self {
        case .iphone: return "iPhone"
        case .playstation: return "PlayStation"
        case .xbox: return "Xbox"
        case .pc: return "PC"
        case .nintendo: return "Nintendo Switch"
        }
    }
}

public enum NetworkKind: String, Codable, CaseIterable, Hashable, Sendable {
    case wifi
    case cellular
    case other
}

/// Forma declarada de ligação de um equipamento externo à rede local.
/// Não descreve a interface observada no iPhone durante a medição.
public enum ExternalEquipmentLink: String, Codable, CaseIterable, Hashable, Sendable {
    case wifi
    case ethernet
}

/// Contexto imutável que será resolvido contra um catálogo validado antes de qualquer medição.
public struct GameContext: Codable, Hashable, Sendable {
    public let gameID: String
    public let market: String
    public let platform: Platform
    /// Declaração da pessoa sobre um console, PC ou Switch. iPhone não tem este fato.
    public let declaredExternalLink: ExternalEquipmentLink?

    public init(
        gameID: String,
        market: String,
        platform: Platform,
        declaredExternalLink: ExternalEquipmentLink? = nil
    ) {
        self.gameID = gameID
        self.market = market
        self.platform = platform
        self.declaredExternalLink = declaredExternalLink
    }

    /// Valida invariantes do pedido antes de ele ser comparado com um catálogo.
    /// O catálogo continua sendo a autoridade para disponibilidade de jogo, mercado e alvo.
    public func validateStructure() throws {
        guard !gameID.isEmpty, gameID == gameID.lowercased() else {
            throw CatalogValidationError.invalidGameID
        }
        guard market.count == 2, market == market.uppercased(), market.allSatisfy(\.isLetter) else {
            throw CatalogValidationError.invalidMarket
        }
        guard platform != .iphone || declaredExternalLink == nil else {
            throw CatalogValidationError.externalEquipmentLinkNotApplicable
        }
    }
}
