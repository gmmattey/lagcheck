# LagCheck — sistema de design (V1)

**Status:** rascunho implementation-ready para V1
**Idioma do documento:** PT-BR
**Sistema mínimo:** iOS 17, SwiftUI
**Documentos relacionados:** [Funcional](./01-funcional.md) · [Arquitetura](./02-arquitetura.md) · [Especificação técnica](./03-especificacao-tecnica.md)
**Ativos relacionados:** `design-system/tokens/`, `design-system/assets/brand/`, `design-system/assets/app-icon/`, `design-system/components.md`
**Protótipo iOS canônico:** [`design-system/prototypes/ios-reference/`](../design-system/prototypes/ios-reference/)

Este documento não altera nem substitui os três documentos funcionais/técnicos existentes. Ele traduz as regras de produto já fechadas (Seções 7, 11 e 12 do documento funcional; Seção 9 da arquitetura) em um sistema visual consistente e implementável.

> **Status dos ativos de marca:** wordmark, símbolo compacto e App Icons presentes em `design-system/assets/` são os ativos oficiais e aprovados do LagCheck para a V1. Eles são a fonte de verdade para produto, App Store e materiais de divulgação; não há pendência de criação ou aprovação de marca.

> **Status dos ativos de marca:** wordmark, símbolo compacto e App Icons presentes em `design-system/assets/` são os ativos oficiais e aprovados do LagCheck para a V1. Eles são a fonte de verdade para produto, App Store e materiais de divulgação.
>
> **Direção Visual Vigente (Decisões 51 e 66 — Dark Competitive UI):** O LagCheck adota a direção visual de **produto gamer competitivo de alta performance**, substituindo a estética de "utilitário de rede / Apple HIG genérico". A experiência é fundamentada em fundo quase preto, superfícies grafite, arte do jogo como protagonista, painéis de borda fina (eliminando o "card soup"), tipografia pesada, números monoespaçados, telemetria viva compacta e Roxo Gamer (`#7C3AED`) para ações primárias; Coral Solar (`#FF5A36`) reservado a atenção, erro e ações destrutivas (Decisão 66).
>
> **Iniciativa Unificada:** Essa linguagem integra a entrega *“Lagcheck Competitive Redesign + Ready Check”* (Decisões 50 e 51).

## 1. Direção visual: Dark Competitive UI

LagCheck fala a linguagem de jogadores competitivos: **impacto, foco, clareza e performance imediata**. Três princípios guiam toda decisão visual:

1. **Veredito antes das métricas:** O jogador descobre instantaneamente se a conexão está pronta para a partida (`● PRONTO PARA RANKED` ou `▲ EU EVITARIA RANKED AGORA`). O score 0–100 e métricas aprofundadas ficam subordinados à decisão.
2. **O jogo é o protagonista:** O artwork do jogo ocupa o espaço central de prestígio da tela. A rede e a telemetria apoiam a experiência com precisão cirúrgica, sem transformar o app em um painel de NOC.
3. **Gamer premium, limpo e direto:** Nada de RGB espalhado, gradientes cyberpunk caricatos ou dezenas de cards empilhados. Usamos painéis amplos com borda fina (1px `rgba(255, 255, 255, 0.08)`), tipografia pesada, labels em caixa alta compacta e **Roxo Gamer** como acento de ação primária (Decisão 66). O verde é utilizado estritamente com função semântica para indicar condição pronta, nunca como cor corporativa.

### 1.1 Wordmark e regras da marca

- Marca oficial: **LagCheck** (sempre com `lagcheck` em minúsculas).
- Wordmark oficial: símbolo e `check` em Roxo Gamer; `lag` em branco (Decisão 66). O símbolo isolado está em `design-system/assets/brand/app-icon-foreground-only.svg`.
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
| Acento | `accent.primary` | Coral Solar (`#FF6B35`) — CTA, anel de medição, tabs ativas, seleção de categoria. Uso estratégico, não decorativo. |
| Score | `score.excellent` / `score.unstable` / `score.lagRisk` / `score.neutral` | Cores semânticas do LagCheck Score (Seção 4). |
| Gráfico | `graph.line` / `graph.fillTop` / `graph.spike` / `graph.spikeSevere` | Paleta dedicada do LatencyGraph. |

Regra de uso: **no máximo uma ocorrência de `accent.primary` em destaque por tela** (ex.: um botão primário OU o símbolo da marca no header, não ambos competindo). Score e gráfico têm paletas próprias e não competem com o acento de marca.

## 4. Cores semânticas e Vereditos da Dark Competitive UI

A comunicação de estado baseia-se nos vereditos da partida (`GameReadinessVerdict`), e não em semáforos ou velocímetros coloridos:

| Estado / Veredito | Símbolo / Indicador | Token | Aplicação |
| --- | --- | --- | --- |
| Pronto para Jogar | `● PRONTO PARA RANKED` | `semantic.ready` | Verde semântico sóbrio (`#22C55E`). Comunica condição saudável para partidas competitivas. |
| Atenção / Instável | `▲ CONDIÇÕES INSTÁVEIS` | `semantic.caution` | Âmbar funcional (`#F59E0B`). Oscilação ou impacto sob carga. |
| Evitaria Ranked | `▲ EU EVITARIA RANKED AGORA` | `semantic.notReady` | Vermelho técnico (`#EF4444`). Perda de pacotes, latência inadequada ou instabilidade severa. |
| Inconclusivo | `— INCONCLUSIVO` | `semantic.neutral` | Cinza frio (`#8A93A0`). Dados insuficientes. |
| Ação Primária | Botões `[ FAZER CHECK ]` e `[ TESTAR NOVAMENTE ]` | `brand.coralSolar` | Coral Solar (`#FF5A36`). Acento exclusivo de ação dominante. |

Regras de aplicação:
- O verde **não é a cor da marca** e nunca deve colorir botões, banners decorativos ou fundos. Ele existe unicamente como indicador de estado no veredito positivo.
- O Coral Solar é a assinatura de ação do app e guia o olhar para o próximo passo.

## 5. Tipografia

A tipografia do LagCheck expressa a energia de alta performance gamer através da família SF Pro com tratamentos específicos:

- **Headlines:** Títulos pesados e imersivos (`.system(size: 28...34, weight: .bold)`), com tracking levemente comprimido. Sem fontes arredondadas ou visual "fofo".
- **Números de Telemetria:** Numerais estritamente monoespaçados (`.monospacedDigit()`, `.heavy` ou `.bold`) para exibir RTT (ms), jitter e perda (%), garantindo estabilidade ótica durante o teste ao vivo.
- **Labels Técnicos:** Caixa alta compacta (Small Caps ou Uppercase com tracking expandido) para tags de telemetria: `PING`, `JITTER`, `PERDA`, `ESTABILIDADE`, `REGIÃO`.
- **Textos de Apoio e Diagnóstico:** Corpo de leitura limpo em branco quente (`#F4F5F7`) e cinza secundário (`#8A93A0`).

## 6. Painéis, bordas e eliminação do "Card Soup"

A Dark Competitive UI abandona cartões soltos empilhados com sombras difusas:
- **Painéis Amplos:** Áreas unificadas com fundo grafite (`#15181E` / `#1E232B`).
- **Borda Fina:** Traço contínuo e discreto de 1px em `rgba(255, 255, 255, 0.08)`, conferindo acabamento de hardware gamer de alta precisão.
- **Raio Contínuo:** Cantos em raio moderno e controlado (12pt a 16pt), sem visual excessivamente arredondado.
- **Hierarquia:** Criada por contraste tonal entre o fundo quase preto (`#0B0D10`) e a superfície dos painéis, dispensando sombras multinível pesadas.

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
- Todos os textos de causa/recomendação (Seção 7 da especificação técnica) são **chaves de mensagem localizáveis**, nunca texto livre vindo do catálogo remoto.
- Diretrizes de texto:
  - PT-BR e inglês devem caber nos mesmos componentes sem quebrar layout; strings de classificação e ação têm um teto informal de ~20 caracteres em inglês e ~24 em PT-BR (o inglês tende a ser mais curto — o design deve acomodar o PT-BR como caso mais exigente).
  - Números, unidades (`ms`, `%`) e formatos de data/hora seguem o `Locale` do sistema, não um formato fixo.
  - Nomes de jogos e regiões vêm do catálogo remoto já traduzidos (`label: { "pt-BR": ..., "en": ... }`, ver especificação técnica Seção 4.3) e não são recompostos pelo app.

## 11. Referência futura — publicidade e consentimento (MVP1.1)

`BannerAdSlot`, publicidade e consentimento não fazem parte do MVP1: não há SDK, tela, reserva de área, placeholder ou gate visual relacionado nesta entrega. Esta seção preserva somente o contrato de design para um MVP1.1 futuro, que exige decisão de produto e implementação própria.

Quando o MVP1.1 for autorizado, aplicar estas regras de layout:

- O `BannerAdSlot` só existe em **Home** e **Histórico**. Nenhuma outra tela reserva espaço para anúncio.
- **Nunca** em Quick Check, Deep Check ou tela de Resultado — nem como placeholder vazio, nem condicionalmente.
- A área é **reservada em layout desde o primeiro render**, com a altura do token `bannerAdSlot.heightStandard` (50pt) ou `heightLarge` (90pt) conforme o tamanho adaptativo retornado pelo SDK, para que o carregamento do anúncio nunca desloque conteúdo já visível (sem "layout shift").
- Se o anúncio falhar ao carregar, a área permanece reservada e vazia (fundo `surfaceAd.background`) — o layout ao redor não deve recolher o espaço nem re-fluir.
- O `BannerAdSlot` nunca cobre, sobrepõe ou fica adjacente sem margem (`adSlotMargin`) a: latência ao vivo, estado do teste, score, classificação, causa, recomendação, ou as ações "Testar novamente" / "Ver detalhes" / "Fazer Deep Check".
- Rótulo de identificação publicitária (`surfaceAd.label`, ex.: "Anúncio"/"Ad") é sempre visível, nunca estilizado para se parecer com conteúdo do LagCheck.

## 12. Inventário de componentes

Anatomia completa, variantes, estados e API SwiftUI pretendida estão em [`design-system/components.md`](../design-system/components.md). Resumo do inventário atualizado (Decisões 24, 34, 35 e 88):

| Componente | Papel |
| --- | --- |
| `MeasurementLiveTrail` | **Trilha Viva de Medição (Decisão 34):** fluxo de pacotes nos 3 nós (`iPhone` ➔ `Wi-Fi` ➔ `Região Gamer`) com partículas proporcionais ao RTT, evaporação de pacotes perdidos e diagnóstico de saturação sob estresse. Substitui o gauge circular e o gráfico abstrato. |
| `RouteTrailSummaryCard` | **Atestado da Rota HIG (Decisão 35):** síntese visual dos 3 nós pós-teste com selos semânticos de integridade (`checkmark.circle.fill` / alertas), integrando o resultado final. |
| `LagCheckScore` | Pílula semântica no topo do Hero Editorial (`[ 92 · EXCELENTE ]`) com tipografia `.monospacedDigit()`. |
| `MetricCard` (Grid 2x2) | Cards compactos com curvatura contínua 12pt para Ping, Jitter, Perda de Pacotes e Picos de Latência, com realce automático de cor na causa raiz. |
| `PlatformSelectionSheet` | Seleção interativa da plataforma de jogo (iPhone, PlayStation, Xbox, PC, Nintendo Switch) antes de iniciar a medição. |
| `PrimaryButton` | Ação principal da tela (Coral Solar `#FF6B35`, pílula, alto contraste, 52pt). |
| `InsightBanner` | Explicação/causa em destaque da qualidade observada para a partida. |
| `StatusMessage` | Estados de progresso, erro, cancelamento e inconclusivo. |
| `EmptyState` | Ausência de histórico, catálogo indisponível, busca sem resultado. |
| `GameReadinessWidget` | Superfície compacta de sistema: arte editorial autorizada do último Check válido, gradiente profundo, jogo/região, P50 monoespaçado e veredito por texto+forma. Home Screen usa arte como contexto; Lock Screen retangular usa miniatura; circular/inline priorizam legibilidade. |

O `GameReadinessWidget` usa exclusivamente a arte editorial fornecida pelo catálogo validado da plataforma em que está instalado. A imagem recebe gradiente `background.deep` suficiente para não reduzir contraste do veredito e da P50; não há texto sobre área clara sem sobreposição. Resultado vencido, inconclusivo ou sem arte válida remove métricas e veredito, mantendo apenas a ação localizada de novo Check e identidade neutra. O widget não introduz uma cor de CTA: Roxo Gamer é reservado ao ícone/arte neutra e as cores semânticas aparecem acompanhadas por headline e indicador de forma.

### Navegação de retorno

Configurações abre como tela própria pelo ícone de ajustes, nunca por gaveta lateral. A tela usa `List` agrupada do iPhone, preservando o fundo visual do LagCheck; Histórico, preferências, privacidade e informações do app seguem a hierarquia nativa. O fundo do app é um degradê contínuo da escala de azuis do produto, sem ilustração ou textura, para não competir com a jornada.

Na vitrine de jogos, a busca começa como uma lupa no canto superior direito. Ao tocar, ela se expande no mesmo eixo para o campo nativo de texto e revela os filtros de categoria; fechar a busca limpa texto e filtros, devolve a lupa e não ocupa espaço permanente na Home. Na Home, a wordmark fica alinhada à esquerda e busca e Ajustes são agrupados à direita em uma única cápsula Glass, com lupa seguida de reticências. Isso evita controles circulares concorrendo com a marca e preserva dois alvos independentes de 44 pt.

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

Referência de MVP1.1, fora do inventário e dos gates visuais do MVP1: `BannerAdSlot`, para publicidade em Home e Histórico somente. Não implementar ou reservar sua área antes da autorização específica do MVP1.1.

### 12.1 Recorte aprovado do piloto de Quick Check

- O piloto tem um único jogo, uma única região e contexto iPhone fixo. Não apresenta seleção de console/PC nem nota de estimativa de equipamento externo.
- A tela de medição reproduz o cabeçalho, jogo, região, ping atual, pulso/progresso, `LatencyGraph` vivo, perda, picos e fase textual do protótipo canônico. O cabeçalho com retorno inclui sempre a wordmark oficial `lagcheck`; ele não pode ser substituído por título vazio. O ping atual é conteúdo de acompanhamento da medição, não um score.
- O botão de voltar durante a medição é um cancelamento explícito: interrompe a sessão e descarta todos os dados parciais antes de mostrar o estado cancelado.
- As ações de Deep Check e de detalhes não são renderizadas no resultado do piloto. Não há botão desabilitado, placeholder ou ação sem destino.
- Resultado saudável e resultado com risco mantêm a ordem score, classificação, conclusão, evidência, métricas e insight. A distância `resultConclusionToMetrics` continua obrigatória.
- Inconclusivo por respostas UDP insuficientes mostra `StatusMessage.inconclusive`: “Não conseguimos dados suficientes para avaliar sua conexão. Tente novamente em instantes.”, com a ação “Tentar novamente”.
- Cancelamento por voltar, troca de rede ou ciclo de vida mostra `StatusMessage.cancelled`: explica o motivo aplicável, confirma o descarte da leitura parcial e oferece “Reiniciar teste”.
- A matriz completa de composição, divergências aprovadas e gate de acessibilidade do piloto está em [`10-decisao-experiencia-piloto.md`](./10-decisao-experiencia-piloto.md). Ela não substitui a validação visual/interativa exigida antes de declarar paridade.

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
7. **Sem SDKs externos no módulo.** `LagCheckDesign` não importa Google Mobile Ads, SwiftData, Network nem nenhum adaptador de `Infrastructure`. `BannerAdSlot` é apenas uma referência visual futura do MVP1.1; não há componente, reserva de layout ou injeção de SDK a implementar no MVP1. Se essa frente for autorizada, a `View` do SDK deverá ficar fora do módulo, em `Features`/`App`, via closure ou `UIViewRepresentable`.
8. **Geração a partir dos tokens JSON**: os arquivos em `Tokens/` devem ser gerados (manual ou por script) a partir de `design-system/tokens/*.json`, preservando os mesmos nomes semânticos (`NLColor.scoreExcellent`, `NLSpacing.resultConclusionToMetrics`, etc.), para que designer e engenheiro leiam o mesmo vocabulário nos dois lados.
