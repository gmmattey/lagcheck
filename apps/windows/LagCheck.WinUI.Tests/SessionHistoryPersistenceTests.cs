using LagCheck.WinUI.History;
using Xunit;

namespace LagCheck.WinUI.Tests;

public sealed class SessionHistoryPersistenceTests : IDisposable
{
    private readonly string _directory = Path.Combine(Path.GetTempPath(), "LagCheck", Guid.NewGuid().ToString("N"));

    [Fact]
    public async Task Reopening_store_preserves_observed_entries_in_newest_first_order()
    {
        var path = Path.Combine(_directory, "history.json");
        var store = new SessionHistoryPersistence(path);
        var older = Entry("older", "cities", DateTimeOffset.Parse("2026-11-14T12:00:00+00:00"));
        var newer = Entry("newer", "cities", DateTimeOffset.Parse("2026-11-14T12:01:00+00:00"));

        await store.SaveAsync([older, newer]);

        var reopened = new SessionHistoryPersistence(path).Load();

        Assert.Collection(reopened,
            entry => Assert.Equal("newer", entry.SessionId),
            entry => Assert.Equal("older", entry.SessionId));
    }

    [Fact]
    public async Task Save_deduplicates_sessions_and_keeps_the_latest_observed_result()
    {
        var path = Path.Combine(_directory, "history.json");
        var store = new SessionHistoryPersistence(path);
        var first = Entry("same", "cities", DateTimeOffset.Parse("2026-11-14T12:00:00+00:00")) with { PingMs = 44 };
        var latest = Entry("same", "cities", DateTimeOffset.Parse("2026-11-14T12:02:00+00:00")) with { PingMs = 18 };

        await store.SaveAsync([first, latest]);

        var entry = Assert.Single(store.Load());
        Assert.Equal(18, entry.PingMs);
        Assert.Equal(latest.CapturedAt, entry.CapturedAt);
    }

    [Fact]
    public void Missing_or_corrupt_file_is_ignored_without_deleting_it()
    {
        var path = Path.Combine(_directory, "history.json");
        var store = new SessionHistoryPersistence(path);
        Assert.Empty(store.Load());

        Directory.CreateDirectory(_directory);
        File.WriteAllText(path, "{ this is not valid json");

        Assert.Empty(store.Load());
        Assert.True(File.Exists(path));
    }

    [Fact]
    public async Task Corrupt_file_is_never_replaced_by_a_later_save()
    {
        var path = Path.Combine(_directory, "history.json");
        Directory.CreateDirectory(_directory);
        const string corrupted = "{ this is not valid json";
        File.WriteAllText(path, corrupted);
        var store = new SessionHistoryPersistence(path);

        Assert.Empty(store.Load());
        await store.SaveAsync([Entry("new-result", "cities", DateTimeOffset.Parse("2026-11-14T12:00:00+00:00"))]);

        Assert.Equal(corrupted, File.ReadAllText(path));
    }

    [Fact]
    public async Task Save_keeps_all_valid_history_entries()
    {
        var path = Path.Combine(_directory, "history.json");
        var store = new SessionHistoryPersistence(path);
        var start = DateTimeOffset.Parse("2026-11-14T12:00:00+00:00");
        var entries = Enumerable.Range(0, 121).Select(index => Entry($"session-{index}", "cities", start.AddMinutes(index)));

        await store.SaveAsync(entries);

        var saved = store.Load();
        Assert.Equal(121, saved.Count);
        Assert.Equal("session-120", saved[0].SessionId);
        Assert.Contains(saved, entry => entry.SessionId == "session-0");
    }

    [Fact]
    public async Task Save_keeps_the_existing_file_when_a_new_history_exceeds_the_safety_budget()
    {
        var path = Path.Combine(_directory, "history.json");
        var store = new SessionHistoryPersistence(path);
        var original = Entry("kept", "cities", DateTimeOffset.Parse("2026-11-14T12:00:00+00:00"));
        await store.SaveAsync([original]);

        var start = DateTimeOffset.Parse("2026-11-14T12:01:00+00:00");
        var oversized = Enumerable.Range(0, 900).Select(index => new PersistedSessionHistoryEntry(
            $"large-{index}",
            new string('v', 160),
            17.5,
            1.2,
            0,
            new string('r', 160),
            start.AddMinutes(index),
            new string('g', 250) + index));

        await store.SaveAsync(oversized);

        var saved = Assert.Single(store.Load());
        Assert.Equal(original.SessionId, saved.SessionId);
    }

    [Fact]
    public async Task Concurrent_stores_merge_results_instead_of_replacing_each_other()
    {
        var path = Path.Combine(_directory, "history.json");
        var firstStore = new SessionHistoryPersistence(path);
        var secondStore = new SessionHistoryPersistence(path);
        var first = Entry("first-window", "cities", DateTimeOffset.Parse("2026-11-14T12:00:00+00:00"));
        var second = Entry("second-window", "cities", DateTimeOffset.Parse("2026-11-14T12:01:00+00:00"));

        await Task.WhenAll(firstStore.SaveAsync([first]), secondStore.SaveAsync([second]));

        var saved = new SessionHistoryPersistence(path).Load();
        Assert.Collection(saved,
            entry => Assert.Equal(second.SessionId, entry.SessionId),
            entry => Assert.Equal(first.SessionId, entry.SessionId));
    }

    [Fact]
    public async Task Contended_lock_fails_in_a_bounded_time_without_writing_history()
    {
        var path = Path.Combine(_directory, "history.json");
        Directory.CreateDirectory(_directory);
        await using var heldLock = new FileStream(path + ".lock", FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None);
        var store = new SessionHistoryPersistence(path, TimeSpan.FromMilliseconds(30));

        await Assert.ThrowsAsync<IOException>(() => store.SaveAsync([Entry("blocked", "cities", DateTimeOffset.Parse("2026-11-14T12:00:00+00:00"))]));

        Assert.False(File.Exists(path));
    }

    [Fact]
    public async Task SaveAsync_and_Load_preserve_general_entries_game_title_and_load_spike_metrics()
    {
        var path = Path.Combine(_directory, "history.json");
        var store = new SessionHistoryPersistence(path);
        var t1 = DateTimeOffset.Parse("2026-11-15T10:00:00+00:00");
        var t2 = DateTimeOffset.Parse("2026-11-15T10:05:00+00:00");
        var generalEntry = new PersistedSessionHistoryEntry(
            "gen-1",
            "ready",
            22.4,
            1.8,
            0.0,
            "sa-east-1",
            t1,
            SessionHistoryStore.GeneralGameId,
            GameTitle: null,
            LoadDeltaMs: 14.5,
            WorstSpikeMs: 42.0);
        var gameEntry = new PersistedSessionHistoryEntry(
            "val-1",
            "caution",
            38.0,
            6.2,
            0.5,
            "sa-east-1",
            t2,
            "valorant",
            GameTitle: "VALORANT",
            LoadDeltaMs: -1.5,
            WorstSpikeMs: 28.0);

        await store.SaveAsync([generalEntry, gameEntry]);
        var loaded = new SessionHistoryPersistence(path).Load();

        Assert.Equal(2, loaded.Count);
        Assert.Equal("val-1", loaded[0].SessionId);
        Assert.Equal("valorant", loaded[0].GameId);
        Assert.Equal("VALORANT", loaded[0].GameTitle);
        Assert.Equal(-1.5, loaded[0].LoadDeltaMs);
        Assert.Equal(28.0, loaded[0].WorstSpikeMs);

        Assert.Equal("gen-1", loaded[1].SessionId);
        Assert.Equal(SessionHistoryStore.GeneralGameId, loaded[1].GameId);
        Assert.Null(loaded[1].GameTitle);
        Assert.Equal(14.5, loaded[1].LoadDeltaMs);
        Assert.Equal(42.0, loaded[1].WorstSpikeMs);
    }

    [Fact]
    public async Task SaveAsync_drops_entries_with_non_finite_load_delta_or_worst_spike()
    {
        var path = Path.Combine(_directory, "history.json");
        var store = new SessionHistoryPersistence(path);
        var t1 = DateTimeOffset.Parse("2026-11-15T11:00:00+00:00");
        var valid = new PersistedSessionHistoryEntry("ok-1", "ready", 19.0, 1.0, 0.0, "sa-east-1", t1, SessionHistoryStore.GeneralGameId, null, 8.0, 22.0);
        var badLoad = new PersistedSessionHistoryEntry("bad-load", "ready", 19.0, 1.0, 0.0, "sa-east-1", t1.AddMinutes(1), "valorant", "VALORANT", double.NaN, 22.0);
        var badSpike = new PersistedSessionHistoryEntry("bad-spike", "ready", 19.0, 1.0, 0.0, "sa-east-1", t1.AddMinutes(2), "cs2", "CS2", 8.0, double.PositiveInfinity);

        await store.SaveAsync([valid, badLoad, badSpike]);
        var loaded = new SessionHistoryPersistence(path).Load();

        var single = Assert.Single(loaded);
        Assert.Equal("ok-1", single.SessionId);
    }

    [Theory]
    [InlineData(null, true)]
    [InlineData("", true)]
    [InlineData("   ", true)]
    [InlineData("general", true)]
    [InlineData("GENERAL", true)]
    [InlineData("generic-gaming", true)]
    [InlineData("GENERIC-GAMING", true)]
    [InlineData("BATTLE_ROYALE_COMPETITIVE", true)]
    [InlineData("MOBILE_REALTIME", true)]
    [InlineData("CASUAL_REALTIME", true)]
    [InlineData("valorant", false)]
    [InlineData("cs2", false)]
    public void IsGeneralId_identifies_general_and_legacy_ids_without_matching_games(string? gameId, bool expected)
    {
        Assert.Equal(expected, SessionHistoryStore.IsGeneralId(gameId));
    }

    [Fact]
    public void MatchesGame_and_EffectiveGameKey_handle_general_games_with_title()
    {
        var t = DateTimeOffset.Parse("2026-11-15T11:46:50+00:00");
        var fallGuys = new SessionHistoryEntry("fg-1", "ready", 10.7, 0.7, 0.0, "sa-east-1", t, GameId: null, GameTitle: "Fall Guys");
        var profileOnly = new SessionHistoryEntry("pr-1", "ready", 13.0, 0.8, 0.0, "sa-east-1", t, GameId: "BATTLE_ROYALE_COMPETITIVE", GameTitle: null);
        var valorant = new SessionHistoryEntry("val-1", "ready", 18.0, 1.0, 0.0, "sa-east-1", t, GameId: "valorant", GameTitle: "VALORANT");

        Assert.Equal("Fall Guys", fallGuys.EffectiveGameKey);
        Assert.Null(profileOnly.EffectiveGameKey);
        Assert.Equal("valorant", valorant.EffectiveGameKey);

        Assert.True(SessionHistoryStore.MatchesGame(fallGuys, "Fall Guys"));
        Assert.True(SessionHistoryStore.MatchesGame(fallGuys, null, "Fall Guys"));
        Assert.False(SessionHistoryStore.MatchesGame(profileOnly, "Fall Guys"));
        Assert.False(SessionHistoryStore.MatchesGame(profileOnly, "BATTLE_ROYALE_COMPETITIVE"));
        Assert.True(SessionHistoryStore.MatchesGame(valorant, "valorant"));
    }

    public void Dispose()
    {
        if (Directory.Exists(_directory)) Directory.Delete(_directory, recursive: true);
    }

    private static PersistedSessionHistoryEntry Entry(string sessionId, string gameId, DateTimeOffset capturedAt) =>
        new(sessionId, "ready", 17.5, 1.2, 0, "sa-east-1", capturedAt, gameId);
}
