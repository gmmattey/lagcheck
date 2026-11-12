using System.Collections.ObjectModel;
using LagCheck.WinUI.Diagnostic;
using Microsoft.UI.Dispatching;

namespace LagCheck.WinUI.History;

/// <summary>Only terminal results emitted by the shared engine are retained for this app session.</summary>
public sealed class SessionHistoryStore
{
    private bool _initialized;
    private DispatcherQueue? _dispatcher;
    public ObservableCollection<SessionHistoryEntry> Entries { get; } = [];

    public void Initialize(DiagnosticEngineClient engine)
    {
        if (_initialized) return;
        _initialized = true;
        _dispatcher = DispatcherQueue.GetForCurrentThread();
        engine.ResultReceived += OnResultReceived;
    }

    public async Task RefreshAsync(DiagnosticEngineClient engine, CancellationToken cancellationToken = default)
    {
        var entries = await engine.GetHistorySnapshotAsync(cancellationToken).ConfigureAwait(false);
        _dispatcher?.TryEnqueue(() =>
        {
            Entries.Clear();
            foreach (var entry in entries)
                Entries.Add(new SessionHistoryEntry(entry.SessionId, entry.Verdict ?? "— INCONCLUSIVO", entry.PingMs, entry.JitterMs, entry.PacketLossPercentage, entry.RegionId, DateTimeOffset.Now));
        });
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
            Entries.Insert(0, new SessionHistoryEntry(result.SessionId, result.Verdict ?? "— INCONCLUSIVO", result.PingMs, result.JitterMs, result.PacketLossPercentage, result.RegionId, DateTimeOffset.Now));
        });
    }
}

public sealed record SessionHistoryEntry(string SessionId, string Verdict, double? PingMs, double? JitterMs, double? PacketLossPercentage, string? RegionId, DateTimeOffset CapturedAt)
{
    public string PingLabel => PingMs is { } value ? $"{value:0.#} ms" : "—";
    public string JitterLabel => JitterMs is { } value ? $"{value:0.#} ms" : "—";
    public string LossLabel => PacketLossPercentage is { } value ? $"{value:0.#}%" : "—";
    public string RegionLabel => string.IsNullOrWhiteSpace(RegionId) ? "REGIÃO NÃO INFORMADA" : RegionId;
    public string TimeLabel => CapturedAt.ToLocalTime().ToString("HH:mm");
}

public static class SessionHistoryServices { public static SessionHistoryStore Store { get; } = new(); }
