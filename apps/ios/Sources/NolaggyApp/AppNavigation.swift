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

private struct NamedScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Cabeçalho canônico das telas nomeadas no iOS (Apple HIG + Dark Competitive UI).
/// Quando não há botão voltar nem ação à direita, omite a barra fantasma superior de 52 pt;
/// ao rolar, recolhe suavemente para barra fixa compacta com título centralizado e fundo translúcido.
struct NolaggyNamedScreenHeader<Trailing: View>: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey? = nil
    var leadingAction: (() -> Void)? = nil
    var leadingAccessibilityIdentifier: String = "screen-back"
    var hasTrailingAction: Bool = false
    @ViewBuilder var trailing: () -> Trailing

    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        leadingAction: (() -> Void)? = nil,
        leadingAccessibilityIdentifier: String = "screen-back",
        hasTrailingAction: Bool = Trailing.self != EmptyView.self,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingAction = leadingAction
        self.leadingAccessibilityIdentifier = leadingAccessibilityIdentifier
        self.hasTrailingAction = hasTrailingAction
        self.trailing = trailing
    }

    private var showsActionRow: Bool {
        leadingAction != nil || hasTrailingAction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if showsActionRow {
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
            } else {
                Spacer().frame(height: NLSpacing.sm)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(NLTypography.screenTitle)
                    .foregroundStyle(NLColor.textPrimary)
                    .textCase(.uppercase)
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

/// Container rolável no padrão Apple HIG: título grande à esquerda em repouso que recolhe
/// suavemente ao rolar para uma barra fixa translúcida com título centralizado em CAIXA ALTA.
struct NolaggyCollapsibleScreen<Trailing: View, Content: View>: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey? = nil
    var leadingAction: (() -> Void)? = nil
    var leadingAccessibilityIdentifier: String = "screen-back"
    var hasTrailingAction: Bool = false
    var horizontalContentPadding: CGFloat = 0
    @ViewBuilder var trailing: () -> Trailing
    @ViewBuilder var content: () -> Content

    @State private var scrollOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        leadingAction: (() -> Void)? = nil,
        leadingAccessibilityIdentifier: String = "screen-back",
        hasTrailingAction: Bool = Trailing.self != EmptyView.self,
        horizontalContentPadding: CGFloat = 0,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingAction = leadingAction
        self.leadingAccessibilityIdentifier = leadingAccessibilityIdentifier
        self.hasTrailingAction = hasTrailingAction
        self.horizontalContentPadding = horizontalContentPadding
        self.trailing = trailing
        self.content = content
    }

    private var collapseProgress: CGFloat {
        let scrolled = max(0, -scrollOffset)
        return min(max((scrolled - 12) / 34, 0), 1)
    }

    private var showsActionRow: Bool {
        leadingAction != nil || hasTrailingAction
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: NamedScrollOffsetPreferenceKey.self,
                            value: geo.frame(in: .named("nolaggyNamedScroll")).minY
                        )
                    }
                    .frame(height: 0)

                    VStack(alignment: .leading, spacing: 2) {
                        Spacer().frame(height: showsActionRow ? 54 : NLSpacing.sm)

                        Text(title)
                            .font(NLTypography.screenTitle)
                            .foregroundStyle(NLColor.textPrimary)
                            .textCase(.uppercase)
                            .tracking(-0.8)

                        if let subtitle {
                            Text(subtitle)
                                .font(NLTypography.monospaceSubtitle)
                                .foregroundStyle(NLColor.textSecondary)
                        }
                    }
                    .padding(.horizontal, NLSpacing.screenMarginHorizontal)
                    .opacity(Double(1 - collapseProgress * 0.9))

                    content()
                        .padding(.horizontal, horizontalContentPadding)
                }
            }
            .coordinateSpace(name: "nolaggyNamedScroll")
            .onPreferenceChange(NamedScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }

            if showsActionRow || collapseProgress > 0.01 {
                collapsedBar
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: collapseProgress > 0.01)
    }

    private var collapsedBar: some View {
        ZStack {
            if collapseProgress > 0.05 {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(NLColor.deep.opacity(0.68))
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(NLColor.borderHairline)
                            .frame(height: 0.5)
                    }
                    .ignoresSafeArea(edges: .top)
                    .opacity(Double(collapseProgress))
            }

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

                Spacer(minLength: 8)

                Text(title)
                    .font(.custom("BarlowSemiCondensed-Bold", size: 17))
                    .foregroundStyle(NLColor.textPrimary)
                    .textCase(.uppercase)
                    .tracking(-0.3)
                    .lineLimit(1)
                    .opacity(Double(collapseProgress))

                Spacer(minLength: 8)

                if hasTrailingAction {
                    trailing()
                        .frame(minWidth: NLSizing.touchTarget, alignment: .trailing)
                } else {
                    Spacer().frame(width: NLSizing.touchTarget, height: NLSizing.touchTarget)
                }
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .frame(height: 52)
        }
        .frame(height: 52)
    }
}

extension NolaggyCollapsibleScreen where Trailing == EmptyView {
    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        leadingAction: (() -> Void)? = nil,
        leadingAccessibilityIdentifier: String = "screen-back",
        horizontalContentPadding: CGFloat = 0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            leadingAction: leadingAction,
            leadingAccessibilityIdentifier: leadingAccessibilityIdentifier,
            hasTrailingAction: false,
            horizontalContentPadding: horizontalContentPadding,
            trailing: { EmptyView() },
            content: content
        )
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
