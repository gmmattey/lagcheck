import SwiftUI
#if canImport(UIKit)
import UIKit

@MainActor
private final class MeasurementHapticsManager {
    static let shared = MeasurementHapticsManager()
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)

    private init() {
        light.prepare()
        medium.prepare()
        heavy.prepare()
    }

    func play(milestone: Int, isUnderStress: Bool, rtt: Double?) {
        #if targetEnvironment(simulator)
        print("[LagCheck Haptics] Pulse milestone \(milestone) | stress: \(isUnderStress) | rtt: \(rtt ?? 0)ms")
        #endif

        switch milestone {
        case 0:
            light.prepare()
            light.impactOccurred(intensity: 0.6)
        case 1, 3:
            light.prepare()
            light.impactOccurred(intensity: 0.4)
        case 2:
            let gen = isUnderStress ? heavy : medium
            gen.prepare()
            let intensity: CGFloat = isUnderStress ? 1.0 : (rtt.map { CGFloat(min(1.0, max(0.6, $0 / 100.0))) } ?? 0.8)
            gen.impactOccurred(intensity: intensity)
        default:
            break
        }
    }
}
#endif

/// Localização de eventual gargalo (preservado para compatibilidade estrutural de tipo).
public enum MeasurementStressLocation: String, Sendable {
    case none
    case localNetwork
    case externalRoute
}

/// Experiência Visual Canônica de Medição do LagCheck (Dark Competitive UI).
/// Rota de telemetria em 3 nós com ícones correspondentes, pingo de dados ("pingo") simulando o tráfego RTT,
/// resposta háptica sincronizada com a velocidade/intensidade do ping e barra de progresso gradual.
public struct MeasurementLiveTrail: View {
    private let isWiFi: Bool
    private let destinationName: String
    private let currentRTT: Double?
    private let progress: Double
    private let sampleCount: Int
    private let isUnderStress: Bool
    private let isPhaseRest: Bool
    private let phaseTitle: LocalizedStringKey
    private let phaseSubtitle: LocalizedStringKey?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date()

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
        self.currentRTT = currentRTT
        self.progress = max(0.0, min(1.0, progress))
        self.sampleCount = sampleCount
        self.isUnderStress = isUnderStress
        self.isPhaseRest = isPhaseRest ?? (!isUnderStress)
        self.phaseTitle = phaseTitle
        self.phaseSubtitle = phaseSubtitle
    }

    /// Duração do ciclo de ida e volta (RTT) do pingo em segundos.
    /// Varia de ~0.7s (ping ultra-baixo, ~10ms) até ~2.0s (ping alto sob lag/carga).
    private var cycleDuration: Double {
        guard let rtt = currentRTT, rtt > 0 else { return 1.2 }
        let clampedRTT = min(max(rtt, 10), 250)
        return 0.7 + (clampedRTT - 10) / 240.0 * 1.3
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Trilha de Rota com 3 nós e pingo vivo percorrendo a rota
            routeView
                .padding(.top, NLSpacing.md)
                .padding(.bottom, 48)

            // Cópia de Status do Check (25pt display bold)
            Text(isPhaseRest ? LocalizedStringKey("check.status.rest") : LocalizedStringKey("check.status.load"))
                .font(NLTypography.statusCopy)
                .foregroundStyle(NLColor.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("check-status")

            // Subtítulo de Apoio
            Text(isPhaseRest ? LocalizedStringKey("check.detail.rest") : LocalizedStringKey("check.detail.load"))
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(NLColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 11)
                .accessibilityIdentifier("check-detail")

            // Barra de Progresso Gradual do início ao fim (4px altura)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(NLColor.surface)
                        .frame(height: 4)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    NLColor.gamerPurple,
                                    NLColor.gamerPurple.opacity(0.85)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, proxy.size.width * CGFloat(progress)), height: 4)
                        .animation(.easeInOut(duration: 0.35), value: progress)
                }
            }
            .frame(height: 4)
            .padding(.top, 38)
            .padding(.horizontal, NLSpacing.sm)

            // Kicker de Fase (11pt mono)
            Text(isPhaseRest ? LocalizedStringKey("check.phase.rest") : LocalizedStringKey("check.phase.load"))
                .font(NLTypography.monospaceMetrics)
                .foregroundStyle(NLColor.textTertiary)
                .padding(.top, 14)
                .accessibilityIdentifier("phase")
        }
        .padding(.horizontal, NLSpacing.md)
        .accessibilityElement(children: .combine)
        .task(id: cycleDuration) {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                // Milestone 0: iPhone (origem)
                triggerHaptic(milestone: 0)
                try? await Task.sleep(nanoseconds: UInt64(cycleDuration * 0.25 * 1_000_000_000))
                guard !Task.isCancelled else { break }

                // Milestone 1: Roteador/Wi-Fi (salto local de ida)
                triggerHaptic(milestone: 1)
                try? await Task.sleep(nanoseconds: UInt64(cycleDuration * 0.25 * 1_000_000_000))
                guard !Task.isCancelled else { break }

                // Milestone 2: Servidor (eco/destino)
                triggerHaptic(milestone: 2)
                try? await Task.sleep(nanoseconds: UInt64(cycleDuration * 0.25 * 1_000_000_000))
                guard !Task.isCancelled else { break }

                // Milestone 3: Roteador/Wi-Fi (salto local de volta)
                triggerHaptic(milestone: 3)
                try? await Task.sleep(nanoseconds: UInt64(cycleDuration * 0.25 * 1_000_000_000))
                guard !Task.isCancelled else { break }
            }
        }
    }

    // MARK: - 3-Node Route View com Pingo de Dados em Tempo Real
    private var routeView: some View {
        TimelineView(.animation) { timelineContext in
            let date = timelineContext.date
            let elapsed = date.timeIntervalSince(startDate)
            let cycle = elapsed.truncatingRemainder(dividingBy: cycleDuration) / cycleDuration

            let isOutbound = cycle <= 0.5
            let nodeFraction: CGFloat = isOutbound ? CGFloat(cycle * 2.0) : CGFloat((1.0 - cycle) * 2.0)

            // Deteção de passagem nos nós para iluminação sutil e reativa
            let isHitNode1 = cycle < 0.08 || cycle > 0.92
            let isHitNode2 = (cycle >= 0.21 && cycle <= 0.29) || (cycle >= 0.71 && cycle <= 0.79)
            let isHitNode3 = cycle >= 0.46 && cycle <= 0.54

            ZStack(alignment: .top) {
                // 1. Linha horizontal de infraestrutura (passa exatamente no centro de 51x51, ou seja y = 25.5)
                GeometryReader { proxy in
                    let y: CGFloat = 25.5
                    let startX = proxy.size.width * (1.0 / 6.0)
                    let endX = proxy.size.width * (5.0 / 6.0)

                    Path { path in
                        path.move(to: CGPoint(x: startX, y: y))
                        path.addLine(to: CGPoint(x: endX, y: y))
                    }
                    .stroke(NLColor.borderStrong, lineWidth: 1.5)
                }
                .frame(height: 51)

                // 2. Pingo animado viajando sobre a rota (passa por baixo dos nós)
                if !reduceMotion {
                    GeometryReader { proxy in
                        let y: CGFloat = 25.5
                        let startX = proxy.size.width * (1.0 / 6.0)
                        let endX = proxy.size.width * (5.0 / 6.0)
                        let currentX = startX + (endX - startX) * nodeFraction

                        // Rastro cometa dinâmico
                        let tailLength: CGFloat = 38.0
                        let tailStart = isOutbound ? max(startX, currentX - tailLength) : min(endX, currentX + tailLength)

                        Path { path in
                            path.move(to: CGPoint(x: tailStart, y: y))
                            path.addLine(to: CGPoint(x: currentX, y: y))
                        }
                        .stroke(
                            LinearGradient(
                                colors: isOutbound
                                    ? [NLColor.gamerPurple.opacity(0.0), NLColor.gamerPurple.opacity(0.75)]
                                    : [NLColor.gamerPurple.opacity(0.75), NLColor.gamerPurple.opacity(0.0)],
                                startPoint: isOutbound ? .leading : .trailing,
                                endPoint: isOutbound ? .trailing : .leading
                            ),
                            lineWidth: 3
                        )

                        // Pingo brilhante
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            NLColor.gamerPurple.opacity(isUnderStress ? 0.7 : 0.45),
                                            NLColor.gamerPurple.opacity(0.0)
                                        ],
                                        center: .center,
                                        startRadius: 2,
                                        endRadius: 14
                                    )
                                )
                                .frame(width: 28, height: 28)

                            Circle()
                                .fill(NLColor.gamerPurple)
                                .frame(width: 10, height: 10)
                                .shadow(color: NLColor.gamerPurple, radius: 4, x: 0, y: 0)

                            Circle()
                                .fill(Color.white)
                                .frame(width: 4, height: 4)
                        }
                        .position(x: currentX, y: y)
                    }
                    .frame(height: 51)
                    .allowsHitTesting(false)
                }

                // 3. Os 3 nós alinhados com ícones correspondentes (círculo 51x51 no topo, na frente da trilha e do pingo)
                HStack(alignment: .top, spacing: 0) {
                    // Nó 1: iPhone
                    nodeItem(
                        icon: "iphone",
                        title: Text(LocalizedStringKey("check.node.iphone")),
                        isFinished: true,
                        isCurrent: false,
                        isHit: isHitNode1
                    )
                    .frame(maxWidth: .infinity)

                    // Nó 2: Rede local (Wi-Fi / Rede Móvel)
                    nodeItem(
                        icon: isWiFi ? "wifi" : "antenna.radiowaves.left.and.right",
                        title: Text(isWiFi ? LocalizedStringKey("check.node.wifi") : LocalizedStringKey("check.node.cellular")),
                        isFinished: !isPhaseRest,
                        isCurrent: isPhaseRest,
                        isHit: isHitNode2
                    )
                    .frame(maxWidth: .infinity)

                    // Nó 3: Região Gamer (Destino)
                    nodeItem(
                        icon: "server.rack",
                        title: Text(String(format: String(localized: "check.node.gamer_region %@", defaultValue: "Região Gamer\n%@"), destinationName)),
                        isFinished: false,
                        isCurrent: !isPhaseRest,
                        isHit: isHitNode3
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func nodeItem(
        icon: String,
        title: Text,
        isFinished: Bool,
        isCurrent: Bool,
        isHit: Bool = false
    ) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(NLColor.surface)
                    .frame(width: 51, height: 51)
                    .overlay(
                        Circle()
                            .stroke(
                                isHit ? NLColor.gamerPurple : (isCurrent ? NLColor.gamerPurple : (isFinished ? NLColor.gamerPurple.opacity(0.8) : NLColor.borderStrong)),
                                lineWidth: isHit ? 2.5 : 1.5
                            )
                    )
                    .shadow(
                        color: (isHit || isCurrent) ? NLColor.gamerPurple.opacity(isHit ? 0.6 : 0.25) : Color.clear,
                        radius: isHit ? 10 : 6,
                        x: 0,
                        y: 0
                    )
                    .scaleEffect(isHit ? 1.08 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isHit)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle((isHit || isCurrent) ? NLColor.gamerPurple : (isFinished ? NLColor.textPrimary : NLColor.textSecondary))
            }

            title
                .font(NLTypography.monospaceSubtitle)
                .foregroundStyle(NLColor.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }

    @MainActor
    private func triggerHaptic(milestone: Int) {
        guard !reduceMotion else { return }
        #if canImport(UIKit)
        MeasurementHapticsManager.shared.play(
            milestone: milestone,
            isUnderStress: isUnderStress,
            rtt: currentRTT
        )
        #endif
    }
}
