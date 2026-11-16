using System.Collections.ObjectModel;
using LagCheck.WinUI.Diagnostic;
using LagCheck.WinUI.Localization;
#if WINDOWS
using Microsoft.UI.Dispatching;
#endif

namespace LagCheck.WinUI.History;

/// <summary>Only terminal results emitted by the shared engine are retained for this app session.</summary>
public sealed class SessionHistoryStore
{
    public const string GeneralGameId = "general";

    public static bool IsGeneralId(string? gameId) =>
        string.IsNullOrWhiteSpace(gameId)
        || string.Equals(gameId, GeneralGameId, StringComparison.OrdinalIgnoreCase)
        || string.Equals(gameId, "generic-gaming", StringComparison.OrdinalIgnoreCase)
        || string.Equals(gameId, "BATTLE_ROYALE_COMPETITIVE", StringComparison.OrdinalIgnoreCase)
        || string.Equals(gameId, "MOBILE_REALTIME", StringComparison.OrdinalIgnoreCase)
        || string.Equals(gameId, "CASUAL_REALTIME", StringComparison.OrdinalIgnoreCase)
        || string.Equals(gameId, "BattleRoyaleCompetitive", StringComparison.OrdinalIgnoreCase)
        || string.Equals(gameId, "MobileRealtime", StringComparison.OrdinalIgnoreCase)
        || string.Equals(gameId, "CasualRealtime", StringComparison.OrdinalIgnoreCase);

    public static string? EffectiveGameKey(string? gameId, string? gameTitle)
    {
        if (!IsGeneralId(gameId)) return gameId!.Trim();
        if (!string.IsNullOrWhiteSpace(gameTitle)) return gameTitle.Trim();
        return null;
    }

    public static bool MatchesGame(SessionHistoryEntry entry, string? gameIdOrKey, string? gameTitle = null)
    {
        if (entry is null) return false;
        if (!string.IsNullOrWhiteSpace(gameIdOrKey))
        {
            var trimmedKey = gameIdOrKey.Trim();
            if (!IsGeneralId(entry.GameId) && string.Equals(entry.GameId?.Trim(), trimmedKey, StringComparison.OrdinalIgnoreCase))
                return true;
            if (!string.IsNullOrWhiteSpace(entry.GameTitle) && string.Equals(entry.GameTitle.Trim(), trimmedKey, StringComparison.OrdinalIgnoreCase))
                return true;
        }
        if (!string.IsNullOrWhiteSpace(gameTitle)
            && !string.IsNullOrWhiteSpace(entry.GameTitle)
            && string.Equals(entry.GameTitle.Trim(), gameTitle.Trim(), StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }
        return false;
    }

    private readonly SessionHistoryPersistence _persistence;
    private readonly SemaphoreSlim _persistGate = new(1, 1);
    private bool _initialized;
    private long _historyRevision;
    private long _savedRevision;
#if WINDOWS
    private DispatcherQueue? _dispatcher;
#endif
    public ObservableCollection<SessionHistoryEntry> Entries { get; } = [];

    internal SessionHistoryStore(SessionHistoryPersistence? persistence = null)
    {
        _persistence = persistence ?? new SessionHistoryPersistence();
    }

    public void Initialize(DiagnosticEngineClient engine)
    {
        if (_initialized) return;
        _initialized = true;
#if WINDOWS
        _dispatcher = DispatcherQueue.GetForCurrentThread();
#endif
        LoadPersistedEntries();
        engine.ResultReceived += OnResultReceived;
    }

    public async Task RefreshAsync(DiagnosticEngineClient engine, CancellationToken cancellationToken = default)
    {
        var entries = await engine.GetHistorySnapshotAsync(cancellationToken).ConfigureAwait(false);
        RunOnUi(() => MergeEngineSnapshot(entries));
    }

    public async Task TryRefreshAsync(DiagnosticEngineClient engine, CancellationToken cancellationToken = default)
    {
        try { await RefreshAsync(engine, cancellationToken); }
        catch (DiagnosticEngineException) { /* the History page keeps its honest empty state */ }
        catch (OperationCanceledException) { }
    }

    private void RunOnUi(Action action)
    {
#if WINDOWS
        _dispatcher?.TryEnqueue(() => action());
#else
        action();
#endif
    }

    private void OnResultReceived(object? sender, DiagnosticResult result)
    {
        RunOnUi(() =>
        {
            if (Entries.Any(entry => entry.SessionId == result.SessionId)) return;
            var gameId = IsGeneralId(result.GameId) ? null : result.GameId;
            Entries.Insert(0, new SessionHistoryEntry(
                result.SessionId,
                result.Verdict ?? Strings.Tr("— INCONCLUSIVO"),
                result.PingMs,
                result.JitterMs,
                result.PacketLossPercentage,
                result.RegionId,
                DateTimeOffset.Now,
                gameId,
                result.GameTitle,
                HasCapturedAt: true,
                LoadDeltaMs: result.LoadDeltaMs,
                WorstSpikeMs: result.WorstSpikeMs));
            var revision = ++_historyRevision;
            _ = PersistObservedEntriesAsync(revision);
        });
    }

    private void LoadPersistedEntries()
    {
        foreach (var entry in _persistence.Load())
        {
            if (Entries.Any(existing => existing.SessionId == entry.SessionId)) continue;
            var gameId = IsGeneralId(entry.GameId) ? null : entry.GameId;
            Entries.Add(new SessionHistoryEntry(
                entry.SessionId,
                entry.Verdict,
                entry.PingMs,
                entry.JitterMs,
                entry.PacketLossPercentage,
                entry.RegionId,
                entry.CapturedAt,
                gameId,
                entry.GameTitle,
                HasCapturedAt: true,
                LoadDeltaMs: entry.LoadDeltaMs,
                WorstSpikeMs: entry.WorstSpikeMs));
        }
        ReorderObservedEntries();
    }

    private void MergeEngineSnapshot(IReadOnlyList<EngineHistoryEntry> snapshot)
    {
        foreach (var entry in snapshot.Reverse())
        {
            if (Entries.Any(existing => existing.SessionId == entry.SessionId)) continue;
            // The engine protocol does not provide a capture time for old entries. Keep them visible,
            // but do not fabricate one or feed an unknown-age result into the stability graph.
            var gameId = IsGeneralId(entry.GameId) ? null : entry.GameId;
            Entries.Add(new SessionHistoryEntry(
                entry.SessionId,
                entry.Verdict ?? Strings.Tr("— INCONCLUSIVO"),
                entry.PingMs,
                entry.JitterMs,
                entry.PacketLossPercentage,
                entry.RegionId,
                DateTimeOffset.MinValue,
                gameId,
                HasCapturedAt: false));
        }
        ReorderObservedEntries();
    }

    private void ReorderObservedEntries()
    {
        var ordered = Entries
            .OrderByDescending(entry => entry.HasCapturedAt)
            .ThenByDescending(entry => entry.CapturedAt)
            .ToArray();
        if (Entries.SequenceEqual(ordered)) return;
        Entries.Clear();
        foreach (var entry in ordered) Entries.Add(entry);
    }

    private async Task PersistObservedEntriesAsync(long revision)
    {
        try
        {
            var entries = Entries
                .Where(entry => entry.HasCapturedAt)
                .Select(entry => new PersistedSessionHistoryEntry(
                    entry.SessionId,
                    entry.Verdict,
                    entry.PingMs,
                    entry.JitterMs,
                    entry.PacketLossPercentage,
                    entry.RegionId,
                    entry.CapturedAt,
                    IsGeneralId(entry.GameId) ? GeneralGameId : entry.GameId!,
                    entry.GameTitle,
                    entry.LoadDeltaMs,
                    entry.WorstSpikeMs))
                .ToArray();
            await _persistGate.WaitAsync().ConfigureAwait(false);
            try
            {
                if (revision <= _savedRevision) return;
                await _persistence.SaveAsync(entries).ConfigureAwait(false);
                _savedRevision = revision;
            }
            finally { _persistGate.Release(); }
        }
        catch (IOException) { }
        catch (UnauthorizedAccessException) { }
        catch (OperationCanceledException) { }
    }
}

public sealed record SessionHistoryEntry(
    string SessionId,
    string Verdict,
    double? PingMs,
    double? JitterMs,
    double? PacketLossPercentage,
    string? RegionId,
    DateTimeOffset CapturedAt,
    string? GameId = null,
    string? GameTitle = null,
    bool HasCapturedAt = true,
    double? LoadDeltaMs = null,
    double? WorstSpikeMs = null,
    string? NetworkType = null)
{
    public string? EffectiveGameKey => SessionHistoryStore.EffectiveGameKey(GameId, GameTitle);
    public string PingLabel => PingMs is { } value ? $"{value:0.#} ms" : "—";
    public string JitterLabel => JitterMs is { } value ? $"{value:0.#} ms" : "—";
    public string LossLabel => PacketLossPercentage is { } value ? $"{value:0.#}%" : "—";
    public string LoadDeltaLabel => LoadDeltaMs is { } value ? $"+{value:0.#} ms" : "—";
    public string SpikeLabel => WorstSpikeMs is { } value ? $"{value:0.#} ms" : "—";
    public string RegionLabel => string.IsNullOrWhiteSpace(RegionId) ? Strings.Tr("REGIÃO NÃO INFORMADA") : RegionId;
    public string TimeLabel => HasCapturedAt ? CapturedAt.ToLocalTime().ToString("HH:mm") : string.Empty;
}

public static class SessionHistoryServices { public static SessionHistoryStore Store { get; } = new(); }
