import FirebaseAnalytics
import FirebaseCore
import Foundation
import NolaggyApplication
import os

/// Adaptador do contrato canônico do app para o Firebase. Eventos automáticos
/// do SDK (por exemplo, first_open e session_start) não são duplicados aqui.
struct FirebaseAnalyticsTracker: AnalyticsTracker {
    func track(_ event: AnalyticsEvent) {
        guard let payload = FirebaseAnalyticsPayload(event: event) else { return }
        Analytics.logEvent(payload.name, parameters: payload.parameters)
    }
}

enum FirebaseAnalyticsRuntime {
    private static let logger = Logger(subsystem: "com.lagcheck.app", category: "FirebaseAnalytics")

    static func configure(collectionEnabled: Bool) {
        guard FirebaseApp.app() == nil else {
            Analytics.setAnalyticsCollectionEnabled(collectionEnabled)
            return
        }

        guard Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil else {
            logger.error("Firebase não configurado: GoogleService-Info.plist ausente no bundle principal")
            return
        }

        FirebaseApp.configure()
        Analytics.setAnalyticsCollectionEnabled(collectionEnabled)
    }

    static func setCollectionEnabled(_ enabled: Bool) {
        guard FirebaseApp.app() != nil else { return }
        Analytics.setAnalyticsCollectionEnabled(enabled)
    }
}

private struct FirebaseAnalyticsPayload {
    let name: String
    let parameters: [String: Any]

    init?(event: AnalyticsEvent) {
        switch event {
        case let .gameSelected(gameID):
            name = "game_selected"
            parameters = ["game_id": gameID]
        case let .lagcheckStarted(gameID, platform, networkType, regionID):
            name = "lagcheck_started"
            parameters = Self.contextParameters(gameID: gameID, platform: platform, networkType: networkType, regionID: regionID)
        case let .lagcheckCompleted(gameID, platform, networkType, regionID, resultClass, durationSeconds):
            name = "lagcheck_completed"
            parameters = Self.contextParameters(gameID: gameID, platform: platform, networkType: networkType, regionID: regionID)
                .merging([
                    "result_class": resultClass,
                    "duration_seconds": max(0, durationSeconds)
                ]) { _, new in new }
        case let .lagcheckInconclusive(gameID, platform, networkType, regionID, reason):
            name = "lagcheck_inconclusive"
            parameters = Self.contextParameters(gameID: gameID, platform: platform, networkType: networkType, regionID: regionID)
                .merging(["inconclusive_reason": reason]) { _, new in new }
        case let .lagcheckCancelled(gameID, platform, networkType, regionID, reason):
            name = "lagcheck_cancelled"
            parameters = Self.contextParameters(gameID: gameID, platform: platform, networkType: networkType, regionID: regionID)
                .merging(["cancellation_reason": reason]) { _, new in new }
        case let .resultViewed(gameID, platform, resultClass):
            name = "result_viewed"
            parameters = [
                "game_id": gameID,
                "game_platform": platform,
                "result_class": resultClass
            ]
        case let .retestStarted(gameID, platform):
            name = "retest_started"
            parameters = [
                "game_id": gameID,
                "game_platform": platform
            ]
        case .appOpen, .platformSelected:
            return nil
        }
    }

    private static func contextParameters(gameID: String, platform: String, networkType: String, regionID: String) -> [String: Any] {
        [
            "game_id": gameID,
            "game_platform": platform,
            "network_type": networkType,
            "region_id": regionID
        ]
    }
}
