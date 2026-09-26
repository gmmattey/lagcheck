import Foundation

/// Métricas finais das duas fases independentes de um Deep Check.
/// A fase sob carga é opcional: uma falha da transferência HTTP, ou dados UDP
/// insuficientes nessa fase, não altera o resultado válido em repouso.
public struct DeepCheckMetrics: Codable, Equatable, Sendable {
    public let rest: QualityMetrics
    public let load: QualityMetrics?
    public let loadImpact: DeepCheckLoadImpact?

    public init(rest: QualityMetrics, load: QualityMetrics?, loadImpact: DeepCheckLoadImpact?) {
        self.rest = rest
        self.load = load
        self.loadImpact = loadImpact
    }
}

/// Como o delta de P50 deve ser apresentado no Deep Check. Esta classificação
/// descreve exclusivamente o impacto observado; não é score, nem classe de
/// qualidade da conexão.
public enum DeepCheckLoadImpactClassification: String, Codable, Equatable, Sendable {
    /// O delta continua visível, mas ficou abaixo do limiar de materialidade.
    case descriptive
    /// O delta atingiu o limiar de materialidade da regra registrada.
    case material
}

/// Regra determinística e versionada para classificar somente o impacto do
/// Deep Check. O corte usa o delta bruto de P50, antes de qualquer arredondamento
/// de apresentação, para que a decisão não varie por locale ou UI.
/// Nível de degradação sob carga multidimensional (Decisão 55).
public enum LoadDegradationTier: String, Codable, CaseIterable, Hashable, Sendable {
    case none
    case light
    case material
    case severe
}

/// Regra determinística e versionada para classificar somente o impacto do
/// Deep Check. O corte usa o delta bruto de P50, antes de qualquer arredondamento
/// de apresentação, para que a decisão não varie por locale ou UI.
public enum DeepCheckLoadImpactMaterialityRuleV1 {
    public static let version = "deep-load-impact-v1"
    public static let materialIncreaseMilliseconds = 20.0

    public static func classify(increaseMilliseconds: Double) -> DeepCheckLoadImpactClassification {
        increaseMilliseconds >= materialIncreaseMilliseconds ? .material : .descriptive
    }
}

/// Regra multidimensional e calibrada por perfil para bufferbloat sob carga (Decisão 55).
public enum DeepCheckLoadImpactMaterialityRuleV2 {
    public static let version = "deep-load-impact-v2"

    public static func classify(
        profile: QualityProfileID,
        deltaP50: Double,
        deltaJitter: Double,
        deltaLoss: Double,
        deltaSpikes: Int
    ) -> LoadDegradationTier {
        switch profile {
        case .battleRoyaleCompetitive:
            if deltaP50 > 40 || deltaJitter > 20 || deltaLoss > 5.0 || deltaSpikes >= 4 {
                return .severe
            }
            if deltaP50 > 18 || deltaJitter > 8 || deltaLoss > 2.0 || deltaSpikes >= 2 {
                return .material
            }
            if deltaP50 > 8 || deltaJitter > 4 || deltaLoss > 1.0 || deltaSpikes >= 1 {
                return .light
            }
            return .none

        case .mobileRealtime:
            if deltaP50 > 55 || deltaJitter > 25 || deltaLoss > 7.0 || deltaSpikes >= 5 {
                return .severe
            }
            if deltaP50 > 25 || deltaJitter > 12 || deltaLoss > 3.0 || deltaSpikes >= 2 {
                return .material
            }
            if deltaP50 > 12 || deltaJitter > 6 || deltaLoss > 1.5 || deltaSpikes >= 1 {
                return .light
            }
            return .none

        case .casualRealtime:
            if deltaP50 > 80 || deltaJitter > 35 || deltaLoss > 10.0 {
                return .severe
            }
            if deltaP50 > 40 || deltaJitter > 18 || deltaLoss > 5.0 {
                return .material
            }
            if deltaP50 > 20 || deltaJitter > 10 || deltaLoss > 2.0 {
                return .light
            }
            return .none
        }
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

    public init(
        restP50Milliseconds: Double,
        loadP50Milliseconds: Double,
        tier: LoadDegradationTier = .none,
        deltaJitterMilliseconds: Double? = nil,
        deltaLossPercentage: Double? = nil,
        deltaSpikesCount: Int? = nil,
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
    }

    public init(restP50Milliseconds: Double, loadP50Milliseconds: Double) {
        let increase = loadP50Milliseconds - restP50Milliseconds
        let tier: LoadDegradationTier = (increase >= DeepCheckLoadImpactMaterialityRuleV1.materialIncreaseMilliseconds) ? .material : .none
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
    }
}

/// Resultado concluído do Deep Check. A classificação e o score pertencem
/// exclusivamente à fase de repouso.
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

/// Avalia o Deep Check sem combinar as séries UDP nem recalcular o score de
/// repouso. Esta fronteira não conhece Wi-Fi, HTTP, ciclo de vida ou UI.
public enum DeepCheckEvaluator {
    /// Ponto de entrada único para todos os perfis publicados. A Application
    /// fornece apenas o perfil já resolvido pelo catálogo; limites, guardrails
    /// e score continuam exclusivamente no domínio.
    public static func evaluate(
        restSamples: [ProbeSample],
        loadSamples: [ProbeSample]?,
        profile: QualityProfileID
    ) -> DeepCheckEvaluation {
        let restEvaluation = QualityEvaluator.evaluate(samples: restSamples, profile: profile)

        guard case let .completed(restResult) = restEvaluation else {
            guard case let .inconclusive(reason, diagnostics) = restEvaluation else {
                preconditionFailure("Quality evaluation must be completed or inconclusive.")
            }
            return .inconclusive(reason: reason, diagnostics: diagnostics)
        }

        guard let loadSamples,
              case let .completed(loadResult) = QualityEvaluator.evaluate(samples: loadSamples, profile: profile),
              let restP50 = restResult.metrics.p50Milliseconds,
              let loadP50 = loadResult.metrics.p50Milliseconds else {
            return .completed(
                DeepCheckResult(
                    restResult: restResult,
                    metrics: DeepCheckMetrics(rest: restResult.metrics, load: nil, loadImpact: nil)
                )
            )
        }

        let deltaP50 = max(0, loadP50 - restP50)
        let restJitter = restResult.metrics.jitterMilliseconds ?? 0
        let loadJitter = loadResult.metrics.jitterMilliseconds ?? 0
        let deltaJitter = max(0, loadJitter - restJitter)
        let restLoss = restResult.metrics.packetLossPercentage
        let loadLoss = loadResult.metrics.packetLossPercentage
        let deltaLoss = max(0, loadLoss - restLoss)
        let restSpikes = restResult.metrics.spikeCount
        let loadSpikes = loadResult.metrics.spikeCount
        let deltaSpikes = max(0, loadSpikes - restSpikes)

        let tier = DeepCheckLoadImpactMaterialityRuleV2.classify(
            profile: profile,
            deltaP50: deltaP50,
            deltaJitter: deltaJitter,
            deltaLoss: deltaLoss,
            deltaSpikes: deltaSpikes
        )

        return .completed(
            DeepCheckResult(
                restResult: restResult,
                metrics: DeepCheckMetrics(
                    rest: restResult.metrics,
                    load: loadResult.metrics,
                    loadImpact: DeepCheckLoadImpact(
                        restP50Milliseconds: restP50,
                        loadP50Milliseconds: loadP50,
                        tier: tier,
                        deltaJitterMilliseconds: deltaJitter,
                        deltaLossPercentage: deltaLoss,
                        deltaSpikesCount: deltaSpikes
                    )
                )
            )
        )
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
