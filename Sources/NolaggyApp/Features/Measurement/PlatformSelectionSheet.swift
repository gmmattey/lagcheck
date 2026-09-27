import SwiftUI
import UIKit
import NolaggyDomain
import NolaggyDesign

/// Sheet Dark Competitive para seleção de plataforma e conexão antes de iniciar o LagCheck (Mockup 02).
/// Apresenta apenas as plataformas disponíveis para o jogo específico e, para consoles/PC, o modo de conexão.
struct PlatformSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let gameName: String
    let supportedPlatforms: [Platform]
    let onSelectPlatform: (Platform, ExternalEquipmentLink?) -> Void

    @State private var selected: Platform?
    @State private var connectionMode: String = "Wi-Fi"

    init(
        gameName: String,
        supportedPlatforms: [Platform],
        initialPlatform: Platform = .iphone,
        onSelectPlatform: @escaping (Platform) -> Void
    ) {
        self.gameName = gameName
        self.supportedPlatforms = supportedPlatforms
        self.onSelectPlatform = { platform, _ in onSelectPlatform(platform) }
        _selected = State(initialValue: supportedPlatforms.contains(initialPlatform) ? initialPlatform : supportedPlatforms.first)
    }

    init(
        gameName: String,
        supportedPlatforms: [Platform],
        initialPlatform: Platform = .iphone,
        onSelectPlatformWithLink: @escaping (Platform, ExternalEquipmentLink?) -> Void
    ) {
        self.gameName = gameName
        self.supportedPlatforms = supportedPlatforms
        self.onSelectPlatform = onSelectPlatformWithLink
        _selected = State(initialValue: supportedPlatforms.contains(initialPlatform) ? initialPlatform : supportedPlatforms.first)
    }

    var body: some View {
        Group {
            if supportedPlatforms.isEmpty {
                unavailablePlatformState
            } else {
                selectionContent
            }
        }
        .presentationDetents([.fraction(0.55), .medium, .large])
        .presentationContentInteraction(.scrolls)
        .presentationDragIndicator(.visible)
        .background(NLColor.backgroundRaised.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var selectionContent: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Título do Jogo (h2)
                    Text(gameName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(NLColor.textPrimary)
                        .padding(.top, NLSpacing.md)
                        .padding(.bottom, 2)
                        .padding(.horizontal, NLSpacing.md)

                    // Subtítulo de Contexto: "Onde você joga?"
                    Text(LocalizedStringKey("game_detail.context.platform_title"))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(NLColor.textSecondary)
                        .padding(.bottom, NLSpacing.sm)
                        .padding(.horizontal, NLSpacing.md)

                    // Linhas de Escolha de Plataforma
                    VStack(spacing: 0) {
                        ForEach(supportedPlatforms, id: \.self) { platform in
                            platformChoiceRow(for: platform)
                        }
                    }
                    .padding(.horizontal, NLSpacing.md)

                    // Modo de Conexão para Console ou PC
                    if let selected, selected != .iphone {
                        VStack(alignment: .leading, spacing: NLSpacing.xs) {
                            Text(String(format: AppLocalization.string("games.connection.mode %@", comment: ""), selected.displayName))
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(NLColor.textSecondary)

                            HStack(spacing: 8) {
                                connectionSegment(title: AppLocalization.string("games.connection.wifi", comment: ""), isSelected: connectionMode == "Wi-Fi") {
                                    connectionMode = "Wi-Fi"
                                }
                                connectionSegment(title: AppLocalization.string("games.connection.ethernet", comment: ""), isSelected: connectionMode != "Wi-Fi") {
                                    connectionMode = "Cabo (Ethernet)"
                                }
                            }
                        }
                        .padding(.horizontal, NLSpacing.md)
                        .padding(.top, NLSpacing.md)
                        .padding(.bottom, NLSpacing.xs)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }

            // Botão Iniciar Check
            Button {
                if let selected {
                    confirmAndStart(platform: selected)
                }
            } label: {
                Text(LocalizedStringKey("games.sheet.start_check"))
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(NLColor.gamerPurple, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(selected == nil)
            .accessibilityIdentifier("start-game-deep-check")
            .padding(.horizontal, NLSpacing.md)
            .padding(.vertical, NLSpacing.sm)
        }
    }

    private func platformChoiceRow(for platform: Platform) -> some View {
        let isSelected = selected == platform
        let title = platform == .nintendo ? "Switch" : platform.displayName
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.15)) {
                selected = platform
            }
        } label: {
            HStack {
                Text(title)
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
            .overlay(
                Rectangle()
                    .fill(NLColor.borderStrong)
                    .frame(height: 1),
                alignment: .top
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("platform-choice-\(platform.rawValue)")
    }

    private func connectionSegment(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? NLColor.gamerPurple : NLColor.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(isSelected ? NLColor.gamerPurple : NLColor.borderStrong, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var unavailablePlatformState: some View {
        VStack(spacing: NLSpacing.lg) {
            Spacer(minLength: 0)

            Image(systemName: "xmark.circle")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(NLColor.textSecondary)
                .accessibilityHidden(true)

            VStack(spacing: NLSpacing.xs) {
                Text("lagcheck.platform_picker.unavailable.title")
                    .font(NLTypography.headline)
                    .foregroundStyle(NLColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text("lagcheck.platform_picker.unavailable.message")
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)

            Button {
                dismiss()
            } label: {
                Text("lagcheck.platform_picker.unavailable.back")
                    .font(NLTypography.bodyEmphasis)
                    .foregroundStyle(NLColor.textLink)
                    .frame(minHeight: NLSizing.touchTarget)
            }
            .accessibilityIdentifier("platform-selection-unavailable-back")

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("lagcheck.platform_picker.unavailable.accessibility"))
    }

    private func confirmAndStart(platform: Platform) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let link: ExternalEquipmentLink? = platform == .iphone ? nil : (connectionMode == "Wi-Fi" ? .wifi : .ethernet)
        onSelectPlatform(platform, link)
    }
}
