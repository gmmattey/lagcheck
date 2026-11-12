using LagCheck.WinUI.Diagnostic.Rules;
using Xunit;
using static LagCheck.WinUI.Tests.Probes;

namespace LagCheck.WinUI.Tests;

/// <summary>Vetores BR001–BR012, MR e CR portados de QualityEvaluatorTest.kt / QualityEvaluatorPilotTests.swift.</summary>
public sealed class QualityEvaluatorTests
{
    private const double Tol = 1e-6;

    [Fact]
    public void BR001_stable()
    {
        var r = Completed(Received(30, 30.0));
        Assert.Equal(30.0, r.Metrics.P50Milliseconds);
        Assert.Equal(30.0, r.Metrics.P95Milliseconds);
        Assert.Equal(30.0, r.Metrics.P99Milliseconds);
        Assert.Equal(0.0, r.Metrics.JitterMilliseconds);
        Assert.Equal(0.0, r.Metrics.PacketLossPercentage);
        Assert.Equal(0, r.Metrics.SpikeCount);
        Assert.Equal(100.0, r.Metrics.Components!.Consistency);
        Assert.Equal(100, r.RawScore);
        Assert.Equal(100, r.FinalScore);
        Assert.Equal(ResultClass.Excellent, r.ResultClass);
    }

    [Fact]
    public void BR002_loss_guardrail()
    {
        var r = Completed(Concat(Received(20, 30.0), Timeouts(10, 20)));
        Assert.Equal(33.333333333333336, r.Metrics.PacketLossPercentage, Tol);
        Assert.Equal(90.0, r.Metrics.Components!.Consistency);
        Assert.Equal(69, r.RawScore);
        Assert.Equal(59, r.FinalScore);
        Assert.Equal(ResultClass.LagRisk, r.ResultClass);
        Assert.Equal(ScoreGuardrails.ExcessiveLossOrLatency, r.AppliedGuardrails);
    }

    [Fact]
    public void BR003_severe_spikes()
    {
        var r = Completed(Concat(Received(28, 30.0), [ProbeSample.Received(28, 160.0), ProbeSample.Received(29, 160.0)]));
        Assert.Equal(30.0, r.Metrics.P50Milliseconds);
        Assert.Equal(101.5, r.Metrics.P95Milliseconds!.Value, Tol);
        Assert.Equal(160.0, r.Metrics.P99Milliseconds);
        Assert.Equal(4.482758620689655, r.Metrics.JitterMilliseconds!.Value, Tol);
        Assert.Equal(2, r.Metrics.SevereSpikeCount);
        Assert.Equal(6.666666666666667, r.Metrics.SpikeRatePercentage, Tol);
        Assert.Equal(69.52380952380952, r.Metrics.Components!.Spikes, Tol);
        Assert.Equal(63.904761904761905, r.Metrics.Components!.Consistency, Tol);
        Assert.Equal(95, r.RawScore);
        Assert.Equal(74, r.FinalScore);
        Assert.Equal(ResultClass.Unstable, r.ResultClass);
        Assert.Equal(ScoreGuardrails.SevereSpikes, r.AppliedGuardrails);
    }

    [Fact]
    public void BR004_fewer_than_ten_valid_responses_is_inconclusive_without_score()
    {
        var e = QualityEvaluator.Evaluate(Concat(Received(9, 30.0), Timeouts(21, 9)), QualityProfileId.BattleRoyaleCompetitive);
        var inconclusive = Assert.IsType<MeasurementEvaluation.Inconclusive>(e);
        Assert.Equal(InconclusiveReason.InsufficientUdpResponses, inconclusive.Reason);
        Assert.Equal(9, inconclusive.Diagnostics.ValidResponseCount);
        Assert.Equal(70.0, inconclusive.Diagnostics.PacketLossPercentage);
        Assert.Null(inconclusive.Diagnostics.Components);
    }

    [Fact]
    public void Exactly_ten_valid_responses_is_the_minimum_that_scores()
    {
        Assert.IsType<MeasurementEvaluation.Completed>(
            QualityEvaluator.Evaluate(Concat(Received(10, 30.0), Timeouts(20, 10)), QualityProfileId.BattleRoyaleCompetitive));
        Assert.IsType<MeasurementEvaluation.Inconclusive>(
            QualityEvaluator.Evaluate(Received(9, 30.0), QualityProfileId.BattleRoyaleCompetitive));
    }

    [Fact]
    public void BR005_response_before_deadline_is_received()
        => Assert.Equal(ProbeOutcome.Received, ProbeAcceptancePolicy.Classify(14.5, 16.499));

    [Fact]
    public void BR006_response_after_timeout_is_timeout()
        => Assert.Equal(ProbeOutcome.Timeout, ProbeAcceptancePolicy.Classify(14.5, 16.501));

    [Fact]
    public void BR007_invalid_response_never_becomes_rtt_or_success()
    {
        var r = Completed(Concat(Received(29, 30.0), [new ProbeSample(29, null, ProbeOutcome.InvalidResponse)]));
        Assert.Equal(29, r.Metrics.ValidResponseCount);
        Assert.Equal(1, r.Metrics.InvalidResponseCount);
        Assert.Equal(30.0, r.Metrics.P50Milliseconds);
        Assert.Equal(0.0, r.Metrics.JitterMilliseconds);
        Assert.Equal(0.0, r.Metrics.PacketLossPercentage); // inválida não é timeout
    }

    [Fact]
    public void BR008_latency_interpolation_is_reproducible()
    {
        var r = Completed(Received(30, 50.0));
        Assert.Equal(90.0, r.Metrics.Components!.Latency);
        Assert.Equal(97, r.RawScore);
        Assert.Equal(97, r.FinalScore);
        Assert.Equal(ResultClass.Excellent, r.ResultClass);
    }

    [Fact]
    public void BR009_one_timeout_applies_loss_guardrail()
    {
        var r = Completed(Concat(Received(29, 30.0), Timeouts(1, 29)));
        Assert.Equal(29, r.Metrics.ValidResponseCount);
        Assert.Equal(3.3333333333333335, r.Metrics.PacketLossPercentage, Tol);
        Assert.Equal(84, r.RawScore);
        Assert.Equal(59, r.FinalScore);
        Assert.Equal(ScoreGuardrails.ExcessiveLossOrLatency, r.AppliedGuardrails);
    }

    [Fact]
    public void BR010_p50_at_hundred_does_not_apply_latency_guardrail()
    {
        var r = Completed(Received(30, 100.0));
        Assert.Equal(65, r.RawScore);
        Assert.Equal(65, r.FinalScore);
        Assert.Equal(ScoreGuardrails.None, r.AppliedGuardrails);
    }

    [Fact]
    public void BR011_p50_above_hundred_applies_latency_guardrail()
    {
        var r = Completed(Received(30, 101.0));
        Assert.Equal(65, r.RawScore);
        Assert.Equal(59, r.FinalScore);
        Assert.Equal(ScoreGuardrails.ExcessiveLossOrLatency, r.AppliedGuardrails);
    }

    [Fact]
    public void BR012_jitter_uses_consecutive_rtts_in_send_sequence()
    {
        var samples = Concat([ProbeSample.Received(0, 30.0), ProbeSample.Received(1, 60.0)], Received(28, 30.0, startingAt: 2));
        Assert.Equal(60.0 / 29.0, Completed(samples).Metrics.JitterMilliseconds!.Value, Tol);
    }

    [Fact]
    public void Jitter_ignores_list_order_and_follows_send_sequence()
    {
        var ordered = Concat([ProbeSample.Received(0, 30.0), ProbeSample.Received(1, 60.0)], Received(28, 30.0, startingAt: 2));
        var shuffled = ordered.AsEnumerable().Reverse().ToList();
        Assert.Equal(
            Completed(ordered).Metrics.JitterMilliseconds!.Value,
            Completed(shuffled).Metrics.JitterMilliseconds!.Value,
            Tol);
    }

    [Fact]
    public void Percentiles_use_linear_interpolation()
    {
        double[] values = [10, 20, 30, 40];
        Assert.Equal(25.0, QualityEvaluator.Percentile(values, 0.50), Tol);
        Assert.Equal(38.5, QualityEvaluator.Percentile(values, 0.95), Tol);
        Assert.Equal(39.7, QualityEvaluator.Percentile(values, 0.99), Tol);
    }

    [Fact]
    public void Jitter_is_mean_of_absolute_adjacent_differences()
    {
        // |20-10| + |5-20| + |10-5| = 30 -> 30 / 3
        Assert.Equal(10.0, QualityEvaluator.AverageAdjacentDifference([10, 20, 5, 10]), Tol);
        Assert.Equal(0.0, QualityEvaluator.AverageAdjacentDifference([42]));
    }

    [Fact]
    public void Out_of_order_arrival_is_counted_but_does_not_reorder_jitter()
    {
        // Sequência 3 chega antes da 2.
        var samples = Received(30, 30.0).Select(s => s with { ArrivalIndex = s.Sequence }).ToList();
        samples[2] = samples[2] with { ArrivalIndex = 3 };
        samples[3] = samples[3] with { ArrivalIndex = 2 };
        var r = Completed(samples);
        Assert.Equal(1, r.Metrics.OutOfOrderCount);
        Assert.Equal(0.0, r.Metrics.JitterMilliseconds);
    }

    [Fact]
    public void MR001_mobile_stable()
    {
        var r = Completed(Received(30, 50.0), QualityProfileId.MobileRealtime);
        Assert.Equal(100, r.FinalScore);
        Assert.Equal(ResultClass.Excellent, r.ResultClass);
    }

    [Fact]
    public void MR002_mobile_loss_above_five_percent()
    {
        var r = Completed(Concat(Received(28, 50.0), Timeouts(2, 28)), QualityProfileId.MobileRealtime);
        Assert.Equal(6.666666666666667, r.Metrics.PacketLossPercentage, Tol);
        Assert.Equal(59, r.FinalScore);
        Assert.Equal(ScoreGuardrails.ExcessiveLossOrLatency, r.AppliedGuardrails);
    }

    [Fact]
    public void CR001_casual_stable()
    {
        var r = Completed(Received(30, 70.0), QualityProfileId.CasualRealtime);
        Assert.Equal(100, r.FinalScore);
        Assert.Equal(ResultClass.Excellent, r.ResultClass);
    }

    [Fact]
    public void CR002_casual_latency_above_180()
    {
        var r = Completed(Received(30, 181.0), QualityProfileId.CasualRealtime);
        Assert.Equal(59, r.FinalScore);
        Assert.Equal(ScoreGuardrails.ExcessiveLossOrLatency, r.AppliedGuardrails);
    }

    [Fact]
    public void Rule_versions_are_stable()
    {
        Assert.Equal("pilot-2026.09.08.1", QualityEvaluator.RuleVersion(QualityProfileId.BattleRoyaleCompetitive));
        Assert.Equal("mobile-realtime-2026.09.08.1", QualityEvaluator.RuleVersion(QualityProfileId.MobileRealtime));
        Assert.Equal("casual-realtime-2026.09.08.1", QualityEvaluator.RuleVersion(QualityProfileId.CasualRealtime));
    }

    [Fact]
    public void Same_samples_always_give_the_same_result()
    {
        var samples = Concat(Received(25, 41.0), [ProbeSample.Received(25, 120.0)], Received(4, 38.0, startingAt: 26));
        Assert.Equal(Completed(samples).FinalScore, Completed(samples).FinalScore);
        Assert.Equal(Completed(samples).Metrics, Completed(samples).Metrics);
    }
}
