namespace LagCheck.WinUI.Diagnostic.Rules;

public enum LoadDegradationTier { None, Light, Material, Severe }

public enum LoadImpactClassification { Descriptive, Material }

public enum BufferbloatGrade { APlus, A, B, C, D, F }

public static class BufferbloatRuleV1
{
    public const string Version = "bufferbloat-grade-v1";

    public static BufferbloatGrade Evaluate(double increaseMilliseconds) => increaseMilliseconds switch
    {
        <= 2.0 => BufferbloatGrade.APlus,
        <= 5.0 => BufferbloatGrade.A,
        <= 15.0 => BufferbloatGrade.B,
        <= 35.0 => BufferbloatGrade.C,
        <= 60.0 => BufferbloatGrade.D,
        _ => BufferbloatGrade.F
    };
}

public static class DeepCheckLoadImpactRuleV1
{
    public const string Version = "deep-load-impact-v1";
    public const double MaterialIncreaseMilliseconds = 20.0;
}

/// <summary>Comparação observada repouso × carga. Não é score nem classe de qualidade.</summary>
public sealed record DeepCheckLoadImpact(
    double RestP50Milliseconds,
    double LoadP50Milliseconds,
    LoadDegradationTier Tier,
    double? DeltaJitterMilliseconds = null,
    double? DeltaLossPercentage = null,
    int? DeltaSpikesCount = null)
{
    public string RuleVersion => DeepCheckLoadImpactRuleV2.Version;

    public double IncreaseMilliseconds => LoadP50Milliseconds - RestP50Milliseconds;

    public BufferbloatGrade BufferbloatGrade => BufferbloatRuleV1.Evaluate(IncreaseMilliseconds);

    public LoadImpactClassification Classification =>
        IncreaseMilliseconds >= DeepCheckLoadImpactRuleV1.MaterialIncreaseMilliseconds
            ? LoadImpactClassification.Material
            : LoadImpactClassification.Descriptive;

    /// <summary>Tier derivado só do delta de P50 (corte de 20 ms); equivalente ao init de conveniência do Swift.</summary>
    public static DeepCheckLoadImpact FromP50(double restP50, double loadP50) =>
        new(restP50, loadP50,
            loadP50 - restP50 >= DeepCheckLoadImpactRuleV1.MaterialIncreaseMilliseconds
                ? LoadDegradationTier.Material
                : LoadDegradationTier.None);
}

/// <summary>Regra multidimensional calibrada por perfil (<c>deep-load-impact-v2</c>).</summary>
public static class DeepCheckLoadImpactRuleV2
{
    public const string Version = "deep-load-impact-v2";

    public static LoadDegradationTier Classify(
        QualityProfileId profile, double deltaP50, double deltaJitter, double deltaLoss, int deltaSpikes)
    {
        switch (profile)
        {
            case QualityProfileId.BattleRoyaleCompetitive:
                if (deltaP50 > 40 || deltaJitter > 20 || deltaLoss > 5.0 || deltaSpikes >= 4) return LoadDegradationTier.Severe;
                if (deltaP50 > 18 || deltaJitter > 8 || deltaLoss > 2.0 || deltaSpikes >= 2) return LoadDegradationTier.Material;
                if (deltaP50 > 8 || deltaJitter > 4 || deltaLoss > 1.0 || deltaSpikes >= 1) return LoadDegradationTier.Light;
                return LoadDegradationTier.None;
            case QualityProfileId.MobileRealtime:
                if (deltaP50 > 55 || deltaJitter > 25 || deltaLoss > 7.0 || deltaSpikes >= 5) return LoadDegradationTier.Severe;
                if (deltaP50 > 25 || deltaJitter > 12 || deltaLoss > 3.0 || deltaSpikes >= 2) return LoadDegradationTier.Material;
                if (deltaP50 > 12 || deltaJitter > 6 || deltaLoss > 1.5 || deltaSpikes >= 1) return LoadDegradationTier.Light;
                return LoadDegradationTier.None;
            case QualityProfileId.CasualRealtime:
                if (deltaP50 > 80 || deltaJitter > 35 || deltaLoss > 10.0) return LoadDegradationTier.Severe;
                if (deltaP50 > 40 || deltaJitter > 18 || deltaLoss > 5.0) return LoadDegradationTier.Material;
                if (deltaP50 > 20 || deltaJitter > 10 || deltaLoss > 2.0) return LoadDegradationTier.Light;
                return LoadDegradationTier.None;
            default:
                throw new ArgumentOutOfRangeException(nameof(profile));
        }
    }
}

public sealed record DeepCheckMetrics(QualityMetrics Rest, QualityMetrics? Load, DeepCheckLoadImpact? LoadImpact);

public sealed record DeepCheckResult(QualityResult RestResult, DeepCheckMetrics Metrics);

public abstract record DeepCheckEvaluation
{
    private DeepCheckEvaluation() { }

    public sealed record Completed(DeepCheckResult Result) : DeepCheckEvaluation;

    public sealed record Inconclusive(InconclusiveReason Reason, QualityMetrics Diagnostics) : DeepCheckEvaluation;
}

/// <summary>
/// Avalia repouso e carga sem misturar as séries nem recalcular o score de repouso.
/// Falha ou dados insuficientes na carga não invalidam o resultado de repouso.
/// </summary>
public static class DeepCheckEvaluator
{
    public static DeepCheckEvaluation Evaluate(
        IReadOnlyList<ProbeSample> restSamples,
        IReadOnlyList<ProbeSample>? loadSamples,
        QualityProfileId profile)
    {
        var restEvaluation = QualityEvaluator.Evaluate(restSamples, profile);
        if (restEvaluation is MeasurementEvaluation.Inconclusive inconclusive)
            return new DeepCheckEvaluation.Inconclusive(inconclusive.Reason, inconclusive.Diagnostics);

        var rest = ((MeasurementEvaluation.Completed)restEvaluation).Result;
        var withoutLoad = new DeepCheckEvaluation.Completed(
            new DeepCheckResult(rest, new DeepCheckMetrics(rest.Metrics, null, null)));
        if (loadSamples is null) return withoutLoad;

        if (QualityEvaluator.Evaluate(loadSamples, profile) is not MeasurementEvaluation.Completed loadCompleted) return withoutLoad;
        var load = loadCompleted.Result;
        if (rest.Metrics.P50Milliseconds is not { } restP50 || load.Metrics.P50Milliseconds is not { } loadP50) return withoutLoad;

        double deltaP50 = Math.Max(0.0, loadP50 - restP50);
        double deltaJitter = Math.Max(0.0, (load.Metrics.JitterMilliseconds ?? 0.0) - (rest.Metrics.JitterMilliseconds ?? 0.0));
        double deltaLoss = Math.Max(0.0, load.Metrics.PacketLossPercentage - rest.Metrics.PacketLossPercentage);
        int deltaSpikes = Math.Max(0, load.Metrics.SpikeCount - rest.Metrics.SpikeCount);
        var tier = DeepCheckLoadImpactRuleV2.Classify(profile, deltaP50, deltaJitter, deltaLoss, deltaSpikes);

        return new DeepCheckEvaluation.Completed(new DeepCheckResult(
            rest,
            new DeepCheckMetrics(rest.Metrics, load.Metrics,
                new DeepCheckLoadImpact(restP50, loadP50, tier, deltaJitter, deltaLoss, deltaSpikes))));
    }
}
