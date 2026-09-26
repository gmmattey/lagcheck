import Foundation

/// Resultado isolado de probe no gateway local (Decisões 50 e 55).
/// Separa com evidência estrita o enlace Wi-Fi doméstico da rota externa da operadora.
public enum GatewayProbeOutcome: Codable, Hashable, Sendable {
    /// Roteador local respondeu com baixa latência e zero perda (RTT <= 15 ms).
    case stable(rttMilliseconds: Double)
    /// Roteador local apresentou oscilação, perda ou latência elevada (> 15 ms).
    case degraded(rttMilliseconds: Double, lossPercentage: Double)
    /// Roteador não responde a probes UDP locais (firewall doméstico fechado).
    /// O enlace local é considerado não observável, sem inventar dados e sem acusar o Wi-Fi.
    case unobservable

    public var isDegraded: Bool {
        if case .degraded = self { return true }
        return false
    }

    public var isStable: Bool {
        if case .stable = self { return true }
        return false
    }

    public var rttMs: Double? {
        switch self {
        case .stable(let rtt): return rtt
        case .degraded(let rtt, _): return rtt
        case .unobservable: return nil
        }
    }
}
