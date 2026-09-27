# LagCheck — Registro Canônico de Decisões

> **Autoridade:** Este é o **único documento oficial de decisões** de produto, arquitetura, design e infraestrutura do LagCheck.
> **Regra de atualização:** Novas decisões não criam novos arquivos markdown soltos. Elas são registradas diretamente neste documento, em ordem cronológica crescente, após alinhamento entre Marco (Product Lead), as frentes responsáveis (Renan, Rian, Iury, Breno, Camillo) e autorização do dono do produto (Luiz).
>
> **Relação de Precedência:** Decisões com ID numérico maior refinam, restringem ou **substituem** decisões anteriores quando houver conflito. A coluna "Status Atual" no índice e as notas em cada decisão sinalizam expressamente o que está ativo (**Vigente**) e o que foi **Superado / Substituído**.
> Os arquivos históricos originais pontuais encontram-se preservados em `docs/archive/decisoes/` para fins de auditoria.

---

## Índice Rápido de Decisões e Status de Vigência

| ID | Título da Decisão | Status Atual | Superada / Refinada por | Frente Principal |
| :--- | :--- | :--- | :--- | :--- |
| [08](#decisão-08) | Piloto vertical de Quick Check (Fortnite · BR · iPhone) | **Superada** | Decisões 43 e 50 (Jornada única com carga / Ready Check) | Marco / Iury |
| [09](#decisão-09) | Contrato de rede do piloto (UDP AWS GameLift `sa-east-1`) | **Superada em parte** | Decisões 28, 29 e 37 (Catálogo global e múltiplos backends) | Iury / Rian |
| [10](#decisão-10) | Experiência do piloto Quick Check e anel de score 160pt | **Superada** | Decisões 50, 51 e 56 (Veredito semântico protagonista; score rebaixado) | Renan / Marco |
| [11](#decisão-11) | Detalhes do resultado e Histórico local (snapshot SwiftData) | **Vigente** | Snapshot local imutável sem servidor | Rian / Marco |
| [12](#decisão-12) | Deep Check do piloto e Cloudflare Worker `/v1/load` | **Vigente** | Worker gratuito mantido sob custo zero | Iury / Rian |
| [13](#decisão-13) | Parecer de design para Deep Check, Histórico e Detalhes | **Superada** | Decisão 51 (Dark Competitive UI substituiu visual inicial) | Renan |
| [14](#decisão-14) | Catálogo remoto assinado em Debug (Ed25519, `/v1/catalog.json`) | **Vigente** | Assinatura criptográfica obrigatória mantida | Iury / Renan |
| [15](#decisão-15) | Artes licenciadas para capas do catálogo | **Substituída** | Decisões 18 e 44 (Identidade neutra sem copyright) | Renan |
| [16](#decisão-16) | Seleção regional automática BR/EUA (`regional-selection-1`) | **Vigente** | Algoritmo determinístico de beacon de referência | Iury / Rian |
| [17](#decisão-17) | Navegação e Configurações da V1 (Home ⇄ Config ⇄ Histórico) | **Superada** | Decisões 24 e 51 (Substituída por 2 abas: `Início \| Jogos`) | Renan / Rian |
| [18](#decisão-18) | Identidade visual neutra dos jogos (sem capa/logo de terceiros) | **Vigente** | Miniaturas neutras e identificação tipográfica | Renan / Marco |
| [19](#decisão-19) | Exploração: adotar taxonomia "Modo gamer" do SignallQ | **Descartada** | Rascunho exploratório sem autorização de código | Marco |
| [20](#decisão-20) | Auditoria exploratória: revisão de nome, telas e monetização | **Descartada** | Rascunho exploratório rejeitado pelo posicionamento | Marco |
| [21](#decisão-21) | Nova direção visual, simples e leve | **Superada** | Decisão 51 (Dark Competitive UI substituiu o visual simples) | Renan |
| [22](#decisão-22) | Jornada com lista nativa e Quick Check em background | **Superada** | Decisões 43 e 50 (Medição sob demanda em 1 toque) | Marco / Renan |
| [23](#decisão-23) | Dicas de conexão com IA Gemini após Deep Check | **Vigente** | Checklist prático físico sem impactar cálculo do score | Marco / Iury |
| [24](#decisão-24) | Design System Apple Games Hub (SF Rounded, 4 abas, card soup) | **Superada** | Decisões 50, 51 e 53 (Substituído por Dark Competitive UI e 2 abas) | Renan |
| [25](#decisão-25) | Adoção da marca LagCheck e Pulse Gauge Coral Solar | **Vigente (Marca) / Superada (Símbolo)** | Marca `lagcheck` vigente; símbolo Pulse Gauge superado pela Decisão 52 | Renan / Luiz |
| [26](#decisão-26) | Teto de plataformas de console no catálogo Debug | **Vigente** | Limitação de escopo em títulos piloto mantida | Marco / Iury |
| [27](#decisão-27) | Diagnóstico e recomendação de frequência Wi-Fi (2.4 vs 5 GHz) | **Vigente** | Recomendação acionável mantida sem culpar roteador sem prova | Iury / Rian |
| [28](#decisão-28) | Servidores de teste globais (AWS GameLift UDP Beacons) | **Vigente** | Infraestrutura distribuída a custo zero | Iury |
| [29](#decisão-29) | Infraestruturas de medição a custo zero (GameLift, PlayFab, Valve) | **Vigente** | Pilares fundamentais de rede a custo zero | Iury |
| [30](#decisão-30) | Status operacional de plataformas de console a custo zero | **Vigente** | Checagem de PSN e Xbox Live sem consumo de APIs pagas | Iury |
| [31](#decisão-31) | Catálogo editorial com notas oficiais e requisitos de rede | **Vigente** | Dados objetivos sem alucinação | Marco / Renan |
| [32](#decisão-32) | Diagnóstico de topologia de rede multiplayer (STUN RFC 5389) | **Vigente** | Identificação determinística de NAT, CGNAT e Duplo NAT | Iury |
| [33](#decisão-33) | Internacionalização multi-idiomas (pt-BR, en, es) | **Vigente** | Localização completa mantida | Marco / Renan |
| [34](#decisão-34) | Trilha Viva de Medição (`MeasurementLiveTrail`) e estresse sob carga | **Vigente** | Visualização da troca de pacotes UDP nos 3 nós | Renan / Rian |
| [35](#decisão-35) | Tela de Resultado HIG com Hero Editorial e Atestado de Rota | **Superada em parte** | Refinada pela Decisão 51/56 (Dark Competitive UI) | Renan / Rian |
| [36](#decisão-36) | Check Completo em Wi-Fi e celular com consentimento de dados | **Vigente** | Trava de segurança contra consumo indesejado de 4G/5G | Marco / Rian |
| [37](#decisão-37) | Catálogo editorial de contextos e rotas reais (Catálogo v3) | **Vigente** | Rotas oficiais por região | Iury / Renan |
| [38/39](#decisões-38-e-39) | Matriz de viabilização e seleção automática de rotas próprias | **Vigente** | Resolução dinâmica de rota de teste | Iury |
| [40](#decisão-40) | Assinatura Ed25519 do catálogo remoto v3 | **Vigente** | Verificação criptográfica no app | Iury / Rian |
| [41](#decisão-41) | Separação entre vínculo de console externo e rede do iPhone | **Vigente** | O app foca estritamente no que o hardware do iPhone mede | Iury / Rian |
| [42](#decisão-42) | Home orientada por estado da conexão e ação primária | **Vigente / Refinada** | Refinada pela Decisão 56 (Jornada 1 Toque) | Renan / Marco |
| [43](#decisão-43) | Jornada única de Deep Check (substitui Quick Check visível) | **Vigente** | Todo teste inclui estresse sob carga | Marco / Renan |
| [44](#decisão-44) | Identidade visual de capas geradas do catálogo | **Vigente** | Artes autorais do catálogo | Renan |
| [45](#decisão-45) | Exceção temporária Gemini Release 1.0.0 | **Vigente** | Degradação graciosa de IA mantida | Marco / Iury |
| [46](#decisão-46) | Reconciliação: Deep Check único e consentimento móvel | **Vigente** | Alinhamento de jornada e travas móveis | Marco / Rian |
| [47](#decisão-47) | Progressão visual com Pulse Gauge Coral Solar | **Superada** | Decisão 52 (Pulse Gauge substituído por Dual-Node Vector) | Renan |
| [48](#decisão-48) | Experiência visual de carregamento com IA (Dicas de Otimização) | **Vigente** | Shimmer e micro-copy na tela de transição | Renan / Marco |
| [49](#decisão-49) | Medição geral de conexão para jogos (rota regional de referência) | **Vigente** | Teste genérico para jogos não cadastrados | Iury / Marco |
| [50](#decisão-50) | Reposicionamento MVP — Ready for Ranked (`GameReadinessVerdict`) | **Vigente (Fundação)** | Jornada `Home → Jogo → Check → Veredito`, integridade diagnóstica | Marco / Squad |
| [51](#decisão-51) | Direção Visual Dark Competitive UI e Iniciativa Unificada | **Vigente (Design)** | Fundo `#0B0D10`, bordas 1px, 2 abas, sem card soup | Renan / Squad |
| [52](#decisão-52) | Marca: Dual-Node Vector e Wordmark Kinetic Speed Slant | **Vigente (Identidade)** | Substitui Pulse Gauge; dois nós conectados com velocidade | Renan / Luiz |
| [53](#decisão-53) | Tipografia Híbrida de Performance (Display pesado e cockpit mono) | **Vigente (Tipografia)** | Elimina SF Rounded; números monoespaçados estilo cockpit | Renan |
| [54](#decisão-54) | Pílula de telemetria local ao vivo na Home (`LiveNetworkSignalCapsule`) | **Vigente** | Latência instantânea e Wi-Fi 5GHz/5G no topo da Home | Renan / Rian |
| [55](#decisão-55) | Melhorias de Diagnóstico e Integridade de Rede (Grok: probe gateway) | **Vigente** | Probes locais determinísticos e descarte rigoroso | Iury |
| [56](#decisão-56) | Jornada Direta em 1 Toque, Cockpit de Rede e Otimizações de Setup | **Vigente** | Ação de 1 toque, Dados da Rede e setup por plataforma | Renan / Rian |
| [57](#decisão-57) | Hero Gauge Pulsante, Meus Favoritos, Export PDF e Otimização Única | **Vigente** | Testar Agora pulsante, até 4 favoritos, exportação PDF local | Renan / Squad |
| [58](#decisão-58) | Detecção de Pacotes Fora de Ordem (RFC 4737) e Modulação `.caution` | **Vigente** | Detecção de reordenação UDP; taxa > 1% modula veredito | Iury / Rian |
| [60](#decisão-60) | Corte do Atalho de Contexto de Rede para o candidato a TestFlight | **Vigente** | Dados 100% observados no iPhone para o release | Marco / Squad |
| [61](#decisão-61) | Website Oficial: Lançamento em Breve no iOS e Captura de Convites | **Vigente** | Site `web/` alinhado ao iOS 17+ e waitlist TestFlight | Marco / Renan |
| [62](#decisão-62) | Reconciliação documental e conformidade estrita com o gate de TestFlight | **Vigente** | Checklist pré-TestFlight e congelamento de escopo | Breno / Squad |
| [63](#decisão-63) | Adoção do Workflow e Governança Unificada Buildea (Paralelismo SignallQ) | **Vigente (Governança)** | Lanes, Breno (QA), Camillo (Arquiteto), Marco (Lead), DECISOES.md | Marco / Squad / Luiz |
| [64](#decisão-64) | Diretriz "Zero Cara de IA / Gamer Não Lê", Card Viral Discord e Dogfooding | **Vigente (Produto & Processo)** | Proibição de cardlização/textão, card pro Discord, dogfooding e skills de ação | Marco / Luiz / Squad |
| [65](#decisão-65) | Validação Científica (12s, 3 Fases), Fallback de Jogo, Cockpit e Blindagem Visual | **Vigente (Execução Total)** | 3 fases reais UDP/Bufferbloat, fallback jogos, 2 abas, anti-glitches visuais | Marco / Squad / Luiz |
| [66](#decisão-66) | Adoção do Design System LagCheck Canônico (Roxo Gamer Primário, Coral Solar para Atenção) | **Vigente (Design System Canônico)** | Roxo Gamer (#7C3AED), Coral Solar (#FF5A36) restrito a atenção/erro, 3 pilhas tipográficas, raios 8/13/17/26/999px | Renan / Squad / Luiz |

---

## Histórico Cronológico Detalhado

### Decisão 08
- **Título:** Início pelo piloto vertical de Quick Check (Fortnite · Brasil · iPhone).
- **Status Atual:** **Superada** pelas Decisões 43 e 50.
> [!NOTE]
> O conceito inicial de ter um "Quick Check" (teste rápido sem estresse de carga) foi superado na Decisão 43 (onde toda medição passou a ser unificada com carga) e na Decisão 50 (reposicionamento focado em *Ready for Ranked*).

### Decisão 09
- **Título:** Contrato de rede do piloto (UDP AWS GameLift `sa-east-1`).
- **Status Atual:** **Superada em parte** pelas Decisões 28, 29 e 37.
> [!NOTE]
> A rota de São Paulo (`sa-east-1`) permanece como rota de referência para o Brasil, mas a arquitetura de rede foi expandida para incluir Azure PlayFab, Valve A2S_INFO e múltiplos servidores globais.

### Decisão 10
- **Título:** Experiência do piloto Quick Check e anel de score de 160pt.
- **Status Atual:** **Superada** pelas Decisões 50, 51 e 56.
> [!NOTE]
> O anel de score numérico (0–100) como elemento visual primário foi superado: na iniciativa Dark Competitive UI, a manchete de maior hierarquia visual é o **Veredito Semântico Direto** (`● PRONTO PARA RANKED`, `▲ EU EVITARIA RANKED AGORA`), e o score numérico ficou subordinado a "Entender resultado / Detalhes".

### Decisão 11
- **Título:** Detalhes do resultado e Histórico local.
- **Status Atual:** **Vigente.**
- **Resumo:** Histórico persistido localmente via SwiftData através de snapshots imutáveis de medição, sem sincronização com servidor e com retenção transparente.

### Decisão 12
- **Título:** Deep Check do piloto e Cloudflare Worker `/v1/load`.
- **Status Atual:** **Vigente.**
- **Resumo:** Autorização de um único Cloudflare Worker gratuito (`nolaggy-deep-check`) para simular estresse de carga via endpoint `GET /v1/load`, assegurando custo operacional zero.

### Decisão 13
- **Título:** Parecer de design para Deep Check, Histórico e Detalhes.
- **Status Atual:** **Superada** pela Decisão 51 (Dark Competitive UI).
> [!NOTE]
> As diretrizes visuais iniciais com cartões soltos e gradientes suaves foram substituídas pelos painéis de 1px com visual escuro competitivo.

### Decisão 14
- **Título:** Catálogo remoto assinado em Debug (Ed25519, `/v1/catalog.json`).
- **Status Atual:** **Vigente.**
- **Resumo:** Entrega do catálogo via Cloudflare Worker com validação de assinatura Ed25519 obrigatória antes de ser consumido pelo aplicativo.

### Decisão 15
- **Título:** Contrato de artes licenciadas para capas do catálogo.
- **Status Atual:** **Substituída** pela Decisão 18 e 44.
> [!WARNING]
> Substituída e proibida. Jogos no catálogo não utilizam capas, logos oficiais ou artes de terceiros por motivos de propriedade intelectual e custo. A identidade visual adotada é estritamente neutra.

### Decisão 16
- **Título:** Seleção regional automática BR/EUA (`regional-selection-1`).
- **Status Atual:** **Vigente.**
- **Resumo:** Algoritmo determinístico para detecção da região do jogador com base em beacons UDP em São Paulo e Virgínia.

### Decisão 17
- **Título:** Navegação e Configurações da V1.
- **Status Atual:** **Superada** pelas Decisões 24 e 51.
> [!NOTE]
> A navegação inicial baseada em telas sequenciais (Home ⇄ Configurações ⇄ Histórico) foi substituída pela TabView de 2 abas (`Início | Jogos`), com Histórico e Ajustes acessados contextualmente.

### Decisão 18
- **Título:** Identidade visual neutra dos jogos.
- **Status Atual:** **Vigente** (substitui Decisão 15).
- **Resumo:** Miniaturas neutras oficiais do LagCheck com tipografia de destaque para o nome do jogo, garantindo segurança jurídica total.

### Decisões 19 e 20
- **Título:** Exploração de taxonomia do SignallQ e revisão de produto/nome.
- **Status Atual:** **Descartadas (Rascunhos exploratórios).**
> [!NOTE]
> Conversas puramente conceituais que não geraram código. Decidiu-se manter o LagCheck como produto 100% autônomo, sem copiar termos residenciais do SignallQ.

### Decisão 21
- **Título:** Nova direção visual, simples e leve.
- **Status Atual:** **Superada** pelas Decisões 24 e 51.
> [!NOTE]
> Substituída em definitivo pelo Design System Dark Competitive UI.

### Decisão 22
- **Título:** Nova jornada com lista nativa e Quick Check em background.
- **Status Atual:** **Superada** pelas Decisões 43 e 50.
> [!NOTE]
> Checagens automáticas em background foram descartadas em favor da medição sob demanda com estresse sob carga para integridade dos dados observados.

### Decisão 23
- **Título:** Dicas de conexão com Gemini pós Deep Check.
- **Status Atual:** **Vigente.**
- **Resumo:** CTA contextualizado após o teste, acionando o Gemini via Worker para gerar checklist físico acionável (cabo, Wi-Fi 5GHz, DNS) sem alucinar causas.

### Decisão 24
- **Título:** Adoção do Design System Apple Games Editorial Hub.
- **Status Atual:** **Superada** pelas Decisões 50, 51 e 53.
> [!NOTE]
> O modelo de 4 abas, estilo editorial com "card soup" e fontes arredondadas (SF Rounded) foi totalmente superado pela **Dark Competitive UI** (2 abas, fundo `#0B0D10`, bordas de 1px e tipografia angular de performance).

### Decisão 25
- **Título:** Adoção da marca LagCheck e Pulse Gauge Coral Solar.
- **Status Atual:** **Vigente em Marca / Superada em Símbolo** (pela Decisão 52).
> [!NOTE]
> A marca oficial **LagCheck** (com `lagcheck` minúsculo na wordmark) e o acento Coral Solar (`#FF5A36`) são plenamente vigentes. O símbolo visual original ("Pulse Gauge") foi superado pelo "Dual-Node Vector" na Decisão 52.

### Decisões 26 a 33
- **Títulos:** Teto de consoles (26), Diagnóstico Wi-Fi 2.4/5GHz (27), Servidores globais GameLift (28), Infra a custo zero (29), Status consoles PSN/Xbox (30), Catálogo sem alucinação (31), Topologia STUN RFC 5389 (32) e Internacionalização multi-idiomas (33).
- **Status Atual:** **Todas Vigentes.**
- **Resumo:** Pilares técnicos do motor determinístico, cobertura de protocolos de rede e garantia irrestrita de custo recorrente zero.

### Decisão 34
- **Título:** Trilha Viva de Medição (`MeasurementLiveTrail`).
- **Status Atual:** **Vigente.**
- **Resumo:** Visualização em tempo real do tráfego UDP nos 3 nós: iPhone ⇄ Gateway ⇄ Servidor do Jogo.

### Decisão 35
- **Título:** Tela de Resultado HIG com Hero Editorial e Atestado de Rota.
- **Status Atual:** **Superada em parte / Refinada** pela Decisão 51/56.
> [!NOTE]
> O conceito de atestado de rota foi mantido, mas o layout foi refinado na Dark Competitive UI para dar protagonismo absoluto ao veredito da partida.

### Decisão 36
- **Título:** Check Completo em Wi-Fi e rede móvel com consentimento.
- **Status Atual:** **Vigente.**
- **Resumo:** Medição em redes celulares mediante consentimento explícito e cancelamento imediato em caso de troca de rede.

### Decisões 37 a 40
- **Títulos:** Rotas próprias, catálogo v3 e assinatura criptográfica Ed25519.
- **Status Atual:** **Todas Vigentes.**
- **Resumo:** Mecanismos de governança e segurança de rotas de rede sem intervenção de backend pago.

### Decisão 41
- **Título:** Separação entre vínculo externo e rede observada no iPhone.
- **Status Atual:** **Vigente.**
- **Resumo:** O app mede estritamente o ambiente observado no hardware do iPhone, sem deduções especulativas sobre cabos de consoles ou PCs externos.

### Decisão 42
- **Título:** Home orientada por estado da conexão e ação primária.
- **Status Atual:** **Vigente (Refinada pela Decisão 56).**
- **Resumo:** Ação direta de medição adaptável à conectividade observada.

### Decisão 43
- **Título:** Jornada única de Deep Check.
- **Status Atual:** **Vigente.**
- **Resumo:** Supera a divisão anterior de Quick Check; todo teste executa ciclo completo de repouso e carga.

### Decisão 44
- **Título:** Identidade visual de capas geradas do catálogo.
- **Status Atual:** **Vigente.**
- **Resumo:** Estilo visual padronizado e autoral para capas da biblioteca de jogos.

### Decisão 45 e 46
- **Títulos:** Exceção Gemini Release 1.0.0 e Reconciliação com consentimento móvel.
- **Status Atual:** **Vigentes.**
- **Resumo:** Garantia de operação offline/graciosa e respeito ao tráfego do usuário.

### Decisão 47
- **Título:** Progressão visual com Pulse Gauge Coral Solar.
- **Status Atual:** **Superada** pela Decisão 52.
> [!NOTE]
> Animações e referências baseadas no formato Pulse Gauge foram ajustadas para o símbolo Dual-Node Vector.

### Decisão 48 e 49
- **Títulos:** Carregamento com IA e Medição Geral de Jogos.
- **Status Atual:** **Vigentes.**
- **Resumo:** Suporte a partidas de qualquer jogo e micro-interações de espera agradáveis.

### Decisão 50
- **Título:** Reposicionamento MVP — Ready for Ranked.
- **Status Atual:** **Vigente (Fundação Atual do Produto).**
- **Resumo:**
  1. Jornada direta: `Home → Jogo → Check → Veredito`;
  2. Contrato semântico `GameReadinessVerdict` (`.ready`, `.caution`, `.notReady`, `.inconclusive`);
  3. Integridade diagnóstica inegociável: proibição de presumir gateway `.1`, sem notas inventadas e descarte estrito quando amostras forem insuficientes;
  4. Telemetria anônima enxuta em `POST /v1/telemetry` para validação de retenção sem PII/IP.

### Decisão 51
- **Título:** Direção Visual Dark Competitive UI e Iniciativa Unificada.
- **Status Atual:** **Vigente (Direção Visual Vigente).**
- **Resumo:** Design system escuro de alta performance: fundo `#0B0D10`, superfícies grafite `#15181E`, painéis com borda de 1px, sem "card soup", 2 abas (`Início | Jogos`), telemetria viva compacta e Coral Solar `#FF5A36` de ação exclusiva.

### Decisão 52
- **Título:** Marca: Dual-Node Vector e Wordmark Kinetic Speed Slant.
- **Status Atual:** **Vigente (Identidade Visual Vigente).**
- **Resumo:** Substitui definitivamente o Pulse Gauge. Símbolo com dois nós em vetor de velocidade, transmitindo a conexão de baixa latência e precisão competitiva.

### Decisão 53
- **Título:** Tipografia Híbrida de Performance.
- **Status Atual:** **Vigente (Tipografia Vigente).**
- **Resumo:** Elimina qualquer traço arredondado (SF Rounded). Display pesado angular para títulos e números monoespaçados estilo cockpit para todas as métricas numéricas.

### Decisão 54
- **Título:** Pílula de telemetria local ao vivo na Home (`LiveNetworkSignalCapsule`).
- **Status Atual:** **Vigente.**
- **Resumo:** Micro-cockpit no topo da Home exibindo latência instantânea, jitter local e tecnologia da interface ativa (Wi-Fi 5GHz / 5G).

### Decisão 55
- **Título:** Especificação de Melhorias em Diagnóstico, Métricas e Integridade de Rede.
- **Status Atual:** **Vigente.**
- **Resumo:** Probes de gateway local com resolução correta de ARP/IP, bufferbloat multidimensional, qualidade amostral e descarte determinístico.

### Decisão 56
- **Título:** Jornada direta em 1 toque, Cockpit de Rede e Otimizações de Setup.
- **Status Atual:** **Vigente.**
- **Resumo:** Início com 1 toque no jogo protagonista, modal de dados técnicos profundos e guia de setup físico por plataforma (PC, Console, Mobile).

### Decisão 57
- **Título:** Hero Gauge Pulsante, Meus Favoritos (até 4) e Exportação de PDF.
- **Status Atual:** **Vigente.**
- **Resumo:** Ação central pulsante "Testar Agora", shelf de jogos favoritos fixados e exportação de PDF vetorizado local (`LagCheckPDFExporter`).

### Decisão 58
- **Título:** Detecção de Pacotes Fora de Ordem (RFC 4737) e Modulação `.caution`.
- **Status Atual:** **Vigente.**
- **Resumo:** Algoritmo determinístico no motor UDP para detectar pacotes que chegam fora de ordem. Se taxa > 1%, o veredito modula para `.caution` prevenindo stuttering.

### Decisão 60
- **Título:** Corte do Atalho de Contexto de Rede para o candidato a TestFlight.
- **Status Atual:** **Vigente.**
- **Resumo:** Corte de formulários manuais de contexto no release; medição opera com dados 100% observados pelo iPhone.

### Decisão 61
- **Título:** Website Oficial: Lançamento em Breve no iOS e Captura de Convites.
- **Status Atual:** **Vigente.**
- **Resumo:** Website em `web/` focado na lista de espera do TestFlight para iOS 17+.

### Decisão 62
- **Título:** Reconciliação documental e conformidade estrita com o gate de TestFlight.
- **Status Atual:** **Vigente.**
- **Resumo:** Validação dos checklists pré-TestFlight e congelamento de escopo.

### Decisão 63
- **Título:** Adoção do Workflow e Governança Unificada Buildea (Paralelismo SignallQ).
- **Status Atual:** **Vigente (Governança Vigente).**
- **Resumo:** Unificação da squad Buildea (Marco, Renan, Rian, Iury, Breno, Camillo, Luiz), 5 pistas de execução (Lanes), `.agents/WORKFLOW.md`, `.agents/architecture-plan.md` e consolidação de `docs/DECISOES.md` como documento único.

### Decisão 64
- **Título:** Diretriz "Zero Cara de IA / Gamer Não Lê", Card Viral para Discord, Dogfooding Obrigatório e Skills Operacionais de Ação.
- **Status Atual:** **Vigente (Produto & Processo).**
- **Frentes envolvidas:** Marco (Lead), Luiz (Dono do Produto), Renan (Design), Breno (QA), Rian (iOS), Iury (Rede).
- **Contexto, Problema e Decisão:**
  1. **Princípio "Zero Cara de IA / Gamer Não Lê" (Diretriz Inegociável do Luiz):**
     - O jovem gamer competitivo **NÃO LÊ**. Textões, blocos didáticos, frases polidas de IA, excesso de cartões soltos ("cardlização") e duplas de títulos com subtítulos explicativos estão **estritamente proibidos** na interface.
     - A UI deve ser visual, direta, limpa e com estética de cockpit/telemetria esportiva. Bateu o olho, entendeu em 1 segundo.
     - Nenhuma métrica ou aviso técnico entra na tela sem passar pela **"Regra do Discord"**: precisa ser traduzível para uma frase curta que o jogador falaria para os amigos na call ("Meu boneco tá sendo puxado pra trás", "Minha rota tá lisa").
  2. **Loop de Retenção e Compartilhamento Viral ("Atestado pro Discord"):**
     - Criação de componente de compartilhamento em 1 toque gerando card visual Dark Competitive UI com o veredito da rota (`● PRONTO PARA RANKED` / `▲ EU EVITARIA`) e o ping do jogo, otimizado para envio no Discord, WhatsApp e Stories.
  3. **Dogfooding Obrigatório e Redução de Atrito de Tempo:**
     - Todos os membros da squad devem rodar o build no iPhone físico antes de suas partidas reais diárias.
     - O Breno audita ativamente a percepção de tempo: o teste precisa ser rápido o bastante para não frustrar o jogador que já está no lobby esperando a fila puxar.
  4. **Skills Operacionais de Ação:**
     - Criação de skills procedimentais de ação direta (`testflight-gate` e `competitive-benchmark`), separando claramente manuais de personas de checklists executáveis.

### Decisão 65
- **Título:** Validação Científica Completa (12s, 3 Fases), Fallback de Jogo Não Listado, Cockpit Expandido e Blindagem Anti-Glitches Visuais.
- **Status Atual:** **Vigente (Execução Total).**
- **Frentes envolvidas:** Marco (Lead), Luiz (Dono do Produto), Renan (Design), Rian (iOS), Iury (Rede), Breno (QA), Camillo (Arquiteto).
- **Contexto, Problema e Decisão:**
  1. **Validação Matemática Real (Baseada no `lagcheck-deep-research-report.md`):**
     - Em conformidade com a determinação explícita do Luiz (*"Se tiver que demorar pra uma medição correta, eu prefiro a correta"*), o ciclo de teste é fixado em **10 a 12 segundos** para atender rigorosamente à física de rede.
     - **Fase 1 (0 a 4s - Baseline de Repouso):** Disparo de 30 a 40 datagramas UDP de 500-1200 bytes nos servidores oficiais do jogo. Cálculo de P50 e desvio padrão de Jitter sem ruído.
     - **Fase 2 (4 a 9s - Estresse de Bufferbloat sob Carga):** Carga contínua via Cloudflare Worker (`/v1/load`) para saturar a fila do roteador, acompanhada de feedback háptico no iPhone e exibição da variação de ping em tempo real.
     - **Fase 3 (9 a 11s - Auditoria de Integridade e Topologia):** Detecção determinística de pacotes fora de ordem (RFC 4737) e verificação de NAT/CGNAT (STUN RFC 5389).
     - **Segundo 12:** Veredito afirmativo `GameReadinessVerdict` cravado.
  2. **Tratamento de Jogos Não Listados (Fallback Universal):**
     - Toda busca sem correspondência exata gera com 1 toque a opção *"Medir Rota Geral para [Nome digitado]"*.
     - O perfil "Rota Geral Competitiva" fica permanentemente acessível na Home e no topo do Catálogo, testando contra os clusters de jogos mais robustos do país (AWS SP / Azure SP).
  3. **Arquitetura de Telas 360 Graus:**
     - Navegação estruturada em 2 abas (`Início | Jogos`), com acesso contextual a Histórico (topo direito) e Ajustes (topo esquerdo).
     - Painel técnico "Dados da Rede" acessível sob demanda no rodapé do resultado, sem poluir a visão do usuário comum.
  4. **Blindagem Anti-Glitches Visuais (Diretriz Inegociável do Luiz):**
     - **Zero telas sambando:** Uso de `ViewThatFits` e paddings de safe area responsivos de iPhone SE a Pro Max.
     - **Zero botões sobrepostos:** Hierarquia de camadas (Z-Index) e espaçamento de TabBar auditados.
     - **Zero contraste fraco:** Conformidade estrita WCAG AAA na Dark Competitive UI (fundo `#0B0D10`, cards `#15181E`, texto `#F4F5F7`, acento `#FF5A36`).
     - **Zero texto de IA:** Frases secas, objetivas e funcionais.

### Decisão 66
- **Título:** Adoção Integral do Design System LagCheck Canônico (Roxo Gamer Primário, Coral Solar para Atenção/Destrutivo, 3 Pilhas Tipográficas e Escala Geométrica Canônica).
- **Status Atual:** **Vigente (Design System Canônico).**
- **Frentes envolvidas:** Renan (Design), Rian (iOS), Marco (Lead), Luiz (Dono do Produto), Breno (QA).
- **Contexto, Problema e Decisão:**
  1. **Migração para o Design System LagCheck Canônico:**
     - Substituição integral de todos os tokens e componentes pelo sistema canônico localizado em Open Design (`e9c0abe1-0267-461b-8ee3-08ed90d3b70a`).
  2. **Papéis Estritos de Cor:**
     - **Roxo Gamer (`#7C3AED` / `oklch(0.585 0.214 299)`):** Cor primária de ação (`accentPrimary`), foco (`borderFocus`), seleção de plataforma/jogos, progresso de medição e links (`textLink`).
     - **Coral Solar (`#FF5A36` / `oklch(0.684 0.196 35)`):** Estritamente reservado para atenção, indicação de risco de lag, erros ou ações destrutivas (ex.: apagar histórico). Proibido usar Coral Solar para botões de ação ordinários ou seleções.
     - **Superfícies Escuras:** Fundo profundo (`#0B0D10`), superfícies (`#15181E`), painéis (`#1E232B`), bordas finas de 1px (`#262D38`).
  3. **3 Pilhas Tipográficas Fundamentais:**
     - **Display (`ui-rounded`, heavy/bold):** Manchetes de veredito (`NLTypography.verdictHeadline`), nomes de jogos e títulos hero.
     - **Corpo (`-apple-system`):** Textos descritivos, notas de contexto e botões de ação (`NLTypography.ctaButton`, 16pt heavy).
     - **Técnica (`ui-monospace`):** Leituras numéricas de latência, jitter, perda e evidências de rede (`NLTypography.metricsNumber`).
  4. **Escala Geométrica e Botão de Ação Primária:**
     - Raios padronizados: 8px (mídia/capas), 13px (cards/inputs/containers), 17px (botão/CTA), 26px (sheet/hero modal) e 999px (pills/chips).
     - Botão primário (`PrimaryButton`): Altura de 58px (`NLSizing.primaryButtonHeight`), largura mínima de 220px, raio de 17px e sombra de ação Roxo Gamer (`shadow.action`).
     - Apenas um CTA primário por viewport para a mesma ação.
  5. **Ativos Oficiais:**
     - Wordmark oficial: `wordmark-primary.svg` com símbolo e "Check" em Roxo Gamer, e "Lag" em branco.
     - Ícone do aplicativo: fonte `app-icon-source.svg` com gradiente roxo gamer (`#5B21B6` -> `#7C3AED` -> `#A78BFA`).

---

## Como Registrar Novas Decisões

1. Adicione a linha correspondente no [Índice Rápido](#índice-rápido-de-decisões-e-status-de-vigência) marcando o status como `Vigente` (ou indicando se substitui alguma decisão anterior);
2. Adicione uma nova subseção numerada ao final deste documento detalhando:
   * **Título**
   * **Status Atual** (`Vigente`, `Superada por X` ou `Em implementação`)
   * **Frentes envolvidas**
   * **Contexto, Problema e Decisão Tomada**
   * **Critérios de validação e aceite**
3. Nunca crie arquivos separados de decisão.
