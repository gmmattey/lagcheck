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
        RouteMapPresentation.beginSession(routeMap)
        showingRegionalSelection = true
        Task { @MainActor in
            await Task.yield()
            let manualRegionID = await regionalPreferenceRepository.manualRegionID()
            guard let snapshot = await automaticRegionalSnapshot(for: activeContext, in: remoteCatalog, manualRegionID: manualRegionID) else { return }
            await performRegionalPreRead(snapshot: snapshot, manualRegionID: manualRegionID)
        }
    }

    func performRegionalPreRead(snapshot: RegionalSelectionSnapshot, manualRegionID: String? = nil) async {
        await VerifiedRemoteArtworkLoader.shared.setDownloadsEnabled(false)
        let decision: RegionalSelectionDecision
        do {
            decision = try await coordinator.selectRegionalCandidate(
                snapshot: snapshot,
                using: RegionalPreReadCoordinator(collector: MeasurementTransportFactory.regionalPreReadCollector(
                    onEvent: RouteMapPresentation.preReadEventHandler(for: routeMap)
                )),
                manualRegionID: manualRegionID
            )
        } catch RegionalSelectionError.manualCandidateNotAllowed where manualRegionID != nil {
            await performRegionalPreRead(snapshot: snapshot, manualRegionID: nil)
            return
        } catch { return }

        switch decision {
        case let .selected(selection):
            let resolved = selection.selected.resolvedContext
            routeMap.selectRegion(resolved.regionID)
            openDeepCheck(resolvedContext: resolved, routeMap: routeMap, runsRegionalPreRead: false)
        case .inconclusive: regionalPresentation = .noViableCandidate
        }
    }

    func retryRegionalPreRead() {
        guard let remoteCatalog, let activeContext = requestedMeasurementContext ?? context else { return }
        regionalPresentation = .confirming
        RouteMapPresentation.beginSession(routeMap)
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
        // Uma rota própria só pode substituir a referência após a identidade
        // passar na pré-validação. Sem isso, a Decisão 90 pré-lê as regiões
        // AWS assinadas e escolhe pelo RTT observado.
        guard resolved.routeKind == .gameOwned else {
            return try? CatalogMeasurementJourney.regionalSnapshot(for: context, in: catalog, manualRegionID: manualRegionID)
        }
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

    func openDeepCheck(
        resolvedContext: ResolvedMeasurementContext? = nil,
        platform: Platform? = nil,
        incomingDuel: HostDuelPayload? = nil,
        routeMap: RouteMapController? = nil,
        runsRegionalPreRead: Bool = true
    ) {
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
            gameName: gameName(forGameID: context.context.gameID),
            incomingDuel: incomingDuel,
            // A varredura só continua no Check quando a região é a mesma escolhida nela.
            routeMap: routeMap?.selectedId == context.regionID ? routeMap : nil,
            regionalSnapshotProvider: runsRegionalPreRead ? regionalSnapshotProvider(for: context.context) : nil
        )
    }

    /// Todo Check passa pela pré-leitura regional (Decisão 90), como no Android:
    /// os servidores candidatos são medidos e o de menor latência UDP é o medido.
    /// Sem rede real (simulador sem `-simulator-real-network` e fixtures), mede
    /// direto a rota resolvida, como antes.
    func regionalSnapshotProvider(for gameContext: GameContext) -> RegionalSnapshotProvider? {
        guard MeasurementTransportFactory.usesRealNetwork,
              !UITestFixtures.isEnabled("-ui-fixture-confirmed-region"),
              let remoteCatalog else { return nil }
        let preferences = regionalPreferenceRepository
        let shell = self
        return {
            let manualRegionID = await preferences.manualRegionID()
            guard let snapshot = await shell.automaticRegionalSnapshot(
                for: gameContext, in: remoteCatalog, manualRegionID: manualRegionID
            ) else { return nil }
            return RegionalSnapshotRequest(snapshot: snapshot, manualRegionID: manualRegionID)
        }
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

                    // Decisão 75 (Fase 2 / Item 6): Gravação do snapshot real para Widgets iOS 17
                    if let verdict = entry.readinessVerdict, verdict != .inconclusive,
                       let metrics = entry.result?.metrics,
                       let p50 = metrics.p50Milliseconds, p50 > 0 {
                        let name = gameName(for: entry)
                        let isPt = AppLocalization.locale.identifier.lowercased().hasPrefix("pt")
                        let region = GlobalProbeRegistry.friendlyLabel(for: entry.resolvedContext.regionID, isPortuguese: isPt)
                        let widgetSnapshot = WidgetTelemetrySnapshot(
                            gameID: entry.resolvedContext.context.gameID,
                            gameName: name,
                            regionLabel: region,
                            verdict: verdict,
                            rttMedianMs: p50,
                            jitterMs: metrics.jitterMilliseconds ?? 0.0,
                            packetLossPercentage: metrics.packetLossPercentage,
                            bufferbloatGrade: entry.deepCheck?.metrics.loadImpact?.bufferbloatGrade.rawValue,
                            platform: entry.resolvedContext.context.platform,
                            declaredExternalLink: entry.resolvedContext.context.declaredExternalLink,
                            capturedAt: Date()
                        )
                        if WidgetArtworkSnapshotWriter.saveArtwork(forGameID: entry.resolvedContext.context.gameID) {
                            SharedAppGroupStore.shared.saveLatestSnapshot(widgetSnapshot)
                        } else {
                            SharedAppGroupStore.shared.clearSnapshot()
                        }
                        WidgetArtworkSnapshotWriter.refreshWidget()
                    } else {
                        // Um novo resultado inconclusivo nunca reutiliza telemetria anterior como se fosse atual.
                        SharedAppGroupStore.shared.clearSnapshot()
                        WidgetArtworkSnapshotWriter.refreshWidget()
                    }


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
