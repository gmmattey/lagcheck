using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;

namespace LagCheck.WinUI.Diagnostic;

public sealed class RouteMapEngine
{
    private static RouteMapEngine? _instance;
    private static readonly object _lock = new();

    public float[] LandLons { get; }
    public float[] LandLats { get; }
    public double Step { get; }

    private RouteMapEngine(float[] lons, float[] lats, double step)
    {
        LandLons = lons;
        LandLats = lats;
        Step = step;
    }

    public static RouteMapEngine Instance
    {
        get
        {
            if (_instance is null)
            {
                lock (_lock)
                {
                    _instance ??= Load();
                }
            }
            return _instance;
        }
    }

    private static RouteMapEngine Load()
    {
        try
        {
            var baseDir = AppContext.BaseDirectory;
            var assetPath = Path.Combine(baseDir, "Assets", "map-grid.json");
            if (!File.Exists(assetPath))
            {
                assetPath = Path.Combine(baseDir, "..", "..", "..", "android", "desktop", "src", "main", "resources", "map", "map-grid.json");
            }
            if (File.Exists(assetPath))
            {
                var json = File.ReadAllText(assetPath);
                using var doc = JsonDocument.Parse(json);
                var root = doc.RootElement;
                var step = root.TryGetProperty("step", out var stepProp) ? stepProp.GetDouble() : 1.5;
                var latTop = root.TryGetProperty("latTop", out var latTopProp) ? latTopProp.GetDouble() : 84.0;
                var cols = root.TryGetProperty("cols", out var colsProp) ? colsProp.GetInt32() : 240;
                var rows = root.TryGetProperty("rows", out var rowsProp) ? rowsProp.GetInt32() : 95;

                if (root.TryGetProperty("grid", out var gridProp) && gridProp.ValueKind == JsonValueKind.Array)
                {
                    var lonsList = new List<float>(5500);
                    var latsList = new List<float>(5500);
                    int r = 0;
                    foreach (var rowEl in gridProp.EnumerateArray())
                    {
                        if (r >= rows) break;
                        var rowStr = rowEl.GetString();
                        if (rowStr is not null)
                        {
                            var lat = (float)(latTop - (r + 0.5) * step);
                            int limit = Math.Min(cols, rowStr.Length);
                            for (int c = 0; c < limit; c++)
                            {
                                if (rowStr[c] == '1')
                                {
                                    var lon = (float)(-180.0 + (c + 0.5) * step);
                                    lonsList.Add(lon);
                                    latsList.Add(lat);
                                }
                            }
                        }
                        r++;
                    }
                    return new RouteMapEngine(lonsList.ToArray(), latsList.ToArray(), step);
                }
            }
        }
        catch
        {
            // Silencioso se não conseguir carregar no ambiente de teste; usa fallback simplificado
        }

        // Fallback simplificado de continentes
        var fallbackLons = new List<float>();
        var fallbackLats = new List<float>();
        for (int lat = -50; lat <= 70; lat += 6)
        {
            for (int lon = -160; lon <= 160; lon += 8)
            {
                fallbackLons.Add(lon);
                fallbackLats.Add(lat);
            }
        }
        return new RouteMapEngine(fallbackLons.ToArray(), fallbackLats.ToArray(), 6.0);
    }

    public static (double X, double Y) Project(double lat, double lon, double camLat, double camLon, double zoom, double width, double height)
    {
        double k = (width / 360.0) * zoom;
        double x = width / 2.0 + (lon - camLon) * k;
        double y = height / 2.0 - (lat - camLat) * k;
        return (x, y);
    }

    public static (double X0, double Y0, double X1, double Y1, double Cx, double Cy) ComputeArc(double x0, double y0, double x1, double y1)
    {
        double dx = x1 - x0;
        double dy = y1 - y0;
        double d = Math.Max(Math.Sqrt(dx * dx + dy * dy), 1.0);
        double h = Math.Clamp(d * 0.32, 28.0, 140.0);
        double nx = -dy / d;
        double ny = dx / d;
        if (ny > 0)
        {
            nx = -nx;
            ny = -ny;
        }
        double cx = (x0 + x1) / 2.0 + nx * h;
        double cy = (y0 + y1) / 2.0 + ny * h;
        return (x0, y0, x1, y1, cx, cy);
    }

    public static (double X, double Y) BezierPoint(double x0, double y0, double cx, double cy, double x1, double y1, double t)
    {
        double inv = 1.0 - t;
        double px = inv * inv * x0 + 2.0 * inv * t * cx + t * t * x1;
        double py = inv * inv * y0 + 2.0 * inv * t * cy + t * t * y1;
        return (px, py);
    }
}
