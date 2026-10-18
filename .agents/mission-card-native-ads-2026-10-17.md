# Cartão de Missão — anúncios nativos Android

## Enquadramento

- **Problema da pessoa:** os banners atuais destoam da interface e atrapalham a experiência.
- **Resultado observável:** o Android exibe anúncios Native Advanced próprios de Home, Histórico, Jogos e Resultado, claramente identificados, sem reduzir a leitura do app ou atrapalhar o Check.
- **Fora de escopo:** iOS, anúncios durante Check, em Detalhes ou Configurações, novo SDK, mediação, score/veredito, campanhas ou publicação.
- **Lane:** full flow comum; não muda API, persistência, Worker ou motor de medição.
- **Decisão:** 94, aprovada pelo Luiz em 17/10/2026 após confirmação expressa das quatro telas.
- **IDs nesta etapa:** Luiz escolheu manter IDs de teste; os IDs reais da captura ficam para configuração e validação posteriores.

## Donos e fronteiras

- **Aceite de produto:** Giam; **coordenação:** Marco; **UI:** Renan; **Android:** Rian; **validação independente:** Breno.
- **Limite:** publicidade não é conteúdo editorial nem recomendação de rede. O veredito e as ações do Resultado precedem o anúncio; nenhum anúncio aparece durante medição.

## Aceite e evidência

| Critério | Evidência necessária | Estado |
| --- | --- | --- |
| Unidade correta e módulo nativo em cada tela | inspeção de configuração e app em execução | configuração e código inspecionados com IDs de teste; execução pendente |
| Consentimento e chave desligada impedem requisição e espaço | testes de política e execução | AdPolicyTest 5/5 e inspeção passaram; execução pendente |
| Falha de carga não deixa módulo vazio; navegação não recarrega sem necessidade | app em execução | código inspecionado; execução pendente |
| Resultado, Check e ações essenciais nunca são bloqueados | teste funcional em emulador e aparelho | posição e política inspecionadas; execução pendente |
| Identificação `Anúncio`/`Ad`, TalkBack e foco/CTA acessíveis | revisão visual e aparelho Android | PT/EN e registro de assets inspecionados; acessibilidade em aparelho pendente |
| Score e veredito idênticos com anúncios ligados/desligados | testes de domínio e regressão | domínio sem alterações; regressão completa bloqueada por fixture preexistente |

Build Debug após a última alteração: `:app:assembleDebug` passou. A suíte `:core:session:test` teve 66/67: `ShelfAndPlannerTest` falha por divergência preexistente entre envelopes assinados do catálogo Android/iOS e Worker; esses arquivos são idênticos aos de `origin/main`. Não havia aparelho conectado, e o emulador deste host não iniciou sem driver de aceleração. Sem prova em aparelho, o aceite de distribuição permanece **NÃO VALIDADO**.
