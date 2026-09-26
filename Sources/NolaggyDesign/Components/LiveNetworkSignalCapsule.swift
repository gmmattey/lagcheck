import SwiftUI

/// Estado da telemetria de rede local ao vivo exibida na Home (Decisão 54).
public struct LiveNetworkSignal: Equatable, Sendable {
    public enum ConnectionKind: Equatable, Sendable {
        case wifi(band: WiFiBand, gatewayRTTMs: Double?)
        case cellular(technology: String)
        case offline
    }

    public enum WiFiBand: Equatable, Sendable {
        case fiveGHz
        case twoPointFourGHz
        case standard
    }

    public let connection: ConnectionKind
    public let regionalRouteName: String
    public let isRegionalRouteOperational: Bool

    public init(
        connection: ConnectionKind = .wifi(band: .fiveGHz, gatewayRTTMs: 2.0),
        regionalRouteName: String = "São Paulo",
        isRegionalRouteOperational: Bool = true
    ) {
        self.connection = connection
        self.regionalRouteName = regionalRouteName
        self.isRegionalRouteOperational = isRegionalRouteOperational
    }
}

/// Pílula compacta de telemetria de rede local ao vivo inspirada no NoPing (Decisão 54).
/// Exibe a saúde do primeiro salto (Wi-Fi 5 GHz / 2.4 GHz e RTT do Gateway)
/// e a conectividade com a rota regional sem drenar bateria ou consumir dados móveis.
public struct LiveNetworkSignalCapsule: View {
    let signal: LiveNetworkSignal
    let onTap: (() -> Void)?

    public init(signal: LiveNetworkSignal, onTap: (() -> Void)? = nil) {
        self.signal = signal
        self.onTap = onTap
    }

    public var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) {
                    content
                }
                .buttonStyle(.plain)
            } else {
                content
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityIdentifier("live-network-signal-capsule")
    }

    private var content: some View {
        HStack(spacing: NLSpacing.xs) {
            // Dot pulsante semântico
            Circle()
                .fill(dotColor)
                .frame(width: 7, height: 7)
                .shadow(color: dotColor.opacity(0.6), radius: 3, x: 0, y: 0)

            // Descrição da interface e primeiro salto
            Text(connectionDescription)
                .font(NLTypography.captionStrong)
                .foregroundStyle(NLColor.textPrimary)

            // Separador sutil
            Text("·")
                .font(NLTypography.caption)
                .foregroundStyle(NLColor.textTertiary)

            // Status da rota regional
            HStack(spacing: 3) {
                Text(signal.regionalRouteName)
                Text(signal.isRegionalRouteOperational ? "Operacional" : "Instável")
            }
            .font(NLTypography.caption)
            .foregroundStyle(NLColor.textSecondary)

            Spacer(minLength: 0)

            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(NLColor.textTertiary)
            }
        }
        .padding(.horizontal, NLSpacing.sm)
        .frame(height: 32)
        .background(NLColor.surface, in: Capsule())
        .overlay(
            Capsule()
                .stroke(NLColor.borderHairline, lineWidth: 1)
        )
    }

    private var dotColor: Color {
        switch signal.connection {
        case .wifi(let band, _):
            switch band {
            case .fiveGHz, .standard:
                return NLColor.scoreExcellent
            case .twoPointFourGHz:
                return NLColor.scoreUnstable
            }
        case .cellular:
            return NLColor.scoreExcellent
        case .offline:
            return NLColor.coralSolarRed
        }
    }

    private var connectionDescription: String {
        switch signal.connection {
        case .wifi(let band, let gatewayRTT):
            let bandLabel: String
            switch band {
            case .fiveGHz: bandLabel = "Wi-Fi 5 GHz"
            case .twoPointFourGHz: bandLabel = "Wi-Fi 2.4 GHz"
            case .standard: bandLabel = "Wi-Fi"
            }
            if let gatewayRTT {
                return "\(bandLabel) · \(Int(round(gatewayRTT))) ms"
            } else {
                return bandLabel
            }
        case .cellular(let tech):
            return "Rede Móvel (\(tech))"
        case .offline:
            return "Sem Conexão"
        }
    }

    private var accessibilityDescription: String {
        "Status de conexão: \(connectionDescription), rota regional \(signal.regionalRouteName) \(signal.isRegionalRouteOperational ? "operacional" : "instável")"
    }
}

#Preview("LiveNetworkSignalCapsule - Wi-Fi 5GHz") {
    VStack(spacing: 12) {
        LiveNetworkSignalCapsule(signal: LiveNetworkSignal(
            connection: .wifi(band: .fiveGHz, gatewayRTTMs: 2.0),
            regionalRouteName: "São Paulo",
            isRegionalRouteOperational: true
        ))
        LiveNetworkSignalCapsule(signal: LiveNetworkSignal(
            connection: .wifi(band: .twoPointFourGHz, gatewayRTTMs: 14.0),
            regionalRouteName: "São Paulo",
            isRegionalRouteOperational: true
        ))
        LiveNetworkSignalCapsule(signal: LiveNetworkSignal(
            connection: .cellular(technology: "5G"),
            regionalRouteName: "São Paulo",
            isRegionalRouteOperational: true
        ))
    }
    .padding()
    .background(NLColor.deep)
    .preferredColorScheme(.dark)
}
