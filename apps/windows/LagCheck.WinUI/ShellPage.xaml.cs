using System;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using LagCheck.WinUI.Diagnostic;
using LagCheck.WinUI.Library;
using LagCheck.WinUI.Pages;

namespace LagCheck.WinUI;

public sealed partial class ShellPage : Page
{
    private bool _navigationLocked;
    private bool _isSidebarCollapsed;
    private DispatcherTimer? _toastTimer;

    public ShellPage()
    {
        InitializeComponent();
        ShellNavigation.Configure(NavigateToDiagnostic);
        UpdateSidebarVisualState();
        Navigate(NavigationRoute.Home);
        WinUiEngineComposition.Client.SessionActivityChanged += OnSessionActivityChanged;
        Unloaded += (_, _) => WinUiEngineComposition.Client.SessionActivityChanged -= OnSessionActivityChanged;
    }

    public void Navigate(NavigationRoute route)
    {
        if (route == NavigationRoute.GeneralCheck)
        {
            NavigateToDiagnostic(null, null);
            RouteText.Text = "Conexão";
            SetActive(route);
            return;
        }

        var pageType = route switch
        {
            NavigationRoute.Home => typeof(HomePage),
            NavigationRoute.Library => typeof(Library.LibraryPage),
            NavigationRoute.History => typeof(HistoryPage),
            NavigationRoute.Settings => typeof(SettingsPage),
            _ => typeof(HomePage),
        };

        ContentFrame.Navigate(pageType);
        RouteText.Text = route switch
        {
            NavigationRoute.Home => "Início",
            NavigationRoute.Library => "Biblioteca",
            NavigationRoute.History => "Histórico",
            _ => "Ajustes"
        };
        SetActive(route);
    }

    public void NavigateToGameDetails(LibraryGame game)
    {
        ContentFrame.Navigate(typeof(GameDetailsPage), game);
        RouteText.Text = game.Title;
    }

    /// <summary>Medição de rede contextual (com gameId) ou genérica de referência (sem gameId).</summary>
    public void NavigateToDiagnostic(string? gameId = null, string? gameTitle = null)
    {
        ContentFrame.Content = WinUiEngineComposition.CreateDiagnosticPage(gameId, gameTitle);
        RouteText.Text = string.IsNullOrWhiteSpace(gameTitle) ? "Conexão" : $"Conexão · {gameTitle}";
        SetActive(NavigationRoute.GeneralCheck);
    }

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

    private void SetActive(NavigationRoute route)
    {
        var buttons = new[] { HomeButton, LibraryButton, GeneralCheckButton, HistoryButton, SettingsButton };
        foreach (var button in buttons)
        {
            button.Background = (Microsoft.UI.Xaml.Media.Brush)Application.Current.Resources["StageBrush"];
            button.Foreground = (Microsoft.UI.Xaml.Media.Brush)Application.Current.Resources["TextSecondaryBrush"];
        }
        var active = route switch
        {
            NavigationRoute.Home => HomeButton,
            NavigationRoute.Library => LibraryButton,
            NavigationRoute.GeneralCheck => GeneralCheckButton,
            NavigationRoute.History => HistoryButton,
            _ => SettingsButton
        };
        active.Background = (Microsoft.UI.Xaml.Media.Brush)Application.Current.Resources["SurfaceBrush"];
        active.Foreground = (Microsoft.UI.Xaml.Media.Brush)Application.Current.Resources["TextPrimaryBrush"];
    }

    private void SidebarToggle_Click(object sender, RoutedEventArgs e)
    {
        _isSidebarCollapsed = !_isSidebarCollapsed;
        UpdateSidebarVisualState();
    }

    private void UpdateSidebarVisualState()
    {
        var navButtons = new[] { QuickSearchButton, HomeButton, LibraryButton, GeneralCheckButton, HistoryButton, SettingsButton };

        if (_isSidebarCollapsed)
        {
            SidebarColumn.Width = new GridLength(64);
            ExpandedHeader.Visibility = Visibility.Collapsed;
            CollapsedHeader.Visibility = Visibility.Visible;
            ExpandedFooter.Visibility = Visibility.Collapsed;
            CollapsedFooterDot.Visibility = Visibility.Visible;
            SearchSeparator.Visibility = Visibility.Collapsed;

            SearchLabel.Visibility = Visibility.Collapsed;
            HomeLabel.Visibility = Visibility.Collapsed;
            LibraryLabel.Visibility = Visibility.Collapsed;
            GeneralCheckLabel.Visibility = Visibility.Collapsed;
            HistoryLabel.Visibility = Visibility.Collapsed;
            SettingsLabel.Visibility = Visibility.Collapsed;

            NavItemsPanel.Padding = new Thickness(10, 8, 10, 0);

            foreach (var btn in navButtons)
            {
                btn.Width = 44;
                btn.Height = 44;
                btn.Padding = new Thickness(0);
                btn.HorizontalAlignment = HorizontalAlignment.Center;
                btn.CornerRadius = new CornerRadius(12);
            }
        }
        else
        {
            SidebarColumn.Width = new GridLength(220);
            ExpandedHeader.Visibility = Visibility.Visible;
            CollapsedHeader.Visibility = Visibility.Collapsed;
            ExpandedFooter.Visibility = Visibility.Visible;
            CollapsedFooterDot.Visibility = Visibility.Collapsed;
            SearchSeparator.Visibility = Visibility.Visible;

            SearchLabel.Visibility = Visibility.Visible;
            HomeLabel.Visibility = Visibility.Visible;
            LibraryLabel.Visibility = Visibility.Visible;
            GeneralCheckLabel.Visibility = Visibility.Visible;
            HistoryLabel.Visibility = Visibility.Visible;
            SettingsLabel.Visibility = Visibility.Visible;

            NavItemsPanel.Padding = new Thickness(12, 8, 12, 0);

            foreach (var btn in navButtons)
            {
                btn.Width = double.NaN;
                btn.Height = 44;
                btn.Padding = new Thickness(0);
                btn.HorizontalAlignment = HorizontalAlignment.Stretch;
                btn.CornerRadius = new CornerRadius(10);
            }
        }
    }

    private void QuickSearch_Click(object sender, RoutedEventArgs e)
    {
        Navigate(NavigationRoute.Library);
        if (ContentFrame.Content is Library.LibraryPage libraryPage)
        {
            libraryPage.FocusSearch();
        }
    }

    private void OnSessionActivityChanged(object? sender, bool active) => DispatcherQueue.TryEnqueue(() => UpdateNavigationLock(active));

    private void UpdateNavigationLock(bool locked)
    {
        if (locked == _navigationLocked) return;
        _navigationLocked = locked;
        foreach (var button in new[] { HomeButton, LibraryButton, GeneralCheckButton, HistoryButton, SettingsButton }) button.IsEnabled = !locked;
    }

    private void Home_Click(object sender, RoutedEventArgs e) => Navigate(NavigationRoute.Home);
    private void Library_Click(object sender, RoutedEventArgs e) => Navigate(NavigationRoute.Library);
    private void GeneralCheck_Click(object sender, RoutedEventArgs e) => Navigate(NavigationRoute.GeneralCheck);
    private void History_Click(object sender, RoutedEventArgs e) => Navigate(NavigationRoute.History);
    private void Settings_Click(object sender, RoutedEventArgs e) => Navigate(NavigationRoute.Settings);
}
