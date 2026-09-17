# Nolaggy — inventário de componentes (`NolaggyDesign`)

Companion de [`docs/04-design-system.md`](../docs/04-design-system.md). Cada componente abaixo documenta anatomia, variantes, estados e a API SwiftUI pretendida para o módulo `NolaggyDesign`. Todos os valores citados (cor, espaçamento, raio, tipografia, motion) referenciam os tokens semânticos de `design-system/tokens/` — nenhum valor mágico.

Convenções de leitura: **Anatomia** lista as partes visuais; **Variantes** são configurações escolhidas por quem usa o componente; **Estados** são condições que o próprio componente gerencia ou recebe como binding; **API** é a assinatura pública pretendida.

---

## `NolaggyScore`

Elemento visual distintivo de qualquer resultado. Nunca aparece sem uma classificação textual associada.

**Anatomia**
- Anel de progresso (`NLSizing.nolaggyScore.ring.*`, espessura `ringStrokeWidth.*`), cor = cor semântica do score.
- Número do score, estilo `scoreDisplay`.
- Selo/rótulo de classificação ("Excelente", "Risco de lag"...), estilo `headline`, cor semântica.
- Halo opcional (`NLShadow.glow.scoreAccent`) atrás do anel.
- Frase-resumo opcional abaixo (estilo `body`, `text.secondary`) — usada no resultado principal, omitida na variante `compact`.

**Variantes**
| Variante | Uso | Tamanho de anel |
| --- | --- | --- |
| `.hero` | Resultado principal do Deep Check / repouso do Deep Check | `lg` (216pt) |
| `.standard` | Resultado do Quick Check e resultado secundário (ex.: card de comparação de região) | `md` (160pt) |
| `.compact` | Card de histórico, atalho "Testar de novo" na Home | `sm` (96pt), sem frase-resumo |

**Estados**
- `.revealed(score, classification)` — estado final, anima via `NLMotion.scoreReveal`.
- `.inconclusive` — usa `score.neutral`, sem número (ícone de "—" ou traço), rótulo "Inconclusivo".
- `.cancelled` — usa `score.neutral`, rótulo "Cancelado".
- `.loading` — placeholder discreto (shimmer curto ou anel vazio), usado apenas na transição imediatamente anterior à revelação, nunca como substituto de `MeasurementPulse`.

**API SwiftUI pretendida**
```swift
public struct NolaggyScore: View {
    public enum Style { case hero, standard, compact }
    public enum Outcome {
        case revealed(score: Int, classification: NLScoreClassification)
        case inconclusive
        case cancelled
    }

    public init(
        outcome: Outcome,
        style: Style = .standard,
        summary: String? = nil,
        showsGlow: Bool = true
    )
}
```
- `accessibilityLabel` combina score, classificação e resumo em uma única leitura ("Nolaggy Score 92, Excelente, pronto para jogar").
- Anima com `NLMotion.scoreReveal`; síncrono (sem contagem) quando Reduzir Movimento está ativo.

---

## `MeasurementPulse`

Único indicador de "medição em andamento". Nunca usa cor de score (score ainda não existe nesse momento).

**Anatomia**
- Forma central pulsante (`NLSizing.measurementPulse.diameter`), traço `accent.primary`.
- Valor atual de RTT opcional no centro (ex.: `24 ms`), acompanhado do rótulo localizável “Ping atual”; ele acompanha a coleta e não tem semântica de score.
- Texto de fase abaixo ("Medindo latência", "Verificando estabilidade", "Procurando picos de lag"), estilo `callout`.
- Indicador de tempo restante opcional (ex.: contorno decrescente), sutil, sem numeração regressiva grande.

**Variantes**
| Variante | Uso |
| --- | --- |
| `.quick` | Quick Check (~15s, uma fase de progresso contínuo) |
| `.deepIdle` | Deep Check, fase em repouso |
| `.deepLoad` | Deep Check, fase sob carga — mesmo componente, rótulo de fase diferente |

**Estados**
- `.measuring(phaseLabel)` — loop ativo (`NLMotion.patterns.measurementPulse`).
- `.networkChanged` — transição imediata para `StatusMessage.cancelled`, o `MeasurementPulse` não permanece visível.
- `.finishing` — pequena transição de saída antes de `NolaggyScore` assumir a tela.

**API SwiftUI pretendida**
```swift
public struct MeasurementPulse: View {
    public enum Phase: String { case quick, deepIdle, deepLoad }

    public init(
        phase: Phase,
        phaseLabel: LocalizedStringKey,
        progress: Double? = nil, // 0...1, opcional; nil = indeterminado
        currentRTT: String? = nil // valor já formatado pela apresentação, ex.: "24 ms"
    )
}
```
- `accessibilityValue` é atualizado a cada mudança de `phaseLabel` e inclui o RTT atual quando disponível, permitindo acompanhar o teste via VoiceOver.
- Reduzir Movimento: substitui o pulso por opacidade alternando lentamente (ver `motion.json`).

---

## `LatencyGraph`

Parte da explicação, não decoração — um spike relevante deve ser percebido visualmente enquanto acontece (Seção 7.3 do funcional).

**Anatomia**
- Linha de latência (`graph.line`) com preenchimento em gradiente (`graph.fillTop` → `graph.fillBottom`).
- Marcadores de spike (`graph.spike`) e spike severo (`graph.spikeSevere`).
- Linhas de grade discretas (`graph.gridLine`), sem eixo numérico pesado.
- Rótulo de eixo mínimo (ex.: "0s" / "15s"), estilo `caption`.

**Variantes**
| Variante | Uso | Altura |
| --- | --- | --- |
| `.live` | Durante Quick/Deep Check, atualização incremental | `heightCompact` (100pt no Quick Check; ver token) |
| `.historical` | Tela de Detalhes, série completa já finalizada | `heightExpanded` (220pt) |
| `.loadComparison` | Deep Check — repouso vs. sob carga, duas séries sobrepostas com opacidade diferenciada | `heightExpanded` |

**Estados**
- `.streaming` — pontos chegando em tempo real (`NLMotion.patterns.latencyGraphLiveUpdate`).
- `.complete` — série estática, permite toque para inspecionar um ponto (tooltip textual).
- `.empty` — menos de 10 amostras válidas; mostra `EmptyState` inline em vez do gráfico vazio.

**API SwiftUI pretendida**
```swift
public struct LatencyGraph: View {
    public enum Style { case live, historical, loadComparison }

    public struct Sample { public let timestamp: TimeInterval; public let rtt: Double? }

    public init(
        style: Style,
        primarySamples: [Sample],
        secondarySamples: [Sample]? = nil, // usado em .loadComparison
        spikes: [TimeInterval],
        severeSpikes: [TimeInterval]
    )
}
```
- `accessibilityLabel` fornece um resumo textual equivalente (mediana, pior spike, contagem de spikes), já que o traçado não é navegável ponto a ponto por VoiceOver.
- Reduzir Movimento: novos pontos aparecem na posição final sem interpolação de entrada.

---

## `GameTile`

O jogo é o protagonista — a capa do jogo domina visualmente o componente; a rede não aparece aqui além de um score compacto opcional.

**Anatomia**
- Arte de capa (`aspectRatio` 3:4, raio `avatarOrGameArt`).
- Nome do jogo, estilo `subheadline`, sobre ou abaixo da arte conforme variante.
- Selo de score compacto opcional (`NolaggyScore.compact` sem frase-resumo) ou texto "Testar Fortnite de novo" quando há histórico recente.
- Badge de categoria opcional (`captionStrong`, ex.: "Battle Royale").

**Variantes**
| Variante | Uso |
| --- | --- |
| `.grid` | Busca, categorias — arte com nome sobreposto na base |
| `.carousel` | Recentes/favoritos na Home — largura fixa `widthCompact`, inclui score compacto e "testar de novo" |
| `.row` | Resultado de busca em lista, resultado de comparação — arte pequena à esquerda, nome + metadado à direita |

**Estados**
- `.available` — normal, interativo.
- `.unavailable(reason)` — jogo sem elegibilidade no mercado/contexto atual (Seção 10.2 do funcional); arte com opacidade reduzida e rótulo curto de indisponibilidade, não interativo para iniciar teste.
- `.selected` — borda `border.focus`, usado em seleção prévia ao Quick Check.
- `.pressed` — leve escala via `NLMotion.easing.spring`.

**API SwiftUI pretendida**
```swift
public struct GameTile: View {
    public enum Style { case grid, carousel, row }
    public enum Availability { case available, unavailable(reason: LocalizedStringKey) }

    public init(
        title: String,
        artwork: Image,
        style: Style,
        categoryBadge: LocalizedStringKey? = nil,
        lastScore: NolaggyScore.Outcome? = nil,
        availability: Availability = .available,
        isSelected: Bool = false,
        action: () -> Void
    )
}
```
- Alvo de toque sempre ≥ 44×44pt mesmo quando a arte visual é menor (ex.: `.row`).

---

## `PlatformSelector`

Cobre tanto a escolha de plataforma (iPhone/PlayStation/Xbox/PC/Nintendo) quanto a pergunta curta de Wi-Fi/Ethernet para console/PC (Seção 7.2 do funcional).

**Anatomia**
- Linha de chips (`chipHeight` 44pt), ícone de plataforma + rótulo, `captionStrong`.
- Nota de representatividade contextual abaixo (estilo `footnote`, `text.tertiary`) — ex.: "Estimativa da rota de internet; a conexão local do console é estimada."

**Variantes**
| Variante | Uso |
| --- | --- |
| `.platform` | Lista de plataformas suportadas pelo jogo (vem do catálogo — só mostra o que é compatível) |
| `.connectionType` | Sub-pergunta Wi-Fi/Ethernet, exibida apenas quando plataforma ≠ iPhone e o catálogo indicar que isso afeta a interpretação |

**Estados**
- `.selectable` — nenhuma seleção ainda.
- `.selected(option)` — chip ativo com `accent.primarySubtle` de fundo e borda `accent.primary`.
- `.disabled(option)` — plataforma não compatível com o jogo no catálogo atual; não é renderizada como opção (o catálogo decide o conjunto, o componente nunca inventa uma opção fora dele).

**API SwiftUI pretendida**
```swift
public struct PlatformSelector<Option: PlatformSelectorOption>: View {
    public enum Kind { case platform, connectionType }

    public init(
        kind: Kind,
        options: [Option],
        selection: Binding<Option?>,
        representativenessNote: LocalizedStringKey? = nil
    )
}

public protocol PlatformSelectorOption: Identifiable, Equatable {
    var label: LocalizedStringKey { get }
    var iconName: String { get }
}
```

---

## `PrimaryButton`

Ação principal única de cada tela. Nunca duas instâncias `.primary` competindo na mesma tela.

**Anatomia**
- Fundo pílula (`radius.button`), altura `primaryButton.height` (52pt).
- Rótulo, `bodyEmphasis`, cor `text.onAccent`.
- Ícone opcional à esquerda/direita, `icon.sm`, gap `primaryButton.iconGap`.
- Spinner opcional substituindo o rótulo em `.loading`.

**Variantes**
| Variante | Uso |
| --- | --- |
| `.filled` | Ação principal padrão (ex.: "Iniciar Quick Check") — fundo `accent.primary` |
| `.filledCritical` | Ação principal em contexto de risco (ex.: "Fazer Deep Check" quando priorizado por indício de problema) — mesmo peso visual, ícone de urgência, ainda dentro da paleta neutra + `accent.primary` (não usa `score.lagRisk` como fundo de botão) |
| `.secondaryOutline` | Ação secundária na mesma tela (ex.: "Testar novamente" ao lado de "Ver detalhes") — traço `border.strong`, fundo transparente |

**Estados**
- `.enabled`, `.pressed` (leve escurecimento + spring), `.disabled` (opacidade reduzida, `text.disabled`), `.loading` (não interativo, spinner, rótulo com `accessibilityLabel` preservado).

**API SwiftUI pretendida**
```swift
public struct PrimaryButton: View {
    public enum Style { case filled, filledCritical, secondaryOutline }

    public init(
        title: LocalizedStringKey,
        style: Style = .filled,
        icon: Image? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    )
}
```

---

## `MetricRow`

Peça atômica de apresentação de métricas (Ping, Jitter, Perda, Spikes, P95/P99...). Usada no resultado (até 4 linhas) e em Detalhes (lista completa).

**Anatomia**
- Ícone à esquerda (`icon.sm`), opcional.
- Rótulo, `bodyEmphasis`.
- Valor + unidade à direita, `subheadlineSecondary`.
- Indicador de destaque opcional (ponto colorido) quando a métrica é a causa principal do resultado.

**Variantes**
| Variante | Uso |
| --- | --- |
| `.summary` | Até 4 métricas no resultado principal (Ping/P50, jitter, perda, spikes) |
| `.detailed` | Lista completa em Detalhes (inclui P95, P99, pior spike, taxa de spikes, região, alvo, confiança) |
| `.loadComparison` | Deep Check — mostra valor em repouso e sob carga lado a lado, com o delta destacado |

**Estados**
- `.normal`, `.highlightedCause` (indicador colorido com a cor semântica do score, usado no máximo em uma linha por resultado — a causa principal), `.unavailable` (ex.: impacto sob carga quando a fase de carga falhou — mostra traço "—" com nota de limitação, nunca um zero).

**API SwiftUI pretendida**
```swift
public struct MetricRow: View {
    public enum Style { case summary, detailed, loadComparison }

    public init(
        label: LocalizedStringKey,
        value: String,
        unit: String? = nil,
        icon: Image? = nil,
        style: Style = .summary,
        isPrimaryCause: Bool = false,
        loadValue: String? = nil // usado em .loadComparison
    )
}
```

---

## `InsightBanner`

Traduz o achado técnico em linguagem simples (ex.: "Sua conexão fica instável quando está ocupada"). Não é o mesmo componente que `BannerAdSlot` — nomes distintos de propósito para evitar qualquer confusão entre insight de produto e anúncio.

**Anatomia**
- Ícone semântico (`icon.md`) refletindo a causa (perda, latência, jitter, spikes, carga).
- Texto explicativo, `callout`.
- Ação inline opcional (ex.: "Fazer Deep Check"), estilo de link (`text.link`).

**Variantes**
| Variante | Uso |
| --- | --- |
| `.positive` | Conexão saudável, achado secundário não crítico (ex.: "Encontramos um pequeno pico que não deve ser perceptível") |
| `.risk` | Causa principal de risco identificada |
| `.tip` | Recomendação acionável (ex.: "Downloads ou streaming na rede podem causar lag") |

**Estados**
- `.default`, `.withAction` (mostra a ação inline), `.compact` (uma linha, usado em cards de histórico).

**API SwiftUI pretendida**
```swift
public struct InsightBanner: View {
    public enum Tone { case positive, risk, tip }

    public init(
        tone: Tone,
        message: LocalizedStringKey,
        icon: Image,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    )
}
```

---

## `StatusMessage`

Cobre todos os estados não-resultado descritos na Seção 10 da especificação técnica (`catalogFallback`, `catalogUnavailable`, `cancelled(networkChanged)`, `deepRequiresWiFi`, `inconclusive(insufficientUDPResponses)`, `loadUnavailable`, `failed(invalidContext)`).

**Anatomia**
- Ícone de estado (`icon.sm`), tom neutro (nunca usa paleta de score).
- Mensagem principal, `body`.
- Ação de recuperação opcional (ex.: "Tentar novamente", "Trocar de rede").

**Variantes**
| Variante | Mapeamento de estado técnico |
| --- | --- |
| `.info` | `catalogFallback` — informativo, não bloqueia a Home |
| `.warning` | `deepRequiresWiFi`, `loadUnavailable` — Quick Check continua disponível |
| `.error` | `catalogUnavailable`, `failed(invalidContext)` — bloqueia início de teste |
| `.cancelled` | `cancelled(networkChanged)` — sempre com ação "Reiniciar teste" |
| `.inconclusive` | `inconclusive(insufficientUDPResponses)` — sempre com recuperação “Tentar novamente”, nunca com nota |

**Estados**
- `.static` (sem ação), `.actionable(title, action)`.

**API SwiftUI pretendida**
```swift
public struct StatusMessage: View {
    public enum Kind { case info, warning, error, cancelled, inconclusive }

    public init(
        kind: Kind,
        message: LocalizedStringKey,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    )
}
```
- `.inconclusive` e `.cancelled` nunca renderizam ao lado de um `NolaggyScore` — são mutuamente exclusivos na composição da tela de resultado (reforça a regra "sem score para inconclusivo/cancelado").
- **Composição aprovada para o piloto:** após o cabeçalho com voltar e o contexto jogo/região, renderizar somente `StatusMessage` centralizado em uma superfície `background.raised` com borda `border.subtle`. Não renderizar `NolaggyScore`, `MetricRow`, `LatencyGraph`, `InsightBanner` ou CTA de Deep Check/detalhes. Em `.inconclusive`, usar a mensagem “Não conseguimos dados suficientes para avaliar sua conexão. Tente novamente em instantes.” e a ação “Tentar novamente”. Em `.cancelled`, explicar o motivo aplicável, declarar que a leitura parcial foi descartada e usar “Reiniciar teste”.
- No piloto, a moldura acima inclui a wordmark oficial `nolaggy` ao lado do retorno. A mensagem é anunciada antes da ação de recuperação; o botão mantém alvo de 44pt e permanece navegável separadamente por VoiceOver. Mensagem, título da ação e hint são localizáveis em PT-BR e inglês.
- Dynamic Type suporta AX1–AX5 sem truncar a mensagem ou a ação. Com Reduzir Movimento, a entrada/substituição do cartão usa somente transição curta de opacidade; o estado é identificável por texto e ícone, sem depender de movimento.

---

## `EmptyState`

Ausência de conteúdo: histórico vazio, busca sem resultado, catálogo indisponível para o contexto.

**Anatomia**
- Ilustração simples baseada no símbolo da marca (`illustrationSize` 120pt), nunca uma ilustração gamer genérica.
- Título, `subheadline`.
- Texto de apoio, `body`, `text.secondary`.
- Ação opcional (`PrimaryButton.secondaryOutline`).

**Variantes**
| Variante | Uso |
| --- | --- |
| `.noHistory` | Histórico vazio para um jogo ou geral |
| `.noSearchResults` | Busca de jogos sem correspondência |
| `.catalogUnavailable` | Jogo/contexto sem elegibilidade de catálogo (Seção 10.2 do funcional) |

**API SwiftUI pretendida**
```swift
public struct EmptyState: View {
    public enum Context { case noHistory, noSearchResults, catalogUnavailable }

    public init(
        context: Context,
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    )
}
```

---

## `BannerAdSlot`

Área reservada de anúncio. Existe **apenas** para uso em Home e Histórico (Seção 11 do documento funcional). O componente em si não sabe nada sobre qualidade de conexão, score ou sessão de medição — apenas reserva espaço e hospeda a view do SDK injetada externamente.

**Anatomia**
- Moldura com fundo `surfaceAd.background`, raio `adSlot`.
- Rótulo "Anúncio"/"Ad" (`surfaceAd.label`), sempre visível, `caption`.
- Slot de conteúdo (a view nativa do Google Mobile Ads é injetada por `Features`/`App`; o módulo `NolaggyDesign` nunca importa o SDK).
- Placeholder vazio com a mesma altura reservada quando não há anúncio carregado.

**Variantes**
| Variante | Uso |
| --- | --- |
| `.home` | Posição fixa na Home |
| `.history` | Posição fixa no Histórico |

Ambas as variantes usam a mesma altura adaptativa (`heightStandard`/`heightLarge`); a distinção existe só para telemetria de posicionamento no lado de `Features`, não para uma aparência diferente.

**Estados**
- `.loaded(AnyView)` — SDK entregou criativo; a `AnyView` injetada é renderizada dentro da moldura.
- `.empty` — nada carregado ainda ou falha de carregamento; mantém a altura reservada, sem conteúdo, sem re-tentativa visível ao usuário além do rótulo padrão.
- `.consentPending` — Google UMP ainda não resolveu consentimento; slot permanece vazio (o `AdProvider` só é chamado após o UMP resolver, Seção 9 da especificação técnica).

**API SwiftUI pretendida**
```swift
public struct BannerAdSlot<AdContent: View>: View {
    public enum Placement { case home, history }

    public init(
        placement: Placement,
        state: State,
        @ViewBuilder adContent: () -> AdContent
    )

    public enum State { case loaded, empty, consentPending }
}
```
- `accessibilityLabel` sempre inicia com "Anúncio"/"Advertisement" e nunca herda o grupo de acessibilidade do conteúdo funcional vizinho.
- O componente nunca aceita um `action`/callback de toque próprio: qualquer interação é inteiramente do conteúdo do SDK injetado.
