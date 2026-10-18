# Architecture Plan — Catálogo local global

**Autor:** Camillo (gate proporcional)  
**Missão:** `.agents/mission-card-local-catalog-2026-10-16.md`  
**Decisão:** 94.

## Estado e causa

O Worker público ainda serve um envelope v3 antigo de 22 jogos e uma única região (`sa-east-1`). Os clientes aceitam cache remoto válido de mesmo schema antes da base embarcada. Isso permite rebaixar um build com catálogo global para São Paulo.

## Arquitetura decidida

1. A única autoridade de catálogo em execução passa a ser o envelope Ed25519 instalado em cada app: `DebugCatalogBase.json` no framework iOS e `catalog-base.json` nos assets Android.
2. Os dois recursos devem ser byte-idênticos, conter 48 jogos e a lista completa de beacons AWS GameLift homologados. Cada jogo conserva rota `awsFallback` de referência regional; ela não representa servidor oficial do jogo.
3. `RemoteCatalogRepository`, fetchers, caches e atualização diária saem dos dois clientes. A remoção elimina o downgrade por cache e toda consulta a `/v1/catalog.json`.
4. O Worker mantém somente os contratos já autorizados de carga e telemetria. A rota de catálogo é removida e deve responder 404.
5. A seleção regional, o motor UDP, score, veredito, schema 3, chave pública e regra `regional-selection-1` permanecem inalterados. Para uma sessão, todas as regiões do envelope local são pré-lidas e a região vencedora vem de P50 observado; sem evidência suficiente, o resultado segue inconclusivo.

## Compatibilidade e rollback

- O dado remoto salvo em instalações antigas deixa de ser lido: o próximo build sempre usa sua base local validada. Não há migração de histórico nem persistência compartilhada.
- O rollback é um novo build contendo o envelope local anterior, nunca a reativação silenciosa de catálogo remoto.
- Builds antigos continuam apontando para o endpoint legado até atualizarem; remover a rota não altera score nem cria resultado inventado, apenas impede que esses builds obtenham catálogo remoto.

## Limites e prova

- Não se cria ou presume destino de jogo. Todos os destinos são beacons AWS GameLift já validados pelo registro compartilhado.
- Não muda PII, telemetria, custo nem adiciona endpoint.
- Testar a decodificação e a paridade de bytes em iOS/Android, 48 jogos e as regiões globais, ausência de clientes HTTP de catálogo e 404 do Worker. Build/simulador/emulador são evidência separada de aparelho físico.

## Gate de Camillo

**can proceed with listed constraints**

Implementar estritamente este corte local, preservar a assinatura e não publicar/deployar sem nova autorização.
