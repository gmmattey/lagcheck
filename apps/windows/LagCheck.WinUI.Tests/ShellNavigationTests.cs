using LagCheck.WinUI;
using Xunit;

namespace LagCheck.WinUI.Tests;

public sealed class ShellNavigationTests
{
    [Fact]
    public void OpenDiagnostic_and_NavigateToDiagnostic_invoke_configured_action()
    {
        string? passedGameId = null;
        string? passedTitle = null;

        ShellNavigation.Configure((id, title) =>
        {
            passedGameId = id;
            passedTitle = title;
        });

        var opened = ShellNavigation.OpenDiagnostic("game-1", "Warzone");
        Assert.True(opened);
        Assert.Equal("game-1", passedGameId);
        Assert.Equal("Warzone", passedTitle);

        var navigated = ShellNavigation.NavigateToDiagnostic("game-2", "Valorant");
        Assert.True(navigated);
        Assert.Equal("game-2", passedGameId);
        Assert.Equal("Valorant", passedTitle);
    }

    [Fact]
    public void Navigate_invokes_configured_route_action()
    {
        NavigationRoute? passedRoute = null;

        ShellNavigation.Configure((_, _) => { }, route =>
        {
            passedRoute = route;
        });

        var navigated = ShellNavigation.Navigate(NavigationRoute.Library);
        Assert.True(navigated);
        Assert.Equal(NavigationRoute.Library, passedRoute);
    }
}
