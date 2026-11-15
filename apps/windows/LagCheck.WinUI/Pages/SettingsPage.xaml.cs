using System;
using System.Threading.Tasks;
using LagCheck.WinUI.Controls;
using LagCheck.WinUI.Diagnostic;
using LagCheck.WinUI.Localization;
using LagCheck.WinUI.Settings;
using LagCheck.WinUI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Animation;
using Windows.System;

namespace LagCheck.WinUI.Pages;

public sealed partial class SettingsPage : Page
{
    private readonly ISettingsBridge _bridge;
    private WindowsPreferences? _preferences;
    private bool _loading;
    private bool _loadingLanguage;
    private bool _loadingFullScreen;

    private static int _lastSelectedCategoryIndex;
    private int _categoryTicket;

    private SettingsCategoryButton[] _categoryButtons = [];
    private StackPanel[] _categoryPanels = [];

    public SettingsPage() : this(SettingsPageServices.Bridge) { }

    internal SettingsPage(ISettingsBridge bridge)
    {
        _bridge = bridge;
        InitializeComponent();
        InitializeComponentsArray();
        LocalizeUI();
        InitLanguageSelection();
        Loaded += SettingsPage_Loaded;
        Unloaded += SettingsPage_Unloaded;
        LocalizationService.Instance.LanguageChanged += OnLanguageChanged;
    }

    private void InitializeComponentsArray()
    {
        _categoryButtons = [CatScreen, CatAppearance, CatGames, CatPrivacy, CatUpdates, CatAbout];
        _categoryPanels = [PanelScreen, PanelAppearance, PanelGames, PanelPrivacy, PanelUpdates, PanelAbout];

        foreach (var button in _categoryButtons)
        {
            button.MoveFocusToContentRequested += FocusFirstRowInCurrentCategory;
        }

        foreach (var panel in _categoryPanels)
        {
            foreach (var child in panel.Children)
            {
                if (child is SettingsRow row)
                {
                    row.MoveFocusToCategoryRequested += FocusCurrentCategory;
                }
            }
        }

        SelectCategory(_lastSelectedCategoryIndex, animate: false);
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
        HeaderTitle.Text = Strings.Tr("Ajustes").ToUpperInvariant();

        // Categorias
        CatScreen.Title = Strings.Tr("Tela e janela");
        CatAppearance.Title = Strings.Tr("Aparência e idioma");
        CatGames.Title = Strings.Tr("Jogos e imagens");
        CatPrivacy.Title = Strings.Tr("Privacidade e rede");
        CatUpdates.Title = Strings.Tr("Atualizações");
        CatAbout.Title = Strings.Tr("Sobre o LagCheck");

        // Tela e janela
        RowFullScreenMode.Title = Strings.Tr("Modo tela cheia");
        RowFullScreenMode.Description = Strings.Tr("Alterna entre janela e tela cheia. Atalho: F11.");
        RowStartFullScreen.Title = Strings.Tr("Abrir em tela cheia");
        RowStartFullScreen.Description = Strings.Tr("Inicia o LagCheck já em tela cheia.");

        // Aparência e idioma
        RowReduceMotion.Title = Strings.Tr("Reduzir movimento");
        RowReduceMotion.Description = Strings.Tr("Remove transições e a rotação automática de arte.");
        ToolTipService.SetToolTip(RowReduceMotion, Strings.Tr("Desativa animações e transições visuais para resposta imediata."));

        RowLanguage.Title = Strings.Tr("Idioma do aplicativo");
        RowLanguage.Description = Strings.Tr("Escolha o idioma da interface. Por padrão, segue as configurações do Windows.");
        LangItemSystem.Content = Strings.Tr("Sistema (Padrão)");

        // Jogos e imagens
        RowArtwork.Title = Strings.Tr("Baixar imagens dos jogos");
        RowArtwork.Description = Strings.Tr("Baixa capas e banners das lojas. Desligado, só usa o que já existe no PC.");
        ToolTipService.SetToolTip(RowArtwork, Strings.Tr("Carrega capas e banners oficiais do cache local dos seus launchers. Desligado, usa miniaturas neutras."));

        // Privacidade e rede
        RowApproximateLocation.Title = Strings.Tr("Localização aproximada");
        RowApproximateLocation.Description = Strings.Tr("Usada só para centralizar o mapa da rota. Fica neste PC.");
        ToolTipService.SetToolTip(RowApproximateLocation, Strings.Tr("Usa a cidade estimada pelo IP para traçar a rota geográfica. Nunca utiliza GPS."));

        RowAnalytics.Title = Strings.Tr("Enviar estatísticas anônimas");
        RowAnalytics.Description = Strings.Tr("Dados anônimos de uso. Você pode desligar quando quiser.");
        ToolTipService.SetToolTip(RowAnalytics, Strings.Tr("Apenas veredito e rota da partida. Sem endereço IP, nome de rede ou identificador pessoal."));

        RowRenewAnalyticsId.Title = Strings.Tr("Gerar novo ID local");
        RenewAnalyticsIdButton.Content = Strings.Tr("Gerar novo ID local");

        // Atualizações
        RowAutoUpdates.Title = Strings.Tr("Verificar automaticamente");
        RowAutoUpdates.Description = Strings.Tr("Procura novas versões ao abrir o app.");
        ToolTipService.SetToolTip(RowAutoUpdates, Strings.Tr("Consulta periodicamente por novas versões no canal oficial do GitHub."));

        RowCheckUpdates.Title = Strings.Tr("Verificar agora");
        CheckUpdatesButton.Content = Strings.Tr("Verificar agora");

        // Sobre o LagCheck
        RowAbout.Title = Strings.Tr("Sobre o LagCheck");
        RowAbout.Description = Strings.Tr("LagCheck para Windows — Launcher gamer com pre-flight check de rede integrado. Sem conta obrigatória e sem anúncios.");
        RowAbout.ValueText = Strings.Tr("Versão v0.1.0 · WinUI 3 (x64) · Repositório Oficial");
    }

    private void SettingsPage_KeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (e.Key != VirtualKey.Escape) return;
        e.Handled = true;
        ShellChrome.Shell?.NavigateBackFromOverlay();
    }

    private async void SettingsPage_Loaded(object sender, RoutedEventArgs e)
    {
        WindowMode.FullScreenChanged += OnFullScreenChanged;
        UpdateFullScreenToggle();
        StartFullScreenSwitch.IsOn = WindowMode.StartFullScreen;

        // Animação de entrada escalonada da página de Ajustes
        Choreo.FadeSlideIn(HeaderTitle, dy: 14, delayMs: 0);
        for (int i = 0; i < _categoryButtons.Length; i++)
        {
            var btnDelay = Math.Min(i, 6) * 30;
            Choreo.FadeSlideIn(_categoryButtons[i], dy: 10, delayMs: 30 + btnDelay);
        }

        AnimateActivePanelRows();

        try
        {
            Apply(await _bridge.GetAsync());
        }
        catch
        {
            RowCheckUpdates.Description = Strings.Tr("Ajustes indisponíveis: o host local não respondeu.");
        }

        await RefreshUpdateStatusAsync(checkNow: false);
    }

    private void AnimateActivePanelRows()
    {
        if (_lastSelectedCategoryIndex < 0 || _lastSelectedCategoryIndex >= _categoryPanels.Length) return;
        var panel = _categoryPanels[_lastSelectedCategoryIndex];
        int rowIndex = 0;
        foreach (var child in panel.Children)
        {
            if (child is SettingsRow row)
            {
                var delay = Math.Min(rowIndex++, 6) * 35;
                Choreo.FadeSlideIn(row, dy: 10, delayMs: 70 + delay);
            }
        }
    }

    private void SettingsPage_Unloaded(object sender, RoutedEventArgs e)
    {
        WindowMode.FullScreenChanged -= OnFullScreenChanged;
        LocalizationService.Instance.LanguageChanged -= OnLanguageChanged;
    }

    private void OnFullScreenChanged() => DispatcherQueue.TryEnqueue(UpdateFullScreenToggle);

    private void UpdateFullScreenToggle()
    {
        _loadingFullScreen = true;
        FullScreenModeSwitch.IsOn = WindowMode.IsFullScreen;
        _loadingFullScreen = false;
    }

    private void FullScreenModeSwitch_Toggled(object sender, RoutedEventArgs e)
    {
        if (_loadingFullScreen) return;
        WindowMode.SetFullScreen(FullScreenModeSwitch.IsOn);
    }

    private void StartFullScreenSwitch_Toggled(object sender, RoutedEventArgs e)
    {
        if (_loadingFullScreen) return;
        WindowMode.StartFullScreen = StartFullScreenSwitch.IsOn;
    }

    private void Category_Selected(object sender, RoutedEventArgs e)
    {
        if (sender is not SettingsCategoryButton button) return;
        var index = Array.IndexOf(_categoryButtons, button);
        if (index >= 0 && index != _lastSelectedCategoryIndex)
        {
            SelectCategory(index, animate: true);
        }
    }

    private void SelectCategory(int index, bool animate)
    {
        if (index < 0 || index >= _categoryButtons.Length) return;

        var prevIndex = _lastSelectedCategoryIndex;
        _lastSelectedCategoryIndex = index;

        for (int i = 0; i < _categoryButtons.Length; i++)
        {
            _categoryButtons[i].IsSelected = (i == index);
        }

        var oldPanel = (prevIndex >= 0 && prevIndex < _categoryPanels.Length && prevIndex != index) ? _categoryPanels[prevIndex] : null;
        var newPanel = _categoryPanels[index];

        if (animate && oldPanel is not null && oldPanel.Visibility == Visibility.Visible)
        {
            var ticket = ++_categoryTicket;
            Choreo.FadeOut(oldPanel, ms: Choreo.Exit, done: () =>
            {
                if (ticket != _categoryTicket) return;
                oldPanel.Visibility = Visibility.Collapsed;
                for (int i = 0; i < _categoryPanels.Length; i++)
                {
                    if (i != index) _categoryPanels[i].Visibility = Visibility.Collapsed;
                }
                ApplyAdaptiveSpacing(newPanel);
                newPanel.Visibility = Visibility.Visible;
                Choreo.FadeSlideIn(newPanel, ms: Choreo.Base, dy: 10);
            });
        }
        else
        {
            for (int i = 0; i < _categoryPanels.Length; i++)
            {
                _categoryPanels[i].Visibility = (i == index) ? Visibility.Visible : Visibility.Collapsed;
            }
            ApplyAdaptiveSpacing(newPanel);
            if (animate)
            {
                Choreo.FadeSlideIn(newPanel, ms: Choreo.Base, dy: 10);
            }
        }
    }

    private void ApplyAdaptiveSpacing(StackPanel? activePanel = null)
    {
        var availableHeight = LayoutGrid.ActualHeight > 0
            ? LayoutGrid.ActualHeight
            : Math.Max(320, ActualHeight - 160);

        if (CategoriesPanel.Orientation == Orientation.Vertical)
        {
            var catCount = _categoryButtons.Length;
            var catRemaining = Math.Max(0, availableHeight * 0.72 - catCount * 44);
            CategoriesPanel.Spacing = catCount <= 1 ? 6 : Math.Clamp(catRemaining / (catCount - 1), 6, 20);
        }
        else
        {
            CategoriesPanel.Spacing = 6;
        }

        var panel = activePanel ?? (_lastSelectedCategoryIndex >= 0 && _lastSelectedCategoryIndex < _categoryPanels.Length
            ? _categoryPanels[_lastSelectedCategoryIndex]
            : null);
        if (panel is null) return;

        var rows = new List<SettingsRow>();
        foreach (var child in panel.Children)
        {
            if (child is SettingsRow row && row.Visibility == Visibility.Visible)
            {
                rows.Add(row);
            }
        }

        var count = rows.Count;
        if (count == 0) return;

        var targetRowHeight = Math.Clamp((availableHeight * 0.55) / count, 64, 92);
        var remaining = Math.Max(0, availableHeight * 0.80 - count * targetRowHeight);
        panel.Spacing = count <= 1 ? 0 : Math.Clamp(remaining / (count - 1), 0, 28);

        foreach (var row in rows)
        {
            row.MinHeight = targetRowHeight;
        }
    }

    private void FocusFirstRowInCurrentCategory()
    {
        if (_lastSelectedCategoryIndex < 0 || _lastSelectedCategoryIndex >= _categoryPanels.Length) return;
        var panel = _categoryPanels[_lastSelectedCategoryIndex];
        foreach (var child in panel.Children)
        {
            if (child is SettingsRow row && row.IsEnabled)
            {
                row.Focus(FocusState.Keyboard);
                break;
            }
        }
    }

    private void FocusCurrentCategory()
    {
        if (_lastSelectedCategoryIndex >= 0 && _lastSelectedCategoryIndex < _categoryButtons.Length)
        {
            _categoryButtons[_lastSelectedCategoryIndex].Focus(FocusState.Keyboard);
        }
    }

    private void SettingsPage_SizeChanged(object sender, SizeChangedEventArgs e)
    {
        var width = e.NewSize.Width;
        if (width <= 0) return;

        if (width < 700)
        {
            CategoriesColDef.Width = new GridLength(1, GridUnitType.Star);
            SpacingColDef.Width = new GridLength(0);
            ContentColDef.Width = new GridLength(0);

            Grid.SetColumn(CategoriesScrollViewer, 0);
            Grid.SetColumnSpan(CategoriesScrollViewer, 3);
            Grid.SetRow(CategoriesScrollViewer, 0);
            CategoriesScrollViewer.HorizontalScrollBarVisibility = ScrollBarVisibility.Auto;
            CategoriesScrollViewer.VerticalScrollBarVisibility = ScrollBarVisibility.Disabled;
            CategoriesPanel.Orientation = Orientation.Horizontal;
            CategoriesPanel.Margin = new Thickness(0, 0, 0, 16);

            Grid.SetColumn(ContentScrollViewer, 0);
            Grid.SetColumnSpan(ContentScrollViewer, 3);
            Grid.SetRow(ContentScrollViewer, 1);
        }
        else if (width < 900)
        {
            CategoriesColDef.Width = new GridLength(200);
            SpacingColDef.Width = new GridLength(24);
            ContentColDef.Width = new GridLength(1, GridUnitType.Star);

            Grid.SetColumn(CategoriesScrollViewer, 0);
            Grid.SetColumnSpan(CategoriesScrollViewer, 1);
            Grid.SetRow(CategoriesScrollViewer, 1);
            CategoriesScrollViewer.HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled;
            CategoriesScrollViewer.VerticalScrollBarVisibility = ScrollBarVisibility.Auto;
            CategoriesPanel.Orientation = Orientation.Vertical;
            CategoriesPanel.Margin = new Thickness(0);

            Grid.SetColumn(ContentScrollViewer, 2);
            Grid.SetColumnSpan(ContentScrollViewer, 1);
            Grid.SetRow(ContentScrollViewer, 1);
        }
        else
        {
            CategoriesColDef.Width = new GridLength(300);
            SpacingColDef.Width = new GridLength(40);
            ContentColDef.Width = new GridLength(1, GridUnitType.Star);

            Grid.SetColumn(CategoriesScrollViewer, 0);
            Grid.SetColumnSpan(CategoriesScrollViewer, 1);
            Grid.SetRow(CategoriesScrollViewer, 1);
            CategoriesScrollViewer.HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled;
            CategoriesScrollViewer.VerticalScrollBarVisibility = ScrollBarVisibility.Auto;
            CategoriesPanel.Orientation = Orientation.Vertical;
            CategoriesPanel.Margin = new Thickness(0);

            Grid.SetColumn(ContentScrollViewer, 2);
            Grid.SetColumnSpan(ContentScrollViewer, 1);
            Grid.SetRow(ContentScrollViewer, 1);
        }

        ApplyAdaptiveSpacing();
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
            ShellChrome.Shell?.ShowToast(Strings.Tr("Ajustes salvos neste PC."));
        }
        catch
        {
            Apply(_preferences);
            ShellChrome.Shell?.ShowToast(Strings.Tr("Não foi possível salvar os ajustes. Nada foi alterado."));
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
        Motion.Reduced = preferences.ReduceMotion;
        _loading = false;
        SetEnabled(true);
    }

    private void SetEnabled(bool enabled)
    {
        ReduceMotionSwitch.IsEnabled = enabled;
        RowReduceMotion.IsEnabled = enabled;

        ArtworkSwitch.IsEnabled = enabled;
        RowArtwork.IsEnabled = enabled;

        ApproximateLocationSwitch.IsEnabled = enabled;
        RowApproximateLocation.IsEnabled = enabled;

        AnalyticsSwitch.IsEnabled = enabled;
        RowAnalytics.IsEnabled = enabled;

        AutomaticUpdatesSwitch.IsEnabled = enabled;
        RowAutoUpdates.IsEnabled = enabled;

        RenewAnalyticsIdButton.IsEnabled = enabled;
        RowRenewAnalyticsId.IsEnabled = enabled;

        // "Abrir em tela cheia" e "Modo tela cheia" ficam sempre habilitadas
        RowFullScreenMode.IsEnabled = true;
        RowStartFullScreen.IsEnabled = true;
        StartFullScreenSwitch.IsEnabled = true;
        FullScreenModeSwitch.IsEnabled = true;
    }

    private async void CheckUpdates_Click(object sender, RoutedEventArgs e) => await RefreshUpdateStatusAsync(checkNow: true);

    private async void RenewAnalyticsId_Click(object sender, RoutedEventArgs e)
    {
        RenewAnalyticsIdButton.IsEnabled = false;
        RowRenewAnalyticsId.IsEnabled = false;
        RowRenewAnalyticsId.Description = Strings.Tr("Gerando um novo identificador local…");
        try
        {
            await WinUiEngineComposition.RenewAnalyticsIdAsync();
            RowRenewAnalyticsId.Description = Strings.Tr("Novo identificador gerado neste PC.");
        }
        catch
        {
            RowRenewAnalyticsId.Description = Strings.Tr("Não foi possível gerar um novo identificador agora.");
        }
        finally
        {
            RenewAnalyticsIdButton.IsEnabled = _preferences is not null;
            RowRenewAnalyticsId.IsEnabled = _preferences is not null;
        }
    }

    private async Task RefreshUpdateStatusAsync(bool checkNow)
    {
        CheckUpdatesButton.IsEnabled = false;
        RowCheckUpdates.IsEnabled = false;

        if (checkNow) RowCheckUpdates.Description = Strings.Tr("Verificando a fonte configurada…");
        try
        {
            var update = checkNow
                ? await WinUiEngineComposition.CheckForUpdatesAsync()
                : await WinUiEngineComposition.GetUpdateStatusAsync();
            if (!update.Configured)
            {
                RowCheckUpdates.Description = Strings.Tr("Nenhuma fonte de atualização está configurada.");
                return;
            }
            var lastChecked = update.LastCheckedEpochMs is { } epoch
                ? Strings.Format("Última verificação: {0}. ", DateTimeOffset.FromUnixTimeMilliseconds(epoch).ToLocalTime().ToString("g"))
                : Strings.Tr("Ainda não verificado. ");
            RowCheckUpdates.Description = update.State.ToLowerInvariant() switch
            {
                "available" => $"{lastChecked}{Strings.Format("Atualização {0} encontrada.", update.Version ?? Strings.Tr("disponível"))}",
                "ready" => $"{lastChecked}{Strings.Tr("Atualização pronta no host local.")}",
                "failed" => $"{lastChecked}{Strings.Tr("Não foi possível verificar agora.")}",
                _ => $"{lastChecked}{Strings.Tr("Nenhuma atualização disponível.")}",
            };
            CheckUpdatesButton.IsEnabled = true;
            RowCheckUpdates.IsEnabled = true;
        }
        catch
        {
            RowCheckUpdates.Description = Strings.Tr("Não foi possível consultar atualizações agora.");
        }
    }
}
