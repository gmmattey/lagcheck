using System.Diagnostics;
using System.Text;
using System.Text.Json;
using System.Collections.Concurrent;
using LagCheck.WinUI.Library;

namespace LagCheck.WinUI.Diagnostic;

/// <summary>
/// Local-only NDJSON bridge to the Kotlin/JVM diagnostic host.
/// It deliberately does not interpret a score, verdict or packet metrics.
/// </summary>
public sealed class DiagnosticEngineClient : IAsyncDisposable
{
    private static readonly UTF8Encoding Utf8NoBom = new(encoderShouldEmitUTF8Identifier: false);
    private readonly string _hostPath;
    private readonly SemaphoreSlim _writeLock = new(1, 1);
    private readonly SemaphoreSlim _connectLock = new(1, 1);
    private readonly SemaphoreSlim _libraryScanLock = new(1, 1);
    private readonly object _gate = new();
    private readonly ConcurrentDictionary<string, PendingRequest> _requests = new();
    private Process? _process;
    private Task? _reader;
    private Task? _stderr;
    private TaskCompletionSource<EngineHello>? _hello;
    private TaskCompletionSource<DiagnosticResult>? _activeResult;
    private string? _activeSessionId;
    private bool _disposed;

    public DiagnosticEngineClient(string? hostPath = null)
    {
        _hostPath = hostPath ?? ResolveHostPath();
    }

    public event EventHandler<DiagnosticProgress>? ProgressChanged;
    public event EventHandler<DiagnosticEngineException>? EngineFaulted;
    /// <summary>Emits only terminal results received from the Kotlin engine, including inconclusive ones.</summary>
    public event EventHandler<DiagnosticResult>? ResultReceived;
    /// <summary>True only while the host owns the single active diagnostic session.</summary>
    public event EventHandler<bool>? SessionActivityChanged;

    public bool IsSessionActive
    {
        get { lock (_gate) return _activeSessionId is not null; }
    }

    public async Task<EngineHello> ConnectAsync(CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        await _connectLock.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            if (_process is { HasExited: false })
            {
                return await (_hello?.Task ?? Task.FromResult(new EngineHello(EngineProtocol.Version, "connected")))
                    .WaitAsync(cancellationToken).ConfigureAwait(false);
            }

            if (!File.Exists(_hostPath))
            {
                throw new DiagnosticEngineException("HOST_NOT_FOUND", "O motor de diagnóstico local não foi encontrado.");
            }

            _hello = new(TaskCreationOptions.RunContinuationsAsynchronously);
            _process = new Process
            {
                StartInfo = CreateProcessStartInfo(_hostPath),
                EnableRaisingEvents = true,
            };
            _process.Exited += (_, _) => CompleteForExit();
            if (!_process.Start())
            {
                throw new DiagnosticEngineException("HOST_START_FAILED", "Não foi possível iniciar o motor de diagnóstico local.");
            }

            _reader = ReadOutputAsync(_process);
            _stderr = DrainStandardErrorAsync(_process);
            await SendAsync(new { type = "hello", requestId = NewId() }, cancellationToken).ConfigureAwait(false);
            var hello = await _hello.Task.WaitAsync(cancellationToken).ConfigureAwait(false);
            if (!string.Equals(hello.Protocol, EngineProtocol.Version, StringComparison.Ordinal))
            {
                await DisposeAsync().ConfigureAwait(false);
                throw new DiagnosticEngineException("PROTOCOL_MISMATCH", "A interface e o motor de diagnóstico não são compatíveis.");
            }
            return hello;
        }
        finally { _connectLock.Release(); }
    }

    public async Task<DiagnosticResult> StartAsync(string? gameId, CancellationToken cancellationToken = default)
    {
        await ConnectAsync(cancellationToken).ConfigureAwait(false);
        var sessionId = NewId();
        TaskCompletionSource<DiagnosticResult> completion;
        lock (_gate)
        {
            if (_activeSessionId is not null)
            {
                throw new DiagnosticEngineException("SESSION_ACTIVE", "Já existe uma medição em andamento.");
            }
            _activeSessionId = sessionId;
            _activeResult = completion = new(TaskCreationOptions.RunContinuationsAsynchronously);
        }
        SessionActivityChanged?.Invoke(this, true);

        var commandSent = false;
        try
        {
            await SendAsync(new { type = "start", requestId = NewId(), sessionId, gameId }, cancellationToken)
                .ConfigureAwait(false);
            commandSent = true;
            if (!cancellationToken.CanBeCanceled) return await completion.Task.ConfigureAwait(false);

            var cancelled = Task.Delay(Timeout.InfiniteTimeSpan, cancellationToken);
            if (await Task.WhenAny(completion.Task, cancelled).ConfigureAwait(false) == completion.Task)
                return await completion.Task.ConfigureAwait(false);

            await CancelAsync(CancellationToken.None).ConfigureAwait(false);
            cancellationToken.ThrowIfCancellationRequested();
            return await completion.Task.ConfigureAwait(false);
        }
        catch
        {
            if (!commandSent) ClearActive(sessionId);
            throw;
        }
    }

    public async Task CancelAsync(CancellationToken cancellationToken = default)
    {
        string? sessionId;
        TaskCompletionSource<DiagnosticResult>? completion;
        lock (_gate)
        {
            sessionId = _activeSessionId;
            completion = _activeResult;
        }
        if (sessionId is null || completion is null) return;
        await SendAsync(new { type = "cancel", requestId = NewId(), sessionId }, cancellationToken).ConfigureAwait(false);
        try
        {
            // After the cancel command is accepted, do not let a caller token release UI state before host terminal confirmation.
            await completion.Task.ConfigureAwait(false);
        }
        catch (DiagnosticEngineException error) when (error.Code == "CANCELLED")
        {
            // The host confirmed the terminal cancellation; partial data was discarded there.
        }
    }

    public async Task<LibrarySnapshot> GetLibrarySnapshotAsync(CancellationToken cancellationToken = default)
    {
        var snapshot = await GetLibrarySnapshotOnceAsync(cancellationToken).ConfigureAwait(false);
        if (snapshot.HasScanned && !snapshot.IsScanning) return snapshot;
        var rescan = await RescanLibraryAsync(cancellationToken).ConfigureAwait(false);
        return rescan.Snapshot ?? snapshot;
    }

    public async Task<LibraryOperationResult> RescanLibraryAsync(CancellationToken cancellationToken = default)
    {
        await _libraryScanLock.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            await RequestAsync("library.rescan", null, cancellationToken).ConfigureAwait(false);
            var snapshot = await WaitForCompletedLibraryScanAsync(cancellationToken).ConfigureAwait(false);
            return new LibraryOperationResult(true, null, snapshot);
        }
        finally { _libraryScanLock.Release(); }
    }

    private async Task<LibrarySnapshot> GetLibrarySnapshotOnceAsync(CancellationToken cancellationToken) =>
        LibraryWireParser.ParseSnapshot((await RequestAsync("library.snapshot", null, cancellationToken).ConfigureAwait(false)).Snapshot!.Value);

    private async Task<LibrarySnapshot> WaitForCompletedLibraryScanAsync(CancellationToken cancellationToken)
    {
        var until = DateTimeOffset.UtcNow.AddSeconds(30);
        LibrarySnapshot? latest = null;
        do
        {
            latest = await GetLibrarySnapshotOnceAsync(cancellationToken).ConfigureAwait(false);
            if (latest.HasScanned && !latest.IsScanning) return latest;
            await Task.Delay(TimeSpan.FromMilliseconds(200), cancellationToken).ConfigureAwait(false);
        }
        while (DateTimeOffset.UtcNow < until);
        throw new DiagnosticEngineException("LIBRARY_SCAN_TIMEOUT", "A procura pelos jogos demorou mais que o esperado.");
    }

    public async Task<LibraryOperationResult> SetLibraryFavoriteAsync(string gameId, bool favorite, CancellationToken cancellationToken = default)
    {
        var response = await RequestAsync("library.favorite", new Dictionary<string, object?> { ["id"] = gameId, ["favorite"] = favorite }, cancellationToken).ConfigureAwait(false);
        return new LibraryOperationResult(true, null, LibraryWireParser.ParseSnapshot(response.Snapshot!.Value));
    }

    public async Task<LibraryOperationResult> SelectLibraryGameAsync(string gameId, CancellationToken cancellationToken = default)
    {
        var response = await RequestAsync("library.select", new Dictionary<string, object?> { ["id"] = gameId }, cancellationToken).ConfigureAwait(false);
        return new LibraryOperationResult(true, null, LibraryWireParser.ParseSnapshot(response.Snapshot!.Value));
    }

    public async Task<LibraryOperationResult> LaunchLibraryGameAsync(string gameId, CancellationToken cancellationToken = default)
    {
        var response = await RequestAsync("library.launch", new Dictionary<string, object?> { ["id"] = gameId }, cancellationToken).ConfigureAwait(false);
        return new LibraryOperationResult(response.Started == true, response.Message, LibraryWireParser.ParseSnapshot(response.Snapshot!.Value));
    }

    public async Task<LibraryOperationResult> RefreshLibraryArtworkAsync(string gameId, CancellationToken cancellationToken = default)
    {
        await RequestAsync("library.artwork.refresh", new Dictionary<string, object?> { ["id"] = gameId }, cancellationToken, "library.artwork").ConfigureAwait(false);
        // The artwork response intentionally carries only local paths; a fresh host snapshot remains the UI source.
        return new LibraryOperationResult(true, "Imagem atualizada neste PC.", await GetLibrarySnapshotAsync(cancellationToken).ConfigureAwait(false));
    }

    /// <summary>Resolves artwork only for currently visible games. The host rejects batches outside 1–8 IDs.</summary>
    public async Task<LibraryOperationResult> ResolveLibraryArtworkAsync(IReadOnlyList<string> gameIds, CancellationToken cancellationToken = default)
    {
        var ids = gameIds.Where(id => !string.IsNullOrWhiteSpace(id)).Distinct(StringComparer.Ordinal).ToArray();
        if (ids.Length is < 1 or > 8)
            throw new DiagnosticEngineException("INVALID_ARTWORK_REQUEST", "Selecione entre 1 e 8 jogos visíveis para atualizar as imagens.");

        await RequestAsync("library.artwork.resolve", new Dictionary<string, object?> { ["ids"] = ids }, cancellationToken, "library.artwork.resolved").ConfigureAwait(false);
        return new LibraryOperationResult(true, null, await GetLibrarySnapshotOnceAsync(cancellationToken).ConfigureAwait(false));
    }

    public async Task<IReadOnlyList<EngineCatalogGame>> GetCatalogSnapshotAsync(CancellationToken cancellationToken = default)
    {
        var response = await RequestAsync("catalog.snapshot", null, cancellationToken).ConfigureAwait(false);
        return Array(response.Games).Select(game => new EngineCatalogGame(
            Required(game, "id"), Required(game, "name"), String(game, "artworkResource"), String(game, "regionId"), String(game, "regionLabel"))).ToArray();
    }

    public Task<IReadOnlyList<EngineCatalogGame>> GetCatalogAsync(CancellationToken cancellationToken = default) => GetCatalogSnapshotAsync(cancellationToken);

    public async Task<IReadOnlyList<EngineHistoryEntry>> GetHistorySnapshotAsync(CancellationToken cancellationToken = default)
    {
        var response = await RequestAsync("history.snapshot", null, cancellationToken).ConfigureAwait(false);
        return Array(response.Entries).Select(entry => new EngineHistoryEntry(
            String(entry, "sessionId") ?? string.Empty, String(entry, "verdict"), Number(entry, "pingMs"), Number(entry, "jitterMs"),
            Number(entry, "packetLossPercentage"), String(entry, "regionId"), String(entry, "profileId"))).ToArray();
    }

    public Task<IReadOnlyList<EngineHistoryEntry>> GetSessionHistoryAsync(CancellationToken cancellationToken = default) => GetHistorySnapshotAsync(cancellationToken);

    public async Task<EngineSettings> GetSettingsAsync(CancellationToken cancellationToken = default) =>
        ReadSettings(await RequestAsync("settings.get", null, cancellationToken).ConfigureAwait(false));

    public async Task<EngineSettings> SetSettingsAsync(EngineSettings settings, CancellationToken cancellationToken = default)
    {
        var response = await RequestAsync("settings.set", new Dictionary<string, object?>
        {
            ["settings"] = new
            {
                reduceMotion = settings.ReduceMotion,
                artworkDownloadEnabled = settings.ArtworkDownloadEnabled,
                approximateLocationEnabled = settings.ApproximateLocationEnabled,
                analyticsEnabled = settings.AnalyticsEnabled,
                automaticUpdates = settings.AutomaticUpdates,
            },
        }, cancellationToken).ConfigureAwait(false);
        return ReadSettings(response);
    }

    public async Task<EngineUpdateStatus> GetUpdateStatusAsync(CancellationToken cancellationToken = default) =>
        ReadUpdate(await RequestAsync("update.status", null, cancellationToken).ConfigureAwait(false));

    /// <summary>Checks the configured source only. It never downloads, applies or installs an update.</summary>
    public async Task<EngineUpdateStatus> CheckForUpdatesAsync(CancellationToken cancellationToken = default) =>
        ReadUpdate(await RequestAsync("update.check", null, cancellationToken, "update.status").ConfigureAwait(false));

    public async Task<ApproximateLocation> GetApproximateLocationAsync(CancellationToken cancellationToken = default) =>
        ReadLocation(await RequestAsync("location.get", null, cancellationToken, "location").ConfigureAwait(false));

    /// <summary>Asks the host to refresh its consent-gated approximate-IP cache. No coordinates are inferred by the UI.</summary>
    public async Task<ApproximateLocation> RefreshApproximateLocationAsync(CancellationToken cancellationToken = default) =>
        ReadLocation(await RequestAsync("location.refresh", null, cancellationToken, "location").ConfigureAwait(false));

    /// <summary>Renews the local anonymous installation identifier. No identifier is returned to the UI.</summary>
    public async Task RenewAnalyticsIdAsync(CancellationToken cancellationToken = default)
    {
        await RequestAsync("analytics.renew_id", null, cancellationToken, "analytics.id_renewed").ConfigureAwait(false);
    }

    private static EngineSettings ReadSettings(EngineWireMessage message)
    {
        if (message.Settings is not { ValueKind: JsonValueKind.Object } settings)
            throw new DiagnosticEngineException("INVALID_SETTINGS_RESPONSE", "O motor local retornou ajustes inválidos.");
        return new EngineSettings(Bool(settings, "reduceMotion"), Bool(settings, "artworkDownloadEnabled"), Bool(settings, "approximateLocationEnabled"), Bool(settings, "analyticsEnabled"), Bool(settings, "automaticUpdates"));
    }

    private static EngineUpdateStatus ReadUpdate(EngineWireMessage message)
    {
        if (message.Update is not { ValueKind: JsonValueKind.Object } update)
            throw new DiagnosticEngineException("INVALID_UPDATE_RESPONSE", "O motor local retornou um status de atualização inválido.");
        return new EngineUpdateStatus(Bool(update, "configured"), Long(update, "lastCheckedEpochMs"), String(update, "state") ?? "none", String(update, "version"));
    }

    private static ApproximateLocation ReadLocation(EngineWireMessage message) => new(
        message.Enabled == true,
        NullIfWhiteSpace(message.City),
        NullIfWhiteSpace(message.Country),
        message.Latitude,
        message.Longitude);

    private static IEnumerable<JsonElement> Array(JsonElement? value) => value is { ValueKind: JsonValueKind.Array } array ? array.EnumerateArray() : System.Array.Empty<JsonElement>();
    private static string Required(JsonElement value, string name) => String(value, name) ?? throw new DiagnosticEngineException("INVALID_HOST_RESPONSE", "O motor local retornou um item incompleto.");
    private static string? String(JsonElement value, string name) => value.TryGetProperty(name, out var item) && item.ValueKind == JsonValueKind.String ? item.GetString() : null;
    private static string? NullIfWhiteSpace(string? value) => string.IsNullOrWhiteSpace(value) ? null : value;
    private static double? Number(JsonElement value, string name) => value.TryGetProperty(name, out var item) && item.TryGetDouble(out var number) ? number : null;
    private static long? Long(JsonElement value, string name) => value.TryGetProperty(name, out var item) && item.TryGetInt64(out var number) ? number : null;
    private static bool Bool(JsonElement value, string name) => value.TryGetProperty(name, out var item)
        && (item.ValueKind is JsonValueKind.True or JsonValueKind.False) && item.GetBoolean();

    private async Task<EngineWireMessage> RequestAsync(string type, Dictionary<string, object?>? fields, CancellationToken cancellationToken, string? terminalType = null)
    {
        await ConnectAsync(cancellationToken).ConfigureAwait(false);
        var requestId = NewId();
        var request = new PendingRequest(terminalType);
        if (!_requests.TryAdd(requestId, request)) throw new InvalidOperationException("Não foi possível criar a requisição local.");
        var command = fields ?? new Dictionary<string, object?>();
        command["type"] = type;
        command["requestId"] = requestId;
        try
        {
            await SendAsync(command, cancellationToken).ConfigureAwait(false);
            return await request.Completion.Task.WaitAsync(cancellationToken).ConfigureAwait(false);
        }
        finally { _requests.TryRemove(requestId, out _); }
    }

    private async Task SendAsync(object command, CancellationToken cancellationToken)
    {
        var process = _process ?? throw new DiagnosticEngineException("HOST_OFFLINE", "O motor de diagnóstico não está disponível.");
        await _writeLock.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            await process.StandardInput.WriteLineAsync(JsonSerializer.Serialize(command, EngineProtocol.Json)).ConfigureAwait(false);
            await process.StandardInput.FlushAsync().ConfigureAwait(false);
        }
        finally { _writeLock.Release(); }
    }

    private async Task ReadOutputAsync(Process process)
    {
        try
        {
            while (await process.StandardOutput.ReadLineAsync().ConfigureAwait(false) is { } line)
            {
                var message = JsonSerializer.Deserialize<EngineWireMessage>(line, EngineProtocol.Json);
                if (message?.Type is not null) Handle(message);
            }
        }
        catch (Exception exception) when (exception is not ObjectDisposedException)
        {
            Fault(new DiagnosticEngineException("PROTOCOL_READ_FAILED", "A resposta do motor de diagnóstico não pôde ser lida."));
        }
    }

    // stderr is intentionally drained and not surfaced verbatim: host output can contain local paths.
    private static async Task DrainStandardErrorAsync(Process process)
    {
        try { await process.StandardError.ReadToEndAsync().ConfigureAwait(false); }
        catch (ObjectDisposedException) { }
    }

    private void Handle(EngineWireMessage message)
    {
        if (message.RequestId is { } requestId && _requests.TryGetValue(requestId, out var request))
        {
            if (message.Type == "error")
            {
                request.Completion.TrySetException(new DiagnosticEngineException(message.Code ?? "ENGINE_ERROR", message.Message ?? "O motor local recusou a ação."));
            }
            else if (request.TerminalType is null || string.Equals(request.TerminalType, message.Type, StringComparison.Ordinal))
            {
                request.Completion.TrySetResult(message);
            }
            return;
        }
        switch (message.Type)
        {
            case "hello":
                _hello?.TrySetResult(new EngineHello(message.Protocol ?? string.Empty, message.Engine ?? string.Empty));
                break;
            case "progress" when message.SessionId is not null:
                ProgressChanged?.Invoke(this, new DiagnosticProgress(message.SessionId, message.Phase ?? "rest", message.Ratio ?? 0, message.LatestPingMs));
                break;
            case "result" when message.SessionId is not null:
                var result = new DiagnosticResult(message.SessionId, message.Status ?? "completed", message.Verdict, message.Score,
                    message.PingMs, message.JitterMs, message.PacketLossPercentage, message.WorstSpikeMs, message.LoadMeasured,
                    message.RegionId, message.ProfileId, message.AbortReason, message.LatencySeries ?? []);
                CompleteSession(result);
                break;
            case "error":
                var error = new DiagnosticEngineException(message.Code ?? "ENGINE_ERROR", message.Message ?? "O motor de diagnóstico encontrou um erro.");
                if (message.SessionId is not null)
                {
                    FaultSession(message.SessionId, error);
                }
                else
                {
                    EngineFaulted?.Invoke(this, error);
                    _hello?.TrySetException(error);
                }
                break;
        }
    }

    private void CompleteSession(DiagnosticResult result)
    {
        TaskCompletionSource<DiagnosticResult>? completion = null;
        lock (_gate)
        {
            if (_activeSessionId != result.SessionId) return;
            completion = _activeResult;
            _activeResult = null;
            _activeSessionId = null;
        }
        completion?.TrySetResult(result);
        SessionActivityChanged?.Invoke(this, false);
        ResultReceived?.Invoke(this, result);
    }

    private void Fault(DiagnosticEngineException error)
    {
        EngineFaulted?.Invoke(this, error);
        _hello?.TrySetException(error);
        TaskCompletionSource<DiagnosticResult>? completion;
        lock (_gate)
        {
            completion = _activeResult;
            _activeResult = null;
            _activeSessionId = null;
        }
        completion?.TrySetException(error);
        if (completion is not null) SessionActivityChanged?.Invoke(this, false);
        foreach (var pending in _requests.Values) pending.Completion.TrySetException(error);
    }

    private void FaultSession(string sessionId, DiagnosticEngineException error)
    {
        EngineFaulted?.Invoke(this, error);
        TaskCompletionSource<DiagnosticResult>? completion = null;
        lock (_gate)
        {
            if (_activeSessionId != sessionId) return;
            completion = _activeResult;
            _activeResult = null;
            _activeSessionId = null;
        }
        completion?.TrySetException(error);
        if (completion is not null) SessionActivityChanged?.Invoke(this, false);
    }

    private void CompleteForExit() => Fault(new DiagnosticEngineException("HOST_EXITED", "O motor de diagnóstico foi encerrado."));

    private void ClearActive(string sessionId)
    {
        lock (_gate)
        {
            if (_activeSessionId == sessionId)
            {
                _activeSessionId = null;
                _activeResult = null;
                SessionActivityChanged?.Invoke(this, false);
            }
        }
    }

    private static string ResolveHostPath()
    {
        var configured = Environment.GetEnvironmentVariable("LAGCHECK_ENGINE_HOST");
        if (!string.IsNullOrWhiteSpace(configured)) return configured;
        var bundledExe = Path.Combine(AppContext.BaseDirectory, "engine", "LagCheckEngineHost.exe");
        if (File.Exists(bundledExe)) return bundledExe;
        var bundledBat = Path.Combine(AppContext.BaseDirectory, "engine", "bin", "engine-host.bat");
        if (File.Exists(bundledBat)) return bundledBat;

        // Development fallback: find the Gradle installDist from any WinUI bin/obj folder.
        var directory = new DirectoryInfo(AppContext.BaseDirectory);
        while (directory is not null)
        {
            var candidate = Path.Combine(directory.FullName, "android", "engine-host", "build", "install", "engine-host", "bin", "engine-host.bat");
            if (File.Exists(candidate)) return candidate;
            directory = directory.Parent;
        }
        return bundledExe;
    }

    private static string NewId() => Guid.NewGuid().ToString("N");

    private static ProcessStartInfo CreateProcessStartInfo(string hostPath)
    {
        var start = new ProcessStartInfo
        {
            UseShellExecute = false,
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            StandardInputEncoding = Utf8NoBom,
            StandardOutputEncoding = Utf8NoBom,
            StandardErrorEncoding = Utf8NoBom,
            CreateNoWindow = true,
        };
        if (hostPath.EndsWith(".bat", StringComparison.OrdinalIgnoreCase))
        {
            var bin = Path.GetDirectoryName(hostPath) ?? throw new DiagnosticEngineException("HOST_LAYOUT_INVALID", "A instalação do motor local está incompleta.");
            var installRoot = Directory.GetParent(bin)?.FullName ?? throw new DiagnosticEngineException("HOST_LAYOUT_INVALID", "A instalação do motor local está incompleta.");
            var bundledJava = Path.Combine(installRoot, "runtime", "bin", "java.exe");
            start.FileName = Environment.GetEnvironmentVariable("LAGCHECK_ENGINE_JAVA")
                ?? (File.Exists(bundledJava) ? bundledJava : "java.exe");
            start.ArgumentList.Add("-cp");
            start.ArgumentList.Add(Path.Combine(installRoot, "lib", "*"));
            start.ArgumentList.Add("com.lagcheck.enginehost.MainKt");
        }
        else
        {
            start.FileName = hostPath;
        }
        return start;
    }

    private sealed class PendingRequest
    {
        public PendingRequest(string? terminalType)
        {
            TerminalType = terminalType;
            Completion = new(TaskCreationOptions.RunContinuationsAsynchronously);
        }

        public string? TerminalType { get; }
        public TaskCompletionSource<EngineWireMessage> Completion { get; }
    }

    private void ThrowIfDisposed() => ObjectDisposedException.ThrowIf(_disposed, this);
    public ValueTask ShutdownAsync() => DisposeAsync();

    public async ValueTask DisposeAsync()
    {
        if (_disposed) return;
        _disposed = true;
        var process = _process;
        _process = null;
        if (process is not null)
        {
            try { if (!process.HasExited) process.Kill(entireProcessTree: true); }
            catch (InvalidOperationException) { }
            process.Dispose();
        }
        if (_reader is not null) await _reader.ConfigureAwait(false);
        if (_stderr is not null) await _stderr.ConfigureAwait(false);
        _writeLock.Dispose();
        _connectLock.Dispose();
        _libraryScanLock.Dispose();
    }
}
