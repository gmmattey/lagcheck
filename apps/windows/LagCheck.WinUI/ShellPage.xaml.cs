using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Animation;
using Microsoft.UI.Xaml.Media.Imaging;
using Microsoft.UI.Xaml.Navigation;
using Windows.System;
using LagCheck.WinUI.Controls;
using LagCheck.WinUI.Diagnostic;
using LagCheck.WinUI.Library;
using LagCheck.WinUI.Localization;
using LagCheck.WinUI.Pages;
using LagCheck.WinUI.Windowing;

namespace LagCheck.WinUI;

/// <summary>Estilo da arte atrás da janela: capa em destaque do Início ou véu escuro do resultado.</summary>
public enum BackdropKind
{
    Hero,
    Veil,
}

/// <summary>Acesso das páginas à moldura do shell (arte de fundo, toast); o shell continua dono do Frame.</summary>
public static class ShellChrome
{
    private static WeakReference<ShellPage>? _shell;
    internal static void Register(ShellPage shell) => _shell = new WeakReference<ShellPage>(shell);
    public static ShellPage? Shell => _shell is not null && _shell.TryGetTarget(out var shell) ? shell : null;
}

public sealed partial class ShellPage : Page
{
    private bool _navigationLocked;
    private double _stageTop = 56;
    private DispatcherTimer? _toastTimer;
    private NavigationRoute _currentRoute = NavigationRoute.Home;
    private NavigationRoute _returnRoute = NavigationRoute.Home;
    private NavigationRoute _detailsBackRoute = NavigationRoute.Home;
    private LibraryGame? _detailsGame;
    private string? _currentGameTitle;
    private bool _hasBackdrop;
    private int _backdropCount;
    private int _backdropIndex;
    private int _backdropTransitionRevision;
    private Storyboard? _backdropTransitionStoryboard;
    private Storyboard? _wallpaperTransitionStoryboard;

    public ShellPage()
    {
        InitializeComponent();
        WallpaperImage.Source = new BitmapImage
        {
            UriSource = new Uri("ms-appx:///Assets/wallpaper-network.jpg"),
            DecodePixelWidth = 1920
        };
        ShellChrome.Register(this);
        ShellNavigation.Configure(NavigateToDiagnostic, Navigate, OpenGameDetails);
        LocalizeUI();
        ContentFrame.Navigated += ContentFrame_Navigated;
        ContentFrame.NavigationFailed += (_, e) =>
        {
            e.Handled = true;
            ShowToast(Strings.Tr("Não foi possível abrir esta tela agora."));
        };
        RootGrid.SizeChanged += (_, _) => LayoutBackdrop();
        Navigate(NavigationRoute.Home);
        WinUiEngineComposition.Client.SessionActivityChanged += OnSessionActivityChanged;
        LocalizationService.Instance.LanguageChanged += OnLanguageChanged;
        Unloaded += (_, _) =>
        {
            WinUiEngineComposition.Client.SessionActivityChanged -= OnSessionActivityChanged;
            LocalizationService.Instance.LanguageChanged -= OnLanguageChanged;
        };

        // Atalhos globais: Ctrl+F busca, Esc e Alt+← voltam (Esc não rouba o foco de campos de texto), botão "voltar" do mouse também.
        var search = new KeyboardAccelerator { Key = VirtualKey.F, Modifiers = VirtualKeyModifiers.Control };
        search.Invoked += (_, e) => { if (!_navigationLocked) { OpenQuickSearch(); e.Handled = true; } };
        KeyboardAccelerators.Add(search);
        var escape = new KeyboardAccelerator { Key = VirtualKey.Escape };
        escape.Invoked += (_, e) =>
        {
            if (_currentRoute == NavigationRoute.Home || _navigationLocked) return;
            if (Microsoft.UI.Xaml.Input.FocusManager.GetFocusedElement(XamlRoot) is TextBox) return;
            NavigateBackFromOverlay();
            e.Handled = true;
        };
        KeyboardAccelerators.Add(escape);
        var altLeft = new KeyboardAccelerator { Key = VirtualKey.Left, Modifiers = VirtualKeyModifiers.Menu };
        altLeft.Invoked += (_, e) => { if (_currentRoute != NavigationRoute.Home && !_navigationLocked) { NavigateBackFromOverlay(); e.Handled = true; } };
        KeyboardAccelerators.Add(altLeft);

        // Atalho F11 global: alterna tela cheia / janela com toast
        var f11 = new KeyboardAccelerator { Key = VirtualKey.F11, Modifiers = VirtualKeyModifiers.None };
        f11.Invoked += (_, e) =>
        {
            var targetFullScreen = !WindowMode.IsFullScreen;
            WindowMode.SetFullScreen(targetFullScreen);
            ShowToast(Strings.Tr(targetFullScreen ? "Tela cheia" : "Modo janela"));
            e.Handled = true;
        };
        KeyboardAccelerators.Add(f11);

        RootGrid.PointerPressed += (_, e) =>
        {
            if (e.GetCurrentPoint(RootGrid).Properties.IsXButton1Pressed && _currentRoute != NavigationRoute.Home && !_navigationLocked)
            {
                NavigateBackFromOverlay();
                e.Handled = true;
            }
        };
        _ = LoadMotionPreferenceAsync();
    }


    /// <summary>Elemento que a janela registra como região arrastável da barra de título.</summary>
    public UIElement TitleBarDragRegion => DragRegion;

    private static async System.Threading.Tasks.Task LoadMotionPreferenceAsync()
    {
        try
        {
            var prefs = await Settings.SettingsPageServices.Bridge.GetAsync();
            Motion.Reduced = prefs.ReduceMotion;
        }
        catch
        {
            // Sem host de ajustes: mantém as animações padrão.
        }
    }

    private void OnLanguageChanged() => DispatcherQueue.TryEnqueue(LocalizeUI);

    private void LocalizeUI()
    {
        UpdateTopNavigation();
    }

    // ------------------------------------------------------------------ navegação

    public void Navigate(NavigationRoute route)
    {
        if (route == NavigationRoute.Settings && _currentRoute != NavigationRoute.Settings)
            _returnRoute = _currentRoute;
        _currentRoute = route;
        _currentGameTitle = null;

        if (route == NavigationRoute.GeneralCheck)
        {
            NavigateToDiagnostic(null, null);
            return;
        }

        var pageType = route switch
        {
            NavigationRoute.Home => typeof(HomePage),
            NavigationRoute.Library => typeof(LibraryPage),
            NavigationRoute.History => typeof(HistoryPage),
            NavigationRoute.Settings => typeof(SettingsPage),
            NavigationRoute.Gallery => typeof(GalleryPage),
            _ => typeof(HomePage),
        };

        // Fora do Início e do resultado de um jogo não há arte atrás da janela.
        if (route != NavigationRoute.Home) ClearBackdrop();
        NavigateFrame(pageType, null);
        UpdateTopNavigation();
    }

    public void OpenGameDetails(LibraryGame game, NavigationRoute backRoute)
    {
        _detailsBackRoute = backRoute == NavigationRoute.Library ? NavigationRoute.Library : NavigationRoute.Home;
        _detailsGame = game;
        _currentRoute = NavigationRoute.GameDetails;
        ClearBackdrop();
        NavigateFrame(typeof(GameDetailsPage), game);
        UpdateTopNavigation();
    }

    /// <summary>Medição de rede contextual (com gameId) ou genérica de referência (sem gameId).</summary>
    public void NavigateToDiagnostic(string? gameId = null, string? gameTitle = null)
    {
        _currentRoute = NavigationRoute.GeneralCheck;
        _currentGameTitle = gameTitle;
        ClearBackdrop();
        try
        {
            ContentFrame.Content = WinUiEngineComposition.CreateDiagnosticPage(gameId, gameTitle, autoStart: !string.IsNullOrWhiteSpace(gameId));
        }
        catch (Exception)
        {
            ShowToast(Strings.Tr("Não foi possível abrir esta tela agora."));
            return;
        }
        ApplyStageMargins(typeof(DiagnosticPage));
        UpdateTopNavigation();
    }

    private void NavigateFrame(Type pageType, object? parameter)
    {
        // Nova página nunca herda a arte da anterior; cada tela pede a sua.
        NavigationTransitionInfo transition = Motion.Reduced ? new SuppressNavigationTransitionInfo() : new EntranceNavigationTransitionInfo();
        try
        {
            ContentFrame.Navigate(pageType, parameter, transition);
        }
        catch (Exception)
        {
            ShowToast(Strings.Tr("Não foi possível abrir esta tela agora."));
            return;
        }
        ApplyStageMargins(pageType);
    }

    private void ContentFrame_Navigated(object sender, NavigationEventArgs e)
    {
        ApplyStageMargins(e.SourcePageType);
        // Voltar pelo Frame (Detalhes -> Início/Biblioteca) precisa refletir o item ativo da sidebar.
        NavigationRoute? route = e.SourcePageType == typeof(HomePage) ? NavigationRoute.Home
            : e.SourcePageType == typeof(LibraryPage) ? NavigationRoute.Library
            : e.SourcePageType == typeof(HistoryPage) ? NavigationRoute.History
            : e.SourcePageType == typeof(SettingsPage) ? NavigationRoute.Settings
            : e.SourcePageType == typeof(GalleryPage) ? NavigationRoute.Gallery
            : null;
        if (route is { } active)
        {
            _currentRoute = active;
            UpdateTopNavigation();
        }
    }

    /// <summary>Faixa de 56px da barra de título; só o banner de Detalhes sobe por baixo dela.</summary>
    private void ApplyStageMargins(Type? pageType)
    {
        _stageTop = pageType == typeof(GameDetailsPage) ? 0 : 56;
        ContentFrame.Margin = new Thickness(0, _stageTop, 0, 0);
    }

    // ------------------------------------------------------------------ arte de fundo

    private void AnimateToGameBackdrop()
    {
        _wallpaperTransitionStoryboard?.Stop();
        _wallpaperTransitionStoryboard = null;

        BackdropHost.Visibility = Visibility.Visible;
        WallpaperHost.Visibility = Visibility.Visible;

        if (Motion.Reduced)
        {
            BackdropHost.Opacity = 1;
            WallpaperHost.Opacity = 0;
            WallpaperHost.Visibility = Visibility.Collapsed;
            return;
        }

        var sb = new Storyboard();
        var fadeIn = new DoubleAnimation
        {
            To = 1,
            Duration = TimeSpan.FromMilliseconds(300),
            EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut }
        };
        Storyboard.SetTarget(fadeIn, BackdropHost);
        Storyboard.SetTargetProperty(fadeIn, "Opacity");
        sb.Children.Add(fadeIn);

        var fadeOut = new DoubleAnimation
        {
            To = 0,
            Duration = TimeSpan.FromMilliseconds(300),
            EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut }
        };
        Storyboard.SetTarget(fadeOut, WallpaperHost);
        Storyboard.SetTargetProperty(fadeOut, "Opacity");
        sb.Children.Add(fadeOut);

        sb.Completed += (_, _) =>
        {
            if (_hasBackdrop) WallpaperHost.Visibility = Visibility.Collapsed;
        };

        _wallpaperTransitionStoryboard = sb;
        sb.Begin();
    }

    private void AnimateToWallpaper()
    {
        _wallpaperTransitionStoryboard?.Stop();
        _wallpaperTransitionStoryboard = null;

        WallpaperHost.Visibility = Visibility.Visible;

        if (Motion.Reduced)
        {
            WallpaperHost.Opacity = 1;
            BackdropHost.Opacity = 0;
            BackdropHost.Visibility = Visibility.Collapsed;
            BackdropSlides.Children.Clear();
            return;
        }

        var sb = new Storyboard();
        var fadeIn = new DoubleAnimation
        {
            To = 1,
            Duration = TimeSpan.FromMilliseconds(300),
            EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut }
        };
        Storyboard.SetTarget(fadeIn, WallpaperHost);
        Storyboard.SetTargetProperty(fadeIn, "Opacity");
        sb.Children.Add(fadeIn);

        var fadeOut = new DoubleAnimation
        {
            To = 0,
            Duration = TimeSpan.FromMilliseconds(300),
            EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut }
        };
        Storyboard.SetTarget(fadeOut, BackdropHost);
        Storyboard.SetTargetProperty(fadeOut, "Opacity");
        sb.Children.Add(fadeOut);

        sb.Completed += (_, _) =>
        {
            if (!_hasBackdrop)
            {
                BackdropHost.Visibility = Visibility.Collapsed;
                BackdropSlides.Children.Clear();
            }
        };

        _wallpaperTransitionStoryboard = sb;
        sb.Begin();
    }

    /// <summary>Define a arte atrás da janela inteira (inclusive sob a sidebar). Lista vazia ou falha volta ao papel de parede.</summary>
    public void SetBackdrop(IReadOnlyList<string> imagePaths, BackdropKind kind, int selectedIndex = 0)
    {
        if (imagePaths == null || imagePaths.Count == 0 || imagePaths.All(string.IsNullOrWhiteSpace))
        {
            ClearBackdrop();
            return;
        }

        var revision = ++_backdropTransitionRevision;
        StopBackdropTransition();
        if (_hasBackdrop && !Motion.Reduced)
        {
            CrossFadeBackdrop(imagePaths, kind, selectedIndex, revision);
            return;
        }
        BackdropTransition.Children.Clear();
        BackdropTransition.Opacity = 0;
        ApplyBackdrop(imagePaths, kind, selectedIndex);
    }

    /// <summary>SetBackdrop troca o conjunto de artes; a arte anterior fica visível até a nova dissolver.</summary>
    private void ApplyBackdrop(IReadOnlyList<string> imagePaths, BackdropKind kind, int selectedIndex)
    {
        if (imagePaths == null || imagePaths.Count == 0)
        {
            ClearBackdrop();
            return;
        }

        var wasHidden = !_hasBackdrop;
        BackdropSlides.Children.Clear();
        BackdropSlides.ColumnDefinitions.Clear();
        var count = imagePaths.Count;
        var validImages = 0;
        for (var i = 0; i < count; i++)
        {
            BackdropSlides.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            var slide = new Grid();
            if (i < imagePaths.Count && TryCreateImage(imagePaths[i]) is { } source)
            {
                slide.Children.Add(new Image { Source = source, Stretch = Stretch.UniformToFill, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = kind == BackdropKind.Veil ? VerticalAlignment.Top : VerticalAlignment.Center });
                validImages++;
            }
            Grid.SetColumn(slide, i);
            BackdropSlides.Children.Add(slide);
        }

        if (validImages == 0)
        {
            ClearBackdrop();
            return;
        }

        _backdropCount = count;
        _backdropIndex = Math.Clamp(selectedIndex, 0, count - 1);
        BackdropVeil.Visibility = kind == BackdropKind.Veil ? Visibility.Visible : Visibility.Collapsed;

        if (wasHidden)
        {
            _hasBackdrop = true;
            AnimateToGameBackdrop();
        }
        LayoutBackdrop(animate: false);
    }

    private void CrossFadeBackdrop(IReadOnlyList<string> imagePaths, BackdropKind kind, int selectedIndex, int revision)
    {
        var targetIndex = imagePaths.Count == 0 ? 0 : Math.Clamp(selectedIndex, 0, imagePaths.Count - 1);
        if (targetIndex >= imagePaths.Count || TryCreateImage(imagePaths[targetIndex]) is not { } source)
        {
            ClearBackdrop();
            return;
        }

        BackdropTransition.Children.Clear();
        var target = new Grid();
        var image = new Image { Source = source, Stretch = Stretch.UniformToFill, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = kind == BackdropKind.Veil ? VerticalAlignment.Top : VerticalAlignment.Center };
        target.Children.Add(image);
        BackdropTransition.Children.Add(target);
        BackdropTransition.Opacity = 0;
        Canvas.SetZIndex(BackdropTransition, 2);
        BeginBackdropTransition(image, revision, () =>
        {
            ApplyBackdrop(imagePaths, kind, selectedIndex);
            BackdropTransition.Children.Clear();
            BackdropTransition.Opacity = 0;
        });
    }

    public void SelectBackdropSlide(int index)
    {
        if (!_hasBackdrop || _backdropCount == 0) return;
        var revision = ++_backdropTransitionRevision;
        StopBackdropTransition();
        _backdropIndex = Math.Clamp(index, 0, _backdropCount - 1);
        if (Motion.Reduced)
        {
            BackdropTransition.Children.Clear();
            BackdropTransition.Opacity = 0;
            LayoutBackdrop(animate: false);
            return;
        }
        // A faixa continua a fonte de verdade; a transição sobreposta impede que a arte saia de uma vez.
        var source = BackdropSlides.Children.ElementAtOrDefault(_backdropIndex) as Grid;
        if (source is null) { LayoutBackdrop(animate: true); return; }
        BackdropTransition.Children.Clear();
        var preview = new Grid();
        Image? image = null;
        if (source.Children.OfType<Image>().FirstOrDefault() is { Source: { } imageSource })
        {
            image = new Image { Source = imageSource, Stretch = Stretch.UniformToFill, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
            preview.Children.Add(image);
        }
        BackdropTransition.Children.Add(preview);
        BackdropTransition.Opacity = 0;
        BeginBackdropTransition(image, revision, () => { LayoutBackdrop(animate: false); BackdropTransition.Children.Clear(); BackdropTransition.Opacity = 0; });
    }

    /// <summary>Só cobre a arte atual depois de ImageOpened; falha volta ao papel de parede.</summary>
    private void BeginBackdropTransition(Image? image, int revision, Action completed)
    {
        var started = false;
        void Start()
        {
            if (started || revision != _backdropTransitionRevision) return;
            if (Motion.Reduced)
            {
                started = true;
                completed();
                return;
            }
            started = true;
            var fade = new DoubleAnimation { To = 1, Duration = TimeSpan.FromMilliseconds(300), EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut } };
            Storyboard.SetTarget(fade, BackdropTransition);
            Storyboard.SetTargetProperty(fade, "Opacity");
            var storyboard = new Storyboard();
            storyboard.Children.Add(fade);
            _backdropTransitionStoryboard = storyboard;
            storyboard.Completed += (_, _) => { if (revision == _backdropTransitionRevision) completed(); };
            storyboard.Begin();
        }
        if (image is null) { Start(); return; }
        image.ImageOpened += (_, _) => Start();
        image.ImageFailed += (_, _) =>
        {
            if (revision != _backdropTransitionRevision) return;
            ClearBackdrop();
        };
    }

    public void ClearBackdrop()
    {
        if (!_hasBackdrop) return;
        _backdropTransitionRevision++;
        StopBackdropTransition();
        _hasBackdrop = false;
        AnimateToWallpaper();
        BackdropTransition.Children.Clear();
        BackdropTransition.Opacity = 0;
    }

    private void StopBackdropTransition()
    {
        _backdropTransitionStoryboard?.Stop();
        _backdropTransitionStoryboard = null;
        BackdropTransition.Opacity = 0;
    }

    private void LayoutBackdrop(bool animate = false)
    {
        if (!_hasBackdrop || RootGrid.ActualWidth <= 0) return;
        var width = RootGrid.ActualWidth;
        BackdropSlides.Width = width * _backdropCount;
        BackdropSlides.Height = RootGrid.ActualHeight;
        var target = -_backdropIndex * width;
        if (!animate || Motion.Reduced)
        {
            BackdropShift.TranslateX = target;
            return;
        }
        var slide = new DoubleAnimation { To = target, Duration = TimeSpan.FromMilliseconds(900), EasingFunction = new CubicEase { EasingMode = EasingMode.EaseInOut } };
        Storyboard.SetTarget(slide, BackdropShift);
        Storyboard.SetTargetProperty(slide, "TranslateX");
        var sb = new Storyboard();
        sb.Children.Add(slide);
        sb.Begin();
    }

    private BitmapImage? TryCreateImage(string path)
    {
        try
        {
            // Decodifica na largura da janela: banners de 4K inteiros travavam a troca de jogo.
            var width = (int)Math.Clamp(Math.Ceiling(RootGrid.ActualWidth > 0 ? RootGrid.ActualWidth : 1920), 960, 2560);
            return new BitmapImage { DecodePixelWidth = width, UriSource = new Uri(path) };
        }
        catch
        {
            return null;
        }
    }

    // ------------------------------------------------------------------ toast

    public void ShowToast(string message)
    {
        ToastText.Text = message;
        ToastBorder.OpacityTransition ??= new ScalarTransition { Duration = TimeSpan.FromMilliseconds(180) };
        ToastBorder.TranslationTransition ??= new Vector3Transition { Duration = TimeSpan.FromMilliseconds(180) };
        ToastBorder.Visibility = Visibility.Visible;
        ToastBorder.Translation = new System.Numerics.Vector3(0, Motion.Reduced ? 0 : 12, 0);
        ToastBorder.Opacity = 0;
        DispatcherQueue.TryEnqueue(Microsoft.UI.Dispatching.DispatcherQueuePriority.Low, () =>
        {
            ToastBorder.Translation = System.Numerics.Vector3.Zero;
            ToastBorder.Opacity = 1;
        });
        _toastTimer?.Stop();
        _toastTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(2.6) };
        _toastTimer.Tick += (_, _) =>
        {
            _toastTimer.Stop();
            ToastBorder.Opacity = 0;
            ToastBorder.Translation = new System.Numerics.Vector3(0, Motion.Reduced ? 0 : 12, 0);
            var hide = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(Motion.Reduced ? 1 : 200) };
            hide.Tick += (_, _) => { hide.Stop(); if (ToastBorder.Opacity == 0) ToastBorder.Visibility = Visibility.Collapsed; };
            hide.Start();
        };
        _toastTimer.Start();
    }

    // ------------------------------------------------------------------ navegação do topo

    public void OpenQuickSearch()
    {
        if (_navigationLocked) return;
        if (ContentFrame.Content is not LibraryPage) Navigate(NavigationRoute.Library);
        DispatcherQueue.TryEnqueue(Microsoft.UI.Dispatching.DispatcherQueuePriority.Low, () =>
        {
            if (ContentFrame.Content is LibraryPage libraryPage) libraryPage.FocusSearch();
        });
    }

    public void NavigateToGallery()
    {
        if (!_navigationLocked) Navigate(NavigationRoute.Gallery);
    }

    /// <summary>Fecha uma tela auxiliar voltando ao contexto que a abriu.</summary>
    public void NavigateBackFromOverlay()
    {
        if (_navigationLocked || _currentRoute == NavigationRoute.Home) return;
        var destination = _currentRoute switch
        {
            NavigationRoute.Settings => _returnRoute,
            NavigationRoute.Gallery => NavigationRoute.Home,
            NavigationRoute.GameDetails => _detailsBackRoute,
            _ => NavigationRoute.Home,
        };
        ReturnToRoute(destination);
    }

    private void OnSessionActivityChanged(object? sender, bool active) => DispatcherQueue.TryEnqueue(() => UpdateNavigationLock(active));

    private void UpdateNavigationLock(bool locked)
    {
        if (locked == _navigationLocked) return;
        _navigationLocked = locked;
        TopHomeButton.IsEnabled = !locked;
    }

    private void UpdateTopNavigation()
    {
        var showsBack = _currentRoute is NavigationRoute.Gallery or NavigationRoute.Library or NavigationRoute.History or NavigationRoute.GeneralCheck or NavigationRoute.Settings;
        TopHomeButton.Visibility = showsBack ? Visibility.Visible : Visibility.Collapsed;
        TopBrandIcon.Visibility = Visibility.Collapsed;
        TopBackIcon.Visibility = showsBack ? Visibility.Visible : Visibility.Collapsed;
        var label = Strings.Tr("Voltar");
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(TopHomeButton, label);
        ToolTipService.SetToolTip(TopHomeButton, label);
    }

    private void TopNavigation_Click(object sender, RoutedEventArgs e)
    {
        NavigateBackFromOverlay();
    }

    private void ReturnToRoute(NavigationRoute destination)
    {
        if (destination == NavigationRoute.GameDetails && _detailsGame is not null)
        {
            OpenGameDetails(_detailsGame, _detailsBackRoute);
            return;
        }
        Navigate(destination is NavigationRoute.GameDetails ? NavigationRoute.Home : destination);
    }
}
