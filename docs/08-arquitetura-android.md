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

## 2. Estrutura Modular do Projeto Android (`apps/android/`)

Arquitetura modular em Gradle + Kotlin Multiplatform (`core:domain`). Os módulos sem dependência do Android SDK são testados diretamente (`./gradlew :core:domain:allTests :core:catalog:test :core:network:test :core:session:test`).

```
apps/android/
├── core/
│   ├── domain/          KMP (JVM + iOS XCFramework + JS). Única implementação de score, veredito readiness-v3.0,
│   │                    SampleQuality v2, SpikePattern v2, DeepCheck carga v4, UseCases v1 e StabilitySummary v1.
│   ├── catalog/         JVM puro. Envelope v3 embarcado sem assinatura (Decisão 106) + refresh opcional em cache.
│   ├── network/         JVM. Codecs GameLift/PlayFab/Steam A2S, ProbeLedger, UdpProbeTransport, cliente do Worker.
│   ├── session/         JVM. CheckOrchestrator (60 probes repouso + 60 probes carga contínua), MeasurementPlanner, TelemetryReporter.
│   ├── telemetry-radio/ Android SDK: WifiManager, ConnectivityManager (o diferencial Android).
│   └── designsystem/    Jetpack Compose: tokens Dark Competitive UI, Barlow/Chakra Petch e RouteMeasurementMap.
├── app/                 Composição (Compose). ViewModel fino sobre :core:session, AdMob/UMP e Glance Widget.
├── engine-host/         Host JVM NDJSON consumido pelo cliente Windows WinUI 3 (Decisão 119).
└── desktop/             Protótipo histórico Compose Desktop (Decisões 114–116).
```
Dependência: `domain ← catalog ← network ← session ← app`.

O widget Android autorizado pela Decisão 88 usa Glance dentro de `:app`, sem transportar regras de rede para fora de `:core:session`. Ele lê somente um snapshot privado gerado pelo app após Check válido e, ao toque, entrega `gameId` e contexto ao `MainActivity`, que revalida catálogo e inicia o Check normal.

## 3. Paridade Única via KMP (Decisões 68, 134–136 e 143)

O módulo `apps/android/core/domain` (`LagCheckEngine`, ver `ENGINE_CONTRACT.md`) é a fonte única de verdade de todas as regras para Android, iOS (`LagCheckEngine.xcframework` encapsulado por `NolaggyDomain`), Windows (`engine-host`) e site (pacote JS).

- **Regras:** `pilot-2026.11.14.1`, `mobile-realtime-2026.11.14.1`, `casual-realtime-2026.11.14.1`, `readiness-v3.0`, `spike-pattern-v2`, `sample-quality-v2`, `deep-load-impact-v4`, `recommendations-v2` e `stability-summary-v1`. Vetores normativos rodam nos três alvos via `:core:domain:allTests`.
- **Veredito:** `READY`, `CAUTION`, `NOT_READY`, `INCONCLUSIVE`. Menos de 20 respostas UDP válidas por fase é inconclusivo, sem fallback HTTP/ICMP e sem nota inventada (Decisão 135).
- **Medição:** repouso (60 probes, 1 a cada 500 ms, ~30 s) e carga contínua (60 probes com downloads paralelos `/v1/load` até 60 MB no Wi-Fi ou 10 MB no celular, ~64 s no total). O veredito avalia o repouso e penaliza a degradação sob carga. Conexão que morre no meio cancela a sessão por integridade.
- **Destino:** catálogo embarcado de 54 jogos com refresh opcional validado (`catalog-v3.json`, `ETag`), rotas `gameLiftPing`, `playFabQoS`, `steamA2S` e pré-leitura regional automática (`RouteMeasurementMap` + `/v1/approx-location`).
- **Gateway e rádio:** gateway medido e exibido; sem resposta do roteador = `UNOBSERVABLE`, nunca acusa Wi-Fi ou operadora sem gateway comprovadamente estável.
- **Idiomas:** PT-BR, EN e ES via `UiStrings.kt` (`tr(...)`) com teste de completude (`UiStringsCompletenessTest`).

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

Em conformidade com `shared/design-system/DESIGN.md` e as Decisões 66, 125–128 e 143–145:
- **Cor Primária de Ação:** Roxo Gamer (`#7C3AED`), restrito ao CTA principal.
- **Cor de Atenção / Risco de Lag:** Coral Solar (`#FF5A36`).
- **Superfícies sem contorno:** Fundo Profundo (`#0B0D10`), Superfície (`#15181E`), Painéis (`#1E232B`), separação por contraste tonal sem bordas em cards, campos de busca, pílulas ou anúncios (Decisão 128).
- **Escala de Raios:** `4 dp` (`xs`), `8 dp` (`sm` mídia/métricas), `12 dp` (`md`/`lg` busca, cards e CTAs — Decisão 126), `26 dp` (`xl` sheet) e `999 dp` (`pill` status e tab bar flutuante).
- **Tipografia:** Tríade unificada **Barlow Semi Condensed** (títulos de tela sempre em caixa alta e vereditos), **Barlow** (corpo, controles e navegação inferior) e **Chakra Petch** com algarismos tabulares `tnum` (score, métricas e kickers — Decisão 125).

## 7. Evidência posterior ao port (2026-10-03)

A [auditoria de paridade com o código iOS](auditorias/android-ios-code-parity-2026-10-03.md) registra o acompanhamento posterior às Decisões 68–69: build Debug e testes locais aprovados, navegação e estados revisados, percentis opcionais no Histórico com leitura retrocompatível e capturas no emulador. O cockpit tem atualização manual e casos de uso com motivo e limite; a exportação PDF foi exercitada no emulador.

Os estados “sem build AGP e sem aparelho” das decisões são registros históricos da entrega inicial. A evidência posterior de build e emulador não fecha os gates físicos: UDP real, troca de rede, cancelamento da resolução DNS, gateway/NAT, PDF em aparelho e comparação renderizada com iPhone continuam pendentes conforme a auditoria. Nenhuma distribuição ou publicação Android é comprovada por esses resultados.
