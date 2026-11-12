import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Avaliação de score focada por jogo individual (Nova Jornada).
/// As medições pertencem exclusivamente a cada jogo testado e não são generalizadas.
extension QuickCheckFeatureView {
    func scoreState(for game: CatalogMeasurementJourney.Game) -> GameRowView.ScoreState {
        if let entry = history.first(where: { $0.resolvedContext.context.gameID == game.id }),
           let result = entry.result {
            let classification: NLScoreClassification
            switch result.resultClass {
            case .excellent: classification = .excellent
            case .great: classification = .great
            case .unstable: classification = .unstable
            case .lagRisk: classification = .lagRisk
            }
            return .evaluated(score: result.finalScore, classification: classification)
        }
        return .inconclusive
    }

    /// Mantido para compatibilidade sem disparar testes em massa automáticos.
    func startBackgroundQuickCheck() {}
}
