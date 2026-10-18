# Cartão de Missão — Home imersiva por jogo

## Enquadramento

- **Problema da pessoa:** na Home, a pessoa vê chrome do app antes de ver o jogo para o qual quer decidir se joga. Wordmark, menu e atalho de Histórico ocupam espaço que a barra inferior já resolve.
- **Resultado esperado observável:** a arte editorial autorizada começa no topo visual nos dois clientes; o nome, contexto e `Trocar jogo` fecham o hero com leitura segura; `Checar agora` segue imediatamente abaixo. Selecionar ou trocar um jogo inicia a medição de uma vez — sem seleção de console e sem retorno à Home. A barra inferior mantém Histórico e Ajustes como destinos claros.
- **Fora de escopo:** medição, score, veredito, rádio, catálogo, Worker, persistência, anúncios, arte de terceiros, novo destino ou nova fonte tipográfica.
- **Lane:** Fast lane.
- **Por que esta lane:** ajuste visual e de composição em duas superfícies Home já existentes, sem contrato ou estado novo.
- **Decisão/fonte de verdade:** Decisão 96; `docs/04-design-system.md`; arte do catálogo e tokens Dark Competitive existentes.

## Donos e fronteiras

- **Responsável pela entrega:** Rian — Home SwiftUI e Compose.
- **Responsável pelo aceite operacional:** Giam.
- **Revisores:** Renan (fidelidade visual e acessibilidade) e Breno (regressão e builds).
- **Gate arquitetural:** não aplicável; não há API, persistência, Worker, segurança ou motor de medição no recorte.

## Contrato compartilhado e diferenças nativas

| Contrato | iOS | Android |
| --- | --- | --- |
| Hero | Arte autorizada até o topo lógico, respeitando Safe Area e gradiente de leitura | Arte autorizada atrás do inset de status, com `statusBarsPadding` para os controles |
| Navegação | Sem wordmark/menu/Histórico na Home; tab bar nativa continua | Sem `HomeTopBar`/Histórico na Home; NavigationBar existente continua |
| Rede | Pílula permanece informativa, sem diagnóstico novo | Pílula informativa continua abrindo o Cockpit de Rede |
| Trocar jogo | Controle SwiftUI de 44 pt abre Jogos | Controle Compose de 48 dp abre Jogos |

## Aceite e evidência

| Critério observável | Evidência exigida | Estado |
| --- | --- | --- |
| Arte inicia no topo e o gradiente mantém status, nome e contexto legíveis | inspeção estática e captura em simulador/emulador | parcial — iOS em simulador; Android sem emulador/aparelho disponível |
| Wordmark, menu e atalho duplicado de Histórico não aparecem na Home | teste/UI e inspeção | parcial — UI iOS; inspeção Compose |
| Pílula de rede, Trocar jogo e CTA preservam comportamento e alvo mínimo | teste/UI e revisão de acessibilidade | parcial — fluxo direto iOS validado; Android compilado e coberto por teste unitário, runtime pendente |
| Título localizado/Dynamic Type/font scale não encobre ação ou contexto | revisão em simulador/emulador e aparelho | pendente |
| Build e testes dos clientes não introduzem regressão | Xcode/Gradle e testes focados | validado localmente — build iOS, 3 UI tests iOS, compile e testes unitários Android |

Validação em simulador/emulador não substitui iPhone ou Android físicos. Nenhuma evidência desta missão afirma comportamento de rede real.
