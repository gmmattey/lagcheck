using System;
using System.Collections.Specialized;
using System.Linq;
using LagCheck.WinUI.History;
using LagCheck.WinUI.Localization;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace LagCheck.WinUI.Pages;

public sealed partial class HistoryPage : Page
{
    private readonly SessionHistoryStore _history = SessionHistoryServices.Store;

    public HistoryPage()
    {
        InitializeComponent();
        LocalizeUI();
        _history.Entries.CollectionChanged += Entries_CollectionChanged;
        LocalizationService.Instance.LanguageChanged += OnLanguageChanged;
        UpdateVisibleEntries();
        Unloaded += (_, _) =>
        {
            _history.Entries.CollectionChanged -= Entries_CollectionChanged;
            LocalizationService.Instance.LanguageChanged -= OnLanguageChanged;
        };
    }

    private void OnLanguageChanged() => DispatcherQueue.TryEnqueue(() =>
    {
        LocalizeUI();
        UpdateVisibleEntries();
    });

    private void LocalizeUI()
    {
        EyebrowText.Text = Strings.Tr("REGISTRO LOCAL");
        TitleText.Text = Strings.Tr("Histórico de Sessões");
        SubtitleText.Text = Strings.Tr("Resultados concluídos ficam guardados apenas neste PC.");
        SearchBox.PlaceholderText = Strings.Tr("Buscar por região ou veredito");
        EmptyTitle.Text = Strings.Tr("Sem testes nesta sessão");
        EmptyDesc.Text = Strings.Tr("Quando uma medição terminar pelo motor compartilhado, o resultado real aparece aqui.");
        NoResults.Text = Strings.Tr("Nenhuma medição corresponde à busca.");
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
