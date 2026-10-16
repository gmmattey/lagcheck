# Cartão de Missão — Issue #51: Lembrete de Check Pré-Partida

## Enquadramento

- **Problema da pessoa:** no lobby, ela pode esquecer de checar a conexão e descobrir a instabilidade tarde demais, no meio da partida.
- **Resultado esperado observável:** quem optou pelo recurso recebe um lembrete local diário no horário escolhido; ao tocar, abre o LagCheck no jogo selecionado e decide iniciar o Check. O app não mede, não presume a qualidade da rede e não notifica sem consentimento.
- **Fora de escopo:** push ou endpoint novo; aprendizado automático de horário; leitura de uso de outros apps; mais de um lembrete diário; execução automática de Check; conta, sincronização, telemetria, mudança de score/veredito, widgets e gamificação.
- **Lane:** Full flow comum.
- **Por que esta lane:** é um fluxo novo de UI, permissões e agendamento local nos dois apps, mas não altera Worker, rede, motor de medição, contrato de catálogo ou persistência de sessões. Se a implementação exigir migração relevante de armazenamento ou novo contrato, ela para e sobe ao Camillo.
- **Decisão/fonte de verdade:** Decisões 33, 50, 64, 85 e 87; `docs/01-funcional.md` §13; `docs/07-voz-do-produto.md`; design system Dark Competitive UI.

## Handoff de experiência

- **Decisão da pessoa:** ativar ou não um lembrete diário, escolher seu horário e poder desativá-lo sem atrito.
- **Entrada:** Ajustes mostra uma única linha `Lembrete pré-partida` com switch inicialmente desligado; quando ligado, revela um seletor nativo de horário e um resumo curto do agendamento. Não criar card, explicação longa ou contagem regressiva na Home.
- **Pré-condição:** sem jogo selecionado, o switch fica indisponível e explica de modo curto que é preciso escolher um jogo; não pedir permissão nesse estado.
- **Permissão:** o toque para ativar pede a permissão do sistema. Concedida, agenda; negada, volta desligado, não agenda e oferece `Abrir Ajustes do aparelho` como ação secundária. O app não repete o prompt automaticamente.
- **Notificação e deep link:** copy factual, por exemplo `Vai jogar agora? Faça um Check antes.`; tocar seleciona o jogo associado, abre o fluxo de Check e preserva a ação explícita de iniciar a medição. Nenhuma notificação declara que a conexão está boa, ruim ou pronta.
- **Estados:** desligado; ligado e agendado; permissão negada; jogo removido/indisponível (desliga e remove o agendamento); idioma alterado (a próxima notificação usa o idioma atual). Alterar horário substitui, nunca duplica, o agendamento; desligar remove todos os pendentes.
- **Acessibilidade e localização:** PT-BR, inglês e espanhol; controle, horário e estado legíveis por VoiceOver/TalkBack, alvo mínimo de 44 pt/dp, Dynamic Type/font scale sem truncar controles. Usar tokens e componentes existentes.

## Donos e fronteiras

- **Responsável pela entrega:** Rian — iOS e Android.
- **Responsável pelo aceite operacional:** Giam.
- **Estratégia/prioridade:** Marco.
- **Revisores obrigatórios:** Renan (experiência, visual e acessibilidade) e Breno (permissões, agendamento, deep link e regressão).
- **Iury:** somente se a implementação introduzir qualquer atividade de rede ou tocar o Check; isso não está autorizado no recorte.
- **Camillo:** somente se houver migração relevante de persistência ou alteração de contrato entre módulos.

## Aceite e evidência

| Critério observável | Dono da prova | Evidência exigida | Estado |
| --- | --- | --- | --- |
| Recurso nasce desligado e só agenda após opt-in e permissão | Rian / Breno | testes e aparelho iOS/Android | pendente |
| Há no máximo uma notificação diária; alterar/desligar substitui/remove o agendamento | Rian / Breno | testes de unidade/integração e inspeção do SO | pendente |
| Toque abre o jogo correto sem iniciar rede ou medição sozinho | Rian / Breno | teste de deep link, aparelho frio e em segundo plano | pendente |
| Negar permissão não agenda nem reabre o prompt automaticamente | Breno | aparelho iOS/Android | pendente |
| Copy localizada, ordem de foco, tamanho de fonte, contraste e alvos são corretos | Renan / Breno | simulador/emulador e aparelho com leitor de tela | pendente |
| Regressão de Check, histórico e Ajustes não introduz alteração de diagnóstico | Breno | suítes aplicáveis e inspeção | pendente |

## Handoff e encerramento

- **Módulos esperados:** telas de Ajustes e roteamento do app; agendador/armazenamento local de preferências e adaptadores nativos de notificação em iOS e Android; recursos localizados e testes. Domínio de score, UDP, catálogo e Worker ficam fora.
- **Risco principal:** permission flow e deep link terem comportamento diferente em app frio, segundo plano e permissão previamente negada. A prova em aparelho é obrigatória antes do aceite.
- **Próximo passo:** Renan fecha o handoff visual sobre as telas atuais; Rian implementa o recorte; Breno valida independentemente; Giam emite o veredito com evidência real.
