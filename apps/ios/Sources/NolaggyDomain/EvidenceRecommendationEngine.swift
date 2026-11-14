import Foundation
@preconcurrency import LagCheckEngine

/// Arquitetura de rede do jogo para contextualização de topologia NAT (Decisão 55).
public enum GameServerArchitecture: String, Codable, CaseIterable, Hashable, Sendable {
    case dedicatedServer
    case peerToPeer
    case hybrid
}

/// Recomendação acionável e fundamentada por evidência diagnóstica real (Decisão 55).
public struct ActionableRecommendation: Codable, Equatable, Hashable, Sendable {
    public let priority: Int
    public let title: String
    public let instruction: String
    public let evidenceBadge: String?

    public init(priority: Int, title: String, instruction: String, evidenceBadge: String? = nil) {
        self.priority = priority
        self.title = title
        self.instruction = instruction
        self.evidenceBadge = evidenceBadge
    }
}

/// Evidência agregada observada para alimentar o motor de recomendações (Decisão 55).
public struct DiagnosticEvidence: Equatable, Sendable {
    public let gatewayOutcome: GatewayProbeOutcome
    public let wifiBand: WiFiBandDiagnostic?
    public let wifiBandConfidence: WiFiBandAssessmentConfidence?
    public let loadTier: LoadDegradationTier?
    public let packetLossPercentage: Double
    public let spikePattern: SpikePattern?
    public let tailRatio: Double?
    public let natType: NATType?
    public let serverArchitecture: GameServerArchitecture
    public let outOfOrderCount: Int

    public init(
        gatewayOutcome: GatewayProbeOutcome = .unobservable,
        wifiBand: WiFiBandDiagnostic? = nil,
        wifiBandConfidence: WiFiBandAssessmentConfidence? = nil,
        loadTier: LoadDegradationTier? = nil,
        packetLossPercentage: Double = 0.0,
        spikePattern: SpikePattern? = nil,
        tailRatio: Double? = nil,
        natType: NATType? = nil,
        serverArchitecture: GameServerArchitecture = .dedicatedServer,
        outOfOrderCount: Int = 0
    ) {
        self.gatewayOutcome = gatewayOutcome
        self.wifiBand = wifiBand
        self.wifiBandConfidence = wifiBandConfidence
        self.loadTier = loadTier
        self.packetLossPercentage = packetLossPercentage
        self.spikePattern = spikePattern
        self.tailRatio = tailRatio
        self.natType = natType
        self.serverArchitecture = serverArchitecture
        self.outOfOrderCount = outOfOrderCount
    }
}

/// Motor determinístico que gera de 1 a 3 recomendações diretamente ligadas às evidências comprovadas via motor KMP.
public enum EvidenceRecommendationEngine {
    public static func generateRecommendations(evidence: DiagnosticEvidence) -> [ActionableRecommendation] {
        var recKeys: [String] = []

        if evidence.gatewayOutcome.isDegraded {
            recKeys.append("APPROACH_ROUTER")
        }

        if let band = evidence.wifiBand, band.isSuspectOrConfirmed24GHz,
           (evidence.wifiBandConfidence == .high || evidence.wifiBandConfidence == .medium) {
            recKeys.append("SWITCH_TO_5GHZ")
        }

        if evidence.packetLossPercentage > 1.0 && !evidence.gatewayOutcome.isDegraded {
            recKeys.append("AVOID_RANKED")
        }

        if evidence.loadTier == .material || evidence.loadTier == .severe {
            recKeys.append("PAUSE_DOWNLOADS")
        }

        if let pattern = evidence.spikePattern, pattern.isRecurring, evidence.gatewayOutcome.isStable {
            recKeys.append("CHECK_LOCAL_INTERFERENCE")
        }

        if evidence.natType == .type3Strict && (evidence.serverArchitecture == .peerToPeer || evidence.serverArchitecture == .hybrid) {
            recKeys.append("ENABLE_UPNP")
        }

        if evidence.outOfOrderCount >= 2 && evidence.gatewayOutcome.isStable {
            recKeys.append("ROUTE_INSTABILITY")
        }

        let localized = recKeys.map { LagCheckEngineBridge.localizeRecommendation(key: $0) }
        return Array(localized.sorted(by: { $0.priority < $1.priority }).prefix(3))
    }
}
