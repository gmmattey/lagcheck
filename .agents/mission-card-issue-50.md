# Cartão de Missão — Issue #50: Ritual honesto do Histórico

## Enquadramento

- **Problema da pessoa:** após vários Checks, a lista isolada não responde se a instabilidade foi pontual ou se se repetiu para aquele jogo.
- **Resultado esperado observável:** no Histórico, cada jogo mostra um resumo local de 7, 14 ou 30 dias: `Pronto em X de Y checks comparáveis`, com a distribuição de `Instável`, `Evitaria` e `Inconclusivo` separada. A pessoa escolhe a janela; não há inferência sobre causa, operadora, Wi-Fi ou melhor horário.
- **Fora de escopo:** previsão, “melhor horário”, correlação causal, média de score, comparação entre jogos/redes/regiões/regras, sincronização, telemetria nova, endpoint/Worker e alteração de score/veredito.
- **Lane:** Full flow sistêmica.
- **Por que esta lane:** corrige a retenção Android para o contrato já documentado e adiciona campos de comparabilidade aos snapshots locais; ambos os clientes passam a consumir a mesma regra de agregação.

## Contrato e handoff de UI

- **Comparável:** mesmo jogo, plataforma, vínculo externo declarado, rede observada, região e versão de regra; só entrada com ao menos 10 respostas UDP válidas e veredito não inconclusivo.
- **Base mínima:** 3 Checks comparáveis distribuídos em pelo menos 2 dias na janela. Sem base, o resumo não faz uma afirmação de padrão.
- **Inconclusivos:** aparecem como contagem separada e não entram no denominador de `Pronto em X de Y`.
- **Decisão da pessoa:** selecionar 7, 14 ou 30 dias e reconhecer o histórico daquele jogo; tocar em um Check ainda abre seus detalhes e permite refazer a medição.
- **Estados:** histórico vazio preserva seu estado atual; histórico com dados insuficientes preserva a lista sem resumo; dados suficientes mostram um único resumo compacto por jogo; apagar tudo remove lista e resumos. Não há loading dedicado, medição, permissão ou estado de erro novo.
- **UI:** usa `NLColor`, `LagCheckColors`, tipografia mono para números, divisores/bordas existentes e `VerdictIndicatorBadge` onde aplicável. Sem cartão adicional, gráficos, animação, cores ou espaçamentos locais. Os controles de período têm alvo de 44 pt/dp, rótulo acessível e ordem de leitura antes da lista do jogo.
- **Copy PT-BR / English:** `Últimos 7 dias` / `Last 7 days`; `Pronto em %d de %d checks` / `Ready in %d of %d checks`; `Inconclusivos: %d` / `Inconclusive: %d`. A copy descreve somente Checks registrados, nunca a rede futura.
- **Interação nativa:** iOS mantém Histórico como destino contextual e volta para a origem; Android mantém voltar para Home. Ambos preservam período selecionado enquanto a tela está aberta. VoiceOver/TalkBack anunciam jogo, janela e resumo; Dynamic Type/font scale pode quebrar linhas, jamais truncar os contadores.

## Donos, aceite e evidência

- **Donos:** Rian (app/persistência), Iury (contrato de comparabilidade), Renan (handoff/visual), Camillo (gate), Breno (QA), Giam (aceite).
- **Aceite:** mesmas entradas equivalentes produzem as mesmas contagens iOS/Android; entradas incompatíveis ou inconclusivas não contaminam a fração; Android expira >90 dias e mantém no máximo 100 por jogo; snapshots Android legados continuam legíveis, porém não são elegíveis para o resumo sem fatos de comparabilidade; não há nova rede, PII ou telemetria.
- **Evidência planejada:** testes puros de agregação e retenção nos dois clientes; build/testes afetados; inspeção de localizações; simulador/emulador para UI e acessibilidade básica. Aparelho físico continua pendência de UI/acessibilidade, não de medição.

## Evidência de implementação — 16/10/2026

- iOS: agregador puro e interface de Histórico em 7/14/30 dias; snapshots inconclusivos finais não têm score nem causa; cancelamentos seguem descartados. O resumo legado sem consumidor foi removido.
- Android: contrato equivalente, campos de comparabilidade retrocompatíveis no JSON e retenção corrigida para 90 dias / 100 por jogo. Snapshots antigos seguem visíveis, mas não entram no resumo.
- Testes locais: `xcodebuild test` focado em ritual, snapshot, coordenador e SwiftData (18 testes, todos verdes); `./gradlew :app:testDebugUnitTest` focado em ritual, snapshot e traduções (verde); build iOS de simulador (verde); `plutil -lint` e `git diff --check` (verdes).
- Limite da evidência: não houve navegação visual no simulador/emulador, VoiceOver/TalkBack nem aparelho físico. Portanto, não é evidência de acessibilidade em runtime, rede real ou release.
