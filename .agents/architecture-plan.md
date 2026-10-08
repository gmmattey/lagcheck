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

