import SwiftUI

/// Localização de eventual gargalo (preservado para compatibilidade estrutural de tipo).
public enum MeasurementStressLocation: String, Sendable {
    case none
    case localNetwork
    case externalRoute
}

/// Trilha Visual Canônica HIG do LagCheck (Decisão 36).
/// Apresenta uma rota limpa e determinística em 5 nós verticais conectados:
///
/// Wi‑Fi ou Rede móvel       [estado]
/// │
/// Ping                      [estado]
/// │
/// Perda                     [estado]
/// │
/// Sob carga                 [estado]
/// │
/// São Paulo                 [estado]
///
/// Diretrizes estritas:
/// - "Ping" e "Perda" são observados em paralelo nas duas fases.
/// - "Sob carga" fica aguardando durante repouso e ativo na segunda fase.
/// - A região de referência começa a responder já na primeira fase e permanece ativa durante a segunda.
/// - O nome da região é amigável e vem do catálogo (sem chamar de servidor oficial do jogo).
/// - Proibição total de números, gráficos, percentuais, tempo restante, score ou explicações durante a execução.
/// - Em rede móvel: ícone `antenna.radiowaves.left.and.right`, sem exibir nem inferir roteador local, frequência 2.4/5 GHz ou gateway.
public struct MeasurementLiveTrail: View {
    private let isWiFi: Bool
    private let destinationName: String
    private let isPhaseRest: Bool
    private let isDestinationResponding: Bool
    private let phaseTitle: LocalizedStringKey
    private let phaseSubtitle: LocalizedStringKey?

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
        self.phaseTitle = phaseTitle
        self.phaseSubtitle = phaseSubtitle
    }

    public var body: some View {
        VStack(spacing: NLSpacing.lg) {
            // Header editorial: Título da fase e contexto (sem tempos, números ou percentuais)
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
            }
            .padding(.horizontal, NLSpacing.xs)

            // Card com a Trilha Visual HIG de 5 Passos
            VStack(spacing: 0) {
                // Nó 1: Wi-Fi ou Rede móvel
                nodeRow(
                    icon: isWiFi ? "wifi" : "antenna.radiowaves.left.and.right",
                    title: isWiFi
                        ? String(localized: "live_trail.node.wifi", defaultValue: "Wi-Fi")
                        : String(localized: "live_trail.node.cellular", defaultValue: "Rede móvel"),
                    badge: String(localized: "live_trail.state.connected", defaultValue: "Conectado"),
                    badgeColor: NLColor.scoreExcellent,
                    isActive: true
                )

                connectorLine(isActive: true)

                // Nó 2: Ping
                nodeRow(
                    icon: "speedometer",
                    title: String(localized: "live_trail.node.ping", defaultValue: "Ping"),
                    badge: isDestinationResponding
                        ? String(localized: "live_trail.state.measuring", defaultValue: "Medindo")
                        : String(localized: "live_trail.state.connecting", defaultValue: "Conectando"),
                    badgeColor: isDestinationResponding ? NLColor.accentPrimary : NLColor.textSecondary,
                    isActive: isDestinationResponding
                )

                connectorLine(isActive: isDestinationResponding)

                // Nó 3: Perda
                nodeRow(
                    icon: "shield.lefthalf.filled",
                    title: String(localized: "live_trail.node.loss", defaultValue: "Perda"),
                    badge: isDestinationResponding
                        ? String(localized: "live_trail.state.monitoring", defaultValue: "Monitorando")
                        : String(localized: "live_trail.state.waiting", defaultValue: "Aguardando"),
                    badgeColor: isDestinationResponding ? NLColor.scoreExcellent : NLColor.textSecondary,
                    isActive: isDestinationResponding
                )

                connectorLine(isActive: !isPhaseRest)

                // Nó 4: Sob carga
                nodeRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: String(localized: "live_trail.node.under_load", defaultValue: "Sob carga"),
                    badge: isPhaseRest
                        ? String(localized: "live_trail.state.waiting", defaultValue: "Aguardando")
                        : String(localized: "live_trail.state.active", defaultValue: "Ativo"),
                    badgeColor: isPhaseRest ? NLColor.textTertiary : NLColor.accentPrimary,
                    isActive: !isPhaseRest
                )

                connectorLine(isActive: isDestinationResponding)

                // Nó 5: Região de referência (nome amigável do catálogo)
                nodeRow(
                    icon: "mappin.and.ellipse",
                    title: destinationName,
                    badge: isDestinationResponding
                        ? String(localized: "live_trail.state.responding", defaultValue: "Respondendo")
                        : String(localized: "live_trail.state.connecting", defaultValue: "Conectando"),
                    badgeColor: isDestinationResponding ? NLColor.scoreExcellent : NLColor.textSecondary,
                    isActive: isDestinationResponding
                )
            }
            .padding(NLSpacing.cardPadding)
            .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(NLColor.borderSubtle, lineWidth: 0.5)
            }
        }
    }

    private func nodeRow(
        icon: String,
        title: String,
        badge: String,
        badgeColor: Color,
        isActive: Bool
    ) -> some View {
        HStack(spacing: NLSpacing.sm) {
            ZStack {
                Circle()
                    .fill(isActive ? badgeColor.opacity(0.15) : NLColor.backgroundOverlay)
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isActive ? badgeColor : NLColor.textSecondary)
            }

            Text(title)
                .font(NLTypography.callout.weight(.medium))
                .foregroundStyle(NLColor.textPrimary)

            Spacer()

            Text(badge)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(badgeColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(badgeColor.opacity(0.12), in: Capsule())
        }
    }

    private func connectorLine(isActive: Bool) -> some View {
        HStack {
            Rectangle()
                .fill(isActive ? NLColor.accentPrimary.opacity(0.6) : NLColor.borderSubtle)
                .frame(width: 2, height: 16)
                .padding(.leading, 17) // Alinhado ao centro do círculo de 36pt (18 - 1)
            Spacer()
        }
    }
}
