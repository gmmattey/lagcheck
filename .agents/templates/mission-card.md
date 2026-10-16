# Cartão de Missão — LagCheck

> Obrigatório antes de iniciar uma mudança. O cartão é o registro operacional
> da demanda; não substitui uma decisão de produto em `docs/DECISOES.md` nem um
> Architecture Plan sistêmico.

## #54 — Card estático preparado ao fim do Check

### Enquadramento

- **Problema da pessoa:** quem acaba de receber um veredito válido precisa compartilhar o resultado sem esperar uma nova geração de imagem no toque.
- **Resultado esperado observável:** após um Check válido, o app mostra primeiro o veredito e, logo abaixo, uma prévia discreta do mesmo card estático já preparado localmente para compartilhar. A prévia torna o resultado desejável sem competir com a manchete; a ação de compartilhamento entrega esse arquivo pronto.
- **Fora de escopo:** vídeo automático, upload ou rede, compartilhamento forçado, promessa de composição garantida em um app social específico, novo endpoint, mudança de score/veredito, opção de Ajustes e qualquer arquivo para resultado inconclusivo. A preferência e o descarte de prévia citados na issue ficam para decisão posterior, pois não foram autorizados neste recorte pelo Luiz.
- **Lane:** Full flow comum.
- **Por que esta lane:** altera uma superfície de resultado e o compartilhamento em iOS e Android, mas preserva contratos de medição, persistência e Worker existentes.
- **Decisão/fonte de verdade:** Decisões 64, 74, 81 e 85; `docs/01-funcional.md` §7.4; `docs/07-voz-do-produto.md`; `design-system/`.

### Donos e fronteiras

- **Responsável pela entrega:** Rian (iOS e Android).
- **Responsável pelo aceite operacional de produto:** Giam.
- **Estratégia/prioridade e escalonamento ao Luiz:** Marco.
- **Revisores obrigatórios:** Renan (experiência e visual), Breno (QA), Iury (integridade dos dados exportados).
- **Decisão pendente do Luiz:** nenhuma; o recorte está aprovado pela Decisão 85 e pelo enquadramento desta missão.
- **Mudança sistêmica / Architecture Plan:** não; Camillo entra se a implementação exigir novo contrato, target compartilhado, persistência ou endpoint.

### Handoff de UI

- **Decisão que a pessoa toma:** compartilhar ou não um resultado já pronto; o preparo nunca pede atenção nem muda a hierarquia do veredito.
- **Hierarquia da prévia:** só em `ready`, `caution` e `notReady`, depois da manchete semântica e antes das ações utilitárias, aparece uma única miniatura do JPEG real. Ela não é um novo card de explicação, não é decorativa e não recria o bitmap. A área clicável usa a largura disponível, limitada a 360 pt/dp e centralizada, mantém a razão exata 1200:630, borda `border.subtle` de 1 px e raio `radius.mediaAndMetrics` (8), sem sombra, cor ou espaçamento local. Em tela estreita ou fonte ampliada, reduz proporcionalmente; a tela rola, sem truncar manchete ou ações.
- **Artefato estático canônico:** JPEG de link em `1200×630`, com wordmark `lagcheck`, rótulo `CHECK`, nome localizado do jogo e miniatura neutra aprovada, região/rota que realmente respondeu, indicador visual de veredito por forma e headline limpa, além de P50, jitter e perda somente quando observados. O bitmap não contém `●`, `▲` ou outro glifo de veredito em texto, capa/logo de jogo, ping de jogo não medido ou causalidade não comprovada. Android reutiliza o layout `ShareMediaRenderer.PREVIEW`; iOS o reproduz com os mesmos tokens e conteúdo. Stories e vídeo não são pré-gerados nesta missão.
- **Componentes/tokens:** a tela mantém o veredito como manchete e usa os tokens/componentes existentes de resultado, `VerdictIndicatorBadge`, `ShareMediaScene`/renderizador e folha nativa de compartilhamento. Não criar cores, espaçamentos, cards ou animações novos.
- **PT-BR / English:** iOS preserva as ações existentes de rede; Android preserva seus ícones oficiais e a folha de formatos da Decisão 81. Durante preparo, o valor acessível é `Preparando card` / `Preparing share card`; pronto, `Card pronto para compartilhar` / `Share card ready`; falha, `Não foi possível preparar o card. Tente novamente.` / `Couldn't prepare the share card. Try again.` com ação `Preparar card novamente` / `Prepare card again`. Não chamar a métrica de ping do jogo quando a rota for referência.
- **iOS:** as ações Discord/WhatsApp permanecem na posição atual e ficam desabilitadas durante o preparo. Depois usam a URL já pronta no share sheet nativo; toque na miniatura abre esse mesmo share sheet com o arquivo, e voltar/cancelar retorna foco à miniatura/controle originador sem descartar o resultado. Respeitar Safe Area, Dynamic Type e foco VoiceOver.
- **Android:** os ícones oficiais e a folha Link/Stories/Vídeo da Decisão 81 permanecem. Eles ficam na posição atual e são desabilitados durante o preparo do Link; ao concluir, o formato Link usa o arquivo pronto, enquanto Stories e Vídeo continuam geração explícita sob demanda. Toque na miniatura abre essa folha com Link selecionado e o arquivo pronto; botão voltar retorna foco à miniatura. O seletor do sistema é o fallback. Respeitar insets, escala de fonte e foco TalkBack.

### Comportamento e risco

- **Estados relevantes:**
  - inicial/medindo: não há card e nenhuma geração é iniciada;
  - sucesso válido (`ready`, `caution` ou `notReady`): o veredito aparece primeiro e o card estático é preparado fora do caminho crítico;
  - preparando: a área da prévia reserva a mesma razão 1200:630 com `surface` e borda sutil; ações e miniatura ficam desabilitadas e expõem valor acessível localizado, sem spinner, shimmer, pulso, copy extra ou anúncio assertivo;
  - pronto: a área troca pelo JPEG real sem animação chamativa; ações são habilitadas sem rearranjo e a prévia anuncia arquivo disponível quando recebe foco;
  - prévia pronta: tocar a miniatura abre o fluxo Link com o mesmo arquivo, sem nova renderização;
  - erro de renderização: o resultado permanece íntegro; a mesma área mostra somente a mensagem localizada e um alvo de 44 pt/dp `Preparar card novamente` / `Prepare card again`; a folha não abre sem arquivo real;
  - cancelado, troca de rede ou inconclusivo: nada é gerado nem compartilhado.
- **Maior risco ou hipótese frágil:** geração em aparelhos modestos competir com o primeiro render do resultado ou exportar dado divergente da medição concluída.
- **Limite da promessa ao usuário:** o arquivo contém somente os valores daquele Check válido e descreve a rota realmente medida; não afirma ping do servidor da partida quando a leitura for estimativa regional.
- **Impacto por plataforma:** iOS 17+ e Android API 26+; os dois usam compartilhamento nativo, mas cada destino social pode aceitar formatos de forma diferente.

### Aceite e evidência

| Critério observável | Dono da prova | Evidência exigida | Estado |
| --- | --- | --- | --- |
| Veredito aparece sem esperar pelo card | Rian / Breno | inspeção, teste de UI e captura em iOS/Android | parcial — fluxo separado por inspeção; UI em simulador/emulador pendente |
| Prévia usa o mesmo JPEG pronto, aparece abaixo do veredito e abre o fluxo Link sem nova renderização | Rian / Renan / Breno | teste de UI e captura em iOS/Android | validado por inspeção e teste focado Android; runtime pendente |
| Prévia preserva razão 1200:630, limite 360 pt/dp, tokens existentes, 44 pt/dp, estados pronto/preparando/erro e foco após cancelar | Renan / Breno | inspeção, simulador/emulador e aparelho | parcial — inspeção estática aprovada; foco e runtime pendentes |
| Card local contém apenas o snapshot válido que o originou | Iury / Rian | teste de contrato e inspeção do arquivo | validado em teste Android e inspeção iOS |
| Inconclusivo, cancelado e troca de rede não geram arquivo | Rian / Breno | testes de estado e regressão | validado em teste Android e inspeção iOS |
| Share nativo recebe o arquivo preparado e cancelamento volta ao resultado | Rian / Breno | simulador/emulador e aparelho físico iOS/Android | não validado em ambiente de UI/aparelho |
| PT-BR e inglês renderizam texto, separador decimal, bitmap e metadados corretos | Renan / Breno | testes de localização e inspeção de arquivos | parcial — localizações e metadados inspecionados; render real pendente |
| Dynamic Type iOS AX1–AX5, Android font scale/display size, contraste e alvos de 44 pt/dp preservados sem truncar manchete ou ações | Renan / Breno | revisão visual em simulador/emulador e aparelho | não validado |
| VoiceOver/TalkBack lê veredito antes do share, nome+estado localizado do controle, erro/recuperação separados e retorna foco ao controle após cancelar | Renan / Breno | teste de acessibilidade em aparelho | não validado |
| Badge e headline permanecem distinguíveis por texto/forma, não apenas cor; Reduce Motion não cria animação de render | Renan / Breno | revisão visual/acessibilidade | parcial — indicador por forma inspecionado; revisão em execução pendente |
| Renderização não atrasa a tela nem degrada interação | Breno | benchmark e toque em aparelhos físicos representativos | não validado |

Registrar o ambiente da prova: inspeção estática, teste unitário/contrato,
simulador/emulador, aparelho iOS, aparelho Android, beta ou produção. Um estado
não substitui o outro.

### Handoff e encerramento

- **Arquivos/módulos tocados:** `CheckCompletoResultView`, `LagCheckDiscordCardExporter`, recursos localizados e testes de UI no iOS; `PreparedShareCard`, `ShareMediaSheet`, `VerdictScreen` e teste unitário no Android. Domínio e Worker não entraram no escopo.
- **Pendências e riscos aceitos:** compatibilidade de formato continua controlada pelo app de destino; o LagCheck apenas oferece o arquivo ao seletor nativo. Simulador iOS não instalou o app por erro preexistente do placeholder `LagCheckWidget`; emulador/aparelhos, acessibilidade em execução, cancelamento do share sheet, FileProvider real e benchmark permanecem sem prova.
- **Resultado da revisão:** APROVADO COM RESSALVAS — a prévia discreta agora usa o mesmo JPEG preparado, aparece sob o veredito e respeita o handoff nos dois clientes. Renan aprovou a revisão visual estática; Iury aprovou a integridade; Breno aprovou com ressalvas após build/testes disponíveis.
- **Próximo passo e dona/o:** validar em simulador/emulador e aparelhos iOS/Android a prévia, cancelamento/retorno de foco da folha, VoiceOver/TalkBack, Dynamic Type/font scale, FileProvider/destino social e benchmark antes de qualquer candidato a release; Breno e Renan registram a evidência.
