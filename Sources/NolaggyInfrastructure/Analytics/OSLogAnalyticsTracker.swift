import Foundation
import os
import NolaggyApplication

/// Implementação do `AnalyticsTracker` baseada no subsistema de logs nativo do iOS (`os.Logger`).
/// Oferece rastreabilidade no console e em builds de teste/release sem custo operacional e sem dependências externas.
public struct OSLogAnalyticsTracker: AnalyticsTracker {
    private let logger: Logger

    public init(subsystem: String = "com.lagcheck.app", category: String = "Analytics") {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func track(_ event: AnalyticsEvent) {
        let paramsString = event.parameters
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        if paramsString.isEmpty {
            logger.info("event: \(event.name, privacy: .public)")
        } else {
            logger.info("event: \(event.name, privacy: .public) \(paramsString, privacy: .public)")
        }
    }
}
