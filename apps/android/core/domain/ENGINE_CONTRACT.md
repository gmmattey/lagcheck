# Contrato do motor LagCheck (`LagCheckEngine`)

Decisões 134 e 135. Única implementação das regras de score, veredito, causas, recomendações, carga, picos, watchdog e casos de uso, compartilhada por iOS (XCFramework `LagCheckEngine`), Android/desktop/Windows (JVM) e site (pacote JS `lagcheck-engine`). O estado da transferência de carga usa `load-transfer-v3`: distingue carga medida, tentativa insuficiente, falha sem bytes e etapa não iniciada.

O transporte (UDP, HTTP de carga, gateway, rádio, upload do site) é nativo de cada plataforma. O motor só recebe amostras e devolve a avaliação.

## API

| Chamada | Entrada | Saída |
| --- | --- | --- |
| `LagCheckEngine.evaluate(requestJson)` | JSON da requisição | JSON da avaliação, ou `{"error": "..."}` se a requisição for inválida |
| `LagCheckEngine.policy()` | — | plano de amostragem, versões de regra e guardrail de perda por perfil |
| `LagCheckEngine.gatewayOutcome(gatewayJson)` | telemetria do roteador `{rttMs, jitterMs, validResponses, plannedResponses, isWifi}` | `{kind: STABLE \| DEGRADED \| UNOBSERVABLE, rttMs, lossPercentage}` |
| `LagCheckEngine.rootCause(requestJson)` | `{gateway: {kind, rttMs, lossPercentage}, wanP50Ms, wanJitterMs, wanLossPercentage, platformDegraded, platformServiceName}` | `{culprit: localWiFi \| internetProvider \| gamePlatform \| allClear \| unobservable, ruleVersion}` (`root-cause-v2`: operadora só com roteador impecável) |
| `LagCheckEngine.bufferbloatGrade(increaseMilliseconds)` | aumento de P50 sob carga, em ms | `A+` a `F` (`bufferbloat-grade-v1`, descritiva) |
| `LagCheckEngine.stabilitySummary(requestJson)` | `{entries, windowDays, nowEpochMs, gameIdFilter?, networkFilter?, maxPoints?}` | série cronológica segmentada, contagens, faixa de ping e 4 anéis (`stability-summary-v2`, Decisão 143) |

- Swift: `LagCheckEngine.shared.evaluate(requestJson:)`. JS: `import { LagCheckEngine } from 'lagcheck-engine'`. JVM: `com.lagcheck.engine.LagCheckEngine`.
- Campos desconhecidos são ignorados; enums são as strings em MAIÚSCULAS abaixo.
- Nada de texto exibido sai do motor como frase: só chaves (`*Key`, `findings[].key`, `recommendations`, `useCases`). As tabelas de texto ficam em `presentation/` (pt, en, es).

## Requisição

| Campo | Tipo | Regra |
| --- | --- | --- |
| `source` | `APP_UDP` \| `WEB_HTTPS` | `WEB_HTTPS`: sem score, sem perda, sem fora de ordem e sem gateway; resultado é estimativa (Decisão 134 item 4). |
| `profile` | `BATTLE_ROYALE_COMPETITIVE` \| `MOBILE_REALTIME` \| `CASUAL_REALTIME` | Perfil de regra do jogo. |
| `rest` | lista de amostras | Fase de repouso, uma amostra por probe planejado (`sequence` 0..59). |
| `load` | lista de amostras, opcional | Fase sob carga. Só é usada com `loadTransfer = MEASURED`. |
| `loadTransfer` | `MEASURED` \| `INSUFFICIENT_TRANSFER` \| `FAILED_NO_BYTES` \| `NOT_RUN` | `MEASURED` exige lista de probes e, com menos de 20 respostas válidas, → `INCONCLUSIVE` (Decisão 135 item 3). `INSUFFICIENT_TRANSFER` registra uma tentativa com bytes abaixo do mínimo definido pelo transporte; `FAILED_NO_BYTES` registra falha sem byte; ambos preservam só o repouso e não derivam impacto sob carga. `NOT_RUN` significa que a etapa não foi iniciada. |
| `gateway` | `{rttMs, jitterMs, validResponses, plannedResponses, isWifi}`, opcional | Telemetria medida. Menos de 3 respostas válidas → não observável. |
| `gatewayOutcome` | `{kind, rttMs, lossPercentage}`, opcional | Estado já classificado por `gatewayOutcome()`; usado quando `gateway` não vem. O iOS guarda só o estado e manda este campo. |
| `nat` | `{type, origin: STUN_APP \| BROWSER_ESTIMATE}`, opcional | Só entra nos casos de uso quando conclusivo; `INCONCLUSIVE` não vira leitura favorável, achado ou recomendação. |
| `serverArchitecture` | `DEDICATED_SERVER` \| `PEER_TO_PEER` \| `HYBRID` | Controla a relevância de NAT. |
| `uploadMbps` | número, opcional | Medido nativamente (hoje só no site). Sem ele, streaming não considera upload. |
| `gameId`, `wifiBand` | opcionais | Reservados; ainda não influenciam a regra. |

Amostra: `{"sequence": Int, "outcome": "RECEIVED" | "TIMEOUT" | "TRANSPORT_ERROR" | "INVALID_RESPONSE", "rttMs": Double?, "arrivalIndex": Int?}`.

## Resposta

| Campo | Significado |
| --- | --- |
| `verdict` | `READY` \| `CAUTION` \| `NOT_READY` \| `INCONCLUSIVE` |
| `headlineKey`, `subtitleKey` | Chaves de texto do veredito. |
| `score` | Nota 0–100 acoplada ao veredito; `null` se inconclusivo ou `WEB_HTTPS`. |
| `isEstimate` | `true` para `WEB_HTTPS`. |
| `rest`, `load` | Métricas completas (P50/P95/P99, jitter, perda, spikes, padrão de picos, fora de ordem). |
| `loadImpact` | `tier` (`NONE`/`LIGHT`/`MATERIAL`/`SEVERE`), deltas e nota de bufferbloat descritiva. |
| `loadTransfer` | Estado factual da etapa de carga, sempre ecoado para a UI não apresentar uma conclusão sob carga quando ela não existe. |
| `spikePattern` | `NONE` \| `ISOLATED` \| `RECURRING` (`spike-pattern-v2`). |
| `primaryCause`, `secondaryCauses` | Causas na ordem de precedência da spec §7.4.1. |
| `findings` | Achados "O que encontramos" (`kind`, `severity`, `key`, `detail`). |
| `recommendations` | Chaves `RecommendationKey` (no máximo 3). |
| `useCases` | Resumo geral e status por caso (`fps`, `br`, `moba`, `fighting`, `casual`, `voice`, `streaming`, `cloud`, `nat`) — `use-cases-v1`, idêntico ao site. |
| `inconclusiveReason` | `INSUFFICIENT_UDP_RESPONSES` \| `POOR_SAMPLE_QUALITY` quando inconclusivo. |
| `ruleVersions` | Versão de cada regra usada (inclui `loadTransfer: load-transfer-v3`; gravar no histórico). |

## Exemplo real

Gerado por `EngineContractExampleTest`: 1 pacote perdido em 60 no repouso e +18 ms sob carga dão `CAUTION` com nota 74 por degradação sob carga.

Requisição:

```json
{
  "source": "APP_UDP",
  "profile": "BATTLE_ROYALE_COMPETITIVE",
  "rest": [
    {
      "sequence": 0,
      "outcome": "RECEIVED",
      "rttMs": 30.0
    },
    {
      "sequence": 1,
      "outcome": "RECEIVED",
      "rttMs": 31.0
    },
    "... (58 itens omitidos)"
  ],
  "load": [
    {
      "sequence": 0,
      "outcome": "RECEIVED",
      "rttMs": 48.0
    },
    {
      "sequence": 1,
      "outcome": "RECEIVED",
      "rttMs": 49.0
    },
    "... (58 itens omitidos)"
  ],
  "loadTransfer": "MEASURED",
  "gateway": {
    "rttMs": 3.0,
    "validResponses": 5,
    "plannedResponses": 5
  },
  "serverArchitecture": "DEDICATED_SERVER",
  "uploadMbps": 8.0
}
```

Resposta:

```json
{
  "verdict": "CAUTION",
  "headlineKey": "game_readiness.verdict.caution.headline",
  "subtitleKey": "game_readiness.verdict.caution.load",
  "score": 74,
  "isEstimate": false,
  "rest": {
    "validResponseCount": 59,
    "timeoutCount": 1,
    "invalidResponseCount": 0,
    "p50Milliseconds": 31.0,
    "p95Milliseconds": 32.0,
    "p99Milliseconds": 32.0,
    "jitterMilliseconds": 1.3275862068965518,
    "packetLossPercentage": 1.6666666666666667,
    "spikeCount": 0,
    "severeSpikeCount": 0,
    "spikeRatePercentage": 0.0,
    "p95ToP50Ratio": 1.032258064516129,
    "worstSpikeMilliseconds": 32.0,
    "outOfOrderCount": 0,
    "outOfOrderRatePercentage": 0.0,
    "spikePattern": "NONE"
  },
  "load": {
    "validResponseCount": 60,
    "timeoutCount": 0,
    "invalidResponseCount": 0,
    "p50Milliseconds": 49.0,
    "p95Milliseconds": 50.0,
    "p99Milliseconds": 50.0,
    "jitterMilliseconds": 1.3220338983050848,
    "packetLossPercentage": 0.0,
    "spikeCount": 0,
    "severeSpikeCount": 0,
    "spikeRatePercentage": 0.0,
    "p95ToP50Ratio": 1.0204081632653061,
    "worstSpikeMilliseconds": 50.0,
    "outOfOrderCount": 0,
    "outOfOrderRatePercentage": 0.0,
    "spikePattern": "NONE"
  },
  "loadTransfer": "MEASURED",
  "loadImpact": {
    "tier": "MATERIAL",
    "deltaP50Milliseconds": 18.0,
    "deltaJitterMilliseconds": 0.0,
    "deltaLossPercentage": 0.0,
    "deltaSpikesCount": 0,
    "bufferbloatGrade": "C"
  },
  "spikePattern": "NONE",
  "primaryCause": "LOAD_DEGRADATION",
  "secondaryCauses": [],
  "findings": [
    {
      "kind": "PACKET_LOSS",
      "severity": "NEGATIVE",
      "key": "game_readiness.finding.packet_loss_detected",
      "detail": "1.7%"
    },
    {
      "kind": "STABLE_ROUTE",
      "severity": "POSITIVE",
      "key": "game_readiness.finding.route_stable",
      "detail": null
    },
    {
      "kind": "LOAD_DEGRADATION",
      "severity": "WARNING",
      "key": "game_readiness.finding.load_degradation_detected",
      "detail": "+18 ms"
    },
    "... (1 itens omitidos)"
  ],
  "recommendations": [
    "AVOID_RANKED",
    "PAUSE_DOWNLOADS"
  ],
  "useCases": {
    "overallTone": "OK",
    "overallHeadlineKey": "use_case.overall.ok.headline",
    "overallSubtitleKey": "use_case.overall.ok.subtitle",
    "cases": [
      {
        "id": "fps",
        "status": "GOOD",
        "titleKey": "use_case.fps.title",
        "detailKey": "use_case.fps.good",
        "origin": null
      },
      {
        "id": "br",
        "status": "EXCELLENT",
        "titleKey": "use_case.br.title",
        "detailKey": "use_case.br.excellent",
        "origin": null
      },
      "... (6 itens omitidos)"
    ]
  },
  "inconclusiveReason": null,
  "ruleVersions": {
    "quality": "pilot-2026.11.14.1",
    "sampleQuality": "sample-quality-v2",
    "loadImpact": "deep-load-impact-v4",
    "loadTransfer": "load-transfer-v3",
    "recommendations": "recommendations-v2",
    "rootCause": "root-cause-v2",
    "spikePattern": "spike-pattern-v2",
    "readiness": "readiness-v3.0",
    "useCases": "use-cases-v1"
  }
}
```

`policy()`:

```json
{
  "plannedProbeCount": 60,
  "sendIntervalMillis": 500,
  "sendWindowMillis": 30000,
  "timeoutMillis": 2000,
  "closureMillis": 32000,
  "minimumValidResponses": 20,
  "ruleVersions": {
    "BATTLE_ROYALE_COMPETITIVE": {
      "quality": "pilot-2026.11.14.1",
      "sampleQuality": "sample-quality-v2",
      "loadImpact": "deep-load-impact-v4",
      "loadTransfer": "load-transfer-v3",
      "recommendations": "recommendations-v2",
      "rootCause": "root-cause-v2",
      "spikePattern": "spike-pattern-v2",
      "readiness": "readiness-v3.0",
      "useCases": "use-cases-v1"
    },
    "...": "um mapa por perfil"
  },
  "lossGuardrailPercentage": {
    "BATTLE_ROYALE_COMPETITIVE": 3.0,
    "MOBILE_REALTIME": 5.0,
    "CASUAL_REALTIME": 3.0
  }
}
```

## Garantias de paridade

- `EngineNormativeVectorsTest`: os vetores das Decisões 135 e 136 (verificando também as recomendações) passam pela API JSON em JVM, simulador iOS, Node e navegador.
- `EngineDiagnosticsFacadeTest`: roteador (3 de 5), causa raiz sem culpar sem evidência e nota de bufferbloat, nos três alvos.
- `SiteUseCaseParityTest`: 6.285 combinações (todos os limites exatos e +0,1) idênticas à função do site; validado por teste de mutação.
- Mudança de qualquer número exige nova versão de regra, vetores atualizados e revisão do Iury (AGENTS.md).
