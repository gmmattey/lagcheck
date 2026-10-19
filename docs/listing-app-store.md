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
| **URL de Suporte** | `https://lagcheck.signallq.com/support/` | E-mail: `suporte@signallq.com`. |
| **URL de Privacidade** | `https://lagcheck.signallq.com/privacy/` | Obrigatória para submissão. |

---

## 2. Metadados — Português (Brasil) [pt-BR]

### Nome do App (20 / 30 car.)
```text
LagCheck: Rota Gamer
```

### Subtítulo (23 / 30 car.)
```text
Conexão antes da ranked
```

### Palavras-chave / Keywords (95 / 100 car.)
> **Regra:** Separadas apenas por vírgula, sem espaços, sem palavras do Nome/Subtítulo.
```text
ping,lag,latência,jitter,perda,pacotes,bufferbloat,wifi,internet,rede,estabilidade,teste,online
```

### Texto Promocional (100 / 170 car.)
```text
Vai puxar uma ranked? Confira latência, jitter e perda na rota até uma infraestrutura de referência.
```

### Descrição Completa (pt-BR)
```text
Vai puxar uma ranked? Veja a leitura da sua conexão antes de entrar na fila.

O LagCheck mede a rota do seu iPhone até uma infraestrutura de referência. Em poucos segundos, mostra latência, jitter e perda de pacotes — os sinais observados nesta medição.

Não é o ping oficial de um jogo. Para console ou PC, o resultado é uma estimativa da conexão no mesmo ambiente.

COMO O CHECK AJUDA
• Veredito direto: veja se a condição observada está pronta, instável ou se é melhor evitar ranked agora.
• Rota sob carga: compare a leitura em repouso e sob carga para entender se a conexão piora quando a rede é disputada.
• Detalhes sem chute: veja métricas e sintomas observados, sem culpar Wi-Fi, operadora ou servidor sem evidência isolada.
• Card para o squad: compartilhe a leitura da sessão pelo compartilhamento do iPhone.

Se faltarem respostas UDP válidas, o LagCheck mostra “inconclusivo” em vez de inventar uma nota ou uma recomendação.

Sem conta nem login. Antes de entrar na fila, faça um Check.
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

- **Dados próprios do LagCheck:** `User ID` pseudônimo por instalação e `Product Interaction` (evento de produto; jogo, plataforma e classe de veredito quando aplicáveis), ambos para **Analytics**, não vinculados à identidade e sem tracking pelo LagCheck.
- **Não enviados no payload próprio:** nome, e-mail, telefone, histórico de navegação, amostras brutas de rede, SSID, BSSID, IDFA ou localização.
- **Google Mobile Ads/UMP:** o SDK pode processar dados técnicos e publicitários próprios. Antes de distribuir o archive, preencher o App Privacy com a matriz vigente do Google para a versão do SDK, a configuração real de consentimento e qualquer recurso opcional ativado; a declaração pré-SDK acima não pode ser reutilizada como declaração total do app.
- **Transporte:** o payload próprio do LagCheck não envia IP; metadados de rede necessários à entrega e proteção podem ser processados pela infraestrutura e pelo SDK de publicidade conforme suas políticas.
