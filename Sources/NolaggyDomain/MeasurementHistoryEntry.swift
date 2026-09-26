import Foundation

/// Fato final, autoexplicável e imutável de uma medição que pode entrar no histórico.
/// Amostras brutas pertencem apenas à sessão em memória e nunca a este snapshot.
public struct MeasurementHistoryEntry: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let completedAt: Date
    public let kind: MeasurementKind
    public let resolvedContext: ResolvedMeasurementContext
    public let profileRuleVersion: String
    public let result: QualityResult
    /// O Deep Check preserva o complemento de carga sem amostras brutas.
    /// Em Quick Check este campo permanece nulo.
    public let deepCheck: DeepCheckResult?
    public let primaryCause: ResultPrimaryCauseKey
    public let readinessVerdict: GameReadinessVerdict?
    public let readinessRuleVersion: String?

    public init(
        id: UUID = UUID(),
        completedAt: Date = Date(),
        kind: MeasurementKind = .quick,
        resolvedContext: ResolvedMeasurementContext,
        profileRuleVersion: String,
        result: QualityResult,
        deepCheck: DeepCheckResult? = nil,
        primaryCause: ResultPrimaryCauseKey,
        readinessVerdict: GameReadinessVerdict? = nil,
        readinessRuleVersion: String? = GameReadinessEvaluator.version
    ) {
        self.id = id
        self.completedAt = completedAt
        self.kind = kind
        self.resolvedContext = resolvedContext
        self.profileRuleVersion = profileRuleVersion
        self.result = result
        self.deepCheck = deepCheck
        self.primaryCause = primaryCause
        self.readinessVerdict = readinessVerdict
        self.readinessRuleVersion = readinessRuleVersion
    }

    public static func completedQuickCheck(
        resolvedContext: ResolvedMeasurementContext,
        result: QualityResult,
        completedAt: Date = Date()
    ) -> MeasurementHistoryEntry {
        let arch = GameEditorialRegistry.serverArchitecture(for: resolvedContext.context.gameID)
        let readiness = GameReadinessEvaluator.evaluate(
            qualityResult: result,
            loadImpact: nil,
            profile: resolvedContext.profileID,
            confidence: resolvedContext.confidence,
            serverArchitecture: arch
        )
        return MeasurementHistoryEntry(
            completedAt: completedAt,
            resolvedContext: resolvedContext,
            profileRuleVersion: resolvedContext.profileRuleVersion,
            result: result,
            primaryCause: ResultInterpreter.interpret(result, profile: resolvedContext.profileID, serverArchitecture: arch).primaryCauseKey,
            readinessVerdict: readiness.verdict,
            readinessRuleVersion: GameReadinessEvaluator.version
        )
    }

    /// Converte somente um Deep Check concluído em um fato histórico.
    /// O score e a classe continuam sendo os da fase de repouso.
    public static func completedDeepCheck(
        resolvedContext: ResolvedMeasurementContext,
        result: DeepCheckResult,
        completedAt: Date = Date()
    ) -> MeasurementHistoryEntry {
        let arch = GameEditorialRegistry.serverArchitecture(for: resolvedContext.context.gameID)
        let readiness = GameReadinessEvaluator.evaluate(
            qualityResult: result.restResult,
            loadImpact: result.metrics.loadImpact,
            profile: resolvedContext.profileID,
            confidence: resolvedContext.confidence,
            serverArchitecture: arch
        )
        return MeasurementHistoryEntry(
            completedAt: completedAt,
            kind: .deep,
            resolvedContext: resolvedContext,
            profileRuleVersion: resolvedContext.profileRuleVersion,
            result: result.restResult,
            deepCheck: result,
            primaryCause: ResultInterpreter.interpret(
                result.restResult,
                profile: resolvedContext.profileID,
                loadTier: result.metrics.loadImpact?.tier,
                serverArchitecture: arch
            ).primaryCauseKey,
            readinessVerdict: readiness.verdict,
            readinessRuleVersion: GameReadinessEvaluator.version
        )
    }
}
