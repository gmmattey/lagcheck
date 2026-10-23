# Minecraft Bedrock/RakNet e Palworld — rotas próprias

## Minecraft Bedrock: ping RakNet, identidade e Realms

### Takeaway
Um servidor Bedrock dedicado autorizado pode ser medido diretamente por UDP com um *unconnected ping* RakNet, mas essa resposta prova disponibilidade e compatibilidade do protocolo — não prova, por si só, que o operador é oficial ou que será o Realm/matchmaking do jogador. Para Realms, não há rota pública documentada que o LagCheck possa descobrir ou consultar sem credencial/autorização do titular.

### Cited Findings
- O Bedrock Dedicated Server (BDS) é software oficial, gratuito, executa em Windows ou Ubuntu Linux e usa as portas configuradas em `server.properties`; os padrões documentados são UDP 19132 (IPv4) e 19133 (IPv6). A própria documentação manda conectar informando endereço e porta. — [Microsoft Learn: BDS getting started](https://learn.microsoft.com/en-us/minecraft/creator/documents/bedrockserver/getting-started?view=minecraft-bedrock-stable)
- O BDS permite definir `server-name` em `server.properties`; portanto, o nome retornado por um servidor é metadado configurável pelo operador, não um atestado de propriedade Mojang/Microsoft. — [Microsoft Learn: BDS configuration](https://learn.microsoft.com/en-us/minecraft/creator/documents/bedrockserver/getting-started?view=minecraft-bedrock-stable)
- A documentação oficial atual de Bedrock publica uma referência de protocolo versionada e declara que o protocolo muda entre releases; o guia de BDS alerta inclusive que mudanças menores e de patch podem incompatibilizar cliente e servidor. — [Mojang Bedrock Protocol Reference](https://mojang.github.io/bedrock-protocol-docs/1.26.60-preview.23/); [Microsoft Learn: BDS version compatibility](https://learn.microsoft.com/en-us/minecraft/creator/documents/bedrockserver/getting-started?view=minecraft-bedrock-stable)
- A estrutura exata do `UnconnectedPing` (`0x01`) e do `UnconnectedPong` (`0x1c`) usada na descoberta RakNet — timestamp ecoado, GUID do servidor, magic de 16 bytes e string `MCPE;...` com nome, versão, jogadores e portas — está documentada por projetos comunitários, não por uma página oficial de Mojang/Microsoft para esse pacote de descoberta. — [Bedrock Wiki: RakNet protocol](https://wiki.bedrock.dev/servers/raknet); [GolemOrg RakNet protocol](https://github.com/GolemOrg/RakNet/blob/master/PROTOCOL.md)
- O fluxo oficial para um servidor Bedrock que não aparece entre os destacados é obter endereço do administrador e adicioná-lo/conectar diretamente; não encontrei nos materiais oficiais pesquisados uma API pública de diretório para listar todos os servidores Bedrock nem um registro público equivalente a A2S. — [Minecraft: how to play on a server](https://www.minecraft.net/en-us/article/how-play-minecraft-server)
- A entrada oficial para Realm é `realmId`/convite, enquanto a entrada para mundo por endereço é separada e aceita `serverUrl`/`serverPort`; o mesmo material diz que parte do token de conexão não é documentada publicamente. Além disso, APIs de script de BDS explicitamente não valem para servidores de gameplay do Realms. — [Microsoft Learn: deep links](https://learn.microsoft.com/en-us/minecraft/creator/reference/content/deep-links?view=minecraft-bedrock-stable); [Microsoft Learn: BDS scripting](https://learn.microsoft.com/en-us/minecraft/creator/documents/bedrockserver/scripting?view=minecraft-bedrock-stable)

### Inferences
- Driver iOS viável para **BDS ou servidor Bedrock autorizado**: enviar apenas `UnconnectedPing` UDP para candidatos explicitamente assinados no catálogo; aceitar um `UnconnectedPong` somente se ecoar o nonce/timestamp enviado, contiver magic válido e passar parsing/limites. Medir RTT apenas com pares válidos. A string `MCPE` e a versão/protocolo devem ser armazenadas como evidência de compatibilidade, não como prova de propriedade.
- Para reduzir troca acidental de destino, o catálogo deve amarrar cada candidato a host/porta, operador aprovado, `server-name` esperado (normalizado), edição `MCPE`, faixa de versão suportada e, após homologação, GUID observado. GUID e nome são sinais de continuidade, não credenciais criptográficas; uma resposta divergente desqualifica o candidato e aciona AWS.
- A descoberta automática correta não é varrer a internet nem extrair a lista interna do cliente. É o app testar um conjunto pequeno, assinado e revisado de BDS/servidores comunitários que aceitaram participar, ordenado por mercado/região. A atualização dessa lista ocorre pelo catálogo remoto, sem nova versão do app.
- **Realms, featured servers e partida por convite** devem continuar em AWS como referência até Microsoft/Mojang fornecer um beacon/API autorizada por Realm ou por região. Um invite/`realmId` não autoriza o LagCheck a resolver ou sondar a infraestrutura privada.
- Gate para ativar Bedrock: implementar o parser isolado contra capturas autorizadas e BDS local; testar em iPhone físico em Wi-Fi e rede móvel; repetir contra cada candidato público; revalidar após atualização de protocolo Bedrock. Em timeout, pacote malformado, nome/GUID divergente ou versão não suportada: não scorear pela rota própria.

### Gaps
- Não encontrei especificação oficial do pacote RakNet de descoberta (ping/pong sem conexão) nem garantia pública de estabilidade para ele. A implementação depende de especificação comunitária, portanto exige fixture capturada de BDS oficial e gate de regressão por versão.
- Não encontrei API pública, sem credenciais, que devolva o IP/porta vigente de um Realm ou que associe de modo verificável um Realm a um usuário. Isso não prova que ela inexista em contratos privados; prova apenas que não é um caminho público suportado para o LagCheck hoje.

## Palworld: dedicado, comunidade e hipótese A2S

### Takeaway
Palworld oferece oficialmente servidor dedicado e comunidade por IP/porta, e pode registrar um dedicado na lista dentro do cliente. Porém, as fontes oficiais pesquisadas não documentam A2S, uma query port, nem uma API pública para baixar essa lista; por isso o LagCheck não pode classificar Palworld como `steamA2S` sem captura e homologação controlada do próprio PalServer.

### Cited Findings
- A documentação oficial da Pocketpair define dedicado como servidor acessado por endereço IP e porta; define comunidade como o mesmo dedicado registrado na lista do cliente. O produto informa suporte cruzado entre Steam, Xbox/Windows Store, macOS e PS5 nos servidores listados. — [Palworld Server Guide: about server](https://docs.palworldgame.com/getting-started/about-server/)
- A Pocketpair fornece o Palworld Dedicated Server oficialmente via Steam/SteamCMD, com instalação anônima do app 2394010 e execução de `PalServer.exe`/`PalServer.sh`. — [Palworld Server Guide: deploy dedicated server](https://docs.palworldgame.com/getting-started/deploy-dedicated-server/)
- O argumento documentado `-port=8211` altera a porta de escuta; `-publiclobby` registra como servidor de comunidade; `-publicip` e `-publicport` descrevem a rota pública, e a própria documentação frisa que `-publicport` não altera a porta de escuta. — [Palworld Server Guide: arguments](https://docs.palworldgame.com/settings-and-operation/arguments/)
- A configuração oficial inclui nome, descrição, IP/porta públicos, RCON e REST API como recursos de administração do servidor, mas não descreve protocolo público de consulta de status, query port A2S, formato de resposta A2S ou endpoint público de descoberta. — [Palworld Server Guide: configuration parameters](https://docs.palworldgame.com/settings-and-operation/configuration/)
- A Steamworks documenta que um **cliente Steamworks** pode pedir a lista de servidores de internet de um AppID e pingar IP/porta, e que servidores podem enviar heartbeats ao master server. Essa é documentação de integração Steamworks, não autorização para um app iOS terceiro consumir ou redistribuir a lista de Palworld. — [Steamworks: ISteamMatchmakingServers](https://partner.steamgames.com/doc/api/ISteamMatchmakingServers); [Steamworks: game servers](https://partner.steamgames.com/doc/features/multiplayer/game_servers)

### Inferences
- O fato de Palworld usar Steam/SteamCMD e ter servidor de comunidade **não prova A2S**. O protocolo correto só pode ser promovido para o catálogo depois de testar um PalServer controlado, capturar a interação documentada/permitida e confirmar que resposta UDP reproduzível identifica Palworld sem login/jogo. Até lá, `steamA2S` seria uma alegação técnica não sustentada.
- Para servidor Palworld autorizado, a seleção automática pode funcionar exatamente como o padrão de catálogo: candidatos assinados por região (host, porta de jogo, plataforma/versão, operador e prazo), probe direto do iPhone com um driver específico já homologado, e AWS se nenhum responder. O catálogo não deve usar a lista de comunidade como serviço de descoberta nem fazer varredura.
- `RCON` e REST API não são substitutos adequados ao probe de jogador: são interfaces administrativas opcionais, potencialmente autenticadas e não devem receber segredo nem ser abertas para o LagCheck. Elas podem, com autorização do operador, servir apenas para montar fixtures de laboratório.
- Gate Palworld: levantar PalServer oficial controlado, ativar explicitamente modo de comunidade se necessário, registrar portas reais e versão; capturar tráfego de uma consulta permitida; produzir parser/fixtures; validar no iPhone em duas redes e em candidato externo autorizado. Só então inserir `protocolKind` específico e candidatos ativos no catálogo.

### Gaps
- Não encontrei documentação oficial da Pocketpair que declare que PalServer responde A2S, qual é sua query port, qual AppID/identidade volta, ou que ofereça uma API pública/sem credencial para a lista de comunidade. A pesquisa não autoriza reutilizar A2S por associação com Steam.
- Não encontrei contrato público para um app externo consultar ou redistribuir a lista interna de servidores de comunidade. Se a Pocketpair oferecer integração de parceiro, ela precisa ser obtida e aprovada antes de automatizar descoberta fora do catálogo assinado.

## Validação controlada, custo e decisão de produto

### Takeaway
Um laboratório próprio é a forma correta de transformar os dois protocolos em evidência, sem scan e sem prometer rota oficial de matchmaking. Ele pode usar software gratuito, mas não cria infraestrutura de referência grátis para sempre: máquina, energia, banda, IP público/NAT e disponibilidade continuam sendo custos/limitações que precisam de dono explícito.

### Cited Findings
- BDS é distribuído gratuitamente e a Microsoft documenta sua execução em Windows/Ubuntu, exigindo liberar as portas configuradas no firewall para acesso externo. — [Microsoft Learn: BDS getting started](https://learn.microsoft.com/en-us/minecraft/creator/documents/bedrockserver/getting-started?view=minecraft-bedrock-stable)
- Palworld Dedicated Server é obtido por Steam ou SteamCMD e a própria Pocketpair documenta a execução em Windows e Linux. — [Palworld Server Guide: deploy dedicated server](https://docs.palworldgame.com/getting-started/deploy-dedicated-server/)
- BDS muda com versões de Minecraft, e a documentação oficial alerta que versões de patch também podem diferir no protocolo. — [Microsoft Learn: BDS version compatibility](https://learn.microsoft.com/en-us/minecraft/creator/documents/bedrockserver/getting-started?view=minecraft-bedrock-stable)

### Inferences
- Laboratório de custo operacional adicional zero para o LagCheck é possível **somente** se usar máquina, rede e licença já disponibilizadas pelo time/operador, por janela de homologação. Não deve virar endpoint público permanente nem entrar como candidato de produção; se depender de VM, IP dedicado, hospedagem ou manutenção contínua, deixa de atender a restrição sem nova decisão.
- Plano de laboratório: (1) BDS oficial e PalServer oficial em hosts controlados distintos; (2) registrar versão, argumentos, host/porta e owner; (3) capturar em rede local e remota as sequências de descoberta permitidas; (4) criar fixtures anonimizadas e testes negativos; (5) validar driver no iPhone físico Wi-Fi e móvel; (6) repetir após upgrade de cada jogo; (7) só então homologar candidatos de operadores externos por contrato e fallback AWS.
- O dado publicado pelo catálogo precisa ter validade curta, owner, protocolo explicitamente homologado, limites de tentativas e evidência de última validação. Quando expirar, mudar o candidato para pendente/inativo, nunca reutilizar a última resposta para gerar score.
- A promessa exibida ao usuário deve ser “rota do servidor selecionado” para servidor dedicado/comunitário e “região de referência” para AWS. Para Realms ou matchmaking, não há evidência suficiente para dizer que a rota é a partida dele.

### Gaps
- Não há ainda captura autorizada, fixture, iPhone físico ou operador externo homologado para BDS/PalServer; portanto nenhum protocolo novo deve ser marcado como ativo no catálogo nesta fase.
- A política de custo zero não responde quem proverá máquina/IP/banda se o laboratório precisar existir de modo contínuo. Isso requer decisão de produto antes de transformar laboratório em operação.
