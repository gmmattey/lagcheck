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

## Inventário dos 20 registros atuais

O catálogo Debug publicado no momento deste inventário resolve os vinte
registros para `gamelift-ping.sa-east-1.api.aws:7770`, como referência regional
AWS. Nenhuma linha abaixo autoriza substituir essa rota por host presumido.

| ID | Destino atual | Melhor classe possível conhecida | Situação de evidência para destino específico |
| --- | --- | --- | --- |
| `fortnite` | AWS São Paulo | referência regional | nenhum endpoint UDP público do título aprovado |
| `call-of-duty-mobile` | AWS São Paulo | referência regional | nenhum endpoint UDP público do título aprovado |
| `free-fire` | AWS São Paulo | referência regional | nenhum endpoint UDP público do título aprovado |
| `pubg-mobile` | AWS São Paulo | referência regional | nenhum endpoint UDP público do título aprovado |
| `brawl-stars` | AWS São Paulo | referência regional | nenhum endpoint UDP público do título aprovado |
| `wild-rift` | AWS São Paulo | referência regional | nenhum endpoint UDP público do título aprovado |
| `roblox` | AWS São Paulo | referência regional | instância é dinâmica; nenhum host fixo aprovado |
| `minecraft` | AWS São Paulo | PlayFab QoS regional, se houver host publicado | não há hostname QoS de título aprovado no catálogo |
| `apex-legends` | AWS São Paulo | referência regional | nenhum endpoint UDP público do título aprovado |
| `blood-strike` | AWS São Paulo | referência regional | nenhum endpoint UDP público do título aprovado |
| `cs2` | AWS São Paulo | Steam A2S dedicado | falta host/porta A2S curado e resposta real revisada |
| `dota2` | AWS São Paulo | referência regional | nenhum endpoint UDP público do título aprovado |
| `eafc` | AWS São Paulo | referência regional | nenhum endpoint UDP público do título aprovado |
| `league-of-legends` | AWS São Paulo | referência regional | nenhum endpoint UDP público do título aprovado |
| `palworld` | AWS São Paulo | Steam A2S dedicado | falta host/porta A2S curado e resposta real revisada |
| `rainbow-six` | AWS São Paulo | PlayFab QoS regional, se houver host publicado | não há hostname QoS de título aprovado no catálogo |
| `rocket-league` | AWS São Paulo | referência regional | nenhum endpoint UDP público do título aprovado |
| `rust` | AWS São Paulo | Steam A2S dedicado | falta host/porta A2S curado e resposta real revisada |
| `valorant` | AWS São Paulo | referência regional | nenhum endpoint UDP público do título aprovado |
| `warzone` | AWS São Paulo | referência regional | nenhum endpoint UDP público do título aprovado |

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
