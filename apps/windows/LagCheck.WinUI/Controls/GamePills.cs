using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using LagCheck.WinUI.Library;
using LagCheck.WinUI.Localization;

#if WINDOWS
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;
#endif

namespace LagCheck.WinUI.Controls;

/// <summary>
/// Pílulas visuais de metadados da loja (gênero e modo) para o hero da Início e tela de Detalhes.
/// Cada rótulo fica em sua própria pílula para leitura imediata, substituindo frases concatenadas.
/// </summary>
public static class GamePills
{
    private static string StripDiacritics(string text)
    {
        var normalized = text.Normalize(NormalizationForm.FormD);
        var sb = new StringBuilder(normalized.Length);
        foreach (var c in normalized)
        {
            if (CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark)
                sb.Append(c);
        }
        return sb.ToString().Normalize(NormalizationForm.FormC).Trim();
    }

    private static bool IsPlatformName(string tag, LibraryGame game)
    {
        var clean = StripDiacritics(tag).ToLowerInvariant();
        if (clean is "pc" or "windows" or "steam" or "epic" or "epic games" or "epicgames" or "xbox" or "xbox / pc" or "xbox/pc" or "xbox pc" or "manual" or "pc local")
            return true;
        if (clean == StripDiacritics(game.PlatformLabel).ToLowerInvariant())
            return true;
        if (clean == StripDiacritics(game.Platform.ToString()).ToLowerInvariant())
            return true;
        return false;
    }

    private static readonly Dictionary<string, string> GenreCanonicalKeys = new(StringComparer.Ordinal)
    {
        ["simulacao"] = "Simulação",
        ["simulation"] = "Simulação",
        ["simulacion"] = "Simulação",
        ["acao"] = "Ação",
        ["action"] = "Ação",
        ["accion"] = "Ação",
        ["aventura"] = "Aventura",
        ["adventure"] = "Aventura",
        ["estrategia"] = "Estratégia",
        ["strategy"] = "Estratégia",
        ["rpg"] = "RPG",
        ["rol"] = "RPG",
        ["corrida"] = "Corrida",
        ["racing"] = "Corrida",
        ["carreras"] = "Corrida",
        ["esportes"] = "Esportes",
        ["desporto"] = "Esportes",
        ["sports"] = "Esportes",
        ["deportes"] = "Esportes",
        ["casual"] = "Casual",
        ["indie"] = "Indie",
        ["luta"] = "Luta",
        ["fighting"] = "Luta",
        ["lucha"] = "Luta",
        ["tiro"] = "Tiro",
        ["shooter"] = "Tiro",
        ["disparos"] = "Tiro",
        ["plataforma"] = "Plataforma",
        ["platformer"] = "Plataforma",
        ["plataformas"] = "Plataforma",
        ["cartas e tabuleiro"] = "Cartas e tabuleiro",
        ["card & board"] = "Cartas e tabuleiro",
        ["cartas y tablero"] = "Cartas e tabuleiro",
        ["classicos"] = "Clássicos",
        ["classics"] = "Clássicos",
        ["quebra-cabeca"] = "Quebra-cabeça",
        ["puzzle & trivia"] = "Quebra-cabeça",
        ["rompecabezas"] = "Quebra-cabeça",
        ["gratuito para jogar"] = "Gratuito para jogar",
        ["free to play"] = "Gratuito para jogar",
        ["gratis para jugar"] = "Gratuito para jogar",
        ["acesso antecipado"] = "Acesso Antecipado",
        ["early access"] = "Acesso Antecipado",
        ["acceso anticipado"] = "Acesso Antecipado",
        ["multijogador massivo"] = "Multijogador Massivo",
        ["massively multiplayer"] = "Multijogador Massivo",
        ["multijugador masivo"] = "Multijogador Massivo",
    };

    private static string TranslateGenreOrTag(string raw)
    {
        var trimmed = raw.Trim();
        var normalized = StripDiacritics(trimmed).ToLowerInvariant();
        return GenreCanonicalKeys.TryGetValue(normalized, out var canonical)
            ? Strings.Tr(canonical)
            : Strings.Tr(trimmed);
    }

    /// <summary>
    /// Extrai os rótulos prioritários da loja (até 2 gêneros e até 2 modos), com limite de até 4 rótulos,
    /// sem repetição e excluindo identificadores de plataforma.
    /// Sem informações de catálogo da loja, recorre a <see cref="LibraryGame.Tags"/> com o mesmo filtro.
    /// </summary>
    public static IReadOnlyList<string> Labels(LibraryGame game, int max = 4)
    {
        if (max <= 0) return Array.Empty<string>();

        var result = new List<string>(max);
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        bool TryAdd(string? label)
        {
            if (string.IsNullOrWhiteSpace(label)) return false;
            var trimmed = label.Trim();
            if (IsPlatformName(trimmed, game)) return false;
            var key = StripDiacritics(trimmed).ToLowerInvariant();
            if (!seen.Add(key)) return false;
            result.Add(trimmed);
            return result.Count >= max;
        }

        if (game.Info is { } info && (info.Genres.Count > 0 || info.Modes.Count > 0))
        {
            var genreCount = 0;
            foreach (var genre in info.Genres)
            {
                if (genreCount >= 2) break;
                if (string.IsNullOrWhiteSpace(genre)) continue;
                var before = result.Count;
                if (TryAdd(TranslateGenreOrTag(genre))) return result;
                if (result.Count > before) genreCount++; // só o que entrou conta; duplicatas não gastam a cota
            }

            var modeCount = 0;
            foreach (var mode in info.Modes)
            {
                if (modeCount >= 2) break;
                var label = GameInfo.ModeLabel(mode);
                if (label is null) continue;
                var before = result.Count;
                if (TryAdd(label)) return result;
                if (result.Count > before) modeCount++;
            }
        }
        else
        {
            foreach (var tag in game.Tags)
            {
                if (string.IsNullOrWhiteSpace(tag)) continue;
                if (TryAdd(TranslateGenreOrTag(tag))) return result;
            }
        }

        return result;
    }

#if WINDOWS
    /// <summary>
    /// Constrói o container com as pílulas separadas para renderização no hero ou em detalhes.
    /// Se não houver nenhum rótulo válido, retorna um elemento colapsado (nada é desenhado).
    /// </summary>
    public static FrameworkElement Create(LibraryGame game, int max = 4)
    {
        var labels = Labels(game, max);
        if (labels.Count == 0)
        {
            return new Border { Visibility = Visibility.Collapsed };
        }

        var panel = new WrapPanel
        {
            Spacing = 8,
        };

        var textBrush = Application.Current?.Resources.TryGetValue("TextPrimaryBrush", out var brushObj) == true && brushObj is Brush b
            ? b
            : new SolidColorBrush(Color.FromArgb(255, 0xF5, 0xF7, 0xFC));
        var backgroundBrush = new SolidColorBrush(Color.FromArgb(0xB3, 0x0B, 0x0D, 0x12));
        var borderBrush = new SolidColorBrush(Color.FromArgb(0x1F, 255, 255, 255));
        var semiBoldFont = Application.Current?.Resources.TryGetValue("BodySemiBoldFont", out var fontObj) == true && fontObj is FontFamily f
            ? f
            : Typography.BodySemiBoldFont;

        foreach (var label in labels)
        {
            var pill = new Border
            {
                Height = 28,
                CornerRadius = new CornerRadius(14),
                Background = backgroundBrush,
                BorderBrush = borderBrush,
                BorderThickness = new Thickness(1),
                Padding = new Thickness(12, 0, 12, 0),
                Child = new TextBlock
                {
                    Text = label,
                    FontFamily = semiBoldFont,
                    FontSize = 13,
                    FontWeight = Microsoft.UI.Text.FontWeights.Normal,
                    Foreground = textBrush,
                    VerticalAlignment = VerticalAlignment.Center,
                },
            };
            panel.Children.Add(pill);
        }

        return panel;
    }
#endif
}
