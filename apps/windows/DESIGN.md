# LagCheck Windows — Design System (v2)

> **Posicionamento do Produto:** O **LagCheck para Windows é um launcher gamer com cockpit de telemetria integrado**. Ele centraliza e inicia os jogos de PC instalados e avalia a rota e estabilidade da conexão antes do jogador entrar na partida.
> **Status:** Especificação de design desktop canônica para Windows (Decisões 114 a 120 de `docs/DECISOES.md`).
> **Referência Visual Canônica 1:1:** Protótipo `LagCheck Windows v2.dc.html` (Design Canvas), tokens canônicos (`Theme.xaml`) e regras de produto do LagCheck.
> **Plataforma alvo:** WinUI 3 / Windows App SDK (`apps/windows/LagCheck.WinUI/`) sobre motor de diagnóstico real sem mock (`WebSpeedtestEngine` e integração com `ILibraryBridge`).

---

## 1. Proposta de valor e princípios visuais

O jogador de PC abre o LagCheck no lobby para duas coisas: **escolher o que vai jogar** e **ter certeza de que a conexão não vai estragar a partida ranqueada**.

1. **Zero enrolação:** O botão de jogar está sempre na mão e nunca fica bloqueado por medições.
2. **Sem catálogo próprio:** O LagCheck para Windows exibe única e exclusivamente os títulos instalados no PC do usuário (Steam, Epic Games, Xbox / PC Game Pass ou executáveis locais). As opções de medição são: testar a conexão contextual ao jogo instalado ou fazer um Check Geral de referência sem jogo selecionado.
3. **Regra do Discord:** Toda informação de rede deve ser traduzível para uma frase curta falada na chamada de voz (*"Minha rota tá lisa hoje, vou jogar tranquilo"*).
4. **Cockpit em vez de vitrine:** Sem notícias, sem promoções, sem banners comerciais e sem textos didáticos de IA. O palco é 100% focado nos jogos instalados do usuário e no play rápido.
5. **Rigorosamente sem mock:** Medições de rede executam testes determinísticos reais HTTPS contra datacenters mundiais e Cloudflare speed. A biblioteca reflete os jogos reais instalados na máquina.

---

## 2. Anatomia das 5 Telas Principais (1:1 com v2)

```text
+------------------------------------------------------------------------------------------+
|  [Wordmark] [<<]   |  LAGCHECK · Início                              | [PC GAMER] [-][#][X] |
+--------------------+---------------------------------------------------------------------+
| (Q) Buscar jogo... |                                                                     |
|                    |  [STEAM]                                                            |
| [*] Início         |  COUNTER-STRIKE 2                                                   |
| [=] Biblioteca     |  [● PRONTO PARA RANKED]  12 ms                                      |
| [~] Conexão        |  [▶ JOGAR AGORA]  [Checar conexão]  [(Coração)]  [(Refresh)]            |
| [H] Histórico      |                                                                     |
| [x] Ajustes        |  [Recentes: CS2, Dota 2, Apex, Rocket League...]                     |
+--------------------+---------------------------------------------------------------------+
```

### 2.1. Tela 1 — Início (Home Cinematográfica)
- **Hero em Tela Cheia:** Ocupa toda a altura útil (`calc(100vh - 56px)`).
- **Slides de Fundo:** Imagens oficiais em alta resolução (`library_hero`, `page_bg_generated_v6b`, `capsule_616x353`) do jogo ativo com transição suave.
- **Tratamento de Luz:**
  - Gradiente horizontal escuro: `linear-gradient(90deg, rgba(11,13,18,.94), rgba(11,13,18,.62) 42%, rgba(11,13,18,.12))`
  - Gradiente vertical: `linear-gradient(180deg, rgba(11,13,18,.5), transparent 22%, transparent 50%, rgba(11,13,18,.92))`
- **Informações do Jogo:**
  - Badge de plataforma com ícone SVG/Glyph (Steam, Epic, Xbox, PC Local).
  - Título em **Barlow Semi Condensed ExtraBold** (56–76 px, maiúsculo, line-height 0.98, tracking -0.5px).
  - Tag de veredito da última medição (`● PRONTO PARA RANKED` em verde `#22C55E` com fundo `rgba(34,197,94,.16)` e ping `12 ms`).
- **Ações Imediatas:**
  - Botão Primário `▶ JOGAR AGORA`: Roxo `#7C3AED`, altura 56 px, cantos arredondados de 28 px, padding lateral 42 px, glow de 36 px `rgba(124,58,237,.55)`.
  - Botão `Checar conexão`: Fundo `rgba(37,42,54,.85)`, cantos 28 px, padding 28 px.
  - Botões circulares (46 px, cantos 23 px): Favoritar (coração) e Atualizar Imagem oficial.
  - Indicadores de slides (dots de 5 px).
- **Faixa de Recentes na Base:**
  - Carrossel horizontal com cards 2:3 dos títulos jogados recentemente.
  - Card ativo ganha anel roxo suave de 2 px (`#A78BFA`) e opacidade 1.0 (inativos em 0.70).
  - Clique simples: seleciona e atualiza o Hero imediatamente; clique duplo: abre a tela de detalhes.

### 2.2. Tela 2 — Biblioteca (Coleção Completa)
- **Cabeçalho:**
  - Título `BIBLIOTECA` em Barlow Semi Condensed 36 px + contador `X JOGOS`.
  - Botão `Procurar jogos` (rescan real de launchers no PC).
- **Barra de Controle:**
  - Campo de busca `Buscar na sua biblioteca (Ctrl+F)`.
  - Dropdown de ordenação: *Nome A–Z*, *Mais recentes*, *Plataforma*, *Favoritos primeiro*.
- **Pílulas de Filtro:**
  - `Todos os jogos`, `Instalados`, `Steam`, `Epic Games`, `Xbox`, `PC local`, `Favoritos`, `Recentes`.
- **Grade de Cards (Proporção 2:3):**
  - Cards verticais (`minmax(180px, 1fr)`), cantos arredondados de 16 px.
  - Capa oficial vertical.
  - Badge da plataforma no canto superior esquerdo (30×30 px).
  - Coração vermelho no canto superior direito se favoritado.
  - Nome do título sobreposto a gradiente escuro na base em Barlow Semi Condensed 17 px.
  - Ao clicar no card: navega para a tela de Detalhes do Jogo.

### 2.3. Tela 3 — Detalhes do Jogo
- **Banner Imersivo Superior (Altura 456 px):**
  - Banner oficial com gradiente escuro de legibilidade.
  - Botão `Voltar` no topo esquerdo.
  - Plataforma, título gigante em Barlow Semi Condensed 60–64 px.
  - Botões de ação: `▶ JOGAR AGORA`, `Checar conexão`, `Favoritar`.
- **Grade Inferior (2 Colunas: minmax(0,1fr) e 340 px):**
  - **Coluna Principal (Esquerda):**
    - Pílulas com tags de gênero e modos de jogo.
    - Painel **DIAS JOGADOS**: Heatmap de 26 semanas × 7 dias (estilo GitHub/Steam), com dias da semana e meses, e escala Menos/Mais em tons de roxo (`#1C212B`, `#3B2A6B`, `#5B3BA8`, `#7C3AED`, `#A78BFA`).
    - Grid com 3 screenshots horizontais em proporção 16:9.
  - **Coluna Lateral (Direita - 340 px):**
    - Card com ficha técnica: Desenvolvedora, Publicadora, Lançamento, Gêneros.
    - Card **HISTÓRICO DE MEDIÇÕES**: lista de medições anteriores para este jogo específico (status, ping, jitter, tempo) e botão de ação rápida `Medir agora`.

### 2.4. Tela 4 — Conexão (Cockpit de Telemetria)
- **Estado Repouso (Idle):**
  - Título maiúsculo `DIAGNÓSTICO DE CONEXÃO` (ou o nome do jogo se contextual).
  - Se contextual: pill arredondada central `{Jogo} · Competitivo`.
  - Mapa permanente interativo em proporção 2:1 com grade de continentes e pontos de datacenters.
  - Botão de ação `Teste agora` roxo `#7C3AED` (56 px, cantos 14 px).
- **Estado Medição (Running):**
  - Barra de progresso contínua 2 px roxa.
  - Numeral gigante ao vivo em **Chakra Petch** (72 px) com unidade tabular (ms ou Mbps).
  - Nome da fase em caixa alta e cor semântica (`CONECTANDO`, `LATÊNCIA`, `SOB CARGA`, `ANALISANDO`, `UPLOAD`).
  - 4 etapas com bullets coloridos: Conexão, Latência, Sob carga, Análise.
  - Faixa com 4 métricas instantâneas em colunas iguais: `RESPOSTA`, `JITTER`, `SOB CARGA`, `UPLOAD`.
  - Status dos servidores respondidos (ex: *"7 de 7 servidores responderam · mais rápido até agora: São Paulo (12 ms)"*).
  - Botão de ação `Cancelar`.
- **Estado Concluído (Done / Resultado):**
  - **Grid Superior em 2 Colunas (1.3fr e 0.7fr):**
    - **Coluna Esquerda:**
      - Contexto do jogo/geral em Cascadia Mono maiúsculo.
      - Ponto colorido + Palavra de status (`● Conexão boa` / `▲ Conexão instável` / `▲ Conexão ruim`).
      - Manchete em Barlow Semi Condensed 46 px (`PRONTO PARA JOGAR` / `PRONTO PARA RANKED` / `CONDIÇÕES INSTÁVEIS` / `EU EVITARIA JOGAR ONLINE AGORA`).
      - Faixa contínua com as 4 métricas com números tabulares 32 px em Chakra Petch coloridos por severidade.
    - **Coluna Direita (EVIDÊNCIA DE ROTA):**
      - Título técnico `EVIDÊNCIA DE ROTA` em Cascadia Mono.
      - Mapa de rota em proporção 16/10 evidenciando o traçado até a região escolhida (São Paulo sa-east-1).
      - Rótulo da região e latência medida (`São Paulo (sa-east-1) · 12 ms`).
  - **Seções em Largura Total:**
    - **VOZ, STREAMING E NAT:**
      - *Voz e chamadas:* Bom / Atenção com explicação prática para Discord/TeamSpeak.
      - *Streaming ao vivo:* Bom / Atenção com capacidade estimada de transmissão (1080p60, 1080p, 720p).
      - *NAT:* Aberto ou moderado.
    - **TEMPO DE RESPOSTA DOS SERVIDORES:** Detalhes expansíveis com lista de datacenters mundiais e latências reais.
    - **O QUE FAZER AGORA:** Recomendações proporcionais quando a rede apresentar instabilidade.
    - Botões de rodapé: `Testar novamente` e `Escolher outro jogo`.

### 2.5. Tela 5 — Histórico de Sessões
- Título `Histórico de Sessões` e campo de busca.
- Tabela limpa com 5 colunas: Veredito, Região/Jogo, Latência, Jitter, Perda de pacotes e Horário da medição.
- Sem testes: honesto estado vazio *"Sem testes nesta sessão"*.

### 2.6. Tela 6 — Ajustes
- Organizado em 4 cards:
  1. *Interface e Visual:* Reduzir movimento e Baixar imagens dos jogos.
  2. *Privacidade e Rede:* Localização aproximada, Enviar estatísticas anônimas + Gerar novo ID local.
  3. *Atualizações:* Verificar automaticamente + Verificar agora.
  4. *Sobre o LagCheck:* Versão v0.1.0 · WinUI 3 (x64) · Repositório Oficial.

---

## 3. Tokens Canônicos e Tipografia

| Token | Hex | Função |
| :--- | :--- | :--- |
| `Stage` | `#0D0F14` | Fundo externo, barra lateral e titlebar |
| `Deep` | `#11141B` | Fundo principal de leitura das páginas |
| `Surface` | `#171B24` | Superfícies ativas, cards e seletor |
| `Panel` | `#202633` | Controles secundários e divisões |
| `TextPrimary` | `#F5F7FC` | Decisões, títulos e números de destaque |
| `TextSecondary`| `#9AA3B5` | Contextos e explicações |
| `TextTertiary` | `#687285` | Eyebrow técnico, rótulos e metadados |
| `Purple` | `#7C3AED` | Ação primária (CTA), botões e acentos |
| `PurpleLight` | `#A78BFA` | Foco acessível e destaques de texto |
| `Ready` | `#22C55E` | Leitura favorável / Veredito positivo |
| `Caution` | `#F59E0B` | Cautela / Oscilação sob carga |
| `Coral` | `#FF5A36` | Erro crítico ou alto risco |
| `Line` | `rgba(255,255,255,0.06)` | Hairline de divisão |
