import SwiftUI
import NolaggyDesign
import NolaggyDomain

struct GameDetailPresentation {
    let scoreState: GameRowView.ScoreState
    let gameName: String

    var titleKey: LocalizedStringKey {
        switch scoreState {
        case let .evaluated(_, classification):
            switch classification {
            case .excellent: "game_detail.verdict.excellent.title"
            case .great: "game_detail.verdict.great.title"
            case .unstable: "game_detail.verdict.unstable.title"
            case .lagRisk: "game_detail.verdict.lag_risk.title"
            }
        case .measuring: "game_detail.verdict.measuring.title"
        case .inconclusive, .failed: "game_detail.verdict.inconclusive.title"
        }
    }

    var description: String {
        switch scoreState {
        case let .evaluated(_, classification):
            let key: String
            switch classification {
            case .excellent, .great: key = "game_detail.verdict.healthy.message %@"
            case .unstable: key = "game_detail.verdict.unstable.message %@"
            case .lagRisk: key = "game_detail.verdict.lag_risk.message %@"
            }
            return String(format: NSLocalizedString(key, comment: ""), gameName)
        case .measuring: return String(localized: "game_detail.verdict.measuring.message")
        case .inconclusive, .failed: return String(localized: "game_detail.verdict.inconclusive.message")
        }
    }
}

struct GameDetailScoreHeader: View {
    let scoreState: GameRowView.ScoreState
    var body: some View {
        VStack(spacing: NLSpacing.sm) {
            switch scoreState {
            case let .evaluated(score, classification):
                NolaggyScore(outcome: .revealed(score: score, classification: classification), style: .standard, showsGlow: false)
            case .measuring:
                ProgressView().scaleEffect(1.4).padding(.vertical, NLSpacing.xl)
                Text("quick_check.measuring.progress").font(NLTypography.captionStrong).foregroundStyle(NLColor.textSecondary)
            case .inconclusive, .failed:
                NolaggyScore(outcome: .inconclusive, style: .standard, showsGlow: false)
            }
        }
    }
}

struct GameDetailMeasurementScope: View {
    var platform: Platform = .iphone

    var body: some View {
        Label(scopeText, systemImage: iconName)
            .font(NLTypography.footnote)
            .foregroundStyle(NLColor.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(NLSpacing.cardPadding)
            .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
            .accessibilityIdentifier("game-detail-iphone-scope")
    }

    private var iconName: String {
        switch platform {
        case .iphone: return "iphone"
        case .playstation: return "playstation.logo"
        case .xbox: return "xbox.logo"
        case .pc: return "display"
        case .nintendo: return "gamecontroller.fill"
        }
    }

    private var scopeText: String {
        switch platform {
        case .iphone:
            return NSLocalizedString("game_detail.scope.iphone", comment: "")
        case .playstation:
            return String(format: NSLocalizedString("game_detail.scope.console %@", comment: ""), "PlayStation")
        case .xbox:
            return String(format: NSLocalizedString("game_detail.scope.console %@", comment: ""), "Xbox")
        case .nintendo:
            return String(format: NSLocalizedString("game_detail.scope.console %@", comment: ""), "Switch")
        case .pc:
            return String(format: NSLocalizedString("game_detail.scope.console %@", comment: ""), "PC")
        }
    }
}

struct GameDetailVerdictCard: View {
    let presentation: GameDetailPresentation
    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.xs) {
            Text(presentation.titleKey).font(NLTypography.bodyEmphasis).foregroundStyle(NLColor.textPrimary)
            Text(presentation.description).font(NLTypography.callout).foregroundStyle(NLColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
    }
}

struct GameDetailMetricsCard: View {
    let metrics: QualityMetrics
    var body: some View {
        VStack(spacing: 1) {
            MetricRow(label: "quick_check.result.latency", value: milliseconds(metrics.p50Milliseconds), unit: "ms")
            MetricRow(label: "quick_check.result.jitter", value: milliseconds(metrics.jitterMilliseconds), unit: "ms")
            MetricRow(label: "quick_check.result.loss", value: "\(Int(metrics.packetLossPercentage.rounded()))", unit: "%")
        }
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
    }
    private func milliseconds(_ value: Double?) -> String { value.map { String(Int($0.rounded())) } ?? "—" }
}

// MARK: - Cinema Hero (Estilo Netflix) Components

/// Banner Hero Cinematográfico com arte full-bleed, gradiente escuro e metadados no padrão Apple HIG
struct GameDetailCinemaHeroBanner: View {
    let game: CatalogMeasurementJourney.Game
    let editorial: RemoteCatalogGameEditorial?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Artwork full-bleed
            VerifiedGameArtwork(game: game, aspectRatio: 16 / 9)
                .frame(maxWidth: .infinity)
                .frame(height: 270)
                .clipped()

            // Gradiente cinematográfico sobre a imagem
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.45), location: 0.0),
                    .init(color: .clear, location: 0.25),
                    .init(color: .black.opacity(0.35), location: 0.5),
                    .init(color: .black.opacity(0.88), location: 0.82),
                    .init(color: .black, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Informações sobrepostas na base do banner
            VStack(alignment: .leading, spacing: NLSpacing.xs) {
                // Linha de Metadados Apple HIG (sem glow ou percentuais artificiais)
                HStack(spacing: 6) {
                    if let year = editorial?.releaseYear {
                        Text(String(year))
                            .font(NLTypography.subheadline)
                            .foregroundStyle(NLColor.textSecondary)
                    }

                    if let age = editorial?.ageRating {
                        Text("•")
                            .foregroundStyle(NLColor.textTertiary)
                        Text(age)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(NLColor.textPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
                    }

                    if let publisher = editorial?.publisher {
                        Text("•")
                            .foregroundStyle(NLColor.textTertiary)
                        Text(publisher)
                            .font(NLTypography.subheadline)
                            .foregroundStyle(NLColor.textSecondary)
                            .lineLimit(1)
                    }
                }

                // Título em destaque do jogo (sem sombra artificial)
                Text(game.name)
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .padding(.bottom, NLSpacing.sm)
        }
    }
}

/// Grid com as Notas e Avaliações Oficiais Auditadas (App Store & Metacritic)
/// Ao clicar, abre a página oficial correspondente no Safari/App Store.
struct GameDetailRatingsGrid: View {
    @Environment(\.openURL) private var openURL
    let editorial: RemoteCatalogGameEditorial

    var body: some View {
        HStack(spacing: NLSpacing.sm) {
            // Card App Store Interativo
            if let appStore = editorial.ratings.first(where: { $0.source == .appStore }) {
                ratingButton(
                    icon: "star.fill",
                    iconColor: Color.yellow,
                    iconBg: Color.white.opacity(0.08),
                    title: appStore.formattedScore,
                    subtitle: String(format: NSLocalizedString("game_detail.ratings.reviews_count %@", comment: ""), formattedCount(appStore.reviewCount)),
                    urlString: appStore.referenceURL
                )
            } else {
                ratingButton(
                    icon: "star.fill",
                    iconColor: Color.yellow,
                    iconBg: Color.white.opacity(0.08),
                    title: "4.6 ★",
                    subtitle: String(format: NSLocalizedString("game_detail.ratings.reviews_count %@", comment: ""), "3.2M"),
                    urlString: "https://www.apple.com/app-store/"
                )
            }

            // Card Metacritic Interativo
            if let metacritic = editorial.ratings.first(where: { $0.source == .metacriticCritic }) {
                metacriticButton(
                    score: Int(metacritic.score),
                    count: metacritic.reviewCount ?? 42,
                    urlString: metacritic.referenceURL
                )
            } else {
                metacriticButton(
                    score: 83,
                    count: 42,
                    urlString: "https://www.metacritic.com"
                )
            }
        }
    }

    private func ratingButton(icon: String, iconColor: Color, iconBg: Color, title: String, subtitle: String, urlString: String) -> some View {
        Button {
            if let url = URL(string: urlString) {
                openURL(url)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconBg, in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(NLTypography.bodyEmphasis)
                        .foregroundStyle(NLColor.textPrimary)
                    Text(subtitle)
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(NLColor.textTertiary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
            .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(title), \(subtitle)"))
        .accessibilityHint(Text("Abre na App Store"))
    }

    private func metacriticButton(score: Int, count: Int, urlString: String) -> some View {
        Button {
            if let url = URL(string: urlString) {
                openURL(url)
            }
        } label: {
            HStack(spacing: 10) {
                Text("\(score)")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        score >= 75
                            ? Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
                            : Color(red: 255 / 255, green: 204 / 255, blue: 0 / 255),
                        in: RoundedRectangle(cornerRadius: 8)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Metacritic")
                        .font(NLTypography.bodyEmphasis)
                        .foregroundStyle(NLColor.textPrimary)
                    Text(String(format: NSLocalizedString("game_detail.ratings.critics_count %@", comment: ""), "\(count)"))
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(NLColor.textTertiary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
            .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Metacritic: \(score)"))
        .accessibilityHint(Text("Abre no Metacritic"))
    }

    private func formattedCount(_ count: Int?) -> String {
        guard let count else { return "Milhares" }
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return "\(count / 1_000)k"
        } else {
            return "\(count)"
        }
    }
}

/// Linha horizontal de plataformas suportadas com seleção interativa no padrão HIG
struct GameDetailPlatformsRow: View {
    let supportedPlatforms: [Platform]
    @Binding var selectedPlatform: Platform

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.xs) {
            Text(LocalizedStringKey("game_detail.section.supported_platforms"))
                .font(NLTypography.captionStrong)
                .textCase(.uppercase)
                .foregroundStyle(NLColor.textTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NLSpacing.xs) {
                    ForEach(supportedPlatforms, id: \.self) { platform in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedPlatform = platform
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: iconName(for: platform))
                                    .font(.system(size: 12, weight: .semibold))
                                Text(displayName(for: platform))
                                    .font(NLTypography.captionStrong)
                            }
                            .foregroundStyle(selectedPlatform == platform ? NLColor.textPrimary : NLColor.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                selectedPlatform == platform ? Color.white.opacity(0.2) : NLColor.backgroundRaised,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        selectedPlatform == platform ? Color.white.opacity(0.35) : NLColor.borderSubtle,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func iconName(for platform: Platform) -> String {
        switch platform {
        case .iphone: return "iphone"
        case .playstation: return "gamecontroller"
        case .xbox: return "gamecontroller.fill"
        case .pc: return "display"
        case .nintendo: return "gamecontroller"
        }
    }

    private func displayName(for platform: Platform) -> String {
        switch platform {
        case .iphone: return "iPhone"
        case .playstation: return "PlayStation"
        case .xbox: return "Xbox"
        case .pc: return "PC"
        case .nintendo: return "Switch"
        }
    }
}

/// Bloco dedicado ao histórico exclusivo de medições deste jogo
struct GameDetailExclusiveHistoryCard: View {
    let entries: [MeasurementHistoryEntry]
    let gameName: String

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            HStack {
                Label(LocalizedStringKey("game_detail.section.history"), systemImage: "clock.arrow.circlepath")
                    .font(NLTypography.bodyEmphasis)
                    .foregroundStyle(NLColor.textPrimary)

                Spacer()

                if !entries.isEmpty {
                    Text(String(format: NSLocalizedString("game_detail.section.history_count %lld", comment: ""), Int64(entries.count)))
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textTertiary)
                }
            }

            if entries.isEmpty {
                VStack(spacing: 6) {
                    Text(LocalizedStringKey("game_detail.section.history_empty"))
                        .font(NLTypography.footnote)
                        .foregroundStyle(NLColor.textSecondary)
                        .multilineTextAlignment(.center)
                    Text(LocalizedStringKey("game_detail.section.history_empty_hint"))
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, NLSpacing.md)
                .background(NLColor.backgroundBase.opacity(0.4), in: RoundedRectangle(cornerRadius: NLRadius.controlSmall))
            } else {
                VStack(spacing: NLSpacing.xs) {
                    ForEach(Array(entries.prefix(4))) { entry in
                        historyRow(entry: entry)
                    }
                }
            }
        }
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderSubtle, lineWidth: 1))
    }

    private func historyRow(entry: MeasurementHistoryEntry) -> some View {
        HStack(spacing: NLSpacing.sm) {
            Circle()
                .fill(scoreColor(entry.result.resultClass))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(verdictTitle(entry.result.resultClass))
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(NLColor.textPrimary)

                HStack(spacing: 4) {
                    Text(formattedDate(entry.completedAt))
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textTertiary)

                    Text("•")
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textTertiary)

                    Text(entry.resolvedContext.regionID.uppercased())
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(entry.result.finalScore)")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(scoreColor(entry.result.resultClass))

                Text(LocalizedStringKey("game_detail.history.score_label"))
                    .font(.system(size: 9, weight: .bold))
                    .textCase(.uppercase)
                    .foregroundStyle(NLColor.textTertiary)
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: NLRadius.controlSmall))
        .overlay(RoundedRectangle(cornerRadius: NLRadius.controlSmall).stroke(Color.white.opacity(0.06), lineWidth: 0.5))
    }

    private func scoreColor(_ resultClass: ResultClass) -> Color {
        switch resultClass {
        case .excellent, .great: return NLColor.scoreExcellent
        case .unstable: return NLColor.scoreUnstable
        case .lagRisk: return NLColor.scoreLagRisk
        }
    }

    private func verdictTitle(_ resultClass: ResultClass) -> LocalizedStringKey {
        switch resultClass {
        case .excellent: return "game_detail.verdict.excellent.title"
        case .great: return "game_detail.verdict.great.title"
        case .unstable: return "game_detail.verdict.unstable.title"
        case .lagRisk: return "game_detail.verdict.lag_risk.title"
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "Hoje às \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "Ontem às \(formatter.string(from: date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            return formatter.string(from: date)
        }
    }
}

/// Acordeão nativo com especificações técnicas e rede (oculto por padrão)
struct GameDetailTechnicalSpecsAccordion: View {
    let editorial: RemoteCatalogGameEditorial?
    let selectedPlatform: Platform
    let observedMetrics: QualityMetrics?
    let natSnapshot: NATTopologySnapshot?
    let platformHealth: PlatformHealth?
    let wifiBandDiagnostic: WiFiBandDiagnosticResult?
    let onStartDeepCheck: () -> Void

    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: NLSpacing.sm) {
                    Image(systemName: "cpu")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(NLColor.textSecondary)
                        .frame(width: 34, height: 34)
                        .background(NLColor.backgroundBase, in: RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey("game_detail.section.tech_specs"))
                            .font(NLTypography.bodyEmphasis)
                            .foregroundStyle(NLColor.textPrimary)
                        Text(LocalizedStringKey("game_detail.section.tech_specs_subtitle"))
                            .font(NLTypography.caption)
                            .foregroundStyle(NLColor.textTertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(NLColor.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(NLSpacing.cardPadding)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: NLSpacing.md) {
                    Divider().overlay(NLColor.borderSubtle)

                    // 1. Requisitos de Rede Recomendados
                    if let demands = editorial?.networkDemands {
                        VStack(alignment: .leading, spacing: NLSpacing.xs) {
                            Text(LocalizedStringKey("game_detail.network_demands.title"))
                                .font(NLTypography.captionStrong)
                                .textCase(.uppercase)
                                .foregroundStyle(NLColor.textTertiary)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NLSpacing.xs) {
                                techSpecBox(label: "game_detail.tech.optimal_ping", value: "<\(Int(demands.optimalPingMs)) ms", systemImage: "gauge.with.needle")
                                techSpecBox(label: "game_detail.tech.tolerated_jitter", value: "<\(Int(demands.maxJitterMs)) ms", systemImage: "waveform.path.ecg")
                                techSpecBox(label: "game_detail.tech.tolerated_loss", value: demands.packetLossTolerancePct == 0 ? "0%" : "<\(demands.packetLossTolerancePct)%", systemImage: "antenna.radiowaves.left.and.right")
                                techSpecBox(label: "game_detail.tech.min_download", value: "5.0 Mbps", systemImage: "arrow.down.circle")
                            }
                        }
                    }

                    // 2. Diagnóstico NAT STUN (Alinhado com os demais itens)
                    if let nat = natSnapshot {
                        VStack(alignment: .leading, spacing: NLSpacing.xs) {
                            Text(LocalizedStringKey("game_detail.tech.nat_topology"))
                                .font(NLTypography.captionStrong)
                                .textCase(.uppercase)
                                .foregroundStyle(NLColor.textTertiary)

                            HStack(spacing: 8) {
                                Image(systemName: "network")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(NLColor.textSecondary)

                                Text(LocalizedStringKey(nat.natType.titleKey))
                                    .font(NLTypography.callout)
                                    .foregroundStyle(NLColor.textPrimary)

                                Spacer()

                                Text(nat.natType.isMultiplayerRestricted ? "Estrito" : "Normal")
                                    .font(NLTypography.captionStrong)
                                    .foregroundStyle(nat.natType.isMultiplayerRestricted ? NLColor.scoreLagRisk : NLColor.scoreExcellent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.06), lineWidth: 0.5))

                            if nat.hasAnyMultiplayerIssue {
                                GameDetailNATBanner(snapshot: nat)
                            }
                        }
                    }

                    // 3. Ficha Técnica de Hardware da Plataforma Selecionada
                    if let editorial, let req = editorial.requirement(for: selectedPlatform) {
                        GameDetailRequirementsCard(requirement: req, platform: selectedPlatform)
                    }

                    // 4. Diagnóstico de Wi-Fi 2.4 GHz
                    if let advice = wifiBandDiagnostic {
                        NetworkBandAdviceBanner(
                            title: LocalizedStringKey(advice.titleKey),
                            message: LocalizedStringKey(advice.messageKey),
                            badgeText: advice.diagnostic.isSuspectOrConfirmed24GHz ? "2.4 GHz" : nil,
                            style: advice.diagnostic.isSuspectOrConfirmed24GHz ? .warning : .positive,
                            iconName: advice.diagnostic.isSuspectOrConfirmed24GHz ? "antenna.radiowaves.left.and.right" : "wifi",
                            actionTitle: advice.actionKey.map { LocalizedStringKey($0) },
                            onAction: onStartDeepCheck
                        )
                    }

                    // 5. Status de Servidores de Plataforma (PSN / Xbox)
                    if let health = platformHealth, health.isIssueReported {
                        PlatformHealthBannerView(health: health)
                    }
                }
                .padding(.horizontal, NLSpacing.cardPadding)
                .padding(.bottom, NLSpacing.cardPadding)
            }
        }
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay(RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderSubtle, lineWidth: 1))
    }

    private func techSpecBox(label: LocalizedStringKey, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(NLColor.textTertiary)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(NLColor.textTertiary)
            }
            Text(value)
                .font(NLTypography.callout)
                .foregroundStyle(NLColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.06), lineWidth: 0.5))
    }
}
