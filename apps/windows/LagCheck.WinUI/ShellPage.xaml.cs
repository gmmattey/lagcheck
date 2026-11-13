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
    private const double CollapsedWidth = 64;
    private const double ExpandedWidth = 220;

    private bool _navigationLocked;
    private bool _pinnedExpanded;
    private double _stageTop = 56;
    private bool _sidebarReady;
    private DispatcherTimer? _toastTimer;
    private NavigationRoute _currentRoute = NavigationRoute.Home;
    private NavigationRoute _detailsBackRoute = NavigationRoute.Home;
    private string? _currentGameTitle;
    private bool _hasBackdrop;
    private int _backdropCount;
    private int _backdropIndex;

    public ShellPage()
    {
        InitializeComponent();
        ShellChrome.Register(this);
        ShellNavigation.Configure(NavigateToDiagnostic, Navigate, OpenGameDetails);
        UpdateSidebarVisualState();
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

        var search = new KeyboardAccelerator { Key = VirtualKey.F, Modifiers = VirtualKeyModifiers.Control };
        search.Invoked += (_, e) =>
        {
            if (_navigationLocked) return;
            if (ContentFrame.Content is LibraryPage page) { page.FocusSearch(); e.Handled = true; }
        };
        KeyboardAccelerators.Add(search);
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
        SearchLabel.Text = Strings.Tr("Buscar jogo...");
        HomeLabel.Text = Strings.Tr("Início");
        LibraryLabel.Text = Strings.Tr("Biblioteca");
        GeneralCheckLabel.Text = Strings.Tr("Conexão");
        HistoryLabel.Text = Strings.Tr("Histórico");
        SettingsLabel.Text = Strings.Tr("Ajustes");

        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(QuickSearchButton, Strings.Tr("Buscar jogo..."));
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(HomeButton, Strings.Tr("Início"));
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(LibraryButton, Strings.Tr("Biblioteca"));
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(GeneralCheckButton, Strings.Tr("Conexão"));
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(HistoryButton, Strings.Tr("Histórico"));
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(SettingsButton, Strings.Tr("Ajustes"));
        ToolTipService.SetToolTip(QuickSearchButton, Strings.Tr("Buscar jogo (Ctrl+F)"));
        ToolTipService.SetToolTip(HomeButton, Strings.Tr("Início"));
        ToolTipService.SetToolTip(LibraryButton, Strings.Tr("Biblioteca de jogos instalados"));
        ToolTipService.SetToolTip(GeneralCheckButton, Strings.Tr("Conexão"));
        ToolTipService.SetToolTip(HistoryButton, Strings.Tr("Histórico de conexões"));
        ToolTipService.SetToolTip(SettingsButton, Strings.Tr("Ajustes do launcher"));
        ToolTipService.SetToolTip(SidebarCollapseButton, Strings.Tr("Recolher barra lateral"));
        ToolTipService.SetToolTip(SidebarExpandButton, Strings.Tr("Expandir barra lateral"));
    }

    // ------------------------------------------------------------------ navegação

    public void Navigate(NavigationRoute route)
    {
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
            _ => typeof(HomePage),
        };

        // Fora do Início e do resultado de um jogo não há arte atrás da janela.
        if (route != NavigationRoute.Home) ClearBackdrop();
        NavigateFrame(pageType, null);
        SetActive(route);
    }

    public void OpenGameDetails(LibraryGame game, NavigationRoute backRoute)
    {
        _detailsBackRoute = backRoute == NavigationRoute.Library ? NavigationRoute.Library : NavigationRoute.Home;
        _currentRoute = NavigationRoute.GameDetails;
        ClearBackdrop();
        NavigateFrame(typeof(GameDetailsPage), game);
        SetActive(_detailsBackRoute);
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
        SetActive(NavigationRoute.GeneralCheck);
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
            : null;
        if (route is { } active)
        {
            _currentRoute = active;
            SetActive(active);
        }
    }

    public static readonly DependencyProperty StageLeftProperty = DependencyProperty.Register(
        nameof(StageLeft), typeof(double), typeof(ShellPage),
        new PropertyMetadata(CollapsedWidth, (d, e) => ((ShellPage)d).ApplyStage((double)e.NewValue)));

    /// <summary>Largura que a sidebar ocupa à esquerda; o palco começa logo depois dela.</summary>
    public double StageLeft
    {
        get => (double)GetValue(StageLeftProperty);
        set => SetValue(StageLeftProperty, value);
    }

    private void ApplyStage(double left)
    {
        Sidebar.Width = left;
        SidebarShadow.Margin = new Thickness(left, 0, 0, 0);
        ContentFrame.Margin = new Thickness(left, _stageTop, 0, 0);
        DragRegion.Margin = new Thickness(left, 0, 0, 0);
    }

    /// <summary>Faixa de 56px da barra de título; só o banner de Detalhes sobe por baixo dela.</summary>
    private void ApplyStageMargins(Type? pageType)
    {
        _stageTop = pageType == typeof(GameDetailsPage) ? 0 : 56;
        ApplyStage(StageLeft);
    }

    // ------------------------------------------------------------------ arte de fundo

    /// <summary>Define a arte atrás da janela inteira (inclusive sob a sidebar). Lista vazia mostra as miniaturas neutras.</summary>
    public void SetBackdrop(IReadOnlyList<string> imagePaths, BackdropKind kind, int selectedIndex = 0)
    {
        BackdropSlides.Children.Clear();
        BackdropSlides.ColumnDefinitions.Clear();
        var count = Math.Max(1, imagePaths.Count);
        for (var i = 0; i < count; i++)
        {
            BackdropSlides.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            var slide = new Grid();
            var stripes = new StripedBackground { Band = 18 };
            slide.Children.Add(stripes);
            if (i < imagePaths.Count && TryCreateImage(imagePaths[i]) is { } source)
            {
                slide.Children.Add(new Image { Source = source, Stretch = Stretch.UniformToFill, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = kind == BackdropKind.Veil ? VerticalAlignment.Top : VerticalAlignment.Center });
            }
            Grid.SetColumn(slide, i);
            BackdropSlides.Children.Add(slide);
        }

        _backdropCount = count;
        _backdropIndex = Math.Clamp(selectedIndex, 0, count - 1);
        BackdropHeroSide.Visibility = kind == BackdropKind.Hero ? Visibility.Visible : Visibility.Collapsed;
        BackdropHeroDepth.Visibility = kind == BackdropKind.Hero ? Visibility.Visible : Visibility.Collapsed;
        BackdropVeil.Visibility = kind == BackdropKind.Veil ? Visibility.Visible : Visibility.Collapsed;

        if (!_hasBackdrop)
        {
            _hasBackdrop = true;
            BackdropHost.Visibility = Visibility.Visible;
            if (!Motion.Reduced)
            {
                var fade = new DoubleAnimation { From = 0, To = 1, Duration = TimeSpan.FromMilliseconds(600), EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut } };
                Storyboard.SetTarget(fade, BackdropHost);
                Storyboard.SetTargetProperty(fade, "Opacity");
                var sb = new Storyboard();
                sb.Children.Add(fade);
                sb.Begin();
            }
        }
        UpdateSidebarVisualState();
        LayoutBackdrop(animate: false);
        FadeBackdropIn();
    }

    /// <summary>A arte nova entra por dissolução em vez de trocar de uma vez.</summary>
    private void FadeBackdropIn()
    {
        if (Motion.Reduced) return;
        var fade = new DoubleAnimation { From = 0.25, To = 1, Duration = new Duration(TimeSpan.FromMilliseconds(380)), EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut } };
        Storyboard.SetTarget(fade, BackdropSlides);
        Storyboard.SetTargetProperty(fade, "Opacity");
        var storyboard = new Storyboard();
        storyboard.Children.Add(fade);
        storyboard.Begin();
    }

    public void SelectBackdropSlide(int index)
    {
        if (!_hasBackdrop || _backdropCount == 0) return;
        _backdropIndex = Math.Clamp(index, 0, _backdropCount - 1);
        LayoutBackdrop(animate: true);
    }

    public void ClearBackdrop()
    {
        if (!_hasBackdrop) return;
        _hasBackdrop = false;
        BackdropHost.Visibility = Visibility.Collapsed;
        BackdropSlides.Children.Clear();
        UpdateSidebarVisualState();
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

    private static BitmapImage? TryCreateImage(string path)
    {
        try
        {
            return new BitmapImage(new Uri(path));
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
        ToastBorder.Visibility = Visibility.Visible;
        _toastTimer?.Stop();
        _toastTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(2.6) };
        _toastTimer.Tick += (_, _) =>
        {
            _toastTimer.Stop();
            ToastBorder.Visibility = Visibility.Collapsed;
        };
        _toastTimer.Start();
    }

    // ------------------------------------------------------------------ sidebar

    private void SetActive(NavigationRoute route)
    {
        var active = route switch
        {
            NavigationRoute.Home => HomeButton,
            NavigationRoute.Library => LibraryButton,
            NavigationRoute.GeneralCheck => GeneralCheckButton,
            NavigationRoute.History => HistoryButton,
            _ => SettingsButton,
        };
        var inactive = (Brush)Application.Current.Resources["TextSecondaryBrush"];
        var primary = (Brush)Application.Current.Resources["TextPrimaryBrush"];
        var accent = (Brush)Application.Current.Resources["PurpleLightBrush"];
        var clear = new SolidColorBrush(Microsoft.UI.Colors.Transparent);
        foreach (var button in new[] { HomeButton, LibraryButton, GeneralCheckButton, HistoryButton, SettingsButton })
        {
            var on = ReferenceEquals(button, active);
            // Item ativo: brilho roxo que se dissolve para a direita + barra de destaque à esquerda
            button.Background = on ? CreateActiveGlow() : clear;
            button.BorderBrush = on ? accent : clear;
            button.Foreground = on ? primary : inactive;
        }
    }

    private static LinearGradientBrush CreateActiveGlow()
    {
        var brush = new LinearGradientBrush { StartPoint = new Windows.Foundation.Point(0, 0.5), EndPoint = new Windows.Foundation.Point(1, 0.5) };
        brush.GradientStops.Add(new GradientStop { Color = Windows.UI.Color.FromArgb(0x4D, 0x7C, 0x3A, 0xED), Offset = 0 });
        brush.GradientStops.Add(new GradientStop { Color = Windows.UI.Color.FromArgb(0x1F, 0x7C, 0x3A, 0xED), Offset = 1 });
        return brush;
    }

    private static LinearGradientBrush CreateSidebarSurface(byte alpha)
    {
        var brush = new LinearGradientBrush { StartPoint = new Windows.Foundation.Point(0, 0), EndPoint = new Windows.Foundation.Point(0, 1) };
        brush.GradientStops.Add(new GradientStop { Color = Windows.UI.Color.FromArgb(alpha, 0x14, 0x17, 0x1F), Offset = 0 });
        brush.GradientStops.Add(new GradientStop { Color = Windows.UI.Color.FromArgb(alpha, 0x0D, 0x0F, 0x14), Offset = 0.55 });
        brush.GradientStops.Add(new GradientStop { Color = Windows.UI.Color.FromArgb(alpha, 0x0A, 0x0B, 0x10), Offset = 1 });
        return brush;
    }

    private void SidebarToggle_Click(object sender, RoutedEventArgs e)
    {
        _pinnedExpanded = !_pinnedExpanded;
        UpdateSidebarVisualState();
        AnimateSidebar(_pinnedExpanded ? ExpandedWidth : CollapsedWidth);
    }

    /// <summary>Abre e fecha a sidebar empurrando o palco, sem nunca cobrir título ou cards.</summary>
    private void AnimateSidebar(double target)
    {
        if (Motion.Reduced)
        {
            StageLeft = target;
            FinishSidebar();
            return;
        }
        var animation = new DoubleAnimation
        {
            To = target,
            Duration = new Duration(TimeSpan.FromMilliseconds(260)),
            EasingFunction = new CubicEase { EasingMode = EasingMode.EaseInOut },
            EnableDependentAnimation = true,
        };
        Storyboard.SetTarget(animation, this);
        Storyboard.SetTargetProperty(animation, nameof(StageLeft));
        var storyboard = new Storyboard();
        storyboard.Children.Add(animation);
        storyboard.Completed += (_, _) => { StageLeft = target; FinishSidebar(); };
        storyboard.Begin();
    }

    private void FinishSidebar()
    {
        if (!_pinnedExpanded) SetLabelsVisible(false);
    }

    private void SetLabelsVisible(bool visible)
    {
        var visibility = visible ? Visibility.Visible : Visibility.Collapsed;
        SearchLabel.Visibility = visibility;
        HomeLabel.Visibility = visibility;
        LibraryLabel.Visibility = visibility;
        GeneralCheckLabel.Visibility = visibility;
        HistoryLabel.Visibility = visibility;
        SettingsLabel.Visibility = visibility;
        SearchSeparator.Visibility = visibility;
    }

    private Button[] NavButtons => new[] { QuickSearchButton, HomeButton, LibraryButton, GeneralCheckButton, HistoryButton, SettingsButton };

    private void UpdateSidebarVisualState()
    {
        var expanded = _pinnedExpanded;
        var buttons = new[] { QuickSearchButton, HomeButton, LibraryButton, GeneralCheckButton, HistoryButton, SettingsButton };

        // Com arte atrás (Início / resultado de um jogo) a sidebar fica translúcida; nas demais telas é sólida.
        Sidebar.Background = CreateSidebarSurface(_hasBackdrop ? (byte)0xB3 : (byte)0xFF);

        ExpandedHeader.Visibility = expanded ? Visibility.Visible : Visibility.Collapsed;
        CollapsedHeader.Visibility = expanded ? Visibility.Collapsed : Visibility.Visible;
        if (expanded) SetLabelsVisible(true);

        NavItemsPanel.Width = double.NaN;
        NavItemsPanel.HorizontalAlignment = HorizontalAlignment.Stretch;
        NavItemsPanel.Padding = expanded ? new Thickness(12, 8, 12, 0) : new Thickness(10, 8, 10, 0);
        foreach (var button in buttons)
        {
            button.Width = expanded ? double.NaN : 44;
            button.HorizontalAlignment = expanded ? HorizontalAlignment.Stretch : HorizontalAlignment.Center;
        }
        if (!_sidebarReady)
        {
            _sidebarReady = true;
            Sidebar.SizeChanged += (_, args) => Sidebar.Clip = new RectangleGeometry { Rect = new Windows.Foundation.Rect(0, 0, args.NewSize.Width, args.NewSize.Height) };
        }
    }

    private void QuickSearch_Click(object sender, RoutedEventArgs e)
    {
        if (_navigationLocked) return;
        if (ContentFrame.Content is not LibraryPage) Navigate(NavigationRoute.Library);
        DispatcherQueue.TryEnqueue(Microsoft.UI.Dispatching.DispatcherQueuePriority.Low, () =>
        {
            if (ContentFrame.Content is LibraryPage libraryPage) libraryPage.FocusSearch();
        });
    }

    private void OnSessionActivityChanged(object? sender, bool active) => DispatcherQueue.TryEnqueue(() => UpdateNavigationLock(active));

    private void UpdateNavigationLock(bool locked)
    {
        if (locked == _navigationLocked) return;
        _navigationLocked = locked;
        foreach (var button in new[] { QuickSearchButton, HomeButton, LibraryButton, GeneralCheckButton, HistoryButton, SettingsButton }) button.IsEnabled = !locked;
    }

    private void Home_Click(object sender, RoutedEventArgs e) => Navigate(NavigationRoute.Home);
    private void Library_Click(object sender, RoutedEventArgs e) => Navigate(NavigationRoute.Library);
    private void GeneralCheck_Click(object sender, RoutedEventArgs e) => Navigate(NavigationRoute.GeneralCheck);
    private void History_Click(object sender, RoutedEventArgs e) => Navigate(NavigationRoute.History);
    private void Settings_Click(object sender, RoutedEventArgs e) => Navigate(NavigationRoute.Settings);
}
