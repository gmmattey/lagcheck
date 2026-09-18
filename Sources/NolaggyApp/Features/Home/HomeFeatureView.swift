import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Estado e composição da Home. Os componentes visuais vivem em
/// `HomePresentationComponents.swift` para manter a jornada independente do layout.
extension QuickCheckFeatureView {
    var contextView: some View { discoveryView }

    var discoveryView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: NLSpacing.lg) {
                if remoteCatalog == nil {
                    catalogUnavailable.padding(.horizontal, NLSpacing.md).padding(.top, NLSpacing.lg)
                } else {
                    HomeNetworkStatusCard(title: networkStatusTitle, color: networkStatusColor, latency: networkLatencyText, isMeasuring: isBackgroundMeasuring, wifiBandText: networkWiFiBandText)
                        .padding(.horizontal, NLSpacing.md)
                        .padding(.top, NLSpacing.xs)
                    HomeHeroSection(title: localizedString("home.featured"), games: featuredGames, categoryTitle: categoryTitle(for:), statusTitle: heroStatusText(for:), latency: gameScoreLatencyText(for:), score: gameScoreNumber(for:), scoreLabel: localizedString("home.score"), detail: localizedString("home.hero.detail"), select: { selectedGameForDetails = $0 })
                    HomeShelfSection(title: localizedString("home.popular"), games: shelfGames, categoryTitle: categoryTitle(for:), detail: shelfDetailText(for:), detailColor: shelfDetailColor(for:), score: gameScoreNumber(for:), select: { selectedGameForDetails = $0 })
                    HomeGameListSection(title: localizedString("home.all_games"), games: availableGames, categoryTitle: categoryTitle(for:), platform: localizedString("quick_check.context.platform"), scoreState: scoreState(for:), select: { selectedGameForDetails = $0 })
                        .padding(.horizontal, NLSpacing.md).padding(.bottom, NLSpacing.xl)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .refreshable { startBackgroundQuickCheck() }
        .safeAreaPadding(.bottom, NLSpacing.md)
        .navigationTitle(localizedString("navigation.home"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HomeRefreshButton(
                    refreshAccessibilityLabel: localizedString("home.refresh.accessibility"),
                    isMeasuring: isBackgroundMeasuring,
                    refresh: startBackgroundQuickCheck
                )
            }
        }
        .onAppear {
            if evaluatedScores.isEmpty && !isBackgroundMeasuring { startBackgroundQuickCheck() }
        }
    }

    var catalogUnavailable: some View {
        CatalogAvailabilityState(title: "catalog.unavailable.title", message: "catalog.unavailable.message")
            .accessibilityIdentifier("catalog-unavailable")
    }

    var availableGames: [CatalogMeasurementJourney.Game] {
        guard let remoteCatalog else { return [] }
        let market = CatalogMeasurementJourney.resolvedMarket(in: remoteCatalog)
        return CatalogMeasurementJourney.availableGames(in: remoteCatalog, market: market, platform: .iphone)
    }

    var selectedGameName: String { availableGames.first(where: { $0.id == effectiveGameID })?.name ?? "—" }

    func category(for profile: QualityProfileID) -> CatalogCategory {
        switch profile {
        case .battleRoyaleCompetitive: .battle
        case .mobileRealtime: .mobile
        case .casualRealtime: .casual
        }
    }

    func categoryTitle(for game: CatalogMeasurementJourney.Game) -> String {
        localizedString(category(for: game.profileID).localizationKey)
    }

    private var featuredGames: [CatalogMeasurementJourney.Game] {
        let preferred = ["fortnite", "wildrift", "codm"]
        let matches = preferred.compactMap { id in availableGames.first(where: { $0.id == id }) }
        return matches.isEmpty ? Array(availableGames.prefix(3)) : matches
    }

    private var shelfGames: [CatalogMeasurementJourney.Game] {
        let featuredIDs = Set(featuredGames.map(\.id))
        let remaining = availableGames.filter { !featuredIDs.contains($0.id) }
        return remaining.isEmpty ? availableGames : remaining
    }

    private func gameScoreNumber(for game: CatalogMeasurementJourney.Game) -> Int? {
        guard case let .completed(result)? = evaluatedScores[game.id] else { return nil }
        return result.finalScore
    }

    private func gameScoreLatencyText(for game: CatalogMeasurementJourney.Game) -> String? {
        guard case let .completed(result)? = evaluatedScores[game.id], let latency = result.metrics.p50Milliseconds else { return nil }
        return "\(Int(latency.rounded())) ms"
    }

    private var networkStatusTitle: String {
        if isBackgroundMeasuring { return localizedString("home.network.measuring") }
        if backgroundMeasurementFailed { return localizedString("home.network.inconclusive") }
        if evaluatedScores.isEmpty { return localizedString("home.network.awaiting_result") }
        return localizedString("home.network.measured")
    }

    private var networkStatusColor: Color {
        if isBackgroundMeasuring { return NLColor.accentPrimary }
        if backgroundMeasurementFailed || evaluatedScores.isEmpty { return NLColor.scoreNeutral }
        return NLColor.accentPrimary
    }

    private var networkLatencyText: String {
        guard !isBackgroundMeasuring, !backgroundMeasurementFailed, let firstGame = availableGames.first, let latency = gameScoreLatencyText(for: firstGame) else { return localizedString("home.network.awaiting_result") }
        return latency
    }

    private var networkWiFiBandText: String? {
        guard !isBackgroundMeasuring, !backgroundMeasurementFailed, let firstGame = availableGames.first, case let .completed(result)? = evaluatedScores[firstGame.id] else { return nil }
        let telemetry = WiFiLocalTelemetry(
            gatewayRTTMedianMs: result.metrics.p50Milliseconds,
            gatewayJitterMs: result.metrics.jitterMilliseconds,
            tailRatioP95P50: result.metrics.p95ToP50Ratio,
            validSampleCount: result.metrics.validResponseCount,
            plannedSampleCount: result.metrics.validResponseCount,
            isWiFi: true
        )
        let eval = WiFiBandEvaluator.evaluate(telemetry: telemetry)
        if eval.diagnostic.isSuspectOrConfirmed24GHz {
            return "2.4 GHz"
        } else if eval.diagnostic == .stableWiFi {
            return "5 GHz"
        }
        return nil
    }

    private func heroStatusText(for game: CatalogMeasurementJourney.Game) -> String {
        switch scoreState(for: game) {
        case .measuring: return localizedString("home.status.measuring")
        case .inconclusive, .failed: return localizedString("home.status.inconclusive")
        case .evaluated: return localizedString("home.status.measured")
        }
    }

    private func shelfDetailText(for game: CatalogMeasurementJourney.Game) -> String { gameScoreLatencyText(for: game) ?? heroStatusText(for: game) }
    private func shelfDetailColor(for game: CatalogMeasurementJourney.Game) -> Color { gameScoreLatencyText(for: game) == nil ? NLColor.textSecondary : NLColor.scoreExcellent }

    var gamesCatalogView: some View {
        HomeCatalogView(title: localizedString("navigation.games"), query: $gameQuery, selectedCategory: $selectedCategory, categories: CatalogCategory.allCases, games: filteredGames, searchPlaceholder: localizedString("catalog.search.placeholder"), clearSearchAccessibilityLabel: localizedString("catalog.search.close"), categoryTitle: { localizedString($0.localizationKey) }, gameCategoryTitle: categoryTitle(for:), scoreState: scoreState(for:), score: gameScoreNumber(for:), latency: gameScoreLatencyText(for:), inconclusiveAccessibilityLabel: localizedString("home.status.inconclusive"), select: { selectedGameForDetails = $0 })
    }

    private var filteredGames: [CatalogMeasurementJourney.Game] {
        availableGames.filter { game in
            let matchesCategory = selectedCategory == .all || category(for: game.profileID) == selectedCategory
            return matchesCategory && (gameQuery.isEmpty || game.name.localizedCaseInsensitiveContains(gameQuery))
        }
    }
}
