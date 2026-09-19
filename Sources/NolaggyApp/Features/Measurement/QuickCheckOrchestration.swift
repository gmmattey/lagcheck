import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Ciclo de vida e navegação da sessão. Mantido fora da casca de tabs para que
/// `QuickCheckFeatureView` fique responsável somente por compor a jornada.
extension QuickCheckFeatureView {
    func retest(_ entry: MeasurementHistoryEntry) {
        guard availableGames.contains(where: { $0.id == entry.resolvedContext.context.gameID }) else { return }
        selectedGameID = entry.resolvedContext.context.gameID
        selectedRegionalContext = entry.resolvedContext
        start()
    }

    func start() {
        guard let remoteCatalog, let context else { return }
        regionalPresentation = .confirming
        showingRegionalSelection = true
        Task { @MainActor in
            await Task.yield()
            let manualRegionID = await regionalPreferenceRepository.manualRegionID()
            guard let snapshot = try? CatalogMeasurementJourney.regionalSnapshot(for: context, in: remoteCatalog, manualRegionID: manualRegionID) else { return }
            await performRegionalPreRead(snapshot: snapshot, manualRegionID: manualRegionID)
        }
    }

    func performRegionalPreRead(snapshot: RegionalSelectionSnapshot, manualRegionID: String? = nil) async {
        let decision: RegionalSelectionDecision
        do {
            decision = try await coordinator.selectRegionalCandidate(
                snapshot: snapshot,
                using: RegionalPreReadCoordinator(collector: MeasurementTransportFactory.regionalPreReadCollector()),
                manualRegionID: manualRegionID
            )
        } catch RegionalSelectionError.manualCandidateNotAllowed where manualRegionID != nil {
            await performRegionalPreRead(snapshot: snapshot, manualRegionID: nil)
            return
        } catch { return }

        switch decision {
        case let .selected(selection): startQuickCheck(resolvedContext: selection.selected.resolvedContext)
        case .inconclusive: regionalPresentation = .noViableCandidate
        }
    }

    func retryRegionalPreRead() {
        guard let remoteCatalog, let context else { return }
        regionalPresentation = .confirming
        Task { @MainActor in
            let manualRegionID = await regionalPreferenceRepository.manualRegionID()
            guard let snapshot = try? CatalogMeasurementJourney.regionalSnapshot(for: context, in: remoteCatalog, manualRegionID: manualRegionID) else { return }
            await performRegionalPreRead(snapshot: snapshot, manualRegionID: manualRegionID)
        }
    }

    func cancelRegionalSelection() {
        Task { @MainActor in
            await coordinator.cancelRegionalPreRead()
            deepCheckDestination = nil
            showingRegionalSelection = false
        }
    }

    func startQuickCheck(resolvedContext: ResolvedMeasurementContext) {
        Task { @MainActor in
            selectedRegionalContext = resolvedContext
            deepCheckDestination = nil
            showingRegionalSelection = false
            do {
                _ = try await coordinator.startQuickCheck(resolvedContext: resolvedContext, plan: MeasurementTransportFactory.quickCheckPlan(for: resolvedContext))
                presentation = .measuring
                await awaitTerminalState()
            } catch { return }
        }
    }

    func restart() {
        completedEntry = nil
        partialSamples = []
        selectedRegionalContext = nil
        presentation = .context
    }

    func openDeepCheck(resolvedContext: ResolvedMeasurementContext? = nil, platform: Platform? = nil) {
        guard let baseContext = resolvedContext ?? selectedRegionalContext ?? completedEntry?.resolvedContext else {
            return
        }
        let context: ResolvedMeasurementContext
        if let platform, platform != baseContext.context.platform {
            let updatedGameContext = GameContext(
                gameID: baseContext.context.gameID,
                market: baseContext.context.market,
                platform: platform,
                equipmentConnection: baseContext.context.equipmentConnection
            )
            context = ResolvedMeasurementContext(
                context: updatedGameContext,
                catalogVersion: baseContext.catalogVersion,
                profileID: baseContext.profileID,
                profileRuleVersion: baseContext.profileRuleVersion,
                regionID: baseContext.regionID,
                destination: baseContext.destination,
                strategy: baseContext.strategy,
                confidence: baseContext.confidence,
                precisionKey: baseContext.precisionKey
            )
        } else {
            context = baseContext
        }
        selectedRegionalContext = context
        deepCheckDestination = DeepCheckDestination(
            resolvedContext: context,
            gameName: gameName(forGameID: context.context.gameID)
        )
    }

    func back() {
        Task { @MainActor in
            if let session = await coordinator.currentSession() {
                await coordinator.cancel(id: session.id)
                presentation = .cancelled(.userInitiated)
            } else { presentation = .context }
        }
    }

    func awaitTerminalState() async {
        while true {
            if let progress = await coordinator.measurementProgress() { partialSamples = progress.receivedSamples }
            let state = await coordinator.sessionState()
            let next = QuickCheckPresentationMapper.map(state)
            if next != .measuring {
                if case let .completed(_, _, entry?) = state {
                    completedEntry = entry
                    partialSamples = await coordinator.completedProbeSamples()
                    await loadHistory()
                }
                presentation = next
                return
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    func loadHistory() async {
        guard !usesUIFixture else { return }
        history = (try? await historyRepository.loadHistory()) ?? []
    }

    func retryFromHistory(_ entry: MeasurementHistoryEntry) {
        selectedTab = .home
        // A Home já mede uma única rota de referência e reaplica a mesma
        // amostra aos perfis do catálogo. Refazer pelo Histórico portanto não
        // reabre a antiga jornada de seleção regional/resultado; volta à Home
        // e inicia uma nova leitura em background, igual à abertura do app.
        selectedGameID = entry.resolvedContext.context.gameID
        startBackgroundQuickCheck()
    }

    func gameName(for entry: MeasurementHistoryEntry) -> String { gameName(forGameID: entry.resolvedContext.context.gameID) }
    func gameName(forGameID gameID: String) -> String { availableGames.first(where: { $0.id == gameID })?.name ?? NSLocalizedString("game.unknown", comment: "") }

    func deleteHistory() async throws {
        try await historyRepository.deleteAll()
        await loadHistory()
    }

    func loadRegionalPreference() async { manualRegionID = await regionalPreferenceRepository.manualRegionID() }
    func selectRegionPreference(_ candidate: RegionalReferenceCandidate) {
        let newValue = candidate.id == RegionalPreferenceIdentifiers.automatic ? nil : candidate.id
        manualRegionID = newValue
        Task { await regionalPreferenceRepository.setManualRegionID(newValue) }
    }
}
