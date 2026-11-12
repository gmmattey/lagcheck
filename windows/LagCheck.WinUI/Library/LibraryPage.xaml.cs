using System;
using System.Collections.Generic;
using System.Linq;
using System.ComponentModel;
using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace LagCheck.WinUI.Library;

public sealed partial class LibraryPage : Page
{
    private readonly HashSet<string> _queuedArtworkIds = new(StringComparer.Ordinal);
    private readonly HashSet<string> _requestedArtworkIds = new(StringComparer.Ordinal);
    private readonly DispatcherQueueTimer _artworkDebounce;
    private bool _artworkRequestInFlight;
    public LibraryViewModel ViewModel { get; }

    public LibraryPage() : this(LibraryPageServices.Bridge, LibraryPageServices.DiagnosticNavigator)
    {
    }

    public LibraryPage(ILibraryBridge bridge, ILibraryDiagnosticNavigator? diagnosticNavigator = null)
    {
        InitializeComponent();
        ViewModel = new LibraryViewModel(bridge, diagnosticNavigator);
        DataContext = ViewModel;
        ViewModel.PropertyChanged += ViewModelOnPropertyChanged;
        _artworkDebounce = DispatcherQueue.CreateTimer();
        _artworkDebounce.Interval = TimeSpan.FromMilliseconds(90);
        _artworkDebounce.Tick += ArtworkDebounce_Tick;
    }

    private async void LibraryPage_Loaded(object sender, RoutedEventArgs e)
    {
        await ViewModel.LoadAsync();
        QueueHeroArtwork();
        UpdateVisualStates();
    }

    private void SearchBox_TextChanged(object sender, TextChangedEventArgs e)
    {
        ViewModel.SearchText = SearchBox.Text;
        UpdateVisualStates();
    }

    private void ViewModelOnPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName is nameof(LibraryViewModel.HasGames) or nameof(LibraryViewModel.HasVisibleGames) or nameof(LibraryViewModel.HeroGame) or nameof(LibraryViewModel.Notice) or nameof(LibraryViewModel.IsScanning))
        {
            DispatcherQueue.TryEnqueue(() =>
            {
                if (e.PropertyName == nameof(LibraryViewModel.HeroGame)) QueueHeroArtwork();
                UpdateVisualStates();
            });
        }
    }

    private void GameGrid_ElementPrepared(ItemsRepeater sender, ItemsRepeaterElementPreparedEventArgs args)
    {
        // O repeater só prepara o viewport e sua pequena área de reciclagem. Não enumeramos a biblioteca inteira.
        if (args.Index >= 0 && args.Index < ViewModel.VisibleGames.Count)
        {
            QueueArtwork(ViewModel.VisibleGames[args.Index]);
        }
    }

    private void QueueHeroArtwork() => QueueArtwork(ViewModel.HeroGame);

    private void QueueArtwork(LibraryGame? game)
    {
        if (game is null || (!string.IsNullOrWhiteSpace(game.CoverArtworkPath) && !string.IsNullOrWhiteSpace(game.HeroArtworkPath))) return;
        if (_requestedArtworkIds.Contains(game.Id)) return;
        _queuedArtworkIds.Add(game.Id);
        if (!_artworkRequestInFlight) _artworkDebounce.Start();
    }

    private async void ArtworkDebounce_Tick(DispatcherQueueTimer sender, object args)
    {
        sender.Stop();
        if (_artworkRequestInFlight || _queuedArtworkIds.Count == 0) return;
        _artworkRequestInFlight = true;
        var ids = _queuedArtworkIds.Take(8).ToArray();
        foreach (var id in ids)
        {
            _queuedArtworkIds.Remove(id);
            _requestedArtworkIds.Add(id);
        }
        try { await ViewModel.ResolveVisibleArtworkAsync(ids); }
        finally
        {
            _artworkRequestInFlight = false;
            if (_queuedArtworkIds.Count > 0) _artworkDebounce.Start();
        }
    }

    private void UpdateVisualStates()
    {
        var hasGames = ViewModel.HasGames;
        HeroSection.Visibility = ViewModel.HeroGame is null ? Visibility.Collapsed : Visibility.Visible;
        LibraryControls.Visibility = hasGames ? Visibility.Visible : Visibility.Collapsed;
        LoadingState.Visibility = ViewModel.IsScanning ? Visibility.Visible : Visibility.Collapsed;
        EmptyState.Visibility = hasGames || ViewModel.IsScanning ? Visibility.Collapsed : Visibility.Visible;
        NoResults.Visibility = hasGames && !ViewModel.HasVisibleGames ? Visibility.Visible : Visibility.Collapsed;
        GameGrid.Visibility = ViewModel.HasVisibleGames ? Visibility.Visible : Visibility.Collapsed;
        NoticeText.Visibility = string.IsNullOrWhiteSpace(ViewModel.Notice) ? Visibility.Collapsed : Visibility.Visible;
    }
}
