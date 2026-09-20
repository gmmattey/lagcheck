# 45 — Exceção temporária: Gemini no release público 1.0.0

**Data:** 19 de setembro de 2026
**Status:** decidido pelo Dono do Produto
**Relacionada a:** decisão 23; fluxo de release em `docs/06`

## Decisão

O primeiro release público do LagCheck, identificado como `1.0.0` com build ainda a definir, pode manter a integração direta client-side com Gemini.

Esta decisão é uma exceção única ao critério de saída da decisão 23. Ela cobre o TestFlight interno desse candidato e sua publicação pública, se todos os demais gates forem aprovados. Não autoriza TestFlight externo nem qualquer release posterior com a mesma arquitetura.

## Risco aceito

A credencial local incluída no archive pode ser extraída do IPA e sofrer uso indevido ou consumir quota. A chamada direta também envia ao Gemini o contexto necessário para gerar dicas após um Deep Check válido: jogo e plataforma selecionados, tipo de rede, métricas de rota, efeito de carga, diagnóstico de Wi-Fi/topologia quando disponível e idioma.

Falhas do serviço não podem gerar dica heurística nem alterar score: a ação fica indisponível ou permite nova tentativa, como já previsto pelo contrato atual.

## Limite e contenção

- Antes de qualquer TestFlight externo ou do próximo build público, a integração deve migrar para proxy de borda aprovado em decisão de infraestrutura própria.
- A exceção não autoriza ampliar o Worker `nolaggy-deep-check` nem criar endpoint novo sem essa decisão.
- Se houver exposição, abuso ou consumo anormal, a credencial deve ser revogada/rotacionada e a ação de dicas deve ficar indisponível até contenção segura.
- Privacidade da App Store, política pública e App Review Notes devem declarar a transmissão ao Gemini de forma coerente com o binário enviado.
