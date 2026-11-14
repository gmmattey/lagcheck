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
    public let arrivalIndex: Int?

    public init(sequence: Int, roundTripMilliseconds: Double? = nil, outcome: ProbeOutcome, arrivalIndex: Int? = nil) {
        self.sequence = sequence
        self.roundTripMilliseconds = roundTripMilliseconds
        self.outcome = outcome
        self.arrivalIndex = arrivalIndex
    }

    public static func == (lhs: ProbeSample, rhs: ProbeSample) -> Bool {
        lhs.sequence == rhs.sequence &&
        lhs.roundTripMilliseconds == rhs.roundTripMilliseconds &&
        lhs.outcome == rhs.outcome
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(sequence)
        hasher.combine(roundTripMilliseconds)
        hasher.combine(outcome)
    }

    public var isValidResponse: Bool {
        outcome == .received && roundTripMilliseconds != nil
    }
}

public enum ProbeAcceptancePolicy {
    public static let plannedProbeCount: Int = EnginePolicyProvider.policy.plannedProbeCount
    public static let sendWindowSeconds: TimeInterval = Double(EnginePolicyProvider.policy.sendWindowMillis) / 1000.0
    public static let timeoutSeconds: TimeInterval = Double(EnginePolicyProvider.policy.timeoutMillis) / 1000.0
    public static let closureSeconds: TimeInterval = Double(EnginePolicyProvider.policy.closureMillis) / 1000.0
    public static let minimumValidResponses: Int = EnginePolicyProvider.policy.minimumValidResponses

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
    public let outOfOrderCount: Int
    public let outOfOrderRatePercentage: Double
    public let components: QualityComponents?
    public let spikePattern: SpikePattern?

    public init(
        validResponseCount: Int, timeoutCount: Int, invalidResponseCount: Int,
        p50Milliseconds: Double?, p95Milliseconds: Double?, p99Milliseconds: Double?, jitterMilliseconds: Double?,
        packetLossPercentage: Double, spikeCount: Int, severeSpikeCount: Int, spikeRatePercentage: Double,
        p95ToP50Ratio: Double?, worstSpikeMilliseconds: Double? = nil,
        outOfOrderCount: Int = 0, outOfOrderRatePercentage: Double = 0.0,
        components: QualityComponents?,
        spikePattern: SpikePattern? = nil
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
        self.outOfOrderCount = outOfOrderCount
        self.outOfOrderRatePercentage = outOfOrderRatePercentage
        self.components = components
        self.spikePattern = spikePattern
    }

    private enum CodingKeys: String, CodingKey {
        case validResponseCount
        case timeoutCount
        case invalidResponseCount
        case p50Milliseconds
        case p95Milliseconds
        case p99Milliseconds
        case jitterMilliseconds
        case packetLossPercentage
        case spikeCount
        case severeSpikeCount
        case spikeRatePercentage
        case p95ToP50Ratio
        case worstSpikeMilliseconds
        case outOfOrderCount
        case outOfOrderRatePercentage
        case components
        case spikePattern
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        validResponseCount = try container.decode(Int.self, forKey: .validResponseCount)
        timeoutCount = try container.decode(Int.self, forKey: .timeoutCount)
        invalidResponseCount = try container.decode(Int.self, forKey: .invalidResponseCount)
        p50Milliseconds = try container.decodeIfPresent(Double.self, forKey: .p50Milliseconds)
        p95Milliseconds = try container.decodeIfPresent(Double.self, forKey: .p95Milliseconds)
        p99Milliseconds = try container.decodeIfPresent(Double.self, forKey: .p99Milliseconds)
        jitterMilliseconds = try container.decodeIfPresent(Double.self, forKey: .jitterMilliseconds)
        packetLossPercentage = try container.decode(Double.self, forKey: .packetLossPercentage)
        spikeCount = try container.decode(Int.self, forKey: .spikeCount)
        severeSpikeCount = try container.decode(Int.self, forKey: .severeSpikeCount)
        spikeRatePercentage = try container.decode(Double.self, forKey: .spikeRatePercentage)
        p95ToP50Ratio = try container.decodeIfPresent(Double.self, forKey: .p95ToP50Ratio)
        worstSpikeMilliseconds = try container.decodeIfPresent(Double.self, forKey: .worstSpikeMilliseconds)
        outOfOrderCount = try container.decodeIfPresent(Int.self, forKey: .outOfOrderCount) ?? 0
        outOfOrderRatePercentage = try container.decodeIfPresent(Double.self, forKey: .outOfOrderRatePercentage) ?? 0.0
        components = try container.decodeIfPresent(QualityComponents.self, forKey: .components)
        spikePattern = try container.decodeIfPresent(SpikePattern.self, forKey: .spikePattern)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(validResponseCount, forKey: .validResponseCount)
        try container.encode(timeoutCount, forKey: .timeoutCount)
        try container.encode(invalidResponseCount, forKey: .invalidResponseCount)
        try container.encodeIfPresent(p50Milliseconds, forKey: .p50Milliseconds)
        try container.encodeIfPresent(p95Milliseconds, forKey: .p95Milliseconds)
        try container.encodeIfPresent(p99Milliseconds, forKey: .p99Milliseconds)
        try container.encodeIfPresent(jitterMilliseconds, forKey: .jitterMilliseconds)
        try container.encode(packetLossPercentage, forKey: .packetLossPercentage)
        try container.encode(spikeCount, forKey: .spikeCount)
        try container.encode(severeSpikeCount, forKey: .severeSpikeCount)
        try container.encode(spikeRatePercentage, forKey: .spikeRatePercentage)
        try container.encodeIfPresent(p95ToP50Ratio, forKey: .p95ToP50Ratio)
        try container.encodeIfPresent(worstSpikeMilliseconds, forKey: .worstSpikeMilliseconds)
        try container.encode(outOfOrderCount, forKey: .outOfOrderCount)
        try container.encode(outOfOrderRatePercentage, forKey: .outOfOrderRatePercentage)
        try container.encodeIfPresent(components, forKey: .components)
        try container.encodeIfPresent(spikePattern, forKey: .spikePattern)
    }
}

public struct QualityResult: Codable, Equatable, Sendable {
    public let metrics: QualityMetrics
    public let rawScore: Int
    public let finalScore: Int
    public let resultClass: ResultClass
    public let appliedGuardrails: Set<ScoreGuardrail>
    /// Pacotes reais da fase, na ordem de envio. Toda reavaliação (tela, histórico, Home, widget)
    /// passa estes pacotes ao motor. `nil` só em entradas antigas do histórico, gravadas antes
    /// desta versão; nelas a ponte reconstrói uma série aproximada a partir das métricas.
    public let samples: [ProbeSample]?

    public init(metrics: QualityMetrics, rawScore: Int, finalScore: Int, resultClass: ResultClass, appliedGuardrails: Set<ScoreGuardrail>, samples: [ProbeSample]? = nil) {
        self.metrics = metrics
        self.rawScore = rawScore
        self.finalScore = finalScore
        self.resultClass = resultClass
        self.appliedGuardrails = appliedGuardrails
        self.samples = samples
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
