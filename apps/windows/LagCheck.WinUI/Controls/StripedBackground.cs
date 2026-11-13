using System;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Path = Microsoft.UI.Xaml.Shapes.Path;
using Windows.Foundation;
using Windows.UI;

namespace LagCheck.WinUI.Controls;

/// <summary>
/// Miniatura neutra do v2: repeating-linear-gradient(135deg, #1c2230 0 N, #232a3a N 2N).
/// Usada quando o jogo ainda não tem arte local (nunca baixamos imagens por conta própria).
/// </summary>
public sealed class StripedBackground : Grid
{
    private readonly Path _stripes = new() { Fill = new SolidColorBrush(Color.FromArgb(255, 0x23, 0x2A, 0x3A)) };
    private readonly Canvas _canvas = new();
    private double _band = 14;

    public StripedBackground()
    {
        Background = new SolidColorBrush(Color.FromArgb(255, 0x1C, 0x22, 0x30));
        _canvas.Children.Add(_stripes);
        Children.Add(_canvas);
        IsHitTestVisible = false;
        SizeChanged += (_, e) => Rebuild(e.NewSize);
    }

    /// <summary>Largura de cada faixa em px (14 nos cards, 18 nos banners).</summary>
    public double Band
    {
        get => _band;
        set
        {
            _band = Math.Max(4, value);
            if (ActualWidth > 0) Rebuild(new Size(ActualWidth, ActualHeight));
        }
    }

    private void Rebuild(Size size)
    {
        if (size.Width <= 0 || size.Height <= 0) return;
        _canvas.Clip = new RectangleGeometry { Rect = new Rect(0, 0, size.Width, size.Height) };
        var group = new PathGeometry();
        var step = _band * Math.Sqrt(2);        // largura da faixa medida em (x + y)
        var maxSum = size.Width + size.Height;
        var margin = size.Height + 4;
        for (var s = step; s < maxSum + step; s += step * 2)
        {
            var figure = new PathFigure { StartPoint = new Point(s + margin, -margin), IsClosed = true, IsFilled = true };
            figure.Segments.Add(new LineSegment { Point = new Point(s + step + margin, -margin) });
            figure.Segments.Add(new LineSegment { Point = new Point(-margin, s + step + margin) });
            figure.Segments.Add(new LineSegment { Point = new Point(-margin, s + margin) });
            group.Figures.Add(figure);
        }
        _stripes.Data = group;
    }
}
