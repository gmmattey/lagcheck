using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.UI.Xaml.Media.Imaging;
using LagCheck.WinUI.Library;

namespace LagCheck.WinUI.Controls;

/// <summary>
/// Arte local dos jogos. A interface nunca baixa imagem sozinha: ela pede ao host (que respeita o ajuste
/// "Baixar imagens dos jogos") e só desenha arquivos que já existem em disco.
/// </summary>
public static class Artwork
{
    private static readonly HashSet<string> Requested = new(StringComparer.Ordinal);

    public static BitmapImage? Load(string? path, int decodeWidth = 0)
    {
        if (string.IsNullOrWhiteSpace(path)) return null;
        try
        {
            if (Uri.TryCreate(path, UriKind.Absolute, out var uri) && uri.IsFile && !File.Exists(uri.LocalPath)) return null;
            var image = new BitmapImage();
            if (decodeWidth > 0) image.DecodePixelWidth = decodeWidth;
            image.UriSource = new Uri(path);
            return image;
        }
        catch
        {
            return null;
        }
    }

    /// <summary>Retorna o caminho da primeira imagem existente em disco, ou null.</summary>
    public static string? FirstExisting(params string?[] paths) =>
        paths.FirstOrDefault(path => !string.IsNullOrWhiteSpace(path) && (!Uri.TryCreate(path, UriKind.Absolute, out var uri) || !uri.IsFile || File.Exists(uri.LocalPath)));

    /// <summary>Pede ao host as capas/banners que ainda faltam nos jogos visíveis (no máximo uma tentativa por jogo e sessão).</summary>
    public static async Task ResolveMissingAsync(LibraryViewModel viewModel, IEnumerable<LibraryGame> visible)
    {
        var pending = visible
            .Where(game => game.IsInstalled && (FirstExisting(game.CoverArtworkPath) is null || FirstExisting(game.HeroArtworkPath) is null))
            .Select(game => game.Id)
            .Where(id => Requested.Add(id))
            .ToList();
        for (var offset = 0; offset < pending.Count; offset += 8)
        {
            await viewModel.ResolveVisibleArtworkAsync(pending.Skip(offset).Take(8).ToArray());
        }
    }
}
