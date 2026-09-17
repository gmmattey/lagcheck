import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Tela de descoberta de jogos (Home): busca sob demanda, categorias, vitrine
/// horizontal e continuidade da última medição — ver doc 01 §7.1.
extension QuickCheckFeatureView {
    var contextView: some View {
        discoveryView
    }

    var discoveryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NLSpacing.xl) {
                header(title: nil, showsBack: false, showsSearch: remoteCatalog != nil)

                if remoteCatalog == nil {
                    catalogUnavailable
                } else {
                    if isGameSearchExpanded {
                        expandedGameSearch
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                    if let summary = MeasurementHistorySummary(entries: history) {
                        recentMeasurement(summary)
                    }
                    gamePicker
                    // Sem escolha explícita e com histórico, a última medição já é a
                    // oferta primária: não duplicar um segundo card "pronto para medir"
                    // por cima dela com um jogo que ninguém escolheu nesta visita.
                    if effectiveGameID != nil {
                        selectedGameAction
                    }

                    /*VStack(alignment: .leading, spacing: NLSpacing.sm) {
                        Text("quick_check.context.platform_title")
                            .font(NLTypography.subheadline)
                            .foregroundStyle(NLColor.textPrimary)
                        contextPill(icon: "iphone", text: "quick_check.context.platform")
                    }

                    VStack(alignment: .leading, spacing: NLSpacing.xs) {
                        Label("quick_check.region.sao_paulo", systemImage: "mappin.and.ellipse")
                            .font(NLTypography.bodyEmphasis)
                            .foregroundStyle(NLColor.textPrimary)
                        Text("quick_check.region.reference")
                            .font(NLTypography.footnote)
                            .foregroundStyle(NLColor.textTertiary)
                        Text("quick_check.context.reference_explanation")
                            .font(NLTypography.callout)
                            .foregroundStyle(NLColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    PrimaryButton(title: "quick_check.start", accessibilityIdentifier: "quick-check-start", action: start)
                        .disabled(context == nil)*/
                        // O Deep Check também usa uma cobertura de tela cheia
                        // no contêiner raiz. A seleção regional pertence à
                        // jornada de contexto e fica ancorada nela para as duas
                        // apresentações não competirem pelo mesmo host SwiftUI.
                }
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .padding(.bottom, NLSpacing.lg)
        }
    }

    var catalogUnavailable: some View {
        CatalogAvailabilityState(
            title: "catalog.unavailable.title",
            message: "catalog.unavailable.message",
        )
        .accessibilityIdentifier("catalog-unavailable")
    }

    var gamePicker: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            Text("quick_check.catalog.available_games")
                .font(NLTypography.subheadline)
                .foregroundStyle(NLColor.textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: NLSpacing.md) {
                    ForEach(filteredGames) { game in
                        let categoryTitle = localizedString(category(for: game.profileID).localizationKey)
                        CompactCatalogGameTile(
                            title: game.name,
                            category: categoryTitle,
                            isSelected: game.id == effectiveGameID,
                            accessibilityLabel: "\(game.name), \(categoryTitle)",
                            action: { select(game) }
                        )
                        .accessibilityIdentifier("catalog-game-\(game.id)")
                    }
                }
            }
        }
    }

    var expandedGameSearch: some View {
        VStack(spacing: NLSpacing.sm) {
            CatalogSearchField(
                query: $gameQuery,
                placeholder: "catalog.search.placeholder",
                accessibilityLabel: "catalog.search.accessibility",
                dismiss: collapseGameSearch,
                focusesOnAppear: true
            )
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NLSpacing.sm) {
                    ForEach(CatalogCategory.allCases, id: \.self) { category in
                        CatalogCategoryChip(
                            label: localizedString(category.localizationKey),
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
            }
        }
    }

    var availableGames: [CatalogMeasurementJourney.Game] {
        guard let remoteCatalog else { return [] }
        return CatalogMeasurementJourney.availableGames(in: remoteCatalog, market: "BR", platform: .iphone)
    }

    var selectedGameName: String {
        availableGames.first(where: { $0.id == effectiveGameID })?.name ?? "—"
    }

    var filteredGames: [CatalogMeasurementJourney.Game] {
        availableGames.filter { game in
            (selectedCategory == .all || category(for: game.profileID) == selectedCategory) &&
            (gameQuery.isEmpty || game.name.localizedCaseInsensitiveContains(gameQuery))
        }
    }

    func category(for profile: QualityProfileID) -> CatalogCategory {
        switch profile {
        case .battleRoyaleCompetitive: .battle
        case .mobileRealtime: .mobile
        case .casualRealtime: .casual
        }
    }

    func select(_ game: CatalogMeasurementJourney.Game) {
        withAnimation(reduceMotion ? NLMotion.gameSelectionCardFade : NLMotion.gameSelectionCard) {
            selectedGameID = game.id
            selectedRegionalContext = nil
        }
    }

    func openGameSearch() {
        withAnimation(.snappy) { isGameSearchExpanded = true }
    }

    func collapseGameSearch() {
        gameQuery = ""
        selectedCategory = .all
        withAnimation(.snappy) { isGameSearchExpanded = false }
    }

    func recentScore(for context: GameContext) -> Int? {
        history.first(where: { $0.resolvedContext.context == context })?.result.finalScore
    }

    func contextPill(icon: String, text: LocalizedStringKey) -> some View {
        Label(text, systemImage: icon)
            .font(NLTypography.callout.weight(.semibold))
            .foregroundStyle(NLColor.accentPrimary)
            .frame(minWidth: 88, minHeight: NLSizing.touchTarget)
            .padding(.horizontal, NLSpacing.sm)
            .background(NLColor.accentPrimarySubtle, in: RoundedRectangle(cornerRadius: NLRadius.controlSmall))
            .overlay { RoundedRectangle(cornerRadius: NLRadius.controlSmall).stroke(NLColor.accentPrimary, lineWidth: NLStroke.hairline) }
    }

    func recentMeasurement(_ summary: MeasurementHistorySummary) -> some View {
        Button(action: { retest(summary.latest) }) {
            VStack(alignment: .leading, spacing: NLSpacing.sm) {
                Text("home.latest_measurement")
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(NLColor.textTertiary)
                HStack(spacing: NLSpacing.md) {
                    GameArtwork(image: nil, sourceRecordID: nil, title: gameName(for: summary.latest))
                        .frame(width: NLSizing.compactGameArtworkSide, height: NLSizing.compactGameArtworkSide)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: NLSpacing.xxs) {
                        Text(gameName(for: summary.latest))
                            .font(NLTypography.bodyEmphasis)
                            .foregroundStyle(NLColor.textPrimary)
                        Text("home.last_score \(summary.latest.result.finalScore)")
                            .font(NLTypography.callout)
                            .foregroundStyle(NLColor.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                        .font(NLTypography.bodyEmphasis)
                        .foregroundStyle(NLColor.accentPrimary)
                        .accessibilityHidden(true)
                }
                Text(String(format: NSLocalizedString("home.retest_game %@", comment: ""), gameName(for: summary.latest)))
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(NLColor.accentPrimary)
            }
            .padding(NLSpacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
            .shadow(
                color: reduceTransparency ? .clear : NLShadow.cardColor,
                radius: reduceTransparency ? 0 : NLShadow.cardRadius,
                y: reduceTransparency ? 0 : NLShadow.cardYOffset
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home-retest-latest")
    }

    var selectedGameAction: some View {
        Group {
            if reduceMotion {
                selectedGameCard
                    .id(effectiveGameID)
                    .transition(.opacity)
            } else {
                selectedGameCard
                    .id(effectiveGameID)
                    .transition(.gameSelectionCardFlip)
            }
        }
        .animation(reduceMotion ? NLMotion.gameSelectionCardFade : NLMotion.gameSelectionCard, value: effectiveGameID)
    }

    var selectedGameCard: some View {
        VStack(alignment: .leading, spacing: NLSpacing.md) {
            Text("home.selected_game")
                .font(NLTypography.captionStrong)
                .foregroundStyle(NLColor.textTertiary)
            Text(selectedGameName)
                .font(NLTypography.displayTitle)
                .foregroundStyle(NLColor.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("home-selected-game-title")
            contextSummary
            PrimaryButton(title: "quick_check.start", accessibilityIdentifier: "quick-check-start", action: start)
                .disabled(context == nil)
        }
        .padding(NLSpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .shadow(
            color: reduceTransparency ? .clear : NLShadow.prominentCardColor,
            radius: reduceTransparency ? 0 : NLShadow.prominentCardRadius,
            y: reduceTransparency ? 0 : NLShadow.prominentCardYOffset
        )
    }

    var contextSummary: some View {
        VStack(alignment: .leading, spacing: NLSpacing.md) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: NLSpacing.xl) {
                    contextFact(label: "quick_check.context.platform_label", value: "quick_check.context.platform", icon: "iphone")
                    contextFact(label: "quick_check.region.reference", value: "quick_check.region.sao_paulo", icon: "mappin.and.ellipse")
                }
                VStack(alignment: .leading, spacing: NLSpacing.md) {
                    contextFact(label: "quick_check.context.platform_label", value: "quick_check.context.platform", icon: "iphone")
                    contextFact(label: "quick_check.region.reference", value: "quick_check.region.sao_paulo", icon: "mappin.and.ellipse")
                }
            }
            Text("quick_check.context.reference_compact")
                .font(NLTypography.contextDisclosure)
                .foregroundStyle(NLColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    func contextFact(label: LocalizedStringKey, value: LocalizedStringKey, icon: String) -> some View {
        VStack(alignment: .leading, spacing: NLSpacing.xxs) {
            Label(label, systemImage: icon)
                .font(NLTypography.captionStrong)
                .foregroundStyle(NLColor.textTertiary)
            Text(value)
                .font(NLTypography.bodyEmphasis)
                .foregroundStyle(NLColor.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}

enum CatalogCategory: CaseIterable {
    case all
    case battle
    case mobile
    case casual

    var localizationKey: String {
        switch self {
        case .all: "catalog.category.all"
        case .battle: "catalog.category.battle"
        case .mobile: "catalog.category.mobile"
        case .casual: "catalog.category.casual"
        }
    }
}

private struct GameSelectionCardFlip: ViewModifier {
    let angle: Double
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .rotation3DEffect(
                .degrees(angle),
                axis: (x: 0, y: 1, z: 0),
                perspective: NLMotion.gameSelectionFlipPerspective
            )
    }
}

@MainActor
private extension AnyTransition {
    static let gameSelectionCardFlip = AnyTransition.asymmetric(
        insertion: .modifier(
            active: GameSelectionCardFlip(angle: -NLMotion.gameSelectionFlipDegrees, opacity: 0),
            identity: GameSelectionCardFlip(angle: 0, opacity: 1)
        ),
        removal: .modifier(
            active: GameSelectionCardFlip(angle: NLMotion.gameSelectionFlipDegrees, opacity: 0),
            identity: GameSelectionCardFlip(angle: 0, opacity: 1)
        )
    )
}
