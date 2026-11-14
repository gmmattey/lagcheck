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

    public LibraryViewModel ViewModel { get; }

    private readonly NotifyCollectionChangedEventHandler _historyChangedHandler;
    private string? _selectedId;
    private List<string> _slides = new();
    private bool _refreshQueued;
    private bool _wired;
    private int _loadGeneration;
    private readonly List<RecentTile> _tiles = new();
    private Storyboard? _selectionTransition;
    private bool _canLaunch;
    private bool _launchHovered;
    private readonly PlatformStatusClient _platformStatus = new();
    private PlatformStatusSnapshot? _lastPlatformStatus;
    private bool _pcSelected;
    private bool _dataReady;
    private string _recentsKey = string.Empty;
    private bool _historyButtonStartsTest;
    private RecentTile? _pcTile;

    /// <summary>Slot fixo no layout: selecionado/repouso é só escala de composição, então nada reflui ao trocar de jogo.</summary>
    private sealed class RecentTile
    {
        public LibraryGame? Game;
        public Button Tile = null!;
        public Border Ring = null!;
        public bool Hovered;
    }

    public HomePage()
    {
        InitializeComponent();
        ViewModel = new LibraryViewModel(LibraryPageServices.Bridge, LibraryPageServices.DiagnosticNavigator);
        DataContext = ViewModel;
        GlowEffect.Attach(LaunchGlow, Color.FromArgb(0xA8, 0x7C, 0x3A, 0xED), 24);
        LaunchBtn.PointerEntered += (_, _) => { _launchHovered = true; UpdateLaunchChrome(); };
        LaunchBtn.PointerExited += (_, _) => { _launchHovered = false; UpdateLaunchChrome(); };
        LocalizeUI();
        foreach (var button in new[] { LaunchBtn, CheckConnBtn, FavBtn, DetailsBtn, TopLibraryBtn, TopHistoryBtn, TopSearchBtn, TopGalleryBtn, TopSettingsBtn, PcCheckBtn, GeneralCheckBtn, ScanGamesBtn, OpenHistoryBtn })
            Fluid.Feedback(button);

        _historyChangedHandler = (_, _) => QueueRefresh();
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

    private void OnLanguageChanged() => DispatcherQueue.TryEnqueue(() => { if (IsLoaded) { LocalizeUI(); Refresh(); } });

    private void LocalizeUI()
    {
        LaunchBtnText.Text = Strings.Tr("JOGAR AGORA");
        ActivityTitle.Text = Strings.Tr("ÚLTIMA ATIVIDADE");
        StabilityTitle.Text = Strings.Tr("HISTÓRICO DE TESTES");
        PlatformsTitle.Text = Strings.Tr("STATUS DAS PLATAFORMAS");
        GalleryTitle.Text = Strings.Tr("Galeria local");
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(TopSearchBtn, Strings.Tr("Buscar jogo..."));
        ToolTipService.SetToolTip(TopSearchBtn, Strings.Tr("Buscar jogo (Ctrl+F)"));
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(TopLibraryBtn, Strings.Tr("Biblioteca"));
        ToolTipService.SetToolTip(TopLibraryBtn, Strings.Tr("Biblioteca"));
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(TopHistoryBtn, Strings.Tr("Histórico"));
        ToolTipService.SetToolTip(TopHistoryBtn, Strings.Tr("Histórico"));
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(DetailsBtn, Strings.Tr("Detalhes do jogo"));
        ToolTipService.SetToolTip(DetailsBtn, Strings.Tr("Detalhes do jogo"));
        StabilityMetricCaption.Text = Strings.Tr("ÚLTIMO PING");
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(TopGalleryBtn, Strings.Tr("Galeria local"));
        ToolTipService.SetToolTip(TopGalleryBtn, Strings.Tr("Galeria local"));
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(TopSettingsBtn, Strings.Tr("Ajustes"));
        ToolTipService.SetToolTip(TopSettingsBtn, Strings.Tr("Ajustes"));
        PcPlatformText.Text = Strings.Tr("ESTE PC");
        PcHeroTitle.Text = Strings.Tr("SEU PC");
        PcHeroDescription.Text = Strings.Tr("Leituras da sua conexão e da atividade conhecida na biblioteca local.");
        PcCheckBtn.Content = Strings.Tr("Testar conexão geral");
        UpdateHistoryButton();
        if (_lastPlatformStatus is null) PlatformStatusText.Text = Strings.Tr("Consultando…");
        else RenderPlatformStatus(_lastPlatformStatus);
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(LaunchBtn, Strings.Tr("Iniciar jogo instalado"));
        CheckConnBtn.Content = Strings.Tr("Testar conexão");
        ToolTipService.SetToolTip(LaunchBtn, Strings.Tr("Iniciar jogo instalado"));
        ToolTipService.SetToolTip(CheckConnBtn, Strings.Tr("Avaliar rota e estabilidade pré-partida"));

        CockpitEyebrow.Text = Strings.Tr("PRONTO PARA JOGAR?");
        EmptyHeroTitle.Text = Strings.Tr("NENHUM JOGO LOCAL ENCONTRADO");
        EmptyHeroDesc.Text = Strings.Tr("O LagCheck monitora seus jogos instalados (Steam, Epic, Xbox) ou sua rota geral.");
        ScanGamesBtn.Content = Strings.Tr("Procurar jogos instalados");
        GeneralCheckBtn.Content = Strings.Tr("Testar conexão geral");
    }

    private async void HomePage_Loaded(object sender, RoutedEventArgs e)
    {
        // A página fica em cache de navegação; reaplica o idioma ao voltar de Ajustes.
        var generation = ++_loadGeneration;
        LocalizeUI();
        Wire();
        Refresh();
        _ = LoadPlatformStatusAsync(generation);
        await ViewModel.LoadAsync();
        if (!IsCurrentLoad(generation)) return;
        _dataReady = true;
        await LagCheck.WinUI.History.SessionHistoryServices.Store.TryRefreshAsync(Diagnostic.WinUiEngineComposition.Client);
        if (!IsCurrentLoad(generation)) return;
        Refresh();
        var visible = Recents().ToList();
        if (CurrentHero() is { } current && visible.All(game => game.Id != current.Id)) visible.Add(current);
        await Artwork.ResolveMissingAsync(ViewModel, visible);
        if (!IsCurrentLoad(generation)) return;
        Refresh();
    }

    private void HomePage_Unloaded(object sender, RoutedEventArgs e)
    {
        ++_loadGeneration;
        _selectionTransition?.Stop();
        GameHeroPanel.Opacity = PcHeroPanel.Opacity = InsightsScroll.Opacity = 1;
        _backdropApplied = false;
        Unwire();
    }

    private bool IsCurrentLoad(int generation) => IsLoaded && generation == _loadGeneration;

    private void HomePage_SizeChanged(object sender, SizeChangedEventArgs e) => ApplyViewportSizing();

    private void QueueRefresh()
    {
        if (_refreshQueued) return;
        _refreshQueued = true;
        DispatcherQueue.TryEnqueue(() =>
        {
            _refreshQueued = false;
            if (IsLoaded) Refresh();
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
        ApplyResponsiveLayout();
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
        EnsureRecents();
    }

    private void ApplyResponsiveLayout()
    {
        // Largura que o hero (620) + a grade de widgets (4 ou 6 colunas de 112) pedem; abaixo disso os widgets descem.
        var insightColumns = GallerySection.Visibility == Visibility.Visible ? 6 : 4;
        var needed = 620 + 14 + 48 + insightColumns * 112 + (insightColumns - 1) * 12;
        var compact = ActualWidth < needed;
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
        if (!_pcSelected && _selectedId == id) return;
        _pcSelected = false;
        _selectedId = id;
        Refresh(rebuildRecents: false);
        FadeHero();
        UpdateRecentSelection(animate: true);
    }

    private void FadeHero()
    {
        _selectionTransition?.Stop();
        GameHeroPanel.Opacity = PcHeroPanel.Opacity = InsightsScroll.Opacity = 1;
        if (Motion.Reduced) return;
        var storyboard = new Storyboard();
        foreach (var target in new UIElement[] { _pcSelected ? PcHeroPanel : GameHeroPanel, InsightsScroll })
        {
            var fade = new DoubleAnimation { From = 0, To = 1, Duration = TimeSpan.FromMilliseconds(300), EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut } };
            Storyboard.SetTarget(fade, target);
            Storyboard.SetTargetProperty(fade, "Opacity");
            storyboard.Children.Add(fade);
        }
        _selectionTransition = storyboard;
        storyboard.Begin();
    }

    private void SelectPc()
    {
        if (_pcSelected) return;
        _pcSelected = true;
        _selectedId = null;
        Refresh(rebuildRecents: false);
        FadeHero();
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
            StabilityTitle.Text = Strings.Tr("HISTÓRICO DE TESTES");
            HistoryColumnA.Width = HistoryColumnB.Width = new GridLength(112);
            GalleryColumnA.Width = GalleryColumnB.Width = new GridLength(0);
            _slides.Clear();
            _backdropApplied = false;
            ShellChrome.Shell?.ClearBackdrop();
            if (_lastPlatformStatus is not null) RenderPlatformStatus(_lastPlatformStatus);
            BuildPcInsights();
            if (rebuildRecents) ApplyViewportSizing();
            else ApplyHeroSizing();
            return;
        }

        var hero = CurrentHero();
        if (hero is null && !_dataReady)
        {
            // Biblioteca ainda carregando: sem "nenhum jogo encontrado" piscando antes da hora.
            GameHeroPanel.Visibility = PcHeroPanel.Visibility = EmptyHeroPanel.Visibility = Visibility.Collapsed;
            ActivityCard.Visibility = StabilityCard.Visibility = GallerySection.Visibility = Visibility.Collapsed;
            return;
        }
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
            _slides.Clear();
            _backdropApplied = false;
            ShellChrome.Shell?.ClearBackdrop();
            if (rebuildRecents) EnsureRecents();
            return;
        }

        _selectedId = hero.Id;
        _pcSelected = false;
        GameHeroPanel.Visibility = Visibility.Visible;
        PcHeroPanel.Visibility = Visibility.Collapsed;
        EmptyHeroPanel.Visibility = Visibility.Collapsed;
        ActivityCard.Visibility = Visibility.Visible;
        StabilityCard.Visibility = Visibility.Visible;
        StabilityTitle.Text = Strings.Tr("HISTÓRICO DE TESTES");
        HistoryColumnA.Width = HistoryColumnB.Width = new GridLength(112);
        if (_lastPlatformStatus is not null) RenderPlatformStatus(_lastPlatformStatus);

        GameTitleText.Text = hero.Title.ToUpperInvariant();
        GameMetaText.Text = string.Join(" · ", new[] { hero.PlatformLabel, hero.Info?.Genres.FirstOrDefault(), hero.NetworkLabel }.Where(value => !string.IsNullOrWhiteSpace(value)));
        GameMetaPill.Visibility = string.IsNullOrWhiteSpace(GameMetaText.Text) ? Visibility.Collapsed : Visibility.Visible;
        ApplyPlatform(hero);
        ApplyVerdict(hero);

        CheckConnBtn.Visibility = hero.CanTestConnection ? Visibility.Visible : Visibility.Collapsed;
        _canLaunch = hero.IsInstalled && hero.IsLaunchable;
        LaunchBtn.IsEnabled = _canLaunch;
        UpdateLaunchChrome();
        FavIcon.IsFilled = hero.IsFavorite;
        FavIcon.Foreground = hero.IsFavorite ? (Brush)Application.Current.Resources["CoralBrush"] : (Brush)Application.Current.Resources["TextPrimaryBrush"];
        ToolTipService.SetToolTip(FavBtn, hero.FavoriteActionLabel);
        DetailsBtn.Visibility = Visibility.Visible;

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

    /// <summary>Arte horizontal existente do jogo (uma só: o fundo não gira sozinho).</summary>
    private static List<string> ArtsOf(LibraryGame game) => Artwork.FirstExisting(game.HeroArtworkPath) is { } path ? new List<string> { path } : new List<string>();

    private void SetSlides(IReadOnlyList<string> images)
    {
        if (images.Count == 0)
        {
            _slides.Clear();
            _backdropApplied = false;
            ShellChrome.Shell?.ClearBackdrop();
            return;
        }

        var changed = !images.SequenceEqual(_slides);
        _slides = images.ToList();
        if (changed || ShellChrome.Shell is { } && !_backdropApplied)
        {
            ShellChrome.Shell?.SetBackdrop(_slides, BackdropKind.Hero, 0);
            _backdropApplied = true;
        }
    }

    private bool _backdropApplied;

    // ------------------------------------------------------------------ recentes

    // Slot fixo de 96x138; o tile em repouso é desenhado a 0,875 (84x121) por escala de composição.
    private const double SlotW = 96, SlotH = 138, RestScale = 0.875;

    private string ComputeRecentsKey() => string.Join("|", Recents().Select(game => game.Id + ":" + (Artwork.FirstExisting(game.CoverArtworkPath) ?? "-")));

    /// <summary>Só reconstrói os tiles quando a fila ou as capas mudam; redimensionar a janela ou chegar histórico não os recria.</summary>
    private void EnsureRecents()
    {
        var key = ComputeRecentsKey();
        if (_tiles.Count == 0 && _pcTile is null || key != _recentsKey)
        {
            _recentsKey = key;
            BuildRecents();
        }
        else UpdateRecentSelection(animate: false);
    }

    private (float Scale, float Y) PoseOf(RecentTile item, bool selected)
    {
        var scale = (float)((selected ? 1.0 : RestScale) * (item.Hovered ? 1.03 : 1.0));
        // Ancora a base do tile: escalar pelo centro moveria a borda inferior.
        var y = (float)(SlotH * (1 - scale) / 2) + (item.Hovered ? -4f : 0f);
        return (scale, y);
    }

    private void ApplyPose(RecentTile item, bool selected)
    {
        var (scale, y) = PoseOf(item, selected);
        Fluid.SetPose(item.Tile, scale, y);
    }

    private RecentTile MakeTile(UIElement face, string name, bool selected, LibraryGame? game)
    {
        var tile = new Grid { Width = SlotW, Height = SlotH };
        var clip = new Border { CornerRadius = new CornerRadius(8), Background = new SolidColorBrush(Color.FromArgb(255, 0x17, 0x1B, 0x24)), Child = face };
        tile.Children.Add(clip);
        tile.Children.Add(new Border { CornerRadius = new CornerRadius(8), BorderThickness = new Thickness(1), BorderBrush = new SolidColorBrush(Color.FromArgb(0x1F, 255, 255, 255)), IsHitTestVisible = false });
        var ring = new Border
        {
            CornerRadius = new CornerRadius(10),
            BorderThickness = new Thickness(2),
            BorderBrush = new SolidColorBrush(Color.FromArgb(255, 0xA7, 0x8B, 0xFA)),
            Margin = new Thickness(-2),
            Opacity = selected ? 1 : 0,
            IsHitTestVisible = false,
            OpacityTransition = Motion.Reduced ? null : new ScalarTransition { Duration = TimeSpan.FromMilliseconds(220) },
        };
        tile.Children.Add(ring);
        var button = new Button
        {
            Width = SlotW,
            Height = SlotH,
            Padding = new Thickness(0),
            BorderThickness = new Thickness(0),
            Background = new SolidColorBrush(Colors.Transparent),
            Content = tile,
            VerticalAlignment = VerticalAlignment.Bottom,
        };
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(button, name);
        ToolTipService.SetToolTip(button, game is null ? name : name + " · " + Strings.Tr("duplo clique para detalhes"));
        Fluid.Prepare(button);
        var item = new RecentTile { Game = game, Tile = button, Ring = ring };
        button.PointerEntered += (_, _) => { item.Hovered = true; ApplyPose(item, IsSelected(item)); };
        button.PointerExited += (_, _) => { item.Hovered = false; ApplyPose(item, IsSelected(item)); };
        ApplyPose(item, selected);
        return item;
    }

    private bool IsSelected(RecentTile item) => item.Game is null ? _pcSelected : !_pcSelected && item.Game.Id == _selectedId;

    private void BuildRecents()
    {
        RecentsPanel.Children.Clear();
        _tiles.Clear();
        var hero = CurrentHero();

        var pcFace = new Grid();
        pcFace.Children.Add(new StripedBackground { Band = 14 });
        pcFace.Children.Add(new SvgIcon
        {
            Data = "M5 4h14a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2zM8 20h8M12 16v4",
            Size = 30,
            Foreground = (Brush)Application.Current.Resources["TextPrimaryBrush"],
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        });
        _pcTile = MakeTile(pcFace, Strings.Tr("Este PC"), _pcSelected, null);
        _pcTile.Tile.Click += (_, _) => SelectPc();
        RecentsPanel.Children.Add(_pcTile.Tile);

        foreach (var game in Recents())
        {
            var selected = !_pcSelected && hero is not null && game.Id == hero.Id;
            var face = new Grid();
            face.Children.Add(new StripedBackground { Band = 14 });
            if (Artwork.Load(Artwork.FirstExisting(game.CoverArtworkPath), 280) is { } cover)
                face.Children.Add(new Image { Source = cover, Stretch = Stretch.UniformToFill });
            var item = MakeTile(face, game.Title, selected, game);
            var id = game.Id;
            item.Tile.Click += (_, _) => SelectRecent(id);
            item.Tile.DoubleTapped += (_, _) => OpenDetails(game);
            _tiles.Add(item);
            RecentsPanel.Children.Add(item.Tile);
        }
    }

    /// <summary>Atualiza só o anel e a pose (escala) dos tiles existentes; nenhum layout muda.</summary>
    private void UpdateRecentSelection(bool animate)
    {
        foreach (var item in _tiles.Prepend(_pcTile).OfType<RecentTile>())
        {
            var selected = IsSelected(item);
            item.Ring.OpacityTransition = Motion.Reduced || !animate ? null : new ScalarTransition { Duration = TimeSpan.FromMilliseconds(180) };
            item.Ring.Opacity = selected ? 1 : 0;
            ApplyPose(item, selected);
        }
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
        ActivityText.Text = activity is null ? Strings.Tr("Sem atividade disponível.") : Strings.Tr("Último uso registrado pelo launcher.");
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
        StabilityMetric.Visibility = StabilityMetricCaption.Visibility = checks.Count == 0 ? Visibility.Collapsed : Visibility.Visible;
        StabilityMetric.Text = checks.Count == 0 ? string.Empty : checks[^1].PingLabel;
        _historyButtonStartsTest = checks.Count == 0 && game.CanTestConnection;
        if (checks.Count == 0) StabilityText.Text = Strings.Tr("Nenhum teste válido deste jogo ainda.");
        else if (checks.Count == 1) StabilityText.Text = string.Empty;
        else StabilityText.Text = Strings.Tr("Pings de testes distintos; não é monitoramento ao vivo.");
        DrawPlot(checks.Select(entry => (entry.PingMs!.Value, $"{entry.PingLabel} · {entry.CapturedAt.ToLocalTime():d MMM HH:mm}")).ToList());
        UpdateHistoryButton();
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
        StabilityMetric.Visibility = StabilityMetricCaption.Visibility = allValid.Count == 0 ? Visibility.Collapsed : Visibility.Visible;
        StabilityMetric.Text = allValid.Count == 0 ? string.Empty : (timestamped.Count > 0 ? timestamped[^1] : allValid[0]).PingLabel;
        _historyButtonStartsTest = allValid.Count == 0;
        UpdateHistoryButton();
        if (allValid.Count == 0)
        {
            DrawPlot(new List<(double, string)>());
            StabilityText.Text = Strings.Tr("Nenhum teste válido ainda.");
            return;
        }

        var withoutTimestamp = allValid.Count - timestamped.Count;
        var note = withoutTimestamp > 0 ? "\n" + Strings.Format("{0} medições sem data confiável.", withoutTimestamp) : string.Empty;
        if (timestamped.Count < 2)
        {
            DrawPlot(new List<(double, string)>());
            StabilityText.Text = note.TrimStart('\n');
            return;
        }

        StabilityText.Text = Strings.Tr("Pings de testes distintos; não é monitoramento ao vivo.") + note;
        DrawPlot(timestamped.Select(entry => (entry.PingMs!.Value, $"{entry.PingLabel} · {entry.CapturedAt.ToLocalTime():d MMM HH:mm}")).ToList());
    }

    /// <summary>Linha + pontos dos pings (largura do card), com a leitura e a data de cada ponto no tooltip.</summary>
    private void DrawPlot(IReadOnlyList<(double Ping, string Tip)> points)
    {
        StabilityPlot.Children.Clear();
        if (points.Count < 2) { StabilityPlot.Visibility = Visibility.Collapsed; return; }
        StabilityPlot.Visibility = Visibility.Visible;
        var width = StabilityPlot.ActualWidth > 40 ? StabilityPlot.ActualWidth : 196;
        var min = points.Min(point => point.Ping);
        var range = Math.Max(points.Max(point => point.Ping) - min, 1d);
        var purple = Color.FromArgb(255, 0xA7, 0x8B, 0xFA);
        var line = new Polyline { Stroke = new SolidColorBrush(Color.FromArgb(0x99, 0xA7, 0x8B, 0xFA)), StrokeThickness = 1.5, StrokeLineJoin = PenLineJoin.Round };
        var coordinates = new List<(double X, double Y)>();
        for (var i = 0; i < points.Count; i++)
        {
            var x = 3 + i * (width - 6) / (points.Count - 1);
            var y = 41 - (points[i].Ping - min) / range * 34;
            coordinates.Add((x, y));
            line.Points.Add(new Windows.Foundation.Point(x, y));
        }
        StabilityPlot.Children.Add(line);
        for (var i = 0; i < points.Count; i++)
        {
            var last = i == points.Count - 1;
            var size = last ? 9 : 6;
            var dot = new Ellipse { Width = size, Height = size, Fill = new SolidColorBrush(last ? Colors.White : purple) };
            ToolTipService.SetToolTip(dot, points[i].Tip);
            Canvas.SetLeft(dot, coordinates[i].X - size / 2.0);
            Canvas.SetTop(dot, coordinates[i].Y - size / 2.0);
            StabilityPlot.Children.Add(dot);
        }
    }

    private void UpdateHistoryButton()
    {
        OpenHistoryBtn.Content = Strings.Tr(_historyButtonStartsTest ? "Fazer o primeiro teste" : "Ver histórico");
    }

    private async System.Threading.Tasks.Task LoadPlatformStatusAsync(int generation)
    {
        var snapshot = await _platformStatus.GetSnapshotAsync();
        DispatcherQueue.TryEnqueue(() =>
        {
            if (!IsCurrentLoad(generation)) return;
            _lastPlatformStatus = snapshot;
            RenderPlatformStatus(snapshot);
        });
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

    private static string PlatformStateLabel(PlatformServiceState state) => state switch
    {
        PlatformServiceState.Operational => Strings.Tr("Operacional"),
        PlatformServiceState.Degraded => Strings.Tr("Degradado"),
        PlatformServiceState.Outage => Strings.Tr("Indisponível"),
        _ => Strings.Tr("Não verificado"),
    };

    private void OpenSearch_Click(object sender, RoutedEventArgs e) => ShellChrome.Shell?.OpenQuickSearch();
    private void OpenGallery_Click(object sender, RoutedEventArgs e) => ShellChrome.Shell?.NavigateToGallery();
    private void OpenLibrary_Click(object sender, RoutedEventArgs e) => ShellChrome.Shell?.Navigate(NavigationRoute.Library);
    private void OpenHistory_Click(object sender, RoutedEventArgs e) => ShellChrome.Shell?.Navigate(NavigationRoute.History);
    private void OpenDetails_Click(object sender, RoutedEventArgs e) { if (CurrentHero() is { } game) OpenDetails(game); }

    private void HistoryWidget_Click(object sender, RoutedEventArgs e)
    {
        if (!_historyButtonStartsTest) { OpenHistory_Click(sender, e); return; }
        if (!_pcSelected && CurrentHero() is { CanTestConnection: true } game) ShellNavigation.NavigateToDiagnostic(game.DiagnosticGameId, game.Title);
        else ShellNavigation.NavigateToDiagnostic(null, null);
    }
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
