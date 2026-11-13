using System.Text.Json;
using LagCheck.WinUI.Library;

namespace LagCheck.WinUI.Diagnostic;

/// <summary>
/// Adapts the one local Kotlin host to the Library UI. It does not scan launchers or
/// persist favorites itself; both continue to belong to the Kotlin library module.
/// </summary>
public sealed class LocalEngineLibraryBridge : ILibraryBridge
{
    private readonly DiagnosticEngineClient _engine;

    public LocalEngineLibraryBridge(DiagnosticEngineClient engine) => _engine = engine ?? throw new ArgumentNullException(nameof(engine));

    public Task<LibrarySnapshot> GetSnapshotAsync(CancellationToken cancellationToken = default) => _engine.GetLibrarySnapshotAsync(cancellationToken);
    public Task<LibraryOperationResult> RescanAsync(CancellationToken cancellationToken = default) => _engine.RescanLibraryAsync(cancellationToken);
    public Task<LibraryOperationResult> SetFavoriteAsync(string gameId, bool favorite, CancellationToken cancellationToken = default) => _engine.SetLibraryFavoriteAsync(gameId, favorite, cancellationToken);
    public Task<LibraryOperationResult> SelectAsync(string gameId, CancellationToken cancellationToken = default) => _engine.SelectLibraryGameAsync(gameId, cancellationToken);
    public Task<LibraryOperationResult> LaunchAsync(string gameId, CancellationToken cancellationToken = default) => _engine.LaunchLibraryGameAsync(gameId, cancellationToken);

    public Task<LibraryOperationResult> RefreshArtworkAsync(string gameId, CancellationToken cancellationToken = default) => _engine.RefreshLibraryArtworkAsync(gameId, cancellationToken);
    public Task<LibraryOperationResult> ResolveArtworkAsync(IReadOnlyList<string> gameIds, CancellationToken cancellationToken = default) => _engine.ResolveLibraryArtworkAsync(gameIds, cancellationToken);
}

internal static class EngineLibraryParser
{
    internal static LibrarySnapshot ReadSnapshot(EngineWireMessage message)
    {
        if (message.Snapshot is not { ValueKind: JsonValueKind.Object } snapshot)
        {
            throw new DiagnosticEngineException("INVALID_LIBRARY_RESPONSE", "O motor local retornou uma biblioteca inválida.");
        }

        var games = snapshot.TryGetProperty("games", out var items) && items.ValueKind == JsonValueKind.Array
            ? items.EnumerateArray().Where(item => item.ValueKind == JsonValueKind.Object).Select(ReadGame).ToArray()
            : Array.Empty<LibraryGame>();
        return new LibrarySnapshot(
            Bool(snapshot, "isScanning"),
            Bool(snapshot, "hasScanned"),
            String(snapshot, "heroGameId"),
            String(snapshot, "selectedGameId"),
            games);
    }

    private static LibraryGame ReadGame(JsonElement game) => new(
        Required(game, "id"),
        Required(game, "title"),
        Platform(String(game, "platform")),
        Bool(game, "isInstalled"),
        Bool(game, "isFavorite"),
        Bool(game, "isLaunchable"),
        Long(game, "lastPlayedEpochMs"),
        Long(game, "lastLaunchedEpochMs"),
        Long(game, "installedAtEpochMs"),
        String(game, "coverArtworkPath"),
        String(game, "heroArtworkPath"),
        NetworkKind(String(game, "networkKind")),
        NetworkKind(String(game, "networkKind")) == GameNetworkKind.Supported ? String(game, "diagnosticGameId") : null,
        String(game, "networkLabel") ?? "Conexão geral",
        Strings(game, "tags"),
        String(game, "description"),
        Strings(game, "alsoIds"),
        ReadInfo(game));

    private static GameInfo? ReadInfo(JsonElement game)
    {
        if (!game.TryGetProperty("info", out var info) || info.ValueKind != JsonValueKind.Object) return null;
        var parsed = new GameInfo(String(info, "description"), String(info, "developer"), String(info, "publisher"), String(info, "releaseDate"), Strings(info, "genres"), Strings(info, "modes"));
        return parsed.IsEmpty ? null : parsed;
    }

    private static GamePlatform Platform(string? value) => value?.ToLowerInvariant() switch
    {
        "steam" => GamePlatform.Steam,
        "epic" or "epicgames" => GamePlatform.EpicGames,
        "xbox" => GamePlatform.Xbox,
        _ => GamePlatform.Manual,
    };

    private static GameNetworkKind NetworkKind(string? value) => value switch
    {
        "lagcheckSupported" => GameNetworkKind.Supported,
        "offlineSingleplayer" => GameNetworkKind.Offline,
        _ => GameNetworkKind.General,
    };

    private static string Required(JsonElement value, string name) => String(value, name) ?? throw new DiagnosticEngineException("INVALID_LIBRARY_RESPONSE", "O motor local retornou um jogo sem " + name + ".");
    private static string? String(JsonElement value, string name) => value.TryGetProperty(name, out var item) && item.ValueKind == JsonValueKind.String ? item.GetString() : null;
    private static bool Bool(JsonElement value, string name) => value.TryGetProperty(name, out var item)
        && (item.ValueKind is JsonValueKind.True or JsonValueKind.False) && item.GetBoolean();
    private static long? Long(JsonElement value, string name) => value.TryGetProperty(name, out var item) && item.TryGetInt64(out var number) ? number : null;
    private static IReadOnlyList<string> Strings(JsonElement value, string name) => value.TryGetProperty(name, out var item) && item.ValueKind == JsonValueKind.Array
        ? item.EnumerateArray().Where(entry => entry.ValueKind == JsonValueKind.String).Select(entry => entry.GetString()!).ToArray()
        : Array.Empty<string>();
}
