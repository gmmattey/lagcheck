# Nolaggy — sistema de design (V1)

**Status:** rascunho implementation-ready para V1
**Idioma do documento:** PT-BR
**Sistema mínimo:** iOS 17, SwiftUI
**Documentos relacionados:** [Funcional](./01-funcional.md) · [Arquitetura](./02-arquitetura.md) · [Especificação técnica](./03-especificacao-tecnica.md)
**Ativos relacionados:** `design-system/tokens/`, `design-system/assets/brand/`, `design-system/assets/app-icon/`, `design-system/components.md`
**Protótipo iOS canônico:** [`design-system/prototypes/ios-reference/`](../design-system/prototypes/ios-reference/)

Este documento não altera nem substitui os três documentos funcionais/técnicos existentes. Ele traduz as regras de produto já fechadas (Seções 7, 11 e 12 do documento funcional; Seção 9 da arquitetura) em um sistema visual consistente e implementável.

> **Status dos ativos de marca:** wordmark, símbolo compacto e App Icons presentes em `design-system/assets/` são os ativos oficiais e aprovados do Nolaggy para a V1. Eles são a fonte de verdade para produto, App Store e materiais de divulgação; não há pendência de criação ou aprovação de marca.

> **Paridade de interface:** o protótipo canônico e a especificação de design adotam a direção editorial nativa Apple Games (ver `docs/21` e `docs/24`). A implementação iPhone busca paridade 1:1 com seus estados nativos (SF Pro, TabView 4 abas, Hero Carousel, Inset Cards 12pt).

> **Adoção Apple Games Editorial (Decisão 24):** as seções de tipografia, superfícies e componentes deste documento foram atualizadas pela [`24-decisao-adocao-design-system-apple-games.md`](./24-decisao-adocao-design-system-apple-games.md). A tipografia é 100% SF Pro (Oxanium removida) e os raios seguem estritamente a escala Apple HIG.

## 1. Direção visual

Nolaggy é uma ferramenta de decisão, não um painel de rede. A interface deve parecer **premium, calma e confiável** — mais próxima de um app de saúde/performance de qualidade do que de um HUD gamer. Três princípios guiam toda decisão visual:

1. **Conclusão antes das métricas.** Em qualquer tela de resultado, o olho deve encontrar primeiro o Nolaggy Score e a classificação, depois a explicação, e só depois os números. Nenhum layout pode inverter essa ordem.
2. **O jogo é o protagonista; a rede fica em segundo plano.** Arte de capa dos jogos, nomes e contexto de jogo recebem destaque visual. Indicadores técnicos (latência, jitter, perda) são tratados como conteúdo de apoio, nunca como o elemento mais chamativo da tela.
3. **Sem estética gamer clichê.** Não há RGB espalhado, gauges/velocímetros, neon, gradientes cyberpunk, excesso de cards empilhados ("card soup") ou molduras agressivas. O azul elétrico é usado como **acento estratégico** — símbolo da marca, ações primárias, estado selecionado, gráfico de latência — nunca como cor de fundo de tela inteira nem em múltiplos elementos simultâneos na mesma vista.

### 1.1 Wordmark e regras da marca

- Marca oficial: **Nolaggy** (nunca "Nologgy" ou variações).
- Wordmark em minúsculas: `nolaggy`.
- O `gg` do wordmark é substituído pelo **símbolo compacto**: duas argolas entrelaçadas em gradiente azul elétrico, lidas como um infinito e como conexão contínua ("less lag, more play, together always" é o território de mensagem, não um claim a ser impresso no produto).
- O símbolo compacto (`design-system/assets/brand/symbol-compact.svg`) pode ser usado isoladamente como marca d'água, favicon, ícone de app ou selo, sempre que o texto completo "nolaggy" não couber.
- **Não usar símbolo ™️ ou ®️** em nenhum artefato de produto desta V1.
- Área de proteção mínima ao redor do wordmark e do símbolo: altura de uma letra "o" do próprio wordmark (medida no SVG-fonte), em todos os lados.
- Tamanho mínimo de exibição: wordmark completo não deve ser reproduzido abaixo de 96pt de largura; símbolo compacto isolado não deve ser reproduzido abaixo de 20pt (equivalente ao ícone de notificação iOS).
- Fundos aprovados: `background.base` (azul-marinho profundo) e branco/neutro claro para materiais de marketing fora do app. Sobre fotografia ou fundos variáveis, usar sempre a versão monocromática (`wordmark-mono-light.svg`), nunca a versão em gradiente colorido.
- O gradiente do símbolo é fixo (`accent.gradientStart` → `accent.gradientEnd`, ver `tokens/colors.json`). Não recolorir o símbolo com outras cores de marca; variações de contexto usam as versões monocromáticas dedicadas, não um recolorimento ad hoc do gradiente.
- Nunca distorcer, inclinar, espelhar ou aplicar sombra/contorno adicional ao wordmark ou ao símbolo além do especificado nos SVGs-fonte.

### 1.2 Ativos de marca disponíveis

| Arquivo | Uso |
| --- | --- |
| `wordmark-primary.svg` | Wordmark completo, letras em branco-gelo + símbolo em gradiente azul. Uso padrão sobre fundo `background.base`. |
| `wordmark-mono-dark.svg` | Wordmark inteiro em tinta escura sólida, para fundos claros (materiais de marketing, imprensa). |
| `wordmark-mono-light.svg` | Wordmark inteiro em branco sólido, para fundos escuros sem o gradiente de marca (contextos de baixo contraste de cor, impressão em 1 cor). |
| `symbol-compact.svg` | Símbolo `gg`/infinito isolado, gradiente azul, para favicons, selos e uso em espaços reduzidos. |
| `app-icon-source.svg` | Fonte quadrada (sem arredondamento embutido) do ícone do app: fundo azul-marinho em gradiente + símbolo centralizado. Base para todos os PNGs de `assets/app-icon/`. |
| `lockup-thumbnail.svg` | Lockup horizontal ícone + wordmark, para thumbnails de listagem (App Store feature, redes sociais, apresentações). |

Todos os SVGs são os vetores oficiais aprovados da marca, sem fonte externa referenciada, sem imagem raster embutida e sem símbolo ™. Cada arquivo contém `viewBox`, `<title>` e `<desc>` para acessibilidade e indexação.

## 2. Modo de cor

**Dark mode é a única experiência da V1.** O app não implementa um tema claro. O ativo oficial `AppBackground` é o fundo único de todas as telas: um gradiente azul-marinho profundo, protegido por uma sobreposição de `background.base` para preservar contraste. Não recriar esse fundo com cores ou gradientes soltos em features. Isso simplifica o contraste do Nolaggy Score e reforça a identidade "sala escura, foco no jogo".

Consequências práticas para implementação:

- O app força `.preferredColorScheme(.dark)` no root da aplicação SwiftUI.
- Nenhuma tela deve ler `colorScheme` do sistema para alternar paleta.
- Todos os tokens de cor em `design-system/tokens/colors.json` já são os valores finais de produção (não existem pares light/dark).
- Configurações do sistema como "Aumentar Contraste" e "Reduzir Transparência" continuam suportadas (ver Seção 6) mesmo com um único tema.

## 3. Paleta

Ver `design-system/tokens/colors.json` para os valores exatos e a estrutura `core` → `semantic`. Resumo:

| Camada | Token semântico | Papel |
| --- | --- | --- |
| Fundo | `background.base` | Fundo padrão, azul-marinho profundo quase preto. |
| Fundo | `background.raised` / `background.overlay` | Cards, sheets, banners — camadas de profundidade sem sombra pesada. |
| Texto | `text.primary` / `text.secondary` / `text.tertiary` | Hierarquia de leitura. |
| Acento | `accent.primary` | Azul elétrico — CTA, símbolo da marca, seleção ativa. Uso estratégico, não decorativo. |
| Score | `score.excellent` / `score.unstable` / `score.lagRisk` / `score.neutral` | Cores semânticas do Nolaggy Score (Seção 4). |
| Gráfico | `graph.line` / `graph.fillTop` / `graph.spike` / `graph.spikeSevere` | Paleta dedicada do LatencyGraph. |

Regra de uso: **no máximo uma ocorrência de `accent.primary` em destaque por tela** (ex.: um botão primário OU o símbolo da marca no header, não ambos competindo). Score e gráfico têm paletas próprias e não competem com o acento de marca.

## 4. Cores semânticas do Nolaggy Score

O score (0–100) e sua classificação textual (Seção 10.5 do funcional) usam sempre a mesma cor semântica, nunca uma escala contínua de matiz (evita leitura tipo "gauge"/semáforo RGB):

| Faixa | Classificação | Token | Cor |
| --- | --- | --- | --- |
| 90–100 | Excelente | `score.excellent` | Verde calmo (`#3DDC97`) |
| 75–89 | Ótimo | `score.excellent` | Mesmo token de "Excelente" — ambos comunicam "pronto para jogar" |
| 60–74 | Instável | `score.unstable` | Âmbar (`#F5B942`) |
| 0–59 | Risco de lag | `score.lagRisk` | Coral (`#F0525B`) |
| Inconclusivo / cancelado | — | `score.neutral` | Cinza-azulado (`#6B7690`) |

Regras de aplicação:

- A cor semântica se aplica ao anel/traço do `NolaggyScore`, ao selo de classificação e a ícones de estado relacionados (ex.: ícone de alerta em `InsightBanner` quando a causa é crítica).
- **Nunca** usar essas cores para decoração fora do contexto de resultado (por exemplo, não usar `score.lagRisk` como cor de erro genérico de formulário — erros de UI usam `text.primary`/`border.strong` com ícone, não a paleta de score).
- Resultado inconclusivo ou cancelado nunca recebe uma cor de "nota baixa": usa sempre `score.neutral`, reforçando a regra de produto de que inconclusivo não é uma nota ruim.
- Em `MeasurementPulse` (durante o teste, antes de haver score), usa-se `accent.primary`, nunca uma cor de score — a classificação só existe após o encerramento válido da sessão.
- Na tela final do piloto, inconclusivo e cancelado não usam `NolaggyScore`: a composição é `StatusMessage` em tom neutro, sem nota, classificação, métricas parciais, insight ou recomendação para jogar. O estado só oferece uma ação segura de recuperação.

## 5. Tipografia

Oxanium é a fonte de destaque experimental do Nolaggy — títulos, score, categorias e ações — para trazer uma leitura tecnológica com mais presença, sem reproduzir a fonte proprietária de outra marca. O arquivo embarcado é distribuído sob SIL Open Font License 1.1 e sua cópia acompanha o app em `Resources/Fonts/Oxanium-OFL.txt`. SF Pro continua nos textos de leitura e explicações. Ambas as camadas usam Dynamic Type. A escala completa está em `design-system/tokens/typography.json`.

Diretrizes principais:

- `scoreDisplay` (64pt, bold, design `.rounded`) é reservado exclusivamente ao número do Nolaggy Score. Nenhum outro número do produto usa esse estilo.
- `headline` carrega a classificação textual ("Excelente", "Risco de lag") sempre imediatamente abaixo do score, nunca antes dele na ordem de leitura/DOM.
- Textos de causa e recomendação usam `body`; nunca usam ênfase de cor da paleta de score (a cor já está no score/selo — repetir a cor no texto reduz legibilidade e pode falhar contraste).
- Métricas técnicas (`MetricRow`, `Detalhes`) usam `bodyEmphasis` para o rótulo e `subheadlineSecondary` para o valor, mantendo uma hierarquia discreta e não competindo com o score.

## 6. Espaçamento, grid e raios

- Espaçamento em base 4pt (`design-system/tokens/spacing.json`). Margem lateral padrão de tela: 16pt (`screenMarginHorizontal`); telas de medição ativa usam 12pt para dar mais área ao `LatencyGraph`.
- **`resultConclusionToMetrics` (40pt)** é um token dedicado e obrigatório: o espaço vertical entre o bloco de conclusão (score + classificação + frase-resumo) e o bloco de métricas resumidas. Ele existe especificamente para impedir que telas futuras "encolham" essa separação e violem a regra de produto "conclusão antes das métricas".
- Grid de conteúdo: colunas fluidas de largura mínima 104pt para grids de jogos (`GameTile`), com gutter `cardGap` (12pt). Listas usam pilha única de largura total menos as margens de tela.
- Raios (`design-system/tokens/radius.json`): cantos suaves e consistentes — `card` (14pt) para conteúdo padrão, `cardLarge` (18pt) para o cartão de resultado e sheets, `pill` para todo botão primário. Não há uso de cantos vivos (raio 0) em superfícies de conteúdo, apenas em divisores/linhas.

## 7. Elevação

Dark UI não usa sombras pesadas como recurso primário de profundidade. A hierarquia visual vem primeiro de **camadas de superfície** (`background.base` → `raised` → `overlay`) e só secundariamente de sombra sutil + borda de 1pt (`design-system/tokens/shadow.json`, níveis `level0`–`level3`).

- O halo (`glow.scoreAccent`) atrás do `NolaggyScore` é opcional, sempre sutil (24% de opacidade, blur alto) e colorido pela cor semântica do score — nunca um brilho neon saturado.
- Quando "Reduzir Transparência" está ativo no iOS, sombra e halo são substituídos por uma borda sólida de 1pt (`reduceTransparencyFallback`), sem blur.

## 8. Motion

Ver `design-system/tokens/motion.json` para durações, easings e os padrões nomeados (`measurementPulse`, `scoreReveal`, `latencyGraphLiveUpdate`, `screenTransition`, `sheetPresent`).

Princípios:

- Motion comunica **estado do sistema**, não decoração: o pulso indica "medindo agora", a contagem do score indica "resultado chegando", a curva do gráfico indica "isto aconteceu agora".
- Nenhuma animação de loop contínuo roda fora de um estado de medição ativa (`MeasurementPulse`). Fora disso, animações são transições pontuais com início e fim claros.
- **Reduzir Movimento**: cada padrão de motion tem uma `reduceMotionAlternative` explícita no token. A política global é: com "Reduzir Movimento" ativo, nenhuma animação usa escala, translação contínua ou loop — apenas opacidade/cross-fade curtos (≤150ms), exceto transições padrão do próprio sistema iOS (push/pop de navegação, apresentação nativa de sheet), que já respeitam a preferência automaticamente.

## 9. Acessibilidade

Acessibilidade é requisito de lançamento, não um passe de revisão posterior (alinhado à Seção 9 "Requisitos arquiteturais de qualidade" da arquitetura: *"Toda conclusão e estado relevante funciona em PT-BR e inglês; localização não modifica regras de score"* — o mesmo padrão vale para acessibilidade).

### 9.1 Dynamic Type

- Todo texto de produto usa os estilos semânticos de `typography.json`, que mapeiam para text styles nativos do sistema e escalam automaticamente, incluindo os tamanhos de acessibilidade AX1–AX5.
- O layout do resultado (`NolaggyScore` + classificação + `MetricRow`s) muda de composição horizontal para vertical automaticamente a partir de `DynamicTypeSize.accessibility3`, evitando truncamento do score ou das métricas.
- `minimumScaleFactor` é proibido em texto de decisão (score, classificação, texto de ação). É permitido, com piso de 0.8, apenas em rótulos curtos de badge (ex.: tag de plataforma) onde o truncamento comprometeria mais a leitura do que a leve redução de escala.
- Nenhum componente do Quick Check limita score, RTT, classificação, mensagem de estado ou CTA a um subconjunto de tamanhos de acessibilidade. AX1–AX5 é o intervalo obrigatório; quando necessário, `ViewThatFits` ou composição vertical substitui redução, corte ou truncamento.

### 9.2 VoiceOver

- Ordem de leitura de VoiceOver segue a ordem visual e a regra de produto: score → classificação → frase-resumo → métricas → ações. Nenhum container agrupa esses elementos de forma que a leitura pule a conclusão.
- `NolaggyScore` expõe um `accessibilityLabel` único e completo (ex.: "Nolaggy Score 92, Excelente, pronto para jogar"), evitando que VoiceOver leia número e classificação como dois elementos desconexos.
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
- Rótulo de identificação publicitária (`surfaceAd.label`, ex.: "Anúncio"/"Ad") é sempre visível, nunca estilizado para se parecer com conteúdo do Nolaggy.

## 12. Inventário de componentes

Anatomia completa, variantes, estados e API SwiftUI pretendida estão em [`design-system/components.md`](../design-system/components.md). Resumo do inventário do MVP1:

| Componente | Papel |
| --- | --- |
| `NolaggyScore` | Exibição do score (anel + número + classificação). Elemento visual distintivo do resultado. |
| `MeasurementPulse` | Indicador vivo de medição em andamento (Quick/Deep Check). |
| `LatencyGraph` | Gráfico vivo/histórico de latência com marcação de spikes. |
| `GameTile` | Item compacto de jogo para a seleção da Home: card de altura fixa com nome centralizado e categoria como legenda abaixo, sem ilustração genérica repetida. O nome localizado é a identificação primária. |

O jogo selecionado na Home usa apenas uma mudança suave de superfície e halo azul; não usa borda, checkmark nem preenchimento saturado.
| `PlatformSelector` | Seleção de plataforma (iPhone/PlayStation/Xbox/PC/Nintendo) e, quando aplicável, Wi-Fi/Ethernet. |
| `PrimaryButton` | Ação principal da tela (pílula, alto contraste). |
| `MetricRow` | Linha rótulo+valor para métricas (ping, jitter, perda, spikes...). |
| `InsightBanner` | Explicação/causa em destaque (ex.: "Sua conexão fica instável sob carga"). |
| `StatusMessage` | Estados de progresso, erro, cancelamento e inconclusivo. |
| `EmptyState` | Ausência de histórico, catálogo indisponível, busca sem resultado. |

### Navegação de retorno

Configurações abre como tela própria pelo ícone de ajustes, nunca por gaveta lateral. A tela usa `List` agrupada do iPhone, preservando o fundo visual do Nolaggy; Histórico, preferências, privacidade e informações do app seguem a hierarquia nativa. O fundo do app é um degradê contínuo da escala de azuis do produto, sem ilustração ou textura, para não competir com a jornada.

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
- A tela de medição reproduz o cabeçalho, jogo, região, ping atual, pulso/progresso, `LatencyGraph` vivo, perda, picos e fase textual do protótipo canônico. O cabeçalho com retorno inclui sempre a wordmark oficial `nolaggy`; ele não pode ser substituído por título vazio. O ping atual é conteúdo de acompanhamento da medição, não um score.
- O botão de voltar durante a medição é um cancelamento explícito: interrompe a sessão e descarta todos os dados parciais antes de mostrar o estado cancelado.
- As ações de Deep Check e de detalhes não são renderizadas no resultado do piloto. Não há botão desabilitado, placeholder ou ação sem destino.
- Resultado saudável e resultado com risco mantêm a ordem score, classificação, conclusão, evidência, métricas e insight. A distância `resultConclusionToMetrics` continua obrigatória.
- Inconclusivo por respostas UDP insuficientes mostra `StatusMessage.inconclusive`: “Não conseguimos dados suficientes para avaliar sua conexão. Tente novamente em instantes.”, com a ação “Tentar novamente”.
- Cancelamento por voltar, troca de rede ou ciclo de vida mostra `StatusMessage.cancelled`: explica o motivo aplicável, confirma o descarte da leitura parcial e oferece “Reiniciar teste”.
- A matriz completa de composição, divergências aprovadas e gate de acessibilidade do piloto está em [`10-decisao-experiencia-piloto.md`](./10-decisao-experiencia-piloto.md). Ela não substitui a validação visual/interativa exigida antes de declarar paridade.

## 13. Convenções do módulo SwiftUI `NolaggyDesign`

`NolaggyDesign` é um Swift Package/módulo local, sem dependência de rede, UI ou domínio de medição — importável por `Features` e por `App`, nunca o contrário.

```text
NolaggyDesign/
├── Sources/NolaggyDesign/
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
└── Tests/NolaggyDesignTests/
    └── SnapshotTests/   // snapshots por componente, incluindo Dynamic Type grande e Reduzir Movimento
```

Convenções obrigatórias:

1. **Tokens primeiro, valores mágicos nunca.** Nenhuma `Feature` referencia um hex, ponto de espaçamento, raio, duração ou tamanho de fonte diretamente — sempre via `NolaggyDesign.NL*`. Um valor numérico solto em uma view de `Features/` é considerado bug de design system.
2. **Nomenclatura**: tipos públicos do módulo usam o prefixo `NL` (`NLColor`, `NLButtonStyle`, `NLScoreRing`) para não colidir com tipos do SwiftUI/domínio e para deixar explícito, em qualquer arquivo, quando algo vem do design system.
3. **Um arquivo por componente do inventário**, com a View pública, seus modificadores de variante/estado e um `#Preview` cobrindo todas as combinações relevantes (ver `components.md` para a lista de variantes/estados por componente).
4. **Dark mode fixo dentro do módulo**: componentes não devem ler `colorScheme`; todo token já resolve para o valor único da V1. Isso mantém o módulo pronto para, no futuro, ganhar um segundo tema sem reescrever componentes — mas essa extensão não faz parte do escopo desta V1.
5. **Acessibilidade embutida no componente, não em quem o consome.** `accessibilityLabel`, `accessibilityValue`, tamanho mínimo de toque e comportamento em Dynamic Type grande são responsabilidade do componente (Seção 9), não recriados em cada tela que o usa.
6. **Motion via tokens nomeados** (`NLMotion.scoreReveal`, etc.), nunca `withAnimation(.easeInOut(duration: 0.3))` solto em `Features`. Cada API de componente que anima expõe o estado final de forma síncrona quando `UIAccessibility.isReduceMotionEnabled` é verdadeiro.
7. **Sem SDKs externos no módulo.** `NolaggyDesign` não importa Google Mobile Ads, SwiftData, Network nem nenhum adaptador de `Infrastructure`. `BannerAdSlot` é apenas uma referência visual futura do MVP1.1; não há componente, reserva de layout ou injeção de SDK a implementar no MVP1. Se essa frente for autorizada, a `View` do SDK deverá ficar fora do módulo, em `Features`/`App`, via closure ou `UIViewRepresentable`.
8. **Geração a partir dos tokens JSON**: os arquivos em `Tokens/` devem ser gerados (manual ou por script) a partir de `design-system/tokens/*.json`, preservando os mesmos nomes semânticos (`NLColor.scoreExcellent`, `NLSpacing.resultConclusionToMetrics`, etc.), para que designer e engenheiro leiam o mesmo vocabulário nos dois lados.
