import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain
import NolaggyInfrastructure

/// Ficha do jogo focado no Check direto a partir do iPhone (Decisão 147).
struct GameDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let game: CatalogMeasurementJourney.Game
    let scoreState: GameRowView.ScoreState
    let evaluation: MeasurementEvaluation?
    let resolvedContext: ResolvedMeasurementContext?
    var gameHistory: [MeasurementHistoryEntry] = []
    let onStartDeepCheck: () -> Void
    let onOpenHistory: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // A arte contextualiza o título sem disputar atenção com a decisão.
                GameDetailCinemaHeroBanner(game: game)

                VStack(alignment: .leading, spacing: NLSpacing.lg) {
                    GameDetailMeasurementScope(
                        platform: .iphone,
                        externalLink: nil
                    )

                    PrimaryButton(
                        title: "home.cta.start_lagcheck",
                        icon: Image(systemName: "play.fill"),
                        accessibilityIdentifier: "start-game-deep-check",
                        action: startDeepCheck
                    )
                    .accessibilityHint(Text("game_detail.context.start_hint"))

                    supplementaryInformation
                }
                .padding(.horizontal, NLSpacing.screenMarginHorizontal)
                .padding(.top, NLSpacing.sm)
                .padding(.bottom, NLSpacing.xxl)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(NLColor.deep.ignoresSafeArea())
        .tint(.white)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .preferredColorScheme(.dark)
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
        guard resolvedContext?.observedPhoneNetwork == .wifi, let metrics = observedMetrics else { return nil }
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

    /// Histórico e observações verificáveis não disputam a decisão de medir.
    /// Dados editoriais de terceiros ficam fora desta versão até serem auditados.
    @ViewBuilder
    private var supplementaryInformation: some View {
        if !gameHistory.isEmpty || wifiBandDiagnostic != nil {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: NLSpacing.lg) {
                    if !gameHistory.isEmpty {
                        GameDetailExclusiveHistoryCard(
                            entries: gameHistory,
                            onOpenHistory: onOpenHistory
                        )
                    }

                    if wifiBandDiagnostic != nil {
                        GameDetailNetworkInformationAccordion(
                            platformHealth: nil,
                            wifiBandDiagnostic: wifiBandDiagnostic,
                            onStartDeepCheck: { startDeepCheck() }
                        )
                    }
                }
                .padding(.top, NLSpacing.sm)
            } label: {
                Label("game_detail.more_information", systemImage: "info.circle")
                    .font(NLTypography.bodyEmphasis)
                    .foregroundStyle(NLColor.textPrimary)
            }
            .tint(NLColor.textSecondary)
            .accessibilityIdentifier("game-detail-more-information")
        }
    }

    private func startDeepCheck() {
        onStartDeepCheck()
    }
}
