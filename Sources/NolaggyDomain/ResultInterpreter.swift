import Foundation

/// Chaves que a camada de apresentação localiza no idioma atual. O domínio não produz copy.
public enum ResultConclusionKey: String, Codable, CaseIterable, Hashable, Sendable {
    case readyToPlay = "quick_check.result.conclusion.ready_to_play"
    case lagMayOccur = "quick_check.result.conclusion.lag_may_occur"
    case investigateBeforePlaying = "quick_check.result.conclusion.investigate_before_playing"
}

/// Rótulo da faixa do score. A apresentação escolhe a string no idioma atual.
public enum ResultHeadlineKey: String, Codable, CaseIterable, Hashable, Sendable {
    case excellent = "quick_check.result.headline.excellent"
    case great = "quick_check.result.headline.great"
    case unstable = "quick_check.result.headline.unstable"
    case lagRisk = "quick_check.result.headline.lag_risk"
}

/// A causa única que recebe destaque na superfície principal do resultado.
public enum ResultPrimaryCauseKey: String, Codable, CaseIterable, Hashable, Sendable {
    case stableConnection = "quick_check.result.cause.stable_connection"
    case packetLoss = "quick_check.result.cause.packet_loss"
    case highLatency = "quick_check.result.cause.high_latency"
    case severeSpikes = "quick_check.result.cause.severe_spikes"
    case highJitter = "quick_check.result.cause.high_jitter"
    case loadDegradation = "quick_check.result.cause.load_degradation"
    case loadInstability = "quick_check.result.cause.load_instability"
    case tailLatency = "quick_check.result.cause.tail_latency"
}

/// Qualificador de origem da causa identificada (Decisão 55).
public enum GatewayOriginQualifier: String, Codable, CaseIterable, Hashable, Sendable {
    case localWiFi
    case remoteWAN
    case unobservable
}

/// Explicação curta da condição observada; não contém texto de produto no domínio.
public enum ResultExplanationKey: String, Codable, CaseIterable, Hashable, Sendable {
    case stableConnection = "quick_check.result.explanation.stable_connection"
    case packetLoss = "quick_check.result.explanation.packet_loss"
    case highLatency = "quick_check.result.explanation.high_latency"
    case severeSpikes = "quick_check.result.explanation.severe_spikes"
    case highJitter = "quick_check.result.explanation.high_jitter"
    case loadDegradation = "quick_check.result.explanation.load_degradation"
    case loadInstability = "quick_check.result.explanation.load_instability"
    case tailLatency = "quick_check.result.explanation.tail_latency"
}

/// Insight complementar do resultado, exibido depois das métricas quando a UI o suportar.
public enum ResultInsightKey: String, Codable, CaseIterable, Hashable, Sendable {
    case stableConnection = "quick_check.result.insight.stable_connection"
    case packetLoss = "quick_check.result.insight.packet_loss"
    case highLatency = "quick_check.result.insight.high_latency"
    case severeSpikes = "quick_check.result.insight.severe_spikes"
    case highJitter = "quick_check.result.insight.high_jitter"
    case loadDegradation = "quick_check.result.insight.load_degradation"
    case loadInstability = "quick_check.result.insight.load_instability"
    case tailLatency = "quick_check.result.insight.tail_latency"
}

public struct ResultInterpretation: Equatable, Sendable {
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

/// Interpreta exclusivamente um resultado concluído do perfil piloto.
///
/// O score e as métricas já foram avaliados antes desta etapa. A prioridade de causa
/// segue a especificação: perda, P50, spikes severos, jitter e conexão estável.
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
        let (cause, secondaries) = evaluateCauses(
            for: result.metrics,
            guardrails: QualityEvaluator.causeGuardrails(for: profile),
            loadTier: loadTier,
            spikePattern: spikePattern
        )

        let evidence = DiagnosticEvidence(
            gatewayOutcome: gatewayOutcome,
            wifiBand: wifiBand,
            wifiBandConfidence: wifiBandConfidence,
            loadTier: loadTier,
            packetLossPercentage: result.metrics.packetLossPercentage,
            spikePattern: spikePattern,
            tailRatio: result.metrics.p95ToP50Ratio,
            natType: natType,
            serverArchitecture: serverArchitecture
        )
        let recommendations = EvidenceRecommendationEngine.generateRecommendations(evidence: evidence)

        return ResultInterpretation(
            score: result.finalScore,
            scoreBand: result.resultClass,
            headlineKey: headline(for: result.resultClass),
            conclusionKey: conclusion(for: result.resultClass),
            primaryCauseKey: cause,
            secondaryCauseKeys: secondaries,
            originQualifier: originQualifier(gatewayOutcome: gatewayOutcome),
            spikePattern: spikePattern,
            recommendations: recommendations,
            explanationKey: explanation(for: cause),
            insightKey: insight(for: cause),
            metrics: result.metrics
        )
    }

    public static func interpret(_ result: QualityResult, profile: QualityProfileID) -> ResultInterpretation {
        interpret(result, profile: profile, loadTier: nil)
    }
}

private extension ResultInterpreter {
    static func conclusion(for resultClass: ResultClass) -> ResultConclusionKey {
        switch resultClass {
        case .excellent, .great:
            .readyToPlay
        case .unstable:
            .lagMayOccur
        case .lagRisk:
            .investigateBeforePlaying
        }
    }

    static func headline(for resultClass: ResultClass) -> ResultHeadlineKey {
        switch resultClass {
        case .excellent: .excellent
        case .great: .great
        case .unstable: .unstable
        case .lagRisk: .lagRisk
        }
    }

    static func evaluateCauses(
        for metrics: QualityMetrics,
        guardrails: QualityEvaluator.CauseGuardrails,
        loadTier: LoadDegradationTier?,
        spikePattern: SpikePattern?
    ) -> (primary: ResultPrimaryCauseKey, secondaries: [ResultPrimaryCauseKey]) {
        var causes: [ResultPrimaryCauseKey] = []

        let isLoss = metrics.packetLossPercentage > guardrails.lossGuardrailPercentage
        let isLatency = (metrics.p50Milliseconds ?? 0) > guardrails.latencyGuardrailMilliseconds
        let isSevereSpikes: Bool
        if let pattern = spikePattern {
            isSevereSpikes = pattern.severeCount >= guardrails.severeSpikeGuardrailCount
        } else {
            isSevereSpikes = metrics.severeSpikeCount >= guardrails.severeSpikeGuardrailCount
        }
        let isJitter = (metrics.jitterMilliseconds ?? 0) > guardrails.jitterRiskMilliseconds
        let isLoad = (loadTier == .material || loadTier == .severe)
        let isTail = (metrics.p95ToP50Ratio ?? 0) >= 1.8

        // Regra de coocorrência (Decisão 55): Jitter alto + Carga material/severa = Instabilidade sob uso da internet
        if isJitter && isLoad {
            causes.append(.loadInstability)
            if isLoss { causes.append(.packetLoss) }
            if isLatency { causes.append(.highLatency) }
            if isSevereSpikes { causes.append(.severeSpikes) }
        } else {
            if isLoss { causes.append(.packetLoss) }
            if isLatency { causes.append(.highLatency) }
            if isSevereSpikes { causes.append(.severeSpikes) }
            if isJitter { causes.append(.highJitter) }
            if isLoad { causes.append(.loadDegradation) }
        }

        let primary = causes.first ?? .stableConnection
        var secondaries = Array(causes.dropFirst().prefix(2))

        if isTail && !causes.contains(.tailLatency) && secondaries.count < 2 {
            secondaries.append(.tailLatency)
        }

        return (primary, secondaries)
    }

    static func originQualifier(gatewayOutcome: GatewayProbeOutcome) -> GatewayOriginQualifier {
        if gatewayOutcome.isDegraded {
            return .localWiFi
        } else if gatewayOutcome.isStable {
            return .remoteWAN
        } else {
            return .unobservable
        }
    }

    static func explanation(for cause: ResultPrimaryCauseKey) -> ResultExplanationKey {
        switch cause {
        case .stableConnection: .stableConnection
        case .packetLoss: .packetLoss
        case .highLatency: .highLatency
        case .severeSpikes: .severeSpikes
        case .highJitter: .highJitter
        case .loadDegradation: .loadDegradation
        case .loadInstability: .loadInstability
        case .tailLatency: .tailLatency
        }
    }

    static func insight(for cause: ResultPrimaryCauseKey) -> ResultInsightKey {
        switch cause {
        case .stableConnection: .stableConnection
        case .packetLoss: .packetLoss
        case .highLatency: .highLatency
        case .severeSpikes: .severeSpikes
        case .highJitter: .highJitter
        case .loadDegradation: .loadDegradation
        case .loadInstability: .loadInstability
        case .tailLatency: .tailLatency
        }
    }
}
