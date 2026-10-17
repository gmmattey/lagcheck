# LagCheck — Registro Canônico de Decisões

> **Autoridade:** Este é o **único documento oficial de decisões** de produto, arquitetura, design e infraestrutura do LagCheck.
> **Regra de atualização:** Novas decisões não criam novos arquivos markdown soltos. Elas são registradas diretamente neste documento, em ordem cronológica crescente, após alinhamento entre Marco (estratégia e orquestração), Giam (Product Owner operacional), as frentes responsáveis (Renan, Rian, Iury, Breno, Camillo) e autorização do dono do produto (Luiz).
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
| [67](#decisão-67) | Expansão Multiplataforma: Rascunho Arquitetural e Telemetria Avançada de Rádio no Android | **Vigente (Expansão Android)** | Módulo de rádio (2.4G/5G/6G, RSSI, PHY speed, Gateway), paridade determinística e custo zero | Marco / Camillo / Iury / Luiz |
| [68](#decisão-68) | Port iOS → Android com paridade de regras (readiness-v2.0, catálogo v3 assinado, beacons) | **Vigente (Execução)** | Substitui a medição STUN e os thresholds fixos do protótipo Android; Android passa a ser alvo oficial | Marco / Camillo / Iury / Luiz |
| [69](#decisão-69) | Android: gateway no veredito, status de redes de console, favoritos e relatório em PDF | **Vigente (Execução)** | Refina o item 6 da Decisão 68: liga o gateway no veredito (autorizado pelo Luiz) e entrega o que tinha sido cortado por escopo | Marco / Iury / Luiz |
| [70](#decisão-70) | Expansão do catálogo: quatro jogos e artes autorais | **Vigente (assinatura pendente)** | Dead by Daylight, For Honor, Borderlands 3 e New World; candidato local de 26 jogos | Marco / Luiz |
| [71](#decisão-71) | Catálogo e artes remotos nos apps | **Vigente (implementação local)** | Ed25519 mantida, imagens sem conferência de hash, descoberta dinâmica Android | Marco / Camillo / Luiz |
| [72](#decisão-72) | Unificação do Motor de Cálculo e Veredito (Fim das Divergências entre Score, Veredito e Detalhes) | **Vigente (Execução)** | Cálculo único em GameReadinessEvaluator, guardrail por veredito no score, consumo 1:1 na UI | Marco / Camillo / Iury / Rian / Renan / Luiz |
| [73](#decisão-73) | Indicador Visual Tático de Veredito (Substituição de Glifos Unicode por VerdictIndicatorBadge) | **Vigente (Design & UI)** | Substitui caracteres de texto cru (●/▲/—) por componente de cockpit com LED/Halo e ícones vetoriais acessíveis | Renan / Rian / Marco / Luiz |
| [74](#decisão-74) | Plano de Crescimento, Viralidade Discord e ASO da App Store (Fase 1: P0) | **Vigente (Aprovada)** | Aprovação do plano de 9 iniciativas: Card Viral Squad Pass, ASO e Bufferbloat Score | Marco / Squad / Luiz |
| [75](#decisão-75) | Fase 2 (P1) — Retenção & Diferenciação Técnica: Ping por Datacenter, Isolador de Causa Raiz e Widgets iOS 17 | **Vigente; widgets refinados pela Decisão 88** | A implementação existente permanece iOS; o recorte de widget por jogo e Android passa a ser o da Decisão 88 | Marco / Camillo / Iury / Rian / Renan / Breno / Luiz |
| [76](#decisão-76) | Fase 3 (P2) — Ecossistema & Fricção Zero: In-App Events, Spotlight Search & Siri Shortcuts, e App Clip Instantâneo | **Vigente (Em implementação)** | CoreSpotlight, App Shortcuts por voz/busca, deeplinks dinâmicos de jogo e App Clip leve (<15MB) | Marco / Camillo / Rian / Renan / Breno / Luiz |
| [77](#decisão-77) | Sistema Unificado de Avaliação In-App (StoreKit & Google Play In-App Review) | **Vigente (Execução)** | Gatilho de delight (3 checks .ready), cooldown de 90 dias, 1 por versão, sem pre-prompts | Marco / Rian / Camillo / Renan / Breno / Luiz |
| [78](#decisão-78) | Ativação de Probes Reais Homologados (Steam A2S & PlayFab QoS), Expansão Multirregional e Transparência de Precisão (Catálogo v4) | **Em homologação técnica** | Bancada de teste de pacotes UDP para A2S/PlayFab, sem rotas presumidas, integridade diagnóstica | Marco / Camillo / Iury / Rian / Renan / Breno / Luiz |
| [79](#decisão-79) | Pesquisa de Rede & Homologação Técnica do Protocolo Valve SDR para CS2 e Dota 2 | **Em homologação técnica** | Bancada de análise de framing SDR da Valve em SP (12-20ms) sem atalhos diagnósticos | Marco / Camillo / Iury / Rian / Breno / Luiz |
| [80](#decisão-80) | Protótipo Android canônico (One UI) e remoção da seleção de dispositivo no Android | **Vigente (Em implementação)** | `design-system/prototypes/android-reference/` é a referência visual do Android; o aparelho é sempre o celular, sem escolha de plataforma. iOS inalterado | Marco / Renan / Rian / Breno / Luiz |
| [90](#decisão-90) | Referência regional global por proximidade medida | **Vigente (Em implementação)** | Refina as Decisões 16, 78 e 89: sem fixação em São Paulo | Marco / Iury / Rian / Camillo / Breno / Luiz |
| [81](#decisão-81) | Compartilhamento do resultado no Android: cartões e vídeo gerados no aparelho | **Vigente (Em implementação)** | Porte do gerador do site (cartões 1200×630 e 1080×1920 e vídeo 9:16 de 14 s) com a identidade do LagCheck; só números medidos; sem rede | Marco / Rian / Renan / Breno / Luiz |
| [82](#decisão-82) | Anúncios no Android (AdMob, banner só em Home e Histórico), desligados no beta | **Vigente (Implementado, ligado)** | Banner adaptativo, UMP, sem ATT; flag `lagcheck.adsEnabled` verdadeira por padrão; IDs de teste do Google até haver IDs reais | Marco / Rian / Iury / Breno / Luiz |
| [83](#decisão-83) | Ícone do app com mascote no Android (Clássico, Joinha, Piscadinha, Comemorando) | **Vigente (Implementado)** | Um activity-alias por ícone, trocado em Configurações; sem reinstalar | Marco / Renan / Rian / Luiz |
| [84](#decisão-84) | Giam como Product Owner Operacional e Gate de Qualidade da Squad | **Vigente (Governança)** | Refina a divisão de papéis da Decisão 63: Giam enquadra e aceita missões; Marco lidera estratégia e orquestração | Giam / Marco / Luiz |
| [85](#decisão-85) | Retirada do gate entre MVP1 e MVP1.1 | **Vigente (Produto)** | Telemetria informa prioridade, mas não bloqueia escopo de retenção ou evolução aprovada | Luiz / Giam / Marco |
| [86](#decisão-86) | Ritual honesto do Histórico por jogo | **Vigente (Implementado localmente; validação visual pendente)** | Resumo local comparável em 7/14/30 dias; sem previsão ou causa | Luiz / Giam / Marco / Squad |
| [87](#decisão-87) | Lembrete local pré-partida, configurado pela pessoa | **Vigente (Autorizada)** | Opt-in local, um horário diário e abertura do Check sem execução automática | Luiz / Giam / Marco / Rian / Renan / Breno |
| [88](#decisão-88) | Widget de prontidão por jogo — arte oficial por plataforma e Check direto | **Vigente (Implementado localmente; validação visual/física pendente)** | Refina a #49 e a Decisão 75: iOS e Android mostram a arte editorial do último Check válido e iniciam novo Check daquele contexto por toque explícito | Luiz / Giam / Marco / Camillo / Rian / Renan / Iury / Breno |
| [89](#decisão-89) | Ativação coordenada do catálogo de 48 jogos por referência regional | **Vigente (assinatura e publicação pendentes)** | Refina a Decisão 70: os 26 jogos preparados entram com referência AWS regional, nunca como rota própria de jogo | Luiz / Giam / Marco / Iury / Rian / Breno |
| [91](#decisão-91) | Ícone do app modernizado (glifo com profundidade) em iOS e Android | **Vigente (Implementado localmente; validação em simulador, emulador e launchers pendente)** | Substitui o ícone chapado; iOS com Dark e Tinted, Android adaptativo dentro da zona segura de 66 dp com monocromático | Luiz / Giam / Marco / Renan / Rian / Breno |
| [92](#decisão-92) | Wordmark com o símbolo modernizado e mono refeito a partir do primary | **Vigente (Implementado localmente; validação visual pendente)** | Revisa o item 5 da Decisão 91: primary, mono claro/escuro e PNGs de app passam a usar o mesmo símbolo e as mesmas letras | Luiz / Giam / Renan / Rian / Breno |
| [93](#decisão-93) | AGENTS.md alinhado ao estado real de anúncios e arte de jogo | **Vigente (Documentação)** | Android com AdMob (Decisão 82) e arte editorial autoral do catálogo (Decisões 18, 44, 71 e 88); iOS segue sem anúncios | Luiz / Giam |



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

### Decisão 67
- **Título:** Expansão Multiplataforma: Especificação Técnica e Rascunho Arquitetural do LagCheck para Android com Telemetria Avançada de Rádio.
- **Status Atual:** **Vigente (Expansão Android).**
- **Frentes envolvidas:** Marco (Product Lead), Luiz (Dono do Produto), Camillo (Arquiteto Sistêmico), Iury (Engenheiro de Redes), Renan (Design System).
- **Contexto, Problema e Decisão:**
  1. **Abertura da Trilha Android:**
     - Autorizada pelo dono do produto (Luiz) a preparação da infraestrutura do repositório e elaboração da arquitetura técnica para suportar o LagCheck no ecossistema Android nativo (Kotlin / Jetpack Compose).
  2. **Diferencial Competitivo — Telemetria de Rádio Sem Sandbox Fechado:**
     - O Android expõe dados de hardware e rádio que a Apple bloqueia no iOS (`WifiInfo.getFrequency()`, `getRssi()`, `getTxLinkSpeedMbps()`, `getWifiStandard()`, `LinkProperties.getRoutes()`).
     - O LagCheck Android usará essas métricas para identificar instantaneamente se o jogador está conectado em Wi-Fi 2.4 GHz vs 5 GHz vs 6 GHz, o nível de sinal real em dBm, queda de velocidade PHY e perda física de pacotes no ar vs rota externa.
     - Cumpre a **Decisão 50 (Integridade Diagnóstica)** com dados empíricos de hardware e a **Decisão 64 (Regra do Discord)** com badges rápidas de telemetria sem textão explicativo.
  3. **Preservação de Custo Operacional Zero:**
     - O app Android consumirá os mesmos contratos e endpoints do Cloudflare Worker já existente (`nolaggy-deep-check`): `GET /v1/catalog.json` (assinado Ed25519), `GET /v1/load` (bufferbloat) e `POST /v1/telemetry` (retenção anônima). Zero custo adicional de backend ou serviços pagos.
  4. **Estrutura Modular e Paridade de Domínio:**
     - Repositório preparado com módulo Android limpo sob `android/`: `:core:domain` (puro Kotlin, port direto de `NolaggyDomain` com os mesmos vetores determinísticos), `:core:network` (STUN RFC 5389, RFC 4737 e bufferbloat), `:core:telemetry-radio` (APIs nativas de rede/rádio Android) e `:ui` (Dark Competitive UI com Roxo Gamer `#7C3AED` e tokens canônicos em Compose).
  5. **Política de Permissões e Degradação Graciosa:**
     - Se o usuário conceder permissões de rádio (`NEARBY_WIFI_DEVICES`), o app ativa a telemetria detalhada de rádio. Se negar, o teste de ping/jitter/loss UDP para os servidores de jogo ocorre normalmente com máxima privacidade.

### Decisão 68
- **Título:** Port iOS → Android com paridade de regras: readiness-v2.0, catálogo v3 assinado e beacons de jogo.
- **Status Atual:** **Vigente (Execução).** Refina a Decisão 67 e **substitui** a linha "somente iPhone / Android fora do escopo" do `AGENTS.md`.
- **Frentes envolvidas:** Marco, Luiz (autorizou "port completo, fim a fim"), Camillo, Iury, Rian (revisão de contrato), Breno (homologação).
- **Contexto e Problema:**
  1. O módulo Android da Decisão 67 era um protótipo: thresholds fixos, medição contra STUN do Google, catálogo hardcoded, fase de carga simulada partindo um único fluxo de probes e telemetria do Worker sem uso. Um mesmo jogador podia receber veredito diferente no iOS e no Android.
  2. As artes de jogo no Android (`res/drawable/game_*.jpg`) foram verificadas por SHA-256 contra `worker/catalog/artwork-manifest.json` (política `lagcheck-editorial-original-only`, status `approved`). Estão em conformidade com as Decisões 18/44.
- **Decisão:**
  1. O código Swift em `Sources/NolaggyDomain` e o catálogo v3 assinado são a fonte de verdade. O Kotlin é port 1:1 de `QualityEvaluator`, `SampleQualityEvaluator`, `SpikePatternEvaluator`, `DeepCheckEvaluator` (carga v2), `ResultInterpreter` e `GameReadinessEvaluator` (readiness-v2.0). Mantêm-se as versões de regra (`pilot-2026.09.08.1`, `mobile-realtime-2026.09.08.1`, `casual-realtime-2026.09.08.1`, `readiness-v2.0`, `spike-pattern-v1`, `sample-quality-v1`, `deep-load-impact-v2`).
  2. A medição usa os destinos do catálogo (`gameLiftPing`, `playFabQoS`, `steamA2S`), 30 probes a cada 500 ms, janela de fechamento de 17 s e resposta válida somente com correlação integral. STUN deixa de ser destino de medição.
  3. Repouso e carga são duas séries independentes. O veredito avalia o repouso e penaliza a degradação sob carga.
  4. O catálogo v3 é verificado com Ed25519 em Kotlin puro (sem SDK novo), com base embarcada e atualização diária.
  5. O contexto `iphone` do catálogo é usado como contexto de celular no Android até o catálogo ganhar `android` (exige nova assinatura do dono da chave).
  6. **Fase 2 (implementada):** banda Wi-Fi, qualidade de voz, NAT/STUN (CGNAT e NAT duplo), probe de gateway por DNS/UDP, recomendações por evidência e EN/ES na interface. Regras de segurança diagnóstica:
     - A frequência real do rádio (`WifiInfo.getFrequency()`) é a única evidência que confirma banda 2.4 ou 5/6 GHz. SSID, RTT e jitter nunca afirmam frequência (Decisão 50).
     - O probe de gateway mede e exibe (Cockpit, voz). **Superado pela Decisão 69:** ele agora também entra no veredito e nas recomendações.
     - Recomendação que atribui a causa à rota ou à operadora só sai com o primeiro salto comprovadamente limpo.
     - NAT só é medido em jogo P2P ou híbrido. IPs são guardados só mascarados.
     **Não implementado:** Connection Booster (chama a API do Gemini com chave embutida no binário: fere o custo recorrente zero e expõe segredo; só com nova decisão do dono do produto). PlatformHealth, favoritos e relatório em PDF foram cortados por escopo e entregues na Decisão 69.
  7. Custo recorrente zero preservado. Nenhum endpoint novo no Worker.
- **Critérios de validação e aceite:** ver `.agents/architecture-plan.md` §7.4. Estados reportados separadamente: documentado, implementado, testes JVM verdes, compilado, validado em aparelho.

### Decisão 69
- **Título:** Android: gateway no veredito, status de redes de console, favoritos e relatório em PDF.
- **Status Atual:** **Vigente (Execução).** Refina o item 6 da Decisão 68.
- **Frentes envolvidas:** Marco, Luiz (autorizou), Iury (regra de veredito), Rian (contrato), Breno (homologação em aparelho).
- **Contexto e Problema:** Na Fase 2 (Decisão 68) o gateway ficou fora do veredito e três itens foram cortados por escopo, sem decisão de produto. O Luiz pediu os três e a ligação do gateway.
- **Decisão:**
  1. **Gateway no veredito.** `LocalDiagnostics.gatewayInfluencesVerdict` passa a `true`. Risco aceito pelo dono do produto: o RTT vem de uma consulta DNS (RD=1) que o roteador pode encaminhar para fora e inflar o tempo, então um roteador lento a DNS pode rebaixar o veredito e disparar a recomendação "aproxime-se do roteador" sem que o Wi-Fi seja a causa. Mitigações mantidas: sem resposta continua `Unobservable` e nunca acusa o Wi-Fi; recomendação de rota ou operadora só com primeiro salto limpo (Decisão 50). **Divergência conhecida:** o iOS não usa o gateway no veredito, então o mesmo jogador, na mesma rede, pode ver veredito diferente entre iOS e Android. Pendente: validar em aparelhos e roteadores diferentes (Breno) e revisão de Iury; se o desvio aparecer, reverter é uma linha (default do flag).
  2. **Status das redes de console (PlatformHealth).** Port da Decisão 30: PSN, Xbox Live e Nintendo, consultados direto nos endpoints públicos das fabricantes (sem Worker, sem identificação, cache de 10 min, timeout de 3 s). Falha de rede, HTTP diferente de 200 ou formato inesperado = `Unknown`: o app não mostra nada, nunca inventa queda nem "operacional". Só avisa com problema reportado, na Home, com símbolo e selo (não depende só de cor). Celular e PC não consultam. **Não verificado:** os três endpoints não puderam ser acessados no ambiente de desenvolvimento; os parsers foram testados só com payloads copiados dos testes do iOS. Se um formato mudou, o efeito é o aviso não aparecer.
  3. **Favoritos.** Local, no aparelho, sem sincronização. Estrela em cada jogo; seção "FAVORITOS" no topo da lista. Ids que saem do catálogo são ignorados.
  4. **Relatório em PDF.** Geração local com `PdfDocument` do Android (A4, sem biblioteca, sem rede), compartilhado como `application/pdf`. O conteúdo vem de `RouteReport` (domínio): só o observado, campo sem leitura sai como "—", rodapé afirma que é estimativa da rota e não o ping real do jogo.
  5. Custo recorrente zero preservado. Nenhum endpoint novo no Worker, nenhum SDK novo.
- **Não implementado (continua dependendo de decisão):** Connection Booster.
- **Critérios de validação e aceite:** testes JVM (parsers, cache e fail-open do status; `RouteReport`; `FavoriteGames`; gateway ligado e desligado no orquestrador); varredura de tradução EN/ES. Estados: implementado e testado na JVM; type-check do app; **sem build AGP e sem aparelho**. O PDF nunca foi gerado de fato (`PdfDocument` só roda no Android).

---

### Decisão 70
- **Data:** 3 de outubro de 2026.
- **Título:** Inclusão de Dead by Daylight, For Honor, Borderlands 3 e New World: Aeternum.
- **Status Atual:** **Vigente; candidato local preparado, assinatura e ativação pendentes.**
- **Frentes envolvidas:** Luiz (solicitação explícita), Marco (escopo), design, catálogo iOS/Android.
- **Decisão:** Acrescentar os quatro jogos ao catálogo, com artes geradas originais semelhantes às existentes e inspiradas no gênero de cada jogo, sem copiar capas, logos ou personagens oficiais. Amplia a autorização da Decisão 44 apenas para estas quatro artes.
- **Plataformas:** Dead by Daylight e Borderlands 3: PC, PlayStation, Xbox, Nintendo; For Honor e New World: Aeternum: PC, PlayStation, Xbox. Não incluir versões mobile.
- **Medição:** Usar o contrato existente, perfil `CASUAL_REALTIME` e referência regional AWS São Paulo. Rota própria continua pendente. Nenhuma alteração de score, thresholds, versão de regra ou promessa de ping real. Uso de AWS pelo publisher não comprova equivalência da rota de partida.
- **Limites:** Nenhum deploy, upload, publicação, alteração de chaves ou endpoint. `catalog-v3.candidate.json` é o payload não assinado para revisão/assinatura externa. O envelope assinado vigente e os catálogos embarcados permanecem intactos; a apresentação Android dos novos jogos fica em `pendingExpansion` até ativação conjunta com o envelope novo.
- **Aceite:** Candidato com 26 IDs únicos, plataformas corretas, arte com SHA-256 e dimensões verificadas, cópias locais idênticas entre plataformas. Antes de ativar: assinatura Ed25519 com a chave vigente, atualização coordenada dos envelopes iOS/Android/Worker e prateleira Android, testes de resolução e QA visual em aparelhos.
- **Fontes de plataformas:** [Dead by Daylight](https://support.deadbydaylight.com/hc/en-us/articles/360047727671-Which-platforms-are-included-in-cross-play), [For Honor](https://www.ubisoft.com/en-us/company/about-us/our-brands/for-honor), [Borderlands](https://borderlands.2k.com/es-MX/buy/), [New World](https://www.newworld.com/en-us/game/faq).

### Decisão 71
- **Data:** 3 de outubro de 2026.
- **Título:** Catálogo e artes atualizados remotamente em iOS e Android.
- **Status Atual:** Implementado localmente; APK Android e testes JVM validados. Build Xcode e suíte iOS validados no Mac em 2026-10-03; catálogo/artes observados em simulador. Prova física e distribuição pendentes (ver `audits/mac-continuation-2026-10-03.md`).
- **Frentes envolvidas:** Marco, Camillo (plano e segunda opinião), implementação iOS/Android.
- **Decisão:** Luiz autorizou baixar catálogo e artes pelo Cloudflare. Preservar assinatura Ed25519 do catálogo e dispensar comparação do hash dos bytes das imagens. Refina Decisões 37/40/70 e o pipeline de assets da especificação técnica: SHA no schema 3 permanece para compatibilidade, sem impedir exibição quando os bytes diferirem. Não rotacionar chave.
- **Comportamento:** Catálogo validado determina descoberta e plataformas; novos jogos aparecem após publicação de envelope válido sem novas builds. Artes remotas com cache local e fallback empacotado/neutro. Uma build inicial é necessária em cada plataforma.
- **Limites:** Sem alteração de medição ou SDK, sem endpoint novo; downloads de arte não devem competir com Check. Preparação local não é assinatura, publicação, instalação nem prova em aparelho.
- **Aceite:** Testes de catálogo/cache e mapeamento dinâmico; bytes e dimensões limitados, HTTPS e cancelamento; validar compilação e aparelhos conforme ambiente. Expansão de 26 jogos ainda depende de envelope assinado pela chave vigente.

### Decisão 72
- **Data:** 4 de outubro de 2026.
- **Título:** Unificação do Motor de Cálculo e Veredito (Fim das Divergências entre Score, Veredito e Detalhes).
- **Status Atual:** **Vigente (Execução).**
- **Frentes envolvidas:** Marco (Product Lead), Camillo (Principal Engineer / Gate Arquitetural), Iury (Network & Edge Systems), Rian (iOS), Renan (Design System) e Luiz (autorização e diretriz).
- **Contexto e Problema:** Ao realizar um teste de conexão, a tela principal de resultado exibiu o veredito semântico `▲ CONDIÇÕES INSTÁVEIS` (Âmbar). Porém, ao abrir a folha secundária de "Entender conexão / Detalhes técnicos", a tela exibia `● MUITO BOM` (Verde), nota `88` e telemetria aparentemente estável. O diagnóstico revelou a existência de avaliadores paralelos no domínio: `QualityEvaluator` calculava o score (88) e a classe (`.great`) olhando apenas para o repouso; `GameReadinessEvaluator` rebaixava o veredito para `caution` ao detectar impacto sob carga (bufferbloat) ou dispersão de cauda, mas não recalculava nem limitava o score numérico; e `TechnicalDetailsView` consumia `result.restResult.resultClass` isolado. Essa discrepância destruía a percepção de confiabilidade do app.
- **Decisão:**
  1. **Motor Único de Domínio:** O `GameReadinessEvaluator` passa a ser o único avaliador canônico do teste, unificando o cálculo de veredito, score numérico integrado, estabilidade e achados em uma única passada determinística.
  2. **Acoplamento Matemático (Guardrail Estrutural por Veredito):** O score numérico passa a ter tetos rígidos vinculados ao veredito de prontidão:
     - `.ready`: score na faixa **75–100** (Pronto para ranked).
     - `.caution`: score obrigatoriamente limitado a **60–74** (Faixa instável; é matematicamente impossível um resultado instável pontuar 88).
     - `.notReady`: score obrigatoriamente limitado a **0–59** (Evitaria ranked / alto risco).
     - `.inconclusive`: score estritamente `nil` (exibido como `—`, sem notas inventadas).
  3. **Penalização Integrada de Carga:** O impacto sob carga (bufferbloat) reduz diretamente o score numérico e modula o veredito de forma simultânea.
  4. **Consumo 1:1 na Interface:** Extinção do `resultClass` e de classificações paralelas na apresentação. A folha de Detalhes Técnicos (`TechnicalDetailsView`) passa a consumir rigorosamente a mesma `GameReadinessEvaluation`, exibindo o mesmo símbolo, cor, veredito e score coerente.
  5. **Paridade Android:** A mesma regra de teto no score subordinado ao veredito é replicada no módulo `:core:domain` Kotlin.
- **Critérios de validação e aceite:** Testes unitários do domínio comprovando que testes com carga material produzem veredito `.caution` e score no intervalo `60..74`; testes de regressão verdes; ausência de qualquer texto "MUITO BOM" na tela de detalhes quando o veredito for de atenção.

### Decisão 73
- **Data:** 5 de outubro de 2026.
- **Título:** Indicador Visual Tático de Veredito (Substituição de Glifos Unicode por `VerdictIndicatorBadge`).
- **Status Atual:** **Vigente (Design & UI).**
- **Frentes envolvidas:** Marco (Product Lead), Renan (Design System), Rian (iOS), Equipe Android e Luiz (diretriz de refinamento).
- **Contexto e Problema:** Os símbolos geométricos de texto cru (`●`, `▲`, `—`) inseridos diretamente nas strings ou concatenados ao lado das manchetes de veredito davam um aspecto amador e de caracteres Unicode genéricos/antigos. Embora a diferenciação por forma seja um requisito inegociável de acessibilidade (WCAG/HIG para daltonismo), a forma de apresentação devia refletir a sofisticação da **Dark Competitive UI** e o clima de cockpit de telemetria esportiva.
- **Decisão:**
  1. **Substituição de Glifos por Componente Tático:** Fica abolido o uso de caracteres de texto soltos (`●` e `▲`) na apresentação do veredito. Em seu lugar, adota-se o componente nativo `VerdictIndicatorBadge` (SwiftUI e Jetpack Compose).
  2. **Anatomia Visual Cockpit/HUD:**
     - `.ready`: Dot de LED luminoso (12pt) com halo concêntrico sutil de emissão e anel externo em Verde Semântico (`#22C55E`), transmitindo sinal travado e conexão limpa.
     - `.caution`: Micro-badge tático angular / aviso em Âmbar/Laranja (`#F59E0B`), com ícone geométrico de alerta integrado para preservar diferenciação por formato independente de cor.
     - `.notReady`: Micro-badge de corte / atenção em Coral Solar (`#FF5A36`).
     - `.inconclusive`: Indicador tracejado / neutro em Slate (`#64748B`), simbolizando radar sem eco.
  3. **Manchetes Limpas:** O texto da headline (ex: `PRONTO PARA RANKED`, `EU EVITARIA RANKED AGORA`) torna-se tipograficamente puro, sem prefixos de texto misturados à tipografia.
- **Critérios de validação e aceite:** Remoção de strings de texto cru com `●` e `▲` das telas principais (`CheckCompletoResultView`, `TechnicalDetailsView`, `VerdictScreen`); renderização nítida dos novos indicadores; validação de contraste e compilação sem regressões.

### Decisão 74
- **Data:** 6 de outubro de 2026.
- **Título:** Plano de Crescimento, Viralidade Discord e ASO da App Store (Fase 1: P0).
- **Status Atual:** **Vigente (Aprovada).**
- **Frentes envolvidas:** Marco (Product Lead), Renan (Design), Rian (iOS), Iury (Network & Edge Systems), Camillo (Principal Engineer / Gate Arquitetural), Breno (QA & Reliability) e Luiz (aprovação).
- **Contexto e Problema:** Para transformar o LagCheck em um app popular com forte tração orgânica na App Store, o produto precisa se diferenciar radicalmente de utilitários genéricos de banda (Ookla/Fast.com) e de serviços pagos invasivos (ExitLag/NoPing). A squad desenvolveu e o dono do produto aprovou um plano com 9 iniciativas divididas em 3 fases, com início imediato pela Fase 1 (P0).
- **Decisão:**
  1. **Aprovação do Plano de Crescimento:** Fica aprovado o plano estruturado das 9 iniciativas (artefato canônico `plano-implementacao-crescimento-lagcheck.md`).
  2. **Início Imediato da Fase 1 (P0):**
     - **Item 2 (ASO Tático):** Metadados focados em busca de dor do jogador (`LagCheck — Teste de Rede Gamer`, subtítulo `Estabilidade e Rota de Conexão` e keywords de alto volume de intenção de busca).
     - **Item 1 (Card Viral "Squad Pass / Ready Check"):** Componente em `NolaggyDesign` renderizado via `ImageRenderer` nativo (iOS 16+), gerando imagem de cockpit esportivo Dark Competitive para cópia instantânea para a área de transferência (`UIPasteboard`) e envio em 1 toque para Discord, WhatsApp e Stories.
     - **Item 3 (Bufferbloat Score Tático):** Formalização no `NolaggyDomain` do cálculo de impacto sob estresse ($\Delta RTT = RTT_{carga} - RTT_{repouso}$) em notas objetivas de Bufferbloat (Grade A+ a F), sem alterar os guardrails matemáticos da Decisão 72.
  3. **Preservação de Guardrails:** Zero custo operacional recorrente, processamento 100% on-device no iPhone, estrita fidelidade à diretriz "Gamer Não Lê" (Decisão 64) e integridade diagnóstica (Decisão 50).

- **Adendo Técnico e Governança da Fase 1 (Revisão Iury — 06/10/2026):**
  - **Regra e Versão:** A escala de Bufferbloat é formalizada e versionada como `bufferbloat-grade-v1`, implementada com paridade 1:1 em Swift (`NolaggyDomain`) e Kotlin (`:core:domain`).
  - **Tabela Oficial de Limiares ($\Delta RTT$):**
    - **Grade A+:** $\le 2$ ms (Bufferbloat indetectável / excelente).
    - **Grade A:** $\le 5$ ms (Bufferbloat mínimo / ótimo).
    - **Grade B:** $\le 15$ ms (Sob controle / bom).
    - **Grade C:** $\le 35$ ms (Oscilação moderada sob estresse / cautela).
    - **Grade D:** $\le 60$ ms (Degradação perceptível sob carga / risco alto).
    - **Grade F:** $> 60$ ms (Saturação severa da fila).
  - **Conformidade Estrita de ASO:** Nenhuma marca de terceiro (ex: jogos ou provedores) compõe os metadados de submissão na App Store, eliminando qualquer risco de rejeição (Diretriz Apple 2.3.7) ou promessa falsa de ping de servidores específicos.
  - **Exportador do Card:** Mantém desenho determinístico em alta definição (`LagCheckDiscordCardExporter`), com token de cor semântica Coral Solar para D/F (Decisão 66), garantindo cópia instantânea sem custo de GPU.
  - **Compatibilidade de Persistência:** Payload legado decodifica com fallback automático derivando a nota do $\Delta RTT$ observado.
  - **Débito de QA (Breno):** Benchmark formal de tempo de renderização (<200ms) e validação tátil em iPhone físico alocados para o gate de release da Fase 1.

- **Critérios de validação e aceite:**
  - Metadados ASO prontos para submissão;
  - Card esportivo com renderização `< 200ms` sem travamento de UI;
  - Vetores unitários de Bufferbloat verdes em `NolaggyDomainTests`.

### Decisão 75

- **Data:** 6 de outubro de 2026.
- **Título:** Fase 2 (P1) — Retenção & Diferenciação Técnica: Ping Real por Datacenter, Isolador de Causa Raiz e Widgets Interativos iOS 17.
- **Status Atual:** **Vigente (Implementado localmente; validação visual pendente).**
- **Frentes envolvidas:** Marco (Product Lead), Camillo (Principal Engineer / Gate Arquitetural), Iury (Network & Edge Systems), Rian (iOS), Renan (Design System & Dark Competitive UI), Breno (QA & Reliability) e Luiz (aprovação).
- **Contexto e Problema:** Após a aprovação da Fase 1 (Card Viral Discord, ASO e Bufferbloat Score), o LagCheck inicia a **Fase 2 (P1)** focada em diferenciação técnica inatacável e retenção diária pré-jogo. A proposta resolve 3 dores centrais dos jogadores competitivos:
  1. *Onde o ping está sendo medido?* Provar rotas e datacenters reais (AWS GameLift, PlayFab QoS, Valve A2S e status oficial Riot) com total conformidade de termos de serviço, sem promessas não comprovadas de IPs de matchmaking fechado.
  2. *De quem é a culpa pelo lag?* Expor de forma limpa, esportiva e sem rodeios os 3 probes determinísticos (Gateway Local Wi-Fi, Rota da Operadora via Anycast neutro e Status de Plataforma do jogo), cumprindo estritamente a Decisão 50 (proibido acusar provedor ou Wi-Fi sem evidência comprovada).
  3. *Ritual diário pré-game:* Widgets interativos no iOS 17+ (Lock Screen e Home) lendo telemetria real do último snapshot via App Group compartilhado com ação em 1 toque, sem dados fictícios ou estáticos inventados ("Nunca uma nota inventada").
- **Decisão:**
  1. **Ping Real por Datacenter & Rotas Ativas (Item 4):**
     - O catálogo remoto assinado Ed25519 (`v3`) consolida clusters de alta fidelidade para as regiões ativas (ex: `sa-east-1` AWS, Azure PlayFab SP, Valve CS2 SP).
     - Rota própria com A2S ou PlayFab é selecionada quando há autorização e driver compatível no binário; quando não há, o app utiliza a rota de referência regional neutra da AWS e rotula claramente como *"rota de referência na região"* com confiança média, nunca mentindo que é o IP da partida.
  2. **Isolador de Causa Raiz ("De Quem é a Culpa?") (Item 5):**
     - Formalização do modelo imutável de domínio `RootCauseIsolationReport` com paridade 1:1 Swift/Kotlin.
     - **Critérios de Atribuição com Evidência:**
       - *Wi-Fi / Rede Local:* RTT medido até o gateway real da tabela de rotas do sistema $> 15\text{ ms}$ ou perda local de pacotes comprovada. Se o roteador não responde (firewall local), o status é estritamente `unobservable` e o app reporta *"Gateway não observável (sem evidência local)"*, jamais culpando o Wi-Fi.
       - *Operadora / WAN:* Gateway local excelente ($\le 5\text{ ms}$, zero perda), mas rota Anycast externa ou destino com jitter alto, perda ou oscilações severas.
       - *Servidores / Plataforma:* Resposta oficial degradada obtida em consulta direta e sem custo aos CDNs oficiais (PSN, Xbox Live, Nintendo, Riot Status).
       - *Tudo Limpo:* Todos os 3 probes verdes $\rightarrow$ Conexão pronta e liberada para Ranked.
  3. **Widgets Interativos & Lock Screen iOS 17+ (Item 6):**
     - Adição do target de extensão `LagCheckWidget` configurado com App Group `group.com.lagcheck.app`.
     - Compartilhamento seguro do último snapshot de medição (`WidgetTelemetrySnapshot`) gravado em UserDefaults compartilhado após cada medição real concluída.
     - **Regra "Zero Mock / Nunca uma Nota Inventada":** Se o widget não encontrar um snapshot válido no container ou se o snapshot tiver idade superior a 4 horas (expirado do ponto de vista competitivo), ele exibe o estado neutro de radar sem sinal com a mensagem *"Sem check recente"* e convite *"Toque para medir"*.
     - App Intent `RunQuickCheckIntent` para acionamento direto em 1 toque.
  4. **Paridade Multiplataforma (Decisões 67 e 68):**
     - Toda a lógica de classificação de causa raiz e regras de validação é portada para `:core:domain` no Android, mantendo suítes de testes unitários verdes em ambas as plataformas.
- **Critérios de validação e aceite:**
  - Architecture Plan de Camillo aprovado antes de alterar código dos targets;
  - Testes unitários puros no `NolaggyDomainTests` e `:core:domain:test` cobrindo todos os cenários da causa raiz;
  - Widget renderizando estados vazios, válidos e expirados sem dados estáticos inventados;
  - Build limpo e suítes de testes passando no Xcode e Gradle.

### Decisão 76

- **Data:** 7 de outubro de 2026.
- **Título:** Fase 3 (P2) — Ecossistema & Fricção Zero: In-App Events Sazonais, Spotlight Search, Siri Shortcuts e App Clip Instantâneo.
- **Status Atual:** **Vigente (Em implementação).**
- **Frentes envolvidas:** Marco (Product Lead), Camillo (Principal Engineer transversal / Gate Arquitetural), Rian (iOS / App Intents / App Clip), Renan (Product Designer / HIG & Dark Competitive UI), Breno (QA & Reliability) e Luiz (aprovação).
- **Contexto e Problema:**
  Concluídas a Fase 1 (Viralidade Discord, ASO e Bufferbloat Score) e a Fase 2 (Ping por Datacenter, Isolador de Causa Raiz e Widgets iOS 17), o LagCheck avança para a **Fase 3 (P2)** para transformar o app em um elemento onipresente do ecossistema do jogador e eliminar atrito na call do Discord/lobby:
  1. *Descoberta Sazonal & Editorial (Item 7):* Atração de tráfego orgânico na App Store via *In-App Events* sincronizados com os calendários das temporadas de Ranked dos principais jogos competitivos, sem infligir marcas de terceiros e a custo zero.
  2. *Acesso por Voz e Busca Nativa (Item 8):* Permitir que o jogador busque por "ping", "valorant", "lag", "ranked" no CoreSpotlight do iOS e execute comandos por voz na Siri (*"E aí Siri, testar conexão no LagCheck"*), acionando medições específicas ou atalhos para jogos específicos.
  3. *Fricção Zero na Call do Discord (Item 9):* Quando um jogador envia um link de teste na call (`lagcheck.signallq.com/check?game=valorant`), o amigo no iPhone não pode ter o atrito de baixar 30 MB da App Store. O link abre instantaneamente o **App Clip** (`LagCheckClip`), executando o teste de rota real em menos de 2 segundos, com banner nativo para o app completo.
- **Decisão:**
  1. **In-App Events Sazonais (Item 7):**
     - Estruturação do catálogo de eventos sazonais no App Store Connect sincronizados com seasons (ex: *"Nova Season de Ranked"*).
     - Artes autorais LagCheck (Dark Competitive UI), sem logotipos, capas ou personagens de terceiros (`docs/18`).
     - Deeplink canônico universal: `https://lagcheck.signallq.com/check?game={game_id}` mapeado para acionamento direto do jogo no app. Atualizado em 12 de outubro de 2026 por autorização explícita de Luiz; os hosts `lagcheck.app`, `www.lagcheck.app` e `check.lagcheck.app` deixam de ser aceitos como Universal Links.
     - Android declara as mesmas rotas com `android:autoVerify`; a associação do host será publicada somente com o SHA-256 do certificado de assinatura de produção do pacote `com.lagcheck.app` na Play Console.
  2. **CoreSpotlight & Siri Shortcuts (Item 8):**
     - `SpotlightIndexCoordinator` indexa os títulos do catálogo localmente com palavras-chave relevantes (`ping`, `lag`, `ranked`, `rotas`, nome do jogo).
     - Suporte a deep links parametrizados por jogo (`lagcheck://check?game={id}`) e tratamento gracioso quando o jogo não for encontrado (cai na Home).
     - Enriquecimento do `LagCheckShortcutsProvider` com frases adicionais em PT-BR, EN e ES.
  3. **App Clip Instantâneo (`LagCheckClip`) (Item 9):**
     - Criação do target `LagCheckClip` (tipo `app-clip`) vinculado aos módulos `NolaggyDomain`, `NolaggyInfrastructure` e `NolaggyDesign`.
     - Exclusão estrita do SwiftData do App Clip para manter binário ultraleve (< 15 MB descompactado, limite estrito Apple HIG).
     - Tela única e direta: abre, executa o check real UDP do jogo especificado na URL, exibe o veredito semântico e convida a instalar o app completo para histórico e widgets.
     - Suporte a `apple-app-site-association` em `lagcheck.signallq.com`, configurado para o App ID `2Z4T8228GR.com.lagcheck.app.Clip`.
  4. **Paridade & Integridade:**
     - A lógica de interpretação de URLs de jogos e modelos de indexação mantém paridade e regras determinísticas em pure domain.
- **Critérios de validação e aceite:**
  - Architecture Plan de Camillo assinado para o novo target `LagCheckClip` e entitlements de App Clip;
  - Indexação Spotlight funcionando e testes unitários verdes para indexação e parsing de links;
  - Deeplinks de jogos direcionando e acionando o teste correto;
  - Target `LagCheckClip` e `Nolaggy` compilando sem erros no Xcode;
  - Auditoria independente via Claude Code CLI aprovada antes do commit.

### Decisão 77

- **Data:** 7 de outubro de 2026.
- **Título:** Sistema Unificado de Avaliação In-App (Apple StoreKit & Google Play In-App Review) com Gatilho Determinístico de Delight e Paridade Multiplataforma.
- **Status Atual:** **Vigente (Execução).**
- **Frentes envolvidas:** Marco (Product Lead), Camillo (Principal Engineer transversal), Rian (iOS / StoreKit), Renan (Product Designer / HIG & UX), Breno (QA & Reliability) e Luiz (aprovação).
- **Contexto e Problema:**
  A avaliação nas lojas de aplicativos (App Store e Google Play) é peça fundamental para a estratégia de crescimento orgânico e ASO (Decisão 74). No entanto, o jogador competitivo em lobby de jogo tem tolerância zero para interrupções ou pop-ups invasivos. Se um prompt de avaliação for disparado após uma medição com rota instável (`.caution`), rota ruim (`.avoid`) ou falha inconclusiva, o usuário é induzido a registrar uma avaliação negativa de 1 estrela por frustração com sua própria operadora. Além disso, modais apelativos ("Você está gostando do app?") violam a diretriz de design *"Zero Cara de IA / Gamer Não Lê"* (Decisão 64) e as diretrizes oficiais de avaliação da Apple e Google.
- **Decisão:**
  1. **Política de Elegibilidade e Gatilho de Delight (`ReviewPromptPolicy`):**
     - O prompt só pode ser disparado quando o resultado da medição for estritamente **`● PRONTO PARA RANKED` (`.ready` / `READY_FOR_RANKED`)**.
     - É terminantemente proibido disparar ou computar elegibilidade em vereditos `.caution`, `.avoid` ou `.inconclusive`.
     - Exige acúmulo de pelo menos **3 medições completas com veredito positivo** (`.ready`).
     - Intervalo mínimo de cooldown de **90 dias** entre solicitações exibidas.
     - Limite de no máximo **1 solicitação por versão/build** do aplicativo.
  2. **Experiência Visual & Não Interrupção:**
     - Nenhum pre-prompt customizado ("Rate Us" / "Gostou do app?"). O app aciona exclusivamente a caixa de diálogo nativa oficial do sistema operacional.
     - Transição suave com debounce de 1.5s após a conclusão da medição e estabilização dos dados na tela de resultado.
  3. **Paridade Multiplataforma (iOS ⇄ Android):**
     - No iOS: `ReviewPromptPolicy` em `NolaggyDomain` (pure domain) e `ReviewPromptCoordinator` em `NolaggyApplication`, acionando `StoreKit` (`requestReview`) de forma idempotente em `DeepCheckFeatureView` com proteção de ciclo de vida (`scenePhase`). Excluído expressamente do `LagCheckClip` (App Clip).
     - No Android: `ReviewPromptPolicy` em `:core:domain`, `ReviewPromptCoordinator` em `:core:session` e acionador da Google Play In-App Review API (`ReviewManager`) em `:app` com canal de eventos buffered e guarda de contexto de tela (`Screen.Verdict`).
     - Persistência desacoplada dos contadores (`UserDefaults` no iOS, `SharedPreferences` no Android).
  4. **Critérios de Validação e Aceite:**
     - Testes unitários puros no iOS e Android validando os cenários: bloqueio com veredito ruim, bloqueio com menos de 3 checks, liberação no 3º check positivo, e bloqueio por cooldown/versão.
     - Paridade determinística mantida sem regressões nas suítes existentes.


#### Decisão 78

- **Data:** 7 de outubro de 2026.
- **Título:** Ativação de Probes Reais Homologados (Steam A2S & PlayFab QoS), Expansão Multirregional e Transparência de Precisão de Rota (Catálogo v4).
- **Status Atual:** **Em homologação técnica (Aprovada a estratégia pelo Luiz).**
- **Frentes envolvidas:** Marco (Product Lead), Camillo (Principal Engineer transversal / Gate Arquitetural), Iury (Network & Edge Systems Engineer), Rian (iOS / Transport & Catalog), Renan (Product Designer / Cockpit & Transparência), Breno (QA & Reliability) e Luiz (aprovação).
- **Contexto e Problema:**
  Até o Catálogo v3, os 22 jogos estavam configurados para usar a rota de referência regional da AWS GameLift (`gamelift-ping.sa-east-1.api.aws:7770`) em São Paulo, mantendo as rotas dedicadas (`dedicatedServer`) marcadas como `status: "pending"`.
  Embora os motores de protocolo UDP para Steam A2S e PlayFab QoS já estejam codificados no app, nenhum host foi ativado em produção sem comprovação empírica de resposta UDP.
  O dono do produto (Luiz) deliberou a ativação progressiva dos testes com servidores reais onde comprovadamente houver suporte técnico e captura real, com incremento do catálogo e transparência de precisão para o jogador.
- **Decisão:**
  1. **Evolução do Conteúdo do Catálogo (v4):**
     - O catálogo remoto avançará na sua versão de conteúdo (`catalogVersion`) assim que os endpoints forem capturados e validados em bancada de rede por Iury.
     - O **`schemaVersion` permanece estritamente em 3**, garantindo compatibilidade imediata com as regras de decodificação e verificação de integridade já em produção no iOS (`RemoteCatalog.swift`) e Android (`RemoteCatalogVerifier.kt`).
     - Preservação inegociável da assinatura criptográfica Ed25519 e custo operacional recorrente zero (Worker Cloudflare existente).
  2. **Critério Rígido de Integridade Diagnóstica para Destinos (Iury):**
     - Nenhuma rota dedicada será ativada como `status: "active"` sem evidência empírica de tráfego UDP em arquivo PCAP demonstrando resposta `A2S_INFO` válida com o desafio `0x41` tratado (Steam A2S), estruturada no formato estrito de `candidates` com `operatorEvidenceURL` e `expectedIdentity`.
     - Endpoints PlayFab QoS permanecem confinados à bancada exploratória de pesquisa de rede e não entram no `schemaVersion: 3`, evitando quebras de validação nos clientes.
     - Hosts presumidos sem teste real de captura permanecem como `pending`, garantindo que o jogador nunca receba falsa promessa de ping dedicado.
     - A rota de infraestrutura regional AWS GameLift permanece como referência neutra sólida e transparente.
  3. **Expansão Multirregional:**
     - Regiões candidatas: Virgínia (`us-east-1`), Oregon (`us-west-2`) e Frankfurt (`eu-central-1`) permanecem sob validação comparativa de latência antes de inclusão no envelope assinado.
  4. **Transparência de Precisão na UI (Cockpit):**
     - A UI continuará utilizando o `RouteTrailSummaryCard` existente para diferenciar `Servidor de Jogo` vs `Referência Regional`, derivada exclusivamente da rota que efetivamente respondeu, sem badges artificiais redundantes.
- **Critérios de Validação e Aceite:**
  - Architecture Plan documentado por Camillo em `.agents/architecture-plan.md` com plano anterior arquivado;
  - Captura real de pacotes UDP em PCAP e homologação de resposta de cada host por Iury;
  - Geração e assinatura Ed25519 do novo envelope com `schemaVersion: 3` compatível com os clientes;
  - Paridade estrita entre iOS e Android e testes unitários 100% verdes sem regressões no Xcode, Gradle e Worker.


#### Decisão 79

- **Data:** 8 de outubro de 2026.
- **Título:** Pesquisa de Rede & Homologação Técnica do Protocolo Valve SDR (Steam Datagram Relay) para CS2 e Dota 2.
- **Status Atual:** **Em homologação técnica (Aprovada a estratégia pelo Luiz).**
- **Frentes envolvidas:** Marco (Product Lead), Camillo (Principal Engineer transversal), Iury (Network & Edge Systems Engineer), Rian (iOS & Android Parity), Breno (QA & Reliability) e Luiz (aprovação).
- **Contexto e Problema:**
  A Valve migrou a infraestrutura de rede competitiva oficial de Counter-Strike 2 e Dota 2 para o Steam Datagram Relay (SDR), desativando queries públicas legadas A2S_INFO (`0xFFFFFFFF`) dos seus clusters oficiais de partida para proteção contra DDoS.
  Testes empíricos em bancada de rede conduzidos por Iury comprovaram que os gateways oficiais SDR da Valve em São Paulo (`155.133.227.35:27015`, POP `gru`) respondem ativamente com latência física de 12–20 ms via datagramas estruturados em Protobuf iniciados por tag de controle (`0x08 0x08 0x01 0x12`), retornando mensagens de controle de gateway.
- **Decisão:**
  1. **Integridade Diagnóstica Inegociável (Sem Hacks de Rede):**
     - O LagCheck **não** aceitará mensagens de erro de gateway ou prefixos genéricos de 4 bytes como substituto de probe de medição sem prova de identidade de jogo, preservando o valor inegociável de determinismo e honestidade diagnóstica (Decisão 50).
  2. **Bancada de Pesquisa de SDR (Iury & Camillo):**
     - O suporte nativo ao SDR da Valve avança em bancada de testes para modelar o framing completo do protocolo (`GameNetworkingSockets`), estabelecendo a correlação determinística de probe com timestamp/nonce antes de qualquer alteração no código de produção do app.
  3. **Manutenção da Referência Regional no Catálogo:**
     - Enquanto a homologação do protocolo SDR completo estiver em bancada, títulos Valve mantêm a rota de referência regional (AWS GameLift em São Paulo) como referência transparente, comunicada honestamente no atestado de rota como *Referência Regional*.
- **Critérios de Validação e Aceite:**
  - Especificação completa do framing do SDR validada em bancada por Iury;
  - Validador correlacionado com nonce/timestamp sem bypass de identidade;
  - Paridade sincronizada nos clientes iOS e Android com testes unitários puros;
  - Validação independente via Claude Code aprovada antes de qualquer merge de código de produção.

#### Decisão 80
- **Data:** 13 de outubro de 2026.
- **Título:** Protótipo Android canônico (One UI) e remoção da seleção de dispositivo no Android.
- **Status Atual:** **Vigente (Em implementação).**
- **Frentes envolvidas:** Marco (Product Lead), Renan (Product Designer), Rian (Android/iOS), Breno (QA) e Luiz (aprovação).
- **Contexto e Problema:**
  O design Android (22 telas, One UI) foi redesenhado no Claude Design e passa a divergir do protótipo iOS. A jornada também mudou: o Android mede a partir do próprio celular, então perguntar "onde você joga?" e "como o console está conectado?" deixou de fazer sentido.
- **Decisão:**
  1. `design-system/prototypes/android-reference/source/LagCheck Android.dc.html` é a referência visual canônica do **Android**. O iOS mantém `ios-reference/` e suas referências, sem alteração.
  2. **Sem seleção de dispositivo no Android:** tocar num jogo do catálogo o define como jogo atual e volta ao Início; "Checar agora" inicia o check. A plataforma de rota vem do catálogo (Mobile quando o jogo tem contexto Mobile; caso contrário, o primeiro contexto disponível). Não há vínculo declarado de equipamento externo.
  3. **Capas dos jogos:** as capas são arte autoral do dono do produto (Luiz) e **ficam** no app; a restrição a arte licenciada de terceiros do `docs/18` não se aplica a elas. As imagens do protótipo não são copiadas para o repositório.
  4. **Tipografia:** **Google Sans Flex** (OFL; o mesmo arquivo usado no SignallQ) é a única família do Android, em títulos, corpo e números (algarismos tabulares). Nunito, Roboto e fontes monoespaçadas saem do app.
  5. **Plataformas:** PlayStation, Xbox e Switch usam os logos oficiais (Simple Icons, CC0); celular e PC usam glifos genéricos, como no iOS.
  6. **Sem Quick vs. Deep:** há um único check (repouso + carga) e a UI não distingue modos. Identificadores internos versionados (`deep-load-impact-v2`, `DeepCheck*`) e o Worker `nolaggy-deep-check` não mudam.
  7. **Check Geral** permanece no fim da tela Jogos para quem não achar o jogo na lista (a lista nunca pode ser um beco sem saída). É um adendo ao protótipo, restilizado com os mesmos tokens; usa a rota regional de referência.
  8. **Barra inferior do Android com 4 abas:** Início · Jogos · Histórico · Configurações (determinação do Luiz). Isso **substitui, só no Android**, as 2 abas das Decisões 50/51 e do protótipo; o iOS mantém `Início | Jogos`. A tela Ajustes passa a se chamar Configurações.
  9. **Movimento e métricas One UI (Android):** transições de tela com curva suave (slide curto + fade para navegação hierárquica, fade-through entre abas) e gesto de voltar preditivo; texto mínimo de 12 sp, alvos de toque de 48 dp e margens laterais de 24 dp (grade de 8 dp). Isso ajusta o protótipo (10–11 sp, 44 dp, 22 dp), que foi desenhado fora dessas métricas.
  10. Mascote (`robot-*`), ícones alternativos e Plano de Anúncios ficam **fora** desta entrega: dependem de decisão própria. O MVP1 segue sem anúncios.
- **Critérios de validação e aceite:**
  - Telas Android alinhadas ao protótipo, sem mudar score, veredito, thresholds ou catálogo;
  - Validação em emulador ao final; hardware físico segue necessário para rede/ciclo de vida.

#### Decisão 81
- **Data:** 13 de outubro de 2026.
- **Título:** Compartilhamento do resultado no Android: cartões e vídeo gerados no aparelho.
- **Status Atual:** **Vigente (Em implementação).**
- **Frentes envolvidas:** Marco (Product Lead), Rian (Android), Renan (Design), Breno (QA) e Luiz (aprovação).
- **Contexto e Problema:**
  O resultado precisa ser compartilhável nas redes (Instagram, WhatsApp, Discord, TikTok) com imagem e vídeo, como no gerador do site (`gmmattey/sites`, `sites/signallq/src/lib/share` e `lib/video`).
- **Decisão:**
  1. A tela de resultado abre a folha "Cards e vídeo para as redes" com o card 1200×630 (link preview), o card 1080×1920 (Status, Stories, TikTok) e o vídeo 9:16 de 14 s (escolha do jogo, medição com as respostas reais, resultado).
  2. Tudo é gerado no aparelho e entregue ao seletor do sistema, sem rede e sem servidor; só números medidos aparecem, e resultado inconclusivo não gera arquivo.
  3. Identidade LagCheck: wordmark oficial, **Google Sans Flex**, rótulo "CHECK" (e não "Teste gamer", termo do SignallQ), selo do Google Play e QR da loja (ZXing core, Apache-2.0, só geração local).
  4. Os cartões mostram `lagcheck.signallq.com`; trocar pela URL oficial da loja quando houver publicação.
  5. PDF segue só no resultado; o "…" da Home e o PDF dos Dados da Rede saem.
  6. **Compartilhar por ícones (13/10/2026):** a tela de resultado mostra só os ícones oficiais de WhatsApp, Telegram, TikTok, X e Instagram (mais o PDF), sem botões de texto; o toque abre a folha com a rede em destaque, onde se escolhe Link, Stories ou Vídeo e o arquivo vai direto ao app da rede (ou ao seletor do sistema se não estiver instalado). Discord e WhatsApp em pílula saem.
  7. Home sem o ícone de Dados da Rede e sem o atalho duplicado de Histórico: a pílula de rede ("Wi-Fi · ms") abre os Dados da Rede.
  8. Histórico e catálogo mostram sempre o celular como aparelho; as linhas usam só uma linha fina embaixo (sem caixa em volta).
- **Critérios de validação e aceite:**
  - Emulador: card e vídeo (14 s, 1080×1920, 30 fps) gerados e abertos no seletor; fontes em Google Sans Flex;
  - Validar em aparelho físico e nos apps de destino (Instagram, WhatsApp, TikTok) antes de release.

#### Decisão 82
- **Data:** 13 de outubro de 2026.
- **Título:** Anúncios no Android (AdMob).
- **Status Atual:** **Vigente (Implementado, ligado).** Nasceu desligado no beta; em 13/10/2026 o Luiz mandou deixar ligado.
- **Frentes envolvidas:** Marco (Product Lead), Rian (Android), Iury (rede/telemetria), Breno (QA) e Luiz (autorização).
- **Contexto e Problema:**
  O plano "Anúncios no iOS e no Android" (MVP1.1) pede banner adaptativo do AdMob só na Home e no Histórico, com consentimento via UMP e sem ATT. O dono do produto autorizou implementar no Android, **desligado enquanto o app estiver em beta**. Isso suspende, só para o Android, a regra de manter SDK e IDs de anúncio fora do binário do MVP1.
- **Decisão:**
  1. **Chave de build:** `ADS_ENABLED` é verdadeiro por padrão e desliga com `-Plagcheck.adsEnabled=false`. Desligado, não há consentimento, inicialização, requisição nem espaço reservado. **Enquanto só houver IDs de teste, os anúncios exibidos são de teste do Google: trocar pelos IDs reais antes de qualquer distribuição.**
  2. **Regras que não mudam** (`AdPolicy`, JVM puro, testada): só Home e Histórico; nunca durante a medição (pré-leitura, repouso, carga, consentimento de dados móveis); nunca sem `canRequestAds`; fora de Resultado, Detalhes, Jogos e Configurações.
  3. **Banner** adaptativo ancorado acima da barra inferior, com altura reservada desde o primeiro render e rótulo "Anúncio / Ad"; falha de carga deixa a área vazia.
  4. **Consentimento:** UMP a cada abertura, na Home; "Opções de privacidade" aparece em Configurações quando o UMP exigir. Sem ATT.
  5. **IDs:** só os IDs de teste do Google até haver IDs reais; os reais entram por `lagcheck.admobAppId` e `lagcheck.admobBannerUnitId`, sem mudar código.
  6. **Custo e binário:** AdMob não tem custo recorrente; o APK de release fica em torno de 55 MB. O SDK 25.x exige `-Xskip-metadata-version-check` enquanto o Kotlin do projeto for o 2.0.20.
- **Pendências antes de ligar (release com anúncios):**
  - Listings dizem "Zero ads / Zero intrusive ads": reescrever;
  - `docs/03` e a política de privacidade (`web/privacy`) precisam citar AdMob, UMP e ID de publicidade;
  - Data safety e declaração do ID de publicidade no Play Console; permissão `AD_ID` já está no manifesto;
  - Criar o app e a unidade de banner no AdMob e conferir `app-ads.txt`;
  - Confirmar que nenhum dado de anúncio cruza com a telemetria do Worker;
  - Validar UMP por região (UE, EUA), TalkBack e anúncio que falha, em aparelho físico.
- **Critérios de validação e aceite:**
  - Desligado: nenhum log do SDK e nenhum espaço reservado (validado no emulador);
  - Ligado: banner de teste carrega em Home e Histórico e não aparece nas outras telas.

#### Decisão 83
- **Data:** 13 de outubro de 2026.
- **Título:** Ícone do app com mascote no Android.
- **Status Atual:** **Vigente (Implementado).** Substitui a exclusão do mascote registrada na Decisão 80 (item 10).
- **Frentes envolvidas:** Marco (Product Lead), Renan (Design), Rian (Android) e Luiz (aprovação).
- **Decisão:**
  1. Configurações → "Ícone do app" oferece Clássico (glifo roxo) e três ícones com o mascote: Joinha, Piscadinha e Comemorando.
  2. Cada opção é um `activity-alias` do launcher; só um fica habilitado e o sistema é a fonte da verdade. O Clássico é o padrão. A troca não reinstala o app, e o launcher atualiza em alguns segundos (alguns launchers fecham o app ao trocar).
  3. Os mascotes são ícones adaptativos (primeiro plano 432 px sobre fundo com brilho roxo), vindos do protótipo `Lagcheck - Prototipos.zip`.
- **Critérios de validação e aceite:** troca confirmada no emulador; validar nos launchers reais (Samsung One UI, Pixel) antes de release.

#### Decisão 84
- **Data:** 15 de outubro de 2026.
- **Título:** Giam como Product Owner Operacional e Gate de Qualidade da Squad.
- **Status Atual:** **Vigente (Governança).** Refina a divisão de papéis da Decisão 63.
- **Frentes envolvidas:** Giam (Product Owner Operacional), Marco (Estratégia de Produto e Orquestração), Luiz (dono do produto) e toda a squad.
- **Contexto e Problema:** O modelo anterior tratava Giam como uma revisão independente e opcional, enquanto Marco acumulava estratégia, enquadramento de missão e aceite operacional. Isso duplicava responsabilidade de produto e deixava o último aceite sem uma dona/o operacional claro.
- **Decisão:**
  1. Giam passa a exercer no LagCheck o mesmo papel que exerce no Linka: representa Luiz operacionalmente, abre ou aprova o Cartão de Missão, define comportamento observável e critérios de aceite, e encerra a entrega com o veredito interno `APROVADO`, `APROVADO COM RESSALVAS`, `REPROVADO` ou `NÃO VALIDADO`.
  2. Giam participa no começo e no fim de todo full flow, mudança sistêmica e candidato a release. Em fast lane, seu enquadramento e veredito são proporcionais ao risco; em hot lane, a restauração do caminho crítico vem primeiro e a revisão de Giam acontece após estabilização.
  3. Marco passa a se concentrar em estratégia, prioridade, trade-offs, integração entre frentes e escalonamento de decisões de negócio a Luiz. Marco não concorre com o aceite operacional de Giam.
  4. Breno mantém a validação técnica independente; Renan, Rian, Iury e Camillo mantêm autoridade em design, app mobile, integridade de rede e arquitetura. Giam consome essa evidência, sem dispensá-la ou inventar prova.
  5. Luiz preserva a autoridade exclusiva sobre negócio, marca, monetização, preço, envio externo, release e publicação. O parecer interno de Giam não autoriza ação externa.
- **Critérios de validação e aceite:**
  - `AGENTS.md`, `docs/05-governanca-e-fluxo-de-trabalho.md`, `.agents/WORKFLOW.md`, o Cartão de Missão e as skills/perfis de Marco e Giam descrevem uma mesma divisão de responsabilidades;
  - cada lane declara onde entra o aceite de Giam sem bloquear a estabilização de hot lane;
  - nenhum documento atribui a Giam autorização de negócio ou publicação, nem transfere a Marco o aceite operacional da missão.

#### Decisão 85
- **Data:** 15 de outubro de 2026.
- **Título:** Retirada do gate entre MVP1 e MVP1.1.
- **Status Atual:** **Vigente (Produto).** Substitui as travas de escopo pós-MVP1 descritas em `docs/01-funcional.md` §13.1 e `docs/05-governanca-e-fluxo-de-trabalho.md` §7.4.
- **Frentes envolvidas:** Luiz (dono do produto), Giam (Product Owner Operacional) e Marco (estratégia e priorização).
- **Contexto e Problema:** A separação por gate entre MVP1 e MVP1.1 atrasava iniciativas de evolução já coerentes com a proposta do LagCheck, mesmo quando fossem locais, de custo operacional zero e sem alterar a integridade da medição.
- **Decisão:**
  1. Não existe mais gate de produto que condicione a entrada de escopo de MVP1.1, retenção, compartilhamento ou mecanismo de retorno a um período mínimo em produção ou à revisão prévia de telemetria.
  2. Telemetria agregada e retenção continuam instrumentos de priorização e aprendizado, nunca autorização implícita para dados pessoais, novos endpoints, promessa diagnóstica ou publicação.
  3. Cada iniciativa continua exigindo decisão registrada quando alterar promessa, arquitetura, privacidade, custo, regras de medição ou escopo de plataforma; o Cartão de Missão, a lane aplicável e a evidência proporcional permanecem obrigatórios.

#### Decisão 86
- **Data:** 16 de outubro de 2026.
- **Título:** Ritual honesto do Histórico por jogo.
- **Status Atual:** **Vigente (Em implementação).**
- **Frentes envolvidas:** Luiz (aprovação), Giam (aceite operacional), Marco (priorização), Camillo (gate), Iury (contrato), Rian (clientes), Renan (UI) e Breno (QA).
- **Decisão:**
  1. O Histórico passa a oferecer, por jogo, janelas locais de 7, 14 e 30 dias com a frase factual `Pronto em X de Y checks comparáveis` e contagem separada de `Instável`, `Evitaria` e `Inconclusivo`.
  2. Um Check só participa da fração quando for válido e comparável: mesma combinação de jogo, plataforma, vínculo externo declarado, rede observada, região e versão de regra. Exige ao menos 3 Checks em 2 dias da janela. Inconclusivo não é falha e não entra no denominador. Se a sessão terminar normalmente por respostas UDP insuficientes, o Histórico preserva esse fato e suas métricas sem score nem causa; cancelamento, troca de rede e parcial continuam descartados.
  3. Ficam expressamente fora: melhor horário, previsão, média de score, comparação de jogos/contextos e atribuição a Wi-Fi, roteador, operadora ou qualquer causa. O resumo não substitui o Check atual antes da partida.
  4. Os dois clientes aplicam 90 dias e no máximo 100 registros por jogo. Snapshot Android legado sem os fatos de comparabilidade é preservado para consulta, mas não gera resumo até haver nova medição completa.
  5. Não há nova chamada de rede, Worker, telemetria, PII, SDK ou custo recorrente.
- **Critérios de validação e aceite:**
  - `docs/01-funcional.md` e `docs/05-governanca-e-fluxo-de-trabalho.md` deixam claro que dados de retenção informam prioridade, sem bloquear escopo;
  - nenhuma regra de integridade diagnóstica, custo operacional zero, consentimento ou autorização de publicação é removida.

#### Decisão 87

- **Data:** 16 de outubro de 2026.
- **Título:** Lembrete local pré-partida, configurado pela pessoa.
- **Status Atual:** **Vigente (Autorizada).**
- **Frentes envolvidas:** Luiz (autorização), Giam (aceite operacional), Marco (prioridade), Rian (iOS e Android), Renan (experiência) e Breno (QA).
- **Decisão:**
  1. O LagCheck oferece, somente após escolha explícita da pessoa, um lembrete local diário em um horário configurado. O recurso começa desligado, não observa outros apps, não aprende rotina, não usa push, não cria conta, não chama Worker nem envia telemetria.
  2. Só pode ser ativado quando houver um jogo selecionado. A notificação usa copy curta e abre o LagCheck no contexto desse jogo, pronto para a pessoa iniciar o Check; ela nunca dispara medição por conta própria.
  3. Há no máximo um lembrete por dia. A pessoa pode mudar o horário ou desligar o recurso nos Ajustes a qualquer momento; ao desligar, os agendamentos locais são removidos.
  4. A permissão do sistema é pedida somente pela ação de ativar. Se negada, o recurso permanece desligado, explica o estado sem culpa e oferece o caminho às Configurações do sistema; não há repetição automática do prompt.
  5. A implementação respeita as permissões e limites nativos de iOS e Android, além de PT-BR, inglês e espanhol. Não afirma que a rede está pronta e não substitui um Check atual.
- **Critérios de validação e aceite:**
  - teste de agendamento, remarcação, desligamento e abertura no jogo correto nos dois clientes;
  - validação em aparelhos iOS e Android do prompt, permissão negada, toque na notificação em app frio e em segundo plano, e cancelamento/retorno;
  - Dynamic Type/font scale, VoiceOver/TalkBack, contraste e alvo de 44 pt/dp na configuração;
  - nenhuma atividade de rede ou medição automática causada pelo lembrete.

#### Decisão 88

- **Data:** 16 de outubro de 2026.
- **Título:** Widget de prontidão por jogo — arte oficial por plataforma e Check direto.
- **Status Atual:** **Vigente (Implementado localmente; validação visual/física pendente).** Refina o item de widgets da Decisão 75 e substitui o recorte iOS-only/Live Activity proposto na issue #49.
- **Frentes envolvidas:** Luiz (autorização), Giam (aceite operacional), Marco (prioridade), Camillo (gate), Rian (iOS e Android), Renan (experiência), Iury (integridade) e Breno (QA).
- **Decisão:**
  1. A #49 passa a entregar widget de prontidão por jogo em iOS 17+ e Android API 26+. A Home Screen mostra a arte editorial autorizada do último Check válido, jogo, região, P50 e veredito; a Lock Screen iOS retangular usa miniatura. Formatos compactos preservam telemetria legível e não são obrigados a exibir capa.
  2. A fonte de arte é oficial **para a build e a plataforma em que o widget roda**: catálogo assinado válido mais cache/resource editorial do iOS para WidgetKit; catálogo assinado válido mais cache/resource editorial Android para o widget Android. Não há transferência de imagem, cache, captura ou URL de um cliente para o outro. Nunca usar capa, logo, personagem ou outro ativo oficial de terceiros.
  3. O toque é intenção explícita: abre o app e inicia um novo Check do jogo, plataforma e vínculo externo exibidos, depois de revalidar o contexto pelo catálogo local atual. iOS usa `lagcheck://check?game={id}`; Android usa Intent/deep link equivalente. O widget não mede, não baixa arte e não atualiza dados em background.
  4. Após quatro horas, em resultado inconclusivo, arte incompatível, catálogo inválido ou jogo removido, o widget não mostra P50 ou veredito antigo como atual. Mantém CTA contextual apenas se o jogo ainda puder ser resolvido; caso contrário, mostra identidade neutra do LagCheck. Nenhuma dessas situações inventa métrica ou diagnóstico.
  5. Live Activity, Dynamic Island, StandBy, leaderboard e superfície social ficam fora desta issue. Qualquer retorno dessas ideias exige decisão e missão próprias.
- **Critérios de validação e aceite:**
  - snapshot e miniatura só vêm da fonte oficial da plataforma e expiram/invalida de forma segura;
  - app frio e em segundo plano iniciam o Check do contexto correto por toque, sem segunda sessão;
  - arte, expiração, fallback e deep link/Intent são testados separadamente em iOS e Android;
  - Dynamic Type/VoiceOver e font scale/TalkBack, contraste, Lock/Home e redimensionamento aplicável têm prova em aparelhos físicos;
  - nenhuma chamada nova ao Worker, telemetria, PII, SDK, regra de score/veredito ou custo recorrente é adicionada.

#### Decisão 89

- **Data:** 16 de outubro de 2026.
- **Título:** Ativação coordenada do catálogo de 48 jogos por referência regional.
- **Status Atual:** **Vigente (assinatura e publicação pendentes).** Refina o limite de ativação pendente da Decisão 70.
- **Frentes envolvidas:** Luiz (autorização), Giam (aceite operacional), Marco (prioridade), Iury (integridade do catálogo), Rian (clientes) e Breno (validação).
- **Contexto e Problema:** O catálogo v3 assinado em uso contém 22 jogos, mas há 26 títulos adicionais já preparados no candidato local, com artes autorais, plataformas e testes de consistência. Renovar somente os 22 preservaria a disponibilidade mínima, mas deixaria de fora jogos já autorizados sem um motivo de integridade.
- **Decisão:**
  1. O próximo envelope v3 assinado e as bases embarcadas iOS/Android passam a conter os 48 jogos do candidato local, com uma única versão coordenada.
  2. Os 26 títulos adicionados usam exclusivamente a rota `awsFallback` ativa de São Paulo como **referência regional**. A rota `gameOwned` de cada contexto continua `pending`; o produto não chama essa leitura de ping, rota ou servidor oficial do jogo.
  3. Não muda score, veredito, threshold, protocolo, endpoint, regra de seleção ou custo operacional. Não entra rota dedicada sem a evidência exigida pelas Decisões 37, 38/39 e 78.
  4. A ativação exige assinatura Ed25519 com a chave vigente, cópia byte-idêntica do envelope para Worker/iOS/Android, testes de validação/resolução e verificação do Worker público. Distribuição de app e prova física continuam etapas separadas.
- **Critérios de validação e aceite:**
  - envelope schema 3 válido com 48 IDs únicos, 22 títulos existentes preservados e 26 expansões com arte/sha e plataformas do candidato;
  - toda expansão resolve somente uma referência regional ativa e mantém rota própria pendente;
  - os dois clientes validam o mesmo envelope e não apresentam o resultado como servidor do jogo;
- publicação do Worker é confirmada pela versão, validade, assinatura e contagem pública; build, aparelho, TestFlight/Play e loja são reportados separadamente.

#### Decisão 90

- **Data:** 16 de outubro de 2026.
- **Título:** Referência regional global por proximidade medida.
- **Status Atual:** **Vigente (em implementação).** Refina as Decisões 16, 78 e 89 no que conflitar.
- **Contexto e problema:** Um app multilíngue e distribuído globalmente não pode transformar São Paulo em destino obrigatório por uma limitação do catálogo. O jogador precisa receber a referência regional com menor latência observada entre os beacons autorizados, sem confundir a referência com o servidor oficial da partida.
- **Decisão:**
  1. O catálogo Schema 3 assinado lista todas as regiões AWS GameLift já homologadas no registro compartilhado iOS/Android. Nenhuma delas é apresentada como servidor do jogo.
  2. Para cada contexto disponível, a rota `awsFallback` continua sendo uma referência regional genérica, mas a pré-leitura mede todas as regiões assinadas e escolhe exclusivamente pela regra `regional-selection-1`: respostas UDP válidas, P50 observado, estabilidade e desempate determinístico. País, idioma, GPS ou ordem no catálogo não decidem a região.
  3. Preferência manual em Ajustes continua sendo um override explícito para uma região que esteja no mesmo catálogo assinado. Fora disso, o comportamento padrão é sempre automático.
  4. Rotas `gameOwned` permanecem `pending`; esta decisão não ativa endpoint de jogo, não altera score, veredito, thresholds, Worker, telemetria, custo ou schema.
- **Critérios de validação e aceite:**
  - iOS e Android recebem o mesmo envelope, com a mesma lista ordenada de beacons e cópia byte-idêntica nas três bases;
  - vetores dos dois clientes provam que a melhor P50 elegível vence, empate usa o desempate documentado e nenhuma resposta suficiente gera `inconclusivo`;
  - o caminho de medição usa a região vencedora, enquanto a UI a chama de `Referência regional`;
  - validação de rede em aparelho físico nas regiões acessíveis e publicação do Worker continuam provas separadas. Falha/ausência de resposta não cria fallback HTTP/ICMP nem resultado inventado.

#### Decisão 91

- **Data:** 16 de outubro de 2026.
- **Título:** Ícone do app modernizado em iOS e Android.
- **Status Atual:** **Vigente (Implementado localmente).** Substitui o ícone aprovado na V1 (glifo roxo chapado) e refina a Decisão 83 apenas no ícone Clássico.
- **Frentes envolvidas:** Luiz (aprovação), Giam (aceite), Marco e Renan (design), Rian (integração) e Breno (validação).
- **Contexto e problema:** O ícone chapado (uma cor sobre preto liso) parecia datado na loja, e o primeiro plano do Android estourava a zona segura de 66 dp (glifo a cerca de 36,5 dp do centro, limite 33 dp).
- **Decisão:**
  1. A versão modernizada do glifo (traço mais grosso, gradiente lilás para roxo, luz de borda, extrusão curta e brilho roxo na base do fundo) é o ícone oficial do LagCheck em iOS e Android. O joystick e as demais rotas exploradas ficam descartados.
  2. iOS: master 1024 sem alpha e sem cantos arredondados, com variantes Dark e Tinted no catálogo `AppIcon`.
  3. Android: ícone adaptativo com fundo e primeiro plano separados, glifo inteiro dentro da zona segura de 66 dp e camada monocromática para ícone temático. O Clássico do seletor da Decisão 83 passa a ser este ícone; os mascotes não mudam.
  4. O teste A/B de loja fica adiado: o volume atual de impressões não sustenta Product Page Optimization nem Store Listing Experiments.
  5. O wordmark e o símbolo compacto dentro dele **não** mudam nesta decisão. A diferença entre o glifo do ícone e o símbolo do wordmark fica como pendência de marca para o Luiz.
- **Critérios de validação e aceite:** build iOS no simulador com Default, Dark e Tinted; emulador Android API 26 e 34 com ícones temáticos ligados; launchers Pixel e Samsung One UI; seletor de ícones da Decisão 83 intacto; leitura em 29 e 60 px sem confundir com os numerais 6 e 9. Cada ambiente é prova separada.

#### Decisão 92

- **Data:** 16 de outubro de 2026.
- **Título:** Wordmark com o símbolo modernizado e mono refeito.
- **Status Atual:** **Vigente (Implementado localmente).** Revisa o item 5 da Decisão 91.
- **Frentes envolvidas:** Luiz (aprovação), Giam (aceite), Renan (design), Rian (integração) e Breno (validação).
- **Contexto e problema:** O símbolo do wordmark ainda era o desenho antigo, diferente do ícone. Os wordmarks mono (claro e escuro) nunca tiveram o mesmo símbolo nem as mesmas letras do primary: usavam um símbolo angular e uma tipografia blocky próprios. Isso já estava errado antes da Decisão 91 e não havia sido apontado.
- **Decisão:**
  1. O wordmark primary oficial é o aprovado pelo Luiz: símbolo modernizado, `lag` branco e `check` roxo (Decisão 66). As letras seguem como pixels do master anterior; o primary ainda não é um master vetorial.
  2. Os wordmarks mono claro e escuro passam a ser vetores derivados das letras do primary, com o mesmo símbolo, em tinta sólida `#15181E` e `#F4F5F7`. O desenho angular antigo do mono sai de uso.
  3. Os PNGs de app (iOS, Android e Play) são regerados do novo primary, nos tamanhos que já existiam. `lagcheck-wordmark-light.svg` do design system deixa de apontar para um caminho inexistente.
  4. Redesenhar `lag` e `check` em vetor a partir da fonte original fica como pendência de marca.
- **Critérios de validação e aceite:** wordmark legível em 24 e 40 px de altura; iOS e Android exibem o primary novo; as páginas web e o protótipo carregam os SVGs sem quebra; cada ambiente é prova separada.

#### Decisão 93

- **Data:** 16 de outubro de 2026.
- **Título:** AGENTS.md alinhado ao estado real de anúncios e arte de jogo.
- **Status Atual:** **Vigente (Documentação).** Não altera produto: sincroniza instruções ao que as Decisões 18, 44, 71, 82 e 88 já estabeleceram.
- **Frentes envolvidas:** Luiz (confirmação) e Giam (registro).
- **Contexto e problema:** O `AGENTS.md` ainda dizia que publicidade não existe no MVP1 e que jogos não exibem arte. A Validação do ícone mostrou, na Home do Android Debug, a arte de jogo e o rótulo "Anúncio", e o Luiz confirmou que ambos fazem parte do app. As instruções contradiziam o código e as decisões vigentes.
- **Decisão:**
  1. Arte de jogo: vale a arte editorial autoral do catálogo assinado; a proibição de capa oficial, logo, personagem e arte licenciada de terceiros continua.
  2. Anúncios: Android com banner AdMob em Home e Histórico (Decisão 82), hoje com IDs de teste; iOS sem anúncios até decisão própria.
- **Confirmação do Luiz (16/10/2026):** toda a arte de jogo exibida no app é autoral. Não há pendência de arte de terceiros; o relato do Breno sobre a Home do Android Debug não é defeito.
- **Critérios de validação e aceite:** `AGENTS.md` e `docs/DECISOES.md` sem contradição entre si.

## Como Registrar Novas Decisões

1. Adicione a linha correspondente no [Índice Rápido](#índice-rápido-de-decisões-e-status-de-vigência) marcando o status como `Vigente` (ou indicando se substitui alguma decisão anterior);
2. Adicione uma nova subseção numerada ao final deste documento detalhando:
   * **Título**
   * **Status Atual** (`Vigente`, `Superada por X` ou `Em implementação`)
   * **Frentes envolvidas**
   * **Contexto, Problema e Decisão Tomada**
   * **Critérios de validação e aceite**
3. Nunca crie arquivos separados de decisão.
