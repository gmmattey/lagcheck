import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain
import NolaggyInfrastructure

/// Ciclo de vida e navegação da sessão. Mantido fora da casca de tabs para que
/// `QuickCheckFeatureView` fique responsável somente por compor a jornada.
extension QuickCheckFeatureView {
    func retest(_ entry: MeasurementHistoryEntry) {
        let previous = entry.resolvedContext.context
        guard availableGames.contains(where: { $0.id == previous.gameID }) else { return }
        analyticsTracker.track(.retestStarted(gameID: previous.gameID, platform: previous.platform.rawValue))
        selectedGameID = previous.gameID
        requestedMeasurementContext = GameContext(
            gameID: previous.gameID,
            market: previous.market,
            platform: previous.platform,
            declaredExternalLink: previous.declaredExternalLink
        )
        selectedRegionalContext = nil
        start()
    }

    func start() {
        guard let remoteCatalog, let activeContext = requestedMeasurementContext ?? context else { return }
        regionalPresentation = .confirming
        showingRegionalSelection = true
        Task { @MainActor in
            await Task.yield()
            let manualRegionID = await regionalPreferenceRepository.manualRegionID()
            guard let snapshot = await automaticRegionalSnapshot(for: activeContext, in: remoteCatalog, manualRegionID: manualRegionID) else { return }
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
        case let .selected(selection): openDeepCheck(resolvedContext: selection.selected.resolvedContext)
        case .inconclusive: regionalPresentation = .noViableCandidate
        }
    }

    func retryRegionalPreRead() {
        guard let remoteCatalog, let activeContext = requestedMeasurementContext ?? context else { return }
        regionalPresentation = .confirming
        Task { @MainActor in
            let manualRegionID = await regionalPreferenceRepository.manualRegionID()
            guard let snapshot = await automaticRegionalSnapshot(for: activeContext, in: remoteCatalog, manualRegionID: manualRegionID) else { return }
            await performRegionalPreRead(snapshot: snapshot, manualRegionID: manualRegionID)
        }
    }

    /// O catálogo v3 pode oferecer candidatos A2S próprios. Eles são
    /// pré-validados silenciosamente antes da pré-leitura que produz a decisão
    /// de medição; falha de identidade/UDP devolve apenas a AWS assinada.
    func automaticRegionalSnapshot(
        for context: GameContext,
        in catalog: RemoteCatalogPayload,
        manualRegionID: String?
    ) async -> RegionalSelectionSnapshot? {
        guard catalog.schemaVersion == RemoteCatalogVerifier.routedCatalogSchemaVersion else {
            return try? CatalogMeasurementJourney.regionalSnapshot(for: context, in: catalog, manualRegionID: manualRegionID)
        }
        guard let resolved = try? await AutomaticGameRouteResolver.resolve(
            context,
            in: catalog,
            preflighting: SteamA2SRoutePreflight()
        ) else { return nil }
        return try? RegionalSelectionSnapshot(
            catalogVersion: resolved.catalogVersion,
            context: context,
            candidates: [try RegionalSelectionCandidate(resolvedContext: resolved, priority: 0)]
        )
    }

    func cancelRegionalSelection() {
        Task { @MainActor in
            await coordinator.cancelRegionalPreRead()
            deepCheckDestination = nil
            showingRegionalSelection = false
            requestedMeasurementContext = nil
        }
    }

    func startQuickCheck(resolvedContext: ResolvedMeasurementContext) {
        Task { @MainActor in
            selectedRegionalContext = resolvedContext
            requestedMeasurementContext = nil
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
            if baseContext.context.gameID == GameContext.genericGamingID {
                let market = remoteCatalog.map { CatalogMeasurementJourney.resolvedMarket(in: $0) } ?? "BR"
                let genericGame = CatalogMeasurementJourney.genericGamingGame(
                    market: market,
                    platform: platform,
                    declaredExternalLink: baseContext.context.declaredExternalLink,
                    localizedName: AppLocalization.string("generic_gaming.name", comment: "")
                )
                guard let resolved = resolveGameContext(genericGame, platform: platform, declaredExternalLink: baseContext.context.declaredExternalLink) else {
                    return
                }
                context = resolved
            } else {
                guard let game = availableGames.first(where: { $0.id == baseContext.context.gameID }),
                      let resolved = resolveGameContext(game, platform: platform) else {
                    return
                }
                context = resolved
            }
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
        if entry.resolvedContext.context.gameID == GameContext.genericGamingID {
            selectedGameID = nil
            startGeneralGamingCheckDirectly()
            return
        }
        selectedGameID = entry.resolvedContext.context.gameID
        if let game = availableGames.first(where: { $0.id == entry.resolvedContext.context.gameID }) {
            startCheckDirectly(for: game)
        } else {
            startGeneralGamingCheckDirectly()
        }
    }

    func gameName(for entry: MeasurementHistoryEntry) -> String { gameName(forGameID: entry.resolvedContext.context.gameID) }
    func gameName(forGameID gameID: String) -> String {
        if gameID == GameContext.genericGamingID {
            return AppLocalization.string("generic_gaming.name", comment: "")
        }
        return availableGames.first(where: { $0.id == gameID })?.name ?? AppLocalization.string("game.unknown", comment: "")
    }

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
