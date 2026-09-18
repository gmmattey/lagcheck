import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain
import NolaggyInfrastructure

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
    @State private var platformHealth: PlatformHealth? = nil
    private let healthClient = DirectPlatformHealthClient()

    private var supportedPlatforms: [Platform] {
        let allowed = RemoteCatalogVerifier.allowedPlatforms(for: game.id)
        let order: [Platform] = [.iphone, .playstation, .xbox, .nintendo, .pc]
        return order.filter { allowed.contains($0) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: NLSpacing.lg) {
                GameDetailScoreHeader(scoreState: scoreState)

                if supportedPlatforms.count > 1 {
                    PlatformSelectorRow(supportedPlatforms: supportedPlatforms, selectedPlatform: $selectedPlatform)
                }

                if let health = platformHealth, health.isIssueReported {
                    PlatformHealthBannerView(health: health)
                }

                GameDetailMeasurementScope(platform: selectedPlatform)
                GameDetailVerdictCard(
                    presentation: GameDetailPresentation(scoreState: scoreState, gameName: game.name)
                )
                if let metrics = observedMetrics {
                    GameDetailMetricsCard(metrics: metrics)
                }
                if let advice = wifiBandDiagnostic {
                    NetworkBandAdviceBanner(
                        title: LocalizedStringKey(advice.titleKey),
                        message: LocalizedStringKey(advice.messageKey),
                        badgeText: advice.diagnostic.isSuspectOrConfirmed24GHz ? "2.4 GHz" : nil,
                        style: advice.diagnostic.isSuspectOrConfirmed24GHz ? .warning : .positive,
                        iconName: advice.diagnostic.isSuspectOrConfirmed24GHz ? "antenna.radiowaves.left.and.right" : "wifi",
                        actionTitle: advice.actionKey.map { LocalizedStringKey($0) },
                        onAction: onStartDeepCheck
                    )
                }
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
        }
        .background(NolaggyScreenBackground())
        .navigationTitle(game.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NolaggyBackButton(action: { dismiss() }, accessibilityIdentifier: "game-detail-back")
            }
        }
        .preferredColorScheme(.dark)
        .task(id: selectedPlatform) {
            if selectedPlatform == .playstation || selectedPlatform == .xbox || selectedPlatform == .nintendo {
                let health = await healthClient.checkHealth(for: selectedPlatform, market: "BR")
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.platformHealth = health
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.platformHealth = nil
                }
            }
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

    private var wifiBandDiagnostic: WiFiBandDiagnosticResult? {
        guard let metrics = observedMetrics else { return nil }
        let telemetry = WiFiLocalTelemetry(
            gatewayRTTMedianMs: metrics.p50Milliseconds,
            gatewayJitterMs: metrics.jitterMilliseconds,
            tailRatioP95P50: metrics.p95ToP50Ratio,
            validSampleCount: metrics.validResponseCount,
            plannedSampleCount: metrics.validResponseCount,
            isWiFi: true
        )
        let result = WiFiBandEvaluator.evaluate(telemetry: telemetry)
        return result.diagnostic.isSuspectOrConfirmed24GHz ? result : nil
    }
}
