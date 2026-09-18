# LagCheck — Decisão 29: Infraestruturas de Medição a Custo Zero (AWS GameLift, Azure PlayFab QoS e Valve A2S_INFO)

**Status:** Decisão aprovada pelo Dono do Produto (Luiz); em especificação técnica e implementação  
**Data:** 18 de setembro de 2026  
**Autores / Revisores:** Luiz (Dono do Produto), Marco (Produto), Iury (Rede), Rian (iOS)  
**Complementa:** `docs/01-funcional.md`, `docs/02-arquitetura.md`, `docs/03-especificacao-tecnica.md`, `docs/09-decisao-rede-piloto.md`, `docs/14-decisao-catalogo-remoto-debug.md`, `docs/16-decisao-selecao-regional-automatica.md`, `docs/26-decisao-catalogo-console.md`, `docs/28-decisao-servidores-testes-globais.md`

---

## 1. Contexto, Objetivos e Princípios Inegociáveis

Para viabilizar a expansão do catálogo do LagCheck e cobrir novos títulos multiplayer de grande relevância sem comprometer a viabilidade econômica do produto, o Dono do Produto (Luiz) aprovou o uso combinado de três infraestruturas de medição de **Custo Operacional Zero**.

Esta expansão segue três princípios inegociáveis:

1. **Custo Operacional Recorrente Zero:** Proibido provisionar servidores intermediários dedicados, VPSs ou instâncias pagas de ping. O tráfego de sondagem deve utilizar estritamente infraestruturas de rede públicas mantidas pelos próprios provedores de nuvem (hyperscalers) ou servidores de jogos dedicados abertos para consulta.
2. **Score Determinístico Baseado em Datagramas UDP Reais:** O score do LagCheck é calculado estritamente sobre pacotes UDP reais recebidos dentro do tempo-limite. Sem respostas UDP suficientes para atender à política estatística (`ProbeAcceptancePolicy`), o resultado é invariavelmente **Inconclusivo**. É terminantemente proibido simular scores, inventar medições ou utilizar fallbacks baseados em ICMP (ping de sistema operacional) ou conexões HTTP para jogos.
3. **Classificação de Precisão Transparente:**
   - **Beacons Regionais em Nuvem (AWS GameLift, Azure PlayFab):** Classificados como `genericRegion` / `regionalReference` com confiança `medium`. Medem a latência e a qualidade da rota entre o dispositivo e o datacenter regional do provedor, sem prometer tempo de resposta interno da engine do jogo.
   - **Servidores de Jogo Dedicados (Steam Query A2S_INFO):** Classificados como `dedicatedServer` (ou `gameInfrastructure`) com confiança `high`. Aferem diretamente a porta de serviço e a resposta do processo do servidor dedicado da comunidade.

---

## 2. Especificação Técnica dos Grupos de Protocolos

A arquitetura de medição é dividida em três grupos de protocolos, cada um adaptado às características da infraestrutura do jogo correspondente:

```
┌────────────────────────────────────────────────────────────────────────┐
│                         LagCheck Measurement Engine                    │
└───────────────────┬───────────────────┬───────────────────┬────────────┘
                    │                   │                   │
         [Grupo A: AWS GameLift] [Grupo B: PlayFab QoS] [Grupo C: Steam A2S]
                    │                   │                   │
               Porta 7770          Porta 3075          Porta 27015
              Eco Monotônico      Bit-Flip 0xFFFF     Challenge/Info
                    │                   │                   │
           genericRegion (AWS) genericRegion (Azure) dedicatedServer
```

---

### Grupo A: AWS GameLift UDP Ping Beacons (Porta 7770)

Homologado originalmente na Decisão 09 e expandido globalmente na Decisão 28, o AWS GameLift mantém endpoints públicos de UDP Ping Beacon em 21 regiões ao redor do mundo para permitir que jogos multiplayer selecionem a melhor região de matchmaking.

#### 1. Contrato de Rede e Datagrama
* **Protocolo:** UDP bidirecional.
* **Porta de Destino:** `7770`.
* **FQDN Padrão:** `gamelift-ping.<region-id>.api.aws` (ex.: `gamelift-ping.sa-east-1.api.aws`).
* **Taxa de Envio Máxima Permitida:** Teto AWS de 3 TPS (Transactions Per Second) por par IP/porta de origem. O LagCheck transmite 2 TPS no Quick Check (1 probe a cada 500 ms) e 1 TPS na pré-leitura regional, respeitando com folga o limite.

#### 2. Formato Binário do Datagrama LagCheck (`PingBeaconPayload`)
O cliente gera um payload determinístico de 33 bytes com identificador criptográfico de sessão:

| Offset (Bytes) | Tamanho | Campo | Tipo | Valor / Descrição |
| :--- | :--- | :--- | :--- | :--- |
| `0x00 - 0x03` | 4 bytes | `magic` | Raw Bytes | `0x4E 0x4C 0x50 0x47` (ASCII: `"NLPG"`) |
| `0x04` | 1 byte | `version` | UInt8 | `0x01` |
| `0x05 - 0x14` | 16 bytes | `sessionID` | UUID (128-bit) | Identificador criptográfico único da sessão de medição |
| `0x15 - 0x18` | 4 bytes | `sequence` | UInt32 (Big-Endian) | Índice sequencial da amostra (0 a 29) |
| `0x19 - 0x20` | 8 bytes | `nonce` | UInt64 (Big-Endian) | Entropia aleatória de alta segurança |

#### 3. Comportamento do Servidor e Validação
* O servidor AWS GameLift reflete **exatamente os mesmos bytes recebidos** de volta para o IP e porta de envio.
* **Critério de Validação:** O datagrama retornado deve ter exatamente 33 bytes e seu conteúdo deve ser binariamente idêntico ao payload transmitido (`response == payload`). Qualquer discrepância classifica a amostra como `invalidResponse`.
* **Timeout Individual:** 2.000 ms. Janela de drenagem total: 17 segundos (30 probes enviados ao longo de 15 segundos).

#### 4. Mapeamento de Jogos Compatíveis
Jogos que hospedam sua infraestrutura de sessões, servidores de matchmaking ou instâncias de partidas na AWS:
* **Fortnite** (Epic Games)
* **Rocket League** (Psyonix)
* **PUBG** e **PUBG MOBILE** (Krafton)
* **Apex Legends** (Respawn / EA)
* **Call of Duty: Warzone** e **CoD Mobile** (Activision)
* **New World** (Amazon Games)

#### 5. Classificação de Precisão
* `strategy`: `genericRegion`
* `confidence`: `medium`
* `precisionKey`: `regionalReference`
* **Apresentação em UI:** Rótulo da cidade/região limpo seguido do qualificador: `"<Cidade/Região> · região de referência"` (ex.: *"São Paulo · região de referência"* ou *"Virgínia do Norte · região de referência"*).

---

### Grupo B: Microsoft Azure PlayFab QoS Beacons (Porta 3075 UDP)

A Microsoft opera em escala global o serviço de **PlayFab Quality of Service (QoS) Beacons** em todas as zonas do Microsoft Azure que suportam servidores multiplayer (`Multiplayer Servers`). Essa infraestrutura permite medir com precisão a latência UDP até os datacenters do Azure com custo operacional zero.

#### 1. Contrato de Rede e Datagrama
* **Protocolo:** UDP bidirecional.
* **Porta de Destino:** `3075`.
* **Formato de Host / FQDN:** Endpoints regionais do Azure PlayFab (ex.: `*.cloudapp.azure.com` ou hosts regionais homologados pela Microsoft para títulos PlayFab).
* **Taxa de Envio:** 2 TPS no Quick Check (1 datagrama a cada 500 ms) e 1 TPS na pré-leitura.

#### 2. Formato Binário do Datagrama LagCheck (`PlayFabQoSPayload`)
O protocolo PlayFab exige estritamente que os **dois primeiros bytes** de qualquer datagrama de requisição sejam `0xFF 0xFF`. A partir do terceiro byte, o servidor preserva o conteúdo recebido. Definimos a estrutura canônica de 33 bytes do LagCheck para o PlayFab:

| Offset (Bytes) | Tamanho | Campo | Tipo | Valor / Descrição |
| :--- | :--- | :--- | :--- | :--- |
| `0x00 - 0x01` | 2 bytes | `playFabHeader` | Raw Bytes | `0xFF 0xFF` (Exigência do protocolo PlayFab QoS) |
| `0x02` | 1 byte | `magic` | UInt8 | `0x50` (ASCII: `'P'`) |
| `0x03` | 1 byte | `version` | UInt8 | `0x01` |
| `0x04 - 0x13` | 16 bytes | `sessionID` | UUID (128-bit) | Identificador criptográfico único da sessão |
| `0x14 - 0x17` | 4 bytes | `sequence` | UInt32 (Big-Endian) | Índice sequencial da amostra (0 a 29) |
| `0x18 - 0x1F` | 8 bytes | `nonce` | UInt64 (Big-Endian) | Entropia aleatória de 64 bits |
| `0x20` | 1 byte | `flags` | UInt8 | `0x00` (Reservado para extensões futuras) |

*Tamanho total da requisição:* **33 bytes**.

#### 3. Comportamento do Servidor e Regra do Bit-Flip
* **Comportamento do PlayFab:** O servidor do Azure PlayFab recebe o pacote na porta 3075, **inverte (flip) os dois primeiros bytes de `0xFF 0xFF` para `0x00 0x00`**, preserva integralmente os bytes subsequentes (offsets `0x02` a `0x20`) e envia o datagrama de resposta de volta ao remetente.
* **Critério de Validação do Codec (`PlayFabQoSPayloadCodec`):**
  1. `response.count == request.count` (exatamente 33 bytes).
  2. `response[0] == 0x00 && response[1] == 0x00` (cabeçalho invertido confirmado).
  3. `response.suffix(from: 2) == request.suffix(from: 2)` (eco perfeito da sessão, sequência e nonce).
  4. Caso o cabeçalho não venha invertido ou os bytes subsequentes não coincidam, o probe é descartado e classificado como `invalidResponse`.
* **Timeout Individual:** 2.000 ms. Janela de drenagem total: 17 segundos.

#### 4. Mapeamento de Jogos Compatíveis
Jogos que utilizam Microsoft Azure e PlayFab para matchmaking e servidores multiplayer:
* **Minecraft / Minecraft Bedrock** (Microsoft / Mojang — roda em Azure PlayFab)
* **Rainbow Six Siege** (Ubisoft — hospeda seus servidores dedicados e infraestrutura de matchmaking no Microsoft Azure)
* **Sea of Thieves** (Rare / Xbox Game Studios — Azure PlayFab)
* **Halo Infinite** (343 Industries / Xbox Game Studios — Azure)
* **Forza Horizon** e **Forza Motorsport** (Playground Games / Turn 10 — Azure PlayFab)

#### 5. Classificação de Precisão
* `strategy`: `genericRegion`
* `confidence`: `medium`
* `precisionKey`: `regionalReference`
* **Apresentação em UI:** `"<Cidade/Região> · região de referência"` (ex.: *"São Paulo (Azure) · região de referência"* ou *"Virgínia (Azure) · região de referência"*).

---

### Grupo C: Protocolo de Consulta UDP Aberto (Valve A2S_INFO / Steam Query - Porta 27015)

O protocolo **A2S_INFO** da Valve é o padrão global da indústria para consulta a servidores de jogos da Source Engine e jogos com servidores dedicados e da comunidade. Ele permite consultar a disponibilidade e latência do servidor real de jogo.

#### 1. Contrato de Rede e Datagrama
* **Protocolo:** UDP bidirecional.
* **Porta de Destino Padrão:** `27015` (ou porta de query especificada na configuração do servidor dedicado).
* **Taxa de Envio:** 2 TPS no Quick Check e 1 TPS na pré-leitura.

#### 2. Fluxo com Challenge Anti-Spoofing (Segurança Valve)
Para prevenir ataques de reflexão e amplificação distribuída (DDoS), os servidores Valve modernos implementam um mecanismo de **Challenge**:

```
Cliente (LagCheck)                                 Servidor Dedicado (A2S)
      │                                                      │
      │── 1. Query Inicial (25 bytes: Header + 'T' + String)─▶│
      │                                                      │
      │◀── 2. Challenge Response (9 bytes: Header + 'A' + Ch)─│
      │                                                      │
      │── 3. Query Autenticada (29 bytes: + Challenge)───────▶│
      │                                                      │
      │◀── 4. Resposta A2S_INFO (Header + 'I' + Server Data)──│
```

##### Passo 1: Query Inicial (Descoberta / Handshake)
* **Formato (25 bytes):**
  - Bytes 0-3: `0xFF 0xFF 0xFF 0xFF` (32-bit integer `-1`, indicando pacote indivisível / unfragmented).
  - Byte 4: `0x54` (ASCII: `'T'`, código de requisição `A2S_INFO`).
  - Bytes 5-24: `"Source Engine Query\0"` (20 bytes ASCII terminados em nulo).

##### Passo 2: Resposta de Challenge (`S2C_CHALLENGE`)
* Se o servidor exigir challenge (comportamento padrão moderno):
  - Bytes 0-3: `0xFF 0xFF 0xFF 0xFF`.
  - Byte 4: `0x41` (ASCII: `'A'`, identificador `S2C_CHALLENGE`).
  - Bytes 5-8: `challengeToken` (4 bytes UInt32 em Little-Endian).

##### Passo 3: Query Autenticada de Medição
* O cliente envia os 25 bytes originais acrescidos do token de 4 bytes obtido:
  - Bytes 0-3: `0xFF 0xFF 0xFF 0xFF`.
  - Byte 4: `0x54` (`'T'`).
  - Bytes 5-24: `"Source Engine Query\0"`.
  - Bytes 25-28: `challengeToken` (4 bytes UInt32 Little-Endian).
  - *Tamanho total:* **29 bytes**.

##### Passo 4: Resposta Válida do Servidor
* O servidor responde com o payload de informações:
  - Bytes 0-3: `0xFF 0xFF 0xFF 0xFF`.
  - Byte 4: `0x49` (ASCII: `'I'`, identificador de payload de informações do servidor).
  - Bytes subsequentes: Metadados do servidor (protocolo, nome, mapa, pasta do jogo, quantidade de jogadores, VAC, ambiente, etc.).

#### 3. Regra de Medição de RTT e Ledger para o LagCheck
* **Fase de Inicialização:** Antes de iniciar a janela formal de 30 probes, o transporte executa uma sondagem preliminar para obter o `challengeToken` do servidor dedicado. Uma vez obtido, o token é reutilizado nas requisições da sessão (os servidores Steam mantêm o challenge ativo para o mesmo IP de origem por vários minutos).
* **Cálculo da Amostra:**
  - Cada probe subsequente transmite o pacote de 29 bytes autenticado.
  - A recepção de um datagrama com cabeçalho `0xFF 0xFF 0xFF 0xFF` seguido de `0x49` ('I') dentro do prazo de 2.000 ms confirma o sucesso da amostra (`outcome: .received`) e calcula o RTT monotônico real: `(t_recebimento - t_envio)`.
  - Caso o servidor retorne novamente `0x41` ('A'), o token é atualizado dinamicamente.
  - Se o servidor responder diretamente com `0x49` já na primeira tentativa (servidores legados ou instâncias sem challenge ativado), a amostra é aceita imediatamente.
* **Proteção contra Amplificação:** O payload de envio é de 29 bytes e o payload retornado costuma ter entre 100 e 300 bytes. Como o LagCheck envia no máximo 2 TPS, a taxa de transferência é irrisória (< 1 KB/s), não caracterizando abuso de rede nem sobrecarga de servidor.

#### 4. Mapeamento de Jogos Compatíveis
Jogos compatíveis com servidores dedicados e da comunidade via Steam Query:
* **Rust** (Facepunch Studios)
* **Palworld** (Pocketpair)
* **ARK: Survival Evolved / Ascended** (Studio Wildcard)
* **Counter-Strike 2 Comunitário** (Valve / Servidores Comunitários de Treino e Campeonatos)

#### 5. Classificação de Precisão
* `strategy`: `dedicatedServer` (ou `gameInfrastructure`)
* `confidence`: `high`
* `precisionKey`: `dedicatedServer`
* **Apresentação em UI:** Rótulo do host ou servidor dedicado com qualificador explícito: `"<Nome do Servidor> · servidor dedicado"` (ex.: *"Servidor SP Community #1 · servidor dedicado"*).

---

## 3. Matriz Comparativa Consolidada

| Parâmetro | Grupo A: AWS GameLift | Grupo B: Azure PlayFab QoS | Grupo C: Valve Steam A2S_INFO |
| :--- | :--- | :--- | :--- |
| **Infraestrutura** | AWS GameLift Ping Beacons | Microsoft Azure PlayFab QoS | Servidores Dedicados Comunitários |
| **Porta UDP** | `7770` | `3075` | `27015` (ou porta de query do server) |
| **Tamanho da Requisição** | 33 bytes | 33 bytes | 25 bytes (initial) / 29 bytes (com challenge) |
| **Prefixo da Requisição** | `0x4E 0x4C 0x50 0x47 0x01` (`NLPG\1`) | `0xFF 0xFF` + `0x50 0x01` (`PF\1`) | `0xFF 0xFF 0xFF 0xFF` + `0x54` (`'T'`) |
| **Comportamento da Resposta** | Eco monotônico exato (33 bytes) | Bit-Flip nos primeiros 2 bytes (`0x00 0x00`) + Eco | `0x41` ('A' Challenge) ou `0x49` ('I' Info) |
| **Critério de Validação** | `response == request` | `resp[0..1] == 0x0000 && resp[2..] == req[2..]` | Header `0xFFFFFFFF` + Byte `0x49` |
| **Timeout por Probe** | 2.000 ms | 2.000 ms | 2.000 ms |
| **Janela Total (30 Probes)** | 17 segundos (15s envio + 2s dreno) | 17 segundos (15s envio + 2s dreno) | 17 segundos (15s envio + 2s dreno) |
| **Taxa de Envio** | 2 TPS (Quick Check) / 1 TPS (PreRead) | 2 TPS (Quick Check) / 1 TPS (PreRead) | 2 TPS (Quick Check) / 1 TPS (PreRead) |
| **Estratégia no Domínio** | `genericRegion` | `genericRegion` | `dedicatedServer` |
| **Confiança** | `medium` | `medium` | `high` |
| **Precision Key** | `regionalReference` | `regionalReference` | `dedicatedServer` |
| **Rótulo Visual de Rota** | `<Região> · região de referência` | `<Região> · região de referência` | `<Servidor> · servidor dedicado` |
| **Jogos Atendidos** | Fortnite, Rocket League, PUBG, Apex Legends, Warzone, New World | Minecraft, Rainbow Six Siege, Sea of Thieves, Halo Infinite, Forza | Rust, Palworld, ARK, CS2 Comunitário |

---

## 4. Arquitetura de Software e Codecs para o Cliente iOS

Para acomodar os novos protocolos sem violar os contratos de integridade de `NolaggyDomain` e `NolaggyInfrastructure`, a arquitetura deve ser modularizada conforme descrito abaixo.

### 4.1 Evolução em `NolaggyDomain`

1. **Expansão de `MeasurementStrategy` (`PilotCatalog.swift`):**
   ```swift
   public enum MeasurementStrategy: String, Codable, CaseIterable, Hashable, Sendable {
       case genericRegion
       case dedicatedServer
   }
   ```
2. **Expansão de `MeasurementConfidence` (`PilotCatalog.swift`):**
   ```swift
   public enum MeasurementConfidence: String, Codable, CaseIterable, Hashable, Sendable {
       case medium
       case high
   }
   ```
3. **Identificador de Protocolo de Transporte no Envelope do Catálogo:**
   O modelo `ProbeDestination` ou um novo atributo no contexto resolvido deve declarar o tipo de protocolo (`ProbeProtocolKind: .gameliftPing, .playfabQoS, .steamA2S`), permitindo ao transporte selecionar o codec correto em tempo de execução com base na porta ou declaração explícita.

### 4.2 Novos Codecs em `NolaggyInfrastructure`

Criação de codecs dedicados e isolados com validação pura (sem dependência de sockets de rede), viabilizando testes unitários determinísticos:

1. **`PingBeaconPayloadCodec` (Existente):** Mantido para AWS GameLift (porta 7770).
2. **`PlayFabQoSPayloadCodec` (Novo):**
   - Responsável por montar o payload com `0xFFFF`, injetar UUID de sessão, sequência e nonce.
   - Responsável por validar o bit-flip para `0x0000` e a igualdade dos 31 bytes restantes.
3. **`SteamQueryA2SPayloadCodec` (Novo):**
   - Responsável por codificar a query básica (25 bytes) e a query autenticada com challenge (29 bytes).
   - Responsável por decodificar as respostas `0x41` (Challenge) e `0x49` (Info payload).

### 4.3 Abstração do `ProbeLedger` e `NWConnectionMeasurementTransport`

O transporte `NWConnectionMeasurementTransport` deve ser generalizado para receber um despachante de codec baseado no tipo de protocolo do destino:
* Antes do envio, o gerador de payloads produz as tuplas `(sequence: Int, payload: Data)` usando o codec apropriado.
* O `ProbeLedger` recebe uma função ou delegate validador `isCorrelatedResponse(request: Data, response: Data) -> Bool` adaptado ao protocolo:
  - GameLift: `request == response`
  - PlayFab: `response.count == request.count && response.starts(with: [0x00, 0x00]) && response.dropFirst(2) == request.dropFirst(2)`
  - Steam A2S: `response.starts(with: [0xFF, 0xFF, 0xFF, 0xFF, 0x49])` (após challenge)

---

## 5. Próximos Passos e Especificação para Rian (iOS)

Rian implementará os componentes técnicos conforme o seguinte plano de trabalho:

### 1. Vetores de Teste Unitários Canônicos

#### Vetor 1: `PlayFabQoSPayloadCodecTests`
* **Entrada de Exemplo:**
  - `sessionID`: `00112233-4455-6677-8899-AABBCCDDEEFF`
  - `sequence`: `0x01020304`
  - `nonce`: `0x0102030405060708`
* **Bytes Gerados na Requisição (33 bytes):**
  ```
  0xFF, 0xFF, 0x50, 0x01,
  0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
  0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF,
  0x01, 0x02, 0x03, 0x04,
  0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
  0x00
  ```
* **Bytes Válidos da Resposta com Bit-Flip (33 bytes):**
  ```
  0x00, 0x00, 0x50, 0x01,
  0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
  0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF,
  0x01, 0x02, 0x03, 0x04,
  0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
  0x00
  ```
* **Casos de Teste:**
  1. `testEncodePlayFabPayloadMatchesExpected33Bytes`
  2. `testValidatePlayFabEchoSucceedsWithFlippedZeroHeader`
  3. `testValidatePlayFabEchoFailsIfHeaderIsNotFlipped` (ex.: se o servidor ecoar `0xFFFF` de volta)
  4. `testValidatePlayFabEchoFailsIfPayloadBodyIsTampered` (divergência de UUID, sequência ou nonce)

#### Vetor 2: `SteamQueryA2SPayloadCodecTests`
* **Requisição Inicial (25 bytes):**
  `[0xFF, 0xFF, 0xFF, 0xFF, 0x54, 0x53, 0x6F, 0x75, 0x72, 0x63, 0x65, 0x20, 0x45, 0x6E, 0x67, 0x69, 0x6E, 0x65, 0x20, 0x51, 0x75, 0x65, 0x72, 0x79, 0x00]`
* **Resposta de Challenge Simulada (9 bytes):**
  `[0xFF, 0xFF, 0xFF, 0xFF, 0x41, 0x78, 0x56, 0x34, 0x12]` (Challenge Token: `0x12345678`)
* **Requisição Autenticada com Challenge (29 bytes):**
  `[0xFF, 0xFF, 0xFF, 0xFF, 0x54, 0x53, 0x6F, 0x75, 0x72, 0x63, 0x65, 0x20, 0x45, 0x6E, 0x67, 0x69, 0x6E, 0x65, 0x20, 0x51, 0x75, 0x65, 0x72, 0x79, 0x00, 0x78, 0x56, 0x34, 0x12]`
* **Resposta Simulada A2S_INFO (Exemplo truncado com Header `0x49`):**
  `[0xFF, 0xFF, 0xFF, 0xFF, 0x49, 0x11, 0x52, 0x75, 0x73, 0x74, 0x20, 0x53, 0x65, 0x72, 0x76, 0x65, 0x72, 0x00, ...]`
* **Casos de Teste:**
  1. `testEncodeInitialA2SRequestProduces25BytesSourceEngineQuery`
  2. `testDecodeS2CChallengeExtracts4ByteLittleEndianToken`
  3. `testEncodeAuthenticatedA2SRequestAppendsChallengeToken`
  4. `testAcceptsValidA2SInfoResponseAndRejectsMalformedPackets`

### 2. Cronograma de Entregas
1. **Fase 1 (Domínio & Modelagem):** Atualização dos enums `MeasurementStrategy` e `MeasurementConfidence` em `NolaggyDomain`.
2. **Fase 2 (Codecs Puros em Infraestrutura):** Implementação de `PlayFabQoSPayloadCodec` e `SteamQueryA2SPayloadCodec` com testes unitários cobrindo 100% dos ramos de validação em `NolaggyInfrastructureTests`.
3. **Fase 3 (Integração de Transporte):** Adaptação do `NWConnectionMeasurementTransport` e `ProbeLedger` para despachar o validador correto conforme a porta e o protocolo da sessão de medição.
4. **Fase 4 (Validação Funcional em Testes de Integração):** Verificação de ponta a ponta garantindo que sessões incompletas resultam em status estritamente `inconclusive`, sem fallback simulado.
