using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading;
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
    private LibraryGame? _game;
    private readonly ILibraryBridge _bridge;
    private bool _isPageLoaded;
    private CancellationTokenSource? _infoCts;

    private static readonly CultureInfo[] ReleaseParseCultures =
    {
        CultureInfo.InvariantCulture,
        CultureInfo.GetCultureInfo("pt-PT"),
        CultureInfo.GetCultureInfo("pt-BR"),
        CultureInfo.GetCultureInfo("en-US"),
        CultureInfo.GetCultureInfo("es-ES"),
    };

    private static readonly string[] ReleaseDateFormats =
    {
        "yyyy-MM-dd",
        "d/MMM./yyyy",
        "d/MMM/yyyy",
        "d 'de' MMM. 'de' yyyy",
        "d 'de' MMM 'de' yyyy",
        "d 'de' MMMM 'de' yyyy",
        "d MMM, yyyy",
        "d MMM yyyy",
        "MMM d, yyyy",
        "MMMM d, yyyy",
    };

    public GameDetailsPage()
    {
        InitializeComponent();
        _bridge = LibraryPageServices.Bridge;
        GlowEffect.Attach(LaunchGlow, Color.FromArgb(0x8C, 0x7C, 0x3A, 0xED), 36);
        LocalizeUI();
        foreach (var button in new[] { LaunchBtn, CheckConnBtn, FavBtn, MeasureNowBtn, BackBtn }) Fluid.Feedback(button);
        LocalizationService.Instance.LanguageChanged += OnLanguageChanged;
        SessionHistoryServices.Store.Entries.CollectionChanged += OnHistoryChanged;
        Loaded += (_, _) => { _isPageLoaded = true; AnimateEntrance(); };
        Unloaded += (_, _) =>
        {
            _infoCts?.Cancel();
            _infoCts?.Dispose();
            _infoCts = null;
            LocalizationService.Instance.LanguageChanged -= OnLanguageChanged;
            SessionHistoryServices.Store.Entries.CollectionChanged -= OnHistoryChanged;
        };
    }

    private void OnLanguageChanged() => DispatcherQueue.TryEnqueue(() =>
    {
        LocalizeUI();
        BindGame();
        if (_game is { } game) _ = EnsureLocalizedGameInfoAsync(game);
    });
    private void OnHistoryChanged(object? sender, System.Collections.Specialized.NotifyCollectionChangedEventArgs e) => DispatcherQueue.TryEnqueue(BindHistory);

    private void LocalizeUI()
    {
        BackBtnText.Text = Strings.Tr("Voltar");
        ToolTipService.SetToolTip(BackBtn, Strings.Tr("Voltar à tela anterior"));
        LaunchBtn.Content = Strings.Tr("JOGAR AGORA");
        CheckConnBtn.Content = Strings.Tr("Testar conexão");
        HistEyebrow.Text = Strings.Tr("HISTÓRICO DE MEDIÇÕES");
        HistStatusText.Text = Strings.Tr("Sem medições");
        MeasureNowBtn.Content = Strings.Tr("Testar agora");
        ShotsEyebrow.Text = Strings.Tr("CAPTURAS");
    }

    protected override void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        if (e.Parameter is LibraryGame game)
        {
            _game = game;
            ApplyHeroSizing();
            BindGame();
            _ = EnsureLocalizedGameInfoAsync(game);
            _ = ResolveArtworkAsync(game);
            if (_isPageLoaded) AnimateEntrance();
        }
    }

    private void AnimateEntrance()
    {
        if (BackgroundLayer.Visibility == Visibility.Visible)
        {
            Choreo.FadeSlideIn(BackgroundLayer, ms: Choreo.Slow, dy: 0);
        }
        Choreo.FadeSlideIn(PlatformPill, dy: 16, delayMs: 0);
        Choreo.FadeSlideIn(GameTitleText, dy: 16, delayMs: 60);
        Choreo.FadeSlideIn(GamePillsHost, dy: 16, delayMs: 120);
        Choreo.FadeSlideIn(CtaRow, dy: 16, delayMs: 180);
        if (DescriptionCard.Visibility == Visibility.Visible)
        {
            Choreo.FadeSlideIn(DescriptionCard, dy: 16, delayMs: 240);
        }
        if (ShotsCard.Visibility == Visibility.Visible)
        {
            Choreo.FadeSlideIn(ShotsCard, dy: 16, delayMs: 300);
        }
        Choreo.FadeSlideIn(SideColumn, dy: 16, delayMs: 300);
    }

    private void GameDetailsPage_SizeChanged(object sender, SizeChangedEventArgs e) => ApplyHeroSizing();

    private void ApplyHeroSizing()
    {
        var height = Math.Max((ShellChrome.Shell?.ActualHeight ?? 0) is > 0 ? ShellChrome.Shell!.ActualHeight : ActualHeight, 420);
        HeroSection.Height = Math.Max(420, height * 0.58);
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
                BindGame(isArtworkRefresh: true);
                _ = EnsureLocalizedGameInfoAsync(updated);
            }
        }
        catch
        {
            // A arte é complementar: o banner neutro continua correto.
        }
    }

    private async System.Threading.Tasks.Task EnsureLocalizedGameInfoAsync(LibraryGame game)
    {
        _infoCts?.Cancel();
        _infoCts?.Dispose();
        var cts = new CancellationTokenSource();
        _infoCts = cts;
        var language = LocalizationService.Instance.EffectiveLanguage;
        try
        {
            var localized = await LocalizedGameInfoResolver.ResolveAsync(game, language, cts.Token);
            if (cts.IsCancellationRequested || ReferenceEquals(localized, game)) return;
            DispatcherQueue.TryEnqueue(() =>
            {
                if (cts.IsCancellationRequested || _game?.Id != game.Id) return;
                _game = localized;
                BindGame();
            });
        }
        catch
        {
            // Falha ao traduzir dados da loja mantém o conteúdo já carregado.
        }
    }

    // ------------------------------------------------------------------ apresentação

    private void BindGame(bool isArtworkRefresh = false)
    {
        if (_game is not { } game) return;

        GameTitleText.Text = game.Title.ToUpperInvariant();
        var logo = Glyphs.PlatformLogo(game.Platform);
        PlatformLogo.Visibility = logo is null ? Visibility.Collapsed : Visibility.Visible;
        PlatformMonitor.Visibility = logo is null ? Visibility.Visible : Visibility.Collapsed;
        PlatformText.Visibility = logo is null ? Visibility.Visible : Visibility.Collapsed;
        if (logo is not null) PlatformLogo.Data = logo;
        ToolTipService.SetToolTip(PlatformPill, game.PlatformLabel);

        var heroArt = Artwork.FirstExisting(game.HeroArtworkPath);
        if (heroArt is not null)
        {
            BackgroundImage.Source = Artwork.Load(heroArt, 2560);
            BackgroundLayer.Visibility = Visibility.Visible;
            if (isArtworkRefresh)
            {
                Choreo.Refresh(BackgroundLayer);
            }
        }
        else
        {
            BackgroundImage.Source = null;
            BackgroundLayer.Visibility = Visibility.Collapsed;
        }

        CheckConnBtn.Visibility = game.CanTestConnection ? Visibility.Visible : Visibility.Collapsed;
        MeasureNowBtn.Visibility = game.CanTestConnection ? Visibility.Visible : Visibility.Collapsed;
        var canLaunch = game.IsInstalled && game.IsLaunchable;
        LaunchBtn.IsEnabled = canLaunch;
        LaunchGlow.Visibility = canLaunch ? Visibility.Visible : Visibility.Collapsed;
        FavIcon.IsFilled = game.IsFavorite;
        FavIcon.Foreground = game.IsFavorite ? (Brush)Application.Current.Resources["CoralBrush"] : (Brush)Application.Current.Resources["TextPrimaryBrush"];
        ToolTipService.SetToolTip(FavBtn, game.FavoriteActionLabel);

        GamePillsHost.Child = GamePills.Create(game);

        var description = !string.IsNullOrWhiteSpace(game.Info?.Description) ? game.Info!.Description : game.Description;
        DescriptionText.Text = description ?? string.Empty;
        DescriptionCard.Visibility = string.IsNullOrWhiteSpace(description) ? Visibility.Collapsed : Visibility.Visible;
        BindFacts(game);
        BindScreenshots(game);
        BindHistory();
    }

    // ------------------------------------------------------------------ capturas

    private void BindScreenshots(LibraryGame game)
    {
        ShotsPanel.Children.Clear();
        // Só arquivos que ainda existem: print movido ou apagado some da lista em vez de virar quadro vazio.
        var shots = game.UserScreenshots.Where(shot => Artwork.FirstExisting(shot.Path) is not null).ToList();
        ShotsCard.Visibility = shots.Count == 0 ? Visibility.Collapsed : Visibility.Visible;
        if (shots.Count == 0) return;

        ShotsEyebrow.Text = $"{Strings.Tr("CAPTURAS")} · {shots.Count}";
        ShotsNote.Text = Strings.Tr("Prints que você tirou neste jogo na Steam.");
        foreach (var shot in shots)
        {
            var image = new Image
            {
                Stretch = Stretch.UniformToFill,
                Source = Artwork.Load(Artwork.FirstExisting(shot.ThumbnailPath, shot.Path), 480),
            };
            var button = new Button
            {
                Width = 240,
                Height = 135,
                Padding = new Thickness(0),
                CornerRadius = new CornerRadius(10),
                Content = image,
                Tag = shot,
            };
            Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(button, shot.CreatedEpochMs is { } at ? $"{Strings.Tr("CAPTURAS")} {FormatDate(at)}" : Strings.Tr("CAPTURAS"));
            if (shot.CreatedEpochMs is { } created) ToolTipService.SetToolTip(button, FormatDate(created));
            button.Click += Screenshot_Click;
            ShotsPanel.Children.Add(button);
        }
    }

    private async void Screenshot_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not Button { Tag: GameScreenshot shot }) return;
        var viewer = new Image { Stretch = Stretch.Uniform, MaxHeight = 560, Source = Artwork.Load(shot.Path, 1920) };
        var dialog = new ContentDialog
        {
            XamlRoot = XamlRoot,
            Content = viewer,
            PrimaryButtonText = Strings.Tr("Abrir no visualizador"),
            CloseButtonText = Strings.Tr("Fechar"),
            DefaultButton = ContentDialogButton.Close,
        };
        try
        {
            if (await dialog.ShowAsync() == ContentDialogResult.Primary)
                await Windows.System.Launcher.LaunchFileAsync(await Windows.Storage.StorageFile.GetFileFromPathAsync(shot.Path));
        }
        catch
        {
            // Visualizar é complementar: falha ao abrir o arquivo não afeta a página.
        }
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
                Padding = new Thickness(0, 12, 0, 12),
                BorderBrush = new SolidColorBrush(Color.FromArgb(0x14, 255, 255, 255)),
                BorderThickness = new Thickness(0, i == 0 ? 0 : 1, 0, 0),
            };
            row.Children.Add(new TextBlock { Text = rows[i].Key, FontFamily = (FontFamily)Application.Current.Resources["TechnicalFont"], FontSize = 11, FontWeight = Microsoft.UI.Text.FontWeights.Normal, CharacterSpacing = 70, Foreground = (Brush)Application.Current.Resources["TextTertiaryBrush"] });
            row.Children.Add(new TextBlock { Text = rows[i].Value, FontFamily = (FontFamily)Application.Current.Resources["BodySemiBoldFont"], FontSize = 14, FontWeight = Microsoft.UI.Text.FontWeights.Normal, LineHeight = 19.6, TextWrapping = TextWrapping.Wrap });
            FactsPanel.Children.Add(row);
        }
    }

    /// <summary>Normaliza datas da Microsoft (ISO) e da Steam para a cultura selecionada no app.</summary>
    private static string? FormatRelease(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return null;
        var trimmed = raw.Trim();
        var targetCulture = LocalizationService.Instance.EffectiveCulture;

        foreach (var culture in ReleaseParseCultures)
        {
            if (DateTime.TryParseExact(trimmed, ReleaseDateFormats, culture, DateTimeStyles.AllowWhiteSpaces, out var exact))
                return exact.ToString("d MMM yyyy", targetCulture);
        }

        foreach (var culture in ReleaseParseCultures)
        {
            if (DateTime.TryParse(trimmed, culture, DateTimeStyles.AllowWhiteSpaces, out var parsed))
                return parsed.ToString("d MMM yyyy", targetCulture);
        }

        return trimmed;
    }

    private static string FormatDate(long epochMs) => DateTimeOffset.FromUnixTimeMilliseconds(epochMs).ToLocalTime().ToString("d MMM yyyy", LocalizationService.Instance.EffectiveCulture);

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
            text.Children.Add(new TextBlock { Text = Verdicts.Headline(tone, true), FontFamily = (FontFamily)Application.Current.Resources["HeadingBoldFont"], FontSize = 14, FontWeight = Microsoft.UI.Text.FontWeights.Normal, TextTrimming = TextTrimming.CharacterEllipsis });
            text.Children.Add(new TextBlock
            {
                Text = $"{entry.PingLabel} · {Strings.Tr("JITTER").ToLower(CultureInfo.CurrentCulture)} {entry.JitterLabel}",
                FontFamily = (FontFamily)Application.Current.Resources["MetricFont"],
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
