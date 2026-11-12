using System;
using System.Linq;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media.Imaging;
using LagCheck.WinUI.Library;

namespace LagCheck.WinUI.Pages;

public sealed partial class HomePage : Page
{
    public LibraryViewModel ViewModel { get; }

    public HomePage()
    {
        InitializeComponent();
        ViewModel = new LibraryViewModel(LibraryPageServices.Bridge, LibraryPageServices.DiagnosticNavigator);
        DataContext = ViewModel;
    }

    private async void HomePage_Loaded(object sender, RoutedEventArgs e)
    {
        await ViewModel.LoadAsync();
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
            return;
        }

        GameHeroPanel.Visibility = Visibility.Visible;
        EmptyHeroPanel.Visibility = Visibility.Collapsed;

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
