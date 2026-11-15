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
using LagCheck.WinUI.History;
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
        new WidgetSpan(2, 2),
    ];

    public WidgetContent Render(WidgetContext context, WidgetSpan span)
    {
        var effectiveSpan = Sizes(context).Contains(span) ? span : Sizes(context)[0];
        var hasGame = context.Game is not null && !context.IsPc;

        var summary = NetworkStabilitySummary.Build(context.History, hasGame ? context.Game!.HistoryGameKey : null, 12);

        if (!summary.HasData || summary.Latest is not { } latest)
        {
            return new WidgetContent(
                State: WidgetState.Empty,
                Message: Strings.Tr("Sem teste ainda."),
                Summary: Strings.Tr("Sem teste ainda."));
        }

        var tone = Verdicts.ToneOf(latest.Verdict);
        var accentBrush = new SolidColorBrush(Verdicts.ColorOf(tone));
        var regionName = RegionCatalog.Find(latest.RegionId)?.Name ?? latest.RegionLabel;

        var targetGameId = hasGame ? context.Game!.HistoryGameKey : null;
        var targetGameTitle = hasGame ? context.Game!.Title : null;
        Action openDetails = () => context.Actions.NavigateToHistory(targetGameId, targetGameTitle);

        var caption = latest.HasCapturedAt ? WidgetParts.RelativeDay(latest.CapturedAt) : null;
        var action = new WidgetAction(Strings.Tr("Ver detalhes"), openDetails);
        var a11ySummary = Strings.Format(
            "Qualidade da rota: jitter {0}, perda {1}, região {2}.",
            latest.JitterLabel,
            latest.LossLabel,
            regionName);

        var body = effectiveSpan switch
        {
            { Cols: 4, Rows: 1 } => BuildWideBody(latest, tone, hasGame, regionName),
            { Cols: 2, Rows: 2 } => BuildTallBody(latest, tone, hasGame, regionName),
            _ => BuildRingsRow(latest, ringSize: 44),
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

    private static Grid BuildRingsRow(SessionHistoryEntry latest, double ringSize)
    {
        var secColor = Color.FromArgb(255, 0x9A, 0xA3, 0xB5);

        var grid = new Grid
        {
            VerticalAlignment = VerticalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        // Coluna 1: JITTER
        var jitterGauge = latest.JitterMs is { } j
            ? WidgetParts.RingMetricGauge(
                Strings.Tr("JITTER"),
                j.ToString("0.#", CultureInfo.CurrentCulture),
                "ms",
                WidgetParts.JitterColor(j),
                WidgetParts.MetricVerdictTone(j, 8, 20),
                WidgetParts.MetricRatio(j, 8, 20, 50),
                ringSize)
            : WidgetParts.RingMetricGauge(Strings.Tr("JITTER"), "—", null, secColor, VerdictTone.Unknown, 0, ringSize);
        Grid.SetColumn(jitterGauge, 0);
        grid.Children.Add(jitterGauge);

        var d0 = WidgetParts.VerticalDivider(ringSize < 48 ? 6 : 8);
        Grid.SetColumn(d0, 1);
        grid.Children.Add(d0);

        // Coluna 2: PERDA
        var lossGauge = latest.PacketLossPercentage is { } l
            ? WidgetParts.RingMetricGauge(
                Strings.Tr("PERDA"),
                l.ToString("0.#", CultureInfo.CurrentCulture),
                "%",
                WidgetParts.LossColor(l),
                WidgetParts.MetricVerdictTone(l, 0.5, 2),
                WidgetParts.MetricRatio(l, 0.5, 2, 10),
                ringSize)
            : WidgetParts.RingMetricGauge(Strings.Tr("PERDA"), "—", null, secColor, VerdictTone.Unknown, 0, ringSize);
        Grid.SetColumn(lossGauge, 2);
        grid.Children.Add(lossGauge);

        var d1 = WidgetParts.VerticalDivider(ringSize < 48 ? 6 : 8);
        Grid.SetColumn(d1, 3);
        grid.Children.Add(d1);

        // Coluna 3: SOB CARGA (ou PING caso não haja dado sob carga)
        FrameworkElement thirdGauge;
        if (latest.LoadDeltaMs is { } load)
        {
            thirdGauge = WidgetParts.RingMetricGauge(
                Strings.Tr("SOB CARGA"),
                "+" + load.ToString("0.#", CultureInfo.CurrentCulture),
                "ms",
                WidgetParts.LoadColor(load),
                WidgetParts.MetricVerdictTone(load, 15, 40),
                WidgetParts.MetricRatio(load, 15, 40, 120),
                ringSize);
        }
        else if (latest.PingMs is { } p)
        {
            thirdGauge = WidgetParts.RingMetricGauge(
                Strings.Tr("PING"),
                p.ToString("0", CultureInfo.CurrentCulture),
                "ms",
                WidgetParts.PingColor(p),
                WidgetParts.MetricVerdictTone(p, 45, 90),
                WidgetParts.MetricRatio(p, 45, 90, 220),
                ringSize);
        }
        else
        {
            thirdGauge = WidgetParts.RingMetricGauge(Strings.Tr("SOB CARGA"), "—", null, secColor, VerdictTone.Unknown, 0, ringSize);
        }
        Grid.SetColumn(thirdGauge, 4);
        grid.Children.Add(thirdGauge);

        return grid;
    }

    private static UIElement BuildWideBody(
        SessionHistoryEntry latest,
        VerdictTone tone,
        bool hasGame,
        string regionName)
    {
        var grid = new Grid
        {
            VerticalAlignment = VerticalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(2.2, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1.4, GridUnitType.Star) });

        var rings = BuildRingsRow(latest, ringSize: 46);
        rings.Margin = new Thickness(0, 0, 10, 0);
        Grid.SetColumn(rings, 0);
        grid.Children.Add(rings);

        var divider = WidgetParts.VerticalDivider(6);
        Grid.SetColumn(divider, 1);
        grid.Children.Add(divider);

        var infoStack = new StackPanel
        {
            Spacing = 4,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(14, 0, 0, 0),
        };
        infoStack.Children.Add(new TextBlock
        {
            Text = Strings.Tr("REGIÃO").ToUpper(CultureInfo.CurrentCulture),
            Style = (Style)Application.Current.Resources["TechLabelStyle"],
        });
        infoStack.Children.Add(new TextBlock
        {
            Text = regionName,
            FontFamily = (FontFamily)Application.Current.Resources["BodySemiBoldFont"],
            FontSize = 13,
            FontWeight = Microsoft.UI.Text.FontWeights.Normal,
            TextTrimming = TextTrimming.CharacterEllipsis,
            Foreground = (Brush)Application.Current.Resources["TextPrimaryBrush"],
        });
        infoStack.Children.Add(new TextBlock
        {
            Text = Verdicts.Headline(tone, hasGame),
            FontFamily = (FontFamily)Application.Current.Resources["BodyMediumFont"],
            FontSize = 12,
            FontWeight = Microsoft.UI.Text.FontWeights.Normal,
            TextTrimming = TextTrimming.CharacterEllipsis,
            Foreground = new SolidColorBrush(Verdicts.ColorOf(tone)),
        });

        Grid.SetColumn(infoStack, 2);
        grid.Children.Add(infoStack);

        return grid;
    }

    private static UIElement BuildTallBody(
        SessionHistoryEntry latest,
        VerdictTone tone,
        bool hasGame,
        string regionName)
    {
        var grid = new Grid
        {
            VerticalAlignment = VerticalAlignment.Stretch,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        var rings = BuildRingsRow(latest, ringSize: 52);
        Grid.SetRow(rings, 0);
        grid.Children.Add(rings);

        var footer = new StackPanel
        {
            Spacing = 4,
            Padding = new Thickness(0, 10, 0, 0),
            BorderBrush = new SolidColorBrush(Color.FromArgb(0x18, 255, 255, 255)),
            BorderThickness = new Thickness(0, 1, 0, 0),
        };
        footer.Children.Add(new TextBlock
        {
            Text = Strings.Tr("REGIÃO").ToUpper(CultureInfo.CurrentCulture),
            Style = (Style)Application.Current.Resources["TechLabelStyle"],
        });
        footer.Children.Add(new TextBlock
        {
            Text = regionName,
            FontFamily = (FontFamily)Application.Current.Resources["BodySemiBoldFont"],
            FontSize = 13,
            FontWeight = Microsoft.UI.Text.FontWeights.Normal,
            TextTrimming = TextTrimming.CharacterEllipsis,
            Foreground = (Brush)Application.Current.Resources["TextPrimaryBrush"],
        });
        footer.Children.Add(new TextBlock
        {
            Text = Verdicts.Headline(tone, hasGame),
            FontFamily = (FontFamily)Application.Current.Resources["BodyMediumFont"],
            FontSize = 12,
            FontWeight = Microsoft.UI.Text.FontWeights.Normal,
            TextTrimming = TextTrimming.CharacterEllipsis,
            Foreground = new SolidColorBrush(Verdicts.ColorOf(tone)),
        });

        Grid.SetRow(footer, 1);
        grid.Children.Add(footer);

        return grid;
    }
}
