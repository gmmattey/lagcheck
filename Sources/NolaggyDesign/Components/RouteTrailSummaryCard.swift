import SwiftUI

/// Card de síntese e atestado dos 3 nós da rota no encerramento da medição.
/// Padrão HIG da Apple com curvatura contínua, selos de validação ótica e hierarquia clara.
public struct RouteTrailSummaryCard: View {
    private let isWiFi: Bool
    private let wifiStatusText: String
    private let isLocalHealthy: Bool
    private let destinationName: String
    private let destinationStatusText: String
    private let isDestinationHealthy: Bool

    public init(
        isWiFi: Bool = true,
        wifiStatusText: String,
        isLocalHealthy: Bool = true,
        destinationName: String,
        destinationStatusText: String,
        isDestinationHealthy: Bool = true
    ) {
        self.isWiFi = isWiFi
        self.wifiStatusText = wifiStatusText
        self.isLocalHealthy = isLocalHealthy
        self.destinationName = destinationName
        self.destinationStatusText = destinationStatusText
        self.isDestinationHealthy = isDestinationHealthy
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.xs) {
            Text(String(localized: "result.route_trail.title", defaultValue: "Atestado da Rota"))
                .font(NLTypography.caption)
                .foregroundStyle(NLColor.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.leading, NLSpacing.xxs)

            VStack(spacing: 0) {
                // Nó 1: iPhone
                summaryNode(
                    icon: "iphone",
                    title: String(localized: "live_trail.node.device", defaultValue: "Seu iPhone"),
                    detail: String(localized: "live_trail.badge.origin", defaultValue: "Dispositivo de teste"),
                    isHealthy: true,
                    statusBadge: "100%"
                )

                // Conector 1
                connector(isHealthy: isLocalHealthy)

                // Nó 2: Wi-Fi / Rede Móvel
                summaryNode(
                    icon: isWiFi ? "wifi" : "antenna.radiowaves.left.and.right",
                    title: isWiFi ? String(localized: "live_trail.node.router", defaultValue: "Wi-Fi local") : String(localized: "live_trail.node.cellular", defaultValue: "Rede móvel"),
                    detail: wifiStatusText,
                    isHealthy: isLocalHealthy,
                    statusBadge: isLocalHealthy ? "OK" : "Atenção"
                )

                // Conector 2
                connector(isHealthy: isDestinationHealthy)

                // Nó 3: Servidor / Região Gamer
                summaryNode(
                    icon: "server.rack",
                    title: destinationName,
                    detail: destinationStatusText,
                    isHealthy: isDestinationHealthy,
                    statusBadge: isDestinationHealthy ? "OK" : "Lento"
                )
            }
            .padding(NLSpacing.cardPadding)
            .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(NLColor.borderSubtle, lineWidth: 0.5)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private func summaryNode(icon: String, title: String, detail: String, isHealthy: Bool, statusBadge: String) -> some View {
        HStack(spacing: NLSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(NLColor.backgroundOverlay)
                    .frame(width: 36, height: 36)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isHealthy ? NLColor.scoreExcellent.opacity(0.4) : NLColor.coralSolarRed.opacity(0.4), lineWidth: 1.0)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isHealthy ? NLColor.textPrimary : NLColor.coralSolarRed)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(NLTypography.subheadline)
                    .foregroundStyle(NLColor.textPrimary)
                Text(detail)
                    .font(NLTypography.caption)
                    .foregroundStyle(isHealthy ? NLColor.textSecondary : NLColor.coralSolarRed)
            }

            Spacer()

            HStack(spacing: NLSpacing.xxs) {
                Image(systemName: isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isHealthy ? NLColor.scoreExcellent : NLColor.coralSolarRed)
                Text(statusBadge)
                    .font(NLTypography.caption)
                    .foregroundStyle(isHealthy ? NLColor.scoreExcellent : NLColor.coralSolarRed)
            }
            .padding(.horizontal, NLSpacing.xs)
            .padding(.vertical, NLSpacing.xxs)
            .background((isHealthy ? NLColor.scoreExcellent : NLColor.coralSolarRed).opacity(0.12), in: Capsule())
        }
    }

    private func connector(isHealthy: Bool) -> some View {
        HStack(spacing: NLSpacing.sm) {
            Rectangle()
                .fill(isHealthy ? NLColor.scoreExcellent.opacity(0.4) : NLColor.coralSolarRed.opacity(0.4))
                .frame(width: 2, height: 16)
                .frame(width: 36)
            Spacer()
        }
    }

    private var accessibilityDescription: String {
        "Atestado da rota: iPhone verificado. \(isWiFi ? "Wi-Fi" : "Rede móvel"): \(wifiStatusText). Destino \(destinationName): \(destinationStatusText)."
    }
}
