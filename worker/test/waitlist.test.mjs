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
  const kvMap = new Map();
  const mockEnv = {
    WAITLIST_KV: {
      get: async (key) => kvMap.get(key) || null,
      put: async (key, val) => kvMap.set(key, val)
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
  assert.ok(kvMap.has("lead:clutch@buildea.com"));
  const parsed = JSON.parse(kvMap.get("lead:clutch@buildea.com"));
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

test("POST /v1/waitlist dispatches to env.DISCORD_WEBHOOK_URL when set", async () => {
  let webhookPayload = null;
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url, options) => {
    if (url === "https://discord.com/api/webhooks/test") {
      webhookPayload = JSON.parse(options.body);
      return new Response("ok", { status: 204 });
    }
    return originalFetch(url, options);
  };

  try {
    const mockEnv = {
      DISCORD_WEBHOOK_URL: "https://discord.com/api/webhooks/test"
    };
    const response = await handleRequest(new Request("https://example.workers.dev/v1/waitlist", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        email: "ranked.gamer@buildea.com",
        platform: "ios",
        source: "hero_form",
        utm: { source: "google", campaign: "ranked_intent" }
      })
    }), mockEnv);

    assert.equal(response.status, 200);
    assert.ok(webhookPayload);
    assert.equal(webhookPayload.username, "Lagcheck Beta");
    assert.ok(webhookPayload.embeds && webhookPayload.embeds.length > 0);
    const embed = webhookPayload.embeds[0];
    assert.equal(embed.title, "🎮 Novo inscrito na Waitlist!");
    const emailField = embed.fields.find(f => f.name.includes("E-mail"));
    assert.ok(emailField.value.includes("ranked.gamer@buildea.com"));
    const platformField = embed.fields.find(f => f.name.includes("Plataforma"));
    assert.ok(platformField.value.includes("iOS (TestFlight)"));
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("POST /v1/visit increments visit count and returns 200", async () => {
  const kvMap = new Map();
  const mockEnv = {
    WAITLIST_KV: {
      get: async (key) => kvMap.get(key) || null,
      put: async (key, val) => kvMap.set(key, val)
    }
  };

  const response = await handleRequest(new Request("https://example.workers.dev/v1/visit", {
    method: "POST"
  }), mockEnv);

  assert.equal(response.status, 200);
  const data = await response.json();
  assert.equal(data.status, "ok");

  const total = JSON.parse(kvMap.get("stats:total"));
  assert.equal(total.visits, 1);
});

test("POST /v1/report/test triggers daily report to Discord", async () => {
  let reportSent = null;
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url, options) => {
    if (url === "https://discord.com/api/webhooks/test") {
      reportSent = JSON.parse(options.body);
      return new Response(null, { status: 204 });
    }
    return originalFetch(url, options);
  };

  try {
    const kvMap = new Map();
    kvMap.set("stats:total", JSON.stringify({ visits: 100, leads: 15 }));
    const mockEnv = {
      DISCORD_WEBHOOK_URL: "https://discord.com/api/webhooks/test",
      WAITLIST_KV: {
        get: async (key) => kvMap.get(key) || null,
        put: async (key, val) => kvMap.set(key, val)
      }
    };

    const response = await handleRequest(new Request("https://example.workers.dev/v1/report/test", {
      method: "POST"
    }), mockEnv);

    assert.equal(response.status, 200);
    assert.ok(reportSent);
    assert.equal(reportSent.username, "Lagcheck Analytics");
    const embed = reportSent.embeds[0];
    assert.ok(embed.title.includes("Relatório Diário"));
    const totalField = embed.fields.find(f => f.name.includes("Acumulado"));
    assert.ok(totalField.value.includes("Visitas Totais:** 100"));
    assert.ok(totalField.value.includes("Cadastros Totais:** 15"));
    assert.ok(totalField.value.includes("Conversão Geral:** **15.0%**"));
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("POST /v1/click tracks App Store clicks without fake email", async () => {
  const kvMap = new Map();
  const mockEnv = {
    WAITLIST_KV: {
      get: async (key) => kvMap.get(key) || null,
      put: async (key, val) => kvMap.set(key, val)
    }
  };

  const payload = {
    event: "appstore_click",
    page: "/jogos/valorant/",
    gameId: "valorant",
    source: "game_hero",
    platform: "ios"
  };

  const response = await handleRequest(new Request("https://example.workers.dev/v1/click", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  }), mockEnv);

  assert.equal(response.status, 200);
  const data = await response.json();
  assert.equal(data.status, "ok");
  assert.equal(data.event, "appstore_click");

  const total = JSON.parse(kvMap.get("stats:total"));
  assert.equal(total.clicks, 1);
});

test("OPTIONS /v1/click responds with CORS preflight headers", async () => {
  const response = await handleRequest(new Request("https://example.workers.dev/v1/click", {
    method: "OPTIONS"
  }));

  assert.equal(response.status, 204);
  assert.equal(response.headers.get("access-control-allow-origin"), "*");
  assert.ok(response.headers.get("access-control-allow-methods").includes("POST"));
});


