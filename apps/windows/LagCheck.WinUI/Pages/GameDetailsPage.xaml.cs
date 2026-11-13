using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Navigation;
using Windows.UI;
using LagCheck.WinUI.Controls;
using LagCheck.WinUI.History;
using LagCheck.WinUI.Library;
using LagCheck.WinUI.Localization;

namespace LagCheck.WinUI.Pages;

public sealed partial class GameDetailsPage : Page
{
    private const int HeatWeeks = 26;

    private LibraryGame? _game;
    private readonly ILibraryBridge _bridge;

    public GameDetailsPage()
    {
        InitializeComponent();
        _bridge = LibraryPageServices.Bridge;
        GlowEffect.Attach(LaunchGlow, Color.FromArgb(0x8C, 0x7C, 0x3A, 0xED), 36);
        LocalizeUI();
        BuildHeatLabels();
        LocalizationService.Instance.LanguageChanged += OnLanguageChanged;
        SessionHistoryServices.Store.Entries.CollectionChanged += OnHistoryChanged;
        Unloaded += (_, _) =>
        {
            LocalizationService.Instance.LanguageChanged -= OnLanguageChanged;
            SessionHistoryServices.Store.Entries.CollectionChanged -= OnHistoryChanged;
        };
    }

    private void OnLanguageChanged() => DispatcherQueue.TryEnqueue(() => { LocalizeUI(); BindGame(); });
    private void OnHistoryChanged(object? sender, System.Collections.Specialized.NotifyCollectionChangedEventArgs e) => DispatcherQueue.TryEnqueue(BindHistory);

    private void LocalizeUI()
    {
        BackBtnText.Text = Strings.Tr("Voltar");
        ToolTipService.SetToolTip(BackBtn, Strings.Tr("Voltar à tela anterior"));
        LaunchBtn.Content = Strings.Tr("▶ JOGAR AGORA");
        CheckConnBtn.Content = Strings.Tr("Checar conexão");
        DaysPlayedEyebrow.Text = Strings.Tr("DIAS JOGADOS");
        LessLabel.Text = Strings.Tr("Menos");
        MoreLabel.Text = Strings.Tr("Mais");
        HistEyebrow.Text = Strings.Tr("HISTÓRICO DE MEDIÇÕES");
        HistStatusText.Text = Strings.Tr("Sem medições");
        MeasureNowBtn.Content = Strings.Tr("Medir agora");
        HeatmapNote.Text = Strings.Tr("Mostra a última atividade registrada pelo launcher neste PC.");
    }

    protected override void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        if (e.Parameter is LibraryGame game)
        {
            _game = game;
            BindGame();
            _ = ResolveArtworkAsync(game);
        }
    }

    private async System.Threading.Tasks.Task ResolveArtworkAsync(LibraryGame game)
    {
        var hasArt = Artwork.FirstExisting(game.HeroArtworkPath) is not null && Artwork.FirstExisting(game.CoverArtworkPath) is not null;
        // As informações de catálogo vêm na mesma chamada da arte: pede também quando só elas faltam.
        if (!game.IsInstalled || (hasArt && game.Info is not null)) return;
        try
        {
            var result = await _bridge.ResolveArtworkAsync(new[] { game.Id });
            if (result.Snapshot?.Games.FirstOrDefault(item => item.Id == game.Id) is { } updated)
            {
                _game = updated;
                BindGame();
            }
        }
        catch
        {
            // A arte é complementar: o banner neutro continua correto.
        }
    }

    // ------------------------------------------------------------------ apresentação

    private void BindGame()
    {
        if (_game is not { } game) return;

        GameTitleText.Text = game.Title.ToUpperInvariant();
        var logo = Glyphs.PlatformLogo(game.Platform);
        PlatformLogo.Visibility = logo is null ? Visibility.Collapsed : Visibility.Visible;
        PlatformMonitor.Visibility = logo is null ? Visibility.Visible : Visibility.Collapsed;
        PlatformText.Visibility = logo is null ? Visibility.Visible : Visibility.Collapsed;
        if (logo is not null) PlatformLogo.Data = logo;
        ToolTipService.SetToolTip(PlatformPill, game.PlatformLabel);

        BannerImage.Source = Artwork.Load(Artwork.FirstExisting(game.HeroArtworkPath, game.CoverArtworkPath));
        CheckConnBtn.Visibility = game.CanTestConnection ? Visibility.Visible : Visibility.Collapsed;
        MeasureNowBtn.Visibility = game.CanTestConnection ? Visibility.Visible : Visibility.Collapsed;
        LaunchBtn.IsEnabled = game.IsInstalled && game.IsLaunchable;
        FavIcon.IsFilled = game.IsFavorite;
        FavIcon.Foreground = game.IsFavorite ? (Brush)Application.Current.Resources["CoralBrush"] : (Brush)Application.Current.Resources["TextPrimaryBrush"];
        ToolTipService.SetToolTip(FavBtn, game.FavoriteActionLabel);

        var description = !string.IsNullOrWhiteSpace(game.Info?.Description) ? game.Info!.Description : game.Description;
        DescriptionText.Text = description ?? string.Empty;
        DescriptionText.Visibility = string.IsNullOrWhiteSpace(description) ? Visibility.Collapsed : Visibility.Visible;

        TagsPanel.Children.Clear();
        var chips = new List<string>(game.Tags.Count > 0 ? game.Tags : new List<string> { "PC", game.PlatformLabel });
        if (game.Info is { } info)
        {
            // Selo de rede primeiro: é o dado que mais importa para um diagnóstico de conexão.
            var modes = info.Modes.Select(GameInfo.ModeLabel).Where(label => label is not null).Cast<string>().ToList();
            var genres = info.Genres.Take(3);
            chips = modes.Concat(genres).Concat(chips.Where(tag => !modes.Contains(tag))).Distinct(StringComparer.CurrentCultureIgnoreCase).ToList();
        }
        foreach (var tag in chips)
        {
            TagsPanel.Children.Add(new Border
            {
                Height = 32,
                CornerRadius = new CornerRadius(16),
                Background = new SolidColorBrush(Color.FromArgb(255, 0x1C, 0x21, 0x2B)),
                Padding = new Thickness(16, 0, 16, 0),
                Child = new TextBlock { Text = tag, FontSize = 13, FontWeight = Microsoft.UI.Text.FontWeights.Medium, Foreground = (Brush)Application.Current.Resources["TextSecondaryBrush"], VerticalAlignment = VerticalAlignment.Center },
            });
        }
        BindFacts(game);
        BuildHeatmap(game);
        BindHistory();
    }

    private void BindFacts(LibraryGame game)
    {
        FactsPanel.Children.Clear();
        var rows = new List<(string Key, string Value)>
        {
            (Strings.Tr("PLATAFORMA"), game.PlatformLabel),
            (Strings.Tr("REDE E DIAGNÓSTICO"), game.DiagnosticLabel),
        };
        if (game.Info is { } info)
        {
            if (!string.IsNullOrWhiteSpace(info.Developer)) rows.Add((Strings.Tr("DESENVOLVEDORA"), info.Developer!));
            if (!string.IsNullOrWhiteSpace(info.Publisher) && !string.Equals(info.Publisher, info.Developer, StringComparison.OrdinalIgnoreCase)) rows.Add((Strings.Tr("PUBLICADORA"), info.Publisher!));
            if (FormatRelease(info.ReleaseDate) is { } release) rows.Add((Strings.Tr("LANÇAMENTO"), release));
        }
        if (game.RecentActivityEpochMs is { } recent) rows.Add((Strings.Tr("ÚLTIMA ATIVIDADE"), FormatDate(recent)));
        if (game.InstalledAtEpochMs is { } installed) rows.Add((Strings.Tr("INSTALADO EM"), FormatDate(installed)));

        for (var i = 0; i < rows.Count; i++)
        {
            var row = new StackPanel
            {
                Spacing = 4,
                Padding = new Thickness(0, 16, 0, 16),
                BorderBrush = new SolidColorBrush(Color.FromArgb(0x0D, 255, 255, 255)),
                BorderThickness = new Thickness(0, i == 0 ? 0 : 1, 0, 0),
            };
            row.Children.Add(new TextBlock { Text = rows[i].Key, FontSize = 12, FontWeight = Microsoft.UI.Text.FontWeights.Bold, CharacterSpacing = 65, Foreground = (Brush)Application.Current.Resources["TextTertiaryBrush"] });
            row.Children.Add(new TextBlock { Text = rows[i].Value, FontSize = 14, FontWeight = Microsoft.UI.Text.FontWeights.SemiBold, LineHeight = 19.6, TextWrapping = TextWrapping.Wrap });
            FactsPanel.Children.Add(row);
        }
    }

    /// <summary>A Microsoft entrega ISO (2012-07-28); a Steam já entrega texto localizado, mostrado como veio.</summary>
    private static string? FormatRelease(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return null;
        return DateTime.TryParseExact(raw, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var date)
            ? date.ToString("d MMM yyyy", CultureInfo.CurrentUICulture)
            : raw;
    }

    private static string FormatDate(long epochMs) => DateTimeOffset.FromUnixTimeMilliseconds(epochMs).ToLocalTime().ToString("d MMM yyyy", CultureInfo.CurrentUICulture);

    private void BindHistory()
    {
        HistoryPanel.Children.Clear();
        var id = _game?.DiagnosticGameId;
        var entries = string.IsNullOrWhiteSpace(id)
            ? new List<SessionHistoryEntry>()
            : SessionHistoryServices.Store.Entries
                .Where(entry => string.Equals(entry.GameId, id, StringComparison.OrdinalIgnoreCase) && entry.PingMs.HasValue)
                .Take(6)
                .ToList();

        HistStatusText.Visibility = entries.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
        for (var i = 0; i < entries.Count; i++)
        {
            var entry = entries[i];
            var tone = Verdicts.ToneOf(entry.Verdict);
            var row = new Grid
            {
                ColumnSpacing = 12,
                Padding = new Thickness(0, 12, 0, 12),
                BorderBrush = new SolidColorBrush(Color.FromArgb(0x0F, 255, 255, 255)),
                BorderThickness = new Thickness(0, i == 0 ? 0 : 1, 0, 0),
            };
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            var marker = Verdicts.Marker(tone);
            row.Children.Add(marker);
            var text = new StackPanel();
            text.Children.Add(new TextBlock { Text = Verdicts.Headline(tone, true), FontSize = 14, FontWeight = Microsoft.UI.Text.FontWeights.SemiBold, TextTrimming = TextTrimming.CharacterEllipsis });
            text.Children.Add(new TextBlock
            {
                Text = $"{entry.PingLabel} · jitter {entry.JitterLabel}",
                FontSize = 12,
                Margin = new Thickness(0, 2, 0, 0),
                Foreground = (Brush)Application.Current.Resources["TextSecondaryBrush"],
            });
            Grid.SetColumn(text, 1);
            row.Children.Add(text);
            var time = new TextBlock { Text = entry.TimeLabel, FontSize = 12, Foreground = (Brush)Application.Current.Resources["TextTertiaryBrush"], VerticalAlignment = VerticalAlignment.Center };
            Grid.SetColumn(time, 2);
            row.Children.Add(time);
            HistoryPanel.Children.Add(row);
        }
    }

    // ------------------------------------------------------------------ heatmap

    private void BuildHeatLabels()
    {
        HeatDayLabels.RowDefinitions.Clear();
        HeatDayLabels.Children.Clear();
        for (var row = 0; row < 8; row++) HeatDayLabels.RowDefinitions.Add(new RowDefinition { Height = new GridLength(14) });
        var names = new Dictionary<int, string> { [1] = "Seg", [3] = "Qua", [5] = "Sex" };
        foreach (var (row, text) in names)
        {
            var label = new TextBlock { Text = Strings.Tr(text), FontSize = 11, Foreground = (Brush)Application.Current.Resources["TextTertiaryBrush"], LineHeight = 14, LineStackingStrategy = LineStackingStrategy.BlockLineHeight };
            Grid.SetRow(label, row);
            HeatDayLabels.Children.Add(label);
        }
    }

    private void BuildHeatmap(LibraryGame game)
    {
        HeatCells.Children.Clear();
        HeatCells.RowDefinitions.Clear();
        HeatCells.ColumnDefinitions.Clear();
        HeatMonths.Children.Clear();
        HeatMonths.ColumnDefinitions.Clear();
        HeatMonths.Width = HeatWeeks * 18 - 4;
        HeatCells.RowSpacing = 4;
        HeatCells.ColumnSpacing = 4;
        for (var r = 0; r < 7; r++) HeatCells.RowDefinitions.Add(new RowDefinition { Height = new GridLength(14) });
        for (var c = 0; c < HeatWeeks; c++) HeatCells.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(14) });

        var played = new HashSet<DateTime>();
        foreach (var epoch in new[] { game.LastPlayedEpochMs, game.LastLaunchedEpochMs })
        {
            if (epoch is { } value) played.Add(DateTimeOffset.FromUnixTimeMilliseconds(value).ToLocalTime().Date);
        }

        var today = DateTime.Today;
        var dow = ((int)today.DayOfWeek + 6) % 7;
        var start = today.AddDays(-dow - (HeatWeeks - 1) * 7);
        var culture = CultureInfo.CurrentUICulture;
        var empty = new SolidColorBrush(Color.FromArgb(255, 0x1C, 0x21, 0x2B));
        var on = new SolidColorBrush(Color.FromArgb(255, 0x7C, 0x3A, 0xED));
        var monthCanvas = new Canvas { Width = HeatMonths.Width, Height = 14 };
        var lastMonth = -1;

        for (var w = 0; w < HeatWeeks; w++)
        {
            var weekStart = start.AddDays(w * 7);
            if (weekStart.Month != lastMonth)
            {
                lastMonth = weekStart.Month;
                var label = new TextBlock { Text = culture.DateTimeFormat.GetAbbreviatedMonthName(weekStart.Month).TrimEnd('.').ToLower(culture), FontSize = 11, Foreground = (Brush)Application.Current.Resources["TextTertiaryBrush"], TextWrapping = TextWrapping.NoWrap };
                Canvas.SetLeft(label, w * 18);
                monthCanvas.Children.Add(label);
            }
            for (var d = 0; d < 7; d++)
            {
                var day = weekStart.AddDays(d);
                var future = day > today;
                var isPlayed = !future && played.Contains(day);
                var cell = new Border
                {
                    Width = 14,
                    Height = 14,
                    CornerRadius = new CornerRadius(3),
                    Background = future ? new SolidColorBrush(Microsoft.UI.Colors.Transparent) : isPlayed ? on : empty,
                };
                ToolTipService.SetToolTip(cell, day.ToString("d MMM", culture) + (future ? string.Empty : isPlayed ? " · " + Strings.Tr("jogado") : " · " + Strings.Tr("sem partidas")));
                Grid.SetRow(cell, d);
                Grid.SetColumn(cell, w);
                HeatCells.Children.Add(cell);
            }
        }
        HeatMonths.Children.Add(monthCanvas);
    }

    // ------------------------------------------------------------------ ações

    private void GoBack_Click(object sender, RoutedEventArgs e)
    {
        if (Frame.CanGoBack) Frame.GoBack();
        else ShellNavigation.Navigate(NavigationRoute.Library);
    }

    private async void Launch_Click(object sender, RoutedEventArgs e)
    {
        if (_game is not { IsInstalled: true, IsLaunchable: true } game) return;
        ShellChrome.Shell?.ShowToast(Strings.Format("Abrindo {0}…", game.Title));
        try
        {
            var result = await _bridge.LaunchAsync(game.Id);
            if (!result.Succeeded && !string.IsNullOrWhiteSpace(result.Message)) ShellChrome.Shell?.ShowToast(result.Message!);
        }
        catch
        {
            ShellChrome.Shell?.ShowToast(Strings.Tr("Não foi possível pedir a abertura do jogo."));
        }
    }

    private void CheckConnection_Click(object sender, RoutedEventArgs e)
    {
        if (_game is { } game) ShellNavigation.NavigateToDiagnostic(game.DiagnosticGameId, game.Title);
    }

    private async void ToggleFavorite_Click(object sender, RoutedEventArgs e)
    {
        if (_game is not { } game) return;
        try
        {
            var result = await _bridge.SetFavoriteAsync(game.Id, !game.IsFavorite);
            if (result.Snapshot?.Games.FirstOrDefault(item => item.Id == game.Id) is { } updated) _game = updated;
            else if (result.Succeeded) _game = game with { IsFavorite = !game.IsFavorite };
            BindGame();
        }
        catch
        {
            ShellChrome.Shell?.ShowToast(Strings.Tr("Não foi possível atualizar os favoritos."));
        }
    }
}
