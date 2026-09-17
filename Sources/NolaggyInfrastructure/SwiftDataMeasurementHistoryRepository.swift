import Foundation
import SwiftData
import NolaggyApplication
import NolaggyDomain

@Model
private final class StoredMeasurementRecord {
    @Attribute(.unique) var id: UUID
    var gameID: String
    var completedAt: Date
    var snapshot: Data

    init(entry: MeasurementHistoryEntry, snapshot: Data) {
        id = entry.id
        gameID = entry.resolvedContext.context.gameID
        completedAt = entry.completedAt
        self.snapshot = snapshot
    }
}

/// Repositório local. A retenção é aplicada aqui, nunca por uma View.
public actor SwiftDataMeasurementHistoryRepository: MeasurementHistoryRepository {
    private let container: ModelContainer
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(inMemory: Bool = false) throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        container = try ModelContainer(for: StoredMeasurementRecord.self, configurations: configuration)
    }

    public func save(_ entry: MeasurementHistoryEntry) throws {
        let context = ModelContext(container)
        let payload = try encoder.encode(entry)
        context.insert(StoredMeasurementRecord(entry: entry, snapshot: payload))
        try applyRetention(in: context, now: entry.completedAt)
        try context.save()
    }

    public func loadHistory() throws -> [MeasurementHistoryEntry] {
        let context = ModelContext(container)
        try applyRetention(in: context, now: Date())
        try context.save()
        return try fetchEntries(in: context)
    }

    public func deleteAll() throws {
        let context = ModelContext(container)
        try context.delete(model: StoredMeasurementRecord.self)
        try context.save()
    }

    private func applyRetention(in context: ModelContext, now: Date) throws {
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: now) ?? now
        let expired = try context.fetch(FetchDescriptor<StoredMeasurementRecord>(predicate: #Predicate { $0.completedAt < cutoff }))
        expired.forEach(context.delete)

        let records = try context.fetch(FetchDescriptor<StoredMeasurementRecord>(sortBy: [SortDescriptor(\StoredMeasurementRecord.completedAt, order: .reverse)]))
        var retainedByGame: [String: Int] = [:]
        for record in records {
            let retained = retainedByGame[record.gameID, default: 0]
            if retained >= 100 {
                context.delete(record)
            } else {
                retainedByGame[record.gameID] = retained + 1
            }
        }
    }

    /// Um único registro que não decodifica mais (ex.: sobra de uma versão
    /// anterior do app com um formato de snapshot diferente) não pode apagar
    /// o histórico inteiro da leitura. Ele é ignorado nesta leitura; a rotina
    /// de retenção continua livre para removê-lo fisicamente mais tarde.
    private func fetchEntries(in context: ModelContext) throws -> [MeasurementHistoryEntry] {
        let records = try context.fetch(FetchDescriptor<StoredMeasurementRecord>(sortBy: [SortDescriptor(\StoredMeasurementRecord.completedAt, order: .reverse)]))
        return records.compactMap { try? decoder.decode(MeasurementHistoryEntry.self, from: $0.snapshot) }
    }
}
