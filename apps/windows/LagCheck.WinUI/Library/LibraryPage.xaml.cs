using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Animation;
using Windows.UI;
using LagCheck.WinUI.Controls;
using LagCheck.WinUI.Localization;

namespace LagCheck.WinUI.Library;

public sealed partial class LibraryPage : Page
{
    public LibraryViewModel ViewModel { get; }

    private readonly List<(LibraryFilter Filter, string Label, string? Logo, Button Chip)> _chips = new();
    private readonly HashSet<string> _animatedCardIds = new(StringComparer.Ordinal);

    public LibraryPage()
    {
        InitializeComponent();
        NavigationCacheMode = Microsoft.UI.Xaml.Navigation.NavigationCacheMode.Disabled;
        ViewModel = new LibraryViewModel(LibraryPageServices.Bridge, LibraryPageServices.DiagnosticNavigator);
        DataContext = ViewModel;
        BuildChips();
        GamesGrid.ElementPrepared += (_, e) => WireCard(e.Element, e.Index);
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
            (LibraryFilter.Manual, "PC local", Glyphs.Windows),
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
        SearchBox.PlaceholderText = Strings.Tr("Buscar na sua biblioteca");
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
            chip.Background = new SolidColorBrush(active ? Color.FromArgb(0xB8, 0x20, 0x26, 0x33) : Color.FromArgb(0xB8, 0x1C, 0x21, 0x2B));
            var foreground = new SolidColorBrush(active ? Color.FromArgb(255, 0xF5, 0xF7, 0xFC) : Color.FromArgb(255, 0x9A, 0xA3, 0xB5));
            chip.Foreground = foreground;
            var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8, VerticalAlignment = VerticalAlignment.Center };
            if (logo is not null) row.Children.Add(new SvgIcon { Data = logo, FillOnly = true, Size = 15, Foreground = new SolidColorBrush(Color.FromArgb(255, 0xF5, 0xF7, 0xFC)) });
            row.Children.Add(new TextBlock { Text = Strings.Tr(label), FontFamily = (FontFamily)Application.Current.Resources["BodyMediumFont"], FontSize = 13, FontWeight = Microsoft.UI.Text.FontWeights.Normal, Foreground = foreground });
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
                _animatedCardIds.Clear();
                DispatcherQueue.TryEnqueue(UpdateChips);
                break;
            case nameof(LibraryViewModel.SearchText):
            case nameof(LibraryViewModel.SelectedSort):
                _animatedCardIds.Clear();
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
        if (!ViewModel.HasVisibleGames)
        {
            if (EmptyResultsBorder.Visibility != Visibility.Visible)
            {
                EmptyResultsBorder.Visibility = Visibility.Visible;
                Choreo.FadeSlideIn(EmptyResultsBorder, dy: 10);
            }
        }
        else
        {
            EmptyResultsBorder.Visibility = Visibility.Collapsed;
        }
    }

    private async void LibraryPage_Loaded(object sender, RoutedEventArgs e)
    {
        _animatedCardIds.Clear();
        Choreo.FadeSlideIn(LibraryTitle, dy: 12, delayMs: 0);
        Choreo.FadeSlideIn(SearchBox, dy: 12, delayMs: 40);
        Choreo.FadeSlideIn(SortBox, dy: 12, delayMs: 40);
        Choreo.FadeSlideIn(FilterChips, dy: 12, delayMs: 80);
        UpdateChips();
        await ViewModel.LoadAsync();
        OnVisibleChanged();
        await Artwork.ResolveMissingAsync(ViewModel, ViewModel.VisibleGames.Take(48).ToList());
    }

    public void FocusSearch() => SearchBox?.Focus(FocusState.Programmatic);

    private async void Rescan_Click(object sender, RoutedEventArgs e)
    {
        _animatedCardIds.Clear();
        if (ViewModel.RefreshCommand.CanExecute(null)) ViewModel.RefreshCommand.Execute(null);
        await ViewModel.LoadAsync();
        await Artwork.ResolveMissingAsync(ViewModel, ViewModel.VisibleGames.Take(48).ToList());
    }

    private void Sort_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (ViewModel is null) return;
        if (sender is ComboBox { SelectedItem: ComboBoxItem { Tag: string tag } } && Enum.TryParse<LibrarySort>(tag, true, out var sort))
        {
            _animatedCardIds.Clear();
            ViewModel.SelectedSort = sort;
        }
    }

    private void Filter_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: string tag } && Enum.TryParse<LibraryFilter>(tag, true, out _))
        {
            _animatedCardIds.Clear();
            ViewModel.SelectFilterCommand.Execute(tag);
        }
    }

    private void WireCard(UIElement element, int index)
    {
        if (element is not Grid card) return;
        // O jogo do card vem do índice (não depende de DataContext, que o ItemsRepeater nem sempre preenche).
        var game = index >= 0 && index < ViewModel.VisibleGames.Count ? ViewModel.VisibleGames[index] : null;
        card.Tag = game;
        if (card.Children.OfType<Microsoft.UI.Xaml.Shapes.Rectangle>().FirstOrDefault(r => r.Name == "CardShadowCaster") is { } shadowCaster)
        {
            GlowEffect.AttachShadow(shadowCaster, Color.FromArgb(0xAA, 0, 0, 0), blur: 20f, offsetY: 7f);
        }
        Fluid.Prepare(card);
        DecorateCard(card);

        if (game is not null)
        {
            if (_animatedCardIds.Add(game.Id))
            {
                var delay = Math.Min(index, 8) * 35;
                Choreo.FadeSlideIn(card, dy: 14, delayMs: delay);
            }
            else
            {
                Choreo.Reset(card);
            }
        }

        card.Tapped -= GameCard_Tapped;
        card.PointerEntered -= Card_PointerEntered;
        card.PointerExited -= Card_PointerExited;
        card.PointerPressed -= Card_PointerPressed;
        card.PointerReleased -= Card_PointerReleased;
        card.KeyDown -= Card_KeyDown;
        card.GotFocus -= Card_PointerEntered;
        card.LostFocus -= Card_PointerExited;
        card.Tapped += GameCard_Tapped;
        card.PointerEntered += Card_PointerEntered;
        card.PointerExited += Card_PointerExited;
        card.PointerPressed += Card_PointerPressed;
        card.PointerReleased += Card_PointerReleased;
        card.KeyDown += Card_KeyDown;
        card.GotFocus += Card_PointerEntered;
        card.LostFocus += Card_PointerExited;
    }

    private void UnwireCard(UIElement element)
    {
        if (element is not Grid card) return;
        card.Tapped -= GameCard_Tapped;
        card.PointerEntered -= Card_PointerEntered;
        card.PointerExited -= Card_PointerExited;
        card.PointerPressed -= Card_PointerPressed;
        card.PointerReleased -= Card_PointerReleased;
        card.KeyDown -= Card_KeyDown;
        card.GotFocus -= Card_PointerEntered;
        card.LostFocus -= Card_PointerExited;
        card.Tag = null;
        Choreo.Reset(card);
        SetHover(card, false);
    }

    private void OpenCard(object sender)
    {
        if (sender is FrameworkElement { Tag: LibraryGame game })
        {
            if (ViewModel.SelectGameCommand.CanExecute(game)) ViewModel.SelectGameCommand.Execute(game);
            ShellNavigation.OpenGameDetails(game, NavigationRoute.Library);
        }
    }

    private void GameCard_Tapped(object sender, TappedRoutedEventArgs e)
    {
        // O botão ▶ do card tem a própria ação; o toque nele não abre os Detalhes.
        for (var node = e.OriginalSource as DependencyObject; node is not null && !ReferenceEquals(node, sender); node = VisualTreeHelper.GetParent(node))
            if (node is FrameworkElement { Name: PlayName }) return;
        OpenCard(sender);
    }

    private const string DecorName = "dyn";
    private const string PlayName = "dynPlay";

    /// <summary>Veredito do último teste e ▶ de jogar direto, só para jogos que têm dado real (sem inventar nada).</summary>
    private void DecorateCard(Grid card)
    {
        foreach (var old in card.Children.OfType<FrameworkElement>().Where(child => child.Name is DecorName or PlayName).ToList())
            card.Children.Remove(old);
        if (card.Tag is not LibraryGame game) return;
        var insertAt = Math.Max(card.Children.Count - 1, 0); // o anel de foco fica sempre por último

        var entry = string.IsNullOrWhiteSpace(game.DiagnosticGameId) ? null : LagCheck.WinUI.History.SessionHistoryServices.Store.Entries
            .FirstOrDefault(item => item.PingMs.HasValue && string.Equals(item.GameId, game.DiagnosticGameId, StringComparison.OrdinalIgnoreCase));
        if (entry is not null && Verdicts.ToneOf(entry.Verdict) != VerdictTone.Unknown)
        {
            var color = Verdicts.ColorOf(Verdicts.ToneOf(entry.Verdict));
            var chip = new Border
            {
                Name = DecorName,
                Background = new SolidColorBrush(Color.FromArgb(0xD9, 0x0D, 0x0F, 0x14)),
                BorderThickness = new Thickness(1),
                BorderBrush = new SolidColorBrush(Color.FromArgb(0x24, 255, 255, 255)),
                CornerRadius = new CornerRadius(8),
                Height = 30,
                Padding = new Thickness(10, 0, 12, 0),
                HorizontalAlignment = HorizontalAlignment.Left,
                VerticalAlignment = VerticalAlignment.Top,
                Margin = new Thickness(46, 10, 0, 0),
                IsHitTestVisible = false,
                Child = new StackPanel
                {
                    Orientation = Orientation.Horizontal,
                    Spacing = 7,
                    VerticalAlignment = VerticalAlignment.Center,
                    Children =
                    {
                        new Microsoft.UI.Xaml.Shapes.Ellipse { Width = 8, Height = 8, Fill = new SolidColorBrush(color), VerticalAlignment = VerticalAlignment.Center },
                        new TextBlock { Text = entry.PingLabel, FontFamily = (FontFamily)Application.Current.Resources["MetricFont"], FontSize = 13, VerticalAlignment = VerticalAlignment.Center },
                    },
                },
            };
            Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(chip, $"{Verdicts.Headline(Verdicts.ToneOf(entry.Verdict), true)} · {entry.PingLabel}");
            card.Children.Insert(insertAt++, chip);
        }

        if (game.IsInstalled && game.IsLaunchable)
        {
            var play = new Button
            {
                Name = PlayName,
                Width = 44,
                Height = 44,
                Padding = new Thickness(0),
                CornerRadius = new CornerRadius(10),
                Background = (Brush)Application.Current.Resources["PurpleBrush"],
                HorizontalAlignment = HorizontalAlignment.Right,
                VerticalAlignment = VerticalAlignment.Bottom,
                Margin = new Thickness(0, 0, 10, 10),
                Opacity = 0,
                Content = new FontIcon { Glyph = "", FontFamily = new FontFamily("Segoe Fluent Icons"), FontSize = 16, Foreground = new SolidColorBrush(Microsoft.UI.Colors.White) },
            };
            Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(play, Strings.Format("Jogar {0}", game.Title));
            ToolTipService.SetToolTip(play, Strings.Tr("JOGAR AGORA"));
            play.Click += async (_, _) =>
            {
                ShellChrome.Shell?.ShowToast(Strings.Format("Abrindo {0}…", game.Title));
                await ViewModel.LaunchAsync(game);
                if (!ViewModel.LastOperationSucceeded && !string.IsNullOrWhiteSpace(ViewModel.Notice)) ShellChrome.Shell?.ShowToast(ViewModel.Notice!);
            };
            play.GotFocus += (_, _) => Choreo.FadeTo(play, 1);
            play.LostFocus += (_, _) => Choreo.FadeTo(play, 0);
            card.Children.Insert(insertAt, play);
        }
    }

    private void Card_KeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (e.Key is Windows.System.VirtualKey.Enter or Windows.System.VirtualKey.Space)
        {
            e.Handled = true;
            OpenCard(sender);
        }
    }

    private void Card_PointerEntered(object sender, RoutedEventArgs e) => SetHover(sender, true);
    private void Card_PointerExited(object sender, RoutedEventArgs e) => SetHover(sender, false);
    private void Card_PointerPressed(object sender, PointerRoutedEventArgs e) { if (sender is UIElement card) Fluid.Press(card, true); }
    private void Card_PointerReleased(object sender, PointerRoutedEventArgs e) { if (sender is UIElement card) Fluid.Press(card, false); }

    private static void SetHover(object sender, bool hover)
    {
        if (sender is not Grid card) return;
        Fluid.Hover(card, hover);
        if (card.Children.LastOrDefault() is Border ring) Choreo.FadeTo(ring, hover ? 1 : 0, 200);
        if (card.Children.OfType<Button>().FirstOrDefault(child => child.Name == PlayName) is { } play) Choreo.FadeTo(play, hover ? 1 : 0, 160);
    }
}
