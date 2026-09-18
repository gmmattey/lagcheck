import Foundation

/// Fonte oficial e auditável de avaliação crítica ou pública do jogo.
public enum EditorialRatingSource: String, Codable, CaseIterable, Hashable, Sendable {
    case metacriticCritic = "metacritic_critic"
    case metacriticUser = "metacritic_user"
    case openCritic = "opencritic"
    case appStore = "app_store"
    case steam = "steam"

    public var displayName: String {
        switch self {
        case .metacriticCritic: return "Metacritic"
        case .metacriticUser: return "Metacritic User"
        case .openCritic: return "OpenCritic"
        case .appStore: return "App Store"
        case .steam: return "Steam"
        }
    }
}

/// Avaliação oficial auditada vinculada a uma fonte verificável.
public struct EditorialRating: Codable, Hashable, Sendable {
    public let source: EditorialRatingSource
    public let score: Double
    public let scale: Double
    public let reviewCount: Int?
    public let referenceURL: String

    public init(
        source: EditorialRatingSource,
        score: Double,
        scale: Double,
        reviewCount: Int? = nil,
        referenceURL: String
    ) {
        self.source = source
        self.score = score
        self.scale = scale
        self.reviewCount = reviewCount
        self.referenceURL = referenceURL
    }

    /// Texto formatado amigável da pontuação (ex: "83/100" ou "4.7 ★").
    public var formattedScore: String {
        if scale == 5.0 {
            return String(format: "%.1f ★", score)
        } else if scale == 100.0 && source == .steam {
            return "\(Int(score))%"
        } else {
            return "\(Int(score))"
        }
    }
}

/// Requisito técnico de hardware e sistema para uma plataforma específica.
public struct PlatformRequirement: Codable, Hashable, Sendable {
    public let platform: Platform
    public let minimumOS: String
    public let storageBytes: Int64
    public let memoryRAMBytes: Int64
    public let targetFramerate: Int?

    public init(
        platform: Platform,
        minimumOS: String,
        storageBytes: Int64,
        memoryRAMBytes: Int64,
        targetFramerate: Int? = 60
    ) {
        self.platform = platform
        self.minimumOS = minimumOS
        self.storageBytes = storageBytes
        self.memoryRAMBytes = memoryRAMBytes
        self.targetFramerate = targetFramerate
    }

    /// Tamanho formatado de armazenamento em GB aproximado (ex: "18 GB").
    public var formattedStorage: String {
        let gb = Double(storageBytes) / 1_000_000_000.0
        return gb >= 1.0 ? String(format: "%.0f GB", gb) : String(format: "%.1f GB", gb)
    }

    /// Memória RAM formatada em GB (ex: "3 GB RAM").
    public var formattedRAM: String {
        let gb = Double(memoryRAMBytes) / 1_000_000_000.0
        return String(format: "%.0f GB RAM", gb)
    }
}

/// Demanda e tolerância de rede recomendadas para jogabilidade ótima e competitiva.
public struct GameNetworkDemands: Codable, Hashable, Sendable {
    public let minDownloadMbps: Double
    public let minUploadMbps: Double
    public let optimalPingMs: Double
    public let acceptablePingMs: Double
    public let maxJitterMs: Double
    public let packetLossTolerancePct: Double

    public init(
        minDownloadMbps: Double,
        minUploadMbps: Double,
        optimalPingMs: Double,
        acceptablePingMs: Double,
        maxJitterMs: Double,
        packetLossTolerancePct: Double
    ) {
        self.minDownloadMbps = minDownloadMbps
        self.minUploadMbps = minUploadMbps
        self.optimalPingMs = optimalPingMs
        self.acceptablePingMs = acceptablePingMs
        self.maxJitterMs = maxJitterMs
        self.packetLossTolerancePct = packetLossTolerancePct
    }

    public static let standardCompetitive = GameNetworkDemands(
        minDownloadMbps: 5.0,
        minUploadMbps: 1.0,
        optimalPingMs: 40.0,
        acceptablePingMs: 70.0,
        maxJitterMs: 5.0,
        packetLossTolerancePct: 0.0
    )
}

/// Metadados editoriais oficiais sem alucinação de dados (Decisão 31).
public struct RemoteCatalogGameEditorial: Codable, Hashable, Sendable {
    public let summary: [String: String]
    public let publisher: String
    public let releaseYear: Int
    public let ageRating: String
    public let ratings: [EditorialRating]
    public let requirements: [PlatformRequirement]
    public let networkDemands: GameNetworkDemands

    public init(
        summary: [String: String],
        publisher: String,
        releaseYear: Int,
        ageRating: String,
        ratings: [EditorialRating],
        requirements: [PlatformRequirement],
        networkDemands: GameNetworkDemands
    ) {
        self.summary = summary
        self.publisher = publisher
        self.releaseYear = releaseYear
        self.ageRating = ageRating
        self.ratings = ratings
        self.requirements = requirements
        self.networkDemands = networkDemands
    }

    /// Retorna o resumo localizado para o idioma solicitado ou fallback para inglês/primeiro disponível.
    public func localizedSummary(localeIdentifier: String = "pt-BR") -> String {
        if let text = summary[localeIdentifier] {
            return text
        }
        if localeIdentifier.starts(with: "pt"), let pt = summary["pt-BR"] {
            return pt
        }
        return summary["en"] ?? summary.values.first ?? ""
    }

    /// Requisito específico para a plataforma do jogador.
    public func requirement(for platform: Platform) -> PlatformRequirement? {
        requirements.first(where: { $0.platform == platform }) ?? requirements.first
    }
}
