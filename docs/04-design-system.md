# LagCheck — sistema de design (V1)

**Status:** referência do sistema de design (atualizado pelas Decisões 124–145)
**Idioma do documento:** PT-BR
**Fonte visual canônica multiplataforma:** [`shared/design-system/DESIGN.md`](../shared/design-system/DESIGN.md) e [`shared/design-system/tokens/`](../shared/design-system/tokens/)
**Documentos relacionados:** [Funcional](./01-funcional.md) · [Arquitetura](./02-arquitetura.md) · [Especificação técnica](./03-especificacao-tecnica.md) · [Design Windows](./09-design-system-windows.md) · [Adaptação WinUI 3](../apps/windows/DESIGN.md)
**Ativos relacionados:** `shared/design-system/tokens/`, `shared/design-system/assets/brand/`, `shared/design-system/assets/app-icon/`, `shared/design-system/components.md`

Este documento traduz as regras de produto em um sistema visual consistente para os apps nativos. Em caso de divergência entre seções históricas deste arquivo e `shared/design-system/DESIGN.md` ou `docs/DECISOES.md`, prevalecem `docs/DECISOES.md` e `shared/design-system/DESIGN.md`.

> **Status dos ativos de marca (Decisão 124):** o símbolo oficial é `lagcheck-mark.svg` ("L + check" com órbita) e a wordmark oficial é `wordmark-primary.svg` (`Lagcheck`, substituindo a grafia em minúsculas da Decisão 25). O App Icon oficial é gerado a partir do mesmo símbolo em `shared/scripts/generate-brand-icons.py`.
>
> **Direção Visual Vigente (Decisões 51, 66, 125–128, 143–145 — Dark Competitive UI):** fundo quase preto (`#0B0D10`), superfícies grafite (`#15181E` / `#1E232B`), profundidade por contraste tonal sem linhas de contorno em cards/busca/pílulas/anúncios (Decisão 128), tríade tipográfica **Barlow Semi Condensed** + **Barlow** + **Chakra Petch** (Decisão 125), raios `8 / 12 / 26 / pill` (Decisão 126), títulos de tela em caixa alta (Decisão 145) e **Roxo Gamer** (`#7C3AED`) restrito ao CTA principal; **Coral Solar** (`#FF5A36`) reservado a atenção, erro e ações destrutivas.

## 1. Direção visual: Dark Competitive UI

LagCheck fala a linguagem de jogadores competitivos: **impacto, foco, clareza e performance imediata**. Três princípios guiam toda decisão visual:

1. **Veredito antes das métricas:** O jogador descobre instantaneamente se a conexão está pronta para a partida (`● PRONTO PARA RANKED` ou `▲ EU EVITARIA RANKED AGORA`). O score 0–100 e métricas aprofundadas ficam subordinados à decisão.
2. **O jogo é o protagonista:** O artwork do jogo ocupa o espaço central de prestígio da tela. A rede e a telemetria apoiam a experiência com precisão cirúrgica, sem transformar o app em um painel de NOC.
3. **Gamer premium, limpo e direto:** Nada de RGB espalhado, gradientes cyberpunk caricatos ou dezenas de cards empilhados. Usamos camadas tonais por contraste (`#0B0D10`, `#15181E`, `#1E232B`) sem linhas de contorno em cards, campos de busca, pílulas ou anúncios (Decisão 128), títulos de tela em caixa alta (Decisão 145) e **Roxo Gamer** (`#7C3AED`) como acento exclusivo de ação primária (Decisão 66). O verde é utilizado estritamente com função semântica para indicar condição pronta, nunca como cor corporativa.

### 1.1 Wordmark e regras da marca

- Marca oficial: **LagCheck** no texto e wordmark **Lagcheck** (`wordmark-primary.svg`, Decisão 124).
- Símbolo oficial: `lagcheck-mark.svg` ("L" roxo com faixas de velocidade, check branco e órbita com dois nós), localizado em `shared/design-system/assets/brand/`.
- Fundos aprovados: Quase preto profundo (`#0B0D10`).
- Sem símbolo ™ ou ® nesta versão.

## 2. Modo de cor

**Dark mode exclusivo.** O fundo de todas as telas é o quase preto absoluto/profundo (`#0B0D10`), complementado por superfícies em grafite (`#15181E`) e painéis de dados em cinza escuro (`#1E232B`).

Consequências práticas para implementação:
- O app força `.preferredColorScheme(.dark)` no root SwiftUI.
- Nenhuma view lê `colorScheme` para alternar para tema claro.
- Alto contraste e redução de transparência continuam suportados como configurações de acessibilidade.
- Configurações do sistema como "Aumentar Contraste" e "Reduzir Transparência" continuam suportadas (ver Seção 6) mesmo com um único tema.

## 3. Paleta

Ver `design-system/tokens/colors.json` para os valores exatos e a estrutura `core` → `semantic`. Resumo:

| Camada | Token semântico | Papel |
| --- | --- | --- |
| Fundo | `background.base` | Fundo padrão, azul-marinho profundo quase preto. |
| Fundo | `background.raised` / `background.overlay` | Cards, sheets, banners — camadas de profundidade sem sombra pesada. |
| Texto | `text.primary` / `text.secondary` / `text.tertiary` | Hierarquia de leitura. |
| Acento | `action.primary` | Roxo Gamer (`#7C3AED`) — CTA principal, seleção ativa e progresso (Decisão 66). Nunca usado em fundos amplos ou filtros. |
| Score | `score.excellent` / `score.unstable` / `score.lagRisk` / `score.neutral` | Cores semânticas do LagCheck Score (Seção 4). |
| Gráfico | `graph.line` / `graph.fillTop` / `graph.spike` / `graph.spikeSevere` | Paleta dedicada do LatencyGraph. |

Regra de uso: **no máximo uma ocorrência de `action.primary` (`#7C3AED`) em destaque por tela** (o CTA principal). Score e gráfico têm paletas próprias e não competem com o acento de marca.

## 4. Cores semânticas e Vereditos da Dark Competitive UI

A comunicação de estado baseia-se nos vereditos da partida (`GameReadinessVerdict`), e não em semáforos ou velocímetros coloridos:

| Estado / Veredito | Símbolo / Indicador | Token | Aplicação |
| --- | --- | --- | --- |
| Pronto para Jogar | `● PRONTO PARA RANKED` | `semantic.ready` | Verde semântico sóbrio (`#22C55E`). Comunica condição saudável para partidas competitivas. |
| Atenção / Instável | `▲ CONDIÇÕES INSTÁVEIS` | `semantic.caution` | Âmbar funcional (`#F59E0B`). Oscilação ou impacto sob carga. |
| Evitaria Ranked | `▲ EU EVITARIA RANKED AGORA` | `semantic.notReady` | Coral Solar (`#FF5A36`). Perda de pacotes, latência inadequada ou instabilidade severa. |
| Inconclusivo | `— INCONCLUSIVO` | `semantic.neutral` | Cinza frio (`#8A93A0`). Dados insuficientes. |
| Ação Primária | Botões `[ TESTAR AGORA ]` e `[ TESTAR NOVAMENTE ]` | `gamerPurple.primary` | Roxo Gamer (`#7C3AED`), cantos `12 px`, sem anéis externos (Decisões 66, 126 e 144). |

Regras de aplicação:
- O verde **não é a cor da marca** e nunca deve colorir botões, banners decorativos ou fundos. Ele existe unicamente como indicador de estado no veredito positivo.
- O Coral Solar (`#FF5A36`) fica reservado exclusivamente a risco, erro, alerta crítico e ações destrutivas (Decisão 66).

## 5. Tipografia

A tipografia do LagCheck segue a tríade unificada nas quatro frentes (iOS, Android, Windows e Web — Decisão 125):

- **Títulos e vereditos (`Barlow Semi Condensed` 700/800):** títulos de tela (sempre em **CAIXA ALTA**: `JOGOS`, `HISTÓRICO`, `AJUSTES` / `CONFIGURAÇÕES`, `DETALHES`, `DETALHES TÉCNICOS`, `DADOS DA REDE`, Decisão 145), nomes de jogo em destaque e manchete de veredito, com tracking negativo.
- **Corpo e controles (`Barlow` 400/500/600):** textos explicativos, listas, campos de busca, barra de navegação inferior (capitalização normal) e rótulos de botões.
- **Telemetria e rótulos técnicos (`Chakra Petch` 600, `tnum`):** valores de ping, jitter, perda, score, rótulos de seção (`SEUS FAVORITOS`, `POPULARES`, `ESTABILIDADE DA REDE`) e metadados técnicos com algarismos tabulares.

## 6. Profundidade sem contornos e eliminação do "Card Soup"

A Dark Competitive UI abandona cartões soltos empilhados e linhas de contorno (Decisão 128):
- **Camadas tonais:** áreas construídas com contraste direto entre fundo (`#0B0D10`), superfície (`#15181E`) e painel elevado (`#1E232B`), evitando card dentro de card.
- **Sem contorno em cards, pílulas, busca e anúncios:** a separação vem do contraste entre superfícies e sombra sutil em sheets/CTAs.
- **Raio Contínuo:** `8 px` para mídia/capas (`3:4`) e métricas; `12 px` para campos de busca, cartões compactos e CTAs; `26 px` para bottom sheets; `999 px` para pílulas concisas e tab bar flutuante.

## 7. Motion e Telemetria Viva

O movimento no LagCheck existe exclusivamente para comunicar medição real de dados:
- **Pulso de Sinal Ativo:** Durante o Check, uma linha de pulso estilizada (`───╲_╱──╲_╱──`) reage à cadência das amostras UDP.
- **Micro-telemetria Dinâmica:** Mensagens rotativas em texto calmo no rodapé informam a etapa em execução (*"Verificando estabilidade..."*, *"Procurando perda de pacotes..."*, *"Testando sob uso..."*).
- **Redução de Movimento:** Quando habilitada no iOS, substitui animações de pulso por indicador estático limpo e cross-fades discretos.

## 8. Acessibilidade

Acessibilidade é requisito de lançamento, não um passe de revisão posterior (alinhado à Seção 9 "Requisitos arquiteturais de qualidade" da arquitetura: *"Toda conclusão e estado relevante funciona em PT-BR e inglês; localização não modifica regras de score"* — o mesmo padrão vale para acessibilidade).

### 9.1 Dynamic Type

- Todo texto de produto usa os estilos semânticos de `typography.json`, que mapeiam para text styles nativos do sistema e escalam automaticamente, incluindo os tamanhos de acessibilidade AX1–AX5.
- O layout do resultado (`LagCheckScore` + classificação + `MetricRow`s) muda de composição horizontal para vertical automaticamente a partir de `DynamicTypeSize.accessibility3`, evitando truncamento do score ou das métricas.
- `minimumScaleFactor` é proibido em texto de decisão (score, classificação, texto de ação). É permitido, com piso de 0.8, apenas em rótulos curtos de badge (ex.: tag de plataforma) onde o truncamento comprometeria mais a leitura do que a leve redução de escala.
- Nenhum componente do Quick Check limita score, RTT, classificação, mensagem de estado ou CTA a um subconjunto de tamanhos de acessibilidade. AX1–AX5 é o intervalo obrigatório; quando necessário, `ViewThatFits` ou composição vertical substitui redução, corte ou truncamento.

### 9.2 VoiceOver

- Ordem de leitura de VoiceOver segue a ordem visual e a regra de produto: score → classificação → frase-resumo → métricas → ações. Nenhum container agrupa esses elementos de forma que a leitura pule a conclusão.
- `LagCheckScore` expõe um `accessibilityLabel` único e completo (ex.: "LagCheck Score 92, Excelente, pronto para jogar"), evitando que VoiceOver leia número e classificação como dois elementos desconexos.
- `MeasurementPulse` expõe estado textual do progresso ("Medindo latência", "Verificando estabilidade", "Procurando picos de lag") como `accessibilityValue`, atualizado a cada mudança de fase, para que quem usa VoiceOver acompanhe o teste sem depender do gráfico.
- `LatencyGraph` expõe um resumo textual equivalente (mediana, pior spike, contagem de spikes) via `accessibilityLabel`, já que o gráfico em si não é navegável ponto a ponto.
- Todo alvo interativo respeita o mínimo de 44×44pt (`tokens/sizing.json`), independentemente do tamanho visual do ícone.
- Uma mensagem de estado e sua recuperação são elementos distintos: VoiceOver lê primeiro a mensagem e expõe em seguida o botão `Tentar novamente` ou `Reiniciar teste`. Não combinar um `Button` dentro de um container que o torne indisponível como ação.
- Labels, valores e hints de acessibilidade são strings localizáveis. Um leitor de tela em inglês não pode receber instrução em PT-BR.

### 9.3 Contraste

- Combinações de texto sobre fundo seguem no mínimo WCAG AA (4.5:1 para texto normal, 3:1 para texto grande/ícones). `text.tertiary` sobre `background.base` é o par de menor contraste do sistema e é reservado a metadados não essenciais à decisão (nunca usado em score, classificação, causa ou CTA).
- As quatro cores semânticas do score foram escolhidas para permanecerem distinguíveis também para as formas mais comuns de daltonismo (deuteranopia/protanopia): a diferenciação nunca depende só de matiz — classificação textual e ícone/forma sempre acompanham a cor.
- Quando "Aumentar Contraste" está ativo no iOS, bordas sutis (`border.subtle`) são promovidas a `border.strong` e o texto `secondary` é promovido a `primary` em contextos de decisão.

### 9.4 Reduzir Movimento

Coberto na Seção 8. Reduzir Movimento é tratado como estado de primeira classe dos tokens de motion, não como exceção tratada tela a tela.

## 10. Localização (PT-BR e inglês)

- PT-BR e inglês são suportados desde a V1 em toda superfície do MVP1: estados de erro, resultado, detalhes, histórico e catálogo. Telas de consentimento e textos publicitários ficam para o MVP1.1, quando essa frente for aprovada e implementada.
- Nenhuma regra de score, guardrail ou confiança muda por idioma — localização afeta apenas apresentação textual (Seção 9, arquitetura).
- Todos os textos de causa/recomendação (Seção 7 da especificação técnica) são **chaves de mensagem localizáveis**, nunca texto livre vindo do catálogo.
- Diretrizes de texto:
  - PT-BR e inglês devem caber nos mesmos componentes sem quebrar layout; strings de classificação e ação têm um teto informal de ~20 caracteres em inglês e ~24 em PT-BR (o inglês tende a ser mais curto — o design deve acomodar o PT-BR como caso mais exigente).
  - Números, unidades (`ms`, `%`) e formatos de data/hora seguem o `Locale` do sistema, não um formato fixo.
  - Nomes de jogos e regiões vêm do catálogo local já traduzidos (`label: { "pt-BR": ..., "en": ... }`, ver especificação técnica Seção 4.3) e não são recompostos pelo app.

## 11. Publicidade e consentimento

As Decisões 96 e 97 autorizam anúncios nativos em Home, Histórico, Jogos e Resultado no Android e no iOS.

Regras de layout para os dois clientes:

- O anúncio nativo ocupa um módulo separado no fluxo de rolagem em **Home**, **Histórico**, **Jogos** e **Resultado**. Não é fixado acima da navegação inferior.
- **Nunca** durante o Check, em Detalhes ou Configurações — nem como placeholder vazio, nem condicionalmente.
- Sem consentimento, carregamento ou após falha, não há módulo ou rótulo publicitário vazio. A inserção de um anúncio carregado deve preservar a posição de rolagem e não deslocar controles essenciais.
- O módulo nativo nunca cobre, sobrepõe ou fica adjacente sem margem (`adSlotMargin`) a latência ao vivo, estado do teste, score, classificação, causa, recomendação ou ações essenciais. No Resultado, aparece após o veredito, métricas, explicação e todas as ações, inclusive compartilhar.
- Rótulo de identificação publicitária (`surfaceAd.label`, ex.: "Anúncio"/"Ad") é sempre visível, nunca estilizado para se parecer com conteúdo do LagCheck.
- Preservar o AdChoices do SDK, patrocinador, texto e ação exigidos pelo formato nativo. A ação publicitária não assume a cor ou a posição da ação primária do app; TalkBack e VoiceOver anunciam publicidade antes dos assets e da ação.

## 12. Inventário de componentes

Anatomia completa, variantes, estados e mapa por plataforma estão em [`shared/design-system/components.md`](../shared/design-system/components.md). Resumo atualizado (Decisões 123–128, 143–145):

| Componente | Papel |
| --- | --- |
| `RouteMeasurementMap` | **Mapa de medição nativo (Decisão 123):** malha de pontos equiretangular com origem aproximada ("Você") e região medida, arcos Bézier e sondas reais durante e após o Check. |
| `RouteTrailSummaryCard` | **Atestado da Rota (Decisão 35):** síntese visual dos 3 nós pós-teste com selos semânticos de integridade (`checkmark.circle.fill` / alertas), integrando o resultado final. |
| `VerdictIndicatorBadge` | Indicador tático de veredito semântico com forma, cor e texto (`PRONTO PARA RANKED`, `CONDIÇÕES INSTÁVEIS`, `EU EVITARIA RANKED AGORA`, `INCONCLUSIVO`). |
| `StabilityEvolutionSection` | **Evolução no Histórico (Decisão 143):** curva de ping por segmento de rede/região (`>= 3` checks válidos) e 4 anéis médios (`Ping méd`, `Jitter`, `Perda`, `Sob carga`), em bloco único sem contorno. |
| `MetricCard` / `MetricBox` | Blocos compactos para Ping, Jitter, Perda de Pacotes e Sob Carga em `Chakra Petch` tabular. |
| `CatalogSearchField` | Barra de busca unificada em **Início**, **Jogos** e seleção de favoritos (`#15181E`, `12 px`, altura mínima `46`, sem borda ou sombra — Decisão 145). |
| `PrimaryButton` | Ação principal da tela (Roxo Gamer `#7C3AED`, cantos `12 px`, altura `58` ou `46` no Hero da Home, sem halo externo duplo — Decisões 126 e 144). |
| `NativeAdSlot` | Faixa horizontal compacta (~`88–96 px`) sem `MediaView` grande e sem linha de contorno em `Início`, `Jogos`, `Histórico` e `Resultado` concluído válido (Decisão 144). |
| `StatusMessage` | Estados de progresso, erro, cancelamento e inconclusivo. |
| `EmptyState` | Ausência de histórico, catálogo indisponível, busca sem resultado (com fallback para Check Geral). |
| `GameReadinessWidget` | Superfície compacta de sistema: arte editorial autorizada do último Check válido, gradiente profundo, jogo/região, P50 monoespaçado e veredito por texto+forma. |

O `GameReadinessWidget` usa exclusivamente a arte editorial fornecida pelo catálogo validado da plataforma em que está instalado. A imagem recebe gradiente `background.deep` suficiente para não reduzir contraste do veredito e da P50; não há texto sobre área clara sem sobreposição. Resultado vencido, inconclusivo ou sem arte válida remove métricas e veredito, mantendo apenas a ação localizada de novo Check e identidade neutra. O widget não introduz uma cor de CTA: Roxo Gamer é reservado ao ícone/arte neutra e as cores semânticas aparecem acompanhadas por headline e indicador de forma.

### Navegação de retorno

Configurações/Ajustes abre como destino próprio na barra de 4 abas (`Início`, `Jogos`, `Histórico`, `Ajustes`/`Configurações` — Decisões 80 e 98), nunca por gaveta lateral. Todas as telas principais e secundárias exibem o título em **CAIXA ALTA** (`JOGOS`, `HISTÓRICO`, `AJUSTES` / `CONFIGURAÇÕES`, `DETALHES`, `DETALHES TÉCNICOS`, `DADOS DA REDE`), mantendo a barra inferior com capitalização normal.

Na Home (`Início`), a arte do Hero ocupa toda a largura da tela até o topo atrás da barra de status com gradiente contínuo para `#0B0D10`, acompanhada pelo botão sólido compacto `TESTAR AGORA` (`#7C3AED`, altura `46`, cantos `12 px`). Logo abaixo do Hero fica a barra de busca padronizada (`#15181E`, `12 px`, sem borda/sombra), seguida por `SEUS FAVORITOS` e `POPULARES` em grade fixa **2 linhas × 3 colunas** (`3:4`) com `"Toque no jogo para iniciar o teste"`. Na aba `Jogos`, a busca permanece sempre visível com o mesmo visual da Home acima da grade de **3 colunas** (`3:4`).

Cards da Home não usam contorno em repouso. A separação do fundo vem da elevação definida em `shadow.json`: sombra curta para o atalho de última medição e elevação mais marcada para o bloco de iniciar medição. Com Reduzir Transparência, as sombras são removidas e a diferença entre superfícies preserva a hierarquia.

No bloco “Pronto para medir”, o nome do jogo é o herói; não há ilustração genérica. Ao selecionar outro jogo, o card inteiro vira no eixo vertical com a transição `gameSelectionCard`. Com Reduzir Movimento, a troca é somente dissolução curta.

O acesso a Ajustes e o retorno usam símbolos SF e área de toque de 44 pt. Fora da Home, a wordmark fica centralizada nas telas de jornada; na Home, segue o alinhamento à esquerda descrito acima. No iOS 26 ou posterior, ações isoladas adotam o acabamento Glass circular do sistema e as ações agrupadas usam uma cápsula Glass; no iOS 17 a 25, seguem como botões de barra sem fundo desenhado pelo app. A ação mantém sua semântica de origem — durante uma medição, por exemplo, retornar continua sendo cancelamento explícito e seguro.

Quando a rota de referência não puder ser confirmada antes da medição, a jornada mostra um estado de falha próprio, sem o card de contexto. O estado usa apenas um `x` discreto em círculo, título, explicação curta, ação primária para tentar novamente e ação secundária para voltar ao início. Não usa emoji, ilustração ou linguagem que prometa diagnóstico do jogo.

Ao tentar novamente, a própria tela de falha troca a ação primária por um progresso curto de confirmação; ela não navega para uma tela técnica intermediária. Quando o catálogo assinado de base já permite a jornada, a Home não exibe aviso sobre atualização de lista: a origem do catálogo não é uma informação útil para a pessoa jogar.

Toda tela de jornada aberta dentro do app precisa expor uma saída visível no mesmo padrão: controle circular Glass com chevron para retornar, animação nativa de volta e alvo mínimo de 44 pt. Isso se aplica a Ajustes, Histórico e detalhes de medições ou Deep Check; uma folha apresentada não pode depender somente do gesto de arrastar para baixo.

A wordmark fica restrita à Home. As telas internas usam cabeçalho mínimo, título próprio e uma única ação de retorno; o gesto nativo de voltar continua disponível onde houver uma pilha de navegação. Superfícies internas não usam contorno decorativo: a separação acontece por contraste e profundidade discreta.

Configurações conserva a organização agrupada do iPhone, mas usa superfícies azul-escuras translúcidas, divisórias nativas discretas e símbolos SF por linha para ficar no mesmo sistema visual da Home. Links sem configuração válida não aparecem como itens indisponíveis; eles entram somente quando o build recebe a URL segura correspondente.

A entrada da vitrine para o contexto de um jogo usa uma navegação `NavigationStack` real, com a transição de avanço e retorno do iPhone. Não trocar telas de jornada por substituição estática de conteúdo.

No contexto do jogo, plataforma e região aparecem como dois fatos escaneáveis. A limitação de precisão permanece obrigatória, mas é apresentada uma única vez em texto curto, sem repetir a mesma informação em frase, card e descrição.

`BannerAdSlot` é referência histórica de MVP1.1; as Decisões 96 e 97 adotam o módulo nativo nas quatro superfícies de cada plataforma.

### 12.1 Recorte aprovado do piloto de Quick Check

- O piloto tem um único jogo, uma única região e contexto iPhone fixo. Não apresenta seleção de console/PC nem nota de estimativa de equipamento externo.
- A tela de medição reproduz o cabeçalho, jogo, região, ping atual, pulso/progresso, `LatencyGraph` vivo, perda, picos e fase textual do protótipo canônico. O cabeçalho com retorno inclui sempre a wordmark oficial `lagcheck`; ele não pode ser substituído por título vazio. O ping atual é conteúdo de acompanhamento da medição, não um score.
- O botão de voltar durante a medição é um cancelamento explícito: interrompe a sessão e descarta todos os dados parciais antes de mostrar o estado cancelado.
- As ações de Deep Check e de detalhes não são renderizadas no resultado do piloto. Não há botão desabilitado, placeholder ou ação sem destino.
- Resultado saudável e resultado com risco mantêm a ordem score, classificação, conclusão, evidência, métricas e insight. A distância `resultConclusionToMetrics` continua obrigatória.
- Inconclusivo por respostas UDP insuficientes mostra `StatusMessage.inconclusive`: “Não conseguimos dados suficientes para avaliar sua conexão. Tente novamente em instantes.”, com a ação “Tentar novamente”.
- Cancelamento por voltar, troca de rede ou ciclo de vida mostra `StatusMessage.cancelled`: explica o motivo aplicável, confirma o descarte da leitura parcial e oferece “Reiniciar teste”.
- A matriz completa de composição, divergências aprovadas e gate de acessibilidade do piloto está em [`10-decisao-experiencia-piloto.md`](archive/decisoes/10-decisao-experiencia-piloto.md). Ela não substitui a validação visual/interativa exigida antes de declarar paridade.

## 13. Convenções do módulo SwiftUI `LagCheckDesign`

`LagCheckDesign` é um Swift Package/módulo local, sem dependência de rede, UI ou domínio de medição — importável por `Features` e por `App`, nunca o contrário.

```text
LagCheckDesign/
├── Sources/LagCheckDesign/
│   ├── Tokens/          // enums/structs gerados a partir de design-system/tokens/*.json
│   │   ├── NLColor.swift
│   │   ├── NLTypography.swift
│   │   ├── NLSpacing.swift
│   │   ├── NLRadius.swift
│   │   ├── NLShadow.swift
│   │   ├── NLMotion.swift
│   │   └── NLSizing.swift
│   ├── Components/      // um arquivo por componente do inventário da Seção 12
│   ├── Brand/           // wordmark e símbolo como Image/Shape SwiftUI, gerados a partir dos SVGs-fonte
│   └── Previews/        // SwiftUI Previews cobrindo todas as variantes/estados de cada componente
└── Tests/LagCheckDesignTests/
    └── SnapshotTests/   // snapshots por componente, incluindo Dynamic Type grande e Reduzir Movimento
```

Convenções obrigatórias:

1. **Tokens primeiro, valores mágicos nunca.** Nenhuma `Feature` referencia um hex, ponto de espaçamento, raio, duração ou tamanho de fonte diretamente — sempre via `LagCheckDesign.NL*`. Um valor numérico solto em uma view de `Features/` é considerado bug de design system.
2. **Nomenclatura**: tipos públicos do módulo usam o prefixo `NL` (`NLColor`, `NLButtonStyle`, `NLScoreRing`) para não colidir com tipos do SwiftUI/domínio e para deixar explícito, em qualquer arquivo, quando algo vem do design system.
3. **Um arquivo por componente do inventário**, com a View pública, seus modificadores de variante/estado e um `#Preview` cobrindo todas as combinações relevantes (ver `components.md` para a lista de variantes/estados por componente).
4. **Dark mode fixo dentro do módulo**: componentes não devem ler `colorScheme`; todo token já resolve para o valor único da V1. Isso mantém o módulo pronto para, no futuro, ganhar um segundo tema sem reescrever componentes — mas essa extensão não faz parte do escopo desta V1.
5. **Acessibilidade embutida no componente, não em quem o consome.** `accessibilityLabel`, `accessibilityValue`, tamanho mínimo de toque e comportamento em Dynamic Type grande são responsabilidade do componente (Seção 9), não recriados em cada tela que o usa.
6. **Motion via tokens nomeados** (`NLMotion.scoreReveal`, etc.), nunca `withAnimation(.easeInOut(duration: 0.3))` solto em `Features`. Cada API de componente que anima expõe o estado final de forma síncrona quando `UIAccessibility.isReduceMotionEnabled` é verdadeiro.
7. **Sem SDKs externos no módulo.** `LagCheckDesign` não importa Google Mobile Ads, SwiftData, Network nem nenhum adaptador de `Infrastructure`. As Views do SDK das Decisões 96 e 97 ficam na camada de app em cada plataforma, fora do design system. `BannerAdSlot` é apenas referência histórica.
8. **Geração a partir dos tokens JSON**: os arquivos em `Tokens/` devem ser alinhados a `shared/design-system/tokens/*.json`, preservando os mesmos nomes semânticos (`NLColor.*`, `NLTypography.*`, `NLSpacing.*`, `NLRadius.*`) para que designer e engenheiro leiam o mesmo vocabulário nas três plataformas.
