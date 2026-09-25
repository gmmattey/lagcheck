# LagCheck — especificação técnica do MVP

**Status:** rascunho técnico inicial  
**Aplicativo:** iPhone, iOS 17 ou superior  
**Documentos relacionados:** [Funcional](./01-funcional.md) · [Arquitetura](./02-arquitetura.md)

## 1. Escopo técnico fechado

| Área | Decisão |
| --- | --- |
| App | Nativo para iPhone, iOS 17+, Swift e SwiftUI. |
| Medição | UDP direto do iPhone para AWS GameLift Ping Beacons. |
| Check (Deep Check) | Wi-Fi e rede móvel (com consentimento); 15 s em repouso + 15 s sob carga; máximo de 10 MB na carga. Chamado simplesmente de **Check** na interface. |
| Veredito Principal | `GameReadinessVerdict` (`.ready`, `.caution`, `.notReady`, `.inconclusive`). Protagonista visual imediato. |
| Score | Local, determinístico, de 0 a 100 (mantido para detalhes, histórico e telemetria). |
| Catálogo & Telemetria | Cloudflare Worker gratuito; catálogo `/v1/catalog.json`, carga `/v1/load` e telemetria anônima `/v1/telemetry`. |
| Assinatura | Ed25519; somente a chave pública vai no app. |
| Histórico | SwiftData local; 90 dias e máximo de 100 medições por jogo, organizado por títulos e vereditos. |
| Publicidade | Fora do MVP1; AdMob, UMP e banners ficam para MVP1.1. |
| Privacidade | Sem SDKs de terceiros (Firebase, Mixpanel, Ads). Telemetria mínima anônima via Worker próprio sem PII/IP. |
| Idiomas | PT-BR, inglês e espanhol. |

Não entram no MVP1: Android, conta, sincronização em nuvem, VPN/otimização de rota, banco de dados remoto, analytics de terceiros, comparação Wi-Fi versus celular, fallback HTTP/ICMP para UDP, AdMob, UMP, banners e assistentes de IA no fluxo principal.

## 2. Organização do código iOS

```text
LagCheck/
├── App/                 composição, ciclo de vida e dependências
├── Features/            Home, Game, Measurement, Result, Details, History, Settings
├── Domain/              modelos, NGQE, regras, resolvedor de contexto, sintomas e GameReadinessEvaluator
├── Infrastructure/      UDP, caminho de rede, HTTP load, catálogo, telemetria e SwiftData
├── Resources/           catálogo-base, traduções, chaves públicas e assets
└── Tests/               unitários, contratos, integração e UI
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
    case inconclusive   // Inconclusivo (menos de 10 respostas UDP válidas)
}

enum ResultClass: String, Codable { case excellent, great, unstable, lagRisk, inconclusive, cancelled }
enum SessionPhase: String { case idle, resolving, measuringIdle, measuringLoad, evaluating, completed, cancelled, inconclusive, failed }

struct GameContext: Codable, Hashable {
    let gameID: String
    let market: String       // "BR" ou "US"
    let platform: Platform
    let equipmentConnection: NetworkKind? // somente console/PC quando declarado
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

## 4. Catálogo remoto

### 4.1 Rotas do Worker

| Rota | Método | Uso | Cache |
| --- | --- | --- | --- |
| `/v1/catalog.json` | `GET` | Configuração assinada do produto. | Conforme versão/validade do catálogo. |
| `/v1/load` | `GET` | Carga HTTP do Check (Wi-Fi e celular com consentimento). | `Cache-Control: no-store`; até 10 MB. |
| `/v1/telemetry` | `POST` | Telemetria mínima e anônima de produto (retenção e retestes). | Sem cache; payload JSON enxuto sem PII/IP. |

Enquanto não houver domínio próprio, essas rotas usam a URL `workers.dev` do Worker. A URL fica em configuração de build e pode ser trocada sem modificar os contratos de domínio.

### 4.2 Envelope assinado

O endpoint entrega um envelope; a assinatura é feita sobre os bytes de `payloadBase64` decodificados, antes de qualquer parse do conteúdo. Isso evita depender de serialização JSON canônica no iPhone.

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
5. Persistir somente a versão validada em cache local.

A chave privada fica fora do app e é usada exclusivamente no processo de publicação do Worker. Um rollback é uma nova publicação assinada com versão superior; o cliente nunca aceita alteração não assinada.

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

O exemplo é o contrato do schema 2 para seleção regional: `candidateRegionIDs` e `candidatePriorities` exigem envelope/payload de schema 2 e a chave de prioridades precisa corresponder exatamente aos IDs candidatos. O Debug publicado de catálogo `debug-2026.09.08.2` permanece no schema 1, compatível por mapear seu único `primaryRegion` BR para candidato implícito de prioridade zero. Todos usam o beacon AWS de São Paulo exclusivamente como `genericRegion`, com confiança `medium`; nenhum contexto declara endpoint ou ping oficial do jogo. Um jogo só é exibido como testável quando o mercado, a plataforma, o perfil, ao menos uma região candidata e a estratégia são válidos. A decisão, fontes e mapa completo estão em [Catálogo remoto Debug](./14-decisao-catalogo-remoto-debug.md) e [Decisão de seleção regional automática](./16-decisao-selecao-regional-automatica.md).

### 4.4 Atualização e fallback

- O app contém um catálogo-base assinado no bundle.
- A consulta remota é tentada no máximo uma vez a cada 24 horas, sem bloquear a Home.
- Uma versão remota válida pode ser usada por até 30 dias.
- Passado esse período, o app volta ao catálogo-base.
- Falha de Worker, HTTP, assinatura ou esquema não sobrescreve o último catálogo válido.

### 4.5 Mercado automático, seleção regional e assets remotos assinados

O identificador regional do sistema somente ordena candidatos de mercado publicados. A escolha efetiva de mercado/região depende da pré-leitura UDP e da resolução contra o catálogo validado; ela não usa IP, localização precisa nem inferência geográfica e não fica travada na localidade quando a pessoa viaja ou usa VPN. Os candidatos, prioridade e destino UDP vêm exclusivamente do snapshot assinado aberto no começo da sessão. Sem contexto confirmado por esse fluxo, o jogo não aparece como testável. A regra `regional-selection-1`, vetores e gates estão em [Decisão de seleção regional automática](./16-decisao-selecao-regional-automatica.md).

> **Substituído para a V1:** o parágrafo de assets remotos abaixo não reflete o catálogo Debug atual. A [Decisão de identidade visual neutra dos jogos](./18-decisao-identidade-visual-neutra-de-jogos.md) remove qualquer asset remoto, URL, hash ou MIME de imagem do payload; a miniatura é um componente neutro do design system. Fica como referência para uma eventual reativação do pipeline, com nova decisão e revisão de Renan/Marco.

Cada asset remoto declarado pelo payload contém `url`, `sha256`, `mimeType`, `byteLength` e identificador estável. O cliente exige HTTPS, host permitido pela configuração assinada, MIME de imagem permitido e tamanho máximo de 5 MB antes de decodificar. Depois do download, confere tamanho e SHA-256; divergência descarta o arquivo e não altera o catálogo nem a sessão de medição.

O armazenamento usa duas políticas independentes:

- catálogo: envelope validado, data de atualização e origem; consulta remota no máximo a cada 24 h e validade máxima de 30 dias;
- imagens: bytes já verificados por hash, chaveados pelo hash do asset, com LRU e teto local de 50 MB.

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
| Prazo | O RTT é `receivedAt - sentAt`; a resposta precisa chegar em menos de 2 s do envio daquele probe. O último envio pode ocorrer aos 14,5 s e a drenagem termina aos 17 s. |
| Rejeições | Duplicata, resposta sem payload pendente, eco tardio, dado diferente e erro de transporte nunca contam como RTT válido nem como sucesso. Não há fallback HTTP ou ICMP. |

O transporte normaliza as amostras válidas pela sequência de envio antes da avaliação. Assim, uma resposta correlacionada que chegue fora de ordem continua válida para o seu probe, mas não reordena a série de RTT usada para jitter. Essa escolha mede a variação entre probes consecutivos da mesma janela e evita que a inversão de chegada por UDP altere a métrica. Respostas inválidas não entram nessa série.

Plano de amostragem:

| Sessão | Região | Cadência | Duração | Máximo planejado |
| --- | --- | ---: | ---: | ---: |
| Quick | Primária | 2 probes/s | 15 s | 30 |
| Deep, repouso | Primária e alternativa, se existir | 2 probes/s por região | 15 s | 30 por região |
| Deep, carga | Primária | 2 probes/s | 15 s | 30 |

O timeout de cada probe é 2 s. Não há fallback para HTTP ou ICMP se UDP falhar. Com menos de 10 respostas válidas na região primária, a sessão é `inconclusive` e não recebe LagCheck Score.

### 5.3 Deep Check e carga controlada (Wi-Fi e Rede Móvel)

Durante a fase de carga, `URLSession` solicita `/v1/load` com política que não usa cache. A transferência é interrompida ao atingir 10 MB ou 15 segundos, o que ocorrer primeiro.
- Em Wi-Fi: executado diretamente.
- Em rede celular: exige consentimento explícito e transparente prévio (*"O Check Completo usa dados móveis para avaliar sua conexão sob carga."* com teto informado de 10 MB).
- Cancelamento imediato: ao cancelar por ação do usuário, background ou troca de caminho de rede, tanto a transferência HTTP quanto os sockets UDP são cancelados imediatamente.

O app mantém a série UDP de repouso e a série UDP sob carga estritamente separadas. Falha na transferência HTTP não invalida o resultado em repouso, mas remove a conclusão sobre impacto sob carga e mostra a limitação ao usuário. O tipo de conexão (`.wifi` ou `.cellular`) é persistido no snapshot histórico.

## 6. Métricas

| Métrica | Implementação |
| --- | --- |
| RTT | `receivedAt - sentAt` para resposta UDP correlacionada. |
| P50/P95/P99 | Percentil por interpolação linear sobre RTTs válidos ordenados. |
| Jitter | Média de `abs(RTT[n] - RTT[n-1])` entre RTTs válidos consecutivos na ordem de sequência de envio. |
| Perda | `timeouts / probes enviados × 100`; respostas inválidas não são RTT e também não contam como sucesso. |
| Spike | Regra dependente do perfil sobre RTT válido e P50 final. |
| Consistência | Indicador 0–100 derivado de jitter, relação P95/P50, taxa de spikes e perda. |
| Impacto sob carga | `P50 carga - P50 repouso`; é apresentado separado do score principal. A classificação de materialidade usa a regra versionada da seção 6.1. |

Percentis não recebem um RTT artificial para timeout. A perda é sempre reportada separadamente, inclusive quando torna uma medição inconclusiva.

### 6.1 Materialidade do impacto sob carga — `deep-load-impact-v1`

Esta regra classifica apenas o delta observado entre os P50 válidos de repouso e carga. Ela não calcula um segundo LagCheck Score, não altera o score/classe/guardrails de repouso e não infere a qualidade integral da conexão sob carga. Perda, jitter e spikes da carga continuam métricas comparativas separadas.

| Entrada | Regra |
| --- | --- |
| Elegibilidade | As duas fases precisam ter avaliação UDP válida; se a carga falhar ou tiver menos de 10 respostas válidas, não há impacto nem classificação. |
| Delta | `P50 carga - P50 repouso`, em milissegundos e sem arredondamento de apresentação. |
| Descritivo | Delta menor que `+20,0 ms`, inclusive zero ou negativo. O valor continua visível, sem linguagem de impacto material. |
| Material | Delta maior ou igual a `+20,0 ms`. A interface pode declarar impacto material sob carga, sem reescrever o resultado de repouso. |
| Snapshot | Persistir `ruleVersion = deep-load-impact-v1` e a classificação calculada junto ao impacto para auditoria histórica. |

O corte de 20 ms é deliberadamente conservador para o piloto: evita transformar flutuações pequenas entre duas janelas independentes de 15 segundos em um alerta. Ele será recalibrado somente com nova versão, vetores de teste e revisão de Iury; medições históricas mantêm a versão que as classificou.

Vetores normativos da regra:

| ID | P50 repouso | P50 carga | Delta bruto | Classificação esperada | Score de repouso |
| --- | ---: | ---: | ---: | --- | --- |
| DLI-001 | 30 ms | 30 ms | 0 ms | descritivo | inalterado |
| DLI-002 | 30 ms | 49,999 ms | +19,999 ms | descritivo | inalterado |
| DLI-003 | 30 ms | 50 ms | +20 ms | material | inalterado |
| DLI-004 | 93 ms | 30 ms | -63 ms | descritivo | inalterado |
| DLI-005 | 30 ms | indisponível ou menos de 10 RTTs válidos | — | sem classificação | inalterado |

Critérios de aceitação:

1. O domínio classifica o delta bruto, e não o inteiro/arredondamento mostrado pela interface.
2. A fronteira é inclusiva: `+20,0 ms` é material; qualquer valor inferior é descritivo.
3. Resultado, score, classe e guardrails da fase de repouso são idênticos com ou sem materialidade sob carga.
4. Falha da carga ou série UDP insuficiente não gera classificação parcial nem impacto persistível.
5. Um snapshot novo contém valor do delta, `ruleVersion` e classificação; um snapshot legado sem esses campos continua decodificável e recebe a regra V1 uma única vez.

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

`ResultInterpreter` recebe métricas, score, guardrails, confiança e estratégia. Ele produz a lista de sintomas objetivos observados para compor o bloco **"O que encontramos"**:

- **Perda de pacotes:** Nenhuma detectada vs. Percentual prejudicial observado;
- **Estabilidade:** Estável vs. Oscilação / Spikes relevantes;
- **Comportamento sob carga:** Estável vs. Degradação material sob uso intenso;
- **Destino testado:** Região amigável e proximidade da referência gamer.

### 7.5 Camada Semântica: `GameReadinessEvaluator` (Decisão 50)

O `GameReadinessEvaluator` atua acima do `QualityResult` e dos sintomas, traduzindo o estado da rede para uma decisão clara de jogo:

```swift
func evaluateReadiness(quality: QualityResult, profile: GameProfile) -> GameReadinessVerdict {
    guard quality.validResponsesCount >= 10 else {
        return .inconclusive
    }
    
    // Critérios restritivos para Ranked/Competitivo
    if quality.packetLossPercentage > profile.maxAcceptableLoss || quality.p50Milliseconds > profile.notReadyLatencyThreshold {
        return .notReady
    }
    
    if quality.jitterMilliseconds > profile.cautionJitterThreshold || quality.hasMaterialLoadDegradation || quality.severeSpikesCount > 0 {
        return .caution
    }
    
    return .ready
}
```

> **Revisão de Regra de Produto:** A antiga restrição em `CheckCompletoVerdict` que proibia o texto "Pronto para jogar" é expressamente revisada. O app passa a emitir vereditos diretos baseados em evidência matemática (*"PRONTO PARA JOGAR"*, *"EU EVITARIA RANKED AGORA"*), mantendo a postura de sobriedade e recomendação situacional em vez de promessa infalível de futuro.

### 7.6 Integridade de Diagnóstico de Rede Local (Wi-Fi Probing)

Para evitar falsas acusações contra equipamentos domésticos ou contra a operadora (Decisão 50):

1. **Gateway Local:** `WiFiLocalGatewayProber` não deve assumir ip `.1` por padrão; o gateway deve ser descoberto via interfaces de roteamento do sistema (`sysctl`/`getifaddrs`).
2. **Medição RTT Local:** O envio de pacotes UDP na porta 53 para o gateway que mede apenas o tempo de retorno da chamada de socket não constitui RTT. Sem resposta do gateway, não há cálculo de latência local do roteador.
3. **Desacoplamento de RTT Remoto e Banda Wi-Fi:** `WiFiBandEvaluator` é proibido de usar a latência mediana (P50) ou jitter da rota remota de internet (WAN) para inferir se o Wi-Fi opera em 2.4 GHz ou 5 GHz. Oscilações remotas pertencem à rota externa até que um probe local isolado prove o contrário.

## 8. Persistência com SwiftData

Modelos persistidos:

| Modelo | Campos essenciais |
| --- | --- |
| `StoredCatalog` | versão, validade, envelope, data de atualização e origem base/remota. |
| `GamePreference` | jogo, favorito, última plataforma e data de uso. |
| `MeasurementRecord` | jogo/contexto, data, score/classe, métricas agregadas, causa, confiança, estratégia, região, versão de catálogo e perfil. |
| `AppPreference` | idioma escolhido/sistema, estado de privacidade e configurações de apresentação. |

Uma tarefa de manutenção remove registros com mais de 90 dias e conserva no máximo os 100 mais recentes por jogo. A ação “Apagar histórico” remove `MeasurementRecord` e dados derivados de recentes; não toca no catálogo-base.

## 9. Privacidade e publicidade planejada

No MVP1 não há publicidade e, portanto, não há SDK Google Mobile Ads, UMP, ATT motivado por anúncios, `AdProvider`, ID de unidade, banner ou fluxo de consentimento publicitário. A privacidade do MVP1 se limita aos dados locais e ao catálogo assinado previstos neste documento.

Publicidade só volta a escopo no MVP1.1, mediante decisão técnica e de produto que especifique consentimento, opções de privacidade, superfícies elegíveis, comportamento em falha e validação de release. Essa evolução não poderá receber amostras, score, causa, região ou resultado.

## 10. Estados e erros

| Situação | Estado técnico | UI esperada |
| --- | --- | --- |
| Catálogo indisponível, mas cache válido | `catalogFallback` | Continua com catálogo válido. |
| Catálogo inválido sem fallback aplicável | `catalogUnavailable` | Explica que a configuração do jogo não está disponível. |
| Mudança de rede (Wi-Fi ⇄ celular) | `cancelled(networkChanged)` | Cancela na hora, descarta parciais e oferece reinício na rede atual. |
| Deep Check em rede celular | Confirmação prévia de dados | Apresenta modal/aviso de consumo (máx 10 MB); permite aceitar, Quick Check ou cancelar. |
| Menos de 10 RTTs válidos | `inconclusive(insufficientUDPResponses)` | Não dá nota; sugere outra rede. |
| Falha de carga HTTP | `loadUnavailable` | Exibe resultado de repouso e limitação do Deep Check. |
| Destino/configuração inválida | `failed(invalidContext)` | Não inicia medição e registra erro local de diagnóstico. |

## 11. Testes e validação

| Camada | Cobertura mínima |
| --- | --- |
| Domínio | Percentis, jitter, perda, spikes, score, guardrails, classe e causa principal para cada perfil. |
| Catálogo | Assinatura válida/inválida, validade, schema, rollback, cache de 24 h e fallback de 30 dias/base. |
| Transporte | Correlação de payload, timeout, duplicata, resposta tardia e cancelamento imediato de sockets/HTTP. |
| Sessão | Quick, Deep (Wi-Fi e Celular), consentimento de dados, troca de caminho (Wi-Fi ⇄ celular) com descarte total e carga falha. |
| Persistência | Registro explícito do tipo de conexão (`.wifi` ou `.cellular`), limites de 90 dias/100 por jogo e apagar histórico. |
| UI | Trilha HIG de 5 passos sem poluição visual (sem números, percentuais, gráficos ou score preliminar), estados inconclusivo/cancelado e PT-BR/EN/ES. |

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

- Catálogo Debug v2 com os oito jogos preenchidos para BR / iPhone; US permanece candidato futuro, sem contexto testável enquanto não houver envelope assinado específico.
- Chave Ed25519 gerada e chave pública adicionada aos recursos do app.
- Worker gratuito publicado com `/v1/catalog.json` e `/v1/load`.
- Textos de causas, recomendações e erros disponíveis em PT-BR e inglês.
- Tabelas de perfil do catálogo reproduzem os limites desta especificação.
