# Cartão de Missão — Catálogo local global (iOS e Android)

**Data:** 16 de outubro de 2026  
**Lane:** Full flow sistêmica.  
**Architecture Plan:** `.agents/architecture-plan-local-catalog-2026-10-16.md`.

## Problema da pessoa

Um catálogo remoto antigo reduziu o Android e o iOS a São Paulo, embora o produto seja global. A pessoa precisa escolher ou receber automaticamente uma referência AWS GameLift global válida, sem depender do Worker e sem a impressão falsa de que São Paulo é o servidor do jogo.

## Resultado esperado observável

- Cada build iOS e Android carrega exclusivamente o mesmo envelope Ed25519 local com 48 jogos e referências AWS GameLift globais autorizadas.
- Para cada jogo testável, a referência continua sendo regional, nunca declarada como servidor oficial do jogo.
- A seleção automática mede as regiões locais do envelope e escolhe a menor P50 elegível; Ajustes só permite override dentre essas mesmas regiões.
- Nenhum cliente consulta, armazena ou aceita catálogo remoto; `/v1/catalog.json` deixa de ser contrato do Worker.

## Fora de escopo

Ativar servidor próprio de jogo, criar endpoints, alterar score/veredito/thresholds, mudar UDP, adicionar custo, publicar build ou fazer upload de loja.

## Donos e risco

- **Produto e aceite:** Giam; **orquestração:** Marco.
- **Arquitetura:** Camillo; **integridade de rede/catálogo:** Iury; **clientes:** Rian; **QA:** Breno.
- **Risco principal:** um recurso antigo ou cache remoto tornar a limitar regiões, ou iOS/Android embarcarem envelopes diferentes.

## Aceite e evidência

| Critério | Evidência |
| --- | --- |
| 48 jogos e referências AWS globais locais nos dois clientes | decodificação assinada e hashes idênticos dos envelopes de recurso |
| Nenhuma rota de catálogo é chamada pelo app | inspeção de dependências e testes sem `catalog.json` |
| Worker não serve `/v1/catalog.json` e preserva carga/telemetria | teste do Worker |
| P50 regional automática e override manual preservam a regra atual | vetores Android/iOS existentes e testes focados |
| Builds locais usam o recurso novo | inspeção de APK/AAB e produto Xcode; aparelho físico continua pendente |
