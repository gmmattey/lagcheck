import test from "node:test";
import assert from "node:assert/strict";
import { handleRequest } from "../src/index.js";

const VALID_UUID = "123e4567-e89b-12d3-a456-426614174000";

test("POST /v1/telemetry succeeds for app_open event", async () => {
  const payload = {
    installationId: VALID_UUID,
    event: "app_open",
    timestamp: "2026-09-25T20:00:00Z"
  };
  const response = await handleRequest(new Request("https://example.workers.dev/v1/telemetry", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  }));

  assert.equal(response.status, 200);
  assert.equal(response.headers.get("cache-control"), "no-store");
  assert.equal(response.headers.get("access-control-allow-origin"), "*");
  const data = await response.json();
  assert.equal(data.status, "ok");
});

test("POST /v1/telemetry succeeds for check_started event with context", async () => {
  const payload = {
    installationId: VALID_UUID,
    event: "check_started",
    gameId: "fortnite",
    platform: "iphone"
  };
  const response = await handleRequest(new Request("https://example.workers.dev/v1/telemetry", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  }));

  assert.equal(response.status, 200);
  const data = await response.json();
  assert.equal(data.status, "ok");
});

test("POST /v1/telemetry succeeds for verdict_viewed event", async () => {
  const payload = {
    installationId: VALID_UUID,
    event: "verdict_viewed",
    gameId: "fortnite",
    platform: "iphone",
    verdict: "ready"
  };
  const response = await handleRequest(new Request("https://example.workers.dev/v1/telemetry", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  }));

  assert.equal(response.status, 200);
  const data = await response.json();
  assert.equal(data.status, "ok");
});

test("POST /v1/telemetry succeeds for retest_started event", async () => {
  const payload = {
    installationId: VALID_UUID,
    event: "retest_started",
    gameId: "fortnite",
    platform: "iphone"
  };
  const response = await handleRequest(new Request("https://example.workers.dev/v1/telemetry", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  }));

  assert.equal(response.status, 200);
  const data = await response.json();
  assert.equal(data.status, "ok");
});

test("OPTIONS /v1/telemetry responds with CORS preflight headers", async () => {
  const response = await handleRequest(new Request("https://example.workers.dev/v1/telemetry", {
    method: "OPTIONS"
  }));

  assert.equal(response.status, 204);
  assert.equal(response.headers.get("access-control-allow-origin"), "*");
  assert.equal(response.headers.get("access-control-allow-methods"), "POST, OPTIONS");
  assert.equal(response.headers.get("access-control-allow-headers"), "Content-Type");
});

test("GET /v1/telemetry returns 405 Method Not Allowed", async () => {
  const response = await handleRequest(new Request("https://example.workers.dev/v1/telemetry", {
    method: "GET"
  }));

  assert.equal(response.status, 405);
  assert.equal(response.headers.get("allow"), "POST, OPTIONS");
});

test("POST /v1/telemetry rejects invalid JSON", async () => {
  const response = await handleRequest(new Request("https://example.workers.dev/v1/telemetry", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: "{ malformed json "
  }));

  assert.equal(response.status, 400);
  const data = await response.json();
  assert.equal(data.error, "invalid_json");
});

test("POST /v1/telemetry rejects missing or invalid installationId", async () => {
  const response = await handleRequest(new Request("https://example.workers.dev/v1/telemetry", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      installationId: "not-a-uuid",
      event: "app_open"
    })
  }));

  assert.equal(response.status, 400);
  const data = await response.json();
  assert.equal(data.error, "invalid_installation_id");
});

test("POST /v1/telemetry rejects unauthorized event", async () => {
  const response = await handleRequest(new Request("https://example.workers.dev/v1/telemetry", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      installationId: VALID_UUID,
      event: "purchase_crypto"
    })
  }));

  assert.equal(response.status, 400);
  const data = await response.json();
  assert.equal(data.error, "invalid_event");
});

test("POST /v1/telemetry rejects invalid platform or verdict", async () => {
  const response = await handleRequest(new Request("https://example.workers.dev/v1/telemetry", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      installationId: VALID_UUID,
      event: "verdict_viewed",
      platform: "android", // V1 é somente iOS
      verdict: "ready"
    })
  }));

  assert.equal(response.status, 400);
  const data = await response.json();
  assert.equal(data.error, "invalid_platform");
});
