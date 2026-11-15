using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using LagCheck.WinUI.Library;
using Xunit;

namespace LagCheck.WinUI.Tests;

public sealed class StoreApiExtensionsWinUiTests
{
    private sealed class StubLibraryBridge(IReadOnlyList<LibraryGame> games) : ILibraryBridge
    {
        public Task<LibrarySnapshot> GetSnapshotAsync(CancellationToken cancellationToken = default) =>
            Task.FromResult(new LibrarySnapshot(false, true, games.Count > 0 ? games[0].Id : null, null, games));

        public Task<LibraryOperationResult> RescanAsync(CancellationToken cancellationToken = default) =>
            Task.FromResult(new LibraryOperationResult(true, null, null));

        public Task<LibraryOperationResult> SetFavoriteAsync(string gameId, bool favorite, CancellationToken cancellationToken = default) =>
            Task.FromResult(new LibraryOperationResult(true, null, null));

        public Task<LibraryOperationResult> SelectAsync(string gameId, CancellationToken cancellationToken = default) =>
            Task.FromResult(new LibraryOperationResult(true, null, null));

        public Task<LibraryOperationResult> LaunchAsync(string gameId, CancellationToken cancellationToken = default) =>
            Task.FromResult(new LibraryOperationResult(true, null, null));

        public Task<LibraryOperationResult> RefreshArtworkAsync(string gameId, CancellationToken cancellationToken = default) =>
            Task.FromResult(new LibraryOperationResult(true, null, null));

        public Task<LibraryOperationResult> ResolveArtworkAsync(IReadOnlyList<string> gameIds, CancellationToken cancellationToken = default) =>
            Task.FromResult(new LibraryOperationResult(true, null, null));
    }

    [Fact]
    public void WireParserParsesExtendedGameAndStoreInfoFields()
    {
        var logoPath = Path.Combine(Path.GetTempPath(), "lagcheck-test-logo.png").Replace("\\", "\\\\");
        var json = $$"""
        {
          "isScanning": false,
          "hasScanned": true,
          "heroGameId": "steam_730",
          "selectedGameId": "steam_730",
          "games": [
            {
              "id": "steam_730",
              "title": "Counter-Strike 2",
              "platform": "steam",
              "isInstalled": true,
              "isFavorite": true,
              "isLaunchable": true,
              "playTimeMinutes": 845,
              "sizeOnDiskBytes": 45000000000,
              "updateState": "downloading",
              "downloadBytesCompleted": 250000,
              "downloadBytesTotal": 1000000,
              "logoArtworkPath": "{{logoPath}}",
              "networkKind": "lagcheckSupported",
              "diagnosticGameId": "cs2",
              "networkLabel": "América do Sul",
              "tags": ["FPS"],
              "alsoIds": [],
              "info": {
                "description": "Tactical shooter.",
                "developer": "Valve",
                "publisher": "Valve",
                "releaseDate": "2023-09-27",
                "genres": ["Ação"],
                "modes": ["online_multiplayer"],
                "controllerSupport": "partial",
                "metacriticScore": 83,
                "recommendationsTotal": 4200000,
                "hasCloudSaves": true,
                "antiCheat": "VAC",
                "hasPtBr": true,
                "pcMinimumRequirements": "SO: Windows 10 · RAM: 8 GB",
                "storeScreenshots": ["https://cdn.example/s1.jpg", "https://cdn.example/s2.jpg"]
              }
            }
          ]
        }
        """;

        using var doc = JsonDocument.Parse(json);
        var snapshot = LibraryWireParser.ParseSnapshot(doc.RootElement);

        var game = Assert.Single(snapshot.Games);
        Assert.Equal(845L, game.PlayTimeMinutes);
        Assert.Equal(45_000_000_000L, game.SizeOnDiskBytes);
        Assert.Equal(GameUpdateState.Downloading, game.UpdateState);
        Assert.Equal(250_000L, game.DownloadBytesCompleted);
        Assert.Equal(1_000_000L, game.DownloadBytesTotal);
        Assert.NotNull(game.LogoArtworkPath);

        Assert.NotNull(game.Info);
        Assert.Equal("partial", game.Info!.ControllerSupport);
        Assert.Equal(83, game.Info.MetacriticScore);
        Assert.Equal(4_200_000, game.Info.RecommendationsTotal);
        Assert.True(game.Info.HasCloudSaves);
        Assert.Equal("VAC", game.Info.AntiCheat);
        Assert.True(game.Info.HasPtBr);
        Assert.Equal("SO: Windows 10 · RAM: 8 GB", game.Info.PcMinimumRequirements);
        Assert.Equal(2, game.Info.StoreScreenshots!.Count);
        Assert.False(game.Info.IsStrictlyOffline);
    }

    [Fact]
    public void GameInfoIsStrictlyOfflineOnlyWhenNoMultiplayerOrCoopModeExists()
    {
        var solo = new GameInfo(null, null, null, null, Array.Empty<string>(), new[] { "singleplayer" });
        var hybrid = new GameInfo(null, null, null, null, Array.Empty<string>(), new[] { "singleplayer", "online_coop" });
        var localMp = new GameInfo(null, null, null, null, Array.Empty<string>(), new[] { "singleplayer", "multiplayer" });

        Assert.True(solo.IsStrictlyOffline);
        Assert.False(hybrid.IsStrictlyOffline);
        Assert.False(localMp.IsStrictlyOffline);
    }

    [Fact]
    public async Task LibraryViewModelSortsByPlaytimeDescending()
    {
        LibraryGame MakeGame(string id, string title, long playTime) => new(
            id, title, GamePlatform.Steam, true, false, true, null, null, null, null, null,
            GameNetworkKind.General, null, "Conexão geral", Array.Empty<string>(), null, Array.Empty<string>(),
            PlayTimeMinutes: playTime);

        var games = new[]
        {
            MakeGame("steam_1", "Alpha", 30),
            MakeGame("steam_2", "Bravo", 900),
            MakeGame("steam_3", "Charlie", 120),
        };
        var vm = new LibraryViewModel(new StubLibraryBridge(games));
        await vm.LoadAsync();

        vm.SelectedSort = LibrarySort.Playtime;
        Assert.Equal(new[] { "steam_2", "steam_3", "steam_1" }, new[] { vm.VisibleGames[0].Id, vm.VisibleGames[1].Id, vm.VisibleGames[2].Id });
    }

    [Fact]
    public void SteamLiveStatsParserHandlesPlayersAndNewsSafely()
    {
        Assert.Equal(123456, SteamLiveStatsResolver.ParsePlayerCount("""{"response":{"player_count":123456,"result":1}}"""));
        Assert.Null(SteamLiveStatsResolver.ParsePlayerCount("""{"response":{"player_count":123456,"result":42}}"""));
        Assert.Null(SteamLiveStatsResolver.ParsePlayerCount("not json"));

        var newsJson = """
        {
          "appnews": {
            "appid": 730,
            "newsitems": [
              {"title": "Patch 1.4", "url": "https://store.steampowered.com/news/1", "author": "Valve", "feedlabel": "Steam Announcements", "date": 1730000000},
              {"title": "Bad Scheme", "url": "javascript:alert(1)", "author": "X", "feedlabel": "Y", "date": 1730000000},
              {"title": "Patch 1.3", "url": "https://store.steampowered.com/news/2", "author": "Valve", "feedlabel": "Updates", "date": 1729000000},
              {"title": "Patch 1.2", "url": "https://store.steampowered.com/news/3", "author": "Valve", "feedlabel": "Updates", "date": 1728000000},
              {"title": "Patch 1.1", "url": "https://store.steampowered.com/news/4", "author": "Valve", "feedlabel": "Updates", "date": 1727000000}
            ]
          }
        }
        """;

        var news = SteamLiveStatsResolver.ParseNews(newsJson, maxItems: 3);
        Assert.Equal(3, news.Count);
        Assert.Equal("Patch 1.4", news[0].Title);
        Assert.Equal("https://store.steampowered.com/news/1", news[0].Url);
        Assert.Equal("Patch 1.3", news[1].Title);
        Assert.Equal("Patch 1.2", news[2].Title);
    }

    [Fact]
    public void FormattedPlaytimeAndDiskSizeReflectExactUnits()
    {
        LibraryGame GameWith(long playMinutes, long? bytes) => new(
            "steam_1", "Test", GamePlatform.Steam, true, false, true, null, null, null, null, null,
            GameNetworkKind.General, null, "Conexão geral", Array.Empty<string>(), null, Array.Empty<string>(),
            PlayTimeMinutes: playMinutes, SizeOnDiskBytes: bytes);

        Assert.Null(GameWith(0, null).FormattedPlayTime);
        Assert.Equal("45 min", GameWith(45, null).FormattedPlayTime);
        Assert.Equal("12 h", GameWith(720, null).FormattedPlayTime);

        Assert.Equal(string.Format(CultureInfo.CurrentCulture, "{0:0} MB", 512), GameWith(0, 512L * 1024L * 1024L).FormattedSizeOnDisk);
        Assert.Equal(string.Format(CultureInfo.CurrentCulture, "{0:0.#} GB", 10), GameWith(0, 10L * 1024L * 1024L * 1024L).FormattedSizeOnDisk);
    }

    [Fact]
    public void LocalizedResolverParsesExtendedSteamAppDetailsFields()
    {
        var json = """
        {
          "730": {
            "success": true,
            "data": {
              "short_description": "Competitive FPS",
              "developers": ["Valve"],
              "publishers": ["Valve"],
              "release_date": {"date": "27 set. 2023"},
              "genres": [{"description": "Ação"}],
              "categories": [{"id": 2}, {"id": 23}, {"id": 8}],
              "controller_support": "full",
              "metacritic": {"score": 85},
              "recommendations": {"total": 250000},
              "supported_languages": "English, Português (Brasil)",
              "pc_requirements": {"minimum": "<strong>OS:</strong> Windows 10<br><strong>Memory:</strong> 8 GB RAM"},
              "screenshots": [{"path_full": "https://cdn.example/1.jpg"}]
            }
          }
        }
        """;

        var info = LocalizedGameInfoResolver.ParseSteamAppDetails(json, "730");
        Assert.NotNull(info);
        Assert.Equal("full", info!.ControllerSupport);
        Assert.Equal(85, info.MetacriticScore);
        Assert.Equal(250000, info.RecommendationsTotal);
        Assert.True(info.HasCloudSaves);
        Assert.Equal("VAC", info.AntiCheat);
        Assert.True(info.HasPtBr);
        Assert.True(info.IsStrictlyOffline);
        Assert.Contains("Windows 10", info.PcMinimumRequirements);
        Assert.Equal(new[] { "https://cdn.example/1.jpg" }, info.StoreScreenshots);
    }
}
