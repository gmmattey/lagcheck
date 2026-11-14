import Foundation
import LagCheckEngine

/// Fachada fina sobre o motor compartilhado LagCheckEngine (Decisões 134 e 135).
public enum QualityEvaluator {
    public static func ruleVersion(for profile: QualityProfileID) -> String {
        let key = LagCheckEngineBridge.toProfileKey(profile)
        return EnginePolicyProvider.policy.ruleVersions[key]?["quality"] ?? "pilot-2026.11.14.1"
    }

    public static func supports(profile: QualityProfileID, ruleVersion: String) -> Bool {
        if ruleVersion == self.ruleVersion(for: profile) { return true }
        switch profile {
        case .battleRoyaleCompetitive:
            return ruleVersion == "pilot-2026.09.08.1"
        case .mobileRealtime:
            return ruleVersion == "mobile-realtime-2026.09.08.1"
        case .casualRealtime:
            return ruleVersion == "casual-realtime-2026.09.08.1"
        }
    }

    public static func evaluateBattleRoyaleCompetitive(
        samples: [ProbeSample]
    ) -> MeasurementEvaluation {
        evaluate(samples: samples, profile: .battleRoyaleCompetitive)
    }

    public static func evaluateMobileRealtime(samples: [ProbeSample]) -> MeasurementEvaluation {
        evaluate(samples: samples, profile: .mobileRealtime)
    }

    public static func evaluateCasualRealtime(samples: [ProbeSample]) -> MeasurementEvaluation {
        evaluate(samples: samples, profile: .casualRealtime)
    }

    public static func evaluate(
        samples: [ProbeSample],
        profile: QualityProfileID
    ) -> MeasurementEvaluation {
        let deepEval = DeepCheckEvaluator.evaluate(
            restSamples: samples,
            loadSamples: nil,
            profile: profile
        )
        switch deepEval {
        case .completed(let deepResult):
            return .completed(deepResult.restResult)
        case .inconclusive(let reason, let diagnostics):
            return .inconclusive(reason: reason, diagnostics: diagnostics)
        }
    }
}
