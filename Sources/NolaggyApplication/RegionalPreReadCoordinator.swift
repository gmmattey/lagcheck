import Foundation
import NolaggyDomain

/// Adaptador de infraestrutura: coleta exatamente a janela curta autorizada
/// para um destino já presente no snapshot. Não recebe URL nem hostname livre.
public protocol RegionalPreReadCollecting: Sendable {
    func collect(candidate: RegionalSelectionCandidate) async -> [RegionalPreReadSample]
}

/// Coordena somente a pré-leitura. O resultado é entregue ao domínio para a
/// regra versionada; estas amostras não entram na sessão de score ou histórico.
public actor RegionalPreReadCoordinator {
    private let collector: any RegionalPreReadCollecting
    private var task: Task<RegionalSelectionDecision, Error>?

    public init(collector: any RegionalPreReadCollecting) { self.collector = collector }

    public func select(
        snapshot: RegionalSelectionSnapshot,
        manualRegionID: String? = nil
    ) async throws -> RegionalSelectionDecision {
        guard task == nil else { throw MeasurementSessionError.alreadyActive }
        try Task.checkCancellation()
        let worker = Task { [collector] () throws -> RegionalSelectionDecision in
            let candidates = manualRegionID.flatMap { id in snapshot.candidates.first(where: { $0.regionID == id }).map { [$0] } } ?? snapshot.candidates
            if manualRegionID != nil, candidates.isEmpty { throw RegionalSelectionError.manualCandidateNotAllowed }
            let samples = await withTaskGroup(of: (String, [RegionalPreReadSample]).self) { group in
                for candidate in candidates { group.addTask { (candidate.regionID, await collector.collect(candidate: candidate)) } }
                var result: [String: [RegionalPreReadSample]] = [:]
                for await (regionID, values) in group { result[regionID] = values }
                return result
            }
            try Task.checkCancellation()
            return try RegionalSelectionRule.select(snapshot: snapshot, preReadSamples: samples, manualRegionID: manualRegionID)
        }
        task = worker
        defer { task = nil }
        return try await worker.value
    }

    public func cancel() {
        task?.cancel()
        task = nil
    }

    public func appDidEnterBackground() { cancel() }
    public func networkPathDidChange() { cancel() }
}
