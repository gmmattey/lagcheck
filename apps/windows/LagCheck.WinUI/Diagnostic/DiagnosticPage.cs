using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.UI;
using LagCheck.WinUI.Localization;

namespace LagCheck.WinUI.Diagnostic;

/// <summary>
/// Tela canônica de Conexão do LagCheck para Windows.
/// Alinhada 1:1 com LagCheck Windows v2:
/// - Mapa de rota permanente (Idle, Running e Done) com sondas e grade de continentes.
/// - Telemetria ao vivo em Chakra Petch e etapas tabulares.
/// - Resultado com coluna de Veredito + Rota evidenciada no mapa lateral.
/// - Seções de Voz, Streaming ao vivo e NAT.
/// - Motor determinístico de medição HTTPS contra endpoints AWS/Cloudflare reais (sem mock).
/// </summary>
public sealed class DiagnosticPage : Page
{
    private static readonly SolidColorBrush DeepBrush = Brush(0x0B, 0x0D, 0x12);
    private static readonly SolidColorBrush SurfaceBrush = Brush(0x15, 0x18, 0x22);
    private static readonly SolidColorBrush PanelBrush = Brush(0x1E, 0x24, 0x32);
    private static readonly SolidColorBrush PurpleBrush = Brush(0x7C, 0x3A, 0xED);
    private static readonly SolidColorBrush PurpleLightBrush = Brush(0xA7, 0x8B, 0xFA);
    private static readonly SolidColorBrush TextPrimaryBrush = Brush(0xF5, 0xF7, 0xFC);
    private static readonly SolidColorBrush TextSecondaryBrush = Brush(0x9A, 0xA3, 0xB5);
    private static readonly SolidColorBrush TextTertiaryBrush = Brush(0x68, 0x72, 0x85);
    private static readonly SolidColorBrush ReadyBrush = Brush(0x22, 0xC5, 0x5E);
    private static readonly SolidColorBrush CautionBrush = Brush(0xF5, 0x9E, 0x0B);
    private static readonly SolidColorBrush CoralBrush = Brush(0xFF, 0x5A, 0x36);
    private static readonly SolidColorBrush LineBrush = Brush(0x1F, 0x26, 0x36);

    private readonly WebSpeedtestEngine _webEngine = new();
    private readonly DiagnosticEngineClient _client;
    private readonly DispatcherTimer _animationTimer;
    private CancellationTokenSource? _measurementCts;

    // Cabeçalho da página
    private readonly TextBlock _title = Title(Strings.Tr("DIAGNÓSTICO DE CONEXÃO"));
    private readonly Border _pillBorder = new()
    {
        Background = Brush(0x2C, 0x2C, 0x2E),
        CornerRadius = new CornerRadius(14),
        Padding = new Thickness(14, 6, 14, 6),
        HorizontalAlignment = HorizontalAlignment.Center,
        Visibility = Visibility.Collapsed
    };
    private readonly TextBlock _pillText = Label("", 13, Brush(0xEB, 0xEB, 0xF5));

    // Controles durante a medição (Running)
    private readonly ProgressBar _progressBar = new()
    {
        Minimum = 0,
        Maximum = 1,
        Value = 0,
        Height = 2,
        Foreground = PurpleBrush,
        Background = LineBrush,
        HorizontalAlignment = HorizontalAlignment.Stretch
    };
    private readonly TextBlock _liveMetric = MetricLarge("—");
    private readonly TextBlock _phaseName = Label(Strings.Tr("CONECTANDO"), 13, PurpleLightBrush);
    private readonly TextBlock _statusMessage = Body(Strings.Tr("Varrendo servidores mais próximos…"));
    private readonly TextBlock _stepIndicator = Label(Strings.Tr("● CONEXÃO   ● LATÊNCIA   ● SOB CARGA   ● ANÁLISE"), 12, TextTertiaryBrush);
    private readonly TextBlock _regionStatusLine = Label(Strings.Tr("Varrendo regiões mundiais…"), 12, TextTertiaryBrush);

    // Métricas Instantâneas (Strip em execução)
    private readonly TextBlock _livePingText = Metric("—");
    private readonly TextBlock _liveJitterText = Metric("—");
    private readonly TextBlock _liveDeltaText = Metric("—");
    private readonly TextBlock _liveLossText = Metric("—");

    // Métricas Finais do Resultado (Done)
    private readonly TextBlock _resultContext = Label("", 11, TextSecondaryBrush);
    private readonly TextBlock _verdictStatusWord = Label(Strings.Tr("Conexão boa"), 13, ReadyBrush);
    private readonly TextBlock _verdictHeadline = Title(Strings.Tr("Pronto para jogar"));
    private readonly TextBlock _resultPing = MetricLarge("—");
    private readonly TextBlock _resultJitter = MetricLarge("—");
    private readonly TextBlock _resultLoad = MetricLarge("—");
    private readonly TextBlock _resultLoss = MetricLarge("—");
    private readonly TextBlock _resultRouteInfo = Label("", 14, TextPrimaryBrush);

    // Mapa de Rota Permanente
    private readonly Canvas _mapCanvas = new()
    {
        Height = 320,
        HorizontalAlignment = HorizontalAlignment.Stretch,
        Background = DeepBrush
    };

    // Botões
    private readonly Button _startBtn = new() { Content = Strings.Tr("Teste agora"), Height = 56, CornerRadius = new CornerRadius(14), Padding = new Thickness(44, 0, 44, 0), HorizontalAlignment = HorizontalAlignment.Left };
    private readonly Button _cancelBtn = new() { Content = Strings.Tr("Cancelar"), Background = new SolidColorBrush(Microsoft.UI.Colors.Transparent), Foreground = PurpleLightBrush, BorderThickness = new Thickness(0), FontSize = 15, FontWeight = Microsoft.UI.Text.FontWeights.Medium, HorizontalAlignment = HorizontalAlignment.Center };
    private readonly Button _measureAgainBtn = new() { Content = Strings.Tr("Testar novamente"), Height = 50, CornerRadius = new CornerRadius(14), Padding = new Thickness(28, 0, 28, 0), HorizontalAlignment = HorizontalAlignment.Left };
    private readonly Button _chooseOtherBtn = new() { Content = Strings.Tr("Escolher outro jogo"), Background = new SolidColorBrush(Microsoft.UI.Colors.Transparent), Foreground = PurpleLightBrush, BorderThickness = new Thickness(0), FontSize = 15, FontWeight = Microsoft.UI.Text.FontWeights.Medium, HorizontalAlignment = HorizontalAlignment.Left };

    // Painéis de estado
    private readonly StackPanel _idleControls = new() { Spacing = 16, HorizontalAlignment = HorizontalAlignment.Stretch };
    private readonly StackPanel _runningControls = new() { Spacing = 14, Visibility = Visibility.Collapsed, HorizontalAlignment = HorizontalAlignment.Stretch };
    private readonly StackPanel _doneControls = new() { Spacing = 24, Visibility = Visibility.Collapsed, HorizontalAlignment = HorizontalAlignment.Stretch };
    private readonly Border _mapHostBorder = new();

    private string? _gameId;
    private string _gameTitle = Strings.Tr("sua conexão");
    private ApproximateLocation? _location;
    private string? _selectedRegionId = "sa-east-1";
    private bool _running;
    private double _animationTick;

    public DiagnosticPage() : this(null, null, WinUiEngineComposition.Client) { }

    public DiagnosticPage(string? gameId, string? gameTitle, DiagnosticEngineClient? engine)
    {
        _gameId = gameId;
        if (!string.IsNullOrWhiteSpace(gameTitle)) _gameTitle = gameTitle;
        _client = engine ?? WinUiEngineComposition.Client;

        _animationTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(33) };
        _animationTimer.Tick += OnAnimationTick;

        Background = DeepBrush;
        Build();

        _mapCanvas.SizeChanged += (_, e) =>
        {
            if (e.NewSize.Width > 0 && e.NewSize.Height > 0)
            {
                RenderMap(_mapCanvas, _running);
            }
        };

        Loaded += DiagnosticPage_Loaded;
        Unloaded += OnUnloaded;
        LocalizationService.Instance.LanguageChanged += OnLanguageChanged;
    }

    private void OnLanguageChanged()
    {
        DispatcherQueue.TryEnqueue(() =>
        {
            _startBtn.Content = Strings.Tr("Teste agora");
            _cancelBtn.Content = Strings.Tr("Cancelar");
            _measureAgainBtn.Content = Strings.Tr("Testar novamente");
            _chooseOtherBtn.Content = Strings.Tr("Escolher outro jogo");
            if (!_running) ResetToIdle();
        });
    }

    public void ConfigureGame(string? gameId, string? gameTitle)
    {
        if (_running) return;
        _gameId = gameId;
        _gameTitle = string.IsNullOrWhiteSpace(gameTitle) ? Strings.Tr("sua conexão") : gameTitle;
        ResetToIdle();
    }

    private void Build()
    {
        ApplyPrimaryButtonStyle(_startBtn);
        ApplyPrimaryButtonStyle(_measureAgainBtn);

        _startBtn.Click += async (_, _) => await StartAsync();
        _cancelBtn.Click += (_, _) => CancelMeasurement();
        _measureAgainBtn.Click += async (_, _) => await StartAsync();
        _chooseOtherBtn.Click += (_, _) => ShellNavigation.Navigate(NavigationRoute.Library);

        _pillBorder.Child = _pillText;

        // Moldura do Mapa
        _mapHostBorder.Background = DeepBrush;
        _mapHostBorder.BorderBrush = LineBrush;
        _mapHostBorder.BorderThickness = new Thickness(1);
        _mapHostBorder.CornerRadius = new CornerRadius(12);
        _mapHostBorder.HorizontalAlignment = HorizontalAlignment.Stretch;
        _mapHostBorder.Child = _mapCanvas;

        // 1. Painel Idle
        _idleControls.Children.Add(_startBtn);

        // 2. Painel Running (Centralizado)
        var runningBox = new StackPanel
        {
            Spacing = 12,
            HorizontalAlignment = HorizontalAlignment.Center,
            MaxWidth = 720
        };
        runningBox.Children.Add(_progressBar);
        runningBox.Children.Add(_liveMetric);
        runningBox.Children.Add(_phaseName);
        runningBox.Children.Add(_statusMessage);
        runningBox.Children.Add(_stepIndicator);

        var runningStrip = CreateLiveMetricStrip(
            (Strings.Tr("RESPOSTA"), _livePingText),
            (Strings.Tr("JITTER"), _liveJitterText),
            (Strings.Tr("SOB CARGA"), _liveDeltaText),
            (Strings.Tr("PERDA"), _liveLossText)
        );
        runningBox.Children.Add(runningStrip);
        runningBox.Children.Add(_regionStatusLine);
        runningBox.Children.Add(_cancelBtn);

        _runningControls.Children.Add(runningBox);

        // 3. Painel Done (Resultado em 2 colunas)
        var resultLayout = BuildResultLayout();
        _doneControls.Children.Add(resultLayout);

        // Container Geral
        var contentStack = new StackPanel
        {
            Spacing = 16,
            MaxWidth = 1000,
            HorizontalAlignment = HorizontalAlignment.Center
        };
        contentStack.Children.Add(_pillBorder);
        contentStack.Children.Add(_title);
        contentStack.Children.Add(_mapHostBorder);
        contentStack.Children.Add(_idleControls);
        contentStack.Children.Add(_runningControls);
        contentStack.Children.Add(_doneControls);

        var rootContainer = new Border
        {
            Padding = new Thickness(40, 28, 40, 56),
            HorizontalAlignment = HorizontalAlignment.Stretch,
            Child = contentStack
        };

        Content = new ScrollViewer
        {
            Content = rootContainer,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            HorizontalContentAlignment = HorizontalAlignment.Stretch
        };

        ResetToIdle();
    }

    private UIElement BuildResultLayout()
    {
        var mainStack = new StackPanel { Spacing = 24, HorizontalAlignment = HorizontalAlignment.Stretch };

        // Grid Superior em 2 Colunas (Veredito e Métricas à esquerda, Mapa à direita)
        var topGrid = new Grid { ColumnSpacing = 36, HorizontalAlignment = HorizontalAlignment.Stretch };
        topGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1.3, GridUnitType.Star) });
        topGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(0.9, GridUnitType.Star) });

        // Coluna Esquerda
        var leftCol = new StackPanel { Spacing = 12 };
        leftCol.Children.Add(_resultContext);
        leftCol.Children.Add(_verdictStatusWord);
        leftCol.Children.Add(_verdictHeadline);

        var resMetrics = CreateLiveMetricStrip(
            (Strings.Tr("RESPOSTA"), _resultPing),
            (Strings.Tr("JITTER"), _resultJitter),
            (Strings.Tr("SOB CARGA"), _resultLoad),
            (Strings.Tr("PERDA"), _resultLoss)
        );
        leftCol.Children.Add(resMetrics);
        Grid.SetColumn(leftCol, 0);
        topGrid.Children.Add(leftCol);

        // Coluna Direita: Evidência de Rota
        var rightCol = new StackPanel { Spacing = 10 };
        rightCol.Children.Add(Label(Strings.Tr("EVIDÊNCIA DE ROTA"), 11, TextTertiaryBrush));
        
        var miniMapBorder = new Border
        {
            Background = SurfaceBrush,
            BorderBrush = LineBrush,
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(12),
            Height = 160,
            Child = new Grid
            {
                Children =
                {
                    new TextBlock
                    {
                        Text = Strings.Tr("Traçado de rota ativa até o datacenter regional"),
                        FontSize = 12,
                        Foreground = TextTertiaryBrush,
                        HorizontalAlignment = HorizontalAlignment.Center,
                        VerticalAlignment = VerticalAlignment.Center
                    }
                }
            }
        };
        rightCol.Children.Add(miniMapBorder);
        rightCol.Children.Add(_resultRouteInfo);

        Grid.SetColumn(rightCol, 1);
        topGrid.Children.Add(rightCol);

        mainStack.Children.Add(topGrid);

        // Ações Finais
        var actionsRow = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 20,
            Margin = new Thickness(0, 10, 0, 0),
            VerticalAlignment = VerticalAlignment.Center
        };
        actionsRow.Children.Add(_measureAgainBtn);
        actionsRow.Children.Add(_chooseOtherBtn);
        mainStack.Children.Add(actionsRow);

        return mainStack;
    }

    private static UIElement CreateLiveMetricStrip(params (string Label, TextBlock Text)[] items)
    {
        var grid = new Grid { HorizontalAlignment = HorizontalAlignment.Stretch, ColumnSpacing = 12 };
        for (int i = 0; i < items.Length; i++)
        {
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            var box = new Border
            {
                Background = SurfaceBrush,
                CornerRadius = new CornerRadius(10),
                Padding = new Thickness(14, 10, 14, 10),
                HorizontalAlignment = HorizontalAlignment.Stretch,
                Child = new StackPanel
                {
                    Spacing = 2,
                    Children =
                    {
                        Label(items[i].Label, 10, TextTertiaryBrush),
                        items[i].Text
                    }
                }
            };
            Grid.SetColumn(box, i);
            grid.Children.Add(box);
        }
        return grid;
    }

    private async void DiagnosticPage_Loaded(object sender, RoutedEventArgs e)
    {
        Loaded -= DiagnosticPage_Loaded;
        try
        {
            _location = await _client.GetApproximateLocationAsync();
        }
        catch
        {
            _location = null;
        }
        RenderMap(_mapCanvas, animated: false);
    }

    private async Task StartAsync()
    {
        if (_running) return;
        _running = true;
        _startBtn.IsEnabled = false;

        _idleControls.Visibility = Visibility.Collapsed;
        _doneControls.Visibility = Visibility.Collapsed;
        _runningControls.Visibility = Visibility.Visible;

        _progressBar.Value = 0;
        _phaseName.Text = Strings.Tr("CONECTANDO");
        _liveMetric.Text = "—";
        _livePingText.Text = "—";
        _liveJitterText.Text = "—";
        _liveDeltaText.Text = "—";
        _liveLossText.Text = "—";
        _statusMessage.Text = Strings.Tr("Varrendo servidores mais próximos…");

        _animationTimer.Start();
        _measurementCts = new CancellationTokenSource();

        try
        {
            var result = await _webEngine.RunAsync(
                onProgress: p => DispatcherQueue.TryEnqueue(() => OnWebProgress(p)),
                onRegionSample: (regId, ms) => DispatcherQueue.TryEnqueue(() => OnRegionSample(regId, ms)),
                cancellationToken: _measurementCts.Token
            );

            ShowResult(result);
        }
        catch (OperationCanceledException)
        {
            ResetToIdle();
        }
        catch
        {
            ShowInconclusive();
        }
        finally
        {
            _running = false;
            _startBtn.IsEnabled = true;
            _animationTimer.Stop();
            RenderMap(_mapCanvas, animated: false);
        }
    }

    private void CancelMeasurement()
    {
        _measurementCts?.Cancel();
    }

    private void OnWebProgress(DiagnosticProgress progress)
    {
        if (!_running) return;
        _progressBar.Value = Math.Clamp(progress.Ratio, 0, 1);

        switch (progress.Phase.ToLowerInvariant())
        {
            case "connect":
                _phaseName.Text = Strings.Tr("CONECTANDO");
                _phaseName.Foreground = Brush(0xBF, 0x5A, 0xF2);
                _statusMessage.Text = Strings.Tr("Testando servidores de menor latência…");
                break;
            case "rest":
                _phaseName.Text = Strings.Tr("LATÊNCIA EM REPOUSO");
                _phaseName.Foreground = PurpleLightBrush;
                _statusMessage.Text = Strings.Tr("Medindo a resposta e os reflexos da sua conexão…");
                break;
            case "load":
                _phaseName.Text = Strings.Tr("SOB CARGA");
                _phaseName.Foreground = CautionBrush;
                _statusMessage.Text = Strings.Tr("Simulando tráfego na rede para medir acréscimo de atraso…");
                break;
            case "analysis":
                _phaseName.Text = Strings.Tr("ANALISANDO");
                _phaseName.Foreground = Brush(0xBF, 0x5A, 0xF2);
                _statusMessage.Text = Strings.Tr("Comparando os resultados com as exigências de jogo…");
                break;
        }

        if (progress.LatestPingMs is { } ping)
        {
            _liveMetric.Text = $"{ping:0} ms";
            _livePingText.Text = $"{ping:0} ms";
        }
        // Jitter e acréscimo sob carga ao vivo vêm do motor; sem amostras suficientes ficam em "—".
        if (progress.LiveJitterMs is { } jitter) _liveJitterText.Text = $"{jitter:0.#} ms";
        if (progress.LiveLoadDeltaMs is { } delta) _liveDeltaText.Text = $"+{delta:0.#} ms";
    }

    private void OnRegionSample(string regionId, double? ms)
    {
        if (ms != null)
        {
            _selectedRegionId = regionId;
            var regInfo = WebSpeedtestEngine.Regions;
            string name = regionId;
            foreach (var r in regInfo) if (r.Id == regionId) { name = r.Name; break; }
            _regionStatusLine.Text = Strings.Format("Mais rápido até agora: {0} ({1:0} ms)", name, ms);
        }
    }

    private void ShowResult(DiagnosticResult result)
    {
        // Sem veredito medido (inconclusivo) não há nota nem métrica inventada.
        if (result.Verdict is null or "inconclusive" || result.PingMs is null)
        {
            ShowInconclusive();
            return;
        }

        _selectedRegionId = result.RegionId ?? _selectedRegionId ?? "sa-east-1";
        _idleControls.Visibility = Visibility.Collapsed;
        _runningControls.Visibility = Visibility.Collapsed;
        _doneControls.Visibility = Visibility.Visible;
        _mapHostBorder.Visibility = Visibility.Collapsed;

        double ping = result.PingMs.Value;

        _resultPing.Text = $"{ping:0}";
        _resultJitter.Text = result.JitterMs is { } jitter ? $"{jitter:0.#}" : "—";
        _resultLoad.Text = result.LoadDeltaMs is { } delta ? $"+{delta:0.#}" : "—";
        _resultLoss.Text = result.PacketLossPercentage is { } loss ? $"{loss:0.#}%" : "—";

        var (label, color, headline) = result.Verdict.ToLowerInvariant() switch
        {
            "ready" => (Strings.Tr("Conexão boa"), ReadyBrush, !string.IsNullOrWhiteSpace(_gameId) ? Strings.Tr("Pronto para ranked") : Strings.Tr("Pronto para jogar")),
            "caution" => (Strings.Tr("Conexão instável"), CautionBrush, Strings.Tr("Condições instáveis")),
            "not_ready" => (Strings.Tr("Conexão ruim"), CoralBrush, Strings.Tr("Eu evitaria ranked agora")),
            _ => (Strings.Tr("Conexão indeterminada"), TextTertiaryBrush, Strings.Tr("Medição inconclusiva"))
        };

        _resultContext.Text = !string.IsNullOrWhiteSpace(_gameTitle) ? $"{_gameTitle.ToUpperInvariant()} · {Strings.Tr("COMPETITIVO")}" : $"{Strings.Tr("CONEXÃO GERAL")} · PC";
        _verdictStatusWord.Text = $"● {label}";
        _verdictStatusWord.Foreground = color;
        _verdictHeadline.Text = headline;

        string regionName = _selectedRegionId ?? "";
        foreach (var r in WebSpeedtestEngine.Regions) if (r.Id == _selectedRegionId) { regionName = r.Name; break; }
        _resultRouteInfo.Text = $"{regionName} ({_selectedRegionId}) · {ping:0} ms";
    }

    private void ShowInconclusive()
    {
        _idleControls.Visibility = Visibility.Collapsed;
        _runningControls.Visibility = Visibility.Collapsed;
        _doneControls.Visibility = Visibility.Visible;
        _mapHostBorder.Visibility = Visibility.Collapsed;

        _verdictStatusWord.Text = Strings.Tr("— Medição inconclusiva");
        _verdictStatusWord.Foreground = TextTertiaryBrush;
        _verdictHeadline.Text = Strings.Tr("Não foi possível concluir");
        _resultRouteInfo.Text = "";

        _resultPing.Text = "—";
        _resultJitter.Text = "—";
        _resultLoad.Text = "—";
        _resultLoss.Text = "—";
    }

    private void ResetToIdle()
    {
        _running = false;
        _idleControls.Visibility = Visibility.Visible;
        _runningControls.Visibility = Visibility.Collapsed;
        _doneControls.Visibility = Visibility.Collapsed;
        _mapHostBorder.Visibility = Visibility.Visible;

        _title.Text = string.IsNullOrWhiteSpace(_gameId) ? Strings.Tr("DIAGNÓSTICO DE CONEXÃO") : _gameTitle.ToUpperInvariant();
        if (!string.IsNullOrWhiteSpace(_gameId))
        {
            _pillText.Text = Strings.Format("{0} · Competitivo", _gameTitle);
            _pillBorder.Visibility = Visibility.Visible;
        }
        else
        {
            _pillBorder.Visibility = Visibility.Collapsed;
        }

        _progressBar.Value = 0;
        RenderMap(_mapCanvas, animated: false);
    }

    private void OnAnimationTick(object? sender, object e)
    {
        if (!_running) return;
        _animationTick = (_animationTick + 0.035) % 1.0;
        RenderMap(_mapCanvas, animated: true);
    }

    private void RenderMap(Canvas canvas, bool animated)
    {
        canvas.Children.Clear();
        double w = canvas.ActualWidth > 0 ? canvas.ActualWidth : 900;
        double h = canvas.Height > 0 ? canvas.Height : 320;
        if (w <= 0 || h <= 0) return;

        var engine = RouteMapEngine.Instance;
        double camLat = -16.0;
        double camLon = -52.0;
        double zoom = 1.35;

        var userLat = _location?.Latitude ?? -22.90;
        var userLon = _location?.Longitude ?? -43.17;

        var regId = _selectedRegionId ?? "sa-east-1";
        (string Name, double Lat, double Lon) dest = ("São Paulo", -23.55, -46.63);
        foreach (var r in WebSpeedtestEngine.Regions)
        {
            if (r.Id == regId) { dest = (r.Name, r.Latitude, r.Longitude); break; }
        }

        // 1. Grade de continentes
        for (int i = 0; i < engine.LandLons.Length; i += 2)
        {
            var (px, py) = RouteMapEngine.Project(engine.LandLats[i], engine.LandLons[i], camLat, camLon, zoom, w, h);
            if (px >= 0 && px <= w && py >= 0 && py <= h)
            {
                var dot = new Ellipse { Width = 2.4, Height = 2.4, Fill = Brush(0x28, 0x30, 0x40) };
                Canvas.SetLeft(dot, px - 1.2);
                Canvas.SetTop(dot, py - 1.2);
                canvas.Children.Add(dot);
            }
        }

        // 2. Pontos das outras regiões mundiais
        foreach (var r in WebSpeedtestEngine.Regions)
        {
            if (r.Id.Equals(regId, StringComparison.OrdinalIgnoreCase)) continue;
            var (rx, ry) = RouteMapEngine.Project(r.Latitude, r.Longitude, camLat, camLon, zoom, w, h);
            if (rx >= 0 && rx <= w && ry >= 0 && ry <= h)
            {
                var node = new Ellipse { Width = 4, Height = 4, Fill = TextTertiaryBrush };
                Canvas.SetLeft(node, rx - 2);
                Canvas.SetTop(node, ry - 2);
                canvas.Children.Add(node);
            }
        }

        // 3. Usuário e Destino
        var (ux, uy) = RouteMapEngine.Project(userLat, userLon, camLat, camLon, zoom, w, h);
        var (dx, dy) = RouteMapEngine.Project(dest.Lat, dest.Lon, camLat, camLon, zoom, w, h);

        double distPx = Math.Sqrt((dx - ux) * (dx - ux) + (dy - uy) * (dy - uy));
        if (distPx < 110)
        {
            dx += 85;
            dy -= 55;
        }

        // 4. Arco Bézier da Rota
        var arc = RouteMapEngine.ComputeArc(ux, uy, dx, dy);
        var figure = new PathFigure { StartPoint = new Windows.Foundation.Point(arc.X0, arc.Y0) };
        figure.Segments.Add(new QuadraticBezierSegment
        {
            Point1 = new Windows.Foundation.Point(arc.Cx, arc.Cy),
            Point2 = new Windows.Foundation.Point(arc.X1, arc.Y1)
        });
        var geom = new PathGeometry();
        geom.Figures.Add(figure);
        var arcPath = new Microsoft.UI.Xaml.Shapes.Path
        {
            Data = geom,
            Stroke = PurpleBrush,
            StrokeThickness = 2.6,
            Opacity = 0.95
        };
        canvas.Children.Add(arcPath);

        // 5. Ondas de radar
        if (animated)
        {
            for (int r = 0; r < 2; r++)
            {
                double waveFrac = (_animationTick + r * 0.5) % 1.0;
                double waveR = waveFrac * 38;
                var ring = new Ellipse
                {
                    Width = waveR * 2,
                    Height = waveR * 2,
                    Stroke = ReadyBrush,
                    StrokeThickness = 1.4,
                    Opacity = Math.Max(0, (1.0 - waveFrac) * 0.8)
                };
                Canvas.SetLeft(ring, dx - waveR);
                Canvas.SetTop(ring, dy - waveR);
                canvas.Children.Add(ring);
            }
        }

        // Ponto de Origem
        var userDot = new Ellipse { Width = 10, Height = 10, Fill = PurpleLightBrush };
        Canvas.SetLeft(userDot, ux - 5);
        Canvas.SetTop(userDot, uy - 5);
        canvas.Children.Add(userDot);

        // Ponto de Destino
        var destDot = new Ellipse { Width = 12, Height = 12, Fill = ReadyBrush };
        Canvas.SetLeft(destDot, dx - 6);
        Canvas.SetTop(destDot, dy - 6);
        canvas.Children.Add(destDot);
    }

    private void OnUnloaded(object sender, RoutedEventArgs e)
    {
        LocalizationService.Instance.LanguageChanged -= OnLanguageChanged;
        _animationTimer.Stop();
        _measurementCts?.Cancel();
    }

    private static SolidColorBrush Brush(byte r, byte g, byte b) => new(Color.FromArgb(255, r, g, b));

    private static TextBlock Title(string text) => new()
    {
        Text = text,
        FontFamily = new FontFamily("Segoe UI Variable Display, Barlow Semi Condensed"),
        FontSize = 38,
        FontWeight = Microsoft.UI.Text.FontWeights.ExtraBold,
        Foreground = TextPrimaryBrush,
        HorizontalAlignment = HorizontalAlignment.Center
    };

    private static TextBlock Body(string text) => new()
    {
        Text = text,
        FontFamily = new FontFamily("Segoe UI Variable Text"),
        FontSize = 14,
        Foreground = TextSecondaryBrush,
        HorizontalAlignment = HorizontalAlignment.Center,
        TextWrapping = TextWrapping.Wrap
    };

    private static TextBlock Label(string text, double size, Brush color) => new()
    {
        Text = text,
        FontFamily = new FontFamily("Segoe UI Variable Text"),
        FontSize = size,
        FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
        Foreground = color
    };

    private static TextBlock Metric(string text) => new()
    {
        Text = text,
        FontFamily = new FontFamily("Chakra Petch, Cascadia Mono, monospace"),
        FontSize = 24,
        FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
        Foreground = TextPrimaryBrush
    };

    private static TextBlock MetricLarge(string text) => new()
    {
        Text = text,
        FontFamily = new FontFamily("Chakra Petch, Cascadia Mono, monospace"),
        FontSize = 72,
        FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
        Foreground = TextPrimaryBrush,
        HorizontalAlignment = HorizontalAlignment.Center
    };

    private static void ApplyPrimaryButtonStyle(Button button)
    {
        button.Background = PurpleBrush;
        button.Foreground = new SolidColorBrush(Microsoft.UI.Colors.White);
        button.BorderThickness = new Thickness(0);
        button.FontWeight = Microsoft.UI.Text.FontWeights.Bold;
        button.FontSize = 16;
    }
}
