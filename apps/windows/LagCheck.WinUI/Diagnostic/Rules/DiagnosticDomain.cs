namespace LagCheck.WinUI.Diagnostic.Rules;

// Port 1:1 dos modelos de domínio do Android (core/domain) e do iOS (NolaggyDomain).
// Sem dependência de WinUI, rede ou persistência: tudo aqui é puro e testável.

public enum QualityProfileId { BattleRoyaleCompetitive, MobileRealtime, CasualRealtime }

public enum ProbeOutcome { Received, Timeout, TransportError, InvalidResponse }

/// <summary>
/// Amostra já classificada pelo transporte. <c>Sequence</c> é a ordem de envio;
/// <c>ArrivalIndex</c> é a ordem de chegada (reordenação, RFC 4737).
/// </summary>
public sealed record ProbeSample(int Sequence, double? RoundTripMilliseconds, ProbeOutcome Outcome, int? ArrivalIndex = null)
{
    public bool IsValidResponse => Outcome == ProbeOutcome.Received && RoundTripMilliseconds is not null;

    public static ProbeSample Received(int sequence, double rtt, int? arrivalIndex = null) =>
        new(sequence, rtt, ProbeOutcome.Received, arrivalIndex);

    public static ProbeSample Timeout(int sequence) => new(sequence, null, ProbeOutcome.Timeout);
}

public static class ProbeAcceptancePolicy
{
    public const int PlannedProbeCount = 30;
    public const int SendIntervalMillis = 500;
    public const int TimeoutMillis = 2_000;
    public const int ClosureMillis = 17_000;
    public const int MinimumValidResponses = 10;

    /// <summary>Classifica somente tempo. A correlação do payload pertence ao transporte.</summary>
    public static ProbeOutcome Classify(double sentAtSeconds, double receivedAtSeconds)
    {
        double elapsed = receivedAtSeconds - sentAtSeconds;
        return elapsed >= 0 && elapsed < TimeoutMillis / 1000.0 && receivedAtSeconds <= ClosureMillis / 1000.0
            ? ProbeOutcome.Received
            : ProbeOutcome.Timeout;
    }
}

public enum ResultClass { Excellent, Great, Unstable, LagRisk }

/// <summary>Teto aplicado ao score. Flags para manter igualdade por valor nos records de resultado.</summary>
[Flags]
public enum ScoreGuardrails { None = 0, ExcessiveLossOrLatency = 1, SevereSpikes = 2 }

public enum InconclusiveReason { InsufficientUdpResponses, PoorSampleQuality }

public sealed record QualityComponents(
    double Latency,
    double Loss,
    double Jitter,
    double Tail,
    double Spikes,
    double Consistency,
    double Stability);

public sealed record QualityMetrics(
    int ValidResponseCount,
    int TimeoutCount,
    int InvalidResponseCount,
    double? P50Milliseconds,
    double? P95Milliseconds,
    double? P99Milliseconds,
    double? JitterMilliseconds,
    double PacketLossPercentage,
    int SpikeCount,
    int SevereSpikeCount,
    double SpikeRatePercentage,
    double? P95ToP50Ratio,
    double? WorstSpikeMilliseconds = null,
    int OutOfOrderCount = 0,
    double OutOfOrderRatePercentage = 0.0,
    QualityComponents? Components = null);

public sealed record QualityResult(
    QualityMetrics Metrics,
    int RawScore,
    int FinalScore,
    ResultClass ResultClass,
    ScoreGuardrails AppliedGuardrails);

public abstract record MeasurementEvaluation
{
    private MeasurementEvaluation() { }

    public sealed record Completed(QualityResult Result) : MeasurementEvaluation;

    public sealed record Inconclusive(InconclusiveReason Reason, QualityMetrics Diagnostics) : MeasurementEvaluation;
}

/// <summary>Distribuição temporal de spikes (spike-pattern-v1).</summary>
public abstract record SpikePattern
{
    private SpikePattern() { }

    public sealed record None : SpikePattern;

    public sealed record Isolated(int Count, int SevereCount) : SpikePattern;

    public sealed record Recurring(int Count, int SevereCount) : SpikePattern;

    public bool IsRecurring => this is Recurring;

    public int SevereSpikes => this switch
    {
        Isolated i => i.SevereCount,
        Recurring r => r.SevereCount,
        _ => 0
    };
}

public enum MeasurementConfidence { High, Medium }

public enum GameReadinessVerdict { Ready, Caution, NotReady, Inconclusive }

public enum PrimaryCause
{
    StableConnection, PacketLoss, HighLatency, SevereSpikes, HighJitter,
    LoadDegradation, LoadInstability, TailLatency, OutOfOrder
}
