import test from "node:test";
import assert from "node:assert/strict";
import { handleRequest } from "../src/index.js";

test("POST /v1/waitlist succeeds with valid email", async () => {
  const payload = {
    email: "player@example.com",
    source: "hero_form",
    lang: "pt"
  };
  const response = await handleRequest(new Request("https://example.workers.dev/v1/waitlist", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  }));

  assert.equal(response.status, 200);
  assert.equal(response.headers.get("cache-control"), "no-store");
  assert.equal(response.headers.get("access-control-allow-origin"), "*");
  const data = await response.json();
  assert.equal(data.status, "ok");
  assert.equal(data.email, "player@example.com");
});

test("POST /v1/waitlist normalizes email to lowercase and trims whitespace", async () => {
  const payload = {
    email: "  PLAYER.RANKED@GMAIL.COM  ",
    source: "footer_cta"
  };
  const response = await handleRequest(new Request("https://example.workers.dev/v1/waitlist", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  }));

  assert.equal(response.status, 200);
  const data = await response.json();
  assert.equal(data.email, "player.ranked@gmail.com");
});

test("POST /v1/waitlist writes to env.WAITLIST_KV when bound", async () => {
  let savedKey = null;
  let savedVal = null;
  const mockEnv = {
    WAITLIST_KV: {
      put: async (key, val) => {
        savedKey = key;
        savedVal = val;
      }
    }
  };
  const payload = {
    email: "clutch@buildea.com",
    source: "waitlist_modal",
    lang: "en"
  };
  const response = await handleRequest(new Request("https://example.workers.dev/v1/waitlist", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  }), mockEnv);

  assert.equal(response.status, 200);
  assert.equal(savedKey, "lead:clutch@buildea.com");
  assert.ok(savedVal);
  const parsed = JSON.parse(savedVal);
  assert.equal(parsed.email, "clutch@buildea.com");
  assert.equal(parsed.source, "waitlist_modal");
  assert.equal(parsed.lang, "en");
  assert.ok(parsed.timestamp);
});

test("OPTIONS /v1/waitlist responds with CORS preflight headers", async () => {
  const response = await handleRequest(new Request("https://example.workers.dev/v1/waitlist", {
    method: "OPTIONS"
  }));

  assert.equal(response.status, 204);
  assert.equal(response.headers.get("access-control-allow-origin"), "*");
  assert.equal(response.headers.get("access-control-allow-methods"), "POST, OPTIONS");
  assert.equal(response.headers.get("access-control-allow-headers"), "Content-Type");
});

test("GET /v1/waitlist returns 405 Method Not Allowed", async () => {
  const response = await handleRequest(new Request("https://example.workers.dev/v1/waitlist", {
    method: "GET"
  }));

  assert.equal(response.status, 405);
  assert.equal(response.headers.get("allow"), "POST, OPTIONS");
});

test("POST /v1/waitlist rejects invalid email format", async () => {
  const response = await handleRequest(new Request("https://example.workers.dev/v1/waitlist", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: "not-an-email" })
  }));

  assert.equal(response.status, 400);
  const data = await response.json();
  assert.equal(data.error, "invalid_email");
});

test("POST /v1/waitlist rejects missing email", async () => {
  const response = await handleRequest(new Request("https://example.workers.dev/v1/waitlist", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ source: "hero" })
  }));

  assert.equal(response.status, 400);
  const data = await response.json();
  assert.equal(data.error, "missing_email");
});
