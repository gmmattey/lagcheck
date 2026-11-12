namespace LagCheck.WinUI.Catalog;

public sealed record CatalogGame(string Id, string Name, string? ArtworkPath, string? RegionId, string? RegionLabel);

public interface ICatalogBridge
{
    Task<IReadOnlyList<CatalogGame>> GetSnapshotAsync(CancellationToken cancellationToken = default);
}

public sealed class UnavailableCatalogBridge : ICatalogBridge
{
    public static UnavailableCatalogBridge Instance { get; } = new();
    public Task<IReadOnlyList<CatalogGame>> GetSnapshotAsync(CancellationToken cancellationToken = default) =>
        Task.FromException<IReadOnlyList<CatalogGame>>(new InvalidOperationException("O catálogo ainda não está conectado ao host local."));
}

public static class CatalogPageServices
{
    private static ICatalogBridge _bridge = UnavailableCatalogBridge.Instance;
    public static ICatalogBridge Bridge => _bridge;
    public static void Configure(ICatalogBridge bridge) => _bridge = bridge ?? throw new ArgumentNullException(nameof(bridge));
}
