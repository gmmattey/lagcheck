# LagCheck — Ficha e Configuração Oficial: Google Play Store

Documento canônico contendo todos os metadados, regras e instruções de cadastro no **Google Play Console** para o aplicativo Android.

---

## 1. Dados Técnicos da Aplicação (Google Play Console)

| Campo | Valor Exato | Observações |
| :--- | :--- | :--- |
| **Nome do App** | `LagCheck: Teste de Ping Gamer` | 29 / 30 caracteres. |
| **Tipo de App** | `Aplicativo` (App) | Não é jogo. |
| **Preço** | `Gratuito` (Free) | Sem compras in-app no MVP. |
| **Pacote (Package Name)** | `com.lagcheck.app` | Paridade com iOS e convenção canônica. |
| **Categoria** | `Ferramentas` (Tools) | Categoria primária. |
| **Tags / Marcadores** | `Rede`, `Velocidade`, `Jogos multijogador` | Máx. 5 tags relevantes. |
| **Classificação de Conteúdo** | `Livre` (Everyone / PEGI 3) | Questionário IARC. |
| **Site Oficial** | `https://lagcheck.signallq.com` | Landing institucional. |
| **E-mail de Suporte** | `suporte@signallq.com` | Exibido publicamente na loja. |
| **URL de Privacidade** | `https://lagcheck.signallq.com/privacy` | Obrigatória. |

---

## 2. Metadados — Português (Brasil) [pt-BR]

### Título do App (29 / 30 car.)
> **Regra Google Play:** Sem emojis, sem ALL CAPS decorativo, sem termos "grátis" ou "melhor".
```text
LagCheck: Teste de Ping Gamer
```
*(Alternativa B: `LagCheck: Ping e Jitter Gamer` — 29 car.)*

### Descrição Curta (80 / 80 car.)
```text
Descubra se a sua conexão está pronta para jogar ranked antes de entrar na call.
```
*(Alternativa B técnica: `Teste de ping, jitter e perda de rota UDP para partidas online sem surpresa.` — 76 car.)*

### Descrição Completa (pt-BR)
```text
Sua internet pode ter 500 Mega de download, mas travar na trocação de tiro da ranked. O LagCheck é o cockpit de telemetria de rede feito para gamers competitivos descobrirem se a conexão está estável antes de iniciar a partida.

Ao contrário de testes de velocidade comuns que medem apenas download e upload via HTTP, o LagCheck envia pacotes UDP reais para infraestruturas de rede gamer, medindo com precisão:
1. Ping Real (Latência): O tempo de resposta da sua rota.
2. Jitter (Oscilação): A variação milissegundo a milissegundo que causa microtravamentos.
3. Perda de Pacotes (Packet Loss): Disparos descartados que causam "tiro fantasma" e teleportes.
4. Bufferbloat (Rota sob Carga): O comportamento do seu ping quando a rede de casa está disputada.

RECURSOS PRINCIPAIS:
• Veredito Imediato: Receba instantaneamente a recomendação para o lobby: "Pronto para Ranked", "Evitaria Ranked Agora" ou "Condições Instáveis".
• Telemetria Avançada de Rádio Wi-Fi: No Android, o LagCheck analisa a frequência do seu roteador (2.4 GHz vs 5 GHz vs Wi-Fi 6), a intensidade do sinal em dBm e a velocidade do enlace físico para apontar se o problema é o sinal no seu quarto.
• Card Oficial para Discord e WhatsApp: Gere e compartilhe a telemetria comprovada da sua sessão com um toque para mostrar a estabilidade da sua rota para o seu duo ou squad.
• Diagnóstico de NAT e Roteador: Descubra se sua rede possui restrições como Duplo NAT ou CGNAT que dificultam a conexão em salas multijogador.
• Estimativa para Console e PC: Use seu smartphone como sonda rápida no mesmo cômodo do seu setup para antecipar a rota da partida.

COMPROMISSO LAGCHECK:
- Não prometemos milagres como "eliminar lag" sem base física. O app entrega diagnóstico científico e real.
- Custo zero e sem cadastros desnecessários: não exigimos login nem coletamos seu IP ou dados privados.
- Sem medições inventadas: se as respostas UDP forem insuficientes, o app é honesto e declara inconclusivo.

Evite surpresas e perdas de pontos na ranked. Faça o LagCheck antes de jogar!
```

---

## 3. Metadados — Inglês (EUA / Global) [en-US]

### App Title (30 / 30 car.)
```text
LagCheck: Gaming Ping & Jitter
```

### Short Description (72 / 80 car.)
```text
Check ping, jitter, and UDP packet loss before queuing for ranked games.
```

### Full Description (en-US)
```text
Your internet connection might boast 500 Mbps download speeds, but still lag during a critical clutch in competitive gaming. LagCheck is the network telemetry cockpit built for gamers to verify route quality before queuing up.

Unlike generic speed tests that only measure HTTP bandwidth, LagCheck transmits authentic UDP packets to gaming edge infrastructure, precisely benchmarking:
1. Real Ping (Latency): Instantaneous round-trip response time.
2. Jitter: Millisecond oscillation that causes micro-stutters and rubberbanding.
3. Packet Loss: Dropped network frames causing hitreg failures and desync.
4. Bufferbloat (Loaded Route): Latency degradation when local network bandwidth is saturated.

KEY FEATURES:
• Instant Readiness Verdict: Clear, actionable advice before you play: "Ready for Ranked", "Avoid Ranked Right Now", or "Unstable Route Conditions".
• Advanced Wi-Fi Radio Telemetry: On Android, LagCheck inspects router band frequency (2.4 GHz vs 5 GHz vs Wi-Fi 6), signal strength in dBm, and PHY link speed to diagnose whether local signal attenuation is causing drops.
• Certified Squad Cards: One-tap export of verified connection summaries formatted for Discord and WhatsApp.
• NAT & Router Diagnostics: Detect Double NAT or CGNAT boundaries that hinder peer-to-peer multiplayer lobbies.
• PC & Console Estimation: Benchmark your room's wireless conditions to predict latency before booting your console or desktop.

THE LAGCHECK PLEDGE:
- No bogus claims or fake "lag booster" promises. We provide pure, empirical network truth.
- Zero ads, no sign-ups, and zero tracking of personal browsing history.
- If network sampling fails scientific confidence thresholds, results are marked Inconclusive rather than fabricating a score.

Stop guessing your latency. Run LagCheck before entering the match!
```

---

## 4. Recursos Gráficos Obrigatórios (Play Console)

- **Ícone do App:** `512 x 512 px` (PNG 32-bit com transparência ou fundo escuro canônico `#0B0D10`).
- **Feature Graphic (Imagem em Destaque):** `1024 x 500 px` (JPG ou PNG 24-bit, sem transparência, destacando a wordmark `lagcheck` e o veredito gamer).
- **Screenshots Celular (mínimo 4):** Formato `9:16` (ex.: `1080 x 2400 px`), retratando a interface Jetpack Compose nativa.

---

## 5. Declaração de Segurança dos Dados (Data Safety Form)

- **Coleta de Dados:** O app não coleta dados pessoais identificáveis (Nome, E-mail, Telefone, Contatos, Fotos).
- **Dados Técnicos de Diagnóstico:** Diagnóstico anônimo de desempenho e telemetria de conectividade não vinculada à identidade do usuário.
- **Compartilhamento de Dados com Terceiros:** Não há compartilhamento comercial ou venda de dados.
- **Práticas de Segurança:** Dados transmitidos de forma criptografada via HTTPS/TLS para endpoints Cloudflare Worker.
