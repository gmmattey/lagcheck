using LagCheck.WinUI.Library;

namespace LagCheck.WinUI;

/// <summary>Pages request navigation; the shell owns the actual Frame and diagnostic context.</summary>
public static class ShellNavigation
{
    private static Action<string?, string?>? _openDiagnostic;
    private static Action<NavigationRoute>? _navigate;
    private static Action<LibraryGame, NavigationRoute>? _openGame;

    public static void Configure(Action<string?, string?> openDiagnostic, Action<NavigationRoute>? navigate = null, Action<LibraryGame, NavigationRoute>? openGame = null)
    {
        _openDiagnostic = openDiagnostic ?? throw new ArgumentNullException(nameof(openDiagnostic));
        _navigate = navigate;
        _openGame = openGame;
    }

    public static bool OpenDiagnostic(string? gameId, string? gameTitle) => NavigateToDiagnostic(gameId, gameTitle);

    public static bool NavigateToDiagnostic(string? gameId, string? gameTitle)
    {
        if (_openDiagnostic is null) return false;
        _openDiagnostic(gameId, gameTitle);
        return true;
    }

    public static bool Navigate(NavigationRoute route)
    {
        if (_navigate is null) return false;
        _navigate(route);
        return true;
    }

    /// <summary>Abre a tela de Detalhes; <paramref name="backRoute"/> define o destino do botão Voltar e o item ativo da sidebar.</summary>
    public static bool OpenGameDetails(LibraryGame game, NavigationRoute backRoute)
    {
        if (_openGame is null) return false;
        _openGame(game, backRoute);
        return true;
    }
}
