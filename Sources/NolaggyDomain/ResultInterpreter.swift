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
}

/// Explicação curta da condição observada; não contém texto de produto no domínio.
public enum ResultExplanationKey: String, Codable, CaseIterable, Hashable, Sendable {
    case stableConnection = "quick_check.result.explanation.stable_connection"
    case packetLoss = "quick_check.result.explanation.packet_loss"
    case highLatency = "quick_check.result.explanation.high_latency"
    case severeSpikes = "quick_check.result.explanation.severe_spikes"
    case highJitter = "quick_check.result.explanation.high_jitter"
}

/// Insight complementar do resultado, exibido depois das métricas quando a UI o suportar.
public enum ResultInsightKey: String, Codable, CaseIterable, Hashable, Sendable {
    case stableConnection = "quick_check.result.insight.stable_connection"
    case packetLoss = "quick_check.result.insight.packet_loss"
    case highLatency = "quick_check.result.insight.high_latency"
    case severeSpikes = "quick_check.result.insight.severe_spikes"
    case highJitter = "quick_check.result.insight.high_jitter"
}

public struct ResultInterpretation: Equatable, Sendable {
    public let score: Int
    public let scoreBand: ResultClass
    public let headlineKey: ResultHeadlineKey
    public let conclusionKey: ResultConclusionKey
    public let primaryCauseKey: ResultPrimaryCauseKey
    public let explanationKey: ResultExplanationKey
    public let insightKey: ResultInsightKey
    public let metrics: QualityMetrics

    public init(
        score: Int,
        scoreBand: ResultClass,
        headlineKey: ResultHeadlineKey,
        conclusionKey: ResultConclusionKey,
        primaryCauseKey: ResultPrimaryCauseKey,
        explanationKey: ResultExplanationKey,
        insightKey: ResultInsightKey,
        metrics: QualityMetrics
    ) {
        self.score = score
        self.scoreBand = scoreBand
        self.headlineKey = headlineKey
        self.conclusionKey = conclusionKey
        self.primaryCauseKey = primaryCauseKey
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
    public static func interpret(_ result: QualityResult, profile: QualityProfileID) -> ResultInterpretation {
        let cause = primaryCause(for: result.metrics, guardrails: QualityEvaluator.causeGuardrails(for: profile))
        return ResultInterpretation(
            score: result.finalScore,
            scoreBand: result.resultClass,
            headlineKey: headline(for: result.resultClass),
            conclusionKey: conclusion(for: result.resultClass),
            primaryCauseKey: cause,
            explanationKey: explanation(for: cause),
            insightKey: insight(for: cause),
            metrics: result.metrics
        )
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

    static func primaryCause(
        for metrics: QualityMetrics,
        guardrails: QualityEvaluator.CauseGuardrails
    ) -> ResultPrimaryCauseKey {
        // Limites versionados do perfil ativo (ver QualityEvaluator.causeGuardrails);
        // nunca hardcodar números de um único perfil aqui.
        if metrics.packetLossPercentage > guardrails.lossGuardrailPercentage {
            return .packetLoss
        }
        if let p50 = metrics.p50Milliseconds, p50 > guardrails.latencyGuardrailMilliseconds {
            return .highLatency
        }
        if metrics.severeSpikeCount >= guardrails.severeSpikeGuardrailCount {
            return .severeSpikes
        }
        if let jitter = metrics.jitterMilliseconds, jitter > guardrails.jitterRiskMilliseconds {
            return .highJitter
        }
        return .stableConnection
    }

    static func explanation(for cause: ResultPrimaryCauseKey) -> ResultExplanationKey {
        switch cause {
        case .stableConnection: .stableConnection
        case .packetLoss: .packetLoss
        case .highLatency: .highLatency
        case .severeSpikes: .severeSpikes
        case .highJitter: .highJitter
        }
    }

    static func insight(for cause: ResultPrimaryCauseKey) -> ResultInsightKey {
        switch cause {
        case .stableConnection: .stableConnection
        case .packetLoss: .packetLoss
        case .highLatency: .highLatency
        case .severeSpikes: .severeSpikes
        case .highJitter: .highJitter
        }
    }
}
