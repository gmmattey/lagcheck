# Parecer de design — Deep Check, Histórico e Detalhes

**Data:** 9 de setembro de 2026  
**Responsável:** Renan  
**Estado:** composição aprovada com pendências de implementação e validação interativa

## Escopo da revisão

Este parecer confronta `design-system/prototypes/ios-reference/source/Nolaggy iOS Prototype.dc.html` com as superfícies atuais de Deep Check, Histórico e Detalhes. Ele define a composição aprovada para os estados que o protótipo não cobre integralmente. Não altera as regras de rede, score ou persistência.

## O que permanece canônico

O Deep Check explica antes do início que compara repouso e uso intenso no Wi-Fi. Durante a execução, as duas leituras são independentes. O resultado mostra primeiro o score de repouso; a carga é apenas um impacto complementar, nunca uma segunda nota. Detalhes começa pelo contexto de referência e só então apresenta gráfico e métricas. Histórico é uma superfície de acompanhamento de medições válidas, não um atalho que faça uma leitura parcial parecer resultado.

## Composição aprovada para estados novos

### 1. Medição em repouso e sob carga

No topo, manter voltar e a wordmark oficial. Logo abaixo, apresentar `Deep Check · {jogo}` e uma linha de contexto persistente: `{região de referência} · rota regional de referência · estimativa de confiança média`. Esse contexto é evidência da rota observada, não promessa de ping oficial do jogo.

Exibir fase textual (`Fase 1 de 2 · em repouso` ou `Fase 2 de 2 · sob carga`), progresso textual e tempo restante aproximado. Na segunda fase, o gráfico deve mostrar a série concluída de repouso como linha secundária tracejada e a série atual sob carga como linha principal; a legenda textual identifica ambas. As séries não podem ser combinadas em uma mesma distribuição nem usar apenas cor para se distinguir. Com Reduzir Movimento, atualizar o gráfico sem pulso, escala ou translação contínua.

VoiceOver deve anunciar, sem repetir a cada amostra: fase, jogo, região de referência, progresso e o último RTT quando houver. O resumo alternativo do gráfico deve explicitar qual série está sendo lida.

### 2. Resultado com comparação repouso/carga disponível

Preservar anel de 160 pt e classificação do repouso como primeira conclusão. O cartão `Impacto sob carga` precisa conter título, variação em ms e uma classificação textual do impacto. Quando a variação representar risco, usar o tratamento semântico de risco (ícone + texto + cor); quando não representar risco, manter texto e ícone, sem depender de verde ou azul para comunicar segurança.

Após o cartão, incluir uma frase curta sobre o que a diferença observada pode significar na partida. A tabela de Ping e Jitter mantém cabeçalhos visíveis de `Repouso` e `Sob carga`, inclusive no layout vertical de Dynamic Type. `Ver detalhes completos` é a ação primária; `Testar novamente` é secundária.

### 3. Carga indisponível após repouso válido

O score, a classificação e as métricas de repouso continuam visíveis. Substituir o cartão de impacto por um estado neutro com ícone, título `Impacto sob carga indisponível` e a explicação de que a rede em repouso foi medida, mas a comparação não foi concluída. Não mostrar travessão como único valor da coluna `Sob carga`; as linhas comparativas devem ser ocultadas nesse caso para não sugerir uma medida inexistente. Oferecer `Testar novamente` e `Ver detalhes do repouso`; a cópia não recomenda jogar com base na carga ausente.

### 4. Dados insuficientes

Usar a composição neutra de `StatusMessage`, sem anel, score, classificação, métricas parciais, impacto, Detalhes ou entrada no Histórico. A mensagem informa que não houve respostas UDP válidas suficientes e a ação única é `Tentar novamente`. A região de referência pode ser exibida como contexto secundário, mas não deve transformar o estado em diagnóstico.

### 5. Cancelamento, background ou mudança de rede

Usar a mesma composição neutra, distinguindo no texto a sessão interrompida da conexão que mudou. Não manter gráfico, progresso, score, métricas, Detalhes ou Histórico. A ação é `Reiniciar teste`. Essa tela precisa receber foco inicial do VoiceOver na mensagem de estado; o botão vem em seguida.

## Divergências objetivas encontradas

1. Na medição do Deep Check atual falta a região de referência, o alvo/estratégia e a confiança; ela mostra apenas a fase e o jogo.
2. Durante a fase sob carga o app atual desenha apenas amostras da fase corrente. Falta a série de repouso concluída, a legenda e o progresso/tempo restantes previstos pelo protótipo.
3. O cartão atual de impacto usa apresentação neutra para qualquer resultado e não traz classificação do impacto nem frase de consequência. Isso reduz a separação visual entre impacto relevante e variação sem risco.
4. Com carga indisponível, a tabela atual ainda apresenta `—` em `Sob carga`. A composição aprovada exige ocultar a comparação inexistente e nomear explicitamente a indisponibilidade.
5. O detalhe aberto a partir do Deep Check é uma folha de métricas sem região de referência, alvo medido, confiança, versão de regra ou aviso sobre a série não persistida. Ele diverge da ordem canônica de Detalhes e do contrato de evidência local.
6. O Histórico atual é uma lista plana de cartões de reteste. Não preserva a organização por jogo, a evolução recente ou a média de sete dias exibidas pelo protótipo; tampouco oferece acesso a Detalhes do registro. Como o resumo de sete dias depende de duas medições em dias distintos, antes disso a composição deve exibir somente a última medição, sem bloco vazio de tendência.
7. O rótulo de acessibilidade do cartão de Histórico descreve somente o reteste. Ele precisa incluir jogo, data/hora, score, classificação, tipo de medição (Quick ou Deep) e a ação disponível. A navegação para Detalhes deve ser uma ação separada e nomeada.

## Encaminhamento para Rian e Marco

Rian precisa implementar os itens 1 a 5 nas telas Deep/Detalhes e o item 6/7 no Histórico, preservando tokens e alvos de 44 pt. Para a sobreposição do gráfico sob carga, a camada de apresentação precisa receber a série de repouso concluída sem alterar o cálculo ou misturar amostras. A classificação semântica do impacto exige que Iury exponha um resultado determinístico próprio para impacto sob carga; não deve ser inferida por uma cor ou threshold na UI.

Marco precisa registrar com Iury o vocabulário e os limites dessa classificação de impacto antes de ela aparecer no produto. Até isso existir, o cartão pode comunicar somente a variação medida e sua limitação, sem dizer que a conexão está boa, ruim ou adequada para jogar sob carga.

## Gate de aceite de design

Após a implementação, validar no mesmo viewport do protótipo: PT-BR e inglês, Dynamic Type AX3 e AX5, VoiceOver, Aumentar Contraste e Reduzir Movimento. O smoke em iPhone no Wi-Fi deve cobrir repouso válido + carga válida, carga indisponível, dados UDP insuficientes, cancelamento e interrupção por mudança de rede/background. A inspeção nesta revisão foi de código, documentação e fixtures; a execução específica de UI no simulador não concluiu porque o boot ficou bloqueado.
