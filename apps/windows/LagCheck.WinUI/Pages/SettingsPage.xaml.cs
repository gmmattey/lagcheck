using LagCheck.WinUI.Settings;
using LagCheck.WinUI.Diagnostic;
using LagCheck.WinUI.Localization;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace LagCheck.WinUI.Pages;

public sealed partial class SettingsPage : Page
{
    private readonly ISettingsBridge _bridge;
    private WindowsPreferences? _preferences;
    private bool _loading;
    private bool _loadingLanguage;

    public SettingsPage() : this(SettingsPageServices.Bridge) { }

    internal SettingsPage(ISettingsBridge bridge)
    {
        _bridge = bridge;
        InitializeComponent();
        LocalizeUI();
        InitLanguageSelection();
        Loaded += SettingsPage_Loaded;
        LocalizationService.Instance.LanguageChanged += OnLanguageChanged;
        Unloaded += (_, _) => LocalizationService.Instance.LanguageChanged -= OnLanguageChanged;
    }

    private void OnLanguageChanged() => DispatcherQueue.TryEnqueue(LocalizeUI);

    private void InitLanguageSelection()
    {
        _loadingLanguage = true;
        LanguageComboBox.SelectedIndex = LocalizationService.Instance.SelectedLanguage switch
        {
            AppLanguage.System => 0,
            AppLanguage.PtBr => 1,
            AppLanguage.En => 2,
            AppLanguage.Es => 3,
            _ => 0
        };
        _loadingLanguage = false;
    }

    private void LanguageComboBox_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_loadingLanguage || LanguageComboBox.SelectedItem is not ComboBoxItem item || item.Tag is not string tag)
            return;

        var selected = AppLanguageExtensions.FromCode(tag);
        if (LocalizationService.Instance.SelectedLanguage != selected)
        {
            LocalizationService.Instance.SelectedLanguage = selected;
        }
    }

    private void LocalizeUI()
    {
        HeaderEyebrow.Text = Strings.Tr("SISTEMA · CONFIGURAÇÕES");
        HeaderTitle.Text = Strings.Tr("Ajustes do Launcher");
        HeaderSubtitle.Text = Strings.Tr("Controle o comportamento da interface e diagnósticos de rede neste PC.");

        LanguageCardTitle.Text = Strings.Tr("Idioma do aplicativo");
        LanguageTitle.Text = Strings.Tr("Idioma do aplicativo");
        LanguageDesc.Text = Strings.Tr("Escolha o idioma da interface. Por padrão, segue as configurações do Windows.");
        LangItemSystem.Content = Strings.Tr("Sistema (Padrão)");

        VisualCardTitle.Text = Strings.Tr("Interface e Visual");
        ReduceMotionTitle.Text = Strings.Tr("Reduzir movimento");
        ReduceMotionDesc.Text = Strings.Tr("Desativa animações e transições visuais para resposta imediata.");
        ArtworkTitle.Text = Strings.Tr("Baixar imagens dos jogos");
        ArtworkDesc.Text = Strings.Tr("Carrega capas e banners oficiais do cache local dos seus launchers. Desligado, usa miniaturas neutras.");

        NetworkCardTitle.Text = Strings.Tr("Privacidade e Rede");
        LocationTitle.Text = Strings.Tr("Localização aproximada");
        LocationDesc.Text = Strings.Tr("Usa a cidade estimada pelo IP para traçar a rota geográfica. Nunca utiliza GPS.");
        AnalyticsTitle.Text = Strings.Tr("Enviar estatísticas anônimas");
        AnalyticsDesc.Text = Strings.Tr("Apenas veredito e rota da partida. Sem endereço IP, nome de rede ou identificador pessoal.");
        RenewAnalyticsIdButton.Content = Strings.Tr("Gerar novo ID local");

        UpdatesCardTitle.Text = Strings.Tr("Atualizações");
        AutoUpdatesTitle.Text = Strings.Tr("Verificar automaticamente");
        AutoUpdatesDesc.Text = Strings.Tr("Consulta periodicamente por novas versões no canal oficial do GitHub.");
        CheckUpdatesButton.Content = Strings.Tr("Verificar agora");

        AboutCardTitle.Text = Strings.Tr("Sobre o LagCheck");
        AboutDesc.Text = Strings.Tr("LagCheck para Windows — Launcher gamer com pre-flight check de rede integrado. Sem conta obrigatória e sem anúncios.");
        AboutVersion.Text = Strings.Tr("Versão v0.1.0 · WinUI 3 (x64) · Repositório Oficial");
    }

    private async void SettingsPage_Loaded(object sender, RoutedEventArgs e)
    {
        Loaded -= SettingsPage_Loaded;
        try
        {
            Apply(await _bridge.GetAsync());
            ConnectionStatus.Text = Strings.Tr("Ajustes locais conectados.");
        }
        catch
        {
            ConnectionStatus.Text = Strings.Tr("Ajustes indisponíveis: o host local não respondeu.");
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
            ConnectionStatus.Text = Strings.Tr("Ajustes salvos neste PC.");
        }
        catch
        {
            Apply(_preferences);
            ConnectionStatus.Text = Strings.Tr("Não foi possível salvar os ajustes. Nada foi alterado.");
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
        AnalyticsStatus.Text = Strings.Tr("Gerando um novo identificador local…");
        try
        {
            await WinUiEngineComposition.RenewAnalyticsIdAsync();
            AnalyticsStatus.Text = Strings.Tr("Novo identificador gerado neste PC.");
        }
        catch
        {
            AnalyticsStatus.Text = Strings.Tr("Não foi possível gerar um novo identificador agora.");
        }
        finally
        {
            RenewAnalyticsIdButton.IsEnabled = _preferences is not null;
        }
    }

    private async Task RefreshUpdateStatusAsync(bool checkNow)
    {
        CheckUpdatesButton.IsEnabled = false;
        if (checkNow) UpdateStatus.Text = Strings.Tr("Verificando a fonte configurada…");
        try
        {
            var update = checkNow
                ? await WinUiEngineComposition.CheckForUpdatesAsync()
                : await WinUiEngineComposition.GetUpdateStatusAsync();
            if (!update.Configured)
            {
                UpdateStatus.Text = Strings.Tr("Nenhuma fonte de atualização está configurada.");
                return;
            }
            var lastChecked = update.LastCheckedEpochMs is { } epoch
                ? Strings.Format("Última verificação: {0}. ", DateTimeOffset.FromUnixTimeMilliseconds(epoch).ToLocalTime().ToString("g"))
                : Strings.Tr("Ainda não verificado. ");
            UpdateStatus.Text = update.State.ToLowerInvariant() switch
            {
                "available" => $"{lastChecked}{Strings.Format("Atualização {0} encontrada.", update.Version ?? Strings.Tr("disponível"))}",
                "ready" => $"{lastChecked}{Strings.Tr("Atualização pronta no host local.")}",
                "failed" => $"{lastChecked}{Strings.Tr("Não foi possível verificar agora.")}",
                _ => $"{lastChecked}{Strings.Tr("Nenhuma atualização disponível.")}",
            };
            CheckUpdatesButton.IsEnabled = true;
        }
        catch
        {
            UpdateStatus.Text = Strings.Tr("Não foi possível consultar atualizações agora.");
        }
    }
}
