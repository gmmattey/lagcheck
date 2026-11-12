import Foundation
import NolaggyApplication

/// Persiste somente um identificador de região textual, escolhido em Configurações.
/// Nenhum dado de localização, IP ou rede é lido ou salvo aqui.
public actor UserDefaultsRegionalPreferenceRepository: RegionalPreferenceRepository {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "nolaggy.regionalPreference.manualRegionID") {
        self.defaults = defaults
        self.key = key
    }

    public func manualRegionID() async -> String? {
        defaults.string(forKey: key)
    }

    public func setManualRegionID(_ regionID: String?) async {
        if let regionID {
            defaults.set(regionID, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
