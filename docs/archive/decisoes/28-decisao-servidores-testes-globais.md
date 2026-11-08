# LagCheck — decisão 28: servidores de teste a nível global (AWS GameLift) e seleção hierárquica por continente

**Status:** decisão aprovada pelo dono do produto (Luiz); em especificação e implementação  
**Data:** 18 de setembro de 2026  
**Autores / Revisores:** Luiz (Dono do Produto), Marco (Produto), Iury (Rede), Renan (Design), Rian (iOS)  
**Complementa:** `docs/01-funcional.md`, `docs/02-arquitetura.md`, `docs/03-especificacao-tecnica.md`, `docs/07-voz-do-produto.md`, `docs/archive/decisoes/14-decisao-catalogo-remoto-debug.md`, `docs/archive/decisoes/16-decisao-selecao-regional-automatica.md`, `docs/archive/decisoes/24-decisao-adocao-design-system-apple-games.md`, `docs/archive/decisoes/25-decisao-marca-lagcheck-coral-solar.md`

---

## 1. Contexto e Decisão do Produto

O Dono do Produto (Luiz) autorizou a ampliação da capacidade de teste do LagCheck para cobrir servidores de teste a nível global em todos os continentes habitados, estabelecendo três diretrizes inegociáveis:
1. **Escopo Global:** Cobertura de todas as regiões consolidadas de infraestrutura de jogos multiplayer pelo mundo.
2. **Formato de UI em Configurações:** Adoção de um **Menu nativo do SwiftUI com submenus por continente** (Américas, Europa, Ásia & Pacífico, Oriente Médio & África), mantendo a opção *"Automática (Mais rápida)"* no topo.
3. **Identidade Visual e Rótulo Amigável (Sem Códigos Técnicos):** Na rota e chip do globo, **não exibir o nome técnico do servidor ou código de região** (proibido expor `sa-east-1`, `us-east-1` ou `gamelift-ping...` como identificador primário ao jogador). Exibir estritamente o nome amigável e localizado da cidade/região (ex.: *"São Paulo"*, *"Virgínia do Norte"*, *"Frankfurt"*, *"Tóquio"*).

---

## 2. Infraestrutura de Rede e Custo Zero (Parecer de Iury)

Para cumprir a restrição inegociável de **custo operacional recorrente zero** e garantir medições determinísticas com datagramas UDP reais (sem fallbacks ICMP ou HTTP), adotamos a malha de **UDP Ping Beacons da AWS GameLift**:
* **Protocolo:** UDP bidirecional com eco monotônico no destino.
* **Porta:** `7770`.
* **Tamanho de pacote:** $< 300\text{ bytes}$.
* **Taxa de envio do app:** 1 probe por segundo por candidato (abaixo do teto AWS de 3 TPS por IP/porta).
* **Classificação de precisão:** Mantida como `genericRegion` / `medium` / `regionalReference` (estimativa da rota até a infraestrutura regional de referência, sem prometer ping interno do jogo).

### Mapeamento dos 21 Servidores Globais

| Continente | Código Técnico | Nome Amigável (PT-BR) | Nome Amigável (EN) | Endpoint UDP (Porta 7770) |
| :--- | :--- | :--- | :--- | :--- |
| **Américas** | `sa-east-1` | São Paulo | São Paulo | `gamelift-ping.sa-east-1.api.aws` |
| **Américas** | `us-east-1` | Virgínia do Norte | N. Virginia | `gamelift-ping.us-east-1.api.aws` |
| **Américas** | `us-east-2` | Ohio | Ohio | `gamelift-ping.us-east-2.api.aws` |
| **Américas** | `us-west-1` | Norte da Califórnia | N. California | `gamelift-ping.us-west-1.api.aws` |
| **Américas** | `us-west-2` | Oregon | Oregon | `gamelift-ping.us-west-2.api.aws` |
| **Américas** | `ca-central-1` | Canadá Central | Central Canada | `gamelift-ping.ca-central-1.api.aws` |
| **Europa** | `eu-central-1` | Frankfurt | Frankfurt | `gamelift-ping.eu-central-1.api.aws` |
| **Europa** | `eu-west-1` | Irlanda | Ireland | `gamelift-ping.eu-west-1.api.aws` |
| **Europa** | `eu-west-2` | Londres | London | `gamelift-ping.eu-west-2.api.aws` |
| **Europa** | `eu-west-3` | Paris | Paris | `gamelift-ping.eu-west-3.api.aws` |
| **Europa** | `eu-north-1` | Estocolmo | Stockholm | `gamelift-ping.eu-north-1.api.aws` |
| **Europa** | `eu-south-1` | Milão | Milan | `gamelift-ping.eu-south-1.api.aws` |
| **Ásia & Pacífico** | `ap-northeast-1` | Tóquio | Tokyo | `gamelift-ping.ap-northeast-1.api.aws` |
| **Ásia & Pacífico** | `ap-northeast-2` | Seul | Seoul | `gamelift-ping.ap-northeast-2.api.aws` |
| **Ásia & Pacífico** | `ap-northeast-3` | Osaka | Osaka | `gamelift-ping.ap-northeast-3.api.aws` |
| **Ásia & Pacífico** | `ap-southeast-1` | Cingapura | Singapore | `gamelift-ping.ap-southeast-1.api.aws` |
| **Ásia & Pacífico** | `ap-southeast-2` | Sydney | Sydney | `gamelift-ping.ap-southeast-2.api.aws` |
| **Ásia & Pacífico** | `ap-south-1` | Mumbai | Mumbai | `gamelift-ping.ap-south-1.api.aws` |
| **Ásia & Pacífico** | `ap-east-1` | Hong Kong | Hong Kong | `gamelift-ping.ap-east-1.api.aws` |
| **Oriente Médio & África** | `me-south-1` | Bahrein | Bahrain | `gamelift-ping.me-south-1.api.aws` |
| **Oriente Médio & África** | `af-south-1` | Cidade do Cabo | Cape Town | `gamelift-ping.af-south-1.api.aws` |

---

## 3. Projeto de Interface e UX (Parecer de Renan)

1. **Menu Hierárquico em Configurações:**
   - O controle `Menu` em `SettingsView` utiliza submenus nativos do SwiftUI organizados pelos quatro agrupamentos continentais.
   - O item selecionado exibe o ícone de checkmark nativo (`checkmark`).
   - A linha de sumário em Configurações exibe apenas o nome limpo da cidade/região (ex: *"Virgínia do Norte"* ou *"São Paulo"*).
2. **Apresentação em Telas de Medição e Resultado:**
   - Na tela de resultado do Quick Check e nos detalhes do jogo, o subtítulo de rota apresenta o formato *"Nome da Região · região de referência"* (ex.: *"Virgínia do Norte · região de referência"*), sem códigos técnicos como `us-east-1` ou hosts de infraestrutura.
3. **Acessibilidade:**
   - Todos os botões do menu cumprem o alvo de toque de 44 pt e suportam leitores de tela VoiceOver com rótulos semânticos.

---

## 4. Arquitetura de Software e Resolução (Parecer de Rian)

1. **`GlobalProbeRegistry` (`NolaggyDomain`):**
   - Criação da enumeração e registros estáticos canônicos com a lista das 21 regiões globais e seus agrupamentos continentais.
2. **`RemoteCatalogVerifier` (`NolaggyDomain`):**
   - Evolução de `validateDebugPayloadBusinessRules` para aceitar qualquer subconjunto das regiões homologadas em `GlobalProbeRegistry`, mantendo total retrocompatibilidade com envelopes mono-região (schema 1) e liberando envelopes multi-região (schema 2).
3. **`CatalogMeasurementJourney` (`NolaggyApplication`):**
   - Suporte à inclusão e resolução de candidatos regionais do registro global em coordenação com as preferências manuais salvas no repositório persistente.
4. **`Localizable.strings`:**
   - Chaves de localização para os nomes amigáveis em português (PT-BR) e inglês (EN).
