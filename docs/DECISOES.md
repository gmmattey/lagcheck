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
| [14](#decisão-14) | Catálogo remoto assinado em Debug (Ed25519, `/v1/catalog.json`) | **Superada** | Decisão 99 (envelope assinado empacotado no build; sem catálogo HTTP) | Iury / Renan |
| [15](#decisão-15) | Artes licenciadas para capas do catálogo | **Substituída** | Decisões 18 e 44 (Identidade neutra sem copyright) | Renan |
| [16](#decisão-16) | Seleção regional automática BR/EUA (`regional-selection-1`) | **Vigente** | Algoritmo determinístico de beacon de referência | Iury / Rian |
| [17](#decisão-17) | Navegação e Configurações da V1 (Home ⇄ Config ⇄ Histórico) | **Superada** | Decisões 24 e 51 (Substituída por 2 abas: `Início \| Jogos`) | Renan / Rian |
| [18](#decisão-18) | Identidade visual neutra dos jogos (sem capa/logo de terceiros) | **Vigente** | Miniaturas neutras e identificação tipográfica | Renan / Marco |
| [19](#decisão-19) | Exploração: adotar taxonomia "Modo gamer" do SignallQ | **Descartada** | Rascunho exploratório sem autorização de código | Marco |
| [20](#decisão-20) | Auditoria exploratória: revisão de nome, telas e monetização | **Descartada** | Rascunho exploratório rejeitado pelo posicionamento | Marco |
| [21](#decisão-21) | Nova direção visual, simples e leve | **Superada** | Decisão 51 (Dark Competitive UI substituiu o visual simples) | Renan |
| [22](#decisão-22) | Jornada com lista nativa e Quick Check em background | **Superada** | Decisões 43 e 50 (Medição sob demanda em 1 toque) | Marco / Renan |
| [23](#decisão-23) | Dicas de conexão com IA Gemini após Deep Check | **Suspensa por conflito** | Decisão 101 registra a chamada ainda presente no fonte, incompatível com a restrição vigente de infraestrutura/custo até resolução de Luiz | Marco / Iury |
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
| [45](#decisão-45) | Exceção temporária Gemini Release 1.0.0 | **Suspensa por conflito** | Decisão 101; a exceção não prevalece sobre a restrição vigente sem nova autorização explícita de Luiz | Marco / Iury |
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
| [61](#decisão-61) | Website Oficial: Lançamento em Breve no iOS e Captura de Convites | **Vigente, com implementação de Worker em conflito** | Decisão 101 registra que as rotas de site ainda existem no mesmo Worker, fora do contrato autorizado aos apps | Marco / Renan |
| [62](#decisão-62) | Reconciliação documental e conformidade estrita com o gate de TestFlight | **Vigente** | Checklist pré-TestFlight e congelamento de escopo | Breno / Squad |
| [63](#decisão-63) | Adoção do Workflow e Governança Unificada Buildea (Paralelismo SignallQ) | **Vigente (Governança)** | Lanes, Breno (QA), Camillo (Arquiteto), Marco (Lead), DECISOES.md | Marco / Squad / Luiz |
| [64](#decisão-64) | Diretriz "Zero Cara de IA / Gamer Não Lê", Card Viral Discord e Dogfooding | **Vigente (Produto & Processo)** | Proibição de cardlização/textão, card pro Discord, dogfooding e skills de ação | Marco / Luiz / Squad |
| [65](#decisão-65) | Validação Científica (12s, 3 Fases), Fallback de Jogo, Cockpit e Blindagem Visual | **Vigente (Execução Total)** | 3 fases reais UDP/Bufferbloat, fallback jogos, 2 abas, anti-glitches visuais | Marco / Squad / Luiz |
| [66](#decisão-66) | Adoção do Design System LagCheck Canônico (Roxo Gamer Primário, Coral Solar para Atenção) | **Vigente (Design System Canônico)** | Roxo Gamer (#7C3AED), Coral Solar (#FF5A36) restrito a atenção/erro, 3 pilhas tipográficas, raios 8/13/17/26/999px | Renan / Squad / Luiz |
| [67](#decisão-67) | Expansão Multiplataforma: Rascunho Arquitetural e Telemetria Avançada de Rádio no Android | **Vigente (Expansão Android)** | Módulo de rádio (2.4G/5G/6G, RSSI, PHY speed, Gateway), paridade determinística e custo zero | Marco / Camillo / Iury / Luiz |
| [68](#decisão-68) | Port iOS → Android com paridade de regras (readiness-v2.0, catálogo v3 assinado, beacons) | **Vigente (Execução)** | Substitui a medição STUN e os thresholds fixos do protótipo Android; Android passa a ser alvo oficial | Marco / Camillo / Iury / Luiz |
| [69](#decisão-69) | Android: gateway no veredito, status de redes de console, favoritos e relatório em PDF | **Vigente (Execução)** | Refina o item 6 da Decisão 68: liga o gateway no veredito (autorizado pelo Luiz) e entrega o que tinha sido cortado por escopo | Marco / Iury / Luiz |
| [70](#decisão-70) | Expansão do catálogo: quatro jogos e artes autorais | **Superada em escopo pela Decisão 89** | Os quatro títulos integram o envelope local assinado de 48 jogos; distribuição continua pendente | Marco / Luiz |
| [71](#decisão-71) | Catálogo e artes remotos nos apps | **Superada em parte** | Decisão 99 elimina catálogo remoto; a política de arte editorial continua sujeita às Decisões 18 e 44 | Marco / Camillo / Luiz |
| [72](#decisão-72) | Unificação do Motor de Cálculo e Veredito (Fim das Divergências entre Score, Veredito e Detalhes) | **Vigente (Execução)** | Cálculo único em GameReadinessEvaluator, guardrail por veredito no score, consumo 1:1 na UI | Marco / Camillo / Iury / Rian / Renan / Luiz |
| [73](#decisão-73) | Indicador Visual Tático de Veredito (Substituição de Glifos Unicode por VerdictIndicatorBadge) | **Vigente (Design & UI)** | Substitui caracteres de texto cru (●/▲/—) por componente de cockpit com LED/Halo e ícones vetoriais acessíveis | Renan / Rian / Marco / Luiz |
| [74](#decisão-74) | Plano de Crescimento, Viralidade Discord e ASO da App Store (Fase 1: P0) | **Vigente (Aprovada)** | Aprovação do plano de 9 iniciativas: Card Viral Squad Pass, ASO e Bufferbloat Score | Marco / Squad / Luiz |
| [75](#decisão-75) | Fase 2 (P1) — Retenção & Diferenciação Técnica: Ping por Datacenter, Isolador de Causa Raiz e Widgets iOS 17 | **Vigente; widgets refinados pela Decisão 88** | A implementação existente permanece iOS; o recorte de widget por jogo e Android passa a ser o da Decisão 88 | Marco / Camillo / Iury / Rian / Renan / Breno / Luiz |
| [76](#decisão-76) | Fase 3 (P2) — Ecossistema & Fricção Zero: In-App Events, Spotlight Search & Siri Shortcuts, e App Clip Instantâneo | **Vigente (Em implementação)** | CoreSpotlight, App Shortcuts por voz/busca, deeplinks dinâmicos de jogo e App Clip leve (<15MB) | Marco / Camillo / Rian / Renan / Breno / Luiz |
| [77](#decisão-77) | Sistema Unificado de Avaliação In-App (StoreKit & Google Play In-App Review) | **Vigente (Execução)** | Gatilho de delight (3 checks .ready), cooldown de 90 dias, 1 por versão, sem pre-prompts | Marco / Rian / Camillo / Renan / Breno / Luiz |
| [78](#decisão-78) | Ativação de Probes Reais Homologados (Steam A2S & PlayFab QoS), Expansão Multirregional e Transparência de Precisão (Catálogo v4) | **Em homologação técnica** | Bancada de teste de pacotes UDP para A2S/PlayFab, sem rotas presumidas, integridade diagnóstica | Marco / Camillo / Iury / Rian / Renan / Breno / Luiz |
| [79](#decisão-79) | Pesquisa de Rede & Homologação Técnica do Protocolo Valve SDR para CS2 e Dota 2 | **Em homologação técnica** | Bancada de análise de framing SDR da Valve em SP (12-20ms) sem atalhos diagnósticos | Marco / Camillo / Iury / Rian / Breno / Luiz |
| [80](#decisão-80) | Protótipo Android canônico (One UI) e remoção da seleção de dispositivo no Android | **Vigente (Em implementação)** | `design-system/prototypes/android-reference/` é a referência visual do Android; o aparelho é sempre o celular, sem escolha de plataforma. iOS inalterado | Marco / Renan / Rian / Breno / Luiz |
| [90](#decisão-90) | Referência regional global por proximidade medida | **Vigente (implementado localmente; validação física pendente)** | Refina as Decisões 16, 78 e 89: sem fixação em São Paulo | Marco / Iury / Rian / Camillo / Breno / Luiz |
| [81](#decisão-81) | Compartilhamento do resultado no Android: cartões e vídeo gerados no aparelho | **Vigente (Em implementação)** | Porte do gerador do site (cartões 1200×630 e 1080×1920 e vídeo 9:16 de 14 s) com a identidade do LagCheck; só números medidos; sem rede | Marco / Rian / Renan / Breno / Luiz |
| [82](#decisão-82) | Anúncios no Android (AdMob, banner só em Home e Histórico), desligados no beta | **Refinada** | Decisão 96 amplia formato e superfícies; UMP e chave de build permanecem | Marco / Rian / Iury / Breno / Luiz |
| [83](#decisão-83) | Ícone do app com mascote no Android (Clássico, Joinha, Piscadinha, Comemorando) | **Vigente (Implementado)** | Um activity-alias por ícone, trocado em Configurações; sem reinstalar | Marco / Renan / Rian / Luiz |
| [84](#decisão-84) | Giam como Product Owner Operacional e Gate de Qualidade da Squad | **Vigente (Governança)** | Refina a divisão de papéis da Decisão 63: Giam enquadra e aceita missões; Marco lidera estratégia e orquestração | Giam / Marco / Luiz |
| [85](#decisão-85) | Retirada do gate entre MVP1 e MVP1.1 | **Vigente (Produto)** | Telemetria informa prioridade, mas não bloqueia escopo de retenção ou evolução aprovada | Luiz / Giam / Marco |
| [86](#decisão-86) | Ritual honesto do Histórico por jogo | **Vigente (Implementado localmente; validação visual pendente)** | Resumo local comparável em 7/14/30 dias; sem previsão ou causa | Luiz / Giam / Marco / Squad |
| [87](#decisão-87) | Lembrete local pré-partida, configurado pela pessoa | **Vigente (implementado localmente; validação física pendente)** | Opt-in local, um horário diário e abertura do Check sem execução automática | Luiz / Giam / Marco / Rian / Renan / Breno |
| [88](#decisão-88) | Widget de prontidão por jogo — arte oficial por plataforma e Check direto | **Vigente (Implementado localmente; validação visual/física pendente)** | Refina a #49 e a Decisão 75: iOS e Android mostram a arte editorial do último Check válido e iniciam novo Check daquele contexto por toque explícito | Luiz / Giam / Marco / Camillo / Rian / Renan / Iury / Breno |
| [89](#decisão-89) | Ativação coordenada do catálogo de 48 jogos por referência regional | **Vigente (implementado localmente; distribuição pendente)** | Refina a Decisão 70: os 48 jogos entram no envelope assinado local, com referência AWS regional, nunca rota própria de jogo | Luiz / Giam / Marco / Iury / Rian / Breno |
| [91](#decisão-91) | Ícone do app modernizado (glifo com profundidade) em iOS e Android | **Vigente (Implementado localmente; validação em simulador, emulador e launchers pendente)** | Substitui o ícone chapado; iOS com Dark e Tinted, Android adaptativo dentro da zona segura de 66 dp com monocromático | Luiz / Giam / Marco / Renan / Rian / Breno |
| [92](#decisão-92) | Wordmark com o símbolo modernizado e mono refeito a partir do primary | **Vigente (Implementado localmente; validação visual pendente)** | Revisa o item 5 da Decisão 91: primary, mono claro/escuro e PNGs de app passam a usar o mesmo símbolo e as mesmas letras | Luiz / Giam / Renan / Rian / Breno |
| [93](#decisão-93) | AGENTS.md alinhado ao estado real de anúncios e arte de jogo | **Refinada** | Estado publicitário atualizado pelas Decisões 96 e 97; arte editorial autoral permanece | Luiz / Giam |
| [94](#decisão-94) | Resultado iOS alinhado à hierarquia Android e card compartilhável local | **Vigente (implementado localmente; validação física pendente)** | Refina a Decisão 80 no resultado iOS; preserva interações nativas e semântica de cada plataforma | Luiz / Giam / Marco / Renan / Rian / Breno |
| [95](#decisão-95) | Detalhes iOS na referência Android, com evidência diagnóstica preservada | **Vigente (implementado localmente; validação física pendente)** | Amplia a Decisão 94 para `TechnicalDetailsView`; restringe atribuições locais aos fatos observados | Luiz / Giam / Marco / Renan / Rian / Iury / Breno |
| [96](#decisão-96) | Anúncios nativos no Android em Home, Histórico, Jogos e Resultado | **Vigente (Implementado localmente; validação em aparelho pendente)** | Refina a Decisão 82: substitui banners adaptativos por Native Advanced nas quatro superfícies; recorte Android | Luiz / Giam / Marco / Renan / Rian / Breno |
| [97](#decisão-97) | AdMob Native Advanced também no iOS, com IDs de produção do app iOS | **Vigente (Implementado localmente; validação no Mac/iPhone pendente)** | Amplia a Decisão 96 ao iOS; Debug com IDs de teste, Release com App ID e quatro unidades iOS reais; sem distribuição implícita | Luiz / Giam / Marco / Camillo / Renan / Rian / Breno |
| [98](#decisão-98) | Quatro destinos iOS e Resultado/compartilhamento pela referência Android | **Vigente (implementado localmente; validação física pendente)** | Resolve a divergência de integração: Início, Jogos, Histórico e Ajustes são destinos iOS de primeira classe; Resultado e card Link seguem o acabamento mais recente aprovado | Luiz / Giam / Marco / Renan / Rian / Breno |
| [99](#decisão-99) | Catálogo global local nos clientes | **Vigente (implementação local; conformidade do Worker pendente)** | 48 jogos e referências AWS GameLift entram no build assinado; o Worker não distribui catálogo, mas o fonte ainda expõe rotas extras registradas na Decisão 101 | Luiz / Giam / Marco / Camillo / Iury / Rian / Breno |
| [100](#decisão-100) | Home imersiva por jogo e remoção do chrome redundante | **Vigente (implementado localmente; validação física pendente)** | A Home começa na arte editorial do jogo e mantém a decisão de Check em primeiro plano | Luiz / Giam / Marco / Renan / Rian / Breno |
| [101](#decisão-101) | Reconciliação do registro com o código em `main` | **Vigente (auditoria documental; correção sistêmica pendente)** | Separa fonte, contrato autorizado e evidência de runtime; expõe rotas extras do Worker e Gemini como conflitos | Giam / Marco / Camillo / Iury / Luiz |
| [102](#decisão-102) | Jogos: seleção direta, trilhos horizontais e contexto somente do iPhone | **Superada** | Decisão 107 abre a vitrine para todo contexto válido do catálogo | Luiz / Giam / Marco / Renan / Rian / Breno |
| [103](#decisão-103) | Paridade do motor de compartilhamento (Cards e Vídeo 14s) no iOS com App Store | **Vigente (implementado localmente e validado no simulador iOS)** | Paridade 1:1 com o motor Android (`ShareMediaScene`, `ShareCanvas`, `ShareMediaRenderer`, `ShareVideoRenderer`, `ShareMediaSheetView`) e QR Code da App Store | Luiz / Giam / Marco / Renan / Rian / Breno |
| [104](#decisão-104) | Compartilhamento direto por rede no Resultado (card e vídeo) | **Vigente (implementado localmente; validado em simulador iOS e build/testes unitários Android; sem aparelho físico)** | Refina a 103: substitui a folha "Compartilhar" por ícones sob o card; WhatsApp/Telegram/X/Discord recebem o card 1200×630, TikTok/Instagram o vídeo 14 s | Luiz / Giam / Marco / Renan / Rian / Breno |
| [105](#decisão-105) | Jogos: paridade visual e de interação entre iOS e Android | **Vigente (implementado localmente; runtime pendente)** | Refina a 102 e substitui o trilho de "Todos os jogos" por grade de 2 colunas; favoritar no card, busca sempre visível, card único, resultados em lista, limite de 4 favoritos | Luiz / Giam / Marco / Renan / Rian / Breno |
| [106](#decisão-106) | Catálogo embutido sem assinatura nem validade; EUA e artes autorais | **Vigente (implementado localmente; runtime pendente)** | Refina a 99 e substitui a assinatura Ed25519 do catálogo local; amplia o catálogo para 54 jogos | Luiz / Giam / Marco / Camillo / Iury / Rian / Breno |
| [107](#decisão-107) | Jogos: vitrine completa e contexto automático validado | **Vigente (implementado localmente; runtime pendente)** | Substitui o recorte iPhone-only da Decisão 102, sem mudar catálogo, medição ou regra de veredito | Luiz / Giam / Marco / Renan / Rian / Breno |
| [108](#decisão-108) | Analytics do funil iOS com Firebase, exclusão local e privacidade mínima | **Implementado; DebugView validado no simulador; aparelho físico pendente** | Mantém a telemetria do Worker; não amplia endpoints nem altera o diagnóstico | Marco / Camillo / Renan / Luiz |
| [109](#decisão-109) | Analytics do funil Android com Firebase, variante Debug preservada e exclusão local | **Em implementação; validação física e DebugView pendentes** | Firebase só no Release; Worker, Check, UMP e AdMob preservados | Marco / Camillo / Renan / Luiz |
| [110](#decisão-110) | Avaliação manual iniciada pela pessoa em Ajustes | **Vigente (implementado localmente; validação em aparelho pendente)** | Refina a Decisão 77 somente para o toque explícito em Ajustes; o gatilho automático não muda | Luiz / Marco / Camillo / Renan |
| [111](#decisão-111) | Versionamento de produto em `X.Y (build)` | **Vigente** | Substitui a regra `MAJOR.MINOR.PATCH` para novas versões; builds já atribuídos não são renumerados | Luiz / Marco / Camillo / Renan |
| [112](#decisão-112) | Duelo de Host: desafio 1v1 para Discord/WhatsApp, landing web e expiração de 30 min | **Vigente** | Custo zero, sem banco de dados; payload no link com TTL de 30 min | Luiz / Marcelo / Priscila / Camillo / Renan |
| [113](#decisão-113) | Home Cockpit com Gauge Circular e Check de Conexão Geral (Refinamento por Jogo em 1 Toque) | **Vigente** | Refina a Home das Decisões 50 e 56 (Check sem jogo obrigatório) | Luiz / Squad |
| [114](#decisão-114) | Protótipo interno Windows (Compose Desktop sobre o `core` do Android) | **Em avaliação** | Não altera produto, score nem lojas; Windows não é alvo oficial | Luiz / Squad |
| [115](#decisão-115) | Identidade visual do protótipo Windows com ativos editoriais locais aprovados | **Em avaliação** | Refina a aparência da Decisão 114; não cria ativos, downloads ou uma versão pública de Windows | Luiz / Squad |
| [116](#decisão-116) | Windows (protótipo Compose Desktop): acabamento premium, mapa de rota com ping animado, verificação de atualização e telemetria de funil | **Em avaliação (protótipo, não publicável)** | Refina as Decisões 114 e 115; libera uma única consulta de atualização, inerte sem fonte | Luiz / Marcelo / Priscila / Camillo / Renan |
| [117](#decisão-117) | Design system: mapa por plataforma e divergências abertas entre tokens, iOS, Android e Windows | **Em avaliação (documental)** | Registra o estado lido do código; nenhum valor visual muda sem aprovação | Priscila / Camillo |



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
- **Status Atual:** **Superada pela Decisão 99.**
- **Resumo:** A assinatura Ed25519 continua obrigatória, mas o catálogo não é mais entregue pelo Cloudflare Worker: o mesmo envelope assinado acompanha os builds iOS e Android.

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
- **Status Atual:** **Suspensa por conflito, conforme Decisão 101.**
- **Resumo:** O fonte ainda contém cliente direto do Gemini, mas isso não é compatível com a restrição vigente de não acrescentar SDK ou infraestrutura externa sem autorização explícita. Não é evidência de serviço autorizado, funcional ou distribuído.

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
- **Status Atual:** **Decisão 45 suspensa por conflito; Decisão 46 vigente.** A suspensão da exceção Gemini segue a Decisão 101 e não altera o consentimento móvel.
- **Resumo:** O caminho Gemini permanece no fonte como implementação legada, sem autorização atual para chave, tráfego, distribuição ou serviço externo. A garantia de operação graciosa e o respeito ao tráfego da pessoa seguem vigentes.

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
- **Status Atual:** **Superada em escopo pela Decisão 89.** Os quatro jogos fazem parte do envelope local assinado de 48 jogos; build distribuído, aparelho e publicação continuam etapas separadas e pendentes.
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
- **Status Atual:** **Superada em parte pela Decisão 99.** O catálogo remoto, cache e atualização sem build não são mais o estado do código; o envelope assinado agora acompanha os dois clientes. O carregamento de arte remota ainda existe no fonte e permanece sujeito à política editorial das Decisões 18 e 44. Prova física e distribuição seguem pendentes.
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
- **Status Atual:** **Vigente (implementado localmente; validação física pendente).**
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
- **Status Atual:** **Vigente (implementado localmente; distribuição pendente).** O envelope Schema 3 com 48 jogos está assinado e acompanha o fonte; isso não comprova build distribuído, aparelho ou publicação. Refina o limite de ativação pendente da Decisão 70.
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
- **Status Atual:** **Vigente (implementado localmente; validação física pendente).** A seleção por respostas UDP/P50 está no fonte dos dois clientes; sua qualidade em redes reais ainda não foi comprovada. Refina as Decisões 16, 78 e 89 no que conflitar.
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
  1. O wordmark primary oficial é o aprovado pelo Luiz: símbolo modernizado, `lag` branco e `check` roxo (Decisão 66). As letras `lag` e `check` foram vetorizadas a partir do master aprovado (traçado sem o contorno escuro do raster), e o primary agora é vetor completo. O `check` mantém a cor aprovada `#7C34FD`, levemente mais viva que o token Roxo Gamer `#7C3AED`.
  2. Os wordmarks mono claro e escuro passam a ser vetores derivados das letras do primary, com o mesmo símbolo, em tinta sólida `#15181E` e `#F4F5F7`. O desenho angular antigo do mono sai de uso.
  3. Os PNGs de app (iOS, Android e Play) são regerados do novo primary, nos tamanhos que já existiam. `lagcheck-wordmark-light.svg` do design system deixa de apontar para um caminho inexistente.
  4. O traçado vem do raster aprovado, sem a fonte original do lettering. Se a fonte original aparecer, o redesenho com ela substitui este traçado.
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

#### Decisão 94

- **Data:** 17 de outubro de 2026.
- **Título:** Resultado iOS alinhado à hierarquia Android e card compartilhável local.
- **Status Atual:** **Vigente (implementado localmente; validação física pendente).** O fonte em `CheckCompletoResultView` e no exportador de card recebeu o recorte; renderização, acessibilidade e compartilhamento nativo em aparelho continuam sem prova. Refina a Decisão 80 exclusivamente para a tela de resultado iOS e suas referências visuais.
- **Frentes envolvidas:** Luiz (autorização), Giam (aceite operacional), Marco (prioridade), Renan (especificação e QA visual), Rian (iOS) e Breno (QA independente).
- **Contexto e problema:** O resultado Android atingiu uma hierarquia mais direta e madura. No iOS, a jornada normal comprovada (`startCheckDirectly → openDeepCheck`) apresenta `CheckCompletoResultView`, que já usa o veredito canônico, mas mantém ações em ordem diversa. `ResultFeatureView` continua compilada como implementação legada e renderiza `presentation.result`, porém não há callsite comprovado de `startQuickCheck`. Sua composição ainda privilegia score, trilha e grade de métricas; se a missão incluir sua manutenção ou reentrada na jornada, ela precisa obedecer à mesma direção visual antes de ser exposta.
- **Decisão:**
  1. Android passa a ser a referência de **hierarquia e acabamento** para a tela de resultado iOS da jornada ativa. Paridade significa a mesma leitura do jogador, não cópia mecânica de Compose: iOS preserva Safe Area, navegação, `sheet` de compartilhamento, VoiceOver e demais interações nativas. Esta decisão não cria nem reativa callsite para o fluxo legado; se ele entrar no escopo de manutenção, recebe o mesmo alinhamento antes de voltar à jornada.
  2. A composição iOS de resultado usa, nesta ordem: contexto discreto monoespaçado; kicker; `VerdictIndicatorBadge` separado; manchete de veredito limpa e dominante, sem score; subtítulo curto; telemetria monoespaçada de ping, jitter e perda; e um único painel `O QUE MAIS PESOU`. Campo não observado aparece como `—`. O painel mostra somente um sintoma ou achado observado; não atribui culpa a Wi-Fi, destino ou operadora.
  3. `Testar novamente` é a ação primária roxa e vem antes de `Ver detalhes`. `Otimizar` sai da superfície principal. Compartilhamento e PDF são ações secundárias, disponíveis somente para resultado conclusivo e com alvo de toque mínimo de 44 pt no iOS.
  4. O iOS prepara localmente, depois do primeiro frame, uma prévia de card compartilhável na proporção 1200×630 para resultado conclusivo. A prévia não compete com o veredito. Falha de preparação não remove nem degrada o resultado, e oferece recuperação clara. Não entram vídeo, formatos adicionais, folha de compartilhamento, ícones de destinos, telemetria de rádio, navegação ou outros comportamentos exclusivos do Android.
  5. Esta decisão não altera `GameReadinessVerdict`, score, thresholds, motor UDP, Worker, SwiftData, catálogo, telemetria, privacidade, custo recorrente ou integridade diagnóstica. Resultado inconclusivo preserva o estado honesto, sem score, causa, PDF ou artefato de compartilhamento.
  6. Renan atualiza a referência iOS versionada antes de a nova composição virar padrão. O protótipo Android continua sendo referência do Android; nenhuma mudança nele é requerida por esta decisão.
- **Critérios de validação e aceite:**
  - a jornada iOS ativa apresenta os quatro estados (`ready`, `caution`, `notReady`, `inconclusive`) com a mesma semântica e hierarquia do Android, sem alterar os dados apresentados;
  - `ResultFeatureView` só exige o mesmo alinhamento visual quando for incluída na missão de manutenção; esta decisão não exige novo mapeamento de estado, nem cria callsite para ela;
  - comparação renderizada lado a lado em iPhone e Android para os quatro estados, documentando apenas diferenças nativas aprovadas;
  - card 1200×630 é preparado localmente após o primeiro frame para resultado conclusivo; erro de render permite recuperação e não bloqueia resultado, detalhes ou novo Check;
  - `Testar novamente`, `Ver detalhes`, compartilhamento e PDF funcionam nos estados permitidos, com retorno e foco corretos;
  - PT-BR e inglês, Dynamic Type AX1–AX5, VoiceOver, contraste e alvos de 44 pt passam em simulador e iPhone físico; build e regressão iOS são evidência separada da referência Android.

#### Decisão 95

- **Data:** 17 de outubro de 2026.
- **Título:** Detalhes iOS na referência Android, com evidência diagnóstica preservada.
- **Status Atual:** **Vigente (implementado localmente; validação física pendente).** O recorte está no fonte em `TechnicalDetailsView`; fidelidade visual, acessibilidade e retorno de foco em aparelho continuam sem prova. Amplia a Decisão 94 à transição `Resultado → Ver detalhes` da jornada iOS ativa.
- **Frentes envolvidas:** Luiz (autorização), Giam (aceite operacional), Marco (prioridade), Renan (especificação e QA visual), Rian (iOS), Iury (integridade diagnóstica) e Breno (QA independente).
- **Contexto e problema:** Luiz aprovou as três capturas Android como referência 1:1 de experiência, composição e hierarquia também para os Detalhes iOS. A referência não pode converter fatos específicos do Android em fatos do iPhone. Uma captura combina `Sinal bom` com `Instabilidade no Wi-Fi local`: sinal de rádio, primeiro salto e rota UDP são leituras distintas. RSSI -43 dBm, Wi-Fi 5 GHz e PHY 433 Mbps podem coexistir com resposta degradada do gateway, mas não provam que o roteador causou a instabilidade; a consulta DNS do gateway pode ser encaminhada e inflar o RTT. Perda UDP na rota de referência também não identifica, sozinha, uma falha local.
- **Decisão:**
  1. A tela iOS ativa de Detalhes recebe a composição, densidade, hierarquia e transição observadas nas capturas Android: resumo compacto do veredito, score e métricas subordinados, gráfico condicional de repouso e carga, origem da evidência, achados observados e ação de retorno nativa. O iOS conserva `sheet`, navegação, Safe Area, Dynamic Type e VoiceOver próprios.
  2. Resultado e Detalhes iOS consomem a mesma `GameReadinessEvaluation`. Detalhes não recalcula score, veredito, causa ou recomendação, e não introduz cópia livre, heurística ou estado paralelo.
  3. Telemetria de rádio Android (RSSI, banda, PHY), gateway, NAT e recomendações específicas do Android não são reproduzidos no iOS por paridade visual. Só aparecem no iOS se já forem observados pelo próprio cliente, tiverem contrato autorizado e forem apresentados com sua origem e limite.
  4. A origem da evidência permanece separada: sinal de rádio descreve apenas RF; primeiro salto só recebe estado quando houver probe isolado e correlacionado; ping, jitter, perda e impacto sob carga descrevem a rota UDP observada. Ausência de leitura aparece como `Não observável` ou `—`.
  5. Nenhuma tela iOS afirma `Instabilidade no Wi-Fi local`, culpa o roteador, a operadora ou o destino, nem recomenda aproximação do roteador sem a evidência isolada exigida pela Decisão 50. Quando dados distintos coexistirem, a UI os mostra como observações independentes, sem inferir causalidade.
  6. O escopo é a jornada ativa `CheckCompletoResultView → TechnicalDetailsView`. `ResultFeatureView` legado não é reativada, não ganha callsite e permanece fora desta extensão.
- **Critérios de validação e aceite:**
  - Resultado e Detalhes exibem o mesmo veredito, score quando aplicável, métricas e achados da mesma avaliação para os estados `ready`, `caution`, `notReady` e `inconclusive`;
  - gráfico, métricas de carga, origem da evidência e recomendações aparecem somente quando os respectivos fatos existem; ausência não fabrica zero, causa ou diagnóstico;
  - prova de que sinal de rádio, primeiro salto e rota UDP não são apresentados como uma única causa; em particular, nenhum texto local acusa Wi-Fi ou roteador sem probe isolado correlacionado;
  - comparação lado a lado das três capturas Android e da renderização iOS registra fidelidade de composição e as diferenças justificadas por Apple ou por ausência de evidência;
  - retorno de foco para Resultado, PT-BR e inglês, Dynamic Type AX1–AX5, VoiceOver, contraste e alvos de 44 pt têm prova em simulador e iPhone físico; build e testes iOS são evidência distinta das capturas Android.

#### Decisão 96

- **Data:** 17 de outubro de 2026.
- **Título:** Anúncios nativos no Android em Home, Histórico, Jogos e Resultado.
- **Status Atual:** **Vigente (implementado localmente; validação em aparelho pendente).** Refina a Decisão 82 somente no formato e nas superfícies Android.
- **Frentes envolvidas:** Luiz (decisão de monetização e escopo), Giam (aceite), Marco (coordenação), Renan (experiência), Rian (Android) e Breno (validação).
- **Contexto e problema:** Luiz relatou que os banners atuais têm apresentação ruim e pediu sua substituição por anúncios nativos. Confirmou explicitamente a inclusão de Jogos e Resultado. A captura do AdMob mostra quatro unidades Native Advanced configuradas; ela não comprova integração, entrega de campanhas ou funcionamento no app.
- **Decisão:**
  1. No Android, substituir os banners adaptativos por unidades Native Advanced específicas de Home, Histórico, Jogos e Resultado. Não exibir anúncio em Check, Detalhes ou Configurações. A extensão posterior ao iOS está na Decisão 97.
  2. O anúncio deve ser identificado inequivocamente como publicidade, manter os elementos e ações exigidos pelo SDK, ser acessível e não imitar veredito, recomendação técnica ou conteúdo editorial do LagCheck.
  3. No Resultado, o veredito, a explicação e as ações essenciais têm prioridade visual e de interação. Anúncios nunca cobrem, atrasam ou interrompem medição, score, resultado ou histórico.
  4. Preservar a chave `lagcheck.adsEnabled`, o gate UMP/`canRequestAds`, a ausência de requisição/espaço quando desligado e a separação da telemetria de produto. Sem mediação, novo SDK ou serviço pago.
  5. Luiz escolheu manter IDs de teste nesta implementação. IDs reais serão configurados por unidade e pelo app Android em etapa posterior; a correspondência dos IDs da captura com o app Android e a configuração de privacidade/loja precisam ser conferidas antes de distribuição.
- **Critérios de validação e aceite:** unidade correta em cada tela; sem anúncio durante Check nem em superfícies excluídas; carregamento/falha/navegação sem bloquear conteúdo; identificação publicitária e TalkBack em PT-BR e inglês; veredito e ações do Resultado acessíveis antes do anúncio; testes de política/build e validação visual em emulador e aparelho Android. Publicação e campanhas não fazem parte desta decisão.

#### Decisão 97

- **Data:** 17 de outubro de 2026.
- **Título:** AdMob Native Advanced também no iOS, com IDs de produção do app iOS.
- **Status Atual:** **Vigente (implementado localmente; validação no Mac/iPhone pendente).** Amplia ao iOS o formato e as quatro superfícies da Decisão 96. QA estática de Breno e revisão arquitetural de Camillo concluídas por inspeção; Giam mantém aceite funcional e distribuição não validados.
- **Frentes envolvidas:** Luiz (decisão de monetização), Giam (aceite), Marco (coordenação), Camillo (gate de SDK/privacidade), Renan (experiência), Rian (iOS) e Breno (QA).
- **Contexto e problema:** após autorizar Native Advanced no Android, Luiz pediu a mesma publicidade no iOS com IDs de produção. Na conta AdMob aberta, o app `LagCheck: Teste de Ping Gamer Gratuito | iOS` tem App ID `ca-app-pub-5542349230926522~8215990145`, associado ao App Store ID `6818706960`, e quatro unidades Native Advanced: Home `/4055030074`, Histórico `/4883886853`, Jogos `/2936380361` e Resultado `/7813302529`, todas sob `ca-app-pub-5542349230926522`. A página informa verificação do app não confirmada e aprovação que requer revisão; a existência das unidades não comprova veiculação.
- **Decisão:**
  1. Integrar AdMob Native Advanced e UMP somente no app iOS completo, em Home, Histórico, Jogos e Resultado. Widget, App Clip, Check, Detalhes e Configurações não carregam ou exibem anúncios.
  2. Configuração Debug usa exclusivamente App ID e unidade nativa de teste do Google; configuração Release usa o App ID e as quatro unidades de produção iOS confirmadas acima. Nenhum teste local gera impressões reais. Ausência ou placeholder em Release falha no build.
  3. O consentimento UMP é consultado a cada abertura; anúncios só são inicializados e solicitados quando `canRequestAds` permite. Opções de privacidade aparecem nas Configurações quando requeridas. Sem autorização, falha de carga ou flag de anúncios desligada, não há requisição nem espaço reservado.
  4. O anúncio é identificado como publicidade, mantém AdChoices e assets/CTA do SDK, é acessível em PT-BR e inglês e não imita recomendação ou veredito. No Resultado, aparece depois do veredito, métricas, explicação e ações essenciais. Nunca interfere na medição, score, histórico ou telemetria de produto.
  5. Esta decisão autoriza implementação local e configuração de IDs de produção. Não autoriza upload, TestFlight, App Store, publicação web ou alteração externa no AdMob.
- **Critérios de validação e aceite:** build e teste iOS; inspeção de Debug e Release para os IDs corretos; ausência total de anúncio quando desligado ou sem `canRequestAds`; funcionamento em iPhone físico de consentimento regional, carga/falha, AdChoices, CTA, VoiceOver, Dynamic Type, navegação e retorno do background; atualização de privacidade, App Privacy e mensagens públicas antes da distribuição. Sem essa evidência, o release permanece não validado.

#### Decisão 98

- **Data:** 17 de outubro de 2026.
- **Título:** Quatro destinos iOS e Resultado/compartilhamento pela referência Android.
- **Status Atual:** **Vigente (implementado localmente; validação física pendente).** Resolve a divergência de integração entre as linhas paralelas de trabalho e refina as Decisões 51, 80, 94 e 95 somente na navegação e composição iOS.
- **Frentes envolvidas:** Luiz (aprovação), Giam (aceite), Marco (orquestração), Renan (composição), Rian (iOS) e Breno (validação).
- **Contexto e problema:** Histórico e Ajustes precisam ser destinos iOS de primeira classe. O Resultado, o card Link e as ações sociais têm uma composição iOS mais recente, aprovada pelo Luiz, que se aproxima da leitura Android sem transformar SwiftUI em uma cópia de Compose.
- **Decisão:**
  1. O iOS expõe **Início, Jogos, Histórico e Ajustes** em `TabView` com tab bar e símbolos SF nativos. Histórico e Ajustes são raízes, sem volta artificial; Android não é alterado por esta decisão.
  2. Para Resultado, compartilhamento e ações sociais, prevalece a composição iOS mais recente: veredito primeiro, prévia Link local antes da telemetria, ações sociais secundárias e acabamento próximo ao Android. Ações, Safe Area, folha de compartilhamento, Dynamic Type e VoiceOver continuam nativos do iPhone.
  3. O card Link 1200×630 usa somente arte editorial autorizada ou fallback neutro, dados do snapshot concluído e a rota observada. Resultado inconclusivo não cria card, prévia, PDF ou ação de compartilhamento.
  4. A paridade é de ordem de leitura, profundidade e decisão; não autoriza copiar componentes Material, fatos de rádio Android, atribuição causal local, ping de servidor do jogo, QR ou URL de loja inexistente no iOS.
  5. Native Ads continuam regidos pelas Decisões 96 e 97: surgem somente nos destinos permitidos e nunca tomam precedência sobre veredito, métricas, ações essenciais, Check, Detalhes ou estado inconclusivo.
- **Critérios de validação e aceite:** as quatro abas iOS são navegáveis; Resultado conclusivo apresenta veredito antes de prévia, telemetria, ações e anúncio; o inconclusivo não prepara/compartilha artefato nem exibe anúncio; o JPEG preserva dados e arte autorizados; PT-BR/inglês, Dynamic Type, VoiceOver e alvos de 44 pt passam em simulador e iPhone físico. Build, teste, simulador e aparelho físico permanecem provas distintas.

#### Decisão 99

- **Data:** 17 de outubro de 2026.
- **Título:** Catálogo global local nos clientes.
- **Status Atual:** **Vigente (implementação local; conformidade do Worker pendente).** Substitui a distribuição remota do catálogo da Decisão 14, preservando a assinatura Ed25519 e o schema 3. A limitação de rotas do Worker ainda não está refletida integralmente no fonte e fica explicitada na Decisão 101.
- **Frentes envolvidas:** Luiz (decisão), Giam (aceite), Marco (produto), Camillo (gate), Iury (integridade de rede), Rian (clientes) e Breno (validação).
- **Decisão:**
  1. iOS e Android usam somente o mesmo envelope Ed25519 instalado no build, com 48 jogos e referências AWS GameLift globais autorizadas. O catálogo não é baixado, cacheado nem interpretado a partir do Worker.
  2. A referência continua regional AWS, nunca servidor oficial de jogo. A seleção automática compara beacons locais por resposta UDP/P50 e regras determinísticas; São Paulo não é default geográfico.
  3. O Worker não expõe `GET /v1/catalog.json`; `GET /v1/load` e `POST /v1/telemetry` são os únicos contratos autorizados.
- **Critérios de validação e aceite:** recursos iOS/Android byte-idênticos; envelope válido com 48 jogos e referências globais; vetores de seleção preservados; nenhuma dependência HTTP/cache de catálogo; Worker retorna 404 para `/v1/catalog.json` e mantém carga/telemetria. Build e aparelho são prova posterior e separada.

#### Decisão 100

- **Data:** 17 de outubro de 2026.
- **Título:** Home imersiva por jogo e remoção do chrome redundante.
- **Status Atual:** **Vigente (implementado localmente; validação física pendente).** Refina a composição de Home sem alterar navegação, medição ou catálogo.
- **Frentes envolvidas:** Luiz (autorização), Giam (aceite), Marco (orquestração), Renan (composição), Rian (clientes) e Breno (validação).
- **Decisão:**
  1. iOS e Android abrem a Home pela arte editorial autorizada do jogo, protegida por gradiente escuro para leitura do sistema e do conteúdo.
  2. Wordmark e menu saem somente da Home; Histórico e Ajustes permanecem destinos primários. A ação `Trocar jogo` abre Jogos e o Check continua a única ação primária.
  3. A implementação reutiliza somente a arte editorial aprovada ou fallback neutro. Não muda score, veredito, rádio, Worker, persistência, catálogo ou políticas de anúncio.
- **Critérios de validação e aceite:** Home começa visualmente pela arte do jogo sem chrome vazio; status e CTA continuam legíveis; `Trocar jogo` e a pílula de rede funcionam; títulos localizados e escala de texto não truncam ações. Build, revisão visual e aparelho físico são evidências separadas.

#### Decisão 101

- **Data:** 17 de outubro de 2026.
- **Título:** Reconciliação do registro canônico com o código em `main`.
- **Status Atual:** **Vigente (auditoria documental; correção sistêmica pendente).** Esta decisão não autoriza infraestrutura, SDK, tráfego, distribuição ou publicação. Ela corrige o registro para que ninguém confunda presença no fonte com contrato autorizado ou prova de runtime.
- **Frentes envolvidas:** Giam (aceite documental), Marco (prioridade e escalonamento), Camillo e Iury (próxima correção sistêmica), Rian (clientes), Breno (evidência) e Luiz (qualquer nova autorização de produto, custo, privacidade ou serviço externo).
- **Evidência de código no commit auditado `c540cf45`:**
  1. Os três envelopes `worker/catalog/catalog-v3.envelope.json`, `Sources/NolaggyInfrastructure/Resources/DebugCatalogBase.json` e `android/app/src/main/assets/catalog-base.json` são byte-idênticos (SHA-256 `ce74a79be75eb14d192aa1259736ca63d593a19a518492e1c42a705d6f0e4cdf`). Eles verificam como Schema 3, versão `catalog-v3-2026.10.17.3`, com 48 jogos, 121 contextos e 242 rotas. iOS usa `BundledCatalogRepository`; Android lê `catalog-base.json`. Não há cliente de catálogo HTTP.
  2. O estado implementado de Histórico, lembrete pré-partida, widgets, seleção regional, resultado/detalhes iOS, navegação iOS, Home e Native Ads foi atualizado para **implementado localmente** apenas onde o fonte correspondente existe. Nenhum desses estados equivale a simulador, aparelho, beta ou produção.
  3. `worker/src/index.js` retorna 404 para `/v1/catalog.json`, como exige a Decisão 99. Porém ele também declara rotas públicas para arte, visita, clique, relatório de teste e waitlist, além de tarefa agendada. Isso contradiz o contrato vigente que autoriza naquele Worker somente `GET /v1/load` e `POST /v1/telemetry`. O estado de deploy não foi consultado; o achado é estritamente do fonte.
  4. O iOS ainda instancia `GeminiConnectionBoosterService`, que chama diretamente a API Gemini. A presença desse caminho contradiz a restrição vigente de não acrescentar serviço/SDK externo sem nova decisão; por isso as Decisões 23 e 45 ficam suspensas, não "implementadas" nem aprovadas.
- **Validação executada nesta revisão:** `npm test` no Worker passou 60 testes, incluindo catálogo local, ausência de `/v1/catalog.json`, telemetria e as próprias rotas extras; `./gradlew :core:catalog:test :core:session:test` passou. Isso prova contratos locais, não deploy, aparelho, consentimento, acessibilidade ou distribuição.
- **Decisão operacional:**
  1. A Decisão 99 substitui de fato o catálogo HTTP da Decisão 14 e a parte de catálogo remoto da Decisão 71. O catálogo local assinado é o único estado de cliente que pode ser tratado como corrente.
  2. As rotas extras e o caminho Gemini são achados de não conformidade, não autorização retroativa. Nenhuma pessoa deve ativá-los, depender deles em release ou ampliar seu escopo.
  3. Antes de qualquer correção de Worker, Gemini, privacidade, telemetria ou persistência, abrir missão **Full flow sistêmica** e Architecture Plan de Camillo. Luiz decide se cada capacidade será removida ou receberá nova autorização explícita.

#### Decisão 102

- **Data:** 17 de outubro de 2026.
- **Título:** Jogos: seleção direta, trilhos horizontais e contexto somente do iPhone.
- **Status Atual:** **Superada pela Decisão 107.** Seu recorte de trilhos, busca, favoritos reais, anúncio e escolha em um toque permanece; a restrição da vitrine ao contexto iPhone não permanece.
- **Frentes envolvidas:** Luiz (direção de produto), Giam (aceite), Marco (orquestração), Renan (experiência), Rian (iOS e Android) e Breno (QA).
- **Decisão:**
  1. Na aba **Jogos**, a pessoa escolhe somente o jogo. Não há escolha, filtro, texto ou ícone de plataforma, nem pergunta sobre Wi-Fi/cabo de equipamento externo, antes do Check.
  2. Fora da busca, a vitrine usa três trilhos horizontais, nesta ordem: **Recentes** (somente histórico real), **Favoritos** (somente IDs escolhidos e persistidos pela pessoa) e **Todos os jogos** (catálogo válido em ordem alfabética pelo nome localizado). Se Recentes ou Favoritos não tiverem dados reais, o trilho correspondente não aparece.
  3. Cada card tem arte editorial autorizada, nome localizado e ação direta para o Check. A busca substitui os trilhos por resultados alfabéticos e, sem resultado, oferece o Check Geral honesto. O anúncio Native Advanced, quando consentido e carregado, só entra depois de todo conteúdo essencial e nunca na busca ou no vazio.
  4. A rota continua sendo a referência medida pelo iPhone; o iOS resolve e revalida o contexto iPhone pelo catálogo assinado antes da pré-leitura, como o Android já faz. Não há fallback silencioso para contexto de console/PC e os campos históricos existentes (`platform`, vínculo externo) não são apagados nem reinterpretados.
- **Critérios de aceite:** mesma promessa e mesma ordem de informação em iOS e Android; interação e navegação nativas; PT-BR e inglês; alvos de 44 pt/dp, VoiceOver/TalkBack; busca, estado vazio e anúncio sem deslocar a escolha. Testes, simulador/emulador e aparelhos físicos são evidências separadas.
- **Critérios de aceite desta reconciliação:** índice e texto não afirmam catálogo remoto, Gemini ou exclusividade de rotas que o fonte não sustenta; o registro preserva a diferença entre inspeção estática, testes, simulador, aparelho e distribuição; qualquer correção subsequente começa pelo gate arquitetural, sem mudança silenciosa de contrato.

#### Decisão 103

- **Data:** 18 de outubro de 2026.
- **Título:** Paridade do motor de compartilhamento (Cards e Vídeo 14s) no iOS com App Store.
- **Status Atual:** **Vigente (implementado localmente e validado no simulador iOS).** Substitui o exportador pontual preliminar e estabelece paridade 1:1 com a arquitetura Android (`com.lagcheck.android.share`).
- **Frentes envolvidas:** Luiz (direção de produto), Giam (aceite), Marco (orquestração), Renan (design system e fidelidade visual), Rian (Swift/AVFoundation) e Breno (QA e regressão).
- **Problema diagnosticado no iOS anterior:**
  1. O QR Code nos cards gerados estava invertido verticalmente (renderizado de cabeça para baixo devido a inversão de coordenadas Quartz CoreGraphics em contexto UIKit).
  2. O QR Code apontava para `https://lagcheck.signallq.com` em vez da URL oficial da App Store (`https://apps.apple.com/app/id6818706960`).
  3. Não havia suporte aos formatos Stories (1080×1920) nem Vídeo MP4 (14s a 30fps em 1080×1920), presentes no Android.
  4. O selo da loja desenhava a wordmark duplicada sobre o texto inferior em vez do selo vetorial oficial da App Store.
  5. A prévia no resultado falhava silenciosamente quando `result` era nulo em fixtures de teste ou previews.
- **Decisão:**
  1. Adotar no iOS a mesma arquitetura modular e determinística do motor Android (`Sources/NolaggyApp/Share/`):
     - `ShareMediaScene`: modelo de dados puro e imutável, com formatação por locale (vírgula em pt-BR/es, ponto em en, sem zeros desnecessários). Inconclusivo não gera cena nem card (Decisões 50 e 64).
     - `ShareCanvas`: primitivas gráficas CoreGraphics/UIKit com tokens Dark Competitive UI (`#0B0D10`, `#F4F5F7`, `#8A93A0`, `#A78BFA`, `#7C3AED`, `#22C55E`, `#F59E0B`, `#FF5A36`). Desenho de QR Code nítido, sem inversão e com cantos arredondados no container. Selo vetorial oficial da App Store.
     - `ShareMediaImages`: carregamento seguro de imagens autorais, com `STORE_URL = "https://apps.apple.com/app/id6818706960"`.
     - `ShareMediaRenderer`: renderização de JPEG em 1200×630 (Link/Discord/WhatsApp) e 1080×1920 (Stories).
     - `ShareVideoTimeline` & `ShareVideoRenderer`: timeline de 14s (420 frames a 30fps) e pipeline de codificação MP4/H.264 via `AVAssetWriter`, reproduzindo fielmente as 3 cenas do Android (scanner de grade, contagem ao vivo da telemetria e revelação do veredito).
     - `PreparedShareCard`: cache efêmero baseado em SHA-256 e gravação atômica em disco temporário.
     - `ShareMediaSheetView`: modal com seletor segmentado de formato (Link, Stories, Vídeo), prévia dinâmica, progresso ao vivo e compartilhamento nativo para WhatsApp, Telegram, TikTok, X, Instagram, Discord, Mais e PDF.
  2. Preservar compatibilidade de API com a interface legada `LagCheckDiscordCardExporter` e acessibilidade (`check-completo-share-preview`, `check-completo-discord-share`, `check-completo-whatsapp-share`, `check-completo-export-pdf`).
- **Critérios de validação e aceite:**
  - Build limpo do target `Nolaggy` no Xcode/iOS Simulator.
  - Testes de UI (`CheckCompletoResultUITests`) passam 100%, incluindo interações do modal de compartilhamento, validação de estados inconclusivo e conclusivo em PT-BR e EN.
  - QR Code escaneável apontando para a App Store (`https://apps.apple.com/app/id6818706960`).
  - Zero dependência externa, SDK pago ou custo de infraestrutura.

#### Decisão 104

- **Data:** 18 de outubro de 2026.
- **Título:** Compartilhamento direto por rede no Resultado (card e vídeo).
- **Status Atual:** **Vigente (implementado localmente).** Refina a Decisão 103: a folha modal "Compartilhar" com abas Link/Stories/Vídeo sai do Resultado.
- **Decisão:**
  1. Ícones das redes ficam logo abaixo do card, no iOS e no Android: WhatsApp, Telegram, X, TikTok, Instagram e Discord. A concorrente do Discord pedida pelo dono do produto fica para decisão futura (rede ainda não definida).
  2. WhatsApp, Telegram, X e Discord enviam o card horizontal 1200×630, já preparado antes do toque; os ícones só habilitam quando o card está pronto. Legenda sem hashtags.
  3. TikTok e Instagram enviam o vídeo vertical de 14 s. O toque abre um pop-up com a porcentagem de geração e botão Cancelar; ao concluir, o app abre o destino. No iOS o destino é o menu nativo de compartilhamento (o sistema não permite escolher o app e o TikTok direto exigiria SDK, vedado pela regra de custo/SDK zero); no Android abre direto o app da rede, com seletor do sistema como alternativa. O vídeo gerado é reaproveitado enquanto a medição for a mesma.
  4. Legenda e hashtags do vídeo (`#LagCheck #Gamer #Ping #Lag #<Jogo>`) são copiadas para a área de transferência ao concluir, com aviso curto, porque Instagram e TikTok ignoram o texto enviado junto do arquivo. Nada é desenhado no vídeo além do já existente.
  5. Tocar no próprio card abre o menu do sistema com o card.
  6. Correção associada: o gradiente de escurecimento dos cards iOS sobrescrevia o alpha dos stops e cobria a arte do jogo; agora o alpha do stop é preservado.
- **Não-escopo:** SDK de TikTok/Instagram, ATT, novo endpoint, serviço pago.
- **Pendências:** validar em iPhone e aparelho Android físicos o abrir-app e a área de transferência; definir a concorrente do Discord; `UiStringsCompletenessTest` já falhava antes (strings da tela de Jogos) e não foi alterado aqui.

#### Decisão 105

- **Data:** 18 de outubro de 2026.
- **Título:** Jogos: paridade visual e de interação entre iOS e Android.
- **Status Atual:** **Vigente (implementado localmente; runtime pendente).** Refina a Decisão 102 sem mudar catálogo, histórico, medição, widgets, deep links ou o contrato dos trilhos.
- **Frentes envolvidas:** Luiz (direção de produto), Giam (aceite), Marco (orquestração), Renan (experiência), Rian (iOS e Android) e Breno (QA).
- **Problema:** a crítica de UI/UX da tela Jogos achou divergências que mudavam o que a pessoa conseguia fazer (favoritar só no Android), copy diferente ("Usados recentemente" vs "Recentes"), busca com regra e forma diferentes, card com moldura e tamanho diferentes, nome truncado no Android, valores tipográficos soltos e contraste insuficiente no rótulo dos trilhos do iOS.
- **Decisão:**
  1. **Favoritar** é uma estrela no canto da arte do card, nos dois clientes, com alvo de 44 pt/dp separado do alvo de iniciar o Check. O limite é de **4 favoritos** nos dois; o mais novo entra primeiro e, ao passar do limite, o mais antigo sai (toque nunca fica sem efeito).
  2. **Card único:** arte 4:3 de 140 pt/dp, sem moldura de superfície, nome em largura total e sem corte de linhas. Rótulos dos trilhos em caixa alta, fonte mono e cor secundária (contraste ≥ 4,5:1): `RECENTES`, `FAVORITOS`, `TODOS OS JOGOS A–Z`.
  3. **Busca** sempre visível abaixo do título, em pílula com borda de 1 px (foco em Roxo Gamer) e botão limpar de 44 pt/dp. Filtra somente pelo nome localizado, nos dois clientes. Enquanto há texto, os trilhos somem e os resultados aparecem em **lista vertical A–Z** (`RESULTADOS (n)`) com a mesma estrela.
  4. **Vazio:** título curto e o botão `Fazer Check Geral` (ação primária), sem ícone decorativo, sem texto explicativo e sem cartão.
  5. Cabeçalho idêntico: voltar (quando existir), wordmark centralizada e título `Jogos`; margem lateral de 24.
  6. **Todos os jogos A–Z** passa de trilho horizontal para **grade vertical de 2 colunas**, nos dois clientes: mostra mais jogos por tela e usa a rolagem que a tela já tem. Recentes e Favoritos (no máximo 4) continuam em trilho. Isso **substitui** o item 2 da Decisão 102 apenas quanto ao formato de "Todos os jogos"; ordem, fontes de dados e anúncio ao final seguem iguais.
- **Não-escopo:** catálogo, arte, regra de veredito, persistência além do limite de favoritos, anúncios.
- **Critérios de aceite:** testes de favoritos (limite, ordem, remoção) nos dois clientes; build iOS e Android; strings PT-BR/EN/ES completas; validação em simulador/emulador, VoiceOver/TalkBack, escala de texto e aparelho físico seguem como evidências separadas e pendentes.

#### Decisão 106

- **Data:** 18 de outubro de 2026.
- **Título:** Catálogo embutido sem assinatura nem validade; EUA e artes autorais.
- **Status Atual:** **Vigente (implementado localmente; runtime pendente).** Refina a Decisão 99 e **substitui** dela somente a exigência de assinatura Ed25519 e de validade de 30 dias.
- **Frentes envolvidas:** Luiz (decisão), Giam (aceite), Marco (orquestração), Camillo (gate), Iury (integridade do catálogo), Rian (clientes) e Breno (QA).
- **Problema:** o envelope assinado foi desenhado para catálogo baixado da rede. Com o catálogo dentro do build, a assinatura só adicionava custo: dependência de uma chave privada guardada em um único Keychain e envelope que expira em até 30 dias. O envelope então embutido vencia em 2026-11-16 e, depois disso, todo build instalado recusaria o catálogo e mostraria "Games unavailable right now". Em paralelo, 8 dos 16 primeiros downloads vieram dos EUA e várias artes do catálogo eram material de terceiros.
- **Decisão:**
  1. iOS e Android carregam o catálogo embutido como **payload JSON puro**, sem `signatureBase64`, `issuedAt` nem `expiresAt`. A integridade vem da assinatura de código da Apple e do Google; o catálogo não é baixado nem cacheado.
  2. O leitor (`RemoteCatalogVerifier.decodeBundled`, iOS e Android) valida somente tamanho (≤ 128 KiB), schema 3 e regras de negócio (regiões AWS GameLift permitidas, rotas, perfis, ids, artes). `verifyAndDecode` permanece apenas como legado de testes.
  3. A fonte única é `worker/catalog/catalog-v3.canonical.js`; `catalog-v3.candidate.json`, `DebugCatalogBase.json` e `catalog-base.json` são idênticos byte a byte, garantido por teste do Worker. Não há mais passo externo de assinatura.
  4. O catálogo passa a ter **54 jogos** (`catalog-v3-2026.10.18.1`), com Clash Royale, Pokémon UNITE, Genshin Impact, Mobile Legends: Bang Bang, Delta Force e Standoff 2 para o mercado dos EUA. A referência continua regional AWS; a baliza é escolhida pela menor latência UDP entre todas as regiões (Decisão 90), nunca pelo país.
  5. Artes que reproduziam material de terceiros foram substituídas por artes originais do LagCheck (15 imagens, 1376×768): Marvel Snap, Squid Game: Unleashed, Tacticool (capa de álbum de outra franquia), Roblox (logo), Star Wars: Hunters, Overwatch 2, Super Mega Baseball 4, Legacy: Steel & Sorcery e Dungeons & Dragons: Dark Alliance, além das seis dos jogos novos. Nenhuma arte tem texto, logo ou personagem de franquia.
- **Não-escopo:** Worker (nenhum endpoint novo), score, veredito, motor UDP, publicação, upload de loja e o site `web/`.
- **Pendências:** reimplantar o Worker para parar de servir as artes antigas; o site `web/` ainda usa `roblox.jpg` e outras imagens próprias; remover `verifyAndDecode` e as telas mortas de resultado (`resultView(result:)` e `DeepCheckResultView`) em limpeza futura; validar em aparelho, em rede dos EUA, o veredito e a escolha da baliza. Testes de schema 2 do catálogo, um teste de DeepCheck e os testes de UI de localização já falhavam antes desta decisão.
- **Critérios de aceite:** catálogo carregado sem data de validade em qualquer data; Worker, iOS e Android byte-idênticos; testes de catálogo, Worker e Android verdes; build iOS verde.

#### Decisão 107

- **Data:** 21 de outubro de 2026.
- **Título:** Jogos: vitrine completa e contexto automático validado.
- **Status Atual:** **Vigente (implementado localmente; runtime pendente).** Substitui da Decisão 102 somente o recorte que escondia jogos sem contexto iPhone.
- **Frentes envolvidas:** Luiz (decisão), Giam (aceite), Marco (orquestração), Renan (experiência), Rian (clientes) e Breno (validação).
- **Problema:** o catálogo embutido já validava 54 jogos, mas a vitrine mostrava somente os 23 que tinham contexto iPhone. Para quem sabe que o LagCheck mede a rota pelo telefone, a lista parcial reduz descoberta sem tornar a promessa mais clara.
- **Decisão:**
  1. A aba **Jogos** mostra todo jogo com ao menos um contexto disponível no mercado resolvido pelo catálogo; não filtra a descoberta por plataforma.
  2. Um toque continua sem seletor intermediário. O cliente resolve somente um contexto publicado e disponível: plataforma preferida válida, iPhone quando disponível ou, sem ele, a plataforma válida do catálogo. Não inventa uma rota, não converte console/PC em iPhone e não cai silenciosamente em outro jogo.
  3. Quando o contexto resolvido for externo ao iPhone, a jornada e o resultado mantêm a plataforma visível e identificam a leitura como estimativa feita pelo iPhone naquela rede. Não assumem que o equipamento usa Wi-Fi ou cabo, nem chamam a métrica de ping real do jogo.
  4. A mudança preserva JSON, schema, arte editorial, regiões, rotas, score, veredito, histórico, Worker, telemetria, anúncios e ações nativas. iOS e Android usam seus resolvedores já validados; não há endpoint, persistência nem alteração de regra.
- **Critérios de aceite:** os 54 jogos válidos aparecem em Jogos no mercado BR/US correspondente; busca encontra um título sem contexto mobile e seu toque abre Check com a plataforma resolvida; títulos com iPhone continuam usando-o; resultado externo traz plataforma e aviso de estimativa; PT-BR e inglês, busca, favoritos, anúncio e alvos de toque não regressam. Build/teste, simulador/emulador e aparelho físico permanecem evidências distintas.

#### Decisão 108

- **Data:** 25 de outubro de 2026.
- **Título:** Analytics do funil iOS com Firebase, exclusão local e privacidade mínima.
- **Status Atual:** **Implementado; DebugView validado no simulador; aparelho físico pendente.** Em 25 de outubro de 2026, o filtro de tráfego de desenvolvedor foi ativado no GA4 e o DebugView recebeu `game_selected`; `first_open`, `session_start` e `user_engagement` vieram do SDK. O simulador não executa o Check, portanto não prova os eventos de início e desfecho do diagnóstico.
- **Frentes envolvidas:** Luiz (autorização), Marco (produto), Camillo (arquitetura), Renan (prova) e Giam (aceite).
- **Decisão:** o app iOS principal passa a enviar ao Firebase somente os eventos do funil `game_selected`, `lagcheck_started`, `lagcheck_completed`, `lagcheck_inconclusive`, `lagcheck_cancelled`, `result_viewed` e `retest_started`. Os únicos parâmetros são jogo, plataforma, região, tipo de rede, classe do resultado, duração e motivo terminal quando existir; IP, SSID, BSSID, identificadores de hardware, endereços de destino e amostras brutas seguem proibidos. Eventos automáticos do Firebase não são replicados pelo app. A telemetria atual do Worker permanece sem mudança e continua sujeita ao seu contrato; Firebase não cria endpoint, banco nem serviço próprio do LagCheck.
- **Exclusão de testes:** Debug não coleta por padrão. A validação deliberada no DebugView depende de argumentos de execução e de filtro de tráfego de desenvolvedor no GA4. Uma chave persistente, local à instalação e sem login desliga todos os destinos de analytics para o aparelho do proprietário; ela é acionada por deep link interno e não aparece na interface pública. A coleta começa desativada no plist e só é habilitada depois que a preferência local é lida, reduzindo a janela do primeiro evento. A exclusão acionada pela primeira vez em uma instalação já aberta não apaga nenhum evento que ela possa ter enviado antes.
- **Privacidade e limites:** sem ATT, IDFA, personalização de anúncios, user ID, vinculação entre apps ou alteração de UMP. Antes de distribuição, política pública e App Privacy do App Store Connect devem refletir o archive real e a coleta efetiva do Firebase e do AdMob/UMP.
- **Critérios de aceite:** build iOS resolve Firebase Core/Analytics somente no app principal; testes automatizados não enviam eventos; a exclusão persiste após reinício; cada diagnóstico gera no máximo um evento terminal; DebugView prova cada caminho do funil em iPhone; o console GA4 tem os parâmetros personalizados registrados e o filtro de tráfego de desenvolvedor ativo.

#### Decisão 109

- **Data:** 25 de outubro de 2026.
- **Título:** Analytics do funil Android com Firebase, variante Debug preservada e exclusão local.
- **Status Atual:** **Em implementação; validação física e DebugView pendentes.**
- **Decisão:** o Release Android envia ao Firebase `game_selected`, `lagcheck_started`, `lagcheck_completed`, `lagcheck_inconclusive`, `lagcheck_cancelled`, `result_viewed` e `retest_started`, com os mesmos parâmetros canônicos do iOS. O início só ocorre quando a medição UDP começa; cada medição tem no máximo um desfecho; resultado visto nasce após a tela aparecer. O Firebase não recebe IP, SSID, BSSID, MAC, localização, destino ou amostra bruta. Eventos automáticos do SDK não são duplicados e o Worker atual não é alterado.
- **Variants e exclusão:** `com.lagcheck.app` usa a configuração do projeto `lagcheck-analytics` apenas no Release. `com.lagcheck.app.debug` continua sem cadastro Firebase, compila sem `google-services.json` e fica com coleta desligada. A coleta do Release começa bloqueada no manifest e só é habilitada depois de ler a chave local persistente. Em Ajustes, a pessoa pode excluir ou reativar manualmente a própria instalação; não há deep link, conta ou parâmetro externo que altere a escolha. A exclusão não controla AdMob/UMP.
- **Privacidade e limites:** Firebase Analytics não coleta Advertising ID nem emite sinal padrão de personalização de anúncios. A integração não adiciona Auth, banco, Crashlytics, endpoint, dashboard ou infraestrutura paga. UMP e os anúncios continuam independentes; antes de publicar, Segurança de Dados da Play e política pública precisam ser confrontadas com o AAB real e a configuração final do GA4/AdMob.
- **Critérios de aceite:** `assembleDebug` continua passando sem um segundo cadastro Firebase; Release resolve o JSON de `com.lagcheck.app`; testes não enviam eventos; uma instalação excluída permanece excluída após reiniciar; cada caminho terminal gera um único evento; DebugView em aparelho Release e o filtro de desenvolvedor no GA4 comprovam o funil antes da publicação.

#### Decisão 110

- **Data:** 1º de novembro de 2026.
- **Título:** Avaliação manual iniciada pela pessoa em Ajustes.
- **Status Atual:** **Vigente (implementado localmente; validação em aparelho pendente).** Refina somente o gatilho manual da Decisão 77.
- **Contexto e decisão:** a linha `Avaliar o LagCheck` em Ajustes existia, mas só mostrava um aviso sem iniciar nenhuma ação. Quando a pessoa a toca, o esperado é abrir a solicitação nativa da loja. No iOS, esse toque passa a chamar diretamente o pedido do StoreKit, sem tela intermediária, texto persuasivo ou coleta adicional. Esta exceção é estritamente iniciada pela pessoa: o gatilho automático permanece idêntico ao da Decisão 77 — terceiro Check `PRONTO PARA RANKED`, espera de 1,5 s, uma solicitação por versão e cooldown de 90 dias.
- **Limites:** a Apple decide se exibe o diálogo naquele momento. O app nunca afirma que a avaliação foi mostrada nem grava esse toque como uma exibição do gatilho automático. Não há alteração no Android, em score, Check, anúncios, telemetria, Worker ou privacidade.
- **Critérios de aceite:** em iPhone físico, tocar em `Avaliar o LagCheck` abre a solicitação nativa quando o sistema a disponibilizar, sem toast enganoso e sem modal próprio; o fluxo automático continua coberto pelos testes de política e coordenação.

#### Decisão 111

- **Data:** 1º de novembro de 2026.
- **Título:** Versionamento de produto em `X.Y (build)`.
- **Status Atual:** **Vigente.** Substitui a convenção `MAJOR.MINOR.PATCH` para toda nova atribuição de versão.
- **Decisão:** a versão de produto passa a ter duas partes, `MAJOR.MINOR`, e o build inteiro crescente aparece sempre separado, no formato `X.Y (build)`. O `MINOR` avança a cada nova versão liberada, incluindo correções; o `MAJOR` fica reservado para uma mudança incompatível de promessa ou contrato. Tags passam a usar `vX.Y`; arquivos Android aceitam somente `versionName` com duas partes. Quando o release for disparado no GitHub, o build vem de `run_number + offset`: o offset inicial é 11, último build já atribuído, para que a primeira execução produza 12. Número de PR, hash de merge e tag permanecem como rastreio do código, não como versão enviada à loja.
- **Limite:** versões já atribuídas a builds não são renumeradas, para não comprometer o histórico da App Store, TestFlight ou Play. A regra vale na próxima definição de versão e build. Em Ajustes, iOS e Android mostram sempre o identificador completo disponível no binário.
- **Critérios de aceite:** documentação, scripts e defaults novos rejeitam ou não instruem `X.Y.Z`; a tela Ajustes mostra a versão e o build entre parênteses; a próxima versão destinada às lojas usa o formato novo sem reaproveitar build.

#### Decisão 112

- **Data:** 5 de novembro de 2026.
- **Título:** Duelo de Host: desafio 1v1 para Discord/WhatsApp, landing web de onboarding e expiração de 30 min.
- **Status Atual:** **Aprovada (em implementação).**
- **Frentes envolvidas:** Luiz (aprovação), Marcelo (produto), Priscila (design/UX), Camillo (arquitetura/implementação) e Renan (QA/prova real).
- **Contexto e problema:** Para acelerar a aquisição orgânica de jogadores competitivos e criar um ritual de lobby no Discord ("quem cria a sala?"), o LagCheck introduz o **Duelo de Host**. O jogador que concluiu um Check em um jogo pode desafiar um amigo diretamente via link/texto compartilhado.
- **Decisão e arquitetura (Custo Zero e Paridade Nativa):**
  1. **Domínio Canônico e Compartilhamento:** O domínio oficial do link é `https://lagcheck.signallq.com/vs`. Todos os dados do desafio (jogo, ping, perda de pacotes, jitter, veredito, timestamp e nick opcional) trafegam codificados no próprio link (`base64` / URL segura). Zero servidores ou bancos de dados adicionais.
  2. **TTL e expiração de 30 minutos:** O desafio é válido por exatamente 30 minutos a partir do timestamp de medição. Passado esse intervalo, o link é considerado expirado no app e na web.
  3. **Regra de Gatilho e Vitória:** Ação disponível em qualquer resultado conclusivo (`Pronto`, `Evitaria` ou `Instável`). O critério de vitória é: 1º Veredito (estabilidade e perda sob carga superam ping bruto); 2º Menor latência P50 em caso de empate.
  4. **Paridade Nativa iOS e Android:** Implementado com contratos espelhados no iOS (SwiftUI, SwiftData/UserDefaults) e no Android (Kotlin, Jetpack Compose, DataStore/Room). Em ambos, abrir o link exibe confirmação em 1 toque ("Aceitar e Medir") e histórico registra o badge de duelo. Exportação suporta texto formatado pro Discord e imagem gerada do card de placar.
  5. **Jornada de onboarding (sem o app instalado):** Na web em `lagcheck.signallq.com/vs`, exibe a tela de confronto em Dark Competitive UI, botão direto para baixar nas lojas (App Store e Play Store) e resposta de W.O. para colar na call.
- **Limites e privacidade:** Sem conta, sem login e sem rastreamento de IP ou dados pessoais; cumprimento estrito da regra do custo zero; sem anúncios extras fora das superfícies autorizadas.
- **Critérios de aceite:** O link gera o payload correto sob `lagcheck.signallq.com/vs`; suites de teste iOS (`swift test`) e Android (`./gradlew test`) cobrem codificação, expiração de 30 min e resolução de vitória; UI em SwiftUI e Compose respeita o design system sem bordas em cards.

#### Decisão 113

- **Data:** 5 de novembro de 2026.
- **Título:** Home Cockpit com Gauge Circular e Check de Conexão Geral (Refinamento por Jogo em 1 Toque).
- **Status Atual:** **Vigente (Aprovada por Luiz).** Refina a jornada das Decisões 50 e 56.
- **Frentes envolvidas:** Luiz (aprovação), Marcelo (produto), Priscila (design/UX), Camillo (arquitetura/implementação) e Renan (QA/prova real).
- **Contexto e problema:** A jornada atual do LagCheck exige obrigatoriamente a seleção de um jogo para realizar uma medição. No entanto, muitos jogadores abrem o app no lobby apenas para responder à pergunta fundamental: *"como está a minha conexão agora pra jogar online?"*. Exigir um jogo como protagonista na Home criava fricção desnecessária.
- **Decisão e experiência:**
  1. **Gauge Circular Protagonista no centro da Home:** A Home adota o componente oficial `HomeCircularPulseGaugeHero` (arco em Roxo Gamer `#7C3AED` e ondas dinâmicas de pulso esportivo). O centro do gauge é estritamente minimalista, contendo apenas a ação **"TESTAR"** em destaque, sem poluição de kickers ou rótulos secundários didáticos.
  2. **Check de Conexão Geral:** Tocar no Gauge inicia imediatamente o diagnóstico de Conexão Geral, medindo repouso e carga UDP para a infraestrutura de referência regional mais próxima de menor latência e maior estabilidade (`sa-east-1` em SP para o Brasil).
  3. **Preservação da Atmosfera e DNA do App:** A pílula de rádio local (`Wi-Fi 5 GHz · 18 ms`) permanece no topo e a linha de último resultado verificado (`● PRONTO PARA RANKED · há X min`) fica logo abaixo do gauge, mantendo 100% da identidade Dark Competitive UI.
  4. **Refinamento por Jogo em 1 Toque:** Na seção inferior da Home, um carrossel horizontal compacto (`TESTAR POR JOGO`) exibe os títulos favoritos e recentes. Tocar no card de um jogo dispara instantaneamente a medição direcionada para os servidores daquele jogo específico (zero fricção no lobby).
  5. **Histórico e Duelo de Host:** O resultado do Check Geral é registrado no histórico local como "Conexão Geral" e suporta a criação de "Duelo de Host" 1v1 para comparar a rota pura entre amigos na call.
  6. **Paridade Nativa Obrigatória:** Implementação espelhada em SwiftUI (iOS 17+) e Jetpack Compose (Android API 26+).
- **Critérios de aceite:** No iOS e no Android, a Home renderiza o Gauge Circular com "TESTAR" no centro; tocar no gauge dispara o Check Geral na rota regional de referência; tocar em um jogo no carrossel mede o jogo específico; o resultado do Check Geral aparece no histórico e gera link de Duelo de Host válido; testes de unidade e compilação passam 100%.

#### Decisão 114

- **Data:** 7 de novembro de 2026.
- **Título:** Protótipo interno Windows (Compose Desktop sobre o `core` do Android).
- **Status Atual:** **Em avaliação (protótipo, não publicável).** Windows **não** é alvo oficial; não há loja, anúncio, telemetria nem release.
- **Frentes envolvidas:** Luiz (aprovação do protótipo), Marcelo (produto), Camillo (implementação).
- **Contexto e problema:** Jogador de PC hoje usa o celular como estimativa. Medir do próprio PC removeria essa margem, mas muda a promessa e a regra de score para PC.
- **Decisão:** Criar `android/desktop/` (Kotlin JVM + Compose Desktop) que reaproveita `core:session`, `core:network`, `core:catalog` e `core:domain` sem duplicar regra. Mede a região genérica do catálogo embarcado com `Platform.PC`. Sem anúncio, histórico, widget, Wi-Fi/rádio e telemetria.
- **Fora de escopo:** publicação (Microsoft Store/MSI assinado), taxa de loja ou certificado, receita, regra de score específica para PC, mudança no Worker.
- **Design system e navegação do protótipo:** documentados em [`docs/09-design-system-windows.md`](./09-design-system-windows.md). Tokens idênticos à Dark Competitive UI; navegação por barra lateral (Início, Jogos, Histórico, Ajustes), adaptação desktop da tab bar de 2 abas do mobile. Telas: Início (anel "TESTAR"), Jogos (busca), Check, Resultado, Histórico (só na sessão), Ajustes e galeria de componentes (`--ds`).
- **Pendências de decisão antes de virar produto:** público (lobby vs. jogador de PC), receita sem AdMob, custo único da Microsoft Store, nova regra/versão de score para PC com vetores e revisão de Iury.
- **Evidência:** compila; `./gradlew :desktop:runCli` executou 60 probes UDP + carga HTTP reais num Mac e devolveu `READY`, ping ~19 ms, perda 0%. **Não validado em Windows** (firewall, VPN, múltiplos adaptadores) nem a janela desktop foi inspecionada visualmente.

#### Decisão 115

- **Data:** 7 de novembro de 2026.
- **Título:** Identidade visual do protótipo Windows com ativos editoriais locais aprovados.
- **Status Atual:** **Em avaliação (protótipo, não publicável).** Refina somente a apresentação da Decisão 114; Windows continua fora do alvo oficial.
- **Frentes envolvidas:** Luiz (direção), Marcelo (produto), Priscila (fidelidade visual), Camillo (implementação) e Renan (prova).
- **Contexto e problema:** a primeira adaptação desktop preservou cor e anel, mas continuou distante do Android por trocar a wordmark por texto, usar glifos genéricos na navegação e omitir as artes editoriais que dão contexto aos jogos.
- **Decisão:** o desktop passa a empacotar e exibir somente os ativos locais já aprovados no Android: wordmark oficial, artes editoriais autorais de jogos e a linguagem dos ícones de navegação. A Home usa a arte editorial como atmosfera e nos atalhos de jogos; Jogos e Histórico usam miniatura quando ela estiver disponível. Ícones da barra lateral seguem o desenho da navegação Android, não caracteres Unicode.
- **Guardrails:** nenhuma arte, logo, personagem ou capa de terceiro é criada ou baixada; não há URL, refresh remoto, Worker, telemetria, anúncio ou custo novo. Se faltar um ativo local compatível, a tela mantém o fallback neutro do LagCheck. A UI não inventa leitura de rádio, Wi-Fi, adaptador ou métrica.
- **Critérios de aceite:** a wordmark renderizada é o ativo oficial, cada arte exibida corresponde ao recurso editorial local aprovado, a navegação não usa glifos tipográficos genéricos, Home/Jogos/Histórico mantêm leitura e foco por teclado, e build/capturas passam sem alterar Check, score ou veredito.

#### Decisão 116

- **Data:** 7 de novembro de 2026.
- **Título:** Windows (protótipo Compose Desktop): acabamento premium, mapa de rota com ping animado e verificação de atualização.
- **Status Atual:** **Em avaliação (protótipo, não publicável).** Refina as Decisões 114 e 115; Windows continua fora do alvo oficial e não há loja, release, anúncio nem telemetria. Autorizada por Luiz em conversa.
- **Publicação (7 de novembro de 2026):** por pedido expresso de Luiz, a prévia **`windows-v0.1.0`** foi publicada em https://github.com/gmmattey/lagcheck/releases/tag/windows-v0.1.0 (instalador `.exe`, `.msi` e checksums; sem assinatura de código; não marcada como prerelease nem como "latest" para não competir com iOS e Android), o `lagcheck-site` foi publicado com a página `/windows/` e o endpoint `GET /v1/approx-location`, e o repositório está público. Windows continua **fora do alvo oficial**.
- **Frentes envolvidas:** Luiz (direção), Marcelo (produto), Priscila (fidelidade visual), Camillo (implementação e Gate do atualizador), Renan (prova visual), Breno (validação).
- **Contexto:** o protótipo `android/desktop/` já existe e usa as artes editoriais do Android (Decisão 115). Luiz quer visual premium dentro do design system do Android (inspiração NVIDIA App e Razer Synapse, sem fugir da Dark Competitive UI), a fonte Google Sans Flex, sem pills clássicas, o mapa de detecção de região com ping animado e a verificação de atualização na abertura. A especificação visual é o protótipo HTML `design-system/prototypes/windows-premium/` (apenas referência; código de produto é Compose Desktop).
- **Decisão (visual):** tipografia Google Sans Flex embarcada (corpo e títulos), mono do sistema para métricas; estado e veredito como marcador com barra lateral colorida e texto mono, **sem pill arredondada**; seções separadas por linha fina, sem card por bloco, sem vidro; tiles de jogo com a arte editorial já embalada (as 51 artes do Android; nenhuma arte nova) e degradê de leitura; microinterações de 150 a 250 ms com `cubic-bezier(.2,0,0,1)`, hover e foco completos, transições de tela, indicador de navegação animado; respeitar Reduzir movimento. Sombra só no botão principal e no toast. Nenhuma mudança em Check, score, veredito ou regras do `core`.
- **Decisão (mapa):** mapa de pontos desenhado em Compose (grade pré-gerada do Natural Earth 110m, domínio público, embarcada) mostrando "Você" até a região medida, com pacotes animados **somente durante a medição real**, refletindo as sondas reais (enviada, voltou com RTT, perdida). Posição do usuário: cidade aproximada **pelo IP**, obtida pelo endpoint do `lagcheck-site` (ver abaixo), nunca GPS. Sem reserva por fuso: se a consulta falhar, estiver desligada em Ajustes ou o endpoint do site ainda não estiver publicado, o mapa mostra só a região medida, sem o pino "Você". A fase de "testar várias regiões" só aparece se o `core` realmente medir várias regiões; sem isso, o mapa mostra apenas a região selecionada. Nada é simulado como medição.
- **Decisão (atualização):** única exceção aos guardrails de rede da Decisão 115: uma consulta HTTPS por abertura (no máximo uma a cada 6 horas) a um manifesto ou API pública de releases, sem login, sem identificação do usuário, sem telemetria e sem custo. A fonte fica numa constante **vazia por padrão**: sem fonte, o recurso é inerte e a UI não promete atualização. Modo semiautomático (padrão): faixa "Nova versão X.Y" com Atualizar agora e Depois; baixa o instalador, confere SHA-256 (e só executa se bater) e abre o instalador. Modo automático (opt-in): baixa e confere em segundo plano e instala somente ao fechar o app, com aviso, nunca durante um check. Apenas HTTPS, lista fechada de hosts, sem downgrade, sem elevação silenciosa; falha de rede nunca aparece como erro nem trava a abertura. A UI diz "verificado por checksum", não "assinado". Por decisão de Luiz (7 de novembro de 2026), a fonte é **GitHub Releases do próprio repositório `gmmattey/lagcheck`, tornado público nessa data**, consultado sem login em `GET /repos/gmmattey/lagcheck/releases`, filtrando as tags `windows-vX.Y.Z` (o repositório também tem releases de iOS e Android); o instalador esperado é o asset `LagCheck-Windows-{versão}-x64-setup.exe` com o SHA-256 no campo `digest` do asset ou em um arquivo `.sha256` da mesma release. Antes de abrir o repositório foi feita varredura de segredos (nenhum token, chave privada, webhook ou keystore no histórico); permanecem versionadas as duas chaves de API de cliente do Firebase (iOS e Android), que devem ser restringidas por pacote/bundle no Google Cloud. Publicar uma release do Windows continua exigindo autorização expressa de Luiz.
- **Decisão (localização por IP, endpoint do site):** por escolha de Luiz, a posição vem de **um único endpoint novo no `lagcheck-site`** (o Worker da landing em `lagcheck.signallq.com`, repositório `gmmattey/sites`, pasta `sites/lagcheck/`): `GET /v1/approx-location`, que devolve apenas cidade, país e latitude/longitude **arredondadas a 0,5°** (cerca de 50 km), derivadas dos dados que a própria Cloudflare já entrega no pedido (`request.cf`), sem custo e sem terceiro. O **Worker `nolaggy-deep-check` não é alterado** (Luiz decidiu não publicar nele). O endpoint **não grava, não registra e não repassa** IP nem localização, não usa cookie, responde `Cache-Control: no-store` e `404` sem corpo quando a Cloudflare não informar a posição; não interfere em `/v1/click`, `/v1/visit`, `/v1/waitlist` nem nas demais rotas `/v1/*`. O cliente guarda a cidade em cache local por 24 h, mostra o ajuste "Localização aproximada" em Ajustes (desligá-lo remove o pino "Você" e nenhuma consulta é feita) e nunca envia a posição a lugar nenhum. A mudança é só código no repositório do site: **publicar o site é uma etapa separada, feita por Luiz**; enquanto não publicado, o cliente trata a ausência como "sem localização" e o mapa mostra só a região medida.
- **Decisão (telemetria):** por escolha de Luiz, o Windows passa a enviar o **mesmo funil** do Firebase do iOS e do Android (Decisões 108 e 109): `game_selected`, `lagcheck_started`, `lagcheck_completed`, `lagcheck_inconclusive`, `lagcheck_cancelled`, `result_viewed` e `retest_started`, com os mesmos parâmetros canônicos (jogo, plataforma, região, tipo de rede, classe do resultado, duração e motivo terminal) definidos em `android/app/src/main/kotlin/com/lagcheck/android/analytics/ProductAnalytics.kt`. Os dados vão para o **mesmo projeto Firebase/GA4 `lagcheck-analytics`** (que já cobre iOS, Android e web), em **mais um stream dedicado ao Windows** (tipo web, para obter ID de medição `G-...`; nome sugerido `lagcheck-windows`), para segmentar o Windows sem poluir os streams existentes. O app só lê o ID e o segredo por configuração de build. Como o SDK do Firebase Analytics não tem versão para JVM/desktop, o envio é pelo **GA4 Measurement Protocol** (HTTPS `POST` a `www.google-analytics.com/mp/collect`), a partir do próprio app, sem passar pelo Worker e sem alterá-lo. `client_id` é um UUID aleatório local da instalação, sem conta, sem `user_id`, sem Advertising ID, sem personalização de anúncios; o IP é visto pelo Google como em qualquer pedido HTTP, como já ocorre no Firebase dos apps móveis. Nunca vão IP, SSID, BSSID, MAC, localização, destino, amostra bruta, nome do PC ou do usuário. Cada medição gera no máximo um evento de desfecho; o início só ocorre quando a medição UDP realmente começa; `result_viewed` só depois da tela aparecer. Windows reporta `platform=pc` junto às demais checagens de PC (sem campo novo de origem; a separação por plataforma é a do stream do GA4).
- **Telemetria: padrão e controle.** Em build empacotado a coleta fica **ligada por padrão**, com aviso curto na primeira abertura, chave "Enviar dados de uso anônimos" em Ajustes (desligar interrompe tudo imediatamente e persiste) e botão para gerar um novo ID de instalação. Builds de desenvolvimento (`gradlew run`, `shots`, testes) **não coletam**. O ID de medição e o segredo da API do GA4 **não ficam no repositório**: entram por propriedade de build ou variável de ambiente e, **sem eles, a telemetria é inerte** (nenhuma chamada). Criar o stream do GA4 e o segredo é ação de Luiz; antes de qualquer distribuição, a política de privacidade e o texto de dados coletados precisam refletir o Windows. Falha, timeout (3 s) ou ausência de rede nunca bloqueia medição, score, resultado nem histórico, e nunca aparece como erro.
- **Limites:** continuam proibidos publicar (inclusive o site), criar release, qualquer mudança no Worker `nolaggy-deep-check`, GPS, telemetria fora desta decisão, anúncio e custo novo. Windows não vira alvo oficial por esta decisão.
- **Critérios de aceite:** `./gradlew :desktop:compileKotlin` e testes do módulo verdes; capturas (`:desktop:shots`) das telas Início, Jogos, Check (com o mapa), Resultado, Histórico e Ajustes; teste do comparador de versão, do filtro de tags/manifesto, de resposta malformada e rede ausente sem travar, de checksum divergente que bloqueia a execução, e de fonte vazia que não chama a rede; Reduzir movimento remove pacotes e pulsos; telemetria: payload canônico por evento, um único desfecho por medição, nenhum evento com a coleta desligada, em build de desenvolvimento ou sem ID/segredo, nenhuma chamada nos testes, exclusão persistente após reiniciar, e ausência de IP/SSID/localização/destino no payload; testes do endpoint do site (cidade e coordenadas arredondadas, ausência de `cf`, sem log nem corpo extra, regressão de `/v1/click` e das demais rotas `/v1/*`); nenhuma chamada fora da lista de hosts; as artes exibidas são as já aprovadas (Decisão 44).

#### Decisão 117

- **Data:** 7 de novembro de 2026.
- **Título:** Design system: mapa por plataforma e divergências abertas entre tokens, iOS, Android e Windows.
- **Status Atual:** **Em avaliação (documental).** Só documenta o que o código faz hoje. Não altera cor, raio, fonte nem navegação de nenhum app.
- **Frentes envolvidas:** Luiz (direção), Priscila (fidelidade visual), Camillo (código) e Renan (conferência).
- **Contexto e problema:** `design-system/tokens/` e `DESIGN.md` eram de 27 de setembro e não cobriam Android nem Windows. Uma comparação com o código em 7 de novembro mostrou cores, espaçamento e raio alinhados no iOS, e divergências nos outros dois.
- **Decisão:** `design-system/tokens/platforms.json`, `design-system/DESIGN.md` (seção Plataformas) e `design-system/components.md` (mapa por plataforma) passam a registrar como cada plataforma implementa os tokens. Em conflito vale, nesta ordem: decisão registrada, `tokens/*.json`, código.
- **Divergências abertas (aguardam decisão do Luiz):** (1) texto terciário `#606873` no Android e no Windows contra `#555E6C` nos tokens e no iOS; (2) Android sem tokens de espaçamento e raio, com 15 raios diferentes e 6 arquivos com cor fixa fora do tema; (3) fonte do Android (Google Sans Flex) sem registro, enquanto o Windows está em `docs/09`; (4) iOS, Android e Windows têm 4 destinos de navegação (Início, Jogos, Histórico, Configurações ou Ajustes), e as Decisões 50 e 51, o `CLAUDE.md` e o `AGENTS.md` falam em 2 abas; (5) cores fixas fora de `NLColor` no iOS.
- **Guardrails:** nenhuma divergência foi corrigida nem aprovada por esta decisão. Alterar valor visual em app exige aprovação e comparação com o protótipo.
- **Critérios de aceite:** `platforms.json` é JSON válido e cada divergência cita o arquivo de origem; os links do `design-system/` e de `docs/` não quebram.

## Como Registrar Novas Decisões

1. Adicione a linha correspondente no [Índice Rápido](#índice-rápido-de-decisões-e-status-de-vigência) marcando o status como `Vigente` (ou indicando se substitui alguma decisão anterior);
2. Adicione uma nova subseção numerada ao final deste documento detalhando:
   * **Título**
   * **Status Atual** (`Vigente`, `Superada por X` ou `Em implementação`)
   * **Frentes envolvidas**
   * **Contexto, Problema e Decisão Tomada**
   * **Critérios de validação e aceite**
3. Nunca crie arquivos separados de decisão.
