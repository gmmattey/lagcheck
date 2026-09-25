import Foundation
import NolaggyApplication

/// Implementação em memória do `AnalyticsTracker`, segura para concorrência (`@unchecked Sendable`).
/// Útil para testes automatizados, validação de fluxo e inspeção de funil.
public final class InMemoryAnalyticsTracker: AnalyticsTracker, @unchecked Sendable {
    private let lock = NSLock()
    private var _events: [(event: AnalyticsEvent, timestamp: Date)] = []

    public init() {}

    public func track(_ event: AnalyticsEvent) {
        lock.lock()
        defer { lock.unlock() }
        _events.append((event, Date()))
    }

    public var events: [AnalyticsEvent] {
        lock.lock()
        defer { lock.unlock() }
        return _events.map(\.event)
    }

    public var recordedCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _events.count
    }

    public func events(named name: String) -> [AnalyticsEvent] {
        lock.lock()
        defer { lock.unlock() }
        return _events.filter { $0.event.name == name }.map(\.event)
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        _events.removeAll()
    }
}
