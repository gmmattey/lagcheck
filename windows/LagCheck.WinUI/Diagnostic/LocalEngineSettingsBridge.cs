using LagCheck.WinUI.Settings;

namespace LagCheck.WinUI.Diagnostic;

/// <summary>Settings adapter over the same local engine process used by Library and Check.</summary>
public sealed class LocalEngineSettingsBridge : ISettingsBridge
{
    private readonly DiagnosticEngineClient _engine;

    public LocalEngineSettingsBridge(DiagnosticEngineClient engine) => _engine = engine ?? throw new ArgumentNullException(nameof(engine));

    public async Task<WindowsPreferences> GetAsync(CancellationToken cancellationToken = default) => ToPreferences(await _engine.GetSettingsAsync(cancellationToken).ConfigureAwait(false));

    public async Task<WindowsPreferences> SetAsync(WindowsPreferences preferences, CancellationToken cancellationToken = default)
    {
        var saved = await _engine.SetSettingsAsync(new EngineSettings(
            preferences.ReduceMotion,
            preferences.ArtworkDownloadEnabled,
            preferences.ApproximateLocationEnabled,
            preferences.AnalyticsEnabled,
            preferences.AutomaticUpdates), cancellationToken).ConfigureAwait(false);
        return ToPreferences(saved);
    }

    private static WindowsPreferences ToPreferences(EngineSettings settings) => new(
        settings.ReduceMotion,
        settings.ArtworkDownloadEnabled,
        settings.ApproximateLocationEnabled,
        settings.AnalyticsEnabled,
        settings.AutomaticUpdates);
}
