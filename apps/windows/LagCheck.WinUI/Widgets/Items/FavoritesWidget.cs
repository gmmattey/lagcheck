using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Automation;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using LagCheck.WinUI.Controls;
using LagCheck.WinUI.Library;
using LagCheck.WinUI.Localization;

namespace LagCheck.WinUI.Widgets.Items;

public sealed class FavoritesWidget : IHomeWidget
{
    public string Id => "favorites";
    public string Title => Strings.Tr("FAVORITOS");
    public string IconPath => "M12 21s-7-4.6-9.3-9A5.3 5.3 0 0 1 12 6.6 5.3 5.3 0 0 1 21.3 12C19 16.4 12 21 12 21z";

    public bool IsAvailable(WidgetContext context)
    {
        if (!context.IsPc && context.Game is not null) return false;
        return context.Library.Any(g => g.IsFavorite && g.IsInstalled);
    }

    public IReadOnlyList<WidgetSpan> Sizes(WidgetContext context) =>
    [
        new WidgetSpan(2, 1),
        new WidgetSpan(4, 1),
        new WidgetSpan(2, 2),
    ];

    public WidgetContent Render(WidgetContext context, WidgetSpan span)
    {
        var effectiveSpan = Sizes(context).Contains(span) ? span : Sizes(context)[0];

        var favs = context.Library.Where(g => g.IsFavorite && g.IsInstalled).ToList();

        if (favs.Count == 0)
        {
            return new WidgetContent(
                State: WidgetState.Empty,
                Message: Strings.Tr("Nenhum favorito instalado ainda."),
                Summary: Strings.Tr("Nenhum favorito instalado ainda."));
        }

        var caption = Strings.Format(favs.Count == 1 ? "{0} favorito" : "{0} favoritos", favs.Count);
        var summary = Strings.Format("{0} favoritos instalados.", favs.Count);

        var body = effectiveSpan switch
        {
            { Cols: 4, Rows: 1 } => BuildStripBody(favs, context, maxCount: 8),
            { Cols: 2, Rows: 2 } => BuildGridBody(favs, context, maxCount: 6),
            _ => BuildStripBody(favs, context, maxCount: 4),
        };

        return new WidgetContent(
            State: WidgetState.Ready,
            Body: body,
            Caption: caption,
            Summary: summary);
    }

    private static UIElement BuildStripBody(IReadOnlyList<LibraryGame> favs, WidgetContext context, int maxCount)
    {
        var panel = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 8,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var displayCount = Math.Min(favs.Count, maxCount);
        for (var i = 0; i < displayCount; i++)
        {
            panel.Children.Add(BuildCoverButton(favs[i], context, width: 40, height: 60, cornerRadius: 8));
        }

        if (favs.Count > maxCount)
        {
            var remaining = favs.Count - maxCount;
            var secBrush = Application.Current?.Resources.TryGetValue("TextSecondaryBrush", out var b) == true && b is Brush brush
                ? brush
                : new SolidColorBrush(Windows.UI.Color.FromArgb(255, 0x9A, 0xA3, 0xB5));

            var overflowText = new TextBlock
            {
                Text = $"+{remaining}",
                FontFamily = (FontFamily)Application.Current.Resources["BodySemiBoldFont"],
                FontSize = 14,
                FontWeight = Microsoft.UI.Text.FontWeights.Normal,
                Foreground = secBrush,
                VerticalAlignment = VerticalAlignment.Center,
                Margin = new Thickness(4, 0, 0, 0),
            };
            panel.Children.Add(overflowText);
        }

        return panel;
    }

    private static UIElement BuildGridBody(IReadOnlyList<LibraryGame> favs, WidgetContext context, int maxCount)
    {
        var grid = new Grid
        {
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Center,
            RowSpacing = 6,
            ColumnSpacing = 6,
        };

        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        var count = Math.Min(favs.Count, maxCount);
        for (var i = 0; i < count; i++)
        {
            var game = favs[i];
            var col = i % 3;
            var row = i / 3;

            var itemStack = new StackPanel
            {
                Spacing = 2,
                HorizontalAlignment = HorizontalAlignment.Center,
                Width = 56,
            };

            var btn = BuildCoverButton(game, context, width: 56, height: 80, cornerRadius: 8);
            itemStack.Children.Add(btn);

            var titleText = new TextBlock
            {
                Text = game.Title,
                FontSize = 10,
                TextTrimming = TextTrimming.CharacterEllipsis,
                TextAlignment = TextAlignment.Center,
                MaxWidth = 56,
            };
            itemStack.Children.Add(titleText);

            Grid.SetColumn(itemStack, col);
            Grid.SetRow(itemStack, row);
            grid.Children.Add(itemStack);
        }

        return grid;
    }

    private static Button BuildCoverButton(
        LibraryGame game,
        WidgetContext context,
        double width,
        double height,
        double cornerRadius)
    {
        var image = new Image
        {
            Source = Artwork.Load(Artwork.FirstExisting(game.CoverArtworkPath), 120),
            Stretch = Stretch.UniformToFill,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };

        var border = new Border
        {
            Width = width,
            Height = height,
            CornerRadius = new CornerRadius(cornerRadius),
            Child = image,
            Background = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 0x1E, 0x23, 0x2B)),
        };

        var btn = new Button
        {
            Content = border,
            Padding = new Thickness(0),
            BorderThickness = new Thickness(0),
            Background = new SolidColorBrush(Microsoft.UI.Colors.Transparent),
        };

        Fluid.Feedback(btn);
        ToolTipService.SetToolTip(btn, game.Title);
        AutomationProperties.SetName(btn, game.Title);
        btn.Click += (_, _) => context.Actions.SelectGame(game);

        return btn;
    }
}
