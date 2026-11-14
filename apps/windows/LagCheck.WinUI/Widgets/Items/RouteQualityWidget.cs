using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;
using LagCheck.WinUI.Controls;
using LagCheck.WinUI.Diagnostic;
using LagCheck.WinUI.Localization;

namespace LagCheck.WinUI.Widgets.Items;

public sealed class RouteQualityWidget : IHomeWidget
{
    public string Id => "quality";
    public string Title => Strings.Tr("ROTA");
    public string IconPath => "M12 3l9 4v5c0 5-4 8-9 9-5-1-9-4-9-9V7z";

    public bool IsAvailable(WidgetContext context) => true;

    public IReadOnlyList<WidgetSpan> Sizes(WidgetContext context) =>
    [
        new WidgetSpan(2, 1),
        new WidgetSpan(4, 1),
    ];

    public WidgetContent Render(WidgetContext context, WidgetSpan span)
    {
        var effectiveSpan = Sizes(context).Contains(span) ? span : Sizes(context)[0];

        var conclusive = context.History.Where(entry =>
            entry.HasCapturedAt &&
            Verdicts.ToneOf(entry.Verdict) != VerdictTone.Unknown &&
            entry.PingMs is { } p &&
            !double.IsNaN(p) &&
            !double.IsInfinity(p) &&
            p >= 0 &&
            p <= 10000);

        if (context.Game is not null && !context.IsPc)
        {
            conclusive = conclusive.Where(entry =>
                string.Equals(entry.GameId, context.Game.DiagnosticGameId, StringComparison.OrdinalIgnoreCase));
        }

        var ordered = conclusive.OrderBy(entry => entry.CapturedAt).ToList();

        if (ordered.Count == 0)
        {
            return new WidgetContent(
                State: WidgetState.Empty,
                Message: Strings.Tr("Sem teste ainda."),
                Activate: () => context.Actions.OpenHistory(),
                Summary: Strings.Tr("Sem teste ainda."));
        }

        var latest = ordered[^1];
        var tone = Verdicts.ToneOf(latest.Verdict);
        var accentBrush = new SolidColorBrush(Verdicts.ColorOf(tone));

        var secColor = Color.FromArgb(255, 0x9A, 0xA3, 0xB5);
        var jitterColor = latest.JitterMs is { } j ? WidgetParts.JitterColor(j) : secColor;
        var lossColor = latest.PacketLossPercentage is { } l ? WidgetParts.LossColor(l) : secColor;

        var regionName = RegionCatalog.Find(latest.RegionId)?.Name ?? latest.RegionLabel;

        var caption = latest.HasCapturedAt ? WidgetParts.RelativeDay(latest.CapturedAt) : null;
        var action = new WidgetAction(Strings.Tr("Ver histórico"), () => context.Actions.OpenHistory());
        var summary = Strings.Format(
            "Qualidade da rota: jitter {0}, perda {1}, região {2}.",
            latest.JitterLabel,
            latest.LossLabel,
            regionName);

        var body = effectiveSpan switch
        {
            { Cols: 4, Rows: 1 } => BuildWideBody(latest, tone, context.Game is not null && !context.IsPc, jitterColor, lossColor, regionName),
            _ => BuildCompactBody(latest, jitterColor, lossColor, regionName),
        };

        return new WidgetContent(
            State: WidgetState.Ready,
            Body: body,
            Caption: caption,
            Action: action,
            Activate: () => context.Actions.OpenHistory(),
            Accent: accentBrush,
            Summary: summary);
    }

    private static UIElement BuildCompactBody(
        LagCheck.WinUI.History.SessionHistoryEntry latest,
        Color jitterColor,
        Color lossColor,
        string regionName)
    {
        var grid = new Grid
        {
            VerticalAlignment = VerticalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(0.8, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(0.8, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1.4, GridUnitType.Star) });

        var jitterStr = latest.JitterMs is { } j ? j.ToString("0.#", CultureInfo.CurrentCulture) : "—";
        var lossStr = latest.PacketLossPercentage is { } l ? l.ToString("0.#", CultureInfo.CurrentCulture) : "—";

        var c0 = WidgetParts.Metric(Strings.Tr("JITTER"), jitterStr, latest.JitterMs is not null ? "ms" : null, jitterColor);
        Grid.SetColumn(c0, 0);
        grid.Children.Add(c0);

        var c1 = WidgetParts.Metric(Strings.Tr("PERDA"), lossStr, latest.PacketLossPercentage is not null ? "%" : null, lossColor);
        Grid.SetColumn(c1, 1);
        grid.Children.Add(c1);

        // Região é texto (ex.: "São Paulo"): fonte de corpo e até duas linhas, em vez do número grande.
        var c2 = new StackPanel { Spacing = 2 };
        c2.Children.Add(new TextBlock { Text = Strings.Tr("REGIÃO").ToUpper(CultureInfo.CurrentCulture), Style = (Style)Application.Current.Resources["TechLabelStyle"] });
        c2.Children.Add(new TextBlock { Text = regionName, FontSize = 14, FontWeight = Microsoft.UI.Text.FontWeights.SemiBold, TextWrapping = TextWrapping.Wrap, MaxLines = 2, TextTrimming = TextTrimming.CharacterEllipsis, Foreground = (Brush)Application.Current.Resources["TextSecondaryBrush"] });
        Grid.SetColumn(c2, 2);
        grid.Children.Add(c2);

        return grid;
    }

    private static UIElement BuildWideBody(
        LagCheck.WinUI.History.SessionHistoryEntry latest,
        VerdictTone tone,
        bool hasGame,
        Color jitterColor,
        Color lossColor,
        string regionName)
    {
        var grid = new Grid
        {
            VerticalAlignment = VerticalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(3, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(2, GridUnitType.Star) });

        var metricsGrid = (Grid)BuildCompactBody(latest, jitterColor, lossColor, regionName);
        Grid.SetColumn(metricsGrid, 0);
        grid.Children.Add(metricsGrid);

        var headlineStack = new StackPanel
        {
            Spacing = 4,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(16, 0, 0, 0),
        };

        var headlineText = new TextBlock
        {
            Text = Verdicts.Headline(tone, hasGame),
            FontSize = 13,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            TextWrapping = TextWrapping.Wrap,
            LineHeight = 16,
            LineStackingStrategy = LineStackingStrategy.BlockLineHeight,
        };
        headlineStack.Children.Add(headlineText);

        Grid.SetColumn(headlineStack, 1);
        grid.Children.Add(headlineStack);

        return grid;
    }
}
