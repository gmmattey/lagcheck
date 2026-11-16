using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Documents;
using Microsoft.UI.Xaml.Media;
using Windows.UI;
using LagCheck.WinUI.Controls;
using LagCheck.WinUI.History;
using LagCheck.WinUI.Localization;

namespace LagCheck.WinUI.Widgets.Items;

public sealed class LatencyWidget : IHomeWidget
{
    private bool _hasGameContext;

    public string Id => "latency";
    public string Title => Strings.Tr(_hasGameContext ? "ESTABILIDADE NO JOGO" : "ESTABILIDADE DA REDE");
    public string IconPath => "M4 20v-4M10 20v-8M16 20V8M22 20V4";

    public bool IsAvailable(WidgetContext context)
    {
        _hasGameContext = context.Game is not null && !context.IsPc;
        return true;
    }

    // Sem nenhum teste real não há o que desenhar em 2x2: o card vazio fica compacto.
    public IReadOnlyList<WidgetSpan> Sizes(WidgetContext context) => BuildSummary(context, 12).HasData
        ? [new WidgetSpan(2, 2), new WidgetSpan(2, 1), new WidgetSpan(4, 2)]
        : [new WidgetSpan(2, 1)];

    private static NetworkStabilitySummary BuildSummary(WidgetContext context, int maxPoints)
    {
        if (context.Game is not null && !context.IsPc)
        {
            return NetworkStabilitySummary.Build(context.History, context.Game.HistoryGameKey, maxPoints);
        }
        return NetworkStabilitySummary.Build(context.History, null, maxPoints);
    }

    public WidgetContent Render(WidgetContext context, WidgetSpan span)
    {
        _hasGameContext = context.Game is not null && !context.IsPc;
        var effectiveSpan = Sizes(context).Contains(span) ? span : Sizes(context)[0];

        var maxPoints = effectiveSpan == new WidgetSpan(4, 2) ? 24 : 12;
        var summary = BuildSummary(context, maxPoints);

        var targetGameId = _hasGameContext ? context.Game!.HistoryGameKey : null;
        var targetGameTitle = _hasGameContext ? context.Game!.Title : null;

        if (!summary.HasData || summary.Latest is not { } latest)
        {
            var canTest = context.Game is null || context.Game.CanTestConnection;
            WidgetAction? testAction = canTest
                ? new WidgetAction(
                    Strings.Tr("Testar agora"),
                    () => context.Actions.TestConnection(context.Game?.DiagnosticGameId, context.Game?.Title))
                : null;

            return new WidgetContent(
                State: WidgetState.Empty,
                Message: Strings.Tr("Nenhum teste ainda."),
                Action: testAction,
                Summary: Strings.Tr("Nenhum teste ainda."));
        }

        var latestTone = Verdicts.ToneOf(latest.Verdict);
        var stabilityTone = summary.StabilityTone;
        var accentBrush = new SolidColorBrush(Verdicts.ColorOf(stabilityTone));
        var stabilityText = NetworkStabilitySummary.HeadlineWord(summary);
        var pctText = Strings.Format("{0}% estável", summary.StabilityPercentage);

        var caption = Strings.Format(
            summary.TotalCount == 1 ? "{0} teste · {1}" : "{0} testes · {1}",
            summary.TotalCount,
            WidgetParts.RelativeDay(latest.CapturedAt));

        Action openDetails = () => context.Actions.NavigateToHistory(targetGameId, targetGameTitle);
        var action = new WidgetAction(Strings.Tr("Ver detalhes"), openDetails);
        var a11ySummary = Strings.Format(
            "Estabilidade: {0} ({1}%), último ping {2:0.#} ms.",
            stabilityText.ToLower(CultureInfo.CurrentCulture),
            summary.StabilityPercentage,
            latest.PingMs ?? 0);

        var body = effectiveSpan switch
        {
            { Cols: 2, Rows: 1 } => BuildCompactBody(latest, latestTone, summary, stabilityText),
            { Cols: 4, Rows: 2 } => BuildWideBody(latest, latestTone, summary, stabilityText, pctText),
            _ => BuildFullBody(latest, latestTone, summary, stabilityText, pctText),
        };

        return new WidgetContent(
            State: WidgetState.Ready,
            Body: body,
            Caption: caption,
            Action: action,
            Activate: openDetails,
            Accent: accentBrush,
            Summary: a11ySummary);
    }

    private static UIElement BuildCompactBody(
        SessionHistoryEntry latest,
        VerdictTone latestTone,
        NetworkStabilitySummary summary,
        string stabilityText)
    {
        var grid = new Grid
        {
            VerticalAlignment = VerticalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(96, GridUnitType.Pixel) });

        var left = new StackPanel { Spacing = 4, VerticalAlignment = VerticalAlignment.Center };
        left.Children.Add(BuildStabilityChip(summary.StabilityTone, $"{stabilityText} · {summary.StabilityPercentage}%"));
        left.Children.Add(BuildPingBlock(latest.PingMs!.Value, latestTone, fontSize: 26));

        Grid.SetColumn(left, 0);
        grid.Children.Add(left);

        var chart = new Border
        {
            Height = 46,
            VerticalAlignment = VerticalAlignment.Center,
            Child = WidgetParts.StabilityChart(summary.Points, Verdicts.ColorOf(summary.StabilityTone)),
        };
        Grid.SetColumn(chart, 1);
        grid.Children.Add(chart);

        return grid;
    }

    private static UIElement BuildFullBody(
        SessionHistoryEntry latest,
        VerdictTone latestTone,
        NetworkStabilitySummary summary,
        string stabilityText,
        string pctText)
    {
        var grid = new Grid
        {
            VerticalAlignment = VerticalAlignment.Stretch,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        var topRow = new Grid { HorizontalAlignment = HorizontalAlignment.Stretch };
        topRow.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        topRow.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        var chip = BuildStabilityChip(summary.StabilityTone, stabilityText);
        Grid.SetColumn(chip, 0);
        topRow.Children.Add(chip);

        var pctBadge = new TextBlock
        {
            Text = pctText,
            FontFamily = (FontFamily)Application.Current.Resources["TechnicalFont"],
            FontSize = 11,
            Foreground = new SolidColorBrush(Verdicts.ColorOf(summary.StabilityTone)),
            VerticalAlignment = VerticalAlignment.Center,
        };
        Grid.SetColumn(pctBadge, 1);
        topRow.Children.Add(pctBadge);

        Grid.SetRow(topRow, 0);
        grid.Children.Add(topRow);

        var pingBlock = BuildPingBlock(latest.PingMs!.Value, latestTone, fontSize: 32, margin: new Thickness(0, 4, 0, 0));
        Grid.SetRow(pingBlock, 1);
        grid.Children.Add(pingBlock);

        var chart = new Border
        {
            MinHeight = 38,
            Margin = new Thickness(0, 4, 0, 8),
            Child = WidgetParts.StabilityChart(summary.Points, Verdicts.ColorOf(summary.StabilityTone)),
        };
        Grid.SetRow(chart, 2);
        grid.Children.Add(chart);

        var metricRow = BuildMinAvgMaxRow(summary.MinPing, summary.AvgPing, summary.MaxPing);
        Grid.SetRow(metricRow, 3);
        grid.Children.Add(metricRow);

        return grid;
    }

    private static UIElement BuildWideBody(
        SessionHistoryEntry latest,
        VerdictTone latestTone,
        NetworkStabilitySummary summary,
        string stabilityText,
        string pctText)
    {
        var grid = new Grid
        {
            VerticalAlignment = VerticalAlignment.Stretch,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(136, GridUnitType.Pixel) });

        var left = new Grid();
        left.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        left.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });

        var top = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 12,
            VerticalAlignment = VerticalAlignment.Center,
        };
        top.Children.Add(BuildStabilityChip(summary.StabilityTone, $"{stabilityText} · {pctText}"));
        top.Children.Add(BuildPingBlock(latest.PingMs!.Value, latestTone, fontSize: 28));
        Grid.SetRow(top, 0);
        left.Children.Add(top);

        var chart = new Border
        {
            Margin = new Thickness(0, 8, 12, 0),
            Child = WidgetParts.StabilityChart(summary.Points, Verdicts.ColorOf(summary.StabilityTone)),
        };
        Grid.SetRow(chart, 1);
        left.Children.Add(chart);

        Grid.SetColumn(left, 0);
        grid.Children.Add(left);

        var divider = WidgetParts.VerticalDivider(6);
        Grid.SetColumn(divider, 1);
        grid.Children.Add(divider);

        var right = new StackPanel
        {
            Spacing = 6,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(14, 0, 0, 0),
        };
        right.Children.Add(WidgetParts.Metric(Strings.Tr("MÍN"), summary.MinPing.ToString("0", CultureInfo.CurrentCulture), "ms", WidgetParts.PingColor(summary.MinPing)));
        right.Children.Add(WidgetParts.Metric(Strings.Tr("MÉD"), summary.AvgPing.ToString("0", CultureInfo.CurrentCulture), "ms", WidgetParts.PingColor(summary.AvgPing)));
        right.Children.Add(WidgetParts.Metric(Strings.Tr("MÁX"), summary.MaxPing.ToString("0", CultureInfo.CurrentCulture), "ms", WidgetParts.PingColor(summary.MaxPing)));

        Grid.SetColumn(right, 2);
        grid.Children.Add(right);

        return grid;
    }

    private static FrameworkElement BuildStabilityChip(VerdictTone tone, string text)
    {
        var stack = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 6,
            VerticalAlignment = VerticalAlignment.Center,
        };
        stack.Children.Add(Verdicts.Marker(tone, 8));

        var secBrush = Application.Current?.Resources.TryGetValue("TextSecondaryBrush", out var b) == true && b is Brush brush
            ? brush
            : new SolidColorBrush(Color.FromArgb(255, 0x9A, 0xA3, 0xB5));

        stack.Children.Add(new TextBlock
        {
            Text = text,
            FontSize = 12,
            Foreground = secBrush,
            VerticalAlignment = VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis,
        });

        return stack;
    }

    private static TextBlock BuildPingBlock(double ping, VerdictTone tone, double fontSize, Thickness margin = default)
    {
        var block = new TextBlock
        {
            FontSize = fontSize,
            Foreground = new SolidColorBrush(Verdicts.ColorOf(tone)),
            Margin = margin,
            VerticalAlignment = VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis,
        };
        if (Application.Current?.Resources.TryGetValue("MetricFont", out var metricFontObj) == true && metricFontObj is FontFamily metricFont)
        {
            block.FontFamily = metricFont;
        }

        block.Inlines.Add(new Run { Text = ping.ToString("0", CultureInfo.CurrentCulture) });

        var secBrush = Application.Current?.Resources.TryGetValue("TextSecondaryBrush", out var b) == true && b is Brush brush
            ? brush
            : new SolidColorBrush(Color.FromArgb(255, 0x9A, 0xA3, 0xB5));

        block.Inlines.Add(new Run
        {
            Text = " ms",
            FontSize = Math.Max(12, fontSize * 0.4),
            Foreground = secBrush,
        });

        return block;
    }

    private static FrameworkElement BuildMinAvgMaxRow(double minPing, double avgPing, double maxPing)
    {
        var grid = new Grid { HorizontalAlignment = HorizontalAlignment.Stretch };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var c0 = WidgetParts.Metric(Strings.Tr("MÍN"), minPing.ToString("0", CultureInfo.CurrentCulture), "ms", WidgetParts.PingColor(minPing));
        c0.HorizontalAlignment = HorizontalAlignment.Center;
        Grid.SetColumn(c0, 0);
        grid.Children.Add(c0);

        var d0 = WidgetParts.VerticalDivider(2);
        Grid.SetColumn(d0, 1);
        grid.Children.Add(d0);

        var c1 = WidgetParts.Metric(Strings.Tr("MÉD"), avgPing.ToString("0", CultureInfo.CurrentCulture), "ms", WidgetParts.PingColor(avgPing));
        c1.HorizontalAlignment = HorizontalAlignment.Center;
        Grid.SetColumn(c1, 2);
        grid.Children.Add(c1);

        var d1 = WidgetParts.VerticalDivider(2);
        Grid.SetColumn(d1, 3);
        grid.Children.Add(d1);

        var c2 = WidgetParts.Metric(Strings.Tr("MÁX"), maxPing.ToString("0", CultureInfo.CurrentCulture), "ms", WidgetParts.PingColor(maxPing));
        c2.HorizontalAlignment = HorizontalAlignment.Center;
        Grid.SetColumn(c2, 4);
        grid.Children.Add(c2);

        return grid;
    }
}
