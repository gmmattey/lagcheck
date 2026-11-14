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
using LagCheck.WinUI.Localization;

namespace LagCheck.WinUI.Widgets.Items;

public sealed class LatencyWidget : IHomeWidget
{
    public string Id => "latency";
    public string Title => Strings.Tr("ÚLTIMO TESTE");
    public string IconPath => "M4 20v-4M10 20v-8M16 20V8M22 20V4";

    public bool IsAvailable(WidgetContext context) => true;

    // Sem nenhum teste real não há o que desenhar em 2x2: o card vazio fica compacto.
    public IReadOnlyList<WidgetSpan> Sizes(WidgetContext context) => HasData(context)
        ? [new WidgetSpan(2, 2), new WidgetSpan(2, 1), new WidgetSpan(4, 2)]
        : [new WidgetSpan(2, 1)];

    private static bool HasData(WidgetContext context) => context.History.Any(entry =>
        entry.HasCapturedAt &&
        Verdicts.ToneOf(entry.Verdict) != VerdictTone.Unknown &&
        entry.PingMs is { } p && double.IsFinite(p) && p >= 0 && p <= 10000 &&
        (context.Game is null || context.IsPc ||
            string.Equals(entry.GameId, context.Game.DiagnosticGameId, StringComparison.OrdinalIgnoreCase)));

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
                Activate: () => context.Actions.OpenHistory(),
                Summary: Strings.Tr("Nenhum teste ainda."));
        }

        var latest = ordered[^1];
        var tone = Verdicts.ToneOf(latest.Verdict);
        var accentBrush = new SolidColorBrush(Verdicts.ColorOf(tone));

        var maxPoints = effectiveSpan == new WidgetSpan(4, 2) ? 24 : 12;
        var ptEntries = ordered.TakeLast(maxPoints).ToList();
        var pingValues = ptEntries.Select(e => e.PingMs!.Value).ToList();
        var minPing = pingValues.Min();
        var avgPing = pingValues.Average();
        var maxPing = pingValues.Max();

        var caption = Strings.Format(ordered.Count == 1 ? "{0} teste · {1}" : "{0} testes · {1}", ordered.Count, WidgetParts.RelativeDay(latest.CapturedAt));
        var action = new WidgetAction(Strings.Tr("Ver histórico"), () => context.Actions.OpenHistory());
        var summary = Strings.Format("Último teste: {0:0.#} ms, {1}.", latest.PingMs ?? 0, Verdicts.StatusWord(tone).ToLower(CultureInfo.CurrentCulture));

        var body = effectiveSpan switch
        {
            { Cols: 2, Rows: 1 } => BuildCompactBody(latest, tone, pingValues),
            { Cols: 4, Rows: 2 } => BuildWideBody(latest, tone, pingValues, minPing, avgPing, maxPing),
            _ => BuildFullBody(latest, tone, pingValues, minPing, avgPing, maxPing),
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
        VerdictTone tone,
        IReadOnlyList<double> pingValues)
    {
        var grid = new Grid
        {
            VerticalAlignment = VerticalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(96, GridUnitType.Pixel) });

        var left = new StackPanel { Spacing = 4, VerticalAlignment = VerticalAlignment.Center };
        var chip = BuildChip(tone);
        left.Children.Add(chip);

        var pingBlock = BuildPingBlock(latest.PingMs!.Value, tone, fontSize: 28);
        left.Children.Add(pingBlock);

        Grid.SetColumn(left, 0);
        grid.Children.Add(left);

        var spark = new Border
        {
            Height = 44,
            VerticalAlignment = VerticalAlignment.Center,
            Child = WidgetParts.Sparkline(pingValues, Verdicts.ColorOf(tone)),
        };
        Grid.SetColumn(spark, 1);
        grid.Children.Add(spark);

        return grid;
    }

    private static UIElement BuildFullBody(
        LagCheck.WinUI.History.SessionHistoryEntry latest,
        VerdictTone tone,
        IReadOnlyList<double> pingValues,
        double minPing,
        double avgPing,
        double maxPing)
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

        var chip = BuildChip(tone);
        Grid.SetRow(chip, 0);
        grid.Children.Add(chip);

        var pingBlock = BuildPingBlock(latest.PingMs!.Value, tone, fontSize: 36, margin: new Thickness(0, 4, 0, 0));
        Grid.SetRow(pingBlock, 1);
        grid.Children.Add(pingBlock);

        var spark = new Border
        {
            MinHeight = 36,
            Margin = new Thickness(0, 4, 0, 8),
            Child = WidgetParts.Sparkline(pingValues, Verdicts.ColorOf(tone)),
        };
        Grid.SetRow(spark, 2);
        grid.Children.Add(spark);

        var metricRow = BuildMinAvgMaxRow(minPing, avgPing, maxPing);
        Grid.SetRow(metricRow, 3);
        grid.Children.Add(metricRow);

        return grid;
    }

    private static UIElement BuildWideBody(
        LagCheck.WinUI.History.SessionHistoryEntry latest,
        VerdictTone tone,
        IReadOnlyList<double> pingValues,
        double minPing,
        double avgPing,
        double maxPing)
    {
        var grid = new Grid
        {
            VerticalAlignment = VerticalAlignment.Stretch,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(140, GridUnitType.Pixel) });

        var left = new Grid();
        left.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        left.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });

        var top = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 16,
            VerticalAlignment = VerticalAlignment.Center,
        };
        top.Children.Add(BuildChip(tone));
        top.Children.Add(BuildPingBlock(latest.PingMs!.Value, tone, fontSize: 30));
        Grid.SetRow(top, 0);
        left.Children.Add(top);

        var spark = new Border
        {
            Margin = new Thickness(0, 8, 12, 0),
            Child = WidgetParts.Sparkline(pingValues, Verdicts.ColorOf(tone)),
        };
        Grid.SetRow(spark, 1);
        left.Children.Add(spark);

        Grid.SetColumn(left, 0);
        grid.Children.Add(left);

        var right = new StackPanel
        {
            Spacing = 6,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(12, 0, 0, 0),
        };
        right.Children.Add(WidgetParts.Metric(Strings.Tr("MÍN"), minPing.ToString("0", CultureInfo.CurrentCulture), "ms", WidgetParts.PingColor(minPing)));
        right.Children.Add(WidgetParts.Metric(Strings.Tr("MÉD"), avgPing.ToString("0", CultureInfo.CurrentCulture), "ms", WidgetParts.PingColor(avgPing)));
        right.Children.Add(WidgetParts.Metric(Strings.Tr("MÁX"), maxPing.ToString("0", CultureInfo.CurrentCulture), "ms", WidgetParts.PingColor(maxPing)));

        Grid.SetColumn(right, 1);
        grid.Children.Add(right);

        return grid;
    }

    private static FrameworkElement BuildChip(VerdictTone tone)
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
            Text = Verdicts.StatusWord(tone),
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
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var c0 = WidgetParts.Metric(Strings.Tr("MÍN"), minPing.ToString("0", CultureInfo.CurrentCulture), "ms", WidgetParts.PingColor(minPing));
        Grid.SetColumn(c0, 0);
        grid.Children.Add(c0);

        var c1 = WidgetParts.Metric(Strings.Tr("MÉD"), avgPing.ToString("0", CultureInfo.CurrentCulture), "ms", WidgetParts.PingColor(avgPing));
        Grid.SetColumn(c1, 1);
        grid.Children.Add(c1);

        var c2 = WidgetParts.Metric(Strings.Tr("MÁX"), maxPing.ToString("0", CultureInfo.CurrentCulture), "ms", WidgetParts.PingColor(maxPing));
        Grid.SetColumn(c2, 2);
        grid.Children.Add(c2);

        return grid;
    }
}
