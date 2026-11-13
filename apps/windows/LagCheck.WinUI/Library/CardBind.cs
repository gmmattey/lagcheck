using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Media;
using LagCheck.WinUI.Controls;

namespace LagCheck.WinUI.Library;

/// <summary>Funções estáticas usadas por x:Bind nos cards da Biblioteca.</summary>
public static class CardBind
{
    public static ImageSource? Cover(string? path) => Artwork.Load(Artwork.FirstExisting(path), 380);
    public static string Logo(GamePlatform platform) => Glyphs.PlatformLogo(platform) ?? string.Empty;
    public static Visibility HasLogo(GamePlatform platform) => Glyphs.PlatformLogo(platform) is null ? Visibility.Collapsed : Visibility.Visible;
    public static Visibility NoLogo(GamePlatform platform) => Glyphs.PlatformLogo(platform) is null ? Visibility.Visible : Visibility.Collapsed;
    public static Visibility Show(bool value) => value ? Visibility.Visible : Visibility.Collapsed;
}
