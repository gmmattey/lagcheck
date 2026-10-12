import test from "node:test";
import assert from "node:assert/strict";
import { handleRequest, sendDailyReport } from "../src/index.js";

const DISCORD_URL = "https://discord.com/api/webhooks/test";
const TOKEN = "secret-test-token";

function mockEnv() {
  return {
    VERCEL_TOKEN: TOKEN,
    DISCORD_WEBHOOK_URL: DISCORD_URL,
    REPORT_TEST_TOKEN: "manual-test-secret",
    WAITLIST_KV: {
      get: async (key) => key === "stats:daily:2026-10-10" ? JSON.stringify({ clicks: 7 }) : null
    }
  };
}

function setupFetch({ failingProject } = {}) {
  const previousFetch = globalThis.fetch;
  const calls = [];
  const discordMessages = [];
  globalThis.fetch = async (input, options = {}) => {
    const url = String(input);
    if (url.startsWith("https://api.vercel.com/v1/query/web-analytics/visits/")) {
      const parsed = new URL(url);
      calls.push({ parsed, options });
      assert.equal(options.headers.Authorization, "Bearer " + TOKEN);
      assert.equal(parsed.searchParams.get("teamId"), "team_VCRx5oIQ20HUO84QLL62RStN");
      const from = Date.parse(parsed.searchParams.get("since"));
      const to = Date.parse(parsed.searchParams.get("until"));
      assert.equal(to - from, 24 * 60 * 60 * 1000 - 1);
      if (failingProject === parsed.searchParams.get("projectId")) {
        return new Response("access denied", { status: 403 });
      }
      if (parsed.pathname.endsWith("/count")) {
        const lagcheck = parsed.searchParams.get("projectId") === "prj_GuijE4Exyc2TplaUG6a22XlbK2gU";
        return Response.json({
          data: { visitors: lagcheck ? 13 : 20, pageviews: lagcheck ? 34 : 55 }
        });
      }
      if (parsed.searchParams.get("by") === "requestPath") {
        return Response.json({ data: [{ requestPath: "/jogos/fortnite/", pageviews: 9 }] });
      }
      return Response.json({ data: [{ referrerHostname: "google.com", pageviews: 5 }] });
    }
    if (url === DISCORD_URL) {
      discordMessages.push(JSON.parse(options.body));
      return new Response(null, { status: 204 });
    }
    throw new Error("Unexpected fetch URL: " + url);
  };
  return {
    calls,
    discordMessages,
    restore: () => { globalThis.fetch = previousFetch; }
  };
}

test("scheduled report uses Vercel metrics for both sites, not KV visits", async () => {
  const mock = setupFetch();
  try {
    await sendDailyReport(mockEnv(), new Date("2026-10-11T12:00:00.000Z"));
    assert.equal(mock.calls.length, 6);
    assert.equal(mock.calls[0].parsed.searchParams.get("since"), "2026-10-10T03:00:00.000Z");
    assert.equal(mock.calls[0].parsed.searchParams.get("until"), "2026-10-11T02:59:59.999Z");
    assert.equal(mock.discordMessages.length, 1);
    const report = mock.discordMessages[0];
    assert.equal(report.embeds.length, 2);
    assert.ok(report.content.includes("Vercel Web Analytics"));
    const signallq = report.embeds[0];
    const lagcheck = report.embeds[1];
    assert.ok(signallq.title.includes("SignallQ"));
    assert.ok(signallq.fields.some(x => x.name === "Visitantes únicos" && x.value === "20"));
    assert.ok(signallq.fields.some(x => x.name === "Visualizações de página" && x.value === "55"));
    assert.ok(signallq.fields.some(x => x.value.includes("/jogos/fortnite/")));
    assert.ok(lagcheck.fields.some(x => x.name === "Visitantes únicos" && x.value === "13"));
    assert.ok(lagcheck.fields.some(x => x.value.includes("7 cliques; não equivalem a instalações")));
    assert.ok(!JSON.stringify(report).includes(TOKEN));
  } finally {
    mock.restore();
  }
});

test("Vercel errors are marked unavailable, not silently counted as zero", async () => {
  const mock = setupFetch({ failingProject: "prj_GuijE4Exyc2TplaUG6a22XlbK2gU" });
  try {
    await sendDailyReport(mockEnv(), new Date("2026-10-11T12:00:00.000Z"));
    assert.equal(mock.discordMessages.length, 1);
    assert.ok(mock.discordMessages[0].embeds[1].title.includes("indisponíveis"));
    assert.ok(mock.discordMessages[0].embeds[0].fields.some(x => x.value === "20"));
  } finally {
    mock.restore();
  }
});

test("manual report endpoint requires REPORT_TEST_TOKEN", async () => {
  const mock = setupFetch();
  try {
    const env = mockEnv();
    const forbidden = await handleRequest(new Request("https://example.workers.dev/v1/report/test", { method: "POST" }), env);
    assert.equal(forbidden.status, 403);
    assert.equal(mock.calls.length, 0);
    assert.equal(mock.discordMessages.length, 0);
    const allowed = await handleRequest(new Request("https://example.workers.dev/v1/report/test", {
      method: "POST", headers: { Authorization: "Bearer " + env.REPORT_TEST_TOKEN }
    }), env);
    assert.equal(allowed.status, 200);
    assert.equal(mock.discordMessages.length, 1);
  } finally {
    mock.restore();
  }
});

test("report does not try to query analytics without VERCEL_TOKEN", async () => {
  const mock = setupFetch();
  try {
    const env = mockEnv();
    delete env.VERCEL_TOKEN;
    await sendDailyReport(env, new Date("2026-10-11T12:00:00.000Z"));
    assert.equal(mock.calls.length, 0);
    assert.equal(mock.discordMessages.length, 0);
  } finally {
    mock.restore();
  }
});
