import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Tela principal (Home) com lista nativa iOS de jogos e Quick Check automático em background (Decisão 22).
extension QuickCheckFeatureView {
    var contextView: some View {
        discoveryView
    }

    var discoveryView: some View {
        VStack(spacing: 0) {
            // Header padrão
            headerView

            if remoteCatalog == nil {
                catalogUnavailable
                    .padding(.horizontal, NLSpacing.screenMarginHorizontal)
                    .padding(.top, NLSpacing.xl)
                Spacer()
            } else {
                // Banner de Status / Erro discreto
                statusBanner

                // Lista Nativa de Jogos
                gamesList
            }
        }
        .onAppear {
            if evaluatedScores.isEmpty && !isBackgroundMeasuring {
                startBackgroundQuickCheck()
            }
        }
    }

    private var headerView: some View {
        HStack {
            Text("nolaggy")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(NLColor.textPrimary)

            Spacer()

            if isBackgroundMeasuring {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: NLColor.textSecondary))
                    .scaleEffect(0.8)
            }

            Button(action: { startBackgroundQuickCheck() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isBackgroundMeasuring ? NLColor.textTertiary : NLColor.accentPrimary)
                    .frame(width: 44, height: 44)
            }
            .disabled(isBackgroundMeasuring)
            .accessibilityLabel("Atualizar medição")
            .accessibilityIdentifier("home-refresh-button")

            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(NLColor.textSecondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Configurações")
            .accessibilityIdentifier("home-settings-button")
        }
        .padding(.horizontal, NLSpacing.screenMarginHorizontal)
        .padding(.top, NLSpacing.xs)
    }

    @ViewBuilder
    private var statusBanner: some View {
        if isBackgroundMeasuring {
            HStack(spacing: NLSpacing.xs) {
                Text("Avaliando sua rede...")
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(NLColor.textSecondary)
                Spacer()
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .padding(.vertical, NLSpacing.xs)
        } else if backgroundMeasurementFailed {
            HStack(spacing: NLSpacing.sm) {
                Image(systemName: "exclamationmark.triangle")
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(NLColor.scoreUnstable)

                Text("Não foi possível medir a rede agora.")
                    .font(NLTypography.caption)
                    .foregroundStyle(NLColor.textSecondary)

                Spacer()

                Button("Tentar novamente") {
                    startBackgroundQuickCheck()
                }
                .font(NLTypography.captionStrong)
                .foregroundStyle(NLColor.accentPrimary)
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .padding(.vertical, NLSpacing.xs)
        }
    }

    private var gamesList: some View {
        List {
            Section {
                ForEach(availableGames) { game in
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
                    .listRowBackground(NLColor.backgroundRaised)
                    .listRowSeparatorTint(NLColor.borderStrong.opacity(0.4))
                }
            } header: {
                Text("JOGOS POPULARES")
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(NLColor.textTertiary)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .refreshable {
            startBackgroundQuickCheck()
        }
    }

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
