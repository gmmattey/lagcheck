using Microsoft.UI.Xaml;
using LagCheck.WinUI.Catalog;
using LagCheck.WinUI.Diagnostic;
using LagCheck.WinUI.History;
using LagCheck.WinUI.Library;

namespace LagCheck.WinUI;

public partial class App : Application
{
    private Window? _window;
    private bool _shuttingDown;
    public App() => InitializeComponent();
    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        WinUiEngineComposition.ConfigurePageServices();
        LibraryPageServices.ConfigureDiagnosticNavigator(new ShellLibraryDiagnosticNavigator());
        CatalogPageServices.Configure(new LocalEngineCatalogBridge(WinUiEngineComposition.Client));
        SessionHistoryServices.Store.Initialize(WinUiEngineComposition.Client);
        _ = SessionHistoryServices.Store.TryRefreshAsync(WinUiEngineComposition.Client);
        _window = new MainWindow();
        _window.Closed += (_, _) => _ = ShutdownEngineAsync();
        _window.Activate();
    }

    private async Task ShutdownEngineAsync()
    {
        if (_shuttingDown) return;
        _shuttingDown = true;
        try { await WinUiEngineComposition.ShutdownAsync(); }
        catch { /* Window shutdown must never be held by a host cleanup failure. */ }
    }
}
