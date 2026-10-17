# LagCheck — Ficha e Configuração Oficial: Apple App Store

Documento canônico contendo todos os metadados, regras de preenchimento e instruções de cadastro no **App Store Connect** e **Apple Developer Portal**.

---

## 1. Dados Técnicos de Registro (Apple Developer Portal & App Store Connect)

| Campo | Valor Exato | Observações |
| :--- | :--- | :--- |
| **Nome da Ficha** | `LagCheck: Rota Gamer` | 20 / 30 caracteres. |
| **Plataformas** | `iOS` | iPhone (iOS 17+). |
| **Idioma Principal** | `Português (Brasil)` | Primary Language padrão. |
| **Bundle ID** | `com.lagcheck.app` | Registrado em *Certificates, Identifiers & Profiles*. |
| **SKU** | `com.lagcheck.app` | Identificador interno único de catálogo. |
| **Acesso de Usuário** | `Acesso Total` | Full Access. |
| **Categoria Primária** | `Utilitários` (Utilities) | Enquadramento técnico correto. |
| **Categoria Secundária** | `Jogos` (Games) ou `Entretenimento` | Contexto de uso. |
| **Classificação Etária** | `4+` (Sem restrições) | Sem conteúdo adulto, apostas ou violência. |
| **URL de Suporte** | `https://lagcheck.signallq.com/support` | E-mail: `suporte@signallq.com`. |
| **URL de Privacidade** | `https://lagcheck.signallq.com/privacy` | Obrigatória para submissão. |

---

## 2. Metadados — Português (Brasil) [pt-BR]

### Nome do App (20 / 30 car.)
```text
LagCheck: Rota Gamer
```

### Subtítulo (22 / 30 car.)
```text
Sua conexão tá pronta?
```

### Palavras-chave / Keywords (85 / 100 car.)
> **Regra:** Separadas apenas por vírgula, sem espaços, sem palavras do Nome/Subtítulo.
```text
latência,jitter,perda,bufferbloat,wifi,rede,conexão,teste,online,estabilidade,partida
```

### Texto Promocional (151 / 170 car.)
```text
Veja como a rota está antes da partida: latência, jitter e perda em uma infraestrutura de referência. Sem nota inventada quando faltam dados.
```

### Descrição Completa (pt-BR)
```text
Sua internet pode ter 500 Mega para baixar filmes, mas oscilar e travar no meio da trocação de tiro na ranked. O LagCheck responde em poucos segundos a única pergunta que importa: sua rota está pronta para jogar agora?

Velocidade de download não ganha jogo. O que define a sua partida online é a estabilidade dos pacotes UDP: latência média (ping), variação de milissegundos (jitter) e pacotes descartados pelo caminho (packet loss).

O LagCheck mede a rota do seu iPhone até uma infraestrutura de referência. Não é o ping oficial de um jogo; para console ou PC, a leitura é uma estimativa da conexão no mesmo ambiente. Nada de ping de navegador via HTTP ou notas inventadas.

POR QUE O LAGCHECK É DIFERENTE?
• Veredito Direto: Sem gráficos confusos ou textão na hora da partida. Você recebe um veredito claro e instantâneo: "Pronto para Ranked", "Evitaria Ranked Agora" ou "Condições Instáveis".
• Teste de Rota Real sob Carga: Mede o repouso e simula o tráfego concorrente da sua casa para identificar bufferbloat (quando o ping explode se alguém abre um vídeo na rede).
• Leitura para o Squad: Gere em 1 toque um card com a leitura daquela sessão para Discord e WhatsApp.
• Diagnóstico Honesto: Mostra sintomas observados sem prometer milagres ou acusar Wi-Fi, operadora ou servidor sem evidência isolada.
• Modo Console e PC: Meça a rota pelo iPhone e estime o comportamento para seu videogame ou computador no mesmo cômodo.

TRANSPARÊNCIA TOTAL
• Zero anúncios invasivos bloqueando seu teste.
• Sem cadastro ou login. A telemetria mínima de produto é pseudônima e não inclui nome, e-mail, histórico de navegação, amostras brutas de rede, SSID, BSSID, IDFA ou localização.
• Medição determinística: se a rede estiver instável demais para garantir precisão, o resultado é inconclusivo — nunca uma nota enganosa.

Antes de dar ready na fila competitiva, faça o LagCheck.
```

---

## 3. Metadados — Inglês (EUA / Global) [en-US]

### App Name (21 / 30 car.)
```text
LagCheck: Gamer Route
```

### Subtitle (24 / 30 car.)
```text
Is your connection ready?
```

### Keywords (90 / 100 car.)
```text
latency,jitter,loss,bufferbloat,network,wifi,connection,test,online,stability,match,packet
```

### Promotional Text (133 / 170 car.)
```text
See how your route looks before you queue: latency, jitter, and packet loss to reference infrastructure. No made-up score when data is insufficient.
```

### Full Description (en-US)
```text
Your internet might have 500 Mbps for video streaming, but still spike and stutter during a critical clutch in ranked. LagCheck answers the only question that matters: is your route ready to play right now?

Download bandwidth doesn't win games. What actually dictates your match is real-time UDP packet stability: ping latency, millisecond jitter, and route packet loss.

LagCheck measures your route from your iPhone to reference infrastructure. It isn’t an official game-server ping; for console or PC, it is an estimate of the connection in the same environment. No browser HTTP ping, no arbitrary guesswork.

WHY LAGCHECK IS DIFFERENT:
• Instant Semantic Verdict: No confusing graphs or textbooks when you are in the lobby. Get a clear recommendation in seconds: "Ready for Ranked", "Avoid Ranked Right Now", or "Unstable Route Conditions".
• Loaded Route Benchmark (Bufferbloat): Measures resting ping and simulates concurrent household traffic to expose bufferbloat spikes before you enter the queue.
• Squad Reading Card: Export a card with that session’s reading for Discord and WhatsApp in one tap.
• Honest Diagnostics: Show observed symptoms without blaming Wi-Fi, an ISP, or a server without isolated evidence.
• Console & PC Estimator: Benchmark the route room-by-room on your iPhone to gauge latency before turning on your console or PC rig.

PRIVACY & INTEGRITY:
• Zero intrusive ads interrupting your benchmarks.
• No account or login. Minimal product telemetry is pseudonymous and excludes name, email, browsing history, raw network samples, SSID, BSSID, IDFA, and location.
• Deterministic precision: if network conditions are insufficient for scientific confidence, we declare the test inconclusive rather than faking a score.

Before you queue for competitive matches, run LagCheck.
```

---

## 4. Diretrizes de Screenshots (6.7" / 6.5" / 5.5")

| # | Título Superior | Subtítulo Inferior | Tela em Destaque |
| :-: | :--- | :--- | :--- |
| **1** | **PRONTO PARA RANKED?** | Veredito instantâneo e honesto antes da partida. | Tela de Veredito com badge `● PRONTO PARA RANKED`. |
| **2** | **TESTE REAL DE LATÊNCIA UDP** | Ping, jitter e rota sob carga sem mentiras de speedtest. | Trilha ao vivo das 3 fases de medição. |
| **3** | **PROVE PARA A CALL NO DISCORD** | Card oficial de rota gerado em 1 toque para o squad. | Card Discord estilizado em Dark Competitive UI. |
| **4** | **DESCUBRA ONDE ESTÁ O GARGALO** | Enlace local de Wi-Fi, CGNAT/NAT e estabilidade externa. | Cockpit de Telemetria com detecções de rede. |
| **5** | **AVALIE A ROTA POR JOGO** | Selecione seu destino com estimativa para PC e Console. | Grid de seleção de jogos em Dark UI limpa. |

---

## 5. Rótulos de Privacidade (App Privacy Nutrition Labels)

Rascunho a conferir no build de distribuição antes de preencher o App Store Connect:

- **Dados coletados:** `User ID` pseudônimo por instalação e `Product Interaction` (evento de produto; jogo, plataforma e classe de veredito quando aplicáveis), ambos para **Analytics**, não vinculados à identidade e sem tracking.
- **Não enviados no payload:** nome, e-mail, telefone, histórico de navegação, amostras brutas de rede, SSID, BSSID, IDFA ou localização.
- **Transporte:** o app não envia IP no payload; metadados de rede necessários à entrega e proteção da solicitação podem ser processados pela infraestrutura.
- **Rastreamento:** não. A declaração no Console deve refletir também qualquer SDK presente no arquivo distribuído.
