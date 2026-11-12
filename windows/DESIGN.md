# LagCheck Windows — Design System

> **Posicionamento do Produto:** O **LagCheck para Windows é um launcher gamer com cockpit de telemetria integrado**. Ele centraliza e inicia os jogos de PC instalados e avalia a rota e estabilidade da conexão antes do jogador entrar na partida.
> **Status:** Especificação de design desktop para Windows (Decisões 114 a 119 de `docs/DECISOES.md`).
> **Referência Visual:** Layout estilo Steam Redesign adaptado com Dark Competitive UI, tokens canônicos (`Theme.xaml`) e regras de produto do LagCheck.
> **Plataforma alvo:** WinUI 3 / Windows App SDK (`windows/LagCheck.WinUI/`) sobre motor de diagnóstico Kotlin compartilhado via protocolo local `lagcheck-engine-v1`.

---

## 1. Proposta de valor e espírito da tela

O jogador de PC abre o LagCheck no lobby para duas coisas: **escolher o que vai jogar** e **ter certeza de que a conexão não vai estragar a partida ranqueada**.

O layout une a estética limpa de um launcher moderno (com hero imersivo e cantos arredondados) com um cockpit de telemetria esportivo e direto ao ponto:
1. **Zero enrolação:** O botão de jogar está sempre na mão e nunca fica bloqueado por medições.
2. **Sem catálogo próprio:** O LagCheck para Windows **não possui catálogo de jogos próprio**. Os jogos exibidos são única e exclusivamente os títulos instalados no PC do usuário (Steam, Epic Games, Xbox / PC Game Pass ou executáveis locais). As opções de medição são: testar a conexão do jogo instalado ou fazer um Check Geral de referência sem jogo selecionado.
3. **Regra do Discord:** Toda informação de rede deve ser traduzível para uma frase curta falada na chamada de voz (*"Minha rota tá lisa hoje, vou jogar tranquilo"*).
4. **Cockpit em vez de vitrine:** Sem notícias, sem promoções, sem banners comerciais e sem textos didáticos de IA. O palco é 100% focado nos jogos instalados do usuário e no play rápido.

---

## 2. Anatomia do Layout

O layout é composto por três áreas principais: **Sidebar Retrátil**, **Top Bar de Controle** e o **Palco Principal** (dividido entre o Hero do Jogo e a Tríade de Telemetria/Biblioteca).

```text
+------------------------------------------------------------------------------------------+
|  [Wordmark] [<<]   |  E aí, Luiz!   [Todos] [Recentes] [Favoritos] [Steam]   | [● SP 14ms] [-][#][X] |
+--------------------+---------------------------------------------------------------------+
| (Q) Busca          | +-----------------------------------------------------------------+ |
|                    | | HERO DO JOGO SELECIONADO                                        | |
| [*] Início         | | [Banner horizontal oficial local com cantos de 24px]            | |
| [=] Biblioteca     | |                                                                 | |
|                    | | (Tempo jogado)                                                  | |
| [S] Catálogo       | | NOME DO JOGO                                                    | |
| [H] Histórico      | | Veredito pré-partida + Rota ativa                               | |
|                    | |                                         [(Engrenagem)] [(i)] [▶ JOGAR] |
|                    | +-----------------------------------------------------------------+ |
|                    | +-------------------+ +---------------------+ +-------------------+ |
|                    | | TELEMETRIA DA ROTA| | SERVIDORES DO JOGO  | | ESTABILIDADE      | |
|                    | | 14 ms             | | ● SP - 14 ms        | | Heatmap semanal   | |
|                    | | Jitter: 0.8 ms    | | ● BA - 38 ms        | | de horários de    | |
| [x] Ajustes        | | Perda: 0.0%       | | ▲ VA - 118 ms       | | pico e conexão    | |
| [v] v0.1.0 (Eth)   | +-------------------+ +---------------------+ +-------------------+ |
+--------------------+---------------------------------------------------------------------+
```

---

## 3. Especificação Detalhada das Áreas

### 3.1. Barra Lateral Retrátil (Sidebar)

A sidebar opera em dois modos: **Expandida** (220 px de largura) e **Compacta / Ícones** (64 px de largura), com transição suave de 150 ms e persistência do estado escolhido pelo usuário.

- **Topo:**
  - Wordmark `lagcheck` (em modo expandido, altura 20 px) ou símbolo isolado `lagcheck-mark` (em modo compacto, 20×14 px).
  - Botão de colapsar/expandir (`<<` / `>>`) em formato de pílula sutil.
- **Busca Rápida:**
  - Atalho global `Ctrl+F` integrado. Em modo expandido, exibe campo com placeholder *"Buscar jogo ou rota..."*. Em modo compacto, exibe ícone de lupa com tooltip.
- **Navegação Principal:**
  - **Biblioteca:** Grade completa de capas verticais (2:3) dos jogos instalados no PC (Steam, Epic, Xbox) com o Hero do título selecionado e botão direto de Play e Checar Rota;
  - **Conexão:** Diagnóstico de conexão de referência do PC sem necessidade de jogo selecionado, com mapa mundi vetorial em tempo real, arco de rota e avaliação de uso (idêntico ao padrão de `lagcheck.signallq.com`);
  - **Histórico:** Gráficos e registros de medições reais anteriores;
  - **Ajustes:** Configurações de interface, inicialização, launchers detectados e telemetria.
- **Estilo dos Itens:**
  - Item ativo usa fundo de pílula arredondada em `--surface` (`#15181E`), texto `--text-primary` e acento Roxo Gamer (`#7C3AED`) na borda esquerda ou ícone.
  - Itens inativos em `--text-secondary` (`#8A93A0`) com transição suave no hover para `--panel` (`#1E232B`).
- **Rodapé da Sidebar:**
  - **Ajustes:** Configurações de inicialização com o Windows, launchers detectados e seleção de adaptadores.
  - **Status de Hardware de Rede:** Chip discreto com ícone de cabo/Wi-Fi e velocidade do link (ex: `Ethernet · 1 Gbps` ou `Wi-Fi 6`).
  - **Versão:** Build do app em Cascadia Mono (`v0.1.0`).

### 3.2. Barra Superior (Top Bar)

Integrada diretamente à janela nativa (altura 48 px), eliminando a separação visual clássica de janelas corporativas:

- **Lado Esquerdo — Saudação e Contexto:**
  - Saudação personalizada curta (ex: *"E aí, Luiz!"* ou *"Lobby pronto"*).
  - Status em subtítulo fino: *"Sua rota principal está pronta para partidas"*.
- **Centro — Segmented Pill Filters (Chips de Filtro em Pílula):**
  - Grupo de filtros com cantos totalmente arredondados (estilo pill-tab):
    - `Todos` | `Recentes` (ativo por padrão) | `Favoritos` | `Steam` | `Epic Games` | `Xbox`
  - A pílula ativa ganha fundo `--panel` (`#1E232B`), contorno sutil de 1 px `--line-strong` e texto branco.
- **Lado Direito — Telemetria Global e Ações de Janela:**
  - **Chip de Ping Global:** Pílula sutil com indicador circular verde e valor em Chakra Petch (`● SP 14 ms`), servindo de pulso rápido de conectividade.
  - Botões nativos de controle de janela do Windows (Minimizar, Maximizar, Fechar) integrados harmoniosamente.

### 3.3. Hero do Jogo Selecionado

O elemento central da experiência. Um banner cinematográfico amplo com cantos arredondados de **24 px**:

- **Arte de Fundo (`library_hero`):**
  - Banner oficial de alta resolução carregado exclusivamente em tempo de execução do cache local da Steam/PC do usuário (Decisão 118).
  - Tratamento visual: vinheta escura suave na parte inferior e esquerda para garantir legibilidade absoluta dos textos e do veredito.
- **Cabeçalho Interno do Hero:**
  - **Última Sessão:** Texto discreto no topo esquerdo (ex: `Jogado ontem · 31 de out`).
  - **Badge de Tempo de Jogo:** Pílula translúcida com ícone de relógio e horas jogadas (ex: `🕒 102 hrs jogadas`).
- **Identificação do Título:**
  - Nome do jogo em **Barlow Semi Condensed Bold** (32 a 38 px, caixa alta ou título natural), com sombra tipográfica suave.
- **Cockpit de Veredito Pré-Partida:**
  - No lugar de sinopses genéricas, o Hero exibe a saúde da conexão para este título específico:
    - **Manchete de Veredito:** Badge em pílula esportiva (`● PRONTO PARA RANKED` em verde neon suave, ou `▲ OSCILAÇÃO SOB CARGA` em amarelo cautela).
    - **Resumo de Rota:** Linha descritiva direta (ex: *"Servidores Valve São Paulo · Rota direta sem perda de pacotes"*).
- **Ações no Canto Inferior Direito:**
  - **Botão de Configurações da Rota:** Botão circular (44×44 px) translúcido escuro com ícone de engrenagem.
  - **Botão de Detalhes da Conexão:** Botão circular (44×44 px) translúcido com ícone de informação/diagnóstico, abrindo a prova real completa.
  - **Botão Primário "▶ JOGAR" / "▶ INICIAR JOGO":**
    - Formato de pílula arredondada esportiva (altura 50 px, padding lateral 28 px).
    - Fundo em **Roxo Gamer** (`#7C3AED`) ou acento de alto contraste, com texto em Barlow Bold.
    - Dispara o jogo instantaneamente através da URI do launcher (`steam://run/...`) ou executável nativo.

---

## 4. A Tríade Inferior (Os 3 Painéis do Cockpit)

Abaixo do Hero, a tela se divide em três cartões modulares com cantos arredondados de **20 px**, fundo em `--surface` (`#15181E`) e borda hairline de 1 px (`--line`):

### Painel 1: Telemetria da Rota (Diagnóstico do Jogo)
Substitui a área de conquistas convencional por telemetria competitiva real:
- **Cabeçalho:** `Telemetria de Rota` acompanhado de link sutil `Detalhes >`.
- **Métrica Principal:** Latência em repouso exibida em **Chakra Petch Bold** (36 px) com unidade (ex: `14 ms`).
- **Barra de Estabilidade:** Barra horizontal graduada mostrando jitter e bufferbloat sob carga.
- **Grid de Indicadores:**
  - `Jitter`: `0.8 ms` (ideal)
  - `Perda UDP`: `0.0%` (limpo)
  - `Delta Carga`: `+2 ms` (rota não engasga durante downloads)
  - `Protocolo`: `UDP Direto`

### Painel 2: Servidores e Regiões do Jogo
Substitui a lista de amigos por rotas oficiais mapeadas:
- **Cabeçalho:** `Regiões do Servidor` com link `Ver todas >`.
- **Lista de Regiões:**
  - Cada linha exibe a região, o datacenter e a latência medida em tempo real:
    - `● Brasil (São Paulo)` — `14 ms` · Rota recomendada
    - `● Argentina (Buenos Aires)` — `38 ms` · Rota alternativa
    - `▲ América do Norte (Virgínia)` — `118 ms` · Alto ping para ranked
- **Ação Rápida:** Botão para alternar região de referência ou disparar novo probe UDP.

### Painel 3: Heatmap de Estabilidade Semanal
Adapta o calendário de atividade do Steam para a **confiabilidade da rota nos horários de pico**:
- **Cabeçalho:** `Estabilidade na Semana` com seletor de período (`Últimos 7 dias` / `Mês`).
- **Legenda Visual:**
  - Blocos vazios / hachurados: sem testes no horário.
  - Blocos cinza: conexão estável e normal.
  - Blocos ciano / verde neon: conexão excelente nos horários jogados.
  - Blocos coral / alerta: horários com degradação na operadora (ex: sexta-feira às 20h com jitter alto).
- **Grade Semanal (Seg a Dom):** Mostra ao jogador quais são os melhores horários para jogar competitivo na rota da casa dele.

---

## 5. Modo Grade Completa da Biblioteca (Toggle de Visualização)

Quando o jogador clica na aba **Biblioteca** na sidebar ou no seletor de exibição:
- O painel inferior das 3 colunas recolhe suavemente e dá lugar à **Grade de Capas Verticais (2:3)**.
- **Capas dos Jogos (140 × 210 px):**
  - Carregadas do cache oficial local do PC (`library_600x900`).
  - Efeito hover esportivo: elevação sutil de 4 px, brilho de borda em `--line-strong` e indicador do launcher de origem no canto superior.
  - Ao clicar em qualquer capa, o Hero superior atualiza instantaneamente a arte de fundo, o nome do jogo e a rota correspondente.

---

## 6. Cores e Tokens Oficiais (Dark Competitive UI)

| Token XAML | Hex / Valor | Função no Layout |
| :--- | :--- | :--- |
| `StageBrush` | `#060709` | Fundo externo da janela e barra superior |
| `DeepBrush` | `#0B0D10` | Fundo principal da área de conteúdo |
| `SurfaceBrush` | `#15181E` | Fundo dos 3 cartões inferiores e sidebar ativa |
| `PanelBrush` | `#1E232B` | Pílulas de filtro ativas, hover e caixas de status |
| `LineBrush` | `rgba(244, 245, 247, 0.08)` | Bordas de 1 px nos cartões e divisórias |
| `LineStrongBrush` | `rgba(244, 245, 247, 0.16)` | Contorno de botões secundários e foco |
| `TextPrimaryBrush` | `#F4F5F7` | Nomes de jogos, títulos e CTA primário |
| `TextSecondaryBrush` | `#8A93A0` | Metadados, descrições de rota e horas jogadas |
| `TextTertiaryBrush` | `#606873` | Rótulos técnicos, Cascadia Mono e versão |
| `PurpleBrush` | `#7C3AED` | Botão "Jogar" primário e acentos ativos |
| `ReadyBrush` | `#22C55E` | Indicador de rota perfeita e pronto para ranked |
| `CautionBrush` | `#F59E0B` | Aviso de oscilação ou ping elevado |
| `CoralBrush` | `#FF5A36` | Alerta de perda de pacotes ou rota rompida |

---

## 7. Tipografia Oficial

- **Títulos e Jogos:** **Barlow Semi Condensed** (Bold 700 / ExtraBold 800) — Título do jogo no Hero (34 px), vereditos e cabeçalhos dos cartões.
- **Corpo e Navegação:** **Barlow** (Medium 500 / SemiBold 600) — Itens da sidebar, pílulas de filtro e botões.
- **Telemetria e Latência:** **Chakra Petch** (SemiBold 600) — Valores numéricos de ping (`14 ms`), jitter (`0.8 ms`) e perda (`0.0%`).
- **Metadados de Rede:** **Cascadia Mono** (SemiBold 600) — Nomes de datacenters (`SA-EAST-1`), versão do build e taxas de interface.

---

## 8. Anti-padrões e Diretrizes Rígidas

1. **Nunca travar o botão de jogar:** O jogador é dono do PC dele; o check de rota informa a realidade, mas jamais impede ou atrasa o clique no jogo.
2. **Sem artes proprietárias no instalador:** Capas e banners são lidos do cache local do próprio PC do usuário em tempo de execução (Decisão 118).
3. **Sem poluição de loja:** O LagCheck não é uma loja de jogos. Não existem preços, promoções ou botões de compra.
4. **Sem dados inventados:** Se a rota ainda não foi testada para um título, exibe-se travessão (`— ms`), nunca estimativa falsa ou zero milissegundos.
