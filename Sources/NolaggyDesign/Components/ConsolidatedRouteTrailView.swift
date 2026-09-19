import SwiftUI

/// Componente visual canônico da Trilha Consolidada HIG do LagCheck (Decisão 35/36).
/// Apresenta o atestado da rota em 5 nós verticais conectados, reutilizando o layout
/// da tela de execução, sem pulsos, sem animações contínuas e sem números/ruídos técnicos.
public struct ConsolidatedRouteTrailView: View {
    public enum NodeState: Sendable {
        case check
        case attention
        case neutral
    }

    private let isWiFi: Bool
    private let regionName: String
    private let networkState: NodeState
    private let responseState: NodeState
    private let deliveryState: NodeState
    private let loadState: NodeState
    private let regionState: NodeState

    public init(
        isWiFi: Bool,
        regionName: String,
        networkState: NodeState = .check,
        responseState: NodeState = .check,
        deliveryState: NodeState = .check,
        loadState: NodeState = .check,
        regionState: NodeState = .check
    ) {
        self.isWiFi = isWiFi
        self.regionName = regionName
        self.networkState = networkState
        self.responseState = responseState
        self.deliveryState = deliveryState
        self.loadState = loadState
        self.regionState = regionState
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Nó 1: Wi-Fi ou Rede móvel
            nodeRow(
                icon: isWiFi ? "wifi" : "antenna.radiowaves.left.and.right",
                title: isWiFi
                    ? String(localized: "check_completo.trail.wifi", defaultValue: "Wi‑Fi")
                    : String(localized: "check_completo.trail.cellular", defaultValue: "Rede móvel"),
                state: networkState
            )

            connectorLine()

            // Nó 2: Resposta
            nodeRow(
                icon: "speedometer",
                title: String(localized: "check_completo.trail.response", defaultValue: "Resposta"),
                state: responseState
            )

            connectorLine()

            // Nó 3: Entrega
            nodeRow(
                icon: "shield.lefthalf.filled",
                title: String(localized: "check_completo.trail.delivery", defaultValue: "Entrega"),
                state: deliveryState
            )

            connectorLine()

            // Nó 4: Carga
            nodeRow(
                icon: "arrow.triangle.2.circlepath",
                title: String(localized: "check_completo.trail.load", defaultValue: "Carga"),
                state: loadState
            )

            connectorLine()

            // Nó 5: Região de referência (ex: São Paulo)
            nodeRow(
                icon: "mappin.and.ellipse",
                title: regionName,
                state: regionState
            )
        }
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(NLColor.borderSubtle, lineWidth: 0.5)
        }
    }

    private func nodeRow(icon: String, title: String, state: NodeState) -> some View {
        HStack(spacing: NLSpacing.sm) {
            ZStack {
                Circle()
                    .fill(nodeIconBackground(for: state))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(nodeIconForeground(for: state))
            }

            Text(title)
                .font(NLTypography.callout.weight(.medium))
                .foregroundStyle(NLColor.textPrimary)

            Spacer()

            stateBadge(for: state)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibleLabel(for: title, state: state))
    }

    private func connectorLine() -> some View {
        HStack {
            Rectangle()
                .fill(NLColor.borderSubtle)
                .frame(width: 2, height: 16)
                .padding(.leading, 17) // Alinhado ao centro do círculo de 36pt (18 - 1)
            Spacer()
        }
    }

    @ViewBuilder
    private func stateBadge(for state: NodeState) -> some View {
        switch state {
        case .check:
            HStack(spacing: 3) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(NLColor.scoreExcellent)
            .frame(width: 26, height: 26)
            .background(NLColor.scoreExcellent.opacity(0.12), in: Circle())
            .overlay { Circle().stroke(NLColor.scoreExcellent.opacity(0.3), lineWidth: 0.5) }

        case .attention:
            HStack(spacing: 3) {
                Image(systemName: "exclamationmark")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(NLColor.coralSolarRed)
            .frame(width: 26, height: 26)
            .background(NLColor.coralSolarRed.opacity(0.12), in: Circle())
            .overlay { Circle().stroke(NLColor.coralSolarRed.opacity(0.3), lineWidth: 0.5) }

        case .neutral:
            HStack(spacing: 3) {
                Text("—")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(NLColor.textTertiary)
            .frame(width: 26, height: 26)
            .background(NLColor.backgroundOverlay, in: Circle())
            .overlay { Circle().stroke(NLColor.borderSubtle, lineWidth: 0.5) }
        }
    }

    private func nodeIconBackground(for state: NodeState) -> Color {
        switch state {
        case .check:
            return NLColor.scoreExcellent.opacity(0.12)
        case .attention:
            return NLColor.coralSolarRed.opacity(0.12)
        case .neutral:
            return NLColor.backgroundOverlay
        }
    }

    private func nodeIconForeground(for state: NodeState) -> Color {
        switch state {
        case .check:
            return NLColor.scoreExcellent
        case .attention:
            return NLColor.coralSolarRed
        case .neutral:
            return NLColor.textSecondary
        }
    }

    private func accessibleLabel(for title: String, state: NodeState) -> String {
        let stateText: String
        switch state {
        case .check:
            stateText = String(localized: "check_completo.trail.state.check", defaultValue: "Verificado")
        case .attention:
            stateText = String(localized: "check_completo.trail.state.attention", defaultValue: "Atenção observada")
        case .neutral:
            stateText = String(localized: "check_completo.trail.state.neutral", defaultValue: "Não avaliado")
        }
        let format = String(localized: "check_completo.trail.a11y.node %@ %@", defaultValue: "%@: %@")
        return String(format: format, title, stateText)
    }
}
