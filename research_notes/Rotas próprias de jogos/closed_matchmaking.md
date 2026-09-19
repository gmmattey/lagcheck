# Rotas próprias de jogos com matchmaking fechado

## 1. O que existe publicamente — e o que não vira uma rota de jogo

### Takeaway

Há apenas um caminho oficial público diretamente aproveitável hoje: os hosts de diagnóstico ICMP que a Epic publica para sub-regiões de Fortnite. Eles não são uma sonda UDP de gameplay. APIs públicas de Riot, PUBG e PlayFab são APIs de dados/QoS autenticadas; não autorizam LagCheck a descobrir, reproduzir ou testar um servidor de partida de um título de terceiros.

### Cited Findings

- A Epic publica `ping-sao.ds.on.epicgames.com` e hosts equivalentes por sub-região para teste de conectividade de Fortnite, mas instrui o uso de `ping`/ICMP; a própria Epic diz que o gameplay usa UDP e que ICMP pode receber prioridade diferente. Portanto este host só pode aparecer como diagnóstico oficial ICMP separado, jamais alimentar score de gameplay UDP. — [Epic: Fortnite latency and ping troubleshooting](https://www.epicgames.com/help/c-34254770/c-38015632/a22355516)
- O endpoint PlayFab `ListQosServersForTitle` lista servidores QoS de **um título** e exige `X-EntityToken`; os tipos aceitos de token são `title_player_account` e `title`. A própria referência documenta erros de acesso não habilitado, proibido e não autorizado. — [Microsoft: List QoS Servers for Title](https://learn.microsoft.com/en-us/rest/api/playfab/multiplayer/multiplayer-server/list-qos-servers-for-title?view=playfab-rest)
- O portal Riot permite produto público somente com chave de produção aprovada; a chave de desenvolvimento expira em 24 horas e a pessoal não pode servir produto público. Para VALORANT, a documentação exibida cobre identidade via RSO e catálogo de conteúdo, não um endpoint de datacenter/matchmaking. — [Riot Developer Portal](https://developer.riotgames.com/docs/portal); [VALORANT official APIs](https://developer.riotgames.com/docs/valorant)
- As APIs oficiais de PUBG documentam jogadores, partidas, estatísticas, leaderboards e telemetria; a chave deve ficar em servidor seguro, não no cliente. A documentação consultada não expõe descoberta de servidor de partida ou uma sonda de rede. — [PUBG API documentation](https://documentation.pubg.com/en/index.html); [PUBG API keys](https://documentation.pubg.com/en/api-keys.html)
- A EA orienta a verificar ping e perda no display interno de Apex e escolher o datacenter dentro do próprio jogo; a página de status expõe estado do serviço, não endereço/protocolo de uma sessão para terceiros. — [EA: Apex ping and packet loss](https://help.ea.com/en/articles/apex-legends/troubleshoot-ping-packet-loss-lag/); [EA Server Status](https://help.ea.com/en/server-status/)
- Activision publica estado operacional e fluxo de suporte; o material oficial localizado não documenta API pública de destino de partida ou beacon de QoS para Call of Duty/Warzone. — [Activision Online Services](https://support.activision.com/onlineservices)
- Ubisoft descreve infraestrutura e regiões de Rainbow Six Siege, além de métricas e ícones dentro do jogo; o material oficial localizado não documenta endpoint/protocolo público para uma sonda externa. — [Ubisoft: Siege status report](https://www.ubisoft.com/en-us/game/rainbow-six/siege/news-updates/HyDyYTuRkWtyYQ3WDFeEL)
- A documentação pública de PUBG é para dados de jogo e sua licença condiciona a emissão de chave a registro e outros documentos que a empresa pode exigir. Isso não deve ser confundido com PUBG Mobile: os materiais consultados não demonstram que a API de PUBG: Battlegrounds cobre o jogo mobile. — [PUBG Developer API terms](https://developer.pubg.com/tos?locale=en)

### Inferences

- Classes a manter como **"integração própria pendente de acordo"**: Fortnite (para UDP), League of Legends, VALORANT, Wild Rift, Apex Legends, EA SPORTS FC, Call of Duty/Warzone, Free Fire, PUBG Mobile, Brawl Stars, Roblox, Rainbow Six Siege/Mobile e Rocket League/Sideswipe. Não foi encontrada, nas fontes oficiais consultadas, uma API pública que entregue a um terceiro o endpoint/protocolo de uma sessão desses jogos.
- PlayFab somente pode virar rota própria se a publicadora titular conceder a LagCheck credencial de título adequada ou um contrato de QoS equivalente. Uma chave/conta do LagCheck não serve para listar servidores de outro título.
- Não tratar API de dados (Riot/PUBG), status operacional (EA/Activision) ou hostname ICMP (Epic) como permissão para UDP. Fazer isso criaria uma promessa técnica maior que a evidência.

### Gaps

- Não há fonte oficial pública encontrada que exponha contratos de probe para Garena/Free Fire, Supercell/Brawl Stars, Roblox geral, Psyonix/Rocket League ou PUBG Mobile. A ausência na pesquisa não prova inexistência; prova que LagCheck não tem um contrato público verificável para ativar.
- Não foram pesquisados SDKs sob NDA, portais de parceiros nem contratos comerciais. Eles podem existir, mas são precisamente o caminho que exige autorização escrita da publicadora.

## 2. Caminho correto para uma rota própria e pacote de integração

### Takeaway

Para matchmaking fechado, a solução correta não é automatizar descoberta de IP nem observar tráfego do jogo. É a publicadora fornecer um beacon/contrato de QoS deliberadamente separado da sessão, com permissão, protocolo e escopo definidos; o iPhone mede diretamente somente esse alvo autorizado e o catálogo assinado seleciona-o.

### Cited Findings

- O contrato PlayFab requer token de entidade e retorna QoS servers conforme as builds implantadas no título; isso é evidência de que o dono do título controla a enumeração e a autorização de QoS. — [Microsoft: List QoS Servers for Title](https://learn.microsoft.com/en-us/rest/api/playfab/multiplayer/multiplayer-server/list-qos-servers-for-title?view=playfab-rest)
- A Riot exige proposta/registro para chave de produção e determina que uma chave seja protegida; a política proíbe incluir chave no código distribuído. — [Riot Developer Portal](https://developer.riotgames.com/docs/portal); [Riot General Policies](https://developer.riotgames.com/policies/general)
- A PUBG também determina que a chave nunca fique no cliente e que chamadas partam de aplicação servidor segura. — [PUBG API keys](https://documentation.pubg.com/en/api-keys.html)
- A Apple exige APIs públicas e proíbe baixar, instalar ou executar código que introduza/mude recursos do app. Configuração remota assinada pode fornecer **dados** declarativos, mas não pode entregar driver/protocolo executável novo. — [Apple App Review Guidelines 2.5.1–2.5.3](https://developer.apple.com/app-store/review/guidelines/uk/)

### Inferences

- Proposta operacional por publicadora: (1) cadastrar LagCheck como parceiro/desenvolvedor; (2) solicitar um "QoS probe contract", não acesso a matchmaking; (3) receber endpoints regionais dedicados, protocolo de eco versionado, autenticação curta por app/device se necessária, limites de taxa e janela de validade; (4) validar em ambiente sandbox/produção com casos de erro; (5) só então publicar a configuração assinada.
- O protocolo de probe deve ser independente de login de jogador, de ticket de matchmaking e do tráfego de uma partida. Nada de proxy, captura de pacote, engenharia reversa, scraping de endpoints, varredura de faixa, ou credencial embutida no app.
- O app precisa trazer todos os drivers no binário. O catálogo remoto pode escolher `driverID` previamente implementado, hostnames permitidos, portas, TTL, versão de regra e thresholds por plataforma; ele não pode enviar script, bytecode ou uma especificação arbitrária que o app passe a executar.

### Proposed integration packet

- **Pacote que LagCheck deve enviar à publicadora (proposta, não contrato de terceiros):**
  - `product`: nome, URL pública, responsável e identificador do bundle iOS.
  - `purpose`: diagnóstico pré-partida de rota até infraestrutura de referência; declaração explícita de que não prevê servidor exato da sessão nem coleta credenciais/telemetria da partida.
  - `requested_contract`: `probeId`, regiões/plataformas cobertas, FQDNs allowlisted, porta/protocolo de echo, formato da resposta, como validar autenticidade, TTL, limites por dispositivo/IP e regra de retirada.
  - `privacy`: mínimos dados enviados (nonce aleatório e timestamp), sem ID de conta, sem IP persistido, sem payload de jogo; retenção e contato de privacidade.
  - `security`: sem SDK privado, sem engenharia reversa, sem scanning, sem chaves no cliente; rotação/revogação por catálogo assinado e kill switch local.
  - `validation`: matriz iPhone Wi-Fi/móvel, sucesso/falha/time-out, taxa de amostra, regra `Inconclusive` sem UDP válido e plano de monitoramento com a publicadora.
  - `commercial/legal`: pedido de autorização escrita para usar o nome do jogo apenas como identificador e para descrever a rota como "infraestrutura de referência oficial"; nunca usar selo/endosso sem autorização.

### Gaps

- O modelo de token, porta e formato de echo não pode ser padronizado unilateralmente por LagCheck; cada publicadora deve aprová-lo. PlayFab/Riot/PUBG mostram que tokens e chaves têm governança própria. — [Microsoft PlayFab](https://learn.microsoft.com/en-us/rest/api/playfab/multiplayer/multiplayer-server/list-qos-servers-for-title?view=playfab-rest); [Riot policies](https://developer.riotgames.com/policies/general); [PUBG API keys](https://documentation.pubg.com/en/api-keys.html)

## 3. Comportamento do catálogo e da interface enquanto não houver contrato

### Takeaway

Todo jogo pode continuar mensurável pelo fallback AWS, mas esse resultado precisa assumir explicitamente o papel de rota de referência. O catálogo não deve promover rota própria pendente para ativa, nem mostrar uma qualidade de multiplayer como se tivesse alcançado o datacenter daquele jogo.

### Cited Findings

- A Epic declara que seus hosts publicados medem caminho a um datacenter de sub-região, que experiências podem usar datacenters diferentes, e que o teste ICMP não elimina problema no caminho UDP de gameplay. — [Epic: Fortnite latency and ping troubleshooting](https://www.epicgames.com/help/c-34254770/c-38015632/a22355516)
- A EA reconhece que o datacenter efetivo e suas condições importam e orienta o usuário a selecionar o datacenter no jogo; isso sustenta a separação entre uma referência externa e a sessão real. — [EA: Apex ping and packet loss](https://help.ea.com/en/articles/apex-legends/troubleshoot-ping-packet-loss-lag/)
- A Apple permite uso de APIs públicas, mas exige que a funcionalidade executada exista no binário; é compatível com catálogo remoto assinado contendo dados e incompatível com habilitar um novo protocolo executável por configuração. — [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/uk/)

### Inferences

- Estados de catálogo recomendados: `officialProbeActive` somente após autorização e validação física; `officialProbePending` para acordo/protocolo em andamento; `officialDiagnosticOnly` para Fortnite ICMP, fora do score UDP; `referenceFallbackActive` para AWS; `inconclusive` quando nem o probe autorizado nem a referência produzem UDP válido.
- Copy resolvida: “Rota de referência na região selecionada” para AWS; “Infraestrutura de referência oficial” apenas para beacon disponibilizado/permitido pela publicadora; “Diagnóstico oficial de conectividade (ICMP)” para os hosts Epic, em cartão separado e sem nota de jogo. Nunca “servidor do jogo” ou “seu ping na partida” sem contrato de sessão.
- A seleção automática deve consultar somente candidatos assinados, allowlisted e já validados pelo driver local. Falha de todos os candidatos próprios troca para AWS e registra a razão técnica; não tenta IPs novos nem altera a rota por dados não assinados.

### Gaps

- Antes de ativar qualquer candidato, faltam testes em iPhone físico em Wi-Fi e celular, evidência de resposta UDP válida do contrato autorizado e revisão de thresholds por plataforma. Nenhuma fonte de documentação substitui essa homologação.
