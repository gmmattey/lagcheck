import SwiftUI
import UIKit
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Tela de Ajustes (Mockup 07 · Dark Competitive UI).
/// Preferências de Idioma, Exclusão de Histórico Local, Sobre o LagCheck e Suporte.
struct SettingsView: View {
    let configuration: NolaggyAppConfiguration
    let regionCandidates: [RegionalReferenceCandidate]
    let manualRegionID: String?
    let onSelectRegion: (RegionalReferenceCandidate) -> Void
    let deleteHistory: () async throws -> Void
    let showHistory: () -> Void
    var showsBackHeader: Bool = true
    var onDismiss: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage(AppLocalization.selectedLanguageKey) private var selectedLanguage: String = AppLanguage.system.rawValue

    @State private var showingLanguageSheet: Bool = false
    @State private var showingDeleteSheet: Bool = false
    @State private var toastMessage: String? = nil
    @State private var showingToast: Bool = false

    private var currentLanguageName: String {
        switch selectedLanguage {
        case AppLanguage.ptBR.rawValue: return "Português (Brasil)"
        case AppLanguage.en.rawValue: return "English"
        case AppLanguage.es.rawValue: return "Español"
        default: return "Português (Brasil)"
        }
    }

    private var regionDetailLabel: String {
        guard let manualRegionID, manualRegionID != RegionalPreferenceIdentifiers.automatic else {
            return AppLocalization.string("settings.region.automatic", comment: "")
        }
        return regionCandidates.first(where: { $0.id == manualRegionID })?.label ?? manualRegionID
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Barra superior e Título
                    NolaggyNamedScreenHeader(
                        title: LocalizedStringKey("navigation.settings"),
                        leadingAction: {
                            if let onDismiss {
                                onDismiss()
                            } else {
                                dismiss()
                            }
                        },
                        leadingAccessibilityIdentifier: "settings-back"
                    )

                    // Seção 1: Preferências
                    VStack(alignment: .leading, spacing: 10) {
                        Text(LocalizedStringKey("settings.preferences.title"))
                            .font(NLTypography.captionMonoUppercase)
                            .foregroundStyle(NLColor.textTertiary)

                        Button(action: { showingLanguageSheet = true }) {
                            HStack {
                                Text(LocalizedStringKey("settings.language.title"))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(NLColor.textPrimary)

                                Spacer()

                                Text(currentLanguageName)
                                    .font(NLTypography.monospaceMetrics)
                                    .foregroundStyle(NLColor.textTertiary)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(NLColor.textTertiary)
                                    .padding(.leading, 4)
                            }
                            .frame(height: 56)
                            .contentShape(Rectangle())
                            .overlay(Rectangle().fill(NLColor.borderStrong).frame(height: 1), alignment: .bottom)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("settings-language")

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
                            } label: {
                                HStack {
                                    Text(LocalizedStringKey("settings.region.title"))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(NLColor.textPrimary)

                                    Spacer()

                                    Text(regionDetailLabel)
                                        .font(NLTypography.monospaceMetrics)
                                        .foregroundStyle(NLColor.textTertiary)

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(NLColor.textTertiary)
                                        .padding(.leading, 4)
                                }
                                .frame(height: 56)
                                .contentShape(Rectangle())
                                .overlay(Rectangle().fill(NLColor.borderStrong).frame(height: 1), alignment: .bottom)
                            }
                            .accessibilityIdentifier("settings-region")
                        }
                    }
                    .padding(.horizontal, NLSpacing.md)

                    // Seção 2: Histórico
                    VStack(alignment: .leading, spacing: 10) {
                        Text(LocalizedStringKey("settings.history.title"))
                            .font(NLTypography.captionMonoUppercase)
                            .foregroundStyle(NLColor.textTertiary)

                        Button(action: {
                            if let onDismiss {
                                onDismiss()
                            } else {
                                dismiss()
                            }
                            showHistory()
                        }) {
                            HStack {
                                Text(LocalizedStringKey("home.shortcuts.history"))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(NLColor.textPrimary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(NLColor.textTertiary)
                            }
                            .frame(height: 56)
                            .contentShape(Rectangle())
                            .overlay(Rectangle().fill(NLColor.borderStrong).frame(height: 1), alignment: .bottom)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("settings-history")

                        Button(action: { showingDeleteSheet = true }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(LocalizedStringKey("settings.history.delete"))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(NLColor.coralSolar)

                                    Text(LocalizedStringKey("settings.history.delete_subtext"))
                                        .font(.system(size: 11))
                                        .foregroundStyle(NLColor.textTertiary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(NLColor.textTertiary)
                            }
                            .frame(height: 56)
                            .contentShape(Rectangle())
                            .overlay(Rectangle().fill(NLColor.borderStrong).frame(height: 1), alignment: .bottom)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("ajustes-apagar-historico")
                    }
                    .padding(.horizontal, NLSpacing.md)

                    // Seção 3: Sobre o LagCheck
                    VStack(alignment: .leading, spacing: 10) {
                        Text(LocalizedStringKey("settings.about.title"))
                            .font(NLTypography.captionMonoUppercase)
                            .foregroundStyle(NLColor.textTertiary)

                        // Versão
                        HStack {
                            Text(LocalizedStringKey("settings.about.version"))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(NLColor.textPrimary)

                            Spacer()

                            Text(verbatim: "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")")
                                .font(NLTypography.monospaceMetrics)
                                .foregroundStyle(NLColor.textTertiary)
                        }
                        .frame(height: 56)
                        .overlay(Rectangle().fill(NLColor.borderStrong).frame(height: 1), alignment: .bottom)

                        // Termos de Uso
                        settingsRowButton(title: LocalizedStringKey("settings.about.terms")) {
                            showToast(message: AppLocalization.string("settings.toast.system_action", comment: ""))
                        }

                        // Política de Privacidade
                        settingsRowButton(title: LocalizedStringKey("settings.about.privacy")) {
                            if let url = URL(string: "https://buildea.com/lagcheck/privacy") {
                                openURL(url)
                            }
                        }

                        // Licenças de código aberto
                        settingsRowButton(title: LocalizedStringKey("settings.about.licenses"), isLast: true) {
                            showToast(message: AppLocalization.string("settings.toast.system_action", comment: ""))
                        }
                    }
                    .padding(.horizontal, NLSpacing.md)

                    // Seção 4: Suporte
                    VStack(alignment: .leading, spacing: 10) {
                        Text(LocalizedStringKey("settings.support.title"))
                            .font(NLTypography.captionMonoUppercase)
                            .foregroundStyle(NLColor.textTertiary)

                        settingsRowButton(title: LocalizedStringKey("settings.support.feedback"), identifier: "ajustes-enviar-feedback") {
                            if let url = URL(string: "mailto:suporte@buildea.com?subject=LagCheck%20Feedback") {
                                openURL(url)
                            }
                        }

                        settingsRowButton(title: LocalizedStringKey("settings.support.rate"), isLast: true, identifier: "ajustes-avaliar") {
                            showToast(message: AppLocalization.string("settings.toast.system_action", comment: ""))
                        }
                    }
                    .padding(.horizontal, NLSpacing.md)

                    Spacer(minLength: NLSpacing.xl)
                }
            }

            // Toast Flutuante
            if showingToast, let toastMessage {
                Text(toastMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(NLColor.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(NLColor.backgroundRaised.opacity(0.97), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(NLColor.borderStrong, lineWidth: 1)
                    )
                    .padding(.horizontal, NLSpacing.md)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(NLColor.deep.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingLanguageSheet) {
            languageSelectorSheet
        }
        .sheet(isPresented: $showingDeleteSheet) {
            deleteConfirmationSheet
        }
    }

    private func settingsRowButton(title: LocalizedStringKey, isLast: Bool = false, identifier: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(NLColor.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(NLColor.textTertiary)
            }
            .frame(height: 56)
            .contentShape(Rectangle())
            .overlay(isLast ? nil : Rectangle().fill(NLColor.borderStrong).frame(height: 1), alignment: .bottom)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier ?? "")
    }

    // MARK: - Language Sheet
    private var languageSelectorSheet: some View {
        VStack(spacing: 0) {
            Text(LocalizedStringKey("settings.language.title"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(NLColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, NLSpacing.md)
                .padding(.bottom, NLSpacing.sm)
                .padding(.horizontal, NLSpacing.md)

            VStack(spacing: 0) {
                languageChoiceRow(name: "Português (Brasil)", code: AppLanguage.ptBR.rawValue)
                languageChoiceRow(name: "English", code: AppLanguage.en.rawValue)
                languageChoiceRow(name: "Español", code: AppLanguage.es.rawValue)
            }
            .padding(.horizontal, NLSpacing.md)

            Spacer()
        }
        .presentationDetents([.fraction(0.38)])
        .presentationDragIndicator(.visible)
        .background(NLColor.backgroundRaised.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func languageChoiceRow(name: String, code: String) -> some View {
        let isSelected = selectedLanguage == code
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedLanguage = code
            showingLanguageSheet = false
            showToast(message: String(format: AppLocalization.string("settings.toast.language %@", comment: ""), name))
        } label: {
            HStack {
                Text(name)
                    .font(.system(size: 15, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? NLColor.gamerPurple : NLColor.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(NLColor.gamerPurple)
                }
            }
            .frame(height: 48)
            .contentShape(Rectangle())
            .overlay(Rectangle().fill(NLColor.borderStrong).frame(height: 1), alignment: .top)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Delete Sheet
    private var deleteConfirmationSheet: some View {
        VStack(spacing: 0) {
            Text(LocalizedStringKey("settings.delete_history.confirmation.title"))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(NLColor.textPrimary)
                .padding(.top, NLSpacing.md)
                .padding(.bottom, 8)

            Text(LocalizedStringKey("settings.delete_history.confirmation.message"))
                .font(.system(size: 14))
                .foregroundStyle(NLColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 24)

            HStack(spacing: 12) {
                Button(action: { showingDeleteSheet = false }) {
                    Text(LocalizedStringKey("common.cancel"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(NLColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(NLColor.borderStrong, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings-delete-cancel")

                Button(action: {
                    showingDeleteSheet = false
                    Task {
                        try? await deleteHistory()
                        showToast(message: AppLocalization.string("settings.toast.history_deleted", comment: ""))
                    }
                }) {
                    Text(LocalizedStringKey("settings.delete_history.confirmation.action"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(NLColor.coralSolar, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings-delete-confirm")
            }
            .padding(.horizontal, NLSpacing.md)
            .padding(.bottom, NLSpacing.lg)
        }
        .presentationDetents([.fraction(0.35)])
        .presentationDragIndicator(.visible)
        .background(NLColor.backgroundRaised.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func showToast(message: String) {
        toastMessage = message
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showingToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.25)) {
                showingToast = false
            }
        }
    }
}

/// Identificador reservado para a opção "escolher automaticamente" dentro da
/// lista de candidatos de região exibida em Configurações.
enum RegionalPreferenceIdentifiers {
    static let automatic = "automatic"
}

