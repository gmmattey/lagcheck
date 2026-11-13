using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Text;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Markup;
using Microsoft.UI.Xaml.Media;
using Windows.Foundation;
using Windows.UI;
using LagCheck.WinUI.Diagnostic;
using Path = Microsoft.UI.Xaml.Shapes.Path;
using Ellipse = Microsoft.UI.Xaml.Shapes.Ellipse;

namespace LagCheck.WinUI.Controls;

/// <summary>
/// Mapa de rota do v2 (porte de route-map.js): grade de continentes, regiões, arco usuário→região,
/// pacotes de sonda e rótulos. A câmera acompanha a rota com suavização exponencial.
/// A origem usa a localização aproximada autorizada pelo usuário; sem ela o mapa só mostra o mundo.
/// </summary>
public sealed class RouteMapView : Grid
{
    private static readonly Color Deep = Color.FromArgb(255, 0x0B, 0x0D, 0x10);
    private static readonly Color RegionColor = Color.FromArgb(255, 0x8A, 0x93, 0xA0);
    private static readonly Color Muted = Color.FromArgb(255, 0x60, 0x68, 0x73);
    private static readonly Color Purple = Color.FromArgb(255, 0x7C, 0x3A, 0xED);
    private static readonly Color PurpleLight = Color.FromArgb(255, 0xA7, 0x8B, 0xFA);
    private static readonly Color TextColor = Color.FromArgb(255, 0xF4, 0xF5, 0xF7);

    private static string? _landPathData;
    private static readonly Stopwatch Clock = Stopwatch.StartNew();

    private sealed class Sample { public double? Ms = null; public bool Ok = false; public int N = 0; }
    private sealed class Packet { public string Id = ""; public bool Sweep; public bool Out = true; public double Start; public double Dur; public double Rtt; }
    private readonly record struct Cam(double Lon, double Lat, double Zoom);
    private readonly record struct Arc(double X0, double Y0, double X1, double Y1, double Cx, double Cy);

    private readonly Canvas _canvas = new();
    private readonly Path _land = new() { Fill = new SolidColorBrush(Color.FromArgb(255, 54, 59, 65)), IsHitTestVisible = false };
    private readonly MatrixTransform _landTransform = new();
    private readonly Dictionary<string, Ellipse> _regionDots = new();
    private readonly Dictionary<string, Path> _sweepArcs = new();
    private readonly Path _routeArc = new() { Stroke = new SolidColorBrush(Purple), StrokeThickness = 1.6, IsHitTestVisible = false };
    private readonly List<Ellipse> _packetDots = new();
    private readonly Ellipse _selDot = new() { Width = 11.2, Height = 11.2, Fill = new SolidColorBrush(Purple), Stroke = new SolidColorBrush(Deep), StrokeThickness = 2 };
    private readonly Ellipse _userDot = new() { Width = 10, Height = 10, Fill = new SolidColorBrush(TextColor), Stroke = new SolidColorBrush(Deep), StrokeThickness = 2 };
    private readonly Border _userLabel = new();
    private readonly Border _destLabel = new();
    private readonly Dictionary<string, Sample> _regions = new();
    private readonly List<Packet> _packets = new();

    private (double Lat, double Lon, string? City)? _user;
    private string? _selId;
    private double? _selMs;
    private bool _sweepWanted;
    private bool _rendering;
    private double _lastFrame;
    private Cam _cam = new(0, 12, 1);
    private readonly bool _animate;

    public RouteMapView(bool animate)
    {
        _animate = animate;
        Background = new SolidColorBrush(Deep);
        Children.Add(_canvas);
        _canvas.IsHitTestVisible = false;

        // Uma geometria nova por instância (um Geometry não pode ser compartilhado entre dois Path).
        _landPathData ??= BuildLandPathData();
        try { _land.Data = string.IsNullOrEmpty(_landPathData) ? null : (Geometry)XamlBindingHelper.ConvertValue(typeof(Geometry), _landPathData); }
        catch { _land.Data = null; }
        _land.RenderTransform = _landTransform;
        _canvas.Children.Add(_land);

        foreach (var region in RegionCatalog.All)
        {
            _sweepArcs[region.Id] = new Path { Stroke = new SolidColorBrush(Color.FromArgb(0x38, 0xA7, 0x8B, 0xFA)), StrokeThickness = 1, Visibility = Visibility.Collapsed };
            _canvas.Children.Add(_sweepArcs[region.Id]);
        }
        _canvas.Children.Add(_routeArc);
        foreach (var region in RegionCatalog.All)
        {
            var dot = new Ellipse { Width = 5.6, Height = 5.6 };
            _regionDots[region.Id] = dot;
            _canvas.Children.Add(dot);
        }
        _canvas.Children.Add(_selDot);
        _canvas.Children.Add(_userDot);
        _selDot.Visibility = Visibility.Collapsed;
        _userDot.Visibility = Visibility.Collapsed;
        InitLabel(_userLabel);
        InitLabel(_destLabel);
        _canvas.Children.Add(_userLabel);
        _canvas.Children.Add(_destLabel);

        SizeChanged += (_, e) =>
        {
            Clip = new RectangleGeometry { Rect = new Rect(0, 0, e.NewSize.Width, e.NewSize.Height) };
            _canvas.Width = e.NewSize.Width;
            _canvas.Height = e.NewSize.Height;
            if (!_animate) _cam = Target();
            Redraw();
        };
        Unloaded += (_, _) => StopRendering();
        _cam = Target();
    }

    // ------------------------------------------------------------------ API

    public void SetUser(double? latitude, double? longitude, string? city)
    {
        _user = latitude is { } lat && longitude is { } lon ? (lat, lon, city) : null;
        Retarget();
        TrySweep();
    }

    public void Reset()
    {
        _selId = null;
        _selMs = null;
        _regions.Clear();
        _packets.Clear();
        _sweepWanted = false;
        Retarget();
    }

    public void StartSweep()
    {
        _sweepWanted = true;
        TrySweep();
    }

    public void SelectRegion(string id, double? ms)
    {
        if (RegionCatalog.Find(id) is null) return;
        _selId = id;
        _sweepWanted = false;
        _packets.RemoveAll(packet => packet.Sweep);
        _selMs = ms ?? (_regions.TryGetValue(id, out var sample) ? sample.Ms : null) ?? _selMs;
        Retarget();
    }

    public void Probe(double rtt)
    {
        if (!_animate || _user is null || _selId is null || _packets.Count >= 6) return;
        _packets.Add(new Packet { Id = _selId, Sweep = false, Out = true, Start = Now(), Dur = 420, Rtt = rtt });
        EnsureRendering();
    }

    private void TrySweep()
    {
        if (!_animate || !_sweepWanted || _selId is not null || _user is null) return;
        _sweepWanted = false;
        var t0 = Now();
        var i = 0;
        foreach (var region in RegionCatalog.All)
            _packets.Add(new Packet { Id = region.Id, Sweep = true, Out = true, Start = t0 + i++ * 45, Dur = 620, Rtt = 0 });
        EnsureRendering();
    }

    /// <summary>Repete a varredura de sondas enquanto a região vencedora ainda não é conhecida.</summary>
    public void PulseSweep()
    {
        if (!_animate || _selId is not null || _user is null || _packets.Any(packet => packet.Sweep)) return;
        _sweepWanted = true;
        TrySweep();
    }

    // ------------------------------------------------------------------ câmera

    private static double Now() => Clock.Elapsed.TotalMilliseconds;

    private (double X, double Y) Project(double lat, double lon, Cam cam)
    {
        var k = ActualWidth / 360.0 * cam.Zoom;
        return (ActualWidth / 2 + (lon - cam.Lon) * k, ActualHeight / 2 - (lat - cam.Lat) * k);
    }

    private static Cam Fit(IReadOnlyList<(double Lat, double Lon)> points, double w, double h, double padX, double padY, double maxZoom)
    {
        var world = new Cam(0, 12, 1);
        if (points.Count == 0 || w <= 0 || h <= 0) return world;
        var lons = points.Select(p => p.Lon).ToArray();
        var lats = points.Select(p => p.Lat).ToArray();
        var ls = Math.Max(lons.Max() - lons.Min(), 8);
        var asp = Math.Max(lats.Max() - lats.Min(), 5);
        var ax = Math.Max(w - padX * 2, 20);
        var ay = Math.Max(h - padY * 2, 20);
        var zoom = Math.Min(maxZoom, Math.Max(1, Math.Min(ax * 360 / (w * ls), ay * 360 / (w * asp))));
        return new Cam((lons.Max() + lons.Min()) / 2, (lats.Max() + lats.Min()) / 2, zoom);
    }

    private Cam Target()
    {
        var w = ActualWidth;
        var h = ActualHeight;
        if (_selId is not null && RegionCatalog.Find(_selId) is { } sel)
        {
            var pts = new List<(double, double)> { (sel.Latitude, sel.Longitude) };
            if (_user is { } user) pts.Add((user.Lat, user.Lon));
            return Fit(pts, w, h, Math.Min(110, w * 0.2), 52, 3.4);
        }
        var all = RegionCatalog.All.Select(region => (region.Latitude, region.Longitude)).ToList();
        if (_user is { } u) all.Add((u.Lat, u.Lon));
        return Fit(all, w, h, 28, 28, 7);
    }

    private void Retarget()
    {
        if (!_animate) _cam = Target();
        Redraw();
        EnsureRendering();
    }

    // ------------------------------------------------------------------ loop

    private void EnsureRendering()
    {
        if (!_animate || _rendering) return;
        _rendering = true;
        _lastFrame = 0;
        CompositionTarget.Rendering += OnRendering;
    }

    private void StopRendering()
    {
        if (!_rendering) return;
        _rendering = false;
        CompositionTarget.Rendering -= OnRendering;
    }

    private void OnRendering(object? sender, object e)
    {
        var now = Now();
        var dt = _lastFrame == 0 ? 0.016 : Math.Min((now - _lastFrame) / 1000.0, 0.05);
        _lastFrame = now;
        var target = Target();
        var k = 1 - Math.Exp(-dt * 3.2);
        _cam = new Cam(_cam.Lon + (target.Lon - _cam.Lon) * k, _cam.Lat + (target.Lat - _cam.Lat) * k, _cam.Zoom + (target.Zoom - _cam.Zoom) * k);

        for (var i = _packets.Count - 1; i >= 0; i--)
        {
            var packet = _packets[i];
            if (now < packet.Start || now - packet.Start < packet.Dur) continue;
            if (packet.Sweep) _packets.RemoveAt(i);
            else if (packet.Out) { packet.Out = false; packet.Start = now; packet.Dur = ReturnMs(packet.Rtt); }
            else _packets.RemoveAt(i);
        }

        Redraw();
        var settled = Math.Abs(target.Lon - _cam.Lon) < 0.01 && Math.Abs(target.Lat - _cam.Lat) < 0.01 && Math.Abs(target.Zoom - _cam.Zoom) < 0.002;
        if (settled && _packets.Count == 0) StopRendering();
    }

    private static double ReturnMs(double rtt) => Math.Min(Math.Max(rtt * 8, 300), 700);
    private static double Ease(double t) { var c = Math.Clamp(t, 0, 1); return c < 0.5 ? 4 * c * c * c : 1 - Math.Pow(-2 * c + 2, 3) / 2; }

    // ------------------------------------------------------------------ desenho

    private static Arc ArcOf((double X, double Y) p0, (double X, double Y) p1, double maxH)
    {
        var dx = p1.X - p0.X;
        var dy = p1.Y - p0.Y;
        var d = Math.Max(Math.Sqrt(dx * dx + dy * dy), 1);
        var hh = Math.Min(Math.Max(d * 0.3, 24), maxH);
        double nx = -dy / d, ny = dx / d;
        if (ny > 0) { nx = -nx; ny = -ny; }
        return new Arc(p0.X, p0.Y, p1.X, p1.Y, (p0.X + p1.X) / 2 + nx * hh, (p0.Y + p1.Y) / 2 + ny * hh);
    }

    private static (double X, double Y) Bezier(Arc a, double t)
    {
        var c = Math.Clamp(t, 0, 1);
        var u = 1 - c;
        return (u * u * a.X0 + 2 * u * c * a.Cx + c * c * a.X1, u * u * a.Y0 + 2 * u * c * a.Cy + c * c * a.Y1);
    }

    private static PathGeometry ArcGeometry(Arc a)
    {
        var figure = new PathFigure { StartPoint = new Point(a.X0, a.Y0) };
        figure.Segments.Add(new QuadraticBezierSegment { Point1 = new Point(a.Cx, a.Cy), Point2 = new Point(a.X1, a.Y1) });
        var geometry = new PathGeometry();
        geometry.Figures.Add(figure);
        return geometry;
    }

    private static void Place(UIElement element, double x, double y)
    {
        Canvas.SetLeft(element, x);
        Canvas.SetTop(element, y);
    }

    private void Redraw()
    {
        var w = ActualWidth;
        var h = ActualHeight;
        if (w <= 0 || h <= 0) return;
        var now = Now();
        var cam = _cam;

        // Terra: uma geometria em graus, posicionada pela câmera.
        var k = w / 360.0 * cam.Zoom;
        _landTransform.Matrix = new Matrix(k, 0, 0, k, w / 2 - cam.Lon * k, h / 2 + cam.Lat * k);

        (double X, double Y)? up = _user is { } user ? Project(user.Lat, user.Lon, cam) : null;
        var sel = _selId is not null ? RegionCatalog.Find(_selId) : null;
        (double X, double Y)? sp = sel is not null ? Project(sel.Latitude, sel.Longitude, cam) : null;

        string? leader = null;
        if (_selId is null)
        {
            var best = double.PositiveInfinity;
            foreach (var (id, sample) in _regions)
                if (sample.Ms is { } ms && ms < best) { best = ms; leader = id; }
        }

        foreach (var region in RegionCatalog.All)
        {
            var dot = _regionDots[region.Id];
            if (region.Id == _selId) { dot.Visibility = Visibility.Collapsed; continue; }
            dot.Visibility = Visibility.Visible;
            var p = Project(region.Latitude, region.Longitude, cam);
            _regions.TryGetValue(region.Id, out var sample);
            double size;
            if (region.Id == leader) { size = 8.4; dot.Fill = new SolidColorBrush(PurpleLight); dot.Stroke = null; }
            else if (sample is { Ok: true }) { size = 5.6; dot.Fill = new SolidColorBrush(RegionColor); dot.Stroke = null; }
            else { size = 5.6; dot.Fill = null; dot.Stroke = new SolidColorBrush(Muted); dot.StrokeThickness = 1.2; }
            dot.Width = size;
            dot.Height = size;
            Place(dot, p.X - size / 2, p.Y - size / 2);
        }

        // Arco principal usuário -> região escolhida.
        Arc? routeArc = null;
        if (up is { } u && sp is { } s)
        {
            routeArc = ArcOf(u, s, h * 0.38);
            _routeArc.Data = ArcGeometry(routeArc.Value);
            _routeArc.Visibility = Visibility.Visible;
        }
        else
        {
            _routeArc.Visibility = Visibility.Collapsed;
        }

        // Pacotes.
        var packetIndex = 0;
        foreach (var arc in _sweepArcs.Values) arc.Visibility = Visibility.Collapsed;
        foreach (var packet in _packets)
        {
            if (now < packet.Start || up is not { } origin) continue;
            var t = Ease((now - packet.Start) / packet.Dur);
            Arc arc;
            double radius;
            if (packet.Sweep)
            {
                if (sp is not null || RegionCatalog.Find(packet.Id) is not { } region) continue;
                arc = ArcOf(origin, Project(region.Latitude, region.Longitude, cam), h * 0.38);
                var path = _sweepArcs[packet.Id];
                path.Data = ArcGeometry(arc);
                path.Visibility = Visibility.Visible;
                radius = 2.6;
            }
            else
            {
                if (routeArc is not { } main) continue;
                arc = main;
                radius = 3.2;
            }
            var position = Bezier(arc, packet.Out ? t : 1 - t);
            var dot = PacketDot(packetIndex++);
            dot.Width = dot.Height = radius * 2;
            dot.Fill = new SolidColorBrush(packet.Out ? PurpleLight : TextColor);
            dot.Visibility = Visibility.Visible;
            Place(dot, position.X - radius, position.Y - radius);
        }
        for (var i = packetIndex; i < _packetDots.Count; i++) _packetDots[i].Visibility = Visibility.Collapsed;

        if (sp is { } selectedPoint)
        {
            _selDot.Visibility = Visibility.Visible;
            Place(_selDot, selectedPoint.X - 5.6, selectedPoint.Y - 5.6);
        }
        else
        {
            _selDot.Visibility = Visibility.Collapsed;
        }
        if (up is { } userPoint)
        {
            _userDot.Visibility = Visibility.Visible;
            Place(_userDot, userPoint.X - 5, userPoint.Y - 5);
        }
        else
        {
            _userDot.Visibility = Visibility.Collapsed;
        }

        // Rótulos (sem sobreposição).
        var placed = new List<Rect>();
        _userLabel.Visibility = Visibility.Collapsed;
        _destLabel.Visibility = Visibility.Collapsed;
        if (up is { } uPoint && _user is { } userInfo)
        {
            var text = string.IsNullOrWhiteSpace(userInfo.City) ? Localization.Strings.Tr("Você") : Localization.Strings.Tr("Você") + " · " + userInfo.City;
            placed.Add(Label(_userLabel, uPoint, true, new[] { (text, false) }, placed));
        }
        var labelId = _selId ?? leader;
        if (labelId is not null && RegionCatalog.Find(labelId) is { } labelRegion)
        {
            var anchor = sp ?? Project(labelRegion.Latitude, labelRegion.Longitude, cam);
            double? ms = _selId is not null ? _selMs : (_regions.TryGetValue(labelId, out var sample) ? sample.Ms : null);
            var runs = new List<(string, bool)> { (labelRegion.Name, false) };
            if (ms is { } value) runs.Add((" · " + Math.Round(value).ToString(CultureInfo.InvariantCulture) + " ms", true));
            placed.Add(Label(_destLabel, anchor, false, runs, placed));
        }
    }

    private Ellipse PacketDot(int index)
    {
        while (_packetDots.Count <= index)
        {
            var dot = new Ellipse { IsHitTestVisible = false };
            _packetDots.Add(dot);
            _canvas.Children.Add(dot);
        }
        return _packetDots[index];
    }

    private static void InitLabel(Border label)
    {
        label.Background = new SolidColorBrush(Color.FromArgb(0xE6, 0x0B, 0x0D, 0x10));
        label.BorderBrush = new SolidColorBrush(Color.FromArgb(0x29, 0xF4, 0xF5, 0xF7));
        label.BorderThickness = new Thickness(1);
        label.CornerRadius = new CornerRadius(6);
        label.Padding = new Thickness(8, 0, 8, 0);
        label.Height = 24;
        label.IsHitTestVisible = false;
        label.Visibility = Visibility.Collapsed;
        label.Child = new StackPanel { Orientation = Orientation.Horizontal, VerticalAlignment = VerticalAlignment.Center };
    }

    private Rect Label(Border label, (double X, double Y) anchor, bool above, IEnumerable<(string Text, bool Metric)> runs, List<Rect> others)
    {
        var panel = (StackPanel)label.Child;
        panel.Children.Clear();
        foreach (var (text, metric) in runs)
        {
            panel.Children.Add(new TextBlock
            {
                Text = text,
                FontSize = 12,
                FontWeight = metric ? Microsoft.UI.Text.FontWeights.Normal : Microsoft.UI.Text.FontWeights.SemiBold,
                FontFamily = (FontFamily)Application.Current.Resources[metric ? "MetricFont" : "BodyFont"],
                Foreground = new SolidColorBrush(metric ? PurpleLight : TextColor),
                VerticalAlignment = VerticalAlignment.Center,
            });
        }
        label.Measure(new Size(double.PositiveInfinity, 24));
        var size = label.DesiredSize;
        double bw = size.Width, bh = 24;
        var box = new Rect();

        Rect PlaceAt(bool top)
        {
            var x = Math.Min(Math.Max(anchor.X - bw / 2, 4), Math.Max(ActualWidth - bw - 4, 4));
            var y = top ? anchor.Y - 12 - bh : anchor.Y + 12;
            y = Math.Min(Math.Max(y, 4), Math.Max(ActualHeight - bh - 4, 4));
            return new Rect(x, y, bw, bh);
        }

        static bool Overlaps(Rect a, Rect b) => a.X < b.X + b.Width + 4 && a.X + a.Width + 4 > b.X && a.Y < b.Y + b.Height + 4 && a.Y + a.Height + 4 > b.Y;

        box = PlaceAt(above);
        if (others.Any(o => Overlaps(box, o))) box = PlaceAt(!above);
        if (others.FirstOrDefault(o => Overlaps(box, o)) is var hit && hit != default)
        {
            var x = hit.X + hit.Width + 6 + bw <= ActualWidth - 4 ? hit.X + hit.Width + 6 : Math.Max(hit.X - bw - 6, 4);
            box = new Rect(x, box.Y, bw, bh);
        }
        label.Visibility = Visibility.Visible;
        Place(label, box.X, box.Y);
        return box;
    }

    // ------------------------------------------------------------------ terra

    private static string? BuildLandPathData()
    {
        try
        {
            var engine = RouteMapEngine.Instance;
            var r = engine.Step * 0.34;
            var builder = new StringBuilder(engine.LandLons.Length * 56);
            var inv = CultureInfo.InvariantCulture;
            for (var i = 0; i < engine.LandLons.Length; i++)
            {
                var x = engine.LandLons[i];
                var y = -engine.LandLats[i];
                builder.Append('M').Append((x - r).ToString("0.###", inv)).Append(',').Append(y.ToString("0.###", inv))
                    .Append('a').Append(r.ToString("0.###", inv)).Append(',').Append(r.ToString("0.###", inv)).Append(" 0 1,0 ").Append((2 * r).ToString("0.###", inv)).Append(",0")
                    .Append('a').Append(r.ToString("0.###", inv)).Append(',').Append(r.ToString("0.###", inv)).Append(" 0 1,0 ").Append((-2 * r).ToString("0.###", inv)).Append(",0");
            }
            return builder.ToString();
        }
        catch
        {
            return null;
        }
    }
}
