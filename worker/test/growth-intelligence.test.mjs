import test from "node:test";
import assert from "node:assert/strict";
import {
  isMondayBrazil,
  getWeeklyDateRanges,
  aggregateWeeklyMetrics,
  validateGrowthIntelligenceResponse,
  formatGrowthIntelligenceEmbed,
  runWeeklyGrowthIntelligence,
  GROWTH_SYSTEM_PROMPT,
  GROWTH_MODEL
} from "../src/growth-intelligence.js";
import { sendDailyReport, handleRequest } from "../src/index.js";

const TOKEN = "secret-vercel-token";
const DISCORD_URL = "https://discord.com/api/webhooks/test-growth";

function mockEnv({ aiResponse, aiThrows, enableAi = "true", cachedGrowth } = {}) {
  const kvStore = new Map();
  if (cachedGrowth) {
    kvStore.set("growth_ai:weekly:2026-10-05", JSON.stringify(cachedGrowth));
  }

  return {
    VERCEL_TOKEN: TOKEN,
    DISCORD_WEBHOOK_URL: DISCORD_URL,
    GROWTH_AI_ENABLED: enableAi,
    AI: {
      runCalls: [],
      run: async (model, params) => {
        if (aiThrows) throw aiThrows;
        return { response: aiResponse };
      }
    },
    WAITLIST_KV: {
      get: async (k) => kvStore.get(k) || (k.startsWith("stats:daily:") ? JSON.stringify({ clicks: 12 }) : null),
      put: async (k, v) => kvStore.set(k, v)
    }
  };
}

const VALID_AI_JSON = JSON.stringify({
  resumoExecutivo: "O ecossistema apresentou estabilidade em SignallQ e forte tração orgânica no Lagcheck. O Linka necessita de rotas de aquisição exploratórias.",
  confiancaGeral: "alta",
  principaisSinais: [
    {
      produto: "Lagcheck",
      observacao: "Alta intenção de download nas páginas de jogos competitivos.",
      evidencia: "84 cliques na App Store com 380 visitantes únicos."
    },
    {
      produto: "SignallQ",
      observacao: "Crescimento sustentado via busca direta e Google.",
      evidencia: "1.250 visitantes com +14% vs semana anterior."
    }
  ],
  prioridades: [
    {
      produto: "Lagcheck",
      acao: "Otimizar meta tags e contextualização para Call of Duty: Warzone",
      justificativa: "Página de maior interesse orgânico com alto volume e intenção.",
      impacto: "alto",
      esforco: "baixo",
      confianca: "alta",
      kpi: "Cliques na App Store por 100 visitantes",
      criterioSucesso: "Aumentar a taxa de cliques de 22% para 28%"
    },
    {
      produto: "SignallQ",
      acao: "Criar CTA contextualizado para ferramenta de ping no Android",
      justificativa: "Mais de 60% dos visitantes buscam ferramentas de rede.",
      impacto: "medio",
      esforco: "medio",
      confianca: "media",
      kpi: "Taxa de engajamento na Home",
      criterioSucesso: "Elevação de 10% nas visitas às rotas de teste"
    }
  ],
  alertas: [
    "Conversão final em downloads não é mensurável na web; métrica reflete intenção."
  ]
});

// 1. Execução semanal somente na segunda-feira
test("1. isMondayBrazil retorna true apenas para segunda-feira em Brasília", () => {
  // Segunda-feira 12/10/2026 09:00 BRT (12:00 UTC)
  assert.equal(isMondayBrazil(new Date("2026-10-12T12:00:00Z")), true);
  // Domingo 11/10/2026
  assert.equal(isMondayBrazil(new Date("2026-10-11T12:00:00Z")), false);
  // Terça-feira 13/10/2026
  assert.equal(isMondayBrazil(new Date("2026-10-13T12:00:00Z")), false);
});

// 2. Não execução de IA nos demais dias
test("2. sendDailyReport não chama IA em dias que não são segunda-feira", async () => {
  let aiCalled = false;
  const env = mockEnv();
  env.AI.run = async () => {
    aiCalled = true;
    return { response: VALID_AI_JSON };
  };

  const originalFetch = globalThis.fetch;
  let discordPayload = null;
  globalThis.fetch = async (url, opts) => {
    if (String(url) === DISCORD_URL) {
      discordPayload = JSON.parse(opts.body);
      return new Response(null, { status: 204 });
    }
    return Response.json({ data: { visitors: 10, pageviews: 20 } });
  };

  try {
    // Executa em um Domingo (11/10/2026)
    await sendDailyReport(env, new Date("2026-10-11T12:00:00Z"));
    assert.equal(aiCalled, false, "IA não deve ser chamada no domingo");
    assert.equal(discordPayload.embeds.length, 3, "Deve conter apenas 3 embeds");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

// 3. Datas no horário de Brasília
test("3. getWeeklyDateRanges calcula corretamente os intervalos civis em Brasília", () => {
  const ranges = getWeeklyDateRanges(new Date("2026-10-12T12:00:00Z"));
  // Semana atual (D-7 a D-1): 05/10/2026 a 11/10/2026
  assert.equal(ranges.currentWeek.startStr, "2026-10-05");
  assert.equal(ranges.currentWeek.endStr, "2026-10-11");
  // Semana anterior (D-14 a D-8): 28/09/2026 a 04/10/2026
  assert.equal(ranges.previousWeek.startStr, "2026-09-28");
  assert.equal(ranges.previousWeek.endStr, "2026-10-04");
  assert.equal(ranges.weekKey, "2026-10-05");
});

// 4. Comparação das duas semanas completas
test("4. aggregateWeeklyMetrics calcula variações percentuais entre semanas", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url) => {
    const parsed = new URL(String(url));
    if (parsed.searchParams.get("since").includes("2026-10-05")) {
      return Response.json({ data: { visitors: 200, pageviews: 500 } });
    }
    return Response.json({ data: { visitors: 100, pageviews: 250 } });
  };

  try {
    const env = mockEnv();
    const ranges = getWeeklyDateRanges(new Date("2026-10-12T12:00:00Z"));
    const metrics = await aggregateWeeklyMetrics(env, [{ name: "SignallQ", id: "prj_test" }], ranges, "team_test");
    const sig = metrics.produtos[0];
    assert.equal(sig.visitorsCurr, 200);
    assert.equal(sig.visitorsPrev, 100);
    assert.equal(sig.deltaVisitors, 100.0);
    assert.equal(sig.deltaPageviews, 100.0);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

// 5. Resposta válida do modelo
test("5. validateGrowthIntelligenceResponse valida schema e formata quarto embed", () => {
  const metrics = { qualidadeDados: { lowVolume: false } };
  const validated = validateGrowthIntelligenceResponse(VALID_AI_JSON, metrics);
  assert.equal(validated.confiancaGeral, "alta");
  assert.equal(validated.principaisSinais.length, 2);
  assert.equal(validated.prioridades.length, 2);
  assert.equal(validated.prioridades[0].produto, "Lagcheck");

  const embed = formatGrowthIntelligenceEmbed(validated, "05/10/2026 a 11/10/2026");
  assert.equal(embed.title, "SIGNALLQ GROWTH INTELLIGENCE");
  assert.equal(embed.color, 0x5b21d6);
  assert.ok(embed.fields.some(f => f.name.includes("Parecer estratégico semanal")));
  assert.ok(embed.fields.some(f => f.name.includes("P1 — Lagcheck")));
  assert.ok(embed.footer.text.includes("Gemma 4"));
});

// 6. Resposta malformada
test("6. validateGrowthIntelligenceResponse rejeita resposta malformada sem quebrar", () => {
  const metrics = { qualidadeDados: { lowVolume: false } };
  assert.throws(() => {
    validateGrowthIntelligenceResponse("Isso é um texto puro sem JSON", metrics);
  }, /Nenhum objeto JSON encontrado/);

  assert.throws(() => {
    validateGrowthIntelligenceResponse('{"outroCampo": 123}', metrics);
  }, /resumoExecutivo/);
});

// 7. Modelo indisponível
test("7. runWeeklyGrowthIntelligence captura falha de modelo e retorna null com segurança", async () => {
  const env = mockEnv({ aiThrows: new Error("Cloudflare AI error: 503 Service Unavailable") });
  const ranges = getWeeklyDateRanges(new Date("2026-10-12T12:00:00Z"));
  const res = await runWeeklyGrowthIntelligence(env, [], ranges, "team_test");
  assert.equal(res, null);
});

// 8. Ausência de binding AI
test("8. runWeeklyGrowthIntelligence retorna null quando env.AI está ausente", async () => {
  const env = mockEnv();
  delete env.AI;
  const ranges = getWeeklyDateRanges(new Date("2026-10-12T12:00:00Z"));
  const res = await runWeeklyGrowthIntelligence(env, [], ranges, "team_test");
  assert.equal(res, null);
});

// 9. Franquia excedida (429)
test("9. runWeeklyGrowthIntelligence trata erro 429 de cota sem exceção não tratada", async () => {
  const env = mockEnv({ aiThrows: new Error("429 Too Many Requests: Daily quota exceeded") });
  const ranges = getWeeklyDateRanges(new Date("2026-10-12T12:00:00Z"));
  const res = await runWeeklyGrowthIntelligence(env, [], ranges, "team_test");
  assert.equal(res, null);
});

// 10. Baixo volume de dados
test("10. Baixo volume de dados (<100) força confiança geral e das prioridades para baixa", () => {
  const metrics = { qualidadeDados: { lowVolume: true } };
  const validated = validateGrowthIntelligenceResponse(VALID_AI_JSON, metrics);
  assert.equal(validated.confiancaGeral, "baixa");
  assert.equal(validated.prioridades[0].confianca, "baixa");
  assert.ok(validated.alertas.some(a => a.includes("Amostragem semanal reduzida")));
});

// 11. Zero visitantes
test("11. Zero visitantes em todos os produtos trata divisão por zero e volume conservador", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => Response.json({ data: { visitors: 0, pageviews: 0 } });

  try {
    const env = mockEnv();
    const ranges = getWeeklyDateRanges(new Date("2026-10-12T12:00:00Z"));
    const metrics = await aggregateWeeklyMetrics(env, [{ name: "Linka", id: "prj_linka" }], ranges, "team_test");
    assert.equal(metrics.qualidadeDados.totalVisitors, 0);
    assert.equal(metrics.qualidadeDados.lowVolume, true);
    assert.equal(metrics.produtos[0].deltaVisitors, null);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

// 12. Histórico incompleto
test("12. Histórico incompleto (semana anterior nula) gera deltas nulos com segurança", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url) => {
    if (String(url).includes("2026-09-28")) {
      return new Response("Not found", { status: 404 });
    }
    return Response.json({ data: { visitors: 150, pageviews: 300 } });
  };

  try {
    const env = mockEnv();
    const ranges = getWeeklyDateRanges(new Date("2026-10-12T12:00:00Z"));
    const metrics = await aggregateWeeklyMetrics(env, [{ name: "SignallQ", id: "prj_sig" }], ranges, "team_test");
    assert.equal(metrics.produtos[0].visitorsCurr, 150);
    assert.equal(metrics.produtos[0].visitorsPrev, null);
    assert.equal(metrics.produtos[0].deltaVisitors, null);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

// 13. Limite de três recomendações
test("13. validateGrowthIntelligenceResponse trunca prioridades para no máximo 3", () => {
  const payloadWith5 = JSON.stringify({
    resumoExecutivo: "Resumo com muitas prioridades.",
    confiancaGeral: "media",
    principaisSinais: [],
    prioridades: [
      { produto: "P1", acao: "A1" },
      { produto: "P2", acao: "A2" },
      { produto: "P3", acao: "A3" },
      { produto: "P4", acao: "A4" },
      { produto: "P5", acao: "A5" }
    ],
    alertas: []
  });

  const validated = validateGrowthIntelligenceResponse(payloadWith5, { qualidadeDados: { lowVolume: false } });
  assert.equal(validated.prioridades.length, 3);
  assert.equal(validated.prioridades[2].produto, "P3");
});

// 14. Limites e sanitização do Discord
test("14. Sanitização remove menções de @everyone, @here e limita tamanho", () => {
  const evilPayload = JSON.stringify({
    resumoExecutivo: "Atenção @everyone e @here com <@&123456789>!",
    confiancaGeral: "media",
    principaisSinais: [],
    prioridades: [],
    alertas: []
  });

  const validated = validateGrowthIntelligenceResponse(evilPayload, { qualidadeDados: { lowVolume: false } });
  assert.ok(!validated.resumoExecutivo.includes("@everyone"));
  assert.ok(!validated.resumoExecutivo.includes("@here"));
  assert.ok(!validated.resumoExecutivo.includes("<@&123456789>"));
});

// 15. Proteção contra publicação duplicada (cache KV)
test("15. Segunda execução reaproveita análise semanal em cache sem chamar a IA", async () => {
  let aiCalled = false;
  const cachedData = {
    resumoExecutivo: "Análise previamente cacheada no KV.",
    confiancaGeral: "baixa",
    principaisSinais: [],
    prioridades: [],
    alertas: []
  };

  const env = mockEnv({ cachedGrowth: cachedData });
  env.AI.run = async () => {
    aiCalled = true;
    return { response: VALID_AI_JSON };
  };

  const ranges = getWeeklyDateRanges(new Date("2026-10-12T12:00:00Z"));
  const embed = await runWeeklyGrowthIntelligence(env, [], ranges, "team_test");

  assert.equal(aiCalled, false, "Não deve chamar IA se já existir cache da semana no KV");
  assert.ok(embed);
  assert.ok(embed.fields[0].value.includes("Análise previamente cacheada"));
});

// 16. Preservação do relatório diário
test("16. sendDailyReport preserva os 3 embeds diários mesmo se a IA falhar na segunda-feira", async () => {
  const env = mockEnv({ aiThrows: new Error("AI Timeout") });

  const originalFetch = globalThis.fetch;
  let discordPayload = null;
  globalThis.fetch = async (url, opts) => {
    if (String(url) === DISCORD_URL) {
      discordPayload = JSON.parse(opts.body);
      return new Response(null, { status: 204 });
    }
    return Response.json({ data: { visitors: 25, pageviews: 50 } });
  };

  try {
    // Segunda-feira (12/10/2026)
    await sendDailyReport(env, new Date("2026-10-12T12:00:00Z"));
    assert.equal(discordPayload.embeds.length, 3, "Os 3 embeds originais continuam intactos");
    assert.equal(discordPayload.embeds[0].title, "SIGNALLQ | Diagnóstico de Internet");
    assert.equal(discordPayload.embeds[1].title, "LAGCHECK | Gaming Network");
    assert.equal(discordPayload.embeds[2].title, "LINKA | Speedtest & Assist");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

// 17. Preservação das rotas de rede existentes
test("17. handleRequest preserva /v1/load e remove /v1/catalog.json", async () => {
  // /v1/load
  const loadRes = await handleRequest(new Request("https://test.com/v1/load"));
  assert.equal(loadRes.status, 200);

  // O catálogo é local nos clientes desde a Decisão 94.
  const catalogRes = await handleRequest(new Request("https://test.com/v1/catalog.json"));
  assert.equal(catalogRes.status, 404);

  // /v1/click
  const clickRes = await handleRequest(new Request("https://test.com/v1/click", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ page: "/jogos/fortnite" })
  }), mockEnv());
  assert.equal(clickRes.status, 200);
});

// 18. Ausência de vazamento de Secrets
test("18. Nenhum segredo (VERCEL_TOKEN ou webhook) vaza nos embeds gerados", () => {
  const validated = validateGrowthIntelligenceResponse(VALID_AI_JSON, { qualidadeDados: { lowVolume: false } });
  const embed = formatGrowthIntelligenceEmbed(validated, "05/10 a 11/10");
  const serialized = JSON.stringify(embed);
  assert.ok(!serialized.includes(TOKEN));
  assert.ok(!serialized.includes(DISCORD_URL));
});

// 19. Feature flag desativada
test("19. GROWTH_AI_ENABLED !== 'true' impede execução da IA", async () => {
  let aiCalled = false;
  const env = mockEnv({ enableAi: "false" });
  env.AI.run = async () => {
    aiCalled = true;
    return { response: VALID_AI_JSON };
  };

  const ranges = getWeeklyDateRanges(new Date("2026-10-12T12:00:00Z"));
  const embed = await runWeeklyGrowthIntelligence(env, [], ranges, "team_test");
  assert.equal(aiCalled, false);
  assert.equal(embed, null);
});

// 20. Compatibilidade com os três produtos
test("20. aggregateWeeklyMetrics cobre SignallQ, Lagcheck (com cliques) e Linka", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => Response.json({ data: { visitors: 50, pageviews: 120 } });

  try {
    const env = mockEnv();
    const ranges = getWeeklyDateRanges(new Date("2026-10-12T12:00:00Z"));
    const projects = [
      { name: "SignallQ", id: "p1" },
      { name: "Lagcheck", id: "p2" },
      { name: "Linka", id: "p3" }
    ];
    const metrics = await aggregateWeeklyMetrics(env, projects, ranges, "team_test");
    assert.equal(metrics.produtos.length, 3);
    const lagcheck = metrics.produtos.find(p => p.name === "Lagcheck");
    assert.ok(Number.isFinite(lagcheck.appStoreClicks));
    assert.ok(lagcheck.notaAquisicao.includes("não downloads confirmados"));
  } finally {
    globalThis.fetch = originalFetch;
  }
});
