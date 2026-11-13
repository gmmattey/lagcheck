using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Windows.UI;
using LagCheck.WinUI.Controls;
using LagCheck.WinUI.Localization;

namespace LagCheck.WinUI.Library;

public sealed partial class LibraryPage : Page
{
    public LibraryViewModel ViewModel { get; }

    private readonly List<(LibraryFilter Filter, string Label, string? Logo, Button Chip)> _chips = new();

    public LibraryPage()
    {
        InitializeComponent();
        NavigationCacheMode = Microsoft.UI.Xaml.Navigation.NavigationCacheMode.Disabled;
        ViewModel = new LibraryViewModel(LibraryPageServices.Bridge, LibraryPageServices.DiagnosticNavigator);
        DataContext = ViewModel;
        BuildChips();
        GamesGrid.ElementPrepared += (_, e) => WireCard(e.Element);
        GamesGrid.ElementClearing += (_, e) => UnwireCard(e.Element);
        LocalizeUI();
        ViewModel.PropertyChanged += OnViewModelChanged;
        ViewModel.VisibleGames.CollectionChanged += (_, _) => OnVisibleChanged();
        LocalizationService.Instance.LanguageChanged += OnLanguageChanged;
        Unloaded += (_, _) => LocalizationService.Instance.LanguageChanged -= OnLanguageChanged;
    }

    private void OnLanguageChanged() => DispatcherQueue.TryEnqueue(LocalizeUI);

    private void BuildChips()
    {
        var defs = new (LibraryFilter, string, string?)[]
        {
            (LibraryFilter.All, "Todos os jogos", null),
            (LibraryFilter.Installed, "Instalados", null),
            (LibraryFilter.Steam, "Steam", Glyphs.Steam),
            (LibraryFilter.Epic, "Epic Games", Glyphs.Epic),
            (LibraryFilter.Xbox, "Xbox", Glyphs.Xbox),
            (LibraryFilter.Manual, "PC local", null),
            (LibraryFilter.Favorites, "Favoritos", null),
            (LibraryFilter.Recent, "Recentes", null),
        };
        foreach (var (filter, label, logo) in defs)
        {
            var chip = new Button { Style = (Style)Application.Current.Resources["PillChipButtonStyle"], Tag = filter.ToString() };
            chip.Click += Filter_Click;
            _chips.Add((filter, label, logo, chip));
        }
        foreach (var item in _chips) FilterChips.Children.Add(item.Chip);
    }

    private void LocalizeUI()
    {
        LibraryTitle.Text = Strings.Tr("BIBLIOTECA");
        ToolTipService.SetToolTip(RescanButton, Strings.Tr("Fazer varredura de launchers instalados"));
        SearchBox.PlaceholderText = Strings.Tr("Buscar na sua biblioteca (Ctrl+F)");
        SortNameItem.Content = Strings.Tr("Ordenar: Nome A–Z");
        SortRecentItem.Content = Strings.Tr("Ordenar: Mais recentes");
        SortPlatformItem.Content = Strings.Tr("Ordenar: Plataforma");
        SortFavoritesItem.Content = Strings.Tr("Ordenar: Favoritos primeiro");
        EmptyResultsText.Text = Strings.Tr("Nenhum jogo corresponde à busca ou ao filtro atual.");
        UpdateRescanLabel();
        UpdateChips();
        UpdateCount();
    }

    private void UpdateRescanLabel() => RescanButtonText.Text = ViewModel.IsScanning ? Strings.Tr("Procurando…") : Strings.Tr("Procurar jogos");

    private void UpdateCount() => CountText.Text = ViewModel.GameCountLabel;

    private void UpdateChips()
    {
        foreach (var (filter, label, logo, chip) in _chips)
        {
            var active = ViewModel.SelectedFilter == filter;
            chip.Background = new SolidColorBrush(active ? Color.FromArgb(255, 0x20, 0x26, 0x33) : Color.FromArgb(255, 0x1C, 0x21, 0x2B));
            var foreground = new SolidColorBrush(active ? Color.FromArgb(255, 0xF5, 0xF7, 0xFC) : Color.FromArgb(255, 0x9A, 0xA3, 0xB5));
            chip.Foreground = foreground;
            var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8, VerticalAlignment = VerticalAlignment.Center };
            if (logo is not null) row.Children.Add(new SvgIcon { Data = logo, FillOnly = true, Size = 15, Foreground = new SolidColorBrush(Color.FromArgb(255, 0xF5, 0xF7, 0xFC)) });
            row.Children.Add(new TextBlock { Text = Strings.Tr(label), FontSize = 13, FontWeight = Microsoft.UI.Text.FontWeights.Medium, Foreground = foreground });
            chip.Content = row;
        }
    }

    private void OnViewModelChanged(object? sender, PropertyChangedEventArgs e)
    {
        switch (e.PropertyName)
        {
            case nameof(LibraryViewModel.IsScanning):
                DispatcherQueue.TryEnqueue(UpdateRescanLabel);
                break;
            case nameof(LibraryViewModel.SelectedFilter):
                DispatcherQueue.TryEnqueue(UpdateChips);
                break;
            case nameof(LibraryViewModel.HasVisibleGames):
            case nameof(LibraryViewModel.GameCountLabel):
                DispatcherQueue.TryEnqueue(OnVisibleChanged);
                break;
        }
    }

    private void OnVisibleChanged()
    {
        UpdateCount();
        EmptyResultsBorder.Visibility = ViewModel.HasVisibleGames ? Visibility.Collapsed : Visibility.Visible;
    }

    private async void LibraryPage_Loaded(object sender, RoutedEventArgs e)
    {
        UpdateChips();
        await ViewModel.LoadAsync();
        OnVisibleChanged();
        await Artwork.ResolveMissingAsync(ViewModel, ViewModel.VisibleGames.Take(48).ToList());
    }

    public void FocusSearch() => SearchBox?.Focus(FocusState.Programmatic);

    private async void Rescan_Click(object sender, RoutedEventArgs e)
    {
        if (ViewModel.RefreshCommand.CanExecute(null)) ViewModel.RefreshCommand.Execute(null);
        await ViewModel.LoadAsync();
        await Artwork.ResolveMissingAsync(ViewModel, ViewModel.VisibleGames.Take(48).ToList());
    }

    private void Sort_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (ViewModel is null) return;
        if (sender is ComboBox { SelectedItem: ComboBoxItem { Tag: string tag } } && Enum.TryParse<LibrarySort>(tag, true, out var sort))
            ViewModel.SelectedSort = sort;
    }

    private void Filter_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: string tag } && Enum.TryParse<LibraryFilter>(tag, true, out _))
            ViewModel.SelectFilterCommand.Execute(tag);
    }

    private void WireCard(UIElement element)
    {
        if (element is not Grid card) return;
        card.Tapped += GameCard_Tapped;
        card.PointerEntered += Card_PointerEntered;
        card.PointerExited += Card_PointerExited;
    }

    private void UnwireCard(UIElement element)
    {
        if (element is not Grid card) return;
        card.Tapped -= GameCard_Tapped;
        card.PointerEntered -= Card_PointerEntered;
        card.PointerExited -= Card_PointerExited;
        SetHover(card, false);
    }

    private void GameCard_Tapped(object sender, TappedRoutedEventArgs e)
    {
        if (sender is FrameworkElement { DataContext: LibraryGame game })
        {
            if (ViewModel.SelectGameCommand.CanExecute(game)) ViewModel.SelectGameCommand.Execute(game);
            ShellNavigation.OpenGameDetails(game, NavigationRoute.Library);
        }
    }

    private void Card_PointerEntered(object sender, PointerRoutedEventArgs e) => SetHover(sender, true);
    private void Card_PointerExited(object sender, PointerRoutedEventArgs e) => SetHover(sender, false);

    private static void SetHover(object sender, bool hover)
    {
        if (sender is not Grid card) return;
        if (card.RenderTransform is CompositeTransform transform) transform.TranslateY = hover ? -4 : 0;
        if (card.Children.LastOrDefault() is Border ring) ring.Opacity = hover ? 1 : 0;
    }
}
