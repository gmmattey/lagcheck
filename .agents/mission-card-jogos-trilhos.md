# Cartão de Missão — Jogos: escolha direta em trilhos

## Enquadramento

- **Problema da pessoa:** no lobby, escolher um jogo não pode virar uma lista infinita, uma falsa lista de favoritos ou uma decisão técnica sobre plataforma.
- **Resultado observável:** fora da busca, Jogos mostra trilhos horizontais de Recentes reais, Favoritos reais e Todos os jogos em A–Z. Um toque no jogo inicia a jornada de Check no contexto do iPhone, sem seletor de plataforma ou vínculo externo. A busca substitui os trilhos por resultados A–Z; sem resultado, oferece Check Geral. O anúncio, se consentido e carregado, vem apenas após esse conteúdo essencial.
- **Fora de escopo:** catálogo, arte, algoritmo/regra de veredito, rota/Worker, schema, persistência, histórico existente, widget, deep link, anúncios fora de Jogos e publicação.
- **Lane:** Full flow comum.
- **Por que esta lane:** é uma mudança de jornada e composição nos clientes. Camillo confirmou que permanece nessa pista somente se o contexto atual for fixado/revalidado como iPhone e nenhum contrato, schema, persistência ou resolvedor for alterado.
- **Decisão/fonte de verdade:** Decisão 102; Decisões 18, 41, 50, 51, 64, 80, 96, 97 e 99; `docs/01-funcional.md`, `docs/04-design-system.md` e `docs/07-voz-do-produto.md`.

## Donos e fronteiras

- **Responsável pela entrega:** Rian — iOS e Android, em arquivos separados por plataforma.
- **Responsável pelo aceite operacional:** Giam.
- **Estratégia e orquestração:** Marco.
- **Revisores:** Renan (experiência/paridade) e Breno (QA independente).
- **Gate de Camillo:** concluído para este recorte; reabrir como full flow sistêmica se surgir mudança em schema, resolvedor, catálogo, histórico, widget, deep link, regra ou persistência.

## Handoff de UI

- **Hierarquia:** `Recentes → Favoritos → Todos os jogos (A–Z) → anúncio`. Trilhos sem dados não existem. Cada card contém apenas arte editorial autorizada e nome; é um alvo inteiro de 44 pt/dp ou maior.
- **Busca:** lupa abre busca nativa e recebe foco. Enquanto há texto, trilhos, anúncio e fallback editorial somem; resultados ficam A–Z. Sem resultado: mensagem curta e Check Geral.
- **Acessibilidade/localização:** nome e ação do jogo são anunciados; favorito comunica estado e ação; arte é decorativa quando o nome já está no controle. Busca/limpar e publicidade são localizados; Dynamic Type/font scale rolam sem truncar o nome.
- **Diferença nativa autorizada:** SwiftUI e Compose podem usar componentes/gestos próprios, mas preservam a mesma ordem, estados e promessa.

## Aceite e evidência

| Critério observável | Dono da prova | Evidência exigida | Estado |
| --- | --- | --- | --- |
| Não há plataforma/vínculo externo na escolha; toque usa somente contexto iPhone válido | Rian / Breno | testes de integração e inspeção dos dois clientes | pendente |
| Recentes e Favoritos nunca são inventados; Todos fica A–Z localizado | Rian / Breno | testes de estado iOS/Android | pendente |
| Busca, vazio e Check Geral preservam a ação honesta | Renan / Breno | teste de UI/inspeção e captura | pendente |
| Anúncio não aparece em busca/vazio nem antes da escolha essencial | Breno | teste de estado e inspeção | pendente |
| PT-BR/inglês, alvos, VoiceOver/TalkBack e escala de texto | Renan / Breno | simulador/emulador e aparelho | pendente |
| Paridade de promessa e diferenças nativas documentadas | Renan / Giam | revisão cruzada iOS/Android | pendente |

## Handoff e estado atual

- **Implementado localmente:** iOS e Android exibem Recentes reais, Favoritos reais e Todos os jogos A–Z em trilhos laterais; busca substitui a vitrine; vazio oferece Check Geral; anúncio fica fora de busca/vazio e depois do conteúdo essencial. A escolha pela vitrine usa somente contexto iPhone/Mobile válido, sem alterar os caminhos legados de widget, deep link ou histórico.
- **Evidência executada:** `git diff --check`; iOS `xcodebuild build-for-testing -project Nolaggy.xcodeproj -scheme NolaggyCoreTests -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO`; Android `./gradlew :app:compileDebugKotlin :core:domain:test`.
- **Não validado:** interação/renderização no simulador iOS (a instalação falhou por placeholder preexistente do widget), emulador Android, VoiceOver/TalkBack, escala de texto, consentimento/UMP e aparelhos físicos. Não é beta nem publicação.
