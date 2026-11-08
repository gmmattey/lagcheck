# LagCheck — Arquitetura e Especificação Técnica Android

> **Documento Canônico de Arquitetura Multiplataforma**  
> **Autores:** Camillo (Principal Engineer / Arquiteto), Iury (Network Systems), Marco (Product Lead)  
> **Referência:** Decisões 67–69 (`docs/DECISOES.md`) e Gate Arquitetural (`.agents/architecture-plan.md`)

---

## 1. Visão Geral e Posicionamento Técnico

O LagCheck para Android expande a experiência do aplicativo mantendo 100% de paridade determinística de regras de negócio com o iOS, porém explorando uma vantagem técnica fundamental: **o acesso a dados de enlace físico e rádio expostos pelo Android OS que a Apple bloqueia na sandbox do iOS**.

### Vantagens Técnicas em Relação ao iOS:
1. **Frequência Real de Wi-Fi (`WifiInfo.getFrequency()`):** Permite detectar deterministicamente se o usuário está conectado em 2.4 GHz (2400–2500 MHz), 5 GHz (4900–5900 MHz) ou 6 GHz (5925–7125 MHz).
2. **Nível de Sinal em dBm (`WifiInfo.getRssi()`):** Fornece a atenuação física real do sinal sem abstrações vagas de "3 barrinhas".
3. **Velocidade de Link PHY Tx/Rx (`WifiInfo.getTxLinkSpeedMbps()` / `getRxLinkSpeedMbps()`):** Permite identificar quedas drásticas de negociação de camada física provocadas por barreiras físicas ou interferências transitórias.
4. **Descoberta Nativa de Gateway (`LinkProperties.getRoutes()`):** Identifica o roteador de saída real sem risco de assumir `.1` (conformidade estrita com a Decisão 50).

---

## 2. Estrutura Modular do Projeto Android (`android/`)

Arquitetura modular em Gradle. Os módulos JVM não importam Android SDK e são testados em qualquer máquina (`./gradlew :core:domain:test :core:catalog:test :core:network:test :core:session:test`).

```
android/
├── core/
│   ├── domain/          JVM puro. QualityEvaluator (3 perfis), SampleQuality, SpikePattern, DeepCheck (carga v2),
│   │                    ResultInterpreter, GameReadinessEvaluator readiness-v2.0, ReadinessPresenter (PT-BR/EN/ES).
│   ├── catalog/         JVM puro. Ed25519 (RFC 8032, verify-only), envelope v3 assinado, validação, resolução de rota,
│   │                    repositório com base embarcada + cache + refresh diário.
│   ├── network/         JVM. Codecs GameLift/PlayFab/Steam A2S, ProbeLedger, UdpProbeTransport,
│   │                    cliente do Worker (catálogo, carga, telemetria). STUN fica só como codec legado (NAT, fase 2).
│   ├── session/         JVM. CheckOrchestrator (repouso → carga → veredito), MeasurementPlanner, TelemetryReporter.
│   ├── telemetry-radio/ Android SDK: WifiManager, ConnectivityManager (o diferencial Android).
│   └── designsystem/    Jetpack Compose: tokens Dark Competitive UI.
└── app/                 Composição (Compose). ViewModel fino sobre :core:session.
```
Dependência: `domain ← catalog ← network ← session ← app`.

O widget Android autorizado pela Decisão 88 será uma superfície de apresentação dentro de `:app` (provider/Glance ou equivalente nativo), sem transportar regras de rede para fora de `:core:session`. Ele lerá somente um snapshot privado gerado pelo app após Check válido: contexto para repetir a medição, valores observados e miniatura editorial da fonte oficial Android (`RemoteArtworkRepository` ou resource embarcado). Não usa App Group iOS, captura iOS, URL externa no render, Worker novo ou fetch em background; ao toque, entrega `gameId` e contexto ao `MainActivity`, que revalida catálogo e inicia o Check normal.

## 3. Paridade com o iOS (Decisão 68)

O Kotlin é port do Swift, não reinterpretação. A fonte de verdade é `Sources/NolaggyDomain` e o catálogo v3 assinado.

- **Regras:** `pilot-2026.09.08.1`, `mobile-realtime-2026.09.08.1`, `casual-realtime-2026.09.08.1`, `readiness-v2.0`, `spike-pattern-v1`, `sample-quality-v1`, `deep-load-impact-v2`. Os testes JVM carregam os vetores dos testes Swift.
- **Veredito:** `READY`, `CAUTION`, `NOT_READY`, `INCONCLUSIVE`. Menos de 10 respostas UDP válidas é inconclusivo, sem fallback HTTP/ICMP e sem nota inventada.
- **Medição:** repouso (30 probes, 1 a cada 500 ms, fechamento em 17 s) e depois carga (30 probes com `GET /v1/load` concorrente). O veredito avalia o repouso e penaliza a degradação sob carga. Conexão que morre no meio cancela a sessão por integridade.
- **Destino:** o do catálogo assinado (`gameLiftPing`, `playFabQoS`, `steamA2S`). Hoje todas as rotas ativas são `awsFallback` em `sa-east-1`, com confiança média. Rotas `gameOwned` pendentes nunca são medidas. Rota própria Steam A2S ativa só vence após a pré-validação de identidade (`SteamA2sRoutePreflight`, contrato `steam-a2s-preflight-1`, vetores em `Tests/Vectors/`); qualquer falha volta à referência AWS assinada. Nenhuma rota própria está ativa no catálogo atual.
- **Plataforma:** o catálogo v3 só publica `iphone|playstation|xbox|pc|nintendo`. O celular Android usa o contexto `iphone` (mesmas rotas) até o catálogo ganhar `android`.
- **Fase 2 (implementada):** banda Wi-Fi (frequência real do Android), qualidade de voz, NAT/STUN (CGNAT e NAT duplo), probe de gateway por DNS/UDP, recomendações por evidência e EN/ES. O gateway é medido, exibido e **entra no veredito** (Decisão 69; o iOS não usa o gateway no veredito, então pode haver divergência entre plataformas; reverter é o default de `LocalDiagnostics.gatewayInfluencesVerdict`). Sem resposta do roteador = não observável, nunca acusa o Wi-Fi. Recomendação sobre rota ou operadora só com primeiro salto comprovadamente limpo (Decisão 50).
- **Decisão 69:** status das redes de console (PSN/Xbox/Nintendo, direto nos endpoints públicos, fail-open, aviso na Home), favoritos locais e relatório em PDF (`PdfDocument`, conteúdo em `RouteReport`).
- **Fora do port:** Connection Booster (Gemini com chave embutida: fere custo zero e segurança).
- **Cockpit:** mostra só o que foi medido. Campo sem leitura aparece como "—". Nunca há valor padrão (o protótipo antigo exibia NAT, UPnP, voz e gateway `192.168.1.1` que ninguém medira).
- **Idiomas:** PT-BR, EN e ES. Textos de tela passam por `tr("texto em PT-BR")` e um teste varre o app exigindo tradução para cada um (`UiStringsCompletenessTest`).

## 4. O Módulo de Telemetria de Rádio (`:core:telemetry-radio`)

Extrai do sistema operacional frequência, RSSI e velocidade de enlace sem invadir privacidade, com degradação graciosa.

### Política de permissões
- **`ACCESS_NETWORK_STATE` e `ACCESS_WIFI_STATE`:** normais, concedidas na instalação.
- **`NEARBY_WIFI_DEVICES` (Android 13+):** declarada com `neverForLocation`.
- **`ACCESS_FINE_LOCATION`:** declarada só até a API 32 (`maxSdkVersion="32"`), onde o Wi-Fi exige localização. O app não a solicita ativamente.
- **Degradação graciosa:** sem permissão opcional, a medição UDP roda normalmente e o app apenas omite os fatos de rádio.

## 5. Integração com o Worker e custo zero

Um único Cloudflare Worker (`nolaggy-deep-check`), sem endpoint novo (hosts iguais aos do iOS):
- `assets/catalog-base.json`: envelope Ed25519 local, byte-idêntico à base do iOS, validado antes do uso. Não há atualização HTTP nem cache em arquivo.
- `GET /v1/load`: carga de download, no máximo 10 MiB ou 15 s.
- `POST /v1/telemetry`: funil anônimo `app_open`, `check_started`, `verdict_viewed`, `retest_started`. O Worker não aceita `android` nem `nintendo` em `platform`, então para celular o campo é omitido.

**Custo operacional recorrente adicional:** R$ 0,00. Sem SDK de terceiros.

## 6. Design System em Jetpack Compose (`:core:designsystem`)

Em total conformidade com a Decisão 66 e o protótipo canônico:
- **Cor Primária de Ação:** Roxo Gamer (`#7C3AED`).
- **Cor de Atenção / Risco de Lag:** Coral Solar (`#FF5A36`).
- **Superfícies:** Fundo Profundo (`#0B0D10`), Superfície (`#15181E`), Painéis (`#1E232B`), Bordas 1px (`#262D38`).
- **Escala de Raios:** 8px, 13px, 17px (botão), 26px (bottom sheet) e 999px (chips/pills).
- **Tipografia:** Manchetes de veredito arredondadas e números de latência/jitter em monoespaçado estilo cockpit.

## 7. Evidência posterior ao port (2026-10-03)

A [auditoria de paridade com o código iOS](auditorias/android-ios-code-parity-2026-10-03.md) registra o acompanhamento posterior às Decisões 68–69: build Debug e testes locais aprovados, navegação e estados revisados, percentis opcionais no Histórico com leitura retrocompatível e capturas no emulador. O cockpit tem atualização manual e casos de uso com motivo e limite; a exportação PDF foi exercitada no emulador.

Os estados “sem build AGP e sem aparelho” das decisões são registros históricos da entrega inicial. A evidência posterior de build e emulador não fecha os gates físicos: UDP real, troca de rede, cancelamento da resolução DNS, gateway/NAT, PDF em aparelho e comparação renderizada com iPhone continuam pendentes conforme a auditoria. Nenhuma distribuição ou publicação Android é comprovada por esses resultados.
