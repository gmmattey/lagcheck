namespace LagCheck.WinUI.Diagnostic.Rules;

/// <summary>
/// Port de <c>QualityEvaluator</c> (Android/iOS). Regras determinísticas e versionadas por perfil.
/// Qualquer mudança de número aqui exige nova versão de regra, vetores e revisão do Iury.
/// </summary>
public static class QualityEvaluator
{
    public static string RuleVersion(QualityProfileId profile) => profile switch
    {
        QualityProfileId.BattleRoyaleCompetitive => "pilot-2026.09.08.1",
        QualityProfileId.MobileRealtime => "mobile-realtime-2026.09.08.1",
        QualityProfileId.CasualRealtime => "casual-realtime-2026.09.08.1",
        _ => throw new ArgumentOutOfRangeException(nameof(profile))
    };

    /// <summary>Guardrails usados para escolher a causa principal. Único ponto de verdade.</summary>
    public sealed record CauseGuardrails(
        double LossGuardrailPercentage,
        double LatencyGuardrailMilliseconds,
        int SevereSpikeGuardrailCount,
        double JitterRiskMilliseconds);

    public static CauseGuardrails GetCauseGuardrails(QualityProfileId profile)
    {
        var rule = ProfileRule.Of(profile);
        return new CauseGuardrails(rule.LossGuardrail, rule.LatencyGuardrail, rule.SevereSpikeGuardrailCount, rule.Jitter.Unstable);
    }

    /// <summary>Limites de spike (spike, spike severo) do perfil: offset sobre o P50 e piso absoluto.</summary>
    public static (double SpikeOffset, double SpikeFloor, double SevereOffset, double SevereFloor) SpikeThresholds(QualityProfileId profile)
    {
        var rule = ProfileRule.Of(profile);
        return (rule.SpikeOffset, rule.SpikeFloor, rule.SevereSpikeOffset, rule.SevereSpikeFloor);
    }

    public static MeasurementEvaluation Evaluate(IReadOnlyList<ProbeSample> samples, QualityProfileId profile)
    {
        var rule = ProfileRule.Of(profile);

        // Jitter usa a ordem de envio; chegada fora de ordem não reordena a série (spec 5.2.1).
        var validRtts = samples
            .Where(s => s.IsValidResponse)
            .OrderBy(s => s.Sequence)
            .Select(s => s.RoundTripMilliseconds!.Value)
            .ToList();
        int timeoutCount = samples.Count(s => s.Outcome == ProbeOutcome.Timeout);
        int invalidCount = samples.Count(s => s.Outcome == ProbeOutcome.InvalidResponse);
        double loss = (double)timeoutCount / ProbeAcceptancePolicy.PlannedProbeCount * 100.0;

        if (validRtts.Count < ProbeAcceptancePolicy.MinimumValidResponses)
        {
            return new MeasurementEvaluation.Inconclusive(
                InconclusiveReason.InsufficientUdpResponses,
                DiagnosticMetrics(validRtts, timeoutCount, invalidCount, loss, rule));
        }

        double p50 = Percentile(validRtts, 0.50);
        double p95 = Percentile(validRtts, 0.95);
        double p99 = Percentile(validRtts, 0.99);
        double jitter = AverageAdjacentDifference(validRtts);
        double ratio = TailRatio(p50, p95);
        int spikeCount = validRtts.Count(v => v > p50 + rule.SpikeOffset && v >= rule.SpikeFloor);
        int severeCount = validRtts.Count(v => v > p50 + rule.SevereSpikeOffset && v >= rule.SevereSpikeFloor);
        double spikeRate = (double)spikeCount / validRtts.Count * 100.0;

        double latencyC = Component(p50, rule.Latency);
        double lossC = Component(loss, rule.Loss);
        double jitterC = Component(jitter, rule.Jitter);
        double tailC = Component(ratio, rule.Tail);
        double spikesC = Component(spikeRate, rule.SpikeRate);
        double consistency = Math.Clamp(0.40 * jitterC + 0.30 * tailC + 0.20 * spikesC + 0.10 * lossC, 0.0, 100.0);
        var components = new QualityComponents(latencyC, lossC, jitterC, tailC, spikesC, consistency, Math.Min(spikesC, consistency));

        // Reordenação (RFC 4737): chegou com sequência menor que a maior já vista.
        var byArrival = samples
            .Where(s => s.IsValidResponse && s.ArrivalIndex is not null)
            .OrderBy(s => s.ArrivalIndex!.Value);
        int outOfOrder = 0;
        int maxSeq = -1;
        foreach (var sample in byArrival)
        {
            if (maxSeq >= 0 && sample.Sequence < maxSeq) outOfOrder++;
            else maxSeq = Math.Max(maxSeq, sample.Sequence);
        }

        var metrics = new QualityMetrics(
            ValidResponseCount: validRtts.Count,
            TimeoutCount: timeoutCount,
            InvalidResponseCount: invalidCount,
            P50Milliseconds: p50,
            P95Milliseconds: p95,
            P99Milliseconds: p99,
            JitterMilliseconds: jitter,
            PacketLossPercentage: loss,
            SpikeCount: spikeCount,
            SevereSpikeCount: severeCount,
            SpikeRatePercentage: spikeRate,
            P95ToP50Ratio: ratio,
            WorstSpikeMilliseconds: validRtts.Max(),
            OutOfOrderCount: outOfOrder,
            OutOfOrderRatePercentage: (double)outOfOrder / validRtts.Count * 100.0,
            Components: components);

        int rawScore = RoundHalfAwayFromZero(
            0.35 * components.Latency + 0.30 * components.Loss + 0.20 * components.Jitter + 0.15 * components.Stability);

        var guardrails = ScoreGuardrails.None;
        int finalScore = rawScore;
        if (loss > rule.LossGuardrail || p50 > rule.LatencyGuardrail)
        {
            guardrails |= ScoreGuardrails.ExcessiveLossOrLatency;
            finalScore = Math.Min(finalScore, 59);
        }
        if (severeCount >= rule.SevereSpikeGuardrailCount)
        {
            guardrails |= ScoreGuardrails.SevereSpikes;
            finalScore = Math.Min(finalScore, 74);
        }

        return new MeasurementEvaluation.Completed(new QualityResult(metrics, rawScore, finalScore, ClassOf(finalScore), guardrails));
    }

    // region Perfis

    private readonly record struct Thresholds(double Excellent, double Great, double Unstable, double Risk);

    private sealed record ProfileRule(
        Thresholds Latency,
        Thresholds Loss,
        Thresholds Jitter,
        Thresholds Tail,
        Thresholds SpikeRate,
        double SpikeOffset,
        double SpikeFloor,
        double SevereSpikeOffset,
        double SevereSpikeFloor,
        double LossGuardrail,
        double LatencyGuardrail,
        int SevereSpikeGuardrailCount)
    {
        public static ProfileRule Of(QualityProfileId profile) => profile switch
        {
            QualityProfileId.BattleRoyaleCompetitive => new ProfileRule(
                Latency: new(40, 60, 90, 100),
                Loss: new(0, 1, 3, 5),
                Jitter: new(8, 15, 25, 40),
                Tail: new(1.10, 1.35, 1.75, 2.50),
                SpikeRate: new(0, 3, 10, 20),
                SpikeOffset: 30, SpikeFloor: 80, SevereSpikeOffset: 80, SevereSpikeFloor: 150,
                LossGuardrail: 3, LatencyGuardrail: 100, SevereSpikeGuardrailCount: 2),
            QualityProfileId.MobileRealtime => new ProfileRule(
                Latency: new(50, 80, 120, 120),
                Loss: new(0, 1, 5, 8),
                Jitter: new(12, 20, 35, 50),
                Tail: new(1.15, 1.50, 2.00, 2.75),
                SpikeRate: new(0, 4, 12, 25),
                SpikeOffset: 40, SpikeFloor: 100, SevereSpikeOffset: 100, SevereSpikeFloor: 200,
                LossGuardrail: 5, LatencyGuardrail: 130, SevereSpikeGuardrailCount: 2),
            QualityProfileId.CasualRealtime => new ProfileRule(
                Latency: new(70, 110, 170, 170),
                Loss: new(0, 1, 3, 5),
                Jitter: new(20, 35, 50, 65),
                Tail: new(1.20, 1.60, 2.20, 3.00),
                SpikeRate: new(0, 5, 15, 30),
                SpikeOffset: 60, SpikeFloor: 140, SevereSpikeOffset: 140, SevereSpikeFloor: 300,
                LossGuardrail: 3, LatencyGuardrail: 180, SevereSpikeGuardrailCount: 3),
            _ => throw new ArgumentOutOfRangeException(nameof(profile))
        };
    }

    // endregion

    private static QualityMetrics DiagnosticMetrics(
        List<double> validRtts, int timeoutCount, int invalidCount, double loss, ProfileRule rule)
    {
        bool hasData = validRtts.Count > 0;
        double? p50 = hasData ? Percentile(validRtts, 0.50) : null;
        double? p95 = hasData ? Percentile(validRtts, 0.95) : null;
        double? p99 = hasData ? Percentile(validRtts, 0.99) : null;
        double? jitter = hasData ? AverageAdjacentDifference(validRtts) : null;
        double? ratio = p50 is { } m50 && p95 is { } m95 ? TailRatio(m50, m95) : null;
        int spikes = p50 is { } a ? validRtts.Count(v => v > a + rule.SpikeOffset && v >= rule.SpikeFloor) : 0;
        int severe = p50 is { } b ? validRtts.Count(v => v > b + rule.SevereSpikeOffset && v >= rule.SevereSpikeFloor) : 0;
        return new QualityMetrics(
            validRtts.Count, timeoutCount, invalidCount, p50, p95, p99, jitter, loss, spikes, severe,
            hasData ? (double)spikes / validRtts.Count * 100.0 : 0.0,
            ratio,
            hasData ? validRtts.Max() : null);
    }

    private static double TailRatio(double p50, double p95) =>
        p50 == 0.0 ? (p95 == 0.0 ? 1.0 : double.PositiveInfinity) : p95 / p50;

    /// <summary>Percentil por interpolação linear entre vizinhos, idêntico ao Swift/Kotlin.</summary>
    public static double Percentile(IReadOnlyList<double> values, double percentile)
    {
        var sorted = values.OrderBy(v => v).ToList();
        double position = (sorted.Count - 1) * percentile;
        int lower = (int)Math.Floor(position);
        int upper = (int)Math.Ceiling(position);
        return sorted[lower] + (sorted[upper] - sorted[lower]) * (position - lower);
    }

    /// <summary>Jitter: média de |RTT[n] − RTT[n−1]| na ordem recebida.</summary>
    public static double AverageAdjacentDifference(IReadOnlyList<double> values)
    {
        if (values.Count <= 1) return 0.0;
        double total = 0.0;
        for (int i = 1; i < values.Count; i++) total += Math.Abs(values[i] - values[i - 1]);
        return total / (values.Count - 1);
    }

    private static double Component(double value, Thresholds t)
    {
        if (value <= t.Excellent) return 100.0;
        if (value <= t.Great) return Interpolate(value, t.Excellent, t.Great, 100.0, 80.0);
        if (value <= t.Unstable) return Interpolate(value, t.Great, t.Unstable, 80.0, 60.0);
        if (value < t.Risk) return Interpolate(value, t.Unstable, t.Risk, 60.0, 0.0);
        return 0.0;
    }

    private static double Interpolate(double value, double from, double to, double start, double end) =>
        start + (end - start) * ((value - from) / (to - from));

    private static int RoundHalfAwayFromZero(double value) =>
        value >= 0 ? (int)Math.Floor(value + 0.5) : -(int)Math.Floor(-value + 0.5);

    private static ResultClass ClassOf(int score) => score switch
    {
        >= 90 => ResultClass.Excellent,
        >= 75 => ResultClass.Great,
        >= 60 => ResultClass.Unstable,
        _ => ResultClass.LagRisk
    };
}
