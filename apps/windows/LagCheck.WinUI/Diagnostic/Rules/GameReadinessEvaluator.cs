namespace LagCheck.WinUI.Diagnostic.Rules;

public sealed record GameReadinessAssessment(
    GameReadinessVerdict Verdict,
    double StabilityRatio,
    double? PingMs,
    double? JitterMs,
    double? PacketLossPercentage,
    bool IsUnderLoadAffected,
    double? WorstSpikeMs,
    int? Score,
    PrimaryCause? PrimaryCause,
    LoadDegradationTier? LoadTier)
{
    /// <summary>Sem 10 respostas válidas: nada é inventado, nem nota.</summary>
    public static GameReadinessAssessment Inconclusive { get; } =
        new(GameReadinessVerdict.Inconclusive, 0.0, null, null, null, false, null, null, null, null);
}

/// <summary>Escolhe a causa única de destaque (<c>ResultInterpreter</c>): perda, P50, spikes severos, jitter, ordem, carga.</summary>
public static class ResultInterpreter
{
    public static (PrimaryCause Primary, IReadOnlyList<PrimaryCause> Secondary) EvaluateCauses(
        QualityMetrics metrics,
        QualityEvaluator.CauseGuardrails guardrails,
        LoadDegradationTier? loadTier,
        SpikePattern? spikePattern)
    {
        var causes = new List<PrimaryCause>();
        bool isLoss = metrics.PacketLossPercentage > guardrails.LossGuardrailPercentage;
        bool isLatency = (metrics.P50Milliseconds ?? 0.0) > guardrails.LatencyGuardrailMilliseconds;
        bool isSevereSpikes = spikePattern is not null
            ? spikePattern.SevereSpikes >= guardrails.SevereSpikeGuardrailCount
            : metrics.SevereSpikeCount >= guardrails.SevereSpikeGuardrailCount;
        bool isJitter = (metrics.JitterMilliseconds ?? 0.0) > guardrails.JitterRiskMilliseconds;
        bool isLoad = loadTier is LoadDegradationTier.Material or LoadDegradationTier.Severe;
        bool isTail = (metrics.P95ToP50Ratio ?? 0.0) >= 1.8;
        bool isOutOfOrder = metrics.OutOfOrderCount >= 2 || metrics.OutOfOrderRatePercentage >= 5.0;

        if (isJitter && isLoad)
        {
            causes.Add(PrimaryCause.LoadInstability);
            if (isLoss) causes.Add(PrimaryCause.PacketLoss);
            if (isLatency) causes.Add(PrimaryCause.HighLatency);
            if (isSevereSpikes) causes.Add(PrimaryCause.SevereSpikes);
            if (isOutOfOrder) causes.Add(PrimaryCause.OutOfOrder);
        }
        else
        {
            if (isLoss) causes.Add(PrimaryCause.PacketLoss);
            if (isLatency) causes.Add(PrimaryCause.HighLatency);
            if (isSevereSpikes) causes.Add(PrimaryCause.SevereSpikes);
            if (isJitter) causes.Add(PrimaryCause.HighJitter);
            if (isOutOfOrder) causes.Add(PrimaryCause.OutOfOrder);
            if (isLoad) causes.Add(PrimaryCause.LoadDegradation);
        }

        var primary = causes.Count > 0 ? causes[0] : PrimaryCause.StableConnection;
        var secondary = causes.Skip(1).Take(2).ToList();
        if (isTail && !causes.Contains(PrimaryCause.TailLatency) && secondary.Count < 2) secondary.Add(PrimaryCause.TailLatency);
        return (primary, secondary);
    }
}

/// <summary>
/// Port de <c>GameReadinessEvaluator</c> (<c>readiness-v2.0</c>). O veredito avalia o repouso e penaliza
/// degradação sob carga. Sem 10 respostas UDP/probe válidas: inconclusivo, sem nota.
/// </summary>
public static class GameReadinessEvaluator
{
    public const string Version = "readiness-v2.0";

    /// <summary>Pipeline completo: repouso + carga opcional → avaliação.</summary>
    public static GameReadinessAssessment Evaluate(
        IReadOnlyList<ProbeSample> restSamples,
        IReadOnlyList<ProbeSample>? loadSamples,
        QualityProfileId profile,
        MeasurementConfidence confidence = MeasurementConfidence.High)
    {
        if (DeepCheckEvaluator.Evaluate(restSamples, loadSamples, profile) is not DeepCheckEvaluation.Completed deep)
            return GameReadinessAssessment.Inconclusive;
        return Evaluate(deep.Result.RestResult, deep.Result.Metrics.LoadImpact, profile, confidence);
    }

    public static GameReadinessAssessment Evaluate(
        QualityResult? qualityResult,
        DeepCheckLoadImpact? loadImpact,
        QualityProfileId profile,
        MeasurementConfidence confidence = MeasurementConfidence.High,
        SpikePattern? spikePattern = null)
    {
        if (qualityResult is null) return GameReadinessAssessment.Inconclusive;
        var metrics = qualityResult.Metrics;

        // Regra inegociável: menos de 10 respostas válidas é inconclusivo.
        if (metrics.ValidResponseCount < ProbeAcceptancePolicy.MinimumValidResponses)
            return GameReadinessAssessment.Inconclusive;

        var guardrails = QualityEvaluator.GetCauseGuardrails(profile);
        var (cause, _) = ResultInterpreter.EvaluateCauses(metrics, guardrails, loadImpact?.Tier, spikePattern);

        // Margem de 10% para rota genérica (confiança medium), Decisão 55.
        double margin = confidence == MeasurementConfidence.Medium ? 0.90 : 1.0;
        double effectiveMaxLoss = guardrails.LossGuardrailPercentage * margin;
        double effectiveMaxP50 = guardrails.LatencyGuardrailMilliseconds * margin;
        double effectiveCautionJitter = guardrails.JitterRiskMilliseconds * margin;

        bool isLoadSevere = loadImpact?.Tier == LoadDegradationTier.Severe;
        bool isLoadMaterial = loadImpact?.Tier == LoadDegradationTier.Material
            || loadImpact?.Classification == LoadImpactClassification.Material;
        bool hasPacketLoss = metrics.PacketLossPercentage > effectiveMaxLoss || cause == PrimaryCause.PacketLoss;
        bool hasHighLatency = (metrics.P50Milliseconds ?? 0.0) > effectiveMaxP50 || cause == PrimaryCause.HighLatency;

        bool recurringSevereSpikes = spikePattern is not null
            ? spikePattern.SevereSpikes >= 2 && spikePattern.IsRecurring
            : metrics.SevereSpikeCount >= guardrails.SevereSpikeGuardrailCount;
        bool hasSevereSpikes = recurringSevereSpikes
            || metrics.SevereSpikeCount >= guardrails.SevereSpikeGuardrailCount
            || cause == PrimaryCause.SevereSpikes;
        bool hasHighJitter = (metrics.JitterMilliseconds ?? 0.0) >= effectiveCautionJitter || cause == PrimaryCause.HighJitter;
        bool hasRecurringSpikes = spikePattern?.IsRecurring ?? false;
        bool hasOutOfOrder = metrics.OutOfOrderCount >= 2 || metrics.OutOfOrderRatePercentage >= 5.0;

        // Cauda só é relevante com dispersão relativa E absoluta (evita falso positivo em fibra rápida).
        double p50 = metrics.P50Milliseconds ?? 0.0;
        double p95 = metrics.P95Milliseconds ?? 0.0;
        bool isTailLatencyHigh = (metrics.P95ToP50Ratio ?? 0.0) >= 1.8 && (p95 - p50) >= 20.0 && p95 > 45.0;

        GameReadinessVerdict verdict;
        if (hasPacketLoss || hasHighLatency || recurringSevereSpikes || hasSevereSpikes || isLoadSevere
            || qualityResult.ResultClass == ResultClass.LagRisk)
            verdict = GameReadinessVerdict.NotReady;
        else if (hasHighJitter || hasOutOfOrder || isLoadMaterial || hasRecurringSpikes || isTailLatencyHigh
            || qualityResult.ResultClass == ResultClass.Unstable)
            verdict = GameReadinessVerdict.Caution;
        else
            verdict = GameReadinessVerdict.Ready;

        double consistency = metrics.Components?.Consistency ?? qualityResult.FinalScore;
        double stability = Math.Clamp(consistency / 100.0, 0.0, 1.0);
        if (isLoadMaterial) stability = Math.Max(0.2, stability * 0.8);
        stability = verdict switch
        {
            GameReadinessVerdict.NotReady => Math.Min(0.45, stability),
            GameReadinessVerdict.Caution => Math.Min(0.75, Math.Max(0.50, stability)),
            _ => Math.Max(0.85, stability)
        };

        int evaluatedScore = qualityResult.FinalScore;
        if (isLoadSevere) evaluatedScore = Math.Min(59, evaluatedScore);
        else if (isLoadMaterial) evaluatedScore = Math.Min(74, evaluatedScore);

        int unifiedScore = verdict switch
        {
            GameReadinessVerdict.Ready => Math.Max(75, evaluatedScore),
            GameReadinessVerdict.Caution => Math.Min(74, Math.Max(60, evaluatedScore)),
            _ => Math.Min(59, Math.Max(0, evaluatedScore))
        };

        return new GameReadinessAssessment(
            verdict, stability, metrics.P50Milliseconds, metrics.JitterMilliseconds, metrics.PacketLossPercentage,
            isLoadMaterial, metrics.WorstSpikeMilliseconds, unifiedScore, cause, loadImpact?.Tier);
    }
}
