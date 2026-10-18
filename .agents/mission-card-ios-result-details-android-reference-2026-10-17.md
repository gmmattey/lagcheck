# Cartão de Missão — Resultado e Detalhes iOS pela referência Android

## Enquadramento

- **Problema da pessoa:** a tela principal de resultado no iPhone começou a alcançar a clareza do Android, mas `Ver detalhes` ainda leva a uma superfície com outra maturidade e outra leitura. A pessoa sai do veredito e perde continuidade.
- **Resultado esperado observável:** a jornada ativa `Resultado → Ver detalhes` no iOS reproduz 1:1 a experiência definida pelas três capturas Android fornecidas pelo Luiz: mesma ordem de informação, densidade, peso visual, estados e leitura rápida. O iOS mantém navegação, Safe Area, folha, foco e controles Apple. Android é referência de experiência e composição, nunca fonte de métricas para o iPhone.
- **Decisão do Luiz:** Resultado e Detalhes iOS devem alcançar 1:1 a experiência Android, respeitando os controles Apple e a integridade diagnóstica.
- **Escopo:** jornada ativa de `CheckCompletoResultView` e `TechnicalDetailsView`; passagem do mesmo `GameReadinessEvaluation` da tela de resultado para os detalhes; `FinalDeepCheckTrace` transitório e elegível para o gráfico real; referências visuais versionadas das três capturas Android; strings, componentes de apresentação e testes iOS necessários. Cobre `ready`, `caution`, `notReady` e `inconclusive`.
- **Fora de escopo:** reativar ou alterar `ResultFeatureView`; score, thresholds, veredito, UDP, Worker, SwiftData, catálogo, privacidade, custo, novos endpoints, SDKs, mudança no Android, vídeo, formato social extra ou publicação. Fatos Android de rádio, gateway, NAT, status de plataforma e recomendações não são copiados para o iOS sem uma observação iOS autorizada.
- **Lane:** Full flow sistêmica — ampliação aprovada no gate de Camillo, §11.
- **Por que esta lane:** a experiência continua em módulos iOS existentes, mas o gráfico final exige um dado transitório do coordenador de sessão até Detalhes. O gate delimitou esse traço fora de persistência, analytics, exportação, widget e compartilhamento; não altera domínio, regra, endpoint ou motor UDP.
- **Decisão/fonte de verdade:** decisão do Luiz nesta missão; Decisões 50, 51, 64, 66, 72, 73, 94 e 95; três capturas Android fornecidas pelo Luiz; handoff visual de Renan; `docs/01-funcional.md`; `docs/04-design-system.md`; `docs/07-voz-do-produto.md`; `Sources/NolaggyApp/Features/Details/TechnicalDetailsView.swift`; `android/app/src/main/kotlin/com/lagcheck/android/ui/verdict/VerdictScreen.kt`; `android/app/src/main/kotlin/com/lagcheck/android/ui/details/TechnicalDetailsScreen.kt`.

## Handoff de experiência

- **Decisão da pessoa:** confirmar o que o resultado significa, abrir detalhes para entender os números que sustentam o veredito e voltar sem perder contexto.
- **Resultado:** mantém a hierarquia já definida na missão anterior: contexto, kicker, indicador, manchete, subtítulo, telemetria, um único achado, retestar, detalhes e utilitários permitidos.
- **Detalhes:** começa com cabeçalho nativo `Detalhes técnicos` e fechar/voltar. O primeiro bloco repete o mesmo `VerdictIndicatorBadge`, headline e contexto do resultado, sem classificação paralela. Depois mostra somente fatos medidos, agrupados e na mesma ordem da referência Android: métricas observadas, comportamento sob carga quando houve carga, traçado de latência quando há amostras suficientes, origem da evidência, achados e versão/confiança da regra. Campo ausente mostra `—` ou não aparece quando isso for mais claro; nunca recebe preenchimento.
- **Estados:**
  - `ready`, `caution` e `notReady`: resultados e detalhes mostram o mesmo veredito, cor, texto e valores provenientes da mesma avaliação;
  - `inconclusive`: sem score, causa, gráfico interpretativo, card, PDF ou compartilhamento; mostra somente a limitação e `Testar novamente`;
  - traço final elegível: mostra as séries UDP originais de repouso e carga, com divisor explícito e lacunas preservadas;
  - sem traço final elegível: explica a ausência do traçado sem inventar curva;
  - cancelamento e troca de rede: descartam o parcial antes do resultado; detalhes não abre com dados parciais;
  - falha de compartilhamento: não bloqueia resultado, detalhes ou novo Check.
- **Integridade diagnóstica:** referência Android não autoriza mostrar no iOS banda Wi-Fi, RSSI, PHY, gateway, NAT, status externo ou recomendação que dependa desses fatos. Nenhuma frase culpa Wi-Fi, roteador, operadora ou servidor sem a prova exigida pela Decisão 50.
- **Acessibilidade e localização:** PT-BR e inglês; alvos de 44 pt; VoiceOver anuncia título, veredito, grupos e valores em ordem; Dynamic Type AX1–AX5 quebra grupos em linhas sem truncar; contraste e forma não dependem apenas de cor; Reduzir Movimento mantém toda leitura.

## Donos e fronteiras

- **Responsável pela entrega:** Rian — iOS.
- **Responsável pelo aceite operacional:** Giam.
- **Estratégia, prioridade e integração:** Marco.
- **Revisores obrigatórios:** Renan (referência 1:1, visual e acessibilidade), Breno (QA independente e runtime) e Iury (aderência da apresentação a `GameReadinessEvaluation` e integridade diagnóstica).
- **Camillo:** aprovou o §11 para o contrato transitório do traço; reentra se houver nova alteração de contrato, persistência, módulo, Worker, segurança ou motor de medição.

## Aceite e evidência

| Critério observável | Dono da prova | Evidência exigida | Estado |
| --- | --- | --- | --- |
| Resultado e Detalhes iOS seguem as três capturas Android na hierarquia, composição e densidade, com diferenças nativas documentadas | Renan / Breno | referência versionada, comparação renderizada iOS/Android e revisão visual | parcial — handoff e código aprovados em revisão estática com ressalvas; comparação renderizada pendente |
| Ao tocar `Ver detalhes`, o iOS entrega a mesma `GameReadinessEvaluation`; headline, indicador, cor e score permitido continuam coerentes | Rian / Iury / Breno | teste de integração, inspeção do dado passado e casos ready/caution/notReady/inconclusive | parcial — passagem do snapshot e consumo da avaliação inspecionados; integração em runtime pendente |
| Detalhes só apresenta fatos medidos e não copia fatos exclusivos do Android nem acusa uma causa sem evidência | Iury / Breno | revisão de dados/copy e testes de estado | parcial — Decisão 95 e implementação estática respeitam a separação; revisão de estados em runtime pendente |
| Inconclusivo não exibe score, causa, gráfico interpretativo, PDF ou compartilhamento; cancelamento e troca de rede não abrem detalhes parciais | Breno | testes de UI/estado, simulador e iPhone | parcial — guardas inspecionados; teste de UI pendente |
| Gráfico usa a série UDP final original de repouso e carga somente quando `FinalDeepCheckTrace` é elegível; ausência é honesta e legível | Camillo / Iury / Renan / Breno | testes do coordenador, revisão de contrato, captura e inspeção de acessibilidade | parcial — gate Camillo §11 e Iury aprovaram o contrato; implementação e testes foram inspecionados, mas não executados |
| Voltar/fechar devolve o foco ao resultado; share sheet, reteste e detalhes não quebram o contexto | Breno | simulador e iPhone físico | não validado — sem runtime iOS |
| PT-BR/inglês, AX1–AX5, VoiceOver, contraste e toque passam em telas pequena e grande | Renan / Breno | simulador e iPhone físico com leitor de tela | não validado — copy inspecionada; layout e leitor de tela exigem runtime |
| Build, testes iOS e regressão do Check, histórico e detalhes passam | Breno | logs de build/teste e aparelho físico | não validado — testes foram escritos, mas não executados; sem Xcode, simulador ou iPhone neste host |

## Evidência da entrega local

- **Decisão e design:** a Decisão 95 torna as três capturas Android a referência de experiência para `Resultado → Ver detalhes`; Renan entregou o handoff de hierarquia, densidade, estados e limites de acessibilidade.
- **Implementação inspecionada:** Rian passa o snapshot de `GameReadinessEvaluation` do resultado para `TechnicalDetailsView`. Detalhes consome essa avaliação para veredito, score permitido, achados e confiança, sem nova classificação paralela.
- **Traço final e gate:** Camillo aprovou o §11 do Architecture Plan. `FinalDeepCheckTrace` conserva apenas as séries originais, por `sessionID`, quando repouso e carga completaram com pelo menos 10 respostas UDP válidas em cada fase. Não persiste, não entra em analytics, exportação, widget ou card; cancelamento, troca de rede, background e nova sessão o descartam. Sem traço elegível, Detalhes mostra a indisponibilidade do gráfico.
- **Integridade e copy:** Iury revisou o contrato do traço e a separação de evidências. A superfície não replica rádio, gateway, NAT ou causalidade Android. A perda usa o locale de `AppLocalization`; recursos PT-BR, inglês e espanhol receberam as chaves necessárias.
- **QA independente:** Breno emitiu `APROVADO COM RESSALVAS` para a revisão estática. Os testes do coordenador para retenção, elegibilidade, lacunas e descarte do traço foram escritos, mas não executados. Não há execução de Xcode, simulador, iPhone, VoiceOver, share sheet, foco, benchmark ou comparação renderizada.

## Revisão final de Giam

1. **Necessidade:** atendida no código inspecionado; a transição para detalhes deixa de quebrar a leitura do resultado.
2. **Valor:** atendido por inspeção; o jogador encontra os fatos que sustentam o veredito na mesma ordem da referência Android.
3. **Coerência:** atendida por inspeção; a implementação usa a mesma avaliação, preserva os limites da Decisão 95 e segue o gate de Camillo para o traço final.
4. **Experiência:** parcial; handoff e composição estática foram revisados, mas ainda não foram vistos no iPhone.
5. **Funcionamento E2E:** não validado; abertura, retorno, foco, estados e ações dependem de runtime.
6. **Qualidade e prova:** não validada; testes foram escritos, mas não há execução, build, simulador ou aparelho físico.
7. **Simplicidade:** atendida por inspeção; a mudança ficou na jornada ativa e não reativou o legado nem alterou o domínio.

**Parecer Giam: NÃO VALIDADO.** A revisão estática aprovada com ressalvas não substitui a prova de runtime iOS.

## Handoff e encerramento

- **Módulos esperados:** `CheckCompletoResultView`, `TechnicalDetailsView`, composição em `DeepCheckFeatureView`, `DeepCheckSessionCoordinator`, traço transitório em `NolaggyApplication`, componentes de apresentação, localizações, referências visuais e testes iOS. Domínio, persistência, analytics, exportação, widget, card, infraestrutura, catálogo, Worker, Android e `ResultFeatureView` ficam fora.
- **Risco principal:** confundir paridade de experiência com cópia de telemetria Android, reavaliar o resultado ao abrir detalhes ou desenhar uma curva que não veio das amostras finais. A implementação precisa transportar a avaliação já decidida, usar somente o traço elegível e ocultar fatos indisponíveis no iPhone.
- **Próximo passo:** em Mac com Xcode e iPhone, Breno e Renan executam os testes do coordenador e de UI, build, comparação lado a lado com as três capturas, estados com e sem traço elegível, retorno de foco, VoiceOver, Dynamic Type e contraste. Giam revisa novamente com essa prova.
