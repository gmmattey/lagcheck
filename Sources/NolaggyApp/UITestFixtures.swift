import Foundation
import NolaggyDomain

/// Dados exclusivos de revisão visual no simulador. Não são rota, transporte ou fallback de rede.
enum UITestFixtures {
    static let launchArgument = "-ui-fixture-valid-result"
    static let resetLanguageArgument = "-ui-fixture-reset-language"

    static func isEnabled(_ argument: String) -> Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains(argument)
        #else
        false
        #endif
    }

    static var validEntry: MeasurementHistoryEntry {
        let context = try! PilotCatalog.pilotBase.resolve(GameContext(gameID: "fortnite", market: "BR", platform: .iphone))
        let metrics = QualityMetrics(
            validResponseCount: 30, timeoutCount: 0, invalidResponseCount: 0,
            p50Milliseconds: 24, p95Milliseconds: 41, p99Milliseconds: 58, jitterMilliseconds: 3,
            packetLossPercentage: 0, spikeCount: 2, severeSpikeCount: 0, spikeRatePercentage: 6.67,
            p95ToP50Ratio: 1.71, worstSpikeMilliseconds: 72,
            components: QualityComponents(latency: 100, loss: 100, jitter: 100, tail: 62, spikes: 76, consistency: 80, stability: 76)
        )
        return MeasurementHistoryEntry(
            completedAt: Date(), resolvedContext: context, profileRuleVersion: context.catalogVersion,
            result: QualityResult(metrics: metrics, rawScore: 92, finalScore: 92, resultClass: .excellent, appliedGuardrails: []),
            primaryCause: .stableConnection
        )
    }

    static var inconclusiveEntry: MeasurementHistoryEntry {
        let context = try! PilotCatalog.pilotBase.resolve(GameContext(gameID: "fortnite", market: "BR", platform: .iphone))
        let metrics = QualityMetrics(
            validResponseCount: 0, timeoutCount: 30, invalidResponseCount: 0,
            p50Milliseconds: nil, p95Milliseconds: nil, p99Milliseconds: nil, jitterMilliseconds: nil,
            packetLossPercentage: 100, spikeCount: 0, severeSpikeCount: 0, spikeRatePercentage: 0,
            p95ToP50Ratio: nil, worstSpikeMilliseconds: nil, components: nil
        )
        return MeasurementHistoryEntry(
            completedAt: Date(), resolvedContext: context, profileRuleVersion: context.catalogVersion,
            result: QualityResult(metrics: metrics, rawScore: 0, finalScore: 0, resultClass: .unstable, appliedGuardrails: []),
            primaryCause: .packetLoss
        )
    }

    static let validSamples: [ProbeSample] = [24, 26, 23, 29, 25, 72, 24, 27, 22, 28, 25, 24, 41, 26, 23, 25].enumerated().map {
        ProbeSample(sequence: $0.offset, roundTripMilliseconds: Double($0.element), outcome: .received)
    }

    static var validDeepResult: DeepCheckResult {
        let rest = validEntry.result
        let load = QualityMetrics(
            validResponseCount: 30, timeoutCount: 0, invalidResponseCount: 0,
            p50Milliseconds: 91, p95Milliseconds: 116, p99Milliseconds: 128, jitterMilliseconds: 19,
            packetLossPercentage: 0, spikeCount: 4, severeSpikeCount: 0, spikeRatePercentage: 13.33,
            p95ToP50Ratio: 1.27, worstSpikeMilliseconds: 132,
            components: QualityComponents(latency: 65, loss: 100, jitter: 44, tail: 50, spikes: 55, consistency: 50, stability: 50)
        )
        return DeepCheckResult(
            restResult: rest,
            metrics: DeepCheckMetrics(
                rest: rest.metrics,
                load: load,
                loadImpact: DeepCheckLoadImpact(restP50Milliseconds: 24, loadP50Milliseconds: 91)
            )
        )
    }
}
