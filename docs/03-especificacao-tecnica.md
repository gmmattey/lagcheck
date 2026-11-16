# LagCheck — especificação técnica do MVP

**Status:** especificação técnica atualizada (Decisões 106, 120, 123, 134–136, 143–145)
**Aplicativo:** iPhone (iOS 17+), Android (API 26+) sobre motor KMP único (`LagCheckEngine`)
**Documentos relacionados:** [Funcional](./01-funcional.md) · [Arquitetura](./02-arquitetura.md) · [Contrato KMP](../apps/android/core/domain/ENGINE_CONTRACT.md)

## 1. Escopo técnico fechado

| Área | Decisão |
| --- | --- |
| Apps & Motor | iOS (`apps/ios/`, SwiftUI) e Android (`apps/android/`, Kotlin/Compose) consumindo o motor único Kotlin Multiplatform (`apps/android/core/domain`, `LagCheckEngine`, Decisão 134). |
| Medição | UDP direto do dispositivo para infraestrutura de referência (AWS GameLift, Azure PlayFab, Valve A2S) + mapa equiretangular nativo com `/v1/approx-location` (Decisão 123). |
| Check (Deep Check) | Wi-Fi e rede móvel (com consentimento); 60 probes (~30 s) em repouso + 60 probes (~30 s) sob carga (~64 s no total; mínimo 20 respostas válidas por fase, Decisão 135); carga contínua até 60 MB no Wi-Fi e 10 MB na rede móvel via `GET /v1/load`. Chamado simplesmente de **Check** na interface. |
| Veredito Principal | `GameReadinessVerdict` (`READY`, `CAUTION`, `NOT_READY`, `INCONCLUSIVE`, regra `readiness-v3.0`). Protagonista visual imediato. |
| Score | Local, determinístico (`0–100`), acoplado aos guardrails do veredito (mantido para detalhes, histórico e telemetria). |
| Catálogo & Telemetria | Catálogo base embutido sem assinatura com 54 jogos e refresh opcional via `catalog-v3.json` (Decisão 106); Cloudflare Worker gratuito somente para `/v1/load` e `/v1/telemetry`. |
| Histórico & Estabilidade | Persistência local (SwiftData no iOS / DataStore no Android); 90 dias e máximo de 100 medições por jogo; evolução da estabilidade via `LagCheckEngine.stabilitySummary` (`stability-summary-v1`, Decisão 143). |
| Publicidade | AdMob Native Advanced em faixa horizontal compacta (sem contorno) e UMP em `Início`, `Jogos`, `Histórico` e `Resultado` válido (Decisões 82, 96, 97 e 144). |
| Privacidade | Telemetria mínima anônima via Worker sem PII/IP e analytics de funil com exclusão local (Decisões 108 e 109). |
| Idiomas | PT-BR, inglês e espanhol. |

Android é alvo oficial (Decisões 67–69) e o protótipo interno Windows WinUI 3 (`apps/windows/`) consome o mesmo `LagCheckEngine` via `engine-host` (`apps/android/engine-host/`). Ficam fora de escopo: conta obrigatória, sincronização em nuvem, VPN/otimização de rota, fallback HTTP/ICMP para UDP e assistentes de IA no fluxo principal.

## 2. Organização do código iOS (`apps/ios/`)

```text
apps/ios/
├── Sources/
│   ├── NolaggyApp/         composição, ciclo de vida, AdMob/UMP e Features (Home, Games, Measurement, Result, Details, History, Settings)
│   ├── NolaggyDesign/      tokens Dark Competitive UI, fontes, RouteMap e componentes SwiftUI
│   ├── NolaggyDomain/      fachada fina sobre o XCFramework KMP LagCheckEngine + modelos Swift
│   └── NolaggyInfrastructure/ UDP, caminho de rede, gateway, carga HTTP, catálogo, telemetria e SwiftData
└── Tests/                  unitários, contrato KMP, integração e UI
```

`Domain` não importa SwiftUI, SwiftData, Network ou URLSession. `Infrastructure` implementa protocolos consumidos por `Domain` e `Features`. `App` monta as dependências em produção e as substitui por fakes nos testes.

## 3. Modelos principais

Os nomes abaixo descrevem contratos Swift; a implementação pode ser `struct`, `enum` e `protocol` equivalentes.

```swift
enum Platform: String, Codable { case iphone, playstation, xbox, pc, nintendo }
enum NetworkKind: String, Codable { case wifi, cellular, other }
enum MeasurementKind: String, Codable { case check } // Nomenclatura unificada
enum MeasurementConfidence: String, Codable { case veryHigh, high, mediumHigh, medium }
enum MeasurementStrategy: String, Codable { case gameOfficial, gameInfrastructure, regionGameProxy, genericRegion }

/// Camada semântica de prontidão competitiva (Decisão 50)
enum GameReadinessVerdict: String, Codable {
    case ready          // Pronto para jogar (condições compatíveis com gameplay competitivo)
    case caution        // Condições instáveis / Atenção (jitter, spikes ou impacto sob carga)
    case notReady       // Evitaria Ranked agora (perda de pacotes, latência alta ou instabilidade severa)
    case inconclusive   // Inconclusivo (menos de 20 respostas UDP válidas por fase, Decisão 135)
}

enum ResultClass: String, Codable { case excellent, great, unstable, lagRisk, inconclusive, cancelled }
enum SessionPhase: String { case idle, resolving, measuringIdle, measuringLoad, evaluating, completed, cancelled, inconclusive, failed }

/// Resultado isolado de probe no gateway local (Decisão 55)
enum GatewayProbeOutcome: Codable, Hashable {
    case stable(rttMilliseconds: Double)
    case degraded(rttMilliseconds: Double, lossPercentage: Double)
    case unobservable // Gateway não responde a probes UDP locais
}

/// Nível de confiança na detecção da banda Wi-Fi (Decisão 55)
enum WiFiBandConfidence: String, Codable {
    case high, medium, low, unknown
}

/// Classificação temporal de picos de latência (Decisão 55)
enum SpikePattern: Codable, Hashable {
    case none
    case isolated(count: Int)
    case recurring(count: Int, severeCount: Int)
}

/// Gradação multidimensional de impacto sob carga (Decisão 55)
enum LoadDegradationTier: String, Codable {
    case none       // Delta irrelevante ou inexistente
    case light      // Leve (descritivo)
    case material   // Material (prejudicial ao competitivo)
    case severe     // Severo (inviabiliza partidas ranqueadas)
}

/// Ação recomendada baseada em evidência (Decisão 55)
struct ActionableRecommendation: Codable, Hashable, Identifiable {
    var id: String { title }
    let priority: Int // 1 a 3
    let title: String
    let instruction: String
    let evidenceBadge: String
}

struct GameContext: Codable, Hashable {
    let gameID: String
    let market: String       // "BR" ou "US"
    let platform: Platform
    let equipmentConnection: NetworkKind? // somente console/PC quando declarado
    let serverArchitecture: ServerArchitecture? // dedicatedServer vs peerToPeer
}

enum ServerArchitecture: String, Codable {
    case dedicatedServer, peerToPeer, hybrid
}

struct ProbeSample: Codable, Hashable {
    let sequence: Int
    let sentAt: Date
    let receivedAt: Date?
    let roundTripMilliseconds: Double?
    let outcome: ProbeOutcome
}

enum ProbeOutcome: String, Codable { case received, timeout, transportError, invalidResponse }
```

`ProbeSample` é temporário durante uma sessão. O histórico persiste métricas agregadas e contexto; amostras brutas só são mantidas localmente enquanto forem necessárias para a tela de detalhes da medição atual.

## 4. Catálogo local assinado

### 4.1 Rotas do Worker

| Rota | Método | Uso | Cache |
| --- | --- | --- | --- |
| `/v1/load` | `GET` | Carga HTTP do Check (Wi-Fi e celular com consentimento). | `Cache-Control: no-store`; até 10 MB. |
| `/v1/telemetry` | `POST` | Telemetria mínima e anônima de produto (retenção e retestes). | Sem cache; payload JSON enxuto sem PII/IP. |

Enquanto não houver domínio próprio, essas rotas usam a URL `workers.dev` do Worker. A URL fica em configuração de build e pode ser trocada sem modificar os contratos de domínio. O catálogo não é uma rota de rede: ele acompanha o build e é validado localmente antes do uso.

### 4.2 Envelope assinado

O recurso local entrega um envelope; a assinatura é feita sobre os bytes de `payloadBase64` decodificados, antes de qualquer parse do conteúdo. Isso evita depender de serialização JSON canônica no iPhone.

```json
{
  "schemaVersion": 1,
  "catalogVersion": "2026.09.07.1",
  "issuedAt": "2026-09-07T12:00:00Z",
  "expiresAt": "2026-10-07T12:00:00Z",
  "algorithm": "Ed25519",
  "payloadBase64": "eyJnYW1lcyI6W119",
  "signatureBase64": "..."
}
```

Fluxo do cliente:

1. Decodificar `payloadBase64` e `signatureBase64`.
2. Verificar Ed25519 com a chave pública embarcada.
3. Recusar o documento se assinatura, versão de esquema, data ou parse falharem.
4. Validar referências e regras de negócio do payload.
5. Usar somente a versão validada presente no build.

A chave privada fica fora do app e é usada exclusivamente no processo de publicação do catálogo. Uma atualização exige novo envelope assinado e novo build; o cliente nunca aceita alteração não assinada.

### 4.3 Payload do catálogo

```json
{
  "markets": ["BR", "US"],
  "profiles": [
    {
      "id": "BATTLE_ROYALE_COMPETITIVE",
      "weights": { "latency": 35, "loss": 30, "jitter": 20, "stability": 15 },
      "thresholds": { "...": "ver seção 7" }
    }
  ],
  "regions": [
    {
      "id": "sa-east-1",
      "label": { "pt-BR": "São Paulo", "en": "São Paulo" },
      "probe": { "host": "gamelift-ping.sa-east-1.api.aws", "port": 7770 }
    }
  ],
  "games": [
    {
      "id": "fortnite",
      "name": "Fortnite",
      "profileID": "BATTLE_ROYALE_COMPETITIVE",
      "supportedPlatforms": ["iphone", "playstation", "xbox", "pc", "nintendo"],
      "markets": {
        "BR": {
          "candidateRegionIDs": ["sa-east-1"],
          "candidatePriorities": { "sa-east-1": 10 },
          "strategy": "genericRegion",
          "confidence": "medium",
          "precisionKey": "regionalReference"
        }
      }
    }
  ]
}
```

O exemplo histórico ilustra o contrato do schema 2. O catálogo local vigente usa schema 3, contém 48 jogos e referências AWS GameLift globais para cada contexto testável. São referências regionais, nunca endpoints ou ping oficial de jogo. Um jogo só é exibido como testável quando mercado, plataforma, perfil, ao menos uma referência regional e estratégia são válidos. A decisão vigente é [Catálogo global local nos clientes](./DECISOES.md#decisão-94).

### 4.4 Distribuição local e falha fechada

- O app contém um único catálogo Ed25519 no bundle.
- Não há consulta HTTP, atualização diária nem cache de catálogo.
- Falha de assinatura, esquema, validade ou regra de negócio torna o catálogo indisponível e impede medição.

### 4.5 Mercado automático, seleção regional e assets remotos assinados

O identificador regional do sistema somente ordena candidatos de mercado publicados. A escolha efetiva de mercado/região depende da pré-leitura UDP e da resolução contra o catálogo validado; ela não usa IP, localização precisa nem inferência geográfica e não fica travada na localidade quando a pessoa viaja ou usa VPN. Os candidatos, prioridade e destino UDP vêm exclusivamente do snapshot assinado aberto no começo da sessão. Sem contexto confirmado por esse fluxo, o jogo não aparece como testável. A regra `regional-selection-1`, vetores e gates estão em [Decisão de seleção regional automática](./DECISOES.md#decisão-16).

> **Atualizado pela Decisão 71:** catálogo assinado e artes remotas estão autorizados para iOS/Android. Artes continuam originais do LagCheck; não baixar capas ou materiais oficiais de terceiros.

O schema 3 declara `assetBaseURL` e `artwork.path`/`sha256`. O cliente exige HTTPS, caminho de imagem restrito, MIME PNG/JPEG/WebP, até 8 MiB e dimensões até 4096×4096 antes de decodificar. Por autorização do dono, não compara SHA-256 aos bytes recebidos; o campo permanece como metadado de compatibilidade. Falha de arte não altera catálogo nem medição. Downloads são interrompidos durante preparação/Check.

O armazenamento usa duas políticas independentes:

- catálogo: envelope local validado e versão registrada no resultado; uma atualização chega somente em novo build;
- imagens: cache local por URL e revisão (versão de catálogo ou metadado assinado), revalidação após 24 h, fallback em falha e teto de 50 MiB por limpeza das entradas antigas.

O carregamento de assets é oportunista. Falha, cache ausente ou pressão de armazenamento mostra placeholder neutro e permite continuar descoberta, seleção e medição. Um asset nunca é pré-requisito para score, região, rota, perfil ou início de sessão.

## 5. Medição de rede

### 5.1 Observação do caminho
 
`NWPathMonitor` começa antes da sessão e registra o caminho inicial. Uma alteração relevante de interface, por exemplo Wi-Fi para celular ou celular para Wi-Fi, cancela imediatamente a sessão e descarta integralmente todas as amostras parciais da memória sem persistência. A UI recebe o estado `cancelled(networkChanged)` e oferece reinício na rede atual.

`Quick Check` e `Deep Check` podem ser iniciados em Wi-Fi ou rede celular. Em rede celular, o `Deep Check` exige confirmação explícita prévia de uso de dados móveis (teto de 10 MB). Sem consentimento, permite apenas Quick Check ou cancelar.

### 5.2 Transporte UDP

O adaptador usa `NWConnection` com `NWParameters.udp` para cada destino do GameLift. Cada probe contém um payload não vazio, menor que 300 bytes, com versão de protocolo, identificador aleatório da sessão e sequência. A resposta só é aceita quando corresponde à sessão/sequência aguardada; duplicatas, respostas fora de ordem não correlacionáveis e dados tardios são inválidos.

#### 5.2.1 Contrato verificável do Ping Beacon — piloto Quick Check

Este é o contrato exclusivo do piloto, versão `NLPG/1`. Ele existe para provar que o RTT veio de um datagrama UDP correlacionado, e não para identificar um servidor oficial de jogo.

| Item | Regra verificável |
| --- | --- |
| Destino permitido | No catálogo Debug v2 vigente, `gamelift-ping.sa-east-1.api.aws:7770`, para os oito contextos BR / iPhone e `sa-east-1`. Esse destino é referência regional AWS com `genericRegion` / `medium`; não autoriza comunicar ping oficial de qualquer jogo. Candidatos EUA só entram após novo envelope assinado, conforme a decisão regional. |
| Payload | Exatos 33 bytes: `4E 4C 50 47` (`NLPG`), versão `01`, UUID aleatório de sessão em 16 bytes, sequência `UInt32` big-endian e nonce aleatório `UInt64` big-endian. |
| Resposta válida | Eco byte a byte dos 33 bytes enviados. Uma resposta com tamanho, magic, versão, UUID, sequência ou nonce diferente é inválida. |
| Correlação | Cada payload é único na sessão por UUID, sequência e nonce. Só a resposta igual ao payload de um probe enviado, ainda sem resultado, pode gerar RTT. |
| Prazo | O RTT é `receivedAt - sentAt`; a resposta precisa chegar em menos de 2 s do envio daquele probe. O último envio pode ocorrer aos 29,5 s e a drenagem termina aos 32 s (Decisão 135). |
| Rejeições | Duplicata, resposta sem payload pendente, eco tardio, dado diferente e erro de transporte nunca contam como RTT válido nem como sucesso. Não há fallback HTTP ou ICMP. |

O transporte normaliza as amostras válidas pela sequência de envio antes da avaliação. Assim, uma resposta correlacionada que chegue fora de ordem continua válida para o seu probe, mas não reordena a série de RTT usada para jitter. Essa escolha mede a variação entre probes consecutivos da mesma janela e evita que a inversão de chegada por UDP altere a métrica. Respostas inválidas não entram nessa série.

Plano de amostragem (`sample-quality-v2`, Decisão 135). Os números vivem em `ProbeAcceptancePolicy` no motor compartilhado (Decisão 134); nenhuma plataforma os redefine:

| Sessão | Região | Cadência | Janela de envio | Máximo planejado |
| --- | --- | ---: | ---: | ---: |
| Quick | Primária | 1 probe a cada 500 ms | 30 s | 60 |
| Deep, repouso | Primária e alternativa, se existir | 1 probe a cada 500 ms por região | 30 s | 60 por região |
| Deep, carga | Primária | 1 probe a cada 500 ms | 30 s | 60 |

O timeout de cada probe é 2 s e a drenagem termina aos 32 s. Não há fallback para HTTP ou ICMP se UDP falhar. Com menos de **20** respostas válidas na fase (1/3 do plano), a sessão é `inconclusive` e não recebe LagCheck Score. Com 60 probes, 1 pacote perdido vale 1,67%.

#### 5.2.2 Contrato do Probe Isolado de Gateway Local (`en0`) — Decisão 55

Para separar sem falsas acusações o enlace doméstico da rota da operadora, o app executa um ciclo de probes isolados no roteador local quando conectado em Wi-Fi:

| Item | Regra verificável |
| --- | --- |
| Descoberta do Gateway | Resolução dinâmica do endereço IPv4/IPv6 do roteador padrão na interface `en0` via tabelas de roteamento BSD (`sysctl` com `NET_RT_DUMP` / `getifaddrs`). É proibido assumir IP fixo `.1`. |
| Protocolo e Porta | Datagramas UDP curtos para a porta de controle/eco local ou porta de serviço RFC 5389/STUN local do gateway com payload mínimo correlacionado. |
| Plano de Amostragem | 5 probes consecutivos no início da sessão (intervalo de 50 ms entre disparos; timeout de 200 ms por probe). Total máximo da janela: 1,0 s. |
| Critério de Sucesso | Pelo menos 3 respostas correlacionadas válidas em 5 calculam `rttLocal` e `lossLocal`; com menos de 3, o resultado é `.unobservable` (Decisão 135). RTT $\le 15$ ms e loss $0\%$ $\rightarrow$ `.stable`. RTT $> 15$ ms ou loss $> 0\%$ $\rightarrow$ `.degraded`. |
| Uso para atribuir culpa | `.stable` só libera texto que atribui o problema à rota/operadora quando o gateway está impecável: RTT $\le 5$ ms e loss $0\%$ (`root-cause-v2`). Fora disso, o texto fala de "rota até o destino" sem culpar ninguém (Decisões 50 e 135). |
| Gateway Não-Responsivo | Se o gateway possuir firewall que descarte UDP local: o resultado é estritamente `.unobservable`. **Não gera erro, não assume falha no Wi-Fi e não acusa o equipamento**. |

### 5.3 Deep Check e carga controlada (Wi-Fi e Rede Móvel)

Durante a fase de carga, `URLSession` solicita `/v1/load` com política que não usa cache. A carga segue `load-transfer-v2` (Decisão 135) e dura a janela de envio da fase de carga (30 s):
- Em Wi-Fi: executada diretamente, com 2 downloads paralelos de `/v1/load` (10 MB cada), reiniciados até a janela fechar, com teto de 6 requisições e 60 MB por check.
- Em rede móvel: 1 download com teto de 10 MB, o mesmo valor informado no consentimento.
- Chegar ao fim da janela com bytes recebidos conta como carga medida; a carga só é indisponível quando nenhum byte chegou.
- Em rede celular: exige consentimento explícito e transparente prévio (*"O Check Completo usa dados móveis para avaliar sua conexão sob carga."* com teto informado de 10 MB).
- Cancelamento imediato: ao cancelar por ação do usuário, background ou troca de caminho de rede, tanto a transferência HTTP quanto os sockets UDP são cancelados imediatamente.

O app mantém a série UDP de repouso e a série UDP sob carga estritamente separadas. Falha na transferência HTTP sem nenhum byte recebido não invalida o resultado em repouso, mas remove a conclusão sobre impacto sob carga e mostra a limitação ao usuário. Se a carga transferiu bytes e a série UDP sob carga ficou com menos de 20 respostas válidas, ou o watchdog abortou durante a carga, a conexão desabou sob carga: o check inteiro é `inconclusive(poorSampleQuality)`, sem nota (Decisão 135). O tipo de conexão (`.wifi` ou `.cellular`) é persistido no snapshot histórico.

### 5.4 Watchdog de Qualidade da Amostra — `sample-quality-v2` (Decisões 55 e 135)

O `SampleQualityEvaluator` monitora os primeiros probes para abortar sessões condenadas sem forçar o usuário a esperar 30 segundos por um resultado nulo. Os timeouts vencidos alimentam o watchdog em tempo real, no iOS e no Android:

1. **Aborto Precoce por Conexão Morta:** Se houver 4 timeouts consecutivos dentro dos primeiros 6 probes enviados, a sessão é interrompida imediatamente com estado `inconclusive(poorSampleQuality)`.
2. **Taxa de Perda Inicial Excessiva:** Se a perda for $\ge 70\%$ nos primeiros 10 probes enviados, a sessão é invalidada de imediato.
3. **Sequência Tardia de Perdas:** Se em qualquer momento após o décimo probe ocorrer uma sequência ininterrupta de 6 ou mais timeouts, a sessão é encerrada como inconclusiva por desconexão súbita.
4. **Descarte em Troca de Interface:** Qualquer sinal de transição de interface via `NWPathMonitor` aborta o ciclo imediatamente, zera o buffer de memória e emite `cancelled(networkChanged)`.

## 6. Métricas

| Métrica | Implementação |
| --- | --- |
| RTT | `receivedAt - sentAt` para resposta UDP correlacionada. |
| P50/P95/P99 | Percentil por interpolação linear sobre RTTs válidos ordenados. |
| Jitter | Média de `abs(RTT[n] - RTT[n-1])` entre RTTs válidos consecutivos na ordem de sequência de envio. |
| Perda | `timeouts / 60 × 100` (probes planejados da fase); respostas inválidas não são RTT e também não contam como sucesso. Medição do site (HTTPS) não reporta perda (Decisão 134). |
| Spike | Regra dependente do perfil sobre RTT válido e P50 final. |
| Consistência | Indicador 0–100 derivado de jitter, relação P95/P50, taxa de spikes e perda. |
| Impacto sob carga | `P50 carga - P50 repouso`; a classificação usa a regra versionada da seção 6.1 e o tier entra no veredito (seção 7.5). |

Percentis não recebem um RTT artificial para timeout. A perda é sempre reportada separadamente, inclusive quando torna uma medição inconclusiva.

### 6.1 Materialidade do impacto sob carga — `deep-load-impact-v4` (Decisões 55, 135 e 136)

A regra avalia P50, jitter, perda e spikes sob carga, calibrada pelo perfil do jogo. Δ = carga − repouso, com mínimo 0. A perda é contada em pacotes a mais que o repouso no plano de 60 (`round(Δperda × 60 / 100)`), porque 1 pacote isolado é ruído estatístico (Decisão 136). Todas as comparações são `≥`. O tier é o mais alto cujo critério for atendido.

| Perfil | Leve | Material | Severo |
| --- | --- | --- | --- |
| `BATTLE_ROYALE_COMPETITIVE` | ΔP50 ≥ 5 ms | ΔP50 ≥ 15 ms, ou Δjitter ≥ 10 ms, ou ≥ 2 pacotes, ou Δspikes ≥ 2 | ΔP50 ≥ 35 ms, ou Δjitter ≥ 20 ms, ou ≥ 3 pacotes, ou Δspikes ≥ 4 |
| `MOBILE_REALTIME` | ΔP50 ≥ 5 ms | ΔP50 ≥ 25 ms, ou Δjitter ≥ 15 ms, ou ≥ 2 pacotes, ou Δspikes ≥ 2 | ΔP50 ≥ 50 ms, ou Δjitter ≥ 25 ms, ou ≥ 4 pacotes, ou Δspikes ≥ 5 |
| `CASUAL_REALTIME` | ΔP50 ≥ 5 ms | ΔP50 ≥ 40 ms, ou Δjitter ≥ 20 ms, ou ≥ 2 pacotes, ou Δspikes ≥ 2 | ΔP50 ≥ 80 ms, ou Δjitter ≥ 35 ms, ou ≥ 4 pacotes, ou Δspikes ≥ 6 |

Sem nenhum critério atendido, o tier é `.none`. O corte fixo de +20 ms (`deep-load-impact-v1`) não decide mais nada; só alimenta a nota descritiva de bufferbloat (`bufferbloat-grade-v1`).

Vetores normativos da regra `deep-load-impact-v4` (os DLI2 da Decisão 55 continuam válidos):

| ID | Perfil | P50 Repouso | P50 Carga | Delta Jitter | Delta Perda | Classificação | Veredito Impactado |
| --- | --- | ---: | ---: | ---: | ---: | --- | --- |
| DLI2-01 | Battle Royale | 28 ms | 40 ms | +2 ms | 0% | `.light` | Mantém `.ready` |
| DLI2-02 | Battle Royale | 28 ms | 45 ms | +4 ms | 0% | `.material` | Modula para `.caution` |
| DLI2-03 | Battle Royale | 28 ms | 65 ms | +8 ms | 0% | `.severe` | Modula para `.notReady` |
| DLI2-04 | Battle Royale | 30 ms | 38 ms | +12 ms | 0% | `.material` (via jitter) | Modula para `.caution` |
| DLI2-05 | Mobile Realtime | 35 ms | 55 ms | +3 ms | 0% | `.light` (tolerância maior) | Mantém `.ready` |
| DLI2-06 | Casual Realtime | 50 ms | 85 ms | +5 ms | 0% | `.light` (tolerância casual) | Mantém `.ready` |
| DLI4-01 | Battle Royale | 30 ms | 40 ms | +2 ms | +1 pacote (1,67%) | `.light` (1 pacote é ruído) | Mantém `.ready` |
| DLI4-02 | Battle Royale | 30 ms | 40 ms | +2 ms | +2 pacotes (3,33%) | `.material` (via perda) | Modula para `.caution` |
| DLI4-03 | Battle Royale | 30 ms | 40 ms | +2 ms | +3 pacotes (5%) | `.severe` (via perda) | Modula para `.notReady` |
| DLI4-04 | Mobile Realtime | 30 ms | 30 ms | 0 | +3 pacotes (5%) | `.material` | Modula para `.caution` |
| DLI4-05 | Mobile Realtime | 30 ms | 30 ms | 0 | +4 pacotes (6,67%) | `.severe` | Modula para `.notReady` |
| DLI4-06 | Casual Realtime | 50 ms | 50 ms | +30,5 ms (6 spikes) | 0 | `.severe` (Δspikes ≥ 6) | Modula para `.notReady` |
| DLI3-03 | Battle Royale | 30 ms | 34,9 ms | 0 | 0% | `.none` | Mantém `.ready` |
| DLI3-04 | Battle Royale | 30 ms | 45 ms | 0 | 0% | `.material` (limite exato) | Modula para `.caution` |
| DLI3-05 | Battle Royale | 30 ms | 65 ms | 0 | 0% | `.severe` (limite exato) | Modula para `.notReady` |

Critérios de aceitação:

1. O domínio classifica o delta bruto avaliando P50, jitter, perda e spikes sob carga.
2. Score, classe e guardrails da fase de repouso são calculados só com o repouso; o tier de carga entra depois, no veredito e no teto da nota unificada (seção 7.5).
3. Carga sem nenhum byte transferido não gera classificação nem impacto persistível. Carga com bytes e série UDP insuficiente torna o check inconclusivo (seção 5.3).
4. O snapshot persiste `ruleVersion = deep-load-impact-v4` e o tier calculado.
5. Os vetores vivem em `apps/android/core/domain/src/commonTest/kotlin/com/lagcheck/domain/vectors/` e passam nos alvos JVM, iOS e JS.

### 6.2 Classificação Temporal de Spikes — `spike-pattern-v2` (Decisões 55 e 135)

O motor calcula o padrão em toda avaliação, na ordem de envio, com os limites de spike do próprio perfil:
- **Spike Isolado (`.isolated`):** 1 ou 2 spikes em toda a sessão, sem 2 spikes numa mesma janela de 5 probes consecutivos. Spike severo isolado nunca leva a `.notReady`: no máximo `.caution`, coerente com o guardrail de nota 74.
- **Spikes Recorrentes (`.recurring`):** $\ge 3$ spikes totais ou 2 spikes numa mesma janela deslizante de 5 probes consecutivos. Com $\ge 2$ spikes severos e padrão recorrente, o veredito é `.notReady`.

### 6.3 Métrica de Latência de Cauda ($P95/P50$) e Consistência (Decisão 55)

A dispersão de cauda mede a severidade dos micro-congelamentos:
$$\text{TailRatio} = \frac{P95}{P50}$$
- A cauda é elevada quando, ao mesmo tempo, $\text{TailRatio} \ge 1.8$, $P95 - P50 \ge 20$ ms e $P95 > 45$ ms. A mesma regra vale no veredito e nas causas (Decisão 135); a exigência absoluta evita falso positivo em conexões muito rápidas, onde 4 ms contra 8 ms já dá razão 2.

## 7. NGQE: avaliação determinística

### 7.1 Normalização por faixas

Cada métrica de menor-melhor é convertida em um componente de 0 a 100 a partir das três faixas do perfil:

- no teto **Excelente**, componente = 100;
- no teto **Ótimo**, componente = 80;
- no teto **Instável**, componente = 60;
- no início de **Risco de lag**, componente = 0;
- entre pontos, interpolação linear; abaixo/acima dos extremos, clamp em 100/0.

O componente de estabilidade usa o pior entre a avaliação de spikes e a avaliação de consistência. Isso impede que uma média de jitter boa esconda picos relevantes.

```text
scoreBruto = round(
  0.35 × componenteLatência +
  0.30 × componentePerda +
  0.20 × componenteJitter +
  0.15 × componenteEstabilidade
)
```

O score final é `scoreBruto` depois de aplicar guardrails. Mesmas amostras, versão de perfil e catálogo devem gerar o mesmo resultado em qualquer execução.

### 7.2 Regra fechada do piloto: `BATTLE_ROYALE_COMPETITIVE`

Para Fortnite, COD Mobile, Free Fire e PUBG MOBILE, a regra aplicável é `BATTLE_ROYALE_COMPETITIVE` na versão `pilot-2026.09.08.1`. O catálogo Debug BR publicado também habilita `MOBILE_REALTIME` para Brawl Stars e Wild Rift, e `CASUAL_REALTIME` para Roblox e Minecraft, nas versões declaradas no envelope. Cada contexto só é aceito quando sua versão declarada corresponde a uma regra determinística conhecida pelo domínio; os limites dos demais perfis estão na seção seguinte.

Cada componente de menor-melhor usa interpolação linear nos pontos `excelente → 100`, `ótimo → 80`, `instável → 60` e `risco → 0`, com clamp fora do intervalo.

| Componente | Excelente | Ótimo | Instável | Risco |
| --- | ---: | ---: | ---: | ---: |
| P50 (ms) | 40 | 60 | 90 | 100 |
| Perda (%) | 0 | 1 | 3 | 5 |
| Jitter (ms) | 8 | 15 | 25 | 40 |
| Relação P95/P50 | 1,10 | 1,35 | 1,75 | 2,50 |
| Taxa de spikes (%) | 0 | 3 | 10 | 20 |

`spike` é um RTT válido `> P50 + 30 ms` e `≥ 80 ms`. `spike severo` é um RTT válido `> P50 + 80 ms` e `≥ 150 ms`. A taxa de spikes é `spikes / respostas UDP válidas × 100`.

```text
consistência = clamp(
  0,40 × componenteJitter +
  0,30 × componenteP95P50 +
  0,20 × componenteSpikes +
  0,10 × componentePerda,
  0, 100
)

estabilidade = min(componenteSpikes, consistência)
scoreBruto = round(0,35 × latência + 0,30 × perda + 0,20 × jitter + 0,15 × estabilidade)
```

Com menos de dez respostas válidas, não há cálculo de componentes nem score. Perda é `timeouts / 30 × 100`; resposta inválida e erro de transporte não são RTT nem sucesso. Após o arredondamento, perda `>3%` ou P50 `>100 ms` limita o resultado a 59; dois ou mais spikes severos limitam o resultado a 74. Os dois limites podem coexistir e prevalece o menor score final.

Os vetores BR001–BR012 em `QualityEvaluatorPilotTests` são a evidência executável desta regra. Uma alteração futura de qualquer ponto, peso, guardrail ou semântica de sequência cria uma nova versão de perfil antes de mudar catálogo ou histórico.

### 7.3 Perfis iniciais da V1

| Perfil | P50: excelente/ótimo/instável/risco | Jitter: excelente/ótimo/instável/risco | Perda: excelente/ótimo/instável/risco |
| --- | --- | --- | --- |
| `BATTLE_ROYALE_COMPETITIVE` | 40 / 60 / 90 / 100 ms | 8 / 15 / 25 / 40 ms | 0 / 1 / 3 / 5% |
| `MOBILE_REALTIME` | 50 / 80 / 120 / >120 ms | 12 / 20 / 35 / >35 ms | 0 / 1 / 5 / >5% |
| `CASUAL_REALTIME` | 70 / 110 / 170 / >170 ms | 20 / 35 / 50 / >50 ms | 0 / 1 / 3 / >3% |

| Perfil | Spike | Spike severo | Guardrails |
| --- | --- | --- | --- |
| Battle Royale | `> P50 + 30 ms` e `≥ 80 ms` | `> P50 + 80 ms` e `≥ 150 ms` | perda >3% ou P50 >100 ms: no máximo Risco; 2 severos: no máximo Instável. |
| Mobile realtime | `> P50 + 40 ms` e `≥ 100 ms` | `> P50 + 100 ms` e `≥ 200 ms` | perda >5% ou P50 >130 ms: no máximo Risco; 2 severos: no máximo Instável. |
| Casual realtime | `> P50 + 60 ms` e `≥ 140 ms` | `> P50 + 140 ms` e `≥ 300 ms` | perda >3% ou P50 >180 ms: no máximo Risco; 3 severos: no máximo Instável. |

“No máximo” define um teto de classe, não uma substituição obrigatória. A classe nominal do score é: 90–100 Excelente, 75–89 Ótimo, 60–74 Instável e 0–59 Risco de lag.

### 7.4 Resultado e diagnóstico honesto de sintomas

`ResultInterpreter` recebe métricas, score, guardrails, confiança, estratégia e o probe isolado do gateway. Ele produz a lista de sintomas objetivos para o bloco **"O que encontramos"**, discriminando enlace local de rota remota:

- **Enlace Local (Wi-Fi / Gateway):** Estável (RTT $\le 15$ ms) vs. Degradação local observada vs. Não observável (firewall local);
- **Perda de pacotes na rota:** Nenhuma detectada vs. Percentual prejudicial observado;
- **Estabilidade e Spikes:** Estável vs. Picos recorrentes vs. Latência de cauda ($P95/P50 \ge 1.8$);
- **Comportamento sob carga:** Estável vs. Degradação material/severa (`LoadDegradationTier`);
- **Destino testado:** Região amigável e proximidade da referência gamer.

#### 7.4.1 Hierarquia de Causas e Coocorrência (Decisão 55)

Quando múltiplos problemas ocorrem em simultâneo, o avaliador resolve uma causa principal e até 2 sintomas secundários pela ordem de precedência:
1. **Perda de Pacotes Crítica** ($>1\%$ competitivo ou $>3\%$ casual) $\rightarrow$ *Perda de pacotes na rota*;
2. **Latência Alta** ($P50 >$ limite do perfil) $\rightarrow$ *Latência incompatível*;
3. **Picos Severos Recorrentes** ($\ge 2$ recorrentes) $\rightarrow$ *Picos recorrentes de latência*;
4. **Instabilidade Contínua (Jitter Alto)** $\rightarrow$ *Instabilidade contínua (jitter)*;
5. **Degradação sob Carga (Bufferbloat Material/Severo)** $\rightarrow$ *Rede saturada sob uso simultâneo*;
6. **Latência de Cauda Elevada** ($P95/P50 \ge 1.8$) $\rightarrow$ *Instabilidade de cauda (oscilações)*.

- **Regra de Coocorrência:** Se Jitter for alto e Carga for material/severa, o avaliador unifica a causa primária como *"Instabilidade sob uso da internet"*.
- **Enlace Local:** Se o gateway probe apontar `.degraded`, a causa ganha o qualificador *"Origem: Enlace Wi-Fi local"*. Só com gateway impecável (`.stable`, RTT $\le 5$ ms, loss 0%) e rota instável a causa ganha *"Origem: Rota externa / Operadora"*. Com gateway `.unobservable` ou estável mas não impecável, o qualificador é neutro (*"rota até o destino"*) e nada é atribuído à operadora (Decisões 50 e 135, `root-cause-v2`).

#### 7.4.2 Motor de Recomendações Baseadas em Evidência — `EvidenceRecommendationEngine` (Decisão 55)

Gera no máximo de 1 a 3 recomendações diretamente ligadas aos sintomas comprovados:

```swift
func generateRecommendations(evidence: DiagnosticEvidence) -> [ActionableRecommendation] {
    var recommendations: [ActionableRecommendation] = []
    
    if evidence.gatewayOutcome == .degraded {
        recommendations.append(ActionableRecommendation(
            priority: 1,
            title: "Aproxime-se do Roteador",
            instruction: "O sinal local até o roteador Wi-Fi oscilou. Reduza a distância ou obstáculos.",
            evidenceBadge: "Wi-Fi Local"
        ))
    }
    
    if evidence.wifiBand == .twoPointFourGigahertz && (evidence.wifiBandConfidence == .high || evidence.wifiBandConfidence == .medium) {
        recommendations.append(ActionableRecommendation(
            priority: 1,
            title: "Troque para Wi-Fi 5 GHz",
            instruction: "Redes 2.4 GHz sofrem alta interferência. Conecte-se na frequência 5 GHz.",
            evidenceBadge: "2.4 GHz Detectado"
        ))
    }
    
    if evidence.loadTier == .material || evidence.loadTier == .severe {
        recommendations.append(ActionableRecommendation(
            priority: 2,
            title: "Pause Downloads e Streaming",
            instruction: "A sua conexão sofreu lentidão sob uso intenso da banda.",
            evidenceBadge: "Saturação sob Carga"
        ))
    }
    
    // recommendations-v2 (Decisão 136): mesmo guardrail de perda do perfil que derruba o veredito
    if evidence.packetLossPercentage > profile.lossGuardrailPercentage && evidence.gatewayOutcome != .degraded {
        recommendations.append(ActionableRecommendation(
            priority: 1,
            title: "Evite Partidas Ranqueadas",
            instruction: "A perda de pacotes externa causará teleporte e comandos ignorados.",
            evidenceBadge: "Rota Externa"
        ))
    }
    
    return Array(recommendations.sorted(by: { $0.priority < $1.priority }).prefix(3))
}
```

### 7.5 Camada Semântica: `GameReadinessEvaluator` — `readiness-v3.0` (Decisão 135)

Um único caminho de avaliação, no motor compartilhado, serve tela, histórico, Home e widget em iOS, Android, Windows e site, com as mesmas entradas. A confiança média continua só como rótulo de estimativa (console/PC ou rota genérica) e **não aplica margem** no veredito. Os limites de perda, P50 e jitter vêm dos guardrails do perfil (seção 7.3).

A primeira condição atendida, na ordem abaixo, define o veredito:

| Ordem | Condição | Veredito |
| ---: | --- | --- |
| 0 | Menos de 20 respostas válidas, ou carga que desabou (seção 5.3) | `.inconclusive` |
| 1 | Perda acima do guardrail do perfil (só UDP do app) | `.notReady` |
| 2 | P50 acima do guardrail do perfil | `.notReady` |
| 3 | Spikes recorrentes com $\ge 2$ severos | `.notReady` |
| 4 | Tier de carga `.severe` | `.notReady` |
| 5 | Classe de repouso `Risco de lag` | `.notReady` |
| 6 | Jitter $\ge$ limite de risco do perfil | `.caution` |
| 7 | Fora de ordem: $\ge 2$ pacotes ou $\ge 5\%$ (só UDP do app) | `.caution` |
| 8 | Tier de carga `.material` | `.caution` |
| 9 | Spikes recorrentes | `.caution` |
| 10 | Cauda elevada (seção 6.3) | `.caution` |
| 11 | Gateway `.degraded` | `.caution` |
| 12 | Classe de repouso `Instável` | `.caution` |
| — | Nenhuma das anteriores | `.ready` |

A nota unificada respeita o veredito: carga `.severe` limita a 59 e `.material` a 74; `.ready` fica em 75 ou mais, `.caution` entre 60 e 74, `.notReady` em 59 ou menos, e `.inconclusive` não tem nota. Medição do site (`WEB_HTTPS`) não tem nota, perda nem fora de ordem e é sempre estimativa (Decisão 134).

### 7.6 Integridade de Diagnóstico de Rede Local e Frequência Wi-Fi

1. **Gateway Dinâmico:** `WiFiLocalGatewayProber` obtém o IP do gateway via rotas do kernel BSD na interface `en0`. Se o gateway não responder probes UDP, o status é `.unobservable`, e o enlace local é considerado neutro.
2. **Medição Local Isolada:** Só há RTT local se o pacote UDP ecoar do gateway.
3. **Banda Wi-Fi:** `WiFiBandDetector` classifica a certeza da frequência em `.high`, `.medium`, `.low`, `.unknown`. Sem confiança alta/média de APIs nativas, o app **não afirma a frequência Wi-Fi** e não sugere troca. Fica expressamente vedado inferir a banda Wi-Fi a partir do P50 da rota remota.

### 7.7 Topologia de NAT e Relevância Contextual (Decisão 55)

O diagnóstico de NAT (Aberto, Moderado, Restrito ou CGNAT) é executado via STUN leve RFC 5389.
- **Regra de Exibição:** O resultado de NAT só é visível na tela de resultado ou diagnóstico quando o jogo selecionado possuir arquitetura `peerToPeer` ou `hybrid` (onde o tipo de NAT impede o pareamento).
- Para jogos com servidores dedicados (`dedicatedServer`, ex: Valorant, Fortnite, LoL, CS2), o diagnóstico de NAT permanece restrito aos detalhes técnicos avançados para não induzir confusão.

## 8. Persistência com SwiftData

Modelos persistidos:

| Modelo | Campos essenciais |
| --- | --- |
| `GamePreference` | jogo, favorito, última plataforma e data de uso. |
| `MeasurementRecord` | jogo/contexto, data, veredito de prontidão (`GameReadinessVerdict`), score/classe, métricas agregadas, causa primária, causas secundárias, recomendações geradas, resultado do probe do gateway local, tipo de conexão (`.wifi` ou `.cellular`), confiança, estratégia, região, versão de catálogo, perfil e versões de regras (`readiness-v3.0`, `deep-load-impact-v4`, `recommendations-v2`, `sample-quality-v2`, `spike-pattern-v2`, `root-cause-v2`, `load-transfer-v2` e a versão do perfil, por exemplo `pilot-2026.11.14.1`). Entradas antigas guardam as versões com que foram gravadas. |
| `AppPreference` | idioma escolhido/sistema, estado de privacidade e configurações de apresentação. |

Uma tarefa de manutenção remove registros com mais de 90 dias e conserva no máximo os 100 mais recentes por jogo. A ação “Apagar histórico” remove `MeasurementRecord` e dados derivados de recentes; não toca no catálogo-base.

### 8.1 Contrato do snapshot de widget por jogo

O snapshot de widget é derivado, local e substituível; não é um novo registro de histórico nem uma fonte de decisão diagnóstica. Só é escrito ao final de um Check válido e contém: `gameID`, nome localizado, plataforma, vínculo externo declarado, região, `GameReadinessVerdict`, P50, jitter, perda, bufferbloat opcional e instante de captura. A imagem é uma miniatura editorial já presente na própria build: JPEG reduzido no contêiner compartilhado do iOS e nome de resource no armazenamento privado Android.

O iOS constrói `lagcheck://check?game={gameID}`; Android recebe o mesmo `gameID` no deep link/`Intent` canônico. Nos dois casos, o app deve recarregar o contexto a partir do catálogo local válido antes de abrir a sessão. Um snapshot com mais de quatro horas nunca exibe métricas ou veredito como atuais. Falha de arte, arte incompatível com a revisão atual, catálogo inválido ou jogo removido não aciona rede pelo widget e cai para identidade neutra/CTA recuperável.

## 9. Privacidade e publicidade planejada

**Estado vigente (Decisões 82, 94 e 95):** Android e iOS usam AdMob e UMP para anúncios Native Advanced em Home, Histórico, Jogos e Resultado. O gate `canRequestAds` e a chave de build condicionam requisições; não há anúncios durante a medição. No iOS, Debug usa IDs de teste e Release configura os IDs de produção do app iOS. Nenhuma amostra, score, causa, região ou resultado é enviado ao SDK de publicidade.

O cliente iOS passa a integrar Google Mobile Ads e UMP somente na camada do app completo. Widget, App Clip, domínio, aplicação, infraestrutura de medição e telemetria de produto não recebem SDK, ID ou dados de anúncio. A decisão sobre ATT e as declarações App Privacy seguem o comportamento real do SDK e precisam de revisão antes de distribuição; nenhuma solicitação ATT é presumida nesta implementação.

As Decisões 82, 94 e 95 estabelecem consentimento, opções de privacidade, superfícies elegíveis, comportamento em falha e validação de release. A integração publicitária não pode receber amostras, score, causa, região ou resultado.

## 10. Estados e erros

| Situação | Estado técnico | UI esperada |
| --- | --- | --- |
| Catálogo local inválido ou vencido | `catalogUnavailable` | Explica que a configuração do jogo não está disponível. |
| Mudança de rede (Wi-Fi ⇄ celular) | `cancelled(networkChanged)` | Cancela na hora, descarta parciais e oferece reinício na rede atual. |
| Amostra de baixa qualidade (Watchdog) | `inconclusive(poorSampleQuality)` | Aborta precocemente; explica instabilidade extrema da conexão e sugere nova tentativa. |
| Deep Check em rede celular | Confirmação prévia de dados | Apresenta modal/aviso de consumo (máx 10 MB); permite aceitar, Quick Check ou cancelar. |
| Menos de 10 RTTs válidos | `inconclusive(insufficientUDPResponses)` | Não dá nota; sugere outra rede. |
| Falha de carga HTTP | `loadUnavailable` | Exibe resultado de repouso e limitação do Deep Check. |
| Destino/configuração inválida | `failed(invalidContext)` | Não inicia medição e registra erro local de diagnóstico. |

## 11. Testes e validação

| Camada | Cobertura mínima |
| --- | --- |
| Domínio | Percentis, jitter, perda, spikes recorrentes/isolados, cauda P95/P50, carga multidimensional (`deep-load-impact-v4`), veredito `readiness-v3.0` sem margem de confiança e motor de recomendações. Os vetores normativos do motor compartilhado rodam em JVM, iOS e JS (Decisão 134). |
| Watchdog | Invalidação antecipada por timeouts consecutivos ($\ge 4$ em 6 probes) e perda precoce ($\ge 70\%$). |
| Gateway Prober | Resolução de rota BSD, probe UDP no gateway, classificação stable/degraded e tolerância a gateways firewall (`.unobservable`). |
| Catálogo | Assinatura válida/inválida, validade, schema, rollback, cache de 24 h e fallback de 30 dias/base. |
| Transporte | Correlação de payload, timeout, duplicata, resposta tardia e cancelamento imediato de sockets/HTTP. |
| Sessão | Check (Wi-Fi e Celular), consentimento de dados, troca de caminho (Wi-Fi ⇄ celular) com descarte total e carga falha. |
| Persistência | Registro de histórico com versões normativas de regras, veredito semântico, causas primárias/secundárias e recomendações. |
| Widget | Snapshot válido, expiração de quatro horas, invalidação por catálogo/arte, fonte oficial iOS e Android isolada, deep link para jogo correto e ausência de fetch/medição em background. |
| UI | Dark Competitive UI: Hero Verdict de maior hierarquia, cockpit telemetria compacto, bloco "O que encontramos" e 1 a 3 cards de recomendação. |

### 11.1 Matriz de Testes Obrigatórios em iPhone Físico (Decisão 36)
- Wi-Fi: repouso, carga, resultado válido e inconclusivo.
- Rede móvel: confirmação de consumo, repouso, carga, resultado válido e inconclusivo.
- Recusar confirmação em rede móvel (deve permitir Quick Check ou cancelar).
- Wi-Fi → rede móvel durante repouso (descarte total imediato).
- Wi-Fi → rede móvel durante carga (descarte total e cancelamento imediato de sockets/HTTP).
- Rede móvel → Wi-Fi durante repouso (descarte total imediato).
- Rede móvel → Wi-Fi durante carga (descarte total e cancelamento imediato de sockets/HTTP).
- Confirmar que nenhuma troca de rede mantém resultado parcial.

## 12. Critérios para iniciar implementação

- Catálogo local v3 assinado, byte-idêntico em iOS e Android, com 48 jogos e referências AWS GameLift globais para os contextos testáveis.
- Chave Ed25519 gerada e chave pública adicionada aos recursos do app.
- Worker gratuito publicado com `/v1/load` e `/v1/telemetry`; catálogo Ed25519 local presente nos dois clientes.
- Textos de causas, recomendações e erros disponíveis em PT-BR e inglês.
- Tabelas de perfil do catálogo reproduzem os limites desta especificação.
