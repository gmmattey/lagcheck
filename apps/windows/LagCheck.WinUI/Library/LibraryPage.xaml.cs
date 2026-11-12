using System;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using LagCheck.WinUI.Localization;
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
        LocalizeUI();
        LocalizationService.Instance.LanguageChanged += OnLanguageChanged;
        Unloaded += (_, _) => LocalizationService.Instance.LanguageChanged -= OnLanguageChanged;
    }

    private void OnLanguageChanged() => DispatcherQueue.TryEnqueue(LocalizeUI);

    private void LocalizeUI()
    {
        LibraryTitle.Text = Strings.Tr("BIBLIOTECA");
        RescanButtonText.Text = Strings.Tr("Procurar jogos");
        ToolTipService.SetToolTip(RescanButton, Strings.Tr("Fazer varredura de launchers instalados"));
        SearchBox.PlaceholderText = Strings.Tr("Buscar na sua biblioteca (Ctrl+F)");

        SortNameItem.Content = Strings.Tr("Ordenar: Nome A–Z");
        SortRecentItem.Content = Strings.Tr("Ordenar: Mais recentes");
        SortPlatformItem.Content = Strings.Tr("Ordenar: Plataforma");
        SortFavoritesItem.Content = Strings.Tr("Ordenar: Favoritos primeiro");

        FilterAllBtn.Content = Strings.Tr("Todos os jogos");
        FilterInstalledBtn.Content = Strings.Tr("Instalados");
        FilterManualBtn.Content = Strings.Tr("PC local");
        FilterFavoritesBtn.Content = Strings.Tr("Favoritos");
        FilterRecentBtn.Content = Strings.Tr("Recentes");

        EmptyResultsText.Text = Strings.Tr("Nenhum jogo corresponde à busca ou ao filtro atual.");
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
