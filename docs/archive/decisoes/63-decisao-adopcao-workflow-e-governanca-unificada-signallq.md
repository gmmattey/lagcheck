# LagCheck — Decisão 63: Adoção do Workflow e Governança Unificada Buildea (Paralelismo com o SignallQ)

**Data:** 2026-09-26  
**Status:** Decidido e em aplicação  
**Frentes:** Marco (Produto e Integração), Renan (Design e Visual QA), Rian (iOS), Iury (Qualidade de Rede & Borda), Camillo (Arquiteto Sistêmico Buildea), Breno (QA & Reliability Buildea), Luiz (Dono do Produto)  
**Fontes relacionadas:** `docs/05-governanca-e-fluxo-de-trabalho.md` · `AGENTS.md` · `.agents/WORKFLOW.md` · `.agents/architecture-plan.md`

---

## 1. Contexto e Motivação

O SignallQ (produto irmão da Buildea, voltado ao diagnóstico doméstico/corporativo em Android) estabeleceu um modelo de governança operacional de alta maturidade com agentes autônomos. Esse modelo provou resolver com excelência:
1. A dispersão de escopo através de uma persona de entrada única que filtra ideias exploratórias de ordens reais de execução;
2. A previsibilidade de entrega através de pistas de execução categorizadas (*Fast lane*, *Full flow comum*, *Full flow sistêmica* e *Hot lane*);
3. A integridade estrutural e de contratos por meio de um **Gate Arquitetural Obrigatório** conduzido pelo Principal Engineer transversal da Buildea (**Camillo**);
4. A independência e rigor de testes através de um papel dedicado de **QA & Reliability** (**Breno**).

No LagCheck, embora os papéis de Marco, Renan, Rian e Iury estivessem bem definidos, a dinâmica entre eles carecia de formalização de lanes, gate arquitetural para mudanças sistêmicas e validação independente de QA além do visual.

Esta decisão unifica o fluxo de trabalho do LagCheck com o padrão institucional da Buildea, estabelecendo um paralelismo direto e rigoroso com a governança do SignallQ.

---

## 2. Paralelismo de Papéis e Funções

A squad do LagCheck passa a espelhar perfeitamente a estrutura de responsabilidades da Buildea:

| Papel Buildea | SignallQ (Android / Diagnóstico) | LagCheck (iOS / Jogos Competitivos) | Responsabilidade Principal no LagCheck |
| :--- | :--- | :--- | :--- |
| **Product Lead & Entrada** | **Cora** | **Marco** | Persona do orquestrador principal ao interagir com Luiz. Triagem, jornada de produto, voz honesta, critérios de aceite e ponto único de integração. |
| **Platform Engineer** | **Davi** (Android) | **Rian** (iOS) | Arquitetura SwiftUI, isolamento do `NolaggyDomain`, SwiftData, ciclo de vida da sessão, concorrência moderna e entrega técnica para iOS 17+. |
| **Diagnostic / Systems Engineer** | **Ramon** (Rede/Equipamentos) | **Iury** (Rede UDP / Borda) | Medição UDP determinística (GameLift, PlayFab, Valve), STUN RFC 5389, RFC 4737 Out-of-Order, `GameReadinessVerdict`, Cloudflare Worker e custo zero. |
| **Product Designer & Visual QA** | *Integrado a Cora / Skills* | **Renan** | Design system *Dark Competitive UI*, protótipo canônico iOS, assets autorais, conformidade com HIG, acessibilidade e QA visual minucioso. |
| **QA & Reliability** | **Breno** | **Breno** (apoiado por Renan em UI) | Validação independente, suites de testes unitários/contrato, análise estática, testes em iPhone físico real e validação de caminhos críticos. |
| **Principal Architect transversal** | **Camillo** | **Camillo** | Condução do Gate Arquitetural Obrigatório em APIs, persistência, mudanças contratuais com Workers, motor central de medição ou impacto cross-repo. |
| **Dono do Produto** | **Luiz** | **Luiz** | Autoridade máxima de negócio: escopo, posicionamento de marca, monetização, preço e autorização de release/publicação. |

---

## 3. As Pistas de Execução Adotadas (Lanes)

Conforme documentado em [`.agents/WORKFLOW.md`](../../../.agents/WORKFLOW.md):

1. **Exploração:** Luiz ou o time propondo cenários ("e se...?"). Marco elabora análise de produto e trade-offs. **Nenhum código é alterado.**
2. **Fast Lane:** Ajustes pontuais de copy, alinhamento cosmético de componentes, pequenas correções sem impacto em contratos.
   * `Marco enquadra → Rian / Iury / Renan implementa → Breno / Renan valida`.
3. **Full Flow Comum:** Novas features locais e telas que não alteram a fundação arquitetural.
   * `Marco define → Renan desenha → Rian / Iury implementa → Breno valida → Marco confere aceite`.
4. **Full Flow Sistêmica (Gate de Camillo):** Alterações de API, Worker Cloudflare, schema do SwiftData, motor central UDP ou segurança.
   * `Marco define → Camillo investiga e gera .agents/architecture-plan.md → Rian / Iury implementa → Breno valida → Camillo confere aderência → Marco confere aceite`.
5. **Hot Lane:** Falha impeditiva no TestFlight ou quebra de medição.
   * `Fix cirúrgico por Rian / Iury → Breno valida caminho crítico → Restauração de build`.

---

## 4. Integração dos Gates de Maturidade do LagCheck

Os gates já existentes no LagCheck (`docs/05` §7) continuam plenamente em vigor e são absorvidos pelas lanes:
* **Gate 7.1 (Antes de código de medição):** Coordenado por Iury e revisado por Camillo e Marco.
* **Gate 7.2 (Antes de tela entrar no app):** Coordenado por Renan e Rian.
* **Gate 7.3 (Antes de TestFlight):** Coordenado por Breno, Rian e Marco, com testes mandatórios em iPhone físico (iOS 17+).
* **Gate 7.4 (Antes do MVP1.1):** Exclusivo do dono do produto (Luiz) e Marco com base em métricas reais do App Store Connect.

---

## 5. Conclusão e Impacto

Com esta decisão:
* O LagCheck passa a ter uma governança 100% interoperável com o padrão Buildea;
* Elimina-se o risco de alterações de infraestrutura ou persistência sem plano arquitetural formal;
* A independência de validação é garantida por Breno e Renan antes de qualquer submissão ao TestFlight;
* A persona de Marco assegura que pedidos exploratórios permaneçam estritamente no campo analítico, mantendo o foco absoluto no MVP P0/P1 "Ready for Ranked".
