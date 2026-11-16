using System.Globalization;
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
    DateTimeOffset CapturedAt,
    bool ConnectToPrevious = false,
    int SegmentIndex = 0,
    string? NetworkType = null);

/// <summary>
/// Resumo determinístico da estabilidade da rede (Visão geral ou filtrado por jogo)
/// espelhando o avaliador único KMP `stability-summary-v1` (Decisão 143).
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
    double? AvgLoadDelta,
    bool CanDrawCurve = false,
    bool HasSummary = false,
    bool HasMixedContexts = false,
    IReadOnlyList<string>? AvailableNetworks = null,
    int InconclusiveCount = 0,
    double? AvgLoss = null)
{
    private const int MinimumComparableChecks = 3;
    private const double MaxValidPingMs = 10000.0;

    public bool HasData => TotalCount > 0;
    public IReadOnlyList<string> Networks => AvailableNetworks ?? Array.Empty<string>();

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
        null,
        CanDrawCurve: false,
        HasSummary: false,
        HasMixedContexts: false,
        AvailableNetworks: Array.Empty<string>(),
        InconclusiveCount: 0);

    public static NetworkStabilitySummary Build(
        IEnumerable<SessionHistoryEntry> history,
        string? gameIdFilter = null,
        int maxPoints = 24,
        int windowDays = 0,
        string? networkFilter = null,
        DateTimeOffset? now = null)
    {
        if (history is null) return Empty;

        var refNow = now ?? DateTimeOffset.UtcNow;
        var cutoff = windowDays > 0 ? refNow.AddDays(-windowDays) : DateTimeOffset.MinValue;
        var filterByGeneralOnly = string.Equals(gameIdFilter, SessionHistoryStore.GeneralGameId, StringComparison.OrdinalIgnoreCase);
        var filterByGame = !string.IsNullOrWhiteSpace(gameIdFilter) && !filterByGeneralOnly;
        var normalizedNetworkFilter = NormalizeNetwork(networkFilter);

        var scoped = new List<(SessionHistoryEntry Entry, VerdictTone Tone, double Ping, string? Network)>();
        var availableNetworks = new HashSet<string>(StringComparer.Ordinal);
        var inconclusiveCount = 0;

        foreach (var entry in history)
        {
            if (!entry.HasCapturedAt) continue;
            if (windowDays > 0 && (entry.CapturedAt < cutoff || entry.CapturedAt > refNow)) continue;

            if (filterByGeneralOnly && entry.EffectiveGameKey is not null) continue;
            if (filterByGame && !SessionHistoryStore.MatchesGame(entry, gameIdFilter)) continue;

            var tone = Verdicts.ToneOf(entry.Verdict);
            if (tone == VerdictTone.Unknown)
            {
                if (IsInconclusiveVerdict(entry.Verdict))
                {
                    inconclusiveCount++;
                }
                continue;
            }

            if (entry.PingMs is not { } ping || !double.IsFinite(ping) || ping < 0 || ping > MaxValidPingMs) continue;

            var net = NormalizeNetwork(entry.NetworkType);
            if (net is not null)
            {
                availableNetworks.Add(net);
            }
            if (normalizedNetworkFilter is not null && !string.Equals(net, normalizedNetworkFilter, StringComparison.Ordinal))
            {
                continue;
            }

            scoped.Add((entry, tone, ping, net));
        }

        if (scoped.Count == 0)
        {
            return Empty with
            {
                AvailableNetworks = SortNetworks(availableNetworks),
                InconclusiveCount = inconclusiveCount,
            };
        }

        scoped.Sort((a, b) => a.Entry.CapturedAt.CompareTo(b.Entry.CapturedAt));

        var ready = 0;
        var caution = 0;
        var bad = 0;
        var minPing = double.MaxValue;
        var maxPing = double.MinValue;
        var pingSum = 0.0;

        var jitterSum = 0.0;
        var jitterCount = 0;
        double? maxLoss = null;
        var lossSum = 0.0;
        var lossCount = 0;
        var loadSum = 0.0;
        var loadCount = 0;

        foreach (var (entry, tone, ping, _) in scoped)
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
                lossSum += loss;
                lossCount++;
            }

            if (entry.LoadDeltaMs is { } load && double.IsFinite(load))
            {
                loadSum += load;
                loadCount++;
            }
        }

        var total = scoped.Count;
        var pct = (int)Math.Round(ready * 100.0 / total);
        var latestTone = scoped[^1].Tone;
        var lastTwoBad = total >= 2 && scoped[^1].Tone == VerdictTone.Bad && scoped[^2].Tone == VerdictTone.Bad;

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

        var pointSlice = maxPoints > 0 && scoped.Count > maxPoints
            ? scoped.GetRange(scoped.Count - maxPoints, maxPoints)
            : scoped;

        var segmentByIndex = new int[pointSlice.Count];
        var segmentCounts = new Dictionary<int, int>();
        var currentSeg = 0;
        for (var i = 0; i < pointSlice.Count; i++)
        {
            if (i > 0 && !SameTimelineContext(pointSlice[i - 1], pointSlice[i]))
            {
                currentSeg++;
            }
            segmentByIndex[i] = currentSeg;
            segmentCounts[currentSeg] = segmentCounts.TryGetValue(currentSeg, out var count) ? count + 1 : 1;
        }

        var points = new StabilityPoint[pointSlice.Count];
        var canDrawCurve = false;
        var distinctContexts = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        for (var i = 0; i < pointSlice.Count; i++)
        {
            var item = pointSlice[i];
            var seg = segmentByIndex[i];
            var connect = i > 0 && segmentByIndex[i - 1] == seg && segmentCounts[seg] >= MinimumComparableChecks;
            if (connect) canDrawCurve = true;
            distinctContexts.Add($"{item.Network ?? ""}|{item.Entry.RegionId?.Trim() ?? ""}");

            points[i] = new StabilityPoint(
                PingMs: item.Ping,
                JitterMs: item.Entry.JitterMs,
                LossPercentage: item.Entry.PacketLossPercentage,
                LoadDeltaMs: item.Entry.LoadDeltaMs,
                Tone: item.Tone,
                GameId: item.Entry.GameId,
                GameTitle: item.Entry.GameTitle,
                RegionId: item.Entry.RegionId,
                CapturedAt: item.Entry.CapturedAt,
                ConnectToPrevious: connect,
                SegmentIndex: seg,
                NetworkType: item.Network);
        }

        return new NetworkStabilitySummary(
            Points: points,
            Latest: scoped[^1].Entry,
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
            AvgLoadDelta: loadCount > 0 ? loadSum / loadCount : null,
            CanDrawCurve: canDrawCurve,
            HasSummary: total >= MinimumComparableChecks,
            HasMixedContexts: distinctContexts.Count > 1,
            AvailableNetworks: SortNetworks(availableNetworks),
            InconclusiveCount: inconclusiveCount,
            AvgLoss: lossCount > 0 ? lossSum / lossCount : null);
    }

    public static string HeadlineKey(VerdictTone tone) => tone switch
    {
        VerdictTone.Ok => "Rede estável",
        VerdictTone.Warn => "Oscilação moderada",
        VerdictTone.Bad => "Rede instável",
        _ => "Sem medições",
    };

    public static string HeadlineWord(VerdictTone tone) => Strings.Tr(HeadlineKey(tone));

    public static string LocalizedNetworkLabel(string networkType) => networkType.ToUpperInvariant() switch
    {
        "WIFI" => Strings.Tr("Wi-Fi"),
        "CELLULAR" => Strings.Tr("Rede móvel"),
        "ETHERNET" => Strings.Tr("Ethernet"),
        _ => Strings.Tr("Outro"),
    };

    private static bool SameTimelineContext(
        (SessionHistoryEntry Entry, VerdictTone Tone, double Ping, string? Network) left,
        (SessionHistoryEntry Entry, VerdictTone Tone, double Ping, string? Network) right) =>
        string.Equals(left.Network ?? string.Empty, right.Network ?? string.Empty, StringComparison.OrdinalIgnoreCase) &&
        string.Equals(left.Entry.RegionId?.Trim() ?? string.Empty, right.Entry.RegionId?.Trim() ?? string.Empty, StringComparison.OrdinalIgnoreCase);

    private static string? NormalizeNetwork(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return null;
        return raw.Trim().ToUpperInvariant() switch
        {
            "WIFI" or "WI-FI" => "WIFI",
            "CELLULAR" or "MOBILE" => "CELLULAR",
            "ETHERNET" or "CABLE" => "ETHERNET",
            _ => "OTHER",
        };
    }

    private static IReadOnlyList<string> SortNetworks(HashSet<string> networks)
    {
        if (networks.Count == 0) return Array.Empty<string>();
        return networks
            .OrderBy(net => net switch
            {
                "ETHERNET" => 0,
                "WIFI" => 1,
                "CELLULAR" => 2,
                _ => 3,
            })
            .ToArray();
    }

    private static bool IsInconclusiveVerdict(string? verdict)
    {
        if (string.IsNullOrWhiteSpace(verdict)) return false;
        var norm = verdict.Trim().ToUpperInvariant();
        return norm.Contains("INCONCLUSIV", StringComparison.Ordinal) || norm.Contains("INSUFICIENT", StringComparison.Ordinal);
    }
}
