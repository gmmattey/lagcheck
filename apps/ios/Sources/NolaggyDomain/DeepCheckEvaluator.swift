import Foundation
import LagCheckEngine

/// Métricas finais das duas fases independentes de um Deep Check.
public struct DeepCheckMetrics: Codable, Equatable, Sendable {
    public let rest: QualityMetrics
    public let load: QualityMetrics?
    public let loadImpact: DeepCheckLoadImpact?
    /// Pacotes reais da fase de carga, na ordem de envio (`nil` em entradas antigas do histórico).
    public let loadSamples: [ProbeSample]?

    public init(rest: QualityMetrics, load: QualityMetrics?, loadImpact: DeepCheckLoadImpact?, loadSamples: [ProbeSample]? = nil) {
        self.rest = rest
        self.load = load
        self.loadImpact = loadImpact
        self.loadSamples = loadSamples
    }
}

/// Como o delta de P50 deve ser apresentado no Deep Check.
public enum DeepCheckLoadImpactClassification: String, Codable, Equatable, Sendable {
    case descriptive
    case material
}

/// Nível de degradação sob carga multidimensional (Decisões 55 e 135).
public enum LoadDegradationTier: String, Codable, CaseIterable, Hashable, Sendable {
    case none
    case light
    case material
    case severe
}

/// Regra legada de impacto material (deep-load-impact-v1).
public enum DeepCheckLoadImpactMaterialityRuleV1 {
    public static var version: String {
        "deep-load-impact-v1"
    }
    public static var materialIncreaseMilliseconds: Double {
        20.0
    }

    public static func classify(increaseMilliseconds: Double) -> DeepCheckLoadImpactClassification {
        increaseMilliseconds >= materialIncreaseMilliseconds ? .material : .descriptive
    }
}

/// Regra multidimensional calibrada por perfil via motor compartilhado (Decisões 55, 134, 135 e 136).
public enum DeepCheckLoadImpactMaterialityRuleV2 {
    public static var version: String {
        EnginePolicyProvider.policy.ruleVersions["BATTLE_ROYALE_COMPETITIVE"]?["loadImpact"] ?? "deep-load-impact-v4"
    }

    public static func classify(
        profile: QualityProfileID,
        deltaP50: Double,
        deltaJitter: Double,
        deltaLoss: Double,
        deltaSpikes: Int
    ) -> LoadDegradationTier {
        let kmpProfile: QualityProfileId
        switch profile {
        case .battleRoyaleCompetitive:
            kmpProfile = QualityProfileId.battleRoyaleCompetitive
        case .mobileRealtime:
            kmpProfile = QualityProfileId.mobileRealtime
        case .casualRealtime:
            kmpProfile = QualityProfileId.casualRealtime
        }
        let kmpTier = DeepCheckLoadImpactRuleV4.shared.classify(
            profile: kmpProfile,
            deltaP50: deltaP50,
            deltaJitter: deltaJitter,
            deltaLoss: deltaLoss,
            deltaSpikes: Int32(deltaSpikes)
        )
        return LagCheckEngineBridge.toLoadTier(kmpTier.name)
    }
}

public enum BufferbloatRuleV1 {
    public static var version: String {
        "bufferbloat-grade-v1"
    }

    public static func evaluate(increaseMilliseconds: Double) -> BufferbloatGrade {
        BufferbloatGrade(rawValue: LagCheckEngine.shared.bufferbloatGrade(increaseMilliseconds: increaseMilliseconds)) ?? .f
    }
}

public enum BufferbloatGrade: String, Codable, Equatable, Sendable, CaseIterable {
    case aPlus = "A+"
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case f = "F"

    public init(increaseMilliseconds: Double) {
        self = BufferbloatRuleV1.evaluate(increaseMilliseconds: increaseMilliseconds)
    }
}

/// Comparação observada entre repouso e carga nas métricas multidimensionais. Não é score nem classe.
public struct DeepCheckLoadImpact: Codable, Equatable, Sendable {
    public let restP50Milliseconds: Double
    public let loadP50Milliseconds: Double
    public let increaseMilliseconds: Double
    public let ruleVersion: String
    public let classification: DeepCheckLoadImpactClassification
    public let tier: LoadDegradationTier
    public let deltaJitterMilliseconds: Double?
    public let deltaLossPercentage: Double?
    public let deltaSpikesCount: Int?
    public let bufferbloatGrade: BufferbloatGrade

    public init(
        restP50Milliseconds: Double,
        loadP50Milliseconds: Double,
        tier: LoadDegradationTier = .none,
        deltaJitterMilliseconds: Double? = nil,
        deltaLossPercentage: Double? = nil,
        deltaSpikesCount: Int? = nil,
        bufferbloatGrade: BufferbloatGrade? = nil,
        ruleVersion: String = DeepCheckLoadImpactMaterialityRuleV2.version
    ) {
        self.restP50Milliseconds = restP50Milliseconds
        self.loadP50Milliseconds = loadP50Milliseconds
        let increase = loadP50Milliseconds - restP50Milliseconds
        self.increaseMilliseconds = increase
        self.ruleVersion = ruleVersion
        self.tier = tier
        self.classification = DeepCheckLoadImpactMaterialityRuleV1.classify(increaseMilliseconds: increase)
        self.deltaJitterMilliseconds = deltaJitterMilliseconds
        self.deltaLossPercentage = deltaLossPercentage
        self.deltaSpikesCount = deltaSpikesCount
        self.bufferbloatGrade = bufferbloatGrade ?? BufferbloatGrade(increaseMilliseconds: increase)
    }

    public init(restP50Milliseconds: Double, loadP50Milliseconds: Double) {
        let increase = loadP50Milliseconds - restP50Milliseconds
        let classification = DeepCheckLoadImpactMaterialityRuleV1.classify(increaseMilliseconds: increase)
        let tier: LoadDegradationTier = (classification == .material) ? .material : .none
        self.init(
            restP50Milliseconds: restP50Milliseconds,
            loadP50Milliseconds: loadP50Milliseconds,
            tier: tier,
            deltaJitterMilliseconds: nil,
            deltaLossPercentage: nil,
            deltaSpikesCount: nil,
            ruleVersion: DeepCheckLoadImpactMaterialityRuleV2.version
        )
    }

    private enum CodingKeys: String, CodingKey {
        case restP50Milliseconds
        case loadP50Milliseconds
        case increaseMilliseconds
        case ruleVersion
        case classification
        case tier
        case deltaJitterMilliseconds
        case deltaLossPercentage
        case deltaSpikesCount
        case bufferbloatGrade
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        restP50Milliseconds = try container.decode(Double.self, forKey: .restP50Milliseconds)
        loadP50Milliseconds = try container.decode(Double.self, forKey: .loadP50Milliseconds)
        increaseMilliseconds = try container.decode(Double.self, forKey: .increaseMilliseconds)
        ruleVersion = try container.decodeIfPresent(String.self, forKey: .ruleVersion)
            ?? DeepCheckLoadImpactMaterialityRuleV1.version
        let legacyClassification = try container.decodeIfPresent(DeepCheckLoadImpactClassification.self, forKey: .classification)
            ?? DeepCheckLoadImpactMaterialityRuleV1.classify(increaseMilliseconds: increaseMilliseconds)
        classification = legacyClassification
        tier = try container.decodeIfPresent(LoadDegradationTier.self, forKey: .tier)
            ?? (legacyClassification == .material ? .material : .none)
        deltaJitterMilliseconds = try container.decodeIfPresent(Double.self, forKey: .deltaJitterMilliseconds)
        deltaLossPercentage = try container.decodeIfPresent(Double.self, forKey: .deltaLossPercentage)
        deltaSpikesCount = try container.decodeIfPresent(Int.self, forKey: .deltaSpikesCount)
        bufferbloatGrade = try container.decodeIfPresent(BufferbloatGrade.self, forKey: .bufferbloatGrade) ?? BufferbloatGrade(increaseMilliseconds: increaseMilliseconds)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(restP50Milliseconds, forKey: .restP50Milliseconds)
        try container.encode(loadP50Milliseconds, forKey: .loadP50Milliseconds)
        try container.encode(increaseMilliseconds, forKey: .increaseMilliseconds)
        try container.encode(ruleVersion, forKey: .ruleVersion)
        try container.encode(classification, forKey: .classification)
        try container.encode(tier, forKey: .tier)
        try container.encodeIfPresent(deltaJitterMilliseconds, forKey: .deltaJitterMilliseconds)
        try container.encodeIfPresent(deltaLossPercentage, forKey: .deltaLossPercentage)
        try container.encodeIfPresent(deltaSpikesCount, forKey: .deltaSpikesCount)
        try container.encode(bufferbloatGrade, forKey: .bufferbloatGrade)
    }
}

/// Resultado concluído do Deep Check.
public struct DeepCheckResult: Codable, Equatable, Sendable {
    public let restResult: QualityResult
    public let metrics: DeepCheckMetrics

    public init(restResult: QualityResult, metrics: DeepCheckMetrics) {
        self.restResult = restResult
        self.metrics = metrics
    }
}

public enum DeepCheckEvaluation: Equatable, Sendable {
    case completed(DeepCheckResult)
    case inconclusive(reason: InconclusiveReason, diagnostics: QualityMetrics)
}

/// Avalia o Deep Check sem combinar as séries UDP nem recalcular o score de repouso via motor compartilhado.
public enum DeepCheckEvaluator {
    public static func evaluate(
        restSamples: [ProbeSample],
        loadSamples: [ProbeSample]?,
        profile: QualityProfileID
    ) -> DeepCheckEvaluation {
        let restSampleDtos = restSamples.map { LagCheckEngineBridge.toSampleDTO($0) }

        // 1. Avalia fase de repouso isoladamente (score puro de repouso)
        let restRequest = EngineRequestDTO(
            source: "APP_UDP",
            profile: LagCheckEngineBridge.toProfileKey(profile),
            rest: restSampleDtos,
            load: nil,
            loadTransfer: "NOT_RUN",
            gateway: nil,
            wifiBand: nil,
            nat: nil,
            serverArchitecture: "DEDICATED_SERVER",
            gameId: nil,
            uploadMbps: nil
        )

        let restResponse = LagCheckEngineBridge.evaluate(request: restRequest)

        if restResponse.verdict == "INCONCLUSIVE" {
            let reason: InconclusiveReason = restResponse.inconclusiveReason == "POOR_SAMPLE_QUALITY"
                ? .poorSampleQuality
                : .insufficientUDPResponses
            return .inconclusive(
                reason: reason,
                diagnostics: LagCheckEngineBridge.mapMetrics(restResponse.rest)
            )
        }

        let restMetrics = LagCheckEngineBridge.mapMetrics(restResponse.rest)
        let restScore = restResponse.score ?? 0
        let restClass = LagCheckEngineBridge.toResultClass(restScore)

        let restResult = QualityResult(
            metrics: restMetrics,
            rawScore: restScore,
            finalScore: restScore,
            resultClass: restClass,
            appliedGuardrails: [],
            samples: restSamples
        )

        guard let loadSamples, !loadSamples.isEmpty else {
            // Um Check Completo sem a fase de carga não pode virar um resultado
            // completo de repouso. O repouso é preservado nos diagnósticos, mas
            // sem share, PDF, widget ou histórico conclusivo.
            return .inconclusive(reason: .insufficientUDPResponses, diagnostics: restMetrics)
        }

        guard loadSamples.filter(\.isValidResponse).count >= ProbeAcceptancePolicy.minimumValidResponses else {
            return .inconclusive(reason: .poorSampleQuality, diagnostics: restMetrics)
        }

        // 2. Avalia fase de carga
        let loadSampleDtos = loadSamples.map { LagCheckEngineBridge.toSampleDTO($0) }
        let fullRequest = EngineRequestDTO(
            source: "APP_UDP",
            profile: LagCheckEngineBridge.toProfileKey(profile),
            rest: restSampleDtos,
            load: loadSampleDtos,
            loadTransfer: "MEASURED",
            gateway: nil,
            wifiBand: nil,
            nat: nil,
            serverArchitecture: "DEDICATED_SERVER",
            gameId: nil,
            uploadMbps: nil
        )

        let fullResponse = LagCheckEngineBridge.evaluate(request: fullRequest)

        if fullResponse.verdict == "INCONCLUSIVE" {
            let reason: InconclusiveReason = fullResponse.inconclusiveReason == "POOR_SAMPLE_QUALITY"
                ? .poorSampleQuality
                : .insufficientUDPResponses
            return .inconclusive(
                reason: reason,
                diagnostics: fullResponse.load != nil
                    ? LagCheckEngineBridge.mapMetrics(fullResponse.load!)
                    : restMetrics
            )
        }

        if let loadDto = fullResponse.load, let impactDto = fullResponse.loadImpact {
            let loadMetrics = LagCheckEngineBridge.mapMetrics(loadDto)
            let tier = LagCheckEngineBridge.toLoadTier(impactDto.tier)
            let grade = BufferbloatGrade(rawValue: impactDto.bufferbloatGrade) ?? .f
            let ruleVer = fullResponse.ruleVersions["loadImpact"] ?? DeepCheckLoadImpactMaterialityRuleV2.version

            let impact = DeepCheckLoadImpact(
                restP50Milliseconds: restMetrics.p50Milliseconds ?? 0,
                loadP50Milliseconds: loadMetrics.p50Milliseconds ?? 0,
                tier: tier,
                deltaJitterMilliseconds: impactDto.deltaJitterMilliseconds,
                deltaLossPercentage: impactDto.deltaLossPercentage,
                deltaSpikesCount: impactDto.deltaSpikesCount,
                bufferbloatGrade: grade,
                ruleVersion: ruleVer
            )
            return .completed(
                DeepCheckResult(
                    restResult: restResult,
                    metrics: DeepCheckMetrics(rest: restMetrics, load: loadMetrics, loadImpact: impact, loadSamples: loadSamples)
                )
            )
        } else {
            return .completed(
                DeepCheckResult(
                    restResult: restResult,
                    metrics: DeepCheckMetrics(rest: restMetrics, load: nil, loadImpact: nil)
                )
            )
        }
    }

    public static func evaluateBattleRoyaleCompetitive(
        restSamples: [ProbeSample],
        loadSamples: [ProbeSample]?
    ) -> DeepCheckEvaluation {
        evaluate(restSamples: restSamples, loadSamples: loadSamples, profile: .battleRoyaleCompetitive)
    }

    public static func evaluateMobileRealtime(
        restSamples: [ProbeSample],
        loadSamples: [ProbeSample]?
    ) -> DeepCheckEvaluation {
        evaluate(restSamples: restSamples, loadSamples: loadSamples, profile: .mobileRealtime)
    }

    public static func evaluateCasualRealtime(
        restSamples: [ProbeSample],
        loadSamples: [ProbeSample]?
    ) -> DeepCheckEvaluation {
        evaluate(restSamples: restSamples, loadSamples: loadSamples, profile: .casualRealtime)
    }
}
