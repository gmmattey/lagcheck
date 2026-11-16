using LagCheck.WinUI.Controls;
using LagCheck.WinUI.History;
using Xunit;

namespace LagCheck.WinUI.Tests;

public sealed class NetworkStabilitySummaryTests
{
    private static readonly DateTimeOffset BaseTime = DateTimeOffset.Parse("2026-11-15T10:00:00+00:00");

    private static SessionHistoryEntry MakeEntry(
        string id,
        string verdict,
        double? pingMs,
        int minutesOffset,
        string? gameId = "general",
        string? gameTitle = null,
        double? jitterMs = 2.0,
        double? lossPct = 0.0,
        double? loadDeltaMs = 6.0,
        bool hasCapturedAt = true) =>
        new(
            SessionId: id,
            Verdict: verdict,
            PingMs: pingMs,
            JitterMs: jitterMs,
            PacketLossPercentage: lossPct,
            RegionId: "sa-east-1",
            CapturedAt: BaseTime.AddMinutes(minutesOffset),
            GameId: gameId,
            GameTitle: gameTitle,
            HasCapturedAt: hasCapturedAt,
            LoadDeltaMs: loadDeltaMs);

    [Fact]
    public void Build_returns_empty_when_history_is_null_or_empty()
    {
        var nullSummary = NetworkStabilitySummary.Build(null!);
        var emptySummary = NetworkStabilitySummary.Build([]);

        Assert.False(nullSummary.HasData);
        Assert.Equal(VerdictTone.Unknown, nullSummary.StabilityTone);
        Assert.Empty(nullSummary.Points);

        Assert.False(emptySummary.HasData);
        Assert.Equal(VerdictTone.Unknown, emptySummary.StabilityTone);
        Assert.Equal(0, emptySummary.TotalCount);
    }

    [Fact]
    public void Build_ignores_entries_without_ping_capturedAt_or_known_verdict()
    {
        var entries = new[]
        {
            MakeEntry("no-ping", "ready", null, 0),
            MakeEntry("no-time", "ready", 18.0, 1, hasCapturedAt: false),
            MakeEntry("unknown-verdict", "inconclusive", 22.0, 2),
        };

        var summary = NetworkStabilitySummary.Build(entries);

        Assert.False(summary.HasData);
        Assert.Equal(0, summary.TotalCount);
    }

    [Fact]
    public void Build_single_warn_entry_preserves_warn_tone()
    {
        var summary = NetworkStabilitySummary.Build([
            MakeEntry("w1", "caution", 52.0, 0, gameId: "valorant", gameTitle: "VALORANT")
        ]);

        Assert.True(summary.HasData);
        Assert.Equal(1, summary.TotalCount);
        Assert.Equal(0, summary.ReadyCount);
        Assert.Equal(1, summary.CautionCount);
        Assert.Equal(0, summary.StabilityPercentage);
        Assert.Equal(VerdictTone.Warn, summary.StabilityTone);
        Assert.Equal("Oscilação moderada", NetworkStabilitySummary.HeadlineKey(summary.StabilityTone));
    }

    [Fact]
    public void Build_one_ready_and_one_warn_gives_fifty_percent_and_warn_tone()
    {
        var summary = NetworkStabilitySummary.Build([
            MakeEntry("r1", "ready", 20.0, 0),
            MakeEntry("w1", "caution", 48.0, 5),
        ]);

        Assert.Equal(2, summary.TotalCount);
        Assert.Equal(50, summary.StabilityPercentage);
        Assert.Equal(VerdictTone.Warn, summary.StabilityTone);
    }

    [Fact]
    public void Build_overall_mode_aggregates_general_and_all_games_chronologically()
    {
        var entries = new[]
        {
            MakeEntry("cs2-later", "ready", 30.0, 15, gameId: "cs2", gameTitle: "CS2", jitterMs: 3.0, lossPct: 1.5, loadDeltaMs: 12.0),
            MakeEntry("gen-first", "ready", 18.0, 0, gameId: "general", gameTitle: null, jitterMs: 1.0, lossPct: 0.0, loadDeltaMs: 4.0),
            MakeEntry("legacy-gen", "caution", 42.0, 10, gameId: "generic-gaming", gameTitle: null, jitterMs: 5.0, lossPct: 0.5, loadDeltaMs: 14.0),
            MakeEntry("null-gen", "ready", 22.0, 5, gameId: null, gameTitle: null, jitterMs: 3.0, lossPct: 0.0, loadDeltaMs: 10.0),
        };

        var summary = NetworkStabilitySummary.Build(entries, gameIdFilter: null);

        Assert.True(summary.HasData);
        Assert.Equal(4, summary.TotalCount);
        Assert.Equal(3, summary.ReadyCount);
        Assert.Equal(1, summary.CautionCount);
        Assert.Equal(75, summary.StabilityPercentage);
        Assert.Equal(VerdictTone.Ok, summary.StabilityTone);
        Assert.Equal(18.0, summary.MinPing);
        Assert.Equal(28.0, summary.AvgPing, precision: 2);
        Assert.Equal(42.0, summary.MaxPing);
        Assert.Equal(3.0, summary.AvgJitter!.Value, precision: 2);
        Assert.Equal(1.5, summary.MaxLoss!.Value, precision: 2);
        Assert.Equal(10.0, summary.AvgLoadDelta!.Value, precision: 2);
        Assert.Equal("general", summary.Points[0].GameId);
        Assert.Equal(BaseTime, summary.Points[0].CapturedAt);
        Assert.Equal("cs2-later", summary.Latest!.SessionId);
    }

    [Fact]
    public void Build_game_filter_includes_only_matching_game_and_excludes_others()
    {
        var entries = new[]
        {
            MakeEntry("g1", "not_ready", 140.0, 0, gameId: "general"),
            MakeEntry("v1", "ready", 20.0, 5, gameId: "valorant", gameTitle: "VALORANT"),
            MakeEntry("c1", "not_ready", 130.0, 10, gameId: "cs2", gameTitle: "CS2"),
            MakeEntry("v2", "ready", 24.0, 15, gameId: "VALORANT", gameTitle: "VALORANT"),
        };

        var summary = NetworkStabilitySummary.Build(entries, gameIdFilter: "valorant");

        Assert.Equal(2, summary.TotalCount);
        Assert.Equal(100, summary.StabilityPercentage);
        Assert.Equal(VerdictTone.Ok, summary.StabilityTone);
        Assert.Equal(20.0, summary.MinPing);
        Assert.Equal(22.0, summary.AvgPing);
        Assert.Equal(24.0, summary.MaxPing);
        Assert.All(summary.Points, pt => Assert.Equal("valorant", pt.GameId, ignoreCase: true));
    }

    [Fact]
    public void Build_stability_tone_respects_latest_bad_consecutive_bad_and_low_ratio_rules()
    {
        // 75% pronto mas último teste foi ruim -> não pode dizer "Rede estável"
        var latestBad = NetworkStabilitySummary.Build([
            MakeEntry("1", "ready", 20, 0),
            MakeEntry("2", "ready", 21, 1),
            MakeEntry("3", "ready", 22, 2),
            MakeEntry("4", "not_ready", 120, 3),
        ]);
        Assert.Equal(75, latestBad.StabilityPercentage);
        Assert.Equal(VerdictTone.Warn, latestBad.StabilityTone);

        // Últimos dois ruins -> Bad mesmo com 50% de taxa
        var lastTwoBad = NetworkStabilitySummary.Build([
            MakeEntry("1", "ready", 20, 0),
            MakeEntry("2", "ready", 21, 1),
            MakeEntry("3", "not_ready", 110, 2),
            MakeEntry("4", "not_ready", 125, 3),
        ]);
        Assert.Equal(50, lastTwoBad.StabilityPercentage);
        Assert.Equal(VerdictTone.Bad, lastTwoBad.StabilityTone);

        // <40% estável com pelo menos um teste ruim -> Bad mesmo se último for caution
        var lowWithBad = NetworkStabilitySummary.Build([
            MakeEntry("1", "ready", 20, 0),
            MakeEntry("2", "not_ready", 130, 1),
            MakeEntry("3", "caution", 55, 2),
            MakeEntry("4", "caution", 60, 3),
        ]);
        Assert.Equal(25, lowWithBad.StabilityPercentage);
        Assert.Equal(VerdictTone.Bad, lowWithBad.StabilityTone);
    }

    [Fact]
    public void Build_slices_points_to_max_points_keeping_most_recent()
    {
        var entries = Enumerable.Range(0, 5)
            .Select(i => MakeEntry($"s{i}", "ready", 20 + i, i))
            .ToArray();

        var summary = NetworkStabilitySummary.Build(entries, maxPoints: 3);

        Assert.Equal(5, summary.TotalCount);
        Assert.Equal(3, summary.Points.Count);
        Assert.Equal(22, summary.Points[0].PingMs);
        Assert.Equal(24, summary.Points[^1].PingMs);
    }

    [Fact]
    public void Build_general_library_game_matches_title_filter_and_aggregates_in_overall()
    {
        var entries = new[]
        {
            MakeEntry("fg-null", "ready", 10.8, 0, gameId: null, gameTitle: "Fall Guys"),
            MakeEntry("fg-gen", "caution", 24.0, 5, gameId: SessionHistoryStore.GeneralGameId, gameTitle: "Fall Guys"),
            MakeEntry("pc-only", "ready", 12.0, 10, gameId: SessionHistoryStore.GeneralGameId, gameTitle: null),
            MakeEntry("legacy-prof", "ready", 13.0, 12, gameId: "BATTLE_ROYALE_COMPETITIVE", gameTitle: null),
            MakeEntry("cs2", "ready", 19.0, 15, gameId: "cs2", gameTitle: "CS2"),
        };

        var fallGuysSummary = NetworkStabilitySummary.Build(entries, gameIdFilter: "Fall Guys");
        Assert.Equal(2, fallGuysSummary.TotalCount);
        Assert.Equal(10.8, fallGuysSummary.MinPing, precision: 2);
        Assert.Equal(24.0, fallGuysSummary.MaxPing, precision: 2);

        var generalOnlySummary = NetworkStabilitySummary.Build(entries, gameIdFilter: SessionHistoryStore.GeneralGameId);
        Assert.Equal(2, generalOnlySummary.TotalCount);

        var overallSummary = NetworkStabilitySummary.Build(entries, gameIdFilter: null);
        Assert.Equal(5, overallSummary.TotalCount);
    }

    [Fact]
    public void Build_breaks_curve_across_different_regions_or_networks_and_requires_three_per_segment()
    {
        var entries = new[]
        {
            new SessionHistoryEntry("1", "ready", 20, 2, 0, "sa-east-1", BaseTime.AddHours(-5), "valorant", "VALORANT", NetworkType: "ETHERNET"),
            new SessionHistoryEntry("2", "ready", 22, 2, 0, "sa-east-1", BaseTime.AddHours(-4), "valorant", "VALORANT", NetworkType: "ETHERNET"),
            new SessionHistoryEntry("3", "ready", 21, 2, 0, "sa-east-1", BaseTime.AddHours(-3), "valorant", "VALORANT", NetworkType: "ETHERNET"),
            new SessionHistoryEntry("4", "caution", 38, 6, 0, "us-east-1", BaseTime.AddHours(-2), "valorant", "VALORANT", NetworkType: "WIFI"),
            new SessionHistoryEntry("5", "ready", 42, 4, 0, "us-east-1", BaseTime.AddHours(-1), "valorant", "VALORANT", NetworkType: "WIFI"),
        };

        var summary = NetworkStabilitySummary.Build(entries, gameIdFilter: "valorant", windowDays: 14, now: BaseTime);

        Assert.True(summary.CanDrawCurve);
        Assert.True(summary.HasSummary);
        Assert.True(summary.HasMixedContexts);
        Assert.Equal(["ETHERNET", "WIFI"], summary.Networks);
        Assert.Equal([false, true, true, false, false], summary.Points.Select(p => p.ConnectToPrevious).ToArray());
    }

    [Fact]
    public void Build_counts_inconclusive_separately_and_marks_below_three_without_curve()
    {
        var entries = new[]
        {
            MakeEntry("r1", "ready", 18, -10, loadDeltaMs: null),
            MakeEntry("inc1", "inconclusive", 99, -5),
        };

        var summary = NetworkStabilitySummary.Build(entries, windowDays: 7, now: BaseTime);

        Assert.True(summary.HasData);
        Assert.False(summary.HasSummary);
        Assert.False(summary.CanDrawCurve);
        Assert.Equal(1, summary.TotalCount);
        Assert.Equal(1, summary.InconclusiveCount);
        Assert.Null(summary.AvgLoadDelta);
    }
}
