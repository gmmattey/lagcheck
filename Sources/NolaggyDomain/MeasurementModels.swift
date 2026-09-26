import Foundation

public enum ProbeOutcome: String, Codable, CaseIterable, Hashable, Sendable {
    case received
    case timeout
    case transportError
    case invalidResponse
}

/// Uma amostra já classificada pelo transporte. A ordem da coleção representa a ordem de recepção.
public struct ProbeSample: Codable, Hashable, Sendable {
    public let sequence: Int
    public let roundTripMilliseconds: Double?
    public let outcome: ProbeOutcome

    public init(sequence: Int, roundTripMilliseconds: Double? = nil, outcome: ProbeOutcome) {
        self.sequence = sequence
        self.roundTripMilliseconds = roundTripMilliseconds
        self.outcome = outcome
    }

    public var isValidResponse: Bool {
        outcome == .received && roundTripMilliseconds != nil
    }
}

public enum ProbeAcceptancePolicy {
    public static let plannedProbeCount = 30
    public static let sendWindowSeconds: TimeInterval = 15
    public static let timeoutSeconds: TimeInterval = 2
    public static let closureSeconds: TimeInterval = 17

    /// Classifica somente tempo: a correlação integral de payload pertence ao adaptador de transporte.
    public static func outcome(
        sentAt secondsFromStart: TimeInterval,
        receivedAt responseSecondsFromStart: TimeInterval
    ) -> ProbeOutcome {
        let elapsed = responseSecondsFromStart - secondsFromStart
        guard elapsed >= 0,
              elapsed < timeoutSeconds,
              responseSecondsFromStart <= closureSeconds else {
            return .timeout
        }
        return .received
    }
}

public enum ResultClass: String, Codable, CaseIterable, Hashable, Sendable {
    case excellent
    case great
    case unstable
    case lagRisk
}

public enum InconclusiveReason: String, Codable, CaseIterable, Hashable, Sendable {
    case insufficientUDPResponses
    case poorSampleQuality
}

public enum ScoreGuardrail: String, Codable, CaseIterable, Hashable, Sendable {
    case excessiveLossOrLatency
    case severeSpikes
}

public struct QualityComponents: Codable, Equatable, Sendable {
    public let latency: Double
    public let loss: Double
    public let jitter: Double
    public let tail: Double
    public let spikes: Double
    public let consistency: Double
    public let stability: Double

    public init(latency: Double, loss: Double, jitter: Double, tail: Double, spikes: Double, consistency: Double, stability: Double) {
        self.latency = latency
        self.loss = loss
        self.jitter = jitter
        self.tail = tail
        self.spikes = spikes
        self.consistency = consistency
        self.stability = stability
    }
}

public struct QualityMetrics: Codable, Equatable, Sendable {
    public let validResponseCount: Int
    public let timeoutCount: Int
    public let invalidResponseCount: Int
    public let p50Milliseconds: Double?
    public let p95Milliseconds: Double?
    public let p99Milliseconds: Double?
    public let jitterMilliseconds: Double?
    public let packetLossPercentage: Double
    public let spikeCount: Int
    public let severeSpikeCount: Int
    public let spikeRatePercentage: Double
    public let p95ToP50Ratio: Double?
    /// Maior RTT válido observado. É preservado para explicar a cauda sem inventar amostras.
    public let worstSpikeMilliseconds: Double?
    public let components: QualityComponents?

    public init(
        validResponseCount: Int, timeoutCount: Int, invalidResponseCount: Int,
        p50Milliseconds: Double?, p95Milliseconds: Double?, p99Milliseconds: Double?, jitterMilliseconds: Double?,
        packetLossPercentage: Double, spikeCount: Int, severeSpikeCount: Int, spikeRatePercentage: Double,
        p95ToP50Ratio: Double?, worstSpikeMilliseconds: Double? = nil, components: QualityComponents?
    ) {
        self.validResponseCount = validResponseCount
        self.timeoutCount = timeoutCount
        self.invalidResponseCount = invalidResponseCount
        self.p50Milliseconds = p50Milliseconds
        self.p95Milliseconds = p95Milliseconds
        self.p99Milliseconds = p99Milliseconds
        self.jitterMilliseconds = jitterMilliseconds
        self.packetLossPercentage = packetLossPercentage
        self.spikeCount = spikeCount
        self.severeSpikeCount = severeSpikeCount
        self.spikeRatePercentage = spikeRatePercentage
        self.p95ToP50Ratio = p95ToP50Ratio
        self.worstSpikeMilliseconds = worstSpikeMilliseconds
        self.components = components
    }
}

public struct QualityResult: Codable, Equatable, Sendable {
    public let metrics: QualityMetrics
    public let rawScore: Int
    public let finalScore: Int
    public let resultClass: ResultClass
    public let appliedGuardrails: Set<ScoreGuardrail>

    public init(metrics: QualityMetrics, rawScore: Int, finalScore: Int, resultClass: ResultClass, appliedGuardrails: Set<ScoreGuardrail>) {
        self.metrics = metrics
        self.rawScore = rawScore
        self.finalScore = finalScore
        self.resultClass = resultClass
        self.appliedGuardrails = appliedGuardrails
    }
}

public enum MeasurementKind: String, Codable, CaseIterable, Hashable, Sendable {
    case quick
    case deep
}

public enum MeasurementEvaluation: Equatable, Sendable {
    case completed(QualityResult)
    case inconclusive(reason: InconclusiveReason, diagnostics: QualityMetrics)
}
