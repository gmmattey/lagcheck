# LagCheck — instruções de trabalho

Você está trabalhando no LagCheck, um app para iPhone que ajuda jogadores a entender a qualidade da própria conexão antes de jogar. Trabalhe pela perspectiva de produto antes de pensar em implementação: problema, pessoa afetada, comportamento esperado, limite da promessa e evidência necessária.

## Contexto inegociável

- Marca oficial: **LagCheck**, sempre com `lagcheck` em minúsculas na wordmark. (Decisão 25; substitui a marca preliminar Nolaggy).
- V1: iPhone, iOS 17 ou superior. Android nativo (Kotlin/Compose, API 26+) é alvo oficial desde as Decisões 67 e 68, com paridade de regras com o iOS.
- O app mede a rota do iPhone até uma infraestrutura de referência. Não promete ping real de um jogo sem evidência. Para console ou PC, comunica resultado como estimativa.
- O score é determinístico, versionado e baseado em medição real. Sem respostas UDP válidas suficientes, o resultado é inconclusivo — nunca uma nota inventada, fallback HTTP/ICMP ou recomendação para jogar.
- Custo operacional recorrente zero é uma restrição de produto. Não adicione serviço pago, SDK ou infraestrutura sem decisão explícita do dono do produto. Exceção já autorizada e em produção: um único Cloudflare Worker gratuito (`nolaggy-deep-check`), servindo `GET /v1/load` (carga do Deep Check) e `POST /v1/telemetry` (telemetria de produto anônima e mínima para validação de retenção sem PII/IP). O catálogo é local, sem assinatura, e acompanha os builds iOS/Android (Decisões 94, 99 e 106) — ver `docs/12`, `docs/14`, `docs/50` e `docs/DECISOES.md`. Não amplie esse Worker nem crie outro endpoint sem nova decisão.
- **Windows (Decisões 114, 115 e 116):** existe um protótipo interno em `android/desktop/` (Kotlin + Compose Desktop sobre o `core` do Android). **Windows não é alvo oficial** e cada publicação exige autorização expressa do Luiz (a prévia `windows-v0.1.0` foi publicada em 7 de novembro de 2026, sem assinatura de código). Spec visual: `docs/09-design-system-windows.md` e `design-system/prototypes/windows-premium/`. Telemetria do funil por GA4 Measurement Protocol (stream `lagcheck-windows` do projeto `lagcheck-analytics`), ligada só no build empacotado e inerte sem ID/segredo (que ficam fora do repositório, em `~/.gradle/gradle.properties` ou variáveis de ambiente); atualização por GitHub Releases deste repositório (tags `windows-vX.Y.Z`); localização aproximada pelo IP por um endpoint do `lagcheck-site` (nunca pelo Worker `nolaggy-deep-check`, que não é alterado por esta frente). Rotas do Worker, catálogo e score não mudam por causa do Windows.
- **Repositório público (desde 7 de novembro de 2026):** tudo que entra aqui é visível. Nenhum segredo, token, chave privada, ID de medição com segredo, `.jks`, `.env`, webhook ou dado pessoal; revise `git diff` antes de commitar. As duas chaves de API de cliente do Firebase (`GoogleService-Info.plist` e `android/app/src/release/google-services.json`) continuam versionadas: a pendência é restringi-las por app no Google Cloud (responsabilidade do Luiz), não removê-las do histórico sem pedido explícito.
- Jogos no catálogo usam a arte editorial autoral autorizada pelo catálogo assinado (Decisões 18, 44, 71 e 88) e, sem ela, a miniatura neutra do LagCheck. Nunca capa oficial, logo, personagem ou arte licenciada de terceiros; o nome localizado do jogo é a identificação primária.
- Publicidade (Decisões 82, 96 e 97): iOS e Android usam AdMob Native Advanced em Início, Histórico, Jogos e somente Resultado concluído válido, com consentimento UMP antes de qualquer request. Não há ATT, intersticial ou rewarded sem nova decisão. Check, consentimento de dados móveis, resultado inconclusivo, detalhes e qualquer estado intermediário ficam sem anúncio. Em qualquer plataforma, falha/ausência de anúncio nunca bloqueia nem desloca medição, score, resultado, histórico ou ação essencial. Antes de distribuir, validar em aparelho, revisar a política pública e completar as declarações da loja contra o archive/AAB real (`docs/01` §11).
- **Zero cara de IA e o Gamer Não Lê (Decisão 64):** O app é para jovem gamer competitivo no lobby esperando a partida. Proibido cardlização em excesso, títulos com subtítulos didáticos e textão explicativo. Interface rápida, visual, limpa e esportiva (cockpit de telemetria). Toda informação na tela deve cumprir a "Regra do Discord": ser traduzível para uma frase curta falada entre amigos na call.
- O app suporta PT-BR e inglês desde a V1.
- **Centralização da Landing Page e Presença Web:** O repositório `lagcheck` é estritamente dedicado aos aplicativos nativos (**iOS e Android**). A landing page pública, termos de privacidade e suporte do LagCheck estão centralizados no monorepo em `~/Projetos/web/landings` (`sites/lagcheck/`). **Não recrie pasta `web/` ou scripts de servidor web neste repositório.** Qualquer evolução de páginas públicas, ASO web ou rotas do site deve ser feita exclusivamente em `~/Projetos/web/landings`.
- **Infraestrutura de Release Autocontida:** Chaves de assinatura e certificados de release ficam isolados em `release/keys/` (ignorado no Git). Builds de produção são direcionados para `release/android/` via `scripts/android-release.sh`. A pasta externa `lagcheck-release` foi descontinuada e eliminada.

## Estrutura do Repositório e Estado Real

O repositório é 100% autocontido para desenvolvimento mobile nativo (Apple + Android):

```text
lagcheck/
├── Sources/                   # Código Swift nativo (iOS 17+ / macOS)
├── Nolaggy.xcodeproj          # Projeto Xcode gerado via XcodeGen (project.yml)
├── Tests/                     # Testes unitários e de integração de medição UDP
├── android/                   # App nativo Android (Kotlin + Jetpack Compose, Material 3, API 26+)
│   ├── app/build.gradle.kts   # Configuração Gradle com resolução de assinatura local em release/keys/
│   └── desktop/               # Protótipo interno Windows (Compose Desktop; Decisões 114 a 116), não é alvo oficial
├── release/                   # Infraestrutura de release autocontida (no .gitignore)
│   ├── keys/                  # Chaves de upload Android (lagcheck-upload.jks e .properties)
│   └── android/               # Saída padronizada de bundles AAB e mapeamentos R8
├── worker/                    # Cloudflare Worker 'nolaggy-deep-check' (/v1/load e /v1/telemetry)
├── design-system/             # Dark Competitive UI, tokens de cor, tipografia e assets
├── store/                     # Metadados e criativos para App Store e Google Play
├── scripts/                   # Automações de build e release (ex: android-release.sh)
└── docs/                      # Documentação técnica e funcional (docs/DECISOES.md canônico)
```

## Fontes de verdade

Leia o documento relevante antes de propor ou implementar mudanças:

| Assunto | Fonte |
| --- | --- |
| Problema, jornada, regras de negócio e métricas | `docs/01-funcional.md` |
| Limites de módulos e serviços | `docs/02-arquitetura.md` |
| Contratos, algoritmos e validação técnica | `docs/03-especificacao-tecnica.md` |
| Marca, tokens, componentes e acessibilidade | `docs/04-design-system.md` e `design-system/` |
| Composição e comportamento de interface da V1 | `design-system/prototypes/ios-reference/README.md` e `design-system/prototypes/ios-reference/source/Nolaggy iOS Prototype.dc.html` |
| Papéis, decisões, workflow e gates | `docs/05-governanca-e-fluxo-de-trabalho.md` e `.agents/WORKFLOW.md` |
| Canais, versões e publicação | `docs/06-fluxo-de-release.md` |
| Tom, copy e localização | `docs/07-voz-do-produto.md` |
| Arquitetura, rádio e expansão Android | `docs/08-arquitetura-android.md` |
| Protótipo Windows: visual, telemetria, atualização e empacotamento | `docs/09-design-system-windows.md`, `android/desktop/PACKAGING.md` e `design-system/prototypes/windows-premium/README.md` (Decisões 114 a 116) |
| **Decisões registradas (08 a 63+) e novas deliberações** | **`docs/DECISOES.md` (documento único vivo de decisões)** |

### Regra do Documento Único de Decisões (`docs/DECISOES.md`)

O LagCheck adota um **único documento vivo de decisões**: [`docs/DECISOES.md`](docs/DECISOES.md). 
- **Não crie arquivos isolados para novas decisões.** Cada nova decisão acordada pela squad e aprovada pelo dono do produto (Luiz) deve ser acrescentada cronologicamente ao final de `docs/DECISOES.md` e indexada no topo do arquivo.
- Decisões com ID numérico maior refinam ou substituem decisões anteriores quando houver conflito.
- Os arquivos originais históricos pontuais estão preservados em `docs/archive/decisoes/` para fins de auditoria.
- Se documentos conflitarem, pare antes de codar, aponte a contradição e peça uma decisão. Código não substitui uma decisão de produto.

## Squad Ultra-Enxuta (4 Titulares & Governança Unificada)

Ao iniciar uma sessão ou demanda dentro deste repositório, **Marcelo** atua como braço direito do Luiz na liderança de produto e orquestração da oficina: ouve a dor na língua de negócio/produto, separa exploração de decisão, abre o [Cartão de Missão](.agents/templates/mission-card.md), protege o WIP, aciona Priscila, Camillo e Renan, e dá o aceite final pelas 7 perguntas (`APROVADO`, `APROVADO COM RESSALVAS`, `REPROVADO`, `NÃO VALIDADO`).

Os 4 agentes vivem nativamente em `.codex/agents/*.toml`:

| Agente | Papel | Responsabilidade Principal | Modo |
| :--- | :--- | :--- | :--- |
| **Marcelo** (`marcelo`) | **Líder de Produto, Negócio & Orquestrador da Oficina** | Porta de entrada com o Luiz: entende a dor, define escopo/pistas, abre o Cartão de Missão, orquestra a equipe e emite o aceite final pelas 7 perguntas. | Leitura por padrão |
| **Priscila** (`priscila`) | **Diretora de Experiência, UX/UI & Design System** | Guardiã visual: Design System **Dark Competitive UI**, jornadas, interfaces Apple HIG e Material 3, acessibilidade (WCAG AA/A11y), Dynamic Type e microcópia gamer. | Leitura por padrão |
| **Camillo** (`camillo`) | **Engenheiro Principal Full-Stack & Arquitetura** | Engenharia de ponta a ponta: motor de medição determinístico UDP, rotas, Worker (`nolaggy-deep-check`), contratos e telas nativas em SwiftUI e Kotlin/Compose. | Escrita / Código |
| **Renan** (`renan`) | **Qualidade, QA, Testes & Aparelho Real** | Auditoria técnica e visual independente: caça-bugs implacável, testes automatizados, cenários adversos de rede, ciclo de vida e prova em iPhone/Android real. | Leitura por padrão |

### Ciclo Ágil de 3 Passos (Zero Burocracia & Prova Real)

Para acelerar entregas e eliminar falhas, o processo abandona cartões de missão em disco e burocracia de handoffs:
1. **Passo 1 — Enquadramento Direto (Marcelo):** 1 parágrafo claro na conversa (o que fazer, o que NÃO fazer e critério de sucesso). Sem arquivos descartáveis.
2. **Passo 2 — Construção & Auto-Teste (Camillo + Priscila):** Priscila define o visual 1:1 e Camillo implementa de ponta a ponta. Camillo é obrigado a rodar localmente a build e os testes antes de passar para o Renan.
3. **Passo 3 — Prova de Fogo (Renan):** Renan atua como caça-bugs independente. Roda a suíte de testes (`swift test` / `./gradlew test`), testa cenários adversos e emite o veredito em 1 linha (`✓ APROVADO` com evidência ou `✗ BLOQUEADO`).

Uma entrega por vez (**WIP = 1**). Detalhes operacionais em [`.agents/WORKFLOW.md`](.agents/WORKFLOW.md).

### Suíte Canônica de Skills (7 Procedimentos Essenciais)
1. **`conversar-com-o-luiz`** *(Toda a Squad)*: Padrão de comunicação de amigo pra amigo, resultado primeiro, zero jargão técnico e propostas em 2-3 opções claras.
2. **`matar-cheiro-de-ia`** *(Toda a Squad)*: Filtro obrigatório contra jargões, muletas de IA, corporativês e floreios em textos, copy, commits e PRs.
3. **`marcelo-produto-e-aceite`** *(Marcelo)*: Enquadramento de demandas nas 5 pistas, abertura de missões, proteção de WIP e as 7 perguntas de aceite final.
4. **`priscila-design-system-ux`** *(Priscila)*: Padrões visuais 1:1, Design System **Dark Competitive UI**, tokens semânticos, ergonomia mobile e acessibilidade WCAG AA.
5. **`camillo-engenharia-e-arquitetura`** *(Camillo)*: Separação motor vs UI, diagnóstico determinístico de rede (UDP/STUN/rotas), contratos tipados e telas nativas em SwiftUI e Compose.
6. **`renan-qa-e-prova-real`** *(Renan)*: Metodologia caça-bugs independente, cenários adversos de rede, ciclo de vida e prova em iPhone/Android real.
7. **`loja-e-aso`** *(Marcelo, Priscila, Renan)*: Estratégia de ASO, metadados, screenshots autorais e conformidade com diretrizes das lojas.

### Delegação a agentes externos (Codex e Antigravity)

Quando o Luiz pedir para delegar, o orquestrador divide por especialidade e **continua dono da entrega**: confere compilação, testes e capturas por conta própria antes de dizer que algo está pronto.
- **Brief por agente**, no escopo do pedido: objetivo, leitura obrigatória (`AGENTS.md`, decisão aplicável), **pastas que o agente pode editar e as que são proibidas** (donos disjuntos para rodar em paralelo), contrato público entre as partes (assinaturas), critérios de aceite e formato do relatório final (o que foi verificado e o que não foi).
- **Regras fixas em todo brief:** sem `commit`, sem trocar de branch, sem `push`, sem deploy, sem `winget`/instalação, sem rede fora do que a tarefa autoriza, sem segredo no código. Trabalho de outras pessoas no working tree é preservado.
- **Trabalho paralelo em outro repositório** (por exemplo o do site `gmmattey/sites`): use um `git worktree` em branch própria saindo da `main`, nunca o clone em branch alheia.
- **Gradle e `dotnet` não rodam no sandbox do Codex** (escrevem fora do workspace e precisam de rede): o orquestrador roda `./gradlew :desktop:compileKotlin :desktop:test` e `:desktop:shots` por fora e devolve os erros. Armadilhas recorrentes de Kotlin escrito sem compilador: lambda final indo para o parâmetro errado (use argumento nomeado), `var x` colidindo com `fun setX` (assinatura JVM), smart cast em propriedade de outro módulo, imports de `androidx.compose.animation.*` e `foundation.selection.*`.
- **Antigravity (`agy`)** em modo `--print` não consegue pedir permissão de comando: precisa de `--dangerously-skip-permissions`, que desliga a trava técnica. Por isso use-o com pastas e regras explícitas no brief e confira o `git status` depois.
- Ações que publicam ou alteram conta de terceiros (deploy de Worker ou site, release, repositório, console do Firebase/GA4/Cloudflare, aceite de termos) só com pedido explícito do Luiz. Acesso a console exige que o Luiz esteja logado; nunca digite senha por ele.

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
- O catálogo local acompanha o build, sem assinatura nem validade (Decisão 106), e só entra após validar tamanho, schema e regras de negócio. Nenhuma UI interpreta o JSON diretamente.
- Toda alteração de score, veredito, thresholds, guardrails, spikes ou catálogo exige versão da regra, vetores de teste e revisão de Iury.
- Tokens da **Dark Competitive UI** são a fonte de verdade visual (Decisões 51 e 66): fundo quase preto (`#0B0D10`), superfícies grafite (`#15181E`/`#1E232B`), bordas finas de 1px, números monoespaçados e Roxo Gamer (`#7C3AED`) para ações primárias. Coral Solar (`#FF5A36`) fica reservado a atenção, erro e ações destrutivas. Não introduza cores ou espaçamentos soltos.
- Ativos em `design-system/assets/brand/` e `design-system/assets/app-icon/` são oficiais e aprovados. Não os redesenhe, deforme, recolora ou substitua. O App Icon vigente é o modernizado da Decisão 91.
- **Iniciativa Unificada (Decisões 50 e 51):** O produto adota a jornada direta `Home → Jogo → Check → Veredito` e a interface **Dark Competitive UI**. A navegação tem 4 destinos: `Início`, `Jogos`, `Histórico` e `Ajustes` (`Configurações` no Android), conforme as Decisões 80 e 98, que refinaram as 2 abas originais, o veredicto semântico é a manchete de maior hierarquia, e o score numérico (0–100) fica subordinado a "Entender resultado / Detalhes".
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
- Use `MAJOR.MINOR` para versão de produto e um build numérico sempre crescente, apresentado como `X.Y (build)`, para uploads à Apple.
- Não crie GitHub, repositório, Actions, chaves, certificados, upload, submissão, publicação ou alteração no App Store Connect sem pedido explícito.

## Segurança e disciplina de alteração

- Leia `git status` e preserve trabalho preexistente antes de editar um repositório já iniciado.
- Use alterações pequenas e rastreáveis. Não apague, reverta ou sobrescreva trabalho alheio.
- Não exponha segredos, chaves, tokens, IDs sensíveis ou dados pessoais em código, logs ou documentação.
- Não afirme que algo foi validado, enviado ou publicado sem evidência do ambiente correto.
