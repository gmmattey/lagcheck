# Cartão de Missão — anúncios nativos iOS

## Enquadramento

- **Problema da pessoa:** a publicidade precisa se integrar ao app iOS com o mesmo cuidado visual decidido para Android, sem atrapalhar o veredito.
- **Resultado observável:** o app iOS completo usa Native Advanced em Home, Histórico, Jogos e Resultado, com unidades próprias do app iOS em Release e IDs de teste em Debug.
- **Fora de escopo:** Widget, App Clip, Check, Detalhes, anúncios em Configurações, mudanças de score, Worker, telemetria, publicação e campanhas.
- **Lane:** full flow sistêmica pela entrada de SDK e consentimento em uma nova plataforma.
- **Decisão/fonte de verdade:** Decisão 97; docs/01–04, docs/06, guia oficial iOS do Google e plano de Camillo.

## Donos e fronteiras

- **Decisão de negócio:** Luiz; **aceite de produto:** Giam; **coordenação:** Marco; **plano:** Camillo; **UI:** Renan; **iOS:** Rian; **QA:** Breno.
- **Limite:** anúncio não é recomendação técnica. Resultado e ações precedem publicidade. Check não pede anúncio.
- **IDs:** app e quatro unidades iOS confirmados por leitura da conta AdMob em 17/10/2026; status de verificação do app não confirmado e aprovação requer revisão.

## Aceite e evidência

| Critério | Evidência necessária | Estado |
| --- | --- | --- |
| Debug usa só IDs de teste; Release configura App ID e quatro unidades iOS reais | inspeção do projeto e build no Mac | configuração inspecionada; build pendente |
| UMP por abertura e gate `canRequestAds`; opções de privacidade quando exigidas | testes e iPhone físico por região | fluxo inspecionado; execução pendente |
| Sem anúncio em Check/Widget/Clip/Detalhes/Configurações | inspeção e execução | posições inspecionadas; execução pendente |
| Resultado, ações, navegação e retorno do background permanecem livres | iPhone físico | posições inspecionadas; execução pendente |
| Rótulo, AdChoices, CTA, VoiceOver, Dynamic Type e idiomas funcionam | revisão visual e iPhone físico | código inspecionado; validação visual e física pendente |
| Política, App Privacy e mensagens públicas refletem publicidade antes da distribuição | revisão de release | fonte web local ajustada; App Privacy e publicação pendentes |

QA estática de Breno e gate de produto de Giam: a implementação local segue o recorte por inspeção, mas o aceite funcional e a distribuição permanecem **NÃO VALIDADOS**. Este Windows não dispõe de Xcode/Swift/XcodeGen; build, resolução SPM, simulador e iPhone físico ainda faltam. A configuração das unidades no AdMob não comprova veiculação, e o painel indicou verificação do app não confirmada.
