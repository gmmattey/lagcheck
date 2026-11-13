using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.UI.Text;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Documents;
using Microsoft.UI.Xaml.Media;
using Windows.UI;
using LagCheck.WinUI.Controls;
using LagCheck.WinUI.Library;
using LagCheck.WinUI.Localization;
using Ellipse = Microsoft.UI.Xaml.Shapes.Ellipse;

namespace LagCheck.WinUI.Diagnostic;

/// <summary>
/// Conexão (v2): ociosa com mapa 2:1, medindo com número ao vivo + etapas + faixa de métricas,
/// e resultado em duas colunas com a evidência de rota. Toda medida vem do motor compartilhado;
/// o que o motor não entrega (upload, NAT, ranking de servidores) não é desenhado nem inventado.
/// </summary>
public sealed class DiagnosticPage : Page
{
    private static readonly Color Primary = Color.FromArgb(255, 0xF5, 0xF7, 0xFC);
    private static readonly Color Secondary = Color.FromArgb(255, 0x9A, 0xA3, 0xB5);
    private static readonly Color Tertiary = Color.FromArgb(255, 0x68, 0x72, 0x85);
    private static readonly Color Tech = Color.FromArgb(255, 0x60, 0x68, 0x73);
    private static readonly Color Dim = Color.FromArgb(255, 0x8E, 0x8E, 0x93);
    private static readonly Color Purple = Color.FromArgb(255, 0x7C, 0x3A, 0xED);
    private static readonly Color PurpleLight = Color.FromArgb(255, 0xA7, 0x8B, 0xFA);
    private static readonly Color Line = Color.FromArgb(0x14, 255, 255, 255);

    private static readonly Color[] StageColors =
    {
        Color.FromArgb(255, 0xBF, 0x5A, 0xF2), Color.FromArgb(255, 0x8B, 0x5C, 0xF6), Color.FromArgb(255, 0xF5, 0x9E, 0x0B), Color.FromArgb(255, 0xBF, 0x5A, 0xF2),
    };

    private static SolidColorBrush Brush(Color color) => new(color);
    private static FontFamily Res(string key) => (FontFamily)Application.Current.Resources[key];

    private readonly DiagnosticEngineClient _client;
    private CancellationTokenSource? _measurementCts;
    private string? _gameId;
    private string _gameTitle = string.Empty;
    private ApproximateLocation? _location;
    private bool _running;
    private double _lastRestPing = double.NaN;

    // Containers
    private readonly StackPanel _flowPanel = new() { MaxWidth = 820, HorizontalAlignment = HorizontalAlignment.Stretch };
    private readonly StackPanel _donePanel = new() { MaxWidth = 1100, HorizontalAlignment = HorizontalAlignment.Stretch, Visibility = Visibility.Collapsed };

    // Fluxo (idle + running)
    private readonly TextBlock _idleTitle = new() { FontFamily = Res("HeadingFont"), FontSize = 40, LineHeight = 42, LineStackingStrategy = LineStackingStrategy.BlockLineHeight, TextWrapping = TextWrapping.Wrap };
    private readonly Border _pill = new() { Background = Brush(Color.FromArgb(255, 0x2C, 0x2C, 0x2E)), CornerRadius = new CornerRadius(999), Padding = new Thickness(14, 6, 14, 6), HorizontalAlignment = HorizontalAlignment.Center, Visibility = Visibility.Collapsed };
    private readonly TextBlock _pillText = new() { FontSize = 13, FontWeight = FontWeights.Medium, Foreground = Brush(Color.FromArgb(255, 0xEB, 0xEB, 0xF5)) };
    private readonly Border _mapFrame = new() { BorderBrush = Brush(Color.FromArgb(0x14, 255, 255, 255)), BorderThickness = new Thickness(1), CornerRadius = new CornerRadius(12), Background = Brush(Color.FromArgb(255, 0x0B, 0x0D, 0x10)), Margin = new Thickness(0, 16, 0, 0) };
    private readonly RouteMapView _map = new(animate: true) { CornerRadius = new CornerRadius(12) };
    private readonly Button _startBtn = new();
    private readonly StackPanel _idleControls = new() { Margin = new Thickness(0, 26, 0, 0) };
    private readonly StackPanel _runningPanel = new() { Visibility = Visibility.Collapsed, HorizontalAlignment = HorizontalAlignment.Stretch };
    private readonly Border _progressFill = new() { Height = 2, Background = Brush(Purple), HorizontalAlignment = HorizontalAlignment.Left, Width = 0 };
    private readonly Grid _progressTrack = new() { Height = 2, Margin = new Thickness(0, 8, 0, 0), Background = Brush(Color.FromArgb(0x14, 255, 255, 255)) };
    private readonly Run _liveValue = new() { Text = "—" };
    private readonly Run _liveUnit = new() { Text = string.Empty };
    private readonly TextBlock _phaseName = new() { FontSize = 13, FontWeight = FontWeights.SemiBold, CharacterSpacing = 40, HorizontalAlignment = HorizontalAlignment.Center, Margin = new Thickness(0, 6, 0, 0) };
    private readonly StackPanel _steps = new() { Orientation = Orientation.Horizontal, Spacing = 18, HorizontalAlignment = HorizontalAlignment.Center, Margin = new Thickness(0, 14, 0, 0) };
    private readonly Grid _strip = new() { BorderBrush = Brush(Line), BorderThickness = new Thickness(0, 1, 0, 1), Margin = new Thickness(0, 16, 0, 0) };
    private readonly TextBlock[] _stripValues = new TextBlock[3];
    private readonly TextBlock[] _stripUnits = new TextBlock[3];
    private readonly TextBlock _regionLine = new() { FontSize = 12, Foreground = Brush(Dim), HorizontalAlignment = HorizontalAlignment.Center, Margin = new Thickness(0, 6, 0, 0), MinHeight = 18, TextWrapping = TextWrapping.Wrap, TextAlignment = TextAlignment.Center };
    private readonly Button _cancelBtn = new();

    // Resultado
    private readonly TextBlock _resContext = new();
    private readonly StackPanel _resStatusRow = new() { Orientation = Orientation.Horizontal, Spacing = 8 };
    private readonly TextBlock _resStatusWord = new() { FontSize = 13, Foreground = Brush(Secondary), VerticalAlignment = VerticalAlignment.Center };
    private readonly TextBlock _resHeadline = new();
    private readonly Grid _resMetrics = new() { BorderBrush = Brush(Line), BorderThickness = new Thickness(0, 1, 0, 1), Margin = new Thickness(0, 24, 0, 0) };
    private readonly TextBlock _resRouteName = new() { FontSize = 14, TextWrapping = TextWrapping.Wrap };
    private readonly TextBlock _resRouteMs = new() { FontFamily = Res("MetricFont"), FontSize = 14 };
    private readonly RouteMapView _resultMap = new(animate: false) { CornerRadius = new CornerRadius(12) };
    private readonly Border _resultMapFrame = new() { BorderBrush = Brush(Color.FromArgb(0x14, 255, 255, 255)), BorderThickness = new Thickness(1), CornerRadius = new CornerRadius(12), Background = Brush(Color.FromArgb(255, 0x0B, 0x0D, 0x10)), Margin = new Thickness(0, 12, 0, 0) };
    private readonly Button _againBtn = new();
    private readonly Button _chooseBtn = new();
    private readonly TextBlock _evidenceLabel = new();

    public DiagnosticPage() : this(null, null, WinUiEngineComposition.Client) { }

    public DiagnosticPage(string? gameId, string? gameTitle, DiagnosticEngineClient? engine)
    {
        _gameId = gameId;
        _gameTitle = gameTitle ?? string.Empty;
        _client = engine ?? WinUiEngineComposition.Client;
        Background = Brush(Color.FromArgb(0, 0, 0, 0));
        Build();
        Loaded += OnLoaded;
        Unloaded += OnUnloaded;
        LocalizationService.Instance.LanguageChanged += OnLanguageChanged;
    }

    private bool HasGame => !string.IsNullOrWhiteSpace(_gameId);

    public void ConfigureGame(string? gameId, string? gameTitle)
    {
        if (_running) return;
        _gameId = gameId;
        _gameTitle = gameTitle ?? string.Empty;
        ResetToIdle();
    }

    private void OnLanguageChanged() => DispatcherQueue.TryEnqueue(() =>
    {
        ApplyStaticText();
        if (!_running && _flowPanel.Visibility == Visibility.Visible) ResetToIdle();
    });

    // ------------------------------------------------------------------ construção

    private static TextBlock TechLabel(string text, double size = 11, int spacing = 100) => new()
    {
        Text = text.ToUpper(CultureInfo.CurrentCulture),
        FontFamily = Res("TechnicalFont"),
        FontSize = size,
        FontWeight = FontWeights.Bold,
        CharacterSpacing = spacing,
        Foreground = Brush(Tech),
    };

    private void Build()
    {
        _idleTitle.Foreground = Brush(Primary);
        _pill.Child = _pillText;

        // Moldura 2:1 do mapa
        _mapFrame.Child = _map;
        _mapFrame.SizeChanged += (_, e) => _mapFrame.Height = Math.Max(e.NewSize.Width / 2, 120);

        // Botão Teste agora
        _startBtn.Style = (Style)Application.Current.Resources["PillPrimaryButtonStyle"];
        _startBtn.Height = 56;
        _startBtn.MinWidth = 240;
        _startBtn.Padding = new Thickness(44, 0, 44, 0);
        _startBtn.CornerRadius = new CornerRadius(14);
        _startBtn.FontSize = 17;
        _startBtn.FontWeight = FontWeights.SemiBold;
        _startBtn.CharacterSpacing = 0;
        _startBtn.HorizontalAlignment = HorizontalAlignment.Left;
        _startBtn.Click += async (_, _) => await StartAsync();
        _idleControls.Children.Add(_startBtn);

        BuildRunning();
        BuildDone();

        _flowPanel.Children.Add(_idleTitle);
        _flowPanel.Children.Add(_pill);
        _flowPanel.Children.Add(_mapFrame);
        _flowPanel.Children.Add(_idleControls);
        _flowPanel.Children.Add(_runningPanel);

        var root = new StackPanel();
        root.Children.Add(_flowPanel);
        root.Children.Add(_donePanel);
        Content = new ScrollViewer
        {
            Content = new Border { Padding = new Thickness(40, 28, 40, 56), Child = root },
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
        };

        ApplyStaticText();
        ResetToIdle();
    }

    private void BuildRunning()
    {
        _progressTrack.Children.Add(_progressFill);
        _progressTrack.SizeChanged += (_, _) => UpdateProgress(_progressRatio);
        _runningPanel.Children.Add(_progressTrack);

        var live = new TextBlock
        {
            FontFamily = Res("MetricFont"),
            FontSize = 72,
            LineHeight = 72,
            LineStackingStrategy = LineStackingStrategy.BlockLineHeight,
            HorizontalAlignment = HorizontalAlignment.Center,
            Margin = new Thickness(0, 16, 0, 0),
            Foreground = Brush(Primary),
        };
        _liveUnit.FontSize = 18;
        _liveUnit.FontFamily = Res("BodyFont");
        _liveUnit.Foreground = Brush(Dim);
        live.Inlines.Add(_liveValue);
        live.Inlines.Add(_liveUnit);
        _runningPanel.Children.Add(live);
        _runningPanel.Children.Add(_phaseName);
        _runningPanel.Children.Add(_steps);

        _strip.ColumnDefinitions.Clear();
        for (var i = 0; i < 3; i++)
        {
            _strip.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            var cell = new StackPanel { Padding = new Thickness(14, 12, 12, 12), BorderBrush = Brush(Line), BorderThickness = new Thickness(i == 0 ? 0 : 1, 0, 0, 0) };
            cell.Tag = i;
            _stripValues[i] = new TextBlock { FontFamily = Res("MetricFont"), FontSize = 26, LineHeight = 26, LineStackingStrategy = LineStackingStrategy.BlockLineHeight, Margin = new Thickness(0, 6, 0, 0), Foreground = Brush(Color.FromArgb(255, 0x63, 0x63, 0x66)), Text = "—" };
            _stripUnits[i] = new TextBlock { FontSize = 12, Foreground = Brush(Dim), VerticalAlignment = VerticalAlignment.Bottom, Margin = new Thickness(2, 0, 0, 0) };
            var valueRow = new StackPanel { Orientation = Orientation.Horizontal };
            valueRow.Children.Add(_stripValues[i]);
            valueRow.Children.Add(_stripUnits[i]);
            cell.Children.Add(new TextBlock { Tag = "label" });
            cell.Children.Add(valueRow);
            Grid.SetColumn(cell, i);
            _strip.Children.Add(cell);
        }
        _runningPanel.Children.Add(_strip);
        _runningPanel.Children.Add(_regionLine);

        _cancelBtn.Style = (Style)Application.Current.Resources["TextLinkButtonStyle"];
        _cancelBtn.Foreground = Brush(Purple);
        _cancelBtn.HorizontalAlignment = HorizontalAlignment.Center;
        _cancelBtn.Margin = new Thickness(0, 8, 0, 0);
        _cancelBtn.Click += (_, _) => CancelMeasurement();
        _runningPanel.Children.Add(_cancelBtn);
    }

    private void BuildDone()
    {
        var topGrid = new Grid { ColumnSpacing = 48, Padding = new Thickness(0, 8, 0, 28) };
        topGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1.3, GridUnitType.Star) });
        topGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(0.7, GridUnitType.Star), MinWidth = 260 });

        var left = new StackPanel();
        _resContext.FontFamily = Res("TechnicalFont");
        _resContext.FontSize = 11;
        _resContext.FontWeight = FontWeights.Bold;
        _resContext.CharacterSpacing = 100;
        _resContext.Foreground = Brush(Secondary);
        _resContext.Margin = new Thickness(0, 0, 0, 12);
        left.Children.Add(_resContext);
        left.Children.Add(_resStatusRow);
        _resHeadline.FontFamily = Res("HeadingFont");
        _resHeadline.FontSize = 46;
        _resHeadline.LineHeight = 48;
        _resHeadline.LineStackingStrategy = LineStackingStrategy.BlockLineHeight;
        _resHeadline.CharacterSpacing = -15;
        _resHeadline.TextWrapping = TextWrapping.Wrap;
        _resHeadline.MaxWidth = 560;
        _resHeadline.HorizontalAlignment = HorizontalAlignment.Left;
        _resHeadline.Margin = new Thickness(0, 12, 0, 0);
        left.Children.Add(_resHeadline);
        left.Children.Add(_resMetrics);
        topGrid.Children.Add(left);

        var right = new StackPanel { Padding = new Thickness(24, 0, 0, 0), BorderBrush = Brush(Line), BorderThickness = new Thickness(1, 0, 0, 0) };
        Grid.SetColumn(right, 1);
        _evidenceLabel.FontFamily = Res("TechnicalFont");
        _evidenceLabel.FontSize = 11;
        _evidenceLabel.FontWeight = FontWeights.Bold;
        _evidenceLabel.CharacterSpacing = 100;
        _evidenceLabel.Foreground = Brush(Tech);
        right.Children.Add(_evidenceLabel);
        _resultMapFrame.Child = _resultMap;
        _resultMapFrame.SizeChanged += (_, e) => _resultMapFrame.Height = Math.Max(e.NewSize.Width * 10 / 16, 120);
        right.Children.Add(_resultMapFrame);
        var routeRow = new Grid { Margin = new Thickness(0, 12, 0, 0), ColumnSpacing = 12 };
        routeRow.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        routeRow.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        Grid.SetColumn(_resRouteMs, 1);
        routeRow.Children.Add(_resRouteName);
        routeRow.Children.Add(_resRouteMs);
        right.Children.Add(routeRow);
        topGrid.Children.Add(right);
        _donePanel.Children.Add(topGrid);

        var actions = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 20, Margin = new Thickness(0, 24, 0, 0) };
        _againBtn.Style = (Style)Application.Current.Resources["PillPrimaryButtonStyle"];
        _againBtn.MinHeight = 50;
        _againBtn.Height = 50;
        _againBtn.Padding = new Thickness(28, 0, 28, 0);
        _againBtn.CornerRadius = new CornerRadius(14);
        _againBtn.FontSize = 17;
        _againBtn.FontWeight = FontWeights.SemiBold;
        _againBtn.CharacterSpacing = 0;
        _againBtn.Click += async (_, _) => await StartAsync();
        _chooseBtn.Style = (Style)Application.Current.Resources["TextLinkButtonStyle"];
        _chooseBtn.Padding = new Thickness(0);
        _chooseBtn.Click += (_, _) => ShellNavigation.Navigate(NavigationRoute.Library);
        actions.Children.Add(_againBtn);
        actions.Children.Add(_chooseBtn);
        _donePanel.Children.Add(actions);
    }

    private void ApplyStaticText()
    {
        _startBtn.Content = Strings.Tr("Teste agora");
        _cancelBtn.Content = Strings.Tr("Cancelar");
        _againBtn.Content = Strings.Tr("Testar novamente");
        _chooseBtn.Content = HasGame ? Strings.Tr("Escolher outro jogo") : Strings.Tr("Escolher um jogo");
        _evidenceLabel.Text = Strings.Tr("EVIDÊNCIA DE ROTA");

        var labels = new[] { Strings.Tr("RESPOSTA"), Strings.Tr("JITTER"), Strings.Tr("SOB CARGA") };
        for (var i = 0; i < 3; i++)
        {
            var cell = _strip.Children.OfType<StackPanel>().First(panel => (int)panel.Tag == i);
            var label = cell.Children.OfType<TextBlock>().First(text => Equals(text.Tag, "label"));
            label.Text = labels[i];
            label.FontFamily = Res("TechnicalFont");
            label.FontSize = 11;
            label.FontWeight = FontWeights.Bold;
            label.CharacterSpacing = 100;
            label.Foreground = Brush(Tech);
        }

        _steps.Children.Clear();
        var stepLabels = new[] { Strings.Tr("Conexão"), Strings.Tr("LATÊNCIA").ToLower(CultureInfo.CurrentCulture), Strings.Tr("SOB CARGA").ToLower(CultureInfo.CurrentCulture), Strings.Tr("ANÁLISE").ToLower(CultureInfo.CurrentCulture) };
        stepLabels[0] = stepLabels[0];
        for (var i = 0; i < 4; i++)
        {
            var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6 };
            row.Children.Add(new Ellipse { Width = 8, Height = 8, Fill = Brush(Color.FromArgb(255, 0x48, 0x48, 0x4A)), VerticalAlignment = VerticalAlignment.Center });
            row.Children.Add(new TextBlock { Text = Capitalize(stepLabels[i]), FontSize = 13, Foreground = Brush(Color.FromArgb(255, 0x63, 0x63, 0x66)) });
            _steps.Children.Add(row);
        }
    }

    private static string Capitalize(string text) => string.IsNullOrEmpty(text) ? text : char.ToUpper(text[0], CultureInfo.CurrentCulture) + text[1..];

    // ------------------------------------------------------------------ ciclo de vida

    private async void OnLoaded(object sender, RoutedEventArgs e)
    {
        Loaded -= OnLoaded;
        try
        {
            _location = await _client.GetApproximateLocationAsync();
        }
        catch
        {
            _location = null;
        }
        ApplyLocation(_map);
        ApplyLocation(_resultMap);
    }

    private void ApplyLocation(RouteMapView map)
    {
        if (_location is { Enabled: true, HasCoordinates: true } location) map.SetUser(location.Latitude, location.Longitude, location.City);
        else map.SetUser(null, null, null);
    }

    private async void OnUnloaded(object sender, RoutedEventArgs e)
    {
        LocalizationService.Instance.LanguageChanged -= OnLanguageChanged;
        _measurementCts?.Cancel();
        if (_running)
        {
            try { await _client.CancelAsync(); }
            catch { /* cancelado no host */ }
        }
    }

    // ------------------------------------------------------------------ estados

    private void ResetToIdle()
    {
        _running = false;
        ShellChrome.Shell?.ClearBackdrop();
        _flowPanel.Visibility = Visibility.Visible;
        _donePanel.Visibility = Visibility.Collapsed;
        _idleControls.Visibility = Visibility.Visible;
        _runningPanel.Visibility = Visibility.Collapsed;
        _idleTitle.Visibility = Visibility.Visible;
        _idleTitle.Text = (HasGame ? _gameTitle : Strings.Tr("Diagnóstico de Conexão")).ToUpper(CultureInfo.CurrentCulture);
        _pill.Visibility = Visibility.Collapsed;
        _chooseBtn.Content = HasGame ? Strings.Tr("Escolher outro jogo") : Strings.Tr("Escolher um jogo");
        _map.Reset();
        UpdateProgress(0);
    }

    private double _progressRatio;

    private void UpdateProgress(double ratio)
    {
        _progressRatio = ratio;
        _progressFill.Width = Math.Max(0, _progressTrack.ActualWidth * Math.Clamp(ratio, 0, 1));
    }

    private void SetStage(int stage)
    {
        for (var i = 0; i < _steps.Children.Count; i++)
        {
            var row = (StackPanel)_steps.Children[i];
            var dot = (Ellipse)row.Children[0];
            var text = (TextBlock)row.Children[1];
            var current = i == stage;
            var done = i < stage;
            dot.Fill = Brush(current ? Color.FromArgb(255, 0x8B, 0x5C, 0xF6) : done ? Color.FromArgb(255, 0x22, 0xC5, 0x5E) : Color.FromArgb(255, 0x48, 0x48, 0x4A));
            text.Foreground = Brush(current ? Colors.White : done ? Color.FromArgb(255, 0xEB, 0xEB, 0xF5) : Color.FromArgb(255, 0x63, 0x63, 0x66));
        }
    }

    private async Task StartAsync()
    {
        if (_running) return;
        _running = true;
        _lastRestPing = double.NaN;
        ShellChrome.Shell?.ClearBackdrop();

        _flowPanel.Visibility = Visibility.Visible;
        _donePanel.Visibility = Visibility.Collapsed;
        _idleControls.Visibility = Visibility.Collapsed;
        _idleTitle.Visibility = Visibility.Collapsed;
        _runningPanel.Visibility = Visibility.Visible;
        if (HasGame)
        {
            _pillText.Text = Strings.Format("{0} · Competitivo", _gameTitle);
            _pill.Visibility = Visibility.Visible;
        }
        else
        {
            _pill.Visibility = Visibility.Collapsed;
        }

        UpdateProgress(0.02);
        _liveValue.Text = "—";
        _liveUnit.Text = string.Empty;
        for (var i = 0; i < 3; i++) { _stripValues[i].Text = "—"; _stripValues[i].Foreground = Brush(Color.FromArgb(255, 0x63, 0x63, 0x66)); _stripUnits[i].Text = string.Empty; }
        SetStage(0);
        ApplyPhase("connect");
        _regionLine.Text = Strings.Tr("Enviando sondas a todos os servidores…");
        _map.Reset();
        ApplyLocation(_map);
        _map.StartSweep();

        _measurementCts = new CancellationTokenSource();
        void ProgressHandler(object? sender, DiagnosticProgress p) => DispatcherQueue.TryEnqueue(() => OnEngineProgress(p));
        _client.ProgressChanged += ProgressHandler;

        try
        {
            var result = await _client.StartAsync(_gameId, _measurementCts.Token);
            await ShowResultAsync(result);
        }
        catch (OperationCanceledException)
        {
            ResetToIdle();
        }
        catch (DiagnosticEngineException dex) when (dex.Code == "CANCELLED")
        {
            ResetToIdle();
        }
        catch
        {
            ShowInconclusive();
        }
        finally
        {
            _client.ProgressChanged -= ProgressHandler;
            _running = false;
        }
    }

    private async void CancelMeasurement()
    {
        _measurementCts?.Cancel();
        try { await _client.CancelAsync(); }
        catch { /* cancelado no host */ }
    }

    private void ApplyPhase(string phase)
    {
        var (stage, name) = phase.ToLowerInvariant() switch
        {
            "connect" => (0, Strings.Tr("CONECTANDO")),
            "rest" => (1, Strings.Tr("LATÊNCIA")),
            "load" => (2, Strings.Tr("SOB CARGA")),
            "analysis" => (3, Strings.Tr("ANALISANDO")),
            _ => (0, Strings.Tr("CONECTANDO")),
        };
        _phaseName.Text = name.ToUpper(CultureInfo.CurrentCulture);
        _phaseName.Foreground = Brush(StageColors[stage]);
        SetStage(stage);
    }

    private void OnEngineProgress(DiagnosticProgress progress)
    {
        if (!_running) return;
        UpdateProgress(progress.Ratio);
        var phase = progress.Phase.ToLowerInvariant();
        ApplyPhase(phase);

        _regionLine.Text = phase switch
        {
            "connect" => Strings.Tr("Enviando sondas a todos os servidores…"),
            "rest" => progress.Ratio < 0.32 ? Strings.Tr("Testando os reflexos da sua rede.") : HasGame ? Strings.Format("Cada milissegundo conta em {0}.", _gameTitle) : Strings.Tr("Cada milissegundo conta em jogos competitivos."),
            "load" => progress.Ratio < 0.72 ? Strings.Tr("Enchendo a fila para ver se a rede aguenta a pressão.") : Strings.Tr("Simulando aquela luta final com a casa inteira online."),
            "analysis" => HasGame ? Strings.Format("Comparando com o que {0} exige.", _gameTitle) : Strings.Tr("Comparando com o que jogos competitivos exigem."),
            _ => string.Empty,
        };
        if (phase != "connect") _map.PulseSweep();

        if (progress.LatestPingMs is { } ping && phase is "rest" or "load")
        {
            _liveValue.Text = ping.ToString("0", CultureInfo.CurrentCulture);
            _liveUnit.Text = " ms";
            _map.Probe(ping);
            if (phase == "rest") _lastRestPing = ping;
        }
        if (!double.IsNaN(_lastRestPing)) SetStrip(0, _lastRestPing.ToString("0", CultureInfo.CurrentCulture), "ms");
        if (progress.LiveJitterMs is { } jitter) SetStrip(1, jitter.ToString("0.#", CultureInfo.CurrentCulture), "ms");
        if (progress.LiveLoadDeltaMs is { } delta) SetStrip(2, "+" + delta.ToString("0.#", CultureInfo.CurrentCulture), "ms");
    }

    private void SetStrip(int index, string value, string unit)
    {
        _stripValues[index].Text = value;
        _stripValues[index].Foreground = Brush(Colors.White);
        _stripUnits[index].Text = unit;
    }

    // ------------------------------------------------------------------ resultado

    // Cores por métrica (ênfase visual do v2). O veredito em si continua sendo o do motor.
    private static Color MetricColor(double value, double okLimit, double warnLimit) =>
        value <= okLimit ? Verdicts.ColorOf(VerdictTone.Ok) : value <= warnLimit ? Verdicts.ColorOf(VerdictTone.Warn) : Verdicts.ColorOf(VerdictTone.Bad);

    private void FillMetricGrid((string Label, string Value, string Unit, Color Color)[] metrics)
    {
        _resMetrics.ColumnDefinitions.Clear();
        _resMetrics.Children.Clear();
        for (var i = 0; i < metrics.Length; i++)
        {
            _resMetrics.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            var cell = new StackPanel { Padding = new Thickness(16, 16, 12, 16), BorderBrush = Brush(Line), BorderThickness = new Thickness(i == 0 ? 0 : 1, 0, 0, 0) };
            cell.Children.Add(new TextBlock
            {
                Text = metrics[i].Label.ToUpper(CultureInfo.CurrentCulture),
                FontFamily = Res("TechnicalFont"),
                FontSize = 11,
                FontWeight = FontWeights.Bold,
                CharacterSpacing = 60,
                Foreground = Brush(Tech),
                MinHeight = 28.6,
                LineHeight = 14.3,
                LineStackingStrategy = LineStackingStrategy.BlockLineHeight,
                TextWrapping = TextWrapping.Wrap,
            });
            var value = new TextBlock { FontFamily = Res("MetricFont"), FontSize = 32, LineHeight = 32, LineStackingStrategy = LineStackingStrategy.BlockLineHeight, Foreground = Brush(metrics[i].Color), Margin = new Thickness(0, 8, 0, 0), TextWrapping = TextWrapping.NoWrap };
            value.Inlines.Add(new Run { Text = metrics[i].Value });
            if (!string.IsNullOrEmpty(metrics[i].Unit)) value.Inlines.Add(new Run { Text = " " + metrics[i].Unit, FontSize = 12, FontFamily = Res("BodyFont"), FontWeight = FontWeights.SemiBold, Foreground = Brush(Secondary) });
            cell.Children.Add(value);
            Grid.SetColumn(cell, i);
            _resMetrics.Children.Add(cell);
        }
    }

    private async Task ShowResultAsync(DiagnosticResult result)
    {
        // Sem veredito medido (inconclusivo) não há nota nem métrica inventada.
        if (result.Verdict is null or "inconclusive" || result.PingMs is null)
        {
            ShowInconclusive();
            return;
        }

        var tone = Verdicts.ToneOf(result.Verdict);
        var ping = result.PingMs.Value;
        var secondary = Brush(Secondary);
        FillMetricGrid(new[]
        {
            (Strings.Tr("RESPOSTA"), ping.ToString("0", CultureInfo.CurrentCulture), "ms", MetricColor(ping, 45, 90)),
            (Strings.Tr("JITTER"), result.JitterMs is { } j ? j.ToString("0.#", CultureInfo.CurrentCulture) : "—", result.JitterMs is null ? string.Empty : "ms", result.JitterMs is { } jv ? MetricColor(jv, 8, 20) : Secondary),
            (Strings.Tr("SOB CARGA"), result.LoadDeltaMs is { } d ? "+" + d.ToString("0.#", CultureInfo.CurrentCulture) : "—", result.LoadDeltaMs is null ? string.Empty : "ms", result.LoadDeltaMs is { } dv ? MetricColor(dv, 15, 40) : Secondary),
            (Strings.Tr("PERDA"), result.PacketLossPercentage is { } l ? l.ToString("0.#", CultureInfo.CurrentCulture) : "—", result.PacketLossPercentage is null ? string.Empty : "%", result.PacketLossPercentage is { } lv ? MetricColor(lv, 0.5, 2) : Secondary),
        });

        _resContext.Visibility = HasGame ? Visibility.Visible : Visibility.Collapsed;
        _resContext.Text = HasGame ? $"{_gameTitle.ToUpper(CultureInfo.CurrentCulture)} · {Strings.Tr("COMPETITIVO")}" : string.Empty;
        _resStatusRow.Children.Clear();
        _resStatusRow.Children.Add(Verdicts.Marker(tone));
        _resStatusWord.Text = Verdicts.StatusWord(tone);
        _resStatusRow.Children.Add(_resStatusWord);
        _resHeadline.Text = Verdicts.Headline(tone, HasGame);
        _resHeadline.Foreground = Brush(Primary);

        var region = RegionCatalog.Find(result.RegionId);
        _resRouteName.Text = region is not null ? $"{region.Name} ({region.Id})" : Strings.Tr("Região de referência");
        _resRouteMs.Text = ping.ToString("0", CultureInfo.CurrentCulture) + " ms";
        _resRouteName.Foreground = Brush(Primary);
        _resRouteMs.Foreground = Brush(Primary);

        _flowPanel.Visibility = Visibility.Collapsed;
        _donePanel.Visibility = Visibility.Visible;
        _chooseBtn.Content = HasGame ? Strings.Tr("Escolher outro jogo") : Strings.Tr("Escolher um jogo");

        ApplyLocation(_resultMap);
        _resultMap.Reset();
        if (region is not null) _resultMap.SelectRegion(region.Id, ping);
        await ApplyGameBackdropAsync();
    }

    private void ShowInconclusive()
    {
        FillMetricGrid(new[]
        {
            (Strings.Tr("RESPOSTA"), "—", string.Empty, Secondary),
            (Strings.Tr("JITTER"), "—", string.Empty, Secondary),
            (Strings.Tr("SOB CARGA"), "—", string.Empty, Secondary),
            (Strings.Tr("PERDA"), "—", string.Empty, Secondary),
        });
        _resContext.Visibility = Visibility.Collapsed;
        _resStatusRow.Children.Clear();
        _resStatusRow.Children.Add(Verdicts.Marker(VerdictTone.Unknown));
        _resStatusWord.Text = Strings.Tr("— Medição inconclusiva");
        _resStatusRow.Children.Add(_resStatusWord);
        _resHeadline.Text = Strings.Tr("Não foi possível concluir");
        _resHeadline.Foreground = Brush(Primary);
        _resRouteName.Text = string.Empty;
        _resRouteMs.Text = string.Empty;
        _flowPanel.Visibility = Visibility.Collapsed;
        _donePanel.Visibility = Visibility.Visible;
        _resultMap.Reset();
        ApplyLocation(_resultMap);
    }

    /// <summary>Resultado de um jogo ganha a arte oficial atrás da janela (véu escuro), como no v2.</summary>
    private async Task ApplyGameBackdropAsync()
    {
        if (!HasGame) return;
        try
        {
            var snapshot = await LibraryPageServices.Bridge.GetSnapshotAsync();
            var game = snapshot.Games.FirstOrDefault(item => string.Equals(item.DiagnosticGameId, _gameId, StringComparison.OrdinalIgnoreCase));
            if (Artwork.FirstExisting(game?.HeroArtworkPath) is { } art && _donePanel.Visibility == Visibility.Visible)
                ShellChrome.Shell?.SetBackdrop(new[] { art }, BackdropKind.Veil);
        }
        catch
        {
            // Sem arte local, o resultado permanece sobre o fundo sólido.
        }
    }
}
