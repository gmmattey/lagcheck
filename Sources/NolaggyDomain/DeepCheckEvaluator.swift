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
public enum DeepCheckLoadImpactMaterialityRuleV1 {
    public static let version = "deep-load-impact-v1"
    public static let materialIncreaseMilliseconds = 20.0

    public static func classify(increaseMilliseconds: Double) -> DeepCheckLoadImpactClassification {
        increaseMilliseconds >= materialIncreaseMilliseconds ? .material : .descriptive
    }
}

/// Comparação observada entre os P50 das duas fases. Não é score nem classe.
public struct DeepCheckLoadImpact: Codable, Equatable, Sendable {
    public let restP50Milliseconds: Double
    public let loadP50Milliseconds: Double
    public let increaseMilliseconds: Double
    public let ruleVersion: String
    public let classification: DeepCheckLoadImpactClassification

    public init(restP50Milliseconds: Double, loadP50Milliseconds: Double) {
        self.restP50Milliseconds = restP50Milliseconds
        self.loadP50Milliseconds = loadP50Milliseconds
        self.increaseMilliseconds = loadP50Milliseconds - restP50Milliseconds
        self.ruleVersion = DeepCheckLoadImpactMaterialityRuleV1.version
        self.classification = DeepCheckLoadImpactMaterialityRuleV1.classify(
            increaseMilliseconds: increaseMilliseconds
        )
    }

    private enum CodingKeys: String, CodingKey {
        case restP50Milliseconds
        case loadP50Milliseconds
        case increaseMilliseconds
        case ruleVersion
        case classification
    }

    /// Snapshots gerados antes da regra não carregavam sua classificação. Eles
    /// são migrados uma única vez com a versão atual a partir do delta já salvo;
    /// snapshots novos preservam tanto a versão quanto a classificação gravadas.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        restP50Milliseconds = try container.decode(Double.self, forKey: .restP50Milliseconds)
        loadP50Milliseconds = try container.decode(Double.self, forKey: .loadP50Milliseconds)
        increaseMilliseconds = try container.decode(Double.self, forKey: .increaseMilliseconds)
        ruleVersion = try container.decodeIfPresent(String.self, forKey: .ruleVersion)
            ?? DeepCheckLoadImpactMaterialityRuleV1.version
        classification = try container.decodeIfPresent(DeepCheckLoadImpactClassification.self, forKey: .classification)
            ?? DeepCheckLoadImpactMaterialityRuleV1.classify(increaseMilliseconds: increaseMilliseconds)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(restP50Milliseconds, forKey: .restP50Milliseconds)
        try container.encode(loadP50Milliseconds, forKey: .loadP50Milliseconds)
        try container.encode(increaseMilliseconds, forKey: .increaseMilliseconds)
        try container.encode(ruleVersion, forKey: .ruleVersion)
        try container.encode(classification, forKey: .classification)
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

        return .completed(
            DeepCheckResult(
                restResult: restResult,
                metrics: DeepCheckMetrics(
                    rest: restResult.metrics,
                    load: loadResult.metrics,
                    loadImpact: DeepCheckLoadImpact(
                        restP50Milliseconds: restP50,
                        loadP50Milliseconds: loadP50
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
