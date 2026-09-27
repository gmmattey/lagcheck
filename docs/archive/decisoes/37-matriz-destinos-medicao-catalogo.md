# LagCheck — Matriz técnica de destinos de medição por contexto

**Status:** inventário técnico para assinatura futura; não publica nem autoriza novos hosts

## Regra de publicação

Cada contexto assinado deve apontar para um `RemoteCatalogRegion` que declara
host, porta, `protocolKind` e, quando não for GameLift previamente homologado,
uma evidência pública revisada. A escolha não pode ser inferida por porta.

| Tipo | Protocolo | Estratégia | Confiança | Precisão | Condição para publicação |
| --- | --- | --- | --- | --- | --- |
| Beacon regional AWS | `gameLiftPing` | `genericRegion` | `medium` | `regionalReference` | região existente no `GlobalProbeRegistry` |
| Beacon regional PlayFab | `playFabQoS` | `genericRegion` | `medium` | `regionalReference` | hostname público do título/provedor, porta 3075 e fonte pública revisada |
| Servidor dedicado Steam | `steamA2S` | `dedicatedServer` | `high` | `dedicatedServer` | host e porta A2S consultáveis, operador/fonte pública e revisão da resposta real |

Uma resposta HTTP, ICMP, um nome de produto ou a simples informação de que um
jogo usa AWS/Azure **não** são evidência de um destino UDP. Sem amostras UDP
válidas, a sessão permanece inconclusiva.

## Inventário final dos 20 registros atuais

O catálogo Debug publicado no momento deste inventário resolve os vinte
registros para `gamelift-ping.sa-east-1.api.aws:7770`, como referência regional
AWS. Após a revisão de fontes públicas dos publishers e operadores, **esse
continua sendo o destino final honesto para os vinte contextos**: não há host
fixo, público, estável e permitido para uma sonda UDP do LagCheck que possa ser
assinado hoje.

| ID | Fonte primária consultada | Resultado técnico | Destino final assinado agora |
| --- | --- | --- | --- |
| `fortnite` | [Epic: endpoints de sub-região](https://www.epicgames.com/help/c-34254770/c-38015632/a22355516) | A Epic publica `ping-sao.ds.on.epicgames.com`, mas instrui teste ICMP e afirma que o tráfego de jogo é UDP. Não publica porta/codec UDP do beacon. | AWS São Paulo · `gameLiftPing` |
| `call-of-duty-mobile` | [Activision Support](https://support.activision.com/call-of-duty-mobile) | Matchmaking/host de partida não publica alvo UDP fixo para consulta. | AWS São Paulo · `gameLiftPing` |
| `free-fire` | [Garena Free Fire](https://ff.garena.com/) | Nenhum alvo UDP de servidor publicado. | AWS São Paulo · `gameLiftPing` |
| `pubg-mobile` | [PUBG MOBILE](https://www.pubgmobile.com/) | Nenhum alvo UDP de servidor publicado. | AWS São Paulo · `gameLiftPing` |
| `brawl-stars` | [Supercell Support](https://support.supercell.com/brawl-stars/) | Nenhum alvo UDP de servidor publicado. | AWS São Paulo · `gameLiftPing` |
| `wild-rift` | [Riot Support](https://support-leagueoflegends.riotgames.com/) | Nenhum alvo UDP de servidor publicado. | AWS São Paulo · `gameLiftPing` |
| `roblox` | [Roblox: matchmaking](https://create.roblox.com/docs/matchmaking) | A instância é selecionada dinamicamente pelo matchmaking; não há host de experiência fixo para medir. | AWS São Paulo · `gameLiftPing` |
| `minecraft` | [Minecraft: Bedrock Dedicated Server](https://www.minecraft.net/en-us/download/server/bedrock) | BDS é software oficial que o operador hospeda; IP/porta pertencem a cada mundo. Não há beacon PlayFab público do título. | AWS São Paulo · `gameLiftPing` |
| `apex-legends` | [EA Help](https://help.ea.com/) | Nenhum alvo UDP de servidor publicado. | AWS São Paulo · `gameLiftPing` |
| `blood-strike` | [Blood Strike](https://www.blood-strike.com/) | Nenhum alvo UDP de servidor publicado. | AWS São Paulo · `gameLiftPing` |
| `cs2` | [Valve: Steam Game Servers](https://partner.steamgames.com/doc/features/multiplayer/game_servers?l=english) | Servidores podem ser dedicados e aparecer no browser Steam, mas a Valve não publica um host oficial fixo de CS2 para consulta. A2S só entra após curadoria de host concreto. | AWS São Paulo · `gameLiftPing` |
| `dota2` | [Valve: Steam Game Servers](https://partner.steamgames.com/doc/features/multiplayer/game_servers?l=english) | A documentação descreve servidores Steam, não um endpoint fixo de matchmaking para o LagCheck. | AWS São Paulo · `gameLiftPing` |
| `eafc` | [EA Help](https://help.ea.com/) | Nenhum alvo UDP de servidor publicado. | AWS São Paulo · `gameLiftPing` |
| `league-of-legends` | [Riot Support](https://support-leagueoflegends.riotgames.com/) | Nenhum alvo UDP de servidor publicado. | AWS São Paulo · `gameLiftPing` |
| `palworld` | [Pocketpair: servidor dedicado](https://docs.palworldgame.com/settings-and-operation/arguments/) | A documentação expõe porta de escuta configurável e IP/porta pública configurável pelo operador, não host fixo nem contrato A2S público. | AWS São Paulo · `gameLiftPing` |
| `rainbow-six` | [Ubisoft Help](https://www.ubisoft.com/help/rainbow-six-siege) | Nenhum hostname PlayFab/QoS público do título. | AWS São Paulo · `gameLiftPing` |
| `rocket-league` | [Epic Help](https://www.epicgames.com/help/en-US/c-Category_RocketLeague) | Nenhum alvo UDP de servidor publicado. | AWS São Paulo · `gameLiftPing` |
| `rust` | [Facepunch: criar servidor](https://wiki.facepunch.com/rust/Creating-a-server) | O operador define `server.port` e `server.queryport`; este último é dinâmico e serve consultas do browser. Sem host curado não há destino fixo. | AWS São Paulo · `gameLiftPing` |
| `valorant` | [Riot Support](https://support-valorant.riotgames.com/) | Nenhum alvo UDP de servidor publicado. | AWS São Paulo · `gameLiftPing` |
| `warzone` | [Activision Support](https://support.activision.com/warzone-2) | Nenhum alvo UDP de servidor publicado. | AWS São Paulo · `gameLiftPing` |

### Resultado dos quatro candidatos específicos

- **CS2:** A2S continua possível para um servidor que seja explicitamente
  curado e responda ao handshake. A documentação pública descreve browser e
  servidores dedicados, não um host oficial global. Não há payload a assinar.
- **Rust:** a Facepunch documenta que `server.queryport` é UDP e pode mudar com
  a configuração do operador. Não pode ser convertido em hostname fixo do
  catálogo.
- **Palworld:** a Pocketpair documenta `-port`, `-publicip` e `-publicport`
  como parâmetros do operador. A pesquisa não encontrou uma especificação
  pública que permita declarar A2S como protocolo do título; portanto não é
  elegível para `steamA2S` agora.
- **Minecraft Bedrock:** a Mojang publica o software BDS, não uma instância
  pública. O endpoint é o mundo escolhido pelo jogador/operador; ele também não
  é um beacon PlayFab QoS público.

## Gate antes de assinar uma rota não genérica

1. Registrar fonte pública, URL, data de revisão, proprietário e contexto de
   jogo/plataforma na ficha do destino.
2. Validar DNS/host, porta e protocolo em iPhone físico; preservar a evidência
   do datagrama correlacionado, sem converter falha em score.
3. Para A2S, validar challenge e `A2S_INFO`; para PlayFab, validar o bit-flip
   do cabeçalho. A porta sozinha não seleciona codec.
4. Publicar somente o contexto assinado que tenha passado o gate. Contexto sem
   rota aprovada fica indisponível/inconclusivo, sem fallback de outro jogo ou
   plataforma.
5. Não criar endpoint, Worker ou serviço intermediário para preencher lacuna de
   evidência.
