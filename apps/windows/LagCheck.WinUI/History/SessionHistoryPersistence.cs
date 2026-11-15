using System.Diagnostics;
using System.Text.Json;

namespace LagCheck.WinUI.History;

/// <summary>
/// Small, local-only cache for results whose capture time was observed by this app.
/// It deliberately excludes host snapshots because those do not carry a trustworthy time.
/// </summary>
internal sealed class SessionHistoryPersistence
{
    private const int CurrentVersion = 1;
    private const long MaximumFileBytes = 256 * 1024;
    private static readonly SemaphoreSlim FileGate = new(1, 1);
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web) { WriteIndented = false };
    private readonly string _path;
    private readonly TimeSpan _lockTimeout;
    private bool _canWrite = true;

    internal SessionHistoryPersistence(string? path = null, TimeSpan? lockTimeout = null)
    {
        _path = path ?? Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "LagCheck",
            "history-v1.json");
        _lockTimeout = lockTimeout ?? TimeSpan.FromSeconds(2);
    }

    internal IReadOnlyList<PersistedSessionHistoryEntry> Load()
    {
        var existing = ReadExistingHistory();
        if (!existing.IsWritable) _canWrite = false;
        return existing.Entries;
    }

    internal async Task SaveAsync(IEnumerable<PersistedSessionHistoryEntry> entries, CancellationToken cancellationToken = default)
    {
        if (!_canWrite) return;
        await FileGate.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            if (!_canWrite) return;
            var directory = Path.GetDirectoryName(_path);
            if (string.IsNullOrWhiteSpace(directory)) return;
            Directory.CreateDirectory(directory);

            await using var fileLock = await AcquireCrossProcessLockAsync(cancellationToken).ConfigureAwait(false);
            var existing = ReadExistingHistory();
            if (!existing.IsWritable)
            {
                _canWrite = false;
                return;
            }
            var normalized = Normalize(existing.Entries.Concat(entries));
            var temporaryPath = Path.Combine(directory, $".{Path.GetFileName(_path)}.{Guid.NewGuid():N}.tmp");
            try
            {
                await using (var stream = new FileStream(temporaryPath, FileMode.CreateNew, FileAccess.Write, FileShare.None, 4096, FileOptions.WriteThrough))
                {
                    await JsonSerializer.SerializeAsync(stream, new PersistedHistoryDocument(CurrentVersion, normalized), Json, cancellationToken).ConfigureAwait(false);
                    await stream.FlushAsync(cancellationToken).ConfigureAwait(false);
                }

                // Keep the previous file intact when a future history would exceed the safety budget.
                // Truncating old measurements here would make the chart quietly lie by omission.
                if (new FileInfo(temporaryPath).Length > MaximumFileBytes) return;
                File.Move(temporaryPath, _path, overwrite: true);
            }
            finally
            {
                try { if (File.Exists(temporaryPath)) File.Delete(temporaryPath); }
                catch (IOException) { }
                catch (UnauthorizedAccessException) { }
            }
        }
        finally { FileGate.Release(); }
    }

    private HistoryReadResult ReadExistingHistory()
    {
        try
        {
            var info = new FileInfo(_path);
            if (!info.Exists || info.Length == 0) return new([], true);
            if (info.Length > MaximumFileBytes) return new([], false);

            using var stream = new FileStream(_path, FileMode.Open, FileAccess.Read, FileShare.Read | FileShare.Delete);
            var document = JsonSerializer.Deserialize<PersistedHistoryDocument>(stream, Json);
            if (document?.Version != CurrentVersion || document.Entries is null || document.Entries.Any(entry => !IsValid(entry)))
                return new([], false);

            return new(Normalize(document.Entries), true);
        }
        catch (IOException) { return new([], false); }
        catch (UnauthorizedAccessException) { return new([], false); }
        catch (JsonException) { return new([], false); }
    }

    private async Task<FileStream> AcquireCrossProcessLockAsync(CancellationToken cancellationToken)
    {
        var lockPath = _path + ".lock";
        var startedAt = Stopwatch.GetTimestamp();
        while (true)
        {
            cancellationToken.ThrowIfCancellationRequested();
            try
            {
                return new FileStream(lockPath, FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None, 1, FileOptions.DeleteOnClose);
            }
            catch (IOException)
            {
                if (Stopwatch.GetElapsedTime(startedAt) >= _lockTimeout)
                    throw new IOException("O histórico local está ocupado por outra instância do LagCheck.");
                await Task.Delay(TimeSpan.FromMilliseconds(25), cancellationToken).ConfigureAwait(false);
            }
        }
    }

    private static IReadOnlyList<PersistedSessionHistoryEntry> Normalize(IEnumerable<PersistedSessionHistoryEntry> entries) => entries
        .Where(IsValid)
        .GroupBy(entry => entry.SessionId, StringComparer.Ordinal)
        .Select(group => group.OrderByDescending(entry => entry.CapturedAt).First())
        .OrderByDescending(entry => entry.CapturedAt)
        .ToArray();

    private static bool IsValid(PersistedSessionHistoryEntry? entry) =>
        entry is not null
        && !string.IsNullOrWhiteSpace(entry.SessionId)
        && entry.SessionId.Length <= 128
        && !string.IsNullOrWhiteSpace(entry.GameId)
        && entry.GameId.Length <= 256
        && (entry.GameTitle is null || entry.GameTitle.Length <= 256)
        && !string.IsNullOrWhiteSpace(entry.Verdict)
        && entry.Verdict.Length <= 160
        && entry.CapturedAt != DateTimeOffset.MinValue
        && IsFinite(entry.PingMs)
        && IsFinite(entry.JitterMs)
        && IsFinite(entry.PacketLossPercentage)
        && IsFinite(entry.LoadDeltaMs)
        && IsFinite(entry.WorstSpikeMs)
        && (entry.RegionId is null || entry.RegionId.Length <= 160);

    private static bool IsFinite(double? value) => value is not { } number || double.IsFinite(number);

    private sealed record HistoryReadResult(IReadOnlyList<PersistedSessionHistoryEntry> Entries, bool IsWritable);
}

/// <summary>Only the fields needed for local result history; no account, network identity or raw probe data is stored.</summary>
internal sealed record PersistedSessionHistoryEntry(
    string SessionId,
    string Verdict,
    double? PingMs,
    double? JitterMs,
    double? PacketLossPercentage,
    string? RegionId,
    DateTimeOffset CapturedAt,
    string GameId,
    string? GameTitle = null,
    double? LoadDeltaMs = null,
    double? WorstSpikeMs = null);

internal sealed record PersistedHistoryDocument(int Version, IReadOnlyList<PersistedSessionHistoryEntry> Entries);
