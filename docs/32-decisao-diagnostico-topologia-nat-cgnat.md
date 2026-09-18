# LagCheck — Decisão 32: Diagnóstico de Topologia de Rede Multiplayer a Custo Zero (Tipo de NAT, CGNAT e Duplo NAT via STUN RFC 5389)

**Status:** Decisão aprovada pelo Dono do Produto (Luiz); em especificação técnica e implementação  
**Data:** 18 de setembro de 2026  
**Autores / Revisores:** Luiz (Dono do Produto), Marco (Produto), Iury (Rede), Rian (iOS), Renan (Design)  
**Complementa:** `docs/01-funcional.md`, `docs/02-arquitetura.md`, `docs/03-especificacao-tecnica.md`, `docs/07-voz-do-produto.md`, `docs/23-decisao-dicas-conexao-gemini-deep-check.md`, `docs/27-decisao-diagnostico-frequencia-wifi.md`, `docs/29-decisao-infraestrutura-medicao-custo-zero.md`

---

## 1. Contexto e Problema de Produto (Marco)

Um dos problemas mais comuns e frustrantes enfrentados por jogadores de console e mobile é o bloqueio ou degradação da experiência multiplayer devido à **topologia de NAT da rede local ou do provedor de internet (ISP)**.

Muitas vezes, a latência do jogador está excelente (ex.: 20 ms) e a perda de pacotes é 0%, mas ele se depara com:
- Impossibilidade de entrar em salas multiplayer P2P (Call of Duty, FIFA, GTA Online, Smash Bros);
- Falhas de conexão em bate-papo de voz (party da PlayStation Network, Xbox Live ou Discord);
- Erros crônicos de matchmaking e desconexões no início da partida.

As causas raízes dessa frustração são:
1. **NAT Estrito (Tipo 3 / Simétrico):** O roteador altera a porta externa para cada destino diferente e bloqueia conexões de entrada sem convite prévio, impossibilitando a comunicação direta entre jogadores.
2. **NAT Duplo (Double NAT):** Presença de dois roteadores em cascata realizando tradução de endereços (ex.: modem/ONT da operadora conectado a um roteador Wi-Fi mesh sem modo bridge ativo), gerando tradução redundante e quebra de UPnP.
3. **CGNAT da Operadora (Carrier-Grade NAT — RFC 6598):** O provedor de banda larga não fornece um endereço IPv4 público dinâmico ao assinante, alocando um IP compartilhado do bloco `100.64.0.0/10`. Nesse cenário, o jogador não consegue abrir portas nem obter NAT Aberto/Moderado em IPv4.

---

## 2. Engenharia de Rede: Sondagem STUN a Custo Zero (Iury)

Para diagnosticar a topologia de NAT sem violar o sandbox restrito do iOS e **sem nenhum custo operacional recorrente**, o LagCheck adota o protocolo padronizado da IETF **STUN (Session Traversal Utilities for NAT — RFC 5389 / RFC 8489)**.

### A. Infraestrutura Pública Gratuita de Alta Disponibilidade
O diagnóstico utiliza endpoints públicos mantidos globalmente pela indústria de telecomunicações e hyperscalers:
- Endpoint Primário: `stun.l.google.com:19302` (Google Cloud STUN, UDP, latência global < 20 ms via Anycast)
- Endpoint Secundário (Fallback): `stun1.l.google.com:19302` / `stun.cloudflare.com:3478`

### B. Formato Binário do Datagrama STUN (RFC 5389)
O cliente transmite um datagrama UDP de 20 bytes:

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|0 0|     STUN Message Type     |         Message Length        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                         Magic Cookie                          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
|                     Transaction ID (96 bits)                  |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

1. **Header STUN (20 bytes):**
   - `Message Type`: `0x0001` (Binding Request).
   - `Message Length`: `0x0000` (sem atributos no envio).
   - `Magic Cookie`: `0x2112A442` (constante fixa da RFC 5389).
   - `Transaction ID`: 12 bytes criptograficamente aleatórios.
2. **Resposta do Servidor (`Binding Response` — 0x0101):**
   - O servidor STUN inspeciona o datagrama UDP recebido e empacota no payload o atributo **`XOR-MAPPED-ADDRESS` (Type `0x0020`)**.
   - Esse atributo contém a **porta externa** e o **endereço IP público** através do qual a internet enxerga o iPhone.

---

## 3. Heurística Determinística de Classificação de Topologia

O algoritmo de avaliação correlaciona o IP local da interface ativa (`en0`), o IP retornado pelo STUN e a estabilidade da porta:

```
┌────────────────────────────────────────────────────────────────────────┐
│                   Heurística de Topologia de Rede                      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                         Datagrama STUN (RFC 5389)
                                    │
           ┌────────────────────────┴────────────────────────┐
           ▼                                                 ▼
   IP Público Retornado                             Porta Externa Mapeada
           │                                                 │
           ├─ Pertence a 100.64.0.0/10?                      ├─ Mapeamento Estável?
           │  └─► SIM: CGNAT Confirmado                      │  └─► NAT Tipo 2 (Moderado)
           │                                                 │
           ├─ Coincide com IP da interface local?            ├─ Porta Varia por Destino?
           │  └─► SIM: NAT Tipo 1 (Aberto)                   │  └─► NAT Tipo 3 (Estrito)
           │                                                 │
           └─ Dois saltos privados detectados?               └─ Timeout / Sem Resposta?
              └─► SIM: NAT Duplo Confirmado                     └─► Inconclusivo
```

### Classificação Gamers:
1. **NAT Tipo 1 (Aberto):** Sem restrições de encaminhamento; conexão ideal para ser host de salas e grupos de voz.
2. **NAT Tipo 2 (Moderado):** Presença de roteador único com UPnP ou mapeamento de portas ativo; experiência multiplayer plena com a maioria dos jogadores.
3. **NAT Tipo 3 (Estrito):** Bloqueio de portas de entrada; incapaz de conectar diretamente com outros jogadores com NAT Moderado ou Estrito.
4. **Alerta de CGNAT:** Informa ao jogador que o provedor não disponibilizou IP público IPv4.
5. **Alerta de NAT Duplo:** Informa que dois roteadores estão em conflito de tradução na residência.

---

## 4. Modelagem de Software no iOS (Rian)

### Módulo `NolaggyDomain`:
```swift
public enum NATType: String, Codable, Equatable, Sendable {
    case type1Open = "type_1_open"
    case type2Moderate = "type_2_moderate"
    case type3Strict = "type_3_strict"
    case inconclusive = "inconclusive"
}

public enum CGNATStatus: String, Codable, Equatable, Sendable {
    case notDetected = "not_detected"
    case detected = "detected"
    case inconclusive = "inconclusive"
}

public enum DoubleNATStatus: String, Codable, Equatable, Sendable {
    case notDetected = "not_detected"
    case suspectOrDetected = "suspect_detected"
    case inconclusive = "inconclusive"
}

public struct NATTopologySnapshot: Codable, Equatable, Sendable {
    public let natType: NATType
    public let cgnatStatus: CGNATStatus
    public let doubleNATStatus: DoubleNATStatus
    public let publicIPMasked: String?
    public let localIPMasked: String?
    public let externalPort: UInt16?
}
```

### Módulo `NolaggyInfrastructure`:
- `StunProbeClient`: Gerencia a conexão `NWConnection` UDP para o host STUN com timeout de 2.000 ms e decodifica o buffer de bytes conforme RFC 5389.

---

## 5. Experiência de Usuário e Voz do Produto (Renan & Marco)

Seguindo `docs/07-voz-do-produto.md`, o LagCheck não utiliza termos alarmistas nem acusações genéricas contra a operadora. O tom é calmo, técnico e orientador:

1. **Card de Status de Conexão na Home (`HomeNetworkStatusCard`):**
   - Exibição do tipo de NAT detectado com badge discreto (`NAT Aberto`, `NAT Moderado` ou `NAT Estrito`).
2. **Resultado de Diagnóstico (`GameDetailView` & `DeepCheckResultView`):**
   - Quando NAT Estrito, NAT Duplo ou CGNAT forem detectados, exibe banner informativo contextualizado para jogos multiplayer:
     - *"NAT Estrito detectado. Isso pode dificultar a entrada em grupos de voz e partidas multiplayer no PlayStation/Xbox."*
3. **Checklist Acionável no `ConnectionBoosterSheet`:**
   - Para **NAT Duplo**: *"Configure o segundo roteador no modo Ponto de Acesso (Bridge) para unificar a rede."*
   - Para **CGNAT**: *"Sua conexão usa CGNAT. Entre em contato com seu provedor e solicite suporte a IPv6 ou ativação de IP público para jogos."*
   - Para **NAT Estrito**: *"Ative o UPnP nas configurações do seu roteador para liberar portas automaticamente."*
