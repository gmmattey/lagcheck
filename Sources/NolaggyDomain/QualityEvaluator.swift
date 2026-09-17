import Foundation

/// Implementação versionada do perfil BATTLE_ROYALE_COMPETITIVE definida no piloto Quick Check.
public enum QualityEvaluator {
    public static func ruleVersion(for profile: QualityProfileID) -> String {
        switch profile {
        case .battleRoyaleCompetitive: "pilot-2026.09.08.1"
        case .mobileRealtime: "mobile-realtime-2026.09.08.1"
        case .casualRealtime: "casual-realtime-2026.09.08.1"
        }
    }

    public static func supports(profile: QualityProfileID, ruleVersion: String) -> Bool {
        ruleVersion == self.ruleVersion(for: profile)
    }

    public static func evaluateBattleRoyaleCompetitive(
        samples: [ProbeSample]
    ) -> MeasurementEvaluation {
        evaluate(samples: samples, profile: .battleRoyaleCompetitive)
    }

    public static func evaluateMobileRealtime(samples: [ProbeSample]) -> MeasurementEvaluation {
        evaluate(samples: samples, profile: .mobileRealtime)
    }

    public static func evaluateCasualRealtime(samples: [ProbeSample]) -> MeasurementEvaluation {
        evaluate(samples: samples, profile: .casualRealtime)
    }

    /// Guardrails do perfil relevantes para escolher a causa principal do resultado.
    /// Único ponto de verdade: `ResultInterpreter` nunca deve hardcodar esses números.
    public struct CauseGuardrails: Equatable, Sendable {
        public let lossGuardrailPercentage: Double
        public let latencyGuardrailMilliseconds: Double
        public let severeSpikeGuardrailCount: Int
        public let jitterRiskMilliseconds: Double
    }

    public static func causeGuardrails(for profile: QualityProfileID) -> CauseGuardrails {
        let rule = ProfileRule(profile)
        return CauseGuardrails(
            lossGuardrailPercentage: rule.lossGuardrail,
            latencyGuardrailMilliseconds: rule.latencyGuardrail,
            severeSpikeGuardrailCount: rule.severeSpikeGuardrailCount,
            jitterRiskMilliseconds: rule.jitter.unstable
        )
    }

    public static func evaluate(samples: [ProbeSample], profile: QualityProfileID) -> MeasurementEvaluation {
        let rule = ProfileRule(profile)
        let validRTTs = samples.compactMap { sample in
            sample.isValidResponse ? sample.roundTripMilliseconds : nil
        }
        let timeoutCount = samples.filter { $0.outcome == .timeout }.count
        let invalidResponseCount = samples.filter { $0.outcome == .invalidResponse }.count
        let loss = Double(timeoutCount) / Double(ProbeAcceptancePolicy.plannedProbeCount) * 100

        guard validRTTs.count >= 10 else {
            return .inconclusive(
                reason: .insufficientUDPResponses,
                diagnostics: diagnosticMetrics(
                    validRTTs: validRTTs,
                    timeoutCount: timeoutCount,
                    invalidResponseCount: invalidResponseCount,
                    loss: loss,
                    rule: rule
                )
            )
        }

        let p50 = percentile(validRTTs, percentile: 0.50)
        let p95 = percentile(validRTTs, percentile: 0.95)
        let p99 = percentile(validRTTs, percentile: 0.99)
        let jitter = averageAdjacentDifference(validRTTs)
        let ratio = p50 == 0 ? (p95 == 0 ? 1 : .infinity) : p95 / p50
        let spikeCount = validRTTs.filter { $0 > p50 + rule.spikeOffset && $0 >= rule.spikeFloor }.count
        let severeSpikeCount = validRTTs.filter { $0 > p50 + rule.severeSpikeOffset && $0 >= rule.severeSpikeFloor }.count
        let spikeRate = Double(spikeCount) / Double(validRTTs.count) * 100

        let components = QualityComponents(
            latency: component(p50, thresholds: rule.latency),
            loss: component(loss, thresholds: rule.loss),
            jitter: component(jitter, thresholds: rule.jitter),
            tail: component(ratio, thresholds: rule.tail),
            spikes: component(spikeRate, thresholds: rule.spikeRate),
            consistency: 0,
            stability: 0
        )
        let consistency = clamp(
            0.40 * components.jitter +
                0.30 * components.tail +
                0.20 * components.spikes +
                0.10 * components.loss,
            minimum: 0,
            maximum: 100
        )
        let completedComponents = QualityComponents(
            latency: components.latency,
            loss: components.loss,
            jitter: components.jitter,
            tail: components.tail,
            spikes: components.spikes,
            consistency: consistency,
            stability: min(components.spikes, consistency)
        )
        let metrics = QualityMetrics(
            validResponseCount: validRTTs.count,
            timeoutCount: timeoutCount,
            invalidResponseCount: invalidResponseCount,
            p50Milliseconds: p50,
            p95Milliseconds: p95,
            p99Milliseconds: p99,
            jitterMilliseconds: jitter,
            packetLossPercentage: loss,
            spikeCount: spikeCount,
            severeSpikeCount: severeSpikeCount,
            spikeRatePercentage: spikeRate,
            p95ToP50Ratio: ratio,
            worstSpikeMilliseconds: validRTTs.max(),
            components: completedComponents
        )
        let rawScore = Int((
            0.35 * completedComponents.latency +
                0.30 * completedComponents.loss +
                0.20 * completedComponents.jitter +
                0.15 * completedComponents.stability
        ).rounded(.toNearestOrAwayFromZero))

        var guardrails = Set<ScoreGuardrail>()
        var finalScore = rawScore
        if loss > rule.lossGuardrail || p50 > rule.latencyGuardrail {
            guardrails.insert(.excessiveLossOrLatency)
            finalScore = min(finalScore, 59)
        }
        if severeSpikeCount >= rule.severeSpikeGuardrailCount {
            guardrails.insert(.severeSpikes)
            finalScore = min(finalScore, 74)
        }

        return .completed(
            QualityResult(
                metrics: metrics,
                rawScore: rawScore,
                finalScore: finalScore,
                resultClass: resultClass(for: finalScore),
                appliedGuardrails: guardrails
            )
        )
    }
}

private extension QualityEvaluator {
    struct Thresholds {
        let excellent: Double
        let great: Double
        let unstable: Double
        let risk: Double
    }

    struct ProfileRule {
        let latency: Thresholds
        let loss: Thresholds
        let jitter: Thresholds
        let tail: Thresholds
        let spikeRate: Thresholds
        let spikeOffset: Double
        let spikeFloor: Double
        let severeSpikeOffset: Double
        let severeSpikeFloor: Double
        let lossGuardrail: Double
        let latencyGuardrail: Double
        let severeSpikeGuardrailCount: Int

        init(_ profile: QualityProfileID) {
            switch profile {
            case .battleRoyaleCompetitive:
                latency = .init(excellent: 40, great: 60, unstable: 90, risk: 100)
                loss = .init(excellent: 0, great: 1, unstable: 3, risk: 5)
                jitter = .init(excellent: 8, great: 15, unstable: 25, risk: 40)
                tail = .init(excellent: 1.10, great: 1.35, unstable: 1.75, risk: 2.50)
                spikeRate = .init(excellent: 0, great: 3, unstable: 10, risk: 20)
                spikeOffset = 30; spikeFloor = 80; severeSpikeOffset = 80; severeSpikeFloor = 150
                lossGuardrail = 3; latencyGuardrail = 100; severeSpikeGuardrailCount = 2
            case .mobileRealtime:
                latency = .init(excellent: 50, great: 80, unstable: 120, risk: 120)
                loss = .init(excellent: 0, great: 1, unstable: 5, risk: 8)
                jitter = .init(excellent: 12, great: 20, unstable: 35, risk: 50)
                tail = .init(excellent: 1.15, great: 1.50, unstable: 2.00, risk: 2.75)
                spikeRate = .init(excellent: 0, great: 4, unstable: 12, risk: 25)
                spikeOffset = 40; spikeFloor = 100; severeSpikeOffset = 100; severeSpikeFloor = 200
                lossGuardrail = 5; latencyGuardrail = 130; severeSpikeGuardrailCount = 2
            case .casualRealtime:
                latency = .init(excellent: 70, great: 110, unstable: 170, risk: 170)
                loss = .init(excellent: 0, great: 1, unstable: 3, risk: 5)
                jitter = .init(excellent: 20, great: 35, unstable: 50, risk: 65)
                tail = .init(excellent: 1.20, great: 1.60, unstable: 2.20, risk: 3.00)
                spikeRate = .init(excellent: 0, great: 5, unstable: 15, risk: 30)
                spikeOffset = 60; spikeFloor = 140; severeSpikeOffset = 140; severeSpikeFloor = 300
                lossGuardrail = 3; latencyGuardrail = 180; severeSpikeGuardrailCount = 3
            }
        }
    }
    static func diagnosticMetrics(
        validRTTs: [Double],
        timeoutCount: Int,
        invalidResponseCount: Int,
        loss: Double,
        rule: ProfileRule
    ) -> QualityMetrics {
        let p50 = validRTTs.isEmpty ? nil : percentile(validRTTs, percentile: 0.50)
        let p95 = validRTTs.isEmpty ? nil : percentile(validRTTs, percentile: 0.95)
        let p99 = validRTTs.isEmpty ? nil : percentile(validRTTs, percentile: 0.99)
        let jitter = validRTTs.isEmpty ? nil : averageAdjacentDifference(validRTTs)
        let ratio: Double?
        if let p50, let p95 {
            ratio = p50 == 0 ? (p95 == 0 ? 1 : .infinity) : p95 / p50
        } else {
            ratio = nil
        }
        let spikeCount = p50.map { median in
            validRTTs.filter { $0 > median + rule.spikeOffset && $0 >= rule.spikeFloor }.count
        } ?? 0
        let severeSpikeCount = p50.map { median in
            validRTTs.filter { $0 > median + rule.severeSpikeOffset && $0 >= rule.severeSpikeFloor }.count
        } ?? 0

        return QualityMetrics(
            validResponseCount: validRTTs.count,
            timeoutCount: timeoutCount,
            invalidResponseCount: invalidResponseCount,
            p50Milliseconds: p50,
            p95Milliseconds: p95,
            p99Milliseconds: p99,
            jitterMilliseconds: jitter,
            packetLossPercentage: loss,
            spikeCount: spikeCount,
            severeSpikeCount: severeSpikeCount,
            spikeRatePercentage: validRTTs.isEmpty ? 0 : Double(spikeCount) / Double(validRTTs.count) * 100,
            p95ToP50Ratio: ratio,
            worstSpikeMilliseconds: validRTTs.max(),
            components: nil
        )
    }

    static func percentile(_ values: [Double], percentile: Double) -> Double {
        let sorted = values.sorted()
        let position = Double(sorted.count - 1) * percentile
        let lowerIndex = Int(position.rounded(.down))
        let upperIndex = Int(position.rounded(.up))
        return sorted[lowerIndex] + (sorted[upperIndex] - sorted[lowerIndex]) * (position - Double(lowerIndex))
    }

    static func averageAdjacentDifference(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let total = zip(values, values.dropFirst()).reduce(0) { partial, pair in
            partial + abs(pair.1 - pair.0)
        }
        return total / Double(values.count - 1)
    }

    static func component(_ value: Double, excellent: Double, great: Double, unstable: Double, risk: Double) -> Double {
        if value <= excellent { return 100 }
        if value <= great { return interpolate(value, from: excellent...great, start: 100, end: 80) }
        if value <= unstable { return interpolate(value, from: great...unstable, start: 80, end: 60) }
        if value < risk { return interpolate(value, from: unstable...risk, start: 60, end: 0) }
        return 0
    }

    static func component(_ value: Double, thresholds: Thresholds) -> Double {
        component(value, excellent: thresholds.excellent, great: thresholds.great, unstable: thresholds.unstable, risk: thresholds.risk)
    }

    static func interpolate(_ value: Double, from input: ClosedRange<Double>, start: Double, end: Double) -> Double {
        let progress = (value - input.lowerBound) / (input.upperBound - input.lowerBound)
        return start + (end - start) * progress
    }

    static func clamp(_ value: Double, minimum: Double, maximum: Double) -> Double {
        min(max(value, minimum), maximum)
    }

    static func resultClass(for score: Int) -> ResultClass {
        switch score {
        case 90...: .excellent
        case 75...89: .great
        case 60...74: .unstable
        default: .lagRisk
        }
    }
}
