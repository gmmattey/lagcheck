import SwiftUI
import NolaggyApplication
import NolaggyDesign

/// Estados sem score: inconclusivo (menos de 10 respostas UDP válidas) e
/// cancelado (mudança de rede, segundo plano ou ação do usuário).
extension QuickCheckFeatureView {
    @ViewBuilder
    func statusView(kind: StatusKind) -> some View {
        VStack(spacing: NLSpacing.xl) {
            header(title: nil, showsBack: true)
            Spacer(minLength: NLSpacing.xs)
            VStack(spacing: NLSpacing.md) {
                Text("quick_check.status.context")
                    .font(NLTypography.subheadline)
                    .foregroundStyle(NLColor.textPrimary)
                Text("quick_check.region.reference")
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textTertiary)
                StatusMessage(
                    kind: kind.messageKind,
                    message: kind.message,
                    actionTitle: kind.actionTitle,
                    action: restart
                )
            }
            Spacer()
        }
        .padding(.horizontal, NLSpacing.screenMarginHorizontal)
    }
}

enum StatusKind {
    case inconclusive
    case cancelled(MeasurementCancellationReason)

    var messageKind: StatusMessage.Kind {
        switch self {
        case .inconclusive: .inconclusive
        case .cancelled: .cancelled
        }
    }

    var message: LocalizedStringKey {
        switch self {
        case .inconclusive:
            "quick_check.inconclusive.message"
        case .cancelled(.networkPathChanged):
            "quick_check.cancelled.network_changed"
        case .cancelled(.appEnteredBackground):
            "quick_check.cancelled.background"
        case .cancelled:
            "quick_check.cancelled.user"
        }
    }

    var actionTitle: LocalizedStringKey {
        switch self {
        case .inconclusive: "quick_check.retry"
        case .cancelled: "quick_check.restart"
        }
    }
}
