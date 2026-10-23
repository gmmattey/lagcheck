# Steam A2S e descoberta automática legítima — CS2 e Rust

Pesquisa concluída em 19 de setembro de 2026. Escopo: rotas próprias de servidores dedicados comunitários para CS2 e Rust; não cobre o matchmaking privado/oficial de cada publicadora.

## Existe uma fonte oficial/pública adequada para descoberta automática no iPhone sem chave ou SDK Steam?

### Takeaway

Não há uma fonte oficialmente documentada que o LagCheck possa chamar diretamente de um iPhone, sem Steamworks/SDK e sem credenciais, para obter a lista global de servidores. A descoberta oficial é parte do Steamworks `ISteamMatchmakingServers`; a alternativa de Web API documentada administra contas de servidores e exige chave. Portanto, a arquitetura correta não é consultar o master server pelo app: é publicar no catálogo assinado apenas candidatos previamente autorizados por operadores (ou fornecidos por uma integração formal com a publicadora), e o iPhone somente validar e medir esses poucos candidatos.

### Cited Findings

- A própria Valve diz que o browser unificado de servidores é a experiência de servidor Steam e que os mesmos dados são acessados pelas funções de `ISteamMatchmakingServers`. [Source](https://partner.steamgames.com/doc/features/multiplayer/game_servers?l=english)
- `RequestInternetServerList(AppId_t, filters, callback)` solicita uma lista de servidores da lista “internet”; a interface exige objetos de callback e ciclo de vida explícito de requisição. [Source](https://partner.steamgames.com/doc/api/ISteamMatchmakingServers?l=english)
- A visão geral do Steamworks documenta suporte oficial do SDK em C++ para Windows, macOS e SteamOS/Linux; não documenta iOS como plataforma de integração do SDK. [Source](https://partner.steamgames.com/doc/sdk/api)
- A Web API documentada `IGameServersService` é administrativa: os métodos listados tratam contas e tokens de logon de game server, e exigem uma chave de autenticação Steamworks. [Source](https://partner.steamgames.com/doc/webapi/IGameServersService)
- A referência oficial de `IGameServersService` documenta apenas operações administrativas de conta/token e resoluções por IP/SteamID; ela não documenta uma operação de listagem global de servidores públicos. [Source](https://partner.steamgames.com/doc/webapi/IGameServersService)
- No Rust, `server.queryport` é especificamente a porta usada para que serviços consultem o servidor e para ele aparecer no browser; desde a alteração de 2 de fevereiro de 2023 ela é distinta da porta de jogo e, se não configurada, pode variar conforme a porta de jogo/RCON. [Source](https://wiki.facepunch.com/rust/Creating-a-server)
- A documentação do Rust mostra que o operador pode deliberadamente bloquear a query port para impedir descoberta no master server e em listagens de Rust. [Source](https://wiki.facepunch.com/rust/Creating_a_hidden_whitelisted_server)

### Inferences

- “Público no browser” não equivale a autorização para o LagCheck fazer do servidor um alvo recorrente para toda a base. A solução defensável é opt-in verificável do operador, com domínio/SteamID/contato e limite de tráfego aceitos, antes de colocar o IP no catálogo assinado. Isto respeita que a query port pode ser deliberadamente privada. [Source](https://wiki.facepunch.com/rust/Creating_a_hidden_whitelisted_server)
- Um diretório público de terceiros pode ser usado apenas como pista humana de prospecção, nunca como fonte de verdade, porque não é a API oficial e pode estar desatualizado, alterar termos ou listar servidores sem consentimento.
- Para CS2/Rust, descoberta automática para o jogador deve significar: selecionar automaticamente entre no máximo 2–3 candidatos opt-in já aprovados para o jogo/plataforma/região. Não significa fazer crawling do master server, nem varrer CIDRs, nem chamar endpoint não documentado.

### Gaps

- Não encontrei documentação pública da Valve que conceda a um aplicativo terceiro, sem relação com o AppID do jogo, autorização explícita para consultar programaticamente a lista global de servidores ou redistribuir seus endereços. Essa autorização precisa vir da Valve/publicadora ou dos operadores candidatos.
- A documentação pública não estabelece SLA, quota ou política de rate limit para uma consulta A2S por milhões de clientes. Por isso os limites precisam ser assumidos pelo LagCheck e acordados com operadores, não inferidos.

## O que um cliente A2S_INFO robusto precisa implementar, e o que a medição pode provar?

### Takeaway

O cliente atual não pode tratar uma resposta simples como A2S completo. Para validar um candidato, ele precisa implementar o desafio opcional pós-2020, reassemblagem de datagramas split, descompressão/CRC quando marcado, parsing estrito com limites e correlação ao endpoint consultado. A2S_INFO prova que aquele endpoint UDP respondeu ao protocolo de consulta e declara uma identidade; não prova que ele será o servidor de matchmaking da próxima partida nem que o ping de query é igual ao ping de gameplay.

### Cited Findings

- `PingServer` no Steamworks consulta diretamente um IP/porta e devolve ping e detalhes atualizados; também há caminho explícito de falha de resposta. [Source](https://partner.steamgames.com/doc/api/ISteamMatchmakingServers?l=english)
- O anúncio técnico da Valve de dezembro de 2020 descreve que A2S_INFO pode exigir challenge; um cliente deve reenviar a consulta com o challenge recebido. [Source](https://steamcommunity.com/discussions/forum/14/2974028351344359625/)
- A mesma orientação da Valve registra o payload moderno `Source Engine Query` e testes com `STEAM_GAMESERVER_A2S_INFO_REQUIRE_CHALLENGE=1`, criado para endurecer a consulta contra amplificação/reflexão. [Source](https://steamcommunity.com/discussions/forum/14/2974028351344359625/)
- A referência de implementação independente ValvePython trata challenge de A2S_INFO, respostas multipacote, bit de compressão, bzip2, tamanho descomprimido e CRC32; isto é evidência secundária de interoperabilidade, não especificação oficial da Valve. [Source](https://github.com/ValvePython/steam/blob/master/steam/game_servers.py)
- Outra implementação independente enumera no A2S_INFO os campos de identidade relevantes: nome, mapa, diretório do jogo, descrição, AppID, jogadores, password/VAC, versão e EDFs opcionais, incluindo porta, SteamID, tags e GameID. Também é fonte secundária. [Source](https://github.com/rumblefrog/go-a2s/blob/master/info.go)
- A documentação do Rust confirma que query port e game port não podem ser a mesma porta e ambos precisam estar acessíveis por UDP quando o servidor quer aparecer/ser consultável. [Source](https://wiki.facepunch.com/rust/Creating-a-server)
- A documentação da Valve descreve Steam Datagram Relay como rede que pode retransmitir tráfego de jogo e ocultar IPs, e afirma que conexões P2P podem ser retransmitidas pela backbone Valve quando apropriado. [Source](https://partner.steamgames.com/doc/features/multiplayer/networking?l=english)

### Inferences

- Contrato mínimo do driver `steamA2S`: (1) resolver hostname apenas do candidato assinado; (2) enviar INFO moderno; (3) aceitar somente resposta do mesmo IP:porta; (4) se `S2C_CHALLENGE`, reenviar uma única vez com o nonce; (5) reassemblar apenas fragmentos com mesmo request-id, total e timeout; (6) se comprimido, impor teto pequeno de bytes, descomprimir bzip2 e verificar CRC/tamanho; (7) fazer parsing limitado de strings/listas e rejeitar bytes excedentes ou campos obrigatórios ausentes; (8) validar AppID/GameID, game directory e allowlist de nome/tags do operador; (9) descartar qualquer ambiguidade como inconclusiva. Os itens de split/CRC derivam de implementação secundária e devem ser confirmados contra capturas de servidores autorizados antes de release. [Source](https://github.com/ValvePython/steam/blob/master/steam/game_servers.py)
- Não enviar A2S_PLAYER nem A2S_RULES como parte do LagCheck. Não são necessários para identidade/RTT, aumentam superfície de abuso e podem revelar nomes/configuração de jogadores; `PlayerDetails` existe para recuperar lista de jogadores, o que não atende o propósito do app. [Source](https://partner.steamgames.com/doc/api/ISteamMatchmakingServers?l=english)
- Para RTT/perda, usar um número pequeno de transações A2S_INFO válidas (cada uma inclui challenge quando exigido), com espaçamento e orçamento temporal fixos. RTT mede ida-e-volta do iPhone à query port; perda é a proporção de transações sem resposta válida dentro da janela. Isso não mede a rota até uma sessão real de CS2/Rust, tick rate, congestionamento no game socket nem tráfego via relay. [Source](https://partner.steamgames.com/doc/features/multiplayer/networking?l=english)
- Um `AppID`/GameID declarado pelo endpoint é sinal de compatibilidade, não prova de propriedade. Só a combinação com registro de operador autorizado, chave de identidade estável (SteamID quando presente), hostname controlado e revalidação contínua permite nomear a rota como “servidor comunitário de CS2/Rust”.

### Gaps

- A página canônica da Valve Developer Community sobre Server Queries respondeu 403 ao pesquisador; por isso challenge, split/compressão e formato detalhado acima se apoiam no post de Valve no Steam Community e em implementações independentes, que precisam de teste de contrato contra CS2/Rust autorizados.
- Não encontrei uma garantia oficial de que CS2 competitivo oficial expose A2S_INFO nem uma forma pública de correlacionar uma partida oficial ao IP/porta. O LagCheck não deve prometer isso.

## Quais gates tornam um candidato ativo, e servidor dedicado controlado é um fallback viável a custo zero?

### Takeaway

Um candidato só vira ativo após autorização do operador, identidade A2S compatível, repetibilidade e validação no iPhone em Wi‑Fi e móvel. Um dedicado controlado pode ser excelente bancada de homologação e rota comunitária opt-in se rodar em hardware já disponível, mas não é fallback do jogo oficial e não preserva custo recorrente zero se exigir VPS, IP dedicado, DDoS protection ou operação contínua paga.

### Cited Findings

- A Valve caracteriza servidores dedicados como adequados para jogos competitivos ou servidores persistentes, podendo ser hospedados pelo próprio desenvolvedor ou pela comunidade. [Source](https://partner.steamgames.com/doc/features/multiplayer/game_servers?l=english)
- A Valve documenta que um servidor dedicado distribuído pelo Steam pode ser executado em modo anônimo via SteamCMD quando seu dono/publicadora o habilita. [Source](https://partner.steamgames.com/doc/sdk/uploading/distributing_gs?l=english)
- Facepunch informa que Rust Dedicated pode ser instalado/atualizado por SteamCMD e que não é necessária conta Steam para instalar/rodar o servidor, embora seja necessária uma conta com Rust para jogar. [Source](https://wiki.facepunch.com/rust/Creating-a-server)
- A orientação oficial de Rust para servidor oculto recomenda ambiente dedicado e proteção DDoS, e explica que a query port torna informações do servidor descobríveis para Steam e aplicações de terceiros. [Source](https://wiki.facepunch.com/rust/Creating_a_hidden_whitelisted_server)
- A Valve permite que um game server seja marcado privado, caso em que ele não deve aparecer no master server. [Source](https://partner.steamgames.com/doc/api/isteamgameserver)

### Inferences

- Gate de cadastro: autorização escrita do operador (nome, domínio/controlador, jogos/portas, permissões de medição e limite de tráfego); confirmação de que o endpoint é público para query e não é uma rota de jogador privada; e identificação administrativa revisável.
- Gate técnico pré-ativo: A2S_INFO com challenge (quando solicitado) em capturas independentes; endpoint/porta resolvidos do hostname permitido; identidade esperada por jogo (`AppID`/GameID, game directory, nome/tags acordados, SteamID se disponível); resposta não comprimida e comprimida testadas quando o servidor puder fornecê-las; e nenhum redirecionamento, destino alternativo ou resposta de IP/porta diferente.
- Gate de qualidade: executar medições repetidas em horários diferentes, registrar taxa de respostas válidas e aplicar expiração curta ao candidato; em falha ou alteração de identidade, rebaixar para pendente e usar AWS. A rota só será “própria” enquanto a evidência atual for válida.
- Gate de produto: no resultado, dizer “servidor comunitário de CS2/Rust na região X” e mostrar o operador; nunca “servidor oficial da sua partida” sem integração da publicadora. Se todos candidatos falharem, rotular AWS como “rota de referência”, não como servidor do jogo.
- Gate físico: validar no iPhone real em Wi‑Fi e rede móvel, incluindo troca de rede/background, IPv4/IPv6 quando aplicável, NAT/CGNAT, timeout, consumo de dados e cancelamento. Simulador e UDP do ambiente de desenvolvimento não equivalem a essa validação.
- Um dedicado CS2/Rust controlado é viável como bancada de protocolo e como rota comunitária separada se houver máquina e conexão já custeadas. Não é “fallback” do matchmaking oficial: mede a rota ao servidor controlado, não a infraestrutura de Valve/Facepunch ou a partida escolhida pelo jogo. Caso demande hospedagem contínua, IP público ou DDoS pago, viola a restrição de custo zero e exige decisão de produto.

### Gaps

- A viabilidade operacional específica de um dedicado CS2 precisa ser confirmada com a documentação/artefato atual da Valve para CS2 e teste em servidor autorizado; a documentação Steamworks encontrada explica a plataforma de dedicated servers de modo genérico, não promete que todo AppID de terceiro seja instalável/operável pelo LagCheck. [Source](https://partner.steamgames.com/doc/sdk/uploading/distributing_gs?l=english)
- Não há evidência nesta pesquisa de que um candidato público existente aceite o volume agregado de consultas do LagCheck. Não ativar nenhum candidato até o opt-in do operador e a homologação em iPhone real.
