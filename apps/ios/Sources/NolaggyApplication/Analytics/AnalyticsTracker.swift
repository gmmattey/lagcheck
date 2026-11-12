import Foundation

/// Protocolo abstrato para rastreamento de eventos de analytics no LagCheck.
/// Permite injeção limpa de dependências nos coordenadores e features da UI.
public protocol AnalyticsTracker: Sendable {
    func track(_ event: AnalyticsEvent)
}

/// Implementação silenciosa (no-op) para testes e fixtures.
public struct NoopAnalyticsTracker: AnalyticsTracker {
    public init() {}
    public func track(_ event: AnalyticsEvent) {}
}
