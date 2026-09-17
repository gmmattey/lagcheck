const LOAD_BYTES = 10 * 1024 * 1024;
const CHUNK_BYTES = 64 * 1024;

// O Worker não assina em tempo de requisição e não contém chave privada. Este
// envelope Debug já foi assinado sobre os bytes de payloadBase64 decodificados.
const CATALOG_ENVELOPE = {
  schemaVersion: 1,
  catalogVersion: "debug-2026.09.08.2",
  issuedAt: "2026-09-08T00:00:00Z",
  expiresAt: "2026-10-08T00:00:00Z",
  algorithm: "Ed25519",
  payloadBase64: "eyJzY2hlbWFWZXJzaW9uIjoxLCJjYXRhbG9nVmVyc2lvbiI6ImRlYnVnLTIwMjYuMDkuMDguMiIsInByb2ZpbGVzIjpbeyJpZCI6IkJBVFRMRV9ST1lBTEVfQ09NUEVUSVRJVkUiLCJydWxlVmVyc2lvbiI6InBpbG90LTIwMjYuMDkuMDguMSJ9LHsiaWQiOiJNT0JJTEVfUkVBTFRJTUUiLCJydWxlVmVyc2lvbiI6Im1vYmlsZS1yZWFsdGltZS0yMDI2LjA5LjA4LjEifSx7ImlkIjoiQ0FTVUFMX1JFQUxUSU1FIiwicnVsZVZlcnNpb24iOiJjYXN1YWwtcmVhbHRpbWUtMjAyNi4wOS4wOC4xIn1dLCJyZWdpb25zIjpbeyJpZCI6InNhLWVhc3QtMSIsImxhYmVsIjp7InB0LUJSIjoiU8OjbyBQYXVsbyIsImVuIjoiU8OjbyBQYXVsbyJ9LCJwcm9iZSI6eyJob3N0IjoiZ2FtZWxpZnQtcGluZy5zYS1lYXN0LTEuYXBpLmF3cyIsInBvcnQiOjc3NzB9fV0sImdhbWVzIjpbeyJpZCI6ImZvcnRuaXRlIiwibmFtZSI6IkZvcnRuaXRlIiwiY29udGV4dHMiOlt7Im1hcmtldCI6IkJSIiwicGxhdGZvcm1zIjpbImlwaG9uZSJdLCJwcm9maWxlSUQiOiJCQVRUTEVfUk9ZQUxFX0NPTVBFVElUSVZFIiwiYXZhaWxhYmlsaXR5IjoiYXZhaWxhYmxlIiwibWVhc3VyZW1lbnQiOnsicHJpbWFyeVJlZ2lvbiI6InNhLWVhc3QtMSIsInN0cmF0ZWd5IjoiZ2VuZXJpY1JlZ2lvbiIsImNvbmZpZGVuY2UiOiJtZWRpdW0iLCJwcmVjaXNpb25LZXkiOiJyZWdpb25hbFJlZmVyZW5jZSJ9fV19LHsiaWQiOiJjYWxsLW9mLWR1dHktbW9iaWxlIiwibmFtZSI6IkNhbGwgb2YgRHV0eTogTW9iaWxlIiwiY29udGV4dHMiOlt7Im1hcmtldCI6IkJSIiwicGxhdGZvcm1zIjpbImlwaG9uZSJdLCJwcm9maWxlSUQiOiJCQVRUTEVfUk9ZQUxFX0NPTVBFVElUSVZFIiwiYXZhaWxhYmlsaXR5IjoiYXZhaWxhYmxlIiwibWVhc3VyZW1lbnQiOnsicHJpbWFyeVJlZ2lvbiI6InNhLWVhc3QtMSIsInN0cmF0ZWd5IjoiZ2VuZXJpY1JlZ2lvbiIsImNvbmZpZGVuY2UiOiJtZWRpdW0iLCJwcmVjaXNpb25LZXkiOiJyZWdpb25hbFJlZmVyZW5jZSJ9fV19LHsiaWQiOiJmcmVlLWZpcmUiLCJuYW1lIjoiRnJlZSBGaXJlIiwiY29udGV4dHMiOlt7Im1hcmtldCI6IkJSIiwicGxhdGZvcm1zIjpbImlwaG9uZSJdLCJwcm9maWxlSUQiOiJCQVRUTEVfUk9ZQUxFX0NPTVBFVElUSVZFIiwiYXZhaWxhYmlsaXR5IjoiYXZhaWxhYmxlIiwibWVhc3VyZW1lbnQiOnsicHJpbWFyeVJlZ2lvbiI6InNhLWVhc3QtMSIsInN0cmF0ZWd5IjoiZ2VuZXJpY1JlZ2lvbiIsImNvbmZpZGVuY2UiOiJtZWRpdW0iLCJwcmVjaXNpb25LZXkiOiJyZWdpb25hbFJlZmVyZW5jZSJ9fV19LHsiaWQiOiJwdWJnLW1vYmlsZSIsIm5hbWUiOiJQVUJHIE1PQklMRSIsImNvbnRleHRzIjpbeyJtYXJrZXQiOiJCUiIsInBsYXRmb3JtcyI6WyJpcGhvbmUiXSwicHJvZmlsZUlEIjoiQkFUVExFX1JPWUFMRV9DT01QRVRJVElWRSIsImF2YWlsYWJpbGl0eSI6ImF2YWlsYWJsZSIsIm1lYXN1cmVtZW50Ijp7InByaW1hcnlSZWdpb24iOiJzYS1lYXN0LTEiLCJzdHJhdGVneSI6ImdlbmVyaWNSZWdpb24iLCJjb25maWRlbmNlIjoibWVkaXVtIiwicHJlY2lzaW9uS2V5IjoicmVnaW9uYWxSZWZlcmVuY2UifX1dfSx7ImlkIjoiYnJhd2wtc3RhcnMiLCJuYW1lIjoiQnJhd2wgU3RhcnMiLCJjb250ZXh0cyI6W3sibWFya2V0IjoiQlIiLCJwbGF0Zm9ybXMiOlsiaXBob25lIl0sInByb2ZpbGVJRCI6Ik1PQklMRV9SRUFMVElNRSIsImF2YWlsYWJpbGl0eSI6ImF2YWlsYWJsZSIsIm1lYXN1cmVtZW50Ijp7InByaW1hcnlSZWdpb24iOiJzYS1lYXN0LTEiLCJzdHJhdGVneSI6ImdlbmVyaWNSZWdpb24iLCJjb25maWRlbmNlIjoibWVkaXVtIiwicHJlY2lzaW9uS2V5IjoicmVnaW9uYWxSZWZlcmVuY2UifX1dfSx7ImlkIjoid2lsZC1yaWZ0IiwibmFtZSI6IkxlYWd1ZSBvZiBMZWdlbmRzOiBXaWxkIFJpZnQiLCJjb250ZXh0cyI6W3sibWFya2V0IjoiQlIiLCJwbGF0Zm9ybXMiOlsiaXBob25lIl0sInByb2ZpbGVJRCI6Ik1PQklMRV9SRUFMVElNRSIsImF2YWlsYWJpbGl0eSI6ImF2YWlsYWJsZSIsIm1lYXN1cmVtZW50Ijp7InByaW1hcnlSZWdpb24iOiJzYS1lYXN0LTEiLCJzdHJhdGVneSI6ImdlbmVyaWNSZWdpb24iLCJjb25maWRlbmNlIjoibWVkaXVtIiwicHJlY2lzaW9uS2V5IjoicmVnaW9uYWxSZWZlcmVuY2UifX1dfSx7ImlkIjoicm9ibG94IiwibmFtZSI6IlJvYmxveCIsImNvbnRleHRzIjpbeyJtYXJrZXQiOiJCUiIsInBsYXRmb3JtcyI6WyJpcGhvbmUiXSwicHJvZmlsZUlEIjoiQ0FTVUFMX1JFQUxUSU1FIiwiYXZhaWxhYmlsaXR5IjoiYXZhaWxhYmxlIiwibWVhc3VyZW1lbnQiOnsicHJpbWFyeVJlZ2lvbiI6InNhLWVhc3QtMSIsInN0cmF0ZWd5IjoiZ2VuZXJpY1JlZ2lvbiIsImNvbmZpZGVuY2UiOiJtZWRpdW0iLCJwcmVjaXNpb25LZXkiOiJyZWdpb25hbFJlZmVyZW5jZSJ9fV19LHsiaWQiOiJtaW5lY3JhZnQiLCJuYW1lIjoiTWluZWNyYWZ0IiwiY29udGV4dHMiOlt7Im1hcmtldCI6IkJSIiwicGxhdGZvcm1zIjpbImlwaG9uZSJdLCJwcm9maWxlSUQiOiJDQVNVQUxfUkVBTFRJTUUiLCJhdmFpbGFiaWxpdHkiOiJhdmFpbGFibGUiLCJtZWFzdXJlbWVudCI6eyJwcmltYXJ5UmVnaW9uIjoic2EtZWFzdC0xIiwic3RyYXRlZ3kiOiJnZW5lcmljUmVnaW9uIiwiY29uZmlkZW5jZSI6Im1lZGl1bSIsInByZWNpc2lvbktleSI6InJlZ2lvbmFsUmVmZXJlbmNlIn19XX1dfQ==",
  signatureBase64: "peL4TeCQZtQTZfFfk05KwcFLGtBuYrWAkYCjkPs+xnXaOel2O6kgrGvM6y0oLo26uIEyH9VtXWEIYW9ppkI8DQ=="
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

export function handleRequest(request) {
  const url = new URL(request.url);
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

export default { fetch: handleRequest };
