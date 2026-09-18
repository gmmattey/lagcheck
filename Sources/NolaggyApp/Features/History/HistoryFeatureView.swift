import SwiftUI
import NolaggyDesign
import NolaggyDomain

/// Histórico local por jogo (doc 01 §7.7): último score, evolução recente e,
/// após dados suficientes, média de sete dias. Nunca é apresentado como modal.
struct HistoryView: View {
    let entries: [MeasurementHistoryEntry]
    let gameName: (MeasurementHistoryEntry) -> String
    let retry: (MeasurementHistoryEntry) -> Void
    let returnToHome: () -> Void
    let openSettings: () -> Void
    var showsBackHeader: Bool = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NLSpacing.lg) {
                if entries.isEmpty {
                    VStack(spacing: NLSpacing.md) {
                        Text("history.empty")
                            .font(NLTypography.body)
                            .foregroundStyle(NLColor.textSecondary)
                        PrimaryButton(title: "history.first_check", action: returnToHome)
                    }
                    .frame(maxWidth: .infinity, minHeight: NLSizing.emptyStateMinHeight)
                } else {
                    historySummary
                    ForEach(entries) { entry in
                        VStack(spacing: NLSpacing.sm) {
                            NavigationLink {
                                MeasurementDetailsView(entry: entry, samples: [])
                            } label: {
                                HistoryCard(entry: entry, gameName: gameName(entry))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(historyAccessibilityLabel(entry))
                            PrimaryButton(title: retryTitle(entry), style: .secondaryOutline, action: { retry(entry) })
                                .accessibilityLabel(Text(retryTitle(entry)))
                        }
                    }
                }
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .padding(.vertical, NLSpacing.lg)
        }
        .background(NolaggyScreenBackground())
        .navigationTitle(Text("history.title"))
        .navigationBarTitleDisplayMode(showsBackHeader ? .inline : .large)
        .toolbar {
            if showsBackHeader {
                ToolbarItem(placement: .topBarLeading) {
                    NolaggyBackButton(action: returnToHome, accessibilityIdentifier: "history-back")
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var historySummary: some View {
        if let summary = MeasurementHistorySummary(entries: entries) {
            VStack(alignment: .leading, spacing: NLSpacing.xs) {
                Text(gameName(summary.latest))
                    .font(NLTypography.headline)
                    .foregroundStyle(NLColor.textPrimary)
                Text(String(format: NSLocalizedString("home.last_score %lld", comment: ""), summary.latest.result.finalScore))
                    .font(NLTypography.callout)
                    .foregroundStyle(NLColor.textSecondary)
                if let average = summary.sevenDayAverageScore {
                    Text(String(format: NSLocalizedString("home.seven_day_average %lld", comment: ""), average))
                        .font(NLTypography.footnote)
                        .foregroundStyle(NLColor.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func retryTitle(_ entry: MeasurementHistoryEntry) -> LocalizedStringKey {
        LocalizedStringKey(String(format: NSLocalizedString("history.retry %@", comment: ""), gameName(entry)))
    }

    private func historyAccessibilityLabel(_ entry: MeasurementHistoryEntry) -> String {
        let type = NSLocalizedString(entry.kind == .deep ? "history.deep_check_short" : "history.quick_check", comment: "")
        let classificationKey: String = switch entry.result.resultClass {
        case .excellent: "quick_check.result.headline.excellent"
        case .great: "quick_check.result.headline.great"
        case .unstable: "quick_check.result.headline.unstable"
        case .lagRisk: "quick_check.result.headline.lag_risk"
        }
        return String(
            format: NSLocalizedString("history.entry_accessibility", comment: ""),
            entry.completedAt.formatted(date: .abbreviated, time: .shortened),
            type,
            entry.result.finalScore,
            NSLocalizedString(classificationKey, comment: "")
        )
    }
}

private struct HistoryCard: View {
    let entry: MeasurementHistoryEntry
    let gameName: String

    var body: some View {
        HStack(spacing: NLSpacing.md) {
            GameArtwork(image: nil, sourceRecordID: nil, title: gameName)
                .frame(width: NLSizing.compactGameArtworkSide, height: NLSizing.compactGameArtworkSide)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: NLSpacing.xs) {
                Text(gameName)
                    .font(NLTypography.bodyEmphasis)
                    .foregroundStyle(NLColor.textPrimary)
                Text(entry.completedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
                if entry.kind == .deep {
                    Text("history.deep_check")
                        .font(NLTypography.footnote.weight(.semibold))
                        .foregroundStyle(NLColor.accentPrimary)
                    if let impact = entry.deepCheck?.metrics.loadImpact {
                        Text(String(format: NSLocalizedString("history.deep_check_delta", comment: ""), Int(impact.increaseMilliseconds.rounded())))
                            .font(NLTypography.footnote)
                            .foregroundStyle(NLColor.textSecondary)
                    } else {
                        Text("deep_check.result.load_unavailable")
                            .font(NLTypography.footnote)
                            .foregroundStyle(NLColor.textSecondary)
                    }
                } else {
                    Text("history.quick_check")
                        .font(NLTypography.footnote)
                        .foregroundStyle(NLColor.textSecondary)
                }
            }
            Spacer(minLength: NLSpacing.sm)
            Text("\(entry.result.finalScore)")
                .font(NLTypography.bodyEmphasis)
                .foregroundStyle(scoreColor)
                .frame(minWidth: NLSizing.touchTarget, minHeight: NLSizing.touchTarget)
                .background(NLColor.backgroundBase, in: Capsule())
                .overlay { Capsule().stroke(scoreColor, lineWidth: NLStroke.hairline) }
        }
        .padding(NLSpacing.cardPadding)
        .frame(maxWidth: .infinity, minHeight: NLSizing.historyCardMinHeight, alignment: .leading)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay { RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline) }
    }

    private var classification: NLScoreClassification {
        switch entry.result.resultClass {
        case .excellent: .excellent
        case .great: .great
        case .unstable: .unstable
        case .lagRisk: .lagRisk
        }
    }

    private var scoreColor: Color {
        switch classification {
        case .excellent: NLColor.scoreExcellent
        case .great: NLColor.accentPrimary
        case .unstable: NLColor.scoreUnstable
        case .lagRisk: NLColor.scoreLagRisk
        }
    }

    private var classificationLabel: LocalizedStringKey {
        switch entry.result.resultClass {
        case .excellent: "quick_check.result.headline.excellent"
        case .great: "quick_check.result.headline.great"
        case .unstable: "quick_check.result.headline.unstable"
        case .lagRisk: "quick_check.result.headline.lag_risk"
        }
    }
}
