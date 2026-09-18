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
