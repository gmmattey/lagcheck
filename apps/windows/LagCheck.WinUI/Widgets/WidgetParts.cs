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
using LagCheck.WinUI.History;
using LagCheck.WinUI.Localization;
using Path = Microsoft.UI.Xaml.Shapes.Path;

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

    public static VerdictTone MetricVerdictTone(double value, double okLimit, double warnLimit) =>
        value <= okLimit ? VerdictTone.Ok :
        value <= warnLimit ? VerdictTone.Warn :
        VerdictTone.Bad;

    /// <summary>Divisória vertical fina ("|") entre colunas de métricas.</summary>
    public static FrameworkElement VerticalDivider(double verticalMargin = 4) => new Border
    {
        Width = 1,
        VerticalAlignment = VerticalAlignment.Stretch,
        Margin = new Thickness(0, verticalMargin, 0, verticalMargin),
        Background = new SolidColorBrush(Color.FromArgb(0x24, 255, 255, 255)),
        IsHitTestVisible = false,
    };

    /// <summary>
    /// Razão de preenchimento do anel (0..1): bom preenche 85–100%, atenção 55–75%, ruim 22–45%.
    /// </summary>
    public static double MetricRatio(double value, double okLimit, double warnLimit, double maxScale)
    {
        if (!double.IsFinite(value) || value < 0) return 0;
        if (value <= okLimit)
        {
            var t = okLimit <= 0 ? 0 : Math.Clamp(value / okLimit, 0, 1);
            return 1.0 - (0.15 * t);
        }
        if (value <= warnLimit)
        {
            var span = Math.Max(warnLimit - okLimit, 0.0001);
            var t = Math.Clamp((value - okLimit) / span, 0, 1);
            return 0.75 - (0.20 * t);
        }
        var badSpan = Math.Max(maxScale - warnLimit, 0.0001);
        var badT = Math.Clamp((value - warnLimit) / badSpan, 0, 1);
        return Math.Max(0.22, 0.45 - (0.23 * badT));
    }

    /// <summary>
    /// Número monoespaçado dentro de um círculo envolto por anel colorido (verde/âmbar/coral)
    /// e marcador geométrico + rótulo abaixo.
    /// </summary>
    public static FrameworkElement RingMetricGauge(
        string label,
        string value,
        string? unit,
        Color toneColor,
        VerdictTone tone,
        double ratio,
        double ringSize = 56)
    {
        var compact = ringSize < 50;
        var stroke = ringSize >= 52 ? 3.5 : 3.0;

        var ringGrid = new Grid
        {
            Width = ringSize,
            Height = ringSize,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        // Fundo sutil dentro do anel
        var innerDiameter = Math.Max(8, ringSize - (stroke * 2));
        if (tone != VerdictTone.Unknown && ratio > 0)
        {
            ringGrid.Children.Add(new Ellipse
            {
                Width = innerDiameter,
                Height = innerDiameter,
                Fill = new SolidColorBrush(Color.FromArgb(0x14, toneColor.R, toneColor.G, toneColor.B)),
                IsHitTestVisible = false,
            });
        }

        // Trilha neutra
        ringGrid.Children.Add(new Ellipse
        {
            Width = ringSize,
            Height = ringSize,
            Stroke = new SolidColorBrush(Color.FromArgb(0x22, 255, 255, 255)),
            StrokeThickness = stroke,
            IsHitTestVisible = false,
        });

        // Anel de status colorido
        if (tone != VerdictTone.Unknown && ratio > 0)
        {
            var clamped = Math.Clamp(ratio, 0.14, 1.0);
            if (clamped >= 0.995)
            {
                ringGrid.Children.Add(new Ellipse
                {
                    Width = ringSize,
                    Height = ringSize,
                    Stroke = new SolidColorBrush(toneColor),
                    StrokeThickness = stroke,
                    IsHitTestVisible = false,
                });
            }
            else
            {
                var radius = (ringSize - stroke) / 2.0;
                var cx = ringSize / 2.0;
                var cy = ringSize / 2.0;
                const double startAngle = -Math.PI / 2.0;
                var endAngle = startAngle + (clamped * 2.0 * Math.PI);

                var startPoint = new Point(cx + radius * Math.Cos(startAngle), cy + radius * Math.Sin(startAngle));
                var endPoint = new Point(cx + radius * Math.Cos(endAngle), cy + radius * Math.Sin(endAngle));

                var figure = new PathFigure { StartPoint = startPoint, IsClosed = false };
                figure.Segments.Add(new ArcSegment
                {
                    Point = endPoint,
                    Size = new Size(radius, radius),
                    IsLargeArc = clamped > 0.5,
                    SweepDirection = SweepDirection.Clockwise,
                });

                var geometry = new PathGeometry();
                geometry.Figures.Add(figure);

                ringGrid.Children.Add(new Path
                {
                    Width = ringSize,
                    Height = ringSize,
                    Stroke = new SolidColorBrush(toneColor),
                    StrokeThickness = stroke,
                    StrokeStartLineCap = PenLineCap.Round,
                    StrokeEndLineCap = PenLineCap.Round,
                    Data = geometry,
                    IsHitTestVisible = false,
                });
            }
        }

        // Valor e unidade centralizados dentro do círculo
        var centerStack = new StackPanel
        {
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Spacing = 0,
        };

        var valueBlock = new TextBlock
        {
            Text = value,
            FontSize = compact ? 12.5 : 15,
            LineHeight = compact ? 13 : 16,
            LineStackingStrategy = LineStackingStrategy.BlockLineHeight,
            Foreground = new SolidColorBrush(toneColor),
            HorizontalAlignment = HorizontalAlignment.Center,
            TextAlignment = TextAlignment.Center,
        };
        if (Application.Current?.Resources.TryGetValue("MetricFont", out var metricFontObj) == true && metricFontObj is FontFamily metricFont)
        {
            valueBlock.FontFamily = metricFont;
        }
        centerStack.Children.Add(valueBlock);

        if (!string.IsNullOrWhiteSpace(unit))
        {
            var secBrush = Application.Current?.Resources.TryGetValue("TextSecondaryBrush", out var b) == true && b is Brush brush
                ? brush
                : new SolidColorBrush(Color.FromArgb(255, 0x9A, 0xA3, 0xB5));

            centerStack.Children.Add(new TextBlock
            {
                Text = unit,
                FontSize = compact ? 9 : 10,
                LineHeight = compact ? 10 : 11,
                LineStackingStrategy = LineStackingStrategy.BlockLineHeight,
                Foreground = secBrush,
                HorizontalAlignment = HorizontalAlignment.Center,
                TextAlignment = TextAlignment.Center,
            });
        }

        ringGrid.Children.Add(centerStack);

        var labelRow = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 4,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };
        labelRow.Children.Add(Verdicts.Marker(tone, compact ? 5.5 : 6.5));

        var labelBlock = new TextBlock
        {
            Text = label.ToUpper(CultureInfo.CurrentCulture),
            FontSize = compact ? 9 : 10,
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Center,
        };
        if (Application.Current?.Resources.TryGetValue("TechLabelStyle", out var styleObj) == true && styleObj is Style style)
        {
            labelBlock.Style = style;
        }
        else if (Application.Current?.Resources.TryGetValue("TechnicalFont", out var fontObj) == true && fontObj is FontFamily font)
        {
            labelBlock.FontFamily = font;
        }
        labelBlock.FontSize = compact ? 9 : 10;
        labelRow.Children.Add(labelBlock);

        var root = new StackPanel
        {
            Spacing = compact ? 3 : 5,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };
        root.Children.Add(ringGrid);
        root.Children.Add(labelRow);
        return root;
    }

    /// <summary>
    /// Gráfico de estabilidade com pontos coloridos por veredito (verde/âmbar/coral)
    /// e tooltip detalhado com jogo, latência, jitter e horário.
    /// </summary>
    public static FrameworkElement StabilityChart(IReadOnlyList<StabilityPoint> points, Color lineColor)
    {
        if (points == null || points.Count == 0)
        {
            return new Grid();
        }

        var grid = new Grid
        {
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        var canvas = new Canvas
        {
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        grid.Children.Add(canvas);

        void Redraw()
        {
            canvas.Children.Clear();
            var width = grid.ActualWidth;
            var height = grid.ActualHeight;
            if (width <= 12 || height <= 12) return;

            const double padX = 8.0;
            const double padY = 8.0;
            var usableW = width - (padX * 2);
            var usableH = height - (padY * 2);

            // Guias horizontais sutis (topo e base)
            var guideBrush = new SolidColorBrush(Color.FromArgb(0x14, 255, 255, 255));
            canvas.Children.Add(new Line { X1 = padX, Y1 = padY, X2 = width - padX, Y2 = padY, Stroke = guideBrush, StrokeThickness = 1, IsHitTestVisible = false });
            canvas.Children.Add(new Line { X1 = padX, Y1 = height - padY, X2 = width - padX, Y2 = height - padY, Stroke = guideBrush, StrokeThickness = 1, IsHitTestVisible = false });

            var min = double.MaxValue;
            var max = double.MinValue;
            for (var i = 0; i < points.Count; i++)
            {
                var p = points[i].PingMs;
                if (p < min) min = p;
                if (p > max) max = p;
            }
            var range = max - min;
            var flat = range <= 0.0001;

            var segmentLines = new List<PointCollection>();
            PointCollection? activeSegment = null;
            var count = points.Count;

            for (var i = 0; i < count; i++)
            {
                var pt = points[i];
                var x = count == 1 ? padX + usableW / 2.0 : padX + (usableW * i / (count - 1));
                var y = flat ? padY + usableH * 0.5 : padY + usableH * (1.0 - (pt.PingMs - min) / range);

                if (i > 0 && pt.ConnectToPrevious)
                {
                    if (activeSegment is null)
                    {
                        var prevPt = points[i - 1];
                        var prevX = count == 1 ? padX + usableW / 2.0 : padX + (usableW * (i - 1) / (count - 1));
                        var prevY = flat ? padY + usableH * 0.5 : padY + usableH * (1.0 - (prevPt.PingMs - min) / range);
                        activeSegment = [new Point(prevX, prevY)];
                        segmentLines.Add(activeSegment);
                    }
                    activeSegment.Add(new Point(x, y));
                }
                else
                {
                    activeSegment = null;
                }

                var isLast = i == count - 1;
                var ptColor = Verdicts.ColorOf(pt.Tone);
                var dotSize = isLast ? 9.0 : 6.0;

                if (isLast)
                {
                    var halo = new Ellipse
                    {
                        Width = 14.0,
                        Height = 14.0,
                        Stroke = new SolidColorBrush(Color.FromArgb(0xCC, 255, 255, 255)),
                        StrokeThickness = 1.5,
                        IsHitTestVisible = false,
                    };
                    Canvas.SetLeft(halo, x - 7.0);
                    Canvas.SetTop(halo, y - 7.0);
                    canvas.Children.Add(halo);
                }

                var dot = new Ellipse
                {
                    Width = dotSize,
                    Height = dotSize,
                    Fill = new SolidColorBrush(ptColor),
                };
                Canvas.SetLeft(dot, x - (dotSize / 2.0));
                Canvas.SetTop(dot, y - (dotSize / 2.0));

                var gameName = !string.IsNullOrWhiteSpace(pt.GameTitle)
                    ? pt.GameTitle
                    : !string.IsNullOrWhiteSpace(pt.GameId)
                        ? pt.GameId
                        : Strings.Tr("Conexão geral");
                var localTime = pt.CapturedAt.ToLocalTime();
                var timeLabel = localTime.Date == DateTime.Today
                    ? localTime.ToString("HH:mm", CultureInfo.CurrentCulture)
                    : localTime.ToString("d MMM HH:mm", LocalizationService.Instance.EffectiveCulture);
                var jitterSuffix = pt.JitterMs is { } j
                    ? $" · {Strings.Tr("JITTER").ToLower(CultureInfo.CurrentCulture)} {j:0.#} ms"
                    : string.Empty;

                ToolTipService.SetToolTip(dot, $"{gameName} · {pt.PingMs:0.#} ms{jitterSuffix} · {timeLabel}");
                canvas.Children.Add(dot);
            }

            var insertIndex = Math.Min(2, canvas.Children.Count);
            foreach (var segPoints in segmentLines)
            {
                if (segPoints.Count < 2) continue;
                var polyline = new Polyline
                {
                    StrokeThickness = 2.0,
                    Stroke = new SolidColorBrush(Color.FromArgb(0xA6, lineColor.R, lineColor.G, lineColor.B)),
                    StrokeLineJoin = PenLineJoin.Round,
                    Points = segPoints,
                    IsHitTestVisible = false,
                };
                canvas.Children.Insert(insertIndex++, polyline);
            }
        }

        grid.SizeChanged += (_, _) => Redraw();
        grid.Loaded += (_, _) => Redraw();

        return grid;
    }
}
