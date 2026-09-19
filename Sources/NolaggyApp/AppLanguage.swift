import SwiftUI

/// Idiomas suportados pelo LagCheck para seleção in-app (Decisão 33 e Correção de UX).
public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system = "system"
    case ptBR = "pt-BR"
    case en = "en"
    case es = "es"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system:
            return NSLocalizedString("settings.language.system", comment: "")
        case .ptBR:
            return "Português (Brasil)"
        case .en:
            return "English"
        case .es:
            return "Español"
        }
    }

    public var locale: Locale {
        switch self {
        case .system:
            return Locale.autoupdatingCurrent
        case .ptBR:
            return Locale(identifier: "pt-BR")
        case .en:
            return Locale(identifier: "en")
        case .es:
            return Locale(identifier: "es")
        }
    }

    public var bundle: Bundle {
        guard self != .system,
              let path = Bundle.main.path(forResource: rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return Bundle.main
        }
        return bundle
    }

    public func localizedString(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
