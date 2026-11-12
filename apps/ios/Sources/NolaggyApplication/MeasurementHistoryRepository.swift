import Foundation
import NolaggyDomain

/// Fronteira de aplicação: a UI não conhece SwiftData e o domínio não conhece armazenamento.
public protocol MeasurementHistoryRepository: Sendable {
    func save(_ entry: MeasurementHistoryEntry) async throws
    func loadHistory() async throws -> [MeasurementHistoryEntry]
    func deleteAll() async throws
}

public struct NoopMeasurementHistoryRepository: MeasurementHistoryRepository {
    public init() {}
    public func save(_: MeasurementHistoryEntry) async throws {}
    public func loadHistory() async throws -> [MeasurementHistoryEntry] { [] }
    public func deleteAll() async throws {}
}
