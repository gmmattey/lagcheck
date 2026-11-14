using System;
using System.Collections.Generic;
using System.Globalization;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Documents;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.Foundation;
using Windows.UI;
using LagCheck.WinUI.Controls;
using LagCheck.WinUI.Localization;

namespace LagCheck.WinUI.Widgets;

/// <summary>
/// Helpers visuais reutilizáveis para os corpos dos widgets da tela Início.
/// Mantém consistência com os limites de diagnóstico e com o Design System da aplicação.
/// </summary>
public static class WidgetParts
{
    /// <summary>Rótulo técnico 11px + valor monoespaçado 22px + unidade opcional 12px.</summary>
    public static StackPanel Metric(string label, string value, string? unit, Color valueColor)
    {
        var panel = new StackPanel { Spacing = 2 };

        var labelBlock = new TextBlock
        {
            Text = label.ToUpper(CultureInfo.CurrentCulture),
            FontSize = 11,
            TextTrimming = TextTrimming.CharacterEllipsis,
        };
        if (Application.Current?.Resources.TryGetValue("TechLabelStyle", out var styleObj) == true && styleObj is Style style)
        {
            labelBlock.Style = style;
        }
        else if (Application.Current?.Resources.TryGetValue("TechnicalFont", out var fontObj) == true && fontObj is FontFamily font)
        {
            labelBlock.FontFamily = font;
        }
        labelBlock.FontSize = 11;
        panel.Children.Add(labelBlock);

        var valueBlock = new TextBlock
        {
            FontSize = 22,
            Foreground = new SolidColorBrush(valueColor),
            TextTrimming = TextTrimming.CharacterEllipsis,
        };
        if (Application.Current?.Resources.TryGetValue("MetricFont", out var metricFontObj) == true && metricFontObj is FontFamily metricFont)
        {
            valueBlock.FontFamily = metricFont;
        }

        valueBlock.Inlines.Add(new Run { Text = value });
        if (!string.IsNullOrWhiteSpace(unit))
        {
            var secBrush = Application.Current?.Resources.TryGetValue("TextSecondaryBrush", out var b) == true && b is Brush brush
                ? brush
                : new SolidColorBrush(Color.FromArgb(255, 0x9A, 0xA3, 0xB5));

            var unitRun = new Run
            {
                Text = " " + unit,
                FontSize = 12,
                Foreground = secBrush,
            };
            valueBlock.Inlines.Add(unitRun);
        }
        panel.Children.Add(valueBlock);

        return panel;
    }

    /// <summary>Ponto ou glifo semântico de status com cor dedicada.</summary>
    public static FrameworkElement StatusDot(Color color, char shape = '●') =>
        new TextBlock
        {
            Text = shape.ToString(),
            FontSize = 11,
            Foreground = new SolidColorBrush(color),
            VerticalAlignment = VerticalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Center
        };

    /// <summary>
    /// Gráfico de linha compacto (Canvas dentro de Grid).
    /// Redesenha no SizeChanged; polilinha 1,5 px com cor 60% + pontos de 5 px, último ponto branco de 8 px e tooltip.
    /// Se menos de 2 pontos válidos, retorna Grid vazio.
    /// </summary>
    public static FrameworkElement Sparkline(IReadOnlyList<double> values, Color line)
    {
        if (values == null || values.Count < 2)
        {
            return new Grid();
        }

        var grid = new Grid { HorizontalAlignment = HorizontalAlignment.Stretch, VerticalAlignment = VerticalAlignment.Stretch };
        var canvas = new Canvas { HorizontalAlignment = HorizontalAlignment.Stretch, VerticalAlignment = VerticalAlignment.Stretch };
        grid.Children.Add(canvas);

        void Redraw()
        {
            canvas.Children.Clear();
            var width = grid.ActualWidth;
            var height = grid.ActualHeight;
            if (width <= 12 || height <= 12) return;

            var min = double.MaxValue;
            var max = double.MinValue;
            for (var i = 0; i < values.Count; i++)
            {
                var v = values[i];
                if (v < min) min = v;
                if (v > max) max = v;
            }

            var range = max - min;
            if (range <= 0.0001) range = 1.0;

            const double padX = 6.0;
            const double padY = 6.0;
            var usableW = width - (padX * 2);
            var usableH = height - (padY * 2);

            var polyline = new Polyline
            {
                StrokeThickness = 1.5,
                Stroke = new SolidColorBrush(Color.FromArgb((byte)(255 * 0.6), line.R, line.G, line.B)),
                StrokeLineJoin = PenLineJoin.Round,
            };

            var points = new PointCollection();
            var count = values.Count;

            for (var i = 0; i < count; i++)
            {
                var val = values[i];
                var x = padX + (count > 1 ? (usableW * i / (count - 1)) : (usableW / 2));
                var normY = (val - min) / range;
                var y = padY + usableH * (1.0 - normY);

                points.Add(new Point(x, y));

                var isLast = (i == count - 1);
                var dotSize = isLast ? 8.0 : 5.0;
                var dotColor = isLast ? Microsoft.UI.Colors.White : line;

                var dot = new Ellipse
                {
                    Width = dotSize,
                    Height = dotSize,
                    Fill = new SolidColorBrush(dotColor),
                };

                Canvas.SetLeft(dot, x - (dotSize / 2.0));
                Canvas.SetTop(dot, y - (dotSize / 2.0));

                ToolTipService.SetToolTip(dot, $"{val:0.#} ms");
                canvas.Children.Add(dot);
            }

            polyline.Points = points;
            canvas.Children.Insert(0, polyline);
        }

        grid.SizeChanged += (_, _) => Redraw();
        grid.Loaded += (_, _) => Redraw();

        return grid;
    }

    /// <summary>Formatação relativa de data ("hoje", "ontem", "há N dias").</summary>
    public static string RelativeDay(DateTimeOffset date)
    {
        var today = DateTimeOffset.Now.Date;
        var target = date.ToLocalTime().Date;
        var days = (today - target).Days;

        if (days <= 0) return Strings.Tr("hoje");
        if (days == 1) return Strings.Tr("ontem");
        return Strings.Format("há {0} dias", days);
    }

    /// <summary>Tom semântico por valor medido usando os limites de diagnóstico.</summary>
    public static Color MetricTone(double value, double okLimit, double warnLimit) =>
        value <= okLimit ? Verdicts.ColorOf(VerdictTone.Ok) :
        value <= warnLimit ? Verdicts.ColorOf(VerdictTone.Warn) :
        Verdicts.ColorOf(VerdictTone.Bad);

    public static Color PingColor(double ping) => MetricTone(ping, 45, 90);
    public static Color JitterColor(double jitter) => MetricTone(jitter, 8, 20);
    public static Color LossColor(double loss) => MetricTone(loss, 0.5, 2);
    public static Color LoadColor(double loadDelta) => MetricTone(loadDelta, 15, 40);
}
