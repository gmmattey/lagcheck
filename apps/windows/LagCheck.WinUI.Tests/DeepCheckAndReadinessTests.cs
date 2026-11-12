using LagCheck.WinUI.Diagnostic.Rules;
using Xunit;
using static LagCheck.WinUI.Tests.Probes;

namespace LagCheck.WinUI.Tests;

/// <summary>
/// deep-load-impact-v2 e readiness-v2.0, portados de DeepCheckEvaluatorTest.kt e GameReadinessEvaluatorTest.kt.
/// Os cortes por perfil seguem o código iOS/Android (idêntico nos dois), não a tabela da seção 6.1 do doc 03.
/// </summary>
public sealed class DeepCheckAndReadinessTests
{
    private const QualityProfileId Br = QualityProfileId.BattleRoyaleCompetitive;

    private static DeepCheckResult Deep(IReadOnlyList<ProbeSample> rest, IReadOnlyList<ProbeSample>? load, QualityProfileId profile = Br) =>
        Assert.IsType<DeepCheckEvaluation.Completed>(DeepCheckEvaluator.Evaluate(rest, load, profile)).Result;

    // region deep-load-impact-v2

    [Fact]
    public void Rest_score_is_preserved_and_impact_is_p50_delta()
    {
        var rest = Received(30, 30.0);
        var r = Deep(rest, Received(30, 93.0));
        Assert.Equal(Completed(rest), r.RestResult);
        Assert.Equal(100, r.RestResult.FinalScore);
        Assert.Equal(93.0, r.Metrics.Load!.P50Milliseconds);
        var impact = r.Metrics.LoadImpact!;
        Assert.Equal(63.0, impact.IncreaseMilliseconds);
        Assert.Equal("deep-load-impact-v2", impact.RuleVersion);
        Assert.Equal(LoadImpactClassification.Material, impact.Classification);
        Assert.Equal(LoadDegradationTier.Severe, impact.Tier);
    }

    [Theory]
    [InlineData(5.0, 2.0, 0.0, 0, LoadDegradationTier.None)]
    [InlineData(12.0, 5.0, 0.0, 0, LoadDegradationTier.Light)]
    [InlineData(22.0, 6.0, 0.0, 0, LoadDegradationTier.Material)]
    [InlineData(10.0, 10.0, 0.0, 0, LoadDegradationTier.Material)]
    [InlineData(10.0, 2.0, 2.5, 0, LoadDegradationTier.Material)]
    [InlineData(45.0, 25.0, 6.0, 4, LoadDegradationTier.Severe)]
    [InlineData(8.0, 4.0, 1.0, 0, LoadDegradationTier.None)]   // limites são estritos (>)
    [InlineData(18.0, 8.0, 2.0, 1, LoadDegradationTier.Light)]
    [InlineData(5.0, 0.0, 0.0, 2, LoadDegradationTier.Material)] // 2 spikes a mais sob carga
    [InlineData(40.0, 20.0, 5.0, 3, LoadDegradationTier.Material)]
    public void Battle_royale_rule_v2_vectors(double dP50, double dJitter, double dLoss, int dSpikes, LoadDegradationTier expected)
        => Assert.Equal(expected, DeepCheckLoadImpactRuleV2.Classify(Br, dP50, dJitter, dLoss, dSpikes));

    [Theory]
    [InlineData(QualityProfileId.MobileRealtime, 25.0, 0.0, 0.0, 0, LoadDegradationTier.Light)]
    [InlineData(QualityProfileId.MobileRealtime, 26.0, 0.0, 0.0, 0, LoadDegradationTier.Material)]
    [InlineData(QualityProfileId.MobileRealtime, 56.0, 0.0, 0.0, 0, LoadDegradationTier.Severe)]
    [InlineData(QualityProfileId.CasualRealtime, 40.0, 0.0, 0.0, 9, LoadDegradationTier.Light)]  // casual ignora spikes
    [InlineData(QualityProfileId.CasualRealtime, 41.0, 0.0, 0.0, 0, LoadDegradationTier.Material)]
    [InlineData(QualityProfileId.CasualRealtime, 81.0, 0.0, 0.0, 0, LoadDegradationTier.Severe)]
    [InlineData(QualityProfileId.CasualRealtime, 0.0, 0.0, 10.1, 0, LoadDegradationTier.Severe)]
    public void Other_profiles_use_their_own_cuts(QualityProfileId profile, double dP50, double dJitter, double dLoss, int dSpikes, LoadDegradationTier expected)
        => Assert.Equal(expected, DeepCheckLoadImpactRuleV2.Classify(profile, dP50, dJitter, dLoss, dSpikes));

    [Fact]
    public void Failed_load_keeps_rest_without_impact()
    {
        var r = Deep(Received(30, 30.0), null);
        Assert.Equal(100, r.RestResult.FinalScore);
        Assert.Null(r.Metrics.Load);
        Assert.Null(r.Metrics.LoadImpact);
    }

    [Fact]
    public void Insufficient_load_responses_do_not_expose_partial_metrics()
    {
        var r = Deep(Received(30, 30.0), Concat(Received(9, 90.0), Timeouts(21, 9)));
        Assert.Equal(100, r.RestResult.FinalScore);
        Assert.Null(r.Metrics.Load);
        Assert.Null(r.Metrics.LoadImpact);
    }

    [Fact]
    public void Insufficient_rest_makes_everything_inconclusive()
    {
        var e = DeepCheckEvaluator.Evaluate(Concat(Received(9, 30.0), Timeouts(21, 9)), Received(30, 90.0), Br);
        var inc = Assert.IsType<DeepCheckEvaluation.Inconclusive>(e);
        Assert.Equal(9, inc.Diagnostics.ValidResponseCount);
    }

    [Fact]
    public void Negative_impact_is_descriptive_and_clamped_in_the_tier()
    {
        var r = Deep(Received(30, 93.0), Received(30, 30.0));
        Assert.Equal(-63.0, r.Metrics.LoadImpact!.IncreaseMilliseconds);
        Assert.Equal(LoadImpactClassification.Descriptive, r.Metrics.LoadImpact.Classification);
        Assert.Equal(LoadDegradationTier.None, r.Metrics.LoadImpact.Tier);
    }

    [Fact]
    public void Materiality_uses_raw_twenty_ms_boundary_and_never_changes_the_rest_result()
    {
        var rest = Received(30, 30.0);
        var below = Deep(rest, Received(30, 49.999));
        var at = Deep(rest, Received(30, 50.0));
        Assert.Equal(LoadImpactClassification.Descriptive, below.Metrics.LoadImpact!.Classification);
        Assert.Equal(LoadImpactClassification.Material, at.Metrics.LoadImpact!.Classification);
        Assert.Equal(below.RestResult, at.RestResult);
    }

    [Fact]
    public void Bufferbloat_grade_thresholds()
    {
        Assert.Equal(BufferbloatGrade.APlus, BufferbloatRuleV1.Evaluate(-5.0));
        Assert.Equal(BufferbloatGrade.APlus, BufferbloatRuleV1.Evaluate(2.0));
        Assert.Equal(BufferbloatGrade.A, BufferbloatRuleV1.Evaluate(2.001));
        Assert.Equal(BufferbloatGrade.A, BufferbloatRuleV1.Evaluate(5.0));
        Assert.Equal(BufferbloatGrade.B, BufferbloatRuleV1.Evaluate(5.01));
        Assert.Equal(BufferbloatGrade.B, BufferbloatRuleV1.Evaluate(15.0));
        Assert.Equal(BufferbloatGrade.C, BufferbloatRuleV1.Evaluate(15.001));
        Assert.Equal(BufferbloatGrade.C, BufferbloatRuleV1.Evaluate(35.0));
        Assert.Equal(BufferbloatGrade.D, BufferbloatRuleV1.Evaluate(35.01));
        Assert.Equal(BufferbloatGrade.D, BufferbloatRuleV1.Evaluate(60.0));
        Assert.Equal(BufferbloatGrade.F, BufferbloatRuleV1.Evaluate(60.001));
    }

    // endregion

    // region readiness-v2.0

    private static GameReadinessAssessment EvalSamples(IReadOnlyList<ProbeSample> samples, QualityProfileId profile = Br, double? loadDelta = null)
    {
        if (QualityEvaluator.Evaluate(samples, profile) is not MeasurementEvaluation.Completed c)
            return GameReadinessEvaluator.Evaluate((QualityResult?)null, null, profile);
        var impact = loadDelta is { } d && c.Result.Metrics.P50Milliseconds is { } p50
            ? DeepCheckLoadImpact.FromP50(p50, p50 + d)
            : null;
        return GameReadinessEvaluator.Evaluate(c.Result, impact, profile);
    }

    [Fact]
    public void Healthy_is_ready()
    {
        var e = EvalSamples(Received(30, 25.0), loadDelta: 5.0);
        Assert.Equal(GameReadinessVerdict.Ready, e.Verdict);
        Assert.True(e.StabilityRatio >= 0.85);
        Assert.Equal(0.0, e.PacketLossPercentage);
        Assert.False(e.IsUnderLoadAffected);
        Assert.True(e.Score >= 75);
    }

    [Fact]
    public void Packet_loss_is_not_ready()
    {
        var e = EvalSamples(Concat(Received(25, 25.0), Timeouts(5, 25)));
        Assert.Equal(GameReadinessVerdict.NotReady, e.Verdict);
        Assert.Equal(PrimaryCause.PacketLoss, e.PrimaryCause);
        Assert.True(e.StabilityRatio <= 0.45);
        Assert.True(e.Score <= 59);
    }

    [Fact]
    public void High_latency_is_not_ready()
    {
        var e = EvalSamples(Received(30, 140.0));
        Assert.Equal(GameReadinessVerdict.NotReady, e.Verdict);
        Assert.Equal(PrimaryCause.HighLatency, e.PrimaryCause);
    }

    [Fact]
    public void Severe_spikes_are_not_ready()
    {
        var e = EvalSamples(Concat(Received(28, 25.0), [ProbeSample.Received(28, 180.0), ProbeSample.Received(29, 180.0)]));
        Assert.Equal(GameReadinessVerdict.NotReady, e.Verdict);
        Assert.Equal(PrimaryCause.SevereSpikes, e.PrimaryCause);
    }

    [Fact]
    public void Material_load_is_caution()
    {
        var e = EvalSamples(Received(30, 25.0), loadDelta: 35.0);
        Assert.Equal(GameReadinessVerdict.Caution, e.Verdict);
        Assert.True(e.IsUnderLoadAffected);
        Assert.InRange(e.Score!.Value, 60, 74);
    }

    [Fact]
    public void Severe_load_tier_is_not_ready()
    {
        var q = Completed(Received(30, 25.0));
        var impact = new DeepCheckLoadImpact(25.0, 80.0, LoadDegradationTier.Severe);
        Assert.Equal(GameReadinessVerdict.NotReady, GameReadinessEvaluator.Evaluate(q, impact, Br).Verdict);
    }

    [Fact]
    public void Moderate_jitter_is_caution_or_worse()
    {
        var s = Enumerable.Range(0, 30).Select(i => ProbeSample.Received(i, i % 2 == 0 ? 20.0 : 50.0)).ToList();
        Assert.Contains(EvalSamples(s).Verdict, new[] { GameReadinessVerdict.Caution, GameReadinessVerdict.NotReady });
    }

    [Fact]
    public void Insufficient_samples_are_inconclusive_and_never_fabricate()
    {
        Assert.IsType<MeasurementEvaluation.Inconclusive>(QualityEvaluator.Evaluate(Received(8, 25.0), Br));
        var r = GameReadinessEvaluator.Evaluate((QualityResult?)null, null, Br);
        Assert.Equal(GameReadinessVerdict.Inconclusive, r.Verdict);
        Assert.Equal(0.0, r.StabilityRatio);
        Assert.Null(r.PacketLossPercentage);
        Assert.Null(r.PingMs);
        Assert.Null(r.JitterMs);
        Assert.Null(r.Score);
    }

    [Fact]
    public void Pipeline_without_enough_valid_responses_is_inconclusive_even_with_a_perfect_load_series()
    {
        var r = GameReadinessEvaluator.Evaluate(Concat(Received(9, 20.0), Timeouts(21, 9)), Received(30, 30.0), Br);
        Assert.Equal(GameReadinessVerdict.Inconclusive, r.Verdict);
        Assert.Null(r.Score);
    }

    [Fact]
    public void All_probes_lost_is_inconclusive_without_score()
    {
        var r = GameReadinessEvaluator.Evaluate(Timeouts(30, 0), null, Br);
        Assert.Equal(GameReadinessVerdict.Inconclusive, r.Verdict);
        Assert.Null(r.Score);
        Assert.Null(r.PingMs);
    }

    [Theory]
    [InlineData(QualityProfileId.BattleRoyaleCompetitive)]
    [InlineData(QualityProfileId.MobileRealtime)]
    [InlineData(QualityProfileId.CasualRealtime)]
    public void All_profiles_are_ready_when_healthy(QualityProfileId profile)
        => Assert.Equal(GameReadinessVerdict.Ready, EvalSamples(Received(30, 20.0), profile).Verdict);

    [Fact]
    public void Medium_confidence_tightens_thresholds_by_ten_percent()
    {
        var q = Completed(Received(30, 95.0));
        Assert.Equal(GameReadinessVerdict.Ready, GameReadinessEvaluator.Evaluate(q, null, Br, MeasurementConfidence.High).Verdict);
        Assert.Equal(GameReadinessVerdict.NotReady, GameReadinessEvaluator.Evaluate(q, null, Br, MeasurementConfidence.Medium).Verdict);
    }

    [Fact]
    public void Recurring_severe_spikes_trigger_not_ready()
    {
        var q = Completed(Received(30, 25.0));
        var r = GameReadinessEvaluator.Evaluate(q, null, Br, spikePattern: new SpikePattern.Recurring(2, 2));
        Assert.Equal(GameReadinessVerdict.NotReady, r.Verdict);
    }

    [Fact]
    public void Verdict_score_is_always_inside_the_verdict_band()
    {
        var ready = EvalSamples(Received(30, 25.0));
        var caution = EvalSamples(Received(30, 25.0), loadDelta: 35.0);
        var notReady = EvalSamples(Received(30, 140.0));
        Assert.True(ready.Score >= 75);
        Assert.InRange(caution.Score!.Value, 60, 74);
        Assert.InRange(notReady.Score!.Value, 0, 59);
    }

    // endregion
}
