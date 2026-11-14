using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using LagCheck.WinUI.Controls;
using LagCheck.WinUI.Library;
using LagCheck.WinUI.Localization;

namespace LagCheck.WinUI.Widgets.Items;

public sealed class ActivityWidget : IHomeWidget
{
    public string Id => "activity";
    public string Title => Strings.Tr("ÚLTIMA ATIVIDADE");
    public string IconPath => "M12 7v5l3 2M3 12a9 9 0 1 0 3-6.7M3 4v5h5";

    public bool IsAvailable(WidgetContext context) => true;

    public IReadOnlyList<WidgetSpan> Sizes(WidgetContext context) =>
    [
        new WidgetSpan(2, 1),
        new WidgetSpan(2, 2),
    ];

    public WidgetContent Render(WidgetContext context, WidgetSpan span)
    {
        var effectiveSpan = Sizes(context).Contains(span) ? span : Sizes(context)[0];

        if (context.Game is not null && !context.IsPc)
        {
            return RenderGameActivity(context, effectiveSpan);
        }

        return RenderPcActivity(context, effectiveSpan);
    }

    private static WidgetContent RenderGameActivity(WidgetContext context, WidgetSpan span)
    {
        var game = context.Game!;
        var activity = ValidEpoch(game.RecentActivityEpochMs);

        if (activity is null)
        {
            return new WidgetContent(
                State: WidgetState.Empty,
                Message: Strings.Tr("Sem atividade registrada pelo launcher."),
                Activate: () => context.Actions.OpenDetails(game),
                Summary: Strings.Tr("Sem atividade registrada pelo launcher."));
        }

        var dateStr = activity.Value.ToLocalTime().ToString("d MMM yyyy", DateCulture());
        var relStr = WidgetParts.RelativeDay(activity.Value);
        var caption = relStr;
        var summary = Strings.Format("Última atividade: {0} ({1}).", dateStr, relStr);

        var body = span switch
        {
            { Cols: 2, Rows: 2 } => BuildGameDetailsBody(context, game, dateStr, relStr),
            _ => BuildCompactGameBody(dateStr, relStr),
        };

        return new WidgetContent(
            State: WidgetState.Ready,
            Body: body,
            Caption: caption,
            Activate: () => context.Actions.OpenDetails(game),
            Summary: summary);
    }

    private static WidgetContent RenderPcActivity(WidgetContext context, WidgetSpan span)
    {
        var installed = context.Library.Where(g => g.IsInstalled).ToList();
        var known = installed
            .Select(g => new { Game = g, Activity = ValidEpoch(g.RecentActivityEpochMs) })
            .Where(item => item.Activity is not null)
            .OrderByDescending(item => item.Activity)
            .ToList();

        if (known.Count == 0)
        {
            return new WidgetContent(
                State: WidgetState.Empty,
                Message: Strings.Tr("Sem atividade registrada pelo launcher."),
                Summary: Strings.Tr("Sem atividade registrada pelo launcher."));
        }

        var latest = known[0];
        var latestDate = latest.Activity!.Value;
        var relStr = WidgetParts.RelativeDay(latestDate);
        var caption = Strings.Format(installed.Count == 1 ? "{0} jogo instalado" : "{0} jogos instalados", installed.Count);
        var summary = Strings.Format("Última atividade: {0}, {1}.", latest.Game.Title, relStr);

        var body = span switch
        {
            { Cols: 2, Rows: 2 } => BuildPcDetailsBody(context, latest.Game.Title, relStr, caption, known.Select(k => (k.Game.Title, k.Activity!.Value)).Take(4).ToList()),
            _ => BuildCompactPcBody(latest.Game.Title, relStr, caption),
        };

        return new WidgetContent(
            State: WidgetState.Ready,
            Body: body,
            Caption: caption,
            Activate: () => context.Actions.SelectGame(latest.Game),
            Summary: summary);
    }

    private static UIElement BuildCompactGameBody(string dateStr, string relStr)
    {
        var panel = new StackPanel { Spacing = 2, VerticalAlignment = VerticalAlignment.Center };

        var dateBlock = new TextBlock
        {
            Text = dateStr,
            FontSize = 20,
            TextTrimming = TextTrimming.CharacterEllipsis,
        };
        if (Application.Current?.Resources.TryGetValue("MetricFont", out var fontObj) == true && fontObj is FontFamily font)
        {
            dateBlock.FontFamily = font;
        }
        panel.Children.Add(dateBlock);

        var secBrush = Application.Current?.Resources.TryGetValue("TextSecondaryBrush", out var b) == true && b is Brush brush
            ? brush
            : new SolidColorBrush(Windows.UI.Color.FromArgb(255, 0x9A, 0xA3, 0xB5));

        panel.Children.Add(new TextBlock
        {
            Text = relStr,
            FontSize = 12,
            Foreground = secBrush,
            TextTrimming = TextTrimming.CharacterEllipsis,
        });

        return panel;
    }

    private static UIElement BuildGameDetailsBody(WidgetContext context, LibraryGame game, string dateStr, string relStr)
    {
        var panel = new StackPanel { Spacing = 8, VerticalAlignment = VerticalAlignment.Stretch };

        panel.Children.Add(BuildCompactGameBody(dateStr, relStr));

        var gameTests = context.History
            .Where(e => e.HasCapturedAt && string.Equals(e.GameId, game.DiagnosticGameId, StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(e => e.CapturedAt)
            .Take(4)
            .ToList();

        if (gameTests.Count > 0)
        {
            var secBrush = Application.Current?.Resources.TryGetValue("TextSecondaryBrush", out var b) == true && b is Brush brush
                ? brush
                : new SolidColorBrush(Windows.UI.Color.FromArgb(255, 0x9A, 0xA3, 0xB5));

            var header = new TextBlock
            {
                Text = Strings.Tr("TESTES RECENTES"),
                FontSize = 11,
                Foreground = secBrush,
                Margin = new Thickness(0, 4, 0, 0),
            };
            if (Application.Current?.Resources.TryGetValue("TechLabelStyle", out var styleObj) == true && styleObj is Style style)
            {
                header.Style = style;
            }
            header.FontSize = 11;
            panel.Children.Add(header);

            var listPanel = new StackPanel { Spacing = 4 };
            foreach (var test in gameTests)
            {
                var row = new Grid { HorizontalAlignment = HorizontalAlignment.Stretch };
                row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
                row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

                var relText = new TextBlock
                {
                    Text = WidgetParts.RelativeDay(test.CapturedAt),
                    FontSize = 11,
                    VerticalAlignment = VerticalAlignment.Center,
                    TextTrimming = TextTrimming.CharacterEllipsis,
                };
                Grid.SetColumn(relText, 0);
                row.Children.Add(relText);

                var pingText = new TextBlock
                {
                    Text = test.PingLabel,
                    FontSize = 11,
                    Foreground = secBrush,
                    VerticalAlignment = VerticalAlignment.Center,
                };
                Grid.SetColumn(pingText, 1);
                row.Children.Add(pingText);

                listPanel.Children.Add(row);
            }
            panel.Children.Add(listPanel);
        }

        return panel;
    }

    private static UIElement BuildCompactPcBody(string gameTitle, string relStr, string caption)
    {
        var panel = new StackPanel { Spacing = 3, VerticalAlignment = VerticalAlignment.Center };

        panel.Children.Add(new TextBlock
        {
            Text = gameTitle,
            FontSize = 15,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            TextTrimming = TextTrimming.CharacterEllipsis,
        });

        var secBrush = Application.Current?.Resources.TryGetValue("TextSecondaryBrush", out var b) == true && b is Brush brush
            ? brush
            : new SolidColorBrush(Windows.UI.Color.FromArgb(255, 0x9A, 0xA3, 0xB5));

        panel.Children.Add(new TextBlock
        {
            Text = $"{relStr} · {caption}",
            FontSize = 12,
            Foreground = secBrush,
            TextTrimming = TextTrimming.CharacterEllipsis,
        });

        return panel;
    }

    private static UIElement BuildPcDetailsBody(
        WidgetContext context,
        string latestTitle,
        string relStr,
        string caption,
        IReadOnlyList<(string Title, DateTimeOffset Date)> recentGames)
    {
        var panel = new StackPanel { Spacing = 8, VerticalAlignment = VerticalAlignment.Stretch };

        panel.Children.Add(BuildCompactPcBody(latestTitle, relStr, caption));

        var secBrush = Application.Current?.Resources.TryGetValue("TextSecondaryBrush", out var b) == true && b is Brush brush
            ? brush
            : new SolidColorBrush(Windows.UI.Color.FromArgb(255, 0x9A, 0xA3, 0xB5));

        var listPanel = new StackPanel { Spacing = 4, Margin = new Thickness(0, 4, 0, 0) };
        foreach (var (title, date) in recentGames)
        {
            var row = new Grid { HorizontalAlignment = HorizontalAlignment.Stretch };
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

            var titleText = new TextBlock
            {
                Text = title,
                FontSize = 11,
                VerticalAlignment = VerticalAlignment.Center,
                TextTrimming = TextTrimming.CharacterEllipsis,
            };
            Grid.SetColumn(titleText, 0);
            row.Children.Add(titleText);

            var relText = new TextBlock
            {
                Text = WidgetParts.RelativeDay(date),
                FontSize = 11,
                Foreground = secBrush,
                Margin = new Thickness(8, 0, 0, 0),
                VerticalAlignment = VerticalAlignment.Center,
            };
            Grid.SetColumn(relText, 1);
            row.Children.Add(relText);

            listPanel.Children.Add(row);
        }

        panel.Children.Add(listPanel);
        return panel;
    }

    private static DateTimeOffset? ValidEpoch(long? epoch)
    {
        if (epoch is not { } value || value <= 0) return null;
        try { return DateTimeOffset.FromUnixTimeMilliseconds(value); }
        catch (ArgumentOutOfRangeException) { return null; }
    }

    private static CultureInfo DateCulture() => LocalizationService.Instance.EffectiveLanguage switch
    {
        AppLanguage.En => CultureInfo.GetCultureInfo("en-US"),
        AppLanguage.Es => CultureInfo.GetCultureInfo("es-ES"),
        _ => CultureInfo.GetCultureInfo("pt-BR"),
    };
}
