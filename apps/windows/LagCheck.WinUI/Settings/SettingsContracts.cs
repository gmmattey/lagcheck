namespace LagCheck.WinUI.Settings;

/// <summary>Owned by the Kotlin desktop preferences API; the WinUI layer only renders and updates it.</summary>
public sealed record WindowsPreferences(
    bool ReduceMotion,
    bool ArtworkDownloadEnabled,
    bool ApproximateLocationEnabled,
    bool AnalyticsEnabled,
    bool AutomaticUpdates);

public interface ISettingsBridge
{
    Task<WindowsPreferences> GetAsync(CancellationToken cancellationToken = default);
    Task<WindowsPreferences> SetAsync(WindowsPreferences preferences, CancellationToken cancellationToken = default);
}

public sealed class UnavailableSettingsBridge : ISettingsBridge
{
    public static UnavailableSettingsBridge Instance { get; } = new();
    public Task<WindowsPreferences> GetAsync(CancellationToken cancellationToken = default) =>
        Task.FromException<WindowsPreferences>(new InvalidOperationException("Os ajustes ainda não estão conectados ao host local."));
    public Task<WindowsPreferences> SetAsync(WindowsPreferences preferences, CancellationToken cancellationToken = default) =>
        Task.FromException<WindowsPreferences>(new InvalidOperationException("Os ajustes ainda não estão conectados ao host local."));
}

public static class SettingsPageServices
{
    private static ISettingsBridge _bridge = UnavailableSettingsBridge.Instance;
    public static ISettingsBridge Bridge => _bridge;
    public static void Configure(ISettingsBridge bridge) => _bridge = bridge ?? throw new ArgumentNullException(nameof(bridge));
}
