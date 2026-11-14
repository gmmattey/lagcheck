import Foundation
import LagCheckEngine

/// Veredito semântico e determinístico de prontidão competitiva (Decisões 50 e 51).
/// Substitui o score numérico como resultado protagonista da jornada.
public enum GameReadinessVerdict: String, Codable, CaseIterable, Equatable, Sendable {
    /// Condições observadas compatíveis com partida competitiva sólida (● PRONTO PARA RANKED).
    case ready = "ready"
    /// Jitter moderado, oscilações esporádicas ou impacto sob carga (▲ CONDIÇÕES INSTÁVEIS).
    case caution = "caution"
    /// Perda de pacotes prejudicial, latência excessiva ou instabilidade severa (▲ EU EVITARIA RANKED AGORA).
    case notReady = "not_ready"
    /// Respostas UDP insuficientes (< 10 amostras válidas) para emitir veredito seguro (— INCONCLUSIVO).
    case inconclusive = "inconclusive"

    public var titleKey: String {
        switch self {
        case .ready: return "game_readiness.verdict.ready"
        case .caution: return "game_readiness.verdict.caution"
        case .notReady: return "game_readiness.verdict.not_ready"
        case .inconclusive: return "game_readiness.verdict.inconclusive"
        }
    }

    public var defaultHeadline: String {
        switch self {
        case .ready: return "PRONTO PARA RANKED"
        case .caution: return "CONDIÇÕES INSTÁVEIS"
        case .notReady: return "EU EVITARIA RANKED AGORA"
        case .inconclusive: return "DADOS INSUFICIENTES"
        }
    }

    public var isReady: Bool {
        self == .ready
    }

    public var symbolName: String {
        switch self {
        case .ready: return "checkmark.circle.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .notReady: return "xmark.octagon.fill"
        case .inconclusive: return "minus.circle.fill"
        }
    }
}

/// Achado de rede honesto para a seção "O que encontramos" (Decisões 50 e 51).
/// Reporta o sintoma comprovado sem atribuir culpa causal falsa a Wi-Fi ou operadora sem probe isolado.
public struct NetworkFinding: Codable, Equatable, Hashable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case packetLoss
        case latencySpikes
        case highLatency
        case highJitter
        case outOfOrderPackets
        case loadDegradation
        case normalDestination
        case stableRoute
        case localGateway
        case natTopology
        case insufficientData
    }

    public enum Severity: String, Codable, Sendable {
        case positive // Verde
        case warning  // Âmbar
        case negative // Vermelho
        case neutral  // Neutro/Cinza
    }

    public let kind: Kind
    public let severity: Severity
    public let labelKey: String
    public let detail: String?

    public init(kind: Kind, severity: Severity, labelKey: String, detail: String? = nil) {
        self.kind = kind
        self.severity = severity
        self.labelKey = labelKey
        self.detail = detail
    }
}

/// Avaliação completa de prontidão competitiva para a tela de resultado HIG Dark Competitive.
public struct GameReadinessEvaluation: Codable, Equatable, Sendable {
    public let verdict: GameReadinessVerdict
    public let headlineKey: String
    public let subtitleKey: String
    /// Valor normalizado de 0.0 a 1.0 para a barra contínua de estabilidade.
    public let stabilityRatio: Double
    public let stabilitySummaryKey: String
    public let findings: [NetworkFinding]
    public let pingMs: Double?
    public let jitterMs: Double?
    public let packetLossPercentage: Double?
    public let isUnderLoadAffected: Bool
    public let worstSpikeMs: Double?
    /// Score numérico (0–100) unificado e acoplado ao veredito (Decisão 72). Nulo se inconclusivo.
    public let score: Int?
    /// Métricas completas de repouso e carga associadas à avaliação.
    public let metrics: DeepCheckMetrics?

    public init(
        verdict: GameReadinessVerdict,
        headlineKey: String,
        subtitleKey: String,
        stabilityRatio: Double,
        stabilitySummaryKey: String,
        findings: [NetworkFinding],
        pingMs: Double?,
        jitterMs: Double?,
        packetLossPercentage: Double?,
        isUnderLoadAffected: Bool,
        worstSpikeMs: Double? = nil,
        score: Int? = nil,
        metrics: DeepCheckMetrics? = nil
    ) {
        self.verdict = verdict
        self.headlineKey = headlineKey
        self.subtitleKey = subtitleKey
        self.stabilityRatio = stabilityRatio
        self.stabilitySummaryKey = stabilitySummaryKey
        self.findings = findings
        self.pingMs = pingMs
        self.jitterMs = jitterMs
        self.packetLossPercentage = packetLossPercentage
        self.isUnderLoadAffected = isUnderLoadAffected
        self.worstSpikeMs = worstSpikeMs
        self.score = score
        self.metrics = metrics
    }

    public static let inconclusive = GameReadinessEvaluation(
        verdict: .inconclusive,
        headlineKey: "game_readiness.verdict.inconclusive.headline",
        subtitleKey: "game_readiness.verdict.inconclusive.subtitle",
        stabilityRatio: 0.0,
        stabilitySummaryKey: "game_readiness.stability.inconclusive",
        findings: [
            NetworkFinding(
                kind: .insufficientData,
                severity: .neutral,
                labelKey: "game_readiness.finding.insufficient_samples"
            )
        ],
        pingMs: nil,
        jitterMs: nil,
        packetLossPercentage: nil,
        isUnderLoadAffected: false,
        worstSpikeMs: nil,
        score: nil,
        metrics: nil
    )
}

/// Avaliador determinístico de prontidão de rede para jogos via motor KMP compartilhado (Decisões 50, 51, 55, 134 e 135).
public enum GameReadinessEvaluator {
    public static var version: String {
        EnginePolicyProvider.policy.ruleVersions["BATTLE_ROYALE_COMPETITIVE"]?["readiness"] ?? "readiness-v3.0"
    }

    /// Avalia a prontidão a partir de um DeepCheckResult (repouso + impacto de carga opcional).
    public static func evaluate(
        deepCheckResult: DeepCheckResult?,
        profile: QualityProfileID,
        confidence: MeasurementConfidence = .high
    ) -> GameReadinessEvaluation {
        guard let result = deepCheckResult else {
            return .inconclusive
        }
        return evaluate(
            qualityResult: result.restResult,
            loadImpact: result.metrics.loadImpact,
            profile: profile,
            confidence: confidence,
            deepCheckMetrics: result.metrics
        )
    }

    /// Avalia a prontidão a partir de QualityResult (repouso) e opcional impacto sob carga.
    public static func evaluate(
        qualityResult: QualityResult?,
        loadImpact: DeepCheckLoadImpact?,
        profile: QualityProfileID,
        confidence: MeasurementConfidence = .high,
        spikePattern: SpikePattern? = nil,
        gatewayOutcome: GatewayProbeOutcome = .unobservable,
        serverArchitecture: GameServerArchitecture = .dedicatedServer,
        natSnapshot: NATTopologySnapshot? = nil,
        deepCheckMetrics: DeepCheckMetrics? = nil
    ) -> GameReadinessEvaluation {
        guard let qualityResult else {
            return .inconclusive
        }

        if qualityResult.metrics.validResponseCount < ProbeAcceptancePolicy.minimumValidResponses {
            return .inconclusive
        }

        let req = LagCheckEngineBridge.buildRequest(
            qualityResult: qualityResult,
            loadImpact: loadImpact,
            profile: profile,
            gatewayOutcome: gatewayOutcome,
            spikePattern: spikePattern ?? qualityResult.metrics.spikePattern,
            serverArchitecture: serverArchitecture,
            natSnapshot: natSnapshot
        )

        let response = LagCheckEngineBridge.evaluate(request: req)
        return LagCheckEngineBridge.mapGameReadinessEvaluation(
            response: response,
            confidence: confidence,
            deepCheckMetrics: deepCheckMetrics,
            qualityResult: qualityResult,
            loadImpact: loadImpact,
            serverArchitecture: serverArchitecture,
            natSnapshot: natSnapshot
        )
    }
}

