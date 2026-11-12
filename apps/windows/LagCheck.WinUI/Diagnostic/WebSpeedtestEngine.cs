using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using LagCheck.WinUI.Diagnostic.Rules;

namespace LagCheck.WinUI.Diagnostic;

/// <summary>
/// Coleta de amostras do protótipo Windows. Este tipo só mede: toda métrica, score e veredito vêm dos
/// avaliadores de Diagnostic.Rules (port 1:1 do domínio Android/iOS).
///
/// Transporte do protótipo: probes HTTPS contra os endpoints públicos de ping da AWS (DynamoDB /ping).
/// Cada probe vira um <see cref="ProbeSample"/> (recebido, timeout ou resposta inválida); nada é
/// preenchido por valor padrão. Sem 10 amostras válidas na região escolhida, o resultado é inconclusivo.
/// A carga é um download concorrente na Cloudflare enquanto a segunda janela de probes roda.
/// </summary>
public sealed class WebSpeedtestEngine
{
    private static readonly HttpClient ProbeClient = new(new SocketsHttpHandler
    {
        PooledConnectionLifetime = TimeSpan.FromMinutes(2),
        ConnectTimeout = TimeSpan.FromSeconds(3),
        EnableMultipleHttp2Connections = true
    })
    {
        Timeout = Timeout.InfiniteTimeSpan // o prazo de 2 s é aplicado por probe
    };

    private static readonly HttpClient LoadClient = new(new SocketsHttpHandler
    {
        ConnectTimeout = TimeSpan.FromSeconds(5)
    })
    {
        Timeout = Timeout.InfiniteTimeSpan // a janela de 15 s cancela a transferência
    };

    public static readonly IReadOnlyList<(string Id, string Name, string Url, double Latitude, double Longitude)> Regions =
    [
        ("sa-east-1", "São Paulo", "https://dynamodb.sa-east-1.amazonaws.com/ping", -23.55, -46.63),
        ("us-east-1", "Virgínia", "https://dynamodb.us-east-1.amazonaws.com/ping", 38.95, -77.45),
        ("us-west-2", "Oregon", "https://dynamodb.us-west-2.amazonaws.com/ping", 45.52, -122.68),
        ("eu-central-1", "Frankfurt", "https://dynamodb.eu-central-1.amazonaws.com/ping", 50.11, 8.68),
        ("eu-west-1", "Irlanda", "https://dynamodb.eu-west-1.amazonaws.com/ping", 53.35, -6.26),
        ("ap-northeast-1", "Tóquio", "https://dynamodb.ap-northeast-1.amazonaws.com/ping", 35.68, 139.69),
        ("ap-southeast-1", "Singapura", "https://dynamodb.ap-southeast-1.amazonaws.com/ping", 1.35, 103.82)
    ];

    private const string LoadUrl = "https://speed.cloudflare.com/__down?bytes=25000000";
    private const int LoadStreams = 4;

    /// <summary>Perfil do protótipo: jogo competitivo. Mapear por jogo exige o catálogo (fora do escopo do motor).</summary>
    public const QualityProfileId Profile = QualityProfileId.BattleRoyaleCompetitive;

    /// <summary>
    /// Rota genérica de referência (não é servidor de jogo): confiança média, margem de 10% do readiness-v2.0.
    /// </summary>
    public const MeasurementConfidence Confidence = MeasurementConfidence.Medium;

    private const string ProfileLabel = "BATTLE_ROYALE_COMPETITIVE";

    public async Task<DiagnosticResult> RunAsync(
        Action<DiagnosticProgress> onProgress,
        Action<string, double?> onRegionSample,
        CancellationToken cancellationToken)
    {
        var sessionId = Guid.NewGuid().ToString("N");

        // ETAPA 1: região de menor RTT medido. Sem região respondendo, não há o que medir.
        onProgress(new DiagnosticProgress(sessionId, "connect", 0.02, null));
        string? chosenId = null;
        double chosenRtt = double.MaxValue;
        for (int i = 0; i < Regions.Count; i++)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var reg = Regions[i];
            double? rtt = await ProbeRegionAsync(reg.Url, cancellationToken).ConfigureAwait(false);
            onRegionSample(reg.Id, rtt);
            if (rtt is { } value && value < chosenRtt)
            {
                chosenRtt = value;
                chosenId = reg.Id;
            }
            onProgress(new DiagnosticProgress(sessionId, "connect", 0.02 + 0.13 * (i + 1) / Regions.Count, rtt));
        }

        if (chosenId is null)
        {
            return Inconclusive(sessionId, null, restDiagnostics: null, series: []);
        }

        string chosenUrl = Regions.First(r => r.Id == chosenId).Url;

        // ETAPA 2: janela de repouso (30 probes, 2/s, prazo de 2 s por probe).
        var restSeries = new List<double>();
        var rest = await RunProbeWindowAsync(
            chosenUrl,
            sampleOnDone: (sample, all) =>
            {
                double ratio = 0.15 + 0.40 * all.Count / ProbeAcceptancePolicy.PlannedProbeCount;
                onProgress(new DiagnosticProgress(sessionId, "rest", Math.Min(ratio, 0.55), sample.RoundTripMilliseconds,
                    LiveJitterMs: LiveJitter(all)));
            },
            abortOnPoorQuality: true,
            cancellationToken).ConfigureAwait(false);

        var restEvaluation = QualityEvaluator.Evaluate(rest.Samples, Profile);
        if (rest.Aborted || restEvaluation is not MeasurementEvaluation.Completed)
        {
            var diagnostics = (restEvaluation as MeasurementEvaluation.Inconclusive)?.Diagnostics;
            return Inconclusive(sessionId, chosenId, diagnostics, ValidSeries(rest.Samples));
        }
        restSeries.AddRange(ValidSeries(rest.Samples));
        double? restP50 = ((MeasurementEvaluation.Completed)restEvaluation).Result.Metrics.P50Milliseconds;

        // ETAPA 3: janela sob carga. O download roda durante toda a janela; falha da transferência
        // remove a conclusão de carga sem invalidar o repouso (spec 5.3).
        using var loadCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        var load = new LoadGenerator();
        var loadTask = load.RunAsync(loadCts.Token);

        WindowResult loadWindow;
        try
        {
            loadWindow = await RunProbeWindowAsync(
                chosenUrl,
                sampleOnDone: (sample, all) =>
                {
                    double ratio = 0.55 + 0.40 * all.Count / ProbeAcceptancePolicy.PlannedProbeCount;
                    double? loadP50 = restP50 is not null ? LiveP50(all) : null;
                    onProgress(new DiagnosticProgress(sessionId, "load", Math.Min(ratio, 0.95), sample.RoundTripMilliseconds,
                        LiveJitterMs: LiveJitter(all),
                        LiveLoadDeltaMs: loadP50 is { } lp && restP50 is { } rp ? Math.Max(0.0, lp - rp) : null));
                },
                abortOnPoorQuality: false,
                cancellationToken).ConfigureAwait(false);
        }
        finally
        {
            loadCts.Cancel();
            await loadTask.ConfigureAwait(false);
        }

        // Carga só vale se a transferência esteve ativa durante a janela inteira.
        IReadOnlyList<ProbeSample>? loadSamples = load.CoveredWholeWindow ? loadWindow.Samples : null;

        // ETAPA 4: análise. Tudo sai do domínio canônico.
        onProgress(new DiagnosticProgress(sessionId, "analysis", 0.98, restP50));
        var deep = DeepCheckEvaluator.Evaluate(rest.Samples, loadSamples, Profile);
        if (deep is not DeepCheckEvaluation.Completed completed)
        {
            return Inconclusive(sessionId, chosenId, (restEvaluation as MeasurementEvaluation.Inconclusive)?.Diagnostics, restSeries);
        }

        var assessment = GameReadinessEvaluator.Evaluate(rest.Samples, loadSamples, Profile, Confidence);
        if (assessment.Verdict == GameReadinessVerdict.Inconclusive)
        {
            return Inconclusive(sessionId, chosenId, completed.Result.RestResult.Metrics, restSeries);
        }

        var impact = completed.Result.Metrics.LoadImpact;
        var series = new List<double>(restSeries);
        if (loadSamples is not null) series.AddRange(ValidSeries(loadSamples));

        return new DiagnosticResult(
            SessionId: sessionId,
            Status: "completed",
            Verdict: VerdictWire(assessment.Verdict),
            Score: assessment.Score,
            PingMs: Round1(assessment.PingMs),
            JitterMs: Round1(assessment.JitterMs),
            PacketLossPercentage: Round1(assessment.PacketLossPercentage),
            WorstSpikeMs: Round1(assessment.WorstSpikeMs),
            LoadMeasured: impact is not null,
            RegionId: chosenId,
            ProfileId: ProfileLabel,
            AbortReason: null,
            LatencySeries: series.ToArray(),
            LoadDeltaMs: impact is null ? null : Round1(Math.Max(0.0, impact.IncreaseMilliseconds)),
            LoadTier: impact?.Tier.ToString());
    }

    public static string VerdictWire(GameReadinessVerdict verdict) => verdict switch
    {
        GameReadinessVerdict.Ready => "ready",
        GameReadinessVerdict.Caution => "caution",
        GameReadinessVerdict.NotReady => "not_ready",
        _ => "inconclusive"
    };

    private static DiagnosticResult Inconclusive(string sessionId, string? regionId, QualityMetrics? restDiagnostics, IReadOnlyList<double> series) =>
        new(
            SessionId: sessionId,
            Status: "inconclusive",
            Verdict: "inconclusive",
            Score: null,
            PingMs: Round1(restDiagnostics?.P50Milliseconds),
            JitterMs: Round1(restDiagnostics?.JitterMilliseconds),
            PacketLossPercentage: restDiagnostics is null ? null : Round1(restDiagnostics.PacketLossPercentage),
            WorstSpikeMs: null,
            LoadMeasured: false,
            RegionId: regionId,
            ProfileId: ProfileLabel,
            AbortReason: "insufficient_valid_responses",
            LatencySeries: series.ToArray());

    private static double? Round1(double? value) => value is { } v ? Math.Round(v, 1) : null;

    private static double[] ValidSeries(IReadOnlyList<ProbeSample> samples) =>
        samples.Where(s => s.IsValidResponse).OrderBy(s => s.Sequence).Select(s => s.RoundTripMilliseconds!.Value).ToArray();

    private static double? LiveJitter(IReadOnlyList<ProbeSample> samples)
    {
        var rtts = ValidSeries(samples);
        return rtts.Length >= 2 ? QualityEvaluator.AverageAdjacentDifference(rtts) : null;
    }

    private static double? LiveP50(IReadOnlyList<ProbeSample> samples)
    {
        var rtts = ValidSeries(samples);
        return rtts.Length >= 1 ? QualityEvaluator.Percentile(rtts, 0.50) : null;
    }

    private sealed record WindowResult(IReadOnlyList<ProbeSample> Samples, bool Aborted);

    /// <summary>
    /// Envia <see cref="ProbeAcceptancePolicy.PlannedProbeCount"/> probes a cada 500 ms, sem esperar a resposta
    /// do anterior. Cada probe escreve só na própria posição do vetor, então não há lock; a ordem de chegada
    /// vem de um contador atômico.
    /// </summary>
    private static async Task<WindowResult> RunProbeWindowAsync(
        string url,
        Action<ProbeSample, IReadOnlyList<ProbeSample>> sampleOnDone,
        bool abortOnPoorQuality,
        CancellationToken cancellationToken)
    {
        int planned = ProbeAcceptancePolicy.PlannedProbeCount;
        var slots = new ProbeSample?[planned];
        int arrivals = -1;
        var gate = new object();
        using var windowCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        int aborted = 0;
        var tasks = new List<Task>(planned);

        IReadOnlyList<ProbeSample> Snapshot()
        {
            lock (gate) return slots.Where(s => s is not null).Select(s => s!).ToList();
        }

        for (int seq = 0; seq < planned; seq++)
        {
            if (windowCts.IsCancellationRequested) break;
            int sequence = seq;
            tasks.Add(Task.Run(async () =>
            {
                var sample = await SendProbeAsync(url, sequence, () => Interlocked.Increment(ref arrivals), windowCts.Token).ConfigureAwait(false);
                if (sample is null) return; // janela cancelada: probe pendente não vira amostra
                IReadOnlyList<ProbeSample> snapshot;
                lock (gate)
                {
                    slots[sequence] = sample;
                    snapshot = slots.Where(s => s is not null).Select(s => s!).ToList();
                }
                sampleOnDone(sample, snapshot);
                if (abortOnPoorQuality && SampleQualityEvaluator.Assess(snapshot).ShouldAbort)
                {
                    Interlocked.Exchange(ref aborted, 1);
                    windowCts.Cancel();
                }
            }, CancellationToken.None));

            if (seq < planned - 1)
            {
                try { await Task.Delay(ProbeAcceptancePolicy.SendIntervalMillis, windowCts.Token).ConfigureAwait(false); }
                catch (OperationCanceledException) { break; }
            }
        }

        await Task.WhenAll(tasks).ConfigureAwait(false);
        cancellationToken.ThrowIfCancellationRequested();
        return new WindowResult(Snapshot(), Volatile.Read(ref aborted) == 1);
    }

    /// <summary>
    /// Um probe: RTT = recebido − enviado, só aceito se chegar em menos de 2 s com resposta HTTP de sucesso.
    /// Resposta fora do prazo é timeout; resposta de erro é inválida e nunca vira RTT. Devolve null se a
    /// janela foi cancelada antes do desfecho.
    /// </summary>
    private static async Task<ProbeSample?> SendProbeAsync(string url, int sequence, Func<int> nextArrival, CancellationToken windowToken)
    {
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(windowToken);
        timeout.CancelAfter(ProbeAcceptancePolicy.TimeoutMillis);
        long start = Stopwatch.GetTimestamp();
        try
        {
            using var req = new HttpRequestMessage(HttpMethod.Get, url);
            req.Headers.Add("Cache-Control", "no-cache");
            using var resp = await ProbeClient.SendAsync(req, HttpCompletionOption.ResponseHeadersRead, timeout.Token).ConfigureAwait(false);
            double ms = Stopwatch.GetElapsedTime(start).TotalMilliseconds;
            if (ms >= ProbeAcceptancePolicy.TimeoutMillis) return ProbeSample.Timeout(sequence);
            if (!resp.IsSuccessStatusCode) return new ProbeSample(sequence, null, ProbeOutcome.InvalidResponse);
            return ProbeSample.Received(sequence, Math.Round(ms, 1), nextArrival());
        }
        catch (OperationCanceledException)
        {
            return windowToken.IsCancellationRequested ? null : ProbeSample.Timeout(sequence);
        }
        catch (HttpRequestException)
        {
            return new ProbeSample(sequence, null, ProbeOutcome.TransportError);
        }
    }

    /// <summary>Menor de dois RTTs: o primeiro aquece a conexão (TCP + TLS) e não representa a rota.</summary>
    private static async Task<double?> ProbeRegionAsync(string url, CancellationToken cancellationToken)
    {
        double? best = null;
        for (int i = 0; i < 2; i++)
        {
            var sample = await SendProbeAsync(url, i, static () => 0, cancellationToken).ConfigureAwait(false);
            cancellationToken.ThrowIfCancellationRequested();
            if (sample is { IsValidResponse: true } && (best is null || sample.RoundTripMilliseconds < best))
                best = sample.RoundTripMilliseconds;
        }
        return best;
    }

    /// <summary>
    /// Gera carga de download concorrente até ser cancelado (fim da janela de 15 s). Registra se ao menos
    /// uma transferência esteve ativa o tempo todo; se todas falharem, a carga é descartada.
    /// </summary>
    private sealed class LoadGenerator
    {
        private int _failedStreams;
        private long _bytes;

        /// <summary>Verdadeiro se nenhuma transferência morreu por erro e algum byte chegou.</summary>
        public bool CoveredWholeWindow => Volatile.Read(ref _failedStreams) == 0 && Interlocked.Read(ref _bytes) > 0;

        public async Task RunAsync(CancellationToken token)
        {
            var streams = Enumerable.Range(0, LoadStreams).Select(_ => Task.Run(() => StreamAsync(token), CancellationToken.None));
            await Task.WhenAll(streams).ConfigureAwait(false);
        }

        private async Task StreamAsync(CancellationToken token)
        {
            var buffer = new byte[64 * 1024];
            try
            {
                while (!token.IsCancellationRequested)
                {
                    using var resp = await LoadClient.GetAsync(LoadUrl, HttpCompletionOption.ResponseHeadersRead, token).ConfigureAwait(false);
                    resp.EnsureSuccessStatusCode();
                    await using var body = await resp.Content.ReadAsStreamAsync(token).ConfigureAwait(false);
                    int read;
                    while ((read = await body.ReadAsync(buffer, token).ConfigureAwait(false)) > 0)
                        Interlocked.Add(ref _bytes, read);
                }
            }
            catch (OperationCanceledException)
            {
                // fim normal da janela
            }
            catch (Exception) when (!token.IsCancellationRequested)
            {
                Interlocked.Increment(ref _failedStreams);
            }
            catch (Exception)
            {
                // erro de leitura causado pelo cancelamento do fim da janela
            }
        }
    }
}
