# Workflow da Squad LagCheck

**Giam** é o braço direito do Luiz (dono do produto) na porta de entrada: entende a dor, separa exploração de decisão, enquadra a missão no Cartão de Missão, escolhe a pista e repassa ao **Marco**. **Marco** é o capitão da oficina e orquestrador: mantém a mesa limpa, coordena prioridades e especialistas por pista, e devolve a entrega consolidada com evidência para o Giam encerrar com o veredito final. Especialistas são acionados por necessidade técnica e funcional, não por cerimônia.

Este arquivo é um mapa rápido de roteamento. A regra operacional canônica é
`docs/05-governanca-e-fluxo-de-trabalho.md`; decisões vigentes ficam em
`docs/DECISOES.md`. Antes de começar qualquer lane, Giam abre ou aprova o Cartão de
Missão em `.agents/templates/mission-card.md` e aciona o Marco. Sem dono, aceite e evidência
planejada, a demanda continua em exploração.

## 1. Roteamento inicial

Giam entende a necessidade com o Luiz e classifica a missão em uma destas cinco modalidades para o Marco conduzir:

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
Giam enquadra proporcionalmente → Rian, Iury ou Renan implementa → Renan/Breno valida → Giam encerra
```

*Não exige Architecture Plan.*

---

### 2.2 Full flow comum
Use para novas telas, novos fluxos de UI sem quebra de persistência, adição de novos jogos ao catálogo estático ou novos cálculos dentro de contratos já existentes.

```text
Giam define comportamento e critérios de aceite
        ↓
Renan especifica UI / estados (quando houver interface)
        ↓
Rian (mobile) e/ou Iury (Rede) implementam
        ↓
Breno valida funcionalidade, testes e regressão (Renan valida visual)
        ↓
Giam avalia necessidade, valor, coerência, experiência, funcionamento E2E,
qualidade e simplicidade com a evidência disponível
        ↓
Giam emite o veredito interno de produto
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
Giam define problema, comportamento e critérios de aceite
        ↓
Camillo investiga arquitetura atual e cria/revisa .agents/architecture-plan.md
        ↓
Rian e/ou Iury implementam estritamente conforme o plano (Renan apoia em UI)
        ↓
Breno valida funcionalidade, regressão, build e testes nas plataformas afetadas
        ↓
Camillo revisa a aderência arquitetural da implementação
        ↓
Giam avalia a entrega contra o Cartão de Missão e a evidência obrigatória
        ↓
Giam emite o veredito interno de produto
```

*Nenhuma implementação sistêmica começa com o gate de Camillo pendente.*

---

### 2.4 Hot lane
Objetivo: restaurar a integridade operacional com o menor diff seguro possível.

```text
Identificar falha crítica → Fix cirúrgico por Rian / Iury → Breno valida caminho crítico → Restaurar build/release → Giam revisa após estabilização
```

Se a causa raiz revelar problema arquitetural, registrar análise estrutural e abrir *Architecture Plan* posterior. Hotfix não autoriza ignorar testes, inventar dados de medição ou quebrar contratos silenciosamente.

---

## 3. Matriz de Responsabilidades (Quem chamar)

### Nico (App Growth & Store Creative Director; alias temporário: StoreGrowth)
- Coordena evidência de descoberta, ficha, criativos, conversão, ativação, retenção e receita;
- Roteia ASO, publicação Apple/Google, experimentos, reviews e analytics sem duplicar as skills especializadas;
- Pode pesquisar, auditar, capturar telas controladas, preparar criativos/metadados e validar arquivos locais;
- Não publica, altera preço/privacidade, responde publicamente, gasta ou cria integrações externas sem autorização explícita do Luiz;
- Integra a conclusão com Giam e Marco quando a proposta alterar promessa de produto, monetização, escopo ou priorização.

### Marco (Estratégia de Produto & Integração)
- Ponto de integração estratégica e de escalonamento de decisões de negócio ao Luiz; a porta de entrada operacional e o aceite de produto são do Giam;
- Triagem, priorização, trade-offs e escopo estratégico do MVP P0/P1 (*Lagcheck Competitive Redesign + Ready Check*);
- Escalonamento de decisões de negócio a Luiz e resolução de conflitos entre frentes;
- Voz do produto, copy (PT-BR, EN, ES) e tom honesto;
- Resolução de conflitos de prioridade entre design e engenharia.

### Renan (Product Designer & Visual QA — iOS e Android)
- Design system **Dark Competitive UI** (tokens, grids, componentes);
- Protótipo canônico iOS e adaptação Android nativa, com paridade de promessa;
- Estados completos de tela: repouso, medindo, sucesso, erro, cancelado, inconclusivo;
- Assets autorais (Dual-Node Vector, wordmark `lagcheck`, capas dos jogos);
- Acessibilidade visual (contraste, toque ≥ 44pt, Dynamic Type, VoiceOver);
- QA visual rigoroso antes de qualquer tela entrar no app.

### Rian (Mobile Application Engineer — iOS e Android)
- Arquitetura SwiftUI, Clean Architecture e isolamento do `NolaggyDomain`;
- Persistência SwiftData (modelos, histórico, snapshots imutáveis);
- Ciclo de vida da sessão de medição (`MeasurementSessionCoordinator`);
- Concorrência Swift (Actors, async/await, cancelamento cooperativo);
- Cliente de telemetria anônima e validação de schema Ed25519;
- Testes unitários de domínio e suites de integração no iOS.
- Composição Kotlin/Compose, ViewModels, ciclo de vida Android, permissões e
  persistência local sem reimplementar as regras de Iury.

### Iury (Network & Edge Systems Engineer)
- Motor determinístico de medição UDP (AWS GameLift, Azure PlayFab, Valve A2S_INFO);
- Integridade diagnóstica (probes locais de gateway sem falsas acusações à WAN/Wi-Fi);
- Protocolos RFC 5389 (STUN) e RFC 4737 (Out-of-Order Packet Detection);
- Algoritmos e thresholds de `GameReadinessVerdict` (`.ready`, `.caution`, `.notReady`, `.inconclusive`);
- Cloudflare Worker (`nolaggy-deep-check`: `/v1/catalog.json`, `/v1/load`, `/v1/telemetry`);
- Garantia irrestrita de custo operacional recorrente zero.
- Paridade determinística dos contratos e vetores de rede entre iOS e Android;
  fatos extras de rádio Android continuam opcionais e observados.

### Breno (QA & Reliability)
- Revisão independente de código e integridade da entrega;
- Validação técnica: suites de testes, análise estática, build e regressão;
- Validação em hardware real iOS e Android quando a mudança depender de rede,
  permissões, ciclo de vida, rádio ou compartilhamento;
- Cenários adversos de rede: oscilação, perda de sinal, troca Wi-Fi ↔ celular, background;
- Privacidade, ausência de PII/IP na telemetria e conformidade com gates de release.

### Camillo (Principal Engineer / System Architect transversal)
- Guardião da arquitetura transversal e coerência técnica da Buildea;
- Elaboração e revisão do *Architecture Plan* em mudanças sistêmicas;
- Validação de contratos de API, schemas de rede e persistência iOS/Android;
- Consulta a subagentes para segunda opinião técnica quando houver alternativas complexas;
- Revisão de aderência arquitetural antes do merge sistêmico.

### Giam (Product Owner Operacional & Quality Gatekeeper)
- Abre ou aprova o Cartão de Missão, define comportamento e critérios de aceite;
- Emite veredito sobre necessidade, valor, coerência, experiência,
  funcionamento E2E, qualidade e simplicidade;
- Consome evidência real de design, engenharia, rede, QA e arquitetura; não
  substitui nenhuma dessas frentes;
- Entra no começo e fim de todo full flow, mudança sistêmica e candidato a
  release; fast lane é proporcional e hot lane é revisada após estabilização.
  Veredito: aprovado, com ressalvas, reprovado ou não validado.

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

O formato obrigatório é o Cartão de Missão. O handoff não declara sucesso sem
separar o que foi inspecionado, testado, visto em simulador/emulador, validado
em aparelho e distribuído externamente.

---

## 5. Critérios de Conclusão

Uma entrega só pode ser declarada concluída se atender ao checklist:

1. **Escopo e Aceite:** Comportamento definido por Giam foi rigorosamente atendido;
2. **Integridade de Diagnóstico:** Sem suposições, sem métricas fabricadas, sem violação dos princípios de rede de Iury;
3. **Paridade Visual:** Aprovada por Renan contra o Design System Dark Competitive UI e protótipo canônico;
4. **Validação Técnica:** Breno executou testes aplicáveis e validou ausência de regressões;
5. **Gate Arquitetural:** Camillo aprovou a aderência ao *Architecture Plan* (se aplicável);
6. **Documentação Atualizada:** Decisões registradas no doc correspondente em `docs/` e referenciadas em `AGENTS.md`;
7. **Transparência:** O que foi testado em simulador vs. iPhone real vs. o que não foi executado está explicitamente declarado.
