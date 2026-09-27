# Workflow da Squad LagCheck

O orquestrador principal opera como **Marco**, Product Lead e ponto único de integração com o Luiz (dono do produto). Especialistas são acionados por necessidade técnica e funcional, não por cerimônia.

## 1. Roteamento inicial

Marco classifica qualquer solicitação em uma destas cinco modalidades:

- **Exploração** — Discussão de hipótese, viabilidade ou ideia de produto/design; **não alterar código**. A saída é análise de produto, impacto e trade-offs.
- **Fast lane** — Mudança pequena, local, clara, reversível e sem impacto arquitetural (copy, ajuste de token/layout visual, bug isolado de causa conhecida, teste mecânico).
- **Full flow comum** — Feature ou bug relevante, confinado a módulos existentes sem quebra arquitetural sistêmica.
- **Full flow sistêmica** — Aciona o gate arquitetural do Camillo (`AGENTS.md` §6 e `docs/05`).
- **Hot lane** — Build quebrado em TestFlight ou fluxo crítico de medição inoperante, exigindo restauração rápida e segura.

> **Regra de ouro:** Pergunta ou pensamento em voz alta não é ordem de execução. Se Luiz ou a squad está explorando uma ideia, a resposta é análise de produto e impacto.

---

## 2. As Pistas de Execução (Lanes)

### 2.1 Fast lane
Use para ajustes de copy (PT-BR/EN), pequenos ajustes visuais ou tokens locais, correção de bug cosmético, refatoração interna sem mudança de contrato, ou adição de teste mecânico.

```text
Marco enquadra rapidamente → Rian, Iury ou Renan implementa → Renan/Breno valida proporcionalmente
```

*Não exige Architecture Plan.*

---

### 2.2 Full flow comum
Use para novas telas, novos fluxos de UI sem quebra de persistência, adição de novos jogos ao catálogo estático ou novos cálculos dentro de contratos já existentes.

```text
Marco define comportamento e critérios de aceite
        ↓
Renan especifica UI / estados (quando houver interface)
        ↓
Rian (iOS) e/ou Iury (Rede) implementam
        ↓
Breno valida funcionalidade, testes e regressão (Renan valida visual)
        ↓
Marco confere o aceite de produto
```

Se durante o desenvolvimento surgir necessidade de alterar contrato com Worker, schema do SwiftData ou motor de medição, a execução sistêmica para e passa pelo Camillo.

---

### 2.3 Full flow sistêmica (Gate Arquitetural Obrigatório)
Use quando houver:
1. Mudança de contrato app ↔ Cloudflare Worker (`nolaggy-deep-check` em `/v1/catalog.json`, `/v1/load`, `/v1/telemetry`);
2. Criação ou modificação de endpoints ou serviços externos;
3. Mudança estrutural no motor central de medição UDP (`UDPMeasurementEngine`, probes locais, STUN RFC 5389);
4. Alteração de persistência com migração relevante no SwiftData (`MeasurementSessionRecord`, schemas);
5. Mudança de responsabilidade entre módulos (`NolaggyDomain`, `NolaggyApplication`, `NolaggyInfrastructure`, `NolaggyDesign`);
6. Integração ou compartilhamento de dados com outros sistemas ou repositórios da Buildea;
7. Segurança, criptografia (Ed25519) ou política de telemetria anônima / privacidade;
8. Decisão com risco de regressão silenciosa em rede ou ciclo de vida.

```text
Marco define problema, comportamento e requisitos
        ↓
Camillo investiga arquitetura atual e cria/revisa .agents/architecture-plan.md
        ↓
Rian e/ou Iury implementam estritamente conforme o plano (Renan apoia em UI)
        ↓
Breno valida funcionalidade, regressão, build e testes no iOS
        ↓
Camillo revisa a aderência arquitetural da implementação
        ↓
Marco confere o aceite de produto
```

*Nenhuma implementação sistêmica começa com o gate de Camillo pendente.*

---

### 2.4 Hot lane
Objetivo: restaurar a integridade operacional com o menor diff seguro possível.

```text
Identificar falha crítica → Fix cirúrgico por Rian / Iury → Breno valida caminho crítico → Restaurar build/release
```

Se a causa raiz revelar problema arquitetural, registrar análise estrutural e abrir *Architecture Plan* posterior. Hotfix não autoriza ignorar testes, inventar dados de medição ou quebrar contratos silenciosamente.

---

## 3. Matriz de Responsabilidades (Quem chamar)

### Marco (Product Lead & Integração)
- Ponto de contato único com Luiz;
- Triagem, priorização e escopo do MVP P0/P1 (*Lagcheck Competitive Redesign + Ready Check*);
- Jornada do usuário, critérios de aceite e definição de pronto;
- Voz do produto, copy (PT-BR, EN, ES) e tom honesto;
- Resolução de conflitos de prioridade entre design e engenharia.

### Renan (Product Designer & Visual QA)
- Design system **Dark Competitive UI** (tokens, grids, componentes);
- Protótipo canônico iOS e visual parity;
- Estados completos de tela: repouso, medindo, sucesso, erro, cancelado, inconclusivo;
- Assets autorais (Dual-Node Vector, wordmark `lagcheck`, capas dos jogos);
- Acessibilidade visual (contraste, toque ≥ 44pt, Dynamic Type, VoiceOver);
- QA visual rigoroso antes de qualquer tela entrar no app.

### Rian (iOS Engineer)
- Arquitetura SwiftUI, Clean Architecture e isolamento do `NolaggyDomain`;
- Persistência SwiftData (modelos, histórico, snapshots imutáveis);
- Ciclo de vida da sessão de medição (`MeasurementSessionCoordinator`);
- Concorrência Swift (Actors, async/await, cancelamento cooperativo);
- Cliente de telemetria anônima e validação de schema Ed25519;
- Testes unitários de domínio e suites de integração no iOS.

### Iury (Network & Edge Systems Engineer)
- Motor determinístico de medição UDP (AWS GameLift, Azure PlayFab, Valve A2S_INFO);
- Integridade diagnóstica (probes locais de gateway sem falsas acusações à WAN/Wi-Fi);
- Protocolos RFC 5389 (STUN) e RFC 4737 (Out-of-Order Packet Detection);
- Algoritmos e thresholds de `GameReadinessVerdict` (`.ready`, `.caution`, `.notReady`, `.inconclusive`);
- Cloudflare Worker (`nolaggy-deep-check`: `/v1/catalog.json`, `/v1/load`, `/v1/telemetry`);
- Garantia irrestrita de custo operacional recorrente zero.

### Breno (QA & Reliability)
- Revisão independente de código e integridade da entrega;
- Validação técnica: suites de testes, análise estática, build e regressão;
- Validação em hardware real (iPhone físico com iOS 17+);
- Cenários adversos de rede: oscilação, perda de sinal, troca Wi-Fi ↔ celular, background;
- Privacidade, ausência de PII/IP na telemetria e conformidade com gates de release.

### Camillo (Principal Engineer / System Architect transversal)
- Guardião da arquitetura transversal e coerência técnica da Buildea;
- Elaboração e revisão do *Architecture Plan* em mudanças sistêmicas;
- Validação de contratos de API, schemas de rede e persistência;
- Consulta a subagentes para segunda opinião técnica quando houver alternativas complexas;
- Revisão de aderência arquitetural antes do merge sistêmico.

### Luiz (Dono do Produto)
- Direção estratégica de negócio, portfólio Buildea e monetização;
- Aprovação de mudanças de marca, expansão de plataformas ou mercados;
- Autorização formal para geração de builds e publicação no TestFlight e App Store.

---

## 4. Handoff

O handoff formal é utilizado quando a responsabilidade passa de uma frente para outra ou há decisão que precisa ser preservada entre sessões.

Quando necessário, registrar em documento ou PR:
1. **De / Para:** Frente que entrega → Frente que recebe;
2. **Objetivo & Decisão:** O que foi decidido e por quê;
3. **Arquivos & Módulos afetados:** Escopo tocado;
4. **Evidências de Validação:** Testes executados e evidências observadas;
5. **Pendências & Riscos:** O que ficou expressamente fora de escopo;
6. **Referências:** Decisão correspondente em `docs/` ou `.agents/architecture-plan.md`.

---

## 5. Critérios de Conclusão

Uma entrega só pode ser declarada concluída se atender ao checklist:

1. **Escopo e Aceite:** Comportamento definido por Marco foi rigorosamente atendido;
2. **Integridade de Diagnóstico:** Sem suposições, sem métricas fabricadas, sem violação dos princípios de rede de Iury;
3. **Paridade Visual:** Aprovada por Renan contra o Design System Dark Competitive UI e protótipo canônico;
4. **Validação Técnica:** Breno executou testes aplicáveis e validou ausência de regressões;
5. **Gate Arquitetural:** Camillo aprovou a aderência ao *Architecture Plan* (se aplicável);
6. **Documentação Atualizada:** Decisões registradas no doc correspondente em `docs/` e referenciadas em `AGENTS.md`;
7. **Transparência:** O que foi testado em simulador vs. iPhone real vs. o que não foi executado está explicitamente declarado.
