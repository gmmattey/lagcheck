using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.UI;

namespace LagCheck.WinUI.Diagnostic;

/// <summary>
/// Contextual diagnostic screen. It shows only values emitted by the Kotlin engine host.
/// </summary>
public sealed class DiagnosticPage : Page
{
    private static readonly SolidColorBrush BackgroundBrush = Brush(0x0B, 0x0D, 0x10);
    private static readonly SolidColorBrush SurfaceBrush = Brush(0x15, 0x18, 0x1E);
    private static readonly SolidColorBrush PanelBrush = Brush(0x1E, 0x23, 0x2B);
    private static readonly SolidColorBrush PrimaryBrush = Brush(0x7C, 0x3A, 0xED);
    private static readonly SolidColorBrush TextBrush = Brush(0xF8, 0xFA, 0xFC);
    private static readonly SolidColorBrush MutedBrush = Brush(0xA8, 0xB3, 0xC7);
    private static readonly SolidColorBrush BorderBrush = Brush(0x3A, 0x43, 0x52);

    private readonly DiagnosticEngineClient _engine;
    private readonly bool _ownsEngine;
    private readonly TextBlock _eyebrow = Label("DIAGNÓSTICO", 12, MutedBrush);
    private readonly TextBlock _title = Title("Preparar medição");
    private readonly TextBlock _detail = Body("A medição usa uma rota de referência. O jogo não é iniciado por esta tela.");
    private readonly TextBlock _phase = Label("PRONTO", 12, MutedBrush);
    private readonly ProgressBar _progress = new() { Minimum = 0, Maximum = 1, Value = 0, Height = 6, Foreground = PrimaryBrush, Background = PanelBrush };
    private readonly TextBlock _ping = Metric("—");
    private readonly TextBlock _jitter = Metric("—");
    private readonly TextBlock _loss = Metric("—");
    private readonly TextBlock _currentPing = Metric("—");
    private readonly TextBlock _currentJitter = Metric("—");
    private readonly TextBlock _currentLoss = Metric("—");
    private readonly TextBlock _verdict = Title("—");
    private readonly TextBlock _resultDetail = Body("Ainda não há resultado.");
    private readonly Canvas _routeMap = new() { Width = 600, Height = 150, Background = PanelBrush };
    private readonly TextBlock _routeStatus = Body("Localização aproximada não carregada.");
    private readonly Button _primary = new() { MinHeight = 44, Content = "INICIAR CHECK" };
    private readonly Button _cancel = new() { MinHeight = 44, Content = "CANCELAR", Visibility = Visibility.Collapsed };
    private readonly StackPanel _checkContent = new() { Spacing = 18 };
    private readonly StackPanel _resultContent = new() { Spacing = 16, Visibility = Visibility.Collapsed };
    private string? _gameId;
    private string _gameTitle = "sua conexão";
    private ApproximateLocation? _location;
    private string? _regionId;
    private bool _running;

    public DiagnosticPage()
        : this(null, null, WinUiEngineComposition.Client)
    {
    }

    public DiagnosticPage(string? gameId, string? gameTitle, DiagnosticEngineClient? engine)
    {
        _gameId = gameId;
        if (!string.IsNullOrWhiteSpace(gameTitle)) _gameTitle = gameTitle;
        _engine = engine ?? new DiagnosticEngineClient();
        _ownsEngine = engine is null;
        _engine.ProgressChanged += OnProgress;
        _engine.EngineFaulted += OnEngineFaulted;
        Background = BackgroundBrush;
        Build();
        Loaded += DiagnosticPage_Loaded;
        Unloaded += OnUnloaded;
    }

    /// <summary>Called by the Library route before navigation; selection alone never starts a measurement.</summary>
    public void ConfigureGame(string? gameId, string? gameTitle)
    {
        if (_running) return;
        _gameId = gameId;
        _gameTitle = string.IsNullOrWhiteSpace(gameTitle) ? "sua conexão" : gameTitle;
        ResetCheck();
    }

    private void Build()
    {
        _primary.Click += async (_, _) => await StartAsync();
        _cancel.Click += async (_, _) => await CancelAsync();
        ApplyButtonStyle(_primary, PrimaryBrush, TextBrush);
        ApplyButtonStyle(_cancel, PanelBrush, TextBrush);

        _checkContent.Children.Add(_eyebrow);
        _checkContent.Children.Add(_title);
        _checkContent.Children.Add(_detail);
        _checkContent.Children.Add(_phase);
        _checkContent.Children.Add(_progress);
        _checkContent.Children.Add(_primary);
        _checkContent.Children.Add(_cancel);
        _checkContent.Children.Add(MetricRow("PING ATUAL", _currentPing));
        _checkContent.Children.Add(MetricRow("JITTER", _currentJitter));
        _checkContent.Children.Add(MetricRow("PERDA", _currentLoss));
        _checkContent.Children.Add(new TextBlock { Text = "TRAJETO ESQUEMÁTICO", FontFamily = new FontFamily("Barlow Semi Condensed"), FontWeight = Microsoft.UI.Text.FontWeights.SemiBold, Foreground = MutedBrush, CharacterSpacing = 60 });
        _checkContent.Children.Add(new Border { Background = PanelBrush, BorderBrush = BorderBrush, BorderThickness = new Thickness(1), CornerRadius = new CornerRadius(8), Padding = new Thickness(8), Child = _routeMap });
        _checkContent.Children.Add(_routeStatus);

        _resultContent.Children.Add(Label("RESULTADO DA MEDIÇÃO", 12, MutedBrush));
        _resultContent.Children.Add(_verdict);
        _resultContent.Children.Add(_resultDetail);
        _resultContent.Children.Add(MetricRow("PING", _ping));
        _resultContent.Children.Add(MetricRow("JITTER", _jitter));
        _resultContent.Children.Add(MetricRow("PERDA", _loss));
        var again = new Button { MinHeight = 44, Content = "MEDIR NOVAMENTE" };
        again.Click += (_, _) => ResetCheck();
        ApplyButtonStyle(again, PrimaryBrush, TextBrush);
        _resultContent.Children.Add(again);

        var root = new Grid { MaxWidth = 700, HorizontalAlignment = HorizontalAlignment.Stretch, Margin = new Thickness(32, 36, 32, 48) };
        var panel = new Border
        {
            Background = SurfaceBrush,
            BorderBrush = BorderBrush,
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(12),
            Padding = new Thickness(28),
            Child = new Grid()
        };
        ((Grid)panel.Child).Children.Add(_checkContent);
        ((Grid)panel.Child).Children.Add(_resultContent);
        root.Children.Add(panel);
        Content = new ScrollViewer { Content = root, HorizontalContentAlignment = HorizontalAlignment.Stretch, HorizontalScrollMode = ScrollMode.Disabled, VerticalScrollBarVisibility = ScrollBarVisibility.Auto };
        ResetCheck();
    }

    private async void DiagnosticPage_Loaded(object sender, RoutedEventArgs e)
    {
        Loaded -= DiagnosticPage_Loaded;
        try
        {
            _location = await _engine.GetApproximateLocationAsync();
        }
        catch
        {
            _location = null;
        }
        RenderRoute();
    }

    private async Task StartAsync()
    {
        if (_running) return;
        _running = true;
        _primary.IsEnabled = false;
        _cancel.Visibility = Visibility.Visible;
        _phase.Text = "CONECTANDO AO MOTOR";
        _detail.Text = "Medindo a rota de referência para " + _gameTitle + ".";
        _progress.Value = 0;
        try
        {
            var result = await _engine.StartAsync(_gameId);
            ShowResult(result);
        }
        catch (DiagnosticEngineException exception) when (exception.Code == "CANCELLED")
        {
            ShowCancelled();
        }
        catch (DiagnosticEngineException exception) when (exception.Code == "INCONCLUSIVE")
        {
            ShowInconclusive();
        }
        catch (Exception)
        {
            ShowUnavailable();
        }
        finally
        {
            _running = false;
            _primary.IsEnabled = true;
            _cancel.Visibility = Visibility.Collapsed;
        }
    }

    private async Task CancelAsync()
    {
        _cancel.IsEnabled = false;
        _phase.Text = "CANCELANDO";
        try { await _engine.CancelAsync(); }
        catch { ShowUnavailable(); }
        finally { _cancel.IsEnabled = true; }
    }

    private void OnProgress(object? sender, DiagnosticProgress progress)
    {
        DispatcherQueue.TryEnqueue(() =>
        {
            if (!_running) return;
            _progress.Value = Math.Clamp(progress.Ratio, 0, 1);
            _phase.Text = progress.Phase.Equals("load", StringComparison.OrdinalIgnoreCase) ? "MEDIÇÃO SOB CARGA" : "MEDIÇÃO EM REPOUSO";
            if (progress.LatestPingMs is { } ping) _currentPing.Text = FormatMs(ping);
        });
    }

    private void OnEngineFaulted(object? sender, DiagnosticEngineException error)
    {
        if (error.Code == "CANCELLED") return;
        DispatcherQueue.TryEnqueue(() =>
        {
            if (!_running) return;
            _phase.Text = error.Code == "INCONCLUSIVE" ? "MEDIÇÃO INCONCLUSIVA" : "CHECK INTERROMPIDO";
        });
    }

    private void ShowResult(DiagnosticResult result)
    {
        _regionId = result.RegionId;
        RenderRoute();
        _ping.Text = FormatMs(result.PingMs);
        _jitter.Text = FormatMs(result.JitterMs);
        _loss.Text = result.PacketLossPercentage is { } loss ? $"{loss:0.#}%" : "—";
        _resultContent.Visibility = Visibility.Visible;
        _checkContent.Visibility = Visibility.Collapsed;
        if (!string.Equals(result.Status, "completed", StringComparison.OrdinalIgnoreCase)
            || string.IsNullOrWhiteSpace(result.Verdict)
            || !string.IsNullOrWhiteSpace(result.AbortReason))
        {
            _verdict.Text = "— INCONCLUSIVO";
            _resultDetail.Text = "Não houve dados UDP suficientes. Nenhuma nota foi calculada.";
            return;
        }
        _verdict.Text = result.Verdict.ToLowerInvariant() switch
        {
            "ready" => "● PRONTO PARA RANKED",
            "caution" => "▲ CONDIÇÕES INSTÁVEIS",
            "not_ready" => "▲ EU EVITARIA RANKED AGORA",
            _ => "— INCONCLUSIVO",
        };
        _resultDetail.Text = result.LoadMeasured
            ? "Repouso e carga foram medidos pelo motor."
            : "O motor concluiu a medição sem fase de carga.";
    }

    private void ShowCancelled()
    {
        _progress.Value = 0;
        _phase.Text = "MEDIÇÃO CANCELADA";
        _detail.Text = "Nada foi salvo e não existe resultado parcial.";
    }

    private void ShowInconclusive()
    {
        _progress.Value = 0;
        _ping.Text = _jitter.Text = _loss.Text = "—";
        _regionId = null;
        RenderRoute();
        _verdict.Text = "— INCONCLUSIVO";
        _resultDetail.Text = "Não houve respostas UDP suficientes. Nenhuma nota foi calculada.";
        _resultContent.Visibility = Visibility.Visible;
        _checkContent.Visibility = Visibility.Collapsed;
    }

    private void ShowUnavailable()
    {
        _progress.Value = 0;
        _phase.Text = "CHECK NÃO CONCLUÍDO";
        _detail.Text = "O Check não pôde ser concluído neste PC. Nenhum resultado foi calculado.";
    }

    private void ResetCheck()
    {
        _checkContent.Visibility = Visibility.Visible;
        _resultContent.Visibility = Visibility.Collapsed;
        _eyebrow.Text = string.IsNullOrWhiteSpace(_gameId) ? "DIAGNÓSTICO GERAL" : "DIAGNÓSTICO DO JOGO";
        _title.Text = "Checar " + _gameTitle;
        _detail.Text = "Inicie quando quiser medir a rota de referência.";
        _phase.Text = "PRONTO";
        _progress.Value = 0;
        _ping.Text = _jitter.Text = _loss.Text = "—";
        _currentPing.Text = _currentJitter.Text = _currentLoss.Text = "—";
        _regionId = null;
        RenderRoute();
    }

    private void RenderRoute()
    {
        _routeMap.Children.Clear();
        for (var x = 75; x < 600; x += 75) _routeMap.Children.Add(new Line { X1 = x, X2 = x, Y1 = 0, Y2 = 150, Stroke = BorderBrush, StrokeThickness = 1, Opacity = 0.45 });
        for (var y = 50; y < 150; y += 50) _routeMap.Children.Add(new Line { X1 = 0, X2 = 600, Y1 = y, Y2 = y, Stroke = BorderBrush, StrokeThickness = 1, Opacity = 0.45 });

        if (_location is not { Enabled: true, HasCoordinates: true } origin)
        {
            _routeStatus.Text = _location?.Enabled == false
                ? "Localização aproximada está desligada nos ajustes."
                : "Sem localização aproximada salva neste PC.";
            return;
        }
        if (_regionId is null || !RegionCoordinates.TryGetValue(_regionId, out var destination))
        {
            _routeStatus.Text = "A rota aparece quando o motor informar uma região de referência.";
            AddPin(Project(origin.Latitude!.Value, origin.Longitude!.Value), "VOCÊ", PrimaryBrush);
            return;
        }

        var from = Project(origin.Latitude!.Value, origin.Longitude!.Value);
        var to = Project(destination.Latitude, destination.Longitude);
        _routeMap.Children.Add(new Line { X1 = from.X, Y1 = from.Y, X2 = to.X, Y2 = to.Y, Stroke = PrimaryBrush, StrokeThickness = 2, Opacity = 0.9 });
        AddPin(from, "VOCÊ", PrimaryBrush);
        AddPin(to, destination.Label, MutedBrush);
        _routeStatus.Text = $"Trajeto esquemático: {origin.Label} → {destination.Label}.";
    }

    private void AddPin((double X, double Y) point, string label, Brush brush)
    {
        var pin = new Ellipse { Width = 12, Height = 12, Fill = brush, Stroke = TextBrush, StrokeThickness = 1 };
        Canvas.SetLeft(pin, point.X - 6); Canvas.SetTop(pin, point.Y - 6);
        _routeMap.Children.Add(pin);
        var text = new TextBlock { Text = label, Foreground = TextBrush, FontFamily = new FontFamily("Barlow Semi Condensed"), FontSize = 12, FontWeight = Microsoft.UI.Text.FontWeights.SemiBold };
        Canvas.SetLeft(text, Math.Clamp(point.X + 8, 4, 520)); Canvas.SetTop(text, Math.Clamp(point.Y - 22, 2, 130));
        _routeMap.Children.Add(text);
    }

    private static (double X, double Y) Project(double latitude, double longitude) =>
        (Math.Clamp((longitude + 180d) / 360d * 600d, 4, 596), Math.Clamp((90d - latitude) / 180d * 150d, 4, 146));

    private async void OnUnloaded(object sender, RoutedEventArgs e)
    {
        Unloaded -= OnUnloaded;
        _engine.ProgressChanged -= OnProgress;
        _engine.EngineFaulted -= OnEngineFaulted;
        if (_running) await _engine.CancelAsync();
        if (_ownsEngine) await _engine.DisposeAsync();
    }

    private static Border MetricRow(string label, TextBlock value) => new Border
    {
        Background = PanelBrush,
        BorderBrush = BorderBrush,
        BorderThickness = new Thickness(1),
        CornerRadius = new CornerRadius(8),
        Padding = new Thickness(16, 12, 16, 12),
        Child = new Grid
        {
            ColumnDefinitions = { new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) }, new ColumnDefinition { Width = GridLength.Auto } },
            Children = { Label(label, 12, MutedBrush), value }
        }
    }.AlsoSetGridColumn(value, 1);

    private static TextBlock Label(string text, double size, Brush color) => new()
    {
        Text = text, FontFamily = new FontFamily("Barlow Semi Condensed"), FontSize = size,
        FontWeight = Microsoft.UI.Text.FontWeights.SemiBold, Foreground = color, CharacterSpacing = 60
    };

    private static TextBlock Title(string text) => new()
    {
        Text = text, FontFamily = new FontFamily("Barlow Semi Condensed"), FontSize = 30,
        FontWeight = Microsoft.UI.Text.FontWeights.ExtraBold, Foreground = TextBrush, TextWrapping = TextWrapping.Wrap
    };

    private static TextBlock Body(string text) => new()
    {
        Text = text, FontFamily = new FontFamily("Barlow"), FontSize = 15, Foreground = MutedBrush, TextWrapping = TextWrapping.Wrap
    };

    private static TextBlock Metric(string text) => new()
    {
        Text = text, FontFamily = new FontFamily("Chakra Petch"), FontSize = 18,
        FontWeight = Microsoft.UI.Text.FontWeights.SemiBold, Foreground = TextBrush, HorizontalAlignment = HorizontalAlignment.Right
    };

    private static void ApplyButtonStyle(Button button, Brush background, Brush foreground)
    {
        button.Background = background;
        button.Foreground = foreground;
        button.BorderBrush = BorderBrush;
        button.BorderThickness = new Thickness(1);
        button.FontFamily = new FontFamily("Barlow Semi Condensed");
        button.FontWeight = Microsoft.UI.Text.FontWeights.SemiBold;
    }

    private static string FormatMs(double? value) => value is { } milliseconds ? $"{milliseconds:0.#} ms" : "—";
    private static SolidColorBrush Brush(byte r, byte g, byte b) => new(Color.FromArgb(255, r, g, b));

    // Fixed public AWS-region coordinates used only to render a route after the host selected a real region.
    private static readonly IReadOnlyDictionary<string, (string Label, double Latitude, double Longitude)> RegionCoordinates =
        new Dictionary<string, (string, double, double)>(StringComparer.OrdinalIgnoreCase)
        {
            ["sa-east-1"] = ("São Paulo", -23.55, -46.63), ["us-east-1"] = ("Virgínia do Norte", 38.95, -77.45),
            ["us-east-2"] = ("Ohio", 39.96, -83.00), ["us-west-1"] = ("Norte da Califórnia", 37.34, -121.89),
            ["us-west-2"] = ("Oregon", 45.52, -122.68), ["ca-central-1"] = ("Canadá Central", 45.42, -75.70),
            ["eu-central-1"] = ("Frankfurt", 50.11, 8.68), ["eu-west-1"] = ("Irlanda", 53.35, -6.26),
            ["eu-west-2"] = ("Londres", 51.51, -0.13), ["eu-west-3"] = ("Paris", 48.86, 2.35),
            ["ap-northeast-1"] = ("Tóquio", 35.68, 139.69), ["ap-northeast-2"] = ("Seul", 37.57, 126.98),
            ["ap-southeast-1"] = ("Cingapura", 1.35, 103.82), ["ap-southeast-2"] = ("Sydney", -33.87, 151.21),
            ["ap-south-1"] = ("Mumbai", 19.08, 72.88), ["ap-east-1"] = ("Hong Kong", 22.32, 114.17),
            ["me-south-1"] = ("Bahrein", 26.22, 50.59), ["af-south-1"] = ("Cidade do Cabo", -33.92, 18.42),
        };
}

internal static class DiagnosticUiExtensions
{
    internal static Border AlsoSetGridColumn(this Border border, FrameworkElement child, int column)
    {
        Grid.SetColumn(child, column);
        return border;
    }
}
