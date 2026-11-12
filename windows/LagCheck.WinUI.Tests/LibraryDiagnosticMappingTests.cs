using System.Text.Json;
using LagCheck.WinUI.Library;
using Xunit;

namespace LagCheck.WinUI.Tests;

public sealed class LibraryDiagnosticMappingTests
{
    [Fact]
    public void Supported_snapshot_exposes_canonical_diagnostic_id()
    {
        var game = ParseGame("lagcheckSupported", "warzone");

        Assert.Equal(GameNetworkKind.Supported, game.NetworkKind);
        Assert.Equal("warzone", game.DiagnosticGameId);
        Assert.True(game.CanTestConnection);
    }

    [Fact]
    public void General_snapshot_discards_diagnostic_id_and_navigates_with_null()
    {
        var game = ParseGame("generalConnectionOnly", "steam_1938090");
        var navigator = new RecordingNavigator();
        var viewModel = new LibraryViewModel(EmptyBridge.Instance, navigator);

        viewModel.TestConnectionCommand.Execute(game);

        var request = Assert.Single(navigator.Requests);
        Assert.Equal(GameNetworkKind.General, request.NetworkKind);
        Assert.Null(request.DiagnosticGameId);
    }

    [Fact]
    public void Offline_game_never_navigates_to_diagnostic()
    {
        var game = ParseGame("offlineSingleplayer", null);
        var navigator = new RecordingNavigator();
        var viewModel = new LibraryViewModel(EmptyBridge.Instance, navigator);

        Assert.False(game.CanTestConnection);
        Assert.False(viewModel.TestConnectionCommand.CanExecute(game));
        viewModel.TestConnectionCommand.Execute(game);

        Assert.Empty(navigator.Requests);
    }

    [Fact]
    public void Supported_game_without_canonical_id_never_starts_diagnostic()
    {
        var game = ParseGame("lagcheckSupported", null);
        var navigator = new RecordingNavigator();
        var viewModel = new LibraryViewModel(EmptyBridge.Instance, navigator);

        Assert.False(game.CanTestConnection);
        Assert.False(viewModel.TestConnectionCommand.CanExecute(game));
        viewModel.TestConnectionCommand.Execute(game);

        Assert.Empty(navigator.Requests);
    }

    private static LibraryGame ParseGame(string networkKind, string? diagnosticGameId)
    {
        var diagnosticField = diagnosticGameId is null ? string.Empty : $", \"diagnosticGameId\": \"{diagnosticGameId}\"";
        using var document = JsonDocument.Parse($$"""
            {
              "isScanning": false,
              "hasScanned": true,
              "games": [
                {
                  "id": "steam_1938090",
                  "title": "Call of Duty",
                  "platform": "steam",
                  "isInstalled": true,
                  "isFavorite": false,
                  "isLaunchable": true,
                  "networkKind": "{{networkKind}}"{{diagnosticField}},
                  "tags": [],
                  "alsoIds": []
                }
              ]
            }
            """);

        return Assert.Single(LibraryWireParser.ParseSnapshot(document.RootElement).Games);
    }

    private sealed class RecordingNavigator : ILibraryDiagnosticNavigator
    {
        public List<ManualDiagnosticRequest> Requests { get; } = [];

        public bool NavigateToManualDiagnostic(ManualDiagnosticRequest request)
        {
            Requests.Add(request);
            return true;
        }
    }

    private sealed class EmptyBridge : ILibraryBridge
    {
        public static EmptyBridge Instance { get; } = new();

        public Task<LibrarySnapshot> GetSnapshotAsync(CancellationToken cancellationToken = default) =>
            Task.FromResult(new LibrarySnapshot(false, true, null, null, []));
        public Task<LibraryOperationResult> RescanAsync(CancellationToken cancellationToken = default) =>
            Task.FromResult(LibraryOperationResult.Failure("not used"));
        public Task<LibraryOperationResult> SetFavoriteAsync(string gameId, bool favorite, CancellationToken cancellationToken = default) =>
            Task.FromResult(LibraryOperationResult.Failure("not used"));
        public Task<LibraryOperationResult> SelectAsync(string gameId, CancellationToken cancellationToken = default) =>
            Task.FromResult(LibraryOperationResult.Failure("not used"));
        public Task<LibraryOperationResult> LaunchAsync(string gameId, CancellationToken cancellationToken = default) =>
            Task.FromResult(LibraryOperationResult.Failure("not used"));
        public Task<LibraryOperationResult> RefreshArtworkAsync(string gameId, CancellationToken cancellationToken = default) =>
            Task.FromResult(LibraryOperationResult.Failure("not used"));
        public Task<LibraryOperationResult> ResolveArtworkAsync(IReadOnlyList<string> gameIds, CancellationToken cancellationToken = default) =>
            Task.FromResult(LibraryOperationResult.Failure("not used"));
    }
}
