# LagCheck — instruções de trabalho

Você está trabalhando no LagCheck, um app para iPhone que ajuda jogadores a entender a qualidade da própria conexão antes de jogar. Trabalhe pela perspectiva de produto antes de pensar em implementação: problema, pessoa afetada, comportamento esperado, limite da promessa e evidência necessária.

## Contexto inegociável

- Marca oficial: **LagCheck**, sempre com `lagcheck` em minúsculas na wordmark. (Decisão 25; substitui a marca preliminar Nolaggy).
- V1: somente iPhone, iOS 17 ou superior. Android está fora do escopo atual.
- O app mede a rota do iPhone até uma infraestrutura de referência. Não promete ping real de um jogo sem evidência. Para console ou PC, comunica resultado como estimativa.
- O score é determinístico, versionado e baseado em medição real. Sem respostas UDP válidas suficientes, o resultado é inconclusivo — nunca uma nota inventada, fallback HTTP/ICMP ou recomendação para jogar.
- Custo operacional recorrente zero é uma restrição de produto. Não adicione serviço pago, SDK ou infraestrutura sem decisão explícita do dono do produto. Exceção já autorizada e em produção: um único Cloudflare Worker gratuito (`nolaggy-deep-check`), servindo `GET /v1/load` (carga do Deep Check) e `GET /v1/catalog.json` (catálogo remoto assinado em Debug) — ver `docs/12` e `docs/14`. Não amplie esse Worker nem crie outro endpoint sem nova decisão.
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

Docs `19` e `20` são conversas exploratórias pedidas por Marco: não implemente nada a partir deles sem decisão explícita registrada, conforme a regra abaixo sobre exploração não ser autorização.

Se documentos conflitarem, pare antes de codar, aponte a contradição e peça uma decisão. Código não substitui uma decisão de produto.

## Time e interação

- **Marco** integra produto, escopo, prioridade e coerência entre as frentes — é o ponto único de integração, não o aprovador final de tudo.
- **Renan** responde por design de produto, design system, acessibilidade, assets e QA visual.
- **Rian** responde por iOS, arquitetura SwiftUI, módulos, persistência, ads e entrega.
- **Iury** responde por qualidade de rede, score, catálogo de regiões, calibração e validação de medições.
- **Dono do produto** (Luiz — ver contexto do workspace) aprova mudanças de escopo, monetização, marca, mercados e promessas ao usuário; publicação, alteração de preço e serviço pago exigem autorização explícita dele, não só de Marco (`docs/05` §2 e §4.1).
- Mudança que atravesse mais de uma frente só começa após alinhamento documentado entre os responsáveis e Marco.

Não altere arquivo de outra frente por conveniência. Proponha a mudança, deixe claro o impacto e obtenha revisão do responsável. Não trate uma conversa exploratória como autorização de implementação.

## Voz do produto

Escreva para a pessoa que quer saber se pode jogar agora: direto, calmo e preciso. Diga o que foi observado, o que pode significar para a partida e o que fazer em seguida.

- Prefira linguagem comum: conexão, rede, medição, partida, região selecionada.
- Use jargão técnico apenas quando ajudar; explique-o se necessário.
- Nunca prometa “zero lag”, “rede perfeita”, “garantido” ou desempenho futuro.
- Não seja alarmista, publicitário, cyberpunk ou caricato de gamer.
- Resultado saudável recebe uma conclusão positiva. Resultado inconclusivo não recebe score nem linguagem positiva.
- Siga `docs/07-voz-do-produto.md` para qualquer copy em PT-BR ou inglês.

## Regras técnicas e de qualidade

- Mantenha domínio, aplicação, infraestrutura, design system, features e composição do app separados conforme `docs/02-arquitetura.md`.
- Regras de score não importam frameworks de UI, rede, persistência ou anúncios.
- Uma única sessão de medição pode estar ativa. Mudança de rede, background, cancelamento ou dados insuficientes descarta o resultado parcial.
- Repouso e carga no Deep Check são leituras diferentes: score principal vem do repouso; impacto sob carga é complementar.
- Catálogo remoto só entra após validar assinatura, schema, validade e regras de negócio. Nenhuma UI interpreta JSON remoto diretamente.
- Toda alteração de score, thresholds, guardrails, spikes ou catálogo exige versão da regra, vetores de teste e revisão de Iury.
- Tokens são a fonte de verdade visual. Não introduza cor, tipografia, espaçamento, raio ou sombra soltos.
- Ativos em `design-system/assets/brand/` e `design-system/assets/app-icon/` são oficiais e aprovados. Não os redesenhe, deforme, recolora ou substitua.
- O protótipo em `design-system/prototypes/ios-reference/` é canônico. Busque paridade 1:1 de hierarquia, composição, estados, ações e comportamento; não o trate como inspiração nem o substitua por uma interface genérica.
- Para paridade de tela, `design-system/prototypes/ios-reference/source/Nolaggy iOS Prototype.dc.html` prevalece sobre PNGs complementares. O board PNG legado com Home divergente foi excluído das referências utilizáveis e não deve ser reintroduzido.
- Divergência do protótipo só é aceita por regra funcional mais específica, precisão/segurança de rede ou acessibilidade iOS. Registre a decisão antes de implementar e preserve o protótipo original em `source/`.
- Gate aberto (`docs/21`): a direção visual mudou para simplicidade/leveza (remove Oxanium, halo/glow, flip 3D, sombras em múltiplos níveis, "card soup") e substitui os princípios de `docs/04-design-system.md` seções 1–2. Renan ainda não entregou a especificação/tokens revisados nem atualizou o protótipo canônico. Não implemente essa direção em código antes dessa entrega — até lá, o protótipo e os tokens atuais continuam valendo como estão.
- Estados que não existem no protótipo (por exemplo: inconclusivo, falha/cancelamento, consentimento, vazio e indisponibilidade de Wi-Fi) exigem composição aprovada por Renan antes de implementação.
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
