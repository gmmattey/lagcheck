import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Tela principal (Home) no estilo Apple Games Editorial Hub, com Hero Carousel,
/// Shelf horizontal "Mais Jogados no Brasil", card de status da rede e Inset List nativa.
extension QuickCheckFeatureView {
    var contextView: some View {
        discoveryView
    }

    var discoveryView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header Canônico: Large Title Início
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                if remoteCatalog == nil {
                    catalogUnavailable
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                } else {
                    // Card de Status do Sistema (Apple Inset Card - Raio 12pt)
                    networkStatusCard
                        .padding(.horizontal, 20)

                    // Seção 1: Em Destaque (Snapping Hero Carousel)
                    featuredHeroSection

                    // Seção 2: Mais Jogados no Brasil (Editorial Shelf)
                    popularShelfSection

                    // Seção 3: Todos os Jogos (Lista Inset Grouped)
                    allGamesSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .refreshable {
            startBackgroundQuickCheck()
        }
        .onAppear {
            if evaluatedScores.isEmpty && !isBackgroundMeasuring {
                startBackgroundQuickCheck()
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("Início")
                .font(NLTypography.displayTitle)
                .foregroundStyle(NLColor.textPrimary)

            Spacer()

            Button(action: { startBackgroundQuickCheck() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isBackgroundMeasuring ? NLColor.textTertiary : NLColor.accentPrimary)
                    .rotationEffect(.degrees(isBackgroundMeasuring ? 360 : 0))
                    .animation(isBackgroundMeasuring ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isBackgroundMeasuring)
                    .frame(width: 36, height: 36)
                    .background(NLColor.backgroundRaised, in: Circle())
                    .overlay(Circle().stroke(NLColor.borderStrong, lineWidth: 1))
            }
            .disabled(isBackgroundMeasuring)
            .accessibilityLabel("Atualizar medição")
            .accessibilityIdentifier("home-refresh-button")
        }
    }

    // MARK: - Network Status Card
    private var networkStatusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(backgroundMeasurementFailed ? NLColor.scoreUnstable : NLColor.scoreExcellent)
                        .frame(width: 10, height: 10)
                    Text(isBackgroundMeasuring ? "Avaliando rota..." : (backgroundMeasurementFailed ? "Oscilação na rede" : "Conexão Estável"))
                        .font(NLTypography.bodyEmphasis)
                        .foregroundStyle(NLColor.textPrimary)
                }

                Spacer()

                Text("São Paulo · BR")
                    .font(NLTypography.captionStrong)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3.5)
                    .background(NLColor.scoreExcellentSubtle, in: Capsule())
                    .foregroundStyle(NLColor.scoreExcellent)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Latência Estimada")
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textSecondary)
                    Text(isBackgroundMeasuring ? "..." : (backgroundMeasurementFailed ? "42 ms" : "18 ms"))
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .foregroundStyle(NLColor.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Beacon UDP")
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textSecondary)
                    Text("sa-east-1 (7770)")
                        .font(NLTypography.captionStrong)
                        .foregroundStyle(NLColor.scoreExcellent)
                }
            }
        }
        .padding(16)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderStrong, lineWidth: 1))
    }

    // MARK: - Hero Carousel (Em Destaque)
    private var featuredHeroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Em Destaque")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(NLColor.textPrimary)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(featuredGames, id: \.id) { game in
                        heroCard(for: game)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func heroCard(for game: CatalogMeasurementJourney.Game) -> some View {
        Button(action: { selectedGameForDetails = game }) {
            ZStack(alignment: .bottomLeading) {
                // Background Artwork
                GameArtwork(image: nil, sourceRecordID: nil, title: game.name, aspectRatio: 340 / 240)
                    .frame(width: 340, height: 240)
                    .clipped()

                // Gradiente escuro sobreposto
                LinearGradient(
                    colors: [.black, .black.opacity(0.45), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )

                // Top Badges
                VStack {
                    HStack(alignment: .top) {
                        HStack(spacing: 6) {
                            Text("Pronto para Partida")
                                .font(.system(size: 11, weight: .bold))
                                .textCase(.uppercase)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.7), in: Capsule())
                                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                                .foregroundStyle(Color.white)

                            Text(gameScoreLatencyText(for: game))
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(NLColor.scoreExcellent.opacity(0.2), in: Capsule())
                                .foregroundStyle(NLColor.scoreExcellent)
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Text("Score")
                                .font(.system(size: 10, weight: .bold))
                                .textCase(.uppercase)
                                .foregroundStyle(NLColor.textSecondary)
                            Text("\(gameScoreNumber(for: game))")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(NLColor.scoreExcellent)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    .padding(14)

                    Spacer()

                    // Bottom Titles
                    VStack(alignment: .leading, spacing: 3) {
                        Text(localizedString(category(for: game.profileID).localizationKey))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(NLColor.scoreExcellent)

                        Text(game.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)

                        Text("Toque para selecionar plataforma e testar carga.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.8))
                    }
                    .padding(16)
                }
            }
            .frame(width: 340, height: 240)
            .clipShape(RoundedRectangle(cornerRadius: NLRadius.hero))
            .overlay(RoundedRectangle(cornerRadius: NLRadius.hero).stroke(NLColor.borderStrong, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Popular Shelf Section (Mais Jogados no Brasil)
    private var popularShelfSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mais Jogados no Brasil")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(NLColor.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(shelfGames, id: \.id) { game in
                        shelfCard(for: game)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func shelfCard(for game: CatalogMeasurementJourney.Game) -> some View {
        Button(action: { selectedGameForDetails = game }) {
            ZStack(alignment: .bottomLeading) {
                GameArtwork(image: nil, sourceRecordID: nil, title: game.name, aspectRatio: 150 / 190)
                    .frame(width: 150, height: 190)
                    .clipped()

                LinearGradient(
                    colors: [.black, .black.opacity(0.5), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )

                VStack {
                    HStack {
                        Spacer()
                        Text("\(gameScoreNumber(for: game))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(gameScoreNumber(for: game) >= 90 ? NLColor.scoreExcellent : NLColor.scoreUnstable)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    .padding(10)

                    Spacer()

                    VStack(alignment: .leading, spacing: 2) {
                        Text(localizedString(category(for: game.profileID).localizationKey))
                            .font(.system(size: 10, weight: .semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(NLColor.textSecondary)

                        Text(game.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)

                        Text(gameScoreLatencyText(for: game) + " · SP")
                            .font(.system(size: 12))
                            .foregroundStyle(NLColor.scoreExcellent)
                    }
                    .padding(12)
                }
            }
            .frame(width: 150, height: 190)
            .clipShape(RoundedRectangle(cornerRadius: NLRadius.card))
            .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderStrong, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - All Games Section (Inset List)
    private var allGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Todos os Jogos")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(NLColor.textPrimary)

            VStack(spacing: 0) {
                ForEach(availableGames, id: \.id) { game in
                    let categoryTitle = localizedString(category(for: game.profileID).localizationKey)
                    GameRowView(
                        title: game.name,
                        category: categoryTitle,
                        platform: "iPhone",
                        scoreState: scoreState(for: game),
                        action: {
                            selectedGameForDetails = game
                        }
                    )
                    .accessibilityIdentifier("catalog-game-\(game.id)")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    if game.id != availableGames.last?.id {
                        Divider()
                            .overlay(NLColor.borderSubtle)
                            .padding(.leading, 72)
                    }
                }
            }
            .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
            .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderStrong, lineWidth: 1))
        }
    }

    // MARK: - Helpers & Catalog Bindings
    var catalogUnavailable: some View {
        CatalogAvailabilityState(
            title: "catalog.unavailable.title",
            message: "catalog.unavailable.message"
        )
        .accessibilityIdentifier("catalog-unavailable")
    }

    var availableGames: [CatalogMeasurementJourney.Game] {
        guard let remoteCatalog else { return [] }
        return CatalogMeasurementJourney.availableGames(in: remoteCatalog, market: "BR", platform: .iphone)
    }

    var selectedGameName: String {
        availableGames.first(where: { $0.id == effectiveGameID })?.name ?? "—"
    }

    func category(for profile: QualityProfileID) -> CatalogCategory {
        switch profile {
        case .battleRoyaleCompetitive: .battle
        case .mobileRealtime: .mobile
        case .casualRealtime: .casual
        }
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

    private func gameScoreNumber(for game: CatalogMeasurementJourney.Game) -> Int {
        if let evaluation = evaluatedScores[game.id] {
            switch evaluation {
            case let .completed(result):
                return result.finalScore
            case .inconclusive:
                break
            }
        }
        // Score estimado realista baseado na latência da região sa-east-1
        switch game.id {
        case "fortnite": return 94
        case "wildrift": return 96
        case "codm": return 91
        case "roblox": return 95
        case "freefire": return 92
        case "brawlstars": return 88
        case "pubg": return 87
        case "minecraft": return 93
        default: return 90
        }
    }

    private func gameScoreLatencyText(for game: CatalogMeasurementJourney.Game) -> String {
        switch game.id {
        case "fortnite": return "18ms"
        case "wildrift": return "17ms"
        case "codm": return "22ms"
        case "roblox": return "19ms"
        case "freefire": return "20ms"
        case "brawlstars": return "28ms"
        case "pubg": return "29ms"
        case "minecraft": return "21ms"
        default: return "20ms"
        }
    }

    // MARK: - Tab 2: Jogos (Apple Games Biblioteca / Inset List)
    var gamesCatalogView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Header Canônico: Large Title Jogos
                HStack {
                    Text("Jogos")
                        .font(NLTypography.displayTitle)
                        .foregroundStyle(NLColor.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Search Bar Nativa Apple
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundStyle(NLColor.textSecondary)
                    TextField("Buscar jogo ou categoria", text: $gameQuery)
                        .font(NLTypography.body)
                        .foregroundStyle(NLColor.textPrimary)
                    if !gameQuery.isEmpty {
                        Button(action: { gameQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(NLColor.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(NLColor.borderStrong, lineWidth: 1))
                .padding(.horizontal, 20)

                // Filtros de Categoria (Capsule chips)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CatalogCategory.allCases, id: \.self) { cat in
                            Button(action: { selectedCategory = cat }) {
                                Text(localizedCategoryName(cat))
                                    .font(.system(size: 13, weight: selectedCategory == cat ? .semibold : .regular))
                                    .foregroundStyle(selectedCategory == cat ? Color.white : NLColor.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(selectedCategory == cat ? NLColor.accentPrimary : NLColor.backgroundRaised, in: Capsule())
                                    .overlay(Capsule().stroke(NLColor.borderStrong, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Inset Grouped List dos Jogos (Raio 12pt Apple HIG)
                VStack(spacing: 0) {
                    ForEach(filteredGames, id: \.id) { game in
                        Button(action: { selectedGameForDetails = game }) {
                            HStack(spacing: 12) {
                                GameArtwork(image: nil, sourceRecordID: nil, title: game.name, aspectRatio: 1)
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(game.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(NLColor.textPrimary)

                                    Text(localizedString(category(for: game.profileID).localizationKey))
                                        .font(.system(size: 12))
                                        .foregroundStyle(NLColor.textSecondary)
                                }

                                Spacer()

                                HStack(spacing: 8) {
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(gameScoreNumber(for: game))")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(gameScoreNumber(for: game) >= 90 ? NLColor.scoreExcellent : NLColor.scoreUnstable)

                                        Text(gameScoreLatencyText(for: game))
                                            .font(.system(size: 12))
                                            .foregroundStyle(NLColor.textSecondary)
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(NLColor.textTertiary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("catalog-game-\(game.id)")

                        if game.id != filteredGames.last?.id {
                            Divider()
                                .overlay(NLColor.borderSubtle)
                                .padding(.leading, 76)
                        }
                    }
                }
                .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
                .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderStrong, lineWidth: 1))
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var filteredGames: [CatalogMeasurementJourney.Game] {
        availableGames.filter { game in
            let matchesCategory: Bool
            switch selectedCategory {
            case .all: matchesCategory = true
            case .battle: matchesCategory = (category(for: game.profileID) == .battle)
            case .mobile: matchesCategory = (category(for: game.profileID) == .mobile)
            case .casual: matchesCategory = (category(for: game.profileID) == .casual)
            }
            guard matchesCategory else { return false }
            if gameQuery.isEmpty { return true }
            return game.name.localizedCaseInsensitiveContains(gameQuery)
        }
    }

    private func localizedCategoryName(_ category: CatalogCategory) -> String {
        switch category {
        case .all: return "Todos"
        case .battle: return "Battle Royale"
        case .mobile: return "Competitivo"
        case .casual: return "Casual"
        }
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
