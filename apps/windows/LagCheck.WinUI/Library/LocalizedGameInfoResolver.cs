using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using LagCheck.WinUI.Localization;

namespace LagCheck.WinUI.Library;

/// <summary>
/// Resolve metadados localizados de jogos da Steam (descrição, gêneros e lançamento)
/// de acordo com o idioma ativo em <see cref="LocalizationService"/>, com cache em disco por idioma.
/// Nunca lança exceção quando está offline ou fora da Steam: devolve o jogo original sem bloquear a tela.
/// </summary>
public static partial class LocalizedGameInfoResolver
{
    private const long PositiveTtlMs = 14L * 24 * 60 * 60 * 1000;
    private const long NegativeTtlMs = 24L * 60 * 60 * 1000;
    private const int MaxDescriptionLength = 600;

    private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromSeconds(6) };
    private static readonly ConcurrentDictionary<string, CachedEntry> MemoryCache = new(StringComparer.Ordinal);

    private sealed record CachedEntry(long FetchedAtMs, GameInfo? Info);

    public static async Task<LibraryGame> ResolveAsync(LibraryGame game, AppLanguage language, CancellationToken cancellationToken = default)
    {
        var appId = ExtractSteamAppId(game);
        if (appId is null) return game;

        var (langCode, steamLang, cc) = MapLanguage(language);
        var cacheKey = $"{appId}_{langCode}";
        var nowMs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

        if (MemoryCache.TryGetValue(cacheKey, out var mem) && IsFresh(mem, nowMs))
        {
            return ApplyLocalizedInfo(game, mem.Info);
        }

        var cachePath = GetCacheFilePath(cacheKey);
        var disk = ReadDiskCache(cachePath);
        if (disk is not null && IsFresh(disk, nowMs))
        {
            MemoryCache[cacheKey] = disk;
            return ApplyLocalizedInfo(game, disk.Info);
        }

        try
        {
            var url = $"https://store.steampowered.com/api/appdetails?appids={appId}&l={steamLang}&cc={cc}";
            using var request = new HttpRequestMessage(HttpMethod.Get, url);
            request.Headers.UserAgent.ParseAdd("LagCheck/1.0");
            using var response = await Http.SendAsync(request, cancellationToken).ConfigureAwait(false);
            if (!response.IsSuccessStatusCode)
            {
                return disk is not null ? ApplyLocalizedInfo(game, disk.Info) : game;
            }

            var body = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
            var parsed = ParseSteamAppDetails(body, appId);
            var entry = new CachedEntry(nowMs, parsed);
            MemoryCache[cacheKey] = entry;
            WriteDiskCache(cachePath, entry);
            return ApplyLocalizedInfo(game, parsed);
        }
        catch (OperationCanceledException)
        {
            return game;
        }
        catch
        {
            return disk is not null ? ApplyLocalizedInfo(game, disk.Info) : game;
        }
    }

    private static string? ExtractSteamAppId(LibraryGame game)
    {
        if (game.Platform != GamePlatform.Steam || !game.Id.StartsWith("steam_", StringComparison.Ordinal))
            return null;

        var raw = game.Id.Substring("steam_".Length);
        return raw.Length > 0 && raw.All(char.IsDigit) ? raw : null;
    }

    private static (string LangCode, string SteamLang, string Cc) MapLanguage(AppLanguage language) => language switch
    {
        AppLanguage.En => ("en", "english", "us"),
        AppLanguage.Es => ("es", "spanish", "es"),
        _ => ("pt-BR", "brazilian", "br"),
    };

    private static bool IsFresh(CachedEntry entry, long nowMs)
    {
        var ttl = entry.Info is null ? NegativeTtlMs : PositiveTtlMs;
        return nowMs - entry.FetchedAtMs < ttl;
    }

    private static LibraryGame ApplyLocalizedInfo(LibraryGame game, GameInfo? localized)
    {
        if (localized is null) return game;

        var baseInfo = game.Info;
        var merged = new GameInfo(
            Description: !string.IsNullOrWhiteSpace(localized.Description) ? localized.Description : baseInfo?.Description,
            Developer: !string.IsNullOrWhiteSpace(localized.Developer) ? localized.Developer : baseInfo?.Developer,
            Publisher: !string.IsNullOrWhiteSpace(localized.Publisher) ? localized.Publisher : baseInfo?.Publisher,
            ReleaseDate: !string.IsNullOrWhiteSpace(localized.ReleaseDate) ? localized.ReleaseDate : baseInfo?.ReleaseDate,
            Genres: localized.Genres.Count > 0 ? localized.Genres : (baseInfo?.Genres ?? Array.Empty<string>()),
            Modes: baseInfo?.Modes ?? Array.Empty<string>());

        return game with
        {
            Description = merged.Description ?? game.Description,
            Info = merged,
        };
    }

    internal static GameInfo? ParseSteamAppDetails(string json, string appId)
    {
        try
        {
            using var doc = JsonDocument.Parse(json);
            if (!doc.RootElement.TryGetProperty(appId, out var entry) || entry.ValueKind != JsonValueKind.Object)
                return null;
            if (!entry.TryGetProperty("success", out var successProp) || successProp.ValueKind != JsonValueKind.True)
                return null;
            if (!entry.TryGetProperty("data", out var data) || data.ValueKind != JsonValueKind.Object)
                return null;

            var description = data.TryGetProperty("short_description", out var descProp) && descProp.ValueKind == JsonValueKind.String
                ? CleanDescription(descProp.GetString())
                : null;

            var developer = ReadFirstString(data, "developers");
            var publisher = ReadFirstString(data, "publishers");

            string? releaseDate = null;
            if (data.TryGetProperty("release_date", out var releaseObj) && releaseObj.ValueKind == JsonValueKind.Object
                && releaseObj.TryGetProperty("date", out var dateProp) && dateProp.ValueKind == JsonValueKind.String)
            {
                var d = dateProp.GetString()?.Trim();
                if (!string.IsNullOrWhiteSpace(d)) releaseDate = d;
            }

            var genres = new List<string>();
            if (data.TryGetProperty("genres", out var genresArr) && genresArr.ValueKind == JsonValueKind.Array)
            {
                foreach (var item in genresArr.EnumerateArray())
                {
                    if (item.ValueKind == JsonValueKind.Object
                        && item.TryGetProperty("description", out var genreDesc)
                        && genreDesc.ValueKind == JsonValueKind.String)
                    {
                        var val = genreDesc.GetString()?.Trim();
                        if (!string.IsNullOrWhiteSpace(val)) genres.Add(val);
                    }
                }
            }

            var info = new GameInfo(description, developer, publisher, releaseDate, genres, Array.Empty<string>());
            return info.IsEmpty ? null : info;
        }
        catch
        {
            return null;
        }
    }

    private static string? ReadFirstString(JsonElement data, string propertyName)
    {
        if (!data.TryGetProperty(propertyName, out var arr) || arr.ValueKind != JsonValueKind.Array)
            return null;
        foreach (var item in arr.EnumerateArray())
        {
            if (item.ValueKind == JsonValueKind.String)
            {
                var value = item.GetString()?.Trim();
                if (!string.IsNullOrWhiteSpace(value)) return value;
            }
        }
        return null;
    }

    private static string? CleanDescription(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return null;
        var withoutTags = HtmlTagRegex().Replace(raw, " ");
        var decoded = WebUtility.HtmlDecode(withoutTags);
        var collapsed = WhitespaceRegex().Replace(decoded, " ").Trim();
        if (string.IsNullOrWhiteSpace(collapsed)) return null;
        return collapsed.Length <= MaxDescriptionLength
            ? collapsed
            : collapsed[..(MaxDescriptionLength - 1)].TrimEnd() + "…";
    }

    [GeneratedRegex("<[^>]+>")]
    private static partial Regex HtmlTagRegex();

    [GeneratedRegex(@"\s+")]
    private static partial Regex WhitespaceRegex();

    private static string GetCacheFilePath(string cacheKey)
    {
        var baseDir = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
        if (string.IsNullOrWhiteSpace(baseDir))
            baseDir = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        return Path.Combine(baseDir, "LagCheck", "info-cache", $"steam_{cacheKey}.json");
    }

    private static CachedEntry? ReadDiskCache(string path)
    {
        try
        {
            if (!File.Exists(path)) return null;
            using var doc = JsonDocument.Parse(File.ReadAllText(path));
            var root = doc.RootElement;
            if (!root.TryGetProperty("fetchedAt", out var atProp) || !atProp.TryGetInt64(out var fetchedAt))
                return null;

            GameInfo? info = null;
            if (root.TryGetProperty("info", out var infoProp) && infoProp.ValueKind == JsonValueKind.Object)
            {
                var desc = infoProp.TryGetProperty("description", out var d) && d.ValueKind == JsonValueKind.String ? d.GetString() : null;
                var dev = infoProp.TryGetProperty("developer", out var dv) && dv.ValueKind == JsonValueKind.String ? dv.GetString() : null;
                var pub = infoProp.TryGetProperty("publisher", out var p) && p.ValueKind == JsonValueKind.String ? p.GetString() : null;
                var rel = infoProp.TryGetProperty("releaseDate", out var r) && r.ValueKind == JsonValueKind.String ? r.GetString() : null;
                var genres = new List<string>();
                if (infoProp.TryGetProperty("genres", out var g) && g.ValueKind == JsonValueKind.Array)
                {
                    foreach (var item in g.EnumerateArray())
                    {
                        if (item.ValueKind == JsonValueKind.String && item.GetString() is { Length: > 0 } s)
                            genres.Add(s);
                    }
                }
                info = new GameInfo(desc, dev, pub, rel, genres, Array.Empty<string>());
                if (info.IsEmpty) info = null;
            }

            return new CachedEntry(fetchedAt, info);
        }
        catch
        {
            return null;
        }
    }

    private static void WriteDiskCache(string path, CachedEntry entry)
    {
        try
        {
            var dir = Path.GetDirectoryName(path);
            if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);
            var payload = new
            {
                fetchedAt = entry.FetchedAtMs,
                info = entry.Info is null ? null : new
                {
                    description = entry.Info.Description,
                    developer = entry.Info.Developer,
                    publisher = entry.Info.Publisher,
                    releaseDate = entry.Info.ReleaseDate,
                    genres = entry.Info.Genres,
                }
            };
            var tmp = path + ".tmp";
            File.WriteAllText(tmp, JsonSerializer.Serialize(payload));
            File.Move(tmp, path, overwrite: true);
        }
        catch
        {
            // Cache em disco é otimização; falha silenciosa não afeta a UI.
        }
    }
}
