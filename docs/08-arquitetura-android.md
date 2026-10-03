# LagCheck — Arquitetura e Especificação Técnica Android

> **Documento Canônico de Arquitetura Multiplataforma**  
> **Autores:** Camillo (Principal Engineer / Arquiteto), Iury (Network Systems), Marco (Product Lead)  
> **Referência:** Decisão 67 (`docs/DECISOES.md`) e Gate Arquitetural (`.agents/architecture-plan.md`)

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

O projeto adota uma arquitetura modular moderna e desacoplada em Gradle:

```
android/
├── build.gradle.kts
├── settings.gradle.kts
├── gradle/
│   └── libs.versions.toml             # Catálogo de dependências centralizado
├── core/
│   ├── domain/                        # Pure Kotlin (JVM) - Sem dependências de Android OS
│   │   ├── model/                     # GameReadinessVerdict, MetricSnapshot, RadioTelemetrySnapshot
│   │   └── rules/                     # Algoritmos determinísticos de score, thresholds e veredito
│   ├── network/                       # Motor UDP puro + STUN RFC 5389 + Jitter RFC 4737 + Bufferbloat
│   ├── telemetry-radio/               # Módulo Android: WifiManager, ConnectivityManager, TelephonyManager
│   └── designsystem/                  # Dark Competitive UI em Jetpack Compose (tokens LagCheck)
└── app/                               # Target executável Android
    ├── MainActivity.kt                # Entrada única
    └── ui/                            # Composição das telas (Home, Jogo, Check, Veredito)
```

---

## 3. Contrato de Domínio Puro (`:core:domain`)

O módulo `:core:domain` é estritamente independente de frameworks de UI, banco de dados ou do SDK do Android. Ele reproduz os mesmos tipos e algoritmos do `NolaggyDomain` (Swift):

- `GameReadinessVerdict`: `.READY`, `.CAUTION`, `.NOT_READY`, `.INCONCLUSIVE` (mínimo de 10 amostras UDP válidas; sem fallback para ping falso).
- `RadioTelemetrySnapshot`:
  - `WifiDetails`: Frequência (MHz), RSSI (dBm), Tx/Rx link speed (Mbps), Padrão (Wi-Fi 4/5/6/7).
  - `Gateway`: Endereço IP do gateway padrão.

---

## 4. O Módulo de Telemetria de Rádio (`:core:telemetry-radio`)

Responsável por extrair do sistema operacional as informações de telemetria sem invasão de privacidade e com degradação graciosa.

### Política de Permissões:
- **`ACCESS_NETWORK_STATE` & `ACCESS_WIFI_STATE`:** Permissões normais concedidas na instalação. Permitem verificar tipo de rede e métricas básicas de rádio.
- **`NEARBY_WIFI_DEVICES` (Android 13+):** Solicitada com a flag `neverForLocation` no `AndroidManifest.xml` para garantir que o app não rastreie localização geográfica do jogador.
- **Degradação Graciosa:** Se o usuário negar permissões opcionais, o LagCheck executa a medição de jogo normalmente via UDP e apenas omite o cartão de diagnóstico de rádio no veredito.

---

## 5. Integração com Backend e Custo Zero

O aplicativo Android consome exatamente a mesma infraestrutura Cloudflare Worker existente (`nolaggy-deep-check`):
- `GET /v1/catalog.json`: Catálogo de jogos e rotas assinado com Ed25519.
- `GET /v1/load`: Carga estática para estresse sob saturação de bufferbloat.
- `POST /v1/telemetry`: Telemetria de produto anônima (sem PII ou IP completo).

**Custo Operacional Recorrente Adicional:** **R$ 0,00**.

---

## 6. Design System em Jetpack Compose (`:core:designsystem`)

Em total conformidade com a Decisão 66 e o protótipo canônico:
- **Cor Primária de Ação:** Roxo Gamer (`#7C3AED`).
- **Cor de Atenção / Risco de Lag:** Coral Solar (`#FF5A36`).
- **Superfícies:** Fundo Profundo (`#0B0D10`), Superfície (`#15181E`), Painéis (`#1E232B`), Bordas 1px (`#262D38`).
- **Escala de Raios:** 8px, 13px, 17px (botão), 26px (bottom sheet) e 999px (chips/pills).
- **Tipografia:** Manchetes de veredito arredondadas e números de latência/jitter em monoespaçado estilo cockpit.
