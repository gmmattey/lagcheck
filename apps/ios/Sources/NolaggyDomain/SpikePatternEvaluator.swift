import Foundation
import LagCheckEngine

/// Padrão temporal de picos de latência classificado pelo motor KMP (Decisões 55, 134 e 135).
public enum SpikePattern: Codable, Equatable, Hashable, Sendable {
    case none
    case isolated(count: Int, severeCount: Int)
    case recurring(count: Int, severeCount: Int)

    public var isRecurring: Bool {
        if case .recurring = self { return true }
        return false
    }

    public var count: Int {
        switch self {
        case .none: return 0
        case .isolated(let count, _): return count
        case .recurring(let count, _): return count
        }
    }

    public var severeCount: Int {
        switch self {
        case .none: return 0
        case .isolated(_, let severe): return severe
        case .recurring(_, let severe): return severe
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case count
        case severeCount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let count = try container.decodeIfPresent(Int.self, forKey: .count) ?? 0
        let severeCount = try container.decodeIfPresent(Int.self, forKey: .severeCount) ?? 0
        switch type {
        case "isolated": self = .isolated(count: count, severeCount: severeCount)
        case "recurring": self = .recurring(count: count, severeCount: severeCount)
        default: self = .none
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none:
            try container.encode("none", forKey: .type)
        case .isolated(let count, let severeCount):
            try container.encode("isolated", forKey: .type)
            try container.encode(count, forKey: .count)
            try container.encode(severeCount, forKey: .severeCount)
        case .recurring(let count, let severeCount):
            try container.encode("recurring", forKey: .type)
            try container.encode(count, forKey: .count)
            try container.encode(severeCount, forKey: .severeCount)
        }
    }
}

/// Avaliador determinístico da distribuição temporal de spikes via motor KMP (Decisões 55, 134 e 135).
public enum SpikePatternEvaluator {
    public static var version: String {
        EnginePolicyProvider.policy.ruleVersions["BATTLE_ROYALE_COMPETITIVE"]?["spikePattern"] ?? "spike-pattern-v2"
    }

    public static func evaluate(
        samples: [ProbeSample],
        p50Milliseconds: Double,
        spikeDelta: Double = 30.0,
        spikeAbsoluteMin: Double = 80.0,
        severeDelta: Double = 80.0,
        severeAbsoluteMin: Double = 150.0
    ) -> SpikePattern {
        evaluate(samples: samples, p50Milliseconds: p50Milliseconds, profile: .battleRoyaleCompetitive)
    }

    public static func evaluate(
        samples: [ProbeSample],
        p50Milliseconds: Double,
        profile: QualityProfileID
    ) -> SpikePattern {
        let req = EngineRequestDTO(
            source: "APP_UDP",
            profile: LagCheckEngineBridge.toProfileKey(profile),
            rest: samples.map { LagCheckEngineBridge.toSampleDTO($0) },
            loadTransfer: "NOT_RUN"
        )
        let res = LagCheckEngineBridge.evaluate(request: req)
        return LagCheckEngineBridge.toSpikePattern(
            res.spikePattern,
            count: res.rest.spikeCount,
            severeCount: res.rest.severeSpikeCount
        )
    }
}
