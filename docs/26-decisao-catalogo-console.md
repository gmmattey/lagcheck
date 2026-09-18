# LagCheck — decisão: teto de plataformas de console no catálogo Debug

**Status:** código do domínio pronto e testado; envelope assinado **não publicado** — bloqueado por assinatura externa
**Escopo:** apenas o validador/schema do catálogo remoto. Tela de seleção de plataforma no app **não faz parte** desta decisão.

## Contexto

Levantamento de quais dos oito jogos do catálogo existem de fato em PlayStation/Xbox, e se a plataforma do cliente muda o alvo de medição:

| Jogo | Existe em PS/Xbox? | Observação |
| --- | --- | --- |
| Fortnite | Sim, crossplay total (PS, Xbox, Switch, PC, mobile) | Mesmo backend AWS para todas as plataformas. |
| Roblox | Só Xbox — a Sony nunca liberou Roblox no PlayStation | Infra própria da Roblox Corp, roteamento por instância. |
| Minecraft | Sim, Bedrock crossplay (PS, Xbox, Switch, PC, mobile) | Sem endpoint de ping público conhecido, independente da plataforma. |
| Call of Duty: Mobile, Free Fire, PUBG MOBILE, Brawl Stars, Wild Rift | Não existem em console | São produtos mobile/PC específicos, sem versão PlayStation/Xbox. |

Conclusão que orienta esta decisão: **a plataforma do cliente não muda qual endpoint é válido** — quem define isso é o backend do jogo, que é o mesmo para todo cliente crossplay. Portanto liberar console nesses três jogos não muda estratégia, confiança nem região: continua `genericRegion` / `medium` / `sa-east-1`, o mesmo beacon UDP já usado hoje.

## Decisão

`RemoteCatalogVerifier.validateDebugPayload` trocou a checagem fixa `platforms == [.iphone]` por um **teto de plataformas por jogo** (`debugAllowedPlatforms`, em `Sources/NolaggyDomain/RemoteCatalog.swift`). Um contexto publicado pode usar qualquer subconjunto do teto do seu jogo:

```swift
"fortnite":    [.iphone, .playstation, .xbox]
"roblox":      [.iphone, .xbox]
"minecraft":   [.iphone, .playstation, .xbox]
// os outros cinco jogos continuam limitados a [.iphone]
```

Isso foi desenhado deliberadamente como **subconjunto, não igualdade**: o envelope já assinado e publicado hoje (`debug-2026.09.08.2`, iPhone-only para os oito jogos) continua válido sem re-assinatura, porque `{iphone}` é subconjunto de `{iphone, playstation, xbox}`. O código pode ser mesclado e distribuído antes de qualquer novo envelope existir, sem quebrar o catálogo em produção.

Um jogo que reivindicar uma plataforma fora do seu teto (ex.: Roblox com `playstation`, ou Wild Rift com `xbox`) continua sendo rejeitado com `unsupportedDebugCatalog`, antes de qualquer resolução de contexto.

### Testes adicionados (`Tests/NolaggyDomainTests/RemoteCatalogTests.swift`)

- `testConsolePlatformsResolveForCrossplayGamesUsingTheSameRegionalReference`: confirma que Fortnite (PS/Xbox), Roblox (Xbox) e Minecraft (PS/Xbox) resolvem para o mesmo `gamelift-ping.sa-east-1.api.aws`/`genericRegion`, e que Roblox em PlayStation continua não resolvendo.
- `testCatalogRejectsAPlatformOutsideTheGameApprovedCeiling`: confirma que Roblox+PlayStation, Wild Rift+Xbox e Free Fire+PlayStation são recusados como catálogo Debug inválido.
- `testPublishedDebugEnvelopeFeedsAllEightBRIPhoneContextsWithoutFortniteFallback` (já existente) segue passando sem alteração, validando que o envelope hoje publicado não foi afetado.

## O que esta decisão não faz

- **Não publica um novo catálogo.** A chave privada de assinatura Ed25519 não está neste repositório, no Worker ou no iPhone (ver `docs/14-decisao-catalogo-remoto-debug.md`) — é assim por desenho. Este código só descreve o que um envelope futuro pode conter; ele precisa ser montado e assinado fora deste checkout antes de qualquer publicação em `/v1/catalog.json` ou no `DebugCatalogBase.json` embarcado.
- **Não muda a estratégia de medição, confiança ou promessa de precisão.** Console continua nível D (`genericRegion`/`medium`), igual mobile hoje — nenhum endpoint mais específico foi encontrado para nenhum dos três jogos.
- **Não constrói a tela de seleção de plataforma.** O domínio já tinha `Platform.playstation`/`.xbox` e a regra de pergunta Wi-Fi/Ethernet (`GameContext.validateStructure`); o app (`NolaggyApp`/`QuickCheckFeatureView`) ainda não tem UI para escolher plataforma — hoje o fluxo está fixo em `.iphone`. Requisito já registrado para quando essa tela for desenhada: **seleção por ícones dos consoles, dispostos lado a lado, em uma única linha horizontal.**

## Payload de exemplo para a próxima assinatura

Estrutura mínima que o próximo envelope precisa ter para liberar console (apenas os três contextos que mudam; os outros cinco jogos permanecem como em `debug-2026.09.08.2`):

```json
{
  "id": "fortnite",
  "name": "Fortnite",
  "contexts": [{
    "market": "BR", "platforms": ["iphone", "playstation", "xbox"],
    "profileID": "BATTLE_ROYALE_COMPETITIVE", "availability": "available",
    "measurement": { "primaryRegion": "sa-east-1", "strategy": "genericRegion", "confidence": "medium", "precisionKey": "regionalReference" }
  }]
},
{
  "id": "roblox",
  "name": "Roblox",
  "contexts": [{
    "market": "BR", "platforms": ["iphone", "xbox"],
    "profileID": "CASUAL_REALTIME", "availability": "available",
    "measurement": { "primaryRegion": "sa-east-1", "strategy": "genericRegion", "confidence": "medium", "precisionKey": "regionalReference" }
  }]
},
{
  "id": "minecraft",
  "name": "Minecraft",
  "contexts": [{
    "market": "BR", "platforms": ["iphone", "playstation", "xbox"],
    "profileID": "CASUAL_REALTIME", "availability": "available",
    "measurement": { "primaryRegion": "sa-east-1", "strategy": "genericRegion", "confidence": "medium", "precisionKey": "regionalReference" }
  }]
}
```

`catalogVersion` precisa ser incrementado (ex.: `debug-2026.09.18.1`) e o novo envelope precisa ser assinado com a chave privada existente, validado localmente contra a chave pública embarcada (`DebugCatalogSigningKey.publicKeyBase64`), publicado no Worker (`/v1/catalog.json`) e, se for a base embarcada, substituído em `Sources/NolaggyInfrastructure/Resources/DebugCatalogBase.json`.

## Próximo gate

Antes de qualquer publicação: revisão de Iury (mesmo padrão de `docs/14-decisao-catalogo-remoto-debug.md`), assinatura do envelope fora deste checkout, e — antes de o console ser utilizável de ponta a ponta — a tela de seleção de plataforma no app.
