using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Markup;
using Microsoft.UI.Xaml.Media;
using Path = Microsoft.UI.Xaml.Shapes.Path;

namespace LagCheck.WinUI.Controls;

/// <summary>
/// Ícone vetorial 24x24 (mesmos traçados SVG do protótipo v2). Herda a cor de Foreground do pai:
/// no modo contorno desenha o traço (2px, pontas arredondadas); no modo preenchido pinta a geometria.
/// </summary>
public sealed class SvgIcon : UserControl
{
    private readonly Path _path = new();
    private readonly Viewbox _box = new() { Stretch = Stretch.Uniform };

    public SvgIcon()
    {
        _path.StrokeLineJoin = PenLineJoin.Round;
        _path.StrokeStartLineCap = PenLineCap.Round;
        _path.StrokeEndLineCap = PenLineCap.Round;
        _path.StrokeThickness = 2;
        // Canvas 24x24 fixa o enquadramento, igual ao viewBox do SVG original.
        var canvas = new Canvas { Width = 24, Height = 24 };
        canvas.Children.Add(_path);
        _box.Child = canvas;
        Content = _box;
        IsTabStop = false;
        IsHitTestVisible = false;
        ApplySize(17);
        RegisterPropertyChangedCallback(ForegroundProperty, (_, _) => ApplyPaint());
        Loaded += (_, _) => ApplyPaint();
    }

    public static readonly DependencyProperty DataProperty = DependencyProperty.Register(nameof(Data), typeof(string), typeof(SvgIcon),
        new PropertyMetadata(string.Empty, (d, _) => ((SvgIcon)d).ApplyData()));
    public static readonly DependencyProperty SizeProperty = DependencyProperty.Register(nameof(Size), typeof(double), typeof(SvgIcon),
        new PropertyMetadata(17d, (d, e) => ((SvgIcon)d).ApplySize((double)e.NewValue)));
    public static readonly DependencyProperty IsFilledProperty = DependencyProperty.Register(nameof(IsFilled), typeof(bool), typeof(SvgIcon),
        new PropertyMetadata(false, (d, _) => ((SvgIcon)d).ApplyPaint()));
    public static readonly DependencyProperty StrokeWidthProperty = DependencyProperty.Register(nameof(StrokeWidth), typeof(double), typeof(SvgIcon),
        new PropertyMetadata(2d, (d, e) => ((SvgIcon)d)._path.StrokeThickness = (double)e.NewValue));
    /// <summary>Quando verdadeiro, o contorno some e só a geometria é pintada (logos de plataforma).</summary>
    public static readonly DependencyProperty FillOnlyProperty = DependencyProperty.Register(nameof(FillOnly), typeof(bool), typeof(SvgIcon),
        new PropertyMetadata(false, (d, _) => ((SvgIcon)d).ApplyPaint()));

    public string Data { get => (string)GetValue(DataProperty); set => SetValue(DataProperty, value); }
    public double Size { get => (double)GetValue(SizeProperty); set => SetValue(SizeProperty, value); }
    public bool IsFilled { get => (bool)GetValue(IsFilledProperty); set => SetValue(IsFilledProperty, value); }
    public double StrokeWidth { get => (double)GetValue(StrokeWidthProperty); set => SetValue(StrokeWidthProperty, value); }
    public bool FillOnly { get => (bool)GetValue(FillOnlyProperty); set => SetValue(FillOnlyProperty, value); }

    private void ApplySize(double size)
    {
        Width = size;
        Height = size;
        _box.Width = size;
        _box.Height = size;
    }

    private void ApplyData()
    {
        try
        {
            _path.Data = string.IsNullOrWhiteSpace(Data) ? null : (Geometry)XamlBindingHelper.ConvertValue(typeof(Geometry), Data);
        }
        catch
        {
            _path.Data = null;
        }
    }

    private void ApplyPaint()
    {
        var brush = Foreground;
        if (FillOnly)
        {
            _path.Fill = brush;
            _path.Stroke = null;
            return;
        }
        _path.Stroke = brush;
        _path.Fill = IsFilled ? brush : null;
    }
}
