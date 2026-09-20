# Decisão de experiência — piloto Quick Check

**Status:** substituído para jornada e copy de release pela decisão 43; preservado como registro histórico do piloto
**Data:** 2026-09-08  
**Decisão de produto:** Marco  
**Frentes envolvidas:** Renan (design e acessibilidade), Rian (iOS) e Iury (medição e score)

## Problema

Antes de ampliar catálogo, histórico ou Deep Check, o Nolaggy precisa provar que consegue conduzir uma medição UDP real no iPhone e apresentar uma conclusão determinística sem sugerir que mede o ping de um jogo. A pessoa deve entender quando há um resultado válido e quando a rede não permitiu concluir nada.

## Decisão

O piloto entrega um Quick Check vertical para um único jogo, uma única região de referência e iPhone. Ele não inclui Deep Check, detalhes, histórico, publicidade, catálogo remoto, seleção de plataforma ou estimativas para console e PC.

O protótipo em `design-system/prototypes/ios-reference/source/Nolaggy iOS Prototype.dc.html` continua canônico e não será alterado. Para o resultado do Quick Check, o anel de score segue a composição do HTML: 160pt. Isso tem precedência sobre a descrição anterior da variante de componente que apontava 216pt.

## Fluxo aprovado

1. A pessoa vê o contexto fixo de jogo, região e iPhone e inicia o Quick Check.
2. Durante a medição, vê jogo, região, RTT atual, progresso, gráfico vivo, perda, picos e uma mensagem de fase. Não vê score nem recomendação para jogar.
3. Se a medição tiver dados UDP válidos suficientes, recebe resultado saudável ou com risco, nesta ordem: score, classificação, conclusão, evidência, métricas e insight.
4. Se faltar dado UDP válido, vê o estado inconclusivo sem score, métricas parciais, insight ou conclusão positiva. A recuperação é “Tentar novamente”.
5. Voltar durante a medição, troca de rede, entrada em background ou cancelamento descartam a leitura parcial. A pessoa vê o estado cancelado com motivo aplicável e a ação “Reiniciar teste”.

## Composição de estados sem referência no protótipo

Inconclusivo e cancelado usam a mesma moldura de resultado — cabeçalho com voltar e contexto jogo/região — mas substituem todo o conteúdo de resultado por um `StatusMessage` centralizado, neutro, em superfície elevada discreta. Não coexistem com `NolaggyScore`, `MetricRow`, `LatencyGraph`, `InsightBanner`, Deep Check ou detalhes.

Copy de inconclusivo:

> Não conseguimos dados suficientes para avaliar sua conexão. Tente novamente em instantes.

Copy de cancelamento por troca de rede:

> A conexão mudou durante a medição. Descartamos a leitura parcial. Reinicie o teste para termos um resultado confiável.

Cancelamento iniciado pela pessoa usa o mesmo tratamento, com motivo equivalente em linguagem simples.

## Limites do piloto

- Deep Check e detalhes não aparecem como CTAs, botões desabilitados ou destinos vazios.
- Não há banner ou espaço reservado de anúncio nas telas de contexto, medição ou resultado.
- A tela não apresenta plataformas externas, logo não faz promessa nem estimativa para console ou PC.
- O resultado não promete desempenho futuro ou ping real de partida; ele descreve a medição para a região de referência.

## Matriz de composição e aceite de design

**Status deste registro:** composição e requisitos de aceite definidos por Renan em 2026-09-08. Isto não é evidência de QA visual, VoiceOver, Dynamic Type ou Reduzir Movimento executado.

O viewport e os estados de referência para a comparação são os do iPhone presente no HTML canônico. O cabeçalho do Quick Check é parte da moldura, não conteúdo opcional: quando houver retorno, ele sempre traz voltar com alvo de 44pt e a wordmark oficial `nolaggy`; a tela de contexto mantém a identidade prevista no HTML sem inventar uma navegação de retorno.

| Estado | Composição aprovada | Exclusões obrigatórias | Aceite visual e interativo |
| --- | --- | --- | --- |
| Contexto | Jogo Fortnite, região São Paulo de referência, plataforma iPhone, explicação do alcance da medição e CTA `Iniciar Quick Check`. | Seleção de plataforma, console/PC, Deep Check, detalhes, anúncio e score prévio. | Hierarquia e espaçamentos do contexto do HTML; CTA inicia a coleta sem prometer ping oficial do jogo. |
| Medindo | Cabeçalho com voltar + wordmark, jogo, região, RTT atual, `MeasurementPulse` com progresso, `LatencyGraph` vivo, perda, picos e fase textual. | Score, classificação, conclusão, insight e recomendação para jogar. | RTT e gráfico mudam apenas com amostras recebidas; voltar cancela e descarta a leitura, sem revelar um resultado. |
| Resultado saudável | Cabeçalho com voltar + wordmark; anel `NolaggyScore.standard` de **160pt**; score, classificação, conclusão, evidência, métricas e insight. | Deep Check, detalhes e anúncio no piloto. | Ordem preservada, `resultConclusionToMetrics` de 40pt e conclusão positiva baseada na medição, não em promessa futura. |
| Resultado com risco | Mesma moldura e ordem do saudável, com classificação, conclusão, evidência e insight de risco proporcionais ao observado. | Deep Check, detalhes e anúncio no piloto, mesmo que apareçam no HTML de escopo V1 completo. | Sem alarmismo e sem mudança da sequência informacional; métricas vêm depois da conclusão. |
| Inconclusivo | Cabeçalho com voltar + wordmark, contexto jogo/região e somente `StatusMessage.inconclusive` centralizado em `background.raised` com borda `border.subtle`, ação `Tentar novamente`. | `NolaggyScore`, métricas parciais, gráfico, insight, `Pronto para jogar`, recomendação, Deep Check e detalhes. | Mensagem e CTA locais em PT-BR/inglês; a recuperação retorna ao contexto sem reutilizar leitura parcial. |
| Cancelado | Mesma moldura neutra do inconclusivo, com `StatusMessage.cancelled`, motivo simples aplicável, confirmação de descarte e ação `Reiniciar teste`. | `NolaggyScore`, métricas parciais, gráfico, insight, recomendação, Deep Check e detalhes. | Vale para voltar, rede alterada, background e cancelamento iniciado pela pessoa; o motivo não culpa a pessoa nem sugere falha de performance. |

### Divergências aprovadas para o piloto

- O HTML continua canônico para contexto, medição e resultados válidos. O contexto de plataforma nos resultados do HTML usa PlayStation 5 por representar a V1 ampla; no piloto, é substituído por iPhone pela decisão funcional mais específica deste documento. Não há estimativa para equipamento externo.
- O anel do resultado do Quick Check usa 160pt (`nolaggyScore.ring.md`). O anel de 216pt (`nolaggyScore.ring.lg`) fica restrito ao resultado principal do Deep Check.
- O HTML mostra CTAs de Deep Check e detalhes em resultados válidos da V1 ampla. Eles são removidos no piloto por recorte deliberado, sem versão desabilitada, placeholder ou destino vazio.
- Inconclusivo e cancelado não existem no HTML e, por isso, usam a composição neutra acima. Isso não autoriza criar uma tela genérica: preservam cabeçalho, wordmark, contexto, tokens de superfície e a hierarquia do resultado.
- `LatencyGraph` compacto do Quick Check preserva os 100pt do HTML canônico. A altura deve ser exposta pelo token de sizing correspondente; nenhuma feature deve introduzir uma altura solta para contornar essa referência.

### Gate de acessibilidade e localização

- Todos os controles, incluindo voltar e as ações de recuperação, têm área de toque mínima de 44×44pt. Mensagem de estado e botão de recuperação são elementos VoiceOver distintos: a ação não pode desaparecer dentro da leitura combinada do cartão.
- Em medição, VoiceOver anuncia a fase ao entrar ou mudar de fase e anuncia RTT atual quando ele muda; o gráfico fornece um resumo textual equivalente. Em resultado válido, a ordem é score, classificação, conclusão, evidência, métricas, insight e ação. Inconclusivo e cancelado leem contexto, limite/motivo e ação de recuperação, nessa ordem.
- Dynamic Type deve permanecer legível de AX1 a AX5. Score, RTT, classificação, mensagem e CTA não usam `minimumScaleFactor` nem limite artificial de tamanho; em espaço restrito, a composição se reorganiza antes de truncar.
- Com Reduzir Movimento, pulso não escala nem repete loop, pontos do gráfico entram na posição final e a revelação do score fica síncrona. Mudança de estado continua perceptível por texto e transição curta, não por animação contínua.
- PT-BR e inglês devem manter intenção, ordem e ações curtas. Todo `accessibilityLabel`, valor e hint é localizável; inglês não pode herdar texto em português. A copy segue `docs/07-voz-do-produto.md`.

## Critérios de aceite de paridade

- Comparar cada estado com o HTML canônico no mesmo viewport de iPhone, verificando composição, hierarquia, espaçamentos, tipografia, cores, transições e ações — não apenas screenshot estático.
- Na medição, o RTT atual e o gráfico devem mudar com amostras reais. O estado visual não pode simular conclusão antes do encerramento válido.
- Nos resultados válidos, manter a sequência score, classificação, conclusão, evidência, métricas e insight, incluindo o espaço semântico de 40pt antes das métricas.
- Nenhum resultado inconclusivo ou cancelado pode mostrar score, número de métricas parciais, “Pronto para jogar” ou recomendação de performance.
- Todo toque tem alvo mínimo de 44pt; VoiceOver anuncia fase e RTT durante a coleta e, em resultado válido, lê score, classificação, resumo, métricas e ações nessa ordem.
- Dynamic Type e Reduzir Movimento preservam leitura e não deixam pulso, gráfico ou revelação de score dependerem de animação contínua.
- PT-BR e inglês mantêm a mesma intenção, sem truncar conclusões ou ações.
- O gate de design/a11y só fecha com a matriz acima percorrida no simulador e, para VoiceOver, Dynamic Type e Reduzir Movimento, em iPhone físico. Medição física isolada não comprova paridade nem acessibilidade.

## Evidência exigida antes de avançar

- Testes de domínio e contrato para os caminhos válido, inconclusivo e cancelado.
- Comparação visual e interativa em simulador contra o protótipo canônico.
- Medição do Quick Check em iPhone físico, incluindo interrupção por troca de rede, background e cancelamento.
