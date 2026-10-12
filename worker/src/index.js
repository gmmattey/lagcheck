import CATALOG_ENVELOPE from "../catalog/catalog-v3.envelope.json" with { type: "json" };

const LOAD_BYTES = 10 * 1024 * 1024;
const CHUNK_BYTES = 64 * 1024;

// O Worker não assina em tempo de requisição e não contém chave privada. Este
// envelope Debug já foi assinado sobre os bytes de payloadBase64 decodificados.
const LEGACY_CATALOG_ENVELOPE = {
  schemaVersion: 1,
  catalogVersion: "debug-2026.09.18.1",
  issuedAt: "2026-09-18T00:00:00Z",
  expiresAt: "2026-10-18T00:00:00Z",
  algorithm: "Ed25519",
  payloadBase64: "eyJzY2hlbWFWZXJzaW9uIjoxLCJjYXRhbG9nVmVyc2lvbiI6ImRlYnVnLTIwMjYuMDkuMTguMSIsInByb2ZpbGVzIjpbeyJpZCI6IkJBVFRMRV9ST1lBTEVfQ09NUEVUSVRJVkUiLCJydWxlVmVyc2lvbiI6InBpbG90LTIwMjYuMDkuMDguMSJ9LHsiaWQiOiJNT0JJTEVfUkVBTFRJTUUiLCJydWxlVmVyc2lvbiI6Im1vYmlsZS1yZWFsdGltZS0yMDI2LjA5LjA4LjEifSx7ImlkIjoiQ0FTVUFMX1JFQUxUSU1FIiwicnVsZVZlcnNpb24iOiJjYXN1YWwtcmVhbHRpbWUtMjAyNi4wOS4wOC4xIn1dLCJyZWdpb25zIjpbeyJpZCI6InNhLWVhc3QtMSIsImxhYmVsIjp7InB0LUJSIjoiU8OjbyBQYXVsbyIsImVuIjoiU8OjbyBQYXVsbyJ9LCJwcm9iZSI6eyJob3N0IjoiZ2FtZWxpZnQtcGluZy5zYS1lYXN0LTEuYXBpLmF3cyIsInBvcnQiOjc3NzB9fV0sImdhbWVzIjpbeyJpZCI6ImZvcnRuaXRlIiwibmFtZSI6IkZvcnRuaXRlIiwiY29udGV4dHMiOlt7Im1hcmtldCI6IkJSIiwicGxhdGZvcm1zIjpbImlwaG9uZSJdLCJwcm9maWxlSUQiOiJCQVRUTEVfUk9ZQUxFX0NPTVBFVElUSVZFIiwiYXZhaWxhYmlsaXR5IjoiYXZhaWxhYmxlIiwibWVhc3VyZW1lbnQiOnsicHJpbWFyeVJlZ2lvbiI6InNhLWVhc3QtMSIsInN0cmF0ZWd5IjoiZ2VuZXJpY1JlZ2lvbiIsImNvbmZpZGVuY2UiOiJtZWRpdW0iLCJwcmVjaXNpb25LZXkiOiJyZWdpb25hbFJlZmVyZW5jZSJ9fV19LHsiaWQiOiJjYWxsLW9mLWR1dHktbW9iaWxlIiwibmFtZSI6IkNhbGwgb2YgRHV0eTogTW9iaWxlIiwiY29udGV4dHMiOlt7Im1hcmtldCI6IkJSIiwicGxhdGZvcm1zIjpbImlwaG9uZSJdLCJwcm9maWxlSUQiOiJCQVRUTEVfUk9ZQUxFX0NPTVBFVElUSVZFIiwiYXZhaWxhYmlsaXR5IjoiYXZhaWxhYmxlIiwibWVhc3VyZW1lbnQiOnsicHJpbWFyeVJlZ2lvbiI6InNhLWVhc3QtMSIsInN0cmF0ZWd5IjoiZ2VuZXJpY1JlZ2lvbiIsImNvbmZpZGVuY2UiOiJtZWRpdW0iLCJwcmVjaXNpb25LZXkiOiJyZWdpb25hbFJlZmVyZW5jZSJ9fV19LHsiaWQiOiJmcmVlLWZpcmUiLCJuYW1lIjoiRnJlZSBGaXJlIiwiY29udGV4dHMiOlt7Im1hcmtldCI6IkJSIiwicGxhdGZvcm1zIjpbImlwaG9uZSJdLCJwcm9maWxlSUQiOiJCQVRUTEVfUk9ZQUxFX0NPTVBFVElUSVZFIiwiYXZhaWxhYmlsaXR5IjoiYXZhaWxhYmxlIiwibWVhc3VyZW1lbnQiOnsicHJpbWFyeVJlZ2lvbiI6InNhLWVhc3QtMSIsInN0cmF0ZWd5IjoiZ2VuZXJpY1JlZ2lvbiIsImNvbmZpZGVuY2UiOiJtZWRpdW0iLCJwcmVjaXNpb25LZXkiOiJyZWdpb25hbFJlZmVyZW5jZSJ9fV19LHsiaWQiOiJwdWJnLW1vYmlsZSIsIm5hbWUiOiJQVUJHIE1PQklMRSIsImNvbnRleHRzIjpbeyJtYXJrZXQiOiJCUiIsInBsYXRmb3JtcyI6WyJpcGhvbmUiXSwicHJvZmlsZUlEIjoiQkFUVExFX1JPWUFMRV9DT01QRVRJVElWRSIsImF2YWlsYWJpbGl0eSI6ImF2YWlsYWJsZSIsIm1lYXN1cmVtZW50Ijp7InByaW1hcnlSZWdpb24iOiJzYS1lYXN0LTEiLCJzdHJhdGVneSI6ImdlbmVyaWNSZWdpb24iLCJjb25maWRlbmNlIjoibWVkaXVtIiwicHJlY2lzaW9uS2V5IjoicmVnaW9uYWxSZWZlcmVuY2UifX1dfSx7ImlkIjoiYnJhd2wtc3RhcnMiLCJuYW1lIjoiQnJhd2wgU3RhcnMiLCJjb250ZXh0cyI6W3sibWFya2V0IjoiQlIiLCJwbGF0Zm9ybXMiOlsiaXBob25lIl0sInByb2ZpbGVJRCI6Ik1PQklMRV9SRUFMVElNRSIsImF2YWlsYWJpbGl0eSI6ImF2YWlsYWJsZSIsIm1lYXN1cmVtZW50Ijp7InByaW1hcnlSZWdpb24iOiJzYS1lYXN0LTEiLCJzdHJhdGVneSI6ImdlbmVyaWNSZWdpb24iLCJjb25maWRlbmNlIjoibWVkaXVtIiwicHJlY2lzaW9uS2V5IjoicmVnaW9uYWxSZWZlcmVuY2UifX1dfSx7ImlkIjoid2lsZC1yaWZ0IiwibmFtZSI6IkxlYWd1ZSBvZiBMZWdlbmRzOiBXaWxkIFJpZnQiLCJjb250ZXh0cyI6W3sibWFya2V0IjoiQlIiLCJwbGF0Zm9ybXMiOlsiaXBob25lIl0sInByb2ZpbGVJRCI6Ik1PQklMRV9SRUFMVElNRSIsImF2YWlsYWJpbGl0eSI6ImF2YWlsYWJsZSIsIm1lYXN1cmVtZW50Ijp7InByaW1hcnlSZWdpb24iOiJzYS1lYXN0LTEiLCJzdHJhdGVneSI6ImdlbmVyaWNSZWdpb24iLCJjb25maWRlbmNlIjoibWVkaXVtIiwicHJlY2lzaW9uS2V5IjoicmVnaW9uYWxSZWZlcmVuY2UifX1dfSx7ImlkIjoicm9ibG94IiwibmFtZSI6IlJvYmxveCIsImNvbnRleHRzIjpbeyJtYXJrZXQiOiJCUiIsInBsYXRmb3JtcyI6WyJpcGhvbmUiXSwicHJvZmlsZUlEIjoiQ0FTVUFMX1JFQUxUSU1FIiwiYXZhaWxhYmlsaXR5IjoiYXZhaWxhYmxlIiwibWVhc3VyZW1lbnQiOnsicHJpbWFyeVJlZ2lvbiI6InNhLWVhc3QtMSIsInN0cmF0ZWd5IjoiZ2VuZXJpY1JlZ2lvbiIsImNvbmZpZGVuY2UiOiJtZWRpdW0iLCJwcmVjaXNpb25LZXkiOiJyZWdpb25hbFJlZmVyZW5jZSJ9fV19LHsiaWQiOiJtaW5lY3JhZnQiLCJuYW1lIjoiTWluZWNyYWZ0IiwiY29udGV4dHMiOlt7Im1hcmtldCI6IkJSIiwicGxhdGZvcm1zIjpbImlwaG9uZSJdLCJwcm9maWxlSUQiOiJDQVNVQUxfUkVBTFRJTUUiLCJhdmFpbGFiaWxpdHkiOiJhdmFpbGFibGUiLCJtZWFzdXJlbWVudCI6eyJwcmltYXJ5UmVnaW9uIjoic2EtZWFzdC0xIiwic3RyYXRlZ3kiOiJnZW5lcmljUmVnaW9uIiwiY29uZmlkZW5jZSI6Im1lZGl1bSIsInByZWNpc2lvbktleSI6InJlZ2lvbmFsUmVmZXJlbmNlIn19XX0seyJpZCI6ImFwZXgtbGVnZW5kcyIsIm5hbWUiOiJBcGV4IExlZ2VuZHMiLCJjb250ZXh0cyI6W3sibWFya2V0IjoiQlIiLCJwbGF0Zm9ybXMiOlsiaXBob25lIl0sInByb2ZpbGVJRCI6IkJBVFRMRV9ST1lBTEVfQ09NUEVUSVRJVkUiLCJhdmFpbGFiaWxpdHkiOiJhdmFpbGFibGUiLCJtZWFzdXJlbWVudCI6eyJwcmltYXJ5UmVnaW9uIjoic2EtZWFzdC0xIiwic3RyYXRlZ3kiOiJnZW5lcmljUmVnaW9uIiwiY29uZmlkZW5jZSI6Im1lZGl1bSIsInByZWNpc2lvbktleSI6InJlZ2lvbmFsUmVmZXJlbmNlIn19XX0seyJpZCI6ImJsb29kLXN0cmlrZSIsIm5hbWUiOiJCbG9vZCBTdHJpa2UiLCJjb250ZXh0cyI6W3sibWFya2V0IjoiQlIiLCJwbGF0Zm9ybXMiOlsiaXBob25lIl0sInByb2ZpbGVJRCI6IkJBVFRMRV9ST1lBTEVfQ09NUEVUSVRJVkUiLCJhdmFpbGFiaWxpdHkiOiJhdmFpbGFibGUiLCJtZWFzdXJlbWVudCI6eyJwcmltYXJ5UmVnaW9uIjoic2EtZWFzdC0xIiwic3RyYXRlZ3kiOiJnZW5lcmljUmVnaW9uIiwiY29uZmlkZW5jZSI6Im1lZGl1bSIsInByZWNpc2lvbktleSI6InJlZ2lvbmFsUmVmZXJlbmNlIn19XX0seyJpZCI6ImNzMiIsIm5hbWUiOiJDb3VudGVyLVN0cmlrZSAyIiwiY29udGV4dHMiOlt7Im1hcmtldCI6IkJSIiwicGxhdGZvcm1zIjpbImlwaG9uZSJdLCJwcm9maWxlSUQiOiJCQVRUTEVfUk9ZQUxFX0NPTVBFVElUSVZFIiwiYXZhaWxhYmlsaXR5IjoiYXZhaWxhYmxlIiwibWVhc3VyZW1lbnQiOnsicHJpbWFyeVJlZ2lvbiI6InNhLWVhc3QtMSIsInN0cmF0ZWd5IjoiZ2VuZXJpY1JlZ2lvbiIsImNvbmZpZGVuY2UiOiJtZWRpdW0iLCJwcmVjaXNpb25LZXkiOiJyZWdpb25hbFJlZmVyZW5jZSJ9fV19LHsiaWQiOiJkb3RhMiIsIm5hbWUiOiJEb3RhIDIiLCJjb250ZXh0cyI6W3sibWFya2V0IjoiQlIiLCJwbGF0Zm9ybXMiOlsiaXBob25lIl0sInByb2ZpbGVJRCI6Ik1PQklMRV9SRUFMVElNRSIsImF2YWlsYWJpbGl0eSI6ImF2YWlsYWJsZSIsIm1lYXN1cmVtZW50Ijp7InByaW1hcnlSZWdpb24iOiJzYS1lYXN0LTEiLCJzdHJhdGVneSI6ImdlbmVyaWNSZWdpb24iLCJjb25maWRlbmNlIjoibWVkaXVtIiwicHJlY2lzaW9uS2V5IjoicmVnaW9uYWxSZWZlcmVuY2UifX1dfSx7ImlkIjoiZWFmYyIsIm5hbWUiOiJFQSBTcG9ydHMgRkMgMjQiLCJjb250ZXh0cyI6W3sibWFya2V0IjoiQlIiLCJwbGF0Zm9ybXMiOlsiaXBob25lIl0sInByb2ZpbGVJRCI6IkNBU1VBTF9SRUFMVElNRSIsImF2YWlsYWJpbGl0eSI6ImF2YWlsYWJsZSIsIm1lYXN1cmVtZW50Ijp7InByaW1hcnlSZWdpb24iOiJzYS1lYXN0LTEiLCJzdHJhdGVneSI6ImdlbmVyaWNSZWdpb24iLCJjb25maWRlbmNlIjoibWVkaXVtIiwicHJlY2lzaW9uS2V5IjoicmVnaW9uYWxSZWZlcmVuY2UifX1dfSx7ImlkIjoibGVhZ3VlLW9mLWxlZ2VuZHMiLCJuYW1lIjoiTGVhZ3VlIG9mIExlZ2VuZHMiLCJjb250ZXh0cyI6W3sibWFya2V0IjoiQlIiLCJwbGF0Zm9ybXMiOlsiaXBob25lIl0sInByb2ZpbGVJRCI6Ik1PQklMRV9SRUFMVElNRSIsImF2YWlsYWJpbGl0eSI6ImF2YWlsYWJsZSIsIm1lYXN1cmVtZW50Ijp7InByaW1hcnlSZWdpb24iOiJzYS1lYXN0LTEiLCJzdHJhdGVneSI6ImdlbmVyaWNSZWdpb24iLCJjb25maWRlbmNlIjoibWVkaXVtIiwicHJlY2lzaW9uS2V5IjoicmVnaW9uYWxSZWZlcmVuY2UifX1dfSx7ImlkIjoicGFsd29ybGQiLCJuYW1lIjoiUGFsd29ybGQiLCJjb250ZXh0cyI6W3sibWFya2V0IjoiQlIiLCJwbGF0Zm9ybXMiOlsiaXBob25lIl0sInByb2ZpbGVJRCI6IkNBU1VBTF9SRUFMVElNRSIsImF2YWlsYWJpbGl0eSI6ImF2YWlsYWJsZSIsIm1lYXN1cmVtZW50Ijp7InByaW1hcnlSZWdpb24iOiJzYS1lYXN0LTEiLCJzdHJhdGVneSI6ImdlbmVyaWNSZWdpb24iLCJjb25maWRlbmNlIjoibWVkaXVtIiwicHJlY2lzaW9uS2V5IjoicmVnaW9uYWxSZWZlcmVuY2UifX1dfSx7ImlkIjoicmFpbmJvdy1zaXgiLCJuYW1lIjoiUmFpbmJvdyBTaXggU2llZ2UiLCJjb250ZXh0cyI6W3sibWFya2V0IjoiQlIiLCJwbGF0Zm9ybXMiOlsiaXBob25lIl0sInByb2ZpbGVJRCI6IkJBVFRMRV9ST1lBTEVfQ09NUEVUSVRJVkUiLCJhdmFpbGFiaWxpdHkiOiJhdmFpbGFibGUiLCJtZWFzdXJlbWVudCI6eyJwcmltYXJ5UmVnaW9uIjoic2EtZWFzdC0xIiwic3RyYXRlZ3kiOiJnZW5lcmljUmVnaW9uIiwiY29uZmlkZW5jZSI6Im1lZGl1bSIsInByZWNpc2lvbktleSI6InJlZ2lvbmFsUmVmZXJlbmNlIn19XX0seyJpZCI6InJvY2tldC1sZWFndWUiLCJuYW1lIjoiUm9ja2V0IExlYWd1ZSIsImNvbnRleHRzIjpbeyJtYXJrZXQiOiJCUiIsInBsYXRmb3JtcyI6WyJpcGhvbmUiXSwicHJvZmlsZUlEIjoiQ0FTVUFMX1JFQUxUSU1FIiwiYXZhaWxhYmlsaXR5IjoiYXZhaWxhYmxlIiwibWVhc3VyZW1lbnQiOnsicHJpbWFyeVJlZ2lvbiI6InNhLWVhc3QtMSIsInN0cmF0ZWd5IjoiZ2VuZXJpY1JlZ2lvbiIsImNvbmZpZGVuY2UiOiJtZWRpdW0iLCJwcmVjaXNpb25LZXkiOiJyZWdpb25hbFJlZmVyZW5jZSJ9fV19LHsiaWQiOiJydXN0IiwibmFtZSI6IlJ1c3QiLCJjb250ZXh0cyI6W3sibWFya2V0IjoiQlIiLCJwbGF0Zm9ybXMiOlsiaXBob25lIl0sInByb2ZpbGVJRCI6IkNBU1VBTF9SRUFMVElNRSIsImF2YWlsYWJpbGl0eSI6ImF2YWlsYWJsZSIsIm1lYXN1cmVtZW50Ijp7InByaW1hcnlSZWdpb24iOiJzYS1lYXN0LTEiLCJzdHJhdGVneSI6ImdlbmVyaWNSZWdpb24iLCJjb25maWRlbmNlIjoibWVkaXVtIiwicHJlY2lzaW9uS2V5IjoicmVnaW9uYWxSZWZlcmVuY2UifX1dfSx7ImlkIjoidmFsb3JhbnQiLCJuYW1lIjoiVkFMT1JBTlQiLCJjb250ZXh0cyI6W3sibWFya2V0IjoiQlIiLCJwbGF0Zm9ybXMiOlsiaXBob25lIl0sInByb2ZpbGVJRCI6IkJBVFRMRV9ST1lBTEVfQ09NUEVUSVRJVkUiLCJhdmFpbGFiaWxpdHkiOiJhdmFpbGFibGUiLCJtZWFzdXJlbWVudCI6eyJwcmltYXJ5UmVnaW9uIjoic2EtZWFzdC0xIiwic3RyYXRlZ3kiOiJnZW5lcmljUmVnaW9uIiwiY29uZmlkZW5jZSI6Im1lZGl1bSIsInByZWNpc2lvbktleSI6InJlZ2lvbmFsUmVmZXJlbmNlIn19XX0seyJpZCI6IndhcnpvbmUiLCJuYW1lIjoiQ2FsbCBvZiBEdXR5OiBXYXJ6b25lIiwiY29udGV4dHMiOlt7Im1hcmtldCI6IkJSIiwicGxhdGZvcm1zIjpbImlwaG9uZSJdLCJwcm9maWxlSUQiOiJCQVRUTEVfUk9ZQUxFX0NPTVBFVElUSVZFIiwiYXZhaWxhYmlsaXR5IjoiYXZhaWxhYmxlIiwibWVhc3VyZW1lbnQiOnsicHJpbWFyeVJlZ2lvbiI6InNhLWVhc3QtMSIsInN0cmF0ZWd5IjoiZ2VuZXJpY1JlZ2lvbiIsImNvbmZpZGVuY2UiOiJtZWRpdW0iLCJwcmVjaXNpb25LZXkiOiJyZWdpb25hbFJlZmVyZW5jZSJ9fV19XX0=",
  signatureBase64: "pvVo10kJG5nFjrDOG3FQnd+ot8r6QU6UMo+twb/T7oCNHzjIxtvYVUdq85HtvmP1+Mn7ZL4X30z36BjGq7fDCA=="
};

const loadHeaders = {
  "Cache-Control": "no-store",
  "Content-Type": "application/octet-stream",
  "X-Content-Type-Options": "nosniff"
};

function loadStream() {
  let sent = 0;
  return new ReadableStream({
    pull(controller) {
      if (sent >= LOAD_BYTES) {
        controller.close();
        return;
      }
      const size = Math.min(CHUNK_BYTES, LOAD_BYTES - sent);
      controller.enqueue(new Uint8Array(size));
      sent += size;
    }
  });
}

const artworkPath = /^\/artwork\/games\/([a-z0-9-]+\.(?:jpg|png))$/;

const ALLOWED_EVENTS = new Set(["app_open", "check_started", "verdict_viewed", "retest_started"]);
const ALLOWED_PLATFORMS = new Set(["iphone", "playstation", "xbox", "pc"]);
const ALLOWED_VERDICTS = new Set(["ready", "caution", "not_ready", "inconclusive"]);
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const TELEMETRY_CORS_HEADERS = {
  "Content-Type": "application/json",
  "Cache-Control": "no-store",
  "Access-Control-Allow-Origin": "*"
};

async function handleTelemetry(request, env = {}) {
  if (request.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
        "Cache-Control": "no-store"
      }
    });
  }

  if (request.method !== "POST") {
    return new Response("Method not allowed", {
      status: 405,
      headers: { "Allow": "POST, OPTIONS", "Cache-Control": "no-store" }
    });
  }

  let body;
  try {
    body = await request.json();
  } catch {
    return Response.json({ error: "invalid_json" }, {
      status: 400,
      headers: { "Cache-Control": "no-store", "Access-Control-Allow-Origin": "*" }
    });
  }

  if (!body || typeof body !== "object") {
    return Response.json({ error: "invalid_payload" }, {
      status: 400,
      headers: { "Cache-Control": "no-store", "Access-Control-Allow-Origin": "*" }
    });
  }

  const { installationId, event, gameId, platform, verdict } = body;

  if (!installationId || typeof installationId !== "string" || !UUID_REGEX.test(installationId)) {
    return Response.json({ error: "invalid_installation_id" }, {
      status: 400,
      headers: { "Cache-Control": "no-store", "Access-Control-Allow-Origin": "*" }
    });
  }

  if (!event || typeof event !== "string" || !ALLOWED_EVENTS.has(event)) {
    return Response.json({ error: "invalid_event" }, {
      status: 400,
      headers: { "Cache-Control": "no-store", "Access-Control-Allow-Origin": "*" }
    });
  }

  if (gameId !== undefined && (typeof gameId !== "string" || gameId.length > 64)) {
    return Response.json({ error: "invalid_game_id" }, {
      status: 400,
      headers: { "Cache-Control": "no-store", "Access-Control-Allow-Origin": "*" }
    });
  }

  if (platform !== undefined && (typeof platform !== "string" || !ALLOWED_PLATFORMS.has(platform))) {
    return Response.json({ error: "invalid_platform" }, {
      status: 400,
      headers: { "Cache-Control": "no-store", "Access-Control-Allow-Origin": "*" }
    });
  }

  if (verdict !== undefined && (typeof verdict !== "string" || !ALLOWED_VERDICTS.has(verdict))) {
    return Response.json({ error: "invalid_verdict" }, {
      status: 400,
      headers: { "Cache-Control": "no-store", "Access-Control-Allow-Origin": "*" }
    });
  }

  // Telemetria anônima validada com sucesso:
  // Zero PII: não registra IP, não armazena cookies, não expõe cabeçalhos de cliente.
  // Suporte a Cloudflare Analytics Engine (gratuito) caso o binding esteja presente no ambiente.
  if (env.ANALYTICS && typeof env.ANALYTICS.writeDataPoint === "function") {
    try {
      env.ANALYTICS.writeDataPoint({
        blobs: [event, platform || "unknown", verdict || "none", gameId || "general"],
        doubles: [1],
        indexes: [installationId]
      });
    } catch {
      // Ignora falha silenciosa no envio ao Analytics Engine para nunca impactar o cliente
    }
  }

  return Response.json({ status: "ok" }, {
    status: 200,
    headers: TELEMETRY_CORS_HEADERS
  });
}

const WAITLIST_CORS_HEADERS = {
  "Content-Type": "application/json",
  "Cache-Control": "no-store",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type"
};

const EMAIL_REGEX = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/;

async function handleWaitlist(request, env = {}) {
  if (request.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: WAITLIST_CORS_HEADERS
    });
  }

  if (request.method !== "POST") {
    return new Response("Method not allowed", {
      status: 405,
      headers: { "Allow": "POST, OPTIONS", "Cache-Control": "no-store" }
    });
  }

  let body;
  try {
    body = await request.json();
  } catch {
    return Response.json({ error: "invalid_json" }, {
      status: 400,
      headers: WAITLIST_CORS_HEADERS
    });
  }

  if (!body || typeof body !== "object") {
    return Response.json({ error: "invalid_payload" }, {
      status: 400,
      headers: WAITLIST_CORS_HEADERS
    });
  }

  const { email, source, lang, platform, utm, launchNotice, createdAt } = body;
  if (!email || typeof email !== "string") {
    return Response.json({ error: "missing_email" }, {
      status: 400,
      headers: WAITLIST_CORS_HEADERS
    });
  }

  const cleanEmail = email.trim().toLowerCase();
  if (cleanEmail.length > 254 || !EMAIL_REGEX.test(cleanEmail)) {
    return Response.json({ error: "invalid_email" }, {
      status: 400,
      headers: WAITLIST_CORS_HEADERS
    });
  }

  const cleanSource = (typeof source === "string" && source.length <= 64) ? source.trim() : "web_waitlist";
  const cleanLang = (lang === "en" || lang === "es") ? lang : "pt-BR";
  const cleanPlatform = (platform === "ios" || platform === "android" || platform === "both") ? platform : (platform ? String(platform).slice(0, 16) : undefined);
  const cleanUtm = (utm && typeof utm === "object" && !Array.isArray(utm)) ? utm : undefined;
  const cleanLaunchNotice = typeof launchNotice === "boolean" ? launchNotice : undefined;
  const timestamp = typeof createdAt === "string" && createdAt.length <= 40 ? createdAt : new Date().toISOString();

  // Grava em Cloudflare KV se o binding estiver presente
  if (env.WAITLIST_KV && typeof env.WAITLIST_KV.put === "function") {
    try {
      const record = {
        email: cleanEmail,
        source: cleanSource,
        lang: cleanLang,
        timestamp
      };
      if (cleanPlatform) record.platform = cleanPlatform;
      if (cleanUtm) record.utm = cleanUtm;
      if (typeof cleanLaunchNotice === "boolean") record.launchNotice = cleanLaunchNotice;
      await env.WAITLIST_KV.put(`lead:${cleanEmail}`, JSON.stringify(record));
      await incrementStat(env, "lead");
    } catch (err) {
      console.error("KV put error:", err);
    }
  }

  // Notificação via Webhook Discord em tempo real
  if (env.DISCORD_WEBHOOK_URL) {
    try {
      const platformLabels = {
        ios: "🍏 iOS (TestFlight)",
        android: "🤖 Android (Play Beta)",
        both: "🍏 iOS + 🤖 Android"
      };
      const platformText = platformLabels[cleanPlatform] || cleanPlatform || "Não especificada";
      let utmDesc = "";
      if (cleanUtm && typeof cleanUtm === "object") {
        utmDesc = Object.entries(cleanUtm).map(([k, v]) => `• **${k}**: \`${v}\``).join("\n");
      }

      const embedFields = [
        { name: "📧 E-mail", value: `\`${cleanEmail}\``, inline: false },
        { name: "📱 Plataforma", value: platformText, inline: true },
        { name: "🌐 Origem", value: `\`${cleanSource}\``, inline: true }
      ];
      if (utmDesc) {
        embedFields.push({ name: "📊 Parâmetros UTM", value: utmDesc, inline: false });
      }
      if (typeof cleanLaunchNotice === "boolean") {
        embedFields.push({ name: "🔔 Notificar Lançamento", value: cleanLaunchNotice ? "Sim" : "Não", inline: true });
      }
      embedFields.push({ name: "⏰ Horário (UTC)", value: timestamp, inline: false });

      await fetch(env.DISCORD_WEBHOOK_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          username: "Lagcheck Beta",
          avatar_url: "https://lagcheck.signallq.com/assets/lagcheck-wordmark-light.svg",
          embeds: [
            {
              title: "🎮 Novo inscrito na Waitlist!",
              description: "Um novo jogador acabou de solicitar acesso antecipado.",
              color: 0x7c3aed,
              fields: embedFields,
              footer: { text: "Lagcheck • Ready for Ranked" }
            }
          ]
        })
      });
    } catch {
      // Ignora falha para não travar a resposta do usuário
    }
  }

  // Notificação via Telegram em tempo real (opcional)
  if (env.TELEGRAM_BOT_TOKEN && env.TELEGRAM_CHAT_ID) {
    try {
      const platformLabels = {
        ios: "iOS (TestFlight)",
        android: "Android (Play Beta)",
        both: "iOS + Android"
      };
      const platformText = platformLabels[cleanPlatform] || cleanPlatform || "Não especificada";
      const message = `🎮 *Novo inscrito na Waitlist do Lagcheck!*\n\n📧 *E-mail:* \`${cleanEmail}\`\n📱 *Plataforma:* ${platformText}\n🌐 *Origem:* ${cleanSource}\n⏰ *Data:* ${timestamp}`;
      await fetch(`https://api.telegram.org/bot${env.TELEGRAM_BOT_TOKEN}/sendMessage`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          chat_id: env.TELEGRAM_CHAT_ID,
          text: message,
          parse_mode: "Markdown"
        })
      });
    } catch {
      // Ignora falha de envio silenciosamente
    }
  }

  // Suporte a Cloudflare Analytics Engine (gratuito) caso o binding esteja presente no ambiente
  if (env.ANALYTICS && typeof env.ANALYTICS.writeDataPoint === "function") {
    try {
      env.ANALYTICS.writeDataPoint({
        blobs: ["waitlist_signup", cleanLang, cleanSource],
        doubles: [1],
        indexes: [cleanEmail]
      });
    } catch {
      // Ignora falha silenciosa no envio ao Analytics Engine
    }
  }

  return Response.json({ status: "ok", email: cleanEmail }, {
    status: 200,
    headers: WAITLIST_CORS_HEADERS
  });
}

export async function getStats(env, key) {
  if (!env.WAITLIST_KV || typeof env.WAITLIST_KV.get !== "function") return { visits: 0, leads: 0 };
  try {
    const val = await env.WAITLIST_KV.get(key);
    if (!val) return { visits: 0, leads: 0 };
    return JSON.parse(val);
  } catch {
    return { visits: 0, leads: 0 };
  }
}

export async function incrementStat(env, type) {
  if (!env.WAITLIST_KV || typeof env.WAITLIST_KV.put !== "function") return;
  const today = new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Sao_Paulo' }).format(new Date());
  const dailyKey = `stats:daily:${today}`;
  const totalKey = 'stats:total';

  try {
    const [daily, total] = await Promise.all([
      getStats(env, dailyKey),
      getStats(env, totalKey)
    ]);

    if (type === "visit") {
      daily.visits = (daily.visits || 0) + 1;
      total.visits = (total.visits || 0) + 1;
    } else if (type === "lead") {
      daily.leads = (daily.leads || 0) + 1;
      total.leads = (total.leads || 0) + 1;
    } else if (type === "click") {
      daily.clicks = (daily.clicks || 0) + 1;
      total.clicks = (total.clicks || 0) + 1;
    }

    await Promise.all([
      env.WAITLIST_KV.put(dailyKey, JSON.stringify(daily)),
      env.WAITLIST_KV.put(totalKey, JSON.stringify(total))
    ]);
  } catch (err) {
    console.error("Failed to increment stat:", err);
  }
}

export async function handleVisit(request, env = {}) {
  if (request.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: WAITLIST_CORS_HEADERS
    });
  }

  if (request.method !== "POST") {
    return new Response("Method not allowed", {
      status: 405,
      headers: { "Allow": "POST, OPTIONS", "Cache-Control": "no-store" }
    });
  }

  // Legado: preserva compatibilidade dos clients antigos sem contar visitas em paralelo.
  // Pageviews e visitantes passam a ser contabilizados apenas pela Vercel.
  return Response.json({ status: "ok", deprecated: true }, {
    status: 200,
    headers: WAITLIST_CORS_HEADERS
  });
}

export async function handleAppStoreClick(request, env = {}) {
  if (request.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: WAITLIST_CORS_HEADERS
    });
  }

  if (request.method !== "POST") {
    return new Response("Method not allowed", {
      status: 405,
      headers: { "Allow": "POST, OPTIONS", "Cache-Control": "no-store" }
    });
  }

  let body = {};
  try {
    body = await request.json();
  } catch {
    body = {};
  }

  const cleanPage = (typeof body?.page === "string" && body.page.length <= 128) ? body.page : "/";
  const cleanGameId = (typeof body?.gameId === "string" && body.gameId.length <= 64) ? body.gameId : undefined;
  const cleanSource = (typeof body?.source === "string" && body.source.length <= 64) ? body.source : "web_download";
  const cleanPlatform = (typeof body?.platform === "string" && body.platform.length <= 16) ? body.platform : "ios";
  const cleanUtm = (body?.utm && typeof body.utm === "object" && !Array.isArray(body.utm)) ? body.utm : undefined;
  const timestamp = (typeof body?.createdAt === "string" && body.createdAt.length <= 40) ? body.createdAt : new Date().toISOString();

  await incrementStat(env, "click");

  if (env.ANALYTICS && typeof env.ANALYTICS.writeDataPoint === "function") {
    try {
      env.ANALYTICS.writeDataPoint({
        blobs: ["appstore_click", cleanPage, cleanGameId || "none", cleanSource],
        doubles: [1],
        indexes: [cleanPlatform]
      });
    } catch {
      // Ignora falha silenciosa
    }
  }

  if (env.DISCORD_WEBHOOK_URL) {
    try {
      let utmDesc = "";
      if (cleanUtm && typeof cleanUtm === "object") {
        utmDesc = Object.entries(cleanUtm).map(([k, v]) => `• **${k}**: \`${v}\``).join("\n");
      }
      const fields = [
        { name: "📱 Plataforma", value: `🍏 ${cleanPlatform.toUpperCase()}`, inline: true },
        { name: "🌐 Origem", value: `\`${cleanSource}\``, inline: true },
        { name: "📄 Página", value: `\`${cleanPage}\``, inline: true }
      ];
      if (cleanGameId) {
        fields.push({ name: "🎮 Jogo Contextual", value: `\`${cleanGameId}\``, inline: true });
      }
      if (utmDesc) {
        fields.push({ name: "📊 Parâmetros UTM", value: utmDesc, inline: false });
      }
      fields.push({ name: "⏰ Horário (UTC)", value: timestamp, inline: false });

      await fetch(env.DISCORD_WEBHOOK_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          username: "Lagcheck Analytics",
          avatar_url: "https://lagcheck.signallq.com/assets/lagcheck-wordmark-light.svg",
          embeds: [
            {
              title: "📲 Intenção de Instalação (App Store Click)",
              description: "Um jogador clicou no botão de download para a App Store.",
              color: 0x7c3aed,
              fields,
              footer: { text: "Lagcheck • App Store Conversion" }
            }
          ]
        })
      });
    } catch {
      // Ignora falha silenciosa
    }
  }

  return Response.json({ status: "ok", event: "appstore_click" }, {
    status: 200,
    headers: WAITLIST_CORS_HEADERS
  });
}

// Vercel Web Analytics e a fonte oficial de visitantes/pageviews.
// IDs de projetos nao sao segredos; o Bearer e mantido apenas em env.VERCEL_TOKEN.
const VERCEL_TEAM_ID = "team_VCRx5oIQ20HUO84QLL62RStN";
const VERCEL_PROJECTS = [
  { name: "SignallQ", id: "prj_XxQs4bRAtAczAwULNqDzAWgQTkpE", url: "https://signallq.com", color: 0x5b21d6 },
  { name: "Lagcheck", id: "prj_GuijE4Exyc2TplaUG6a22XlbK2gU", url: "https://lagcheck.signallq.com", color: 0x7c3aed },
  { name: "Linka", id: "prj_7BpZVVugGOf644g81XxOCLKnDRe0", url: "https://linka.signallq.com", color: 0x0284c7 }
];

function brazilDate(date) {
  return new Intl.DateTimeFormat("en-CA", { timeZone: "America/Sao_Paulo", year: "numeric", month: "2-digit", day: "2-digit" }).format(date);
}

async function vercelAnalyticsQuery(env, projectId, resource, since, until, dimension) {
  const params = new URLSearchParams({
    teamId: VERCEL_TEAM_ID,
    projectId,
    since,
    until
  });
  if (dimension) {
    params.set("by", dimension);
    params.set("limit", "3");
  }
  const url = "https://api.vercel.com/v1/query/web-analytics/visits/" + resource + "?" + params.toString();
  const response = await fetch(url, {
    headers: { Authorization: "Bearer " + env.VERCEL_TOKEN, Accept: "application/json" }
  });
  if (!response.ok) {
    // Nunca logar URL de webhook, segredos ou a resposta completa da API.
    throw new Error("Vercel Analytics " + resource + " HTTP " + response.status);
  }
  return response.json();
}

function formatVercelDimension(data, name) {
  if (!Array.isArray(data) || data.length === 0) return "Sem registros no período.";
  return data.slice(0, 3).map((row) => {
    const label = String(row?.[name] ?? "Não identificado")
      .replace(/[\r\n*_]/g, " ")
      .replace(/@/g, "@\u200b")
      .slice(0, 85);
    const quantity = Number(row?.pageviews ?? row?.count ?? 0);
    return "• " + label + ": " + (Number.isFinite(quantity) ? quantity : 0);
  }).join("\n").slice(0, 950);
}

async function readProjectAnalytics(env, project, since, until) {
  const counts = await vercelAnalyticsQuery(env, project.id, "count", since, until);
  const visits = Number(counts?.data?.visitors);
  const pageviews = Number(counts?.data?.pageviews);
  if (!Number.isFinite(visits) || !Number.isFinite(pageviews)) {
    throw new Error("Resposta de contagem inesperada da Vercel");
  }

  // Dados auxiliares nao podem derrubar a contagem principal.
  const [pages, referrers] = await Promise.allSettled([
    vercelAnalyticsQuery(env, project.id, "aggregate", since, until, "requestPath"),
    vercelAnalyticsQuery(env, project.id, "aggregate", since, until, "referrerHostname")
  ]);
  return {
    visitors: visits,
    pageviews,
    pages: pages.status === "fulfilled" ? formatVercelDimension(pages.value?.data, "requestPath") : "Indisponível",
    referrers: referrers.status === "fulfilled" ? formatVercelDimension(referrers.value?.data, "referrerHostname") : "Indisponível"
  };
}

export async function sendDailyReport(env, now = new Date()) {
  if (!env.DISCORD_WEBHOOK_URL) {
    console.warn("DISCORD_WEBHOOK_URL ausente: relatorio nao enviado");
    return;
  }
  if (!env.VERCEL_TOKEN) {
    console.warn("VERCEL_TOKEN ausente: nao usar dados de visitas do KV como substitutos");
    return;
  }

  // Relatorio do dia civil anterior em horario de Brasilia (UTC-3).
  const yesterday = brazilDate(new Date(now.getTime() - 24 * 60 * 60 * 1000));
  const today = brazilDate(now);
  const since = new Date(yesterday + "T00:00:00-03:00").toISOString();
  const until = new Date(new Date(today + "T00:00:00-03:00").getTime() - 1).toISOString();

  const results = await Promise.allSettled(
    VERCEL_PROJECTS.map((project) => readProjectAnalytics(env, project, since, until))
  );
  const dailyLagcheck = await getStats(env, "stats:daily:" + yesterday);
  const clicks = Number(dailyLagcheck.clicks || 0);
  const embeds = VERCEL_PROJECTS.map((project, index) => {
    const result = results[index];
    if (result.status !== "fulfilled") {
      console.warn("Vercel Analytics indisponivel para " + project.name + ": " + result.reason?.message);
      return {
        title: project.name + " — dados indisponíveis",
        url: project.url,
        color: project.color,
        description: "A consulta à Vercel falhou. Verifique o token, o escopo e o script de Analytics. Não substituir por zero ou contagem local."
      };
    }
    const analytics = result.value;
    const fields = [
      { name: "Visitantes únicos", value: String(analytics.visitors), inline: true },
      { name: "Visualizações de página", value: String(analytics.pageviews), inline: true },
      { name: "Páginas mais acessadas", value: analytics.pages, inline: false },
      { name: "Origens de tráfego", value: analytics.referrers, inline: false }
    ];
    if (project.name === "Lagcheck") {
      fields.push({
        name: "Cliques na App Store (medição separada)",
        value: Number.isFinite(clicks) ? String(clicks) + " cliques; não equivalem a instalações." : "Indisponível",
        inline: false
      });
    }
    return {
      title: project.name + " — Web Analytics",
      url: project.url,
      color: project.color,
      fields
    };
  });

  const payload = {
    username: "SignallQ Analytics",
    content: "Relatório diário de sites (D-1: " + yesterday + ", Brasília). Fonte: Vercel Web Analytics.",
    embeds
  };

  try {
    const response = await fetch(env.DISCORD_WEBHOOK_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });
    if (!response.ok) console.error("Discord: falha ao publicar relatorio (HTTP " + response.status + ")");
  } catch (err) {
    console.error("Discord: falha de rede ao publicar relatorio", err?.message);
  }
}

export async function handleScheduled(event, env, ctx) {
  await sendDailyReport(env);
}

export async function handleRequest(request, env = {}) {
  const url = new URL(request.url);
  const assetMatch = url.pathname.match(artworkPath);
  if (assetMatch) {
    if (request.method !== "GET") {
      return new Response("Method not allowed", { status: 405, headers: { "Allow": "GET", "Cache-Control": "no-store" } });
    }
    if (!env.ASSETS) return new Response("Asset binding unavailable", { status: 503, headers: { "Cache-Control": "no-store" } });
    // A URL pública não expõe o diretório interno nem aceita segmentos livres.
    return env.ASSETS.fetch(new Request(new URL(`/games/${assetMatch[1]}`, url), request));
  }
  if (url.pathname === "/v1/visit") {
    return handleVisit(request, env);
  }
  if (url.pathname === "/v1/click" || url.pathname === "/v1/click/appstore") {
    return handleAppStoreClick(request, env);
  }
  if (url.pathname === "/v1/report/test") {
    if (request.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }
    // Impede disparos anonimos do webhook/consultas Vercel na internet publica.
    if (!env.REPORT_TEST_TOKEN || request.headers.get("authorization") !== "Bearer " + env.REPORT_TEST_TOKEN) {
      return new Response("Forbidden", { status: 403, headers: { "Cache-Control": "no-store" } });
    }
    await sendDailyReport(env);
    return Response.json({ status: "ok", message: "Daily report dispatched" });
  }
  if (url.pathname === "/v1/telemetry") {
    return handleTelemetry(request, env);
  }
  if (url.pathname === "/v1/waitlist") {
    return handleWaitlist(request, env);
  }
  if (url.pathname === "/v1/catalog.json") {
    if (request.method !== "GET") {
      return new Response("Method not allowed", {
        status: 405,
        headers: { "Allow": "GET", "Cache-Control": "no-store" }
      });
    }
    return Response.json(CATALOG_ENVELOPE, {
      headers: { "Cache-Control": "no-store" }
    });
  }
  if (url.pathname !== "/v1/load") {
    return new Response("Not found", { status: 404, headers: { "Cache-Control": "no-store" } });
  }
  if (request.method !== "GET") {
    return new Response("Method not allowed", {
      status: 405,
      headers: { "Allow": "GET", "Cache-Control": "no-store" }
    });
  }
  return new Response(loadStream(), { status: 200, headers: loadHeaders });
}

export default {
  fetch: handleRequest,
  scheduled: handleScheduled
};

