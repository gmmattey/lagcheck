namespace LagCheck.WinUI.Diagnostic.Rules;

/// <summary>Distribuição temporal de spikes (<c>spike-pattern-v1</c>).</summary>
public static class SpikePatternEvaluator
{
    public const string Version = "spike-pattern-v1";

    public static SpikePattern Evaluate(
        IReadOnlyList<ProbeSample> samples,
        double p50Milliseconds,
        double spikeDelta = 30.0,
        double spikeAbsoluteMin = 80.0,
        double severeDelta = 80.0,
        double severeAbsoluteMin = 150.0)
    {
        var valid = samples.Where(s => s.IsValidResponse).ToList();
        if (valid.Count == 0) return new SpikePattern.None();

        int totalSpikes = 0;
        int totalSevere = 0;
        var flags = new List<bool>(valid.Count);
        foreach (var sample in valid)
        {
            double rtt = sample.RoundTripMilliseconds!.Value;
            bool isSevere = rtt > p50Milliseconds + severeDelta && rtt >= severeAbsoluteMin;
            bool isSpike = isSevere || (rtt > p50Milliseconds + spikeDelta && rtt >= spikeAbsoluteMin);
            if (isSpike) totalSpikes++;
            if (isSevere) totalSevere++;
            flags.Add(isSpike);
        }
        if (totalSpikes == 0) return new SpikePattern.None();
        if (totalSpikes >= 3) return new SpikePattern.Recurring(totalSpikes, totalSevere);

        if (flags.Count >= 2)
        {
            for (int i = 0; i < flags.Count; i++)
            {
                int end = Math.Min(i + 5, flags.Count);
                int inWindow = 0;
                for (int j = i; j < end; j++) if (flags[j]) inWindow++;
                if (inWindow >= 2) return new SpikePattern.Recurring(totalSpikes, totalSevere);
            }
        }
        return new SpikePattern.Isolated(totalSpikes, totalSevere);
    }
}

public sealed record SampleQualityAssessment(
    bool ShouldAbort,
    InconclusiveReason? AbortReason,
    int ConsecutiveTimeouts,
    double EarlyLossPercentage);

/// <summary>Watchdog determinístico (<c>sample-quality-v1</c>): evita esperar 15 s por uma conexão morta.</summary>
public static class SampleQualityEvaluator
{
    public const string RuleVersion = "sample-quality-v1";

    public static SampleQualityAssessment Assess(IReadOnlyList<ProbeSample> samples)
    {
        if (samples.Count == 0) return new SampleQualityAssessment(false, null, 0, 0.0);
        var sorted = samples.OrderBy(s => s.Sequence).ToList();

        int trailing = 0;
        for (int i = sorted.Count - 1; i >= 0; i--)
        {
            if (sorted[i].Outcome == ProbeOutcome.Received) break;
            trailing++;
        }
        int nonReceived = sorted.Count(s => s.Outcome != ProbeOutcome.Received);
        double loss = (double)nonReceived / sorted.Count * 100.0;

        bool abort = (sorted.Count <= 6 && trailing >= 4)
            || (sorted.Count is >= 6 and <= 10 && loss >= 70.0)
            || trailing >= 6;
        return new SampleQualityAssessment(
            abort,
            abort ? InconclusiveReason.PoorSampleQuality : null,
            trailing,
            loss);
    }
}
