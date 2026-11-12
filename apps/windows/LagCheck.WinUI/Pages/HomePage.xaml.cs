using System;
using System.Linq;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media.Imaging;
using LagCheck.WinUI.Library;
using LagCheck.WinUI.Localization;

namespace LagCheck.WinUI.Pages;

public sealed partial class HomePage : Page
{
    public LibraryViewModel ViewModel { get; }

    private readonly System.Collections.Specialized.NotifyCollectionChangedEventHandler _historyChangedHandler;

    public HomePage()
    {
        InitializeComponent();
        ViewModel = new LibraryViewModel(LibraryPageServices.Bridge, LibraryPageServices.DiagnosticNavigator);
        DataContext = ViewModel;
        LocalizeUI();

        _historyChangedHandler = (_, _) => DispatcherQueue.TryEnqueue(UpdateHeroDisplay);
        LagCheck.WinUI.History.SessionHistoryServices.Store.Entries.CollectionChanged += _historyChangedHandler;
        LocalizationService.Instance.LanguageChanged += OnLanguageChanged;
        Unloaded += (_, _) =>
        {
            LagCheck.WinUI.History.SessionHistoryServices.Store.Entries.CollectionChanged -= _historyChangedHandler;
            LocalizationService.Instance.LanguageChanged -= OnLanguageChanged;
        };
    }

    private void OnLanguageChanged() => DispatcherQueue.TryEnqueue(LocalizeUI);

    private void LocalizeUI()
    {
        LaunchBtn.Content = Strings.Tr("▶ JOGAR AGORA");
        CheckConnBtn.Content = Strings.Tr("Checar conexão");

        ToolTipService.SetToolTip(LaunchBtn, Strings.Tr("Iniciar jogo instalado"));
        ToolTipService.SetToolTip(CheckConnBtn, Strings.Tr("Avaliar rota e estabilidade pré-partida"));
        ToolTipService.SetToolTip(FavBtn, Strings.Tr("Favoritar jogo"));
        ToolTipService.SetToolTip(RefreshArtBtn, Strings.Tr("Atualizar imagem oficial"));

        CockpitEyebrow.Text = Strings.Tr("COCKPIT DE TELEMETRIA");
        EmptyHeroTitle.Text = Strings.Tr("NENHUM JOGO LOCAL ENCONTRADO");
        EmptyHeroDesc.Text = Strings.Tr("O LagCheck monitora seus jogos instalados (Steam, Epic, Xbox) ou sua rota geral.");
        ScanGamesBtn.Content = Strings.Tr("Procurar jogos instalados");
        GeneralCheckBtn.Content = Strings.Tr("Testar conexão geral");
    }

    private async void HomePage_Loaded(object sender, RoutedEventArgs e)
    {
        await ViewModel.LoadAsync();
        await LagCheck.WinUI.History.SessionHistoryServices.Store.TryRefreshAsync(Diagnostic.WinUiEngineComposition.Client);
        UpdateHeroDisplay();
    }

    private void UpdateHeroDisplay()
    {
        var hero = ViewModel.HeroGame;
        if (hero == null)
        {
            GameHeroPanel.Visibility = Visibility.Collapsed;
            EmptyHeroPanel.Visibility = Visibility.Visible;
            HeroBackgroundImage.Source = null;
            HeroVerdictPanel.Visibility = Visibility.Collapsed;
            return;
        }

        GameHeroPanel.Visibility = Visibility.Visible;
        EmptyHeroPanel.Visibility = Visibility.Collapsed;

        // Veredito e métricas reais: filtrado estritamente pelo jogo em destaque
        var matchingResult = LagCheck.WinUI.History.SessionHistoryServices.Store.Entries.FirstOrDefault(entry =>
            entry.PingMs.HasValue &&
            !string.IsNullOrWhiteSpace(hero.DiagnosticGameId) &&
            string.Equals(entry.GameId, hero.DiagnosticGameId, StringComparison.OrdinalIgnoreCase));

        if (matchingResult != null && matchingResult.PingMs.HasValue)
        {
            HeroVerdictPanel.Visibility = Visibility.Visible;
            ApplyVerdictStyle(matchingResult.Verdict);
            PingEstimateText.Text = matchingResult.PingLabel;
        }
        else
        {
            HeroVerdictPanel.Visibility = Visibility.Collapsed;
        }

        // Atualiza imagem de fundo se houver
        if (!string.IsNullOrWhiteSpace(hero.HeroArtworkPath))
        {
            try
            {
                HeroBackgroundImage.Source = new BitmapImage(new Uri(hero.HeroArtworkPath));
            }
            catch
            {
                HeroBackgroundImage.Source = null;
            }
        }
        else
        {
            HeroBackgroundImage.Source = null;
        }
    }

    private void ApplyVerdictStyle(string rawVerdict)
    {
        var v = rawVerdict.Trim().ToLowerInvariant();
        string clean = v.TrimStart('●', '▲', '—', ' ').Trim();

        // not_ready deve ser avaliado antes de ready para evitar falso positivo de substring
        if (clean.StartsWith("not_ready") || clean.Contains("evitaria") || clean == "ruim")
        {
            var brush = (SolidColorBrush)Application.Current.Resources["CoralBrush"];
            VerdictText.Text = Strings.Tr("▲ EU EVITARIA RANKED AGORA");
            VerdictText.Foreground = brush;
            VerdictDot.Fill = brush;
            VerdictBorder.Background = new SolidColorBrush(Windows.UI.Color.FromArgb(0x25, 0xFF, 0x5A, 0x36));
        }
        else if (clean.StartsWith("caution") || clean.Contains("instáv") || clean.Contains("instav"))
        {
            var brush = (SolidColorBrush)Application.Current.Resources["CautionBrush"];
            VerdictText.Text = Strings.Tr("▲ CONDIÇÕES INSTÁVEIS");
            VerdictText.Foreground = brush;
            VerdictDot.Fill = brush;
            VerdictBorder.Background = new SolidColorBrush(Windows.UI.Color.FromArgb(0x25, 0xF5, 0x9E, 0x0B));
        }
        else if (clean.StartsWith("ready") || clean.Contains("pronto") || clean == "boa")
        {
            var brush = (SolidColorBrush)Application.Current.Resources["ReadyBrush"];
            VerdictText.Text = Strings.Tr("● PRONTO PARA RANKED");
            VerdictText.Foreground = brush;
            VerdictDot.Fill = brush;
            VerdictBorder.Background = new SolidColorBrush(Windows.UI.Color.FromArgb(0x25, 0x22, 0xC5, 0x5E));
        }
        else
        {
            var brush = (SolidColorBrush)Application.Current.Resources["TextTertiaryBrush"];
            VerdictText.Text = Strings.Tr("— INCONCLUSIVO");
            VerdictText.Foreground = brush;
            VerdictDot.Fill = brush;
            VerdictBorder.Background = new SolidColorBrush(Windows.UI.Color.FromArgb(0x25, 0x68, 0x72, 0x85));
        }
    }

    private void RecentGame_Click(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement { DataContext: LibraryGame game })
        {
            ViewModel.SetHeroGame(game);
            UpdateHeroDisplay();
        }
    }

    private async void Launch_Click(object sender, RoutedEventArgs e)
    {
        if (ViewModel.HeroGame is { } game)
        {
            if (ViewModel.LaunchCommand.CanExecute(game))
            {
                ViewModel.LaunchCommand.Execute(game);
            }
        }
    }

    private void CheckConnection_Click(object sender, RoutedEventArgs e)
    {
        if (ViewModel.HeroGame is { } game)
        {
            ShellNavigation.NavigateToDiagnostic(game.DiagnosticGameId, game.Title);
        }
    }

    private void ToggleFavorite_Click(object sender, RoutedEventArgs e)
    {
        if (ViewModel.HeroGame is { } game)
        {
            if (ViewModel.ToggleFavoriteCommand.CanExecute(game))
            {
                ViewModel.ToggleFavoriteCommand.Execute(game);
            }
        }
    }

    private void RefreshArtwork_Click(object sender, RoutedEventArgs e)
    {
        if (ViewModel.HeroGame is { } game)
        {
            if (ViewModel.RefreshArtworkCommand.CanExecute(game))
            {
                ViewModel.RefreshArtworkCommand.Execute(game);
            }
        }
    }

    private async void Rescan_Click(object sender, RoutedEventArgs e)
    {
        if (ViewModel.RefreshCommand.CanExecute(null))
        {
            ViewModel.RefreshCommand.Execute(null);
        }
        await ViewModel.LoadAsync();
        UpdateHeroDisplay();
    }

    private void GeneralCheck_Click(object sender, RoutedEventArgs e)
    {
        ShellNavigation.NavigateToDiagnostic(null, null);
    }
}
