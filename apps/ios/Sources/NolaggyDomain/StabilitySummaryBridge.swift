import Foundation
import LagCheckEngine

public struct StabilityHistoryEntryDTO: Codable, Equatable, Sendable {
    public let capturedAtEpochMs: Int64
    public let pingMs: Double?
    public let jitterMs: Double?
    public let packetLossPercentage: Double?
    public let loadDeltaMs: Double?
    public let verdict: String?
    public let validResponseCount: Int
    public let gameId: String?
    public let gameTitle: String?
    public let platform: String?
    public let declaredExternalLink: String?
    public let networkType: String?
    public let regionId: String?
    public let ruleVersion: String?

    public init(
        capturedAtEpochMs: Int64,
        pingMs: Double?,
        jitterMs: Double?,
        packetLossPercentage: Double?,
        loadDeltaMs: Double?,
        verdict: String?,
        validResponseCount: Int,
        gameId: String?,
        gameTitle: String?,
        platform: String?,
        declaredExternalLink: String?,
        networkType: String?,
        regionId: String?,
        ruleVersion: String?
    ) {
        self.capturedAtEpochMs = capturedAtEpochMs
        self.pingMs = pingMs
        self.jitterMs = jitterMs
        self.packetLossPercentage = packetLossPercentage
        self.loadDeltaMs = loadDeltaMs
        self.verdict = verdict
        self.validResponseCount = validResponseCount
        self.gameId = gameId
        self.gameTitle = gameTitle
        self.platform = platform
        self.declaredExternalLink = declaredExternalLink
        self.networkType = networkType
        self.regionId = regionId
        self.ruleVersion = ruleVersion
    }
}

public struct StabilitySummaryRequestDTO: Codable, Equatable, Sendable {
    public let entries: [StabilityHistoryEntryDTO]
    public let windowDays: Int
    public let nowEpochMs: Int64
    public let gameIdFilter: String?
    public let networkFilter: String?
    public let maxPoints: Int

    public init(
        entries: [StabilityHistoryEntryDTO],
        windowDays: Int = 14,
        nowEpochMs: Int64 = Int64((Date().timeIntervalSince1970 * 1000.0).rounded()),
        gameIdFilter: String? = nil,
        networkFilter: String? = nil,
        maxPoints: Int = 30
    ) {
        self.entries = entries
        self.windowDays = windowDays
        self.nowEpochMs = nowEpochMs
        self.gameIdFilter = gameIdFilter
        self.networkFilter = networkFilter
        self.maxPoints = maxPoints
    }
}

public struct StabilityPointDTO: Codable, Equatable, Sendable {
    public let capturedAtEpochMs: Int64
    public let pingMs: Double
    public let jitterMs: Double?
    public let packetLossPercentage: Double?
    public let loadDeltaMs: Double?
    public let verdict: String
    public let gameId: String?
    public let gameTitle: String?
    public let networkType: String?
    public let regionId: String?
    public let segmentIndex: Int
    public let connectToPrevious: Bool
}

public struct StabilityRingMetricDTO: Codable, Equatable, Sendable {
    public let value: Double?
    public let tone: String
    public let fillRatio: Double
}

public struct StabilityRingsDTO: Codable, Equatable, Sendable {
    public let ping: StabilityRingMetricDTO
    public let jitter: StabilityRingMetricDTO
    public let loss: StabilityRingMetricDTO
    public let load: StabilityRingMetricDTO
}

public struct StabilitySummaryResponseDTO: Codable, Equatable, Sendable {
    public let ruleVersion: String
    public let windowDays: Int
    public let points: [StabilityPointDTO]
    public let canDrawCurve: Bool
    public let hasSummary: Bool
    public let hasMixedContexts: Bool
    public let availableNetworks: [String]
    public let summaryNetworkType: String?
    public let summaryRegionId: String?
    public let totalComparableCount: Int
    public let readyCount: Int
    public let cautionCount: Int
    public let badCount: Int
    public let inconclusiveCount: Int
    public let stabilityPercentage: Int?
    public let stabilityTone: String
    public let headlineKey: String
    public let minPingMs: Double?
    public let avgPingMs: Double?
    public let maxPingMs: Double?
    public let rings: StabilityRingsDTO?
    public let latest: StabilityPointDTO?

    public static func empty(windowDays: Int = 14) -> StabilitySummaryResponseDTO {
        StabilitySummaryResponseDTO(
            ruleVersion: "stability-summary-v2",
            windowDays: windowDays,
            points: [],
            canDrawCurve: false,
            hasSummary: false,
            hasMixedContexts: false,
            availableNetworks: [],
            summaryNetworkType: nil,
            summaryRegionId: nil,
            totalComparableCount: 0,
            readyCount: 0,
            cautionCount: 0,
            badCount: 0,
            inconclusiveCount: 0,
            stabilityPercentage: nil,
            stabilityTone: "UNKNOWN",
            headlineKey: "stability.headline.empty",
            minPingMs: nil,
            avgPingMs: nil,
            maxPingMs: nil,
            rings: nil,
            latest: nil
        )
    }
}

/// Avalia a evolução de estabilidade no histórico do iOS usando o motor compartilhado KMP (Decisão 143).
public enum StabilityHistoryAdapter {
    public static func evaluate(
        entries: [MeasurementHistoryEntry],
        windowDays: Int = 14,
        gameIdFilter: String? = nil,
        networkFilter: String? = nil,
        now: Date = Date(),
        maxPoints: Int = 30,
        gameName: (MeasurementHistoryEntry) -> String = { $0.resolvedContext.context.gameID }
    ) -> StabilitySummaryResponseDTO {
        let mapped: [StabilityHistoryEntryDTO] = entries.map { entry in
            let loadDelta = entry.deepCheck?.metrics.loadImpact?.increaseMilliseconds ?? {
                guard let loadP50 = entry.deepCheck?.metrics.load?.p50Milliseconds,
                      let restP50 = entry.deepCheck?.metrics.rest.p50Milliseconds else {
                    return nil
                }
                return loadP50 - restP50
            }()
            return StabilityHistoryEntryDTO(
                capturedAtEpochMs: Int64((entry.completedAt.timeIntervalSince1970 * 1000.0).rounded()),
                pingMs: entry.metrics?.p50Milliseconds,
                jitterMs: entry.metrics?.jitterMilliseconds,
                packetLossPercentage: entry.metrics?.packetLossPercentage,
                loadDeltaMs: loadDelta,
                verdict: verdictKey(for: entry),
                validResponseCount: entry.metrics?.validResponseCount ?? 0,
                gameId: entry.resolvedContext.context.gameID,
                gameTitle: gameName(entry),
                platform: platformKey(entry.resolvedContext.context.platform),
                declaredExternalLink: entry.resolvedContext.context.declaredExternalLink?.rawValue.uppercased(),
                networkType: entry.resolvedContext.observedPhoneNetwork?.rawValue.uppercased(),
                regionId: entry.resolvedContext.regionID,
                ruleVersion: entry.profileRuleVersion
            )
        }

        let request = StabilitySummaryRequestDTO(
            entries: mapped,
            windowDays: windowDays,
            nowEpochMs: Int64((now.timeIntervalSince1970 * 1000.0).rounded()),
            gameIdFilter: gameIdFilter,
            networkFilter: networkFilter,
            maxPoints: maxPoints
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(request),
              let requestJson = String(data: data, encoding: .utf8) else {
            return .empty(windowDays: windowDays)
        }

        let responseJson = LagCheckEngine.shared.stabilitySummary(requestJson: requestJson)
        guard let responseData = responseJson.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(StabilitySummaryResponseDTO.self, from: responseData) else {
            return .empty(windowDays: windowDays)
        }
        return decoded
    }

    private static func verdictKey(for entry: MeasurementHistoryEntry) -> String {
        if entry.isInconclusive {
            return "INCONCLUSIVE"
        }
        switch entry.readinessVerdict {
        case .ready: return "READY"
        case .caution: return "CAUTION"
        case .notReady: return "NOT_READY"
        case .inconclusive, .none: return "INCONCLUSIVE"
        }
    }

    private static func platformKey(_ platform: Platform) -> String {
        switch platform {
        case .iphone: return "MOBILE"
        case .pc: return "PC"
        case .playstation, .xbox, .nintendo: return "CONSOLE"
        }
    }
}
