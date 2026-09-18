import Foundation
import NolaggyDomain

/// Categoria da ação recomendada de melhoria de rede
public enum BoosterActionCategory: String, Codable, Sendable, CaseIterable {
    case routerEquipment = "router_equipment"
    case platformSystem = "platform_system"
    case ispConnection = "isp_connection"
    
    public var iconName: String {
        switch self {
        case .routerEquipment:
            return "wifi.router"
        case .platformSystem:
            return "tv.and.mediabox"
        case .ispConnection:
            return "network"
        }
    }
    
    public var titleKey: String {
        switch self {
        case .routerEquipment:
            return "booster.category.router"
        case .platformSystem:
            return "booster.category.platform"
        case .ispConnection:
            return "booster.category.isp"
        }
    }
}

/// Item de ação sugerido ao jogador
public struct BoosterActionItem: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let category: BoosterActionCategory
    public let title: String
    public let detail: String
    
    public init(id: String = UUID().uuidString, category: BoosterActionCategory, title: String, detail: String) {
        self.id = id
        self.category = category
        self.title = title
        self.detail = detail
    }
}

/// Dados medidos no Deep Check para alimentar a consulta do Gemini
public struct ConnectionBoosterRequest: Sendable {
    public let gameName: String
    public let platform: Platform
    public let networkKind: NetworkKind
    public let p50Milliseconds: Double
    public let jitterMilliseconds: Double
    public let packetLossRate: Double
    public let loadImpactMilliseconds: Double?
    public let wifiBandEstimate: WiFiBandDiagnostic?
    public let locale: String
    
    public init(
        gameName: String,
        platform: Platform,
        networkKind: NetworkKind,
        p50Milliseconds: Double,
        jitterMilliseconds: Double,
        packetLossRate: Double,
        loadImpactMilliseconds: Double?,
        wifiBandEstimate: WiFiBandDiagnostic? = nil,
        locale: String = Locale.current.identifier
    ) {
        self.gameName = gameName
        self.platform = platform
        self.networkKind = networkKind
        self.p50Milliseconds = p50Milliseconds
        self.jitterMilliseconds = jitterMilliseconds
        self.packetLossRate = packetLossRate
        self.loadImpactMilliseconds = loadImpactMilliseconds
        self.wifiBandEstimate = wifiBandEstimate
        self.locale = locale
    }
}

/// Recomendações consolidadas para o usuário
public struct ConnectionBoosterAdvice: Sendable, Equatable {
    public let gameName: String
    public let platform: Platform
    public let summary: String
    public let items: [BoosterActionItem]
    
    public init(gameName: String, platform: Platform, summary: String, items: [BoosterActionItem]) {
        self.gameName = gameName
        self.platform = platform
        self.summary = summary
        self.items = items
    }
}

/// Protocolo abstrato de serviço para obtenção de dicas
public protocol ConnectionBoosterService: Sendable {
    func fetchAdvice(for request: ConnectionBoosterRequest) async throws -> ConnectionBoosterAdvice
}
