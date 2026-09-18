import Foundation

/// Estado de integridade operacional de uma plataforma de console ou serviço parceiro.
public enum PlatformHealthStatus: Codable, Hashable, Sendable {
    case operational
    case degraded(summary: String)
    case majorOutage(summary: String)
    case unknown

    private enum CodingKeys: String, CodingKey {
        case type
        case summary
    }

    private enum StatusType: String, Codable {
        case operational
        case degraded
        case majorOutage
        case unknown
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(StatusType.self, forKey: .type)
        switch type {
        case .operational:
            self = .operational
        case .degraded:
            let summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
            self = .degraded(summary: summary)
        case .majorOutage:
            let summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
            self = .majorOutage(summary: summary)
        case .unknown:
            self = .unknown
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .operational:
            try container.encode(StatusType.operational, forKey: .type)
        case .degraded(let summary):
            try container.encode(StatusType.degraded, forKey: .type)
            try container.encode(summary, forKey: .summary)
        case .majorOutage(let summary):
            try container.encode(StatusType.majorOutage, forKey: .type)
            try container.encode(summary, forKey: .summary)
        case .unknown:
            try container.encode(StatusType.unknown, forKey: .type)
        }
    }
}

/// Diagnóstico pontual do status operacional da infraestrutura da plataforma.
public struct PlatformHealth: Codable, Hashable, Sendable {
    public let platform: Platform
    public let status: PlatformHealthStatus
    public let checkedAt: Date
    public let serviceName: String
    public let affectedServices: [String]
    public let details: String?

    public init(
        platform: Platform,
        status: PlatformHealthStatus,
        checkedAt: Date = Date(),
        serviceName: String,
        affectedServices: [String] = [],
        details: String? = nil
    ) {
        self.platform = platform
        self.status = status
        self.checkedAt = checkedAt
        self.serviceName = serviceName
        self.affectedServices = affectedServices
        self.details = details
    }

    public var isIssueReported: Bool {
        switch status {
        case .degraded, .majorOutage:
            return true
        case .operational, .unknown:
            return false
        }
    }

    /// Cria uma representação neutra operacional.
    public static func operational(for platform: Platform, serviceName: String) -> PlatformHealth {
        PlatformHealth(platform: platform, status: .operational, serviceName: serviceName)
    }

    /// Cria uma representação segura de falha de leitura (fail-open).
    public static func unknown(for platform: Platform, serviceName: String) -> PlatformHealth {
        PlatformHealth(platform: platform, status: .unknown, serviceName: serviceName)
    }
}

/// Contrato agnóstico de porta para obtenção de status de plataformas.
public protocol PlatformHealthProvider: Sendable {
    func checkHealth(for platform: Platform, market: String) async -> PlatformHealth
}
