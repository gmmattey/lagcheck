using LagCheck.WinUI.Library;
using LagCheck.WinUI.Settings;

namespace LagCheck.WinUI.Diagnostic;

/// <summary>
/// Process-wide composition root: Library and Check share exactly one host process.
/// The shell calls ConfigureLibraryPageServices during app startup, before creating LibraryPage.
/// </summary>
public static class WinUiEngineComposition
{
    private static readonly object Gate = new();
    private static DiagnosticEngineClient? _client;
    private static LocalEngineLibraryBridge? _library;
    private static LocalEngineSettingsBridge? _settings;

    public static DiagnosticEngineClient Client
    {
        get
        {
            lock (Gate) return _client ??= new DiagnosticEngineClient();
        }
    }

    public static ILibraryBridge LibraryBridge
    {
        get
        {
            lock (Gate) return _library ??= new LocalEngineLibraryBridge(Client);
        }
    }

    public static ISettingsBridge SettingsBridge
    {
        get
        {
            lock (Gate) return _settings ??= new LocalEngineSettingsBridge(Client);
        }
    }

    public static void ConfigureLibraryPageServices() => LibraryPageServices.Configure(LibraryBridge);
    public static void ConfigureSettingsPageServices() => SettingsPageServices.Configure(SettingsBridge);

    public static void ConfigurePageServices()
    {
        ConfigureLibraryPageServices();
        ConfigureSettingsPageServices();
    }

    public static Task<EngineUpdateStatus> GetUpdateStatusAsync(CancellationToken cancellationToken = default) =>
        Client.GetUpdateStatusAsync(cancellationToken);

    public static Task<EngineUpdateStatus> CheckForUpdatesAsync(CancellationToken cancellationToken = default) =>
        Client.CheckForUpdatesAsync(cancellationToken);

    public static Task RenewAnalyticsIdAsync(CancellationToken cancellationToken = default) =>
        Client.RenewAnalyticsIdAsync(cancellationToken);

    public static DiagnosticPage CreateDiagnosticPage(string? gameId = null, string? gameTitle = null) =>
        new(gameId, gameTitle, Client);

    public static async ValueTask ShutdownAsync()
    {
        DiagnosticEngineClient? client;
        lock (Gate)
        {
            client = _client;
            _client = null;
            _library = null;
            _settings = null;
        }
        if (client is not null) await client.DisposeAsync();
    }
}
