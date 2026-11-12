using LagCheck.WinUI.Diagnostic.Rules;
using Xunit;

namespace LagCheck.WinUI.Tests;

/// <summary>Portado de SampleQualityAndSpikeTest.kt (sample-quality-v1 e spike-pattern-v1).</summary>
public sealed class SpikeAndSampleQualityTests
{
    private static ProbeSample Ok(int seq, double rtt) => ProbeSample.Received(seq, rtt);
    private static ProbeSample Lost(int seq) => ProbeSample.Timeout(seq);

    [Fact]
    public void Empty_is_normal()
    {
        var a = SampleQualityEvaluator.Assess([]);
        Assert.False(a.ShouldAbort);
        Assert.Equal(0, a.ConsecutiveTimeouts);
    }

    [Fact]
    public void Healthy_is_normal()
    {
        var a = SampleQualityEvaluator.Assess(Enumerable.Range(1, 15).Select(i => Ok(i, 25.0)).ToList());
        Assert.False(a.ShouldAbort);
        Assert.Equal(0.0, a.EarlyLossPercentage);
    }

    [Fact]
    public void Four_consecutive_timeouts_in_first_six_abort()
    {
        var a = SampleQualityEvaluator.Assess([Ok(1, 25.0), Lost(2), Lost(3), Lost(4), Lost(5)]);
        Assert.True(a.ShouldAbort);
        Assert.Equal(InconclusiveReason.PoorSampleQuality, a.AbortReason);
        Assert.Equal(4, a.ConsecutiveTimeouts);
    }

    [Fact]
    public void Severe_initial_loss_aborts()
    {
        var a = SampleQualityEvaluator.Assess([Ok(1, 20.0), Lost(2), Lost(3), Ok(4, 25.0), Lost(5), Lost(6), Lost(7), Lost(8), Lost(9)]);
        Assert.True(a.ShouldAbort);
        Assert.True(a.EarlyLossPercentage >= 70.0);
    }

    [Fact]
    public void Sudden_disconnect_with_six_timeouts_aborts()
    {
        var samples = Enumerable.Range(1, 12).Select(i => Ok(i, 22.0)).Concat(Enumerable.Range(13, 6).Select(Lost)).ToList();
        var a = SampleQualityEvaluator.Assess(samples);
        Assert.True(a.ShouldAbort);
        Assert.Equal(6, a.ConsecutiveTimeouts);
    }

    [Fact]
    public void Five_late_timeouts_do_not_abort()
    {
        var samples = Enumerable.Range(1, 12).Select(i => Ok(i, 22.0)).Concat(Enumerable.Range(13, 5).Select(Lost)).ToList();
        Assert.False(SampleQualityEvaluator.Assess(samples).ShouldAbort);
    }

    private static List<ProbeSample> Base() => Enumerable.Range(0, 30).Select(i => Ok(i, 25.0)).ToList();

    [Fact]
    public void No_spikes()
        => Assert.IsType<SpikePattern.None>(SpikePatternEvaluator.Evaluate(Base(), 25.0));

    [Fact]
    public void Single_spike_is_isolated()
    {
        var s = Base();
        s[10] = Ok(10, 85.0);
        Assert.Equal(new SpikePattern.Isolated(1, 0), SpikePatternEvaluator.Evaluate(s, 25.0));
    }

    [Fact]
    public void Two_dispersed_spikes_are_isolated()
    {
        var s = Base();
        s[2] = Ok(2, 85.0);
        s[20] = Ok(20, 85.0);
        Assert.Equal(new SpikePattern.Isolated(2, 0), SpikePatternEvaluator.Evaluate(s, 25.0));
    }

    [Fact]
    public void Two_spikes_in_close_window_are_recurring()
    {
        var s = Base();
        s[10] = Ok(10, 85.0);
        s[13] = Ok(13, 90.0);
        var p = SpikePatternEvaluator.Evaluate(s, 25.0);
        Assert.Equal(new SpikePattern.Recurring(2, 0), p);
        Assert.True(p.IsRecurring);
    }

    [Fact]
    public void Three_spikes_are_recurring_regardless_of_spacing()
    {
        var s = Base();
        s[1] = Ok(1, 85.0);
        s[15] = Ok(15, 85.0);
        s[28] = Ok(28, 85.0);
        Assert.Equal(new SpikePattern.Recurring(3, 0), SpikePatternEvaluator.Evaluate(s, 25.0));
    }

    [Fact]
    public void Severe_spikes_are_counted()
    {
        var s = Base();
        s[5] = Ok(5, 160.0);
        s[7] = Ok(7, 170.0);
        var p = SpikePatternEvaluator.Evaluate(s, 25.0);
        Assert.Equal(new SpikePattern.Recurring(2, 2), p);
        Assert.Equal(2, p.SevereSpikes);
    }
}
