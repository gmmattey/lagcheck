using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Linq;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.UI;
using LagCheck.WinUI.Controls;
using LagCheck.WinUI.Library;
using LagCheck.WinUI.Localization;

namespace LagCheck.WinUI.Pages;

/// <summary>Início (v2): hero em tela cheia do jogo em foco + faixa de recentes. A arte fica no shell, atrás da janela.</summary>
public sealed partial class HomePage : Page
{
    private const int MaxRecents = 12;

    public LibraryViewModel ViewModel { get; }

    private readonly NotifyCollectionChangedEventHandler _historyChangedHandler;
    private readonly DispatcherTimer _slideTimer = new() { Interval = TimeSpan.FromSeconds(5) };
    private string? _selectedId;
    private int _slide;
    private List<string> _slides = new();
    private bool _refreshQueued;
    private bool _wired;

    public HomePage()
    {
        InitializeComponent();
        ViewModel = new LibraryViewModel(LibraryPageServices.Bridge, LibraryPageServices.DiagnosticNavigator);
        DataContext = ViewModel;
        GlowEffect.Attach(LaunchGlow, Color.FromArgb(0x8C, 0x7C, 0x3A, 0xED), 36);
        LocalizeUI();

        _historyChangedHandler = (_, _) => QueueRefresh();
        _slideTimer.Tick += (_, _) =>
        {
            if (_slides.Count > 1 && !Motion.Reduced) SelectSlide((_slide + 1) % _slides.Count);
        };
    }

    private void Wire()
    {
        if (_wired) return;
        _wired = true;
        LagCheck.WinUI.History.SessionHistoryServices.Store.Entries.CollectionChanged += _historyChangedHandler;
        ViewModel.VisibleGames.CollectionChanged += OnGamesChanged;
        ViewModel.PropertyChanged += OnViewModelChanged;
        LocalizationService.Instance.LanguageChanged += OnLanguageChanged;
    }

    private void Unwire()
    {
        if (!_wired) return;
        _wired = false;
        LagCheck.WinUI.History.SessionHistoryServices.Store.Entries.CollectionChanged -= _historyChangedHandler;
        ViewModel.VisibleGames.CollectionChanged -= OnGamesChanged;
        ViewModel.PropertyChanged -= OnViewModelChanged;
        LocalizationService.Instance.LanguageChanged -= OnLanguageChanged;
    }

    private void OnGamesChanged(object? sender, NotifyCollectionChangedEventArgs e) => QueueRefresh();
    private void OnViewModelChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
    {
        if (e.PropertyName is nameof(LibraryViewModel.HeroGame) or nameof(LibraryViewModel.HasGames)) QueueRefresh();
    }

    private void OnLanguageChanged() => DispatcherQueue.TryEnqueue(() => { LocalizeUI(); Refresh(); });

    private void LocalizeUI()
    {
        LaunchBtn.Content = Strings.Tr("▶ JOGAR AGORA");
        CheckConnBtn.Content = Strings.Tr("Checar conexão");
        ToolTipService.SetToolTip(LaunchBtn, Strings.Tr("Iniciar jogo instalado"));
        ToolTipService.SetToolTip(CheckConnBtn, Strings.Tr("Avaliar rota e estabilidade pré-partida"));
        ToolTipService.SetToolTip(RefreshArtBtn, Strings.Tr("Atualizar imagem oficial"));

        CockpitEyebrow.Text = Strings.Tr("COCKPIT DE TELEMETRIA");
        EmptyHeroTitle.Text = Strings.Tr("NENHUM JOGO LOCAL ENCONTRADO");
        EmptyHeroDesc.Text = Strings.Tr("O LagCheck monitora seus jogos instalados (Steam, Epic, Xbox) ou sua rota geral.");
        ScanGamesBtn.Content = Strings.Tr("Procurar jogos instalados");
        GeneralCheckBtn.Content = Strings.Tr("Testar conexão geral");
    }

    private async void HomePage_Loaded(object sender, RoutedEventArgs e)
    {
        Wire();
        Refresh();
        _slideTimer.Start();
        await ViewModel.LoadAsync();
        await LagCheck.WinUI.History.SessionHistoryServices.Store.TryRefreshAsync(Diagnostic.WinUiEngineComposition.Client);
        Refresh();
        var visible = Recents().ToList();
        if (CurrentHero() is { } current && visible.All(game => game.Id != current.Id)) visible.Add(current);
        await Artwork.ResolveMissingAsync(ViewModel, visible);
        Refresh();
    }

    private void HomePage_Unloaded(object sender, RoutedEventArgs e)
    {
        _slideTimer.Stop();
        _backdropApplied = false;
        Unwire();
    }

    private void HomePage_SizeChanged(object sender, SizeChangedEventArgs e) => ApplyViewportSizing();

    private void QueueRefresh()
    {
        if (_refreshQueued) return;
        _refreshQueued = true;
        DispatcherQueue.TryEnqueue(() =>
        {
            _refreshQueued = false;
            Refresh();
        });
    }

    // ------------------------------------------------------------------ dados

    private IReadOnlyList<LibraryGame> Recents() => ViewModel.VisibleGames
        .Where(game => game.IsInstalled)
        .OrderByDescending(game => game.RecentActivityEpochMs ?? long.MinValue)
        .ThenBy(game => game.Title, StringComparer.CurrentCultureIgnoreCase)
        .Take(MaxRecents)
        .ToList();

    private LibraryGame? CurrentHero()
    {
        var games = ViewModel.VisibleGames;
        return (_selectedId is null ? null : games.FirstOrDefault(game => game.Id == _selectedId))
            ?? ViewModel.HeroGame
            ?? Recents().FirstOrDefault();
    }

    // ------------------------------------------------------------------ apresentação

    private double ViewportHeight => Math.Max((ShellChrome.Shell?.ActualHeight ?? 0) is > 0 ? ShellChrome.Shell!.ActualHeight : ActualHeight + 56, 320);

    private void ApplyViewportSizing()
    {
        var vh = ViewportHeight / 100.0;
        GameTitleText.FontSize = Math.Clamp(8 * vh, 36, 76);
        GameTitleText.LineHeight = GameTitleText.FontSize * 0.98;
        GameHeroPanel.Spacing = Math.Clamp(2 * vh, 8, 18);
        GameHeroPanel.Margin = new Thickness(0, 0, 0, Math.Clamp(3 * vh, 12, 30));
        EmptyHeroPanel.Margin = GameHeroPanel.Margin;
        BuildRecents();
    }

    private void Refresh()
    {
        var hero = CurrentHero();
        if (hero is null)
        {
            GameHeroPanel.Visibility = Visibility.Collapsed;
            EmptyHeroPanel.Visibility = Visibility.Visible;
            HeroVerdictPanel.Visibility = Visibility.Collapsed;
            SetSlides(Array.Empty<string>());
            BuildRecents();
            return;
        }

        _selectedId = hero.Id;
        GameHeroPanel.Visibility = Visibility.Visible;
        EmptyHeroPanel.Visibility = Visibility.Collapsed;

        GameTitleText.Text = hero.Title.ToUpperInvariant();
        ApplyPlatform(hero);
        ApplyVerdict(hero);

        CheckConnBtn.Visibility = hero.CanTestConnection ? Visibility.Visible : Visibility.Collapsed;
        LaunchBtn.IsEnabled = hero.IsInstalled && hero.IsLaunchable;
        FavIcon.IsFilled = hero.IsFavorite;
        FavIcon.Foreground = hero.IsFavorite ? (Brush)Application.Current.Resources["CoralBrush"] : (Brush)Application.Current.Resources["TextPrimaryBrush"];
        ToolTipService.SetToolTip(FavBtn, hero.FavoriteActionLabel);

        SetSlides(new[] { Artwork.FirstExisting(hero.HeroArtworkPath) }.Where(path => path is not null).Cast<string>().ToList());
        ApplyViewportSizing();
    }

    private void ApplyPlatform(LibraryGame hero)
    {
        var logo = Glyphs.PlatformLogo(hero.Platform);
        PlatformLogo.Visibility = logo is null ? Visibility.Collapsed : Visibility.Visible;
        PlatformMonitor.Visibility = logo is null ? Visibility.Visible : Visibility.Collapsed;
        PlatformText.Visibility = logo is null ? Visibility.Visible : Visibility.Collapsed;
        if (logo is not null) PlatformLogo.Data = logo;
        ToolTipService.SetToolTip(PlatformPill, hero.PlatformLabel);
    }

    private void ApplyVerdict(LibraryGame hero)
    {
        // Veredito e métricas reais: filtrados estritamente pelo jogo em destaque.
        var match = LagCheck.WinUI.History.SessionHistoryServices.Store.Entries.FirstOrDefault(entry =>
            entry.PingMs.HasValue
            && !string.IsNullOrWhiteSpace(hero.DiagnosticGameId)
            && string.Equals(entry.GameId, hero.DiagnosticGameId, StringComparison.OrdinalIgnoreCase));

        if (match is null || !match.PingMs.HasValue)
        {
            HeroVerdictPanel.Visibility = Visibility.Collapsed;
            return;
        }

        HeroVerdictPanel.Visibility = Visibility.Visible;
        ApplyVerdictStyle(match.Verdict);
        PingEstimateText.Text = match.PingLabel;
    }

    private void ApplyVerdictStyle(string rawVerdict)
    {
        var v = rawVerdict.Trim().ToLowerInvariant();
        var clean = v.TrimStart('●', '▲', '—', ' ').Trim();
        string text;
        Color color;
        // not_ready deve ser avaliado antes de ready para evitar falso positivo de substring.
        if (clean.StartsWith("not_ready") || clean.Contains("evitaria") || clean == "ruim")
        {
            text = Strings.Tr("▲ EU EVITARIA RANKED AGORA");
            color = Color.FromArgb(255, 0xFF, 0x5A, 0x36);
        }
        else if (clean.StartsWith("caution") || clean.Contains("instáv") || clean.Contains("instav"))
        {
            text = Strings.Tr("▲ CONDIÇÕES INSTÁVEIS");
            color = Color.FromArgb(255, 0xF5, 0x9E, 0x0B);
        }
        else if (clean.StartsWith("ready") || clean.Contains("pronto") || clean == "boa")
        {
            text = Strings.Tr("● PRONTO PARA RANKED");
            color = Color.FromArgb(255, 0x22, 0xC5, 0x5E);
        }
        else
        {
            text = Strings.Tr("— INCONCLUSIVO");
            color = Color.FromArgb(255, 0x9A, 0xA3, 0xB5);
        }
        VerdictText.Text = text;
        VerdictText.Foreground = new SolidColorBrush(color);
        VerdictBorder.Background = new SolidColorBrush(Color.FromArgb(0x29, color.R, color.G, color.B));
    }

    // ------------------------------------------------------------------ slides

    private void SetSlides(IReadOnlyList<string> images)
    {
        var changed = !images.SequenceEqual(_slides);
        _slides = images.ToList();
        if (_slide >= Math.Max(_slides.Count, 1)) _slide = 0;
        if (changed || ShellChrome.Shell is { } && !_backdropApplied)
        {
            ShellChrome.Shell?.SetBackdrop(_slides, BackdropKind.Hero, _slide);
            _backdropApplied = true;
        }
        BuildDots();
    }

    private bool _backdropApplied;

    private void SelectSlide(int index)
    {
        _slide = index;
        ShellChrome.Shell?.SelectBackdropSlide(index);
        BuildDots();
    }

    private void BuildDots()
    {
        DotsPanel.Children.Clear();
        DotsPanel.Visibility = _slides.Count > 1 ? Visibility.Visible : Visibility.Collapsed;
        for (var i = 0; i < _slides.Count; i++)
        {
            var index = i;
            var active = i == _slide;
            var dot = new Border
            {
                Height = 5,
                Width = active ? 28 : 10,
                CornerRadius = new CornerRadius(3),
                Background = new SolidColorBrush(active ? Color.FromArgb(255, 0xF5, 0xF7, 0xFC) : Color.FromArgb(0x59, 0xF5, 0xF7, 0xFC)),
            };
            dot.Tapped += (_, _) => { SelectSlide(index); _slideTimer.Stop(); _slideTimer.Start(); };
            DotsPanel.Children.Add(dot);
        }
    }

    // ------------------------------------------------------------------ recentes

    private void BuildRecents()
    {
        RecentsPanel.Children.Clear();
        var vh = ViewportHeight / 100.0;
        var selectedWidth = Math.Min(140, 12 * vh);
        var selectedHeight = Math.Min(210, 18 * vh);
        var restWidth = Math.Min(98, 8.6 * vh);
        var restHeight = Math.Min(147, 13 * vh);
        var hero = CurrentHero();

        foreach (var game in Recents())
        {
            var selected = hero is not null && game.Id == hero.Id;
            var tile = new Grid { Width = selected ? selectedWidth : restWidth, Height = selected ? selectedHeight : restHeight, VerticalAlignment = VerticalAlignment.Bottom };
            var clip = new Border { CornerRadius = new CornerRadius(14), Background = new SolidColorBrush(Color.FromArgb(255, 0x17, 0x1B, 0x24)) };
            var content = new Grid();
            content.Children.Add(new StripedBackground { Band = 14 });
            if (Artwork.Load(Artwork.FirstExisting(game.CoverArtworkPath), 280) is { } cover)
                content.Children.Add(new Image { Source = cover, Stretch = Stretch.UniformToFill });
            clip.Child = content;
            tile.Children.Add(clip);
            if (selected)
            {
                tile.Children.Add(new Border
                {
                    CornerRadius = new CornerRadius(16),
                    BorderThickness = new Thickness(2),
                    BorderBrush = new SolidColorBrush(Color.FromArgb(255, 0xA7, 0x8B, 0xFA)),
                    Margin = new Thickness(-2),
                    IsHitTestVisible = false,
                });
            }
            tile.Opacity = selected ? 1 : 0.7;
            ToolTipService.SetToolTip(tile, game.Title);
            tile.PointerEntered += (_, _) =>
            {
                tile.Opacity = 1;
                if (_selectedId == game.Id) return;
                _selectedId = game.Id;
                _slide = 0;
                Refresh();
            };
            tile.PointerExited += (_, _) => tile.Opacity = _selectedId == game.Id ? 1 : 0.7;
            tile.Tapped += (_, _) => OpenDetails(game);
            RecentsPanel.Children.Add(tile);
        }
    }

    private void OpenDetails(LibraryGame game)
    {
        if (ViewModel.SelectGameCommand.CanExecute(game)) ViewModel.SelectGameCommand.Execute(game);
        ShellNavigation.OpenGameDetails(game, NavigationRoute.Home);
    }

    // ------------------------------------------------------------------ ações

    private async void Launch_Click(object sender, RoutedEventArgs e)
    {
        if (CurrentHero() is not { } game) return;
        ShellChrome.Shell?.ShowToast(Strings.Format("Abrindo {0}…", game.Title));
        await ViewModel.LaunchAsync(game);
        if (!ViewModel.LastOperationSucceeded && !string.IsNullOrWhiteSpace(ViewModel.Notice)) ShellChrome.Shell?.ShowToast(ViewModel.Notice!);
    }

    private void CheckConnection_Click(object sender, RoutedEventArgs e)
    {
        if (CurrentHero() is { } game) ShellNavigation.NavigateToDiagnostic(game.DiagnosticGameId, game.Title);
    }

    private void ToggleFavorite_Click(object sender, RoutedEventArgs e)
    {
        if (CurrentHero() is { } game && ViewModel.ToggleFavoriteCommand.CanExecute(game)) ViewModel.ToggleFavoriteCommand.Execute(game);
    }

    private async void RefreshArtwork_Click(object sender, RoutedEventArgs e)
    {
        if (CurrentHero() is not { } game) return;
        await ViewModel.RefreshArtworkAsync(game);
        ShellChrome.Shell?.ShowToast(ViewModel.LastOperationSucceeded
            ? Strings.Tr("Imagem oficial atualizada a partir do cache local.")
            : ViewModel.Notice ?? Strings.Tr("Não foi possível atualizar a imagem agora."));
        _backdropApplied = false;
        Refresh();
    }

    private async void Rescan_Click(object sender, RoutedEventArgs e)
    {
        if (ViewModel.RefreshCommand.CanExecute(null)) ViewModel.RefreshCommand.Execute(null);
        await ViewModel.LoadAsync();
        Refresh();
    }

    private void GeneralCheck_Click(object sender, RoutedEventArgs e) => ShellNavigation.NavigateToDiagnostic(null, null);
}
