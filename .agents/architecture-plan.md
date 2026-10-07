# Architecture Plan — LagCheck Fase 2 (P1): Retenção, Causa Raiz & Widgets

> Documento mantido por **Camillo** (Principal Engineer / System Architect) e **Marco** (Product Lead) conforme Decisões 63 e 75, governança Buildea (`AGENTS.md` e `.agents/WORKFLOW.md`).

---

## 1. Contexto & Problema
A Fase 2 (P1) do LagCheck estabelece o diferencial técnico e a retenção de uso diário do produto antes de cada sessão competitiva:
1. **Item 4 — Ping Real por Datacenter & Rotas Ativas:** Validação dos probes e rotas ativas (AWS GameLift, Azure PlayFab, Valve A2S_INFO e status oficial Riot) com estrita integridade: rotulagem honesta quando em fallback regional neutro vs. servidor comunitário, respeitando termos de terceiros e sem promessas não comprovadas de IPs de matchmaking fechado.
2. **Item 5 — Isolador de Causa Raiz ("De Quem é a Culpa?"):** Estruturação do modelo de domínio e apresentação dos 3 probes determinísticos com segregação de culpa:
   - **Probe 1 (Local Gateway / Wi-Fi):** `BSDWiFiLocalGatewayProber` lendo IP real de rota BSD, RTT DNS real com Transaction ID. RTT > 15ms ou perda local = Gargalo no Wi-Fi/Sinal Local. Se firewall fechar porta 53, resultado é `unobservable` (Decisão 50: **proibido** culpar o Wi-Fi sem evidência).
   - **Probe 2 (Operadora / WAN):** Borda Anycast neutra Cloudflare/AWS. Se Gateway local está liso (<= 5ms, 0% perda) mas WAN tem jitter/perda/spikes = Instabilidade na Rota da Operadora.
   - **Probe 3 (Status de Plataforma):** `DirectPlatformHealthClient` consultando CDNs oficiais (PSN, Xbox Live, Nintendo, Riot) a custo zero.
3. **Item 6 — Widgets Interativos & Lock Screen (iOS 17+):** Exibição da telemetria de rota em widget sem dados estáticos/inventados:
   - Container compartilhado via App Group (`group.com.lagcheck.app`).
   - Snapshot imutável gravado ao término de cada medição real (`WidgetTelemetrySnapshot`).
   - Política estrita de Zero Mock: se o cache estiver vazio ou a última medição for mais antiga que 4 horas, o widget exibe estado semântico neutro (*"Sem check recente"* / *"Toque para medir"*).

---

## 2. Escopo Arquitetural e Limites dos Módulos

```
                                    ┌────────────────────────────────────────────────────────┐
                                    │                     NolaggyApp                         │
                                    │  - Home, Result, Seletor, TechnicalDetailsView        │
                                    │  - RootCauseSectionView (De Quem é a Culpa?)           │
                                    └───────────────┬────────────────────────┬───────────────┘
                                                    │                        │
                    ┌───────────────────────────────▼────────┐      ┌────────▼───────────────────────┐
                    │          LagCheckWidget (Novo)         │      │      NolaggyDesign Tokens      │
                    │  - Lock Screen Circular / Retangular   │      │  - Dark Competitive UI         │
                    │  - Home Screen Small                   │      │  - VerdictIndicatorBadge       │
                    │  - App Intent (RunQuickCheckIntent)    │      │  - Hairline borders, Roxo/Coral│
                    └───────────────┬────────────────────────┘      └────────────────────────────────┘
                                    │ (App Group UserDefaults)
                                    │ Reads WidgetTelemetrySnapshot
                                    │
┌───────────────────────────────────▼────────────────────────────────────────────────────────┐
│                                    NolaggyApplication                                      │
│  - MeasurementSessionCoordinator: orquestra a medição e grava snapshot compartilhado       │
│  - RootCauseCoordinator: orquestra os 3 probes independentes com timeout de 800ms          │
└───────────────────────────────────┬────────────────────────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────────────────────────┐
│                                      NolaggyDomain                                         │
│  - RootCauseIsolationReport: modelo puro imutável de evidências de causa raiz              │
│  - RootCauseEvaluator: lógica determinística de classificação (Local vs WAN vs Plataforma) │
│  - WidgetTelemetrySnapshot: modelo codable e autocontido para widgets                      │
│  - GameReadinessVerdict & QualityMetrics intactos                                          │
└───────────────────────────────────┬────────────────────────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────────────────────────┐
│                                  NolaggyInfrastructure                                     │
│  - BSDWiFiLocalGatewayProber (Probe 1: Gateway real + RTT DNS 53)                          │
│  - AnycastWANProber / StunProbeClient (Probe 2: Primeiro salto WAN Anycast)                │
│  - DirectPlatformHealthClient (Probe 3: CDN público oficial)                               │
│  - SharedAppGroupStore: gravação e leitura segura do snapshot com fail-safe                │
└────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Paridade Multiplataforma (Decisões 67 e 68)
No Android (`android/`):
- `:core:domain`: Implementa `RootCauseIsolationReport` e `RootCauseEvaluator` idênticos em Kotlin puro, com vetores de teste unitários equivalentes.
- `:core:telemetry-radio`: Alimenta o Probe 1 com rádio Wi-Fi (frequência MHz, RSSI dBm e LinkSpeed) além do gateway BSD.

---

## 3. Modelo de Domínio Puro (`NolaggyDomain`)

### 3.1 `RootCauseIsolationReport`
```swift
public enum CulpritEntity: String, Codable, Sendable {
    case localWiFi          // Wi-Fi / Rede Local do usuário
    case internetProvider   // Rota da Operadora / WAN
    case gamePlatform       // Servidores do Jogo / Plataforma
    case allClear           // Nenhum gargalo detectado (Tudo Verde)
    case unobservable       // Gateway não respondeu ou dados insuficientes
}

public struct RootCauseIsolationReport: Codable, Equatable, Sendable {
    public let primaryCulprit: CulpritEntity
    public let localGatewayRTTMs: Double?
    public let localGatewayPacketLoss: Double
    public let localGatewayObservable: Bool
    
    public let wanMedianRTTMs: Double?
    public let wanJitterMs: Double?
    public let wanPacketLoss: Double
    
    public let platformDegraded: Bool
    public let platformServiceName: String?
    
    public let evaluatedAt: Date
}
```

### 3.2 Regras Determinísticas (`RootCauseEvaluator`)
1. **Regra Wi-Fi:** Se `localGatewayObservable == true`, e (`localGatewayRTTMs > 15.0` OU `localGatewayPacketLoss > 2.0`) $\rightarrow$ `primaryCulprit = .localWiFi`.
2. **Regra Rota / Operadora:** Se o gateway local está comprovadamente pristino (`localGatewayRTTMs <= 5.0` e `localGatewayPacketLoss == 0`) OU `localGatewayObservable == false`, mas `wanPacketLoss > 1.0` OU `wanJitterMs > 15.0` $\rightarrow$ `primaryCulprit = .internetProvider`.
3. **Regra Plataforma:** Se os probes de rede estão limpos, mas a plataforma reporta manutenção/instabilidade $\rightarrow$ `primaryCulprit = .gamePlatform`.
4. **Regra Tudo Limpo:** Se o gateway local for pristino (`<= 5.0ms`), a WAN estiver estável e a plataforma operacional $\rightarrow$ `primaryCulprit = .allClear`.
5. **Regra Inconclusivo / Faixa Intermediária:** Se os dados forem ambíguos (ex: gateway na faixa intermediária de 5ms a 15ms com WAN instável, ou gateway unobservable sem WAN degradada), **NUNCA** atribui culpa precipitada $\rightarrow$ `primaryCulprit = .unobservable` (Decisão 50/75: integridade diagnóstica estrita).

---

## 4. Estratégia de Widgets & App Group (Item 6)

### 4.1 Identificadores e Entitlements
- **App Group Identifier:** `group.com.lagcheck.app`
- **Suite UserDefaults:** `UserDefaults(suiteName: "group.com.lagcheck.app")`
- **Target App:** Adiciona entitlement `com.apple.security.application-groups: [ "group.com.lagcheck.app" ]` em `project.yml`.
- **Target Widget:** `NolaggyWidget` (tipo `app-extension`) vinculado a `group.com.lagcheck.app`.

### 4.2 Modelo `WidgetTelemetrySnapshot`
```swift
public struct WidgetTelemetrySnapshot: Codable, Equatable, Sendable {
    public let gameID: String
    public let gameName: String
    public let regionLabel: String
    public let verdict: GameReadinessVerdict
    public let rttMedianMs: Double
    public let jitterMs: Double
    public let packetLossPercentage: Double
    public let bufferbloatGrade: String?
    public let capturedAt: Date
    
    public var isFresh: Bool {
        Date().timeIntervalSince(capturedAt) < 14400 // 4 horas
    }
}
```

### 4.3 Garantia de Zero Mock
- Se `WidgetTelemetrySnapshot` for nulo no container ou `isFresh == false`:
  - O widget exibe **Estado Semântico Neutro**:
    - Headline: *"SEM CHECK RECENTE"*
    - Indicador: Radar cinza/tracejado (Verdict `.inconclusive`)
    - Subtítulo: *"Abra o LagCheck para testar sua rota"*

---

## 5. Plano de Execução e Responsabilidades da Squad

| Frente | Ação | Responsável |
| :--- | :--- | :--- |
| **Arquitetura (Camillo)** | Validação do Gate Arquitetural, isolamento de módulos e custo zero. | Camillo |
| **Domínio (Iury & Rian)** | Implementação de `RootCauseIsolationReport` e `RootCauseEvaluator` em `NolaggyDomain` e `:core:domain` (Kotlin). | Iury / Rian |
| **Infraestrutura (Iury & Rian)** | Integração do gateway prober, WAN prober e platform health sob timeout rigoroso de 800ms; App Group storage. | Iury / Rian |
| **Design (Renan)** | Especificação dos layouts Lock Screen (circular/inline) e Home (small/medium) com Dark Competitive UI. | Renan |
| **iOS / Widget (Rian)** | Criação do target `NolaggyWidget` no `project.yml`, timeline provider e `RunQuickCheckIntent`. | Rian |
| **QA (Breno)** | Testes unitários puros no domínio Swift/Kotlin, testes de expiração de cache no widget e validação de ausência de mocks. | Breno |
| **Produto (Marco)** | Auditoria de voz ("O Gamer Não Lê"), copy PT-BR/EN/ES e aceite final com o Luiz. | Marco |

---

## 6. Critérios de Aceite & Conclusão
1. [x] Gate arquitetural aprovado e documentado;
2. [x] Zero novos custos recorrentes (sem Workers extras, sem SDKs de telemetria pagos);
3. [x] Proibição absoluta de acusar provedor ou Wi-Fi sem probe isolado comprovado;
4. [x] 100% de paridade lógica Swift (`NolaggyDomain`) e Kotlin (`:core:domain`);
5. [x] Widgets exibindo dados reais compartilhados ou estado neutro (sem valores fictícios hardcoded);
6. [x] Testes unitários passando no Xcode (`NolaggyUnitTests`) e Gradle (`:core:domain:test`).

