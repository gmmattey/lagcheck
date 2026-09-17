import Foundation
import NolaggyDomain

/// Estado pronto para apresentação. Não carrega métricas parciais para resultado inconclusivo ou cancelado.
public enum QuickCheckPresentation: Equatable, Sendable {
    case context
    case measuring
    case result(QualityResult)
    case inconclusive
    case cancelled(MeasurementCancellationReason)
}

public enum QuickCheckPresentationMapper {
    public static func map(_ state: MeasurementSessionState) -> QuickCheckPresentation {
        switch state {
        case .idle:
            .context
        case .measuring:
            .measuring
        case let .completed(_, evaluation, _):
            switch evaluation {
            case .inconclusive:
                .inconclusive
            case let .completed(result):
                .result(result)
            }
        case let .cancelled(_, reason):
            .cancelled(reason)
        }
    }
}
