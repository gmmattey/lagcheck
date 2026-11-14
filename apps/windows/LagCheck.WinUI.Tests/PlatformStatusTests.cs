using System.Net;
using System.Text;
using LagCheck.WinUI.PlatformStatus;
using Xunit;

namespace LagCheck.WinUI.Tests;

public sealed class PlatformStatusTests
{
    private static readonly DateTimeOffset Now = new(2026, 11, 14, 15, 0, 0, TimeSpan.Zero);

    [Fact]
    public async Task Returns_all_known_platforms_from_a_valid_source_response()
    {
        var client = CreateClient(StatusPayload("operational", Now));

        var snapshot = await client.GetSnapshotAsync();

        Assert.Equal(PlatformStatusAvailability.Available, snapshot.Availability);
        Assert.Collection(snapshot.Platforms,
            item => Assert.Equal(("playstation", PlatformServiceState.Operational), (item.Id, item.State)),
            item => Assert.Equal(("xbox", PlatformServiceState.Operational), (item.Id, item.State)),
            item => Assert.Equal(("steam", PlatformServiceState.Operational), (item.Id, item.State)),
            item => Assert.Equal(("epicgames", PlatformServiceState.Operational), (item.Id, item.State)),
            item => Assert.Equal(("nintendo", PlatformServiceState.Operational), (item.Id, item.State)));
        Assert.Equal(Now, snapshot.Platforms[0].CheckedAt);
    }

    [Fact]
    public async Task Marks_invalid_states_and_missing_platforms_as_unknown()
    {
        const string payload = """
            {"platforms":[
              {"id":"steam","name":"Steam","status":"up","checkedAt":"2026-11-14T15:00:00Z"},
              {"id":"xbox","name":"Xbox","status":"operational","checkedAt":"not-a-date"}
            ]}
            """;
        var client = CreateClient(payload);

        var snapshot = await client.GetSnapshotAsync();

        Assert.Equal(PlatformStatusAvailability.Unavailable, snapshot.Availability);
        Assert.All(snapshot.Platforms, item => Assert.Equal(PlatformServiceState.Unknown, item.State));
    }

    [Fact]
    public async Task Makes_old_source_data_unknown_instead_of_green()
    {
        var client = CreateClient(StatusPayload("operational", Now - TimeSpan.FromMinutes(6)));

        var snapshot = await client.GetSnapshotAsync();

        Assert.Equal(PlatformStatusAvailability.Unavailable, snapshot.Availability);
        Assert.All(snapshot.Platforms, item => Assert.Equal(PlatformServiceState.Unknown, item.State));
    }

    [Fact]
    public async Task Uses_bounded_cache_until_a_manual_refresh()
    {
        var handler = new RecordingHandler(StatusPayload("operational", Now));
        using var httpClient = new HttpClient(handler);
        var client = new PlatformStatusClient(httpClient, new FixedTimeProvider(Now));

        await client.GetSnapshotAsync();
        await client.GetSnapshotAsync();
        await client.GetSnapshotAsync(forceRefresh: true);

        Assert.Equal(2, handler.RequestCount);
    }

    [Fact]
    public async Task Returns_unknown_without_throwing_for_failed_requests()
    {
        using var client = new HttpClient(new RecordingHandler("{}", HttpStatusCode.ServiceUnavailable));
        var statusClient = new PlatformStatusClient(client, new FixedTimeProvider(Now));

        var snapshot = await statusClient.GetSnapshotAsync();

        Assert.Equal(PlatformStatusAvailability.Unavailable, snapshot.Availability);
        Assert.All(snapshot.Platforms, item => Assert.Equal(PlatformServiceState.Unknown, item.State));
    }

    [Fact]
    public async Task Returns_unknown_when_the_response_stream_fails_after_headers()
    {
        using var httpClient = new HttpClient(new ThrowingStreamHandler());
        var statusClient = new PlatformStatusClient(httpClient, new FixedTimeProvider(Now));

        var snapshot = await statusClient.GetSnapshotAsync();

        Assert.Equal(PlatformStatusAvailability.Unavailable, snapshot.Availability);
        Assert.All(snapshot.Platforms, item => Assert.Equal(PlatformServiceState.Unknown, item.State));
    }

    private static PlatformStatusClient CreateClient(string payload)
    {
        var httpClient = new HttpClient(new RecordingHandler(payload));
        return new PlatformStatusClient(httpClient, new FixedTimeProvider(Now));
    }

    private static string StatusPayload(string state, DateTimeOffset checkedAt) => $$"""
        {"platforms":[
          {"id":"playstation","name":"PlayStation Network","status":"{{state}}","checkedAt":"{{checkedAt:O}}"},
          {"id":"xbox","name":"Xbox","status":"{{state}}","checkedAt":"{{checkedAt:O}}"},
          {"id":"steam","name":"Steam","status":"{{state}}","checkedAt":"{{checkedAt:O}}"},
          {"id":"epicgames","name":"Epic Games","status":"{{state}}","checkedAt":"{{checkedAt:O}}"},
          {"id":"nintendo","name":"Nintendo","status":"{{state}}","checkedAt":"{{checkedAt:O}}"}
        ]}
        """;

    private sealed class RecordingHandler(string payload, HttpStatusCode statusCode = HttpStatusCode.OK) : HttpMessageHandler
    {
        public int RequestCount { get; private set; }

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            RequestCount++;
            Assert.Equal(PlatformStatusClient.StatusEndpoint, request.RequestUri);
            return Task.FromResult(new HttpResponseMessage(statusCode)
            {
                Content = new StringContent(payload, Encoding.UTF8, "application/json"),
            });
        }
    }

    private sealed class FixedTimeProvider(DateTimeOffset now) : TimeProvider
    {
        public override DateTimeOffset GetUtcNow() => now;
    }

    private sealed class ThrowingStreamHandler : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken) =>
            Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StreamContent(new ThrowingStream()),
            });
    }

    private sealed class ThrowingStream : Stream
    {
        public override bool CanRead => true;
        public override bool CanSeek => false;
        public override bool CanWrite => false;
        public override long Length => throw new NotSupportedException();
        public override long Position { get => throw new NotSupportedException(); set => throw new NotSupportedException(); }
        public override void Flush() => throw new NotSupportedException();
        public override Task FlushAsync(CancellationToken cancellationToken) => throw new NotSupportedException();
        public override int Read(byte[] buffer, int offset, int count) => throw new IOException("network stream interrupted");
        public override ValueTask<int> ReadAsync(Memory<byte> buffer, CancellationToken cancellationToken = default) => ValueTask.FromException<int>(new IOException("network stream interrupted"));
        public override long Seek(long offset, SeekOrigin origin) => throw new NotSupportedException();
        public override void SetLength(long value) => throw new NotSupportedException();
        public override void Write(byte[] buffer, int offset, int count) => throw new NotSupportedException();
    }
}
