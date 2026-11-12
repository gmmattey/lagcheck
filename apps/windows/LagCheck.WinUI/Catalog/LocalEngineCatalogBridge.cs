using LagCheck.WinUI.Diagnostic;

namespace LagCheck.WinUI.Catalog;

/// <summary>Catalog adapter over the already shared local Kotlin host.</summary>
public sealed class LocalEngineCatalogBridge : ICatalogBridge
{
    private readonly DiagnosticEngineClient _engine;
    public LocalEngineCatalogBridge(DiagnosticEngineClient engine) => _engine = engine ?? throw new ArgumentNullException(nameof(engine));

    public async Task<IReadOnlyList<CatalogGame>> GetSnapshotAsync(CancellationToken cancellationToken = default) =>
        (await _engine.GetCatalogSnapshotAsync(cancellationToken).ConfigureAwait(false))
            .Select(game => new CatalogGame(game.Id, game.Name, game.ArtworkResource, game.RegionId, game.RegionLabel))
            .ToArray();
}
