import SwiftUI
import NolaggyApplication
import NolaggyDesign

/// Ponte visual da pré-leitura regional automática. A seleção em si é sempre
/// decidida pelo domínio (automática, ou pela preferência manual salva em
/// Configurações) — esta tela só mostra o carregamento breve e a falha quando
/// nenhum candidato é viável; não pede confirmação nem oferece escolha aqui.
struct RegionalSelectionFeatureView: View {
    @Binding private var presentation: RegionalSelectionPresentation
    @State private var retryInProgress = false

    private let gameTitle: String
    private let onRetry: () -> Void
    private let onBackOrCancel: () -> Void

    init(
        gameTitle: String,
        presentation: Binding<RegionalSelectionPresentation>,
        onRetry: @escaping () -> Void,
        onBackOrCancel: @escaping () -> Void
    ) {
        self.gameTitle = gameTitle
        _presentation = presentation
        self.onRetry = onRetry
        self.onBackOrCancel = onBackOrCancel
    }

    var body: some View {
        VStack(spacing: NLSpacing.xl) {
            NolaggyBackHeader(action: onBackOrCancel, accessibilityIdentifier: "regional-selection-back")
                .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            Spacer(minLength: NLSpacing.xs)
            content
                .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            Spacer()
        }
        .background(NolaggyScreenBackground())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: presentation, initial: false) { _, next in
            guard next != .confirming else { return }
            retryInProgress = false
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var content: some View {
        switch presentation {
        case .confirming:
            RegionalReferenceConfirming()
                .accessibilityIdentifier("regional-selection-confirming")
        case .noViableCandidate:
            noViableCandidate
        }
    }

    private var noViableCandidate: some View {
        VStack(spacing: NLSpacing.lg) {
            Image(systemName: "xmark")
                .font(.system(size: NLSizing.iconMedium, weight: .bold))
                .foregroundStyle(NLColor.textSecondary)
                .frame(width: NLSizing.failureStateIconSide, height: NLSizing.failureStateIconSide)
                .background(NLColor.backgroundRaised, in: Circle())
                .accessibilityHidden(true)

            VStack(spacing: NLSpacing.xs) {
                Text("regional_selection.no_viable.title")
                    .font(NLTypography.headline)
                    .foregroundStyle(NLColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text("regional_selection.no_viable.message")
                    .font(NLTypography.body)
                    .foregroundStyle(NLColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: NLSpacing.sm) {
                if retryInProgress {
                    HStack(spacing: NLSpacing.sm) {
                        ProgressView()
                            .tint(NLColor.accentPrimary)
                            .accessibilityHidden(true)
                        Text("regional_selection.confirming")
                            .font(NLTypography.bodyEmphasis)
                            .foregroundStyle(NLColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: NLSizing.primaryButtonHeight)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("regional-selection-retrying")
                } else {
                    PrimaryButton(title: "quick_check.retry", action: retry)
                        .accessibilityIdentifier("regional-selection-retry")
                }

                Button(action: onBackOrCancel) {
                    Text("regional_selection.no_viable.back_home")
                        .font(NLTypography.bodyEmphasis)
                        .foregroundStyle(NLColor.textLink)
                        .frame(minHeight: NLSizing.touchTarget)
                }
                .accessibilityIdentifier("regional-selection-back-home")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func retry() {
        retryInProgress = true
        onRetry()
    }
}
