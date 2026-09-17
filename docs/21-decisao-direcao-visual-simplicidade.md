# Nolaggy — decisão: nova direção visual, simples e leve

**Status:** decisão de direção tomada (dono do produto, nesta conversa) — pendente de execução
visual por Renan antes de virar implementação. Este documento registra a mudança de rumo e o que
ela implica; não substitui o trabalho de design real (mockups, especificação pixel a pixel), que
continua sendo dele.
**Substitui:** os princípios visuais de `docs/04-design-system.md` seção 1 ("premium, calma,
confiável... mais próxima de um app de saúde") e a estética "sala escura" da seção 2 — não porque
estivessem errados, mas porque a direção de produto mudou: menos composição, mais objetividade.
**Não muda:** nenhuma regra de `docs/01-funcional.md`, `02-arquitetura.md` ou
`03-especificacao-tecnica.md`. O motor de medição, o score, os thresholds e as regras de
confiança/inconclusivo são `Domain`, desacoplados de UI por arquitetura — esta decisão não toca
neles. "Sem perder na qualidade da análise" já está garantido pela própria separação de camadas
que o Nolaggy já tem.

## O pedido, em uma frase

Simplicidade e leveza como diferencial de design, sem sacrificar o rigor da análise. A análise
não é uma variável desta decisão — ela já mora em `Domain`, imune a mudança de UI.

## Princípio central

**Cada tela mostra uma coisa. O resto é ruído até que seja pedido.** Isso substitui o princípio
anterior de "premium e calmo através de camadas visuais" (halo, gradiente, glass, flip 3D) por
"premium através de ausência" — menos elemento na tela, não elemento mais bem produzido.

## O que sai (é "firula" no sentido do pedido)

| Elemento atual | Por que sai |
| --- | --- |
| Fonte Oxanium (título/score) | O próprio doc 04 já a chamava de "experimental". Custom font é decoração tipográfica, não clareza — sai em favor de SF Pro/system font em todos os pesos. Menos uma fonte embarcada, app mais leve de verdade (tamanho de binário, não só percepção). |
| Halo/glow atrás do `NolaggyScore` (`glow.scoreAccent`) | Efeito decorativo puro, sem função de leitura. |
| Flip 3D ao trocar de jogo (`gameSelectionCardFlip`, `GameSelectionCardFlip`) | Animação de personalidade em vez de animação de estado. Substituir por cross-fade simples (~150ms) — mais rápido de perceber, mais barato de manter, já é a alternativa que o próprio Reduzir Movimento usa hoje. |
| Gradiente de marca no símbolo (`accent.gradientStart/End`) em uso decorativo amplo | Manter só como identidade mínima (ícone do app), não espalhar gradiente em superfícies de produto. |
| Sombras em múltiplos níveis (`shadow.level0`–`level3`, halo + borda) | Reduzir para no máximo 1 nível de elevação por tela (ex.: só o card de ação primária se destaca; o resto é plano). |
| "Card soup" residual (card de última medição + card de jogo selecionado + card de contexto empilhados na Home) | Consolidar em um único bloco por estado de tela, não múltiplos cards competindo. |
| Busca expansível + filtro de categoria na Home | Já sinalizado como fricção desnecessária na revisão anterior (`docs/20`, seção 2) — reforça a mesma direção agora por princípio de design, não só por tamanho de catálogo. |
| Cápsula "Glass" de ações agrupadas (busca + reticências) | Reavaliar: Glass é um efeito de material do sistema, vale mantê-lo só se for a opção *mais simples* disponível no iOS 26+, não porque é bonito. Em iOS 17–25, já cai para botão plano — isso vira o padrão em toda versão, não a exceção. |

## O que fica (é rigor, não firula)

- **Conclusão antes de métrica.** Esse princípio já era sobre objetividade, não sobre
  composição — reforça a nova direção, não conflita com ela.
- **Cor semântica única por estado de score** (verde/âmbar/coral/cinza-neutro) — é comunicação
  funcional, não decoração. Simplificar visual não significa tirar o sinal de cor que informa a
  decisão.
- **Toda a base de acessibilidade** (Dynamic Type AX1–AX5, VoiceOver, contraste, Reduzir
  Movimento/Transparência) — simplicidade e acessibilidade puxam na mesma direção; nada aqui é
  cortado.
- **Separação `Domain`/`Infrastructure`/`Design`** — a arquitetura que já garante que simplificar
  a UI não pode, por construção, afetar a régua de score.

## Tela por tela — o que muda concretamente

| Tela | Antes | Depois proposto |
| --- | --- | --- |
| Home | Vitrine com busca expansível, filtro de categoria, card de última medição, card de jogo selecionado, cápsula Glass de ações | Um único bloco: jogo mais recente/relevante em destaque, ação primária óbvia, lista simples de jogos abaixo sem filtro (até o catálogo crescer o bastante para justificar) |
| Medição (Quick Check) | Pulso animado + gráfico de latência ao vivo com grade, spikes marcados, halo | Manter o gráfico (é informação, não decoração), remover halo e reduzir a grade a linhas mínimas |
| Resultado | Score com anel 160pt, halo, classificação, métricas em cartão com borda, insight banner colorido | Score sem halo, mesma hierarquia de leitura, cartão de métrica sem sombra dupla — só separação por espaço em branco |
| Configurações | Lista agrupada com superfícies translúcidas azul-escuras | Manter estrutura (já é simples), remover translucidez decorativa em favor de superfície plana |
| Histórico / Detalhes | Não revisado a fundo ainda | Aplicar o mesmo princípio quando chegar a vez — não redesenhar agora sem necessidade |

## O que isso implica em tokens (`design-system/tokens/`)

Não estou reescrevendo os arquivos JSON agora — isso é trabalho de Renan, incluindo escolha exata
de valores. Registro aqui só o que os tokens precisam deixar de expressar:

- `typography.json`: remover a família Oxanium; um único sistema tipográfico (SF Pro/system),
  hierarquia por peso e tamanho, não por fonte diferente.
- `shadow.json`: reduzir de 4 níveis para no máximo 2 (um para "elevado", um para "plano"); remover
  `glow.scoreAccent`.
- `motion.json`: remover o padrão `gameSelectionCard` (flip 3D); um padrão único de transição
  (`crossFadeShort`, ~150ms) para trocas de conteúdo que hoje usam flip.
- `colors.json`: manter a paleta semântica de score como está (função, não decoração); revisar uso
  de `accent.gradientStart/End` para ficar restrito à marca (ícone), não a componentes de produto.

## O que isso NÃO implica

- Não muda o nome do app (`docs/20` seção 1 continua em aberto, separada desta decisão).
- Não muda o modo escuro único da V1 — "leve" aqui é sobre densidade visual, não sobre tema
  claro/escuro. Se tema claro entrar depois, é decisão separada.
- Não muda nenhuma métrica, threshold, texto de causa/recomendação ou regra de confiança.
- Não implica monetização — é ortogonal ao que `docs/20` seção 4 propôs.

## Próximo passo

Esta decisão de direção está tomada; falta a execução visual. Gate único antes de código: Renan
produz a especificação visual concreta (tokens revisados + composição das telas acima) seguindo
estes princípios, e o protótipo iOS canônico (`design-system/prototypes/ios-reference/`) é
atualizado ou substituído para refletir a nova direção — ele continua sendo a fonte de paridade
1:1 para implementação, só que com o conteúdo revisado.
