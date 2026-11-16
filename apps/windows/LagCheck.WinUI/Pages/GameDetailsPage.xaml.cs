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
    private static readonly HashSet<string> SessionResolvedArtworkIds = new(StringComparer.Ordinal);

    private LibraryGame? _game;
    private SteamLiveStats? _liveStats;
    private readonly ILibraryBridge _bridge;
    private bool _isPageLoaded;
    private CancellationTokenSource? _infoCts;
    private CancellationTokenSource? _liveStatsCts;

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
        GlowEffect.AttachShadow(PlatformPillShadow, Color.FromArgb(0x90, 0, 0, 0), blur: 12f, offsetY: 4f);
        GlowEffect.AttachShadow(CheckConnShadow, Color.FromArgb(0xA0, 0, 0, 0), blur: 14f, offsetY: 5f);
        GlowEffect.AttachShadow(FavBtnShadow, Color.FromArgb(0xA0, 0, 0, 0), blur: 14f, offsetY: 5f);
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
            _liveStatsCts?.Cancel();
            _liveStatsCts?.Dispose();
            _liveStatsCts = null;
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
        StabilityDetailsBtn.Content = Strings.Tr("Ver detalhes da estabilidade");
        ShotsEyebrow.Text = Strings.Tr("CAPTURAS");
        NewsEyebrow.Text = Strings.Tr("ATUALIZAÇÕES E NOTÍCIAS");
    }

    protected override void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        if (e.Parameter is LibraryGame game)
        {
            _game = game;
            _liveStats = null;
            ApplyHeroSizing();
            BindGame();
            _ = EnsureLocalizedGameInfoAsync(game);
            _ = ResolveArtworkAsync(game);
            _ = FetchSteamLiveStatsAsync(game);
            if (_isPageLoaded) AnimateEntrance();
        }
    }

    private void AnimateEntrance()
    {
        if (BackgroundLayer.Visibility == Visibility.Visible)
        {
            Choreo.FadeSlideIn(BackgroundImage, ms: Choreo.Slow, dy: 0);
        }
        Choreo.FadeSlideIn(PlatformPillContainer, dy: 16, delayMs: 0);
        Choreo.FadeSlideIn(GameLogoImage.Visibility == Visibility.Visible ? (UIElement)GameLogoImage : GameTitleText, dy: 16, delayMs: 60);
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
        if (NewsCard.Visibility == Visibility.Visible)
        {
            Choreo.FadeSlideIn(NewsCard, dy: 16, delayMs: 300);
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
        var hasLogoOrTried = Artwork.FirstExisting(game.LogoArtworkPath) is not null || SessionResolvedArtworkIds.Contains(game.Id);
        var hasArt = Artwork.FirstExisting(game.HeroArtworkPath) is not null && Artwork.FirstExisting(game.CoverArtworkPath) is not null && hasLogoOrTried;
        // As informações de catálogo vêm na mesma chamada da arte: pede também quando só elas faltam.
        if (!game.IsInstalled || (hasArt && game.Info is not null)) return;
        SessionResolvedArtworkIds.Add(game.Id);
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

    private async System.Threading.Tasks.Task FetchSteamLiveStatsAsync(LibraryGame game)
    {
        _liveStatsCts?.Cancel();
        _liveStatsCts?.Dispose();
        var cts = new CancellationTokenSource();
        _liveStatsCts = cts;
        try
        {
            var stats = await SteamLiveStatsResolver.ResolveAsync(game, cts.Token);
            if (cts.IsCancellationRequested || stats is null) return;
            DispatcherQueue.TryEnqueue(() =>
            {
                if (cts.IsCancellationRequested || _game?.Id != game.Id) return;
                _liveStats = stats;
                BindPills(_game);
                BindNews();
            });
        }
        catch
        {
            // Dados ao vivo são opcionais; falha de rede nunca bloqueia a página.
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

        var logoArt = Artwork.FirstExisting(game.LogoArtworkPath);
        if (logoArt is not null)
        {
            GameLogoImage.Source = Artwork.Load(logoArt);
            GameLogoImage.Visibility = Visibility.Visible;
            Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(GameLogoImage, game.Title);
            GameTitleText.Visibility = Visibility.Collapsed;
        }
        else
        {
            GameLogoImage.Source = null;
            GameLogoImage.Visibility = Visibility.Collapsed;
            GameTitleText.Visibility = Visibility.Visible;
        }
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
            BackgroundImage.Source = Artwork.Load(heroArt);
            BackgroundLayer.Visibility = Visibility.Visible;
            if (isArtworkRefresh)
            {
                Choreo.Refresh(BackgroundImage);
            }
        }
        else
        {
            BackgroundImage.Source = null;
            BackgroundLayer.Visibility = Visibility.Collapsed;
        }

        var canTest = game.CanTestConnection ? Visibility.Visible : Visibility.Collapsed;
        CheckConnContainer.Visibility = canTest;
        CheckConnShadow.Visibility = canTest;
        CheckConnBtn.Visibility = canTest;
        MeasureNowBtn.Visibility = game.CanTestConnection ? Visibility.Visible : Visibility.Collapsed;
        var canLaunch = game.IsInstalled && game.IsLaunchable;
        LaunchBtn.IsEnabled = canLaunch;
        LaunchGlow.Visibility = canLaunch ? Visibility.Visible : Visibility.Collapsed;
        FavIcon.IsFilled = game.IsFavorite;
        FavIcon.Foreground = game.IsFavorite ? (Brush)Application.Current.Resources["CoralBrush"] : (Brush)Application.Current.Resources["TextPrimaryBrush"];
        ToolTipService.SetToolTip(FavBtn, game.FavoriteActionLabel);

        BindPills(game);

        var description = !string.IsNullOrWhiteSpace(game.Info?.Description) ? game.Info!.Description : game.Description;
        DescriptionText.Text = description ?? string.Empty;
        DescriptionCard.Visibility = string.IsNullOrWhiteSpace(description) ? Visibility.Collapsed : Visibility.Visible;
        BindFacts(game);
        BindScreenshots(game);
        BindNews();
        BindHistory();
    }

    private void BindPills(LibraryGame game)
    {
        var liveChip = _liveStats?.CurrentPlayers is { } players && players > 0
            ? Strings.Format("{0:N0} jogando agora", players)
            : null;
        GamePillsHost.Child = GamePills.Create(game, extraStatusChip: liveChip);
    }

    // ------------------------------------------------------------------ capturas

    private void BindScreenshots(LibraryGame game)
    {
        ShotsPanel.Children.Clear();
        // Só arquivos que ainda existem: print movido ou apagado some da lista em vez de virar quadro vazio.
        var shots = game.UserScreenshots.Where(shot => Artwork.FirstExisting(shot.Path) is not null).ToList();
        if (shots.Count > 0)
        {
            ShotsCard.Visibility = Visibility.Visible;
            ShotsEyebrow.Text = $"{Strings.Tr("CAPTURAS")} · {shots.Count}";
            ShotsNote.Text = Strings.Tr("Prints que você tirou neste jogo na Steam.");
            foreach (var shot in shots)
            {
                var image = new Image
                {
                    Stretch = Stretch.UniformToFill,
                    Source = Artwork.Load(Artwork.FirstExisting(shot.ThumbnailPath, shot.Path), 960),
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
            return;
        }

        var storeShots = game.Info?.StoreScreenshots?
            .Where(url => Uri.TryCreate(url, UriKind.Absolute, out var uri) && (uri.Scheme == Uri.UriSchemeHttps || uri.Scheme == Uri.UriSchemeHttp))
            .Take(6)
            .ToList() ?? new List<string>();
        ShotsCard.Visibility = storeShots.Count == 0 ? Visibility.Collapsed : Visibility.Visible;
        if (storeShots.Count == 0) return;

        ShotsEyebrow.Text = $"{Strings.Tr("CAPTURAS DA LOJA")} · {storeShots.Count}";
        ShotsNote.Text = Strings.Tr("Imagens divulgadas pela loja oficial.");
        foreach (var url in storeShots)
        {
            var image = new Image
            {
                Stretch = Stretch.UniformToFill,
                Source = new Microsoft.UI.Xaml.Media.Imaging.BitmapImage(new Uri(url)) { DecodePixelWidth = 960 },
            };
            var button = new Button
            {
                Width = 240,
                Height = 135,
                Padding = new Thickness(0),
                CornerRadius = new CornerRadius(10),
                Content = image,
                Tag = url,
            };
            Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(button, Strings.Tr("CAPTURAS DA LOJA"));
            button.Click += Screenshot_Click;
            ShotsPanel.Children.Add(button);
        }
    }

    private async void Screenshot_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: GameScreenshot shot })
        {
            var viewer = new Image { Stretch = Stretch.Uniform, MaxHeight = 760, Source = Artwork.Load(shot.Path) };
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
        else if (sender is Button { Tag: string remoteUrl } && Uri.TryCreate(remoteUrl, UriKind.Absolute, out var remoteUri))
        {
            var viewer = new Image
            {
                Stretch = Stretch.Uniform,
                MaxHeight = 760,
                Source = new Microsoft.UI.Xaml.Media.Imaging.BitmapImage(remoteUri),
            };
            var dialog = new ContentDialog
            {
                XamlRoot = XamlRoot,
                Content = viewer,
                PrimaryButtonText = Strings.Tr("Abrir no navegador"),
                CloseButtonText = Strings.Tr("Fechar"),
                DefaultButton = ContentDialogButton.Close,
            };
            try
            {
                if (await dialog.ShowAsync() == ContentDialogResult.Primary)
                    await Windows.System.Launcher.LaunchUriAsync(remoteUri);
            }
            catch
            {
                // Visualizar é complementar: falha ao abrir o link não afeta a página.
            }
        }
    }

    private void BindNews()
    {
        NewsPanel.Children.Clear();
        var news = _liveStats?.News;
        NewsCard.Visibility = news is { Count: > 0 } ? Visibility.Visible : Visibility.Collapsed;
        if (news is null || news.Count == 0) return;

        NewsEyebrow.Text = Strings.Tr("ATUALIZAÇÕES E NOTÍCIAS");
        var surface = new SolidColorBrush(Color.FromArgb(0x99, 0x15, 0x18, 0x1E));
        var border = new SolidColorBrush(Color.FromArgb(0x1F, 255, 255, 255));
        var headingFont = (FontFamily)Application.Current.Resources["BodySemiBoldFont"];
        var tertiary = (Brush)Application.Current.Resources["TextTertiaryBrush"];

        foreach (var item in news.Take(3))
        {
            var stack = new StackPanel { Spacing = 4, HorizontalAlignment = HorizontalAlignment.Stretch };
            stack.Children.Add(new TextBlock
            {
                Text = item.Title,
                FontFamily = headingFont,
                FontSize = 14,
                FontWeight = Microsoft.UI.Text.FontWeights.Normal,
                TextWrapping = TextWrapping.Wrap,
            });
            var metaParts = new List<string>();
            if (!string.IsNullOrWhiteSpace(item.FeedLabel)) metaParts.Add(item.FeedLabel);
            if (item.PublishedAt > DateTimeOffset.MinValue) metaParts.Add(FormatDate(item.PublishedAt.ToUnixTimeMilliseconds()));
            if (metaParts.Count > 0)
            {
                stack.Children.Add(new TextBlock
                {
                    Text = string.Join(" · ", metaParts),
                    FontSize = 12,
                    Foreground = tertiary,
                });
            }

            var btn = new Button
            {
                HorizontalAlignment = HorizontalAlignment.Stretch,
                HorizontalContentAlignment = HorizontalAlignment.Stretch,
                Padding = new Thickness(16, 12, 16, 12),
                CornerRadius = new CornerRadius(10),
                Background = surface,
                BorderBrush = border,
                BorderThickness = new Thickness(1),
                Content = stack,
                Tag = item.Url,
            };
            Fluid.Feedback(btn);
            btn.Click += NewsItem_Click;
            NewsPanel.Children.Add(btn);
        }
    }

    private async void NewsItem_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not Button { Tag: string url } || !Uri.TryCreate(url, UriKind.Absolute, out var uri)) return;
        try
        {
            await Windows.System.Launcher.LaunchUriAsync(uri);
        }
        catch
        {
            // Link complementar; falha silenciosa.
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
        if (game.UpdateState != GameUpdateState.Ready)
        {
            var stateText = Strings.Tr(game.UpdateState == GameUpdateState.Downloading ? "Baixando atualização" : "Atualização pendente");
            if (game.DownloadBytesTotal is > 0 && game.DownloadBytesCompleted is >= 0)
            {
                var pct = (int)Math.Clamp(game.DownloadBytesCompleted.Value * 100.0 / game.DownloadBytesTotal.Value, 0, 99);
                stateText = $"{stateText} ({pct}%)";
            }
            rows.Add((Strings.Tr("ESTADO NO LAUNCHER"), stateText));
        }
        if (game.FormattedPlayTime is { } playTime) rows.Add((Strings.Tr("TEMPO JOGADO"), playTime));
        if (game.FormattedSizeOnDisk is { } diskSize) rows.Add((Strings.Tr("TAMANHO NO DISCO"), diskSize));
        if (game.Info is { } info)
        {
            if (!string.IsNullOrWhiteSpace(info.Developer)) rows.Add((Strings.Tr("DESENVOLVEDORA"), info.Developer!));
            if (!string.IsNullOrWhiteSpace(info.Publisher) && !string.Equals(info.Publisher, info.Developer, StringComparison.OrdinalIgnoreCase)) rows.Add((Strings.Tr("PUBLICADORA"), info.Publisher!));
            if (FormatRelease(info.ReleaseDate) is { } release) rows.Add((Strings.Tr("LANÇAMENTO"), release));
            var controller = info.ControllerSupport switch
            {
                "full" => Strings.Tr("Completo"),
                "partial" => Strings.Tr("Parcial"),
                _ => null,
            };
            if (controller is not null) rows.Add((Strings.Tr("CONTROLE"), controller));

            var ratingParts = new List<string>();
            if (info.MetacriticScore is { } mc) ratingParts.Add($"Metacritic {mc}");
            if (info.RecommendationsTotal is { } rec) ratingParts.Add(Strings.Format("{0:N0} análises", rec));
            if (ratingParts.Count > 0) rows.Add((Strings.Tr("AVALIAÇÃO"), string.Join(" · ", ratingParts)));

            var featureParts = new List<string>();
            if (info.HasCloudSaves) featureParts.Add(Strings.Tr("Nuvem"));
            if (!string.IsNullOrWhiteSpace(info.AntiCheat)) featureParts.Add(info.AntiCheat!);
            if (featureParts.Count > 0) rows.Add((Strings.Tr("RECURSOS"), string.Join(" · ", featureParts)));

            if (info.HasPtBr == true) rows.Add((Strings.Tr("IDIOMA PT-BR"), Strings.Tr("Disponível")));
            if (!string.IsNullOrWhiteSpace(info.PcMinimumRequirements)) rows.Add((Strings.Tr("REQUISITOS MÍNIMOS"), info.PcMinimumRequirements!));
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

    private void StabilityDetails_Click(object sender, RoutedEventArgs e)
    {
        if (_game is not null)
        {
            LagCheck.WinUI.ShellNavigation.OpenHistory(_game.HistoryGameKey, _game.Title);
        }
    }

    private void BindHistory()
    {
        StabilityBlock.Children.Clear();
        HistoryPanel.Children.Clear();
        var gameKey = _game?.HistoryGameKey;
        var summary = string.IsNullOrWhiteSpace(gameKey)
            ? NetworkStabilitySummary.Empty
            : NetworkStabilitySummary.Build(SessionHistoryServices.Store.Entries, gameKey, maxPoints: 16);

        if (summary.HasData && summary.Latest is not null)
        {
            StabilityBlock.Visibility = Visibility.Visible;
            StabilityDetailsBtn.Visibility = Visibility.Visible;

            var culture = LocalizationService.Instance.EffectiveCulture;
            var toneColor = Verdicts.ColorOf(summary.StabilityTone);

            var headerRow = new Grid { ColumnSpacing = 8 };
            headerRow.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            headerRow.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

            var statusBadge = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8, VerticalAlignment = VerticalAlignment.Center };
            statusBadge.Children.Add(Verdicts.Marker(summary.StabilityTone));
            statusBadge.Children.Add(new TextBlock
            {
                Text = Strings.Tr(NetworkStabilitySummary.HeadlineKey(summary.StabilityTone)),
                FontFamily = (FontFamily)Application.Current.Resources["HeadingBoldFont"],
                FontSize = 14,
                FontWeight = Microsoft.UI.Text.FontWeights.Normal,
                Foreground = (Brush)Application.Current.Resources["TextPrimaryBrush"],
                TextTrimming = TextTrimming.CharacterEllipsis,
            });
            headerRow.Children.Add(statusBadge);

            var pctText = new TextBlock
            {
                Text = string.Format(culture, Strings.Tr("{0}% estável"), summary.StabilityPercentage),
                FontFamily = (FontFamily)Application.Current.Resources["MetricFont"],
                FontSize = 12,
                Foreground = new SolidColorBrush(toneColor),
                VerticalAlignment = VerticalAlignment.Center,
            };
            Grid.SetColumn(pctText, 1);
            headerRow.Children.Add(pctText);
            StabilityBlock.Children.Add(headerRow);

            var chartColor = summary.HasMixedContexts
                ? Color.FromArgb(0xFF, 0x8A, 0x93, 0xA0)
                : toneColor;
            var chartHost = new Border
            {
                Height = 72,
                Padding = new Thickness(4, 4, 4, 4),
                Child = LagCheck.WinUI.Widgets.WidgetParts.StabilityChart(summary.Points, chartColor),
            };
            StabilityBlock.Children.Add(chartHost);

            var gaugesGrid = new Grid { ColumnSpacing = 8, Margin = new Thickness(0, 2, 0, 0) };
            gaugesGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            gaugesGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            gaugesGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            gaugesGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            gaugesGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

            var jitterTone = summary.AvgJitter is { } j ? LagCheck.WinUI.Widgets.WidgetParts.MetricVerdictTone(j, 12, 25) : VerdictTone.Unknown;
            var jitterGauge = LagCheck.WinUI.Widgets.WidgetParts.RingMetricGauge(
                Strings.Tr("JITTER"),
                summary.AvgJitter is { } jv ? string.Format(culture, "{0:0.#}", jv) : "—",
                summary.AvgJitter.HasValue ? "ms" : null,
                Verdicts.ColorOf(jitterTone),
                jitterTone,
                summary.AvgJitter is { } jr ? LagCheck.WinUI.Widgets.WidgetParts.MetricRatio(jr, 12, 25, 40) : 0,
                ringSize: 42);
            jitterGauge.HorizontalAlignment = HorizontalAlignment.Center;
            gaugesGrid.Children.Add(jitterGauge);

            var div1 = LagCheck.WinUI.Widgets.WidgetParts.VerticalDivider(6);
            Grid.SetColumn(div1, 1);
            gaugesGrid.Children.Add(div1);

            var avgLoss = summary.AvgLoss ?? summary.MaxLoss;
            var lossTone = avgLoss is { } l ? LagCheck.WinUI.Widgets.WidgetParts.MetricVerdictTone(l, 1, 3) : VerdictTone.Unknown;
            var lossGauge = LagCheck.WinUI.Widgets.WidgetParts.RingMetricGauge(
                Strings.Tr("PERDA"),
                avgLoss is { } lv ? string.Format(culture, "{0:0.#}", lv) : "—",
                avgLoss.HasValue ? "%" : null,
                Verdicts.ColorOf(lossTone),
                lossTone,
                avgLoss is { } lr ? LagCheck.WinUI.Widgets.WidgetParts.MetricRatio(lr, 1, 3, 10) : 0,
                ringSize: 42);
            lossGauge.HorizontalAlignment = HorizontalAlignment.Center;
            Grid.SetColumn(lossGauge, 2);
            gaugesGrid.Children.Add(lossGauge);

            var div2 = LagCheck.WinUI.Widgets.WidgetParts.VerticalDivider(6);
            Grid.SetColumn(div2, 3);
            gaugesGrid.Children.Add(div2);

            var loadTone = summary.AvgLoadDelta is { } ld ? LagCheck.WinUI.Widgets.WidgetParts.MetricVerdictTone(ld, 15, 40) : VerdictTone.Unknown;
            var loadGauge = LagCheck.WinUI.Widgets.WidgetParts.RingMetricGauge(
                Strings.Tr("SOB CARGA"),
                summary.AvgLoadDelta is { } ldv ? string.Format(culture, ldv >= 0 ? "+{0:0.#}" : "{0:0.#}", ldv) : "—",
                summary.AvgLoadDelta.HasValue ? "ms" : null,
                Verdicts.ColorOf(loadTone),
                loadTone,
                summary.AvgLoadDelta is { } ldr ? LagCheck.WinUI.Widgets.WidgetParts.MetricRatio(ldr, 15, 40, 80) : 0,
                ringSize: 42);
            loadGauge.HorizontalAlignment = HorizontalAlignment.Center;
            Grid.SetColumn(loadGauge, 4);
            gaugesGrid.Children.Add(loadGauge);

            StabilityBlock.Children.Add(gaugesGrid);
        }
        else
        {
            StabilityBlock.Visibility = Visibility.Collapsed;
            StabilityDetailsBtn.Visibility = Visibility.Collapsed;
        }

        var entries = _game is null
            ? new List<SessionHistoryEntry>()
            : SessionHistoryServices.Store.Entries
                .Where(entry => entry.PingMs.HasValue && SessionHistoryStore.MatchesGame(entry, _game.DiagnosticGameId, _game.Title))
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
