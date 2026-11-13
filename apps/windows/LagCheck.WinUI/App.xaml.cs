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
    public App()
    {
        InitializeComponent();
        // Registro de falhas: se o app fechar sozinho, o motivo fica em %LOCALAPPDATA%\LagCheck\crash.log
        UnhandledException += (_, e) => LogCrash("XAML", e.Exception);
        AppDomain.CurrentDomain.UnhandledException += (_, e) => LogCrash("AppDomain", e.ExceptionObject as Exception);
        TaskScheduler.UnobservedTaskException += (_, e) => LogCrash("Task", e.Exception);
#if DEBUG
        // Diagnóstico de fechamento súbito: toda exceção lançada (mesmo as tratadas) vai para firstchance.log.
        AppDomain.CurrentDomain.FirstChanceException += (_, e) => LogFirstChance(e.Exception);
#endif
    }

    private static void LogFirstChance(Exception error)
    {
        try
        {
            var dir = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "LagCheck");
            System.IO.Directory.CreateDirectory(dir);
            var file = System.IO.Path.Combine(dir, "firstchance.log");
            if (System.IO.File.Exists(file) && new System.IO.FileInfo(file).Length > 400_000) System.IO.File.Delete(file);
            var text = error.ToString();
            if (text.Length > 1500) text = text[..1500];
            System.IO.File.AppendAllText(file, $"[{DateTime.Now:HH:mm:ss.fff}] {text}\n--\n");
        }
        catch { }
    }

    private static void LogCrash(string source, Exception? error)
    {
        try
        {
            var dir = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "LagCheck");
            System.IO.Directory.CreateDirectory(dir);
            System.IO.File.AppendAllText(System.IO.Path.Combine(dir, "crash.log"), $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {source}: {error}\n\n");
        }
        catch { /* o log nunca pode causar outra falha */ }
    }
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
