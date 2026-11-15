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
    private const int MaxRequirementsLength = 600;
    private const int CacheVersion = 2;

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
        var modes = localized.Modes.Count > 0 ? localized.Modes : (baseInfo?.Modes ?? Array.Empty<string>());
        var merged = new GameInfo(
            Description: !string.IsNullOrWhiteSpace(localized.Description) ? localized.Description : baseInfo?.Description,
            Developer: !string.IsNullOrWhiteSpace(localized.Developer) ? localized.Developer : baseInfo?.Developer,
            Publisher: !string.IsNullOrWhiteSpace(localized.Publisher) ? localized.Publisher : baseInfo?.Publisher,
            ReleaseDate: !string.IsNullOrWhiteSpace(localized.ReleaseDate) ? localized.ReleaseDate : baseInfo?.ReleaseDate,
            Genres: localized.Genres.Count > 0 ? localized.Genres : (baseInfo?.Genres ?? Array.Empty<string>()),
            Modes: modes,
            ControllerSupport: localized.ControllerSupport ?? baseInfo?.ControllerSupport,
            MetacriticScore: localized.MetacriticScore ?? baseInfo?.MetacriticScore,
            RecommendationsTotal: localized.RecommendationsTotal ?? baseInfo?.RecommendationsTotal,
            HasCloudSaves: localized.HasCloudSaves || (baseInfo?.HasCloudSaves ?? false),
            AntiCheat: localized.AntiCheat ?? baseInfo?.AntiCheat,
            HasPtBr: localized.HasPtBr ?? baseInfo?.HasPtBr,
            PcMinimumRequirements: localized.PcMinimumRequirements ?? baseInfo?.PcMinimumRequirements,
            StoreScreenshots: localized.StoreScreenshots is { Count: > 0 } ? localized.StoreScreenshots : baseInfo?.StoreScreenshots);

        var networkKind = game.NetworkKind;
        var networkLabel = game.NetworkLabel;
        if (networkKind == GameNetworkKind.General && merged.IsStrictlyOffline)
        {
            networkKind = GameNetworkKind.Offline;
            networkLabel = Strings.Tr("Jogo solo, sem servidor para medir");
        }

        return game with
        {
            Description = merged.Description ?? game.Description,
            Info = merged,
            NetworkKind = networkKind,
            NetworkLabel = networkLabel,
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

            var categoryIds = new HashSet<int>();
            var modes = new List<string>();
            if (data.TryGetProperty("categories", out var catArr) && catArr.ValueKind == JsonValueKind.Array)
            {
                foreach (var item in catArr.EnumerateArray())
                {
                    if (item.ValueKind != JsonValueKind.Object || !item.TryGetProperty("id", out var idEl)) continue;
                    int catId;
                    if (idEl.ValueKind == JsonValueKind.Number && idEl.TryGetInt32(out var numId)) catId = numId;
                    else if (idEl.ValueKind == JsonValueKind.String && int.TryParse(idEl.GetString(), out var strId)) catId = strId;
                    else continue;

                    categoryIds.Add(catId);
                    var mode = MapSteamCategoryMode(catId);
                    if (mode is not null && !modes.Contains(mode, StringComparer.Ordinal))
                        modes.Add(mode);
                }
            }

            string? controllerSupport = null;
            if (data.TryGetProperty("controller_support", out var ctrlEl) && ctrlEl.ValueKind == JsonValueKind.String)
            {
                var norm = ctrlEl.GetString()?.Trim().ToLowerInvariant();
                if (norm is "full" or "partial") controllerSupport = norm;
            }
            controllerSupport ??= categoryIds.Contains(28) ? "full" : categoryIds.Contains(18) ? "partial" : null;

            int? metacriticScore = null;
            if (data.TryGetProperty("metacritic", out var metaObj) && metaObj.ValueKind == JsonValueKind.Object
                && metaObj.TryGetProperty("score", out var scoreEl) && scoreEl.TryGetInt32(out var score)
                && score is >= 1 and <= 100)
            {
                metacriticScore = score;
            }

            int? recommendationsTotal = null;
            if (data.TryGetProperty("recommendations", out var recObj) && recObj.ValueKind == JsonValueKind.Object
                && recObj.TryGetProperty("total", out var totalEl) && totalEl.TryGetInt32(out var total)
                && total > 0)
            {
                recommendationsTotal = total;
            }

            var hasCloudSaves = categoryIds.Contains(23);
            var antiCheat = categoryIds.Contains(8) ? "VAC" : null;

            bool? hasPtBr = null;
            if (data.TryGetProperty("supported_languages", out var langsEl) && langsEl.ValueKind == JsonValueKind.String)
            {
                var langsClean = CleanDescription(langsEl.GetString())?.ToLowerInvariant();
                if (!string.IsNullOrEmpty(langsClean))
                {
                    hasPtBr = langsClean.Contains("português (brasil)", StringComparison.Ordinal) ||
                              langsClean.Contains("portuguese - brazil", StringComparison.Ordinal) ||
                              langsClean.Contains("portugues (brasil)", StringComparison.Ordinal) ||
                              langsClean.Contains("português do brasil", StringComparison.Ordinal);
                }
            }

            string? pcMinimumRequirements = null;
            if (data.TryGetProperty("pc_requirements", out var reqObj) && reqObj.ValueKind == JsonValueKind.Object
                && reqObj.TryGetProperty("minimum", out var minEl) && minEl.ValueKind == JsonValueKind.String)
            {
                pcMinimumRequirements = CleanRequirements(minEl.GetString());
            }

            var storeScreenshots = new List<string>(6);
            if (data.TryGetProperty("screenshots", out var shotsArr) && shotsArr.ValueKind == JsonValueKind.Array)
            {
                foreach (var item in shotsArr.EnumerateArray())
                {
                    if (item.ValueKind != JsonValueKind.Object) continue;
                    string? url = null;
                    if (item.TryGetProperty("path_full", out var fullEl) && fullEl.ValueKind == JsonValueKind.String)
                        url = fullEl.GetString()?.Trim();
                    else if (item.TryGetProperty("path_thumbnail", out var thumbEl) && thumbEl.ValueKind == JsonValueKind.String)
                        url = thumbEl.GetString()?.Trim();

                    if (string.IsNullOrWhiteSpace(url)) continue;
                    if (!url.StartsWith("https://", StringComparison.OrdinalIgnoreCase) &&
                        !url.StartsWith("http://", StringComparison.OrdinalIgnoreCase))
                        continue;
                    if (!storeScreenshots.Contains(url, StringComparer.Ordinal))
                    {
                        storeScreenshots.Add(url);
                        if (storeScreenshots.Count >= 6) break;
                    }
                }
            }

            var info = new GameInfo(
                description,
                developer,
                publisher,
                releaseDate,
                genres,
                modes,
                ControllerSupport: controllerSupport,
                MetacriticScore: metacriticScore,
                RecommendationsTotal: recommendationsTotal,
                HasCloudSaves: hasCloudSaves,
                AntiCheat: antiCheat,
                HasPtBr: hasPtBr,
                PcMinimumRequirements: pcMinimumRequirements,
                StoreScreenshots: storeScreenshots);
            return info.IsEmpty ? null : info;
        }
        catch
        {
            return null;
        }
    }

    private static string? MapSteamCategoryMode(int id) => id switch
    {
        2 => "singleplayer",
        1 or 49 => "multiplayer",
        36 => "online_multiplayer",
        9 => "coop",
        38 => "online_coop",
        20 => "mmo",
        27 => "crossplay",
        _ => null,
    };

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

    private static string? CleanRequirements(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return null;
        var withLines = LineBreakTagRegex().Replace(raw, "\n");
        var withoutTags = HtmlTagRegex().Replace(withLines, " ");
        var decoded = WebUtility.HtmlDecode(withoutTags);
        var lines = decoded
            .Split('\n')
            .Select(line => WhitespaceRegex().Replace(line, " ").Trim())
            .Where(line => !string.IsNullOrWhiteSpace(line) && !line.Equals("Mínimos:", StringComparison.OrdinalIgnoreCase) && !line.Equals("Minimum:", StringComparison.OrdinalIgnoreCase) && !line.Equals("Mínimo:", StringComparison.OrdinalIgnoreCase))
            .ToList();
        if (lines.Count == 0) return null;
        var joined = string.Join(" · ", lines);
        return joined.Length <= MaxRequirementsLength
            ? joined
            : joined[..(MaxRequirementsLength - 1)].TrimEnd() + "…";
    }

    [GeneratedRegex(@"<(?:br|li|/p|/tr)[^>]*>", RegexOptions.IgnoreCase)]
    private static partial Regex LineBreakTagRegex();

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
            if (!root.TryGetProperty("v", out var versionProp) || !versionProp.TryGetInt32(out var version) || version < CacheVersion)
                return null;
            if (!root.TryGetProperty("fetchedAt", out var atProp) || !atProp.TryGetInt64(out var fetchedAt))
                return null;

            GameInfo? info = null;
            if (root.TryGetProperty("info", out var infoProp) && infoProp.ValueKind == JsonValueKind.Object)
            {
                var desc = ReadJsonString(infoProp, "description");
                var dev = ReadJsonString(infoProp, "developer");
                var pub = ReadJsonString(infoProp, "publisher");
                var rel = ReadJsonString(infoProp, "releaseDate");
                var genres = ReadJsonStrings(infoProp, "genres");
                var modes = ReadJsonStrings(infoProp, "modes");
                var controllerSupport = ReadJsonString(infoProp, "controllerSupport");
                var metacriticScore = infoProp.TryGetProperty("metacriticScore", out var mc) && mc.TryGetInt32(out var mcVal) ? mcVal : (int?)null;
                var recommendationsTotal = infoProp.TryGetProperty("recommendationsTotal", out var rec) && rec.TryGetInt32(out var recVal) ? recVal : (int?)null;
                var hasCloudSaves = infoProp.TryGetProperty("hasCloudSaves", out var cs) && cs.ValueKind == JsonValueKind.True;
                var antiCheat = ReadJsonString(infoProp, "antiCheat");
                bool? hasPtBr = infoProp.TryGetProperty("hasPtBr", out var pt) && pt.ValueKind is JsonValueKind.True or JsonValueKind.False
                    ? pt.GetBoolean()
                    : null;
                var pcMinimumRequirements = ReadJsonString(infoProp, "pcMinimumRequirements");
                var storeScreenshots = ReadJsonStrings(infoProp, "storeScreenshots");
                info = new GameInfo(
                    desc,
                    dev,
                    pub,
                    rel,
                    genres,
                    modes,
                    ControllerSupport: controllerSupport,
                    MetacriticScore: metacriticScore,
                    RecommendationsTotal: recommendationsTotal,
                    HasCloudSaves: hasCloudSaves,
                    AntiCheat: antiCheat,
                    HasPtBr: hasPtBr,
                    PcMinimumRequirements: pcMinimumRequirements,
                    StoreScreenshots: storeScreenshots);
                if (info.IsEmpty) info = null;
            }

            return new CachedEntry(fetchedAt, info);
        }
        catch
        {
            return null;
        }
    }

    private static string? ReadJsonString(JsonElement obj, string name) =>
        obj.TryGetProperty(name, out var prop) && prop.ValueKind == JsonValueKind.String ? prop.GetString() : null;

    private static List<string> ReadJsonStrings(JsonElement obj, string name)
    {
        var list = new List<string>();
        if (obj.TryGetProperty(name, out var arr) && arr.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in arr.EnumerateArray())
            {
                if (item.ValueKind == JsonValueKind.String && item.GetString() is { Length: > 0 } s)
                    list.Add(s);
            }
        }
        return list;
    }

    private static void WriteDiskCache(string path, CachedEntry entry)
    {
        try
        {
            var dir = Path.GetDirectoryName(path);
            if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);
            var payload = new
            {
                v = CacheVersion,
                fetchedAt = entry.FetchedAtMs,
                info = entry.Info is null ? null : new
                {
                    description = entry.Info.Description,
                    developer = entry.Info.Developer,
                    publisher = entry.Info.Publisher,
                    releaseDate = entry.Info.ReleaseDate,
                    genres = entry.Info.Genres,
                    modes = entry.Info.Modes,
                    controllerSupport = entry.Info.ControllerSupport,
                    metacriticScore = entry.Info.MetacriticScore,
                    recommendationsTotal = entry.Info.RecommendationsTotal,
                    hasCloudSaves = entry.Info.HasCloudSaves,
                    antiCheat = entry.Info.AntiCheat,
                    hasPtBr = entry.Info.HasPtBr,
                    pcMinimumRequirements = entry.Info.PcMinimumRequirements,
                    storeScreenshots = entry.Info.StoreScreenshots,
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
