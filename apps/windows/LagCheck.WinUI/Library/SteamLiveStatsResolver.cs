using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace LagCheck.WinUI.Library;

public sealed record SteamNewsItem(
    string Title,
    string Url,
    string Author,
    string FeedLabel,
    DateTimeOffset PublishedAt);

public sealed record SteamLiveStats(
    int? CurrentPlayers,
    IReadOnlyList<SteamNewsItem> News);

/// <summary>
/// Consulta dados públicos ao vivo da Steam para a página de detalhes (jogadores online agora e notas recentes)
/// sem login nem chave de API, com cache curto em memória e degradação silenciosa offline.
/// </summary>
public static class SteamLiveStatsResolver
{
    private const long PlayersTtlMs = 2L * 60 * 1000;
    private const long NewsTtlMs = 30L * 60 * 1000;
    private const long ErrorTtlMs = 60L * 1000;

    private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromSeconds(5) };
    private static readonly ConcurrentDictionary<string, CachedPlayers> PlayersCache = new(StringComparer.Ordinal);
    private static readonly ConcurrentDictionary<string, CachedNews> NewsCache = new(StringComparer.Ordinal);

    private sealed record CachedPlayers(long FetchedAtMs, int? Count, bool Failed);
    private sealed record CachedNews(long FetchedAtMs, IReadOnlyList<SteamNewsItem> Items, bool Failed);

    public static async Task<SteamLiveStats?> ResolveAsync(LibraryGame game, CancellationToken cancellationToken = default)
    {
        var appId = ExtractSteamAppId(game);
        if (appId is null) return null;

        var playersTask = ResolvePlayersAsync(appId, cancellationToken);
        var newsTask = ResolveNewsAsync(appId, cancellationToken);
        await Task.WhenAll(playersTask, newsTask).ConfigureAwait(false);

        var players = await playersTask.ConfigureAwait(false);
        var news = await newsTask.ConfigureAwait(false);
        if (players is null && news.Count == 0) return null;
        return new SteamLiveStats(players, news);
    }

    public static int? ParsePlayerCount(string json)
    {
        if (string.IsNullOrWhiteSpace(json)) return null;
        try
        {
            using var doc = JsonDocument.Parse(json);
            if (!doc.RootElement.TryGetProperty("response", out var response) || response.ValueKind != JsonValueKind.Object)
                return null;
            if (!response.TryGetProperty("result", out var resultEl) || resultEl.ValueKind != JsonValueKind.Number || resultEl.GetInt32() != 1)
                return null;
            if (!response.TryGetProperty("player_count", out var countEl) || countEl.ValueKind != JsonValueKind.Number)
                return null;
            var count = countEl.GetInt32();
            return count >= 0 ? count : null;
        }
        catch
        {
            return null;
        }
    }

    public static IReadOnlyList<SteamNewsItem> ParseNews(string json, int maxItems = 3)
    {
        if (string.IsNullOrWhiteSpace(json) || maxItems <= 0) return Array.Empty<SteamNewsItem>();
        try
        {
            using var doc = JsonDocument.Parse(json);
            if (!doc.RootElement.TryGetProperty("appnews", out var appnews) || appnews.ValueKind != JsonValueKind.Object)
                return Array.Empty<SteamNewsItem>();
            if (!appnews.TryGetProperty("newsitems", out var itemsEl) || itemsEl.ValueKind != JsonValueKind.Array)
                return Array.Empty<SteamNewsItem>();

            var items = new List<SteamNewsItem>(maxItems);
            foreach (var item in itemsEl.EnumerateArray())
            {
                if (item.ValueKind != JsonValueKind.Object) continue;
                var title = ReadString(item, "title");
                var url = ReadString(item, "url");
                if (title is null || url is null) continue;
                if (!Uri.TryCreate(url, UriKind.Absolute, out var uri) ||
                    (uri.Scheme != Uri.UriSchemeHttps && uri.Scheme != Uri.UriSchemeHttp))
                {
                    continue;
                }

                var epochSeconds = item.TryGetProperty("date", out var dateEl) && dateEl.ValueKind == JsonValueKind.Number && dateEl.TryGetInt64(out var sec)
                    ? sec
                    : 0L;
                var publishedAt = epochSeconds > 0
                    ? DateTimeOffset.FromUnixTimeSeconds(epochSeconds)
                    : DateTimeOffset.MinValue;
                var author = ReadString(item, "author") ?? string.Empty;
                var feedLabel = ReadString(item, "feedlabel") ?? string.Empty;
                items.Add(new SteamNewsItem(title, uri.AbsoluteUri, author, feedLabel, publishedAt));
                if (items.Count >= maxItems) break;
            }
            return items;
        }
        catch
        {
            return Array.Empty<SteamNewsItem>();
        }
    }

    private static async Task<int?> ResolvePlayersAsync(string appId, CancellationToken cancellationToken)
    {
        var nowMs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        if (PlayersCache.TryGetValue(appId, out var cached) &&
            nowMs - cached.FetchedAtMs < (cached.Failed ? ErrorTtlMs : PlayersTtlMs))
        {
            return cached.Count;
        }

        try
        {
            var url = $"https://api.steampowered.com/ISteamUserStats/GetNumberOfCurrentPlayers/v1/?appid={appId}";
            using var request = new HttpRequestMessage(HttpMethod.Get, url);
            request.Headers.UserAgent.ParseAdd("LagCheck/1.0");
            using var response = await Http.SendAsync(request, cancellationToken).ConfigureAwait(false);
            if (!response.IsSuccessStatusCode)
            {
                PlayersCache[appId] = new CachedPlayers(nowMs, cached?.Count, Failed: true);
                return cached?.Count;
            }

            var body = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
            var parsed = ParsePlayerCount(body);
            PlayersCache[appId] = new CachedPlayers(nowMs, parsed, Failed: parsed is null);
            return parsed;
        }
        catch (OperationCanceledException)
        {
            return cached?.Count;
        }
        catch
        {
            PlayersCache[appId] = new CachedPlayers(nowMs, cached?.Count, Failed: true);
            return cached?.Count;
        }
    }

    private static async Task<IReadOnlyList<SteamNewsItem>> ResolveNewsAsync(string appId, CancellationToken cancellationToken)
    {
        var nowMs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        if (NewsCache.TryGetValue(appId, out var cached) &&
            nowMs - cached.FetchedAtMs < (cached.Failed ? ErrorTtlMs : NewsTtlMs))
        {
            return cached.Items;
        }

        try
        {
            var url = $"https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid={appId}&count=5&maxlength=120&format=json";
            using var request = new HttpRequestMessage(HttpMethod.Get, url);
            request.Headers.UserAgent.ParseAdd("LagCheck/1.0");
            using var response = await Http.SendAsync(request, cancellationToken).ConfigureAwait(false);
            if (!response.IsSuccessStatusCode)
            {
                NewsCache[appId] = new CachedNews(nowMs, cached?.Items ?? Array.Empty<SteamNewsItem>(), Failed: true);
                return cached?.Items ?? Array.Empty<SteamNewsItem>();
            }

            var body = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
            var parsed = ParseNews(body, maxItems: 3);
            NewsCache[appId] = new CachedNews(nowMs, parsed, Failed: false);
            return parsed;
        }
        catch (OperationCanceledException)
        {
            return cached?.Items ?? Array.Empty<SteamNewsItem>();
        }
        catch
        {
            NewsCache[appId] = new CachedNews(nowMs, cached?.Items ?? Array.Empty<SteamNewsItem>(), Failed: true);
            return cached?.Items ?? Array.Empty<SteamNewsItem>();
        }
    }

    private static string? ExtractSteamAppId(LibraryGame game)
    {
        if (game.Platform != GamePlatform.Steam || !game.Id.StartsWith("steam_", StringComparison.Ordinal))
            return null;
        var raw = game.Id.Substring("steam_".Length);
        return raw.Length > 0 && raw.All(char.IsDigit) ? raw : null;
    }

    private static string? ReadString(JsonElement obj, string name)
    {
        if (!obj.TryGetProperty(name, out var prop) || prop.ValueKind != JsonValueKind.String) return null;
        var text = prop.GetString()?.Trim();
        return string.IsNullOrEmpty(text) ? null : text;
    }
}
