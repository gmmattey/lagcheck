# Nolaggy — decisão: catálogo remoto assinado em Debug

**Status:** Worker/envelope v2 publicados em Debug; smoke UDP em iPhone físico concluído; validação física do catálogo remoto e cenários regionais pendente

## Decisão

O Debug usa `GET /v1/catalog.json` no mesmo Worker gratuito já autorizado para a carga do Deep Check. A resposta é um envelope `Ed25519` de schema `1`; a assinatura cobre os bytes exatos de `payloadBase64` depois da decodificação. O app verifica a assinatura com a chave pública embarcada antes de interpretar JSON, além de conferir schema, algoritmo, período de validade de no máximo 30 dias, versão coincidente e regras de negócio.

A chave privada não fica no iPhone, no repositório ou no Worker. O Worker apenas entrega o envelope pré-assinado. O Worker e o envelope v2 estão publicados em Debug. A sessão UDP contra a referência BR já teve smoke em iPhone físico; isso não prova a cadeia remota do catálogo, TestFlight ou produção. Uma nova publicação continua exigindo o processo seguro de assinatura fora deste checkout.

## Limite da medição

O único destino que esta entrega reconhece é `gamelift-ping.sa-east-1.api.aws:7770`. Ele é um beacon UDP AWS em São Paulo (`sa-east-1`) e sustenta exclusivamente a estratégia `genericRegion`, confiança `medium` e a chave de precisão `regionalReference`. Não é endpoint oficial de Fortnite nem de outro jogo.

Com a decisão de ampliação, o catálogo Debug `debug-2026.09.08.2` libera os oito contextos BR/iPhone pela mesma referência regional genérica. Isso não cria endpoint oficial, nem muda a promessa de precisão:

| Jogo | Contexto Debug | Estado | Motivo |
| --- | --- | --- | --- |
| Fortnite | BR · iPhone | testável | Rota regional AWS de São Paulo validada; `genericRegion` / `medium`. |
| Call of Duty: Mobile | BR · iPhone | testável | Referência regional genérica; Activision informa conexão ao servidor fisicamente mais próximo. |
| Free Fire | BR · iPhone | testável | Referência regional genérica; operação/suporte oficial no Brasil, sem endpoint público. |
| PUBG MOBILE | BR · iPhone | testável | Referência regional genérica; operação oficial no Brasil, sem endpoint público. |
| Brawl Stars | BR · iPhone | testável | Referência regional genérica; Supercell informa seleção de servidor próximo. |
| League of Legends: Wild Rift | BR · iPhone | testável | Referência regional genérica; Riot publica rota/peering Wild Rift para Brasil. |
| Roblox | BR · iPhone | testável | Referência regional genérica; Roblox confirma data center em São Paulo em operação. |
| Minecraft | BR · iPhone | testável | Referência regional genérica, não do servidor escolhido pela pessoa. |

Todos os contextos carregam `measurement` com `genericRegion` e confiança `medium`; a UI deve qualificá-los como rota regional de referência. As fontes de evidência são AWS GameLift Ping Beacons, Epic Fortnite, Activision COD Mobile, Garena Free Fire, Supercell Brawl Stars, Riot Peering e Roblox RDC 2025; nenhuma delas autoriza chamar o resultado de ping oficial.

## Contrato e aceite

O payload contém perfis, regiões, jogos e contextos por mercado/plataforma. Contexto `available` exige perfil, região existente, `measurement`, estratégia, confiança e chave de precisão compatíveis. Contexto `unavailable` exige `measurement = null`. O validador Debug exige exatamente os oito IDs da tabela, um único contexto `BR`/iPhone disponível para cada um e a mesma referência `sa-east-1` com `genericRegion`/`medium`.

Aceite automatizado:

1. Envelope assinado válido resolve os oito contextos BR/iPhone da tabela para o beacon regional AWS.
2. Payload ou assinatura adulterados são recusados antes de parse/uso.
3. Schema, algoritmo, validade, versão, duplicatas, perfil/região pendentes e disponibilidade incoerente são recusados.
4. Um contexto ausente ou indisponível não resolve destino, score ou sessão.
5. O teste do Worker confirma que o envelope entregue é verificável pela chave pública embarcada.

## Próximo gate

Antes de TestFlight: registrar a resposta Debug vigente e validar em iPhone físico o download, a assinatura, o cache/fallback e os cenários regionais do catálogo. A entrada de novo jogo, mercado ou região exige evidência da estratégia, endpoint, confiança, nova versão assinada e revisão de Iury. Os candidatos EUA registrados em [Decisão de seleção regional automática](./16-decisao-selecao-regional-automatica.md) ainda não fazem parte deste payload Debug e não autorizam medição até entrarem em envelope válido.

Este gate não exige UMP, AdMob, banner ou consentimento de anúncios: esses itens saíram do MVP1 e pertencem ao recorte MVP1.1. O catálogo remoto não carrega IDs, flags ou requisitos de publicidade.
