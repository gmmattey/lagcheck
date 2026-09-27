# 46 — Reconciliação: Deep Check único e consentimento móvel

**Data:** 19 de setembro de 2026
**Status:** decidido e aplicável ao corte de release
**Consolida:** decisões 36 e 43

## Regra prevalente

A decisão 43 substitui a jornada de Quick Check da decisão 36. Há uma única medição visível, o **Deep Check**.

Em rede móvel, o consentimento com o teto de 10 MB é solicitado antes de iniciar probes UDP ou transferência sob carga. Ao recusar, a jornada é encerrada sem alternativa reduzida, resultado, score, histórico, reteste ou requisição a `/v1/load`.

## O que permanece da decisão 36

- Em Wi-Fi e celular, após início válido, o Deep Check mede repouso por UDP e carga por UDP + `/v1/load`, com máximo de 10 MB e 15 segundos.
- O score vem do repouso; o efeito sob carga é complementar.
- Em celular, não há inferência de roteador, gateway ou frequência Wi-Fi.
- Cancelamento por pessoa, background ou troca de interface interrompe UDP e carga, descarta tudo e não persiste resultado parcial.
- Menos de dez respostas UDP válidas resulta em inconclusivo, sem score.

## Matriz revisada

TC-04 passa a ser: **Recusa no móvel** — ao recusar, Deep Check retorna ao estado neutro; não oferece Quick Check, não inicia probe ou carga, não exibe resultado e não grava histórico.

Acrescentar ao release:

- **TC-10:** Home, detalhe, histórico, reteste, copy, acessibilidade e testes de UI não expõem Quick Check; todo caminho válido chega ao Deep Check.
- **TC-11:** a recusa no móvel resulta em zero chamada a `/v1/load` e nenhuma amostra/resultado persistido.
