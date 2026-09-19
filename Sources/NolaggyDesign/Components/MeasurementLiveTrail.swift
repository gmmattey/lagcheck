import SwiftUI

/// Localização do gargalo diagnosticado durante a fase de estresse sob carga.
public enum MeasurementStressLocation: String, Sendable {
    case none
    case localNetwork
    case externalRoute
}

/// Componente visual canônico do LagCheck para acompanhar a rota ao vivo.
/// Substitui o gauge circular e o gráfico abstrato por uma trilha verificável de 3 nós:
/// [ iPhone ] ➔ [ Wi-Fi / Roteador ] ➔ [ Região Gamer ]
public struct MeasurementLiveTrail: View {
    private let isWiFi: Bool
    private let destinationName: String
    private let currentRTT: Double?
    private let progress: Double
    private let sampleCount: Int
    private let lossCount: Int
    private let isUnderStress: Bool
    private let stressLocation: MeasurementStressLocation
    private let phaseTitle: LocalizedStringKey
    private let phaseSubtitle: LocalizedStringKey?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        isWiFi: Bool = true,
        destinationName: String,
        currentRTT: Double? = nil,
        progress: Double = 0,
        sampleCount: Int = 0,
        lossCount: Int = 0,
        isUnderStress: Bool = false,
        stressLocation: MeasurementStressLocation = .none,
        phaseTitle: LocalizedStringKey,
        phaseSubtitle: LocalizedStringKey? = nil
    ) {
        self.isWiFi = isWiFi
        self.destinationName = destinationName
        self.currentRTT = currentRTT
        self.progress = min(max(progress, 0), 1)
        self.sampleCount = sampleCount
        self.lossCount = lossCount
        self.isUnderStress = isUnderStress
        self.stressLocation = stressLocation
        self.phaseTitle = phaseTitle
        self.phaseSubtitle = phaseSubtitle
    }

    public var body: some View {
        VStack(spacing: NLSpacing.lg) {
            // Header: Título da fase e barra de progresso sutil
            VStack(spacing: NLSpacing.xs) {
                Text(phaseTitle)
                    .font(NLTypography.headline)
                    .foregroundStyle(NLColor.textPrimary)
                    .multilineTextAlignment(.center)

                if let phaseSubtitle {
                    Text(phaseSubtitle)
                        .font(NLTypography.footnote)
                        .foregroundStyle(NLColor.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Barra de progresso linear fina
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(NLColor.backgroundOverlay)
                            .frame(height: 4)

                        Capsule()
                            .fill(isUnderStress ? NLColor.coralSolarRed : NLColor.accentPrimary)
                            .frame(width: max(geo.size.width * CGFloat(progress), 6), height: 4)
                            .animation(.smooth(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 4)
                .padding(.top, NLSpacing.xxs)
            }
            .padding(.horizontal, NLSpacing.xs)

            // Card principal com a trilha viva (Padrão Inset Grouped do HIG)
            VStack(spacing: 0) {
                // Nó 1: iPhone
                nodeRow(
                    icon: "iphone",
                    title: String(localized: "live_trail.node.device", defaultValue: "Seu iPhone"),
                    subtitle: String(localized: "live_trail.badge.origin", defaultValue: "Origem do teste"),
                    badge: "100%",
                    badgeColor: NLColor.scoreExcellent
                )

                // Trecho 1: Salto Local (Wi-Fi ou Celular)
                trackSection(
                    isStressed: isUnderStress && stressLocation == .localNetwork,
                    label: isWiFi ? "< 2 ms (Wi-Fi)" : "Rede móvel",
                    statusText: (isUnderStress && stressLocation == .localNetwork) ? "Saturação local" : "Enlace local estável"
                )

                // Nó 2: Roteador Local / Gateway
                nodeRow(
                    icon: isWiFi ? "wifi" : "antenna.radiowaves.left.and.right",
                    title: isWiFi
                        ? String(localized: "live_trail.node.router", defaultValue: "Roteador local")
                        : String(localized: "live_trail.node.cellular", defaultValue: "Rede móvel"),
                    subtitle: isWiFi
                        ? String(localized: "live_trail.badge.wifi", defaultValue: "Salto sem fio")
                        : String(localized: "live_trail.badge.cellular", defaultValue: "Operadora móvel"),
                    badge: (isUnderStress && stressLocation == .localNetwork) ? "Sob carga" : "Ativo",
                    badgeColor: (isUnderStress && stressLocation == .localNetwork) ? NLColor.coralSolarRed : NLColor.accentPrimary
                )

                // Trecho 2: Rota Externa até a Região Gamer
                trackSection(
                    isStressed: isUnderStress && stressLocation == .externalRoute,
                    label: currentRTT.map { "\(Int($0.rounded())) ms" } ?? "...",
                    statusText: (isUnderStress && stressLocation == .externalRoute) ? "Gargalo sob carga" : "Rota externa"
                )

                // Nó 3: Região Gamer de Destino
                nodeRow(
                    icon: "server.rack",
                    title: destinationName,
                    subtitle: String(localized: "live_trail.badge.destination", defaultValue: "Infraestrutura de referência"),
                    badge: currentRTT != nil ? "Respondendo" : "Aguardando",
                    badgeColor: currentRTT != nil ? NLColor.scoreExcellent : NLColor.textSecondary
                )
            }
            .padding(NLSpacing.cardPadding)
            .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isUnderStress ? NLColor.coralSolarRed.opacity(0.4) : NLColor.borderSubtle,
                        lineWidth: isUnderStress ? 1.0 : 0.5
                    )
            }

            // Rodapé com latência atual em destaque e status de pacotes (Grid HIG)
            HStack(spacing: NLSpacing.sm) {
                // Ping instantâneo
                VStack(spacing: NLSpacing.xxs) {
                    if let currentRTT {
                        Text("\(Int(currentRTT.rounded())) ms")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(NLColor.textPrimary)
                            .contentTransition(.numericText())
                    } else {
                        Text("—")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(NLColor.textSecondary)
                    }
                    Text(String(localized: "quick_check.measuring.current_rtt", defaultValue: "Ping atual"))
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, NLSpacing.sm)
                .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(NLColor.borderSubtle, lineWidth: 0.5) }

                // Amostras coletadas
                VStack(spacing: NLSpacing.xxs) {
                    Text("\(sampleCount)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(NLColor.accentPrimary)
                    Text(String(localized: "live_trail.footer.samples", defaultValue: "Amostras UDP"))
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, NLSpacing.sm)
                .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(NLColor.borderSubtle, lineWidth: 0.5) }

                // Perda de pacotes
                VStack(spacing: NLSpacing.xxs) {
                    Text("\(lossCount)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(lossCount > 0 ? NLColor.coralSolarRed : NLColor.textPrimary)
                    Text(String(localized: "quick_check.measuring.loss", defaultValue: "Perda"))
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, NLSpacing.sm)
                .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(NLColor.borderSubtle, lineWidth: 0.5) }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    // MARK: - Subviews

    private func nodeRow(icon: String, title: String, subtitle: String, badge: String, badgeColor: Color) -> some View {
        HStack(spacing: NLSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(NLColor.backgroundOverlay)
                    .frame(width: 38, height: 38)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(badgeColor.opacity(0.35), lineWidth: 1.0)
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(badgeColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(NLTypography.subheadline)
                    .foregroundStyle(NLColor.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(NLTypography.caption)
                    .foregroundStyle(NLColor.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            Text(badge)
                .font(NLTypography.caption)
                .foregroundStyle(badgeColor)
                .padding(.horizontal, NLSpacing.xs)
                .padding(.vertical, NLSpacing.xxs)
                .background(badgeColor.opacity(0.12), in: Capsule())
        }
    }

    private func trackSection(isStressed: Bool, label: String, statusText: String) -> some View {
        HStack(spacing: NLSpacing.sm) {
            // Canal visual vertical onde trafegam os pacotes
            ZStack {
                Rectangle()
                    .fill(NLColor.borderSubtle)
                    .frame(width: 2, height: 48)

                if isStressed {
                    Rectangle()
                        .fill(NLColor.coralSolarRed)
                        .frame(width: 3, height: 48)
                }

                if !reduceMotion {
                    TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        Canvas { context, size in
                            let speed = isStressed ? 1.2 : 2.0
                            let particleCount = 4

                            for i in 0..<particleCount {
                                let offset = Double(i) / Double(particleCount)
                                let progress = (time * speed + offset).truncatingRemainder(dividingBy: 1.0)
                                let y = progress * size.height
                                let point = CGPoint(x: size.width / 2, y: y)

                                let rect = CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)
                                let color = isStressed ? NLColor.coralSolarRed : NLColor.accentPrimary
                                context.fill(Circle().path(in: rect), with: .color(color))
                            }
                        }
                    }
                    .frame(width: 14, height: 48)
                }
            }
            .frame(width: 44)

            // Descrição do enlace / status do trecho
            HStack {
                Text(statusText)
                    .font(NLTypography.caption)
                    .foregroundStyle(isStressed ? NLColor.coralSolarRed : NLColor.textSecondary)

                Spacer()

                Text(label)
                    .font(NLTypography.caption)
                    .foregroundStyle(isStressed ? NLColor.coralSolarRed : NLColor.textTertiary)
            }
            .padding(.trailing, NLSpacing.xs)
        }
    }

    private var accessibilityText: String {
        let rttDesc = currentRTT.map { "\(Int($0)) milissegundos" } ?? "medindo"
        let stressDesc = isUnderStress ? "em teste de carga sob estresse" : "medição padrão"
        return "Trilha de medição ativa para \(destinationName). Ping atual \(rttDesc). \(sampleCount) amostras, \(lossCount) perdas. \(stressDesc)."
    }
}
