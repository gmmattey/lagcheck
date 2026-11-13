using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;

namespace LagCheck.WinUI.Library;

/// <summary>Conversão literal do NDJSON v1 emitido pelo host Kotlin; não contém regra de negócio.</summary>
public static class LibraryWireParser
{
    public static LibrarySnapshot ParseSnapshot(JsonElement message)
    {
        var snapshot = message.TryGetProperty("snapshot", out var nested) ? nested : message;
        return new LibrarySnapshot(
            ReadBoolean(snapshot, "isScanning"),
            ReadBoolean(snapshot, "hasScanned"),
            ReadString(snapshot, "heroGameId"),
            ReadString(snapshot, "selectedGameId"),
            ReadArray(snapshot, "games").Select(ParseGame).ToArray(),
            ReadString(snapshot, "notice"));
    }

    public static LibraryOperationResult ParseOperation(JsonElement message)
    {
        var type = ReadString(message, "type");
        if (string.Equals(type, "error", StringComparison.Ordinal))
            return LibraryOperationResult.Failure(ReadString(message, "message") ?? "O motor local não concluiu a ação.");

        var snapshot = message.TryGetProperty("snapshot", out _) ? ParseSnapshot(message) : null;
        var started = !string.Equals(type, "library.launch", StringComparison.Ordinal) || ReadBoolean(message, "started");
        return new LibraryOperationResult(started, ReadString(message, "message"), snapshot);
    }

    private static LibraryGame ParseGame(JsonElement game)
    {
        var networkKind = ParseNetworkKind(ReadString(game, "networkKind"));
        // A fronteira já descarta um valor indevido em jogo geral/offline: apenas
        // LagcheckSupported pode contextualizar uma medição com o id do catálogo.
        var diagnosticGameId = networkKind == GameNetworkKind.Supported
            ? ReadString(game, "diagnosticGameId")
            : null;

        return new LibraryGame(
            RequireString(game, "id"), RequireString(game, "title"), ParsePlatform(ReadString(game, "platform")),
            ReadBoolean(game, "isInstalled"), ReadBoolean(game, "isFavorite"), ReadBoolean(game, "isLaunchable"),
            ReadInt64(game, "lastPlayedEpochMs"), ReadInt64(game, "lastLaunchedEpochMs"), ReadInt64(game, "installedAtEpochMs"),
            ReadLocalPath(game, "coverArtworkPath"), ReadLocalPath(game, "heroArtworkPath"), networkKind,
            diagnosticGameId,
            ReadString(game, "networkLabel") ?? "Conexão geral",
            ReadArray(game, "tags").Select(item => item.GetString()).Where(item => !string.IsNullOrWhiteSpace(item)).Cast<string>().ToArray(),
            ReadString(game, "description"),
            ReadArray(game, "alsoIds").Select(item => item.GetString()).Where(item => !string.IsNullOrWhiteSpace(item)).Cast<string>().ToArray(),
            ParseInfo(game),
            ParseScreenshots(game));
    }

    private static GameScreenshot[] ParseScreenshots(JsonElement game) =>
        ReadArray(game, "screenshots")
            .Where(item => item.ValueKind == JsonValueKind.Object)
            .Select(item => (Path: ReadLocalPath(item, "path"), Item: item))
            .Where(entry => entry.Path is not null)
            .Select(entry => new GameScreenshot(
                entry.Path!, ReadLocalPath(entry.Item, "thumbnailPath"), ReadInt64(entry.Item, "createdEpochMs"),
                (int?)ReadInt64(entry.Item, "width"), (int?)ReadInt64(entry.Item, "height")))
            .ToArray();

    private static GameInfo? ParseInfo(JsonElement game)
    {
        if (!game.TryGetProperty("info", out var info) || info.ValueKind != JsonValueKind.Object) return null;
        string[] Strs(string name) => ReadArray(info, name).Select(item => item.GetString()).Where(item => !string.IsNullOrWhiteSpace(item)).Cast<string>().ToArray();
        var parsed = new GameInfo(ReadString(info, "description"), ReadString(info, "developer"), ReadString(info, "publisher"), ReadString(info, "releaseDate"), Strs("genres"), Strs("modes"));
        return parsed.IsEmpty ? null : parsed;
    }

    private static string? ReadLocalPath(JsonElement source, string name)
    {
        var path = ReadString(source, name);
        if (string.IsNullOrWhiteSpace(path)) return null;
        return Uri.TryCreate(path, UriKind.Absolute, out var uri) && !uri.IsFile ? null : path;
    }

    private static GamePlatform ParsePlatform(string? value) => value?.ToLowerInvariant() switch
    { "steam" => GamePlatform.Steam, "epic_games" => GamePlatform.EpicGames, "xbox" => GamePlatform.Xbox, _ => GamePlatform.Manual };

    private static GameNetworkKind ParseNetworkKind(string? value) => value switch
    { "lagcheckSupported" => GameNetworkKind.Supported, "offlineSingleplayer" => GameNetworkKind.Offline, _ => GameNetworkKind.General };

    private static string RequireString(JsonElement source, string name) => ReadString(source, name) ?? throw new JsonException($"Campo obrigatório ausente: {name}");
    private static string? ReadString(JsonElement source, string name) => source.TryGetProperty(name, out var value) && value.ValueKind == JsonValueKind.String ? value.GetString() : null;
    private static bool ReadBoolean(JsonElement source, string name) => source.TryGetProperty(name, out var value)
        && (value.ValueKind is JsonValueKind.True or JsonValueKind.False) && value.GetBoolean();
    private static long? ReadInt64(JsonElement source, string name) => source.TryGetProperty(name, out var value) && value.TryGetInt64(out var number) ? number : null;
    private static IEnumerable<JsonElement> ReadArray(JsonElement source, string name) => source.TryGetProperty(name, out var value) && value.ValueKind == JsonValueKind.Array ? value.EnumerateArray() : Array.Empty<JsonElement>();
}
