# Cartão de Missão — Issue #49: Widget de prontidão por jogo

## Enquadramento

- **Problema da pessoa:** no lobby, ela lembra do resultado anterior, mas o atalho atual é genérico, não mostra o jogo que acabou de medir e não existe no Android.
- **Resultado esperado observável:** em iOS 17+ e Android API 26+, o widget mostra a arte editorial autorizada do último Check válido daquela instalação, mais jogo, região, P50 e veredito. Tocar abre o app e inicia um novo Check para o mesmo jogo, plataforma e vínculo externo, depois de o catálogo local atual revalidar o contexto.
- **Fora de escopo:** Live Activity/Dynamic Island, StandBy, widget social/leaderboard, fetch ou medição em background, Worker/endpoint novo, telemetria, alteração de score/veredito, arte oficial de terceiros, conta/sincronização e uso de imagem de uma plataforma na outra.
- **Lane:** Full flow sistêmica.
- **Por que esta lane:** acrescenta uma superfície Android, snapshots locais derivados e uma ação que dispara medição; atravessa persistência/armazenamento, catálogo, ciclo de vida e deep links sem alterar a matemática da medição.
- **Decisão/fonte de verdade:** Decisões 18, 44, 64, 71, 75, 85 e 88; `docs/01-funcional.md` §7.9; `docs/02-arquitetura.md` §3.6; `docs/03-especificacao-tecnica.md` §8.1; `docs/04-design-system.md`; `docs/08-arquitetura-android.md`.

## Donos e fronteiras

- **Responsável pela entrega:** Rian (iOS e Android).
- **Responsável pelo aceite operacional de produto:** Giam.
- **Estratégia/prioridade:** Marco; Luiz autorizou o escopo pela Decisão 88.
- **Revisores obrigatórios:** Camillo (Architecture Plan), Renan (experiência e acessibilidade), Iury (integridade/retomada), Breno (QA).
- **Mudança sistêmica / Architecture Plan:** sim; gate em `.agents/architecture-plan.md` §10.

## Handoff de experiência

- **Hierarquia:** Home Screen usa arte editorial da plataforma como fundo com gradiente `background.deep`; jogo e região ficam no topo, P50 monoespaçada no centro e veredito textual+forma no rodapé. Lock Screen retangular usa miniatura; circular/inline preservam apenas telemetria legível.
- **Estados:** válido e fresco (<4 h); vencido, sem métrica/veredito antigo e CTA para medir; arte indisponível com identidade neutra; catálogo/jogo/contexto inválido com recuperação no app; sessão ativa sem criar segunda medição.
- **Ação:** `lagcheck://check?game={id}` no iOS e Intent/deep link equivalente no Android. A chegada revalida catálogo e só então inicia Check; o toque não autoriza fetch/medição em background nem ignora uma sessão ativa.
- **Fonte de imagem:** somente arte editorial aprovada do catálogo/cache/resource da build em execução. A imagem é miniatura local derivada; não é URL renderizada pelo widget, upload nem arquivo transferido entre plataformas.

## Aceite e evidência

| Critério observável | Evidência exigida | Estado |
| --- | --- | --- |
| iOS e Android exibem o último contexto válido com arte oficial da própria build | testes de contrato, inspeção de cache e captura separada nas duas plataformas | pendente |
| Toque em app frio e em segundo plano inicia o Check do jogo/plataforma/vínculo corretos | teste de deep link/Intent e aparelho físico iOS/Android | pendente |
| Vencido, inconclusivo, catálogo/arte inválidos não mostram diagnóstico antigo e têm fallback neutro | testes de estado e render | pendente |
| Não há fetch, medição extra, Worker novo, PII ou telemetria pelo widget | inspeção, teste de contrato e revisão de Iury | pendente |
| Home/Lock Screen suportadas preservam tokens, contraste, Dynamic Type/VoiceOver e font scale/TalkBack | simulador/emulador e aparelhos físicos | pendente |
| Não há regressão em cancelamento, mudança de rede ou sessão única | testes de integração e aparelho físico | pendente |

## Estado inicial

**Implementado localmente; aceite pendente.** O iOS agora materializa miniatura editorial no App Group e abre o Check com jogo/plataforma/vínculo; Android possui `AppWidgetProvider` com snapshot privado e `Intent` equivalente. Compilação iOS de simulador e Kotlin Android concluídas; ainda faltam render/interação em simulador/emulador e evidência em aparelhos físicos.
