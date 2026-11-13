using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.UI;
using LagCheck.WinUI.Localization;

namespace LagCheck.WinUI.Controls;

public enum VerdictTone
{
    Ok,
    Warn,
    Bad,
    Unknown,
}

/// <summary>
/// Apresentação do veredito emitido pelo motor (ready / caution / not_ready). Nenhuma regra de nota mora aqui:
/// só traduz o veredito já calculado em cor, forma (não depende só de cor) e frase curta.
/// </summary>
public static class Verdicts
{
    public static VerdictTone ToneOf(string? raw)
    {
        var v = (raw ?? string.Empty).Trim().ToLowerInvariant().TrimStart('●', '▲', '—', ' ').Trim();
        // not_ready antes de ready: evita falso positivo de substring.
        if (v.StartsWith("not_ready") || v.Contains("evitaria") || v == "ruim") return VerdictTone.Bad;
        if (v.StartsWith("caution") || v.Contains("instáv") || v.Contains("instav")) return VerdictTone.Warn;
        if (v.StartsWith("ready") || v.Contains("pronto") || v == "boa") return VerdictTone.Ok;
        return VerdictTone.Unknown;
    }

    public static Color ColorOf(VerdictTone tone) => tone switch
    {
        VerdictTone.Ok => Color.FromArgb(255, 0x22, 0xC5, 0x5E),
        VerdictTone.Warn => Color.FromArgb(255, 0xF5, 0x9E, 0x0B),
        VerdictTone.Bad => Color.FromArgb(255, 0xFF, 0x5A, 0x36),
        _ => Color.FromArgb(255, 0x9A, 0xA3, 0xB5),
    };

    public static string Headline(VerdictTone tone, bool hasGame) => tone switch
    {
        VerdictTone.Ok => hasGame ? Strings.Tr("Pronto para ranked") : Strings.Tr("Pronto para jogar"),
        VerdictTone.Warn => hasGame ? Strings.Tr("Condições instáveis") : Strings.Tr("Atenção antes de jogar"),
        VerdictTone.Bad => hasGame ? Strings.Tr("Eu evitaria ranked agora") : Strings.Tr("Eu evitaria jogar online agora"),
        _ => Strings.Tr("Medição inconclusiva"),
    };

    public static string StatusWord(VerdictTone tone) => tone switch
    {
        VerdictTone.Ok => Strings.Tr("Conexão boa"),
        VerdictTone.Warn => Strings.Tr("Conexão instável"),
        VerdictTone.Bad => Strings.Tr("Conexão ruim"),
        _ => Strings.Tr("Conexão indeterminada"),
    };

    /// <summary>Marcador do v2: círculo = bom, quadrado = atenção, losango = ruim (forma além da cor).</summary>
    public static FrameworkElement Marker(VerdictTone tone, double size = 10)
    {
        var brush = new SolidColorBrush(ColorOf(tone));
        FrameworkElement marker = tone switch
        {
            VerdictTone.Ok => new Ellipse { Width = size, Height = size, Fill = brush },
            VerdictTone.Warn => new Rectangle { Width = size, Height = size, RadiusX = 2, RadiusY = 2, Fill = brush },
            VerdictTone.Bad => new Rectangle { Width = size, Height = size, Fill = brush, RenderTransformOrigin = new Windows.Foundation.Point(0.5, 0.5), RenderTransform = new RotateTransform { Angle = 45 } },
            _ => new Ellipse { Width = size, Height = size, Fill = brush },
        };
        marker.VerticalAlignment = VerticalAlignment.Center;
        return marker;
    }
}
