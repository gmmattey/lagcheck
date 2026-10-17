import Foundation
import NolaggyDomain

/// Repositório e gerenciador do snapshot de telemetria compartilhado entre o App e Widgets.
/// Utiliza App Group "group.com.lagcheck.app" com fallback gracioso para UserDefaults.standard.
/// Decisão 75 (Fase 2 / Item 6): "Zero Mock / Nunca uma Nota Inventada".
public final class SharedAppGroupStore: @unchecked Sendable {
    public static let shared = SharedAppGroupStore()

    public static let appGroupIdentifier = "group.com.lagcheck.app"
    public static let snapshotKey = "lagcheck.shared.telemetry.snapshot"
    public static let artworkKey = "lagcheck.shared.telemetry.artwork"
    public static let maximumArtworkBytes = 1_000_000

    private let userDefaults: UserDefaults

    public init(suiteName: String? = SharedAppGroupStore.appGroupIdentifier) {
        if let suite = suiteName, let defaults = UserDefaults(suiteName: suite) {
            self.userDefaults = defaults
        } else {
            self.userDefaults = .standard
        }
    }

    /// Salva o snapshot imutável da última medição real.
    public func saveLatestSnapshot(_ snapshot: WidgetTelemetrySnapshot) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(snapshot) {
            userDefaults.set(data, forKey: SharedAppGroupStore.snapshotKey)
        }
    }

    /// Carrega o snapshot mais recente salvo no App Group.
    /// Retorna nil caso não exista ou esteja corrompido.
    public func loadLatestSnapshot() -> WidgetTelemetrySnapshot? {
        guard let data = userDefaults.data(forKey: SharedAppGroupStore.snapshotKey) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode(WidgetTelemetrySnapshot.self, from: data)
    }

    /// A miniatura é um derivado local da arte já aprovada pelo cliente iOS.
    /// O widget nunca baixa arte nem consulta o catálogo por conta própria.
    @discardableResult
    public func saveLatestArtwork(_ data: Data?) -> Bool {
        guard let data, !data.isEmpty, data.count <= Self.maximumArtworkBytes else {
            userDefaults.removeObject(forKey: Self.artworkKey)
            return false
        }
        userDefaults.set(data, forKey: Self.artworkKey)
        return true
    }

    public func loadLatestArtwork() -> Data? {
        guard let data = userDefaults.data(forKey: Self.artworkKey),
              !data.isEmpty, data.count <= Self.maximumArtworkBytes else { return nil }
        return data
    }

    /// Limpa o snapshot compartilhado (usado em testes ou reset de diagnóstico).
    public func clearSnapshot() {
        userDefaults.removeObject(forKey: SharedAppGroupStore.snapshotKey)
        userDefaults.removeObject(forKey: SharedAppGroupStore.artworkKey)
    }
}
