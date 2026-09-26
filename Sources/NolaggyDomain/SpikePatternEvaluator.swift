import Foundation

/// Classificação temporal da ocorrência de spikes durante uma medição (Decisão 55).
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
        case .isolated(let count, _), .recurring(let count, _): return count
        }
    }

    public var severeCount: Int {
        switch self {
        case .none: return 0
        case .isolated(_, let severeCount), .recurring(_, let severeCount): return severeCount
        }
    }
}

/// Avaliador determinístico da distribuição temporal de spikes (spike-pattern-v1).
public enum SpikePatternEvaluator {
    public static let version = "spike-pattern-v1"

    public static func evaluate(
        samples: [ProbeSample],
        p50Milliseconds: Double,
        spikeDelta: Double = 30.0,
        spikeAbsoluteMin: Double = 80.0,
        severeDelta: Double = 80.0,
        severeAbsoluteMin: Double = 150.0
    ) -> SpikePattern {
        let validSamples = samples.filter(\.isValidResponse)
        guard !validSamples.isEmpty else { return .none }

        var totalSpikes = 0
        var totalSevereSpikes = 0
        var isSpikeFlags: [Bool] = []

        for sample in validSamples {
            guard let rtt = sample.roundTripMilliseconds else {
                isSpikeFlags.append(false)
                continue
            }
            let isSevere = (rtt > p50Milliseconds + severeDelta) && (rtt >= severeAbsoluteMin)
            let isSpike = isSevere || ((rtt > p50Milliseconds + spikeDelta) && (rtt >= spikeAbsoluteMin))

            if isSpike { totalSpikes += 1 }
            if isSevere { totalSevereSpikes += 1 }
            isSpikeFlags.append(isSpike)
        }

        guard totalSpikes > 0 else { return .none }

        // Critério de recorrência (Decisão 55):
        // 1. Total de spikes >= 3
        // 2. OU >= 2 spikes em qualquer janela de até 5 probes consecutivos
        if totalSpikes >= 3 {
            return .recurring(count: totalSpikes, severeCount: totalSevereSpikes)
        }

        if isSpikeFlags.count >= 2 {
            for i in 0..<isSpikeFlags.count {
                let windowEnd = min(i + 5, isSpikeFlags.count)
                let windowSpikes = isSpikeFlags[i..<windowEnd].filter { $0 }.count
                if windowSpikes >= 2 {
                    return .recurring(count: totalSpikes, severeCount: totalSevereSpikes)
                }
            }
        }

        return .isolated(count: totalSpikes, severeCount: totalSevereSpikes)
    }
}
