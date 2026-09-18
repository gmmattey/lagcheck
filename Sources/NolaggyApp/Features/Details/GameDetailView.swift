import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Tela de Detalhes do Jogo (Decisão 22).
/// Apresenta o Score contextual do jogo, seletor de plataforma (iPhone, Console, PC),
/// diagnóstico da rota de internet e acionamento de Deep Check.
struct GameDetailView: View {
    let game: CatalogMeasurementJourney.Game
    let scoreState: GameRowView.ScoreState
    let evaluation: MeasurementEvaluation?
    let resolvedContext: ResolvedMeasurementContext?
    let onStartDeepCheck: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: NLSpacing.lg) {
                GameDetailScoreHeader(scoreState: scoreState)
                GameDetailMeasurementScope()
                GameDetailVerdictCard(
                    presentation: GameDetailPresentation(scoreState: scoreState, gameName: game.name)
                )
                if let metrics = observedMetrics {
                    GameDetailMetricsCard(metrics: metrics)
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

}
