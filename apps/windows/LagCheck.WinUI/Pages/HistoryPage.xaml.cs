using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Globalization;
using System.Linq;
using LagCheck.WinUI.Controls;
using LagCheck.WinUI.Diagnostic;
using LagCheck.WinUI.History;
using LagCheck.WinUI.Localization;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;

namespace LagCheck.WinUI.Pages;

/// <summary>Linha já formatada do histórico: jogo medido, região, resultado e as três medições.</summary>
public sealed record HistoryRow(string Game, string Verdict, Microsoft.UI.Xaml.Media.Brush ToneBrush, string Region, string Ping, string Jitter, string Loss, string Time);

public sealed partial class HistoryPage : Page
{
    private readonly SessionHistoryStore _history = SessionHistoryServices.Store;
    private Dictionary<string, string> _gameNames = new(StringComparer.OrdinalIgnoreCase);

    public HistoryPage()
    {
        InitializeComponent();
        LocalizeUI();
        _history.Entries.CollectionChanged += Entries_CollectionChanged;
        LocalizationService.Instance.LanguageChanged += OnLanguageChanged;
        UpdateVisibleEntries();
        Loaded += async (_, _) => await LoadGameNamesAsync();
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

    private static readonly Brush RowHoverBrush = new SolidColorBrush(Windows.UI.Color.FromArgb(0x0D, 0xFF, 0xFF, 0xFF));
    private static readonly Brush RowNormalBrush = new SolidColorBrush(Microsoft.UI.Colors.Transparent);

    private void LocalizeUI()
    {
        TitleText.Text = Strings.Tr("HISTÓRICO").ToUpper(CultureInfo.CurrentCulture);
        SearchBox.PlaceholderText = Strings.Tr("Buscar por jogo, região ou resultado");
        HGame.Text = Strings.Tr("JOGO");
        HRegion.Text = Strings.Tr("REGIÃO");
        HResult.Text = Strings.Tr("RESULTADO");
        HLoss.Text = Strings.Tr("PERDA");
        HTime.Text = Strings.Tr("HORA");
        EmptyTitle.Text = Strings.Tr("Sem testes ainda");
        EmptyDescription.Text = Strings.Tr("Teste sua conexão para ver aqui o histórico das medições.");
        StartCheckButton.Content = Strings.Tr("Testar conexão");
        NoResults.Text = Strings.Tr("Nenhuma medição corresponde à busca.");
    }

    private void StartCheck_Click(object sender, RoutedEventArgs e) => ShellNavigation.Navigate(NavigationRoute.GeneralCheck);

    private void HistoryList_ElementPrepared(ItemsRepeater sender, ItemsRepeaterElementPreparedEventArgs args)
    {
        if (args.Element is Grid rowGrid)
        {
            rowGrid.Background = RowNormalBrush;
            rowGrid.BackgroundTransition = Motion.Reduced ? null : new BrushTransition { Duration = TimeSpan.FromMilliseconds(150) };
            rowGrid.PointerEntered -= Row_PointerEntered;
            rowGrid.PointerEntered += Row_PointerEntered;
            rowGrid.PointerExited -= Row_PointerExited;
            rowGrid.PointerExited += Row_PointerExited;
        }
    }

    private void HistoryList_ElementClearing(ItemsRepeater sender, ItemsRepeaterElementClearingEventArgs args)
    {
        if (args.Element is Grid rowGrid)
        {
            rowGrid.PointerEntered -= Row_PointerEntered;
            rowGrid.PointerExited -= Row_PointerExited;
            rowGrid.Background = RowNormalBrush;
        }
    }

    private void Row_PointerEntered(object sender, PointerRoutedEventArgs e)
    {
        if (sender is Grid rowGrid)
        {
            rowGrid.BackgroundTransition = Motion.Reduced ? null : new BrushTransition { Duration = TimeSpan.FromMilliseconds(150) };
            rowGrid.Background = RowHoverBrush;
        }
    }

    private void Row_PointerExited(object sender, PointerRoutedEventArgs e)
    {
        if (sender is Grid rowGrid)
        {
            rowGrid.BackgroundTransition = Motion.Reduced ? null : new BrushTransition { Duration = TimeSpan.FromMilliseconds(150) };
            rowGrid.Background = RowNormalBrush;
        }
    }

    /// <summary>Nomes dos jogos do catálogo do motor, para dar contexto às medições (sem inventar nada).</summary>
    private async System.Threading.Tasks.Task LoadGameNamesAsync()
    {
        try
        {
            var catalog = await WinUiEngineComposition.Client.GetCatalogSnapshotAsync();
            _gameNames = catalog.ToDictionary(game => game.Id, game => game.Name, StringComparer.OrdinalIgnoreCase);
            UpdateVisibleEntries();
        }
        catch
        {
            // Sem catálogo, as linhas continuam corretas, só sem o nome do jogo.
        }
    }

    private void Entries_CollectionChanged(object? sender, NotifyCollectionChangedEventArgs e) => DispatcherQueue.TryEnqueue(UpdateVisibleEntries);
    private void SearchBox_TextChanged(object sender, TextChangedEventArgs e) => UpdateVisibleEntries();

    private HistoryRow ToRow(SessionHistoryEntry entry)
    {
        var tone = Verdicts.ToneOf(entry.Verdict);
        // Nome do jogo testado: o título guardado na medição; senão o catálogo do motor. Nunca a categoria/perfil.
        string? game = !string.IsNullOrWhiteSpace(entry.GameTitle) ? entry.GameTitle
            : entry.GameId is { Length: > 0 } id && _gameNames.TryGetValue(id, out var name) ? name : null;
        var verdict = Verdicts.Headline(tone, game is not null);
        var region = RegionCatalog.Label(entry.RegionId);
        if (string.IsNullOrEmpty(region)) region = Strings.Tr("REGIÃO NÃO INFORMADA");
        var time = !entry.HasCapturedAt
            ? string.Empty
            : entry.CapturedAt.ToLocalTime().Date == DateTime.Today ? entry.TimeLabel : entry.CapturedAt.ToLocalTime().ToString("d MMM");
        var brush = new Microsoft.UI.Xaml.Media.SolidColorBrush(Verdicts.ColorOf(tone));
        return new HistoryRow(game ?? Strings.Tr("Conexão geral"), verdict, brush, region, entry.PingLabel, entry.JitterLabel, entry.LossLabel, time);
    }

    private void UpdateVisibleEntries()
    {
        var query = SearchBox?.Text?.Trim() ?? string.Empty;
        var rows = _history.Entries.Select(ToRow)
            .Where(row => string.IsNullOrEmpty(query) || row.Region.Contains(query, StringComparison.OrdinalIgnoreCase) || row.Game.Contains(query, StringComparison.OrdinalIgnoreCase) || row.Verdict.Contains(query, StringComparison.OrdinalIgnoreCase))
            .ToList();
        HistoryList.ItemsSource = rows;
        HistoryScroll.Visibility = rows.Count > 0 ? Visibility.Visible : Visibility.Collapsed;
        HeaderRow.Visibility = HistoryScroll.Visibility;
        EmptyState.Visibility = _history.Entries.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
        NoResults.Visibility = _history.Entries.Count > 0 && rows.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
    }
}
