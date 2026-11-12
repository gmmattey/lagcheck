using LagCheck.WinUI.Settings;
using LagCheck.WinUI.Diagnostic;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace LagCheck.WinUI.Pages;

public sealed partial class SettingsPage : Page
{
    private readonly ISettingsBridge _bridge;
    private WindowsPreferences? _preferences;
    private bool _loading;

    public SettingsPage() : this(SettingsPageServices.Bridge) { }

    internal SettingsPage(ISettingsBridge bridge)
    {
        _bridge = bridge;
        InitializeComponent();
        Loaded += SettingsPage_Loaded;
    }

    private async void SettingsPage_Loaded(object sender, RoutedEventArgs e)
    {
        Loaded -= SettingsPage_Loaded;
        try
        {
            Apply(await _bridge.GetAsync());
            ConnectionStatus.Text = "Ajustes locais conectados.";
        }
        catch
        {
            ConnectionStatus.Text = "Ajustes indisponíveis: o host local não respondeu.";
        }
        await RefreshUpdateStatusAsync(checkNow: false);
    }

    private async void Preference_Toggled(object sender, RoutedEventArgs e)
    {
        if (_loading || _preferences is null || sender is not ToggleSwitch toggle || toggle.Tag is not string key)
            return;

        SetEnabled(false);
        try
        {
            var current = _preferences;
            var next = key switch
            {
                "reduceMotion" => current with { ReduceMotion = toggle.IsOn },
                "artworkDownload" => current with { ArtworkDownloadEnabled = toggle.IsOn },
                "approximateLocation" => current with { ApproximateLocationEnabled = toggle.IsOn },
                "analytics" => current with { AnalyticsEnabled = toggle.IsOn },
                "automaticUpdates" => current with { AutomaticUpdates = toggle.IsOn },
                _ => current,
            };
            Apply(await _bridge.SetAsync(next));
            ConnectionStatus.Text = "Ajustes salvos neste PC.";
        }
        catch
        {
            Apply(_preferences);
            ConnectionStatus.Text = "Não foi possível salvar os ajustes. Nada foi alterado.";
        }
    }

    private void Apply(WindowsPreferences preferences)
    {
        _loading = true;
        _preferences = preferences;
        ReduceMotionSwitch.IsOn = preferences.ReduceMotion;
        ArtworkSwitch.IsOn = preferences.ArtworkDownloadEnabled;
        ApproximateLocationSwitch.IsOn = preferences.ApproximateLocationEnabled;
        AnalyticsSwitch.IsOn = preferences.AnalyticsEnabled;
        AutomaticUpdatesSwitch.IsOn = preferences.AutomaticUpdates;
        _loading = false;
        SetEnabled(true);
    }

    private void SetEnabled(bool enabled)
    {
        ReduceMotionSwitch.IsEnabled = enabled;
        ArtworkSwitch.IsEnabled = enabled;
        ApproximateLocationSwitch.IsEnabled = enabled;
        AnalyticsSwitch.IsEnabled = enabled;
        AutomaticUpdatesSwitch.IsEnabled = enabled;
        RenewAnalyticsIdButton.IsEnabled = enabled;
    }

    private async void CheckUpdates_Click(object sender, RoutedEventArgs e) => await RefreshUpdateStatusAsync(checkNow: true);

    private async void RenewAnalyticsId_Click(object sender, RoutedEventArgs e)
    {
        RenewAnalyticsIdButton.IsEnabled = false;
        AnalyticsStatus.Text = "Gerando um novo identificador local…";
        try
        {
            await WinUiEngineComposition.RenewAnalyticsIdAsync();
            AnalyticsStatus.Text = "Novo identificador gerado neste PC.";
        }
        catch
        {
            AnalyticsStatus.Text = "Não foi possível gerar um novo identificador agora.";
        }
        finally
        {
            RenewAnalyticsIdButton.IsEnabled = _preferences is not null;
        }
    }

    private async Task RefreshUpdateStatusAsync(bool checkNow)
    {
        CheckUpdatesButton.IsEnabled = false;
        if (checkNow) UpdateStatus.Text = "Verificando a fonte configurada…";
        try
        {
            var update = checkNow
                ? await WinUiEngineComposition.CheckForUpdatesAsync()
                : await WinUiEngineComposition.GetUpdateStatusAsync();
            if (!update.Configured)
            {
                UpdateStatus.Text = "Nenhuma fonte de atualização está configurada.";
                return;
            }
            var lastChecked = update.LastCheckedEpochMs is { } epoch
                ? $"Última verificação: {DateTimeOffset.FromUnixTimeMilliseconds(epoch).ToLocalTime():g}. "
                : "Ainda não verificado. ";
            UpdateStatus.Text = update.State.ToLowerInvariant() switch
            {
                "available" => $"{lastChecked}Atualização {update.Version ?? "disponível"} encontrada.",
                "ready" => $"{lastChecked}Atualização pronta no host local.",
                "failed" => $"{lastChecked}Não foi possível verificar agora.",
                _ => $"{lastChecked}Nenhuma atualização disponível.",
            };
            CheckUpdatesButton.IsEnabled = true;
        }
        catch
        {
            UpdateStatus.Text = "Não foi possível consultar atualizações agora.";
        }
    }
}
