# Cartão de Missão — Resultado iOS pela referência Android

## Enquadramento

- **Problema da pessoa:** depois de um Check no iPhone, a tela de resultado e o card de compartilhamento ainda têm menos clareza e acabamento que o Android. A decisão principal e o que fazer em seguida perdem força.
- **Resultado esperado observável:** na jornada ativa de resultado iOS, o jogador vê a mesma hierarquia madura do Android: contexto discreto, kicker, indicador visual separado, manchete limpa, explicação curta, telemetria monoespaçada, causa principal e ações sem disputa. O card 1200×630 preparado no aparelho alcança a mesma qualidade visual e mostra somente o snapshot daquele Check válido. Android é a referência de composição e acabamento; iOS preserva controles, navegação e compartilhamento nativos.
- **Decisão do Luiz:** Android vira a referência da tela de resultado iOS. O card iOS também deve alcançar a qualidade visual do card Android.
- **Escopo:** `CheckCompletoResultView`, que compõe a jornada ativa de resultado, incluindo estados pronto, cautela, evitar e inconclusivo; a prévia e o renderizador local do card de compartilhamento iOS; recursos localizados e testes de UI/renderização necessários. A jornada ativa usa `GameReadinessEvaluation` e os tokens/componentes existentes.
- **Fora de escopo:** `ResultFeatureView`, tela legada compilada e renderizável por `presentation.result`, sem callsite no fluxo normal `startCheckDirectly → openDeepCheck`; ela exige missão própria de manutenção. Também ficam fora score, veredito, thresholds, regras de rede, UDP, Worker, SwiftData, catálogo, telemetria de rádio, novos endpoints, SDKs, formatos Stories/vídeo, mudança no Android, nova marca ou publicação. Fatos exclusivos do Android não entram no iOS. Nenhum campo sem leitura recebe valor de preenchimento.
- **Lane:** Full flow comum.
- **Por que esta lane:** reforma duas superfícies iOS e o card local dentro dos módulos existentes. Não altera contrato, persistência, motor de medição ou serviço externo. Se a unificação exigir mudança em qualquer uma dessas fronteiras, a implementação para e segue para o gate de Camillo.
- **Decisão/fonte de verdade:** decisão do Luiz nesta missão; Decisões 50, 51, 64, 66, 72, 73, 74, 81 e 85; `docs/01-funcional.md`; `docs/04-design-system.md`; `docs/07-voz-do-produto.md`; `docs/08-arquitetura-android.md`; implementação atual `android/app/src/main/kotlin/com/lagcheck/android/ui/verdict/VerdictScreen.kt`.

## Handoff de experiência

- **Decisão da pessoa:** depois de uma medição válida, entender a condição para jogar, consultar detalhes, repetir o Check ou compartilhar o resultado. No inconclusivo, entender que não há resultado confiável e repetir o Check.
- **Hierarquia comum:** contexto discreto; `RESULTADO DO CHECK`; `VerdictIndicatorBadge`; manchete de veredito sem glifo no texto; subtítulo curto; telemetria compacta; `O QUE MAIS PESOU`; CTA primário `Testar novamente`; `Ver detalhes` como ação secundária; compartilhamento e PDF como utilitários. Só há um CTA primário por viewport.
- **Card/prévia:** para `ready`, `caution` e `notReady`, preparar localmente um único JPEG 1200×630 fora do caminho crítico do resultado. A prévia aparece abaixo do veredito, antes da telemetria, mantém a proporção 1200:630 e abre o compartilhamento nativo com o mesmo arquivo. O card usa wordmark oficial, rótulo `CHECK`, jogo com arte editorial autorizada ou identidade neutra, referência regional realmente respondida, veredito por forma e texto, e métricas observadas. Não contém capa, logo ou personagem de terceiro, ping não medido, atribuição de culpa, nota em inconclusivo ou dado inventado.
- **Interações iOS:** manter retorno, Safe Area, foco e share sheet nativos. Cancelar o share volta ao controle que o abriu. O resultado não espera o card para aparecer. Durante o preparo, a área reserva espaço sem spinner, shimmer ou animação chamativa; em falha, o resultado continua íntegro e há uma recuperação clara. Inconclusivo, cancelamento e troca de rede não geram arquivo.
- **Acessibilidade e localização:** PT-BR e inglês; VoiceOver anuncia primeiro o veredito e depois controles/estado do card; alvos de pelo menos 44 pt; contraste, texto+forma e Dynamic Type AX1–AX5 sem corte. A tela rola quando necessário.

## Donos e fronteiras

- **Responsável pela entrega:** Rian — iOS.
- **Responsável pelo aceite operacional:** Giam.
- **Estratégia, prioridade e integração:** Marco.
- **Revisores obrigatórios:** Renan (especificação, visual e acessibilidade) e Breno (QA independente, regressão e aparelho).
- **Iury:** revisa somente se a apresentação deixar de refletir fielmente `GameReadinessEvaluation` ou alterar qualquer alegação diagnóstica.
- **Camillo:** entra somente se a implementação tocar contrato, persistência, módulo, serviço externo ou motor de medição.

## Aceite e evidência

| Critério observável | Dono da prova | Evidência exigida | Estado |
| --- | --- | --- | --- |
| A jornada ativa iOS usa a hierarquia aprovada, sem pílula de score ou grade legada disputando a decisão | Renan / Breno | diff, revisão visual e captura lado a lado com a referência Android | parcial — Renan e Breno aprovaram a inspeção estática com ressalvas; captura iOS pendente |
| Na jornada ativa, ready, caution, not ready e inconclusivo preservam o significado de `GameReadinessEvaluation`; inconclusivo não mostra score nem ação de compartilhar | Rian / Breno | testes de UI/estado, inspeção e captura iOS | parcial — fluxos e guardas inspecionados; teste e captura pendentes |
| Ações funcionam no iOS: retestar, detalhes, PDF e compartilhamento; cancelar a folha nativa devolve o foco ao originador | Breno | teste de integração, simulador e iPhone físico | não validado — sem runtime iOS |
| O card 1200×630 tem o acabamento da referência Android e só contém dados, arte e texto permitidos pelo snapshot válido | Renan / Iury / Breno | inspeção do JPEG, teste de renderização e comparação visual | parcial — implementação e fontes inspecionadas; JPEG renderizado e comparação iOS pendentes |
| Preparar o card não atrasa o primeiro frame do resultado; erro permite tentar de novo sem perder o resultado | Breno | benchmark e interação em iPhone físico representativo | não validado — sem benchmark nem aparelho |
| Cancelamento, troca de rede e inconclusivo não preparam nem oferecem arquivo | Rian / Breno | testes de estado e regressão | parcial — guardas estáticos inspecionados; regressão em runtime pendente |
| PT-BR/inglês, AX1–AX5, contraste, alvo de toque e ordem do VoiceOver funcionam sem truncar manchete ou ação | Renan / Breno | simulador e iPhone físico com VoiceOver | não validado — localidade de perda foi corrigida por inspeção; layout e VoiceOver exigem runtime |
| Build e suítes iOS aplicáveis passam sem regressão no Check, histórico e detalhes | Breno | logs de build e testes executados | não validado — Xcode e iPhone indisponíveis neste host Windows |

## Evidência da entrega local

- **Implementação inspecionada:** `CheckCompletoResultView` recebeu a hierarquia de referência: indicador separado da manchete, telemetria compacta, ação primária antes da secundária e ações utilitárias reduzidas. A prévia continua fora do primeiro frame e o card usa o snapshot preparado.
- **Card e localização inspecionados:** `LagCheckDiscordCardExporter` passou a receber o identificador do jogo para resolver arte editorial autorizada e usa o locale de `AppLocalization` no separador decimal de perda; a tela segue o mesmo locale. Zero continua `0`.
- **Revisão independente:** Renan e Breno emitiram `APROVADO COM RESSALVAS` para a revisão estática. Não há captura renderizada, teste automatizado executado, build, simulador, share sheet, VoiceOver, benchmark ou iPhone físico nesta entrega.
- **Limite do ambiente:** o host Windows não dispõe de Xcode nem de iPhone para fechar os itens de runtime.

## Revisão final de Giam

1. **Necessidade:** atendida no código inspecionado; a tela ativa aproxima sua hierarquia da referência Android.
2. **Valor:** atendido por inspeção; veredito e próxima ação ficam mais fáceis de localizar.
3. **Coerência:** atendida por inspeção; mantém Dark Competitive UI, snapshot local e limites diagnósticos.
4. **Experiência:** parcial; a composição estática foi aprovada com ressalvas, mas ainda falta vê-la no iPhone.
5. **Funcionamento E2E:** não validado; ações, retorno de foco, share sheet, erro e estados dependem de runtime.
6. **Qualidade e prova:** não validada; não há build, testes executados, simulador ou aparelho físico.
7. **Simplicidade:** atendida por inspeção; o recorte ficou em `CheckCompletoResultView` e no card, sem mexer em domínio ou Android.

**Parecer Giam: NÃO VALIDADO.** A implementação local e as revisões estáticas são promissoras, mas a falta de prova de runtime iOS impede aceite de produto.

## Handoff e encerramento

- **Módulos esperados:** `Sources/NolaggyApp/Features/Result/CheckCompletoResultView.swift`, componentes de apresentação e compartilhamento iOS usados pela jornada ativa, localizações e testes iOS. Domínio, infraestrutura, catálogo, Worker, Android e `ResultFeatureView` ficam fora.
- **Risco principal:** reaproveitar dados ou estética Android sem respeitar limites de plataforma e proveniência de cada métrica. O resultado iOS só mostra aquilo que seu próprio snapshot mediu.
- **Próximo passo:** em Mac com Xcode e iPhone, Breno e Renan executam build, testes, comparação renderizada, share sheet/cancelamento, estados, VoiceOver, Dynamic Type e benchmark. Giam revisa novamente com essa prova.
