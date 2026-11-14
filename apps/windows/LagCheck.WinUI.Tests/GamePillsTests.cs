using System;
using System.Collections.Generic;
using LagCheck.WinUI.Controls;
using LagCheck.WinUI.Library;
using Xunit;

namespace LagCheck.WinUI.Tests;

public sealed class GamePillsTests
{
    private static LibraryGame MakeGame(
        GamePlatform platform = GamePlatform.Steam,
        GameInfo? info = null,
        IReadOnlyList<string>? tags = null)
    {
        return new LibraryGame(
            Id: "game_test_1",
            Title: "Super Game",
            Platform: platform,
            IsInstalled: true,
            IsFavorite: false,
            IsLaunchable: true,
            LastPlayedEpochMs: null,
            LastLaunchedEpochMs: null,
            InstalledAtEpochMs: null,
            CoverArtworkPath: null,
            HeroArtworkPath: null,
            NetworkKind: GameNetworkKind.Supported,
            DiagnosticGameId: "supergame",
            NetworkLabel: "Conexão suportada",
            Tags: tags ?? Array.Empty<string>(),
            Description: null,
            AlsoIds: Array.Empty<string>(),
            Info: info);
    }

    [Fact]
    public void Labels_PreservesOrder_GenresThenModes()
    {
        var info = new GameInfo(
            Description: null,
            Developer: null,
            Publisher: null,
            ReleaseDate: null,
            Genres: new[] { "Tiro", "Estratégia", "Corrida" },
            Modes: new[] { "online_multiplayer", "coop" });

        var game = MakeGame(info: info);
        var labels = GamePills.Labels(game);

        // Deve trazer no máximo 2 gêneros e depois os modos traduzidos
        Assert.Equal(4, labels.Count);
        Assert.Equal("Tiro", labels[0]);
        Assert.Equal("Estratégia", labels[1]);
        Assert.Equal("Multijogador online", labels[2]);
        Assert.Equal("Co-op", labels[3]);
    }

    [Fact]
    public void Labels_RespectsMaxLimit_Default4AndCustom()
    {
        var info = new GameInfo(
            Description: null,
            Developer: null,
            Publisher: null,
            ReleaseDate: null,
            Genres: new[] { "Ação", "Aventura", "RPG" },
            Modes: new[] { "online_multiplayer", "coop", "mmo" });

        var game = MakeGame(info: info);

        var defaultLabels = GamePills.Labels(game);
        Assert.Equal(4, defaultLabels.Count);

        var customLabels = GamePills.Labels(game, max: 2);
        Assert.Equal(2, customLabels.Count);
        Assert.Equal("Ação", customLabels[0]);
        Assert.Equal("Aventura", customLabels[1]);
    }

    [Fact]
    public void Labels_Deduplicates_IgnoringCaseAndAccents()
    {
        var info = new GameInfo(
            Description: null,
            Developer: null,
            Publisher: null,
            ReleaseDate: null,
            Genres: new[] { "Ação", "acao", "AÇÃO", "Aventura" },
            Modes: new[] { "singleplayer" });

        var game = MakeGame(info: info);
        var labels = GamePills.Labels(game);

        Assert.Equal(3, labels.Count);
        Assert.Equal("Ação", labels[0]);
        Assert.Equal("Aventura", labels[1]);
        Assert.Equal("Um jogador", labels[2]);
    }

    [Fact]
    public void Labels_FiltersOut_PlatformNames()
    {
        var info = new GameInfo(
            Description: null,
            Developer: null,
            Publisher: null,
            ReleaseDate: null,
            Genres: new[] { "Steam", "PC", "Windows", "Epic Games", "Xbox", "Tático" },
            Modes: new[] { "singleplayer" });

        var game = MakeGame(platform: GamePlatform.Steam, info: info);
        var labels = GamePills.Labels(game);

        Assert.Equal(2, labels.Count);
        Assert.Equal("Tático", labels[0]);
        Assert.Equal("Um jogador", labels[1]);
    }

    [Fact]
    public void Labels_FallsBackToTags_WhenInfoIsNull()
    {
        var game = MakeGame(
            platform: GamePlatform.EpicGames,
            info: null,
            tags: new[] { "PC", "Epic Games", "Sobrevivência", "Zumbis", "Terror", "Mundo Aberto", "Indie" });

        var labels = GamePills.Labels(game);

        // Deve filtrar "PC" e "Epic Games" e limitar a 4
        Assert.Equal(4, labels.Count);
        Assert.Equal("Sobrevivência", labels[0]);
        Assert.Equal("Zumbis", labels[1]);
        Assert.Equal("Terror", labels[2]);
        Assert.Equal("Mundo Aberto", labels[3]);
    }

    [Fact]
    public void Labels_FallsBackToTags_WhenInfoIsEmpty()
    {
        var emptyInfo = new GameInfo(
            Description: null,
            Developer: null,
            Publisher: null,
            ReleaseDate: null,
            Genres: Array.Empty<string>(),
            Modes: Array.Empty<string>());

        var game = MakeGame(
            info: emptyInfo,
            tags: new[] { "Steam", "Simulação", "Espaço" });

        var labels = GamePills.Labels(game);

        Assert.Equal(2, labels.Count);
        Assert.Equal("Simulação", labels[0]);
        Assert.Equal("Espaço", labels[1]);
    }

    [Fact]
    public void Labels_ReturnsEmpty_WhenNoLabelsAvailable()
    {
        var game = MakeGame(
            info: null,
            tags: new[] { "PC", "Steam", "Windows" });

        var labels = GamePills.Labels(game);
        Assert.Empty(labels);
    }
}
