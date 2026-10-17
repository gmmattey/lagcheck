# Architecture Plan — Integridade operacional

**Gate:** Camillo — `can proceed with listed constraints`
**Missão:** `.agents/mission-card-operational-integrity-2026-10-16.md`

## Contrato preservado

O Worker continua oferecendo somente `GET /v1/catalog.json`, `GET /v1/load` e
`POST /v1/telemetry`. Conforme as Decisões 89 e 90, o catálogo permanece em
Schema 3, Ed25519, com 48 jogos, 121 contextos e uma rota `awsFallback`
regional genérica por contexto; o conjunto de beacons AWS autorizado vem do
mesmo envelope e é pré-lido antes de escolher a região. As rotas
`gameOwned` ficam `pending`. Não há schema, endpoint, payload de telemetria,
score, veredito, persistência, SDK ou custo novo.

## Mudança mínima

1. Incrementar apenas `catalogVersion` da fonte canônica homologada e gerar os
   mesmos bytes de payload nos três clientes.
2. Assinar esses bytes exclusivamente com a chave v3 protegida do Keychain
   (`com.buildea.lagcheck.catalog.ed25519.v3` / `publisher`), depois de
   conferir que a chave pública emitida é a chave v3 distribuída pelos apps.
   A chave privada não entra em arquivo, log, Worker ou commit.
3. Elevar em paridade o teto de payload assinado de 64 KiB para 128 KiB: os
   48 jogos autorizados ocupam 74.415 bytes. O teto continua explícito,
   exercitado por vetor acima do limite e não altera schema nem contrato.
4. Validar o envelope com `verify-catalog-envelope.mjs` e com os validadores
   Swift/Kotlin. `catalog-signing.mjs` usa uma chave legada e não é gate desta
   rotação; sua correção é dívida técnica separada, nunca um motivo para aceitar
   uma assinatura incompatível.
5. Assinar todas as regiões AWS GameLift já presentes nos registros globais
   espelhados de iOS/Android. A rota `awsFallback` mantém a semântica de
   referência regional e a pré-leitura gera candidatos para essas regiões;
   país, locale e ordem não escolhem o vencedor. Rotas próprias ativas, caso
   existam no futuro, continuam a exigir pré-validação de identidade antes de
   superar a referência.
6. Substituir, byte a byte, o envelope em Worker, base iOS e asset Android.
7. Reapontar apenas os defaults de telemetria dos dois clientes ao host já
   ativo `nolaggy-deep-check.buildealabs.workers.dev`.

## Compatibilidade e recuperação

- Quem abrir uma build existente antes do vencimento pode receber/cachear o
  envelope remoto renovado; quem fizer cold start após a expiração ainda precisa
  de uma nova build com a base renovada. Logo Worker e novo archive/AAB são
  provas independentes.
- Cache remoto assinado e válido vence base inválida; resposta remota inválida
  não substitui cache válido.
- Rollback é somente para um envelope anterior ainda válido e byte-verificado.
  Um envelope expirado não é plano de recuperação.
- Telemetria segue best-effort (3 s, falha silenciosa) e não bloqueia Check,
  score, veredito ou histórico.

## Provas obrigatórias

| Área | Prova |
| --- | --- |
| Assinatura | verificador v3, validação Swift e Kotlin, validade menor ou igual a 30 dias |
| Paridade | Worker, `DebugCatalogBase.json` e `catalog-base.json` byte-idênticos |
| Seleção regional | Vetores Swift/Kotlin: menor P50 elegível, empate determinístico, preferência manual válida e inconclusivo sem duas respostas UDP |
| Expiração | sem cache: base renovada inicia após o antigo vencimento; com cache válido: base antiga vencida usa cache; remoto inválido preserva cache |
| Telemetria | defaults iOS/Android apontam ao host correto, payload permitido e sem PII; método inválido recebe 405 |
| Produção | resposta pública reflete envelope novo; `POST` controlado usa UUID efêmero; não prova distribuição de app |
| Distribuição | archive/AAB novo e depois hardware, track/TestFlight e lojas permanecem gates separados |
