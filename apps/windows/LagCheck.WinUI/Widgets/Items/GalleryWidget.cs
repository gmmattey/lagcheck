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

public sealed class GalleryWidget : IHomeWidget
{
    public string Id => "gallery";
    public string Title => Strings.Tr("CAPTURAS");
    public string IconPath => "M4 5h16v14H4zM7 15l3-3 2 2 3-4 3 5";

    public bool IsAvailable(WidgetContext context)
    {
        if (context.Game is null || context.IsPc) return false;
        return context.Game.UserScreenshots.Any(shot => Artwork.FirstExisting(shot.ThumbnailPath, shot.Path) is not null);
    }

    public IReadOnlyList<WidgetSpan> Sizes(WidgetContext context) =>
    [
        new WidgetSpan(2, 2),
        new WidgetSpan(4, 2),
        new WidgetSpan(2, 1),
    ];

    public WidgetContent Render(WidgetContext context, WidgetSpan span)
    {
        var effectiveSpan = Sizes(context).Contains(span) ? span : Sizes(context)[0];

        if (context.Game is null || context.IsPc)
        {
            return new WidgetContent(
                State: WidgetState.Empty,
                Message: Strings.Tr("Nenhuma captura local ainda."),
                Summary: Strings.Tr("Nenhuma captura local ainda."));
        }

        var game = context.Game;
        var validShots = game.UserScreenshots
            .Select(shot => Artwork.FirstExisting(shot.ThumbnailPath, shot.Path))
            .Where(file => !string.IsNullOrWhiteSpace(file))
            .Select(file => file!)
            .ToList();

        if (validShots.Count == 0)
        {
            return new WidgetContent(
                State: WidgetState.Empty,
                Message: Strings.Tr("Nenhuma captura local ainda."),
                Summary: Strings.Tr("Nenhuma captura local ainda."));
        }

        var caption = Strings.Format(validShots.Count == 1 ? "{0} captura" : "{0} capturas", validShots.Count);
        var action = new WidgetAction(Strings.Tr("Ver galeria"), () => context.Actions.OpenGallery());
        var summary = Strings.Format("{0} capturas salvas.", validShots.Count);

        var body = effectiveSpan switch
        {
            { Cols: 2, Rows: 1 } => BuildGridBody(validShots, game, context, cols: 2, rows: 1, maxCount: 2),
            { Cols: 4, Rows: 2 } => BuildGridBody(validShots, game, context, cols: 4, rows: 2, maxCount: 8),
            _ => BuildGridBody(validShots, game, context, cols: 2, rows: 2, maxCount: 4),
        };

        return new WidgetContent(
            State: WidgetState.Ready,
            Body: body,
            Caption: caption,
            Action: action,
            Activate: () => context.Actions.OpenGallery(),
            Summary: summary);
    }

    private static UIElement BuildGridBody(
        IReadOnlyList<string> files,
        LibraryGame game,
        WidgetContext context,
        int cols,
        int rows,
        int maxCount)
    {
        var grid = new Grid
        {
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
            RowSpacing = 6,
            ColumnSpacing = 6,
        };

        for (var c = 0; c < cols; c++)
        {
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        }
        for (var r = 0; r < rows; r++)
        {
            grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        }

        var count = Math.Min(files.Count, maxCount);
        for (var i = 0; i < count; i++)
        {
            var btn = BuildThumbnailButton(files[i], game, context);
            var col = i % cols;
            var row = i / cols;
            Grid.SetColumn(btn, col);
            Grid.SetRow(btn, row);
            grid.Children.Add(btn);
        }

        return grid;
    }

    private static Button BuildThumbnailButton(string filePath, LibraryGame game, WidgetContext context)
    {
        var image = new Image
        {
            Source = Artwork.Load(filePath, 160),
            Stretch = Stretch.UniformToFill,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };

        var shadowRect = new Microsoft.UI.Xaml.Shapes.Rectangle
        {
            RadiusX = 8,
            RadiusY = 8,
            Fill = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 0x0B, 0x0D, 0x10)),
            IsHitTestVisible = false,
        };
        GlowEffect.AttachShadow(shadowRect, Windows.UI.Color.FromArgb(0x88, 0, 0, 0), blur: 10f, offsetY: 4f);

        var border = new Border
        {
            CornerRadius = new CornerRadius(8),
            BorderThickness = new Thickness(1),
            BorderBrush = new SolidColorBrush(Windows.UI.Color.FromArgb(0x28, 255, 255, 255)),
            Child = image,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };

        var host = new Grid
        {
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        host.Children.Add(shadowRect);
        host.Children.Add(border);

        var btn = new Button
        {
            Content = host,
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(0),
            BorderThickness = new Thickness(0),
            Background = new SolidColorBrush(Microsoft.UI.Colors.Transparent),
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
            HorizontalContentAlignment = HorizontalAlignment.Stretch,
            VerticalContentAlignment = VerticalAlignment.Stretch,
        };

        Fluid.Feedback(btn);
        AutomationProperties.SetName(btn, Strings.Format("Captura de {0}", game.Title));
        btn.Click += (_, _) => context.Actions.OpenDetails(game);

        return btn;
    }
}
