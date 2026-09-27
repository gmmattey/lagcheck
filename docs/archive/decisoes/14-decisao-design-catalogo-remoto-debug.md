# Decisão de design — catálogo remoto assinado em Debug

**Data:** 9 de setembro de 2026  
**Responsável:** Renan  
**Estado:** composição aprovada para implementação em Debug

## Problema e limite da promessa

O catálogo de oito jogos amplia a descoberta sem transformar a Home em um painel técnico ou permitir que uma configuração incompleta pareça testável. A pessoa escolhe um jogo e somente opções que o catálogo validado autoriza para seu mercado; então entende qual região de referência será medida e o limite dessa estimativa.

O catálogo escolhe contexto, região, destino e linguagem permitida. Ele não autoriza a interface a chamar uma rota regional de “ping oficial” de qualquer jogo. A URL do Worker, versão, assinatura, expiração e detalhes de falha são evidência interna e não entram na copy de produto.

## Composição canônica

### Descoberta

A Home preserva a composição do protótipo: busca no topo, recentes quando existirem e grade de Jogos por categoria. Cada `GameTile` mostra capa, nome e categoria; score compacto aparece apenas em recentes com uma medição válida anterior. Não usar score, rótulo de “otimizado”, destino técnico ou disponibilidade de região como decoração da capa.

O catálogo só entrega à Home e à busca jogos que tenham ao menos um contexto integralmente validado para o mercado ativo: plataforma, perfil, região primária, estratégia, confiança e textos publicados. Um jogo ou contexto rejeitado em validação não aparece como opção para medir, nem como botão desabilitado. Busca sem resultado usa o estado vazio já previsto, sem sugerir um jogo não validado.

### Seleção de contexto

Ao tocar em um jogo, sair da Home e abrir a tela de contexto do segundo frame do protótipo. A descoberta não continua acima ou abaixo do contexto: busca, categorias, recentes, grade e aviso de fallback pertencem exclusivamente à Home. Essa separação evita que o CTA essencial fique depois de oito cards e mantém a pessoa orientada sobre a escolha que acabou de fazer.

A tela de contexto tem cabeçalho com botão visual de voltar, nome do jogo e rótulo acessível `Voltar para jogos` / `Back to games`. Voltar retorna à mesma Home, preservando busca, categoria e posição de rolagem; é também a ação de alterar jogo. Não criar um segundo botão visual de “Alterar jogo” concorrendo com a seta, pois o protótipo canônico usa a volta como essa transição.

Depois do cabeçalho, mostrar apenas capa/fallback neutro, plataforma, notas de região e precisão e o CTA. Exibir somente chips de plataforma permitidos pelo contexto do catálogo. Para console ou PC, mostrar a pergunta Wi-Fi/Ethernet apenas se a configuração disser que ela afeta a leitura. O CTA `Iniciar Quick Check` só fica ativo depois de haver uma seleção válida completa e fica ancorado no rodapé seguro da tela, como no protótipo; o conteúdo rolável recebe espaço inferior suficiente para não ficar oculto por ele.

Antes do CTA, apresentar uma linha de contexto em `text.tertiary`, com ícone de localização e sem cor de score:

`Região de referência: {região}. Qualidade estimada para jogar nessa região.`

Quando a estratégia não for específica/oficial para o jogo, acrescentar em seguida:

`Esta medição usa uma rota regional de referência; não é o ping oficial do jogo.`

Para console ou PC, esta nota vem depois da ressalva de representatividade da conexão local. As duas notas não devem ser fundidas nem escondidas em tooltip.

### Seleção regional automática

Depois de a pessoa completar jogo e plataforma, o app confirma uma região de referência por uma pré-leitura curta dos candidatos assinados daquele contexto. A sugestão não usa GPS, endereço, IP, rede móvel, Wi-Fi observado, localização precisa nem histórico de escolhas. A localidade do sistema pode apenas ordenar mercados publicados; ela não aparece como prova de onde a pessoa está nem de qual servidor de jogo deveria usar.

Durante a pré-leitura, manter a seleção visível e trocar o CTA por estado de carregamento com `Confirmando região de referência…` / `Confirming a reference region…`. Não exibir RTT parcial, ranking, “mais perto”, “melhor servidor” ou o nome de uma região antes de ela ser confirmada. Essa etapa não gera score, resultado ou entrada no Histórico.

Quando houver um candidato viável, exibir antes do CTA o bloco de contexto:

| Idioma | Título | Texto | Ação condicional |
| --- | --- | --- | --- |
| PT-BR | Região sugerida: {região} | Vamos medir uma rota regional de referência nesta medição. Isso não indica o servidor do jogo. | Mudar região |
| EN | Suggested region: {region} | We’ll measure a regional reference route in this check. This doesn’t indicate the game server. | Change region |

`Mudar região` só aparece quando existirem dois ou mais candidatos assinados para o mesmo jogo, mercado, plataforma e perfil. Com um candidato único, não renderizar botão desabilitado. A escolha manual abre uma sheet com o título `Escolha uma região de referência` / `Choose a reference region`, lista somente candidatos assinados e explica `Vale só para esta medição.` / `This applies to this check only.` Cada linha traz nome localizado da região e `Rota regional de referência` / `Regional reference route`; ela não exibe valor de pré-leitura, score, classificação nem recomenda trocar o servidor do jogo.

Depois da escolha manual, o bloco passa a `Região escolhida para esta medição: {região}` / `Region selected for this check: {region}`. O override não é salvo como preferência, não muda o próximo Quick/Deep Check e não faz fallback silencioso para a sugestão automática se falhar. A nota de precisão regional permanece imediatamente abaixo desse bloco.

### Sem candidato regional viável

Se nenhum candidato tiver respostas UDP válidas suficientes na pré-leitura, substituir a área de contexto por `StatusMessage.inconclusive`, sem score, classificação, métricas, detalhe ou CTA de começar o Quick Check:

| Idioma | Título | Texto | Ação primária | Ação secundária |
| --- | --- | --- | --- | --- |
| PT-BR | Não foi possível confirmar uma região | Não conseguimos confirmar uma rota regional de referência para esta medição. Tente novamente. | Tentar novamente | Escolher outra região* |
| EN | We couldn’t confirm a region | We couldn’t confirm a regional reference route for this check. Try again. | Try again | Choose another region* |

`*` A ação secundária só aparece com dois ou mais candidatos assinados. Ela abre a mesma sheet manual e deixa claro que a nova escolha ainda precisa ser confirmada nesta sessão. Não usar HTTP, ICMP, resultado anterior ou uma região padrão como recuperação; não comunicar esse estado como problema da localização da pessoa, do jogo ou da sua rede.

## Estados de catálogo

### Catálogo remoto atualizado ou catálogo-base válido

Não mostrar aviso. A origem do catálogo é transparente para quem usa o app e não altera a jornada.

### `catalogFallback`: remoto indisponível, mas existe catálogo local válido

Home e seleção continuam funcionando apenas com os contextos presentes no catálogo local válido. Usar `StatusMessage.info` compacto logo abaixo da busca, uma vez por abertura do app, sem ocupar a área dos jogos e sem bloquear nenhuma ação:

| Idioma | Título | Texto |
| --- | --- | --- |
| PT-BR | Usando jogos disponíveis | Não foi possível atualizar a lista agora. Você ainda pode testar os jogos mostrados aqui. |
| EN | Using available games | We couldn’t update the list right now. You can still check the games shown here. |

Não oferecer “tentar de novo” nessa mensagem: a atualização segue a política técnica de 24 horas e não deve induzir uma promessa de recuperação imediata. A mensagem não aparece durante Quick Check, Deep Check, resultado, Detalhes ou Histórico.

### `catalogUnavailable`: não há catálogo válido aplicável

Home abre normalmente, mas sua área de descoberta mostra `EmptyState.catalogUnavailable`. Não renderizar jogos, recentes, categorias, busca interativa ou CTA de medição. A mensagem usa ícone neutro e uma ação secundária única de atualizar a tela quando essa operação for realmente oferecida pelo produto:

| Idioma | Título | Texto | Ação |
| --- | --- | --- | --- |
| PT-BR | Jogos indisponíveis agora | Não conseguimos carregar uma configuração válida para testar jogos. Tente novamente mais tarde. | Tentar novamente |
| EN | Games unavailable right now | We couldn’t load a valid configuration to check games. Try again later. | Try again |

Esse estado não fala em assinatura, servidor, HTTP ou erro de rede. Sem catálogo aplicável, nenhum teste começa e nenhuma medição anterior é recalculada.

### Contexto que deixou de ser elegível

Se uma preferência recente, um link interno ou uma tela já aberta apontar para uma combinação que o catálogo atual não valida, não apresentar chips inválidos nem iniciar a sessão. Trocar o conteúdo de seleção por `EmptyState.catalogUnavailable`, mantendo voltar para a descoberta:

| Idioma | Título | Texto | Ação |
| --- | --- | --- | --- |
| PT-BR | Esta opção não está disponível | Escolha outro jogo para fazer uma medição com uma região de referência válida. | Ver jogos |
| EN | This option isn’t available | Choose another game to run a check with a valid reference region. | View games |

## Acessibilidade e localização

- Busca recebe rótulo e hint localizados; VoiceOver anuncia cada resultado como `{jogo}, {categoria}, disponível` e cada recente inclui o último score somente quando ele existir.
- Capa é decorativa quando nome já está no cartão; o cartão inteiro é um único alvo de no mínimo 44 pt, com ordem de leitura capa omitida → nome → categoria → resultado anterior opcional.
- Chips expõem papel de botão, estado selecionado e seleção atual. Em Dynamic Type AX3–AX5, quebram em linhas sem reduzir fonte ou truncar nomes; o CTA permanece depois de todas as escolhas e notas de representatividade.
- A região de referência e a limitação de precisão são texto real e localizável, não dependem de ícone, cor ou tooltip. VoiceOver lê a região antes do CTA.
- A pré-leitura anuncia uma única vez `Confirmando região de referência` / `Confirming a reference region`; depois anuncia a sugestão ou o estado sem candidato. Não anuncia cada probe nem expõe a ordem/ranking dos candidatos.
- A mudança Home → contexto move o foco para o cabeçalho com o nome do jogo. O botão de voltar tem alvo de no mínimo 44 pt e anuncia que retorna aos jogos; a Home restaurada devolve o foco ao card antes selecionado. Busca, filtros e grade não permanecem na árvore de acessibilidade enquanto o contexto estiver aberto.
- Em Dynamic Type AX3–AX5, o CTA continua disponível no rodapé sem cobrir a última nota; se a altura não comportar a composição, o conteúdo acima dele rola, sem reduzir fonte. Reduzir Movimento usa a transição de navegação do sistema, sem animação customizada de grade ou de capa.
- `Mudar região` e `Escolher outra região` informam em hint que a escolha vale somente para esta medição. A sheet anuncia título, nota de escopo e cada linha como `{região}, rota regional de referência, botão`; a região sugerida ou escolhida recebe o estado selecionado.
- Em AX3–AX5, o bloco de sugestão e os botões se organizam verticalmente; nenhuma ação depende de swipe lateral, mapa, gesto de arrastar ou reconhecimento da imagem. O estado sem candidato recebe foco inicial no título, seguido da explicação e das ações separadas.
- O aviso de fallback é anúncio educado uma única vez por abertura, sem roubar foco da busca. O estado indisponível recebe foco inicial no título; depois lê explicação e ação.
- Com Reduzir Movimento, troca de grade, busca, fallback e estado vazio usa somente cross-fade curto. Com Aumentar Contraste, tiles, chips selecionados e o estado vazio promovem bordas para `border.strong`.

## Aceite de design

Publicidade, `BannerAdSlot` e consentimento não fazem parte deste catálogo nem dos gates visuais do MVP1. Permanecem apenas como referência futura de MVP1.1 no design system, sem implementação ou reserva de área nesta jornada.

Validar no simulador e no iPhone: oito jogos em PT-BR e inglês; busca com resultado e sem resultado; plataforma elegível; console/PC com ressalva; sugestão automática com um e com múltiplos candidatos; override manual só na sessão; ausência de candidato viável; rota regional de referência; fallback com catálogo local; catálogo ausente; contexto recente que se tornou inválido; VoiceOver; AX3 e AX5; Aumentar Contraste; Reduzir Movimento. A aprovação visual exige comparação no viewport do HTML canônico e não é substituída por testes de assinatura ou schema.

## Encaminhamento

Rian integra somente objetos já validados pelo repositório de catálogo na descoberta e seleção. Iury define os rótulos localizados de região, estratégia e confiança que o catálogo entrega; a interface não traduz valores técnicos livres nem cria thresholds. Marco revisa qualquer mudança de copy que altere a precisão comunicada. Esta decisão não autoriza adicionar jogos fora dos oito contextos validados, mexer em score ou publicar catálogo/Worker.
