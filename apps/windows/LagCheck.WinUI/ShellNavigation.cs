namespace LagCheck.WinUI;

/// <summary>Pages request navigation; the shell owns the actual Frame and diagnostic context.</summary>
public static class ShellNavigation
{
    private static Action<string?, string?>? _openDiagnostic;
    private static Action<NavigationRoute>? _navigate;

    public static void Configure(Action<string?, string?> openDiagnostic, Action<NavigationRoute>? navigate = null)
    {
        _openDiagnostic = openDiagnostic ?? throw new ArgumentNullException(nameof(openDiagnostic));
        _navigate = navigate;
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
}
