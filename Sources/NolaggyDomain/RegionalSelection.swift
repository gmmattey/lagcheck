import Foundation

/// Regra determinística para escolher uma referência regional antes da janela
/// que produz score. O snapshot deve ser criado a partir de um catálogo remoto
/// já verificado; esta regra não abre sockets, resolve DNS nem infere localização.
public struct RegionalSelectionSnapshot: Equatable, Sendable {
    public let catalogVersion: String
    public let context: GameContext
    public let candidates: [RegionalSelectionCandidate]

    public init(
        catalogVersion: String,
        context: GameContext,
        candidates: [RegionalSelectionCandidate]
    ) throws {
        guard !catalogVersion.isEmpty, !candidates.isEmpty else {
            throw RegionalSelectionError.invalidSnapshot
        }
        guard Set(candidates.map(\.regionID)).count == candidates.count else {
            throw RegionalSelectionError.duplicateCandidateRegion
        }
        guard candidates.allSatisfy({ candidate in
            candidate.resolvedContext.catalogVersion == catalogVersion &&
            candidate.resolvedContext.context == context
        }) else {
            throw RegionalSelectionError.candidateOutsideSnapshot
        }
        self.catalogVersion = catalogVersion
        self.context = context
        self.candidates = candidates
    }
}

/// Candidato autorizado pelo snapshot validado. A prioridade menor vence apenas
/// depois de P50 e quantidade de respostas, conforme `regional-selection-1`.
public struct RegionalSelectionCandidate: Equatable, Sendable {
    public let resolvedContext: ResolvedMeasurementContext
    public let priority: Int

    public init(resolvedContext: ResolvedMeasurementContext, priority: Int) throws {
        guard priority >= 0 else { throw RegionalSelectionError.invalidPriority }
        self.resolvedContext = resolvedContext
        self.priority = priority
    }

    public var regionID: String { resolvedContext.regionID }
}

/// Uma resposta já correlacionada pelo coordenador durante a pré-leitura UDP.
/// Respostas inválidas, timeouts e RTTs não finitos nunca tornam um candidato elegível.
public struct RegionalPreReadSample: Equatable, Sendable {
    public let outcome: ProbeOutcome
    public let roundTripMilliseconds: Double?

    public init(outcome: ProbeOutcome, roundTripMilliseconds: Double? = nil) {
        self.outcome = outcome
        self.roundTripMilliseconds = roundTripMilliseconds
    }

    fileprivate var validRoundTripMilliseconds: Double? {
        guard outcome == .received,
              let roundTripMilliseconds,
              roundTripMilliseconds.isFinite,
              roundTripMilliseconds >= 0 else {
            return nil
        }
        return roundTripMilliseconds
    }
}

public enum RegionalSelectionMode: String, Equatable, Sendable {
    case automatic
    case manual
}

public enum RegionalSelectionInconclusiveReason: String, Equatable, Sendable {
    case noViableRegionalCandidate
}

public enum RegionalSelectionDecision: Equatable, Sendable {
    case selected(RegionalSelectionResult)
    case inconclusive(RegionalSelectionInconclusiveReason)
}

public struct RegionalSelectionResult: Equatable, Sendable {
    public let ruleVersion: String
    public let catalogVersion: String
    public let mode: RegionalSelectionMode
    public let selected: RegionalSelectionCandidate
    public let p50Milliseconds: Double
    public let validResponseCount: Int
}

public enum RegionalSelectionError: Error, Equatable, Sendable {
    case invalidSnapshot
    case duplicateCandidateRegion
    case candidateOutsideSnapshot
    case invalidPriority
    case manualCandidateNotAllowed
}

public enum RegionalSelectionRule {
    public static let version = "regional-selection-1"
    public static let minimumValidResponses = 2
    public static let clearLeadMilliseconds = 6.0
    public static let tieWindowMilliseconds = 5.0

    /// Seleciona exclusivamente entre candidatos já autorizados pelo snapshot.
    /// A ausência de duas respostas válidas em todos eles é inconclusiva e não
    /// possui fallback para outro transporte ou destino.
    public static func select(
        snapshot: RegionalSelectionSnapshot,
        preReadSamples: [String: [RegionalPreReadSample]],
        manualRegionID: String? = nil
    ) throws -> RegionalSelectionDecision {
        let candidates: [RegionalSelectionCandidate]
        let mode: RegionalSelectionMode
        if let manualRegionID {
            guard let candidate = snapshot.candidates.first(where: { $0.regionID == manualRegionID }) else {
                throw RegionalSelectionError.manualCandidateNotAllowed
            }
            candidates = [candidate]
            mode = .manual
        } else {
            candidates = snapshot.candidates
            mode = .automatic
        }

        let eligible = candidates.compactMap { candidate -> EvaluatedCandidate? in
            let validRTTs = (preReadSamples[candidate.regionID] ?? []).compactMap(\.validRoundTripMilliseconds)
            guard validRTTs.count >= minimumValidResponses,
                  let p50 = percentile(validRTTs, percentile: 0.5) else {
                return nil
            }
            return EvaluatedCandidate(candidate: candidate, p50Milliseconds: p50, validResponseCount: validRTTs.count)
        }

        guard !eligible.isEmpty else {
            return .inconclusive(.noViableRegionalCandidate)
        }

        let winner: EvaluatedCandidate
        if eligible.count == 1 {
            winner = eligible[0]
        } else if let clearLeader = eligible.first(where: { contender in
            eligible.allSatisfy { other in
                other.candidate.regionID == contender.candidate.regionID ||
                contender.p50Milliseconds + clearLeadMilliseconds <= other.p50Milliseconds
            }
        }) {
            winner = clearLeader
        } else {
            let minimumP50 = eligible.map(\.p50Milliseconds).min()!
            winner = eligible
                .filter { $0.p50Milliseconds <= minimumP50 + tieWindowMilliseconds }
                .sorted(by: tieBreak)
                .first!
        }

        return .selected(RegionalSelectionResult(
            ruleVersion: version,
            catalogVersion: snapshot.catalogVersion,
            mode: mode,
            selected: winner.candidate,
            p50Milliseconds: winner.p50Milliseconds,
            validResponseCount: winner.validResponseCount
        ))
    }

    private struct EvaluatedCandidate {
        let candidate: RegionalSelectionCandidate
        let p50Milliseconds: Double
        let validResponseCount: Int
    }

    private static func tieBreak(_ lhs: EvaluatedCandidate, _ rhs: EvaluatedCandidate) -> Bool {
        if lhs.validResponseCount != rhs.validResponseCount {
            return lhs.validResponseCount > rhs.validResponseCount
        }
        if lhs.candidate.priority != rhs.candidate.priority {
            return lhs.candidate.priority < rhs.candidate.priority
        }
        return lhs.candidate.regionID < rhs.candidate.regionID
    }

    private static func percentile(_ values: [Double], percentile: Double) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let position = percentile * Double(sorted.count - 1)
        let lowerIndex = Int(position.rounded(.down))
        let upperIndex = Int(position.rounded(.up))
        guard lowerIndex != upperIndex else { return sorted[lowerIndex] }
        let fraction = position - Double(lowerIndex)
        return sorted[lowerIndex] + (sorted[upperIndex] - sorted[lowerIndex]) * fraction
    }
}
