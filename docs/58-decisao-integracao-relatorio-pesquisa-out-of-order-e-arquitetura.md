# Decisão 58 — Incorporação do Relatório de Pesquisa de Rede: Detecção de Pacotes Fora de Ordem e Arquitetura de Servidores

- **Data:** 26 de setembro de 2026
- **Status:** Decidido e implementado
- **Papéis:** Marco (Produto e Integração), Iury (Qualidade de Rede e Integridade Diagnóstica), Rian (Arquitetura iOS/SwiftUI), Renan (Design e Voz do Produto), Dono do Produto (Diretrizes Estratégicas)
- **Consolida e detalha:** Decisões 09, 31, 32, 50, 51, 55, 56 e 57

---

## 1. Contexto e Racional

A leitura do relatório técnico profundo (`lagcheck-deep-research-report.md`) consolidou práticas consolidadas da indústria de medição e redes multiplayer. O relatório validou integralmente os pilares do LagCheck (integridade diagnóstica sem acusação leviana de Wi-Fi, avaliação de bufferbloat multidimensional, linguagem direta e esportiva "Ready for Ranked", e custo operacional recorrente zero).

Adicionalmente, a análise identificou oportunidades imediatas de evolução com alto impacto de precisão:
1. **Pacotes Fora de Ordem (*Out-of-Order Delivery* / RFC 4737):** Jogos online transmitem datagramas UDP sequenciais. Pacotes que chegam fora de sequência (inversão temporal) provocam atraso no motor de física/predição do cliente de jogo e micro-stutters/tiros ignorados, mesmo quando não há perda estrita de pacotes. Essa é uma evidência cabal de roteamento multipath/peering instável na operadora.
2. **Arquitetura de Servidores por Jogo (`GameServerArchitecture`):** Jogos com servidores dedicados centralizados (CS2, LoL) ou borda Anycast (Valorant via Riot Direct) operam com tolerâncias e lógicas distintas de jogos P2P ou híbridos (Minecraft, Roblox, EA Sports FC Mobile), especialmente quanto à relevância de NAT e CGNAT.
3. **Filtro de Escopo e Regras do LagCheck:** O relatório sugeria ferramentas invasivas (agentes companion no PC, raw sockets com ping ICMP ou VPN Network Extension no iOS). Essas alternativas foram formalmente rejeitadas para manter o onboarding sem atrito, a autonomia do app no iPhone e a disciplina de medição nativa via UDP.

---

## 2. Decisões Técnicas e de Produto

### 2.1 Detecção de Pacotes Fora de Ordem no `ProbeLedger` e `QualityEvaluator`
- **Rastreamento de Recepção:** O `ProbeLedger` em `NolaggyInfrastructure` agora registra atomicamente o `arrivalIndex` no momento do aceite de cada resposta UDP correlacionada válida (`accept(response:receivedAt:)`).
- **Métrica RFC 4737:** Em `QualityEvaluator`, quando amostras recebidas contêm ordem de chegada, calcula-se:
  - `outOfOrderCount`: Total de pacotes recebidos cuja sequência é estritamente menor do que a maior sequência já observada até aquele instante.
  - `outOfOrderRatePercentage`: Porcentagem de pacotes desordenados sobre o total de respostas válidas.
- **Transparência de Modelo:** `ProbeSample` compara igualdade semântica de `sequence`, `roundTripMilliseconds` e `outcome`, garantindo compatibilidade reversa com todos os testes existentes.

### 2.2 Modulação de Veredito e Achados honestos
- **Impacto no Veredito (`GameReadinessEvaluator`):**
  - Se `outOfOrderCount >= 2` ou `outOfOrderRatePercentage >= 5.0%`, a conexão é modulada para `▲ CONDIÇÕES INSTÁVEIS` (`.caution`), com a manchete explicativa localizada `game_readiness.verdict.caution.out_of_order` ("Detectamos pacotes fora de ordem na rota externa.").
- **Achado Honesto no Bloco "O Que Encontramos":**
  - Adicionado `NetworkFinding.Kind.outOfOrderPackets` com rótulo "Pacotes fora de ordem na rota" e badge contendo a contagem de pacotes afetados.
- **Causa e Diagnóstico (`ResultInterpreter`):**
  - Adicionado `ResultPrimaryCauseKey.outOfOrder` integrado à hierarquia de causas e explicações.

### 2.3 Recomendação Acionável no `EvidenceRecommendationEngine`
- Quando detectada desordem de pacotes ($\ge 2$) e o enlace do gateway local estiver estável (`.isStable`), o app emite a recomendação:
  - **Título:** "Instabilidade de Rota na Operadora"
  - **Instrução:** "Pacotes foram entregues fora de ordem pelo seu provedor (roteamento multipath instável), o que pode causar micro-travamentos."
  - **Badge:** "Rota Desordenada"

### 2.4 Mapeamento de Arquitetura de Servidores no `GameEditorialRegistry`
- O `GameEditorialRegistry` agora expõe o método oficial `serverArchitecture(for gameID: String) -> GameServerArchitecture`:
  - `minecraft`, `roblox`, `ea-sports-fc-mobile`: Classificados como `.hybrid` (suscetíveis a restrições de NAT / CGNAT).
  - Demais títulos competitivos (ex: `fortnite`, `valorant`, `call-of-duty-mobile`): Classificados como `.dedicatedServer` (onde NAT não interfere no pareamento principal).
- Integrado em `MeasurementHistoryEntry` ao persistir medições concluídas.

### 2.5 Localização Multi-idiomas Completa
- Novas chaves inseridas e validadas em `pt-BR`, `en` e `es`:
  - `quick_check.result.cause.out_of_order`
  - `quick_check.result.explanation.out_of_order`
  - `quick_check.result.insight.out_of_order`
  - `game_readiness.verdict.caution.out_of_order`
  - `game_readiness.finding.out_of_order_detected`

---

## 3. Matriz de Rastreabilidade e Evidência

| Componente | Mudança Implementada | Status |
|---|---|---|
| `NolaggyDomain/MeasurementModels` | `arrivalIndex` em `ProbeSample`, `outOfOrderCount` e `outOfOrderRatePercentage` em `QualityMetrics` | Validado por testes |
| `NolaggyDomain/QualityEvaluator` | Algoritmo RFC 4737 para cálculo determinístico de pacotes desordenados | Validado por testes |
| `NolaggyInfrastructure/NWConnectionMeasurementTransport` | Contador de chegada `receivedCount` e gravação no `ProbeLedger` | Validado por testes |
| `NolaggyDomain/GameReadinessDomain` | Modulação de veredito `.caution` e achado `.outOfOrderPackets` | Validado por testes |
| `NolaggyDomain/EvidenceRecommendationEngine` | Recomendação acionável de operadora/peering para desordem de pacotes | Validado por testes |
| `NolaggyDomain/GameEditorialRegistry` | Mapeamento oficial de arquitetura dedicada vs híbrida por jogo | Validado por testes |
| `NolaggyDomain/CheckCompletoResultDomain` | Suporte ao caso `.outOfOrder` no fluxo legado de resultado | Validado por testes |
| `NolaggyApp/Resources` | Localização completa em PT-BR, EN e ES | Validado |
| `Tests/NolaggyDomainTests` | Novos testes unitários cobrindo desordem de pacotes e arquiteturas de servidor | 62/62 testes passando |
