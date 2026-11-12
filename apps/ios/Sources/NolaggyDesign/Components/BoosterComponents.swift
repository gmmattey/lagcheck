import SwiftUI

public struct BoosterItemRow: View {
    public let iconName: String
    public let title: String
    public let detail: String
    
    public init(iconName: String, title: String, detail: String) {
        self.iconName = iconName
        self.title = title
        self.detail = detail
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: NLSpacing.sm) {
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(NLColor.accentPrimary)
                .frame(width: 36, height: 36)
                .background(NLColor.accentPrimarySubtle, in: RoundedRectangle(cornerRadius: NLRadius.controlSmall))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: NLSpacing.xs) {
                Text(title)
                    .font(NLTypography.bodyEmphasis)
                    .foregroundStyle(NLColor.textPrimary)
                
                Text(detail)
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: NLRadius.card)
                .stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline)
        }
    }
}

/// Experiência Visual de Carregamento com IA das Dicas de Otimização (Decisão 48).
/// Substitui esqueletos cinzas estáticos pelo Orbe de Inteligência Coral Solar,
/// narrativa rotativa de diagnóstico e cartões de shimmer em Coral Solar.
public struct BoosterSkeletonView: View {
    private let gameName: String?
    private let platform: String?
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var waveAnimation: Bool = false
    @State private var shimmerOffset: CGFloat = -1.0
    @State private var currentStep: Int = 0
    
    public init(gameName: String? = nil, platform: String? = nil) {
        self.gameName = gameName
        self.platform = platform
    }
    
    public var body: some View {
        VStack(spacing: NLSpacing.xl) {
            orbeSection
                .padding(.top, NLSpacing.sm)
            
            statusNarrativeSection
            
            shimmerCardsSection
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false)) {
                    waveAnimation = true
                }
                withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                    shimmerOffset = 1.0
                }
            }
        }
        .task {
            // Ciclo narrativo suave enquanto a API responde
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(1600))
                withAnimation(.easeInOut(duration: 0.35)) {
                    currentStep = (currentStep + 1) % 3
                }
            }
        }
    }
    
    // MARK: - Orbe Editorial de Inteligência
    private var orbeSection: some View {
        ZStack {
            // Ondas concêntricas de pulso
            if !reduceMotion {
                ForEach(0..<2, id: \.self) { index in
                    Circle()
                        .stroke(NLColor.accentPrimary.opacity(waveAnimation ? 0.0 : 0.4), lineWidth: 1.5)
                        .scaleEffect(waveAnimation ? 1.75 + CGFloat(index) * 0.2 : 1.0)
                        .opacity(waveAnimation ? 0.0 : 0.7)
                        .animation(
                            .easeOut(duration: 1.8)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.4),
                            value: waveAnimation
                        )
                }
            } else {
                Circle()
                    .stroke(NLColor.accentPrimary.opacity(0.15), lineWidth: 1.5)
                    .scaleEffect(1.3)
            }
            
            // Halo de brilho suave
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            NLColor.accentPrimary.opacity(0.25),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 15,
                        endRadius: 55
                    )
                )
                .frame(width: 110, height: 110)
            
            // Núcleo central
            Circle()
                .fill(NLColor.backgroundRaised)
                .frame(width: 68, height: 68)
                .overlay {
                    Circle()
                        .stroke(NLColor.accentPrimary.opacity(0.55), lineWidth: 1.5)
                }
                .shadow(color: NLColor.accentPrimary.opacity(0.3), radius: 12, x: 0, y: 0)
            
            // Ícone inteligente
            Image(systemName: "sparkles")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(NLColor.accentPrimary)
        }
        .frame(width: 130, height: 130)
    }
    
    // MARK: - Micro-narrativa Sequencial
    private var statusNarrativeSection: some View {
        VStack(spacing: NLSpacing.xxs) {
            Text(currentStepTitle)
                .font(NLTypography.headline)
                .foregroundStyle(NLColor.textPrimary)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            
            Text(currentStepDetail)
                .font(NLTypography.footnote)
                .foregroundStyle(NLColor.textSecondary)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: currentStep)
        }
        .padding(.horizontal, NLSpacing.md)
    }
    
    private var currentStepTitle: String {
        switch currentStep {
        case 0:
            return String(localized: "booster.loading.step1.title", defaultValue: "Lendo o comportamento da sua rede…")
        case 1:
            if let gameName, !gameName.isEmpty {
                return String(format: String(localized: "booster.loading.step2.title %@", defaultValue: "Cruzando requisitos de %@…"), gameName)
            }
            return String(localized: "booster.loading.step2.fallback", defaultValue: "Analisando requisitos do jogo…")
        default:
            if let platform, !platform.isEmpty {
                return String(format: String(localized: "booster.loading.step3.title %@", defaultValue: "Preparando ações práticas para %@…"), platform)
            }
            return String(localized: "booster.loading.step3.fallback", defaultValue: "Preparando ações práticas…")
        }
    }
    
    private var currentStepDetail: String {
        switch currentStep {
        case 0:
            return String(localized: "booster.loading.step1.detail", defaultValue: "Avaliando estabilidade, jitter e impacto sob carga")
        case 1:
            return String(localized: "booster.loading.step2.detail", defaultValue: "Verificando limites de latência e tolerância da partida")
        default:
            return String(localized: "booster.loading.step3.detail", defaultValue: "Formatando ajustes no roteador, equipamento e conexão")
        }
    }
    
    // MARK: - Cards Skeleton com Shimmer Coral
    private var shimmerCardsSection: some View {
        VStack(spacing: NLSpacing.sm) {
            shimmerRow(icon: "wifi.router")
            shimmerRow(icon: "gamecontroller")
            shimmerRow(icon: "network")
        }
    }
    
    private func shimmerRow(icon: String) -> some View {
        HStack(alignment: .top, spacing: NLSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: NLRadius.controlSmall)
                    .fill(NLColor.backgroundRaised)
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(NLColor.textTertiary.opacity(0.4))
            }
            
            VStack(alignment: .leading, spacing: NLSpacing.xs) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(NLColor.backgroundRaised)
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(NLColor.backgroundRaised)
                    .frame(height: 12)
                    .frame(maxWidth: 190)
            }
        }
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised.opacity(0.6), in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: NLRadius.card)
                .stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline)
        }
        .overlay {
            if !reduceMotion {
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            NLColor.accentPrimary.opacity(0.12),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * 0.7)
                    .offset(x: proxy.size.width * shimmerOffset)
                }
                .mask(RoundedRectangle(cornerRadius: NLRadius.card))
            }
        }
    }
    
    private var accessibilityLabelText: Text {
        Text("booster.loading.a11y")
    }
}
