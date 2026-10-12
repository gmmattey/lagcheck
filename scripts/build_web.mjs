import fs from 'node:fs';
import path from 'node:path';

const ROOT_DIR = process.cwd();
const WEB_DIR = path.join(ROOT_DIR, 'web');

// Script oficial do Web Analytics para paginas HTML estaticas.
const VERCEL_ANALYTICS_SCRIPT = [
  '  <script>window.va = window.va || function () { (window.vaq = window.vaq || []).push(arguments); };</script>',
  '  <script defer src="/_vercel/insights/script.js"></script>'
].join("\n");

function withVercelAnalytics(html) {
  if (!html.includes("</head>")) throw new Error("HTML without head");
  return html.replace("</head>", VERCEL_ANALYTICS_SCRIPT + "\n</head>");
}

const APP_STORE_URL = "https://apps.apple.com/br/app/lagcheck-teste-de-ping-gamer/id6818706960";
const LINKA_APP_STORE_URL = "https://apps.apple.com/app/id6808479321";
const SIGNALLQ_URL = "https://signallq.com";

export const GAMES = [
  {
    slug: "fortnite",
    name: "Fortnite",
    file: "fortnite",
    category: "br",
    categoryLabel: "Battle Royale",
    platforms: "iPhone · PC · PlayStation · Xbox · Switch",
    isMobileNative: false,
    infra: "aws",
    summary: "Battle Royale multiplataforma com construção e combate sincronizado para até 100 jogadores.",
    netProfile: "O Fortnite tem partidas com 100 jogadores e construção/combate acelerados. O matchmaking e as instâncias dependem de rotas em nuvem regional (AWS sa-east-1 em São Paulo).",
    lagSymptoms: [
      "Delay na colocação e edição de estruturas ('ghost building')",
      "Rubber-banding durante movimentação rápida, saltos e uso de tirolesas",
      "Disparos de espingarda ou submetralhadora sem registro de dano em confrontos próximos",
      "Picos repentinos de latência ao se aproximar de zonas povoadas no mapa"
    ],
    guidance: "Conecte o iPhone na mesma rede Wi-Fi (5 GHz) onde você joga para medir se o roteador está sofrendo com bufferbloat ou fila na operadora antes de puxar uma ranqueada.",
    faq: [
      {
        q: "Como o Lagcheck ajuda a saber se o Fortnite vai ter lag?",
        a: "O app envia pacotes UDP contínuos até o beacon regional AWS GameLift em São Paulo. Ele mede latência média, oscilação (jitter) e descarte de pacotes em repouso e sob carga, entregando um veredito direto."
      },
      {
        q: "O Lagcheck mede o servidor oficial da minha partida no Fortnite?",
        a: "Não. O app mede uma rota de referência regional comprovada (AWS GameLift sa-east-1). Se essa rota de saída ou seu roteador apresentarem instabilidade, sua partida certamente oscilará."
      },
      {
        q: "Posso testar no iPhone mesmo jogando no PC ou console?",
        a: "Sim. Como você compartilha o mesmo link de internet e roteador, o teste no iPhone serve como um indicador confiável da saúde da rede doméstica antes de você abrir o jogo no PC ou console."
      }
    ]
  },
  {
    slug: "free-fire",
    name: "Free Fire",
    file: "freefire",
    category: "br",
    categoryLabel: "Battle Royale",
    platforms: "iPhone (iOS nativo)",
    isMobileNative: true,
    infra: "mobile",
    summary: "Battle Royale mobile competitivo em tempo real com partidas dinâmicas no mesmo smartphone.",
    netProfile: "Como o jogo roda diretamente no iPhone, a qualidade do rádio Wi-Fi ou sinal de dados móveis (4G/5G) determina cada trocação. Servidores regionais com alta demanda de pacotes UDP.",
    lagSymptoms: [
      "Botão de tiro com atraso na resposta e mira grudando com atraso",
      "Dano não computado em trocações a curta distância ('hitmarker fantasma')",
      "Inimigos se teletransportando ou congelando durante a corrida",
      "Perda de conexão no meio da troca de safe zone"
    ],
    guidance: "Faça o check no iPhone antes de iniciar a partida ranqueada. Se o veredito indicar instabilidade no 4G/5G, migre para o Wi-Fi 5 GHz próximo ao roteador.",
    faq: [
      {
        q: "Por que o Free Fire trava mesmo com internet rápida?",
        a: "Velocidade de download não impede lag. No Free Fire, oscilações de 10 a 20 ms (jitter) ou perda de pacotes de 1% já causam atrasos fatais no registro de dano."
      },
      {
        q: "O teste do Lagcheck é feito no próprio aparelho onde jogo?",
        a: "Sim. O Lagcheck avalia a mesma interface de rede (Wi-Fi ou dados móveis) que o Free Fire utiliza no seu iPhone, oferecendo um diagnóstico preciso das condições do rádio."
      },
      {
        q: "O veredito diz se posso jogar ranqueada agora?",
        a: "Sim. O resultado classifica a conexão como 'Pronto para Ranked', 'Condições instáveis' ou 'Evitaria ranked agora', orientando sua decisão antes de perder pontos."
      }
    ]
  },
  {
    slug: "cod-mobile",
    name: "COD Mobile",
    file: "codm",
    category: "fps",
    categoryLabel: "FPS / Tático",
    platforms: "iPhone (iOS nativo)",
    isMobileNative: true,
    infra: "mobile",
    summary: "FPS mobile competitivo com modos multijogador acelerados e Battle Royale no iPhone.",
    netProfile: "Exige tempos de resposta extremamente baixos e consistência entre pacotes UDP para registro de acertos e alinhamento do hitbox em cantos de paredes.",
    lagSymptoms: [
      "Efeito de 'peeker's advantage' invertido: morrer antes de ver o inimigo sair da cobertura",
      "Tiros não computados em duelos frente a frente com fuzis de alta cadência",
      "Micro-travamentos na transição de mira holográfica e mira de precisão",
      "Atraso na ativação de Scorestreaks e operadores"
    ],
    guidance: "Execute o diagnóstico no iPhone conectado ao Wi-Fi 5 GHz para confirmar se há perda de pacotes antes de entrar nas filas ranqueadas de Multijogador ou Battle Royale.",
    faq: [
      {
        q: "Como o Lagcheck avalia a rota para o COD Mobile?",
        a: "O app envia sequências de pacotes UDP para a infraestrutura regional em São Paulo, simulando o tráfego do jogo sob repouso e sob carga concorrente de rede."
      },
      {
        q: "O que significa 'Condições instáveis' no veredito?",
        a: "Indica que foram detectadas oscilações de latência (jitter) ou perda de pacotes que podem prejudicar seu tempo de reação no COD Mobile. Vale aguardar ou reiniciar o roteador."
      },
      {
        q: "O check consome meus dados móveis?",
        a: "O check é leve e consome apenas o tráfego estritamente necessário para testar pacotes UDP e simular bufferbloat, durando apenas alguns segundos."
      }
    ]
  },
  {
    slug: "valorant",
    name: "Valorant",
    file: "valorant",
    category: "fps",
    categoryLabel: "FPS / Tático",
    platforms: "PC · PlayStation · Xbox",
    isMobileNative: false,
    infra: "riot",
    summary: "Tactical shooter competitivo 5v5 com servidores de 128-tick e infraestrutura Riot Direct.",
    netProfile: "O Valorant requer precisão de sub-milissegundos com tickrate de 128 Hz. Oscilações mínimas de latência quebram a consistência do disparo e a precisão em duelos de mira (first bullet accuracy).",
    lagSymptoms: [
      "Headshots aparentes que não contam no primeiro disparo em cantos abertos",
      "Inconsistência no recuo das armas por perda de sincronia de pacotes",
      "Modelos de personagens deslizando ou surgindo bruscamente de trás de fumaças",
      "Ícones de rede (jitter/packet loss) acesos no canto superior direito da tela"
    ],
    guidance: "Como o Valorant roda no PC ou console, execute o Lagcheck no iPhone na mesma rede para verificar se o roteador doméstico ou a operadora estão sofrendo com congestionamento de rota antes da fila competitiva.",
    faq: [
      {
        q: "O Lagcheck mede o servidor oficial da Riot Games no Valorant?",
        a: "O Valorant opera em rede fechada da Riot Games. O Lagcheck avalia a rota de referência UDP regional em São Paulo (sa-east-1). Se a sua conexão doméstica apresentar jitter ou perda no teste, o Valorant também sofrerá."
      },
      {
        q: "Se meu PC usa cabo Ethernet, o teste no iPhone ainda vale?",
        a: "Sim. O teste no iPhone mostra se o seu modem/provedor de internet está com rota oscilando ou com bufferbloat na saída para os datacenters de São Paulo, o que afeta tanto Wi-Fi quanto cabo."
      },
      {
        q: "O que o veredito 'Pronto para Ranked' garante?",
        a: "Garante que na medição determinística recente não foram identificados jitter elevado, descarte de pacotes ou degradação sob carga concorrente."
      }
    ]
  },
  {
    slug: "counter-strike-2",
    name: "Counter-Strike 2",
    file: "cs2",
    category: "fps",
    categoryLabel: "FPS / Tático",
    platforms: "PC (Steam / Valve)",
    isMobileNative: false,
    infra: "valve",
    summary: "FPS tático da Valve com arquitetura sub-tick e servidores oficiais dedicados em São Paulo.",
    netProfile: "O Counter-Strike 2 adota a tecnologia de sub-tick e a infraestrutura Steam Datagram Relay (SDR) da Valve com datacenters em São Paulo. Perda de pacotes e jitter quebram a precisão de tiros e movimentação.",
    lagSymptoms: [
      "Perda de comandos de recoil e spray em duelos decisivos de rifles",
      "Tagging desincronizado: seu boneco congela com atraso ao ser alvejado",
      "Micro-teleportes ao esbarrar em companheiros de equipe em corredores estreitos",
      "Granadas que rebatem com física atrasada em quinas de portas e janelas"
    ],
    guidance: "Rode o Lagcheck no seu iPhone no Wi-Fi da casa para aferir a qualidade da sua conexão antes de abrir a fila Premier ou Competitiva no CS2.",
    faq: [
      {
        q: "O Lagcheck se conecta aos servidores da Valve no CS2?",
        a: "O teste mede a rota UDP de referência até os principais centros de servidores de jogos em São Paulo. A Valve opera sua rede SDR em São Paulo, tornando a medição um indicador confiável da qualidade de tráfego regional."
      },
      {
        q: "Por que o CS2 parece lagado mesmo quando o ping marca 20 ms?",
        a: "Porque ping baixo não significa estabilidade. Jitter e perda de pacotes afetam diretamente o registro do sub-tick do CS2, criando a sensação de balas que somem no ar."
      },
      {
        q: "O app é compatível com jogadores de PC?",
        a: "Sim. O app é um utilitário de bolso para iPhone que analisa a saúde da sua rede doméstica e operadora antes de você abrir o PC."
      }
    ]
  },
  {
    slug: "apex-legends",
    name: "Apex Legends",
    file: "apexlegends",
    category: "br",
    categoryLabel: "Battle Royale",
    platforms: "PC · PlayStation · Xbox · Switch",
    isMobileNative: false,
    infra: "ea",
    summary: "Battle Royale rápido com movimentação dinâmica, tirolesas e combate em ritmo acelerado.",
    netProfile: "O Apex Legends exige transmissão intensa de pacotes UDP devido à velocidade de slide, saltos e habilidades táticas de lendas. A EA hospeda suas instâncias em datacenters em São Paulo.",
    lagSymptoms: [
      "Efeito 'no-reg': som característico do tiro acertando a blindagem, mas sem causar dano",
      "Ícones vermelhos de predição e desync piscando no canto da tela",
      "Atraso ao abrir portas, cápsulas de suprimento ou trocar de armadura",
      "Movimentação em câmera lenta no início da partida em áreas com muitos esquadrões"
    ],
    guidance: "Verifique no Lagcheck se a sua rota em repouso e sob carga concorrente mantém estabilidade antes de jogar partidas ranqueadas no Apex.",
    faq: [
      {
        q: "O Lagcheck identifica bufferbloat para Apex Legends?",
        a: "Sim. Durante a medição sob carga, o app avalia se o ping dispara quando outros dispositivos da sua casa utilizam a conexão, prevenindo quedas no meio do combate."
      },
      {
        q: "O app promete zero lag no Apex?",
        a: "Nunca prometemos zero lag. O Lagcheck entrega um diagnóstico factual e honesto com base em medições reais para você decidir com segurança."
      },
      {
        q: "Como interpretar o jitter medido?",
        a: "Jitter abaixo de 3–4 ms indica estabilidade excelente. Acima de 8–10 ms, a oscilação já prejudica armas automáticas de alta cadência como a R-99."
      }
    ]
  },
  {
    slug: "league-of-legends",
    name: "League of Legends",
    file: "leagueoflegends",
    category: "moba",
    categoryLabel: "MOBA",
    platforms: "PC (Riot Games)",
    isMobileNative: false,
    infra: "riot",
    summary: "MOBA competitivo onde teamfights e reações em fração de segundo definem a vitória no Rift.",
    netProfile: "O LoL utiliza a infraestrutura Riot Direct com servidores em São Paulo. Requer estabilidade absoluta nos pacotes UDP para garantir que cliques de movimentação e skillshots ocorram sem atraso.",
    lagSymptoms: [
      "Atraso aparente no clique de movimentação ('input delay')",
      "Skillshots disparadas na direção correta que saem com frações de segundo de atraso",
      "Congelamento súbito de personagens em teamfights com muitas partículas na tela",
      "Flash ou Zhonya não acionando no instante exato da conjuração"
    ],
    guidance: "Antes de entrar na fila Solo/Duo no PC, faça um check rápido no iPhone para certificar-se de que a rota até São Paulo está limpa e sem oscilações na operadora.",
    faq: [
      {
        q: "Por que fazer o check antes da fila de LoL?",
        a: "Porque uma partida de LoL dura mais de 30 minutos e custa pontos de PDL. Saber se a rota está instável antes da seleção de campeões evita frustrações desnecessárias."
      },
      {
        q: "O teste mede a rota do meu provedor de internet?",
        a: "Sim. O iPhone analisa a rota UDP saindo da sua rede local até os pontos de interconexão em São Paulo, revelando se a sua operadora está sofrendo congestionamento."
      },
      {
        q: "O resultado ajuda a identificar problemas no Wi-Fi?",
        a: "Sim. A comparação entre repouso e carga aponta se o roteador está enfileirando pacotes de forma inadequada."
      }
    ]
  },
  {
    slug: "wild-rift",
    name: "Wild Rift",
    file: "wildrift",
    category: "moba",
    categoryLabel: "MOBA",
    platforms: "iPhone (iOS nativo)",
    isMobileNative: true,
    infra: "mobile",
    summary: "O MOBA da Riot Games adaptado com controles táteis velozes para o ecossistema iOS.",
    netProfile: "Partidas no próprio iPhone com controle contínuo via joystick virtual e botões táteis. Sensível a variações de latência na antena Wi-Fi e dados móveis.",
    lagSymptoms: [
      "Indicador de ping in-game saltando de verde para amarelo/vermelho em teamfights",
      "Atraso ao direcionar habilidades em linha reta com joystick virtual",
      "Personagem continuando a andar em linha reta em direção à torre inimiga",
      "Tentativa de reconexão automática no momento de disputa de Barão ou Dragão"
    ],
    guidance: "Abra o Lagcheck no iPhone momentos antes de buscar partida no Wild Rift. Se a rota estiver instável, aproxime-se do roteador ou aguarde a estabilização.",
    faq: [
      {
        q: "Como o Lagcheck mede o ping do Wild Rift no iPhone?",
        a: "Ele utiliza sockets UDP nativos no próprio iOS para enviar e receber pacotes determinísticos, medindo a qualidade de transmissão sem depender de testes genéricos de navegador."
      },
      {
        q: "O teste substitui o indicador de ping interno do jogo?",
        a: "O Lagcheck é preventivo: ele mede antes de você entrar na fila ranqueada, evitando que você descubra a instabilidade somente depois que a partida já começou."
      },
      {
        q: "O app é gratuito no iPhone?",
        a: "Sim, 100% gratuito na App Store e sem necessidade de criar conta ou fazer login."
      }
    ]
  },
  {
    slug: "rocket-league",
    name: "Rocket League",
    file: "rocketleague",
    category: "casual",
    categoryLabel: "Esportes / Físico",
    platforms: "PC · PlayStation · Xbox · Switch",
    isMobileNative: false,
    infra: "epic",
    summary: "Futebol acrobático com carros em física de simulação calculada em tempo real no servidor.",
    netProfile: "O Rocket League processa física contínua no servidor. Jitter ou perda de pacotes geram correção visual imediata pelo cliente, fazendo a bola ou os carros desviarem inesperadamente.",
    lagSymptoms: [
      "Bola 'fantasma' que parece mudar de direção no ar após ser rebatida por outro carro",
      "Colisões de carros desajustadas em disputas aéreas e no kick-off inicial",
      "Ícones triangulares vermelhos de variação de latência e perda de pacotes na tela",
      "Carro saindo do chão e caindo de volta bruscamente ao coletar boost de 100%"
    ],
    guidance: "Faça o check no iPhone para checar o nível de jitter na sua rede antes de disputar partidas competitivas no Rocket League.",
    faq: [
      {
        q: "Por que o Rocket League sofre tanto com pequenas oscilações de ping?",
        a: "Porque a trajetória da bola e dos veículos é simulada a 120 Hz no servidor. Qualquer pacote atrasado força o cliente a corrigir a posição dos objetos, causando o famoso desvio fantasma."
      },
      {
        q: "O Lagcheck avalia a perda de pacotes?",
        a: "Sim. O app mede a porcentagem exata de pacotes UDP descartados na rota de referência regional em São Paulo."
      },
      {
        q: "Posso confiar no veredito?",
        a: "O veredito é determinístico e derivado de regras transparentes: se houver perda ou jitter alto, ele indicará 'Condições instáveis' ou que evitaria ranked."
      }
    ]
  },
  {
    slug: "roblox",
    name: "Roblox",
    file: "roblox",
    category: "casual",
    categoryLabel: "Sandbox / Criação",
    platforms: "iPhone · PC · PlayStation · Xbox",
    isMobileNative: false,
    infra: "roblox",
    summary: "Plataforma de criação e jogos multijogador com instâncias dinâmicas hospedadas na nuvem.",
    netProfile: "Cada experiência no Roblox aloca instâncias dinâmicas em servidores em nuvem. A qualidade de conexão varia de acordo com a rota de saída da sua operadora.",
    lagSymptoms: [
      "Personagens travando no chão ou flutuando sem animação de caminhada",
      "Atraso de vários segundos ao interagir com portas, lojas e itens do inventário",
      "Desconexões repentinas com o código de erro 279 ou 267",
      "Falta de sincronia em minigames competitivos de corrida e obstáculos (Obby)"
    ],
    guidance: "Utilize o Lagcheck no iPhone para saber se a sua conexão está operando com baixa latência e sem perda de pacotes antes de iniciar sua sessão no Roblox.",
    faq: [
      {
        q: "O Roblox possui servidor fixo para teste?",
        a: "No Roblox, cada experiência aloca instâncias dinâmicas. O Lagcheck mede a rota de saída regional até datacenters de referência em São Paulo para certificar a estabilidade da sua internet."
      },
      {
        q: "O app funciona tanto para quem joga no iPhone quanto no PC?",
        a: "Sim. Se você joga no iPhone, o teste é direto. Se joga no PC ou console, serve como indicador da integridade da sua rede doméstica."
      },
      {
        q: "O teste exige cadastro?",
        a: "Não. Você baixa na App Store e faz o check diretamente sem fornecer nenhum dado pessoal."
      }
    ]
  },
  {
    slug: "minecraft",
    name: "Minecraft",
    file: "minecraft",
    category: "casual",
    categoryLabel: "Sandbox / Sobrevivência",
    platforms: "iPhone · PC · PlayStation · Xbox · Switch",
    isMobileNative: false,
    infra: "dedicated",
    summary: "Multijogador cooperativo, servidores comunitários e Realms de sobrevivência e minigames.",
    netProfile: "No Minecraft multiplayer, as partidas ocorrem em Realms ou servidores dedicados da comunidade. A instabilidade causa dessincronização de blocos, inventário e combate com mobs.",
    lagSymptoms: [
      "Blocos minerados que reaparecem instantaneamente na sua frente ('ghost blocks')",
      "Atraso perceptível ao abrir baús, fornalhas e mesas de trabalho",
      "Mobs e outros jogadores se teletransportando ou atacando à distância",
      "Dano de queda aplicado segundos após a descida, causando mortes inesperadas"
    ],
    guidance: "Rode o check no iPhone para averiguar se a sua rota doméstica está estável antes de explorar o Nether ou entrar em minigames de servidores da comunidade.",
    faq: [
      {
        q: "Como o Lagcheck ajuda no Minecraft se os servidores são comunitários?",
        a: "Mesmo que os servidores de Minecraft sejam variados, o gargalo comum quase sempre está na sua rota de saída ou no Wi-Fi. O Lagcheck avalia a qualidade da sua rede local e da conexão regional."
      },
      {
        q: "O teste mede combate de tiro?",
        a: "Não. O Lagcheck avalia pacotes UDP puros, latência e jitter — métricas que no Minecraft evitam blocos fantasmas e atrasos de sincronização."
      },
      {
        q: "É gratuito?",
        a: "Sim, o app é gratuito na App Store para iPhone."
      }
    ]
  },
  {
    slug: "brawl-stars",
    name: "Brawl Stars",
    file: "brawlstars",
    category: "moba",
    categoryLabel: "Ação / MOBA Mobile",
    platforms: "iPhone (iOS nativo)",
    isMobileNative: true,
    infra: "mobile",
    summary: "Batalhas 3v3 de ação rápida da Supercell onde cada segundo de atraso define o controle da partida.",
    netProfile: "Partidas de 2 a 3 minutos direto no iPhone. O protocolo em tempo real da Supercell é extremamente intolerante a micro-quedas e variações de sinal.",
    lagSymptoms: [
      "Ícone vermelho de Wi-Fi pulsando no meio da tela no momento mais crítico",
      "Super ou ataque principal saindo com atraso de meio segundo após o toque",
      "Brawler deslizando sem controle em direção ao fogo cruzado inimigo",
      "Golpes de brawlers corpo a corpo que parecem acertar antes da animação"
    ],
    guidance: "Abra o Lagcheck no iPhone antes de iniciar sua sequência de troféus. O diagnóstico leva poucos segundos e previne perdas de partidas por causa do Wi-Fi.",
    faq: [
      {
        q: "Por que o Brawl Stars exibe o ícone vermelho de Wi-Fi?",
        a: "O ícone aparece quando há perda de pacotes ou o jitter supera a tolerância do motor da Supercell. O Lagcheck mede essas mesmas variáveis antes de você entrar na fila."
      },
      {
        q: "O check funciona em dados móveis 4G/5G?",
        a: "Sim, você pode testar tanto sua rede Wi-Fi quanto sua conexão de dados móveis no iPhone."
      },
      {
        q: "O veredito é honesto?",
        a: "Sim. Se houver instabilidade observada, o app diz explicitamente que evitaria ranked agora."
      }
    ]
  },
  {
    slug: "warzone",
    name: "Warzone",
    file: "warzone",
    category: "br",
    categoryLabel: "Battle Royale",
    platforms: "PC · PlayStation · Xbox",
    isMobileNative: false,
    infra: "aws",
    summary: "Battle Royale massivo em grande escala com intenso tráfego de dados e tiroteios decisivos no Gulag.",
    netProfile: "Tráfego UDP intenso e contínuo para sincronizar dezenas de jogadores, veículos e contratos em mapas abertos. Datacenters regionais em São Paulo.",
    lagSymptoms: [
      "Gulag perdido por desync de milissegundos na trocação de pistolas",
      "Paraquedas não abrindo a tempo por atraso de registro de comando",
      "Congelamento súbito de tela ao abrir caixas de armamento (loadout drops)",
      "Marcadores de perda de pacotes em cascata no canto superior esquerdo"
    ],
    guidance: "Use o Lagcheck no iPhone na rede doméstica antes de juntar o esquadrão no PC ou console para garantir que o modem não está com bufferbloat.",
    faq: [
      {
        q: "Como o Lagcheck avalia a rota do Warzone?",
        a: "O app mede a rota UDP até a infraestrutura de referência regional em São Paulo, simulando condições de repouso e estresse de banda."
      },
      {
        q: "O resultado reflete o jogo no console ou PC?",
        a: "Sim, como você divide a mesma conexão de internet e roteador, problemas de operadora e jitter afetam todos os aparelhos da residência."
      },
      {
        q: "Preciso pagar pelo app?",
        a: "Não. O Lagcheck é gratuito na App Store."
      }
    ]
  },
  {
    slug: "pubg-mobile",
    name: "PUBG Mobile",
    file: "pubg",
    category: "br",
    categoryLabel: "Battle Royale",
    platforms: "iPhone (iOS nativo)",
    isMobileNative: true,
    infra: "mobile",
    summary: "Battle Royale tático mobile com balística realista e mapas extensos no iPhone.",
    netProfile: "Como opera nativamente no smartphone, a estabilidade da antena Wi-Fi e a consistência da torre de celular são vitais para a física de disparos e veículos.",
    lagSymptoms: [
      "Dano tardio recebido após já ter entrado completamente atrás de uma parede",
      "Veículos com direção travada ou batendo em obstáculos invisíveis",
      "Itens de caixas de suprimento demorando segundos para entrar na mochila",
      "Mira telescópica (4x/8x) com movimentação engasgada durante a puxada"
    ],
    guidance: "Faça o check no iPhone antes de iniciar a partida. Se o veredito sugerir cautela, aguarde ou troque de rede para não prejudicar seu ranking.",
    faq: [
      {
        q: "O check ajuda no PUBG Mobile?",
        a: "Com certeza. Como você joga no iPhone, o Lagcheck analisa exatamente a mesma interface de rede que o jogo usará."
      },
      {
        q: "Qual a diferença entre Speedtest e Lagcheck para PUBG Mobile?",
        a: "Speedtest mede quantos megabits você pode baixar. O Lagcheck mede se os pacotes de tiro chegam a tempo e sem oscilação."
      },
      {
        q: "O app coleta dados pessoais?",
        a: "Não coletamos dados pessoais nem exigimos login. Política de privacidade estrita e armazenamento local no iPhone."
      }
    ]
  },
  {
    slug: "blood-strike",
    name: "Blood Strike",
    file: "bloodstrike",
    category: "br",
    categoryLabel: "Battle Royale / FPS",
    platforms: "iPhone · PC",
    isMobileNative: true,
    infra: "mobile",
    summary: "FPS Battle Royale ultrarrápido focado em mobilidade, corrida tática e parkour.",
    netProfile: "Movimentação em alta velocidade onde o slide-cancel e trocações verticais exigem sincronização imediata entre cliente e servidor.",
    lagSymptoms: [
      "Falha na execução de corrida tática e deslizamento por atraso de pacotes",
      "Dano atrasado em combates cara a cara com submetralhadoras",
      "Dessincronia no momento de respawn aéreo na partida",
      "Congelamento súbito ao ativar habilidades ativas dos agentes"
    ],
    guidance: "Execute o diagnóstico no seu iPhone para validar se a conexão está pronta para suportar a velocidade de movimentação do Blood Strike.",
    faq: [
      {
        q: "O que o teste avalia para o Blood Strike?",
        a: "Latência média, variação de milissegundos (jitter) e descarte de pacotes sob tráfego UDP em São Paulo."
      },
      {
        q: "Posso testar se jogo no PC?",
        a: "Sim. O iPhone na mesma rede ajuda a identificar se há problemas no modem ou na operadora."
      },
      {
        q: "Quanto tempo dura o teste?",
        a: "Leva apenas alguns segundos para emitir um veredito conclusivo."
      }
    ]
  },
  {
    slug: "dota-2",
    name: "Dota 2",
    file: "dota2",
    category: "moba",
    categoryLabel: "MOBA",
    platforms: "PC (Valve)",
    isMobileNative: false,
    infra: "valve",
    summary: "MOBA de altíssima complexidade estratégica da Valve em servidores dedicados em São Paulo.",
    netProfile: "Utiliza servidores da Valve no Brasil com roteamento Steam Datagram Relay. Exige consistência de milissegundos para cancelar animações e conjurar habilidades críticas.",
    lagSymptoms: [
      "Atraso no cancelamento de animações de ataque básico (backswing)",
      "Itens de ativação imediata como Black King Bar ou Blink Dagger falhando no timing",
      "Skillshots massivas (Black Hole, Chronosphere) conjuradas com delay fatal",
      "Perda de last hits em creeps por dessincronia no projétil de ataque à distância"
    ],
    guidance: "Consulte o Lagcheck no iPhone antes de iniciar sua partida ranqueada no PC para averiguar a estabilidade da rota da sua internet.",
    faq: [
      {
        q: "O Dota 2 roda nos servidores da Valve em São Paulo?",
        a: "Sim. A Valve possui infraestrutura em São Paulo. O Lagcheck mede a rota de referência UDP regional para diagnosticar a estabilidade do enlace."
      },
      {
        q: "Por que medir antes da partida?",
        a: "Partidas de Dota 2 costumam passar de 40 minutos. Evitar uma partida instável previne quedas, frustração e penalidades de abandono."
      },
      {
        q: "O app é seguro?",
        a: "Totalmente seguro, oficial na App Store e sem anúncios."
      }
    ]
  },
  {
    slug: "ea-sports-fc",
    name: "EA Sports FC",
    file: "eafc",
    category: "casual",
    categoryLabel: "Futebol / Esportes",
    platforms: "iPhone · PC · PlayStation · Xbox · Switch",
    isMobileNative: false,
    infra: "ea",
    summary: "Simulador de futebol competitivo com servidores dedicados para modos online e Ultimate Team.",
    netProfile: "Os modos online operam em servidores dedicados da EA. A oscilação na rota causa o temido 'heavy gameplay', onde os comandos respondem com lentidão.",
    lagSymptoms: [
      "Sensação de 'jogadores pesados' que demoram para girar o corpo com a bola ('heavy gameplay')",
      "Atraso entre apertar o botão de passe/chute e a execução do jogador",
      "Divididas e botes de marcação que ocorrem fora de tempo",
      "Ícone circular de perda de conexão da EA piscando na parte superior da tela"
    ],
    guidance: "Verifique o veredito no Lagcheck antes de iniciar sua rodada da Weekend League ou Division Rivals no PC/console para certificar-se de que a conexão está leve.",
    faq: [
      {
        q: "O Lagcheck detecta o que causa o 'heavy gameplay' no EA Sports FC?",
        a: "O heavy gameplay é frequentemente provocado por jitter e bufferbloat na rota até os servidores da EA. O Lagcheck mede exatamente essas métricas."
      },
      {
        q: "O teste mede no iPhone para console?",
        a: "Sim. O iPhone na sua rede doméstica avalia a qualidade da rota do provedor, revelando se a rede está sofrendo com engarrafamento de dados."
      },
      {
        q: "Como o app é classificado na App Store?",
        a: "Disponível gratuitamente para iOS 17 ou superior."
      }
    ]
  },
  {
    slug: "palworld",
    name: "Palworld",
    file: "palworld",
    category: "casual",
    categoryLabel: "Sobrevivência / Co-op",
    platforms: "PC · Xbox",
    isMobileNative: false,
    infra: "dedicated",
    summary: "Sobrevivência multiplayer com captura de criaturas e construção de bases em mundo aberto.",
    netProfile: "Partidas em servidores dedicados ou cooperativo direto. Grande quantidade de entidades e construções sincronizadas pela rede simultaneamente.",
    lagSymptoms: [
      "Pals parados sem responder a comandos de trabalho ou combate",
      "Atraso no arremesso e registro de captura de esferas",
      "Dessincronia na física de construção de estruturas de base",
      "Inimigos em masmorras se teletransportando durante ataques"
    ],
    guidance: "Confira o status de estabilidade no Lagcheck antes de entrar no servidor dedicado com amigos para evitar perda de itens por desconexão.",
    faq: [
      {
        q: "Como o app avalia conexões para Palworld?",
        a: "Ele mede a qualidade do tráfego UDP em direção aos nós centrais de servidores em São Paulo, indicando a saúde geral da sua rede."
      },
      {
        q: "Preciso de conta para usar?",
        a: "Não, o Lagcheck não exige contas, logins nem assinaturas."
      },
      {
        q: "O teste é rápido?",
        a: "Sim, medição completa em poucos segundos no iPhone."
      }
    ]
  },
  {
    slug: "rainbow-six-siege",
    name: "Rainbow Six Siege",
    file: "rainbowsix",
    category: "fps",
    categoryLabel: "FPS / Tático",
    platforms: "PC · PlayStation · Xbox",
    isMobileNative: false,
    infra: "aws",
    summary: "FPS tático da Ubisoft onde destruição de cenários e linhas de visão exigem conexão sólida.",
    netProfile: "A precisão dos ângulos de visão através de frestas e paredes destruídas não tolera jitter. Servidores dedicados regionais com alto volume de validações de física.",
    lagSymptoms: [
      "Rubber-banding ao passar por brechas abertas na parede ou janelas barricadas",
      "Morrer antes mesmo do operador inimigo aparecer no ângulo da câmera",
      "Atraso ao ativar o desarmador ou usar gadgets táticos",
      "Ícones amarelos e vermelhos de conexão no canto inferior direito da tela"
    ],
    guidance: "Faça o check no iPhone no Wi-Fi antes de começar sua partida ranqueada no PC ou console para saber se a operadora está oscilando.",
    faq: [
      {
        q: "O que o teste do Lagcheck mede para o Rainbow Six?",
        a: "Latência UDP, estabilidade de milissegundos e descarte de pacotes até os datacenters de referência de São Paulo."
      },
      {
        q: "O resultado diz se devo jogar ranqueada?",
        a: "Sim. O veredito semântico diz com clareza se as condições estão recomendadas ou se o melhor é evitar a ranked no momento."
      },
      {
        q: "Funciona em qualquer iPhone com iOS 17?",
        a: "Sim, projetado nativamente para iOS 17 ou superior."
      }
    ]
  },
  {
    slug: "rust",
    name: "Rust",
    file: "rust",
    category: "casual",
    categoryLabel: "Sobrevivência PvP",
    platforms: "PC · PlayStation · Xbox",
    isMobileNative: false,
    infra: "dedicated",
    summary: "Sobrevivência PvP hardcore onde perder um tiroteio por lag significa perder horas de saque.",
    netProfile: "Servidores dedicados de alta população com milhares de construções e tiros calculados por balística. Perda de pacotes resulta em invalidação de tiros.",
    lagSymptoms: [
      "Mensagens de 'projectile invalid' no console de combate ao acertar tiros em inimigos",
      "Delay ao abrir portas, trancas de código e caixas de inventário",
      "Congelamento súbito durante trocas de tiros com armas automáticas como AK-47",
      "Teleportes ao descer de cavalos, minicopters ou barcos em alta velocidade"
    ],
    guidance: "Confira seu status no Lagcheck no iPhone antes de sair da base para um raid ou confronto no Rust.",
    faq: [
      {
        q: "Por que 'projectile invalid' acontece no Rust?",
        a: "Quando há atraso de pacotes (jitter ou ping elevado), o servidor rejeita o tiro porque na linha do tempo do servidor o inimigo já se moveu. O Lagcheck mede essas variações."
      },
      {
        q: "O teste mede o servidor específico do Rust onde jogo?",
        a: "Ele mede a rota de referência regional em São Paulo, indicando se sua operadora e rede local estão operando de forma estável."
      },
      {
        q: "O app é gratuito?",
        a: "Sim, 100% gratuito e sem publicidade."
      }
    ]
  }
];

function getRouteText(infra) {
  const base = "O Lagcheck mede a rota UDP até beacons de referência de infraestrutura em São Paulo (sa-east-1).";
  if (infra === "valve") return "A Valve utiliza a infraestrutura Steam Datagram Relay (SDR) e servidores oficiais em São Paulo. " + base;
  if (infra === "riot") return "A Riot Games opera em rede própria (Riot Direct) e nuvem regional. " + base;
  if (infra === "ea") return "A EA Sports e Respawn hospedam instâncias de jogos em datacenters em São Paulo. " + base;
  if (infra === "mobile") return "O jogo roda nativamente no mesmo smartphone. O app mede a rota UDP direta no aparelho. " + base;
  if (infra === "dedicated") return "Neste jogo as partidas operam em servidores comunitários ou dedicados. " + base;
  if (infra === "roblox") return "No Roblox, cada experiência aloca instâncias dinâmicas na nuvem. " + base;
  return "Muitos títulos competitivos rodam sobre a infraestrutura da AWS. " + base;
}

const COMMON_CSS = `
:root {
  --bg: #0B0D10;
  --bg-surface-1: #15181E;
  --bg-surface-2: #1E232B;
  --border-subtle: rgba(255, 255, 255, 0.08);
  --border-hover: rgba(124, 58, 237, 0.45);
  --text-primary: #F3F4F6;
  --text-secondary: #9CA3AF;
  --text-muted: #6B7280;
  --brand-purple: #7C3AED;
  --brand-purple-hover: #9055FF;
  --brand-purple-glow: rgba(124, 58, 237, 0.25);
  --accent-solar: #FF5A36;
  --status-ready: #10B981;
  --status-ready-bg: rgba(16, 185, 129, 0.12);
  --status-caution: #F59E0B;
  --status-caution-bg: rgba(245, 158, 11, 0.12);
  --status-unstable: #FF5A36;
  --status-unstable-bg: rgba(255, 90, 54, 0.12);
  --font-sans: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
  --font-mono: ui-monospace, 'SF Mono', Menlo, Consolas, monospace;
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

html {
  background: var(--bg);
  color: var(--text-primary);
  font-family: var(--font-sans);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  scroll-behavior: smooth;
  text-size-adjust: 100%;
}

body {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  line-height: 1.5;
  background: var(--bg);
  overflow-x: hidden;
}

a {
  color: inherit;
  text-decoration: none;
  transition: color 0.15s ease, opacity 0.15s ease;
}

a:hover {
  color: var(--brand-purple-hover);
}

img {
  max-width: 100%;
  height: auto;
  display: block;
}

/* Acessibilidade: Skip Link */
.skip-link {
  position: absolute;
  top: -100px;
  left: 20px;
  background: var(--brand-purple);
  color: #fff;
  padding: 12px 20px;
  border-radius: 8px;
  font-weight: 700;
  z-index: 999;
  transition: top 0.2s ease;
}

.skip-link:focus {
  top: 20px;
}

/* Foco visível WCAG */
:focus-visible {
  outline: 2px solid var(--brand-purple);
  outline-offset: 3px;
}

/* HEADER COMPACTO & NAVEGAÇÃO RESPONSIVA */
.site-header {
  position: sticky;
  top: 0;
  z-index: 100;
  background: rgba(11, 13, 16, 0.88);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border-bottom: 1px solid var(--border-subtle);
}

.header-inner {
  max-width: 1200px;
  margin: 0 auto;
  padding: 14px 22px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.brand-link {
  display: flex;
  align-items: center;
  flex-shrink: 0;
}

.brand-logo {
  width: 124px;
  height: auto;
}

.desktop-nav {
  display: flex;
  align-items: center;
  gap: 28px;
  font-size: 14px;
  font-weight: 500;
  color: var(--text-secondary);
}

.desktop-nav a {
  padding: 6px 0;
  position: relative;
}

.desktop-nav a:hover,
.desktop-nav a.active {
  color: var(--text-primary);
}

.desktop-nav a.active::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 2px;
  background: var(--brand-purple);
  border-radius: 2px;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.btn-header-cta {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 9px 18px;
  border-radius: 999px;
  background: var(--brand-purple);
  color: #fff;
  font-size: 13px;
  font-weight: 700;
  transition: transform 0.15s ease, background 0.15s ease;
  white-space: nowrap;
}

.btn-header-cta:hover {
  background: var(--brand-purple-hover);
  color: #fff;
  transform: translateY(-1px);
}

/* BOTÃO MENU HAMBÚRGUER (MOBILE) */
.mobile-menu-btn {
  display: none;
  background: transparent;
  border: 1px solid var(--border-subtle);
  border-radius: 10px;
  width: 44px;
  height: 44px;
  cursor: pointer;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  gap: 5px;
  padding: 10px;
}

.menu-bar {
  width: 20px;
  height: 2px;
  background: var(--text-primary);
  border-radius: 2px;
  transition: transform 0.25s ease, opacity 0.25s ease;
}

/* DRAWER / OVERLAY MOBILE */
.mobile-nav-drawer {
  display: none;
  position: fixed;
  top: 73px;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(11, 13, 16, 0.98);
  backdrop-filter: blur(24px);
  -webkit-backdrop-filter: blur(24px);
  z-index: 99;
  padding: 24px;
  overflow-y: auto;
  border-top: 1px solid var(--border-subtle);
  flex-direction: column;
  justify-content: space-between;
}

.mobile-nav-drawer.open {
  display: flex;
}

.mobile-nav-links {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.mobile-link {
  font-size: 18px;
  font-weight: 600;
  color: var(--text-secondary);
  padding: 10px 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.mobile-link:hover {
  color: #fff;
}

.mobile-nav-footer {
  margin-top: 32px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.btn-mobile-download {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;
  border-radius: 14px;
  background: var(--brand-purple);
  color: #fff;
  font-weight: 700;
  font-size: 16px;
  text-align: center;
}

.mobile-nav-subtext {
  font-size: 12px;
  color: var(--text-muted);
  text-align: center;
}

@media (max-width: 860px) {
  .desktop-nav {
    display: none;
  }
  .mobile-menu-btn {
    display: flex;
  }
}

@media (max-width: 480px) {
  .btn-header-cta {
    display: none;
  }
}

/* BOTÕES GLOBAIS */
.btn-primary {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 14px 28px;
  border-radius: 14px;
  background: var(--brand-purple);
  color: #fff;
  font-weight: 700;
  font-size: 16px;
  transition: transform 0.15s ease, background 0.15s ease, box-shadow 0.15s ease;
  box-shadow: 0 4px 20px var(--brand-purple-glow);
}

.btn-primary:hover {
  background: var(--brand-purple-hover);
  color: #fff;
  transform: translateY(-2px);
  box-shadow: 0 6px 24px rgba(124, 58, 237, 0.4);
}

.btn-secondary {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 14px 24px;
  border-radius: 14px;
  background: var(--bg-surface-2);
  border: 1px solid var(--border-subtle);
  color: var(--text-primary);
  font-weight: 600;
  font-size: 15px;
  transition: background 0.15s ease, border-color 0.15s ease;
}

.btn-secondary:hover {
  background: #252b35;
  border-color: rgba(255, 255, 255, 0.15);
  color: #fff;
}

/* TIPOGRAFIA & HERO */
.gradient-text {
  background: linear-gradient(90deg, #A78BFA, #38BDF8, #F43F5E, #A78BFA);
  background-size: 300% 100%;
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  animation: gradientShift 6s ease infinite;
}

@keyframes gradientShift {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}

.eyebrow {
  display: inline-block;
  font-family: var(--font-mono);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: #A78BFA;
  margin-bottom: 14px;
}

/* BADGES DE VEREDITO */
.verdict-pill {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 6px 14px;
  border-radius: 999px;
  font-family: var(--font-mono);
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.05em;
  text-transform: uppercase;
}

.verdict-pill.ready {
  background: var(--status-ready-bg);
  color: var(--status-ready);
  border: 1px solid rgba(16, 185, 129, 0.3);
}

.verdict-pill.unstable {
  background: var(--status-unstable-bg);
  color: var(--status-unstable);
  border: 1px solid rgba(255, 90, 54, 0.3);
}

.verdict-pill.caution {
  background: var(--status-caution-bg);
  color: var(--status-caution);
  border: 1px solid rgba(245, 158, 11, 0.3);
}

/* CARDS E SURFACES */
.card {
  background: var(--bg-surface-1);
  border: 1px solid var(--border-subtle);
  border-radius: 24px;
  padding: 28px;
  transition: border-color 0.2s ease, transform 0.2s ease;
}

.card:hover {
  border-color: var(--border-hover);
}

/* PLATFORM CALLOUT (PC x CONSOLE x IPHONE) */
.platform-notice {
  margin: 24px 0;
  padding: 18px 22px;
  border-radius: 16px;
  background: rgba(124, 58, 237, 0.08);
  border: 1px solid rgba(124, 58, 237, 0.25);
  font-size: 14px;
  line-height: 1.6;
  color: #D1D5DB;
}

.platform-notice b {
  color: #fff;
}

.platform-notice-mobile {
  background: rgba(16, 185, 129, 0.08);
  border-color: rgba(16, 185, 129, 0.25);
}

/* ANIMAÇÃO DE REVELAÇÃO */
[data-rv] {
  opacity: 0;
  transform: translateY(24px);
  transition: opacity 0.6s cubic-bezier(0.16, 1, 0.3, 1), transform 0.6s cubic-bezier(0.16, 1, 0.3, 1);
}

[data-rv].in {
  opacity: 1;
  transform: none;
}

@media (prefers-reduced-motion: reduce) {
  * {
    animation: none !important;
    transition: none !important;
  }
  [data-rv] {
    opacity: 1 !important;
    transform: none !important;
  }
}

/* FOOTER UNIFICADO */
.site-footer {
  border-top: 1px solid var(--border-subtle);
  background: #080A0D;
  padding: 56px 22px 40px;
  margin-top: auto;
}

.footer-inner {
  max-width: 1200px;
  margin: 0 auto;
}

.footer-top {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  gap: 40px;
  padding-bottom: 40px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
}

.footer-brand {
  max-width: 320px;
}

.footer-brand p {
  margin-top: 14px;
  font-size: 14px;
  color: var(--text-muted);
  line-height: 1.5;
}

.footer-cols {
  display: flex;
  flex-wrap: wrap;
  gap: 48px;
}

.footer-col h4 {
  font-size: 13px;
  font-family: var(--font-mono);
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--text-secondary);
  margin-bottom: 16px;
}

.footer-col ul {
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 10px;
  font-size: 14px;
  color: var(--text-muted);
}

.footer-col a:hover {
  color: var(--text-primary);
}

.footer-bottom {
  padding-top: 28px;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  font-size: 12px;
  font-family: var(--font-mono);
  color: var(--text-muted);
}

.footer-bottom a {
  color: var(--text-secondary);
}
`;

const COMMON_JS = `
<script>
(function() {
  'use strict';

  // 1. Menu Mobile Drawer com Gestão de Foco e Acessibilidade
  var menuBtn = document.getElementById('mobile-menu-btn');
  var mobileDrawer = document.getElementById('mobile-nav');

  if (menuBtn && mobileDrawer) {
    function toggleMenu(open) {
      var isOpen = typeof open === 'boolean' ? open : !mobileDrawer.classList.contains('open');
      menuBtn.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
      menuBtn.setAttribute('aria-label', isOpen ? 'Fechar menu' : 'Abrir menu');
      mobileDrawer.setAttribute('aria-hidden', isOpen ? 'false' : 'true');
      if (isOpen) {
        mobileDrawer.classList.add('open');
        document.body.style.overflow = 'hidden';
      } else {
        mobileDrawer.classList.remove('open');
        document.body.style.overflow = '';
      }
    }

    menuBtn.addEventListener('click', function(e) {
      e.stopPropagation();
      toggleMenu();
    });

    // Fechar ao clicar em qualquer link
    mobileDrawer.querySelectorAll('a').forEach(function(link) {
      link.addEventListener('click', function() {
        toggleMenu(false);
      });
    });

    // Fechar com Escape
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape' && mobileDrawer.classList.contains('open')) {
        toggleMenu(false);
        menuBtn.focus();
      }
    });

    // Fechar ao clicar fora
    document.addEventListener('click', function(e) {
      if (mobileDrawer.classList.contains('open') && !mobileDrawer.contains(e.target) && !menuBtn.contains(e.target)) {
        toggleMenu(false);
      }
    });
  }

  // 2. Animação de Scroll via IntersectionObserver (executa 1 vez, sem polling no DOM)
  if ('IntersectionObserver' in window) {
    var observer = new IntersectionObserver(function(entries) {
      entries.forEach(function(entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('in');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.1 });

    document.querySelectorAll('[data-rv]').forEach(function(el) {
      observer.observe(el);
    });
  } else {
    document.querySelectorAll('[data-rv]').forEach(function(el) {
      el.classList.add('in');
    });
  }

  // 3. Pageviews e visitantes por Vercel Web Analytics.

  // 4. Tracking correto de CONVERSÃO (App Store Click -> /v1/click)
  // Sem e-mails fictícios e sem corromper a waitlist de leads
  document.addEventListener('click', function(e) {
    var target = e.target.closest('a[data-track-conversion="appstore"]');
    if (!target) return;

    try {
      var clickPayload = JSON.stringify({
        event: 'appstore_click',
        page: window.location.pathname,
        gameId: document.body.getAttribute('data-game-id') || undefined,
        source: new URLSearchParams(window.location.search).get('utm_source') || 'web_download',
        platform: 'ios',
        utm: Object.fromEntries(new URLSearchParams(window.location.search).entries()),
        createdAt: new Date().toISOString()
      });

      if (navigator.sendBeacon) {
        navigator.sendBeacon('/v1/click', clickPayload);
      } else {
        fetch('/v1/click', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: clickPayload,
          keepalive: true
        }).catch(function() {});
      }
    } catch(err) {}
  });

  // 5. Busca e Filtro de Jogos em Tempo Real (/jogos/)
  var searchInput = document.getElementById('game-search');
  var filterButtons = document.querySelectorAll('.filter-btn');
  var gameCards = document.querySelectorAll('.game-card');
  var emptyState = document.getElementById('games-empty-state');

  if (searchInput && gameCards.length) {
    var activeCategory = 'all';

    function filterGames() {
      var query = searchInput.value.trim().toLowerCase();
      var visibleCount = 0;

      gameCards.forEach(function(card) {
        var name = (card.getAttribute('data-name') || '').toLowerCase();
        var cat = card.getAttribute('data-category') || '';
        var matchesQuery = !query || name.includes(query);
        var matchesCat = (activeCategory === 'all') || (cat === activeCategory);

        if (matchesQuery && matchesCat) {
          card.style.display = '';
          visibleCount++;
        } else {
          card.style.display = 'none';
        }
      });

      if (emptyState) {
        emptyState.style.display = visibleCount === 0 ? 'block' : 'none';
      }
    }

    searchInput.addEventListener('input', filterGames);

    filterButtons.forEach(function(btn) {
      btn.addEventListener('click', function() {
        filterButtons.forEach(function(b) { b.classList.remove('active'); });
        btn.classList.add('active');
        activeCategory = btn.getAttribute('data-filter') || 'all';
        filterGames();
      });
    });
  }
})();
</script>
`;

function buildHeader(activePage = '') {
  return `
<a href="#conteudo-principal" class="skip-link">Pular para o conteúdo principal</a>
<header class="site-header">
  <div class="header-inner">
    <a href="/" class="brand-link" aria-label="Lagcheck Home">
      <img src="/assets/lagcheck-wordmark-light.svg" alt="Lagcheck" class="brand-logo" width="124" height="28">
    </a>

    <nav class="desktop-nav" aria-label="Navegação principal">
      <a href="/jogos/" class="${activePage === 'jogos' ? 'active' : ''}">Jogos</a>
      <a href="/#como">Como funciona</a>
      <a href="/#faq">Dúvidas</a>
    </nav>

    <div class="header-actions">
      <a href="${APP_STORE_URL}" target="_blank" rel="noopener noreferrer" data-track-conversion="appstore" class="btn-header-cta" aria-label="Baixar na App Store">
        <svg width="15" height="18" viewBox="0 0 170 170" fill="currentColor" aria-hidden="true">
          <path d="M150.37 130.25c-2.45 5.66-5.35 10.87-8.71 15.66-4.58 6.53-8.33 11.05-11.22 13.56-4.48 4.12-9.28 6.23-14.42 6.35-3.69 0-8.14-1.05-13.32-3.18-5.19-2.12-9.97-3.17-14.34-3.17-4.58 0-9.49 1.05-14.75 3.17-5.26 2.13-9.5 3.24-12.74 3.35-4.35.13-9.16-1.9-14.42-6.08-3.69-3.04-7.67-7.85-11.93-14.42-6.52-10.11-11.75-21.43-15.68-33.95-3.93-12.52-5.9-24.18-5.9-34.98 0-14.15 3.58-25.92 10.74-35.31 7.16-9.39 16.27-14.2 27.33-14.42 4.9 0 10.3 1.34 16.22 4.01 5.92 2.68 9.77 4.07 11.55 4.18 1.56 0 5.48-1.46 11.76-4.39 6.27-2.92 11.79-4.26 16.55-4.01 12.72.63 22.74 5.28 30.06 13.97-11.08 6.74-16.51 15.99-16.3 27.75.22 9.24 3.86 17.02 10.92 23.34 7.07 6.33 15.42 9.85 25.06 10.57-2.35 7.18-5.26 14.65-8.73 22.4zM119.22 33.3c0-7.39 2.67-14.23 8.01-20.52 5.34-6.29 11.96-10.55 19.86-12.78.33 1.33.49 2.44.49 3.34 0 7.39-2.78 14.41-8.34 21.05-5.56 6.64-12.28 10.63-20.16 11.97-.22-1.12-.34-2.14-.34-3.06z"/>
        </svg>
        Baixar na App Store
      </a>
      <button type="button" class="mobile-menu-btn" id="mobile-menu-btn" aria-label="Abrir menu" aria-expanded="false" aria-controls="mobile-nav">
        <span class="menu-bar"></span>
        <span class="menu-bar"></span>
        <span class="menu-bar"></span>
      </button>
    </div>
  </div>

  <div class="mobile-nav-drawer" id="mobile-nav" aria-hidden="true" role="dialog" aria-modal="true" aria-label="Menu de navegação">
    <div class="mobile-nav-links">
      <a href="/" class="mobile-link">Início</a>
      <a href="/jogos/" class="mobile-link">Catálogo de Jogos (${GAMES.length})</a>
      <a href="/#demonstracao" class="mobile-link">Demonstração do Resultado</a>
      <a href="/#como" class="mobile-link">Como funciona</a>
      <a href="/#speedtest" class="mobile-link">Speedtest vs Lagcheck</a>
      <a href="/#transparencia" class="mobile-link">O que é medido</a>
      <a href="/#faq" class="mobile-link">Dúvidas frequentes</a>
      <a href="/support/" class="mobile-link">Suporte Oficial</a>
      <a href="/privacy/" class="mobile-link">Privacidade</a>
    </div>
    <div class="mobile-nav-footer">
      <a href="${APP_STORE_URL}" target="_blank" rel="noopener noreferrer" data-track-conversion="appstore" class="btn-mobile-download">
        Baixar grátis na App Store →
      </a>
      <p class="mobile-nav-subtext">Disponível para iPhone (iOS 17+)</p>
    </div>
  </div>
</header>
`;
}

function buildFooter() {
  return `
<footer class="site-footer">
  <div class="footer-inner">
    <div class="footer-top">
      <div class="footer-brand">
        <a href="/" aria-label="Lagcheck Home"><img src="/assets/lagcheck-wordmark-light.svg" alt="Lagcheck" width="118" height="26"></a>
        <p>Diagnóstico determinístico de estabilidade e latência para jogadores competitivos no iPhone.</p>
        <div style="margin-top:16px;display:inline-flex;align-items:center;gap:8px;padding:6px 12px;border-radius:8px;background:rgba(255,255,255,0.04);border:1px solid rgba(255,255,255,0.06);font-size:12px;color:var(--text-muted)">
          <span>Ecossistema</span> <a href="${SIGNALLQ_URL}" target="_blank" rel="noopener noreferrer" style="color:#A78BFA;font-weight:700">SignallQ →</a>
        </div>
      </div>

      <div class="footer-cols">
        <div class="footer-col">
          <h4>Produto</h4>
          <ul>
            <li><a href="${APP_STORE_URL}" target="_blank" rel="noopener noreferrer" data-track-conversion="appstore">Lagcheck iOS (App Store)</a></li>
            <li><a href="${LINKA_APP_STORE_URL}" target="_blank" rel="noopener noreferrer">Linka Speedtest (iOS)</a></li>
            <li><a href="https://linka-speedtest.web.app/" target="_blank" rel="noopener noreferrer">Linka Speedtest (Web)</a></li>
            <li><a href="${SIGNALLQ_URL}" target="_blank" rel="noopener noreferrer">SignallQ Android</a></li>
          </ul>
        </div>

        <div class="footer-col">
          <h4>Explorar</h4>
          <ul>
            <li><a href="/jogos/">Catálogo de Jogos (20)</a></li>
            <li><a href="/#como">Como funciona</a></li>
            <li><a href="/#demonstracao">Demonstração</a></li>
            <li><a href="/#faq">Dúvidas sobre lag</a></li>
          </ul>
        </div>

        <div class="footer-col">
          <h4>Institucional</h4>
          <ul>
            <li><a href="/support/">Suporte e Contato</a></li>
            <li><a href="/privacy/">Política de Privacidade</a></li>
            <li><a href="mailto:suporte@signallq.com">suporte@signallq.com</a></li>
          </ul>
        </div>
      </div>
    </div>

    <div class="footer-bottom">
      <p>© 2026 Lagcheck. Todos os direitos reservados. Lagcheck é parte do ecossistema <a href="${SIGNALLQ_URL}" target="_blank" rel="noopener noreferrer">SignallQ</a>.</p>
      <p>Marcas e nomes de jogos pertencem a suas respectivas publicadoras e foram citados para identificação de rota.</p>
    </div>
  </div>
</footer>
`;
}

// 1. GERAR A HOMEPAGE (web/index.html)
function generateHome() {
  const featuredGames = GAMES.slice(0, 8);

  const featuredGamesHtml = featuredGames.map(g => `
    <a href="/jogos/${g.slug}/" class="card" style="display:flex;flex-direction:column;padding:16px;border-radius:20px;text-decoration:none">
      <div style="aspect-ratio:1;border-radius:14px;overflow:hidden;background:#15181E;margin-bottom:14px">
        <picture>
          <source srcset="/assets/games/${g.file}-thumb.webp" type="image/webp">
          <img src="/assets/games/${g.file}.jpg" alt="${g.name}" loading="lazy" decoding="async" width="480" height="480" style="width:100%;height:100%;object-fit:cover">
        </picture>
      </div>
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:4px">
        <h3 style="font-size:17px;font-weight:700;color:#fff">${g.name}</h3>
        <span style="font-size:10px;font-family:var(--font-mono);color:#A78BFA;background:rgba(124,58,237,0.12);padding:2px 8px;border-radius:4px">${g.categoryLabel}</span>
      </div>
      <p style="font-size:12px;color:var(--text-muted);margin-bottom:12px">${g.platforms}</p>
      <span style="font-size:12px;font-weight:700;color:#A78BFA;margin-top:auto">Ver guia e rota →</span>
    </a>
  `).join('');

  const steps = [
    {
      n: '01',
      t: 'Escolha o jogo',
      d: 'Selecione o título que você vai abrir ou a rota regional de referência.',
      bg: 'linear-gradient(145deg, rgba(124,58,237,0.18), rgba(21,24,30,0.85))'
    },
    {
      n: '02',
      t: 'O app envia pacotes UDP reais',
      d: 'Aferição determinística da rota em repouso e sob carga concorrente de bufferbloat.',
      bg: 'linear-gradient(145deg, rgba(56,189,248,0.15), rgba(21,24,30,0.85))'
    },
    {
      n: '03',
      t: 'Receba o veredito direto',
      d: 'Pronto para Ranked, Condições instáveis ou sinal honesto para evitar a fila competitiva.',
      bg: 'linear-gradient(145deg, rgba(244,63,94,0.15), rgba(21,24,30,0.85))'
    }
  ];

  const stepsHtml = steps.map(s => `
    <article data-rv="1" class="card" style="background:${s.bg};display:flex;flex-direction:column;justify-content:space-between;min-height:240px">
      <span style="font-family:var(--font-mono);font-size:13px;font-weight:700;color:#A78BFA;letter-spacing:0.1em">${s.n}</span>
      <div>
        <h3 style="font-size:22px;font-weight:800;letter-spacing:-0.03em;color:#fff;margin-bottom:8px">${s.t}</h3>
        <p style="font-size:15px;line-height:1.5;color:var(--text-secondary)">${s.d}</p>
      </div>
    </article>
  `).join('');

  const faqList = [
    {
      q: 'Por que estou com lag no jogo se minha internet é de 500 Mega?',
      a: 'Velocidade de download (largura de banda) mede o volume de dados por segundo, bom para baixar arquivos. Já os jogos online transmitem pacotes UDP minúsculos em tempo real: o que importa é a consistência da rota, a oscilação de milissegundos (jitter) e a ausência de descarte de pacotes sob carga (bufferbloat).'
    },
    {
      q: 'O que o veredito do Lagcheck significa na prática?',
      a: 'Em vez de exigir que você interprete dezenas de números complexos, o app resume tudo em uma conclusão direta: ● PRONTO PARA RANKED (rota sólida), ▲ CONDIÇÕES INSTÁVEIS (oscilações perceptíveis) ou ▲ EU EVITARIA RANKED AGORA (perda severa de pacotes ou saturação de rede).'
    },
    {
      q: 'O Lagcheck promete zero lag ou diminui meu ping?',
      a: 'Não. O Lagcheck não é um otimizador de rotas nem faz promessas milagrosas. O app é um instrumento confiável de medição e diagnóstico preventivo: ele mede sua conexão real antes de você entrar na fila para evitar perda de pontos.'
    },
    {
      q: 'Posso usar no iPhone mesmo jogando no PC ou console?',
      a: 'Sim! Ao conectar o iPhone na mesma rede Wi-Fi da sua residência, o Lagcheck diagnostica a saúde geral da sua rede local e a rota de saída da sua operadora para São Paulo. Se o teste acusar instabilidade, seu PC ou console também será afetado.'
    },
    {
      q: 'O app é gratuito? Precisa de cadastro?',
      a: 'O Lagcheck é 100% gratuito na App Store para iPhone (iOS 17+). Não exige cadastro, login, e-mail nem exibe anúncios.'
    }
  ];

  const faqHtml = faqList.map(f => `
    <article data-rv="1" class="card" style="padding:24px">
      <h3 style="font-size:18px;font-weight:700;color:#fff;margin-bottom:10px">${f.q}</h3>
      <p style="font-size:15px;line-height:1.6;color:var(--text-secondary)">${f.a}</p>
    </article>
  `).join('');

  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Lagcheck — Teste de lag: sua conexão aguenta o ranked?</title>
  <meta name="description" content="Meça latência, jitter e perda de pacotes antes do ranked e saiba se sua conexão aguenta. Disponível na App Store para iPhone.">
  <meta name="robots" content="index,follow">
  <meta name="apple-itunes-app" content="app-id=6818706960">
  <link rel="canonical" href="https://lagcheck.signallq.com/">
  <link rel="icon" href="/favicon.svg" type="image/svg+xml">
  <link rel="apple-touch-icon" href="/apple-touch-icon.png">
  <meta name="theme-color" content="#0B0D10">
  <meta property="og:type" content="website">
  <meta property="og:locale" content="pt_BR">
  <meta property="og:site_name" content="Lagcheck">
  <meta property="og:title" content="Lagcheck — Teste de lag: sua conexão aguenta o ranked?">
  <meta property="og:description" content="Medição real de latência, jitter e perda antes de entrar na partida. Disponível na App Store.">
  <meta property="og:url" content="https://lagcheck.signallq.com/">
  <meta property="og:image" content="https://lagcheck.signallq.com/og.png">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:image:alt" content="Lagcheck: sua conexão está pronta para ranked?">
  <meta name="twitter:card" content="summary_large_image">
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "MobileApplication",
        "name": "Lagcheck: Teste de Ping Gamer",
        "operatingSystem": "iOS 17.0+",
        "applicationCategory": "UtilitiesApplication",
        "offers": { "@type": "Offer", "price": "0", "priceCurrency": "BRL" },
        "description": "App que diagnostica latência, jitter e perda de pacotes para jogos online antes do ranked.",
        "url": "${APP_STORE_URL}"
      },
      {
        "@type": "FAQPage",
        "mainEntity": [
${faqList.map(f => `          {
            "@type": "Question",
            "name": ${JSON.stringify(f.q)},
            "acceptedAnswer": { "@type": "Answer", "text": ${JSON.stringify(f.a)} }
          }`).join(',\n')}
        ]
      }
    ]
  }
  </script>
  <style>${COMMON_CSS}</style>
</head>
<body>
  ${buildHeader()}

  <main id="conteudo-principal">
    <!-- 1. HERO COM VALOR CLARO E PROVAS DO APP -->
    <section id="inicio" style="position:relative;padding:80px 22px 40px;text-align:center;background:radial-gradient(ellipse 70% 50% at 50% 35%, rgba(124,58,237,0.25), transparent 75%)">
      <div style="max-width:920px;margin:0 auto">
        <span class="eyebrow hi">Disponível na App Store para iPhone</span>
        <h1 class="hi" style="font-size:clamp(38px,7vw,84px);font-weight:900;line-height:1.02;letter-spacing:-0.05em;margin-bottom:24px;text-wrap:balance">
          Sua conexão está pronta para o <span class="gradient-text">ranked</span>?
        </h1>
        <p class="hi" style="font-size:clamp(17px,2.2vw,21px);line-height:1.5;color:var(--text-secondary);max-width:640px;margin:0 auto 36px">
          Descubra se sua conexão está estável para jogar online. O Lagcheck analisa indicadores como latência, jitter e perda de pacotes e explica o que os resultados significam.
        </p>

        <!-- CTAS PRINCIPAIS -->
        <div class="hi" style="display:flex;flex-wrap:wrap;justify-content:center;align-items:center;gap:14px;margin-bottom:28px">
          <a href="${APP_STORE_URL}" target="_blank" rel="noopener noreferrer" data-track-conversion="appstore" class="btn-primary" aria-label="Baixar na App Store">
            <svg width="20" height="24" viewBox="0 0 170 170" fill="currentColor" aria-hidden="true">
              <path d="M150.37 130.25c-2.45 5.66-5.35 10.87-8.71 15.66-4.58 6.53-8.33 11.05-11.22 13.56-4.48 4.12-9.28 6.23-14.42 6.35-3.69 0-8.14-1.05-13.32-3.18-5.19-2.12-9.97-3.17-14.34-3.17-4.58 0-9.49 1.05-14.75 3.17-5.26 2.13-9.5 3.24-12.74 3.35-4.35.13-9.16-1.9-14.42-6.08-3.69-3.04-7.67-7.85-11.93-14.42-6.52-10.11-11.75-21.43-15.68-33.95-3.93-12.52-5.9-24.18-5.9-34.98 0-14.15 3.58-25.92 10.74-35.31 7.16-9.39 16.27-14.2 27.33-14.42 4.9 0 10.3 1.34 16.22 4.01 5.92 2.68 9.77 4.07 11.55 4.18 1.56 0 5.48-1.46 11.76-4.39 6.27-2.92 11.79-4.26 16.55-4.01 12.72.63 22.74 5.28 30.06 13.97-11.08 6.74-16.51 15.99-16.3 27.75.22 9.24 3.86 17.02 10.92 23.34 7.07 6.33 15.42 9.85 25.06 10.57-2.35 7.18-5.26 14.65-8.73 22.4zM119.22 33.3c0-7.39 2.67-14.23 8.01-20.52 5.34-6.29 11.96-10.55 19.86-12.78.33 1.33.49 2.44.49 3.34 0 7.39-2.78 14.41-8.34 21.05-5.56 6.64-12.28 10.63-20.16 11.97-.22-1.12-.34-2.14-.34-3.06z"/>
            </svg>
            Baixar grátis na App Store
          </a>
          <a href="#demonstracao" class="btn-secondary">
            Ver demonstração do app ↓
          </a>
        </div>

        <!-- MICRO-PONTOS DE CONFIANÇA -->
        <div class="hi" style="display:flex;flex-wrap:wrap;justify-content:center;gap:18px;font-size:13px;font-family:var(--font-mono);color:var(--text-muted)">
          <span>✓ Para iPhone (iOS 17+)</span>
          <span>✓ 100% gratuito</span>
          <span>✓ Sem cadastro nem login</span>
          <span>✓ Diagnóstico em segundos</span>
        </div>
      </div>

      <!-- CAPTURAS REAIS DO APP COM HIERARQUIA VISUAL -->
      <div style="position:relative;max-width:960px;margin:56px auto 0;display:flex;justify-content:center;align-items:flex-end;gap:clamp(10px,2vw,24px)">
        <div style="width:28%;max-width:240px;opacity:0.75;transform:translateY(24px) scale(0.95);transition:opacity 0.2s">
          <img src="/assets/app-games.webp" alt="Seleção de Jogos no Lagcheck" width="600" height="1300" loading="eager" style="border-radius:28px;border:1px solid rgba(255,255,255,0.12);box-shadow:0 20px 50px rgba(0,0,0,0.6)">
        </div>
        <div style="width:40%;max-width:340px;z-index:2">
          <img src="/assets/app-home.webp" alt="Tela Principal do Lagcheck no iPhone" width="600" height="1300" loading="eager" fetchpriority="high" style="border-radius:34px;border:1px solid rgba(124,58,237,0.5);box-shadow:0 24px 70px rgba(0,0,0,0.8), 0 0 35px rgba(124,58,237,0.25)">
        </div>
        <div style="width:28%;max-width:240px;opacity:0.85;transform:translateY(24px) scale(0.95)">
          <img src="/assets/app-result.webp" alt="Veredito e Análise no Lagcheck" width="600" height="1300" loading="eager" style="border-radius:28px;border:1px solid rgba(255,255,255,0.12);box-shadow:0 20px 50px rgba(0,0,0,0.6)">
        </div>
      </div>
    </section>

    <!-- 2. DEMONSTRAÇÃO DO RESULTADO REAL (HIERARQUIA EM 5 NÍVEIS) -->
    <section id="demonstracao" style="max-width:1100px;margin:80px auto 0;padding:0 22px">
      <div style="text-align:center;max-width:680px;margin:0 auto 48px">
        <span class="eyebrow">Experiência Real</span>
        <h2 style="font-size:clamp(30px,4.5vw,48px);font-weight:800;letter-spacing:-0.04em;margin-bottom:14px">
          Não é apenas um número de ping. É um veredito compreensível.
        </h2>
        <p style="font-size:17px;color:var(--text-secondary);line-height:1.5">
          O Lagcheck organiza o resultado em uma conclusão direta para que você saiba instantaneamente se vale a pena puxar a fila agora.
        </p>
      </div>

      <div data-rv="1" class="card" style="padding:clamp(24px,4vw,48px);background:linear-gradient(145deg, #15181E, #11141A);border-color:rgba(124,58,237,0.3)">
        <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:36px;align-items:center">
          <div>
            <div style="display:flex;align-items:center;gap:12px;margin-bottom:20px">
              <span class="verdict-pill ready">● PRONTO PARA RANKED</span>
              <span style="font-size:12px;font-family:var(--font-mono);color:var(--text-muted)">São Paulo · AWS sa-east-1</span>
            </div>
            <h3 style="font-size:26px;font-weight:800;color:#fff;margin-bottom:12px;letter-spacing:-0.03em">
              Sua rota está estável e sem perdas de pacotes.
            </h3>
            <p style="font-size:16px;color:var(--text-secondary);line-height:1.6;margin-bottom:24px">
              A latência de ida e volta e a variação entre pacotes (jitter) estão dentro dos parâmetros ideais para partidas de alta competitividade.
            </p>

            <div style="display:grid;grid-template-columns:repeat(2,1fr);gap:12px;margin-bottom:28px">
              <div style="padding:14px;border-radius:14px;background:rgba(255,255,255,0.03);border:1px solid var(--border-subtle)">
                <span style="display:block;font-size:11px;font-family:var(--font-mono);color:var(--text-muted)">LATÊNCIA MÉDIA</span>
                <b style="font-size:22px;color:#fff">18 ms</b>
              </div>
              <div style="padding:14px;border-radius:14px;background:rgba(255,255,255,0.03);border:1px solid var(--border-subtle)">
                <span style="display:block;font-size:11px;font-family:var(--font-mono);color:var(--text-muted)">JITTER (OSCILAÇÃO)</span>
                <b style="font-size:22px;color:var(--status-ready)">1.8 ms</b>
              </div>
              <div style="padding:14px;border-radius:14px;background:rgba(255,255,255,0.03);border:1px solid var(--border-subtle)">
                <span style="display:block;font-size:11px;font-family:var(--font-mono);color:var(--text-muted)">PERDA DE PACOTES</span>
                <b style="font-size:22px;color:var(--status-ready)">0.0%</b>
              </div>
              <div style="padding:14px;border-radius:14px;background:rgba(255,255,255,0.03);border:1px solid var(--border-subtle)">
                <span style="display:block;font-size:11px;font-family:var(--font-mono);color:var(--text-muted)">SOB CARGA</span>
                <b style="font-size:22px;color:#fff">+3 ms</b>
              </div>
            </div>

            <div style="display:flex;align-items:center;gap:14px;flex-wrap:wrap">
              <a href="${APP_STORE_URL}" target="_blank" rel="noopener noreferrer" data-track-conversion="appstore" class="btn-primary" style="padding:12px 24px;font-size:15px">
                Fazer meu primeiro check →
              </a>
              <span style="font-size:13px;color:var(--text-muted)">Grátis para iPhone</span>
            </div>
          </div>

          <!-- EXEMPLO COMPARATIVO DE ALERTA -->
          <div style="display:flex;flex-direction:column;gap:16px">
            <div style="padding:22px;border-radius:18px;background:rgba(255,90,54,0.06);border:1px solid rgba(255,90,54,0.25)">
              <div style="display:flex;align-items:center;gap:10px;margin-bottom:8px">
                <span class="verdict-pill unstable" style="font-size:11px;padding:4px 10px">▲ CONDIÇÕES INSTÁVEIS</span>
              </div>
              <p style="font-size:14px;color:#F3F4F6;line-height:1.5;margin-bottom:8px">
                <b>Alerta de Bufferbloat:</b> O ping saltou de 20 ms para 114 ms sob carga. Alguém na rede pode estar assistindo vídeo ou fazendo downloads pesados.
              </p>
              <span style="font-size:12px;font-family:var(--font-mono);color:var(--accent-solar)">Orientação: Evite ranked agora ou use cabo/Wi-Fi 5 GHz exclusivo.</span>
            </div>

            <div style="padding:22px;border-radius:18px;background:rgba(245,158,11,0.06);border:1px solid rgba(245,158,11,0.25)">
              <div style="display:flex;align-items:center;gap:10px;margin-bottom:8px">
                <span class="verdict-pill caution" style="font-size:11px;padding:4px 10px">▲ EU EVITARIA RANKED AGORA</span>
              </div>
              <p style="font-size:14px;color:#F3F4F6;line-height:1.5;margin-bottom:8px">
                <b>Perda de pacotes detectada (3.8%):</b> Disparos e comandos falharão na sincronização.
              </p>
              <span style="font-size:12px;font-family:var(--font-mono);color:var(--status-caution)">Orientação: Reinicie o modem ou espere a rota da operadora estabilizar.</span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- 3. COMO O LAGCHECK FUNCIONA -->
    <section id="como" style="max-width:1100px;margin:90px auto 0;padding:0 22px">
      <div style="max-width:680px;margin-bottom:40px">
        <span class="eyebrow">Diagnóstico Limpo</span>
        <h2 style="font-size:clamp(28px,4vw,44px);font-weight:800;letter-spacing:-0.04em">
          Um check projetado para a realidade do jogo.
        </h2>
      </div>
      <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:20px">
        ${stepsHtml}
      </div>
    </section>

    <!-- 4. JOGOS POPULARES -->
    <section id="jogos" style="max-width:1100px;margin:90px auto 0;padding:0 22px">
      <div style="display:flex;flex-wrap:wrap;justify-content:space-between;align-items:baseline;gap:20px;margin-bottom:36px">
        <div>
          <span class="eyebrow">Catálogo</span>
          <h2 style="font-size:clamp(28px,4vw,42px);font-weight:800;letter-spacing:-0.04em">
            Jogos populares suportados
          </h2>
        </div>
        <a href="/jogos/" style="font-size:14px;font-weight:700;color:#A78BFA">Ver todos os ${GAMES.length} jogos →</a>
      </div>

      <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:18px">
        ${featuredGamesHtml}
      </div>

      <div style="text-align:center;margin-top:36px">
        <a href="/jogos/" class="btn-secondary" style="padding:12px 24px">
          Explorar hub completo com busca e filtros (${GAMES.length} jogos) →
        </a>
      </div>
    </section>

    <!-- 5. POR QUE O SPEEDTEST TRADICIONAL NÃO RESPONDE TUDO -->
    <section id="speedtest" style="max-width:1100px;margin:90px auto 0;padding:0 22px">
      <div style="max-width:680px;margin-bottom:36px">
        <span class="eyebrow">Velocidade x Estabilidade</span>
        <h2 style="font-size:clamp(28px,4vw,44px);font-weight:800;letter-spacing:-0.04em">
          Por que testes de velocidade comuns não resolvem seu ranked.
        </h2>
        <p style="font-size:16px;color:var(--text-secondary);line-height:1.6;margin-top:10px">
          Um download rápido não impede tiros que não registram nem teleportes causados por jitter.
        </p>
      </div>

      <div data-rv="1" class="card" style="padding:0;overflow:hidden">
        <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:1px;background:rgba(255,255,255,0.06)">
          <div style="padding:32px;background:var(--bg-surface-1)">
            <h3 style="font-size:20px;font-weight:800;color:#9CA3AF;margin-bottom:12px">Speedtest tradicional</h3>
            <p style="font-size:14px;color:var(--text-muted);line-height:1.5;margin-bottom:20px">Mede quanta banda cabe na sua linha para baixar arquivos e carregar vídeos.</p>
            <ul style="list-style:none;font-size:13px;font-family:var(--font-mono);color:var(--text-muted);display:flex;flex-direction:column;gap:8px">
              <li>— Velocidade de download (Mbps)</li>
              <li>— Velocidade de upload (Mbps)</li>
              <li>— Ping pontual e estático via TCP/HTTP</li>
              <li>✕ Não diagnostica jitter milissegundo a milissegundo</li>
            </ul>
          </div>

          <div style="padding:32px;background:linear-gradient(145deg, rgba(124,58,237,0.14), rgba(21,24,30,0.95))">
            <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:12px">
              <h3 style="font-size:22px;font-weight:800;color:#fff">Lagcheck (Ping Gamer)</h3>
              <span class="verdict-pill ready" style="font-size:10px;padding:3px 8px">Foco em jogos</span>
            </div>
            <p style="font-size:14px;color:#D1D5DB;line-height:1.5;margin-bottom:20px">Mede a estabilidade da rota que seus pacotes de jogo percorrem.</p>
            <ul style="list-style:none;font-size:13px;font-family:var(--font-mono);color:#E5E7EB;display:flex;flex-direction:column;gap:8px">
              <li>✓ Pacotes UDP contínuos (o protocolo real dos jogos)</li>
              <li>✓ Jitter (oscilação milissegundo a milissegundo)</li>
              <li>✓ Perda de pacotes e estabilidade sob carga (bufferbloat)</li>
              <li>✓ Veredito claro: pronto para ranked ou não</li>
            </ul>
          </div>
        </div>
      </div>
    </section>

    <!-- 6. TRANSPARÊNCIA SOBRE O QUE É MEDIDO -->
    <section id="transparencia" style="max-width:1100px;margin:90px auto 0;padding:0 22px">
      <div data-rv="1" class="card" style="padding:clamp(28px,4vw,48px);background:linear-gradient(135deg, rgba(124,58,237,0.15), rgba(21,24,30,0.95))">
        <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:32px;align-items:center">
          <div>
            <span class="eyebrow">Transparência Técnica</span>
            <h2 style="font-size:clamp(26px,3.8vw,38px);font-weight:800;letter-spacing:-0.03em;margin-bottom:14px">
              Onde e como sua conexão é medida.
            </h2>
            <p style="font-size:15px;line-height:1.6;color:var(--text-secondary);margin-bottom:16px">
              O Lagcheck mede a rota UDP real entre seu iPhone e beacons de referência regional em São Paulo (como AWS GameLift sa-east-1).
            </p>
            <p style="font-size:14px;line-height:1.6;color:var(--text-muted)">
              Transparência honesta: o teste avalia a rota regional de saída da sua operadora e rede local. Não prometemos medir servidores privados fechados de jogos sem evidência direta.
            </p>
          </div>

          <!-- AVISO PARA PC E CONSOLES -->
          <div class="platform-notice" style="margin:0">
            <h4 style="font-size:16px;font-weight:700;color:#fff;margin-bottom:8px">Joga no PC ou Console?</h4>
            <p style="font-size:13px;color:#D1D5DB;line-height:1.5">
              O Lagcheck é executado no seu iPhone. Se seu computador ou videogame compartilha a mesma conexão de internet e roteador, a medição no iPhone aponta com precisão se o provedor está com rota oscilando ou se o roteador está sofrendo com bufferbloat na residência.
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- 7. DÚVIDAS FREQUENTES (FAQ) -->
    <section id="faq" style="max-width:1100px;margin:90px auto 0;padding:0 22px">
      <div style="max-width:680px;margin-bottom:36px">
        <span class="eyebrow">Tire suas dúvidas</span>
        <h2 style="font-size:clamp(28px,4vw,42px);font-weight:800;letter-spacing:-0.04em">
          Perguntas frequentes sobre conexão e lag
        </h2>
      </div>
      <div style="display:grid;gap:14px">
        ${faqHtml}
      </div>
    </section>

    <!-- 8. CTA FINAL DE CONVERSÃO -->
    <section id="baixar" style="margin-top:100px;padding:90px 22px;text-align:center;background:radial-gradient(ellipse 70% 60% at 50% 100%, rgba(124,58,237,0.3), transparent 75%)">
      <div data-rv="1" style="max-width:640px;margin:0 auto">
        <span class="eyebrow">Comece agora</span>
        <h2 style="font-size:clamp(34px,5.5vw,56px);font-weight:900;letter-spacing:-0.05em;margin-bottom:18px">
          Faça o check antes da sua próxima fila.
        </h2>
        <p style="font-size:17px;color:var(--text-secondary);margin-bottom:32px;line-height:1.5">
          Baixe o Lagcheck gratuitamente na App Store para iPhone. Sem anúncios, sem cadastro e com veredito direto para o seu jogo.
        </p>

        <a href="${APP_STORE_URL}" target="_blank" rel="noopener noreferrer" data-track-conversion="appstore" class="btn-primary" style="padding:16px 36px;font-size:17px" aria-label="Baixar na App Store">
          <svg width="22" height="26" viewBox="0 0 170 170" fill="currentColor" aria-hidden="true">
            <path d="M150.37 130.25c-2.45 5.66-5.35 10.87-8.71 15.66-4.58 6.53-8.33 11.05-11.22 13.56-4.48 4.12-9.28 6.23-14.42 6.35-3.69 0-8.14-1.05-13.32-3.18-5.19-2.12-9.97-3.17-14.34-3.17-4.58 0-9.49 1.05-14.75 3.17-5.26 2.13-9.5 3.24-12.74 3.35-4.35.13-9.16-1.9-14.42-6.08-3.69-3.04-7.67-7.85-11.93-14.42-6.52-10.11-11.75-21.43-15.68-33.95-3.93-12.52-5.9-24.18-5.9-34.98 0-14.15 3.58-25.92 10.74-35.31 7.16-9.39 16.27-14.2 27.33-14.42 4.9 0 10.3 1.34 16.22 4.01 5.92 2.68 9.77 4.07 11.55 4.18 1.56 0 5.48-1.46 11.76-4.39 6.27-2.92 11.79-4.26 16.55-4.01 12.72.63 22.74 5.28 30.06 13.97-11.08 6.74-16.51 15.99-16.3 27.75.22 9.24 3.86 17.02 10.92 23.34 7.07 6.33 15.42 9.85 25.06 10.57-2.35 7.18-5.26 14.65-8.73 22.4zM119.22 33.3c0-7.39 2.67-14.23 8.01-20.52 5.34-6.29 11.96-10.55 19.86-12.78.33 1.33.49 2.44.49 3.34 0 7.39-2.78 14.41-8.34 21.05-5.56 6.64-12.28 10.63-20.16 11.97-.22-1.12-.34-2.14-.34-3.06z"/>
          </svg>
          Baixar grátis na App Store
        </a>
      </div>
    </section>
  </main>

  ${buildFooter()}
  ${COMMON_JS}
</body>
</html>
`;
}

// 2. GERAR O HUB DE JOGOS (web/jogos/index.html)
function generateJogosHub() {
  const categories = [
    { id: 'all', label: 'Todos' },
    { id: 'br', label: 'Battle Royale' },
    { id: 'fps', label: 'FPS / Tático' },
    { id: 'moba', label: 'MOBA' },
    { id: 'casual', label: 'Outros' }
  ];

  const categoriesHtml = categories.map((c, i) => `
    <button type="button" class="filter-btn ${i === 0 ? 'active' : ''}" data-filter="${c.id}" style="padding:8px 16px;border-radius:999px;border:1px solid var(--border-subtle);background:${i === 0 ? 'var(--brand-purple)' : 'var(--bg-surface-2)'};color:#fff;font-size:13px;font-weight:600;cursor:pointer">
      ${c.label}
    </button>
  `).join('');

  const cardsHtml = GAMES.map(g => `
    <a href="/jogos/${g.slug}/" class="card game-card" data-name="${g.name}" data-category="${g.category}" style="display:flex;flex-direction:column;padding:16px;border-radius:22px;text-decoration:none">
      <div style="aspect-ratio:1;border-radius:16px;overflow:hidden;background:#15181E;margin-bottom:14px">
        <picture>
          <source srcset="/assets/games/${g.file}-thumb.webp" type="image/webp">
          <img src="/assets/games/${g.file}.jpg" alt="${g.name}" loading="lazy" decoding="async" width="480" height="480" style="width:100%;height:100%;object-fit:cover">
        </picture>
      </div>
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px">
        <h2 style="font-size:18px;font-weight:800;color:#fff">${g.name}</h2>
        <span style="font-size:10px;font-family:var(--font-mono);color:#A78BFA;background:rgba(124,58,237,0.12);padding:2px 8px;border-radius:4px">${g.categoryLabel}</span>
      </div>
      <p style="font-size:12px;color:var(--text-muted);margin-bottom:14px;line-height:1.4">${g.platforms}</p>
      <span style="font-size:13px;font-weight:700;color:#A78BFA;margin-top:auto">Ver guia de rota →</span>
    </a>
  `).join('');

  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Testar ping e lag nos seus jogos | Lagcheck</title>
  <meta name="description" content="Escolha seu jogo e veja se sua conexão aguenta o ranked: Fortnite, Free Fire, COD Mobile, Valorant e mais. Latência, jitter e perda de pacotes no Lagcheck.">
  <meta name="robots" content="index,follow">
  <meta name="apple-itunes-app" content="app-id=6818706960">
  <link rel="canonical" href="https://lagcheck.signallq.com/jogos/">
  <link rel="icon" href="/favicon.svg" type="image/svg+xml">
  <link rel="apple-touch-icon" href="/apple-touch-icon.png">
  <meta name="theme-color" content="#0B0D10">
  <meta property="og:type" content="website">
  <meta property="og:locale" content="pt_BR">
  <meta property="og:site_name" content="Lagcheck">
  <meta property="og:title" content="Testar ping e lag nos seus jogos | Lagcheck">
  <meta property="og:description" content="Escolha seu jogo e veja se sua conexão aguenta o ranked: Fortnite, Free Fire, COD Mobile e mais. Disponível na App Store.">
  <meta property="og:url" content="https://lagcheck.signallq.com/jogos/">
  <meta property="og:image" content="https://lagcheck.signallq.com/og.png">
  <meta name="twitter:card" content="summary_large_image">
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    "itemListElement": [
      { "@type": "ListItem", "position": 1, "name": "Lagcheck", "item": "https://lagcheck.signallq.com/" },
      { "@type": "ListItem", "position": 2, "name": "Jogos", "item": "https://lagcheck.signallq.com/jogos/" }
    ]
  }
  </script>
  <style>${COMMON_CSS}
  .filter-btn.active {
    background: var(--brand-purple) !important;
    border-color: var(--brand-purple) !important;
  }
  </style>
</head>
<body>
  ${buildHeader('jogos')}

  <main id="conteudo-principal" style="max-width:1100px;margin:0 auto;padding:60px 22px 100px">
    <div style="max-width:760px;margin-bottom:36px">
      <span class="eyebrow">Catálogo de Jogos</span>
      <h1 style="font-size:clamp(36px,5.5vw,64px);font-weight:900;letter-spacing:-0.05em;line-height:1.05;margin-bottom:16px">
        Escolha o jogo. Veja se a conexão aguenta.
      </h1>
      <p style="font-size:18px;color:var(--text-secondary);line-height:1.5">
        Guias específicos para diagnosticar latência, jitter e perda de pacotes antes de iniciar sua partida nos títulos mais populares.
      </p>
    </div>

    <!-- BARRA DE BUSCA E FILTROS INTERATIVOS -->
    <div style="margin-bottom:40px;display:flex;flex-direction:column;gap:18px">
      <div>
        <label for="game-search" class="visually-hidden" style="position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);border:0">Buscar jogo</label>
        <input type="search" id="game-search" placeholder="Buscar jogo por nome (ex: Fortnite, Valorant, CS2)..." style="width:100%;max-width:540px;padding:14px 20px;border-radius:14px;background:var(--bg-surface-2);border:1px solid var(--border-subtle);color:#fff;font-size:15px;outline:none">
      </div>
      <div style="display:flex;flex-wrap:wrap;gap:8px">
        ${categoriesHtml}
      </div>
    </div>

    <!-- GRID DE JOGOS -->
    <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:18px">
      ${cardsHtml}
    </div>

    <!-- ESTADO VAZIO -->
    <div id="games-empty-state" style="display:none;text-align:center;padding:60px 20px">
      <h3 style="font-size:20px;font-weight:700;color:#fff;margin-bottom:8px">Nenhum jogo encontrado com esse termo.</h3>
      <p style="font-size:14px;color:var(--text-muted);margin-bottom:20px">Você pode usar o Lagcheck no iPhone com a rota de referência geral para qualquer jogo.</p>
    </div>

    <!-- CALLOUT CONTEXTUAL -->
    <div class="card" style="margin-top:60px;padding:32px;background:linear-gradient(135deg, rgba(124,58,237,0.12), rgba(21,24,30,0.9))">
      <h3 style="font-size:20px;font-weight:800;color:#fff;margin-bottom:8px">Não achou o título que você joga?</h3>
      <p style="font-size:15px;color:var(--text-secondary);line-height:1.5;margin-bottom:18px">
        O Lagcheck mede a rota UDP até servidores de referência da AWS em São Paulo. Essa infraestrutura é a mesma usada por centenas de jogos modernos, servindo como termômetro confiável para qualquer partida.
      </p>
      <a href="${APP_STORE_URL}" target="_blank" rel="noopener noreferrer" data-track-conversion="appstore" class="btn-primary" style="padding:10px 20px;font-size:14px">
        Baixar Lagcheck na App Store →
      </a>
    </div>
  </main>

  ${buildFooter()}
  ${COMMON_JS}
</body>
</html>
`;
}

// 3. GERAR PÁGINAS INDIVIDUAIS DOS 20 JOGOS (web/jogos/<slug>/index.html)
function generateGamePage(game) {
  const others = GAMES.filter(g => g.slug !== game.slug).slice(0, 5);
  const othersHtml = others.map(o => `
    <a href="/jogos/${o.slug}/" style="display:inline-flex;align-items:center;gap:8px;padding:10px 18px;border-radius:999px;background:var(--bg-surface-2);border:1px solid var(--border-subtle);font-size:13px;font-weight:600;color:#fff">
      ${o.name}
    </a>
  `).join('');

  const routeText = getRouteText(game.infra);

  const symptomsHtml = game.lagSymptoms.map(s => `
    <li style="padding:12px 0;border-top:1px solid var(--border-subtle);font-size:15px;line-height:1.5;color:#E5E7EB">
      ✕ ${s}
    </li>
  `).join('');

  const faqHtml = game.faq.map(f => `
    <article class="card" style="padding:22px">
      <h3 style="font-size:17px;font-weight:700;color:#fff;margin-bottom:8px">${f.q}</h3>
      <p style="font-size:14px;line-height:1.6;color:var(--text-secondary)">${f.a}</p>
    </article>
  `).join('');

  const platformNotice = game.isMobileNative
    ? `<div class="platform-notice platform-notice-mobile">
        <b>Diagnóstico no mesmo aparelho:</b> Como o ${game.name} é jogado diretamente no iPhone, a medição do Lagcheck reflete com exatidão a qualidade da sua conexão Wi-Fi ou dados móveis (4G/5G) no momento em que você jogar.
       </div>`
    : `<div class="platform-notice">
        <b>Diagnóstico via iPhone para PC/Console:</b> O Lagcheck é executado no iPhone. Estando conectado na mesma rede doméstica da sua casa, ele verifica se o roteador ou o provedor estão apresentando perda de pacotes e oscilação de rota antes de você entrar na fila competitiva no PC ou console.
       </div>`;

  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Testar ping no ${game.name} | Lagcheck</title>
  <meta name="description" content="Descubra se sua conexão aguenta a ranked no ${game.name}. Medição determinística de latência, jitter e perda de pacotes no iPhone.">
  <meta name="robots" content="index,follow">
  <meta name="apple-itunes-app" content="app-id=6818706960">
  <link rel="canonical" href="https://lagcheck.signallq.com/jogos/${game.slug}/">
  <link rel="icon" href="/favicon.svg" type="image/svg+xml">
  <link rel="apple-touch-icon" href="/apple-touch-icon.png">
  <meta name="theme-color" content="#0B0D10">
  <meta property="og:type" content="website">
  <meta property="og:locale" content="pt_BR">
  <meta property="og:site_name" content="Lagcheck">
  <meta property="og:title" content="Testar ping no ${game.name} | Lagcheck">
  <meta property="og:description" content="Descubra se sua conexão aguenta a ranked no ${game.name}. Veredito honesto no Lagcheck para iPhone.">
  <meta property="og:url" content="https://lagcheck.signallq.com/jogos/${game.slug}/">
  <meta property="og:image" content="https://lagcheck.signallq.com/assets/games/${game.file}.jpg">
  <meta name="twitter:card" content="summary_large_image">
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "BreadcrumbList",
        "itemListElement": [
          { "@type": "ListItem", "position": 1, "name": "Lagcheck", "item": "https://lagcheck.signallq.com/" },
          { "@type": "ListItem", "position": 2, "name": "Jogos", "item": "https://lagcheck.signallq.com/jogos/" },
          { "@type": "ListItem", "position": 3, "name": ${JSON.stringify(game.name)}, "item": "https://lagcheck.signallq.com/jogos/${game.slug}/" }
        ]
      },
      {
        "@type": "MobileApplication",
        "name": "Lagcheck: Teste de Ping Gamer",
        "operatingSystem": "iOS 17.0+",
        "applicationCategory": "UtilitiesApplication",
        "offers": { "@type": "Offer", "price": "0", "priceCurrency": "BRL" },
        "description": "App que diagnostica latência, jitter e perda de pacotes para ${game.name} antes do ranked.",
        "url": "${APP_STORE_URL}"
      },
      {
        "@type": "FAQPage",
        "mainEntity": [
${game.faq.map(f => `          {
            "@type": "Question",
            "name": ${JSON.stringify(f.q)},
            "acceptedAnswer": { "@type": "Answer", "text": ${JSON.stringify(f.a)} }
          }`).join(',\n')}
        ]
      }
    ]
  }
  </script>
  <style>${COMMON_CSS}</style>
</head>
<body data-game-id="${game.slug}">
  ${buildHeader('jogos')}

  <main id="conteudo-principal">
    <!-- HERO COM CAPA OTIMIZADA E CONTEXTO -->
    <section style="position:relative;min-height:clamp(460px,70vh,680px);display:flex;align-items:flex-end;background:#0B0D10;overflow:hidden">
      <picture style="position:absolute;inset:0;width:100%;height:100%">
        <source srcset="/assets/games/${game.file}.webp" type="image/webp">
        <img src="/assets/games/${game.file}.jpg" alt="Capa ilustrativa de ${game.name}" fetchpriority="high" width="1280" height="720" style="width:100%;height:100%;object-fit:cover;object-position:center 30%;opacity:0.38">
      </picture>
      <div style="position:absolute;inset:0;background:linear-gradient(180deg, rgba(11,13,16,0.6) 0%, rgba(11,13,16,0.2) 40%, #0B0D10 100%)"></div>

      <div style="position:relative;width:100%;max-width:1100px;margin:0 auto;padding:40px 22px 60px">
        <nav aria-label="Trilha de navegação" style="margin-bottom:20px;font-size:12px;font-family:var(--font-mono);color:var(--text-muted)">
          <a href="/">Lagcheck</a> / <a href="/jogos/">Jogos</a> / <span style="color:#fff">${game.name}</span>
        </nav>
        <span class="eyebrow">${game.platforms}</span>
        <h1 style="font-size:clamp(36px,6vw,76px);font-weight:900;letter-spacing:-0.05em;line-height:1.02;margin-bottom:16px;max-width:860px">
          Testar ping no ${game.name}
        </h1>
        <p style="font-size:clamp(16px,2vw,20px);color:#D1D5DB;max-width:620px;line-height:1.5;margin-bottom:28px">
          ${game.summary} Descubra se sua conexão está estável antes de iniciar a partida.
        </p>

        <div style="display:flex;flex-wrap:wrap;align-items:center;gap:14px">
          <a href="${APP_STORE_URL}" target="_blank" rel="noopener noreferrer" data-track-conversion="appstore" class="btn-primary" aria-label="Baixar na App Store">
            Baixar grátis na App Store
          </a>
          <span style="font-size:13px;font-family:var(--font-mono);color:var(--text-muted)">Diagnóstico no iPhone</span>
        </div>
      </div>
    </section>

    <!-- DETALHES DE REDE DO JOGO -->
    <div style="max-width:1100px;margin:0 auto;padding:50px 22px 90px">
      ${platformNotice}

      <!-- O QUE O CHECK MEDE -->
      <section style="margin-top:40px">
        <h2 style="font-size:clamp(24px,3.5vw,36px);font-weight:800;letter-spacing:-0.03em;margin-bottom:24px">
          O que o check analisa para ${game.name}
        </h2>
        <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:16px">
          <article class="card" style="padding:22px">
            <span style="font-size:11px;font-family:var(--font-mono);color:#A78BFA;display:block;margin-bottom:6px">LATÊNCIA REAL</span>
            <h3 style="font-size:18px;font-weight:700;color:#fff;margin-bottom:6px">Ping de ida e volta</h3>
            <p style="font-size:14px;color:var(--text-secondary);line-height:1.5">Tempo que os pacotes UDP levam para ir e voltar do destino regional.</p>
          </article>
          <article class="card" style="padding:22px">
            <span style="font-size:11px;font-family:var(--font-mono);color:var(--status-caution);display:block;margin-bottom:6px">OSCILAÇÃO</span>
            <h3 style="font-size:18px;font-weight:700;color:#fff;margin-bottom:6px">Jitter entre pacotes</h3>
            <p style="font-size:14px;color:var(--text-secondary);line-height:1.5">A variação do tempo de resposta que causa micro-stutters e tiros desincronizados.</p>
          </article>
          <article class="card" style="padding:22px">
            <span style="font-size:11px;font-family:var(--font-mono);color:var(--status-unstable);display:block;margin-bottom:6px">DESCARTE</span>
            <h3 style="font-size:18px;font-weight:700;color:#fff;margin-bottom:6px">Perda de pacotes</h3>
            <p style="font-size:14px;color:var(--text-secondary);line-height:1.5">Pacotes perdidos que geram teleportes e comandos não registrados.</p>
          </article>
          <article class="card" style="padding:22px">
            <span style="font-size:11px;font-family:var(--font-mono);color:#38BDF8;display:block;margin-bottom:6px">BUFFERBLOAT</span>
            <h3 style="font-size:18px;font-weight:700;color:#fff;margin-bottom:6px">Comportamento sob carga</h3>
            <p style="font-size:14px;color:var(--text-secondary);line-height:1.5">Como a rota reage caso alguém assista streaming ou faça download na mesma rede.</p>
          </article>
        </div>
      </section>

      <!-- SINTOMAS COMUNS E ROTA -->
      <section style="margin-top:60px;display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:24px">
        <div class="card" style="padding:28px">
          <span class="eyebrow" style="color:var(--status-unstable)">Sintomas na partida</span>
          <h3 style="font-size:22px;font-weight:800;color:#fff;margin-bottom:14px">Como o lag se manifesta no ${game.name}</h3>
          <ul style="list-style:none">
            ${symptomsHtml}
          </ul>
        </div>

        <div class="card" style="padding:28px;background:linear-gradient(145deg, rgba(124,58,237,0.12), rgba(21,24,30,0.95))">
          <span class="eyebrow">Infraestrutura</span>
          <h3 style="font-size:22px;font-weight:800;color:#fff;margin-bottom:14px">Rota medida e destino</h3>
          <p style="font-size:15px;color:var(--text-secondary);line-height:1.6;margin-bottom:18px">
            ${routeText}
          </p>
          <div style="padding:14px;border-radius:12px;background:rgba(0,0,0,0.3);border:1px solid var(--border-subtle);font-size:13px;color:var(--text-muted);line-height:1.5">
            <b>Recomendação prática:</b> ${game.guidance}
          </div>
        </div>
      </section>

      <!-- FAQ ESPECÍFICA DO JOGO -->
      <section style="margin-top:60px">
        <h2 style="font-size:clamp(24px,3.5vw,36px);font-weight:800;letter-spacing:-0.03em;margin-bottom:24px">
          Perguntas sobre lag no ${game.name}
        </h2>
        <div style="display:grid;gap:14px">
          ${faqHtml}
        </div>
      </section>

      <!-- OUTROS JOGOS -->
      <section style="margin-top:60px;padding-top:40px;border-top:1px solid var(--border-subtle)">
        <h3 style="font-size:18px;font-weight:700;color:#fff;margin-bottom:16px">Verificar outros jogos</h3>
        <div style="display:flex;flex-wrap:wrap;gap:10px;align-items:center">
          ${othersHtml}
          <a href="/jogos/" style="font-size:13px;font-weight:700;color:#A78BFA">Ver todos os ${GAMES.length} →</a>
        </div>
      </section>
    </div>
  </main>

  ${buildFooter()}
  ${COMMON_JS}
</body>
</html>
`;
}

// 4. GERAR PÁGINAS DE SUPORTE (web/support/index.html e web/support.html)
function generateSupport() {
  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Suporte Oficial | Lagcheck</title>
  <meta name="description" content="Central de suporte oficial do Lagcheck para iPhone. Tire dúvidas sobre a medição de rota UDP, diagnósticos e vereditos.">
  <meta name="robots" content="index,follow">
  <meta name="apple-itunes-app" content="app-id=6818706960">
  <link rel="canonical" href="https://lagcheck.signallq.com/support/">
  <link rel="icon" href="/favicon.svg" type="image/svg+xml">
  <link rel="apple-touch-icon" href="/apple-touch-icon.png">
  <meta name="theme-color" content="#0B0D10">
  <meta property="og:type" content="website">
  <meta property="og:locale" content="pt_BR">
  <meta property="og:site_name" content="Lagcheck">
  <meta property="og:title" content="Suporte Oficial | Lagcheck">
  <meta property="og:description" content="Central de ajuda e suporte técnico do Lagcheck para iPhone.">
  <meta property="og:url" content="https://lagcheck.signallq.com/support/">
  <meta property="og:image" content="https://lagcheck.signallq.com/og.png">
  <meta name="twitter:card" content="summary_large_image">
  <style>${COMMON_CSS}</style>
</head>
<body>
  ${buildHeader('support')}

  <main id="conteudo-principal" style="max-width:900px;margin:0 auto;padding:60px 22px 100px">
    <span class="eyebrow">Atendimento</span>
    <h1 style="font-size:clamp(36px,5vw,60px);font-weight:900;letter-spacing:-0.05em;line-height:1.05;margin-bottom:18px">
      Central de Suporte Oficial
    </h1>
    <p style="font-size:18px;color:var(--text-secondary);line-height:1.5;margin-bottom:44px">
      O Lagcheck está disponível na App Store para iPhone (iOS 17+). Se tiver dúvidas sobre os diagnósticos de rota UDP ou vereditos, conte com nosso time.
    </p>

    <div style="display:grid;gap:18px">
      <article class="card">
        <h2 style="font-size:20px;font-weight:700;color:#fff;margin-bottom:8px">O que o Lagcheck mede exatamente?</h2>
        <p style="font-size:15px;color:var(--text-secondary);line-height:1.6">
          O app envia pacotes UDP contínuos e mede a latência de ida e volta (ping), a oscilação de milissegundos entre pacotes (jitter), a perda de pacotes e o enfileiramento da rota sob carga concorrente (bufferbloat).
        </p>
      </article>

      <article class="card">
        <h2 style="font-size:20px;font-weight:700;color:#fff;margin-bottom:8px">O app mede o servidor exato da minha próxima partida?</h2>
        <p style="font-size:15px;color:var(--text-secondary);line-height:1.6">
          O Lagcheck mede uma rota determinística até beacons de referência regional em São Paulo (como AWS GameLift sa-east-1). Ele não invade a infraestrutura privada dos jogos nem inventa números: avalia a integridade do seu enlace regional.
        </p>
      </article>

      <article class="card">
        <h2 style="font-size:20px;font-weight:700;color:#fff;margin-bottom:8px">O que fazer se o veredito for "Condições instáveis"?</h2>
        <p style="font-size:15px;color:var(--text-secondary);line-height:1.6">
          Recomendamos evitar filas ranqueadas no momento. Aproxime-se do roteador Wi-Fi (preferindo a banda 5 GHz), verifique se há downloads ativos na sua rede doméstica ou reinicie o modem se a oscilação continuar.
        </p>
      </article>

      <article class="card" style="background:linear-gradient(135deg, rgba(124,58,237,0.18), rgba(21,24,30,0.95));border-color:rgba(124,58,237,0.4);display:flex;flex-wrap:wrap;justify-content:space-between;align-items:center;gap:20px">
        <div>
          <h2 style="font-size:20px;font-weight:800;color:#fff;margin-bottom:6px">Fale diretamente com nosso time</h2>
          <p style="font-size:14px;color:var(--text-secondary)">Canal oficial de atendimento por e-mail para usuários do app.</p>
        </div>
        <a href="mailto:suporte@signallq.com" class="btn-primary" style="padding:12px 24px;font-size:15px">
          suporte@signallq.com →
        </a>
      </article>
    </div>
  </main>

  ${buildFooter()}
  ${COMMON_JS}
</body>
</html>
`;
}

// 5. GERAR PÁGINAS DE PRIVACIDADE (web/privacy/index.html e web/privacy.html)
function generatePrivacy() {
  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Privacidade Oficial | Lagcheck</title>
  <meta name="description" content="Política de privacidade oficial do app Lagcheck na App Store. Sem contas, sem anúncios e com dados locais no iPhone.">
  <meta name="robots" content="index,follow">
  <meta name="apple-itunes-app" content="app-id=6818706960">
  <link rel="canonical" href="https://lagcheck.signallq.com/privacy/">
  <link rel="icon" href="/favicon.svg" type="image/svg+xml">
  <link rel="apple-touch-icon" href="/apple-touch-icon.png">
  <meta name="theme-color" content="#0B0D10">
  <meta property="og:type" content="website">
  <meta property="og:locale" content="pt_BR">
  <meta property="og:site_name" content="Lagcheck">
  <meta property="og:title" content="Privacidade Oficial | Lagcheck">
  <meta property="og:description" content="Política de privacidade oficial do app Lagcheck para iPhone.">
  <meta property="og:url" content="https://lagcheck.signallq.com/privacy/">
  <meta property="og:image" content="https://lagcheck.signallq.com/og.png">
  <meta name="twitter:card" content="summary_large_image">
  <style>${COMMON_CSS}</style>
</head>
<body>
  ${buildHeader('privacy')}

  <main id="conteudo-principal" style="max-width:900px;margin:0 auto;padding:60px 22px 100px">
    <span class="eyebrow">Transparência</span>
    <h1 style="font-size:clamp(36px,5vw,60px);font-weight:900;letter-spacing:-0.05em;line-height:1.05;margin-bottom:18px">
      Privacidade em Primeiro Lugar
    </h1>
    <p style="font-size:18px;color:var(--text-secondary);line-height:1.5;margin-bottom:44px">
      O Lagcheck foi desenvolvido com respeito rigoroso à privacidade dos jogadores. Sem contas, sem anúncios de terceiros e sem rastreamento intrusivo.
    </p>

    <div style="display:grid;gap:18px">
      <article class="card">
        <h2 style="font-size:20px;font-weight:700;color:#fff;margin-bottom:8px">Zero Coleta de Dados Pessoais</h2>
        <p style="font-size:15px;color:var(--text-secondary);line-height:1.6">
          O aplicativo não exige criação de conta, nome, e-mail, telefone ou autenticação de redes sociais. Você abre o aplicativo e realiza suas medições imediatamente de forma anônima.
        </p>
      </article>

      <article class="card">
        <h2 style="font-size:20px;font-weight:700;color:#fff;margin-bottom:8px">Armazenamento Local no iPhone (SwiftData)</h2>
        <p style="font-size:15px;color:var(--text-secondary);line-height:1.6">
          O histórico das suas medições de rede fica armazenado exclusivamente no armazenamento seguro do seu próprio iPhone. Os dados de medição nunca são comercializados com terceiros.
        </p>
      </article>

      <article class="card">
        <h2 style="font-size:20px;font-weight:700;color:#fff;margin-bottom:8px">Telemetria Técnica e Minimização</h2>
        <p style="font-size:15px;color:var(--text-secondary);line-height:1.6">
          Tanto o app quanto este site utilizam telemetria mínima agregada estritamente para monitorar a saúde da infraestrutura e conversão de produto (ex.: versão do iOS, identificadores de instalação técnicos gerados aleatoriamente e cliques na App Store). Não armazenamos endereços de IP de forma permanente e não correlacionamos dados técnicos com a identidade civil de jogadores.
        </p>
      </article>

      <article class="card">
        <h2 style="font-size:20px;font-weight:700;color:#fff;margin-bottom:8px">Ausência de Publicidade no MVP</h2>
        <p style="font-size:15px;color:var(--text-secondary);line-height:1.6">
          O aplicativo não inclui nenhum SDK de redes de anúncios nem rastreadores de publicidade comportamental em seu binário atual.
        </p>
      </article>

      <article class="card" style="background:linear-gradient(135deg, rgba(124,58,237,0.18), rgba(21,24,30,0.95));border-color:rgba(124,58,237,0.4);display:flex;flex-wrap:wrap;justify-content:space-between;align-items:center;gap:20px">
        <div>
          <h2 style="font-size:20px;font-weight:800;color:#fff;margin-bottom:6px">Dúvidas sobre seus dados?</h2>
          <p style="font-size:14px;color:var(--text-secondary)">Entre em contato com nossa equipe pelo canal oficial de privacidade.</p>
        </div>
        <a href="mailto:suporte@signallq.com" class="btn-primary" style="padding:12px 24px;font-size:15px">
          suporte@signallq.com →
        </a>
      </article>
    </div>
  </main>

  ${buildFooter()}
  ${COMMON_JS}
</body>
</html>
`;
}

// 6. GERAR SITEMAP & ROBOTS
function generateSitemap() {
  const today = '2026-10-11';
  const urls = [
    { loc: 'https://lagcheck.signallq.com/', priority: '1.0' },
    { loc: 'https://lagcheck.signallq.com/jogos/', priority: '0.9' },
    ...GAMES.map(g => ({ loc: `https://lagcheck.signallq.com/jogos/${g.slug}/`, priority: '0.8' })),
    { loc: 'https://lagcheck.signallq.com/support/', priority: '0.3' },
    { loc: 'https://lagcheck.signallq.com/privacy/', priority: '0.3' }
  ];

  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls.map(u => `  <url><loc>${u.loc}</loc><lastmod>${today}</lastmod><priority>${u.priority}</priority></url>`).join('\n')}
</urlset>
`;
}

function generateRobots() {
  return `User-agent: *
Allow: /

Sitemap: https://lagcheck.signallq.com/sitemap.xml
`;
}

// EXECUÇÃO DO BUILD
console.log('🚀 Iniciando geração do site comercial Lagcheck (App Store Live & Dark Competitive UI)...');

// Escreve index.html
fs.writeFileSync(path.join(WEB_DIR, 'index.html'), withVercelAnalytics(generateHome()), 'utf8');
console.log('✅ Home gerada: web/index.html');

// Escreve web/jogos/index.html
const jogosDir = path.join(WEB_DIR, 'jogos');
fs.mkdirSync(jogosDir, { recursive: true });
fs.writeFileSync(path.join(jogosDir, 'index.html'), withVercelAnalytics(generateJogosHub()), 'utf8');
console.log('✅ Hub de jogos gerado: web/jogos/index.html');

// Escreve páginas individuais dos 20 jogos
for (const game of GAMES) {
  const gameDir = path.join(jogosDir, game.slug);
  fs.mkdirSync(gameDir, { recursive: true });
  fs.writeFileSync(path.join(gameDir, 'index.html'), withVercelAnalytics(generateGamePage(game)), 'utf8');
}
console.log(`✅ ${GAMES.length} páginas de jogos geradas em web/jogos/<slug>/index.html`);

// Escreve Suporte (index.html e fallback raiz)
const supportDir = path.join(WEB_DIR, 'support');
fs.mkdirSync(supportDir, { recursive: true });
const supportHtml = withVercelAnalytics(generateSupport());
fs.writeFileSync(path.join(supportDir, 'index.html'), supportHtml, 'utf8');
fs.writeFileSync(path.join(WEB_DIR, 'support.html'), supportHtml, 'utf8');
console.log('✅ Suporte gerado em web/support/index.html e web/support.html');

// Escreve Privacidade (index.html e fallback raiz)
const privacyDir = path.join(WEB_DIR, 'privacy');
fs.mkdirSync(privacyDir, { recursive: true });
const privacyHtml = withVercelAnalytics(generatePrivacy());
fs.writeFileSync(path.join(privacyDir, 'index.html'), privacyHtml, 'utf8');
fs.writeFileSync(path.join(WEB_DIR, 'privacy.html'), privacyHtml, 'utf8');
console.log('✅ Privacidade gerada em web/privacy/index.html e web/privacy.html');

// Escreve sitemap.xml e robots.txt
fs.writeFileSync(path.join(WEB_DIR, 'sitemap.xml'), generateSitemap(), 'utf8');
fs.writeFileSync(path.join(WEB_DIR, 'robots.txt'), generateRobots(), 'utf8');
console.log('✅ sitemap.xml e robots.txt atualizados');

console.log('🏁 Build concluído com sucesso!');
