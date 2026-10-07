import Foundation
import NolaggyDomain

/// Repositório e gerenciador do snapshot de telemetria compartilhado entre o App e Widgets.
/// Utiliza App Group "group.com.lagcheck.app" com fallback gracioso para UserDefaults.standard.
/// Decisão 75 (Fase 2 / Item 6): "Zero Mock / Nunca uma Nota Inventada".
public final class SharedAppGroupStore: @unchecked Sendable {
    public static let shared = SharedAppGroupStore()

    public static let appGroupIdentifier = "group.com.lagcheck.app"
    public static let snapshotKey = "lagcheck.shared.telemetry.snapshot"

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

    /// Limpa o snapshot compartilhado (usado em testes ou reset de diagnóstico).
    public func clearSnapshot() {
        userDefaults.removeObject(forKey: SharedAppGroupStore.snapshotKey)
    }
}
