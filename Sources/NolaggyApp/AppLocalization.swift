import Foundation

/// Resolves strings against the language chosen in Settings, falling back to the
/// current system language when the user chose the automatic option.
enum AppLocalization {
    static let selectedLanguageKey = "app_selected_language"

    static var language: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: selectedLanguageKey) ?? AppLanguage.system.rawValue) ?? .system
    }

    static var locale: Locale { language.locale }

    static func string(_ key: String, comment: String = "") -> String {
        language.localizedString(key)
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: locale, arguments: arguments)
    }
}
