import SwiftUI
import NolaggyApplication
import NolaggyDesign

enum AppDestination: Hashable {
    case home
    case history
}

struct NolaggyAppConfiguration: Equatable {
    let supportURL: URL?
    let privacyPolicyURL: URL?

    init(bundle: Bundle = .main) {
        supportURL = Self.secureURL(bundle.object(forInfoDictionaryKey: "NolaggySupportURL") as? String)
        privacyPolicyURL = Self.secureURL(bundle.object(forInfoDictionaryKey: "NolaggyPrivacyPolicyURL") as? String)
    }

    init(supportURL: URL?, privacyPolicyURL: URL?) {
        self.supportURL = supportURL.flatMap(Self.secureURL)
        self.privacyPolicyURL = privacyPolicyURL.flatMap(Self.secureURL)
    }

    private static func secureURL(_ rawValue: String?) -> URL? {
        guard let rawValue, let url = URL(string: rawValue), url.scheme == "https", url.host != nil else { return nil }
        return url
    }

    private static func secureURL(_ url: URL) -> URL? {
        url.scheme == "https" && url.host != nil ? url : nil
    }
}

struct NolaggyAppHeader: View {
    let openSettings: () -> Void
    let openSearch: (() -> Void)?

    init(openSettings: @escaping () -> Void, openSearch: (() -> Void)? = nil) {
        self.openSettings = openSettings
        self.openSearch = openSearch
    }

    var body: some View {
        HStack(spacing: NLSpacing.md) {
            Image("WordmarkPrimary", bundle: .main)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 110, height: 30)
                .accessibilityLabel(Text("nolaggy"))
            Spacer()
            if let openSearch {
                NolaggyHeaderActionGroup(openSettings: openSettings, openSearch: openSearch)
            } else {
                NolaggyNavigationControl(
                    systemImage: "ellipsis",
                    accessibilityLabel: "navigation.open_settings",
                    accessibilityIdentifier: "navigation-settings-open",
                    action: openSettings
                )
            }
        }
    }
}

private struct NolaggyHeaderActionGroup: View {
    let openSettings: () -> Void
    let openSearch: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            action(
                systemImage: "magnifyingglass",
                accessibilityLabel: "catalog.search.accessibility",
                accessibilityIdentifier: "catalog-search-open",
                action: openSearch
            )
            action(
                systemImage: "ellipsis",
                accessibilityLabel: "navigation.open_settings",
                accessibilityIdentifier: "navigation-settings-open",
                action: openSettings
            )
        }
        .foregroundStyle(NLColor.accentPrimary)
        .modifier(NolaggyHeaderActionGroupGlass())
    }

    private func action(
        systemImage: String,
        accessibilityLabel: LocalizedStringKey,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(NLTypography.navigationIcon)
                .frame(width: NLSizing.touchTarget, height: NLSizing.touchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

private struct NolaggyHeaderActionGroupGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: Capsule())
        } else {
            content
        }
    }
}

/// Mantém a affordance de retorno igual em fluxos de estado e telas apresentadas.
/// A área de toque atende ao mínimo do iOS, mas a seta não ganha um contêiner visual próprio.
struct NolaggyBackButton: View {
    let action: () -> Void
    let accessibilityIdentifier: String?

    init(action: @escaping () -> Void, accessibilityIdentifier: String? = nil) {
        self.action = action
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    var body: some View {
        NolaggyNavigationControl(
            systemImage: "chevron.backward",
            accessibilityLabel: "quick_check.back",
            accessibilityIdentifier: accessibilityIdentifier ?? "nolaggy-back",
            action: action
        )
    }
}

/// Cabeçalho mínimo das telas internas. A wordmark é exclusiva da Home;
/// fora dela, a jornada prioriza conteúdo e uma única ação de retorno.
struct NolaggyBackHeader: View {
    let action: () -> Void
    let accessibilityIdentifier: String

    var body: some View {
        HStack {
            NolaggyBackButton(action: action, accessibilityIdentifier: accessibilityIdentifier)
            Spacer()
        }
    }
}

/// Controle de navegação único: menu e retorno ocupam o mesmo alvo de 44 pt.
/// No iOS 26 usa o vidro do próprio sistema; em versões anteriores preserva o
/// botão de barra nativo, sem cápsula ou fundo desenhado pelo app.
private struct NolaggyNavigationControl: View {
    let systemImage: String
    let accessibilityLabel: LocalizedStringKey
    let accessibilityIdentifier: String
    let action: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            control
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: Circle())
        } else {
            control.buttonStyle(.plain)
        }
    }

    private var control: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(NLTypography.navigationIcon)
                .frame(width: NLSizing.touchTarget, height: NLSizing.touchTarget)
                .contentShape(Rectangle())
        }
        .foregroundStyle(NLColor.accentPrimary)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

/// Superfície visual única do app, aplicada como base de cada tela e nunca
/// recriada com cores soltas em features individuais.
struct NolaggyScreenBackground: View {
    var body: some View {
        LinearGradient(
            colors: [NLColor.backgroundBase, NLColor.backgroundOverlay],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

// SettingsView vive em Features/Settings/SettingsView.swift.
