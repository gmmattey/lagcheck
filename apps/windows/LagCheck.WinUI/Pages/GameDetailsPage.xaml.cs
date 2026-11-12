using System;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media.Imaging;
using Microsoft.UI.Xaml.Navigation;
using LagCheck.WinUI.Library;

namespace LagCheck.WinUI.Pages;

public sealed partial class GameDetailsPage : Page
{
    private LibraryGame? _game;
    private readonly ILibraryBridge _bridge;

    public GameDetailsPage()
    {
        InitializeComponent();
        _bridge = LibraryPageServices.Bridge;
    }

    protected override void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        if (e.Parameter is LibraryGame game)
        {
            _game = game;
            BindGame();
        }
    }

    private void BindGame()
    {
        if (_game == null) return;

        GameTitleText.Text = _game.Title;
        PlatformText.Text = _game.PlatformLabel;
        MetaPlatformText.Text = _game.PlatformLabel;
        MetaNetworkText.Text = _game.DiagnosticLabel;

        TagsList.ItemsSource = _game.Tags.Count > 0 ? _game.Tags : new[] { "PC", _game.PlatformLabel };

        if (!string.IsNullOrWhiteSpace(_game.HeroArtworkPath))
        {
            try
            {
                BannerImage.Source = new BitmapImage(new Uri(_game.HeroArtworkPath));
            }
            catch
            {
                BannerImage.Source = null;
            }
        }
        else
        {
            BannerImage.Source = null;
        }

        CheckConnBtn.Visibility = _game.CanTestConnection ? Visibility.Visible : Visibility.Collapsed;
    }

    private void GoBack_Click(object sender, RoutedEventArgs e)
    {
        if (Frame.CanGoBack) Frame.GoBack();
        else Frame.Navigate(typeof(Library.LibraryPage));
    }

    private async void Launch_Click(object sender, RoutedEventArgs e)
    {
        if (_game != null && _game.IsInstalled && _game.IsLaunchable)
        {
            try
            {
                await _bridge.LaunchAsync(_game.Id);
            }
            catch
            {
                // Tratamento gracioso
            }
        }
    }

    private void CheckConnection_Click(object sender, RoutedEventArgs e)
    {
        if (_game != null)
        {
            ShellNavigation.NavigateToDiagnostic(_game.DiagnosticGameId, _game.Title);
        }
    }

    private async void ToggleFavorite_Click(object sender, RoutedEventArgs e)
    {
        if (_game != null)
        {
            try
            {
                await _bridge.SetFavoriteAsync(_game.Id, !_game.IsFavorite);
            }
            catch
            {
                // Tratamento gracioso
            }
        }
    }
}
