import Foundation
import LagCheckEngine

/// Diagnóstico estruturado da qualidade e densidade da amostra UDP (Decisões 55 e 135).
public struct SampleQualityAssessment: Equatable, Sendable {
    public enum Status: Equatable, Sendable {
        /// A amostragem está com qualidade aceitável e pode continuar.
        case normal
        /// A amostragem apresenta instabilidade ou perda extrema e deve ser abortada imediatamente.
        case shouldAbort(reason: InconclusiveReason)
    }

    public let status: Status
    public let consecutiveTimeouts: Int
    public let earlyLossPercentage: Double
    public let ruleVersion: String

    public init(
        status: Status,
        consecutiveTimeouts: Int,
        earlyLossPercentage: Double,
        ruleVersion: String = SampleQualityEvaluator.ruleVersion
    ) {
        self.status = status
        self.consecutiveTimeouts = consecutiveTimeouts
        self.earlyLossPercentage = earlyLossPercentage
        self.ruleVersion = ruleVersion
    }
}

/// Watchdog determinístico executado diretamente no motor compartilhado (Decisões 55, 134 e 135).
public enum SampleQualityEvaluator {
    public static var ruleVersion: String {
        EnginePolicyProvider.policy.ruleVersions["BATTLE_ROYALE_COMPETITIVE"]?["sampleQuality"] ?? "sample-quality-v2"
    }

    /// Avalia a sequência de amostras recebidas até o momento na ordem de sequência de envio via motor KMP.
    public static func assess(samples: [ProbeSample]) -> SampleQualityAssessment {
        KmpSampleQualityBridge.assess(samples)
    }
}
