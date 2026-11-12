# LagCheck Windows — Design System

> **Posicionamento do Produto:** O **LagCheck para Windows é um launcher gamer com check de rede integrado**. Ele reúne e inicia os jogos de PC instalados e avalia a rota e estabilidade da conexão antes do jogador entrar na partida.
> **Status:** Especificação de design desktop para Windows (Decisões 114 a 119 de `docs/DECISOES.md`).
> **Plataforma alvo:** WinUI 3 / Windows App SDK (`windows/LagCheck.WinUI/`) sobre motor de diagnóstico Kotlin compartilhado via protocolo local `lagcheck-engine-v1`.
> **Referência canônica de tokens e fontes:** `design-system/DESIGN.md`, `design-system/tokens/` e `windows/LagCheck.WinUI/Styles/Theme.xaml`.

---

## 1. Contexto e proposta de valor

O LagCheck para Windows **não é apenas um medidor de ping ou ferramenta de diagnóstico utilitária**: ele é o **launcher gamer do PC**.

O jogador de PC abre o LagCheck para escolher e iniciar seus jogos instalados (Steam, Epic Games, Xbox / PC Game Pass, Battle.net e manuais). A vantagem competitiva única do LagCheck frente a launchers convencionais (como Steam, Xbox App ou Playnite) é o **cockpit de telemetria de rede pré-partida (pre-flight check)**:
1. **Centraliza e inicia jogos:** detecta automaticamente a biblioteca instalada, exibe capas e banners oficiais locais e dispara o jogo em um clique.
2. **Avalia a rota antes do play:** para títulos com servidores suportados (ou via rota de referência geral), o launcher exibe o estado de rota, latência em repouso, jitter e perda UDP diretamente no painel do jogo.
3. **Decisão rápida no lobby:** o jogador sabe se pode jogar partidas competitivas ranqueadas agora ou se deve reiniciar o roteador / aguardar a rota estabilizar antes de perder pontos na partida.
4. **A **Regra do Discord** segue inegociável:** toda leitura de rede deve ser traduzível para uma frase curta falada entre amigos na chamada de voz (ex: *"Minha rota pro servidor de SP tá com jitter alto hoje, vou jogar casual"*).

---

## 2. Fundamentos visuais

Visual escuro, esportivo, técnico e focado em performance, construído para o jogador de PC no lobby:
1. **Estética de Cockpit Gamer:** Foco na biblioteca e na telemetria. Sem estética de cassino gamer, sem HUD ornamental futurista, sem anéis orbitais, sem neon exagerado, sem vidro espelhado (*glassmorphism*) e sem auroras ou halos de fundo.
2. **Biblioteca de Jogos em Primeiro Plano:** O palco inicial é a estante de jogos do jogador. Grid visual de capas verticais com navegação fluida, filtros rápidos por plataforma/status e busca instantânea.
3. **Hierarquia Clara no Hero do Jogo:**
   - **1. Ação Primária de Lançamento:** Botão **"Jogar"** / **"Iniciar Jogo"** de destaque máximo;
   - **2. Leitura de Rede Pré-Partida:** Veredito semântico contextual (ex: `● PRONTO PARA RANKED` ou `▲ INSTÁVEL SOB CARGA`) e botão de conferência rápida de rota;
   - **3. Evidência Técnica:** Métricas numéricas tabulares (Ping, Jitter, Perda UDP, Delta de Carga);
   - **4. Plataforma e Launcher de Origem:** Identificação do cliente (Steam, Epic, Xbox).
4. **Sem Sopa de Cards (*Card Soup*):** Linhas de divisão de 1 px hairline (`--line`) organizam os dados de forma contínua. Cards só existem para as capas na biblioteca e seletores de contexto.
5. **Métrica é Medição Real:** Numerais tabulares em Chakra Petch. Onde não houver dado medido, exibe-se travessão (`—`); proibido exibir `0 ms` falso ou inventar estabilidade.

---

## 3. Cores e tokens funcionais

Os tokens vivem canonicamente em `windows/LagCheck.WinUI/Styles/Theme.xaml` e seguem os padrões do produto:

| Token XAML / CSS | Hex / Valor | Função no Launcher Windows | Uso correto | Onde NÃO usar |
| :--- | :--- | :--- | :--- | :--- |
| `StageBrush` / `--stage` | `#060709` | Fundo externo e barra de título | Moldura externa da janela e titlebar nativa | Cards, textos ou áreas de leitura |
| `DeepBrush` / `--deep` | `#0B0D10` | Fundo principal da biblioteca | Palco central (`main`), tela da biblioteca, grade de jogos | Gradientes decorativos ou texturas |
| `SurfaceBrush` / `--surface` | `#15181E` | Superfície funcional e cartões | Item ativo da sidebar, cards de jogos na grade, painel hero | Fundo de títulos ou textos soltos |
| `PanelBrush` / `--panel` | `#1E232B` | Camada ativa e microcontroles | Hover forte de card, chips de launcher, caixas de status | Fundo geral da aplicação |
| `LineBrush` / `--line` | `rgba(244, 245, 247, 0.10)` | Hairline de divisão | Separadores sutis de seções, linhas de tabela e divisores | Bordas grossas ou ornamentais |
| `LineStrongBrush` / `--line-strong` | `rgba(244, 245, 247, 0.16)` | Contorno de controle | Bordas de botões secundários, inputs de busca, switches | Divisores de leitura de conteúdo |
| `TextPrimaryBrush` / `--text-primary` | `#F4F5F7` | Decisões e títulos | Nomes de jogos, vereditos, numerais em Chakra Petch e texto do CTA | Textos longos de suporte |
| `TextSecondaryBrush` / `--text-secondary` | `#8A93A0` | Metadados e contexto | Plataforma do jogo, detalhes da rota, explicações técnicas | Valores numéricos de métricas |
| `TextTertiaryBrush` / `--text-tertiary` | `#606873` | Apoio técnico e labels | Eyebrow técnico, horas jogadas, timestamps, hash de build | Textos essenciais de acessibilidade (contraste 3,45:1) |
| `PurpleBrush` / `--purple` | `#7C3AED` | Ação primária e foco | Botão "Jogar", foco de teclado, fase ativa da medição | Fundo amplo de tela ou cor de vitória |
| `PurpleLightBrush` / `--purple-light` | `#A78BFA` | Foco acessível e acento | Anel de foco de teclado (3 px) e acento textual suave | Fundo de botões primários |
| `ReadyBrush` / `--ready` | `#22C55E` | Conexão favorável | Indicador de rota limpa e veredito positivo para o jogo | Sinal isolado sem rótulo textual |
| `CautionBrush` / `--caution` | `#F59E0B` | Alerta contextual de rede | Jitter alto, aumento sob carga, aviso para usar cabo de rede | Decoração ou badge promocional |
| `CoralBrush` / `--coral` | `#FF5A36` | Erro de conexão ou risco | Perda de pacotes crítica, rota congestionada, erro de socket | Botão de ação comum ou alertas falsos |

---

## 4. Tipografia oficial

A tipografia do Windows é empacotada no projeto (`ms-appx:///Assets/Fonts/`) e espelha a identidade do ecossistema LagCheck:

| Papel | Família | Pesos recomendados | Tamanhos e entrelinhas | Uso exclusivo no Launcher |
| :--- | :--- | :--- | :--- | :--- |
| **Títulos / Jogo / Veredito** | **Barlow Semi Condensed** | 700 (Bold), 800 (ExtraBold) | H1: 30–38 px / 1.1; H2: 24–28 px; Veredito: 32–40 px (tracking `-0.015em`) | Título do jogo em destaque no Hero, veredito de rede, títulos de seção |
| **Corpo / UI** | **Barlow** | 400 (Regular), 500 (Medium), 600 (SemiBold) | 13–16 px / 1.5 | Rótulos de botões ("Jogar", "Checar rota"), textos de apoio e configurações |
| **Telemetria de Rede** | **Chakra Petch** | 600 (SemiBold) | 20–36 px / 1.0 (números tabulares) | Latência em repouso, jitter, carga e perda UDP de servidores de jogos |
| **Técnica / Metadados** | **Cascadia Mono** / `ui-monospace` | 600 (SemiBold/Bold) | 10–12 px / 1.2 (tracking `0.08em` a `0.12em`, caixa alta) | Região do servidor (ex: `SA-EAST-1 (SP)`), launcher (STEAM), status de rota |

**Regras estritas:**
- **Chakra Petch** é restrita a métricas e valores numéricos; nunca use em parágrafos de texto.
- **Barlow Semi Condensed** é restrita a títulos, nomes de jogos e vereditos; nunca use em parágrafos de texto corrido.
- Textos técnicos em **Cascadia Mono** não recebem sublinhado nem gradientes decorativos.

---

## 5. Marca e identificação visual

A marca oficial do LagCheck é rigorosamente protegida:

- **Wordmark primária (`wordmark-primary.svg`):**
  - Aplicação no topo esquerdo da sidebar ou cabeçalho da janela.
  - Altura fixa entre 18 px e 22 px, preservando proporção ~4.9:1.
  - Uso estrito com “Check” em Roxo Gamer (`#7C3AED`) e “Lag” em branco (`#F4F5F7`). Proibido aplicar sombras projetadas ou gradientes alternativos por código.
- **Símbolo isolado (`lagcheck-mark.svg`):**
  - Ícone nativo da barra de título do Windows (16×16 ou 20×14 px), ícone da barra de tarefas, atalho na área de trabalho e ícone na bandeja do sistema (system tray).
  - Versão compacta da barra lateral quando colapsada.

---

## 6. Arquitetura da janela e experiência do Launcher

- **Dimensões do shell:**
  - Janela padrão recomendada: **1120 × 740 px** (otimizada para telas 1080p e 1440p).
  - Janela mínima suportada: **960 × 600 px**.
  - Responsividade: em larguras maiores (>1200 px), a grade de jogos expande o número de colunas (5 a 6 colunas) mantendo o painel Hero proeminente no topo.
- **Barra de Título Nativa (Titlebar):**
  - Altura de 42 px integrada ao fundo `--stage`, com botões nativos do Windows.
  - Indicador central sutil: `BIBLIOTECA · JOGOS INSTALADOS` ou `CONEXÃO GERAL`.
- **Barra Lateral de Navegação (Sidebar):**
  - 4 destinos fixos:
    1. **Biblioteca (Início):** Grade de jogos instalados no PC com o Hero do título selecionado;
    2. **Catálogo de Jogos:** Catálogo completo de jogos monitorados com servidores mapeados;
    3. **Histórico:** Registro de sessões de diagnóstico e estabilidade ao longo do tempo;
    4. **Ajustes:** Configurações de inicialização com o Windows, launchers detectados e opções de rede.
  - Rodapé exibe a interface de rede ativa (`Ethernet` ou `Wi-Fi`) e a versão do build.
- **Comportamento em Background / Bandeja (System Tray):**
  - Ao iniciar um jogo, o LagCheck pode minimizar para a bandeja do sistema para não consumir recursos de CPU/GPU durante a jogatina.
  - O app é leve, instantâneo e não executa processos invasivos durante a partida.

---

## 7. Componentes do Launcher

### 7.1. Hero do Jogo Selecionado
O topo da Biblioteca exibe o jogo atualmente selecionado em destaque:
- **Arte de fundo:** Banner horizontal oficial (`library_hero`), carregado em runtime do cache local da Steam/PC do jogador (Decisão 118).
- **Cabeçalho:** Nome do jogo em Barlow Semi Condensed (32–36 px), badge do launcher de origem (Steam, Epic, Xbox) e badge de suporte de rota (`ROTA DEDICADA` ou `ROTA GERAL`).
- **Ações duplas coordenadas:**
  1. **Botão Primário "Jogar":** Botão roxo de 48–52 px de altura, largo e de clique rápido. Dispara o jogo via protocolo de launcher ou executável local.
  2. **Check de Rede Contextual:** Ao lado do botão "Jogar", exibe o veredito pré-jogo (ex: `● Conexão ideal · 14 ms SP`) com botão secundário rápido `Checar conexão` para rodar novo probe UDP.
  3. O check de rede **nunca bloqueia o botão de jogar**: o jogador tem a liberdade de entrar no jogo quando quiser.

### 7.2. Grade da Biblioteca de Jogos
- **Cards de Capa Vertical:** Formato 2:3 padronizado (ex: 140×210 px).
- **Arte autêntica local:** Capa vertical oficial (`library_600x900`) obtida do cache do launcher local. Para jogos sem arte disponível, usa miniatura neutra estilizada do LagCheck com o nome e plataforma.
- **Filtros e busca rápida:** Barra de filtro no topo da grade:
  - Campo de busca instantânea (filtro por nome com atalho `Ctrl+F`);
  - Chips de filtro: `Todos`, `Instalados`, `Steam`, `Epic`, `Xbox`, `Favoritos`;
  - Ordenação: `Últimos jogados`, `Nome (A-Z)`, `Ping mais baixo`.

### 7.3. Painel de Diagnóstico Contextual
- Quando o jogador clica em `Checar conexão` no jogo:
  - O launcher consulta os servidores específicos daquele jogo através do motor Kotlin compartilhado (`lagcheck-engine-v1`).
  - Faixa de métricas sob o Hero: Repouso, Jitter, Sob Carga e Perda de Pacotes.
  - Se a conexão estiver com perda de pacotes ou instabilidade, exibe recomendação prática e direta (ex: *"Perda de pacotes na rota de SP detectada. Evite filas ranqueadas agora"*).

### 7.4. Botões e controles WinUI 3
- **Botão Primário ("Jogar"):** altura mínima de 48 px, Roxo Gamer (`#7C3AED`), raio de 12 px, texto Barlow SemiBold branco (`#F4F5F7`).
- **Botão Secundário ("Checar conexão"):** altura de 44 px, fundo transparente, contorno de 1 px (`--line-strong`), raio de 8 px e texto `--text-primary`.
- **Chips de filtro:** botões compactos de 32 px em `--surface` com contorno de 1 px e texto `--text-secondary` (ativo em `--panel` e `--text-primary`).

---

## 8. Movimento, foco e acessibilidade

- **Fluidez desktop:** transições suaves de 150 ms a 200 ms ao selecionar jogos e alternar abas (`cubic-bezier(0.2, 0, 0, 1)`).
- **Foco por teclado e gamepad:** navegação completa por teclado na grade de jogos (setas direcionais, Enter para jogar, Barra de espaço para checar conexão).
- **Anel de foco visível:** todo elemento interativo focado recebe borda de 3 px na cor `PurpleLightBrush` (`#A78BFA`).
- **Prefers-Reduced-Motion:** respeita configurações de acessibilidade do Windows, eliminando transições de banner e pulsos visuais.

---

## 9. Anti-padrões no Launcher Windows

- **Não ser bloatware:** o LagCheck é ultra-leve e rápido. Não adiciona overlays invasivos de tela cheia que degradem FPS nem serviços pesados em segundo plano.
- **Não travar o play:** a telemetria é uma ferramenta de auxílio e confiança para o jogador; o botão "Jogar" nunca deve ficar travado enquanto um check é executado.
- **Não distribuir artes proprietárias no instalador:** capas e banners de jogos são exclusivamente carregados em tempo de execução da biblioteca do próprio jogador (Decisão 118).
- **Não prometer "zero lag" ou melhorias milagrosas:** o app diagnostica a verdade da rota com evidência real, sem promessas de VPN milagrosa ou "otimizadores" de sistema falsos.
- **Não poluir a tela com notícias ou anúncios promocionais:** o espaço pertence exclusivamente aos jogos do usuário e à integridade da sua conexão.
