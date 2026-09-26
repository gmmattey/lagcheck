# LagCheck — instruções de trabalho

Você está trabalhando no LagCheck, um app para iPhone que ajuda jogadores a entender a qualidade da própria conexão antes de jogar. Trabalhe pela perspectiva de produto antes de pensar em implementação: problema, pessoa afetada, comportamento esperado, limite da promessa e evidência necessária.

## Contexto inegociável

- Marca oficial: **LagCheck**, sempre com `lagcheck` em minúsculas na wordmark. (Decisão 25; substitui a marca preliminar Nolaggy).
- V1: somente iPhone, iOS 17 ou superior. Android está fora do escopo atual.
- O app mede a rota do iPhone até uma infraestrutura de referência. Não promete ping real de um jogo sem evidência. Para console ou PC, comunica resultado como estimativa.
- O score é determinístico, versionado e baseado em medição real. Sem respostas UDP válidas suficientes, o resultado é inconclusivo — nunca uma nota inventada, fallback HTTP/ICMP ou recomendação para jogar.
- Custo operacional recorrente zero é uma restrição de produto. Não adicione serviço pago, SDK ou infraestrutura sem decisão explícita do dono do produto. Exceção já autorizada e em produção: um único Cloudflare Worker gratuito (`nolaggy-deep-check`), servindo `GET /v1/load` (carga do Deep Check), `GET /v1/catalog.json` (catálogo remoto assinado em Debug) e `POST /v1/telemetry` (telemetria de produto anônima e mínima para validação de retenção sem PII/IP) — ver `docs/12`, `docs/14` e `docs/50`. Não amplie esse Worker nem crie outro endpoint sem nova decisão.
- Jogos no catálogo não exibem capa oficial, logo, personagem ou arte licenciada de terceiros. A identidade visual é uma miniatura neutra do LagCheck; o nome localizado do jogo é a identificação primária (`docs/18`).
- Publicidade não existe no MVP1: nenhum SDK, ID ou espaço reservado de anúncio entra no binário atual. A regra vale para quando o MVP1.1 for autorizado: banner apenas em Home e Histórico; nunca bloqueia medição, score, resultado, histórico ou ação essencial (`docs/01` §11).
- O app suporta PT-BR e inglês desde a V1.

## Fontes de verdade

Leia o documento relevante antes de propor ou implementar mudanças:

| Assunto | Fonte |
| --- | --- |
| Problema, jornada, regras de negócio e métricas | `docs/01-funcional.md` |
| Limites de módulos e serviços | `docs/02-arquitetura.md` |
| Contratos, algoritmos e validação técnica | `docs/03-especificacao-tecnica.md` |
| Marca, tokens, componentes e acessibilidade | `docs/04-design-system.md` e `design-system/` |
| Composição e comportamento de interface da V1 | `design-system/prototypes/ios-reference/README.md` e `design-system/prototypes/ios-reference/source/Nolaggy iOS Prototype.dc.html` |
| Papéis, decisões e gates | `docs/05-governanca-e-fluxo-de-trabalho.md` |
| Canais, versões e publicação | `docs/06-fluxo-de-release.md` |
| Tom, copy e localização | `docs/07-voz-do-produto.md` |

Além dos sete documentos estruturais acima, `docs/08` em diante registra decisões pontuais, em ordem cronológica crescente. Um número maior pode revisar, restringir ou substituir um documento anterior — confira sempre o mais recente antes de agir:

| Doc | Assunto | Status |
| --- | --- | --- |
| `08` | Decisão de iniciar por um piloto vertical de Quick Check (Fortnite · BR · iPhone) | decidido |
| `09` | Contrato de rede do piloto: beacon UDP AWS GameLift `sa-east-1`, janela, timeouts, `genericRegion`/`medium` | decidido |
| `10` | Experiência do piloto Quick Check; anel de score 160pt substitui variante anterior de 216pt | decidido |
| `11` | Detalhes do resultado e Histórico local (snapshot imutável, retenção SwiftData) | decidido |
| `12` | Deep Check do piloto; autoriza o Cloudflare Worker gratuito de `/v1/load` | decidido |
| `13` | Parecer de design para Deep Check, Histórico e Detalhes | decidido |
| `14` (dois documentos: técnico e de design) | Catálogo remoto assinado em Debug (Ed25519, `/v1/catalog.json`), ampliação para oito jogos BR/iPhone | decidido |
| `15` | Contrato de artes licenciadas para capas do catálogo | **substituído pelo `docs/18`** — não adotar |
| `16` | Seleção regional automática BR/EUA (`regional-selection-1`) | decidido; validação em iPhone físico pendente |
| `17` | Navegação e Configurações da V1 (Home ⇄ Configurações ⇄ Histórico) | decidido e implementado |
| `18` | Identidade visual neutra dos jogos (sem capa/logo licenciado) | decidido; substitui `docs/15` |
| `19` | Explorar adotar taxonomia "Modo gamer" do SignallQ | **rascunho exploratório — nenhuma decisão, nenhuma autorização** |
| `20` | Revisão de nome, telas, design system e monetização | **rascunho de auditoria — propõe opções que contrariam regras deste AGENTS.md; nenhuma decisão tomada** |
| `21` | Nova direção visual, simples e leve | decisão de direção tomada; substitui os princípios visuais de `docs/04-design-system.md` (seções 1–2); execução pixel a pixel ainda pendente de Renan |
| `22` | Nova jornada com lista nativa e Quick Check automático em background | decisão aprovada pelo dono do produto; em especificação e implementação pelo time |
| `23` | Dicas de conexão com Gemini após Deep Check (CTA e checklist de otimização) | decisão aprovada para especificação e implementação |
| `24` | Adoção definitiva do Design System Apple Games Editorial Hub (SF Pro nativo, TabView 4 abas, Hero Carousel, Shelf) | decidido e implementado |
| `25` | Adoção da nova marca LagCheck e identidade visual Pulse Gauge Coral Solar | decidido e implementado |
| `26` | Teto de plataformas de console no catálogo Debug (Fortnite, Roblox, Minecraft) | decidido e implementado |
| `27` | Diagnóstico e recomendação de frequência Wi-Fi (2.4 GHz vs 5 GHz) | decidido e em implementação |
| `28` | Servidores de teste globais (AWS GameLift UDP Beacons), submenus por continente e rotas amigáveis | decidido e em implementação |
| `29` | Infraestruturas de medição a custo zero (AWS GameLift, Azure PlayFab QoS e Valve A2S_INFO) | decidido e em implementação |
| `30` | Status operacional de plataformas de console a custo zero (PSN e Xbox Live) | decidido e em implementação |
| `31` | Catálogo editorial com notas oficiais, requisitos de sistema e rede sem alucinação de dados | decidido e em implementação |
| `32` | Diagnóstico de topologia de rede multiplayer a custo zero (tipo de NAT, CGNAT e duplo NAT via STUN RFC 5389) | decidido e em implementação |
| `33` | Internacionalização multi-idiomas (pt-BR, en, es), resolução de mercados e lançamento global | decidido e implementado |
| `34` | Trilha Viva de Medição (`MeasurementLiveTrail`), fluxo de pacotes UDP nos 3 nós e visualização de estresse sob carga | decidido e implementado |
| `35` | Tela de Resultado HIG com Hero Editorial, Atestado da Rota consolidado (`RouteTrailSummaryCard`), Grid 2x2 e unificação definitiva do LagCheck | decidido e implementado |
| `36` | Check Completo em Wi-Fi e rede móvel com consentimento de dados, trilha visual HIG sem ruído e descarte em troca de rede | decidido e em implementação |
| `41` | Separação entre vínculo declarado do equipamento externo e rede observada no iPhone | decidido e em implementação |
| `42` | Home orientada por estado da conexão e ação primária | decidido e em implementação |
| `43` | Jornada única de Deep Check (substitui Quick Check na experiência visível) | decidido e implementado |
| `44` | Identidade visual de capas geradas e artes do catálogo | decidido e implementado |
| `45` | Exceção temporária Gemini Release 1.0.0 | decidido |
| `46` | Reconciliação: Deep Check único e consentimento móvel | decidido e implementado |
| `47` | Progressão visual imersiva com Pulse Gauge Coral Solar durante a medição | decidido e em implementação |
| `48` | Experiência visual de carregamento com IA (Dicas de Otimização) | decidido e em implementação |
| `49` | Medição geral de conexão para jogos (jogo genérico, busca sem resultado e rota regional de referência) | decidido e em implementação |
| `50` | Reposicionamento do MVP — Ready for Ranked (Jornada direta Home → Jogo → Check → Veredito, `GameReadinessVerdict`, integridade diagnóstica, telemetria mínima remota e foco no P0/P1) | decidido e em implementação |
| `51` | Direção Visual Dark Competitive UI e Iniciativa Unificada (“Lagcheck Competitive Redesign + Ready Check”: fundo quase preto, jogo protagonista, painéis de borda fina, telemetria viva compacta e Coral Solar de ação) | decidido e em implementação |
| `52` | Decisão de marca: Dual-Node Vector e Wordmark Kinetic Speed Slant (substitui Pulse Gauge, alinhamento com NoPing benchmark e Dark Competitive UI) | decidido e em implementação |
| `53` | Decisão de tipografia: Arquitetura Híbrida de Performance (NoPing benchmark: display pesado, cockpit monoespaçado e eliminação de rounded) | decidido e implementado |
| `54` | Pílula de telemetria local ao vivo na Home (`LiveNetworkSignalCapsule`), correção do botão duplo de voltar no Histórico e resolução de jogos não listados | decidido e implementado |
| `55` | Especificação de Melhorias em Diagnóstico, Métricas e Integridade de Rede (Grok: probe gateway local, Wi-Fi 2.4/5GHz confiável, bufferbloat multidimensional, qualidade da amostra, hierarquia de causas, spikes recorrentes, recomendações acionáveis e descarte estrito) | decidido e em implementação |
| `56` | Jornada Direta em 1 Toque, Cockpit de Rede ("Dados da Rede") e Otimizações de Setup por Plataforma no Resultado | decidido e implementado |
| `57` | Hero Gauge Pulsante com "Testar Agora", Meus Jogos Favoritos (até 4), Exportação de Relatórios PDF Customizados, Otimização Única de Maior Impacto e Casos de Uso com Ícones | decidido e implementado |
| `58` | Incorporação do Relatório de Pesquisa: Detecção de Pacotes Fora de Ordem (RFC 4737), Modulação `.caution`, Mapeamento de Arquitetura de Servidores (`GameServerArchitecture`) e Recomendações de Peering | decidido e implementado |

Docs `19` e `20` são conversas exploratórias pedidas por Marco: não implemente nada a partir deles sem decisão explícita registrada, conforme a regra abaixo sobre exploração não ser autorização.

Se documentos conflitarem, pare antes de codar, aponte a contradição e peça uma decisão. Código não substitui uma decisão de produto.

## Time e interação

- **Marco** integra produto, escopo, prioridade e coerência entre as frentes — é o ponto único de integração, garantindo que o escopo permaneça estritamente no MVP P0/P1 da iniciativa **“Lagcheck Competitive Redesign + Ready Check”** (Decisões 50 e 51).
- **Renan** responde por design de produto, design system **Dark Competitive UI**, acessibilidade, assets e QA visual (Home com jogo protagonista, telemetria viva com pulso, resultado verdict-first, eliminação de card soup e Coral Solar de ação).
- **Rian** responde por iOS, arquitetura SwiftUI, módulos (`NolaggyDomain`, `NolaggyApplication`, etc.), persistência SwiftData, cliente de telemetria anônima e entrega.
- **Iury** responde por qualidade de rede, vereditos de prontidão (`GameReadinessVerdict`), calibração por perfil, integridade diagnóstica (probes locais, STUN, descarte de falsas acusações à WAN/Wi-Fi) e infraestrutura de borda no Cloudflare Worker (`/v1/catalog.json`, `/v1/load` e `/v1/telemetry`).
- **Dono do produto** (Luiz — ver contexto do workspace) aprova mudanças de escopo, monetização, marca, mercados e promessas ao usuário; publicação, alteração de preço e serviço pago exigem autorização explícita dele, não só de Marco (`docs/05` §2 e §4.1).
- Mudança que atravesse mais de uma frente só começa após alinhamento documentado entre os responsáveis e Marco.

Não altere arquivo de outra frente por conveniência. Proponha a mudança, deixe claro o impacto e obtenha revisão do responsável. Não trate uma conversa exploratória como autorização de implementação.

## Voz do produto

Escreva para a pessoa que quer saber se pode jogar agora: direto, calmo e preciso. Diga o que foi observado, o que pode significar para a partida e o que fazer em seguida.

- Prefira linguagem comum: conexão, rede, medição, partida, região selecionada.
- Use jargão técnico apenas quando ajudar; explique-o se necessário.
- Nunca prometa “zero lag”, “rede perfeita”, “garantido” ou desempenho futuro.
- Não seja alarmista, publicitário, cyberpunk ou caricato de gamer.
- Veredito claro e proporcional: `● PRONTO PARA RANKED`, `▲ EU EVITARIA RANKED AGORA`, `▲ CONDIÇÕES INSTÁVEIS` ou `— INCONCLUSIVO`.
- Siga `docs/07-voz-do-produto.md` para qualquer copy em PT-BR, inglês ou espanhol.

## Regras técnicas e de qualidade

- Mantenha domínio, aplicação, infraestrutura, design system, features e composição do app separados conforme `docs/02-arquitetura.md`.
- Regras de veredito e score não importam frameworks de UI, rede, persistência ou anúncios.
- Uma única sessão de medição pode estar ativa. Mudança de rede, background, cancelamento ou dados insuficientes descarta o resultado parcial.
- Repouso e carga no Check são leituras complementares: o veredito avalia repouso e penaliza degradações sob carga.
- Catálogo remoto só entra após validar assinatura Ed25519, schema, validade e regras de negócio. Nenhuma UI interpreta JSON remoto diretamente.
- Toda alteração de score, veredito, thresholds, guardrails, spikes ou catálogo exige versão da regra, vetores de teste e revisão de Iury.
- Tokens da **Dark Competitive UI** são a fonte de verdade visual (Decisão 51): fundo quase preto (`#0B0D10`), superfícies grafite (`#15181E`/`#1E232B`), bordas finas de 1px, números monoespaçados e Coral Solar (`#FF5A36`) para ações. Não introduza cores ou espaçamentos soltos.
- Ativos em `design-system/assets/brand/` e `design-system/assets/app-icon/` são oficiais e aprovados. Não os redesenhe, deforme, recolora ou substitua.
- **Iniciativa Unificada (Decisões 50 e 51):** O produto adota a jornada direta `Home → Jogo → Check → Veredito` e a interface **Dark Competitive UI**. A tab bar tem 2 abas (`Início | Jogos`), o veredicto semântico é a manchete de maior hierarquia, e o score numérico (0–100) fica subordinado a "Entender resultado / Detalhes".
- **Integridade Diagnóstica:** É terminantemente proibido acusar roteador local ou operadora sem evidência comprovada por probe isolado (Decisão 50).
- Acessibilidade é requisito: contraste, alvo mínimo de 44 pt, Dynamic Type, VoiceOver e alternativa que não dependa apenas de cor.

## Fluxo de uma alteração

1. Confirme o problema, comportamento esperado, escopo e não-escopo.
2. Identifique a fonte de verdade e os responsáveis que precisam revisar.
3. Registre/atualize a decisão no documento correto antes de alterar código, quando a decisão for nova.
4. Implemente de forma isolada, preservando mudanças existentes de outras pessoas.
5. Valide proporcionalmente ao risco: testes puros para domínio, contrato para integração, iPhone físico para rede/ciclo de vida/ads/consentimento, e comparação visual/interativa com o protótipo iOS canônico para UI.
6. Reporte evidência real: documentado, implementado localmente, validado em simulador, validado em iPhone físico, enviado ao TestFlight e publicado são estados distintos.

## Releases e estado externo

- Debug é instalação local via Xcode; não é beta.
- TestFlight é distribuição de um release candidate identificado por versão e build.
- Produção só acontece após autorização explícita, seleção do build correto no App Store Connect e confirmação de disponibilidade.
- Use `MAJOR.MINOR.PATCH` para versão de produto e um build numérico sempre crescente para uploads à Apple.
- Não crie GitHub, repositório, Actions, chaves, certificados, upload, submissão, publicação ou alteração no App Store Connect sem pedido explícito.

## Segurança e disciplina de alteração

- Leia `git status` e preserve trabalho preexistente antes de editar um repositório já iniciado.
- Use alterações pequenas e rastreáveis. Não apague, reverta ou sobrescreva trabalho alheio.
- Não exponha segredos, chaves, tokens, IDs sensíveis ou dados pessoais em código, logs ou documentação.
- Não afirme que algo foi validado, enviado ou publicado sem evidência do ambiente correto.
