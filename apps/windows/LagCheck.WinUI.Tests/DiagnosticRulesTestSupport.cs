using LagCheck.WinUI.Diagnostic.Rules;

namespace LagCheck.WinUI.Tests;

internal static class Probes
{
    public static List<ProbeSample> Received(int count, double rtt, int startingAt = 0) =>
        Enumerable.Range(0, count).Select(i => ProbeSample.Received(startingAt + i, rtt)).ToList();

    public static List<ProbeSample> Timeouts(int count, int startingAt) =>
        Enumerable.Range(0, count).Select(i => ProbeSample.Timeout(startingAt + i)).ToList();

    public static List<ProbeSample> Concat(params IEnumerable<ProbeSample>[] parts) => parts.SelectMany(p => p).ToList();

    public static QualityResult Completed(
        IReadOnlyList<ProbeSample> samples,
        QualityProfileId profile = QualityProfileId.BattleRoyaleCompetitive) =>
        QualityEvaluator.Evaluate(samples, profile) is MeasurementEvaluation.Completed c
            ? c.Result
            : throw new InvalidOperationException("Expected completed evaluation");
}
