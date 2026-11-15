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
using LagCheck.WinUI.Widgets;

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
    private bool _platformsLoading;
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
        foreach (var button in new[] { LaunchBtn, CheckConnBtn, FavBtn, DetailsBtn, TopLibraryBtn, TopHistoryBtn, TopSearchBtn, TopGalleryBtn, TopSettingsBtn, PcCheckBtn, GeneralCheckBtn, ScanGamesBtn })
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
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(TopSearchBtn, Strings.Tr("Buscar jogo..."));
        ToolTipService.SetToolTip(TopSearchBtn, Strings.Tr("Buscar jogo (Ctrl+F)"));
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(TopLibraryBtn, Strings.Tr("Biblioteca"));
        ToolTipService.SetToolTip(TopLibraryBtn, Strings.Tr("Biblioteca"));
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(TopHistoryBtn, Strings.Tr("Histórico"));
        ToolTipService.SetToolTip(TopHistoryBtn, Strings.Tr("Histórico"));
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(DetailsBtn, Strings.Tr("Detalhes do jogo"));
        ToolTipService.SetToolTip(DetailsBtn, Strings.Tr("Detalhes do jogo"));
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(TopGalleryBtn, Strings.Tr("Galeria local"));
        ToolTipService.SetToolTip(TopGalleryBtn, Strings.Tr("Galeria local"));
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(TopSettingsBtn, Strings.Tr("Ajustes"));
        ToolTipService.SetToolTip(TopSettingsBtn, Strings.Tr("Ajustes"));
        PcPlatformText.Text = Strings.Tr("ESTE PC");
        PcHeroTitle.Text = Strings.Tr("SEU PC");
        PcHeroDescription.Text = Strings.Tr("Leituras da sua conexão e da atividade conhecida na biblioteca local.");
        PcCheckBtn.Content = Strings.Tr("Testar conexão geral");
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
        // O hero (620) pede ao menos 4 colunas de widgets ao lado; abaixo disso a grade desce para baixo do hero.
        var needed = 620 + 14 + 48 + 4 * 112 + 3 * 12;
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
        Widgets.SetGridAlignment(compact ? HorizontalAlignment.Left : HorizontalAlignment.Right);
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
        // Texto do herói sobe com suavidade; os widgets só "respiram" (a arte do fundo já faz o próprio crossfade).
        Choreo.FadeSlideIn(_pcSelected ? PcHeroPanel : GameHeroPanel, Choreo.Base, 12);
        Choreo.Refresh(InsightsScroll, 0.55f, Choreo.Base);
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
            _slides.Clear();
            _backdropApplied = false;
            ShellChrome.Shell?.ClearBackdrop();
            UpdateWidgets();
            if (rebuildRecents) ApplyViewportSizing();
            else ApplyHeroSizing();
            return;
        }

        var hero = CurrentHero();
        if (hero is null && !_dataReady)
        {
            // Biblioteca ainda carregando: sem "nenhum jogo encontrado" piscando antes da hora.
            GameHeroPanel.Visibility = PcHeroPanel.Visibility = EmptyHeroPanel.Visibility = Visibility.Collapsed;
            return;
        }
        if (hero is null)
        {
            GameHeroPanel.Visibility = Visibility.Collapsed;
            PcHeroPanel.Visibility = Visibility.Collapsed;
            EmptyHeroPanel.Visibility = Visibility.Visible;
            HeroVerdictPanel.Visibility = Visibility.Collapsed;
            _slides.Clear();
            _backdropApplied = false;
            ShellChrome.Shell?.ClearBackdrop();
            UpdateWidgets();
            if (rebuildRecents) EnsureRecents();
            return;
        }

        _selectedId = hero.Id;
        _pcSelected = false;
        GameHeroPanel.Visibility = Visibility.Visible;
        PcHeroPanel.Visibility = Visibility.Collapsed;
        EmptyHeroPanel.Visibility = Visibility.Collapsed;

        GameTitleText.Text = hero.Title.ToUpperInvariant();
        GamePillsHost.Child = GamePills.Create(hero);
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
        UpdateWidgets();
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
            Choreo.FadeTo(item.Ring, selected ? 1 : 0, animate ? Choreo.Fast : 0);
            ApplyPose(item, selected);
        }
    }

    private void OpenDetails(LibraryGame game)
    {
        if (ViewModel.SelectGameCommand.CanExecute(game)) ViewModel.SelectGameCommand.Execute(game);
        ShellNavigation.OpenGameDetails(game, NavigationRoute.Home);
    }

    // ------------------------------------------------------------------ ações

    private async System.Threading.Tasks.Task LoadPlatformStatusAsync(int generation, bool force = false)
    {
        _platformsLoading = true;
        UpdateWidgets();
        PlatformStatusSnapshot snapshot;
        try { snapshot = await _platformStatus.GetSnapshotAsync(force); }
        catch { return; }
        DispatcherQueue.TryEnqueue(() =>
        {
            _platformsLoading = false;
            if (!IsCurrentLoad(generation)) return;
            _lastPlatformStatus = snapshot;
            UpdateWidgets();
        });
    }

    // ------------------------------------------------------------------ widgets

    /// <summary>Entrega ao módulo de widgets o contexto atual (jogo ou Este PC, biblioteca, histórico, plataformas).</summary>
    private void UpdateWidgets()
    {
        if (!IsLoaded && !_dataReady) return;
        var game = _pcSelected ? null : CurrentHero();
        var actions = new WidgetActions(
            OpenDetails: OpenDetails,
            SelectGame: selected => SelectRecent(selected.Id),
            OpenHistory: () => ShellChrome.Shell?.Navigate(NavigationRoute.History),
            OpenGallery: () => ShellChrome.Shell?.NavigateToGallery(),
            TestConnection: (id, title) => ShellNavigation.NavigateToDiagnostic(id, title),
            RefreshPlatforms: () => _ = LoadPlatformStatusAsync(_loadGeneration, force: true));
        Widgets.Update(new WidgetContext(
            game,
            game is null,
            ViewModel.AllGames.ToList(),
            LagCheck.WinUI.History.SessionHistoryServices.Store.Entries.ToList(),
            _lastPlatformStatus,
            _platformsLoading,
            actions));
    }

    private void OpenSearch_Click(object sender, RoutedEventArgs e) => ShellChrome.Shell?.OpenQuickSearch();
    private void OpenGallery_Click(object sender, RoutedEventArgs e) => ShellChrome.Shell?.NavigateToGallery();
    private void OpenLibrary_Click(object sender, RoutedEventArgs e) => ShellChrome.Shell?.Navigate(NavigationRoute.Library);
    private void OpenHistory_Click(object sender, RoutedEventArgs e) => ShellChrome.Shell?.Navigate(NavigationRoute.History);
    private void OpenDetails_Click(object sender, RoutedEventArgs e) { if (CurrentHero() is { } game) OpenDetails(game); }

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
