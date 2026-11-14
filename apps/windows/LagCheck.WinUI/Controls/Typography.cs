using Microsoft.UI.Text;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;

namespace LagCheck.WinUI.Controls;

/// <summary>
/// Pesos semânticos do corpo Barlow (Decisão 125).
/// Cada peso aponta para sua FontFamily correspondente em Theme.xaml, mantendo
/// FontWeight Normal para evitar negrito sintético no WinUI 3.
/// </summary>
public enum BodyWeight
{
    Regular,
    Medium,
    SemiBold,
}

/// <summary>
/// Helper de tipografia da Tríade Oficial (Decisão 125):
/// 1. Display: Barlow Semi Condensed (títulos e vereditos)
/// 2. Corpo: Barlow (Regular / Medium / SemiBold)
/// 3. Telemetria: Chakra Petch SemiBold (métricas e kickers técnicos tabulares)
/// </summary>
public static class Typography
{
    public static FontFamily BodyFont => GetResourceFont("BodyFont");
    public static FontFamily BodyMediumFont => GetResourceFont("BodyMediumFont");
    public static FontFamily BodySemiBoldFont => GetResourceFont("BodySemiBoldFont");
    public static FontFamily HeadingFont => GetResourceFont("HeadingFont");
    public static FontFamily HeadingBoldFont => GetResourceFont("HeadingBoldFont");
    public static FontFamily MetricFont => GetResourceFont("MetricFont");
    public static FontFamily TechnicalFont => GetResourceFont("TechnicalFont");

    private static FontFamily GetResourceFont(string key)
    {
        if (Application.Current?.Resources.TryGetValue(key, out var obj) == true && obj is FontFamily font)
            return font;
        return new FontFamily(key);
    }

    /// <summary>Aplica a família de corpo com o peso semântico correto e FontWeight Normal.</summary>
    public static TextBlock Body(TextBlock tb, BodyWeight weight = BodyWeight.Regular, double? size = null)
    {
        tb.FontFamily = weight switch
        {
            BodyWeight.Medium => BodyMediumFont,
            BodyWeight.SemiBold => BodySemiBoldFont,
            _ => BodyFont,
        };
        tb.FontWeight = FontWeights.Normal;
        if (size.HasValue) tb.FontSize = size.Value;
        return tb;
    }

    /// <summary>Atalho para corpo SemiBold (Barlow SemiBold com corte nativo).</summary>
    public static TextBlock SemiBold(TextBlock tb, double? size = null) => Body(tb, BodyWeight.SemiBold, size);

    /// <summary>Atalho para corpo Medium (Barlow Medium com corte nativo).</summary>
    public static TextBlock Medium(TextBlock tb, double? size = null) => Body(tb, BodyWeight.Medium, size);

    /// <summary>Aplica Chakra Petch SemiBold para kickers técnicos com espaçamento tabular.</summary>
    public static TextBlock Technical(TextBlock tb, double? size = null, int characterSpacing = 70)
    {
        tb.FontFamily = TechnicalFont;
        tb.FontWeight = FontWeights.Normal;
        tb.CharacterSpacing = characterSpacing;
        if (size.HasValue) tb.FontSize = size.Value;
        return tb;
    }

    /// <summary>Aplica Chakra Petch SemiBold para métricas numéricas tabulares.</summary>
    public static TextBlock Metric(TextBlock tb, double? size = null)
    {
        tb.FontFamily = MetricFont;
        tb.FontWeight = FontWeights.Normal;
        if (size.HasValue) tb.FontSize = size.Value;
        return tb;
    }

    /// <summary>Aplica Barlow Semi Condensed para títulos e vereditos (Display).</summary>
    public static TextBlock Heading(TextBlock tb, double? size = null, bool extraBold = false)
    {
        tb.FontFamily = extraBold ? HeadingFont : HeadingBoldFont;
        tb.FontWeight = FontWeights.Normal;
        if (size.HasValue) tb.FontSize = size.Value;
        return tb;
    }
}
