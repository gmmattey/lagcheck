# Cartão de Missão — Ativação segura de rotas Valve/Steam A2S

**Data:** 16 de outubro de 2026
**Lane:** Full flow sistêmica (motor UDP nos dois clientes + contrato do catálogo assinado).
**Fontes de verdade:** Decisões 37, 38/39, 78, 89 e 90 em `docs/DECISOES.md`; `docs/03`; `docs/08`.
**Architecture Plan:** `.agents/architecture-plan-steam-a2s-route-activation-2026-10-16.md`.

## Problema da pessoa

Quem joga um título Valve quer saber se pode jogar agora. Hoje a leitura é sempre uma
referência regional AWS. Quando houver um servidor Valve real, comprovado e compatível, o
LagCheck pode medir uma rota própria; sem prova suficiente, continua dizendo
"Referência regional" e nunca inventa um servidor de jogo.

## Resultado esperado observável

- Uma rota Valve só vence depois de A2S_INFO inicial, tratamento do challenge `0x41`, resposta
  INFO `0x49` e identidade estrita (AppID, diretório do jogo e prefixo de nome quando houver).
- Timeout, resposta inválida/truncada, challenge malformado ou repetido e identidade divergente
  não geram score nessa rota: a medição volta à referência AWS assinada.
- iOS e Android tomam a mesma decisão para os mesmos vetores.
- A UI só distingue "Servidor de jogo" de "Referência regional"; host e porta nunca aparecem.

## Não-escopo

Worker novo/publicado, endpoint, SDK, serviço pago, mudança de score/veredito/threshold,
assinatura ou ativação de catálogo em produção, build de loja, TestFlight/Play, A2S_PLAYER/RULES,
fragmentação/compressão de INFO (fora do contrato `steam-a2s-preflight-1`; ver plano).

## Donos e revisores

- Aceite: Giam. Prioridade/escalonamento: Marco. Arquitetura: Camillo.
- Entrega: Iury (protocolo, vetores, paridade) e Rian (integração Android/iOS).
- Validação: Breno. Visual/copy: Renan (somente o rótulo "Servidor de jogo").
- Decisão pendente do Luiz: autorizar operadores/hosts Valve e a captura de PCAP.

## Aceite e evidência

- Vetores compartilhados `tools/vectors/steam-a2s-preflight-vectors.json` (15 de protocolo + 5 de decisão) passam nos dois clientes.
- Catálogo assinado atual: nenhuma rota `gameOwned` ativa (121 `pending`, sem host).
- Relatório final separa: código local, testes, PCAP/evidência real, aparelho físico, Worker, distribuição e produção.

## Bloqueio de ativação

Sem PCAP real da troca UDP e identidade verificável de um servidor Valve autorizado, nenhuma rota
pode virar `active`. Isto é um bloqueio de ativação, não uma falha da implementação.
