using LagCheck.WinUI.Controls;
using LagCheck.WinUI.Localization;

namespace LagCheck.WinUI.History;

public sealed record StabilityPoint(
    double PingMs,
    double? JitterMs,
    double? LossPercentage,
    double? LoadDeltaMs,
    VerdictTone Tone,
    string? GameId,
    string? GameTitle,
    string? RegionId,
    DateTimeOffset CapturedAt);

/// <summary>
/// Resumo determinístico da estabilidade da rede (Geral ou filtrado por jogo) a partir das medições reais.
/// </summary>
public sealed record NetworkStabilitySummary(
    IReadOnlyList<StabilityPoint> Points,
    SessionHistoryEntry? Latest,
    int TotalCount,
    int ReadyCount,
    int CautionCount,
    int BadCount,
    int StabilityPercentage,
    VerdictTone StabilityTone,
    double MinPing,
    double AvgPing,
    double MaxPing,
    double? AvgJitter,
    double? MaxLoss,
    double? AvgLoadDelta)
{
    public bool HasData => TotalCount > 0;

    public static NetworkStabilitySummary Empty { get; } = new(
        Array.Empty<StabilityPoint>(),
        null,
        0,
        0,
        0,
        0,
        0,
        VerdictTone.Unknown,
        0,
        0,
        0,
        null,
        null,
        null);

    public static NetworkStabilitySummary Build(
        IEnumerable<SessionHistoryEntry> history,
        string? gameIdFilter = null,
        int maxPoints = 24)
    {
        if (history is null) return Empty;

        var filterByGeneralOnly = string.Equals(gameIdFilter, SessionHistoryStore.GeneralGameId, StringComparison.OrdinalIgnoreCase);
        var filterByGame = !string.IsNullOrWhiteSpace(gameIdFilter) && !filterByGeneralOnly;

        var matched = new List<(SessionHistoryEntry Entry, VerdictTone Tone, double Ping)>();
        foreach (var entry in history)
        {
            if (!entry.HasCapturedAt) continue;
            if (entry.PingMs is not { } ping || !double.IsFinite(ping) || ping < 0 || ping > 10000) continue;

            var tone = Verdicts.ToneOf(entry.Verdict);
            if (tone == VerdictTone.Unknown) continue;

            if (filterByGeneralOnly && entry.EffectiveGameKey is not null) continue;
            if (filterByGame && !SessionHistoryStore.MatchesGame(entry, gameIdFilter)) continue;

            matched.Add((entry, tone, ping));
        }

        if (matched.Count == 0) return Empty;

        matched.Sort((a, b) => a.Entry.CapturedAt.CompareTo(b.Entry.CapturedAt));

        var ready = 0;
        var caution = 0;
        var bad = 0;
        var minPing = double.MaxValue;
        var maxPing = double.MinValue;
        var pingSum = 0.0;

        var jitterSum = 0.0;
        var jitterCount = 0;
        double? maxLoss = null;
        var loadSum = 0.0;
        var loadCount = 0;

        foreach (var (entry, tone, ping) in matched)
        {
            switch (tone)
            {
                case VerdictTone.Ok: ready++; break;
                case VerdictTone.Warn: caution++; break;
                case VerdictTone.Bad: bad++; break;
            }

            if (ping < minPing) minPing = ping;
            if (ping > maxPing) maxPing = ping;
            pingSum += ping;

            if (entry.JitterMs is { } jitter && double.IsFinite(jitter) && jitter >= 0)
            {
                jitterSum += jitter;
                jitterCount++;
            }

            if (entry.PacketLossPercentage is { } loss && double.IsFinite(loss) && loss >= 0)
            {
                maxLoss = maxLoss is { } currentMax ? Math.Max(currentMax, loss) : loss;
            }

            if (entry.LoadDeltaMs is { } load && double.IsFinite(load))
            {
                loadSum += load;
                loadCount++;
            }
        }

        var total = matched.Count;
        var pct = (int)Math.Round(ready * 100.0 / total);
        var latestTone = matched[^1].Tone;
        var lastTwoBad = total >= 2 && matched[^1].Tone == VerdictTone.Bad && matched[^2].Tone == VerdictTone.Bad;

        VerdictTone stabilityTone;
        if (pct >= 75 && latestTone != VerdictTone.Bad)
        {
            stabilityTone = VerdictTone.Ok;
        }
        else if ((pct < 40 && bad > 0) || lastTwoBad)
        {
            stabilityTone = VerdictTone.Bad;
        }
        else
        {
            stabilityTone = VerdictTone.Warn;
        }

        var pointSlice = maxPoints > 0 && matched.Count > maxPoints
            ? matched.GetRange(matched.Count - maxPoints, maxPoints)
            : matched;

        var points = pointSlice.Select(item => new StabilityPoint(
            item.Ping,
            item.Entry.JitterMs,
            item.Entry.PacketLossPercentage,
            item.Entry.LoadDeltaMs,
            item.Tone,
            item.Entry.GameId,
            item.Entry.GameTitle,
            item.Entry.RegionId,
            item.Entry.CapturedAt)).ToArray();

        return new NetworkStabilitySummary(
            Points: points,
            Latest: matched[^1].Entry,
            TotalCount: total,
            ReadyCount: ready,
            CautionCount: caution,
            BadCount: bad,
            StabilityPercentage: pct,
            StabilityTone: stabilityTone,
            MinPing: minPing,
            AvgPing: pingSum / total,
            MaxPing: maxPing,
            AvgJitter: jitterCount > 0 ? jitterSum / jitterCount : null,
            MaxLoss: maxLoss,
            AvgLoadDelta: loadCount > 0 ? loadSum / loadCount : null);
    }

    public static string HeadlineKey(VerdictTone tone) => tone switch
    {
        VerdictTone.Ok => "Rede estável",
        VerdictTone.Warn => "Oscilação moderada",
        VerdictTone.Bad => "Rede instável",
        _ => "Sem medições",
    };

    public static string HeadlineWord(VerdictTone tone) => Strings.Tr(HeadlineKey(tone));
}
