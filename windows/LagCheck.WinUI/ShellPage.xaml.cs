using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using LagCheck.WinUI.Diagnostic;

namespace LagCheck.WinUI;

public sealed partial class ShellPage : Page
{
    private bool _navigationLocked;

    public ShellPage()
    {
        InitializeComponent();
        ShellNavigation.Configure(NavigateToDiagnostic);
        Navigate(NavigationRoute.Library);
        WinUiEngineComposition.Client.SessionActivityChanged += OnSessionActivityChanged;
        Unloaded += (_, _) => WinUiEngineComposition.Client.SessionActivityChanged -= OnSessionActivityChanged;
    }

    public void Navigate(NavigationRoute route)
    {
        var pageType = route switch
        {
            NavigationRoute.Library => ResolveOptionalPage("LagCheck.WinUI.Library.LibraryPage") ?? typeof(Pages.UnavailableLibraryPage),
            NavigationRoute.Catalog => typeof(Pages.CatalogPage),
            NavigationRoute.History => typeof(Pages.HistoryPage),
            NavigationRoute.Settings => typeof(Pages.SettingsPage),
            _ => typeof(Pages.UnavailableLibraryPage),
        };
        ContentFrame.Navigate(pageType);
        RouteText.Text = route switch { NavigationRoute.Library => "Biblioteca", NavigationRoute.Catalog => "Catálogo", NavigationRoute.History => "Histórico", _ => "Ajustes" };
        SetActive(route);
    }

    /// <summary>Integração contextual futura. Não inicia medição nem cria resultado.</summary>
    public void NavigateToDiagnostic(string? gameId = null, string? gameTitle = null)
    {
        ContentFrame.Content = WinUiEngineComposition.CreateDiagnosticPage(gameId, gameTitle);
        RouteText.Text = "Check";
    }

    private static Type? ResolveOptionalPage(string typeName) => Type.GetType($"{typeName}, LagCheck.WinUI");
    private void SetActive(NavigationRoute route)
    {
        foreach (var button in new[] { LibraryButton, CatalogButton, HistoryButton, SettingsButton })
        {
            button.Background = (Microsoft.UI.Xaml.Media.Brush)Application.Current.Resources["StageBrush"];
            button.Foreground = (Microsoft.UI.Xaml.Media.Brush)Application.Current.Resources["TextSecondaryBrush"];
        }
        var active = route switch { NavigationRoute.Library => LibraryButton, NavigationRoute.Catalog => CatalogButton, NavigationRoute.History => HistoryButton, _ => SettingsButton };
        active.Background = (Microsoft.UI.Xaml.Media.Brush)Application.Current.Resources["SurfaceBrush"];
        active.Foreground = (Microsoft.UI.Xaml.Media.Brush)Application.Current.Resources["TextPrimaryBrush"];
    }

    private void OnSessionActivityChanged(object? sender, bool active) => DispatcherQueue.TryEnqueue(() => UpdateNavigationLock(active));

    private void UpdateNavigationLock(bool locked)
    {
        if (locked == _navigationLocked) return;
        _navigationLocked = locked;
        foreach (var button in new[] { LibraryButton, CatalogButton, HistoryButton, SettingsButton }) button.IsEnabled = !locked;
    }
    private void Library_Click(object sender, RoutedEventArgs e) => Navigate(NavigationRoute.Library);
    private void Catalog_Click(object sender, RoutedEventArgs e) => Navigate(NavigationRoute.Catalog);
    private void History_Click(object sender, RoutedEventArgs e) => Navigate(NavigationRoute.History);
    private void Settings_Click(object sender, RoutedEventArgs e) => Navigate(NavigationRoute.Settings);
}
