using System;
using System.Collections.Generic;
using System.Linq;

namespace LagCheck.WinUI.Diagnostic;

/// <summary>Regiões AWS conhecidas do mapa (mesmas coordenadas do protótipo v2) para nomear e posicionar a rota.</summary>
public static class RegionCatalog
{
    public sealed record Region(string Id, string Name, double Latitude, double Longitude);

    public static readonly IReadOnlyList<Region> All =
    [
        new("sa-east-1", "São Paulo", -23.55, -46.63),
        new("us-east-1", "Virgínia", 38.95, -77.45),
        new("us-east-2", "Ohio", 39.96, -83.0),
        new("us-west-1", "Califórnia", 37.34, -121.89),
        new("us-west-2", "Oregon", 45.52, -122.68),
        new("ca-central-1", "Canadá", 45.42, -75.7),
        new("eu-central-1", "Frankfurt", 50.11, 8.68),
        new("eu-west-1", "Irlanda", 53.35, -6.26),
        new("eu-west-2", "Londres", 51.51, -0.13),
        new("eu-west-3", "Paris", 48.86, 2.35),
        new("eu-north-1", "Estocolmo", 59.33, 18.07),
        new("eu-south-1", "Milão", 45.46, 9.19),
        new("ap-northeast-1", "Tóquio", 35.68, 139.69),
        new("ap-northeast-2", "Seul", 37.57, 126.98),
        new("ap-northeast-3", "Osaka", 34.69, 135.5),
        new("ap-southeast-1", "Singapura", 1.35, 103.82),
        new("ap-southeast-2", "Sydney", -33.87, 151.21),
        new("ap-south-1", "Mumbai", 19.08, 72.88),
        new("ap-east-1", "Hong Kong", 22.32, 114.17),
        new("me-south-1", "Bahrein", 26.22, 50.59),
        new("af-south-1", "Cidade do Cabo", -33.92, 18.42),
    ];

    public static Region? Find(string? id) =>
        string.IsNullOrWhiteSpace(id) ? null : All.FirstOrDefault(region => string.Equals(region.Id, id, StringComparison.OrdinalIgnoreCase));

    /// <summary>"São Paulo · sa-east-1" quando a região é conhecida; senão o próprio id.</summary>
    public static string Label(string? id)
    {
        if (string.IsNullOrWhiteSpace(id)) return string.Empty;
        return Find(id) is { } region ? $"{region.Name} · {region.Id}" : id;
    }
}
