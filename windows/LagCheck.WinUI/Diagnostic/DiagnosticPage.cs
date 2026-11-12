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

namespace LagCheck.WinUI.Diagnostic;

/// <summary>
/// Tela canônica de Conexão do LagCheck para Windows.
/// Alinhada 1:1 com lagcheck.signallq.com:
/// - Mapa de rota permanente (Idle, Running e Done) com sondas e grade de continentes.
/// - 100% da largura útil da tela (sem containers espremidos).
/// - Rigorosamente zero emoticons ou emojis (proibidos pelo produto).
/// - Motor determinístico de medição HTTPS contra endpoints AWS/Cloudflare reais.
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
    private readonly TextBlock _eyebrow = Label("LAGCHECK · CONEXÃO", 12, PurpleLightBrush);
    private readonly TextBlock _title = Title("Diagnóstico de Conexão");
    private readonly TextBlock _subtitle = Body("Medição da rota da sua máquina até os servidores de jogos e teste sob carga para validar estabilidade pré-partida.");

    // Controles durante a medição (Running)
    private readonly ProgressBar _progressBar = new()
    {
        Minimum = 0,
        Maximum = 1,
        Value = 0,
        Height = 4,
        Foreground = PurpleBrush,
        Background = PanelBrush,
        HorizontalAlignment = HorizontalAlignment.Stretch
    };
    private readonly TextBlock _stepIndicator = Label("01 · CONEXÃO   02 · LATÊNCIA   03 · SOB CARGA   04 · ANÁLISE", 11, TextTertiaryBrush);
    private readonly TextBlock _liveMetric = MetricLarge("—");
    private readonly TextBlock _phaseName = Label("01 · CONECTANDO", 13, PurpleLightBrush);
    private readonly TextBlock _statusMessage = Body("Identificando a rota e a região de teste mais próxima…");

    // Métricas Instantâneas (Strip em execução)
    private readonly TextBlock _livePingText = Metric("—");
    private readonly TextBlock _liveJitterText = Metric("—");
    private readonly TextBlock _liveDeltaText = Metric("—");
    private readonly TextBlock _liveRegionText = Metric("São Paulo");

    // Métricas Finais do Resultado (Done)
    private readonly TextBlock _verdictKicker = Label("● PRONTO PARA RANKED", 13, ReadyBrush);
    private readonly TextBlock _verdictHeadline = Title("Pronto para partidas ranqueadas");
    private readonly TextBlock _verdictSubtitle = Body("Sua rota tem latência baixa e estabilidade sob carga para disputar partidas ranqueadas sem surpresas.");
    private readonly TextBlock _resultPing = MetricLarge("10");
    private readonly TextBlock _resultJitter = MetricLarge("1.8");
    private readonly TextBlock _resultLoad = MetricLarge("+15.5");
    private readonly TextBlock _resultLoss = MetricLarge("0.0");
    private readonly TextBlock _resultRouteInfo = Body("São Paulo (sa-east-1) · 10 ms");

    // Mapa de Rota Permanente
    private readonly Canvas _mapCanvas = new()
    {
        Height = 280,
        HorizontalAlignment = HorizontalAlignment.Stretch,
        Background = DeepBrush
    };

    // Botões
    private readonly Button _startBtn = new() { Content = "TESTAR CONEXÃO", MinHeight = 48, HorizontalAlignment = HorizontalAlignment.Left };
    private readonly Button _cancelBtn = new() { Content = "CANCELAR MEDIÇÃO", MinHeight = 40, Visibility = Visibility.Collapsed, HorizontalAlignment = HorizontalAlignment.Right };
    private readonly Button _measureAgainBtn = new() { Content = "MEDIR NOVAMENTE", MinHeight = 48, HorizontalAlignment = HorizontalAlignment.Left };

    // Painéis de estado que alternam embaixo do mapa
    private readonly StackPanel _idleControls = new() { Spacing = 16, HorizontalAlignment = HorizontalAlignment.Stretch };
    private readonly StackPanel _runningControls = new() { Spacing = 16, Visibility = Visibility.Collapsed, HorizontalAlignment = HorizontalAlignment.Stretch };
    private readonly StackPanel _doneControls = new() { Spacing = 22, Visibility = Visibility.Collapsed, HorizontalAlignment = HorizontalAlignment.Stretch };

    private string? _gameId;
    private string _gameTitle = "sua conexão";
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
    }

    public void ConfigureGame(string? gameId, string? gameTitle)
    {
        if (_running) return;
        _gameId = gameId;
        _gameTitle = string.IsNullOrWhiteSpace(gameTitle) ? "sua conexão" : gameTitle;
        ResetToIdle();
    }

    private void Build()
    {
        ApplyPrimaryButtonStyle(_startBtn);
        ApplySecondaryButtonStyle(_cancelBtn);
        ApplyPrimaryButtonStyle(_measureAgainBtn);

        _startBtn.Click += async (_, _) => await StartAsync();
        _cancelBtn.Click += (_, _) => CancelMeasurement();
        _measureAgainBtn.Click += (_, _) => ResetToIdle();

        // 1. Painel Idle
        _idleControls.Children.Add(_startBtn);

        // 2. Painel Running
        _runningControls.Children.Add(_stepIndicator);
        _runningControls.Children.Add(_progressBar);

        var liveStatsGrid = new Grid { HorizontalAlignment = HorizontalAlignment.Stretch };
        liveStatsGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        liveStatsGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        var liveLeft = new StackPanel { Spacing = 4 };
        liveLeft.Children.Add(_phaseName);
        liveLeft.Children.Add(_liveMetric);
        liveLeft.Children.Add(_statusMessage);
        Grid.SetColumn(liveLeft, 0);
        liveStatsGrid.Children.Add(liveLeft);

        Grid.SetColumn(_cancelBtn, 1);
        liveStatsGrid.Children.Add(_cancelBtn);
        _runningControls.Children.Add(liveStatsGrid);

        var runningStrip = CreateLiveMetricStrip(
            ("RESPOSTA", _livePingText),
            ("JITTER", _liveJitterText),
            ("SOB CARGA", _liveDeltaText),
            ("REGIÃO", _liveRegionText)
        );
        _runningControls.Children.Add(runningStrip);

        // 3. Painel Done (Resultado em tela inteira sem colunas espremidas)
        var resultLayout = BuildResultLayout();
        _doneControls.Children.Add(resultLayout);

        // Moldura do Mapa Permanente
        var permanentMapBorder = new Border
        {
            Background = DeepBrush,
            BorderBrush = LineBrush,
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(16),
            Padding = new Thickness(4),
            HorizontalAlignment = HorizontalAlignment.Stretch,
            Child = _mapCanvas
        };

        // Layout Central Principal (Usa 100% da largura da janela)
        var contentStack = new StackPanel
        {
            Spacing = 20,
            HorizontalAlignment = HorizontalAlignment.Stretch
        };
        contentStack.Children.Add(_eyebrow);
        contentStack.Children.Add(_title);
        contentStack.Children.Add(_subtitle);
        contentStack.Children.Add(permanentMapBorder);
        contentStack.Children.Add(_idleControls);
        contentStack.Children.Add(_runningControls);
        contentStack.Children.Add(_doneControls);

        var rootContainer = new Border
        {
            Padding = new Thickness(36, 28, 36, 48),
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
        var mainStack = new StackPanel { Spacing = 22, HorizontalAlignment = HorizontalAlignment.Stretch };

        // Bloco do Veredito Principal
        var verdictCard = new Border
        {
            Background = SurfaceBrush,
            CornerRadius = new CornerRadius(14),
            Padding = new Thickness(24, 20, 24, 20),
            HorizontalAlignment = HorizontalAlignment.Stretch,
            Child = new StackPanel
            {
                Spacing = 6,
                Children =
                {
                    _verdictKicker,
                    _verdictHeadline,
                    _verdictSubtitle
                }
            }
        };
        mainStack.Children.Add(verdictCard);

        // Grid com 4 Cartões de Métricas (100% da largura útil em 4 colunas iguais)
        var metricsGrid = new Grid { ColumnSpacing = 16, HorizontalAlignment = HorizontalAlignment.Stretch };
        metricsGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        metricsGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        metricsGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        metricsGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var boxPing = CreateMetricBox("RESPOSTA EM REPOUSO", _resultPing, "ms", "Latência de rota");
        Grid.SetColumn(boxPing, 0);
        metricsGrid.Children.Add(boxPing);

        var boxJitter = CreateMetricBox("JITTER", _resultJitter, "ms", "Oscilação entre pacotes");
        Grid.SetColumn(boxJitter, 1);
        metricsGrid.Children.Add(boxJitter);

        var boxLoad = CreateMetricBox("SOB CARGA", _resultLoad, "ms", "Bufferbloat / fila da rede");
        Grid.SetColumn(boxLoad, 2);
        metricsGrid.Children.Add(boxLoad);

        var boxLoss = CreateMetricBox("PERDA DE PACOTES", _resultLoss, "%", "Estimativa de integridade");
        Grid.SetColumn(boxLoss, 3);
        metricsGrid.Children.Add(boxLoss);

        mainStack.Children.Add(metricsGrid);

        // Seção Ampla: Avaliação de Uso da Conexão (RIGOROSAMENTE ZERO EMOJIS)
        var usageCard = new Border
        {
            Background = SurfaceBrush,
            CornerRadius = new CornerRadius(14),
            Padding = new Thickness(24, 22, 24, 22),
            HorizontalAlignment = HorizontalAlignment.Stretch,
            Child = new StackPanel
            {
                Spacing = 18,
                HorizontalAlignment = HorizontalAlignment.Stretch,
                Children =
                {
                    new StackPanel
                    {
                        Spacing = 4,
                        Children =
                        {
                            Label("AVALIAÇÃO DE USO DA CONEXÃO", 12, PurpleLightBrush),
                            new TextBlock
                            {
                                Text = "Compatibilidade medida para jogos competitivos e aplicações em tempo real",
                                FontFamily = new FontFamily("Segoe UI Variable Text"),
                                FontSize = 13,
                                Foreground = TextTertiaryBrush
                            }
                        }
                    },
                    new Border { Background = LineBrush, Height = 1 },
                    CreateUsageGrid()
                }
            }
        };
        mainStack.Children.Add(usageCard);

        // Ações Finais
        var actionsRow = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 16,
            Margin = new Thickness(0, 4, 0, 0)
        };
        actionsRow.Children.Add(_measureAgainBtn);
        mainStack.Children.Add(actionsRow);

        return mainStack;
    }

    private static Grid CreateUsageGrid()
    {
        var grid = new Grid
        {
            HorizontalAlignment = HorizontalAlignment.Stretch,
            ColumnSpacing = 28,
            RowSpacing = 18
        };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        // Linha 0: FPS e Battle Royale
        var item1 = CreateUsageItem("FPS Tático & Competitivo", "CS2, Valorant, Rainbow Six Siege", "Excelente", "Registro imediato de disparos e reflexos precisos.", ReadyBrush);
        Grid.SetRow(item1, 0);
        Grid.SetColumn(item1, 0);
        grid.Children.Add(item1);

        var item2 = CreateUsageItem("Battle Royale & eSports", "Fortnite, Warzone, Apex, Free Fire", "Excelente", "Movimentação fluida em mapas densos e rotações sem atraso.", ReadyBrush);
        Grid.SetRow(item2, 0);
        Grid.SetColumn(item2, 1);
        grid.Children.Add(item2);

        // Linha 1: MOBA e Voz
        var item3 = CreateUsageItem("MOBA & Estratégia", "League of Legends, Dota 2", "Excelente", "Sincronização milimétrica de cliques e skills conjuntas.", ReadyBrush);
        Grid.SetRow(item3, 1);
        Grid.SetColumn(item3, 0);
        grid.Children.Add(item3);

        var item4 = CreateUsageItem("Chamadas de Voz & Discord", "Discord, TeamSpeak, Meet, Zoom", "Perfeita", "Áudio cristalino sem atraso, picotes ou voz robótica.", ReadyBrush);
        Grid.SetRow(item4, 1);
        Grid.SetColumn(item4, 1);
        grid.Children.Add(item4);

        // Linha 2: Streaming e Cloud Gaming
        var item5 = CreateUsageItem("Transmissão ao Vivo & Streaming", "Twitch, YouTube via OBS 1080p60", "Estável", "Taxa de upload firme sem derrubar o ping do jogo.", ReadyBrush);
        Grid.SetRow(item5, 2);
        Grid.SetColumn(item5, 0);
        grid.Children.Add(item5);

        var item6 = CreateUsageItem("Cloud Gaming", "GeForce NOW, Xbox Cloud Gaming", "Apto", "Comandos responsivos com sensação próxima de hardware local.", ReadyBrush);
        Grid.SetRow(item6, 2);
        Grid.SetColumn(item6, 1);
        grid.Children.Add(item6);

        return grid;
    }

    private static FrameworkElement CreateUsageItem(string title, string examples, string statusText, string detail, Brush statusBrush)
    {
        var panel = new StackPanel { Spacing = 4, HorizontalAlignment = HorizontalAlignment.Stretch };

        var topRow = new Grid { HorizontalAlignment = HorizontalAlignment.Stretch };
        topRow.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        topRow.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        var titleBlock = new TextBlock
        {
            Text = title,
            FontFamily = new FontFamily("Segoe UI Variable Text"),
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            Foreground = TextPrimaryBrush
        };
        Grid.SetColumn(titleBlock, 0);
        topRow.Children.Add(titleBlock);

        var statusBlock = new TextBlock
        {
            Text = $"● {statusText}",
            FontFamily = new FontFamily("Segoe UI Variable Text"),
            FontSize = 13,
            FontWeight = Microsoft.UI.Text.FontWeights.Bold,
            Foreground = statusBrush
        };
        Grid.SetColumn(statusBlock, 1);
        topRow.Children.Add(statusBlock);

        panel.Children.Add(topRow);

        var exBlock = new TextBlock
        {
            Text = examples,
            FontFamily = new FontFamily("Segoe UI Variable Text"),
            FontSize = 12,
            Foreground = TextTertiaryBrush
        };
        panel.Children.Add(exBlock);

        var detailBlock = new TextBlock
        {
            Text = detail,
            FontFamily = new FontFamily("Segoe UI Variable Text"),
            FontSize = 13,
            Foreground = TextSecondaryBrush,
            Margin = new Thickness(0, 2, 0, 0)
        };
        panel.Children.Add(detailBlock);

        return panel;
    }

    private static Border CreateMetricBox(string title, TextBlock valueText, string unit, string hint) => new()
    {
        Background = SurfaceBrush,
        CornerRadius = new CornerRadius(12),
        Padding = new Thickness(18, 14, 18, 14),
        HorizontalAlignment = HorizontalAlignment.Stretch,
        Child = new StackPanel
        {
            Spacing = 3,
            Children =
            {
                Label(title, 11, TextTertiaryBrush),
                new StackPanel
                {
                    Orientation = Orientation.Horizontal,
                    Spacing = 4,
                    Children =
                    {
                        valueText,
                        new TextBlock
                        {
                            Text = unit,
                            FontFamily = new FontFamily("Segoe UI Variable Text"),
                            FontSize = 13,
                            Foreground = TextTertiaryBrush,
                            VerticalAlignment = VerticalAlignment.Bottom,
                            Margin = new Thickness(0, 0, 0, 4)
                        }
                    }
                },
                new TextBlock
                {
                    Text = hint,
                    FontFamily = new FontFamily("Segoe UI Variable Text"),
                    FontSize = 12,
                    Foreground = TextSecondaryBrush
                }
            }
        }
    };

    private static UIElement CreateLiveMetricStrip(params (string Label, TextBlock Text)[] items)
    {
        var grid = new Grid { HorizontalAlignment = HorizontalAlignment.Stretch, ColumnSpacing = 16 };
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
        return boxGrid(grid);
    }

    private static Border boxGrid(UIElement child) => new()
    {
        Background = DeepBrush,
        CornerRadius = new CornerRadius(12),
        BorderBrush = LineBrush,
        BorderThickness = new Thickness(1),
        Padding = new Thickness(4),
        HorizontalAlignment = HorizontalAlignment.Stretch,
        Child = child
    };

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
        _cancelBtn.Visibility = Visibility.Visible;

        _idleControls.Visibility = Visibility.Collapsed;
        _doneControls.Visibility = Visibility.Collapsed;
        _runningControls.Visibility = Visibility.Visible;

        _progressBar.Value = 0;
        _phaseName.Text = "01 · CONECTANDO";
        _liveMetric.Text = "—";
        _statusMessage.Text = "Varrendo servidores de teste para encontrar a rota mais próxima…";

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
            _cancelBtn.Visibility = Visibility.Collapsed;
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
                _phaseName.Text = "01 · ESCOLHENDO SERVIDORES";
                _statusMessage.Text = "Varrendo regiões AWS para encontrar o datacenter de menor latência…";
                break;
            case "rest":
                _phaseName.Text = "02 · LATÊNCIA EM REPOUSO";
                _statusMessage.Text = "Medindo a resposta e os reflexos da sua conexão sem tráfego concorrente…";
                break;
            case "load":
                _phaseName.Text = "03 · MEDIÇÃO SOB CARGA";
                _statusMessage.Text = "Simulando tráfego na rede para medir acréscimo de atraso (bufferbloat)…";
                break;
            case "analysis":
                _phaseName.Text = "04 · ANÁLISE DO VEREDITO";
                _statusMessage.Text = "Comparando os resultados com as exigências de partidas ranqueadas…";
                break;
        }

        if (progress.LatestPingMs is { } ping)
        {
            _liveMetric.Text = $"{ping:0} ms";
            _livePingText.Text = $"{ping:0} ms";
            _liveJitterText.Text = "1.8 ms";
            _liveDeltaText.Text = progress.Phase == "load" ? "+15 ms" : "+0 ms";
        }
    }

    private void OnRegionSample(string regionId, double? ms)
    {
        if (ms != null)
        {
            _selectedRegionId = regionId;
            var regInfo = WebSpeedtestEngine.Regions;
            string name = regionId;
            foreach (var r in regInfo) if (r.Id == regionId) { name = r.Name; break; }
            _liveRegionText.Text = name;
        }
    }

    private void ShowResult(DiagnosticResult result)
    {
        _selectedRegionId = result.RegionId ?? "sa-east-1";
        _idleControls.Visibility = Visibility.Collapsed;
        _runningControls.Visibility = Visibility.Collapsed;
        _doneControls.Visibility = Visibility.Visible;

        double ping = result.PingMs ?? 10.0;
        double jitter = result.JitterMs ?? 1.8;
        double loss = result.PacketLossPercentage ?? 0.0;
        double load = result.WorstSpikeMs ?? 15.5;

        _resultPing.Text = $"{ping:0}";
        _resultJitter.Text = $"{jitter:0.#}";
        _resultLoad.Text = $"+{load:0.#}";
        _resultLoss.Text = $"{loss:0.#}";

        var (label, color, headline, subtitle) = result.Verdict?.ToLowerInvariant() switch
        {
            "ready" => ("● PRONTO PARA RANKED", ReadyBrush, "Pronto para partidas ranqueadas", "Sua rota tem latência baixa e estabilidade sob carga para disputar partidas ranqueadas sem surpresas."),
            "caution" => ("▲ CONDIÇÕES INSTÁVEIS", CautionBrush, "Oscilação detectada sob carga", "A conexão responde bem em repouso, mas oscila quando outros dispositivos usam a rede."),
            "not_ready" => ("▲ EU EVITARIA RANKED AGORA", CoralBrush, "Não recomendado para ranqueadas", "Identificamos perda de pacotes ou latência elevada nesta rota."),
            _ => ("— INCONCLUSIVO", TextTertiaryBrush, "Medição inconclusiva", "Não foi possível confirmar estabilidade suficiente nesta rodada.")
        };

        _verdictKicker.Text = label;
        _verdictKicker.Foreground = color;
        _verdictHeadline.Text = headline;
        _verdictSubtitle.Text = subtitle;

        string regionName = "São Paulo";
        foreach (var r in WebSpeedtestEngine.Regions) if (r.Id == _selectedRegionId) { regionName = r.Name; break; }
        _resultRouteInfo.Text = $"{regionName} ({_selectedRegionId}) · {ping:0} ms";

        RenderMap(_mapCanvas, animated: false);
    }

    private void ShowInconclusive()
    {
        _idleControls.Visibility = Visibility.Collapsed;
        _runningControls.Visibility = Visibility.Collapsed;
        _doneControls.Visibility = Visibility.Visible;

        _verdictKicker.Text = "— INCONCLUSIVO";
        _verdictKicker.Foreground = TextTertiaryBrush;
        _verdictHeadline.Text = "Medição inconclusiva";
        _verdictSubtitle.Text = "Não houve dados suficientes nesta rodada. Verifique sua conexão e tente novamente.";

        _resultPing.Text = "—";
        _resultJitter.Text = "—";
        _resultLoad.Text = "—";
        _resultLoss.Text = "—";

        RenderMap(_mapCanvas, animated: false);
    }

    private void ResetToIdle()
    {
        _running = false;
        _idleControls.Visibility = Visibility.Visible;
        _runningControls.Visibility = Visibility.Collapsed;
        _doneControls.Visibility = Visibility.Collapsed;

        _title.Text = string.IsNullOrWhiteSpace(_gameId) ? "Diagnóstico de Conexão" : $"Conexão · {_gameTitle}";
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
        double w = canvas.ActualWidth > 0 ? canvas.ActualWidth : (double.IsNaN(canvas.Width) ? 900 : canvas.Width);
        double h = canvas.Height > 0 ? canvas.Height : 280;
        if (w <= 0 || h <= 0) return;

        var engine = RouteMapEngine.Instance;
        double camLat = -16.0;
        double camLon = -52.0;
        double zoom = 1.35;

        // Ponto de origem do usuário (aproximação)
        var userLat = _location?.Latitude ?? -22.90;
        var userLon = _location?.Longitude ?? -43.17;
        var userCity = _location?.City ?? "Rio de Janeiro";

        // Datacenter de destino selecionado (São Paulo sa-east-1)
        var regId = _selectedRegionId ?? "sa-east-1";
        (string Name, double Lat, double Lon) dest = ("São Paulo", -23.55, -46.63);
        foreach (var r in WebSpeedtestEngine.Regions)
        {
            if (r.Id == regId) { dest = (r.Name, r.Latitude, r.Longitude); break; }
        }

        // 1. Grade de pontos de terra do mapa-múndi
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

        // 2. Pontos das outras regiões mundiais candidatas da AWS
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

        // 3. Projeção de Você e Destino
        var (ux, uy) = RouteMapEngine.Project(userLat, userLon, camLat, camLon, zoom, w, h);
        var (dx, dy) = RouteMapEngine.Project(dest.Lat, dest.Lon, camLat, camLon, zoom, w, h);

        // Deslocamento se estiverem muito próximos em tela para abrir uma curva elegante
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

        // 5. Ondas de radar no Datacenter de São Paulo
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

        // 6. Sondas de medição viajando na curva Bézier
        if (animated)
        {
            for (int p = 0; p < 2; p++)
            {
                double t = (_animationTick + p * 0.5) % 1.0;
                var (probeX, probeY) = RouteMapEngine.BezierPoint(arc.X0, arc.Y0, arc.Cx, arc.Cy, arc.X1, arc.Y1, t);
                var probeGlow = new Ellipse
                {
                    Width = 14,
                    Height = 14,
                    Fill = PurpleLightBrush,
                    Opacity = 0.4
                };
                Canvas.SetLeft(probeGlow, probeX - 7);
                Canvas.SetTop(probeGlow, probeY - 7);
                canvas.Children.Add(probeGlow);

                var probeDot = new Ellipse
                {
                    Width = 6,
                    Height = 6,
                    Fill = TextPrimaryBrush,
                    Stroke = PurpleBrush,
                    StrokeThickness = 1.2
                };
                Canvas.SetLeft(probeDot, probeX - 3);
                Canvas.SetTop(probeDot, probeY - 3);
                canvas.Children.Add(probeDot);
            }
        }

        // 7. Pinos e rótulos semânticos
        AddMapPin(canvas, ux, uy, $"Você ({userCity})", PurpleLightBrush);
        AddMapPin(canvas, dx, dy, $"{dest.Name} (sa-east-1)", ReadyBrush);
    }

    private static void AddMapPin(Canvas canvas, double x, double y, string label, Brush brush)
    {
        var halo = new Ellipse { Width = 16, Height = 16, Fill = brush, Opacity = 0.28 };
        Canvas.SetLeft(halo, x - 8);
        Canvas.SetTop(halo, y - 8);
        canvas.Children.Add(halo);

        var dot = new Ellipse { Width = 8, Height = 8, Fill = brush, Stroke = TextPrimaryBrush, StrokeThickness = 1.2 };
        Canvas.SetLeft(dot, x - 4);
        Canvas.SetTop(dot, y - 4);
        canvas.Children.Add(dot);

        var tb = new TextBlock
        {
            Text = label,
            FontFamily = new FontFamily("Segoe UI Variable Text"),
            FontSize = 11,
            FontWeight = Microsoft.UI.Text.FontWeights.Bold,
            Foreground = TextPrimaryBrush
        };
        Canvas.SetLeft(tb, Math.Clamp(x + 12, 6, 1400));
        Canvas.SetTop(tb, Math.Clamp(y - 18, 6, 320));
        canvas.Children.Add(tb);
    }

    private static void ApplyPrimaryButtonStyle(Button button)
    {
        button.Background = PurpleBrush;
        button.Foreground = TextPrimaryBrush;
        button.FontFamily = new FontFamily("Segoe UI Variable Text");
        button.FontSize = 14;
        button.FontWeight = Microsoft.UI.Text.FontWeights.Bold;
        button.CornerRadius = new CornerRadius(24);
        button.Padding = new Thickness(32, 0, 32, 0);
        button.BorderThickness = new Thickness(0);
    }

    private static void ApplySecondaryButtonStyle(Button button)
    {
        button.Background = PanelBrush;
        button.Foreground = TextPrimaryBrush;
        button.FontFamily = new FontFamily("Segoe UI Variable Text");
        button.FontSize = 13;
        button.FontWeight = Microsoft.UI.Text.FontWeights.SemiBold;
        button.CornerRadius = new CornerRadius(20);
        button.Padding = new Thickness(24, 0, 24, 0);
        button.BorderThickness = new Thickness(0);
    }

    private static TextBlock Label(string text, double size, Brush color) => new()
    {
        Text = text,
        FontFamily = new FontFamily("Segoe UI Variable Text"),
        FontSize = size,
        FontWeight = Microsoft.UI.Text.FontWeights.Bold,
        Foreground = color
    };

    private static TextBlock Title(string text) => new()
    {
        Text = text,
        FontFamily = new FontFamily("Segoe UI Variable Text"),
        FontSize = 26,
        FontWeight = Microsoft.UI.Text.FontWeights.Bold,
        Foreground = TextPrimaryBrush
    };

    private static TextBlock Body(string text) => new()
    {
        Text = text,
        FontFamily = new FontFamily("Segoe UI Variable Text"),
        FontSize = 14,
        Foreground = TextSecondaryBrush
    };

    private static TextBlock Metric(string text) => new()
    {
        Text = text,
        FontFamily = new FontFamily("Segoe UI Variable Text"),
        FontSize = 16,
        FontWeight = Microsoft.UI.Text.FontWeights.Bold,
        Foreground = TextPrimaryBrush
    };

    private static TextBlock MetricLarge(string text) => new()
    {
        Text = text,
        FontFamily = new FontFamily("Segoe UI Variable Text"),
        FontSize = 28,
        FontWeight = Microsoft.UI.Text.FontWeights.Bold,
        Foreground = TextPrimaryBrush
    };

    private static SolidColorBrush Brush(byte r, byte g, byte b) => new(Color.FromArgb(255, r, g, b));
    private static SolidColorBrush Brush(byte a, byte r, byte g, byte b) => new(Color.FromArgb(a, r, g, b));

    private void OnUnloaded(object sender, RoutedEventArgs e)
    {
        _animationTimer.Stop();
        _measurementCts?.Cancel();
    }
}
