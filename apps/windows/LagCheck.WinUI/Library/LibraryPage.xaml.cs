using System;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using LagCheck.WinUI.Pages;

namespace LagCheck.WinUI.Library;

public sealed partial class LibraryPage : Page
{
    public LibraryViewModel ViewModel { get; }

    public LibraryPage()
    {
        InitializeComponent();
        ViewModel = new LibraryViewModel(LibraryPageServices.Bridge, LibraryPageServices.DiagnosticNavigator);
        DataContext = ViewModel;
    }

    private async void LibraryPage_Loaded(object sender, RoutedEventArgs e)
    {
        await ViewModel.LoadAsync();
    }

    public void FocusSearch()
    {
        SearchBox?.Focus(FocusState.Programmatic);
    }

    private async void Rescan_Click(object sender, RoutedEventArgs e)
    {
        if (ViewModel.RefreshCommand.CanExecute(null))
        {
            ViewModel.RefreshCommand.Execute(null);
        }
        await ViewModel.LoadAsync();
    }

    private void Sort_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (sender is ComboBox { SelectedItem: ComboBoxItem item } && item.Tag is string tag)
        {
            if (Enum.TryParse<LibrarySort>(tag, true, out var sort))
            {
                ViewModel.SelectedSort = sort;
            }
        }
    }

    private void Filter_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: string tag })
        {
            if (Enum.TryParse<LibraryFilter>(tag, true, out var filter))
            {
                ViewModel.SelectFilterCommand.Execute(tag);
            }
        }
    }

    private void GameCard_Click(object sender, ItemClickEventArgs e)
    {
        if (e.ClickedItem is LibraryGame game)
        {
            Frame.Navigate(typeof(GameDetailsPage), game);
        }
    }
}
