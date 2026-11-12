namespace LagCheck.WinUI;

/// <summary>Pages request navigation; the shell owns the actual Frame and diagnostic context.</summary>
public static class ShellNavigation
{
    private static Action<string?, string?>? _openDiagnostic;
    public static void Configure(Action<string?, string?> openDiagnostic) => _openDiagnostic = openDiagnostic ?? throw new ArgumentNullException(nameof(openDiagnostic));
    public static bool OpenDiagnostic(string? gameId, string? gameTitle)
    {
        if (_openDiagnostic is null) return false;
        _openDiagnostic(gameId, gameTitle);
        return true;
    }
}
