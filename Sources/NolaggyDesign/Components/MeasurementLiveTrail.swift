import SwiftUI

/// Localização de eventual gargalo (preservado para compatibilidade estrutural de tipo).
public enum MeasurementStressLocation: String, Sendable {
    case none
    case localNetwork
    case externalRoute
}

/// Experiência Visual Imersiva de Medição do LagCheck (Decisão 47).
/// Substitui o checklist de auditoria técnica de 5 nós por uma apresentação
/// editorial centrada no jogador com o Pulse Gauge Coral Solar:
///
/// 1. Topo Editorial: Jogo e Fase atual do teste.
/// 2. Hero Pulse Gauge: Radar de ondas concêntricas fluidas em Coral Solar.
/// 3. Voz do Jogo: Microcopy calmo e contextual (sem termos áridos de telecomunicações).
/// 4. Barra de Etapas da Partida: Indicador fluido de 2 tempos (Conexão base e Sob pressão).
/// 5. Rodapé Editorial da Rota: Síntese minimalista da origem e destino ativos.
///
/// Diretrizes estritas:
/// - Zero ruído técnico: sem números oscilantes de milissegundos pulando.
/// - Suporte total a `accessibilityReduceMotion` (ondas contínuas viram anéis suaves estáticos).
/// - Toda a animação é alimentada pela telemetria real de `sampleCount` e fase.
public struct MeasurementLiveTrail: View {
    private let isWiFi: Bool
    private let destinationName: String
    private let isPhaseRest: Bool
    private let isDestinationResponding: Bool
    private let sampleCount: Int
    private let isUnderStress: Bool
    private let phaseTitle: LocalizedStringKey
    private let phaseSubtitle: LocalizedStringKey?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var waveAnimation: Bool = false

    public init(
        isWiFi: Bool = true,
        destinationName: String,
        currentRTT: Double? = nil,
        progress: Double = 0,
        sampleCount: Int = 0,
        lossCount: Int = 0,
        isUnderStress: Bool = false,
        stressLocation: MeasurementStressLocation = .none,
        isPhaseRest: Bool? = nil,
        phaseTitle: LocalizedStringKey,
        phaseSubtitle: LocalizedStringKey? = nil
    ) {
        self.isWiFi = isWiFi
        self.destinationName = destinationName
        self.isPhaseRest = isPhaseRest ?? (!isUnderStress)
        self.isDestinationResponding = (sampleCount > 0) || (currentRTT != nil)
        self.sampleCount = sampleCount
        self.isUnderStress = isUnderStress
        self.phaseTitle = phaseTitle
        self.phaseSubtitle = phaseSubtitle
    }

    public var body: some View {
        VStack(spacing: NLSpacing.xl) {
            headerSection

            Spacer(minLength: NLSpacing.xs)

            pulseGaugeHero

            Spacer(minLength: NLSpacing.xs)

            contextualStatusSection

            stepProgressSection

            routeFooterCard
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: isUnderStress ? 1.4 : 1.8).repeatForever(autoreverses: false)) {
                    waveAnimation = true
                }
            }
        }
        .onChange(of: reduceMotion) { _, isReduced in
            if isReduced {
                waveAnimation = false
            } else {
                withAnimation(.easeInOut(duration: isUnderStress ? 1.4 : 1.8).repeatForever(autoreverses: false)) {
                    waveAnimation = true
                }
            }
        }
    }

    // MARK: - Header Editorial
    private var headerSection: some View {
        VStack(spacing: NLSpacing.xxs) {
            if let phaseSubtitle {
                Text(phaseSubtitle)
                    .font(NLTypography.caption.weight(.bold))
                    .foregroundStyle(NLColor.accentPrimary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(NLColor.accentPrimarySubtle, in: Capsule())
            }

            Text(isPhaseRest
                ? String(localized: "live_trail.phase.rest.title", defaultValue: "Etapa 1: Conexão base")
                : String(localized: "live_trail.phase.load.title", defaultValue: "Etapa 2: Conexão sob pressão"))
                .font(NLTypography.headline)
                .foregroundStyle(NLColor.textPrimary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Hero Pulse Gauge Coral Solar
    private var pulseGaugeHero: some View {
        ZStack {
            // Ondas concêntricas animadas
            if !reduceMotion {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(NLColor.accentPrimary.opacity(waveAnimation ? 0.0 : 0.45), lineWidth: 1.5)
                        .scaleEffect(waveAnimation ? 2.1 + CGFloat(index) * 0.25 : 1.0)
                        .opacity(waveAnimation ? 0.0 : 0.8)
                        .animation(
                            .easeOut(duration: isUnderStress ? 1.5 : 2.0)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.45),
                            value: waveAnimation
                        )
                }
            } else {
                // Modo Acessibilidade (sem movimento): Anéis suaves estáticos
                Circle()
                    .stroke(NLColor.accentPrimary.opacity(0.18), lineWidth: 1.5)
                    .scaleEffect(1.35)
                Circle()
                    .stroke(NLColor.accentPrimary.opacity(0.08), lineWidth: 1.0)
                    .scaleEffect(1.7)
            }

            // Halo sutil de iluminação Coral Solar
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            NLColor.accentPrimary.opacity(isUnderStress ? 0.32 : 0.22),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 90
                    )
                )
                .frame(width: 170, height: 170)

            // Núcleo central elevado
            Circle()
                .fill(NLColor.backgroundRaised)
                .frame(width: 84, height: 84)
                .overlay {
                    Circle()
                        .stroke(NLColor.accentPrimary.opacity(0.5), lineWidth: 1.5)
                }
                .shadow(color: NLColor.accentPrimary.opacity(0.25), radius: 14, x: 0, y: 0)

            // Ícone do sinal / conexão no centro
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(NLColor.accentPrimary)
        }
        .frame(width: 200, height: 200)
    }

    // MARK: - Mensagem Contextual da Partida (Voz do Jogo)
    private var contextualStatusSection: some View {
        VStack(spacing: NLSpacing.xxs) {
            Text(dynamicStatusTitle)
                .font(NLTypography.headline)
                .foregroundStyle(NLColor.textPrimary)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: dynamicStatusTitle)

            Text(dynamicStatusDetail)
                .font(NLTypography.footnote)
                .foregroundStyle(NLColor.textSecondary)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: dynamicStatusDetail)
        }
        .padding(.horizontal, NLSpacing.md)
    }

    private var dynamicStatusTitle: String {
        if sampleCount == 0 {
            return String(localized: "live_trail.status.connecting \(destinationName)")
        }
        if isPhaseRest {
            return sampleCount < 15
                ? String(localized: "live_trail.status.rest.evaluating")
                : String(localized: "live_trail.status.rest.stability")
        } else {
            return sampleCount < 15
                ? String(localized: "live_trail.status.load.simulating")
                : String(localized: "live_trail.status.load.resistance")
        }
    }

    private var dynamicStatusDetail: String {
        if sampleCount == 0 {
            return String(localized: "live_trail.hint.keep_open")
        }
        if isPhaseRest {
            return sampleCount < 15
                ? String(localized: "live_trail.status.rest.evaluating.detail")
                : String(localized: "live_trail.status.rest.stability.detail")
        } else {
            return sampleCount < 15
                ? String(localized: "live_trail.status.load.simulating.detail")
                : String(localized: "live_trail.status.load.resistance.detail")
        }
    }

    // MARK: - Barra de Etapas da Partida (2 Fases)
    private var stepProgressSection: some View {
        VStack(spacing: NLSpacing.xs) {
            HStack(spacing: NLSpacing.sm) {
                // Etapa 1: Repouso
                stepBar(
                    title: String(localized: "live_trail.phase.rest.title", defaultValue: "Conexão base"),
                    progress: isPhaseRest ? min(Double(sampleCount) / 30.0, 1.0) : 1.0,
                    isActive: isPhaseRest,
                    isDone: !isPhaseRest
                )

                // Etapa 2: Carga
                stepBar(
                    title: String(localized: "live_trail.phase.load.title", defaultValue: "Sob pressão"),
                    progress: !isPhaseRest ? min(Double(sampleCount) / 30.0, 1.0) : 0.0,
                    isActive: !isPhaseRest,
                    isDone: false
                )
            }
        }
        .padding(.horizontal, NLSpacing.xs)
    }

    private func stepBar(title: String, progress: Double, isActive: Bool, isDone: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(NLColor.backgroundRaised)
                        .frame(height: 6)

                    Capsule()
                        .fill(isDone ? NLColor.scoreExcellent : NLColor.accentPrimary)
                        .frame(width: proxy.size.width * max(progress, 0.02), height: 6)
                        .animation(.smooth(duration: 0.35), value: progress)
                }
            }
            .frame(height: 6)

            HStack {
                Text(title)
                    .font(NLTypography.caption.weight(isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? NLColor.textPrimary : NLColor.textTertiary)
                Spacer()
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(NLColor.scoreExcellent)
                }
            }
        }
    }

    // MARK: - Rodapé Editorial da Rota
    private var routeFooterCard: some View {
        HStack(spacing: NLSpacing.xs) {
            HStack(spacing: 6) {
                Image(systemName: isWiFi ? "wifi" : "antenna.radiowaves.left.and.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(NLColor.textPrimary)
                Text(isWiFi
                    ? String(localized: "live_trail.node.wifi", defaultValue: "Wi-Fi")
                    : String(localized: "live_trail.node.cellular", defaultValue: "Rede móvel"))
                    .font(NLTypography.caption.weight(.medium))
                    .foregroundStyle(NLColor.textPrimary)
            }

            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(NLColor.textTertiary)

            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(NLColor.textPrimary)
                Text(destinationName)
                    .font(NLTypography.caption.weight(.medium))
                    .foregroundStyle(NLColor.textPrimary)
                    .lineLimit(1)
            }

            Spacer()

            Text(String(localized: "live_trail.route.active", defaultValue: "Rota ativa"))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(NLColor.scoreExcellent)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(NLColor.scoreExcellent.opacity(0.12), in: Capsule())
        }
        .padding(.horizontal, NLSpacing.cardPadding)
        .padding(.vertical, NLSpacing.sm)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(NLColor.borderSubtle, lineWidth: 0.5)
        }
    }

    private var accessibilityDescription: String {
        "\(dynamicStatusTitle). \(isPhaseRest ? "Etapa 1 de 2" : "Etapa 2 de 2"). Rota ativa: \(isWiFi ? "Wi-Fi" : "Rede móvel") para \(destinationName)."
    }
}
