using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using System.Windows.Input;

namespace LagCheck.WinUI.Library;

public sealed class LibraryViewModel : INotifyPropertyChanged
{
    private readonly ILibraryBridge _bridge;
    private readonly ILibraryDiagnosticNavigator _diagnosticNavigator;
    private IReadOnlyList<LibraryGame> _games = Array.Empty<LibraryGame>();
    private string _searchText = string.Empty;
    private LibraryFilter _selectedFilter = LibraryFilter.Installed;
    private LibraryGame? _heroGame;
    private LibraryGame? _selectedGame;
    private string? _notice;
    private bool _isScanning;
    private bool _hasScanned;

    public LibraryViewModel(ILibraryBridge bridge, ILibraryDiagnosticNavigator? diagnosticNavigator = null)
    {
        _bridge = bridge ?? throw new ArgumentNullException(nameof(bridge));
        _diagnosticNavigator = diagnosticNavigator ?? UnavailableLibraryDiagnosticNavigator.Instance;
        VisibleGames = new ObservableCollection<LibraryGame>();
        RefreshCommand = new AsyncCommand(_ => RefreshAsync());
        SelectFilterCommand = new AsyncCommand(SetFilterAsync);
        SelectGameCommand = new AsyncCommand(SelectGameAsync);
        ToggleFavoriteCommand = new AsyncCommand(ToggleFavoriteAsync);
        LaunchCommand = new AsyncCommand(LaunchAsync, game => game is LibraryGame item && item.IsInstalled && item.IsLaunchable);
        TestConnectionCommand = new AsyncCommand(TestConnectionAsync, game => game is LibraryGame item && item.CanTestConnection);
        RefreshArtworkCommand = new AsyncCommand(RefreshArtworkAsync, game => game is LibraryGame item && item.IsInstalled);
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    public ObservableCollection<LibraryGame> VisibleGames { get; }
    public ICommand RefreshCommand { get; }
    public ICommand SelectFilterCommand { get; }
    public ICommand SelectGameCommand { get; }
    public ICommand ToggleFavoriteCommand { get; }
    public ICommand LaunchCommand { get; }
    public ICommand TestConnectionCommand { get; }
    public ICommand RefreshArtworkCommand { get; }

    public string SearchText
    {
        get => _searchText;
        set
        {
            if (!Set(ref _searchText, value ?? string.Empty)) return;
            RefreshVisibleGames();
        }
    }

    public LibraryFilter SelectedFilter
    {
        get => _selectedFilter;
        private set
        {
            if (!Set(ref _selectedFilter, value)) return;
            OnPropertyChanged(nameof(SelectedFilterLabel));
            RefreshVisibleGames();
        }
    }

    public string SelectedFilterLabel => SelectedFilter switch
    {
        LibraryFilter.All => "TODOS",
        LibraryFilter.Installed => "INSTALADOS",
        LibraryFilter.Recent => "RECENTES",
        LibraryFilter.Favorites => "FAVORITOS",
        LibraryFilter.Steam => "STEAM",
        _ => "EPIC GAMES",
    };

    public LibraryGame? HeroGame { get => _heroGame; private set => Set(ref _heroGame, value); }
    public LibraryGame? SelectedGame { get => _selectedGame; private set => Set(ref _selectedGame, value); }
    public string? Notice { get => _notice; private set => Set(ref _notice, value); }
    public bool IsScanning { get => _isScanning; private set => Set(ref _isScanning, value); }
    public bool HasScanned { get => _hasScanned; private set => Set(ref _hasScanned, value); }
    public bool HasGames => _games.Count > 0;
    public bool HasVisibleGames => VisibleGames.Count > 0;
    public string GameCountLabel => $"{VisibleGames.Count} {(VisibleGames.Count == 1 ? "JOGO" : "JOGOS")}";

    public async Task LoadAsync()
    {
        try
        {
            ApplySnapshot(await _bridge.GetSnapshotAsync());
            // O host nasce sem scan automático para não bloquear a inicialização da janela.
            // A Biblioteca mantém a experiência anterior: a primeira abertura procura os launchers reais.
            if (!HasScanned && !IsScanning) await RefreshAsync();
            else if (IsScanning) await WaitForScanCompletionAsync();
        }
        catch (Exception) { Notice = "Não foi possível ler a biblioteca local agora."; }
    }

    private async Task RefreshAsync()
    {
        try
        {
            // library.rescan confirma logo o início da varredura e entrega o snapshot final em
            // outro evento. Aplicar só a primeira resposta congelava a UI vazia para sempre.
            ApplyResult(await _bridge.RescanAsync());
            if (IsScanning) await WaitForScanCompletionAsync();
        }
        catch (Exception) { Notice = "Não foi possível procurar os jogos agora."; }
    }

    private async Task WaitForScanCompletionAsync()
    {
        // Steam/Epic podem estar em disco lento. Consultamos o host canônico, sem repetir scan,
        // por até 30 s; o resultado continua sendo o LibraryRepository persistido no Kotlin.
        const int attempts = 150;
        for (var attempt = 0; attempt < attempts; attempt++)
        {
            await Task.Delay(TimeSpan.FromMilliseconds(200));
            var snapshot = await _bridge.GetSnapshotAsync();
            ApplySnapshot(snapshot);
            if (!snapshot.IsScanning) return;
        }

        Notice = "A busca continua em segundo plano. Atualize a biblioteca em instantes.";
    }

    private Task SetFilterAsync(object? parameter)
    {
        if (parameter is string value && Enum.TryParse<LibraryFilter>(value, true, out var filter)) SelectedFilter = filter;
        return Task.CompletedTask;
    }

    private async Task SelectGameAsync(object? parameter)
    {
        if (parameter is not LibraryGame game) return;
        try { ApplyResult(await _bridge.SelectAsync(game.Id)); }
        catch (Exception) { Notice = "Não foi possível selecionar esse jogo."; }
    }

    private async Task ToggleFavoriteAsync(object? parameter)
    {
        if (parameter is not LibraryGame game) return;
        try { ApplyResult(await _bridge.SetFavoriteAsync(game.Id, !game.IsFavorite)); }
        catch (Exception) { Notice = "Não foi possível atualizar os favoritos."; }
    }

    private async Task LaunchAsync(object? parameter)
    {
        if (parameter is not LibraryGame game || !game.IsInstalled || !game.IsLaunchable) return;
        try { ApplyResult(await _bridge.LaunchAsync(game.Id)); }
        catch (Exception) { Notice = "Não foi possível pedir a abertura do jogo."; }
    }

    private Task TestConnectionAsync(object? parameter)
    {
        if (parameter is not LibraryGame game || !game.IsInstalled || game.NetworkKind == GameNetworkKind.Offline) return Task.CompletedTask;
        if (game.NetworkKind == GameNetworkKind.Supported && string.IsNullOrWhiteSpace(game.DiagnosticGameId))
        {
            Notice = "Este jogo não tem um mapeamento de diagnóstico homologado.";
            return Task.CompletedTask;
        }

        // A medição geral recebe null. Para homologados, somente o id canônico
        // emitido pelo host Kotlin pode cruzar a fronteira para o motor.
        var request = new ManualDiagnosticRequest(game.DiagnosticGameId, game.Title, game.NetworkKind);
        if (!_diagnosticNavigator.NavigateToManualDiagnostic(request))
        {
            Notice = "O Check manual não está disponível neste momento.";
        }
        return Task.CompletedTask;
    }

    private async Task RefreshArtworkAsync(object? parameter)
    {
        if (parameter is not LibraryGame game || !game.IsInstalled) return;
        try { ApplyResult(await _bridge.RefreshArtworkAsync(game.Id)); }
        catch (Exception) { Notice = "Não foi possível atualizar a imagem agora."; }
    }

    /// <summary>Chamado pela viewport da Page, nunca por todos os jogos conhecidos.</summary>
    public async Task ResolveVisibleArtworkAsync(IReadOnlyList<string> gameIds)
    {
        var ids = gameIds.Where(id => !string.IsNullOrWhiteSpace(id))
            .Distinct(StringComparer.Ordinal)
            .Where(id => _games.Any(game => game.Id == id))
            .Take(8)
            .ToArray();
        if (ids.Length == 0) return;

        try { ApplyResult(await _bridge.ResolveArtworkAsync(ids)); }
        // A imagem é complementar: o tile neutro continua correto se o host/cache estiver indisponível.
        catch (Exception) { }
    }

    private void ApplyResult(LibraryOperationResult result)
    {
        Notice = result.Message;
        if (result.Snapshot is not null) ApplySnapshot(result.Snapshot);
    }

    private void ApplySnapshot(LibrarySnapshot snapshot)
    {
        _games = snapshot.Games ?? Array.Empty<LibraryGame>();
        IsScanning = snapshot.IsScanning;
        HasScanned = snapshot.HasScanned;
        Notice = snapshot.Notice ?? Notice;
        HeroGame = Find(snapshot.HeroGameId) ?? _games.FirstOrDefault(game => game.IsInstalled);
        SelectedGame = Find(snapshot.SelectedGameId) ?? HeroGame;
        OnPropertyChanged(nameof(HasGames));
        RefreshVisibleGames();
    }

    private LibraryGame? Find(string? id) => id is null ? null : _games.FirstOrDefault(game => game.Id == id);

    private void RefreshVisibleGames()
    {
        var query = _games.Where(MatchesFilter)
            .Where(MatchesSearch)
            .OrderByDescending(game => game.RecentActivityEpochMs ?? long.MinValue)
            .ThenBy(game => game.Title, StringComparer.CurrentCultureIgnoreCase)
            .ThenBy(game => game.Id, StringComparer.Ordinal)
            .ToList();
        VisibleGames.Clear();
        foreach (var game in query) VisibleGames.Add(game);
        OnPropertyChanged(nameof(HasVisibleGames));
        OnPropertyChanged(nameof(GameCountLabel));
    }

    private bool MatchesFilter(LibraryGame game) => SelectedFilter switch
    {
        LibraryFilter.Installed => game.IsInstalled,
        LibraryFilter.Recent => game.RecentActivityEpochMs.HasValue,
        LibraryFilter.Favorites => game.IsFavorite,
        LibraryFilter.Steam => game.Platform == GamePlatform.Steam,
        LibraryFilter.Epic => game.Platform == GamePlatform.EpicGames,
        _ => true,
    };

    private bool MatchesSearch(LibraryGame game)
    {
        if (string.IsNullOrWhiteSpace(SearchText)) return true;
        var search = SearchText.Trim();
        return game.Title.Contains(search, StringComparison.CurrentCultureIgnoreCase)
            || game.Tags.Any(tag => tag.Contains(search, StringComparison.CurrentCultureIgnoreCase));
    }

    private bool Set<T>(ref T field, T value, [CallerMemberName] string? propertyName = null)
    {
        if (EqualityComparer<T>.Default.Equals(field, value)) return false;
        field = value;
        OnPropertyChanged(propertyName);
        return true;
    }

    private void OnPropertyChanged([CallerMemberName] string? propertyName = null) => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
}
