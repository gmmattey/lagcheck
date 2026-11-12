using LagCheck.WinUI.Library;

namespace LagCheck.WinUI;

/// <summary>Explicit manual navigation only; the Diagnostic page still waits for its own start action.</summary>
public sealed class ShellLibraryDiagnosticNavigator : ILibraryDiagnosticNavigator
{
    public bool NavigateToManualDiagnostic(ManualDiagnosticRequest request)
    {
        if (!request.NetworkKind.Equals(GameNetworkKind.Supported) && !request.NetworkKind.Equals(GameNetworkKind.General)) return false;
        // General deliberately sends null to request the generic measurement. A
        // homologated game without its canonical catalog id must not degrade to it.
        if (request.NetworkKind == GameNetworkKind.Supported && string.IsNullOrWhiteSpace(request.DiagnosticGameId)) return false;
        return ShellNavigation.OpenDiagnostic(request.DiagnosticGameId, request.GameTitle);
    }
}
