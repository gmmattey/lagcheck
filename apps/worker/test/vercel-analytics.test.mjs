import test from "node:test";
import assert from "node:assert/strict";
import { handleRequest, sendDailyReport, generateSparkline, formatDelta } from "../src/index.js";

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
        const projectId = parsed.searchParams.get("projectId");
        let visitors = 20;
        let pageviews = 55;
        if (projectId === "prj_GuijE4Exyc2TplaUG6a22XlbK2gU") {
          visitors = 13;
          pageviews = 34;
        } else if (projectId === "prj_7BpZVVugGOf644g81XxOCLKnDRe0") {
          visitors = 8;
          pageviews = 19;
        }
        return Response.json({
          data: { visitors, pageviews }
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

test("sparkline unit tests: crescente, decrescente, estavel, zeros e ausentes", () => {
  // Crescente
  const inc = generateSparkline([
    { visitors: 10 }, { visitors: 20 }, { visitors: 30 },
    { visitors: 40 }, { visitors: 50 }, { visitors: 60 }, { visitors: 70 }
  ]);
  assert.equal(inc.length, 7);
  assert.equal(inc[0], " ");
  assert.equal(inc[6], "█");

  // Decrescente
  const dec = generateSparkline([
    { visitors: 70 }, { visitors: 60 }, { visitors: 50 },
    { visitors: 40 }, { visitors: 30 }, { visitors: 20 }, { visitors: 10 }
  ]);
  assert.equal(dec.length, 7);
  assert.equal(dec[0], "█");
  assert.equal(dec[6], " ");

  // Estável com valores > 0
  const flat = generateSparkline([
    { visitors: 15 }, { visitors: 15 }, { visitors: 15 },
    { visitors: 15 }, { visitors: 15 }, { visitors: 15 }, { visitors: 15 }
  ]);
  assert.equal(flat, "▄▄▄▄▄▄▄");

  // Todos zeros
  const zeros = generateSparkline([
    { visitors: 0 }, { visitors: 0 }, { visitors: 0 },
    { visitors: 0 }, { visitors: 0 }, { visitors: 0 }, { visitors: 0 }
  ]);
  assert.equal(zeros, "       ");

  // Dados ausentes
  assert.equal(generateSparkline([{ visitors: 10 }, { visitors: null }]), null);
  assert.equal(generateSparkline([]), null);
  assert.equal(generateSparkline(null), null);
});

test("formatDelta unit tests: percentual, queda, estabilidade e divisao por zero", () => {
  assert.equal(formatDelta(114, 100), "▲ +14,0%");
  assert.equal(formatDelta(91.5, 100), "▼ -8,5%");
  assert.equal(formatDelta(100, 100), "▬ 0%");
  assert.equal(formatDelta(0, 0), "▬ 0%");
  assert.equal(formatDelta(15, 0), "Sem base comparável");
  assert.equal(formatDelta(null, 10), "Sem base comparável");
  assert.equal(formatDelta(10, null), "Sem base comparável");
});

test("scheduled report delivers formatted 3-product dashboard with sparklines and acquisition", async () => {
  const mock = setupFetch();
  try {
    // Simula execução às 09:00 BRT em 11/10/2026 (D-1 = 10/10/2026)
    await sendDailyReport(mockEnv(), new Date("2026-10-11T12:00:00.000Z"));
    // 3 projetos * (7 contagens diárias + 2 agregações) = 3 * 9 = 27 chamadas
    assert.equal(mock.calls.length, 27);
    assert.equal(mock.discordMessages.length, 1);
    const report = mock.discordMessages[0];
    assert.equal(report.embeds.length, 3);
    assert.ok(report.content.includes("RELATÓRIO DIÁRIO — ECOSSISTEMA SIGNALLQ"));
    assert.ok(report.content.includes("Período: 2026-10-10"));

    const [signallq, lagcheck, linka] = report.embeds;

    // 1. SignallQ
    assert.equal(signallq.title, "SIGNALLQ | Diagnóstico de Internet");
    assert.equal(signallq.color, 0x5b21d6);
    assert.ok(signallq.fields.some(x => x.name.includes("Visitantes únicos") && x.value === "20"));
    assert.ok(signallq.fields.some(x => x.name.includes("Visualizações") && x.value === "55"));
    assert.ok(signallq.fields.some(x => x.name.includes("Variação vs ontem") && x.value === "▬ 0%"));
    assert.ok(signallq.fields.some(x => x.name.includes("Tendência dos últimos 7 dias")));
    assert.ok(signallq.fields.some(x => x.name.includes("Páginas mais acessadas")));
    assert.ok(signallq.fields.some(x => x.name.includes("Principais origens")));

    // 2. Lagcheck
    assert.equal(lagcheck.title, "LAGCHECK | Gaming Network");
    assert.equal(lagcheck.color, 0x7c3aed);
    assert.ok(lagcheck.fields.some(x => x.name.includes("Visitantes únicos") && x.value === "13"));
    assert.ok(lagcheck.fields.some(x => x.name.includes("Visualizações") && x.value === "34"));
    const aquisicao = lagcheck.fields.find(x => x.name === "Aquisição");
    assert.ok(aquisicao.value.includes("7"));
    assert.ok(aquisicao.value.includes("Cliques por 100 visitantes"));
    assert.ok(aquisicao.value.includes("53,8"));
    assert.ok(aquisicao.value.includes("não downloads confirmados"));
    assert.ok(lagcheck.fields.some(x => x.name.includes("Páginas de maior interesse")));

    // 3. Linka
    assert.equal(linka.title, "LINKA | Speedtest & Assist");
    assert.equal(linka.color, 0x102245);
    assert.ok(linka.fields.some(x => x.name.includes("Visitantes únicos") && x.value === "8"));
    assert.ok(linka.fields.some(x => x.name.includes("Visualizações") && x.value === "19"));
    assert.ok(linka.fields.some(x => x.name.includes("Tendência dos últimos 7 dias")));

    // Nenhum segredo exposto
    assert.ok(!JSON.stringify(report).includes(TOKEN));
  } finally {
    mock.restore();
  }
});

test("Vercel errors on single project mark only that embed as unavailable", async () => {
  const mock = setupFetch({ failingProject: "prj_GuijE4Exyc2TplaUG6a22XlbK2gU" });
  try {
    await sendDailyReport(mockEnv(), new Date("2026-10-11T12:00:00.000Z"));
    assert.equal(mock.discordMessages.length, 1);
    const [signallq, lagcheck, linka] = mock.discordMessages[0].embeds;
    assert.ok(lagcheck.title.includes("dados indisponíveis"));
    assert.ok(signallq.fields.some(x => x.value === "20"));
    assert.ok(linka.fields.some(x => x.value === "8"));
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
