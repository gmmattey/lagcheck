# Architecture Plan — Pré-validação Steam A2S com paridade iOS/Android

**Autor do plano:** Camillo (proporcional). **Missão:** `.agents/mission-card-steam-a2s-route-activation-2026-10-16.md`.
**Refina:** Decisões 37, 38/39 e 78. Não cria decisão nova: cumpre o critério de ativação da Decisão 78.

## Estado encontrado

- Schema 3 + Ed25519 já carregam `selection.candidates` com `expectedIdentity`, `operatorEvidenceURL` e `priority`. Rotas `gameOwned` ativas exigem candidatos válidos; pendentes não carregam host.
- iOS: `SteamQueryA2SPayloadCodec`, `SteamA2SRoutePreflight` e `AutomaticGameRouteResolver` existiam. A pré-validação aceitava challenges repetidos até o timeout (sem limite).
- Android: codec/transporte A2S existiam, mas o resolvedor excluía qualquer rota própria com candidatos e não havia pré-validação equivalente.

## Contrato `steam-a2s-preflight-1` (igual nos dois clientes)

1. Envia A2S_INFO inicial (25 B) ao único host/porta do candidato assinado, em socket UDP conectado (só aceita datagramas daquele endpoint).
2. Resposta `0x41` válida (≥ 9 B): reenvia **uma única vez** com o token (29 B). Segundo challenge, challenge curto/malformado → rejeita.
3. Resposta `0x49`: decodifica nome, diretório e AppID (16 bits LE); aceita só se AppID e diretório forem iguais e, quando houver, o nome começar com o prefixo.
4. Timeout total de 2 s por candidato; truncamento, cabeçalho inválido, tipo inesperado ou erro de rede → rejeita.
5. Nenhum A2S_PLAYER/RULES. Fragmentação/compressão de INFO não são tratadas: uma resposta fragmentada é rejeitada (cai na AWS). Se um servidor autorizado exigir isso, entra como evolução com novo PCAP.

## Decisão de rota (igual nos dois clientes)

Candidatos ativos do catálogo assinado, ordenados por (prioridade, `routeId = route.id-candidate.id`); o primeiro que passa vence; nenhum passa → `awsFallback` assinada (que continua pré-lida por região conforme a Decisão 90). `resolve` simples nunca devolve rota própria sem pré-validação. Preferência manual de região não substitui rota própria validada.

## Mudanças

| Camada | iOS | Android |
| --- | --- | --- |
| Máquina pura | `SteamA2SPreflightMachine` (`NolaggyInfrastructure`) | `SteamA2sPreflightMachine` (`core:network`) |
| Transporte | `SteamA2SRoutePreflight` usa a máquina | `SteamA2sRoutePreflight` (DatagramSocket conectado, cancelável) |
| Porta | `GameRoutePreflighting` (existente) | `GameRoutePreflighting` (`core:catalog`) |
| Plano/resolvedor | existente | `RemoteCatalogResolver.automaticRoutePlan`, `AutomaticGameRouteResolver`, `MeasurementPlanner.planRegionalAutomatic` |
| Verificador | existente | `selection.mode` obrigatório e AppID em 1…65535 (paridade com `UInt16`) |
| UI | existente | rótulo "Servidor de jogo" só quando a rota respondida é `gameOwned` |

Sem mudança em Worker, endpoints, telemetria, score, veredito, thresholds, custo ou schema.

## Vetores compartilhados

`tools/vectors/steam-a2s-preflight-vectors.json`: challenge válido, INFO válido (com/sem challenge), AppID errado, diretório errado, prefixo errado, timeout (antes e depois do challenge), INFO truncado, challenge malformado/repetido, cabeçalho e tipo inválidos; decisão de rota: ordem de prioridade, desempate por id, falha→próximo, e fallback AWS.

## Portão de ativação (não executado)

Para marcar uma rota `active`: (1) operador autorizado e `operatorEvidenceURL` https; (2) PCAP real com challenge `0x41` + INFO `0x49` reproduzível por Iury; (3) identidade confirmada (AppID, diretório, prefixo); (4) novo envelope assinado com a chave vigente e cópia byte-idêntica para Worker/iOS/Android; (5) prova em aparelho físico. Nada disso foi feito.

## Riscos residuais

- Servidores que fragmentam/comprimem INFO são rejeitados (fallback seguro, não falso positivo).
- AppIDs acima de 65535 não cabem no campo A2S_INFO legado e são rejeitados na verificação do catálogo.
- A pré-validação roda antes do `pathWatcher` no Android (até ~6 s com 3 candidatos), igual ao iOS.
