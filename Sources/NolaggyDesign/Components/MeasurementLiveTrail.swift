import SwiftUI

/// Localização de eventual gargalo (preservado para compatibilidade estrutural de tipo).
public enum MeasurementStressLocation: String, Sendable {
    case none
    case localNetwork
    case externalRoute
}

/// Experiência Visual Canônica de Medição do LagCheck (Mockup 03 · Dark Competitive UI).
/// Rota de telemetria em 3 nós com pacotes em trânsito em Roxo Gamer, status de alta legibilidade,
/// barra de progresso contínua e sem números oscilantes de ping.
public struct MeasurementLiveTrail: View {
    private let isWiFi: Bool
    private let destinationName: String
    private let currentRTT: Double?
    private let isPhaseRest: Bool
    private let sampleCount: Int
    private let isUnderStress: Bool
    private let phaseTitle: LocalizedStringKey
    private let phaseSubtitle: LocalizedStringKey?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var packetOffset: CGFloat = 0.0

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
        self.isPhaseRest = isPhaseRest ?? (!isUnderStress)
        self.sampleCount = sampleCount
        self.isUnderStress = isUnderStress
        self.phaseTitle = phaseTitle
        self.phaseSubtitle = phaseSubtitle
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Trilha de Rota com 3 nós e pacotes viajando
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

            // Barra de Progresso Contínua (4px altura)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(NLColor.surface)
                        .frame(height: 4)

                    Capsule()
                        .fill(NLColor.gamerPurple)
                        .frame(width: proxy.size.width * (isPhaseRest ? 0.45 : 0.85), height: 4)
                        .animation(.easeInOut(duration: 0.6), value: isPhaseRest)
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
        .onAppear {
            if !reduceMotion {
                withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                    packetOffset = 1.0
                }
            }
        }
    }

    // MARK: - 3-Node Route View
    private var routeView: some View {
        ZStack {
            // Linha horizontal conectando os nós
            GeometryReader { proxy in
                Path { path in
                    let y: CGFloat = 25
                    let startX = proxy.size.width * 0.16
                    let endX = proxy.size.width * 0.84
                    path.move(to: CGPoint(x: startX, y: y))
                    path.addLine(to: CGPoint(x: endX, y: y))
                }
                .stroke(NLColor.borderStrong, lineWidth: 1)

                // Pacotes de dados viajando na linha
                if !reduceMotion {
                    let startX = proxy.size.width * 0.18
                    let totalDistance = proxy.size.width * 0.64
                    ForEach(0..<3, id: \.self) { index in
                        let delay = Double(index) * 0.33
                        let fraction = (packetOffset + delay).truncatingRemainder(dividingBy: 1.0)
                        Circle()
                            .fill(NLColor.gamerPurple)
                            .frame(width: 7, height: 7)
                            .position(x: startX + totalDistance * fraction, y: 25)
                            .opacity(fraction < 0.1 ? fraction * 10 : (fraction > 0.9 ? (1.0 - fraction) * 10 : 0.85))
                    }
                }
            }
            .frame(height: 52)

            // Os 3 nós alinhados
            HStack(alignment: .top, spacing: 0) {
                // Nó 1: iPhone
                nodeItem(
                    badge: "IP",
                    title: LocalizedStringKey("check.node.iphone"),
                    isFinished: true,
                    isCurrent: false
                )
                .frame(maxWidth: .infinity)

                // Nó 2: Rede local (Wi-Fi / Móvel)
                nodeItem(
                    badge: isWiFi ? "Wi" : "4G",
                    title: isWiFi ? LocalizedStringKey("check.node.wifi") : LocalizedStringKey("check.node.cellular"),
                    isFinished: !isPhaseRest,
                    isCurrent: isPhaseRest
                )
                .frame(maxWidth: .infinity)

                // Nó 3: Região Gamer (Destino)
                nodeItem(
                    badge: regionBadgeText,
                    title: LocalizedStringKey("check.node.gamer_region \(destinationName)"),
                    isFinished: false,
                    isCurrent: !isPhaseRest
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var regionBadgeText: String {
        let trimmed = destinationName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.localizedCaseInsensitiveContains("paulo") {
            return "SP"
        }
        let initials = trimmed.split(separator: " ").compactMap { $0.first }.prefix(2)
        return initials.isEmpty ? "RG" : String(initials).uppercased()
    }

    private func nodeItem(badge: String, title: LocalizedStringKey, isFinished: Bool, isCurrent: Bool) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(NLColor.surface)
                    .frame(width: 51, height: 51)
                    .overlay(
                        Circle()
                            .stroke(isCurrent ? NLColor.gamerPurple : (isFinished ? NLColor.gamerPurple.opacity(0.8) : NLColor.borderStrong), lineWidth: 1.5)
                    )
                    .shadow(color: isCurrent ? NLColor.gamerPurple.opacity(0.25) : Color.clear, radius: 6, x: 0, y: 0)

                Text(verbatim: badge)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(isCurrent ? NLColor.textPrimary : NLColor.textSecondary)
            }

            Text(title)
                .font(NLTypography.monospaceSubtitle)
                .foregroundStyle(NLColor.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
}
