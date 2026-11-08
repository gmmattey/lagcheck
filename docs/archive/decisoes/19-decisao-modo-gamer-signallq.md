# Nolaggy — decisão: adotar taxonomia do "Modo gamer" do SignallQ

**Status:** rascunho — levantamento técnico concluído, nenhuma decisão tomada, nenhuma
implementação autorizada. Este documento é o registro da conversa exploratória pedida por Marco;
segue a regra do `AGENTS.md` de não tratar exploração como autorização.
**Responsável de domínio:** a definir (envolve Marco, Renan, Rian e Iury — decisão atravessa
produto, arquitetura, design e regra de rede).
**Origem:** pedido para avaliar se o Nolaggy deve se posicionar como a versão iPhone do módulo
"Modo gamer" do SignallQ (produto irmão da Buildea, Android-only, repositório local em
`/Users/giammattey/Projetos/buildea/signallq`).

## Problema

O SignallQ tem, dentro do seu fluxo de diagnóstico pós-teste, uma tela chamada "Modo gamer":
usuário escolhe jogo + device e recebe um veredito direto sobre a conexão para aquele jogo
específico. Foi levantada a hipótese de o Nolaggy adotar essa mesma taxonomia de produto —
categorias de jogo, seleção de device, veredito direto — se posicionando como o equivalente iOS
desse módulo.

Isso não é um pedido de portar código: o Modo gamer do SignallQ é escrito em Kotlin, roda sobre a
infraestrutura de diagnóstico Android (`core/diagnostico`) e seu motor de latência é **mais fraco**
que o do Nolaggy (ping por HTTPS aproximado contra CDN, não ICMP/UDP real — ver nota abaixo). O que
está em jogo é reaproveitar **conceito de produto e vocabulário**, não motor de medição.

## O que existe hoje em cada lado (evidência de código)

**SignallQ** (`android/core/diagnostico/src/main/kotlin/io/signallq/app/core/diagnostico/`):

- `ModoGamerEngine.kt` — motor puro, sem dependência de Android framework. 6 categorias de jogo
  (`CategoriaJogoModoGamer`: FPS_COMPETITIVO, BATTLE_ROYALE, MOBA, CASUAL, CLOUD_GAMING, OUTRO),
  7 devices (`DeviceJogo`: PS5/PS4, Xbox, PC, Android, iPhone, Switch, TV/Cloud), veredito direto
  em texto (`paraVereditoDiretoModoGamer`: "Bom pra jogar" / "Pode ter atrasos" / "Não
  recomendado" / "Sem dados suficientes" — decisão de produto do Luiz, issue #1667,
  2026-08-19, "clareza rápida sobre nuance de incerteza").
- `CatalogoJogosModoGamer` — 21 jogos com categoria fixa; jogo fora da lista cai em `OUTRO`
  (fallback determinístico, nunca erro — regra de produto da issue #1476).
- `ModoGamerMedicaoElegibilidade.kt` — janela de reaproveitamento de medição-base de 15 min
  (mesma rede) e de ping específico de 2 min (mesma tentativa); rede diferente ou identidade de
  rede ausente nunca é tratada como igual.
- Medição de latência: `PingExecutor` contra CDN Cloudflare ou contra o worker dedicado
  `game-latency-probe-worker`. O próprio kdoc do `PingExecutor` documenta que **isto nunca é ping
  ICMP real** — Android não concede socket ICMP bruto a apps; é latência HTTPS aproximada,
  rotulada como tal.
- Produto Android-only: `PRODUCT.md` do SignallQ define papel de cada plataforma como
  "Android" + "Web (aquisição)"; não há iOS em nenhum documento do repositório.

**Nolaggy** (este repositório):

- Mede via **UDP direto para AWS GameLift Ping Beacons** (RTT real), Quick Check e Deep Check
  (repouso + carga), score local determinístico 0–100 (`docs/03-especificacao-tecnica.md`).
- Já tem catálogo de jogos remoto assinado (Ed25519) com perfis e pesos por perfil
  (`BATTLE_ROYALE_COMPETITIVE`, etc. — `docs/03-especificacao-tecnica.md` seção 4.3) e seleção
  regional automática validada (`docs/archive/decisoes/16-decisao-selecao-regional-automatica.md`).
- Regras inegociáveis (`AGENTS.md`): custo operacional recorrente zero, sem SDK pago, resultado
  inconclusivo nunca vira score inventado, nunca promete "zero lag"/"garantido".

Conclusão de viabilidade técnica: **não há bloqueio de plataforma**. O motor de medição do
Nolaggy já é estrategicamente superior ao do SignallQ nesse módulo específico. O trabalho real,
se a decisão for seguir em frente, é de produto e design — não de portar sistema de medição.

## O que seria reaproveitado, e como

| Ativo do SignallQ | Proposta para o Nolaggy | Reescrita necessária |
| --- | --- | --- |
| 6 categorias de jogo | Adotar a mesma taxonomia como camada de apresentação sobre o catálogo remoto já existente | Nova `enum` Swift em `Domain`, ~1 dia |
| 21 jogos + fallback `OUTRO` | Reconciliar com o catálogo remoto assinado do Nolaggy (que já tem perfis/pesos por jogo) — **não duplicar fonte de verdade**: o catálogo remoto continua sendo a única origem de jogo→perfil | Trabalho de mapeamento de dados, revisão de Iury |
| Veredito direto ("Bom pra jogar"/"Não recomendado") | Avaliar contra `docs/07-voz-do-produto.md` — precisa decisão do responsável pela voz do produto, não é automática | Copy nova, revisão de Renan |
| `ModoGamerMedicaoElegibilidade` (janela de reaproveitamento) | Conceito direto, útil para não reexecutar Quick Check ao trocar jogo/device | Regra de domínio nova, ~50 linhas Swift, testável isoladamente |
| `game-latency-probe-worker` | **Não recomendado adotar** — o Nolaggy já tem sonda melhor (UDP GameLift real); reintroduzir latência HTTPS aproximada seria regressão de precisão | — |
| Motor Kotlin em si | Não portável nem desejável — decisão é reaproveitar conceito, motor de decisão continua sendo o do Nolaggy | — |

## Pontos a confirmar antes de virar task (não decididos silenciosamente)

**19.1 — Veredito direto vs. regra de voz do Nolaggy.** O SignallQ usa frases como "Bom pra
jogar" / "Não recomendado". O Nolaggy proíbe linguagem alarmista ou promessa de resultado
("nunca prometa zero lag, rede perfeita, garantido"). As duas regras parecem compatíveis (o
SignallQ também evita linguagem de probabilidade por decisão de produto), mas quem decide é o
responsável pela voz do Nolaggy, não este documento. **Não decidido.**

> **Proposta para revisão de Renan (não é decisão):** não importar o vocabulário do SignallQ
> palavra por palavra — mapear o veredito direto sobre o `ResultClass` que o Nolaggy já tem
> (`docs/03-especificacao-tecnica.md` seção 3), em vez de criar um segundo vocabulário de status
> paralelo ao que já existe:
>
> | `ResultClass` do Nolaggy | Veredito direto proposto | Por que não copiar o texto do SignallQ |
> | --- | --- | --- |
> | `excellent` / `great` | "Boa para este jogo" | Evita "bom pra jogar" (soa a promessa de resultado na partida, o que o Nolaggy proíbe); fala da conexão medida, não do desfecho da partida |
> | `unstable` | "Pode ter atrasos" | Mesmo texto do SignallQ — já é condicional, compatível com a regra do Nolaggy |
> | `lagRisk` | "Alta chance de lag" | Evita "não recomendado" (soa a instrução de não jogar, papel que o Nolaggy não assume); descreve o que foi medido, deixa a decisão com a pessoa |
> | `inconclusive` | "Sem dados suficientes" | Mesmo texto do SignallQ; já é o comportamento atual do Nolaggy para inconclusivo (sem score, sem linguagem positiva) |
> | `cancelled` | Não gera veredito de jogo (estado de sessão, não de resultado) | Sem equivalente no SignallQ; o modo gamer nunca despacha veredito para sessão cancelada |
>
> Vantagem de amarrar no `ResultClass` existente em vez de criar um enum de veredito próprio do
> modo gamer: uma mudança futura na régua de score não exige manter dois vocabulários de status
> sincronizados manualmente. Continua exigindo aprovação de Renan antes de virar copy final —
> isto é ponto de partida para a revisão, não o texto definitivo.

**19.2 — Escopo do catálogo de jogos.** O SignallQ tem 21 jogos com categoria fixa; o Nolaggy já
tem catálogo remoto assinado com perfis próprios. Manter dois catálogos de jogo divergentes entre
os dois produtos da Buildea é aceitável, ou a expectativa é convergir para uma lista única?
**Não decidido — depende de alinhamento de portfólio, fora do escopo de decisão só do Nolaggy.**

> **Proposta para revisão de Iury (não é decisão):** não fundir os dois catálogos. Propõe-se
> tratar a taxonomia de 6 categorias como uma **camada de agrupamento visual sobre o catálogo que
> já existe**, não como um segundo catálogo de jogos:
>
> 1. O catálogo remoto assinado do Nolaggy continua sendo a única fonte de verdade de
>    jogo→perfil→thresholds — nada disso muda. A lista de 21 jogos do SignallQ **não é
>    importada** como dado; ela só inspirou a existência das 6 categorias como conceito.
> 2. Cada jogo já publicado no catálogo do Nolaggy ganha um campo de metadado
>    `displayCategory` (uma das 6: FPS competitivo, battle royale, MOBA, casual, cloud gaming,
>    outro), validado pelo mesmo pipeline de assinatura/schema que já existe — não é uma segunda
>    fonte não assinada.
>  3. Jogo sem `displayCategory` declarada cai em "outro" — mesmo princípio de fallback
>    determinístico que o Nolaggy já usa em outras camadas (nunca erro, nunca tela vazia).
> 4. **Escopo mínimo desta etapa:** aplicar `displayCategory` só aos jogos que já estão no
>    catálogo atual do Nolaggy. Não expandir a lista de jogos agora — isso é decisão de catálogo
>    separada, com o processo de revisão que já existe (`docs/03-especificacao-tecnica.md`), não
>    parte desta mudança de taxonomia.
>
> Isso evita duas listas de jogos divergentes competindo por autoridade e mantém a governança de
> catálogo (assinatura Ed25519, revisão de Iury) intacta — a única mudança é um campo novo no
> payload já existente.

**19.3 — Posicionamento de marca.** "Transformar o Nolaggy em mini-app do módulo Gamer do
SignallQ" pode significar (a) Nolaggy continua app independente na App Store, reaproveitando só
taxonomia/UX, ou (b) Nolaggy passa a se apresentar publicamente como extensão do SignallQ. A
resposta já registrada na conversa que originou este documento foi **(a)** — mini-app iOS
independente, não embutido no app SignallQ (que nem existe em iOS). Este documento assume (a) até
decisão em contrário.

**19.4 — Quem no SignallQ precisa revisar.** Mesma empresa (Buildea), mas reaproveitar
taxonomia/copy de um produto para reposicionar outro é decisão de portfólio. O SignallQ cita
"Luiz" como aprovador de decisões de produto/release nesse repositório — vale confirmação
explícita antes de anunciar qualquer vínculo entre os dois produtos publicamente.

**19.5 — Estados novos de UI.** Categorias, seletor de device e tela de veredito direto não têm
composição aprovada no protótipo iOS canônico do Nolaggy (`design-system/prototypes/ios-reference/`).
Por regra do `AGENTS.md`, exigem composição aprovada por Renan antes de qualquer implementação.

> **Proposta para revisão de Renan (não é decisão):** minimizar composição nova, reaproveitando
> o que já foi aprovado em vez de desenhar uma jornada paralela. Três pontos de tela, não mais:
>
> 1. **Seleção de categoria/device** — estende a seleção de jogo/plataforma que já existe em
>    `GameContext` (`docs/03-especificacao-tecnica.md` seção 3: `Platform`, `equipmentConnection`)
>    em vez de criar um fluxo de seleção novo do zero. A categoria (uma das 6) é derivada do jogo
>    escolhido via `displayCategory` (proposta 19.2), não é uma pergunta extra ao usuário — só
>    aparece como rótulo/ícone no card do jogo já selecionado.
> 2. **Card de resultado com veredito direto** — reaproveita a composição de resultado que já
>    existe (`ResultClass`, selo de severidade), adicionando só uma linha de headline acima do que
>    já é exibido hoje (mapeamento proposto em 19.1). Não é uma tela nova, é uma adição a uma tela
>    existente.
> 3. **Estado "sem dados suficientes"** — reaproveita o padrão de inconclusivo já aprovado em
>    outras decisões do Nolaggy (ex. `docs/archive/decisoes/16-decisao-selecao-regional-automatica.md`,
>    `inconclusive(noViableRegionalCandidate)`), sem inventar uma composição de erro nova.
>
> Se Renan concordar com essa leitura, o trabalho de design fica restrito a variações de
> componentes existentes (ícone de categoria, headline de veredito) em vez de uma tela inteira
> nova — reduz o escopo de revisão visual, mas a decisão final de "o que é reaproveitável sem
> descaracterizar o protótipo canônico" continua sendo dele, não deste documento.

## Fora de escopo (nesta decisão)

- Portar qualquer código Kotlin do SignallQ.
- Adotar `game-latency-probe-worker` ou qualquer sonda HTTPS-aproximada — o Nolaggy mede UDP real.
- Sincronização de dados entre Nolaggy e SignallQ (histórico, preferências, contas) — nenhum dos
  dois produtos tem conta ou backend com estado de usuário hoje.
- Expansão do catálogo de jogos do Nolaggy além do que já existe assinado remotamente.
- Qualquer anúncio público de vínculo de marca entre Nolaggy e SignallQ.

## Gates antes de qualquer implementação

Revisão de Marco (escopo e alinhamento entre frentes) → revisão de Iury (reconciliação de
catálogo de jogos e regra de elegibilidade de medição) → revisão de Renan (voz do produto, item
19.1, e composição visual, item 19.5) → revisão de Rian (arquitetura: onde a taxonomia entra em
`Domain`/`Features` sem acoplar a `Infrastructure`) → só então rascunho de especificação técnica
equivalente a `docs/03-especificacao-tecnica.md` para esta feature específica.

Nenhum desses gates foi cumprido. Este documento é insumo para a conversa entre os responsáveis,
não uma especificação pronta para implementação.
