import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Tela de Detalhes do Jogo (Decisão 22).
/// Apresenta o Score contextual do jogo, seletor de plataforma (iPhone, Console, PC),
/// diagnóstico da rota de internet e acionamento de Deep Check.
struct GameDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let game: CatalogMeasurementJourney.Game
    let scoreState: GameRowView.ScoreState
    let evaluation: MeasurementEvaluation?
    let resolvedContext: ResolvedMeasurementContext?
    let onStartDeepCheck: () -> Void

    @State private var selectedPlatform: Platform = .iphone
    @State private var equipmentConnection: NetworkKind = .wifi

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: NLSpacing.lg) {
                // Header com Score
                scoreHeader

                // Seletor de Plataforma
                platformPicker

                // Se Console ou PC, seletor de conexão (Wi-Fi vs Cabo)
                if selectedPlatform != .iphone {
                    connectionPicker
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Veredito e Explicação Contextualizada
                verdictCard

                // Métricas Observadas
                if let metrics = observedMetrics {
                    metricsCard(metrics)
                }

                Spacer(minLength: NLSpacing.md)

                // Botão para Deep Check
                VStack(spacing: NLSpacing.sm) {
                    PrimaryButton(
                        title: "deep_check.intro.start",
                        accessibilityIdentifier: "start-game-deep-check",
                        action: onStartDeepCheck
                    )
                    Text("deep_check.intro.wifi")
                        .font(NLTypography.footnote)
                        .foregroundStyle(NLColor.textTertiary)
                }
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .padding(.vertical, NLSpacing.lg)
            .animation(.easeInOut(duration: 0.2), value: selectedPlatform)
            .animation(.easeInOut(duration: 0.2), value: equipmentConnection)
        }
        .background(NolaggyScreenBackground())
        .navigationTitle(game.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    private var scoreHeader: some View {
        VStack(spacing: NLSpacing.sm) {
            switch scoreState {
            case let .evaluated(score, classification):
                NolaggyScore(
                    outcome: .revealed(score: score, classification: classification),
                    style: .standard,
                    showsGlow: false
                )
            case .measuring:
                ProgressView()
                    .scaleEffect(1.4)
                    .padding(.vertical, NLSpacing.xl)
                Text("quick_check.measuring.progress")
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(NLColor.textSecondary)
            case .inconclusive, .failed:
                NolaggyScore(
                    outcome: .inconclusive,
                    style: .standard,
                    showsGlow: false
                )
            }
        }
    }

    private var platformPicker: some View {
        VStack(alignment: .leading, spacing: NLSpacing.xs) {
            Text("PLATAFORMA")
                .font(NLTypography.captionStrong)
                .foregroundStyle(NLColor.textTertiary)

            Picker("Plataforma", selection: $selectedPlatform) {
                Text("iPhone").tag(Platform.iphone)
                Text("PlayStation").tag(Platform.playstation)
                Text("Xbox").tag(Platform.xbox)
                Text("PC").tag(Platform.pc)
                Text("Nintendo").tag(Platform.nintendo)
            }
            .pickerStyle(.segmented)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var connectionPicker: some View {
        VStack(alignment: .leading, spacing: NLSpacing.xs) {
            Text("CONEXÃO DO EQUIPAMENTO")
                .font(NLTypography.captionStrong)
                .foregroundStyle(NLColor.textTertiary)

            Picker("Conexão", selection: $equipmentConnection) {
                Label("Wi-Fi", systemImage: "wifi").tag(NetworkKind.wifi)
                Label("Cabo (Ethernet)", systemImage: "cable.connector").tag(NetworkKind.other)
            }
            .pickerStyle(.segmented)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var verdictCard: some View {
        VStack(alignment: .leading, spacing: NLSpacing.xs) {
            Text(verdictTitle)
                .font(NLTypography.bodyEmphasis)
                .foregroundStyle(NLColor.textPrimary)

            Text(verdictDescription)
                .font(NLTypography.callout)
                .foregroundStyle(NLColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
    }

    private func metricsCard(_ metrics: QualityMetrics) -> some View {
        VStack(spacing: 1) {
            MetricRow(
                label: "quick_check.result.latency",
                value: milliseconds(metrics.p50Milliseconds),
                unit: "ms"
            )
            MetricRow(
                label: "quick_check.result.jitter",
                value: milliseconds(metrics.jitterMilliseconds),
                unit: "ms"
            )
            MetricRow(
                label: "quick_check.result.loss",
                value: "\(Int(metrics.packetLossPercentage.rounded()))",
                unit: "%"
            )
        }
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
    }

    private var verdictTitle: LocalizedStringKey {
        switch scoreState {
        case let .evaluated(_, classification):
            switch classification {
            case .excellent: "Conexão excelente"
            case .great: "Boa conexão para jogar"
            case .unstable: "Oscilação detectada"
            case .lagRisk: "Risco de travamento ou lag"
            }
        case .measuring:
            "Avaliando estabilidade..."
        case .inconclusive, .failed:
            "Medição inconclusiva"
        }
    }

    private var verdictDescription: LocalizedStringKey {
        switch scoreState {
        case let .evaluated(_, classification):
            if selectedPlatform == .iphone {
                switch classification {
                case .excellent, .great:
                    return "Sua conexão atende aos requisitos de responsividade e estabilidade esperados para \(game.name) no iPhone."
                case .unstable:
                    return "A latência média é aceitável, mas oscilações na rede sem fio podem causar pequenos atrasos durante a partida."
                case .lagRisk:
                    return "Perda de pacotes ou latência elevada podem comprometer a jogabilidade de \(game.name) agora."
                }
            } else {
                let platformName = platformDisplayName(selectedPlatform)
                if equipmentConnection == .other {
                    // Cabo Ethernet
                    switch classification {
                    case .excellent, .great:
                        return "A rota da sua internet até o servidor está ótima. Como seu \(platformName) usa cabo de rede, a partida terá ainda mais estabilidade e menos oscilação do que o medido pelo Wi-Fi."
                    case .unstable:
                        return "Detectamos oscilação na rota da sua operadora. Mesmo usando cabo no seu \(platformName), partidas competitivas podem apresentar pequenos picos."
                    case .lagRisk:
                        return "A rota de internet da sua operadora está com instabilidade ou perda de pacotes hoje. O cabo de rede no \(platformName) reduz o jitter local, mas não resolve o problema na rota externa."
                    }
                } else {
                    // Wi-Fi
                    switch classification {
                    case .excellent, .great:
                        return "A rota da sua internet é excelente para seu \(platformName). Por estar no Wi-Fi, certifique-se de que o videogame esteja próximo ao roteador para evitar interferências."
                    case .unstable:
                        return "Oscilação detectada na rede. Em consoles ou PC no Wi-Fi, recomendamos usar um cabo de rede para evitar perda de pacotes durante a partida."
                    case .lagRisk:
                        return "Instabilidade significativa na rota para \(game.name). Evite partidas ranqueadas no seu \(platformName) no momento."
                    }
                }
            }
        case .measuring:
            return "Estamos medindo a rota da sua rede. O resultado será exibido em instantes."
        case .inconclusive, .failed:
            return "Não foi possível obter respostas suficientes da rota de rede para calcular uma nota confiável."
        }
    }

    private func platformDisplayName(_ platform: Platform) -> String {
        switch platform {
        case .iphone: "iPhone"
        case .playstation: "PlayStation"
        case .xbox: "Xbox"
        case .pc: "PC"
        case .nintendo: "Nintendo"
        }
    }

    private var observedMetrics: QualityMetrics? {
        guard let evaluation else { return nil }
        switch evaluation {
        case let .completed(result):
            return result.metrics
        case let .inconclusive(_, diagnostics):
            return diagnostics
        }
    }

    private func milliseconds(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(Int(value.rounded()))
    }
}
