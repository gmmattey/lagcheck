using System;
using System.Collections.Generic;
using System.Linq;
using LagCheck.WinUI.Widgets.Items;

namespace LagCheck.WinUI.Widgets;

/// <summary>
/// Catálogo central de todos os widgets disponíveis para a tela Início do LagCheck no Windows.
/// Ordem padrão, consulta por Id e instâncias reutilizáveis sem estado mutável.
/// </summary>
public static class WidgetRegistry
{
    private static readonly IHomeWidget Latency = new LatencyWidget();
    private static readonly IHomeWidget Platforms = new PlatformsWidget();
    private static readonly IHomeWidget Quality = new RouteQualityWidget();
    private static readonly IHomeWidget Activity = new ActivityWidget();
    private static readonly IHomeWidget Gallery = new GalleryWidget();
    private static readonly IHomeWidget Favorites = new FavoritesWidget();

    public static IReadOnlyList<IHomeWidget> All { get; } =
    [
        Latency,
        Platforms,
        Quality,
        Activity,
        Gallery,
        Favorites,
    ];

    public static IReadOnlyList<string> DefaultOrder => All.Select(w => w.Id).ToList();

    public static IHomeWidget? Find(string id) =>
        All.FirstOrDefault(w => string.Equals(w.Id, id, StringComparison.Ordinal));
}
