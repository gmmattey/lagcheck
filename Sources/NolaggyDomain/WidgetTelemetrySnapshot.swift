import Foundation

/// Snapshot serializável e autocontido da telemetria de rota para consumo em Widgets (iOS 17+).
/// Gravado via App Group ("group.com.lagcheck.app") pela aplicação principal.
/// Decisão 75 (Fase 2 / Item 6): "Zero Mock" / "Nunca uma Nota Inventada".
public struct WidgetTelemetrySnapshot: Codable, Equatable, Sendable {
    public let gameID: String
    public let gameName: String
    public let regionLabel: String
    public let verdict: GameReadinessVerdict
    public let rttMedianMs: Double
    public let jitterMs: Double
    public let packetLossPercentage: Double
    public let bufferbloatGrade: String?
    /// Contexto originalmente medido. Campos opcionais preservam snapshots de versões anteriores.
    public let platformRawValue: String?
    public let declaredExternalLinkRawValue: String?
    public let capturedAt: Date

    public init(
        gameID: String,
        gameName: String,
        regionLabel: String,
        verdict: GameReadinessVerdict,
        rttMedianMs: Double,
        jitterMs: Double,
        packetLossPercentage: Double,
        bufferbloatGrade: String? = nil,
        platform: Platform? = nil,
        declaredExternalLink: ExternalEquipmentLink? = nil,
        capturedAt: Date = Date()
    ) {
        self.gameID = gameID
        self.gameName = gameName
        self.regionLabel = regionLabel
        self.verdict = verdict
        self.rttMedianMs = rttMedianMs
        self.jitterMs = jitterMs
        self.packetLossPercentage = packetLossPercentage
        self.bufferbloatGrade = bufferbloatGrade
        self.platformRawValue = platform?.rawValue
        self.declaredExternalLinkRawValue = declaredExternalLink?.rawValue
        self.capturedAt = capturedAt
    }

    public var platform: Platform? { platformRawValue.flatMap(Platform.init(rawValue:)) }
    public var declaredExternalLink: ExternalEquipmentLink? {
        declaredExternalLinkRawValue.flatMap(ExternalEquipmentLink.init(rawValue:))
    }

    /// Avalia se a medição ainda é fresca para fins competitivos (TTL = 4 horas).
    public func isFresh(referenceDate: Date = Date()) -> Bool {
        referenceDate.timeIntervalSince(capturedAt) < 14400 // 4 horas
    }
}
