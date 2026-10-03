# Audit de telas Android × iOS — 2026-10-03

## Método e limite

Referência: composição e navegação SwiftUI atuais em `Sources/NolaggyApp/` e tokens em `Sources/NolaggyDesign/`. Comparação com o Compose em `android/app/` e `android/core/designsystem/`. O protótipo e os documentos de produto não foram usados como referência visual. O mapeamento iOS é estático neste host Windows. O Android foi renderizado em um emulador API 37 após a correção, mas não houve captura de iPhone no mesmo estado e viewport. Espaçamento percebido, quebra de linha, Dynamic Type e contraste entre plataformas permanecem sem prova lado a lado.

## Matriz tela a tela

| Prioridade | Tela/estado | iOS atual | Android antes do recorte `agy` | Resultado do audit |
| --- | --- | --- | --- | --- |
| P0 | Casca e navegação principal | `QuickCheckFeatureView.swift:159-280` mantém `TabView` com Início e Jogos. | `MainActivity.kt:92-243` trocava uma tela inteira por `Screen`, sem abas. | Desvio estrutural confirmado. Abas devem aparecer nos destinos principais e sumir durante medição e resultado. |
| P1 | Home | `HomeFeatureView.swift:145-320` mostra wordmark, pílula de rede, hero de jogo com arte sangrando pelas margens, CTA, último check e atalhos. | `HomeScreen.kt:84-278` contém a mesma ordem geral, mas a arte estava contida na margem horizontal de 22 dp. | Hierarquia próxima; largura do hero divergente. |
| P1 | Jogos | `HomePresentationComponents.swift:1050-1390` usa favoritos em trilho horizontal de miniaturas, um recente destacado e lista de jogos. | `GameSelectionScreen.kt:195-332` repetia favoritos e recentes em linhas; `FavoriteCard` existia sem uso. | Composição de favoritos e recentes divergente. O bloco de Check Geral fica no fim da lista **também no iOS atual**. |
| P1 | Seleção de plataforma | `PlatformSelectionSheet.swift:56-180` permite escolher plataforma e, em console/PC, Wi-Fi ou cabo antes de iniciar. | `GameSelectionScreen.kt:336-420` escolhe plataforma, mas lê o tipo de conexão do aparelho e não oferece o segmento de conexão do equipamento externo. | Lacuna de interação e conteúdo; depende de decisão funcional antes de copiar a UI. |
| P2 | Detalhe de jogo | `GameDetailView.swift:29-169` tem hero, contexto do equipamento, escopo da medição, CTA e informações complementares, mas `selectedGameForDetails` só recebe `nil` no código atual; não há atribuição que abra o destino. | Não há `GameDetailScreen` no Compose; a seleção usa uma folha e inicia o check. | Código iOS sem rota ativa no fluxo atual; não é lacuna de paridade da jornada alcançável. Não criar nova etapa Android até esse destino existir no iOS. |
| P1 | Pré-leitura regional | `RegionalSelectionFeatureView.swift:31-112` mostra carregamento ou ausência de rota viável com retry. `QuickCheckOrchestration.swift:23-63` abre esse estado antes do check. | `MainViewModel.kt:286-315` entra na tela de medição antes de resolver o plano; falha vira estado cancelado da mesma tela. | Estados e sequência visual diferentes. |
| P1 | Medição ao vivo | A jornada Deep Check ativa usa `DeepCheckFeatureView.swift:211-234` com cabeçalho “Cancelar”, jogo e `MeasurementLiveTrail` em repouso/carga. `MeasurementProgressView.swift` pertence ao caminho Quick Check alternativo e usa chevron. | `CheckCockpitScreen.kt:45-151` usa a trilha e fases; os textos PT-BR da trilha estavam fixos. | Paridade parcial; localização e alvo de cancelar foram corrigidos. Não misturar os dois cabeçalhos SwiftUI. |
| P2 | Consentimento de dados móveis | `CellularDataConsentSheet.swift` e `DeepCheckFeatureView.swift:192-210` apresentam consentimento antes de medir. | `CheckCockpitScreen.kt:157-244` apresenta folha de consentimento. | Equivalente conceitual; falta comparação renderizada de texto, altura e ações. |
| P1 | Cancelado e inconclusivo | No Deep Check ativo, `DeepCheckFeatureView.swift` apresenta cancelado como terminal central e inconclusivo por `CheckCompletoResultView(result: nil)`. `MeasurementStatusView.swift` pertence ao Quick Check alternativo. | `CheckCockpitScreen.kt` mostra terminal central para cancelamento; inconclusivo usa `VerdictScreen`. | A correspondência funcional do inconclusivo existe; diferença restante é composição, copy e retorno do terminal cancelado. |
| P1 | Veredito | `CheckCompletoResultView.swift:78-198,550-646` mostra veredito, subtítulo, métricas, peso principal, **Ver detalhes antes de Testar novamente** e compartilhamento. | `VerdictScreen.kt:200-475` inverte a ordem das ações e insere barra de estabilidade entre métricas e peso principal. | Diferença visível. A barra usa largura derivada do veredito quando `stabilityRatio` falta (`VerdictScreen.kt:92-98`), então também precisa revisão de integridade visual. |
| P1 | Detalhes técnicos | `TechnicalDetailsView.swift:30-70,134-228` tem resumo, score, grade 2×2 e gráfico de percentis repouso/carga. | `TechnicalDetailsScreen.kt:52-310` tem resumo e grade, mas o gráfico usa série temporal e os cartões seguintes têm outra composição. | Paridade parcial; gráfico e hierarquia são diferentes. |
| P1 | Histórico e detalhe de registro | `HistoryFeatureView.swift:31-180` agrupa por jogo e abre `MeasurementDetailsView.swift:11-138` em sheet. | `HistoryScreen.kt:60-239` também agrupa por jogo, mas `MainViewModel.kt:422-442` abre `TechnicalDetailsScreen`, que representa outra tela iOS. | Lista principal próxima; destino de um registro divergente. |
| P2 | Ajustes | `SettingsView.swift:44-303` tem idioma, região, histórico, sobre e suporte. | `SettingsScreen.kt:51-310` cobre idioma, histórico, sobre e suporte; não há escolha de região na tela. | Lacuna de opção e hierarquia, além de diferenças de apresentação. |
| P2 | Dados da Rede | `NetworkCockpitView.swift:42-105` mostra resumo ao vivo, rede local, borda WAN, casos de uso e ações, com refresh e PDF. | `NetworkCockpitScreen.kt:50-181` mostra seções do presenter, cópia e compartilhamento de texto. | Cobertura e ações diferentes; métricas de rádio específicas do Android precisam ser preservadas. |
| P2 | Deep Check | `DeepCheckFeatureView.swift:63-136` tem estados de intro, Wi-Fi indisponível, consentimento, repouso/carga, resultado, inconclusivo e cancelado. | `MainViewModel.kt:61-87` expõe um fluxo único `Measurement` → `Verdict` com consentimento/cancelamento no cockpit. | Não existe correspondência 1:1 de cada estado iOS. Auditar produto antes de criar telas adicionais. |

## Diferenças transversais comprovadas

- **Tipografia display:** `NLTypography.swift:5-47` usa desenho `.rounded` para nomes de jogos, títulos e manchetes. `Type.kt:14-68` usa `FontFamily.SansSerif` nas posições equivalentes. Os tamanhos declarados são próximos, mas o desenho das letras muda em todas as telas principais.
- **Alvos de toque:** o iOS dá 44 pt ao retorno da medição (`MeasurementProgressView.swift:12-21`) e ao retorno do resultado (`CheckCompletoResultView.swift:86-95`). No Android, os botões de texto de cancelar/fechar são `clickable` com padding de 7×6 dp (`CheckCockpitScreen.kt:78-96`, `VerdictScreen.kt:201-218`), sem tamanho mínimo equivalente explícito.
- **Check Geral:** o Android cria um jogo de apresentação copiando Fortnite e usando o ID `check-geral` (`MainActivity.kt:203-209`). A revisão aprofundada confirmou que `MeasurementPlanner.kt` reconhece esse ID por `PlatformLabels.GENERIC_GAME_ID` e chama `GameContext.genericGaming`; portanto, a suspeita inicial de rejeição por ID não se sustenta. Ainda falta executar o fluxo funcional.

## Recorte P0/P1 aplicado nesta sessão

- **Navegação:** `MainActivity.kt` agora mantém Início e Jogos na barra inferior somente nos destinos principais. O ícone de Jogos representa um controle; a seta no cabeçalho do catálogo aparece apenas quando a entrada vem do atalho da Home.
- **Home:** `HomeScreen.kt` expande a arte do jogo até as bordas sem deslocar título, contexto e CTA da margem de conteúdo.
- **Jogos:** `GameSelectionScreen.kt` usa trilho horizontal de favoritos, mostra três sugestões quando não há favoritos e destaca apenas o recente mais novo. Check Geral permanece no fim da lista, como no SwiftUI atual.
- **Medição:** `MeasurementLiveTrail.kt` recebe os textos do app, e `ScreenStrings.kt` traduz os novos rótulos em PT-BR, inglês e espanhol.

**Evidência Android:** Home (captura inicial removida por estar superada pela tipografia em `android-home-rounded-emulator.png`), `android-games-emulator.png` (entrada pela aba) e `android-games-home-shortcut-emulator.png` (entrada pelo atalho) foram capturadas no emulador `persona_api37_x86_64`. `:core:session:test`, `:app:testDebugUnitTest` e `:app:assembleDebug` passaram em modo offline. O primeiro AVD recusou instalação por falta de espaço; o segundo instalou e abriu o APK. Não houve teste em aparelho Android físico nem renderização iOS nesta sessão.

## Critérios para encerrar a paridade

1. Revisar o diff do recorte `agy` contra as views SwiftUI citadas, preservando apenas os P0/P1 autorizados.
2. Compilar Android e executar testes pertinentes; verificar navegação, busca/favoritos, medição em PT-BR e inglês.
3. Capturar Home, Jogos, seleção, medição, veredito, detalhes, Histórico e Ajustes nos mesmos estados e em viewports equivalentes. Validar também texto ampliado e acessibilidade.
4. Tratar as lacunas restantes em recortes separados, sobretudo seleção de conexão externa, estados regionais, resultado e detalhe vindo do Histórico.

## Acompanhamento sequencial — Veredito

- `agy` alinhou a composição de `VerdictScreen.kt` ao `body` atual de `CheckCompletoResultView.swift`: retorno por chevron, card de peso imediatamente após as métricas, detalhes antes do novo teste e compartilhamentos compactos. A barra de estabilidade e seus ratios substitutos saíram porque `stabilitySection` não é chamada pelo SwiftUI atual.
- Revisão Marco: alvos de compartilhamento mantidos em 44 dp pelo requisito de acessibilidade; o ícone de retorno usa a variante AutoMirrored e descrição localizada.
- `git diff --check` passou; `:app:assembleDebug` offline passou via `java -cp gradle/wrapper/gradle-wrapper.jar org.gradle.wrapper.GradleWrapperMain`. AGY não havia encontrado esse método de build; a validação foi feita na revisão. Falta comparar renderizações iOS e Android em estados equivalentes.

## Acompanhamento sequencial — Detalhes técnicos

- `agy` aproximou cabeçalho, espaçamento entre blocos, resumo e moldura dos achados ao `TechnicalDetailsView.swift` atual. A revisão manteve o alvo de fechar em 44 dp, traduziu o novo título para EN/ES e restaurou “O que fazer”, pois as recomendações medidas não aparecem em outra tela Android.
- Permanece diferença de dados e de gráfico: o iOS recebe percentis de repouso/carga e P99 por fase; o `GameReadinessEvaluation` Android desta tela não os expõe. O gráfico temporal e o valor de pior spike foram mantidos com seus nomes verdadeiros. Não foi fabricado P99.
- `:app:assembleDebug` e `:app:testDebugUnitTest` passaram offline após a revisão. Paridade renderizada ainda pendente.

## Acompanhamento sequencial — Medição e detalhe do Histórico

- `agy` ajustou o cabeçalho da medição e centralizou o estado cancelado, mantendo `CancelReason`, consentimento móvel e texto de progresso medido. O alvo de cancelar tem mínimo de 44 dp e o de tentar novamente, 48 dp. `:app:assembleDebug` passou offline.
- O clique em um registro agora abre `CheckHistoryItemDetailsScreen.kt`, uma tela própria. Após revisão e retrabalho com `agy`, a composição segue o detalhe SwiftUI: retorno/título compacto, gráfico antes da lista de métricas. Ela só mostra campos persistidos; região, alvo, percentis superiores e divisão repouso/carga não são reconstruídos. A tela técnica da sessão atual permanece separada.
- `:app:assembleDebug` e `:app:testDebugUnitTest` passaram offline após a mudança de rota. Ainda faltam capturas comparativas e navegação interativa no emulador para esse novo destino.

## Gate de arquitetura aberto

- A pré-leitura regional iOS faz coleta de rota antes do Check. O Android apenas resolve uma rota do catálogo e já entra no cockpit. Uma tela de espera sem o trabalho de rede equivalente comunicaria uma validação inexistente. A paridade desse P1 requer plano do Camillo em `.agents/architecture-plan.md` antes de alterar o fluxo de rede.
- O seletor de plataforma iOS captura separadamente o enlace declarado do console/PC e a rede observada no iPhone. O Android só mantém a rede observada do telefone. Esse P1 exige contrato de sessão, apresentação e histórico que não confunda as duas fontes; não basta adicionar o segmento visual.

## Acompanhamento sequencial — Ajustes

- `agy` acrescentou a linha Histórico antes da ação destrutiva e ligou a navegação a `Screen.History`. Os grupos usam 24 dp de espaçamento, como o `VStack` SwiftUI atual. O seletor de região segue pendente porque o planejador Android não consome preferência manual; exibi-lo agora criaria controle sem efeito.
- `:app:assembleDebug` e `:app:testDebugUnitTest` passaram offline após revisão. Falta comparação renderizada.

## Acompanhamento sequencial — Plataforma e conexão externa

- O adendo 10 de `.agents/architecture-plan.md` define `ExternalEquipmentLink` declarado, distinto de `connectionType` observado no Android. A revisão alinhou a folha ao SwiftUI atual (Wi-Fi inicial, opção Cabo), sem entregar essa declaração ao avaliador/UDP.
- `agy` conectou a escolha na sessão e no histórico JSON com leitura nula para entradas antigas. A revisão zera a declaração quando a plataforma é celular, inclusive no Check Geral, e ignora valores de histórico desconhecidos. O detalhe do Histórico identifica o dado como declarado.
- `:core:domain:test`, `:app:testDebugUnitTest` e `:app:assembleDebug` passaram offline. O teste criado por `agy` que apenas copiava um objeto de avaliação e comparava seus getters foi removido por não exercitar o avaliador.
- Retrocompatibilidade executada no emulador: `legacy-history-fixture.json` (sem `declaredExternalLink`) foi colocado apenas no armazenamento do app Debug. Após reinício, o registro apareceu na Home e no Histórico e abriu em Detalhes sem valor de conexão externa inventado. As capturas iniciais foram removidas por estarem superadas; a evidência mantida de leitura retrocompatível está em `android-history-mixed-emulator.png` e `android-history-detail-legacy-after-emulator.png`, no acompanhamento posterior. Esse acompanhamento usa fixtures, não coleta real. O fixture foi retirado do emulador após a prova.
- A captura inicial da folha de plataforma (removida após a correção) expôs diferença de composição; `agy` retrabalhou a mesma folha e `android-platform-sheet-revised-emulator.png` mostra título/subtítulo, linhas de plataforma e Wi-Fi/Cabo lado a lado. `android-platform-mobile-emulator.png` confirma que o segmento some para Mobile. O uso de “agora” no card recente para um registro antigo foi corrigido para `check.formattedDate`.
- A suíte `:core:session:test` apontou “Voltar” sem tradução e “PDF” fora de `tr()`; ambos foram corrigidos. A rodada final offline de `:core:session:test`, `:core:domain:test`, `:app:testDebugUnitTest` e `:app:assembleDebug` passou. Não houve aparelho físico nem comparação renderizada no iOS.

## Acompanhamento sequencial — Pré-leitura regional

- O adendo 11 de `.agents/architecture-plan.md` delimita a seleção regional antes do score. `agy` portou `regional-selection-1`, criou snapshot de candidatos do catálogo validado, coletor UDP curto (3 probes) e a tela de progresso/sem rota viável. A revisão exigiu validação de versão/contexto/região/prioridade do snapshot, testes com vetores da regra iOS e cancelamento da coleta.
- A revisão independente encontrou erros de compilação na tela e em um teste, apesar do relato inicial de sucesso do `agy`. Corrigimos os imports e o construtor do teste. Também passamos a mostrar a tela regional antes de aguardar o catálogo, paramos o observador de rede ao ficar inconclusivo e descartamos a pré-leitura ao ir para segundo plano ou trocar de rede, sem mostrar uma medição que não ocorreu.
- `:core:domain:test`, `:core:catalog:test`, `:core:network:test`, `:core:session:test`, `:app:testDebugUnitTest` e `:app:assembleDebug` passaram offline via wrapper Java após essas correções. Isto valida compilação e vetores locais; a coleta regional real, a troca de rede em aparelho e a comparação visual com iPhone ainda não foram comprovadas.

## Acompanhamento sequencial — Região em Ajustes

- `agy` ligou o item Região de referência a candidatos do catálogo carregado e a uma preferência opcional em `SharedPreferences`; a preferência entra na pré-leitura seguinte. Automático limpa o override. Uma região manual presente no snapshot é a única coletada; se falhar, não há troca silenciosa de destino.
- Revisão Marco: valor salvo ausente no catálogo é limpo ao carregar a lista; se ausente apenas no snapshot do jogo, a sessão usa automático. A tela deixa de exibir ID bruto obsoleto. Exceções genéricas da coleta não acionam fallback automático.
- `git diff --check` e suíte offline `:core:domain:test :core:catalog:test :core:network:test :core:session:test :app:testDebugUnitTest :app:assembleDebug` passaram. Não houve teste físico da escolha manual.

## Acompanhamento sequencial — Dados da Rede

- `agy` acrescentou atualização manual, IP local observado, IP público apenas mascarado e casos de uso com leituras locais. O cabeçalho deixou de chamar `text/plain` de PDF: a ação agora é Compartilhar. Exportação PDF do iOS segue como diferença explícita.
- A revisão corrigiu a regra de 5 GHz para não classificar 6 GHz como 5 GHz; adicionou teste para 5 GHz, 6 GHz e ausência de RTT do gateway. O estado de captura agora é separado de relatório ausente: falha termina em campos inconclusivos e mantém Atualizar disponível. Fechar, compartilhar e atualizar têm mínimo de 44 dp.
- `:core:session:test`, `:app:testDebugUnitTest` e `:app:assembleDebug` passaram offline. A leitura de gateway/NAT e a disposição em aparelho físico continuam sem prova.

## Acompanhamento sequencial — Detalhes técnicos com métricas de fase

- O adendo 12 de `.agents/architecture-plan.md` foi revisado contra o código: `DeepCheckEvaluator` fornece `QualityMetrics` com percentis `Double?`, e o Histórico usa `org.json`. A primeira fase altera só os Detalhes da sessão atual.
- `agy` transportou `DeepCheckMetrics?` a partir das amostras já coletadas, sem alterar o veredito, e acrescentou gráfico de percentis. A revisão encontrou erro de chaves que quebrava `:app:compileDebugKotlin`; corrigimos. Também impedimos que uma fase de carga ausente fosse desenhada com valores copiados do repouso. A grade mostra P99 real quando disponível; registros sem essas métricas continuam identificando o pior spike pelo seu nome.
- `:core:domain:test`, `:core:session:test`, `:app:testDebugUnitTest` e `:app:assembleDebug` passaram offline após as correções de compilação. Ainda falta capturar um resultado completo real para comparar o gráfico renderizado com o iOS.

## Acompanhamento sequencial — Métricas no detalhe do Histórico

- `agy` acrescentou campos opcionais P50/P95/P99 e contagem de spikes por fase ao item persistido e à tela. A revisão preservou a gravação da série temporal real já existente no Android, isolou a leitura de campos novos inválidos e exibiu os percentis disponíveis independentemente de um P50 ausente. Labels PT/EN/ES das novas linhas foram adicionados.
- O teste JVM do `org.json` não era executável sem runtime Android; a prova foi feita no emulador API 37 com `mixed-history-fixture.json`. Dois registros carregaram: um legado sem chaves novas e outro com `idleP50` malformado. O segundo exibiu os demais P95/P99 de repouso e P50/P95/P99 de carga; o legado mostrou apenas métricas antigas. Evidências: `android-history-mixed-emulator.png`, `android-history-detail-mixed-emulator.png`, `android-history-detail-legacy-after-emulator.png`. O fixture foi removido do app Debug após a captura.
- `:core:domain:test`, `:core:session:test`, `:app:testDebugUnitTest` e `:app:assembleDebug` passaram offline. Os percentis da fixture verificam parse e apresentação; não comprovam coleta real no aparelho.

## Acompanhamento sequencial — Consentimento de dados móveis

- `agy` alinhou a folha ao `CellularDataConsentSheet.swift`: ícone em círculo de 80 dp, título, motivo, limite de até 10 MB em linha própria, ação primária acima de Cancelar, alvos de 48 dp e expansão parcial. As strings PT-BR/EN/ES correspondem aos `Localizable.strings` atuais. A medição continua iniciando apenas após o callback de confirmação.
- A revisão substituiu o ícone genérico de alerta deixado pelo `agy` por uma antena desenhada localmente, sem dependência nova. A suíte offline `:core:domain:test :core:catalog:test :core:network:test :core:session:test :app:testDebugUnitTest :app:assembleDebug` passou após acrescentar a tradução ausente de “Região de referência” que o teste de completude revelou. A altura e aparência em aparelho físico permanecem sem comparação renderizada.
- O Check Geral copiava também a miniatura neutra de Fortnite; sua apresentação agora usa `drawableResName` vazio, evitando associar arte de outro jogo ao diagnóstico genérico. O planejador já tratava `check-geral` como contexto genérico.

## Acompanhamento sequencial — Cancelado e inconclusivo

- A comparação de `DeepCheckFeatureView.swift` com `CheckCockpitScreen.kt` confirma o terminal central de cancelamento e o resultado inconclusivo dentro do mesmo formato de veredito; não há motivo para criar uma tela Android adicional apenas por diferença de nomes de estados.
- A revisão encontrou um erro de conteúdo no inconclusivo: `ReadinessPresenter.primaryWeight` podia comunicar “Rota estável” quando a causa era nula. Agora usa a razão localizada “Amostras UDP insuficientes”. O cabeçalho do veredito também deixou de inventar “São Paulo” quando a região está vazia. O teste de domínio cobre o texto do inconclusivo; a suíte offline completa de módulos e APK passou.

## Complemento direto — PDF de Dados da Rede

- Após o limite do `agy`, Marco implementou `NetworkReportPdfExporter.kt` com `PdfDocument` nativo. O cabeçalho da tela exporta `application/pdf` via FileProvider; os dados vêm das mesmas `CockpitPresenter.sections` exibidas no momento, sem inventar gateway RTT ou casos de uso. A ação fica indisponível durante a captura; cópia de texto permanece separada.
- No emulador API 37, o toque em PDF criou um arquivo de uma página no cache isolado `network-reports` e abriu o compartilhamento. A página foi renderizada e inspecionada: as três seções cabem, valores longos permanecem legíveis, e o IP público aparece mascarado. O exemplo temporário com dados da rede foi apagado do checkout após a inspeção. `:app:assembleDebug` e `:app:testDebugUnitTest` passaram offline.

## Complemento direto — Tipografia e estado de rede indisponível

- Os estilos Android de manchete, nome do jogo, título de tela, status e título de modal passaram a usar Nunito variável, fonte de terminais arredondados distribuída sob SIL OFL em `core/designsystem/third_party/nunito/OFL.txt`. Corpo e números monoespaçados foram preservados. A Home foi capturada no emulador em `android-home-rounded-emulator.png`; isto aproxima o desenho `.rounded` de `NLTypography.swift`, sem alegar identidade com SF Rounded da Apple.
- A licença também entra em `assets/licenses/nunito-OFL.txt` no APK. Ajustes oferece “Licenças de código aberto” com a íntegra em folha rolável. `jar tf app-debug.apk` confirmou a fonte e a licença empacotadas.
- A leitura do fluxo iOS atual mostrou que `DeepCheckSessionCoordinator.start` aceita somente Wi-Fi ou celular. Para rede ausente/desconhecida/Ethernet, o Android agora abre `ConnectionRequiredScreen` com o mesmo título, mensagem e ação localizados da view `requiresWiFi`, antes de qualquer coleta. A rede é verificada novamente depois do consentimento móvel. A suíte offline `:core:domain:test :core:catalog:test :core:network:test :core:session:test :app:testDebugUnitTest :app:assembleDebug` passou.
- No emulador API 37, Wi-Fi e dados móveis foram desligados antes de tocar em “Checar agora”. A tela mostrou “Não foi possível iniciar o teste”, a mensagem de conexão e “Voltar”, sem progresso/medição; captura: `android-connection-required-emulator.png`. As rádios foram reabilitadas e o emulador encerrado. Permanecem sem prova a comparação renderizada com iPhone e a medição regional/UDP em aparelho físico.

## Complemento direto — Casos de uso do Cockpit

- `NetworkCockpitView.swift` permite tocar em cada caso de uso para ler o motivo e o limite da análise. As quatro linhas Android agora abrem folha parcial com o resultado local já calculado pelo `CockpitPresenter`; quando não avaliado, explicam a falta de leituras. O texto de escopo foi adaptado de “iPhone” para “Android” em PT-BR/EN/ES. Nenhuma regra de prontidão nova foi criada.
- A primeira captura expôs uma colisão entre o modelo `CockpitRow` importado e o composable homônimo: as seções local/WAN ficaram vazias. O import recebeu alias, e nova instalação no emulador mostrou novamente todas as linhas. Ao tocar Cloud Gaming sem leituras, a folha abriu com motivo e limite; `android-network-use-case-emulator.png` registra o estado. Wi-Fi/dados móveis foram reabilitados e o emulador encerrado. `:core:domain:test :core:catalog:test :core:network:test :core:session:test :app:testDebugUnitTest :app:assembleDebug` passou offline antes do alias; `:app:assembleDebug :app:testDebugUnitTest` passou depois.

## Estado atual do mapeamento

### Revisão anterior ao merge

- O atalho de último resultado da Home passou a abrir o mesmo detalhe persistido do Histórico, preservando enlace declarado e percentis disponíveis. O retorno volta à Home quando a entrada ocorreu por ela.
- O catálogo v3 do Check Geral passou a pré-ler apenas a rota primária do mercado, como o `automaticRegionalSnapshot` SwiftUI atual. Teste de catálogo cobre BR e o fallback US do catálogo publicado, que só contém SA; uma preferência manual fora desse snapshot usa a rota automática, como no iOS atual.
- O PDF usa Coral Solar `#FF5A36` e a wordmark minúscula. A resolução DNS síncrona anterior à abertura do socket ainda não tem prova de cancelamento imediato em dispositivo físico; a revisão estrutural não equivale a esse gate.

| Tela/estado | Resultado local | Prova que ainda falta |
| --- | --- | --- |
| Abas, Home, Jogos e folha de plataforma | Composição, navegação, favoritos/recentes e enlace declarado corrigidos. | Comparação renderizada iOS/Android. |
| Detalhe de jogo | Sem rota ativa no iOS atual; não foi criado destino Android artificial. | Reavaliar se o iOS tornar a rota alcançável. |
| Pré-leitura regional | Coleta e seleção antes da medição, com cancelamento e retry. | Rede real e troca de rede em aparelho físico. |
| Deep Check | Consentimento, rede indisponível, fases, cancelado e inconclusivo cobertos. A intro do SwiftUI é transitória porque `autoStart` é `true` na chamada ativa. | Consentimento e medição em aparelho físico; visual iPhone. |
| Veredito e Detalhes técnicos | Hierarquia de ações, resultado inconclusivo e percentis de fase corrigidos. | Resultado real completo e comparação visual iPhone. |
| Histórico e detalhe | Destino separado e métricas opcionais retrocompatíveis, provados com fixture no emulador. | Registro gerado por medição física real. |
| Ajustes | Região manual conectada à próxima pré-leitura; licença da fonte é legível no app. Termos e avaliar aparecem no iOS atual, mas seus botões só exibem aviso; o Android não ganhou ações vazias. Endereços externos atuais das plataformas diferem e exigem validação de destino antes de trocar. | Escolha manual em aparelho físico; decisão sobre links de suporte e privacidade. |
| Dados da Rede | Captura, refresh, casos de uso com motivo e exportação PDF funcional no emulador. | Leitura de gateway/NAT e PDF em aparelho físico. |
| Tipografia display | Nunito arredondada aplicada aos estilos equivalentes do iOS. | Inspeção lado a lado na mesma viewport com iPhone. |
