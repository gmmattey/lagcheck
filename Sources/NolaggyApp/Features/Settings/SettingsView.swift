import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Configurações (doc 01 §7.8 / decisão 17): idioma do sistema, exclusão do
/// histórico local, versão do app, Suporte e Política de privacidade.
///
/// A região de referência é sempre escolhida automaticamente com base na rede
/// no momento da medição. A preferência manual guardada aqui é só um override
/// persistido — não existe mais um passo de escolha de região no meio da
/// jornada de medição (ver decisão de seleção regional automática, doc 16).
struct SettingsView: View {
    let configuration: NolaggyAppConfiguration
    /// Vazio enquanto o catálogo ainda não carregou: a linha de região fica
    /// oculta até existir algo para escolher. O primeiro candidato é sempre
    /// "Automática".
    let regionCandidates: [RegionalReferenceCandidate]
    let manualRegionID: String?
    let onSelectRegion: (RegionalReferenceCandidate) -> Void
    let deleteHistory: () async throws -> Void
    let showHistory: () -> Void
    var showsBackHeader: Bool = true

    private var regionDetailLabel: String {
        regionCandidates.first(where: { $0.id == (manualRegionID ?? RegionalPreferenceIdentifiers.automatic) })?.label
            ?? NSLocalizedString("settings.region.automatic", comment: "")
    }

    @Environment(\.openURL) private var openURL
    @State private var showingDeleteConfirmation = false
    @State private var deletionFailed = false

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    Button(action: showHistory) {
                        SettingsRow(title: "history.title", symbol: "clock.arrow.circlepath", detail: nil, showsChevron: true)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(SettingsListSurface())
                    .listRowSeparator(.hidden)
                    .compactSettingsRow()
                    .accessibilityIdentifier("settings-history")
                }

                Section {
                    settingValueRow(
                        "settings.language",
                        symbol: "globe",
                        value: Locale.current.localizedString(forIdentifier: Locale.current.identifier) ?? Locale.current.identifier
                    )
                    if !regionCandidates.isEmpty {
                        Menu {
                            if let autoCandidate = regionCandidates.first(where: { $0.id == RegionalPreferenceIdentifiers.automatic }) {
                                Button {
                                    onSelectRegion(autoCandidate)
                                } label: {
                                    let isSelected = (manualRegionID == nil || manualRegionID == RegionalPreferenceIdentifiers.automatic)
                                    if isSelected {
                                        Label(autoCandidate.label, systemImage: "checkmark")
                                    } else {
                                        Text(autoCandidate.label)
                                    }
                                }
                            }

                            Divider()

                            ForEach(GlobalProbeRegistry.Continent.allCases, id: \.self) { continent in
                                let continentCandidates = regionCandidates.filter { $0.continentKey == continent.localizationKey }
                                if !continentCandidates.isEmpty {
                                    Menu(LocalizedStringKey(continent.localizationKey)) {
                                        ForEach(continentCandidates) { candidate in
                                            Button {
                                                onSelectRegion(candidate)
                                            } label: {
                                                let isSelected = candidate.id == manualRegionID
                                                if isSelected {
                                                    Label(candidate.label, systemImage: "checkmark")
                                                } else {
                                                    Text(candidate.label)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            let otherCandidates = regionCandidates.filter {
                                $0.id != RegionalPreferenceIdentifiers.automatic && $0.continentKey == nil
                            }
                            if !otherCandidates.isEmpty {
                                Divider()
                                ForEach(otherCandidates) { candidate in
                                    Button {
                                        onSelectRegion(candidate)
                                    } label: {
                                        let isSelected = candidate.id == manualRegionID
                                        if isSelected {
                                            Label(candidate.label, systemImage: "checkmark")
                                        } else {
                                            Text(candidate.label)
                                        }
                                    }
                                }
                            }
                        } label: {
                            SettingsRow(
                                title: "settings.region.title",
                                symbol: "mappin.and.ellipse",
                                detail: regionDetailLabel,
                                showsChevron: true
                            )
                        }
                        .listRowBackground(SettingsListSurface())
                        .listRowSeparator(.hidden)
                        .compactSettingsRow()
                        .accessibilityIdentifier("settings-region")
                    }
                } header: {
                    sectionHeader("settings.section.preferences")
                } footer: {
                    if !regionCandidates.isEmpty {
                        Text("settings.region.explanation")
                            .font(NLTypography.footnote)
                            .foregroundStyle(NLColor.textTertiary)
                    }
                }

                Section {
                    configuredLinkRow("settings.privacy_policy", symbol: "hand.raised", url: configuration.privacyPolicyURL)
                    Button { showingDeleteConfirmation = true } label: {
                        SettingsRow(
                            title: "settings.delete_history",
                            symbol: "trash",
                            detail: nil,
                            showsChevron: false,
                            tone: .destructive
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(SettingsListSurface())
                    .listRowSeparator(.hidden)
                    .compactSettingsRow()
                    .accessibilityIdentifier("settings-delete-history")
                } header: {
                    sectionHeader("settings.section.privacy")
                }

                Section {
                    settingValueRow("settings.version", symbol: "info.circle", value: versionDescription)
                    configuredLinkRow("settings.support", symbol: "questionmark.circle", url: configuration.supportURL)
                } header: {
                    sectionHeader("settings.section.about")
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(NLSpacing.xs)
            .scrollContentBackground(.hidden)
        }
        .background(NolaggyScreenBackground())
        .navigationTitle("settings.title")
        .navigationBarTitleDisplayMode(showsBackHeader ? .inline : .large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .alert("settings.delete_history.confirmation.title", isPresented: $showingDeleteConfirmation) {
            Button("settings.delete_history.confirmation.cancel", role: .cancel) {}
            Button("settings.delete_history.confirmation.action", role: .destructive) {
                Task {
                    do { try await deleteHistory() }
                    catch { deletionFailed = true }
                }
            }
        } message: { Text("settings.delete_history.confirmation.message") }
        .alert("settings.delete_history.error.title", isPresented: $deletionFailed) {
            Button("settings.delete_history.error.action", role: .cancel) {}
        } message: { Text("settings.delete_history.error.message") }
    }

    private var versionDescription: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return String(format: NSLocalizedString("settings.version.value", comment: ""), version, build)
    }

    private func settingValueRow(_ title: LocalizedStringKey, symbol: String, value: String) -> some View {
        SettingsRow(title: title, symbol: symbol, detail: value, showsChevron: false)
            .listRowBackground(SettingsListSurface())
            .listRowSeparator(.hidden)
            .compactSettingsRow()
    }

    @ViewBuilder
    private func configuredLinkRow(_ title: LocalizedStringKey, symbol: String, url: URL?) -> some View {
        Group {
            if let url {
                Button { openURL(url) } label: { SettingsRow(title: title, symbol: symbol, detail: nil, showsChevron: true) }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text("settings.link.opens_browser"))
            } else {
                SettingsRow(title: title, symbol: symbol, detail: String(localized: "settings.link_unavailable"), showsChevron: false)
                    .accessibilityHint(Text("settings.link_unavailable"))
            }
        }
        .listRowBackground(SettingsListSurface())
            .listRowSeparator(.hidden)
            .compactSettingsRow()
    }

    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(NLTypography.captionStrong)
            .foregroundStyle(NLColor.textTertiary)
    }
}

/// Identificador reservado para a opção "escolher automaticamente" dentro da
/// lista de candidatos de região exibida em Configurações.
enum RegionalPreferenceIdentifiers {
    static let automatic = "automatic"
}

private struct SettingsRow: View {
    enum Tone { case standard, destructive }

    let title: LocalizedStringKey
    let symbol: String
    let detail: String?
    let showsChevron: Bool
    let tone: Tone

    init(title: LocalizedStringKey, symbol: String, detail: String?, showsChevron: Bool, tone: Tone = .standard) {
        self.title = title
        self.symbol = symbol
        self.detail = detail
        self.showsChevron = showsChevron
        self.tone = tone
    }

    var body: some View {
        HStack(spacing: NLSpacing.sm) {
            Image(systemName: symbol)
                .font(NLTypography.navigationIcon)
                .foregroundStyle(tone == .destructive ? NLColor.scoreLagRisk : NLColor.textLink)
                .frame(width: NLSizing.iconMedium, height: NLSizing.iconMedium)
                .accessibilityHidden(true)
            Text(title).font(NLTypography.body).foregroundStyle(tone == .destructive ? NLColor.scoreLagRisk : NLColor.textPrimary)
            Spacer()
            if let detail { Text(detail).font(NLTypography.callout).foregroundStyle(NLColor.textSecondary).multilineTextAlignment(.trailing) }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(NLTypography.footnote.weight(.semibold))
                    .foregroundStyle(NLColor.textSecondary)
                    .accessibilityHidden(true)
                    .padding(.leading, detail == nil ? 0 : NLSpacing.xs)
            }
        }
        .padding(.horizontal, NLSpacing.md)
        .frame(minHeight: NLSizing.touchTarget)
    }
}

private struct SettingsListSurface: View {
    var body: some View {
        Rectangle()
            .fill(NLColor.settingsSurface)
    }
}

private extension View {
    func compactSettingsRow() -> some View {
        listRowInsets(
            EdgeInsets(
                top: 0,
                leading: NLSpacing.screenMarginHorizontal,
                bottom: 0,
                trailing: NLSpacing.screenMarginHorizontal
            )
        )
    }
}
