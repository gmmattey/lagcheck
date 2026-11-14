using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Automation;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;
using LagCheck.WinUI.Controls;
using LagCheck.WinUI.Library;
using LagCheck.WinUI.Localization;
using LagCheck.WinUI.PlatformStatus;

namespace LagCheck.WinUI.Widgets.Items;

public sealed class PlatformsWidget : IHomeWidget
{
    private bool _isSinglePlatform;

    public string Id => "platforms";
    public string Title => Strings.Tr(_isSinglePlatform ? "PLATAFORMA" : "PLATAFORMAS");
    public string IconPath => "M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z";

    private static string? KnownPlatformId(GamePlatform platform) => platform switch
    {
        GamePlatform.Steam => "steam",
        GamePlatform.EpicGames => "epicgames",
        GamePlatform.Xbox => "xbox",
        _ => null,
    };

    public bool IsAvailable(WidgetContext context)
    {
        if (context.IsPc)
        {
            _isSinglePlatform = false;
            return true;
        }

        if (context.Game is { } game)
        {
            var isOnline = game.Info?.IsOnline == true || game.NetworkKind == GameNetworkKind.Supported;
            if (isOnline && KnownPlatformId(game.Platform) is not null)
            {
                _isSinglePlatform = true;
                return true;
            }
        }

        _isSinglePlatform = false;
        return false;
    }

    public IReadOnlyList<WidgetSpan> Sizes(WidgetContext context)
    {
        if (!context.IsPc && context.Game is not null)
        {
            return
            [
                new WidgetSpan(2, 1),
                new WidgetSpan(2, 2),
            ];
        }

        return
        [
            new WidgetSpan(2, 2),
            new WidgetSpan(2, 1),
            new WidgetSpan(4, 1),
        ];
    }

    public WidgetContent Render(WidgetContext context, WidgetSpan span)
    {
        _isSinglePlatform = !context.IsPc && context.Game is not null;
        var effectiveSpan = Sizes(context).Contains(span) ? span : Sizes(context)[0];

        if (context.PlatformsLoading && context.Platforms is null)
        {
            return new WidgetContent(State: WidgetState.Loading);
        }

        if (context.Platforms is null)
        {
            return new WidgetContent(
                State: WidgetState.Empty,
                Message: Strings.Tr("Status indisponível."),
                Action: new WidgetAction(Strings.Tr("Atualizar"), () => context.Actions.RefreshPlatforms(), string.Empty),
                Activate: () => context.Actions.RefreshPlatforms(),
                Summary: Strings.Tr("Status indisponível."));
        }

        var snapshot = context.Platforms;
        var isStale = snapshot.Availability is PlatformStatusAvailability.Stale or PlatformStatusAvailability.Unavailable
            || (DateTimeOffset.UtcNow - snapshot.RetrievedAt) > TimeSpan.FromMinutes(5);

        var targetPlatformId = !context.IsPc && context.Game is { } g ? KnownPlatformId(g.Platform) : null;
        var list = (context.IsPc
            ? snapshot.Platforms.Where(p => p.Id is "steam" or "epicgames" or "xbox")
            : targetPlatformId is not null
                ? snapshot.Platforms.Where(p => string.Equals(p.Id, targetPlatformId, StringComparison.OrdinalIgnoreCase))
                : snapshot.Platforms).ToList();

        var (worstColor, worstState) = DetermineWorstState(list, isStale);
        var accentBrush = new SolidColorBrush(worstColor);

        var caption = Strings.Format("Consulta do site · atualizado {0:HH:mm}", snapshot.RetrievedAt.ToLocalTime());
        var action = new WidgetAction(Strings.Tr("Atualizar"), () => context.Actions.RefreshPlatforms(), string.Empty);

        var summary = isStale
            ? Strings.Tr(_isSinglePlatform ? "Status da plataforma desatualizado." : "Status das plataformas desatualizado.")
            : _isSinglePlatform
                ? Strings.Format(
                    "Status da plataforma: {0}.",
                    worstState == PlatformServiceState.Operational
                        ? Strings.Tr("operacional")
                        : Strings.Tr("instabilidade detectada"))
                : Strings.Format(
                    "Status das plataformas: {0}.",
                    worstState == PlatformServiceState.Operational
                        ? Strings.Tr("todos os serviços operacionais")
                        : Strings.Tr("instabilidade detectada"));

        var body = _isSinglePlatform
            ? BuildFullRowsBody(list, isStale)
            : effectiveSpan switch
            {
                { Cols: 2, Rows: 1 } => BuildCompactIconsBody(list, isStale),
                { Cols: 4, Rows: 1 } => BuildWideLineBody(list, isStale),
                _ => BuildFullRowsBody(list, isStale),
            };

        return new WidgetContent(
            State: isStale ? WidgetState.Stale : WidgetState.Ready,
            Body: body,
            Caption: caption,
            Action: action,
            Activate: () => context.Actions.RefreshPlatforms(),
            Accent: accentBrush,
            Summary: summary);
    }

    private static (Color Color, PlatformServiceState State) DetermineWorstState(
        IReadOnlyList<PlatformServiceStatus> list,
        bool isStale)
    {
        if (isStale || list.Count == 0)
        {
            return (Color.FromArgb(255, 0x9A, 0xA3, 0xB5), PlatformServiceState.Unknown);
        }

        if (list.Any(p => p.State == PlatformServiceState.Outage))
        {
            return (Color.FromArgb(255, 0xFF, 0x5A, 0x36), PlatformServiceState.Outage);
        }

        if (list.Any(p => p.State == PlatformServiceState.Degraded))
        {
            return (Color.FromArgb(255, 0xF5, 0x9E, 0x0B), PlatformServiceState.Degraded);
        }

        if (list.Any(p => p.State == PlatformServiceState.Operational))
        {
            return (Color.FromArgb(255, 0x22, 0xC5, 0x5E), PlatformServiceState.Operational);
        }

        return (Color.FromArgb(255, 0x9A, 0xA3, 0xB5), PlatformServiceState.Unknown);
    }

    private static string PlatformDisplayName(string id) => id.ToLowerInvariant() switch
    {
        "playstation" => "PSN",
        "xbox" => "Xbox",
        "steam" => "Steam",
        "epicgames" => "Epic Games",
        "nintendo" => "Nintendo",
        _ => id,
    };

    private static (char Symbol, string Label, Color Color) PlatformStateInfo(PlatformServiceState state, bool isStale)
    {
        if (isStale)
        {
            return ('?', Strings.Tr("Não verificado"), Color.FromArgb(255, 0x9A, 0xA3, 0xB5));
        }

        return state switch
        {
            PlatformServiceState.Operational => ('●', Strings.Tr("Operacional"), Color.FromArgb(255, 0x22, 0xC5, 0x5E)),
            PlatformServiceState.Degraded => ('▲', Strings.Tr("Degradado"), Color.FromArgb(255, 0xF5, 0x9E, 0x0B)),
            PlatformServiceState.Outage => ('×', Strings.Tr("Indisponível"), Color.FromArgb(255, 0xFF, 0x5A, 0x36)),
            _ => ('?', Strings.Tr("Não verificado"), Color.FromArgb(255, 0x9A, 0xA3, 0xB5)),
        };
    }

    private static FrameworkElement BuildPlatformLogo(string id, double size = 18)
    {
        var logoGlyph = id.ToLowerInvariant() switch
        {
            "steam" => Glyphs.Steam,
            "epicgames" => Glyphs.Epic,
            "xbox" => Glyphs.Xbox,
            _ => null,
        };

        var textBrush = Application.Current?.Resources.TryGetValue("TextPrimaryBrush", out var b) == true && b is Brush brush
            ? brush
            : new SolidColorBrush(Color.FromArgb(255, 0xF5, 0xF7, 0xFC));

        if (logoGlyph is not null)
        {
            return new SvgIcon
            {
                Data = logoGlyph,
                Size = size,
                FillOnly = true,
                Foreground = textBrush,
                VerticalAlignment = VerticalAlignment.Center,
                HorizontalAlignment = HorizontalAlignment.Center,
            };
        }

        // Sem logo oficial no app (PSN, Nintendo): um controle genérico, o nome já aparece ao lado.
        return new FontIcon
        {
            Glyph = "\uE7FC",
            FontFamily = new FontFamily("Segoe Fluent Icons"),
            FontSize = size * 0.9,
            Foreground = textBrush,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };
    }

    private static UIElement BuildFullRowsBody(IReadOnlyList<PlatformServiceStatus> list, bool isStale)
    {
        var panel = new StackPanel
        {
            Spacing = 6,
            VerticalAlignment = VerticalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };

        foreach (var p in list)
        {
            var grid = new Grid { HorizontalAlignment = HorizontalAlignment.Stretch };
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(24, GridUnitType.Pixel) });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

            var logo = BuildPlatformLogo(p.Id, 18);
            Grid.SetColumn(logo, 0);
            grid.Children.Add(logo);

            var nameText = new TextBlock
            {
                Text = PlatformDisplayName(p.Id),
                FontSize = 12,
                Margin = new Thickness(8, 0, 8, 0),
                VerticalAlignment = VerticalAlignment.Center,
                TextTrimming = TextTrimming.CharacterEllipsis,
            };
            Grid.SetColumn(nameText, 1);
            grid.Children.Add(nameText);

            var (symbol, label, color) = PlatformStateInfo(p.State, isStale);
            var statusStack = new StackPanel
            {
                Orientation = Orientation.Horizontal,
                Spacing = 4,
                VerticalAlignment = VerticalAlignment.Center,
            };
            statusStack.Children.Add(WidgetParts.StatusDot(color, symbol));
            statusStack.Children.Add(new TextBlock
            {
                Text = label,
                FontSize = 11,
                Foreground = new SolidColorBrush(color),
                VerticalAlignment = VerticalAlignment.Center,
            });

            Grid.SetColumn(statusStack, 2);
            grid.Children.Add(statusStack);

            AutomationProperties.SetName(grid, $"{PlatformDisplayName(p.Id)}: {label}");
            panel.Children.Add(grid);
        }

        return panel;
    }

    private static UIElement BuildCompactIconsBody(IReadOnlyList<PlatformServiceStatus> list, bool isStale)
    {
        var panel = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 16,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        foreach (var p in list)
        {
            var item = new StackPanel
            {
                Spacing = 4,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center,
            };

            var logo = BuildPlatformLogo(p.Id, 20);
            item.Children.Add(logo);

            var (symbol, label, color) = PlatformStateInfo(p.State, isStale);
            item.Children.Add(WidgetParts.StatusDot(color, symbol));

            var description = $"{PlatformDisplayName(p.Id)}: {label}";
            ToolTipService.SetToolTip(item, description);
            AutomationProperties.SetName(item, description);

            panel.Children.Add(item);
        }

        return panel;
    }

    private static UIElement BuildWideLineBody(IReadOnlyList<PlatformServiceStatus> list, bool isStale)
    {
        var panel = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 20,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        foreach (var p in list)
        {
            var item = new StackPanel
            {
                Orientation = Orientation.Horizontal,
                Spacing = 6,
                VerticalAlignment = VerticalAlignment.Center,
            };

            var logo = BuildPlatformLogo(p.Id, 18);
            item.Children.Add(logo);

            var nameBlock = new TextBlock
            {
                Text = PlatformDisplayName(p.Id),
                FontFamily = (FontFamily)Application.Current.Resources["BodySemiBoldFont"],
                FontSize = 13,
                FontWeight = Microsoft.UI.Text.FontWeights.Normal,
                VerticalAlignment = VerticalAlignment.Center,
            };
            item.Children.Add(nameBlock);

            var (symbol, label, color) = PlatformStateInfo(p.State, isStale);
            item.Children.Add(WidgetParts.StatusDot(color, symbol));
            item.Children.Add(new TextBlock
            {
                Text = label,
                FontSize = 12,
                Foreground = new SolidColorBrush(color),
                VerticalAlignment = VerticalAlignment.Center,
            });

            var description = $"{PlatformDisplayName(p.Id)}: {label}";
            ToolTipService.SetToolTip(item, description);
            AutomationProperties.SetName(item, description);

            panel.Children.Add(item);
        }

        return panel;
    }
}
