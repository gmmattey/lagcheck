using System.Globalization;
using System.Net;
using System.Text.Json;

namespace LagCheck.WinUI.PlatformStatus;

/// <summary>
/// The state reported by the public LagCheck site for one platform. It is an
/// observation from that source, not a guarantee that a game or every service
/// of the platform is working.
/// </summary>
public enum PlatformServiceState
{
    Unknown,
    Operational,
    Degraded,
    Outage,
}

public enum PlatformStatusAvailability
{
    Available,
    Partial,
    Unavailable,
    Stale,
}

public sealed record PlatformServiceStatus(
    string Id,
    string Name,
    PlatformServiceState State,
    DateTimeOffset? CheckedAt);

/// <summary>
/// A point-in-time response from the site's status endpoint. Consumers must
/// present <see cref="ObservationNote"/> with any positive state and must not
/// treat it as a diagnostic result for the selected game.
/// </summary>
public sealed record PlatformStatusSnapshot(
    IReadOnlyList<PlatformServiceStatus> Platforms,
    PlatformStatusAvailability Availability,
    DateTimeOffset RetrievedAt)
{
    public const string ObservationNote = "Segundo a consulta do site; não cobre todos os serviços da plataforma.";

    public bool IsUsable => Availability is PlatformStatusAvailability.Available or PlatformStatusAvailability.Partial;
}

/// <summary>
/// Bounded, best-effort reader for the existing public status page. It sends
/// no identifier and intentionally returns unknown data on failure instead of
/// guessing that a platform is online.
/// </summary>
public sealed class PlatformStatusClient
{
    public static readonly Uri StatusEndpoint = new("https://lagcheck.signallq.com/api/status");

    private const int MaximumResponseBytes = 64 * 1024;
    private static readonly TimeSpan RequestTimeout = TimeSpan.FromSeconds(3);
    private static readonly TimeSpan CacheLifetime = TimeSpan.FromMinutes(1);
    private static readonly TimeSpan MaximumDataAge = TimeSpan.FromMinutes(5);
    private static readonly TimeSpan MaximumFutureSkew = TimeSpan.FromMinutes(1);
    private readonly HttpClient _httpClient;
    private readonly TimeProvider _clock;
    private readonly SemaphoreSlim _gate = new(1, 1);
    private readonly object _cacheLock = new();
    private CachedSnapshot? _cache;

    private static readonly PlatformDefinition[] KnownPlatforms =
    [
        new("playstation", "PlayStation Network"),
        new("xbox", "Xbox"),
        new("steam", "Steam"),
        new("epicgames", "Epic Games"),
        new("nintendo", "Nintendo"),
    ];

    public PlatformStatusClient(HttpClient? httpClient = null, TimeProvider? clock = null)
    {
        _httpClient = httpClient ?? CreateHttpClient();
        _clock = clock ?? TimeProvider.System;
    }

    /// <summary>Returns the last valid source observation, or unknown entries if it cannot be obtained.</summary>
    public async Task<PlatformStatusSnapshot> GetSnapshotAsync(
        bool forceRefresh = false,
        CancellationToken cancellationToken = default)
    {
        var now = _clock.GetUtcNow();
        if (!forceRefresh && TryGetFreshCache(now, out var cached))
        {
            return cached;
        }

        await _gate.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            now = _clock.GetUtcNow();
            if (!forceRefresh && TryGetFreshCache(now, out cached))
            {
                return cached;
            }

            var response = await FetchAsync(now, cancellationToken).ConfigureAwait(false);
            if (response is not null)
            {
                lock (_cacheLock)
                {
                    _cache = new CachedSnapshot(response, now);
                }

                return response;
            }

            return CreateUnavailableOrStaleSnapshot(now);
        }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            return CreateUnavailableOrStaleSnapshot(_clock.GetUtcNow());
        }
        catch (HttpRequestException)
        {
            return CreateUnavailableOrStaleSnapshot(_clock.GetUtcNow());
        }
        catch (IOException)
        {
            return CreateUnavailableOrStaleSnapshot(_clock.GetUtcNow());
        }
        catch (InvalidOperationException)
        {
            return CreateUnavailableOrStaleSnapshot(_clock.GetUtcNow());
        }
        catch (JsonException)
        {
            return CreateUnavailableOrStaleSnapshot(_clock.GetUtcNow());
        }
        finally
        {
            _gate.Release();
        }
    }

    /// <summary>Convenience API for widget binders that only need the typed platform list.</summary>
    public async Task<IReadOnlyList<PlatformServiceStatus>> GetStatusesAsync(
        bool forceRefresh = false,
        CancellationToken cancellationToken = default) =>
        (await GetSnapshotAsync(forceRefresh, cancellationToken).ConfigureAwait(false)).Platforms;

    private bool TryGetFreshCache(DateTimeOffset now, out PlatformStatusSnapshot snapshot)
    {
        lock (_cacheLock)
        {
            if (_cache is not null && now - _cache.StoredAt <= CacheLifetime)
            {
                snapshot = _cache.Snapshot;
                return true;
            }
        }

        snapshot = default!;
        return false;
    }

    private async Task<PlatformStatusSnapshot?> FetchAsync(DateTimeOffset now, CancellationToken cancellationToken)
    {
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeout.CancelAfter(RequestTimeout);
        using var request = new HttpRequestMessage(HttpMethod.Get, StatusEndpoint);
        using var response = await _httpClient.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, timeout.Token).ConfigureAwait(false);
        if (response.StatusCode != HttpStatusCode.OK)
        {
            return null;
        }

        var content = await ReadLimitedContentAsync(response.Content, timeout.Token).ConfigureAwait(false);
        if (content is null)
        {
            return null;
        }

        using var document = JsonDocument.Parse(content);
        return ParseSnapshot(document.RootElement, now);
    }

    private static async Task<byte[]?> ReadLimitedContentAsync(HttpContent content, CancellationToken cancellationToken)
    {
        if (content.Headers.ContentLength is > MaximumResponseBytes)
        {
            return null;
        }

        await using var stream = await content.ReadAsStreamAsync(cancellationToken).ConfigureAwait(false);
        using var output = new MemoryStream();
        var buffer = new byte[4096];
        int read;
        while ((read = await stream.ReadAsync(buffer.AsMemory(), cancellationToken).ConfigureAwait(false)) > 0)
        {
            if (output.Length + read > MaximumResponseBytes)
            {
                return null;
            }

            output.Write(buffer, 0, read);
        }

        return output.ToArray();
    }

    private static PlatformStatusSnapshot? ParseSnapshot(JsonElement root, DateTimeOffset now)
    {
        if (root.ValueKind != JsonValueKind.Object || !root.TryGetProperty("platforms", out var platforms) || platforms.ValueKind != JsonValueKind.Array)
        {
            return null;
        }

        var values = new Dictionary<string, PlatformServiceStatus>(StringComparer.Ordinal);
        foreach (var item in platforms.EnumerateArray())
        {
            if (item.ValueKind != JsonValueKind.Object || !TryReadKnownId(item, out var id) || values.ContainsKey(id))
            {
                continue;
            }

            var definition = KnownPlatforms.Single(platform => platform.Id == id);
            var checkedAt = ReadTimestamp(item, now);
            var state = checkedAt is null ? PlatformServiceState.Unknown : ReadState(item);
            values[id] = new PlatformServiceStatus(id, ReadName(item, definition.Name), state, checkedAt);
        }

        var result = new List<PlatformServiceStatus>(KnownPlatforms.Length);
        foreach (var definition in KnownPlatforms)
        {
            result.Add(values.TryGetValue(definition.Id, out var status)
                ? status
                : new PlatformServiceStatus(definition.Id, definition.Name, PlatformServiceState.Unknown, null));
        }

        var hasKnownObservation = result.Any(status => status.State != PlatformServiceState.Unknown);
        var hasCompleteKnownObservation = result.All(status => status.State != PlatformServiceState.Unknown);
        return new PlatformStatusSnapshot(
            result,
            hasCompleteKnownObservation && values.Count == KnownPlatforms.Length
                ? PlatformStatusAvailability.Available
                : hasKnownObservation ? PlatformStatusAvailability.Partial : PlatformStatusAvailability.Unavailable,
            now);
    }

    private static string ReadName(JsonElement item, string fallback)
    {
        if (!item.TryGetProperty("name", out var name) || name.ValueKind != JsonValueKind.String)
        {
            return fallback;
        }

        var value = name.GetString()?.Trim();
        return string.IsNullOrWhiteSpace(value) || value.Length > 80 ? fallback : value;
    }

    private static bool TryReadKnownId(JsonElement item, out string id)
    {
        id = string.Empty;
        if (!item.TryGetProperty("id", out var idValue) || idValue.ValueKind != JsonValueKind.String)
        {
            return false;
        }

        var value = idValue.GetString();
        if (value is null || !KnownPlatforms.Any(platform => platform.Id == value))
        {
            return false;
        }

        id = value;
        return true;
    }

    private static DateTimeOffset? ReadTimestamp(JsonElement item, DateTimeOffset now)
    {
        if (!item.TryGetProperty("checkedAt", out var timestamp) || timestamp.ValueKind != JsonValueKind.String ||
            !DateTimeOffset.TryParse(timestamp.GetString(), CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind, out var checkedAt))
        {
            return null;
        }

        checkedAt = checkedAt.ToUniversalTime();
        return checkedAt > now + MaximumFutureSkew || now - checkedAt > MaximumDataAge ? null : checkedAt;
    }

    private static PlatformServiceState ReadState(JsonElement item)
    {
        if (!item.TryGetProperty("status", out var value) || value.ValueKind != JsonValueKind.String)
        {
            return PlatformServiceState.Unknown;
        }

        return value.GetString() switch
        {
            "operational" => PlatformServiceState.Operational,
            "degraded" => PlatformServiceState.Degraded,
            "outage" => PlatformServiceState.Outage,
            _ => PlatformServiceState.Unknown,
        };
    }

    private PlatformStatusSnapshot CreateUnavailableOrStaleSnapshot(DateTimeOffset now)
    {
        lock (_cacheLock)
        {
            if (_cache is not null)
            {
                return new PlatformStatusSnapshot(
                    _cache.Snapshot.Platforms
                        .Select(platform => platform with { State = PlatformServiceState.Unknown })
                        .ToArray(),
                    PlatformStatusAvailability.Stale,
                    now);
            }
        }

        return new PlatformStatusSnapshot(
            KnownPlatforms.Select(platform => new PlatformServiceStatus(platform.Id, platform.Name, PlatformServiceState.Unknown, null)).ToArray(),
            PlatformStatusAvailability.Unavailable,
            now);
    }

    private static HttpClient CreateHttpClient()
    {
        var handler = new HttpClientHandler { AllowAutoRedirect = false };
        return new HttpClient(handler) { Timeout = Timeout.InfiniteTimeSpan };
    }

    private sealed record PlatformDefinition(string Id, string Name);
    private sealed record CachedSnapshot(PlatformStatusSnapshot Snapshot, DateTimeOffset StoredAt);
}
