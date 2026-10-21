# Cartão de Missão — Encerramento háptico no fim do Check iOS

## Enquadramento

- **Problema da pessoa:** depois de receber o resultado do Check no iPhone, a vibração periódica da trilha pode continuar. Isso comunica falsamente que a medição ainda está acontecendo.
- **Resultado esperado observável:** a vibração ocorre somente durante o estado `medindo` e cessa ao entrar em resultado válido, inconclusivo, cancelado ou ao sair da tela de medição.
- **Fora de escopo:** regras de medição, score, veredito, rede, Android, novas preferências, copy, endpoints e publicação.
- **Lane:** Fast lane.
- **Por que esta lane:** correção local e reversível no ciclo de vida SwiftUI do feedback tátil; não altera contrato, persistência ou motor de medição.
- **Fonte de verdade:** Decisão 65 (feedback háptico durante a fase de carga); `docs/01-funcional.md` §7. A decisão não autoriza háptico após a sessão terminal.

## Donos e aceite

- **Implementação:** Rian / iOS.
- **QA proporcional:** Breno.
- **Aceite operacional:** Giam.
- **Critérios:**
  1. Enquanto o Check estiver em `medindo`, a trilha pode emitir hápticos, respeitando Reduzir Movimento.
  2. Resultado, inconclusivo, cancelamento e saída da tela não deixam tarefa háptica ativa.
  3. A mudança não altera dados, cronograma, score ou veredito do Check.
- **Evidência planejada:** build/testes iOS focados e repetição manual em iPhone físico; build ou simulador não substituem a última prova.
- **Evidência executada:** `xcodebuild build-for-testing -project Nolaggy.xcodeproj -scheme NolaggyCoreTests -destination 'generic/platform=iOS Simulator'` passou após a alteração. A execução completa da suíte no simulador foi interrompida após travar no runner de UI por mais de cinco minutos, sem resultado final; não conta como aprovada.
- **Pendente:** repetir um Check no iPhone físico e confirmar que a vibração termina imediatamente ao aparecer resultado, inconclusivo ou cancelamento.
