# Architecture Plan — LagCheck Decisão 78: Ativação de Probes Reais Homologados (Steam A2S & PlayFab QoS), Expansão Multirregional e Transparência de Precisão (Catálogo v4)

> Documento mantido por **Camillo** (Principal Engineer / System Architect), **Iury** (Network & Edge Systems Engineer) e **Marco** (Product Lead) conforme Decisões 63, 77 e 78, governança Buildea (`AGENTS.md` e `.agents/WORKFLOW.md`).

---

## 1. Contexto & Problema
Até o Catálogo v3, 100% dos jogos do catálogo dependiam da rota `awsFallback` (`gamelift-ping.sa-east-1.api.aws:7770`), mantendo as rotas dedicadas (`dedicatedServer`) com `status: "pending"`.
Embora os clientes iOS e Android já possuam os codecs para `SteamQueryA2SPayloadCodec` e `PlayFabQoSPayloadCodec`, a ausência de endpoints reais assinados impedia que o aplicativo executasse testes de ping direto aos jogos.
Além disso, a existência de uma única região (`sa-east-1`) gerava distorções para partidas em clusters internacionais.
O dono do produto (Luiz) aprovou a **Decisão 78**:
1. Homologação empírica de servidores de jogo diretos (Steam A2S e PlayFab QoS);
2. Expansão multirregional de infraestrutura gamer (regiões candidatas em bancada);
3. Sinalização visual da natureza da rota no RouteTrailSummaryCard (`Servidor de Jogo` vs `Referência Regional`), sem badges artificiais;
4. Incremento progressivo do catálogo com garantia de integridade diagnóstica.

---

## 2. Topologia de Rede & Candidatos para Homologação (Iury)

```
                       ┌─────────────────────────────────────────────────────────┐
                       │                     LagCheck Client                     │
                       │               (iOS 17+ / Android API 26+)               │
                       └────────────────────────────┬────────────────────────────┘
                                                    │
                 ┌──────────────────────────────────┼──────────────────────────────────┐
                 │                                  │                                  │
                 ▼                                  ▼                                  ▼
   ┌───────────────────────────┐      ┌───────────────────────────┐      ┌───────────────────────────┐
   │       Steam A2S UDP       │      │      PlayFab QoS UDP      │      │     AWS GameLift UDP      │
   │  (Candidato Rota Direta)  │      │  (Candidato Rota Direta)  │      │   (Infra de Referência)   │
   ├───────────────────────────┤      ├───────────────────────────┤      ├───────────────────────────┤
   │ Protocolo: Valve A2S_INFO │      │ Protocolo: PlayFab QoS    │      │ Protocolo: GameLift Ping  │
   │ Payload: 25 bytes / 0x54  │      │ Payload: QoS Header/Echo  │      │ Payload: Echo Ping        │
   │ Desafio: Handshake 0x41   │      │ Resposta: Latência/Qual   │      │ Resposta: Timestamp RTT   │
   │ Alvos: CS2, Dota 2, Rust  │      │ Alvos: Palworld           │      │ Referência Cloud Regional │
   │ Status: Bancada de Teste  │      │ Status: Bancada de Teste  │      │ Status: Em Produção       │
   └───────────────────────────┘      └───────────────────────────┘      └───────────────────────────┘
```

### 2.1 Especificação dos Endpoints por Protocolo

1. **Valve Steam A2S Query (`steamA2S`):**
   - **Porta padrão:** 27015 / portas de query dedicadas.
   - **Mecanismo:** Request inicial `A2S_INFO` (25 bytes), recebimento de `A2S_SERVERQUERY_GETCHALLENGE` (0x41), e segundo disparo com challenge token acoplado.
   - **Candidatos em bancada de teste (Iury):**
     - Relays e servidores públicos da Valve em São Paulo e nos EUA.
     - Critério inegociável: só avançam para `status: "active"` após captura de tráfego UDP em arquivo PCAP demonstrando resposta `A2S_INFO` válida com o desafio `0x41` tratado. Enquanto não capturado, permanecem `status: "pending"`.
   - **Títulos candidatos:** `cs2`, `dota2`, `rust`.

2. **Microsoft Azure PlayFab QoS (`playFabQoS`) — Bancada Exploratória:**
   - **Status:** Confinado à bancada de pesquisa de Iury. Não entra em envelopes de produção sob o `schemaVersion: 3`, pois o verificador roteado em produção em ambos os clientes restringe as regiões a `gameLiftPing:7770` e o cliente Android não implementa validador de destino PlayFab no pipeline roteado.
   - **Próximos passos técnicos:** Qualquer ativação de PlayFab exigirá gate arquitetural formal com atualização sincronizada dos dois verificadores (`RemoteCatalog.swift` e `RemoteCatalogVerifier.kt`), nova versão de schema e suíte de testes.

3. **AWS GameLift Beacons (`gameLiftPing`):**
   - **Função de produto:** Infraestrutura regional de referência neutra para estimar o caminho de trânsito até os principais datacenters de nuvem pública. Não se declara como servidor dedicado de nenhum jogo específico, preservando a integridade diagnóstica inegociável.
   - **Destinos multirregionais:**
     - São Paulo: `gamelift-ping.sa-east-1.api.aws:7770` (ativo em produção)
     - Regiões candidatas em homologação de latência (Iury):
       - Virgínia do Norte: `gamelift-ping.us-east-1.api.aws:7770`
       - Oregon: `gamelift-ping.us-west-2.api.aws:7770`
       - Frankfurt: `gamelift-ping.eu-central-1.api.aws:7770`

---

## 3. Schema & Envelope do Catálogo (Compatibilidade com Clientes)

### 3.1 Modelo de Dados (Compatível com Schema 3)
Para manter paridade e compatibilidade com os clientes em produção (iOS 17+ via `RemoteCatalog.swift` e Android API 26+ via `RemoteCatalogVerifier.kt`), o catálogo **mantém `schemaVersion: 3`**, evoluindo apenas o `catalogVersion`. 

*(Exemplo conceitual ilustrativo; a compilação do catálogo de produção inclui todas as regiões, rotas com bloco de candidatos e assinatura Ed25519 pelo Worker):*

```json
{
  "schemaVersion": 3,
  "catalogVersion": "catalog-v3-2026.10.08.1",
  "assetBaseURL": "https://nolaggy-deep-check.buildealabs.workers.dev/",
  "profiles": [
    { "id": "BATTLE_ROYALE_COMPETITIVE", "ruleVersion": "pilot-2026.09.08.1" },
    { "id": "MOBILE_REALTIME", "ruleVersion": "mobile-realtime-2026.09.08.1" },
    { "id": "CASUAL_REALTIME", "ruleVersion": "casual-realtime-2026.09.08.1" }
  ],
  "regions": [
    { "id": "sa-east-1", "label": { "pt-BR": "São Paulo", "en": "São Paulo", "es": "São Paulo" }, "probe": { "host": "gamelift-ping.sa-east-1.api.aws", "port": 7770, "protocolKind": "gameLiftPing" } }
  ]
}
```

### 3.2 Transição de Rotas (Ativação)
Em cada jogo no Catálogo:
- Para títulos Steam (`steamA2S`) com servidor oficial validado empiricamente em bancada com evidência PCAP:
  - Rota dedicada: `status: "active"`, `strategy: "dedicatedServer"`, `confidence: "high"`, `precisionKey: "dedicatedServer"`, `destination: nil`;
  - Formato estrito exigido pelos verificadores iOS (`RemoteCatalog.swift:1160-1175`) e Android (`RemoteCatalogVerifier.kt:271-290`): bloco `selection` com `mode: "automaticValidatedCandidates"`, `maxCandidates: 3`, contendo de 1 a 3 itens em `candidates`, onde cada candidato contém:
    - `id`: identificador único do candidato;
    - `priority`: prioridade numérica de seleção (ex: 0);
    - `destination`: objeto contendo `{ "host": "...", "port": 27015, "protocolKind": "steamA2S" }`;
    - `regionID`: região correspondente (ex: `"sa-east-1"`);
    - `identity`: `{ "expectedAppID": 730, "expectedGameDirectory": "csgo" }` (diretório estritamente em minúsculas);
    - `operatorEvidenceURL`: URL pública HTTPS comprovando a legitimidade do endpoint.
  - Rota de fallback: `status: "active"`, `strategy: "genericRegion"`, `confidence: "medium"`, `precisionKey: "regionalReference"`.
- Enquanto não houver validação empírica comprovada de cada host candidato:
  - Rotas dedicadas permanecem: `status: "pending"`.
  - Rota de fallback regional da AWS permanece ativa, comunicada no atestado de rota como Referência Regional.

---

## 4. Apresentação & Transparência Visual (Renan / Marco)

A transparência de rota segue a regra do **"Gamer Não Lê"** e a integridade de medição:
- Sem badges artificiais ou emojis na interface;
- A sinalização é centralizada no **`RouteTrailSummaryCard`** ("Atestado da Rota"), utilizando exclusivamente tokens do **Dark Competitive UI** (`NLColor`, `NLTypography`);
- A indicação de `Servidor de Jogo` (rota dedicada) vs `Referência Regional` (datacenter da nuvem) é derivada da **rota que de fato respondeu com sucesso**, nunca de intenção do catálogo.

---

## 5. Paridade de Plataforma (iOS & Android)

- Toda alteração nas regras de decodificação de catálogo, probes ou veredicto deve manter paridade estrita entre iOS (Swift) e Android (Kotlin/Compose), conforme Decisões 67 e 68.
- Nenhuma chave nova de schema entra sem validação correspondente no `RemoteCatalogVerifier.kt`.

---

## 6. Histórico e Planos Anteriores

- O plano de arquitetura da **Fase 3 (Decisão 76 — Ecossistema & Fricção Zero: In-App Events, Spotlight Search, App Clip)** está preservado e arquivado para rastreabilidade em:
  `docs/archive/architecture-plans/architecture-plan-fase3-decisao76.md`.

---

## 7. Plano de Execução da Squad

| Agente | Responsabilidade |
| :--- | :--- |
| **Camillo** | Gate arquitetural, preservação de `schemaVersion: 3`, assinatura Ed25519 e custo zero no Worker. |
| **Iury** | Bancada de teste, captura UDP e validação empírica de pacotes para Steam A2S e PlayFab QoS. |
| **Rian** | Adaptação e testes da decodificação no `NolaggyDomain`, `NolaggyInfrastructure` e paridade no Kotlin/Compose (`RemoteCatalogVerifier.kt`). |
| **Renan (Design)** | Atestado de rota no Cockpit sem ruído visual ("Gamer Não Lê") e compatível com Dynamic Type. |
| **Breno (QA)** | Testes de integração de rede, suite `NolaggyUnitTests` completa e validação de regressão. |
| **Marco (Produto)** | Aceite de produto, validação de integridade diagnóstica e alinhamento com Luiz. |

---

## 8. Critérios de Aceite & Conclusão
1. [x] Decisão 78 devidamente aprovada por Luiz e registrada em `docs/DECISOES.md`;
2. [x] `.agents/architecture-plan.md` elaborado por Camillo e Marco (homologação de bancada sob Iury), com histórico da Fase 3 arquivado;
3. [ ] Hosts candidatos de Steam A2S e PlayFab QoS testados com captura de pacotes UDP reais e homologados por Iury;
4. [ ] Script do catálogo gerando envelope assinado compatível com `schemaVersion: 3`;
5. [ ] Paridade de decodificação e testes confirmados em iOS e Android;
6. [ ] Todos os testes unitários passando 100% verdes (`xcodebuild test`).

---

## 9. Gate — Issue #50: Ritual honesto do Histórico

### Parecer de Camillo

**can proceed with listed constraints**

O trabalho é sistêmico porque corrige a retenção persistida no Android e acrescenta fatos de comparabilidade ao snapshot local. Não muda score, veredito, transporte UDP, catálogo, Worker, telemetria, privacidade ou custo.

| Área | Contrato obrigatório |
| --- | --- |
| Semântica compartilhada | Janela de 7/14/30 dias; mínimo de 3 resultados válidos em 2 dias; mesma chave de contexto (jogo, plataforma, vínculo externo, rede observada, região e versão de regra); inconclusivos contados à parte. |
| iOS | Nova regra pura de resumo no domínio; SwiftData mantém retenção atual de 90 dias/100 por jogo; `MeasurementHistorySummary` legado sem consumidor é removido depois de a nova regra estar coberta por testes. |
| Android | `CheckHistoryItem` ganha versão, região e rede observada; JSON aceita ausência desses campos em snapshots existentes, que permanecem visíveis mas inelegíveis ao resumo; limpeza aplica 90 dias e 100 por jogo antes de salvar/carregar. |
| UI | Cada cliente somente apresenta o resultado do contrato puro. Sem média de score, melhor horário, previsão, causa ou recomputação de veredito. |
| Inconclusivo final | Uma sessão que chega ao fim por menos de 10 respostas UDP vira snapshot sem score e sem causa, contado separadamente. Cancelamento, troca de rede e parcial são descartados antes da persistência. |
| Rollback | A remoção da UI não destrói registros. Os novos campos são opcionais na leitura de snapshots anteriores; não há migração de servidor. |

**Riscos e provas obrigatórias:** vetores de inclusão/exclusão e retenção nos dois clientes; casos com legado, inconclusivo, contexto divergente e apagamento; inspeção de localização. Simulador/emulador valida somente composição e foco; hardware continua necessário para VoiceOver/TalkBack e escala real.

## 10. Gate — Issue #49: Widget de prontidão por jogo iOS e Android

### Parecer de Camillo

**can proceed with listed constraints**

O recorte é sistêmico porque acrescenta uma superfície Android, um contrato de snapshot local derivado para cada plataforma, miniatura compartilhada com extensão/widget e retomada que pode iniciar medição. Não altera o algoritmo, score, veredito, catálogo remoto, Worker, telemetria, PII ou custo recorrente.

| Área | Contrato obrigatório |
| --- | --- |
| Fonte de arte | Cada cliente usa exclusivamente seu catálogo assinado válido e cache/resource editorial autorizado. O widget jamais consome arte, arquivo, URL ou captura produzida pelo outro cliente. |
| Snapshot | É derivado e substituível, escrito só ao final de Check válido. Inclui `gameID`, plataforma, vínculo externo, região, métricas observadas, veredito, instante e a referência local da miniatura. Não substitui histórico nem entra em telemetria. |
| iOS | A extensão lê snapshot e miniatura já materializados no App Group; não baixa arte. O URL é `lagcheck://check?game={id}` e o app revalida contexto antes de iniciar. |
| Android | O `AppWidgetProvider` em `:app` lê snapshot privado e resource editorial da própria build; não baixa arte. O `Intent` entrega o `gameID` para `MainActivity`, que resolve o contexto e dispara o fluxo normal. |
| Expiração e falhas | Após quatro horas, inconclusivo, arte incompatível, catálogo inválido ou jogo removido, o widget não mostra P50/veredito como atual. Mostra CTA contextual somente quando o jogo ainda for resolúvel; caso contrário, identidade neutra. |
| Concorrência e segurança | Não há medição/fetch em background. Toque explícito é a intenção do Check. Sessão já ativa, mudança de rede, contexto incompatível ou catálogo inválido preservam os guardrails existentes e mostram recuperação, nunca uma segunda sessão. |
| Rollback | A remoção do widget/snapshot não afeta histórico, catálogo ou resultado. O snapshot pode ser apagado localmente; não existe migração/servidor. |

**Riscos e provas obrigatórias:** teste de serialização, expiração, invalidação de arte e deep link por plataforma; render em tamanhos suportados; app frio/segundo plano; offline; troca de catálogo; Dynamic Type/VoiceOver no iOS e font scale/TalkBack/redimensionamento no Android; aparelhos físicos em ambas as plataformas. Uma captura ou build de uma plataforma não aprova a outra.

---

## 11. Gate — Decisão 95: traço final do Deep Check para Detalhes iOS

### Parecer de Camillo

**can proceed with listed constraints**

O gráfico solicitado pela referência Android precisa de fatos por fase depois de a
medição terminar. Hoje o `DeepCheckSessionCoordinator` oferece amostras apenas
durante o progresso e as limpa ao concluir; `DeepCheckResult` guarda somente
métricas agregadas. A menor mudança segura é um contrato efêmero dentro de
`NolaggyApplication`, sem alterar `NolaggyDomain`, transporte UDP, persistência,
Worker, telemetria, Android, score ou veredito.

| Área | Contrato obrigatório |
| --- | --- |
| Novo dado transitório | `FinalDeepCheckTrace` pertence a `NolaggyApplication` e contém `sessionID`, `restSamples` e `loadSamples` originais, em coleções separadas. Não é `Codable`, não entra em `MeasurementHistoryEntry`, SwiftData, analytics, exportação, widget ou share card. |
| Elegibilidade | O coordenador cria o traço somente ao terminar em `.completed(result)`, com `LoadTransferOutcome.completed`, `result.metrics.loadImpact != nil` e ao menos 10 respostas UDP válidas em **cada** fase. Resultado inconclusivo, carga indisponível, carga sem métricas, timeout/cancelamento, troca de rede, background e watchdog não expõem traço. |
| Acesso | O traço só pode ser lido para o mesmo `sessionID` enquanto `DeepCheckSessionState` é `.completed`. Ele deve viajar no snapshot concluído ou por getter guardado por esse estado; nunca por um cache global, callback de progresso ou novo estado público parcial. `start` e `cancel` o limpam antes de qualquer nova sessão. |
| Integridade da série | A UI usa as amostras originais por fase. Timeout, resposta inválida e erro de transporte formam lacunas; não podem ser interpolados, substituídos por percentil ou unidos à fase vizinha. O divisor entre repouso e carga é explícito. Como `ProbeSample` não registra timestamp, o eixo X representa a ordem/`sequence` dos probes, não duração absoluta. |
| Resultado e detalhes | `DeepCheckFeatureView` captura uma única avaliação ao receber o estado concluído e passa o mesmo snapshot ao Resultado e aos Detalhes. `TechnicalDetailsView` recebe o traço somente junto a esse resultado. Se o traço não estiver elegível, mostra a ausência de forma honesta e não desenha curva sintética. |
| Domínio e plataformas | `ProbeSample`, `DeepCheckEvaluator`, `GameReadinessEvaluator`, versões de regra e vetores permanecem inalterados. Android não recebe obrigação de persistir ou mudar seu contrato por esta entrega iOS. |
| Privacidade, custo e rollback | O traço fica somente na memória do processo enquanto o resultado está aberto; não amplia coleta, rede, serviços ou custo. Remover o consumidor da UI e a retenção efêmera restaura o comportamento anterior sem migração e sem dados residuais. |

### Provas obrigatórias

1. Teste de aplicação: sessão elegível devolve duas séries originais; a primeira
   tentativa de nova sessão, cancelamento, troca de rede e background removem o
   traço.
2. Vetores: timeout e resposta inválida viram lacuna; carga indisponível e menos
   de 10 respostas válidas em qualquer fase não entregam gráfico.
3. Teste de integração de apresentação: Resultado e Detalhes recebem a mesma
   `GameReadinessEvaluation`; abrir Detalhes não reavalia score, veredito ou
   causa.
4. Validação iOS em simulador e iPhone: divisor de fases, retorno ao Resultado,
   Dynamic Type, VoiceOver e cancelamento durante Check. A prova física continua
   obrigatória para ciclo de vida e rede.

