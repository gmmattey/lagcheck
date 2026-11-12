using System.Text.Json;

namespace LagCheck.WinUI.Diagnostic;

/// <summary>
/// The UI only transports these messages. Metric calculation and verdict rules remain in core.
/// </summary>
public static class EngineProtocol
{
    public const string Version = "lagcheck-engine-v1";

    internal static readonly JsonSerializerOptions Json = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true,
    };
}

public sealed record EngineHello(string Protocol, string Engine);

public sealed record DiagnosticProgress(
    string SessionId,
    string Phase,
    double Ratio,
    double? LatestPingMs);

public sealed record DiagnosticResult(
    string SessionId,
    string Status,
    string? Verdict,
    int? Score,
    double? PingMs,
    double? JitterMs,
    double? PacketLossPercentage,
    double? WorstSpikeMs,
    bool LoadMeasured,
    string? RegionId,
    string? ProfileId,
    string? AbortReason,
    IReadOnlyList<double> LatencySeries);

public sealed record EngineCatalogGame(string Id, string Name, string? ArtworkResource, string? RegionId, string? RegionLabel);
public sealed record EngineHistoryEntry(string SessionId, string? Verdict, double? PingMs, double? JitterMs, double? PacketLossPercentage, string? RegionId, string? ProfileId);
public sealed record EngineSettings(bool ReduceMotion, bool ArtworkDownloadEnabled, bool ApproximateLocationEnabled, bool AnalyticsEnabled, bool AutomaticUpdates);
public sealed record EngineUpdateStatus(bool Configured, long? LastCheckedEpochMs, string State, string? Version);
public sealed record ApproximateLocation(bool Enabled, string? City, string? Country, double? Latitude, double? Longitude)
{
    public bool HasCoordinates => Latitude is >= -90 and <= 90 && Longitude is >= -180 and <= 180;
    public string Label => City ?? Country ?? "Local aproximado indisponível";
}

public sealed class DiagnosticEngineException : Exception
{
    public DiagnosticEngineException(string code, string message)
        : base(message)
    {
        Code = code;
    }

    public string Code { get; }
}

internal sealed class EngineWireMessage
{
    public string? Type { get; init; }
    public string? RequestId { get; init; }
    public string? SessionId { get; init; }
    public string? Protocol { get; init; }
    public string? Engine { get; init; }
    public string? Phase { get; init; }
    public double? Ratio { get; init; }
    public double? LatestPingMs { get; init; }
    public string? Status { get; init; }
    public string? Verdict { get; init; }
    public int? Score { get; init; }
    public double? PingMs { get; init; }
    public double? JitterMs { get; init; }
    public double? PacketLossPercentage { get; init; }
    public double? WorstSpikeMs { get; init; }
    public bool LoadMeasured { get; init; }
    public string? RegionId { get; init; }
    public string? ProfileId { get; init; }
    public string? AbortReason { get; init; }
    public double[]? LatencySeries { get; init; }
    public string? Code { get; init; }
    public string? Message { get; init; }
    public bool? Started { get; init; }
    public JsonElement? Snapshot { get; init; }
    public JsonElement? Games { get; init; }
    public JsonElement? Entries { get; init; }
    public JsonElement? Settings { get; init; }
    public JsonElement? Update { get; init; }
    public bool? Enabled { get; init; }
    public string? City { get; init; }
    public string? Country { get; init; }
    public double? Latitude { get; init; }
    public double? Longitude { get; init; }
}
