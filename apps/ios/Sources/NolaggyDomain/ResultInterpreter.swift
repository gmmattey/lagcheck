import Foundation
import LagCheckEngine

public enum ResultConclusionKey: String, Codable, CaseIterable, Hashable, Sendable {
    case readyToPlay
    case lagMayOccur
    case investigateBeforePlaying
}

public enum ResultHeadlineKey: String, Codable, CaseIterable, Hashable, Sendable {
    case excellent
    case great
    case unstable
    case lagRisk
}

public enum ResultPrimaryCauseKey: String, Codable, CaseIterable, Hashable, Sendable {
    case stableConnection
    case packetLoss
    case highLatency
    case severeSpikes
    case highJitter
    case loadDegradation
    case loadInstability
    case tailLatency
    case outOfOrder

    public var isRouteInstability: Bool {
        self != .stableConnection
    }
}

public enum ResultExplanationKey: String, Codable, CaseIterable, Hashable, Sendable {
    case stableConnection
    case packetLoss
    case highLatency
    case severeSpikes
    case highJitter
    case loadDegradation
    case loadInstability
    case tailLatency
    case outOfOrder
}

public enum ResultInsightKey: String, Codable, CaseIterable, Hashable, Sendable {
    case stableConnection
    case packetLoss
    case highLatency
    case severeSpikes
    case highJitter
    case loadDegradation
    case loadInstability
    case tailLatency
    case outOfOrder
}

public enum GatewayOriginQualifier: String, Codable, CaseIterable, Hashable, Sendable {
    case localWiFi
    case remoteWAN
    case unobservable
}

public struct ResultInterpretation: Codable, Equatable, Sendable {
    public let score: Int
    public let scoreBand: ResultClass
    public let headlineKey: ResultHeadlineKey
    public let conclusionKey: ResultConclusionKey
    public let primaryCauseKey: ResultPrimaryCauseKey
    public let secondaryCauseKeys: [ResultPrimaryCauseKey]
    public let originQualifier: GatewayOriginQualifier
    public let spikePattern: SpikePattern?
    public let recommendations: [ActionableRecommendation]
    public let explanationKey: ResultExplanationKey
    public let insightKey: ResultInsightKey
    public let metrics: QualityMetrics

    public init(
        score: Int,
        scoreBand: ResultClass,
        headlineKey: ResultHeadlineKey,
        conclusionKey: ResultConclusionKey,
        primaryCauseKey: ResultPrimaryCauseKey,
        secondaryCauseKeys: [ResultPrimaryCauseKey] = [],
        originQualifier: GatewayOriginQualifier = .unobservable,
        spikePattern: SpikePattern? = nil,
        recommendations: [ActionableRecommendation] = [],
        explanationKey: ResultExplanationKey,
        insightKey: ResultInsightKey,
        metrics: QualityMetrics
    ) {
        self.score = score
        self.scoreBand = scoreBand
        self.headlineKey = headlineKey
        self.conclusionKey = conclusionKey
        self.primaryCauseKey = primaryCauseKey
        self.secondaryCauseKeys = secondaryCauseKeys
        self.originQualifier = originQualifier
        self.spikePattern = spikePattern
        self.recommendations = recommendations
        self.explanationKey = explanationKey
        self.insightKey = insightKey
        self.metrics = metrics
    }
}

/// Interpreta o resultado executando a árvore de causas no motor KMP compartilhado.
public enum ResultInterpreter {
    public static func interpret(
        _ result: QualityResult,
        profile: QualityProfileID,
        loadTier: LoadDegradationTier? = nil,
        gatewayOutcome: GatewayProbeOutcome = .unobservable,
        spikePattern: SpikePattern? = nil,
        wifiBand: WiFiBandDiagnostic? = nil,
        wifiBandConfidence: WiFiBandAssessmentConfidence? = nil,
        natType: NATType? = nil,
        serverArchitecture: GameServerArchitecture = .dedicatedServer
    ) -> ResultInterpretation {
        let loadImpact: DeepCheckLoadImpact? = loadTier.map { tier in
            let p50 = result.metrics.p50Milliseconds ?? 30.0
            let delta = (tier == .severe) ? 40.0 : (tier == .material ? 18.0 : 0.0)
            return DeepCheckLoadImpact(restP50Milliseconds: p50, loadP50Milliseconds: p50 + delta, tier: tier)
        }
        let req = LagCheckEngineBridge.buildRequest(
            qualityResult: result,
            loadImpact: loadImpact,
            profile: profile,
            gatewayOutcome: gatewayOutcome,
            spikePattern: spikePattern ?? result.metrics.spikePattern,
            serverArchitecture: serverArchitecture,
            natSnapshot: nil
        )
        let response = LagCheckEngineBridge.evaluate(request: req)

        let primaryKey = LagCheckEngineBridge.toPrimaryCauseKey(response.primaryCause)
        let secondaryKeys = response.secondaryCauses.map { LagCheckEngineBridge.toPrimaryCauseKey($0) }

        let evidence = DiagnosticEvidence(
            gatewayOutcome: gatewayOutcome,
            wifiBand: wifiBand,
            wifiBandConfidence: wifiBandConfidence,
            loadTier: loadTier,
            packetLossPercentage: result.metrics.packetLossPercentage,
            spikePattern: spikePattern ?? result.metrics.spikePattern,
            tailRatio: result.metrics.p95ToP50Ratio,
            natType: natType,
            serverArchitecture: serverArchitecture,
            outOfOrderCount: result.metrics.outOfOrderCount
        )
        let recommendations = EvidenceRecommendationEngine.generateRecommendations(evidence: evidence)

        return ResultInterpretation(
            score: result.finalScore,
            scoreBand: result.resultClass,
            headlineKey: headline(for: result.resultClass),
            conclusionKey: conclusion(for: result.resultClass),
            primaryCauseKey: primaryKey,
            secondaryCauseKeys: secondaryKeys,
            originQualifier: originQualifier(gatewayOutcome: gatewayOutcome),
            spikePattern: spikePattern ?? result.metrics.spikePattern,
            recommendations: recommendations,
            explanationKey: explanation(for: primaryKey),
            insightKey: insight(for: primaryKey),
            metrics: result.metrics
        )
    }

    public static func interpret(_ result: QualityResult, profile: QualityProfileID) -> ResultInterpretation {
        interpret(result, profile: profile, loadTier: nil)
    }

    private static func conclusion(for resultClass: ResultClass) -> ResultConclusionKey {
        switch resultClass {
        case .excellent, .great:
            return .readyToPlay
        case .unstable:
            return .lagMayOccur
        case .lagRisk:
            return .investigateBeforePlaying
        }
    }

    private static func headline(for resultClass: ResultClass) -> ResultHeadlineKey {
        switch resultClass {
        case .excellent: return .excellent
        case .great: return .great
        case .unstable: return .unstable
        case .lagRisk: return .lagRisk
        }
    }

    private static func originQualifier(gatewayOutcome: GatewayProbeOutcome) -> GatewayOriginQualifier {
        switch gatewayOutcome {
        case .stable: return .remoteWAN
        case .degraded: return .localWiFi
        case .unobservable: return .unobservable
        }
    }

    private static func explanation(for cause: ResultPrimaryCauseKey) -> ResultExplanationKey {
        switch cause {
        case .stableConnection: return .stableConnection
        case .packetLoss: return .packetLoss
        case .highLatency: return .highLatency
        case .severeSpikes: return .severeSpikes
        case .highJitter: return .highJitter
        case .loadDegradation: return .loadDegradation
        case .loadInstability: return .loadInstability
        case .tailLatency: return .tailLatency
        case .outOfOrder: return .outOfOrder
        }
    }

    private static func insight(for cause: ResultPrimaryCauseKey) -> ResultInsightKey {
        switch cause {
        case .stableConnection: return .stableConnection
        case .packetLoss: return .packetLoss
        case .highLatency: return .highLatency
        case .severeSpikes: return .severeSpikes
        case .highJitter: return .highJitter
        case .loadDegradation: return .loadDegradation
        case .loadInstability: return .loadInstability
        case .tailLatency: return .tailLatency
        case .outOfOrder: return .outOfOrder
        }
    }
}
