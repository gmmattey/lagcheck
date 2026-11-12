import Foundation

/// Preferência de região manual, persistida localmente e opcional. Quando
/// presente, é aplicada como override automático na próxima seleção regional.
/// Se deixar de ser um candidato válido para o contexto (jogo/mercado/plataforma
/// mudou o catálogo), a sessão cai para seleção automática em vez de falhar —
/// nunca é uma escolha feita durante a medição, sempre uma preferência prévia.
public protocol RegionalPreferenceRepository: Sendable {
    func manualRegionID() async -> String?
    func setManualRegionID(_ regionID: String?) async
}

public actor NoopRegionalPreferenceRepository: RegionalPreferenceRepository {
    public init() {}
    public func manualRegionID() async -> String? { nil }
    public func setManualRegionID(_ regionID: String?) async {}
}
