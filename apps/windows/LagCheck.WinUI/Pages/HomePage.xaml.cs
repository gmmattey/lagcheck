using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Globalization;
using System.Linq;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Animation;
using Microsoft.UI.Xaml.Shapes;
using Windows.UI;
using LagCheck.WinUI.Controls;
using LagCheck.WinUI.Library;
using LagCheck.WinUI.Localization;
using LagCheck.WinUI.PlatformStatus;

namespace LagCheck.WinUI.Pages;

/// <summary>Início (v2): hero em tela cheia do jogo em foco + faixa de recentes. A arte fica no shell, atrás da janela.</summary>
public sealed partial class HomePage : Page
{
    /// <summary>Y: tamanho máximo da fila (faixa de recentes e rotação automática do hero).</summary>
    private const int MaxRecents = 8;
    /// <summary>Máximo de artes mostradas por jogo antes de passar ao próximo da fila.</summary>
    private const int MaxArtsPerGame = 3;

    public LibraryViewModel ViewModel { get; }

    private readonly NotifyCollectionChangedEventHandler _historyChangedHandler;
    private readonly DispatcherTimer _slideTimer = new() { Interval = TimeSpan.FromSeconds(5) };
    private string? _selectedId;
    private int _slide;
    private List<string> _slides = new();
    private bool _refreshQueued;
    private bool _wired;
    private readonly List<RecentTile> _tiles = new();
    private readonly DispatcherTimer _hoverTimer = new() { Interval = TimeSpan.FromMilliseconds(110) };
    private string? _hoverId;
    private bool _canLaunch;
    private bool _launchHovered;
    private readonly PlatformStatusClient _platformStatus = new();
    private PlatformStatusSnapshot? _lastPlatformStatus;
    private bool _pcSelected = true;
    private Button? _pcTile;
    private Border? _pcRing;

    private sealed record RecentTile(LibraryGame Game, Button Tile, Border Ring);

    public HomePage()
    {
        InitializeComponent();
        ViewModel = new LibraryViewModel(LibraryPageServices.Bridge, LibraryPageServices.DiagnosticNavigator);
        DataContext = ViewModel;
        GlowEffect.Attach(LaunchGlow, Color.FromArgb(0xA8, 0x7C, 0x3A, 0xED), 24);
        LaunchBtn.PointerEntered += (_, _) => { _launchHovered = true; UpdateLaunchChrome(); };
        LaunchBtn.PointerExited += (_, _) => { _launchHovered = false; UpdateLaunchChrome(); };
        LocalizeUI();

        _historyChangedHandler = (_, _) => QueueRefresh();
        _hoverTimer.Tick += (_, _) =>
        {
            _hoverTimer.Stop();
            if (_hoverId is { } id && id != _selectedId) SelectRecent(id);
        };
        _slideTimer.Tick += (_, _) => AdvanceCarousel();
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
        LaunchBtnText.Text = Strings.Tr("JOGAR AGORA");
        ActivityTitle.Text = Strings.Tr("ATIVIDADE CONHECIDA");
        StabilityTitle.Text = Strings.Tr(_pcSelected ? "HISTÓRICO DE MEDIÇÕES" : "HISTÓRICO DE CHECKS");
        PlatformsTitle.Text = Strings.Tr("STATUS DAS PLATAFORMAS");
        GalleryTitle.Text = Strings.Tr("Galeria local");
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(TopSearchBtn, Strings.Tr("Buscar jogo..."));
        ToolTipService.SetToolTip(TopSearchBtn, Strings.Tr("Buscar jogo (Ctrl+F)"));
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(TopGalleryBtn, Strings.Tr("Galeria local"));
        ToolTipService.SetToolTip(TopGalleryBtn, Strings.Tr("Galeria local"));
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(TopSettingsBtn, Strings.Tr("Ajustes"));
        ToolTipService.SetToolTip(TopSettingsBtn, Strings.Tr("Ajustes"));
        PcPlatformText.Text = Strings.Tr("ESTE PC");
        PcHeroTitle.Text = Strings.Tr("SEU PC");
        PcHeroDescription.Text = Strings.Tr("Leituras da sua conexão e da atividade conhecida na biblioteca local.");
        PcCheckBtn.Content = Strings.Tr("Testar conexão geral");
        OpenHistoryBtn.Content = Strings.Tr("Ver histórico");
        if (_lastPlatformStatus is null) PlatformStatusText.Text = Strings.Tr("Consultando…");
        else RenderPlatformStatus(_lastPlatformStatus);
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(LaunchBtn, Strings.Tr("Iniciar jogo instalado"));
        CheckConnBtn.Content = Strings.Tr("Checar conexão");
        ToolTipService.SetToolTip(LaunchBtn, Strings.Tr("Iniciar jogo instalado"));
        ToolTipService.SetToolTip(CheckConnBtn, Strings.Tr("Avaliar rota e estabilidade pré-partida"));

        CockpitEyebrow.Text = Strings.Tr("COCKPIT DE TELEMETRIA");
        EmptyHeroTitle.Text = Strings.Tr("NENHUM JOGO LOCAL ENCONTRADO");
        EmptyHeroDesc.Text = Strings.Tr("O LagCheck monitora seus jogos instalados (Steam, Epic, Xbox) ou sua rota geral.");
        ScanGamesBtn.Content = Strings.Tr("Procurar jogos instalados");
        GeneralCheckBtn.Content = Strings.Tr("Testar conexão geral");
    }

    private async void HomePage_Loaded(object sender, RoutedEventArgs e)
    {
        // A página fica em cache de navegação; reaplica o idioma ao voltar de Ajustes.
        LocalizeUI();
        Wire();
        Refresh();
        _slideTimer.Start();
        _ = LoadPlatformStatusAsync();
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

    /// <summary>Data que coloca o jogo na fila: último uso e, na falta dele, a instalação. Nunca estimada.</summary>
    private static long? RecencyOf(LibraryGame game) => game.RecentActivityEpochMs ?? game.InstalledAtEpochMs;

    /// <summary>Fila do carrossel: jogos instalados com data real de uso ou de instalação, do mais recente ao mais antigo, até Y.</summary>
    private IReadOnlyList<LibraryGame> Recents() => ViewModel.VisibleGames
        .Where(game => game.IsInstalled)
        .OrderByDescending(game => RecencyOf(game) ?? long.MinValue)
        .ThenBy(game => game.Title, StringComparer.CurrentCultureIgnoreCase)
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

    private void ApplyHeroSizing()
    {
        var vh = ViewportHeight / 100.0;
        GameTitleText.FontSize = Math.Clamp(8 * vh, 36, 76);
        GameTitleText.LineHeight = GameTitleText.FontSize * 0.98;
        GameHeroPanel.Spacing = Math.Clamp(2 * vh, 8, 18);
        GameHeroPanel.Margin = new Thickness(0, 0, 0, Math.Clamp(3 * vh, 12, 30));
        EmptyHeroPanel.Margin = GameHeroPanel.Margin;
        PcHeroPanel.Margin = GameHeroPanel.Margin;
    }

    private void UpdateLaunchChrome()
    {
        if (!_canLaunch)
        {
            LaunchGlow.Opacity = 0;
            LaunchCtaRing.BorderBrush = new SolidColorBrush(Colors.Transparent);
            return;
        }

        LaunchGlow.Opacity = _launchHovered ? 1 : 0.78;
        LaunchCtaRing.BorderBrush = _launchHovered
            ? new SolidColorBrush(Color.FromArgb(0x8C, 0xA7, 0x8B, 0xFA))
            : (Brush)Application.Current.Resources["HomeHeroCtaRingBrush"];
    }

    private void ApplyViewportSizing()
    {
        // ScrollViewer measures its content without a vertical limit. Reserve at least the
        // visible height so bottom alignment refers to the window, not just the content.
        Stage.MinHeight = Math.Max(0, ActualHeight);
        ApplyHeroSizing();
        ApplyResponsiveLayout();
        BuildRecents();
    }

    private void ApplyResponsiveLayout()
    {
        var compact = ActualWidth < 1500;
        HeroActions.Orientation = ActualWidth < 680 ? Orientation.Vertical : Orientation.Horizontal;
        HomeContentGrid.ColumnDefinitions[0].Width = compact ? new GridLength(1, GridUnitType.Star) : new GridLength(620);
        HomeContentGrid.ColumnDefinitions[1].Width = compact ? new GridLength(0) : new GridLength(1, GridUnitType.Star);
        HomeContentGrid.RowDefinitions[1].Height = compact ? GridLength.Auto : new GridLength(0);
        Grid.SetColumn(InsightsScroll, compact ? 0 : 1);
        Grid.SetRow(InsightsScroll, compact ? 1 : 0);
        InsightsScroll.Margin = compact ? new Thickness(0, 14, 0, 0) : new Thickness(0, 0, 0, 24);
        InsightsScroll.HorizontalAlignment = compact ? HorizontalAlignment.Stretch : HorizontalAlignment.Right;
        InsightsScroll.VerticalAlignment = compact ? VerticalAlignment.Top : VerticalAlignment.Bottom;
        InsightsScroll.MaxWidth = compact ? double.PositiveInfinity : 760;
        HeroSurface.HorizontalAlignment = compact ? HorizontalAlignment.Stretch : HorizontalAlignment.Left;
        HeroSurface.MaxWidth = compact ? double.PositiveInfinity : 620;
    }

    /// <summary>Troca o jogo em destaque sem refazer a faixa: o hero some e volta rápido, os cards animam o tamanho.</summary>
    private void SelectRecent(string id)
    {
        _pcSelected = false;
        _selectedId = id;
        _slide = 0;
        _slideTimer.Stop();
        _slideTimer.Start();
        Refresh(rebuildRecents: false);
        FadeHero();
        UpdateRecentSelection(animate: true);
    }

    private void FadeHero()
    {
        if (Motion.Reduced) return;
        var fade = new DoubleAnimation { From = 0.15, To = 1, Duration = new Duration(TimeSpan.FromMilliseconds(260)), EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut } };
        Storyboard.SetTarget(fade, GameHeroPanel);
        Storyboard.SetTargetProperty(fade, "Opacity");
        var storyboard = new Storyboard();
        storyboard.Children.Add(fade);
        storyboard.Begin();
    }

    private void SelectPc()
    {
        _pcSelected = true;
        _selectedId = null;
        _slide = 0;
        _slideTimer.Stop();
        Refresh(rebuildRecents: false);
        if (!Motion.Reduced)
        {
            var fade = new DoubleAnimation { From = 0.15, To = 1, Duration = new Duration(TimeSpan.FromMilliseconds(260)), EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut } };
            Storyboard.SetTarget(fade, PcHeroPanel);
            Storyboard.SetTargetProperty(fade, "Opacity");
            var storyboard = new Storyboard();
            storyboard.Children.Add(fade);
            storyboard.Begin();
        }
        UpdateRecentSelection(animate: true);
    }

    private void Refresh(bool rebuildRecents = true)
    {
        if (_pcSelected)
        {
            GameHeroPanel.Visibility = Visibility.Collapsed;
            PcHeroPanel.Visibility = Visibility.Visible;
            EmptyHeroPanel.Visibility = Visibility.Collapsed;
            HeroVerdictPanel.Visibility = Visibility.Collapsed;
            ActivityCard.Visibility = Visibility.Visible;
            StabilityCard.Visibility = Visibility.Visible;
            GallerySection.Visibility = Visibility.Collapsed;
            StabilityTitle.Text = Strings.Tr("HISTÓRICO DE MEDIÇÕES");
            HistoryColumnA.Width = HistoryColumnB.Width = new GridLength(112);
            GalleryColumnA.Width = GalleryColumnB.Width = new GridLength(0);
            SetSlides(new[] { "ms-appx:///Assets/home-pc-purple.jpg" });
            if (_lastPlatformStatus is not null) RenderPlatformStatus(_lastPlatformStatus);
            BuildPcInsights();
            if (rebuildRecents) ApplyViewportSizing();
            else ApplyHeroSizing();
            return;
        }

        var hero = CurrentHero();
        if (hero is null)
        {
            GameHeroPanel.Visibility = Visibility.Collapsed;
            PcHeroPanel.Visibility = Visibility.Collapsed;
            EmptyHeroPanel.Visibility = Visibility.Visible;
            HeroVerdictPanel.Visibility = Visibility.Collapsed;
            ActivityCard.Visibility = Visibility.Collapsed;
            StabilityCard.Visibility = Visibility.Collapsed;
            GallerySection.Visibility = Visibility.Collapsed;
            HistoryColumnA.Width = HistoryColumnB.Width = new GridLength(0);
            GalleryColumnA.Width = GalleryColumnB.Width = new GridLength(0);
            SetSlides(Array.Empty<string>());
            if (rebuildRecents) BuildRecents();
            return;
        }

        _selectedId = hero.Id;
        _pcSelected = false;
        GameHeroPanel.Visibility = Visibility.Visible;
        PcHeroPanel.Visibility = Visibility.Collapsed;
        EmptyHeroPanel.Visibility = Visibility.Collapsed;
        ActivityCard.Visibility = Visibility.Visible;
        StabilityCard.Visibility = Visibility.Visible;
        StabilityTitle.Text = Strings.Tr("HISTÓRICO DE CHECKS");
        HistoryColumnA.Width = HistoryColumnB.Width = new GridLength(112);
        if (_lastPlatformStatus is not null) RenderPlatformStatus(_lastPlatformStatus);

        GameTitleText.Text = hero.Title.ToUpperInvariant();
        GameMetaText.Text = string.Join(" · ", new[] { hero.PlatformLabel, hero.Info?.Genres.FirstOrDefault(), hero.NetworkLabel }.Where(value => !string.IsNullOrWhiteSpace(value)));
        ApplyPlatform(hero);
        ApplyVerdict(hero);

        CheckConnBtn.Visibility = hero.CanTestConnection ? Visibility.Visible : Visibility.Collapsed;
        _canLaunch = hero.IsInstalled && hero.IsLaunchable;
        LaunchBtn.IsEnabled = _canLaunch;
        UpdateLaunchChrome();
        FavIcon.IsFilled = hero.IsFavorite;
        FavIcon.Foreground = hero.IsFavorite ? (Brush)Application.Current.Resources["CoralBrush"] : (Brush)Application.Current.Resources["TextPrimaryBrush"];
        ToolTipService.SetToolTip(FavBtn, hero.FavoriteActionLabel);

        SetSlides(ArtsOf(hero));
        BuildInsights(hero);
        if (rebuildRecents) ApplyViewportSizing();
        else ApplyHeroSizing();
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

    /// <summary>Artes horizontais existentes do jogo (até <see cref="MaxArtsPerGame"/>), sem repetir arquivo.</summary>
    private static List<string> ArtsOf(LibraryGame game) => new[] { game.HeroArtworkPath }
        .Select(path => Artwork.FirstExisting(path))
        .Where(path => path is not null)
        .Cast<string>()
        .Distinct(StringComparer.OrdinalIgnoreCase)
        .Take(MaxArtsPerGame)
        .ToList();

    /// <summary>Passa à próxima arte do jogo; depois da última, vai ao próximo jogo da fila (e volta ao primeiro no fim).</summary>
    private void AdvanceCarousel()
    {
        if (Motion.Reduced) return;
        if (_pcSelected) return;
        if (_slide < _slides.Count - 1)
        {
            SelectSlide(_slide + 1);
            return;
        }
        var queue = Recents();
        if (queue.Count < 2) return;
        var current = queue.ToList().FindIndex(game => game.Id == _selectedId);
        var next = queue[(current + 1) % queue.Count];
        SelectRecent(next.Id);
    }

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

    private void BuildDots() { }

    // ------------------------------------------------------------------ recentes

    private static (double W, double H, double RestW, double RestH) TileSizes() => (92, 132, 84, 120);

    private void BuildRecents()
    {
        RecentsPanel.Children.Clear();
        _tiles.Clear();
        var (selectedWidth, selectedHeight, restWidth, restHeight) = TileSizes();
        var hero = CurrentHero();

        var pcTile = new Grid();
        var pcClip = new Border { CornerRadius = new CornerRadius(8), Background = new SolidColorBrush(Color.FromArgb(255, 0x17, 0x1B, 0x24)) };
        var pcContent = new Grid();
        pcContent.Children.Add(new StripedBackground { Band = 14 });
        pcContent.Children.Add(new SvgIcon
        {
            Data = "M5 4h14a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2zM8 20h8M12 16v4",
            Size = 30,
            Foreground = (Brush)Application.Current.Resources["TextPrimaryBrush"],
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        });
        pcClip.Child = pcContent;
        pcTile.Children.Add(pcClip);
        _pcRing = new Border
        {
            CornerRadius = new CornerRadius(10),
            BorderThickness = new Thickness(2),
            BorderBrush = new SolidColorBrush(Color.FromArgb(255, 0xA7, 0x8B, 0xFA)),
            Margin = new Thickness(-2),
            Opacity = _pcSelected ? 1 : 0,
            IsHitTestVisible = false,
            OpacityTransition = new ScalarTransition { Duration = TimeSpan.FromMilliseconds(220) },
        };
        pcTile.Children.Add(_pcRing);
        _pcTile = new Button
        {
            Width = _pcSelected ? selectedWidth : restWidth,
            Height = _pcSelected ? selectedHeight : restHeight,
            Padding = new Thickness(0),
            BorderThickness = new Thickness(0),
            Background = new SolidColorBrush(Colors.Transparent),
            Content = pcTile,
            VerticalAlignment = VerticalAlignment.Bottom,
        };
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(_pcTile, Strings.Tr("Este PC"));
        ToolTipService.SetToolTip(_pcTile, Strings.Tr("Este PC"));
        Fluid.Prepare(_pcTile);
        _pcTile.PointerEntered += (_, _) => Fluid.Hover(_pcTile, true, 1.04f, -4f);
        _pcTile.PointerExited += (_, _) => Fluid.Hover(_pcTile, false);
        _pcTile.Click += (_, _) => SelectPc();
        RecentsPanel.Children.Add(_pcTile);

        foreach (var game in Recents())
        {
            var selected = !_pcSelected && hero is not null && game.Id == hero.Id;
            var tile = new Grid();
            var clip = new Border { CornerRadius = new CornerRadius(8), Background = new SolidColorBrush(Color.FromArgb(255, 0x17, 0x1B, 0x24)) };
            var content = new Grid();
            content.Children.Add(new StripedBackground { Band = 14 });
            if (Artwork.Load(Artwork.FirstExisting(game.CoverArtworkPath), 280) is { } cover)
                content.Children.Add(new Image { Source = cover, Stretch = Stretch.Uniform });
            clip.Child = content;
            tile.Children.Add(clip);
            tile.Children.Add(new Border
            {
                CornerRadius = new CornerRadius(8),
                BorderThickness = new Thickness(1),
                BorderBrush = new SolidColorBrush(Color.FromArgb(0x1F, 255, 255, 255)),
                IsHitTestVisible = false,
            });
            var ring = new Border
            {
                CornerRadius = new CornerRadius(10),
                BorderThickness = new Thickness(2),
                BorderBrush = new SolidColorBrush(Color.FromArgb(255, 0xA7, 0x8B, 0xFA)),
                Margin = new Thickness(-2),
                Opacity = selected ? 1 : 0,
                IsHitTestVisible = false,
                OpacityTransition = new ScalarTransition { Duration = TimeSpan.FromMilliseconds(220) },
            };
            tile.Children.Add(ring);
            var selector = new Button
            {
                Width = selected ? selectedWidth : restWidth,
                Height = selected ? selectedHeight : restHeight,
                Padding = new Thickness(0),
                BorderThickness = new Thickness(0),
                Background = new SolidColorBrush(Colors.Transparent),
                Content = tile,
                VerticalAlignment = VerticalAlignment.Bottom,
            };
            Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(selector, game.Title);
            Fluid.Prepare(selector);
            selector.Opacity = 1;
            ToolTipService.SetToolTip(selector, game.Title);

            var id = game.Id;
            selector.PointerEntered += (_, _) =>
            {
                Fluid.Hover(selector, true, 1.04f, -4f);
                _hoverId = id;
                if (id == _selectedId) { _hoverTimer.Stop(); return; }
                _hoverTimer.Stop();
                _hoverTimer.Start();
            };
            selector.PointerExited += (_, _) =>
            {
                Fluid.Hover(selector, false);
                if (_hoverId == id) { _hoverId = null; _hoverTimer.Stop(); }
            };
            selector.Click += (_, _) => SelectRecent(game.Id);
            selector.DoubleTapped += (_, _) => OpenDetails(game);
            _tiles.Add(new RecentTile(game, selector, ring));
            RecentsPanel.Children.Add(selector);
        }
    }

    /// <summary>Atualiza só o tamanho, o anel e a opacidade dos cards já criados.</summary>
    private void UpdateRecentSelection(bool animate)
    {
        var (selectedWidth, selectedHeight, restWidth, restHeight) = TileSizes();
        if (_pcTile is not null)
        {
            _pcRing!.Opacity = _pcSelected ? 1 : 0;
            _pcTile.Width = _pcSelected ? selectedWidth : restWidth;
            _pcTile.Height = _pcSelected ? selectedHeight : restHeight;
        }
        var storyboard = new Storyboard();
        foreach (var item in _tiles)
        {
            var selected = !_pcSelected && item.Game.Id == _selectedId;
            var width = selected ? selectedWidth : restWidth;
            var height = selected ? selectedHeight : restHeight;
            item.Ring.Opacity = selected ? 1 : 0;
            item.Tile.Opacity = 1;
            if (!animate || Motion.Reduced)
            {
                item.Tile.Width = width;
                item.Tile.Height = height;
                continue;
            }
            foreach (var (property, target) in new[] { ("Width", width), ("Height", height) })
            {
                var animation = new DoubleAnimation
                {
                    To = target,
                    Duration = new Duration(TimeSpan.FromMilliseconds(260)),
                    EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut },
                    EnableDependentAnimation = true,
                };
                Storyboard.SetTarget(animation, item.Tile);
                Storyboard.SetTargetProperty(animation, property);
                storyboard.Children.Add(animation);
            }
        }
        if (animate && !Motion.Reduced && storyboard.Children.Count > 0) storyboard.Begin();
    }

    private void OpenDetails(LibraryGame game)
    {
        if (ViewModel.SelectGameCommand.CanExecute(game)) ViewModel.SelectGameCommand.Execute(game);
        ShellNavigation.OpenGameDetails(game, NavigationRoute.Home);
    }

    // ------------------------------------------------------------------ ações

    private void BuildInsights(LibraryGame game)
    {
        var activity = ValidEpoch(game.RecentActivityEpochMs);
        ActivityMetric.Visibility = activity is null ? Visibility.Collapsed : Visibility.Visible;
        ActivityMetric.Text = activity?.ToLocalTime().ToString("d MMM yyyy", DateCulture()) ?? string.Empty;
        ActivityText.Text = activity is null ? Strings.Tr("Sem atividade disponível.") : Strings.Tr("Somente última atividade conhecida.");
        // A single observed date cannot describe activity on the remaining days.
        ActivityCalendar.Visibility = Visibility.Collapsed;

        GalleryPanel.Children.Clear();
        var shots = game.UserScreenshots.Where(shot => Artwork.FirstExisting(shot.ThumbnailPath, shot.Path) is { }).Take(4).ToList();
        GallerySection.Visibility = shots.Count == 0 ? Visibility.Collapsed : Visibility.Visible;
        GalleryColumnA.Width = GalleryColumnB.Width = new GridLength(shots.Count == 0 ? 0 : 112);
        foreach (var shot in shots)
        {
            var image = new Image { Width = 96, Height = 58, Stretch = Stretch.UniformToFill, Source = Artwork.Load(Artwork.FirstExisting(shot.ThumbnailPath, shot.Path), 160) };
            var button = new Button { Width = 96, Height = 58, Margin = new Thickness(0, 0, 6, 6), Padding = new Thickness(0), BorderThickness = new Thickness(0), Background = new SolidColorBrush(Colors.Transparent), Content = image };
            Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(button, Strings.Tr("Abrir detalhes do jogo"));
            button.Click += (_, _) => OpenDetails(game);
            GalleryPanel.Children.Add(button);
        }

        var checks = LagCheck.WinUI.History.SessionHistoryServices.Store.Entries
            .Where(entry => IsConclusiveVerdict(entry.Verdict) && entry.HasCapturedAt && entry.PingMs is { } ping && double.IsFinite(ping) && ping >= 0 && ping <= 10_000 && !string.IsNullOrWhiteSpace(game.DiagnosticGameId)
                && string.Equals(entry.GameId, game.DiagnosticGameId, StringComparison.OrdinalIgnoreCase))
            .OrderBy(entry => entry.CapturedAt).ToList();
        StabilityPlot.Children.Clear();
        StabilityMetric.Visibility = checks.Count == 0 ? Visibility.Collapsed : Visibility.Visible;
        StabilityMetric.Text = checks.Count == 0 ? string.Empty : checks[^1].PingLabel;
        if (checks.Count == 0) { StabilityPlot.Visibility = Visibility.Collapsed; StabilityText.Text = Strings.Tr("Sem Checks válidos deste jogo."); }
        else if (checks.Count == 1) { StabilityPlot.Visibility = Visibility.Collapsed; StabilityText.Text = string.Empty; }
        else
        {
            StabilityText.Text = Strings.Tr("Pings de Checks distintos; não é monitoramento ao vivo.");
            StabilityPlot.Visibility = Visibility.Visible;
            var values = checks.Select(entry => entry.PingMs!.Value).ToArray();
            var min = values.Min(); var range = Math.Max(values.Max() - min, 1d);
            for (var i = 0; i < values.Length; i++)
            {
                var point = new Ellipse { Width = 6, Height = 6, Fill = new SolidColorBrush(Color.FromArgb(255, 0xA7, 0x8B, 0xFA)) };
                Canvas.SetLeft(point, i * 196d / (values.Length - 1));
                Canvas.SetTop(point, 41 - (values[i] - min) / range * 34);
                StabilityPlot.Children.Add(point);
            }
        }
    }

    private static bool IsConclusiveVerdict(string verdict) =>
        verdict.Equals("ready", StringComparison.OrdinalIgnoreCase) ||
        verdict.Equals("caution", StringComparison.OrdinalIgnoreCase) ||
        verdict.Equals("notReady", StringComparison.OrdinalIgnoreCase);

    private void BuildPcInsights()
    {
        ActivityCalendar.Visibility = Visibility.Collapsed;
        var knownActivity = ViewModel.AllGames
            .Select(game => new { game.Title, Activity = ValidEpoch(game.RecentActivityEpochMs) })
            .Where(item => item.Activity is not null)
            .OrderByDescending(item => item.Activity)
            .ToList();
        ActivityMetric.Visibility = knownActivity.Count == 0 ? Visibility.Collapsed : Visibility.Visible;
        ActivityMetric.Text = knownActivity.Count == 0 ? string.Empty : knownActivity[0].Activity!.Value.ToLocalTime().ToString("d MMM yyyy", DateCulture());
        ActivityText.Text = knownActivity.Count == 0 ? Strings.Tr("Sem atividade disponível.") : knownActivity[0].Title;

        GalleryPanel.Children.Clear();
        GallerySection.Visibility = Visibility.Collapsed;
        GalleryColumnA.Width = GalleryColumnB.Width = new GridLength(0);

        var allValid = LagCheck.WinUI.History.SessionHistoryServices.Store.Entries
            .Where(entry => IsConclusiveVerdict(entry.Verdict) && entry.PingMs is { } ping && double.IsFinite(ping) && ping >= 0 && ping <= 10_000)
            .ToList();
        var timestamped = allValid.Where(entry => entry.HasCapturedAt).OrderBy(entry => entry.CapturedAt).ToList();
        StabilityPlot.Children.Clear();
        StabilityMetric.Visibility = allValid.Count == 0 ? Visibility.Collapsed : Visibility.Visible;
        StabilityMetric.Text = allValid.Count == 0 ? string.Empty : (timestamped.Count > 0 ? timestamped[^1] : allValid[0]).PingLabel;
        if (allValid.Count == 0)
        {
            StabilityPlot.Visibility = Visibility.Collapsed;
            StabilityText.Text = Strings.Tr("Sem medições válidas ainda.");
            return;
        }

        var withoutTimestamp = allValid.Count - timestamped.Count;
        var note = withoutTimestamp > 0 ? "\n" + Strings.Format("{0} medições sem data confiável.", withoutTimestamp) : string.Empty;
        if (timestamped.Count < 2)
        {
            StabilityPlot.Visibility = Visibility.Collapsed;
            StabilityText.Text = note.TrimStart('\n');
            return;
        }

        StabilityText.Text = Strings.Tr("Pings de medições distintas; não é monitoramento ao vivo.") + note;
        StabilityPlot.Visibility = Visibility.Visible;
        var values = timestamped.Select(entry => entry.PingMs!.Value).ToArray();
        var min = values.Min(); var range = Math.Max(values.Max() - min, 1d);
        for (var i = 0; i < values.Length; i++)
        {
            var point = new Ellipse { Width = 6, Height = 6, Fill = new SolidColorBrush(Color.FromArgb(255, 0xA7, 0x8B, 0xFA)) };
            Canvas.SetLeft(point, i * 196d / (values.Length - 1));
            Canvas.SetTop(point, 41 - (values[i] - min) / range * 34);
            StabilityPlot.Children.Add(point);
        }
    }

    private async System.Threading.Tasks.Task LoadPlatformStatusAsync()
    {
        var snapshot = await _platformStatus.GetSnapshotAsync();
        DispatcherQueue.TryEnqueue(() =>
        {
            _lastPlatformStatus = snapshot;
            RenderPlatformStatus(snapshot);
        });
    }

    private void Widget_PointerEntered(object sender, PointerRoutedEventArgs e)
    {
        if (sender is Border widget) widget.Background = new SolidColorBrush(Color.FromArgb(0xF2, 0x35, 0x3C, 0x4D));
    }

    private void Widget_PointerExited(object sender, PointerRoutedEventArgs e)
    {
        if (sender is Border widget) widget.ClearValue(Border.BackgroundProperty);
    }

    private void RenderPlatformStatus(PlatformStatusSnapshot snapshot)
    {
        var stale = DateTimeOffset.UtcNow - snapshot.RetrievedAt > TimeSpan.FromMinutes(5);
        var unavailable = snapshot.Availability is PlatformStatusAvailability.Stale or PlatformStatusAvailability.Unavailable || stale;
        var platforms = _pcSelected
            ? snapshot.Platforms.Where(platform => platform.Id is "steam" or "epicgames" or "xbox")
            : snapshot.Platforms;
        PlatformRows.Children.Clear();
        foreach (var platform in platforms)
        {
            var state = unavailable ? PlatformServiceState.Unknown : platform.State;
            var tile = new Grid { Width = 34, Height = 38 };
            var logoPath = platform.Id switch { "steam" => Glyphs.Steam, "epicgames" => Glyphs.Epic, "xbox" => Glyphs.Xbox, _ => null };
            if (logoPath is not null)
                tile.Children.Add(new SvgIcon { Data = logoPath, Size = 23, FillOnly = true, Foreground = (Brush)Application.Current.Resources["TextPrimaryBrush"], VerticalAlignment = VerticalAlignment.Center, HorizontalAlignment = HorizontalAlignment.Center });
            else
                tile.Children.Add(new TextBlock { Text = platform.Id == "playstation" ? "PSN" : "N", FontSize = 12, FontWeight = Microsoft.UI.Text.FontWeights.SemiBold, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center });
            var marker = new TextBlock { Text = state switch
            {
                PlatformServiceState.Operational => "●",
                PlatformServiceState.Degraded => "▲",
                PlatformServiceState.Outage => "×",
                _ => "?",
            }, FontSize = 12, FontWeight = Microsoft.UI.Text.FontWeights.Bold, HorizontalAlignment = HorizontalAlignment.Right, VerticalAlignment = VerticalAlignment.Bottom, Foreground = new SolidColorBrush(state switch
            {
                PlatformServiceState.Operational => Color.FromArgb(255, 0x22, 0xC5, 0x5E),
                PlatformServiceState.Degraded => Color.FromArgb(255, 0xFF, 0xC0, 0x4D),
                PlatformServiceState.Outage => Color.FromArgb(255, 0xFF, 0x79, 0x5D),
                _ => Color.FromArgb(255, 0xCF, 0xD4, 0xDF),
            }) };
            tile.Children.Add(marker);
            var description = $"{PlatformDisplayName(platform.Id)}: {PlatformStateLabel(state)}" + (!unavailable && platform.CheckedAt is { } checkedAt ? $" · {checkedAt.ToLocalTime():HH:mm}" : string.Empty);
            Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(tile, description);
            ToolTipService.SetToolTip(tile, description);
            PlatformRows.Children.Add(tile);
        }
        PlatformStatusText.Text = unavailable
            ? Strings.Tr(snapshot.Availability == PlatformStatusAvailability.Stale || stale ? "Status desatualizado" : "Status indisponível")
            : Strings.Tr("Consulta do site; não cobre todos os serviços da plataforma.");
        ToolTipService.SetToolTip(PlatformStatusText, PlatformStatusText.Text);
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(PlatformRows, string.Join("; ", platforms.Select(platform => $"{PlatformDisplayName(platform.Id)}: {PlatformStateLabel(unavailable ? PlatformServiceState.Unknown : platform.State)}")));
    }

    private static string PlatformDisplayName(string id) => id switch
    {
        "playstation" => "PSN",
        "xbox" => "Xbox",
        "steam" => "Steam API",
        "epicgames" => "Epic Games",
        "nintendo" => "Nintendo",
        _ => id,
    };

    private static DateTimeOffset? ValidEpoch(long? epoch)
    {
        if (epoch is not { } value || value <= 0) return null;
        try { return DateTimeOffset.FromUnixTimeMilliseconds(value); }
        catch (ArgumentOutOfRangeException) { return null; }
    }

    private static CultureInfo DateCulture() => LocalizationService.Instance.EffectiveLanguage switch
    {
        AppLanguage.En => CultureInfo.GetCultureInfo("en-US"),
        AppLanguage.Es => CultureInfo.GetCultureInfo("es-ES"),
        _ => CultureInfo.GetCultureInfo("pt-BR"),
    };

    private void BuildActivityCalendar(DateTimeOffset? activity)
    {
        ActivityCalendar.Children.Clear();
        ActivityCalendar.ColumnDefinitions.Clear();
        ActivityCalendar.RowDefinitions.Clear();
        if (activity is not { } observed || observed.ToLocalTime().Year != DateTime.Now.Year || observed.ToLocalTime().Month != DateTime.Now.Month)
        {
            ActivityCalendar.Visibility = Visibility.Collapsed;
            return;
        }
        ActivityCalendar.Visibility = Visibility.Visible;
        for (var column = 0; column < 7; column++) ActivityCalendar.ColumnDefinitions.Add(new ColumnDefinition());
        for (var row = 0; row < 6; row++) ActivityCalendar.RowDefinitions.Add(new RowDefinition());
        var first = new DateTime(DateTime.Now.Year, DateTime.Now.Month, 1);
        var offset = ((int)first.DayOfWeek + 6) % 7;
        for (var day = 1; day <= DateTime.DaysInMonth(first.Year, first.Month); day++)
        {
            var cell = new Border { Margin = new Thickness(1), CornerRadius = new CornerRadius(2), Background = new SolidColorBrush(day == observed.LocalDateTime.Day ? Color.FromArgb(255, 0x7C, 0x3A, 0xED) : Color.FromArgb(255, 0x1C, 0x21, 0x2B)) };
            Grid.SetColumn(cell, (offset + day - 1) % 7); Grid.SetRow(cell, (offset + day - 1) / 7);
            ActivityCalendar.Children.Add(cell);
        }
    }

    private static string PlatformStateLabel(PlatformServiceState state) => state switch
    {
        PlatformServiceState.Operational => Strings.Tr("Operacional"),
        PlatformServiceState.Degraded => Strings.Tr("Degradado"),
        PlatformServiceState.Outage => Strings.Tr("Indisponível"),
        _ => Strings.Tr("Não verificado"),
    };

    private void OpenSearch_Click(object sender, RoutedEventArgs e) => ShellChrome.Shell?.OpenQuickSearch();
    private void OpenGallery_Click(object sender, RoutedEventArgs e) => ShellChrome.Shell?.NavigateToGallery();
    private void OpenHistory_Click(object sender, RoutedEventArgs e) => ShellChrome.Shell?.Navigate(NavigationRoute.History);
    private void OpenSettings_Click(object sender, RoutedEventArgs e) => ShellChrome.Shell?.Navigate(NavigationRoute.Settings);

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
