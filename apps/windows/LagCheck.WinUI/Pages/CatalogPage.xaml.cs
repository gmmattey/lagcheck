using LagCheck.WinUI.Catalog;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
namespace LagCheck.WinUI.Pages;
public sealed partial class CatalogPage : Page
{
    private readonly ICatalogBridge _bridge;
    private IReadOnlyList<CatalogGame> _games = [];
    public CatalogPage() : this(CatalogPageServices.Bridge) { }
    internal CatalogPage(ICatalogBridge bridge) { _bridge = bridge; InitializeComponent(); Loaded += CatalogPage_Loaded; }
    private async void CatalogPage_Loaded(object sender, RoutedEventArgs e)
    {
        Loaded -= CatalogPage_Loaded;
        try { _games = await _bridge.GetSnapshotAsync(); SearchBox.IsEnabled = true; EmptyTitle.Text = "Nenhum jogo no catálogo"; EmptyDetail.Text = "O catálogo local não retornou jogos compatíveis."; ApplyFilter(); }
        catch { EmptyTitle.Text = "Catálogo indisponível"; EmptyDetail.Text = "O catálogo local ainda não respondeu. Esta tela não inventa jogos, endpoints ou compatibilidade."; }
    }
    private void SearchBox_TextChanged(object sender, TextChangedEventArgs e) => ApplyFilter();
    private void Test_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: CatalogGame game }) ShellNavigation.OpenDiagnostic(game.Id, game.Name);
    }
    private void ApplyFilter()
    {
        var query = SearchBox.Text.Trim();
        var filtered = _games.Where(game => string.IsNullOrWhiteSpace(query) || game.Name.Contains(query, StringComparison.OrdinalIgnoreCase) || (game.RegionLabel?.Contains(query, StringComparison.OrdinalIgnoreCase) ?? false)).ToList();
        CatalogList.ItemsSource = filtered;
        CatalogList.Visibility = filtered.Count > 0 ? Visibility.Visible : Visibility.Collapsed;
        EmptyState.Visibility = filtered.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
    }
}
