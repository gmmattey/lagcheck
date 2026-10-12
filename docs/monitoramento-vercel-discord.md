# Monitoramento oficial: Vercel → Discord & SignallQ Growth Intelligence

## 1. Fonte de dados
- **SignallQ:** projeto Vercel `signallq-web` (`prj_XxQs4bRAtAczAwULNqDzAWgQTkpE`)
- **Lagcheck:** projeto Vercel `lagcheck` (`prj_GuijE4Exyc2TplaUG6a22XlbK2gU`)
- **Linka:** projeto Vercel `linka` (`prj_7BpZVVugGOf644g81XxOCLKnDRe0`)
- **Equipe Vercel:** `team_VCRx5oIQ20HUO84QLL62RStN`
- Web Analytics é a fonte oficial de **visitantes** e **visualizações**; as páginas do Lagcheck recebem o script `/_vercel/insights/script.js`.
- Cliques na App Store do Lagcheck continuam em `POST /v1/click` e no KV local (`WAITLIST_KV`). **Cliques não equivalem a instalações.** O plano Hobby não fornece eventos personalizados de Web Analytics.

---

## 2. Relatório Diário Determinístico (Segunda a Domingo)
O Worker `nolaggy-deep-check` possui cron `0 12 * * *` (09h Brasília em UTC-3).
- **Execução:** diária, 100% determinística. Não consome Workers AI.
- **Estrutura:**
  - Mensagem principal: cabeçalho com período D-1 e fonte oficial.
  - Embed 1 (SignallQ, `0x5b21d6`): visitantes, views, variação vs D-2, sparkline 7d, top páginas e origens.
  - Embed 2 (Lagcheck, `0x7c3aed`): tráfego, sparkline 7d, seção de **Aquisição** (cliques App Store e taxa por 100 visitantes), top páginas e origens.
  - Embed 3 (Linka, `0x102245`): tráfego, variação vs D-2, sparkline 7d, top páginas e origens.

---

## 3. SignallQ Growth Intelligence (Workers AI Semanal)
Módulo estratégico de marketing e aquisição para aplicativos mobile B2C (SignallQ Android, Lagcheck iOS, Linka iOS).

### 3.1 Modelo e Binding
- **Provedor:** Cloudflare Workers AI (nativo, sem chaves ou custos externos).
- **Modelo:** `@cf/google/gemma-4-26b-a4b-it`
- **Binding no `wrangler.jsonc`:**
  ```json
  "ai": {
    "binding": "AI"
  }
  ```
- **Parâmetros de Inferência:**
  - `max_completion_tokens: 900`
  - `temperature: 0.2`
  - `chat_template_kwargs: { enable_thinking: false }`

### 3.2 Frequência e Agendamento
- **Frequência:** exclusivamente **uma vez por semana**, às segundas-feiras no cron das 09h Brasília (`0 12 * * *`).
- **Janela de Análise:**
  - **Semana civil analisada:** de segunda-feira a domingo anteriores (`D-7` a `D-1`).
  - **Semana de comparação:** de segunda-feira a domingo anteriores à analisada (`D-14` a `D-8`).
  - Consulta os visitantes únicos reais do intervalo semanal completo na Vercel (nunca soma dias).

### 3.3 Regras de Recomendação e Qualidade
- **Persona:** Diretor de Growth e Marketing do ecossistema SignallQ, focado em aquisição orgânica, SEO, ASO e conversão.
- **Regras determinísticas:**
  - Limite estrito de no máximo 3 prioridades (P1, P2, P3).
  - Nunca confunde cliques com downloads nem pageviews com visitantes.
  - Amostragem baixa (< 100 visitantes no período) rebaixa a confiança para "baixa" e força o alerta para testes controlados.
  - Falha da Vercel em um produto não quebra a análise dos demais.

### 3.4 Controle de Custos e Franquia Gratuita
- Uma única inferência semanal.
- Entrada compacta (apenas métricas agregadas pré-processadas).
- **Cache e Deduplicação no KV:** o resultado semanal validado é salvo em `growth_ai:weekly:{semana}` com TTL de 14 dias. Reexecuções acidentais do cron não geram novas inferências.
- **Feature Flag `GROWTH_AI_ENABLED`:**
  - Se for `"true"`, a IA roda na segunda-feira.
  - Se for ausente ou diferente de `"true"`, o módulo é ignorado sem quebrar o relatório diário.
- **Tolerância a Falhas:** em caso de timeout, cota 429 ou erro no modelo, o erro é registrado no log e os 3 embeds numéricos do Discord são entregues normalmente.

---

## 4. Exemplo de Saída (Dados Fictícios de Demonstração)

```markdown
📊 RELATÓRIO DIÁRIO — ECOSSISTEMA SIGNALLQ
📅 Período: 2026-10-11
🕘 Gerado às 09h · Brasília
📡 Fonte: Vercel Web Analytics
```

*(Seguem os 3 embeds diários normais de SignallQ, Lagcheck e Linka)*

### 4º Embed — SIGNALLQ GROWTH INTELLIGENCE
> **Cor:** `#5B21D6` (Roxo SignallQ)
> 
> **📋 Parecer estratégico semanal**  
> *Análise dos últimos sete dias completos · Cloudflare Workers AI*  
> 
> **Resumo executivo:**  
> O ecossistema apresentou estabilidade em SignallQ e forte tração orgânica no Lagcheck. O Linka necessita de rotas de aquisição exploratórias para acelerar descoberta inicial.  
> *Nível de confiança geral: **ALTA***  
> 
> **🔍 Principais sinais observados**  
> • **Lagcheck:** Alta intenção de download nas páginas de jogos competitivos. *(Evidência: 84 cliques na App Store com 380 visitantes únicos.)*  
> • **SignallQ:** Crescimento sustentado via busca direta e Google. *(Evidência: 1.250 visitantes com +14% vs semana anterior.)*  
> 
> **P1 — Lagcheck / Otimizar meta tags e contextualização para Call of Duty: Warzone**  
> • **Motivo:** Página de maior interesse orgânico com alto volume e intenção.  
> • **Impacto:** alto | **Esforço:** baixo | **Confiança:** alta  
> • **KPI:** Cliques na App Store por 100 visitantes  
> • **Critério de sucesso:** Aumentar a taxa de cliques de 22% para 28%  
> 
> **P2 — SignallQ / Criar CTA contextualizado para ferramenta de ping no Android**  
> • **Motivo:** Mais de 60% dos visitantes buscam ferramentas de rede.  
> • **Impacto:** medio | **Esforço:** medio | **Confiança:** media  
> • **KPI:** Taxa de engajamento na Home  
> • **Critério de sucesso:** Elevação de 10% nas visitas às rotas de teste  
> 
> **⚠️ Atenção e limitações**  
> • Conversão final em downloads não é mensurável na web; métrica reflete intenção.  
> 
> *Rodapé: Análise automatizada por Gemma 4 · Cloudflare Workers AI · Período: 2026-10-05 a 2026-10-11 · Recomendações sujeitas a validação*

---

## 5. Configurações e Variáveis de Ambiente no Cloudflare

### Segredos (Cloudflare Workers)
- `VERCEL_TOKEN`: token da API Vercel com escopo de leitura nos 3 projetos.
- `DISCORD_WEBHOOK_URL`: webhook do canal Discord.
- `REPORT_TEST_TOKEN` (opcional): chave para testes manuais via `POST /v1/report/test`.

### Variáveis de Configuração (Vars)
- `GROWTH_AI_ENABLED`: definir como `"true"` para ativar o modelo Gemma 4 às segundas-feiras.

---

## 6. Procedimento de Rollback
1. Para desativar a IA instantaneamente sem novo deploy de código: alterar a variável `GROWTH_AI_ENABLED` para `"false"` no dashboard do Cloudflare Workers.
2. O Worker continuará publicando normalmente o relatório de 3 embeds sem qualquer interrupção.
