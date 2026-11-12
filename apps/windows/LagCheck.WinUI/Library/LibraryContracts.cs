using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using LagCheck.WinUI.Localization;

namespace LagCheck.WinUI.Library;

/// <summary>
/// Projeção da biblioteca emitida pelo host Kotlin. Esta camada não lê launchers,
/// não grava LibraryStore e não calcula prioridade do Hero: isso preserva os dados
/// reais e as regras já existentes no núcleo compartilhado.
/// </summary>
public sealed record LibraryGame(
    string Id,
    string Title,
    GamePlatform Platform,
    bool IsInstalled,
    bool IsFavorite,
    bool IsLaunchable,
    long? LastPlayedEpochMs,
    long? LastLaunchedEpochMs,
    long? InstalledAtEpochMs,
    string? CoverArtworkPath,
    string? HeroArtworkPath,
    GameNetworkKind NetworkKind,
    string? DiagnosticGameId,
    string NetworkLabel,
    IReadOnlyList<string> Tags,
    string? Description,
    IReadOnlyList<string> AlsoIds)
{
    public long? RecentActivityEpochMs
    {
        get
        {
            var values = new[] { LastLaunchedEpochMs, LastPlayedEpochMs }
                .Where(value => value.HasValue)
                .Select(value => value!.Value)
                .ToArray();
            return values.Length == 0 ? null : values.Max();
        }
    }

    public string AvailabilityLabel => IsInstalled ? Platform.DisplayName() : Strings.Tr("NÃO INSTALADO");
    public string PlatformLabel => Platform.DisplayName();
    public string FavoriteActionLabel => IsFavorite ? Strings.Tr("REMOVER FAVORITO") : Strings.Tr("FAVORITAR");
    /// <summary>
    /// Somente abre o Check manual; nunca inicia uma medição ao selecionar o jogo.
    /// Um jogo homologado precisa trazer o id canônico do catálogo do LagCheck. O id
    /// da biblioteca (Steam/Epic) não é um identificador válido para o motor.
    /// </summary>
    public bool CanTestConnection => IsInstalled
        && NetworkKind != GameNetworkKind.Offline
        && (NetworkKind != GameNetworkKind.Supported || !string.IsNullOrWhiteSpace(DiagnosticGameId));
    public string DiagnosticLabel => NetworkKind switch
    {
        GameNetworkKind.Supported when string.IsNullOrWhiteSpace(DiagnosticGameId) => Strings.Tr("Sem diagnóstico"),
        GameNetworkKind.Supported => Strings.Tr("Conexão suportada"),
        GameNetworkKind.Offline => Strings.Tr("Offline / Sem medição"),
        _ => Strings.Tr("Conexão geral"),
    };
}

public enum GamePlatform
{
    Steam,
    EpicGames,
    Xbox,
    Manual,
}

public static class GamePlatformExtensions
{
    public static string DisplayName(this GamePlatform platform) => platform switch
    {
        GamePlatform.Steam => "STEAM",
        GamePlatform.EpicGames => "EPIC GAMES",
        GamePlatform.Xbox => "XBOX / PC",
        _ => "PC LOCAL",
    };
}

public enum GameNetworkKind
{
    Supported,
    General,
    Offline,
}

public enum LibraryFilter
{
    All,
    Installed,
    Recent,
    Favorites,
    Steam,
    Epic,
    Xbox,
    Manual,
}

public enum LibrarySort
{
    Name,
    Recent,
    Platform,
    Favorites,
}

public sealed record LibrarySnapshot(
    bool IsScanning,
    bool HasScanned,
    string? HeroGameId,
    string? SelectedGameId,
    IReadOnlyList<LibraryGame> Games,
    string? Notice = null);

public sealed record LibraryOperationResult(bool Succeeded, string? Message, LibrarySnapshot? Snapshot = null)
{
    public static LibraryOperationResult Failure(string message) => new(false, message);
}

/// <summary>
/// Fronteira local para o host Kotlin. O host é o único dono do scan Steam/Epic,
/// LibraryStore, reconciliação, launch e cache de capas. Caminhos de imagem são
/// locais; a interface nunca baixa uma URL por conta própria.
/// </summary>
public interface ILibraryBridge
{
    Task<LibrarySnapshot> GetSnapshotAsync(CancellationToken cancellationToken = default);
    Task<LibraryOperationResult> RescanAsync(CancellationToken cancellationToken = default);
    Task<LibraryOperationResult> SetFavoriteAsync(string gameId, bool favorite, CancellationToken cancellationToken = default);
    Task<LibraryOperationResult> SelectAsync(string gameId, CancellationToken cancellationToken = default);
    Task<LibraryOperationResult> LaunchAsync(string gameId, CancellationToken cancellationToken = default);
    Task<LibraryOperationResult> RefreshArtworkAsync(string gameId, CancellationToken cancellationToken = default);
    /// <summary>Resolve somente ids que a tela já tornou visíveis; máximo de oito por chamada.</summary>
    Task<LibraryOperationResult> ResolveArtworkAsync(IReadOnlyList<string> gameIds, CancellationToken cancellationToken = default);
}

/// <summary>
/// Navegação de apresentação, separada do motor. O destino abre o Check já
/// contextualizado, mas não pode iniciar sondas, score ou telemetria por conta própria.
/// </summary>
/// <param name="DiagnosticGameId">
/// Id canônico do catálogo LagCheck somente para jogos homologados; nulo abre a
/// medição geral. Nunca recebe o id de Steam, Epic ou da biblioteca local.
/// </param>
public sealed record ManualDiagnosticRequest(string? DiagnosticGameId, string GameTitle, GameNetworkKind NetworkKind);

public interface ILibraryDiagnosticNavigator
{
    bool NavigateToManualDiagnostic(ManualDiagnosticRequest request);
}

public sealed class UnavailableLibraryDiagnosticNavigator : ILibraryDiagnosticNavigator
{
    public static UnavailableLibraryDiagnosticNavigator Instance { get; } = new();
    public bool NavigateToManualDiagnostic(ManualDiagnosticRequest request) => false;
}

/// <summary>Evita uma tela enganosa enquanto o shell ainda não conectou o host.</summary>
public sealed class UnavailableLibraryBridge : ILibraryBridge
{
    public static UnavailableLibraryBridge Instance { get; } = new();
    private const string Message = "A biblioteca ainda não está conectada ao motor local.";
    private static readonly LibrarySnapshot Empty = new(false, false, null, null, Array.Empty<LibraryGame>(), Message);

    public Task<LibrarySnapshot> GetSnapshotAsync(CancellationToken cancellationToken = default) => Task.FromResult(Empty);
    public Task<LibraryOperationResult> RescanAsync(CancellationToken cancellationToken = default) => Task.FromResult(LibraryOperationResult.Failure(Message));
    public Task<LibraryOperationResult> SetFavoriteAsync(string gameId, bool favorite, CancellationToken cancellationToken = default) => Task.FromResult(LibraryOperationResult.Failure(Message));
    public Task<LibraryOperationResult> SelectAsync(string gameId, CancellationToken cancellationToken = default) => Task.FromResult(LibraryOperationResult.Failure(Message));
    public Task<LibraryOperationResult> LaunchAsync(string gameId, CancellationToken cancellationToken = default) => Task.FromResult(LibraryOperationResult.Failure(Message));
    public Task<LibraryOperationResult> RefreshArtworkAsync(string gameId, CancellationToken cancellationToken = default) => Task.FromResult(LibraryOperationResult.Failure(Message));
    public Task<LibraryOperationResult> ResolveArtworkAsync(IReadOnlyList<string> gameIds, CancellationToken cancellationToken = default) => Task.FromResult(LibraryOperationResult.Failure(Message));
}

/// <summary>
/// Ponte de composição mínima para o shell WinUI. O shell configura uma vez o
/// adaptador NDJSON; o construtor sem parâmetros de LibraryPage continua utilizável
/// pela navegação padrão de Frame.
/// </summary>
public static class LibraryPageServices
{
    private static ILibraryBridge _bridge = UnavailableLibraryBridge.Instance;
    private static ILibraryDiagnosticNavigator _diagnosticNavigator = UnavailableLibraryDiagnosticNavigator.Instance;

    public static ILibraryBridge Bridge => _bridge;
    public static ILibraryDiagnosticNavigator DiagnosticNavigator => _diagnosticNavigator;

    public static void Configure(ILibraryBridge bridge) => _bridge = bridge ?? throw new ArgumentNullException(nameof(bridge));
    public static void ConfigureDiagnosticNavigator(ILibraryDiagnosticNavigator navigator) => _diagnosticNavigator = navigator ?? throw new ArgumentNullException(nameof(navigator));
}
