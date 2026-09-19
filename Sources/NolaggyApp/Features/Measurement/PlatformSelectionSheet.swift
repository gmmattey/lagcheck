import SwiftUI
import UIKit
import NolaggyDomain
import NolaggyDesign

/// Sheet nativa Apple HIG para seleção de plataforma antes de iniciar o LagCheck.
/// Apresenta apenas as plataformas disponíveis para o jogo específico, dispostas
/// em linha horizontal conforme a Decisão 26.
struct PlatformSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let gameName: String
    let supportedPlatforms: [Platform]
    let onSelectPlatform: (Platform) -> Void

    @State private var selected: Platform

    init(
        gameName: String,
        supportedPlatforms: [Platform],
        initialPlatform: Platform = .iphone,
        onSelectPlatform: @escaping (Platform) -> Void
    ) {
        self.gameName = gameName
        let validPlatforms = supportedPlatforms.isEmpty ? [.iphone] : supportedPlatforms
        self.supportedPlatforms = validPlatforms
        self.onSelectPlatform = onSelectPlatform
        _selected = State(initialValue: validPlatforms.contains(initialPlatform) ? initialPlatform : (validPlatforms.first ?? .iphone))
    }

    var body: some View {
        VStack(spacing: NLSpacing.lg) {
            // Cabeçalho da Sheet
            VStack(spacing: NLSpacing.xxs) {
                Text(LocalizedStringKey("lagcheck.platform_picker.title"))
                    .font(NLTypography.headline)
                    .foregroundStyle(NLColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text(String(format: NSLocalizedString("lagcheck.platform_picker.subtitle %@", comment: ""), gameName))
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, NLSpacing.sm)
            }
            .padding(.top, NLSpacing.md)

            // Linha Horizontal de Plataformas (Decisão 26)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NLSpacing.sm) {
                    ForEach(supportedPlatforms, id: \.self) { platform in
                        platformCard(for: platform)
                    }
                }
                .padding(.horizontal, NLSpacing.screenMarginHorizontal)
                .padding(.vertical, NLSpacing.xxs)
            }

            Spacer(minLength: 0)

            // Botão de Confirmação Primário
            Button {
                confirmAndStart(platform: selected)
            } label: {
                HStack(spacing: NLSpacing.xs) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(LocalizedStringKey("home.cta.start_lagcheck"))
                        .font(NLTypography.bodyEmphasis)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(NLColor.accentPrimary, in: RoundedRectangle(cornerRadius: NLRadius.controlMedium))
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .padding(.bottom, NLSpacing.lg)
            .accessibilityIdentifier("confirm-platform-and-start")
        }
        .presentationDetents([.height(290)])
        .presentationDragIndicator(.visible)
        .background(NLColor.backgroundBase.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func platformCard(for platform: Platform) -> some View {
        let isSelected = selected == platform
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) {
                selected = platform
            }
        } label: {
            VStack(spacing: NLSpacing.xs) {
                Image(systemName: iconName(for: platform))
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(isSelected ? NLColor.textPrimary : NLColor.textSecondary)
                    .frame(height: 32)

                Text(displayName(for: platform))
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(isSelected ? NLColor.textPrimary : NLColor.textSecondary)

                Text(subLabel(for: platform))
                    .font(NLTypography.caption)
                    .foregroundStyle(NLColor.textTertiary)
            }
            .frame(width: 96, height: 104)
            .background(
                isSelected ? Color.white.opacity(0.14) : NLColor.backgroundRaised,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? NLColor.accentPrimary : NLColor.borderSubtle,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(displayName(for: platform)), \(subLabel(for: platform))")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func confirmAndStart(platform: Platform) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
        onSelectPlatform(platform)
    }

    private func iconName(for platform: Platform) -> String {
        switch platform {
        case .iphone: return "iphone"
        case .playstation: return "gamecontroller"
        case .xbox: return "gamecontroller.fill"
        case .pc: return "display"
        case .nintendo: return "gamecontroller"
        }
    }

    private func displayName(for platform: Platform) -> String {
        switch platform {
        case .iphone: return "iPhone"
        case .playstation: return "PlayStation"
        case .xbox: return "Xbox"
        case .pc: return "PC"
        case .nintendo: return "Switch"
        }
    }

    private func subLabel(for platform: Platform) -> String {
        switch platform {
        case .iphone: return "iOS"
        case .playstation: return "PS4 / PS5"
        case .xbox: return "Series X|S"
        case .pc: return "Windows"
        case .nintendo: return "Console"
        }
    }
}
