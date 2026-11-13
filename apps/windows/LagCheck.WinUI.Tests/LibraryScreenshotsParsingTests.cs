using System.Text.Json;
using LagCheck.WinUI.Library;
using Xunit;

namespace LagCheck.WinUI.Tests;

public sealed class LibraryScreenshotsParsingTests
{
    private static LibraryGame Parse(string extra)
    {
        using var document = JsonDocument.Parse($$"""
            {"games":[{"id":"steam_42","title":"Jogo","platform":"steam","isInstalled":true,"networkKind":"generalConnectionOnly","tags":[],"alsoIds":[]{{extra}}}]}
            """);
        return Assert.Single(LibraryWireParser.ParseSnapshot(document.RootElement).Games);
    }

    [Fact]
    public void LeCapturasLocaisComMetadados()
    {
        var game = Parse(""","screenshots":[{"path":"C:\\Steam\\a.jpg","thumbnailPath":"C:\\Steam\\t\\a.jpg","createdEpochMs":1000,"width":1920,"height":1080}]""");
        var shot = Assert.Single(game.UserScreenshots);
        Assert.Equal(@"C:\Steam\a.jpg", shot.Path);
        Assert.Equal(@"C:\Steam\t\a.jpg", shot.ThumbnailPath);
        Assert.Equal(1000, shot.CreatedEpochMs);
        Assert.Equal(1920, shot.Width);
    }

    [Fact]
    public void DescartaUrlRemotaEJogoSemCapturasFicaVazio()
    {
        Assert.Empty(Parse(""","screenshots":[{"path":"https://exemplo.com/a.jpg"}]""").UserScreenshots);
        Assert.Empty(Parse("").UserScreenshots);
    }
}
