using System.Collections.Specialized;
using LagCheck.WinUI.History;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
namespace LagCheck.WinUI.Pages;
public sealed partial class HistoryPage : Page
{
    private readonly SessionHistoryStore _history = SessionHistoryServices.Store;
    public HistoryPage()
    {
        InitializeComponent();
        _history.Entries.CollectionChanged += Entries_CollectionChanged;
        UpdateVisibleEntries();
        Unloaded += (_, _) => _history.Entries.CollectionChanged -= Entries_CollectionChanged;
    }
    private void Entries_CollectionChanged(object? sender, NotifyCollectionChangedEventArgs e) => DispatcherQueue.TryEnqueue(UpdateVisibleEntries);
    private void SearchBox_TextChanged(object sender, TextChangedEventArgs e) => UpdateVisibleEntries();
    private void UpdateVisibleEntries()
    {
        var query = SearchBox?.Text?.Trim() ?? string.Empty;
        var items = _history.Entries.Where(entry => string.IsNullOrEmpty(query) || entry.RegionLabel.Contains(query, StringComparison.OrdinalIgnoreCase) || entry.Verdict.Contains(query, StringComparison.OrdinalIgnoreCase)).ToList();
        HistoryList.ItemsSource = items;
        HistoryList.Visibility = items.Count > 0 ? Visibility.Visible : Visibility.Collapsed;
        EmptyState.Visibility = _history.Entries.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
        NoResults.Visibility = _history.Entries.Count > 0 && items.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
    }
}
