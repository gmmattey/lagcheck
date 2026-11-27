import Foundation

/// Eventos canônicos de produto para validação comercial e funil de conversão do LagCheck.
/// Rigorosamente em conformidade com as diretrizes de privacidade da Apple (Privacy Manifest),
/// sem qualquer coleta de PII, IP, SSID, BSSID, informações de roteador ou amostras brutas de rede.
public enum AnalyticsEvent: Equatable, Sendable {
    case appOpen
    case gameSelected(gameID: String)
    case platformSelected(platform: String)
    case lagcheckStarted(gameID: String, platform: String, networkType: String, regionID: String)
    case lagcheckCompleted(gameID: String, platform: String, networkType: String, regionID: String, resultClass: String, durationSeconds: Double)
    case lagcheckInconclusive(gameID: String, platform: String, networkType: String, regionID: String, reason: String)
    case lagcheckCancelled(gameID: String, platform: String, networkType: String, regionID: String, reason: String, stage: String = "unknown")
    case resultViewed(gameID: String, platform: String, resultClass: String)
    case retestStarted(gameID: String, platform: String)
    case detailsViewed(gameID: String, platform: String)
    case recommendationsViewed(gameID: String, platform: String, count: Int)
    case resultShared(gameID: String, platform: String, channel: String)

    public var name: String {
        switch self {
        case .appOpen: "app_open"
        case .gameSelected: "game_selected"
        case .platformSelected: "platform_selected"
        case .lagcheckStarted: "lagcheck_started"
        case .lagcheckCompleted: "lagcheck_completed"
        case .lagcheckInconclusive: "lagcheck_inconclusive"
        case .lagcheckCancelled: "lagcheck_cancelled"
        case .resultViewed: "result_viewed"
        case .retestStarted: "retest_started"
        case .detailsViewed: "details_viewed"
        case .recommendationsViewed: "recommendations_viewed"
        case .resultShared: "result_shared"
        }
    }

    public var parameters: [String: String] {
        switch self {
        case .appOpen:
            return [:]
        case let .gameSelected(gameID):
            return ["game_id": gameID]
        case let .platformSelected(platform):
            return ["platform": platform]
        case let .lagcheckStarted(gameID, platform, networkType, regionID):
            return [
                "game_id": gameID,
                "platform": platform,
                "network_type": networkType,
                "region_id": regionID
            ]
        case let .lagcheckCompleted(gameID, platform, networkType, regionID, resultClass, duration):
            return [
                "game_id": gameID,
                "platform": platform,
                "network_type": networkType,
                "region_id": regionID,
                "result_class": resultClass,
                "duration_seconds": String(format: "%.1f", duration)
            ]
        case let .lagcheckInconclusive(gameID, platform, networkType, regionID, reason):
            return [
                "game_id": gameID,
                "platform": platform,
                "network_type": networkType,
                "region_id": regionID,
                "inconclusive_reason": reason
            ]
        case let .lagcheckCancelled(gameID, platform, networkType, regionID, reason, stage):
            return [
                "game_id": gameID,
                "platform": platform,
                "network_type": networkType,
                "region_id": regionID,
                "cancellation_reason": reason,
                "cancellation_stage": stage
            ]
        case let .resultViewed(gameID, platform, resultClass):
            return [
                "game_id": gameID,
                "platform": platform,
                "result_class": resultClass
            ]
        case let .retestStarted(gameID, platform):
            return [
                "game_id": gameID,
                "platform": platform
            ]
        case let .detailsViewed(gameID, platform):
            return [
                "game_id": gameID,
                "platform": platform
            ]
        case let .recommendationsViewed(gameID, platform, count):
            return [
                "game_id": gameID,
                "platform": platform,
                "recommendation_count": String(count)
            ]
        case let .resultShared(gameID, platform, channel):
            return [
                "game_id": gameID,
                "platform": platform,
                "share_channel": channel
            ]
        }
    }
}
