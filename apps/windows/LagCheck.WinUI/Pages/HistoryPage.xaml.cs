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
    private int _historyStateTicket;
    private UIElement? _activeStateView;
    private bool _isPageLoaded;
    private string? _selectedGameId;
    private string? _selectedGameTitle;
    private int _selectedWindowDays = 14;
    private string? _selectedNetworkFilter;
    private string? _lastChipsSignature;

    public HistoryPage()
    {
        InitializeComponent();
        LocalizeUI();
        _history.Entries.CollectionChanged += Entries_CollectionChanged;
        LocalizationService.Instance.LanguageChanged += OnLanguageChanged;
        UpdateVisibleEntries();
        Loaded += async (_, _) =>
        {
            _isPageLoaded = true;
            Choreo.FadeSlideIn(TitleText, dy: 14, delayMs: 0);
            Choreo.FadeSlideIn(ScopeChipsScroll, dy: 12, delayMs: 20);
            if (StabilityCard.Visibility == Visibility.Visible)
            {
                Choreo.FadeSlideIn(StabilityCard, dy: 14, delayMs: 35);
            }
            Choreo.FadeSlideIn(SearchBox, dy: 14, delayMs: 50);
            if (_activeStateView is not null)
            {
                Choreo.FadeSlideIn(_activeStateView, dy: 14, delayMs: 80);
            }
            await LoadGameNamesAsync();
        };
        Unloaded += (_, _) =>
        {
            _history.Entries.CollectionChanged -= Entries_CollectionChanged;
            LocalizationService.Instance.LanguageChanged -= OnLanguageChanged;
        };
    }

    protected override void OnNavigatedTo(Microsoft.UI.Xaml.Navigation.NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        var filter = e.Parameter as HistoryNavigationFilter;
        var key = filter is not null ? SessionHistoryStore.EffectiveGameKey(filter.GameId, filter.GameTitle) : null;
        if (!string.IsNullOrWhiteSpace(key))
        {
            _selectedGameId = key;
            _selectedGameTitle = !string.IsNullOrWhiteSpace(filter?.GameTitle) ? filter!.GameTitle : key;
        }
        else
        {
            _selectedGameId = null;
            _selectedGameTitle = null;
        }
        _lastChipsSignature = null;
        UpdateVisibleEntries();
    }

    private void OnLanguageChanged() => DispatcherQueue.TryEnqueue(() =>
    {
        _lastChipsSignature = null;
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
            rowGrid.PointerEntered -= Row_PointerEntered;
            rowGrid.PointerEntered += Row_PointerEntered;
            rowGrid.PointerExited -= Row_PointerExited;
            rowGrid.PointerExited += Row_PointerExited;

            var delay = Math.Min(args.Index, 8) * 35;
            Choreo.FadeSlideIn(rowGrid, dy: 8, delayMs: delay);
        }
    }

    private void HistoryList_ElementClearing(ItemsRepeater sender, ItemsRepeaterElementClearingEventArgs args)
    {
        if (args.Element is Grid rowGrid)
        {
            rowGrid.PointerEntered -= Row_PointerEntered;
            rowGrid.PointerExited -= Row_PointerExited;
            rowGrid.Background = RowNormalBrush;
            Choreo.Reset(rowGrid);
        }
    }

    private void Row_PointerEntered(object sender, PointerRoutedEventArgs e)
    {
        if (sender is Grid rowGrid)
        {
            rowGrid.Background = RowHoverBrush;
        }
    }

    private void Row_PointerExited(object sender, PointerRoutedEventArgs e)
    {
        if (sender is Grid rowGrid)
        {
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

    private string? ResolveGameName(string? gameId, string? recordedTitle)
    {
        if (!string.IsNullOrWhiteSpace(recordedTitle)) return recordedTitle;
        if (SessionHistoryStore.IsGeneralId(gameId)) return null;
        if (gameId is { Length: > 0 } && _gameNames.TryGetValue(gameId, out var catalogName) && !string.IsNullOrWhiteSpace(catalogName))
            return catalogName;
        return null;
    }

    private void RebuildScopeChips()
    {
        var games = new List<(string Id, string Title)>();
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var entry in _history.Entries)
        {
            var id = entry.EffectiveGameKey;
            if (string.IsNullOrWhiteSpace(id)) continue;
            if (!seen.Add(id)) continue;
            var label = ResolveGameName(entry.GameId, entry.GameTitle) ?? id;
            games.Add((id, label));
        }

        if (!string.IsNullOrWhiteSpace(_selectedGameId) && seen.Add(_selectedGameId))
        {
            var label = ResolveGameName(_selectedGameId, _selectedGameTitle) ?? _selectedGameId;
            games.Add((_selectedGameId, label));
        }

        var networks = NetworkStabilitySummary.Build(
            _history.Entries,
            _selectedGameId,
            maxPoints: 30,
            windowDays: _selectedWindowDays).Networks;

        if (_selectedNetworkFilter is not null && !networks.Contains(_selectedNetworkFilter, StringComparer.Ordinal))
        {
            _selectedNetworkFilter = null;
        }

        var sig = string.Join("|",
            LocalizationService.Instance.SelectedLanguage,
            _selectedGameId ?? "",
            _selectedWindowDays,
            _selectedNetworkFilter ?? "",
            _history.Entries.Count > 0,
            string.Join(",", networks),
            string.Join(";", games.Select(g => $"{g.Id}={g.Title}")));
        if (string.Equals(sig, _lastChipsSignature, StringComparison.Ordinal)) return;
        _lastChipsSignature = sig;

        ScopeChips.Children.Clear();
        ScopeChips.Children.Add(BuildFilterChip(Strings.Tr("Visão geral"), _selectedGameId is null, () =>
        {
            _selectedGameId = null;
            _selectedGameTitle = null;
            _selectedNetworkFilter = null;
            UpdateVisibleEntries();
        }));
        foreach (var (id, title) in games)
        {
            var selected = string.Equals(_selectedGameId, id, StringComparison.OrdinalIgnoreCase);
            ScopeChips.Children.Add(BuildFilterChip(title, selected, () =>
            {
                _selectedGameId = id;
                _selectedGameTitle = title;
                _selectedNetworkFilter = null;
                UpdateVisibleEntries();
            }));
        }
        ScopeChipsScroll.Visibility = ScopeChips.Children.Count > 1 ? Visibility.Visible : Visibility.Collapsed;

        WindowChips.Children.Clear();
        foreach (var days in new[] { 7, 14, 30 })
        {
            var label = Strings.Tr($"{days} dias");
            WindowChips.Children.Add(BuildFilterChip(label, _selectedWindowDays == days, () =>
            {
                _selectedWindowDays = days;
                UpdateVisibleEntries();
            }));
        }
        WindowChipsScroll.Visibility = _history.Entries.Count > 0 ? Visibility.Visible : Visibility.Collapsed;

        NetworkChips.Children.Clear();
        if (networks.Count > 1)
        {
            NetworkChips.Children.Add(BuildFilterChip(Strings.Tr("Todas as redes"), _selectedNetworkFilter is null, () =>
            {
                _selectedNetworkFilter = null;
                UpdateVisibleEntries();
            }));
            foreach (var net in networks)
            {
                var label = NetworkStabilitySummary.LocalizedNetworkLabel(net);
                NetworkChips.Children.Add(BuildFilterChip(label, string.Equals(_selectedNetworkFilter, net, StringComparison.Ordinal), () =>
                {
                    _selectedNetworkFilter = net;
                    UpdateVisibleEntries();
                }));
            }
            NetworkChipsScroll.Visibility = Visibility.Visible;
        }
        else
        {
            NetworkChipsScroll.Visibility = Visibility.Collapsed;
        }
    }

    private Button BuildFilterChip(string label, bool selected, Action onClick)
    {
        var btn = new Button
        {
            Content = label,
            Style = (Style)Application.Current.Resources["PillChipButtonStyle"],
            FontSize = 13,
            Padding = new Thickness(14, 7, 14, 7),
            MinHeight = 36,
            CornerRadius = new CornerRadius(8),
            BorderThickness = new Thickness(0),
            Background = (Brush)Application.Current.Resources[selected ? "PanelBrush" : "SurfaceBrush"],
            Foreground = (Brush)Application.Current.Resources[selected ? "TextPrimaryBrush" : "TextSecondaryBrush"],
        };
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(btn, label);
        btn.Click += (_, _) => onClick();
        return btn;
    }

    private void UpdateStabilityCard()
    {
        var summary = NetworkStabilitySummary.Build(
            _history.Entries,
            _selectedGameId,
            maxPoints: 30,
            windowDays: _selectedWindowDays,
            networkFilter: _selectedNetworkFilter);
        if (!summary.HasData && summary.InconclusiveCount == 0)
        {
            StabilityCard.Visibility = Visibility.Collapsed;
            return;
        }

        StabilityCard.Visibility = Visibility.Visible;
        var culture = LocalizationService.Instance.EffectiveCulture;
        var toneColor = Verdicts.ColorOf(summary.StabilityTone);
        StabilityDot.Fill = new SolidColorBrush(toneColor);

        var title = Strings.Tr(string.IsNullOrWhiteSpace(_selectedGameId) ? "ESTABILIDADE DA REDE" : "ESTABILIDADE NO JOGO");
        if (!string.IsNullOrWhiteSpace(_selectedGameId))
        {
            var resolvedGame = ResolveGameName(_selectedGameId, _selectedGameTitle) ?? _selectedGameId;
            title = $"{title} · {resolvedGame.ToUpper(CultureInfo.CurrentCulture)}";
        }
        StabilityTitle.Text = title;

        if (!summary.HasSummary)
        {
            StabilityHeadline.Text = Strings.Tr("Poucas medições ainda");
            StabilityPercent.Visibility = Visibility.Collapsed;
            StabilitySubtitle.Text = summary.HasData
                ? string.Format(culture, "{0:0.#} ms", summary.AvgPing)
                : string.Empty;
            StabilityDivider.Visibility = Visibility.Collapsed;
            StabilityGaugesHost.Visibility = Visibility.Collapsed;
            StabilityGaugesHost.Children.Clear();
            StabilityChartHost.Visibility = summary.Points.Count > 0 ? Visibility.Visible : Visibility.Collapsed;
            StabilityChartHost.Child = summary.Points.Count > 0
                ? LagCheck.WinUI.Widgets.WidgetParts.StabilityChart(summary.Points, Windows.UI.Color.FromArgb(0xFF, 0x8A, 0x93, 0xA0))
                : null;

            var hints = new List<string> { Strings.Tr("Faça pelo menos 3 checks na mesma rede para ver a evolução.") };
            if (summary.InconclusiveCount > 0)
            {
                hints.Add(summary.InconclusiveCount == 1
                    ? Strings.Tr("1 inconclusivo")
                    : Strings.Format("{0} inconclusivos", summary.InconclusiveCount));
            }
            StabilityHint.Text = string.Join(" · ", hints);
            StabilityHint.Visibility = Visibility.Visible;
            return;
        }

        StabilityPercent.Visibility = Visibility.Visible;
        StabilityDivider.Visibility = Visibility.Visible;
        StabilityGaugesHost.Visibility = Visibility.Visible;
        StabilityChartHost.Visibility = Visibility.Visible;

        var headline = Strings.Tr(NetworkStabilitySummary.HeadlineKey(summary));
        StabilityHeadline.Text = headline;
        StabilityPercent.Text = Math.Abs(summary.MaxPing - summary.MinPing) < 0.5
            ? string.Format(culture, "{0:0.#} ms", summary.AvgPing)
            : string.Format(culture, "{0:0}–{1:0} ms", summary.MinPing, summary.MaxPing);
        StabilityPercent.Foreground = new SolidColorBrush(toneColor);
        StabilitySubtitle.Text = string.Format(
            culture,
            Strings.Tr(summary.TotalCount == 1 ? "{0}% estável em {1} medição" : "{0}% estável em {1} medições"),
            summary.StabilityPercentage,
            summary.TotalCount);

        var chartColor = summary.HasMixedContexts
            ? Windows.UI.Color.FromArgb(0xFF, 0x8A, 0x93, 0xA0)
            : toneColor;
        StabilityChartHost.Child = LagCheck.WinUI.Widgets.WidgetParts.StabilityChart(summary.Points, chartColor);

        var activeHints = new List<string>();
        if (!summary.CanDrawCurve)
        {
            activeHints.Add(Strings.Tr("Faça pelo menos 3 checks na mesma rede para ver a evolução."));
        }
        if (summary.InconclusiveCount > 0)
        {
            activeHints.Add(summary.InconclusiveCount == 1
                ? Strings.Tr("1 inconclusivo")
                : Strings.Format("{0} inconclusivos", summary.InconclusiveCount));
        }
        if (activeHints.Count > 0)
        {
            StabilityHint.Text = string.Join(" · ", activeHints);
            StabilityHint.Visibility = Visibility.Visible;
        }
        else
        {
            StabilityHint.Visibility = Visibility.Collapsed;
        }

        StabilityGaugesHost.Children.Clear();
        var pingTone = LagCheck.WinUI.Widgets.WidgetParts.MetricVerdictTone(summary.AvgPing, 45, 90);
        StabilityGaugesHost.Children.Add(LagCheck.WinUI.Widgets.WidgetParts.RingMetricGauge(
            Strings.Tr("PING MÉD"),
            string.Format(culture, "{0:0.#}", summary.AvgPing),
            "ms",
            Verdicts.ColorOf(pingTone),
            pingTone,
            LagCheck.WinUI.Widgets.WidgetParts.MetricRatio(summary.AvgPing, 45, 90, 160),
            ringSize: 54));

        StabilityGaugesHost.Children.Add(LagCheck.WinUI.Widgets.WidgetParts.VerticalDivider(10));

        var jitterTone = summary.AvgJitter is { } j ? LagCheck.WinUI.Widgets.WidgetParts.MetricVerdictTone(j, 12, 25) : VerdictTone.Unknown;
        StabilityGaugesHost.Children.Add(LagCheck.WinUI.Widgets.WidgetParts.RingMetricGauge(
            Strings.Tr("JITTER"),
            summary.AvgJitter is { } jv ? string.Format(culture, "{0:0.#}", jv) : "—",
            summary.AvgJitter.HasValue ? "ms" : null,
            Verdicts.ColorOf(jitterTone),
            jitterTone,
            summary.AvgJitter is { } jr ? LagCheck.WinUI.Widgets.WidgetParts.MetricRatio(jr, 12, 25, 40) : 0,
            ringSize: 54));

        StabilityGaugesHost.Children.Add(LagCheck.WinUI.Widgets.WidgetParts.VerticalDivider(10));

        var avgLoss = summary.AvgLoss ?? summary.MaxLoss;
        var lossTone = avgLoss is { } l ? LagCheck.WinUI.Widgets.WidgetParts.MetricVerdictTone(l, 1, 3) : VerdictTone.Unknown;
        StabilityGaugesHost.Children.Add(LagCheck.WinUI.Widgets.WidgetParts.RingMetricGauge(
            Strings.Tr("PERDA"),
            avgLoss is { } lv ? string.Format(culture, "{0:0.#}", lv) : "—",
            avgLoss.HasValue ? "%" : null,
            Verdicts.ColorOf(lossTone),
            lossTone,
            avgLoss is { } lr ? LagCheck.WinUI.Widgets.WidgetParts.MetricRatio(lr, 1, 3, 10) : 0,
            ringSize: 54));

        StabilityGaugesHost.Children.Add(LagCheck.WinUI.Widgets.WidgetParts.VerticalDivider(10));

        var loadTone = summary.AvgLoadDelta is { } ld ? LagCheck.WinUI.Widgets.WidgetParts.MetricVerdictTone(ld, 15, 40) : VerdictTone.Unknown;
        StabilityGaugesHost.Children.Add(LagCheck.WinUI.Widgets.WidgetParts.RingMetricGauge(
            Strings.Tr("SOB CARGA"),
            summary.AvgLoadDelta is { } ldv ? string.Format(culture, ldv >= 0 ? "+{0:0.#}" : "{0:0.#}", ldv) : "—",
            summary.AvgLoadDelta.HasValue ? "ms" : null,
            Verdicts.ColorOf(loadTone),
            loadTone,
            summary.AvgLoadDelta is { } ldr ? LagCheck.WinUI.Widgets.WidgetParts.MetricRatio(ldr, 15, 40, 80) : 0,
            ringSize: 54));

        if (summary.Latest?.PingMs is { } latestPing)
        {
            Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(
                StabilityCard,
                string.Format(culture, Strings.Tr("Estabilidade: {0} ({1}%), último ping {2:0.#} ms."), headline, summary.StabilityPercentage, latestPing));
        }
    }

    private HistoryRow ToRow(SessionHistoryEntry entry)
    {
        var tone = Verdicts.ToneOf(entry.Verdict);
        // Nome do jogo testado: o título guardado na medição; senão o catálogo do motor. Nunca a categoria/perfil.
        string? game = ResolveGameName(entry.GameId, entry.GameTitle);
        var verdict = Verdicts.Headline(tone, game is not null);
        var region = RegionCatalog.Label(entry.RegionId);
        if (string.IsNullOrEmpty(region)) region = Strings.Tr("REGIÃO NÃO INFORMADA");
        var time = !entry.HasCapturedAt
            ? string.Empty
            : entry.CapturedAt.ToLocalTime().Date == DateTime.Today ? entry.TimeLabel : entry.CapturedAt.ToLocalTime().ToString("d MMM", LocalizationService.Instance.EffectiveCulture);
        var brush = new Microsoft.UI.Xaml.Media.SolidColorBrush(Verdicts.ColorOf(tone));
        return new HistoryRow(game ?? Strings.Tr("Conexão geral"), verdict, brush, region, entry.PingLabel, entry.JitterLabel, entry.LossLabel, time);
    }

    private void UpdateVisibleEntries()
    {
        RebuildScopeChips();
        UpdateStabilityCard();

        var query = SearchBox?.Text?.Trim() ?? string.Empty;
        var filteredEntries = string.IsNullOrWhiteSpace(_selectedGameId)
            ? _history.Entries
            : _history.Entries.Where(entry => SessionHistoryStore.MatchesGame(entry, _selectedGameId, _selectedGameTitle));
        var rows = filteredEntries.Select(ToRow)
            .Where(row => string.IsNullOrEmpty(query) || row.Region.Contains(query, StringComparison.OrdinalIgnoreCase) || row.Game.Contains(query, StringComparison.OrdinalIgnoreCase) || row.Verdict.Contains(query, StringComparison.OrdinalIgnoreCase))
            .ToList();
        HistoryList.ItemsSource = rows;

        var hasRows = rows.Count > 0;
        UIElement targetView = hasRows ? TableCard
            : (_history.Entries.Count == 0 ? EmptyState : NoResults);

        HeaderRow.Visibility = Visibility.Visible;
        HistoryScroll.Visibility = Visibility.Visible;

        if (_activeStateView == targetView)
        {
            targetView.Visibility = Visibility.Visible;
            return;
        }

        var prevView = _activeStateView;
        _activeStateView = targetView;

        if (prevView is not null && _isPageLoaded)
        {
            var ticket = ++_historyStateTicket;
            Choreo.FadeOut(prevView, ms: Choreo.Exit, done: () =>
            {
                if (ticket != _historyStateTicket) return;
                prevView.Visibility = Visibility.Collapsed;
                targetView.Visibility = Visibility.Visible;
                Choreo.FadeSlideIn(targetView, dy: 10);
            });
        }
        else
        {
            TableCard.Visibility = (targetView == TableCard) ? Visibility.Visible : Visibility.Collapsed;
            EmptyState.Visibility = (targetView == EmptyState) ? Visibility.Visible : Visibility.Collapsed;
            NoResults.Visibility = (targetView == NoResults) ? Visibility.Visible : Visibility.Collapsed;
            if (_isPageLoaded)
            {
                Choreo.FadeSlideIn(targetView, dy: 10);
            }
        }
    }
}
