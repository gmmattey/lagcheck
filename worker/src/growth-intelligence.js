// SignallQ Growth Intelligence — Módulo de Inteligência com Cloudflare Workers AI
// Modelo: @cf/google/gemma-4-26b-a4b-it
// Análise semanal estratégica para SignallQ (Android), Lagcheck (iOS) e Linka (iOS).

export const GROWTH_MODEL = "@cf/google/gemma-4-26b-a4b-it";

export const GROWTH_SYSTEM_PROMPT = `Você é o Diretor de Growth e Marketing do ecossistema SignallQ, especializado em aplicativos mobile B2C, aquisição orgânica, SEO, ASO, conversão, engajamento e posicionamento comercial.

Seu portfólio contém:
- SignallQ: aplicativo Android para diagnóstico de internet, Wi-Fi, ferramentas de rede e avaliação de conectividade para jogos.
- Lagcheck: aplicativo iOS dedicado a avaliar indicadores de estabilidade de rede para jogadores online. Não promete reduzir o ping nem testar diretamente todos os servidores oficiais de jogos.
- Linka: aplicativo iOS de conectividade, testes de internet e assistência contextual.

Sua responsabilidade é recomendar decisões práticas para aumentar descoberta, interesse qualificado, instalações e utilização dos aplicativos.
Você não é um assistente motivacional.

Você deve:
1. Analisar somente os dados fornecidos.
2. Identificar mudanças relevantes.
3. Separar fatos de hipóteses.
4. Priorizar ações pelo potencial de impacto e esforço.
5. Identificar problemas de aquisição e conversão.
6. Recomendar no máximo três ações.
7. Indicar a métrica que permitirá avaliar cada ação.
8. Declarar explicitamente quando não houver dados suficientes.

Regras obrigatórias:
- Nunca invente dados.
- Não atribua causalidade a uma simples correlação.
- Não confunda pageviews com visitantes.
- Não confunda cliques com instalações.
- Não conclua que uma campanha deu certo sem dados correspondentes.
- Não sugira investimento financeiro como prioridade automática.
- Não recomende mudanças genéricas como "melhorar SEO" sem especificar uma ação e a evidência disponível.
- Não presuma que todos os acessos do site acontecem em dispositivos compatíveis com o aplicativo.
- Não repita recomendações sem fatos novos ou sem acompanhamento.
- Quando a amostra for pequena, reduza a confiança e priorize mensuração e experimentos simples.
- A linguagem deve ser profissional, direta, objetiva e em português brasileiro.

Cada recomendação deve explicar:
- Qual produto.
- Qual oportunidade ou problema.
- Qual evidência sustenta a hipótese.
- Qual ação executar.
- Qual métrica acompanhar.
- Qual nível de confiança.

Não produza mais de três prioridades por relatório.
Se não houver evidências suficientes, declare isso claramente.

Responda ESTRITAMENTE em formato JSON com o seguinte schema:
{
  "resumoExecutivo": "string (máximo 3 frases objetivas)",
  "confiancaGeral": "baixa" | "media" | "alta",
  "principaisSinais": [
    {
      "produto": "string",
      "observacao": "string",
      "evidencia": "string"
    }
  ],
  "prioridades": [
    {
      "produto": "SignallQ" | "Lagcheck" | "Linka" | "Ecossistema",
      "acao": "string",
      "justificativa": "string",
      "impacto": "alto" | "medio" | "baixo",
      "esforco": "alto" | "medio" | "baixo",
      "confianca": "baixa" | "media" | "alta",
      "kpi": "string",
      "criterioSucesso": "string"
    }
  ],
  "alertas": [
    "string"
  ]
}`;

export function isMondayBrazil(date = new Date()) {
  const weekday = new Intl.DateTimeFormat("en-US", {
    timeZone: "America/Sao_Paulo",
    weekday: "short"
  }).format(date);
  return weekday === "Mon";
}

function brazilDate(date) {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/Sao_Paulo",
    year: "numeric",
    month: "2-digit",
    day: "2-digit"
  }).format(date);
}

function sanitizeDiscordText(text) {
  if (typeof text !== "string") return "";
  return text
    .replace(/@everyone/gi, "@\u200beveryone")
    .replace(/@here/gi, "@\u200bhere")
    .replace(/<@&?\d+>/g, "[menção]")
    .trim();
}

export function getWeeklyDateRanges(now = new Date()) {
  const MS_PER_DAY = 24 * 60 * 60 * 1000;

  // D-1 (domingo anterior)
  const d1 = new Date(now.getTime() - 1 * MS_PER_DAY);
  const d1Str = brazilDate(d1);

  // D-7 (segunda anterior)
  const d7 = new Date(now.getTime() - 7 * MS_PER_DAY);
  const d7Str = brazilDate(d7);

  // D-8 (domingo de 2 semanas atrás)
  const d8 = new Date(now.getTime() - 8 * MS_PER_DAY);
  const d8Str = brazilDate(d8);

  // D-14 (segunda de 2 semanas atrás)
  const d14 = new Date(now.getTime() - 14 * MS_PER_DAY);
  const d14Str = brazilDate(d14);

  const afterD1 = brazilDate(now);
  const afterD8 = brazilDate(new Date(d8.getTime() + MS_PER_DAY));

  const currentWeek = {
    startStr: d7Str,
    endStr: d1Str,
    since: new Date(d7Str + "T00:00:00-03:00").toISOString(),
    until: new Date(new Date(afterD1 + "T00:00:00-03:00").getTime() - 1).toISOString()
  };

  const previousWeek = {
    startStr: d14Str,
    endStr: d8Str,
    since: new Date(d14Str + "T00:00:00-03:00").toISOString(),
    until: new Date(new Date(afterD8 + "T00:00:00-03:00").getTime() - 1).toISOString()
  };

  return {
    currentWeek,
    previousWeek,
    weekKey: currentWeek.startStr
  };
}

export async function fetchWeeklyProjectMetrics(env, project, dateRanges, vercelTeamId) {
  const baseCount = "https://api.vercel.com/v1/query/web-analytics/visits/count";
  const baseAgg = "https://api.vercel.com/v1/query/web-analytics/visits";

  const headers = {
    Authorization: "Bearer " + env.VERCEL_TOKEN,
    "User-Agent": "SignallQ-Growth-Intelligence/1.0"
  };

  const urlCurr = `${baseCount}?teamId=${vercelTeamId}&projectId=${project.id}&since=${encodeURIComponent(dateRanges.currentWeek.since)}&until=${encodeURIComponent(dateRanges.currentWeek.until)}`;
  const urlPrev = `${baseCount}?teamId=${vercelTeamId}&projectId=${project.id}&since=${encodeURIComponent(dateRanges.previousWeek.since)}&until=${encodeURIComponent(dateRanges.previousWeek.until)}`;
  const urlPages = `${baseAgg}?teamId=${vercelTeamId}&projectId=${project.id}&since=${encodeURIComponent(dateRanges.currentWeek.since)}&until=${encodeURIComponent(dateRanges.currentWeek.until)}&by=requestPath&limit=3`;
  const urlRef = `${baseAgg}?teamId=${vercelTeamId}&projectId=${project.id}&since=${encodeURIComponent(dateRanges.currentWeek.since)}&until=${encodeURIComponent(dateRanges.currentWeek.until)}&by=referrerHostname&limit=3`;

  const [resCurr, resPrev, resPages, resRef] = await Promise.allSettled([
    fetch(urlCurr, { headers }),
    fetch(urlPrev, { headers }),
    fetch(urlPages, { headers }),
    fetch(urlRef, { headers })
  ]);

  if (resCurr.status !== "fulfilled" || !resCurr.value.ok) {
    return {
      name: project.name,
      available: false,
      reason: "Falha ao obter contagem semanal da Vercel"
    };
  }

  const currJson = await resCurr.value.json().catch(() => ({}));
  const prevJson = resPrev.status === "fulfilled" && resPrev.value.ok ? await resPrev.value.json().catch(() => ({})) : null;
  const pagesJson = resPages.status === "fulfilled" && resPages.value.ok ? await resPages.value.json().catch(() => ({})) : null;
  const refJson = resRef.status === "fulfilled" && resRef.value.ok ? await resRef.value.json().catch(() => ({})) : null;

  const visitorsCurr = Number(currJson?.data?.visitors || 0);
  const pageviewsCurr = Number(currJson?.data?.pageviews || 0);
  const visitorsPrev = prevJson?.data?.visitors != null ? Number(prevJson.data.visitors) : null;
  const pageviewsPrev = prevJson?.data?.pageviews != null ? Number(prevJson.data.pageviews) : null;

  let deltaVisitors = null;
  if (visitorsPrev != null && visitorsPrev > 0) {
    deltaVisitors = Number((((visitorsCurr - visitorsPrev) / visitorsPrev) * 100).toFixed(1));
  }

  let deltaPageviews = null;
  if (pageviewsPrev != null && pageviewsPrev > 0) {
    deltaPageviews = Number((((pageviewsCurr - pageviewsPrev) / pageviewsPrev) * 100).toFixed(1));
  }

  const topPages = Array.isArray(pagesJson?.data)
    ? pagesJson.data.map(p => ({ path: p.requestPath, views: p.pageviews }))
    : [];

  const topReferrers = Array.isArray(refJson?.data)
    ? refJson.data.map(r => ({ source: r.referrerHostname || "direto", views: r.pageviews }))
    : [];

  return {
    name: project.name,
    available: true,
    visitorsCurr,
    pageviewsCurr,
    visitorsPrev,
    pageviewsPrev,
    deltaVisitors,
    deltaPageviews,
    topPages,
    topReferrers
  };
}

export async function aggregateWeeklyMetrics(env, projects, dateRanges, vercelTeamId) {
  const projectMetrics = await Promise.all(
    projects.map(p => fetchWeeklyProjectMetrics(env, p, dateRanges, vercelTeamId))
  );

  // Cliques de Lagcheck na semana completa (D-7 a D-1)
  let lagcheckWeeklyClicks = 0;
  const MS_PER_DAY = 24 * 60 * 60 * 1000;
  const weekStart = new Date(dateRanges.currentWeek.startStr + "T12:00:00-03:00");
  for (let i = 0; i < 7; i++) {
    const day = new Date(weekStart.getTime() + i * MS_PER_DAY);
    const dateStr = brazilDate(day);
    if (env.WAITLIST_KV && typeof env.WAITLIST_KV.get === "function") {
      try {
        const val = await env.WAITLIST_KV.get("stats:daily:" + dateStr);
        if (val) {
          const parsed = JSON.parse(val);
          lagcheckWeeklyClicks += Number(parsed?.clicks || 0);
        }
      } catch {
        // Ignora falha de leitura individual
      }
    }
  }

  // Verifica volume total para conservadorismo estatístico
  let totalVisitors = 0;
  let anyAvailable = false;
  for (const m of projectMetrics) {
    if (m.available) {
      anyAvailable = true;
      totalVisitors += m.visitorsCurr;
    }
  }

  const lowVolume = totalVisitors < 100;

  return {
    periodo: {
      semanaAtual: `${dateRanges.currentWeek.startStr} a ${dateRanges.currentWeek.endStr}`,
      semanaAnterior: `${dateRanges.previousWeek.startStr} a ${dateRanges.previousWeek.endStr}`
    },
    qualidadeDados: {
      anyAvailable,
      totalVisitors,
      lowVolume,
      observacao: lowVolume
        ? "Amostragem semanal reduzida (< 100 visitantes totais). Conclusões devem ser tratadas com baixa confiança e foco em testes simples."
        : "Amostragem suficiente para priorização orientada a dados."
    },
    produtos: projectMetrics.map(m => {
      if (!m.available) return m;
      const res = { ...m };
      if (m.name === "Lagcheck") {
        res.appStoreClicks = lagcheckWeeklyClicks;
        res.clicksPer100Visitors = m.visitorsCurr > 0
          ? Number(((lagcheckWeeklyClicks / m.visitorsCurr) * 100).toFixed(1))
          : 0;
        res.notaAquisicao = "Cliques na App Store representam intenção de instalação, não downloads confirmados.";
      }
      return res;
    })
  };
}

export function validateGrowthIntelligenceResponse(rawText, metrics) {
  if (!rawText || typeof rawText !== "string") {
    throw new Error("Resposta da IA vazia ou inválida");
  }

  // Remove eventuais blocos markdown ```json ... ```
  let clean = rawText.trim();
  clean = clean.replace(/^```json\s*/i, "").replace(/^```\s*/, "").replace(/\s*```$/, "");

  // Tenta encontrar o primeiro { e o último }
  const firstBrace = clean.indexOf("{");
  const lastBrace = clean.lastIndexOf("}");
  if (firstBrace === -1 || lastBrace === -1 || lastBrace <= firstBrace) {
    throw new Error("Nenhum objeto JSON encontrado na resposta da IA");
  }

  const jsonSubstring = clean.substring(firstBrace, lastBrace + 1);
  let parsed;
  try {
    parsed = JSON.parse(jsonSubstring);
  } catch (err) {
    throw new Error("Falha ao analisar JSON da IA: " + err.message);
  }

  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error("JSON da IA não é um objeto");
  }

  const resumo = sanitizeDiscordText(parsed.resumoExecutivo || "");
  if (!resumo) {
    throw new Error("Campo 'resumoExecutivo' ausente ou vazio");
  }

  let confiancaGeral = String(parsed.confiancaGeral || "baixa").toLowerCase();
  if (!["baixa", "media", "alta"].includes(confiancaGeral)) {
    confiancaGeral = "baixa";
  }

  // Se o volume de visitantes for baixo, força a confiança para baixa
  if (metrics.qualidadeDados?.lowVolume) {
    confiancaGeral = "baixa";
  }

  // Validação de principais sinais (máximo 3)
  const principaisSinais = [];
  if (Array.isArray(parsed.principaisSinais)) {
    for (const sinal of parsed.principaisSinais.slice(0, 3)) {
      if (sinal && typeof sinal === "object") {
        principaisSinais.push({
          produto: sanitizeDiscordText(String(sinal.produto || "")).slice(0, 40),
          observacao: sanitizeDiscordText(String(sinal.observacao || "")).slice(0, 160),
          evidencia: sanitizeDiscordText(String(sinal.evidencia || "")).slice(0, 160)
        });
      }
    }
  }

  // Validação de prioridades (máximo 3)
  const prioridades = [];
  if (Array.isArray(parsed.prioridades)) {
    for (const p of parsed.prioridades.slice(0, 3)) {
      if (p && typeof p === "object") {
        let conf = String(p.confianca || "baixa").toLowerCase();
        if (!["baixa", "media", "alta"].includes(conf) || metrics.qualidadeDados?.lowVolume) {
          conf = "baixa";
        }
        prioridades.push({
          produto: sanitizeDiscordText(String(p.produto || "Ecossistema")).slice(0, 32),
          acao: sanitizeDiscordText(String(p.acao || "")).slice(0, 120),
          justificativa: sanitizeDiscordText(String(p.justificativa || "")).slice(0, 240),
          impacto: ["alto", "medio", "baixo"].includes(String(p.impacto || "").toLowerCase()) ? String(p.impacto).toLowerCase() : "medio",
          esforco: ["alto", "medio", "baixo"].includes(String(p.esforco || "").toLowerCase()) ? String(p.esforco).toLowerCase() : "medio",
          confianca: conf,
          kpi: sanitizeDiscordText(String(p.kpi || "")).slice(0, 100),
          criterioSucesso: sanitizeDiscordText(String(p.criterioSucesso || "")).slice(0, 160)
        });
      }
    }
  }

  // Validação de alertas
  const alertas = [];
  if (Array.isArray(parsed.alertas)) {
    for (const a of parsed.alertas.slice(0, 3)) {
      if (typeof a === "string" && a.trim()) {
        alertas.push(sanitizeDiscordText(a).slice(0, 180));
      }
    }
  }

  if (metrics.qualidadeDados?.lowVolume && !alertas.some(a => a.toLowerCase().includes("amostragem"))) {
    alertas.unshift("Amostragem semanal reduzida (< 100 visitantes): priorizar validação básica e testes controlados.");
  }

  return {
    resumoExecutivo: resumo.slice(0, 400),
    confiancaGeral,
    principaisSinais,
    prioridades,
    alertas
  };
}

export function formatGrowthIntelligenceEmbed(growthData, periodStr) {
  const fields = [];

  // Parecer estratégico / Resumo executivo
  fields.push({
    name: "📋 Parecer estratégico semanal",
    value: `*Análise dos últimos sete dias completos · Cloudflare Workers AI*\n\n**Resumo executivo:**\n${growthData.resumoExecutivo}\n\n*Nível de confiança geral: **${growthData.confiancaGeral.toUpperCase()}***`,
    inline: false
  });

  // Principais sinais (até 3)
  if (growthData.principaisSinais.length > 0) {
    const sinaisText = growthData.principaisSinais
      .map(s => `• **${s.produto}:** ${s.observacao} *(Evidência: ${s.evidencia})*`)
      .join("\n");
    fields.push({
      name: "🔍 Principais sinais observados",
      value: sinaisText,
      inline: false
    });
  }

  // Prioridades (P1, P2, P3)
  if (growthData.prioridades.length > 0) {
    growthData.prioridades.forEach((p, idx) => {
      const pNum = `P${idx + 1}`;
      const header = `${pNum} — ${p.produto} / ${p.acao}`;
      const body = [
        `• **Motivo:** ${p.justificativa}`,
        `• **Impacto:** ${p.impacto} | **Esforço:** ${p.esforco} | **Confiança:** ${p.confianca}`,
        `• **KPI:** ${p.kpi}`,
        `• **Critério de sucesso:** ${p.criterioSucesso}`
      ].join("\n");

      fields.push({
        name: header,
        value: body,
        inline: false
      });
    });
  }

  // Alertas / Atenção
  if (growthData.alertas.length > 0) {
    const alertasText = growthData.alertas.map(a => `• ${a}`).join("\n");
    fields.push({
      name: "⚠️ Atenção e limitações",
      value: alertasText,
      inline: false
    });
  }

  return {
    title: "SIGNALLQ GROWTH INTELLIGENCE",
    color: 0x5b21d6,
    fields,
    footer: {
      text: `Análise automatizada por Gemma 4 · Cloudflare Workers AI · Período: ${periodStr} · Recomendações sujeitas a validação`
    }
  };
}

export async function runWeeklyGrowthIntelligence(env, projects, dateRanges, vercelTeamId) {
  // 1. Verificação de Feature Flag
  if (env.GROWTH_AI_ENABLED !== "true") {
    console.info("Growth Intelligence: desativado por feature flag (GROWTH_AI_ENABLED !== 'true')");
    return null;
  }

  // 2. Verificação do binding AI
  if (!env.AI || typeof env.AI.run !== "function") {
    console.warn("Growth Intelligence: binding env.AI ausente ou inválido");
    return null;
  }

  // 3. Cache / Deduplicação no KV
  const cacheKey = "growth_ai:weekly:" + dateRanges.weekKey;
  if (env.WAITLIST_KV && typeof env.WAITLIST_KV.get === "function") {
    try {
      const cached = await env.WAITLIST_KV.get(cacheKey);
      if (cached) {
        const parsedCached = JSON.parse(cached);
        console.info("Growth Intelligence: reutilizando análise semanal em cache para " + dateRanges.weekKey);
        return formatGrowthIntelligenceEmbed(parsedCached, `${dateRanges.currentWeek.startStr} a ${dateRanges.currentWeek.endStr}`);
      }
    } catch (err) {
      console.warn("Growth Intelligence: erro ao ler cache KV", err?.message);
    }
  }

  // 4. Agregação determinística das métricas
  const metrics = await aggregateWeeklyMetrics(env, projects, dateRanges, vercelTeamId);

  // Se nenhum produto estiver disponível na Vercel, aborta inferência
  if (!metrics.qualidadeDados.anyAvailable) {
    console.warn("Growth Intelligence: nenhum produto com dados disponíveis na Vercel");
    return null;
  }

  // 5. Chamada de Inferência ao Modelo Gemma 4
  let rawAiResponse;
  try {
    const aiResult = await env.AI.run(
      GROWTH_MODEL,
      {
        messages: [
          { role: "system", content: GROWTH_SYSTEM_PROMPT },
          { role: "user", content: JSON.stringify(metrics) }
        ],
        max_completion_tokens: 900,
        temperature: 0.2,
        chat_template_kwargs: {
          enable_thinking: false
        }
      }
    );

    rawAiResponse = typeof aiResult === "string"
      ? aiResult
      : (aiResult?.response || aiResult?.choices?.[0]?.message?.content || "");
  } catch (err) {
    console.error("Growth Intelligence: falha na inferência Cloudflare Workers AI", err?.message);
    return null;
  }

  // 6. Validação e sanitização estrita do contrato
  let validated;
  try {
    validated = validateGrowthIntelligenceResponse(rawAiResponse, metrics);
  } catch (err) {
    console.error("Growth Intelligence: resposta da IA rejeitada por validação de contrato", err?.message);
    return null;
  }

  // 7. Salva no cache do KV para deduplicação (TTL 14 dias)
  if (env.WAITLIST_KV && typeof env.WAITLIST_KV.put === "function") {
    try {
      await env.WAITLIST_KV.put(cacheKey, JSON.stringify(validated), {
        expirationTtl: 14 * 86400
      });
    } catch (err) {
      console.warn("Growth Intelligence: falha ao salvar cache KV", err?.message);
    }
  }

  const periodStr = `${dateRanges.currentWeek.startStr} a ${dateRanges.currentWeek.endStr}`;
  return formatGrowthIntelligenceEmbed(validated, periodStr);
}
