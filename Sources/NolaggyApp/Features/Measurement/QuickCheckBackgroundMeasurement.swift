import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Reavalia a mesma série UDP contra cada perfil publicado. A avaliação segue
/// no domínio; esta extensão apenas atualiza o estado de apresentação.
extension QuickCheckFeatureView {
    func scoreState(for game: CatalogMeasurementJourney.Game) -> GameRowView.ScoreState {
        if isBackgroundMeasuring && evaluatedScores[game.id] == nil { return .measuring }
        if let evaluation = evaluatedScores[game.id] {
            switch evaluation {
            case let .completed(result):
                let classification: NLScoreClassification
                switch result.resultClass {
                case .excellent: classification = .excellent
                case .great: classification = .great
                case .unstable: classification = .unstable
                case .lagRisk: classification = .lagRisk
                }
                return .evaluated(score: result.finalScore, classification: classification)
            case .inconclusive: return .inconclusive
            }
        }
        return backgroundMeasurementFailed ? .failed : .measuring
    }

    func startBackgroundQuickCheck() {
        guard !isBackgroundMeasuring, let remoteCatalog, let firstGame = availableGames.first else { return }
        isBackgroundMeasuring = true
        backgroundMeasurementFailed = false
        Task { @MainActor in
            guard let snapshot = try? CatalogMeasurementJourney.regionalSnapshot(for: firstGame.context, in: remoteCatalog) else {
                failBackgroundMeasurement(); return
            }
            let decision: RegionalSelectionDecision
            do {
                decision = try await coordinator.selectRegionalCandidate(
                    snapshot: snapshot,
                    using: RegionalPreReadCoordinator(collector: MeasurementTransportFactory.regionalPreReadCollector()),
                    manualRegionID: await regionalPreferenceRepository.manualRegionID()
                )
            } catch { failBackgroundMeasurement(); return }
            guard case let .selected(selection) = decision else { failBackgroundMeasurement(); return }
            do {
                _ = try await coordinator.startQuickCheck(
                    resolvedContext: selection.selected.resolvedContext,
                    plan: MeasurementTransportFactory.quickCheckPlan(for: selection.selected.resolvedContext)
                )
                await awaitBackgroundMeasurementCompletion()
            } catch { failBackgroundMeasurement() }
        }
    }

    private func awaitBackgroundMeasurementCompletion() async {
        while true {
            switch await coordinator.sessionState() {
            case let .completed(_, _, entry):
                evaluateAllGames(with: await coordinator.completedProbeSamples())
                if let entry { completedEntry = entry; await loadHistory() }
                isBackgroundMeasuring = false
                return
            case .cancelled:
                failBackgroundMeasurement()
                return
            case .measuring, .idle:
                try? await Task.sleep(for: .milliseconds(150))
            }
        }
    }

    private func failBackgroundMeasurement() {
        isBackgroundMeasuring = false
        backgroundMeasurementFailed = true
    }

    func evaluateAllGames(with samples: [ProbeSample]) {
        evaluatedScores = Dictionary(uniqueKeysWithValues: availableGames.map {
            ($0.id, QualityEvaluator.evaluate(samples: samples, profile: $0.profileID))
        })
    }
}
