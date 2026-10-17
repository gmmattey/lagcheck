import SwiftUI
import NolaggyApplication
import NolaggyDesign

enum AppDestination: Hashable {
    case home
    case history
}

enum AppTab: String, Hashable, CaseIterable {
    case home
    case games
    case history
    case settings
}

struct NolaggyAppConfiguration: Equatable {
    let supportURL: URL?
    let privacyPolicyURL: URL?

    init(bundle: Bundle = .main) {
        let rawSupport = (bundle.object(forInfoDictionaryKey: "LagCheckSupportURL") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "NolaggySupportURL") as? String)
        let rawPrivacy = (bundle.object(forInfoDictionaryKey: "LagCheckPrivacyPolicyURL") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "NolaggyPrivacyPolicyURL") as? String)
        supportURL = Self.secureURL(rawSupport)
        privacyPolicyURL = Self.secureURL(rawPrivacy)
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
    let openNetworkCockpit: (() -> Void)?

    init(
        openSettings: @escaping () -> Void,
        openSearch: (() -> Void)? = nil,
        openNetworkCockpit: (() -> Void)? = nil
    ) {
        self.openSettings = openSettings
        self.openSearch = openSearch
        self.openNetworkCockpit = openNetworkCockpit
    }

    var body: some View {
        HStack(spacing: NLSpacing.sm) {
            Image("WordmarkPrimary", bundle: .main)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 110, height: 30)
                .accessibilityLabel(Text("LagCheck"))

            Spacer()

            if let openNetworkCockpit {
                NolaggyNavigationControl(
                    systemImage: "network",
                    accessibilityLabel: "network_cockpit.title",
                    accessibilityIdentifier: "navigation-network-cockpit-open",
                    action: openNetworkCockpit
                )
            }

            if let openSearch {
                NolaggyHeaderActionGroup(openSettings: openSettings, openSearch: openSearch)
            } else {
                NolaggyNavigationControl(
                    systemImage: "ellipsis",
                    accessibilityLabel: "settings.title",
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
            accessibilityIdentifier: accessibilityIdentifier ?? "lagcheck-back",
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

/// Cabeçalho canônico das telas nomeadas (Jogos, Detalhes, Histórico, Ajustes).
/// A barra de ações superior (52 pt) mantém os controles de retorno e ações secundárias;
/// o título fica logo abaixo, alinhado à esquerda, sem colisão com o chevron.
struct NolaggyNamedScreenHeader<Trailing: View>: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey? = nil
    var leadingAction: (() -> Void)? = nil
    var leadingAccessibilityIdentifier: String = "screen-back"
    @ViewBuilder var trailing: () -> Trailing

    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        leadingAction: (() -> Void)? = nil,
        leadingAccessibilityIdentifier: String = "screen-back",
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingAction = leadingAction
        self.leadingAccessibilityIdentifier = leadingAccessibilityIdentifier
        self.trailing = trailing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 0) {
                if let leadingAction {
                    Button(action: leadingAction) {
                        Image(systemName: "chevron.backward")
                            .font(NLTypography.navigationIcon)
                            .frame(width: NLSizing.touchTarget, height: NLSizing.touchTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(NLColor.textPrimary)
                    .accessibilityLabel(Text("quick_check.back"))
                    .accessibilityIdentifier(leadingAccessibilityIdentifier)
                } else {
                    Spacer().frame(width: NLSizing.touchTarget, height: NLSizing.touchTarget)
                }

                Spacer()

                trailing()
            }
            .frame(height: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(NLTypography.screenTitle)
                    .foregroundStyle(NLColor.textPrimary)
                    .tracking(-0.8)

                if let subtitle {
                    Text(subtitle)
                        .font(NLTypography.monospaceSubtitle)
                        .foregroundStyle(NLColor.textSecondary)
                }
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, NLSpacing.screenMarginHorizontal)
    }
}

extension NolaggyNamedScreenHeader where Trailing == EmptyView {
    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        leadingAction: (() -> Void)? = nil,
        leadingAccessibilityIdentifier: String = "screen-back"
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            leadingAction: leadingAction,
            leadingAccessibilityIdentifier: leadingAccessibilityIdentifier,
            trailing: { EmptyView() }
        )
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
        NLColor.deep
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

// SettingsView vive em Features/Settings/SettingsView.swift.
