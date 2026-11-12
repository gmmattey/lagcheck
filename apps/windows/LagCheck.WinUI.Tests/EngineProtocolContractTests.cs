using System.Text.Json;
using LagCheck.WinUI.Diagnostic;
using Xunit;

namespace LagCheck.WinUI.Tests;

public sealed class EngineProtocolContractTests
{
    [Fact]
    public void Version_is_lagcheck_engine_v1()
    {
        Assert.Equal("lagcheck-engine-v1", EngineProtocol.Version);
    }

    [Fact]
    public void Deserializes_hello_message()
    {
        const string json = "{\"type\":\"hello\",\"protocol\":\"lagcheck-engine-v1\",\"engine\":\"kotlin-core\"}";
        var msg = JsonSerializer.Deserialize<EngineWireMessage>(json, EngineProtocol.Json);
        Assert.NotNull(msg);
        Assert.Equal("hello", msg.Type);
        Assert.Equal("lagcheck-engine-v1", msg.Protocol);
        Assert.Equal("kotlin-core", msg.Engine);
    }

    [Fact]
    public void Deserializes_progress_with_live_jitter_and_load_delta()
    {
        const string json = "{\"type\":\"progress\",\"sessionId\":\"sess-123\",\"phase\":\"load\",\"ratio\":0.75,\"latestPingMs\":18.4,\"liveJitterMs\":1.8,\"liveLoadDeltaMs\":4.2}";
        var msg = JsonSerializer.Deserialize<EngineWireMessage>(json, EngineProtocol.Json);
        Assert.NotNull(msg);
        Assert.Equal("progress", msg.Type);
        Assert.Equal("sess-123", msg.SessionId);
        Assert.Equal("load", msg.Phase);
        Assert.Equal(0.75, msg.Ratio);
        Assert.Equal(18.4, msg.LatestPingMs);
        Assert.Equal(1.8, msg.LiveJitterMs);
        Assert.Equal(4.2, msg.LiveLoadDeltaMs);

        var progress = new DiagnosticProgress(
            msg.SessionId!,
            msg.Phase ?? "rest",
            msg.Ratio ?? 0,
            msg.LatestPingMs,
            msg.LiveJitterMs,
            msg.LiveLoadDeltaMs);

        Assert.Equal(1.8, progress.LiveJitterMs);
        Assert.Equal(4.2, progress.LiveLoadDeltaMs);
    }

    [Fact]
    public void Deserializes_result_with_load_metrics()
    {
        const string json = "{\"type\":\"result\",\"sessionId\":\"sess-456\",\"status\":\"completed\",\"verdict\":\"ready\",\"score\":94,\"pingMs\":15.2,\"jitterMs\":0.8,\"packetLossPercentage\":0.0,\"worstSpikeMs\":21.0,\"loadMeasured\":true,\"loadDeltaMs\":2.5,\"loadTier\":\"optimal\",\"regionId\":\"sa-east-1\",\"profileId\":\"BattleRoyaleCompetitive\"}";
        var msg = JsonSerializer.Deserialize<EngineWireMessage>(json, EngineProtocol.Json);
        Assert.NotNull(msg);
        Assert.Equal("result", msg.Type);
        Assert.Equal("ready", msg.Verdict);
        Assert.Equal(94, msg.Score);
        Assert.Equal(15.2, msg.PingMs);
        Assert.Equal(2.5, msg.LoadDeltaMs);
        Assert.Equal("optimal", msg.LoadTier);
        Assert.Equal("sa-east-1", msg.RegionId);
    }

    [Fact]
    public void DiagnosticResult_retains_gameId()
    {
        var result = new DiagnosticResult(
            SessionId: "sess-789",
            Status: "completed",
            Verdict: "ready",
            Score: 92,
            PingMs: 14.0,
            JitterMs: 1.0,
            PacketLossPercentage: 0.0,
            WorstSpikeMs: 19.0,
            LoadMeasured: true,
            RegionId: "sa-east-1",
            ProfileId: "BattleRoyaleCompetitive",
            AbortReason: null,
            LatencySeries: [14.0, 15.0],
            GameId: "warzone"
        );

        Assert.Equal("warzone", result.GameId);
        Assert.Equal("ready", result.Verdict);
    }
}
