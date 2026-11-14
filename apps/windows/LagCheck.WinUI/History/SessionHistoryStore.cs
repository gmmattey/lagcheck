using System.Collections.ObjectModel;
using LagCheck.WinUI.Diagnostic;
using LagCheck.WinUI.Localization;
using Microsoft.UI.Dispatching;

namespace LagCheck.WinUI.History;

/// <summary>Only terminal results emitted by the shared engine are retained for this app session.</summary>
public sealed class SessionHistoryStore
{
    private readonly SessionHistoryPersistence _persistence;
    private readonly SemaphoreSlim _persistGate = new(1, 1);
    private bool _initialized;
    private long _historyRevision;
    private long _savedRevision;
    private DispatcherQueue? _dispatcher;
    public ObservableCollection<SessionHistoryEntry> Entries { get; } = [];

    internal SessionHistoryStore(SessionHistoryPersistence? persistence = null)
    {
        _persistence = persistence ?? new SessionHistoryPersistence();
    }

    public void Initialize(DiagnosticEngineClient engine)
    {
        if (_initialized) return;
        _initialized = true;
        _dispatcher = DispatcherQueue.GetForCurrentThread();
        LoadPersistedEntries();
        engine.ResultReceived += OnResultReceived;
    }

    public async Task RefreshAsync(DiagnosticEngineClient engine, CancellationToken cancellationToken = default)
    {
        var entries = await engine.GetHistorySnapshotAsync(cancellationToken).ConfigureAwait(false);
        _dispatcher?.TryEnqueue(() => MergeEngineSnapshot(entries));
    }

    public async Task TryRefreshAsync(DiagnosticEngineClient engine, CancellationToken cancellationToken = default)
    {
        try { await RefreshAsync(engine, cancellationToken); }
        catch (DiagnosticEngineException) { /* the History page keeps its honest empty state */ }
        catch (OperationCanceledException) { }
    }

    private void OnResultReceived(object? sender, DiagnosticResult result)
    {
        _dispatcher?.TryEnqueue(() =>
        {
            if (Entries.Any(entry => entry.SessionId == result.SessionId)) return;
            Entries.Insert(0, new SessionHistoryEntry(result.SessionId, result.Verdict ?? Strings.Tr("— INCONCLUSIVO"), result.PingMs, result.JitterMs, result.PacketLossPercentage, result.RegionId, DateTimeOffset.Now, result.GameId ?? result.ProfileId, result.GameTitle));
            var revision = ++_historyRevision;
            _ = PersistObservedEntriesAsync(revision);
        });
    }

    private void LoadPersistedEntries()
    {
        foreach (var entry in _persistence.Load())
        {
            if (Entries.Any(existing => existing.SessionId == entry.SessionId)) continue;
            Entries.Add(new SessionHistoryEntry(entry.SessionId, entry.Verdict, entry.PingMs, entry.JitterMs, entry.PacketLossPercentage, entry.RegionId, entry.CapturedAt, entry.GameId));
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
            Entries.Add(new SessionHistoryEntry(entry.SessionId, entry.Verdict ?? Strings.Tr("— INCONCLUSIVO"), entry.PingMs, entry.JitterMs, entry.PacketLossPercentage, entry.RegionId, DateTimeOffset.MinValue, entry.GameId ?? entry.ProfileId, HasCapturedAt: false));
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
                .Where(entry => entry.HasCapturedAt && !string.IsNullOrWhiteSpace(entry.GameId))
                .Select(entry => new PersistedSessionHistoryEntry(entry.SessionId, entry.Verdict, entry.PingMs, entry.JitterMs, entry.PacketLossPercentage, entry.RegionId, entry.CapturedAt, entry.GameId!))
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

public sealed record SessionHistoryEntry(string SessionId, string Verdict, double? PingMs, double? JitterMs, double? PacketLossPercentage, string? RegionId, DateTimeOffset CapturedAt, string? GameId = null, string? GameTitle = null, bool HasCapturedAt = true)
{
    public string PingLabel => PingMs is { } value ? $"{value:0.#} ms" : "—";
    public string JitterLabel => JitterMs is { } value ? $"{value:0.#} ms" : "—";
    public string LossLabel => PacketLossPercentage is { } value ? $"{value:0.#}%" : "—";
    public string RegionLabel => string.IsNullOrWhiteSpace(RegionId) ? Strings.Tr("REGIÃO NÃO INFORMADA") : RegionId;
    public string TimeLabel => HasCapturedAt ? CapturedAt.ToLocalTime().ToString("HH:mm") : string.Empty;
}

public static class SessionHistoryServices { public static SessionHistoryStore Store { get; } = new(); }
