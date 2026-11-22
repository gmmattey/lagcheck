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
        // Quick Check mede apenas repouso. Não passa pelo avaliador do Check
        // Completo, pois nele uma fase de carga ausente é corretamente
        // inconclusiva e não pode contaminar a jornada rápida.
        let request = EngineRequestDTO(
            source: "APP_UDP",
            profile: LagCheckEngineBridge.toProfileKey(profile),
            rest: samples.map(LagCheckEngineBridge.toSampleDTO),
            load: nil,
            loadTransfer: "NOT_RUN",
            gateway: nil,
            wifiBand: nil,
            nat: nil,
            serverArchitecture: "DEDICATED_SERVER",
            gameId: nil,
            uploadMbps: nil
        )
        let response = LagCheckEngineBridge.evaluate(request: request)
        let metrics = LagCheckEngineBridge.mapMetrics(response.rest)
        guard response.verdict != "INCONCLUSIVE" else {
            return .inconclusive(
                reason: response.inconclusiveReason == "POOR_SAMPLE_QUALITY" ? .poorSampleQuality : .insufficientUDPResponses,
                diagnostics: metrics
            )
        }
        let score = response.score ?? 0
        return .completed(QualityResult(
            metrics: metrics,
            rawScore: score,
            finalScore: score,
            resultClass: LagCheckEngineBridge.toResultClass(score),
            appliedGuardrails: [],
            samples: samples
        ))
    }
}
