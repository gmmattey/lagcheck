# LagCheck — Decisão 37: Catálogo por Contexto e Rotas Reais

**Status:** decidido pelo dono do produto; implementação pronta para assinatura externa
**Data:** 19 de setembro de 2026  
**Frentes:** Marco, Iury, Rian e Renan

Esta decisão substitui o teto restrito de plataformas Debug da decisão 26 a
partir do primeiro catálogo assinado que usar o schema 2. O envelope legado de
schema 1 continua aceito apenas para que uma atualização inválida nunca deixe
o app sem catálogo.

## Decisão

O LagCheck preserva todos os jogos do catálogo, mas cada entrada passa a representar
o produto correto, a plataforma correta e o tipo de rota que está realmente sendo
medido. O app não pode usar uma plataforma apenas como rótulo, nem reutilizar uma
rota de iPhone para uma seleção de PC ou console.

O destino de medição segue esta ordem:

1. servidor dedicado público, verificável e permitido do jogo, quando houver;
2. infraestrutura pública verificável associada ao ecossistema do jogo;
3. beacon regional público, identificado na interface como `região de referência`.

Um destino de nível inferior não pode ser apresentado como se fosse um servidor do
jogo. Um contexto sem destino assinado compatível é indisponível; ele não herda o
destino de outro contexto.

## Catálogo canônico

| Família atual | Produto/contextos corretos | Rota prioritária |
| --- | --- | --- |
| Fortnite | iPhone, PlayStation, Xbox, PC, Nintendo Switch | referência regional, salvo endpoint público verificável futuro |
| Call of Duty: Mobile | iPhone | referência regional |
| Free Fire | iPhone | referência regional |
| PUBG MOBILE | iPhone | referência regional |
| Brawl Stars | iPhone | referência regional |
| League of Legends: Wild Rift | iPhone | referência regional |
| Roblox | iPhone, PlayStation, Xbox, PC | referência regional; a instância é dinâmica |
| Minecraft | iPhone, PlayStation, Xbox, PC, Nintendo Switch | servidor Bedrock específico quando declarado; caso contrário, referência regional |
| Apex Legends | PlayStation, Xbox, PC, Nintendo Switch | referência regional |
| Blood Strike | iPhone, PC | referência regional |
| Counter-Strike 2 | PC | servidor dedicado Steam/A2S validado; referência regional somente quando não houver servidor declarado |
| Dota 2 | PC | referência regional |
| EA SPORTS FC | FC Mobile no iPhone; versão anual corrente em PC/PlayStation/Xbox | referência regional por produto |
| League of Legends | PC | referência regional |
| Palworld | PC, Xbox e plataformas oficialmente disponibilizadas pelo publisher | servidor dedicado Steam/A2S validado; referência regional como limite seguro |
| Rainbow Six Siege | PC, PlayStation, Xbox | referência regional |
| Rainbow Six Mobile | iPhone, como produto distinto de Siege | referência regional |
| Rocket League | PC, PlayStation, Xbox, Nintendo Switch | referência regional |
| Rocket League Sideswipe | iPhone, como produto distinto de Rocket League | referência regional |
| Rust | PC, PlayStation, Xbox | servidor dedicado Steam/A2S validado; referência regional como limite seguro |
| VALORANT | PC, PlayStation, Xbox | referência regional; não declarar iPhone no Brasil sem publicação oficial |
| Call of Duty: Warzone | PC, PlayStation, Xbox | referência regional; Warzone Mobile não é contexto disponível |

As entradas distintas acrescentadas acima preservam a descoberta das famílias já
catalogadas, mas impedem que uma medição, requisito ou plataforma de um produto seja
atribuído a outro.

## Não-escopo

- Não criar servidor próprio, Worker, VPS, SDK pago ou novo endpoint remoto.
- Não descobrir endpoints privados, não documentados ou obtidos por engenharia
  reversa.
- Não prometer ping de matchmaking ou do servidor da publisher sem host e protocolo
  públicos, verificáveis e efetivamente medidos.
- Não exibir arte, logo ou capa licenciada de jogos.

## Contrato de catálogo

Cada contexto publicável deve ter: `gameID`, produto canônico, mercado, plataforma,
perfil, disponibilidade e uma declaração de destino/protocolo. A declaração registra
estratégia, confiança, chave de precisão, origem da evidência e vencimento da revisão.

Um contexto específico de servidor exige host, porta, protocolo, regra de validação de
resposta e prova de que a consulta é pública e permitida. A2S é aplicável a servidor
dedicado concreto; não representa automaticamente matchmaking oficial.

O catálogo-base e o remoto continuam sujeitos a assinatura Ed25519. A publicação de
um envelope novo permanece fora deste checkout e não faz parte desta entrega.

## Critérios de aceite

1. A plataforma oferecida pela UI existe no contexto assinado resolvido.
2. Plataforma sem contexto não inicia sessão e não recebe destino herdado.
3. Todo destino resolve para o protocolo e validador declarados; amostras insuficientes
   continuam inconclusivas.
4. A UI distingue `servidor dedicado` de `região de referência` sem depender só de cor.
5. Cada novo host específico possui registro de evidência, teste de contrato e revisão
   de Iury antes de assinar um catálogo.
6. O histórico preserva plataforma, estratégia, precisão, destino e versão do catálogo
   usados naquela sessão.

## Gates restantes

- Um cofre externo assina os bytes de `DebugCatalogPayload.schema2.canonical.json`
  com a chave Ed25519 já confiada pelo app. A chave privada não pertence ao
  checkout, Worker ou iPhone.
- O envelope retornado precisa passar por `catalog-signing.mjs verify`, substituir
  em conjunto o bundle Debug e o Worker, e então passar por testes e leitura
  remota após deploy autorizado.
- A publicação do catálogo assinado e qualquer teste físico de host externo exigem
  revisão separada; esta decisão não os declara concluídos.
