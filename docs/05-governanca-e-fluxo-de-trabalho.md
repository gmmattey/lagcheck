# LagCheck — governança e fluxo de trabalho

**Status:** regra operacional do projeto
**Idioma:** PT-BR  
**Escopo:** iPhone e Android oficial (Decisões 67–69); gates de release específicos por plataforma
**Documentos relacionados:** [Funcional](./01-funcional.md) · [Arquitetura](./02-arquitetura.md) · [Especificação técnica](./03-especificacao-tecnica.md) · [Sistema de design](./04-design-system.md)

## 1. Objetivo

Esta governança existe para manter o LagCheck simples, confiável e coerente enquanto sai do papel. Ela separa claramente uma conversa exploratória de uma decisão de produto e uma decisão de uma mudança executável.

O objetivo não é criar burocracia. É evitar três erros caros: prometer precisão que a medição não entrega, transformar uma tela em uma solução visual isolada e alterar a fundação técnica sem saber o impacto no resultado para o jogador.

## 2. Time e responsabilidades

| Pessoa | Frente | Responsabilidade principal | Não decide sozinho |
| --- | --- | --- | --- |
| Giam | Braço Direito do Luiz, Product Owner Operacional e Gate de Qualidade | Porta de entrada com o Luiz: entende a dor, abre o Cartão de Missão, define a pista e o aceite, repassa ao Marco e emite o veredito final pelas 7 perguntas | Negócio, preço, publicação, regra de rede ou dispensa de evidência obrigatória |
| Marco | Capitão da Oficina, Estratégia e Orquestração | Recebe o Cartão de Missão do Giam, organiza a fila e prioridades, protege a mesa limpa, coordena as frentes na pista certa e devolve consolidado ao Giam | Aceite final de produto, mudança de marca ou promessa pública sem aprovação do dono do produto |
| Renan | Design de Produto & Visual QA | Design system **Dark Competitive UI**, jornada direta, estados, acessibilidade, assets e QA visual em iOS/Android | Regras de veredito/score, escopo funcional ou arquitetura de medição |
| Rian | Mobile Application Engineer | Composição e entrega do app em SwiftUI e Kotlin/Compose, ciclo de vida, persistência local e integrações de UI | Semântica das métricas, calibração de veredito ou alteração de jornada |
| Iury | Qualidade de Rede & Borda | Métricas, `GameReadinessVerdict`, calibração por perfil, integridade diagnóstica, paridade de rede iOS/Android e Worker (`/v1/catalog.json`, `/v1/load`, `/v1/telemetry`) | UI, jornada, aquisição de usuários ou atalhos técnicos fora da medição |
| Breno | QA, Reliability & Caça-Bugs | Validação independente, suites de testes, análise estática, regressão e validação em hardware físico iOS/Android | Aprovação de escopo de produto ou dispensa de testes obrigatórios |
| Camillo | Arquitetura Transversal | Principal Engineer Buildea, conduz o Gate Arquitetural Obrigatório em APIs, persistência, contratos, segurança e motor UDP nos dois clientes | Não altera código rotineiro nem decide escopo funcional de produto |
| Nico | Growth & Store Creative | Evidência de loja, ASO, criativos, claims e prontidão de distribuição Apple/Google | Publicar, alterar preço, privacidade, Data safety ou campanhas sem autorização explícita de Luiz |
| Dono do produto | Direção de negócio | Validação de hipótese de retenção, mudanças de escopo, monetização, marca e autorização de release (Luiz) | — |

**Giam** é o braço direito do Luiz na porta de entrada: ouve a necessidade, separa exploração de decisão, abre o enquadramento no Cartão de Missão, repassa ao **Marco** (que coordena a oficina com mesa limpa) e no fim encerra a entrega com o veredito de produto. Nenhuma frente abre trabalho que mude outra fronteira sem registrar a decisão e alinhar prioridade e impacto com Marco e Giam; mudanças sistêmicas acionam o Gate Arquitetural de Camillo.

Este documento é a fonte operacional única da squad. `AGENTS.md` contém as
regras de entrada do repositório e `.agents/WORKFLOW.md` é apenas um mapa
rápido; ambos apontam para cá. Decisões de produto continuam exclusivamente em
`docs/DECISOES.md` e prevalecem quando forem posteriores. Uma contradição é um
bloqueio a ser resolvido, nunca uma licença para escolher a regra conveniente.

## 3. Princípios que não são negociáveis

1. **Honestidade antes de aparência.** O app mede a rota do iPhone até uma infraestrutura de referência; não chama isso de ping real de um jogo sem evidência para tal. Em console ou PC, o resultado é uma estimativa.
2. **Conclusão antes das métricas.** A pessoa vê primeiro se está pronta para jogar e por quê. Os números sustentam a conclusão, não disputam atenção com ela.
3. **Determinismo antes de interpretação.** Score, classe, guardrails, causa e recomendação são calculados por regras versionadas. Não há IA ou regra implícita decidindo o resultado.
4. **Uma mudança, uma dona.** Toda alteração tem uma frente responsável, uma hipótese, critérios de aceite e evidência de validação.
5. **A base não vira monólito.** Domínio, aplicação, infraestrutura, design system, features e composição do app permanecem separados conforme a arquitetura aprovada.
6. **Custo recorrente zero é uma restrição de produto.** Qualquer dependência, serviço ou recurso novo precisa declarar custo presente e futuro antes de entrar no escopo.
7. **iPhone como plataforma inicial; Android oficial.** As Decisões 67–69 autorizam o port nativo Android com paridade determinística e limites registrados em `docs/08-arquitetura-android.md`. iPad continua fora do escopo. O restante deste item registra a justificativa histórica da priorização inicial: Decisões que facilitam o futuro são bem-vindas quando não aumentam a complexidade nem atrasam o iPhone. Essa ordem é uma escolha de viabilidade de distribuição (o closed testing do Google Play exige 14 dias com 12 usuários, fricção alta para o tamanho do time), não uma afirmação de que o público iPhone é quem mais sente a dor do produto — detalhe e implicação em [Funcional](./01-funcional.md#1-visão-do-produto).
8. **V1 é fundação, não validação de negócio.** O MVP1 prioriza qualidade técnica, superfície enxuta e identidade de produto definida. Retenção e monetização são avaliadas depois, com os dados agregados de App Store Connect — nunca o código limpo sozinho — como critério de decidir avançar ao MVP1.1. Ver [Funcional §13.1](./01-funcional.md#131-critério-de-saída-do-mvp1).

## 4. Como uma decisão acontece

Há três níveis de conversa:

| Nível | O que é | Pode virar implementação? | Registro |
| --- | --- | --- | --- |
| Exploração | Ideia, hipótese ou alternativa ainda aberta | Não | Comentário ou nota temporária |
| Decisão | Escolha consciente com impacto conhecido | Ainda não, se faltar especificação | Documento de produto, arquitetura ou design system |
| Execução | Trabalho com escopo, responsável e critério de aceite definidos | Sim | Card/tarefa e alteração rastreável no repositório |

Para uma decisão virar execução, ela precisa responder: qual problema resolve, quem é afetado, qual frente é dona, qual é o limite de escopo, como será validada e qual documento precisa mudar.

### 4.1 Matriz de decisão

| Tipo de mudança | Proposta | Aprovação obrigatória | Evidência mínima |
| --- | --- | --- | --- |
| Jornada, texto de produto ou escopo | Giam, com Marco ou Renan | Giam; Luiz quando alterar negócio | Fluxo, estados e impacto no documento funcional |
| Monetização, marca ou promessa pública | Marco ou Giam | Dono do produto | Fluxo, estados e impacto no documento funcional |
| Tokens, componentes compartilhados ou acessibilidade | Renan | Renan + Giam | Especificação visual, contraste e estados afetados |
| Score, perfis, thresholds, spikes, guardrails ou catálogo de regiões | Iury | Iury + Giam | Vetores de teste, versão da regra e linguagem honesta ao usuário |
| Arquitetura, módulos, SDKs, armazenamento, segurança ou integração externa | Rian | Rian + Giam; Camillo quando sistêmico | Impacto técnico, testes e custo operacional |
| Mudança que cruza duas ou mais frentes | Qualquer pessoa | Marco + Giam + responsáveis das frentes | Decisão registrada antes do código |
| Publicação, alteração de preço, dados da App Store ou serviço pago | Marco | Dono do produto | Estado real da plataforma e autorização explícita |

## 5. Regras por frente

### 5.1 Design e experiência — Renan

- Nenhuma tela segue para desenvolvimento sem objetivo, fluxo e estados de carregamento, vazio, erro, cancelamento e sucesso necessários.
- A direção **Dark Competitive UI** é a fonte de verdade visual (Decisão 51): fundo quase preto (`#0B0D10`), superfícies grafite, painéis com borda fina de 1px (sem card soup), tipografia pesada, números monoespaçados e Roxo Gamer (`#7C3AED`) para ação primária; Coral Solar (`#FF5A36`) é reservado para atenção, erro e ações destrutivas (Decisão 66, que refina a 51).
- A wordmark `lagcheck` é a marca oficial. O jogo é o protagonista visual, recebendo artwork autoral amplo em destaque na Home.
- Tokens são a fonte de verdade. Valor de cor, espaço, raio ou tipografia solto na tela exige revisão de design.
- Marca, ícones e artes vêm de arquivo-fonte aprovado e versionado. Não se redesenha, deforma, recolore ou adiciona efeito ad hoc a um asset.
- Todo fluxo cumpre contraste adequado, alvo de toque de pelo menos 44 pt, Dynamic Type, VoiceOver e alternativa que não dependa apenas de cor. O verde (`#22C55E`) é estritamente semântico para condição de prontidão, nunca cor da marca.
- Veredito da partida (`● PRONTO PARA RANKED`, `▲ EU EVITARIA RANKED AGORA`), limitações e impacto sob carga devem ser imediatos e compreensíveis.

### 5.2 Entrega mobile — Rian

- O domínio é puro: `NolaggyDomain` não importa SwiftUI, Network.framework, SwiftData, URLSession ou SDKs de anúncios.
- O modelo de prontidão `GameReadinessVerdict` (`.ready`, `.caution`, `.notReady`, `.inconclusive`) é o contrato semântico principal entregue à UI.
- Há uma única sessão de medição ativa. O `MeasurementSessionCoordinator` é a autoridade para iniciar, cancelar, invalidar e concluir uma sessão.
- Mudança relevante de rede, ida para background, cancelamento explícito ou dados insuficientes encerra a sessão. Resultado parcial não entra no histórico.
- Catálogo remoto só é usado depois de validar assinatura Ed25519, schema, datas e regras de negócio. Tela alguma interpreta JSON remoto diretamente.
- A navegação é simplificada para 2 abas (`Início | Jogos`). Histórico e Ajustes são acessados contextualmente.
- SwiftData guarda o histórico estruturado por jogos e vereditos de prontidão.
- Implementa cliente de telemetria anônima enxuto apontando para `POST /v1/telemetry` no Cloudflare Worker existente.
- Mudança no domínio exige testes determinísticos; integração exige teste de contrato; jornada ou consentimento exige validação manual em iPhone.
- No Android, `:app` compõe a interface e `:core:designsystem` fornece os
  componentes Compose; domínio, catálogo, rede e sessão permanecem módulos JVM
  sem UI. Permissão de rádio opcional ausente não bloqueia Check nem vira fato
  diagnóstico.
- Toda mudança mobile declara seu efeito em iOS e Android. Um comportamento
  específico de plataforma é aceitável apenas quando está explícito no Cartão
  de Missão e preserva a mesma promessa de produto.

### 5.3 Qualidade de rede & Borda — Iury

- A classificação usa apenas dados efetivamente medidos por UDP. Não há fallback de HTTP/ICMP para fabricar um resultado UDP nem inferência inventada de ping de servidor de jogo.
- A região primária só produz veredito com pelo menos 10 respostas UDP válidas. Menos que isso resulta estritamente em **inconclusivo**.
- Regras e perfis de jogo são determinísticos e versionados. Mudança de threshold cria nova versão de regra e preserva compatibilidade do histórico.
- **Integridade Diagnóstica (Decisão 50):** É proibido presumir gateway `.1` em probes locais; tempo de envio na porta 53 sem resposta não é RTT; e RTT/jitter da rota remota (WAN) nunca deve ser repassado ao `WiFiBandEvaluator` para tentar deduzir 2.4 vs 5 GHz.
- O relatório de rede reporta sintomas objetivos no bloco **"O que encontramos"**, sem culpar nós de terceiros sem isolamento comprovado.
- Responsável pelos contratos e schemas do Cloudflare Worker (`/v1/catalog.json`, `/v1/load`, `/v1/telemetry`), mantendo o custo recorrente zero.

### 5.4 QA & Confiabilidade — Breno (em conjunto com Renan em UI)

- Breno atua com independência do desenvolvedor que codificou a solução.
- Tenta provar falhas na implementação antes de liberar qualquer entrega.
- Valida proporcionalmente: testes de unidade/contrato, análise estática, build
  limpo, regressão e validação em hardware físico iOS e Android quando o fluxo
  depende de rede, permissões, ciclo de vida, compartilhamento ou rádio.
- Testa cenários adversos de rede: perda de pacotes, oscilação de jitter, descarte por background, cancelamento gracioso e inexistência de vazamento de memória.
- Breno não escreve o código do fix que está revisando, preservando a imparcialidade do QA.
- O relatório separa inspeção estática, testes, simulador/emulador e aparelho
  físico. O resultado é sempre `aprovado`, `aprovado com ressalvas` ou
  `reprovado`, com o bloqueio e a prova nomeados.

### 5.5 Arquitetura Transversal — Camillo

- Camillo não executa tarefas rotineiras de desenvolvimento do LagCheck; atua como arquiteto sênior transversal da Buildea.
- Conduz o **Gate Arquitetural Obrigatório** sempre que houver:
  1. Alteração de contratos ou rotas do Cloudflare Worker (`/v1/*`);
  2. Modificação ou criação de APIs e protocolos de rede;
  3. Mudanças na persistência SwiftData, DataStore/armazenamento Android com impacto estrutural ou migração de schema;
  4. Alteração de responsabilidade ou contratos entre módulos (`NolaggyDomain`, `:core:domain`, `:core:session`, etc.);
  5. Mudança estrutural no motor central de medição UDP;
  6. Integração cross-repo ou requisitos de segurança/privacidade com impacto sistêmico.
- Elabora ou revisa o `.agents/architecture-plan.md` antes do início da implementação técnica.

### 5.6 Growth e loja — Nico

- Nico entra quando a missão toca descoberta, ficha de loja, criativos,
  conversão, distribuição ou evidência de lançamento; não é um passo obrigatório
  em ajustes internos sem efeito na loja.
- Antes de uma submissão Apple/Google, prepara o pacote que confronta build,
  claims, screenshots/criativos, privacidade, Data safety, consentimento e
  anúncios com a evidência disponível. Material local preparado não é estado de
  console, beta ou produção.
- Não publica, sobe build, altera preço, dados legais ou campanha sem ordem
  explícita do Luiz. Marco integra a conclusão quando a proposta muda promessa,
  escopo, monetização ou prioridade.

### 5.7 Product Owner operacional e gate de produto — Giam

- Giam abre e encerra todo full flow, mudança sistêmica e candidato a release.
  Em fast lane, enquadra e encerra proporcionalmente; em hot lane, revisa
  depois que o fluxo crítico estiver estabilizado.
- Ele abre ou aprova o Cartão de Missão, define comportamento observável e
  critérios de aceite, e consome a evidência de Renan, Rian, Iury, Breno e
  Camillo contra sete perguntas: necessidade, valor, coerência, experiência,
  funcionamento E2E, qualidade e simplicidade.
- Seu parecer é `APROVADO`, `APROVADO COM RESSALVAS`, `REPROVADO` ou `NÃO
  VALIDADO`. Falta de prova vira `NÃO VALIDADO`, nunca aprovação por confiança.
- Marco mantém estratégia, prioridade, trade-offs e o escalonamento ao Luiz;
  Luiz mantém negócio, marca, monetização, release externo e publicação. Giam
  não substitui QA, arquitetura ou revisão de rede.

## 6. Fluxo de trabalho e Pistas de Execução (Lanes)

Em conformidade com a Decisão 63 e [`.agents/WORKFLOW.md`](../.agents/WORKFLOW.md), o LagCheck opera com 5 modalidades de fluxo:

### 6.1 Exploração
Discussão de ideias, análises de viabilidade ou propostas de negócio com o Luiz. Marco conduz, analisa produto e impacto. **Nenhum código é alterado.**

### 6.2 Fast lane (Mudanças locais e cosméticas)
Para copy, micro-ajuste visual de componente, bug isolado ou refatoração simples sem alteração de contrato:
```text
Giam enquadra proporcionalmente → Rian / Iury / Renan implementa → Renan/Breno valida → Giam encerra
```

### 6.3 Full flow comum (Features regulares)
Para novas features ou ajustes contidos em módulos existentes:
```text
Giam define comportamento e aceite → Renan desenha UI → Rian / Iury implementa → Breno valida → Giam emite veredito interno
```

### 6.4 Full flow sistêmica (Gate de Camillo)
Para mudanças que tocam APIs, persistência, Worker, motor central ou contratos:
```text
Giam define problema e aceite → Camillo cria Architecture Plan → Rian / Iury implementa → Breno valida → Camillo confere aderência → Giam emite veredito interno
```

### 6.5 Hot lane (Incidentes críticos)
Para build quebrado ou medição inoperante:
```text
Fix cirúrgico por Rian/Iury → Breno valida caminho crítico → Restaurar build/release → Giam revisa após estabilização
```

### 6.6 Fontes de verdade e Documento Único de Decisões

| Assunto | Fonte de verdade |
| --- | --- |
| Valor, jornada, regras de negócio e métricas visíveis | `docs/01-funcional.md` |
| Limites de módulos, serviços e integração | `docs/02-arquitetura.md` |
| Contratos, algoritmos, endpoints e critérios de validação | `docs/03-especificacao-tecnica.md` |
| Tokens, componentes, brand e comportamento visual | `docs/04-design-system.md`, `design-system/` e `design-system/prototypes/ios-reference/` |
| Regras de colaboração, workflow e gates | este documento e `.agents/WORKFLOW.md` |
| **Decisões registradas (08 a 63+) e novas deliberações** | **`docs/DECISOES.md` (documento único vivo de decisões)** |

> **Regra do Documento Único:** Todas as decisões pontuais e históricas do produto vivem unificadas em [`docs/DECISOES.md`](DECISOES.md). Novas decisões são adicionadas cronologicamente ao final desse arquivo, sem fragmentação em arquivos isolados. Arquivos históricos individuais originais estão arquivados em `docs/archive/decisoes/`.

Se uma mudança contradiz um documento anterior, a contradição precisa ser resolvida antes da implementação. Não se “corrige depois no código”.

### 6.7 Definition of Ready

Uma tarefa está pronta para execução quando possui, no mínimo:

- problema e resultado esperado;
- escopo e não-escopo;
- responsável e frentes consultadas;
- referência funcional, técnica ou visual;
- estados de falha relevantes;
- critérios de aceite observáveis;
- plano de validação proporcional ao risco.

O registro mínimo é `.agents/templates/mission-card.md`. Sem Cartão de Missão
preenchido, a demanda permanece em exploração; a exceção é Hot lane, que deve
registrá-lo logo após estabilizar o fluxo crítico.

### 6.8 Execução e comunicação

Quem executa começa confirmando o entendimento do comportamento esperado, não a solução técnica. Durante o trabalho, atualiza apenas fatos relevantes: descoberta que muda escopo, bloqueio real, decisão necessária e evidência de validação.

Uma frente não altera arquivo de outra por conveniência. Quando for inevitável, a mudança é proposta ao responsável, que revisa a fronteira e aprova a integração.

### 6.9 Revisão cruzada

| Mudança executada | Revisão obrigatória |
| --- | --- |
| Score, métricas, catálogo ou medição | Iury + Rian; Renan revisa linguagem e apresentação quando houver UI; Breno valida vetores e ambiente aplicável |
| Tela, componente ou fluxo | Renan + Rian; Iury participa se explicar um resultado de rede; Breno verifica o caminho afetado |
| Módulo, persistência, SDK, anúncio ou consentimento | Rian + Giam + Camillo quando sistêmico; Renan revisa se houver impacto visível |
| Widget multiplataforma, cache de arte ou toque que inicia Check | Giam + Camillo + Rian + Renan + Iury + Breno; exige Cartão de Missão, Architecture Plan e prova separada em iOS/Android |
| Escopo ou promessa | Giam + Marco; Luiz quando alterar negócio |
| Mercado ou monetização | Marco + dono do produto |

### 6.10 Definition of Done

Uma entrega só está concluída quando:

- o comportamento atende ao critério de aceite;
- os documentos impactados foram atualizados;
- testes e validações aplicáveis foram executados e registrados;
- não há promessa maior que a evidência disponível;
- acessibilidade e localização PT-BR/EN foram revisadas quando houver interface;
- telas e interações de interface foram comparadas ao protótipo iOS canônico, no mesmo viewport;
- o responsável da frente e Giam deram aceite operacional para o tipo de mudança.
- o Cartão de Missão foi encerrado com a evidência que sustenta cada critério,
  pendências remanescentes e um veredito inequívoco.

## 7. Gates obrigatórios antes de marcos importantes

### 7.1 Antes do primeiro código de medição

1. Fórmula completa de estabilidade/consistência aprovada.
2. Faixas numéricas e interpolação de score sem ambiguidade.
3. Deep Check definido: score de repouso permanece principal; carga é impacto complementar.
4. Janela de coleta e período de fechamento definidos.
5. Mapa jogo → região baseado em evidência e comunicado como estimativa quando necessário.
6. Validação do protocolo real de UDP Ping Beacon em iPhone físico.

### 7.2 Antes de uma tela entrar no app

1. Composição e todos os estados funcionais aprovados.
2. Tokens e componente reutilizável definidos ou já existentes.
3. Copy PT-BR e inglês revisada, incluindo inconclusivo e falhas.
4. Critérios mínimos de acessibilidade definidos.

### 7.3 Antes de TestFlight

1. Deep Check único validado em iPhone real em Wi-Fi e celular, incluindo aceite e recusa de consentimento móvel.
2. Cancelamento por troca de rede, background e interrupção verificado.
3. Deep Check validado em Wi-Fi com carga concluída, falha e dados insuficientes.
4. Catálogo assinado, cache e fallback testados.
5. Consentimento e banner validados sem bloquear o fluxo principal.
6. Fluxos PT-BR/EN, Dynamic Type e VoiceOver revisados.

### 7.4 Priorização de evolução após o MVP1

1. Dados agregados de App Store Connect e telemetria mínima podem orientar prioridade, sem se tornarem gate de escopo — ver Funcional §13.1 e Decisão 85.
2. Uma decisão registrada continua obrigatória para o recurso que justifica assinatura anual do MVP2, ou para declarar que ele permanece adiado.
3. Notificação, widget ou outro mecanismo de retorno entram por decisão registrada, Cartão de Missão e evidência proporcional; não dependem de período mínimo em produção.

## 8. Mudanças de escopo e resolução de conflito

Quando duas frentes discordarem, não vale o argumento mais técnico nem o layout mais bonito. A decisão é tomada nesta ordem:

1. proteção da verdade do resultado para o jogador;
2. clareza da experiência;
3. segurança e manutenção do app;
4. custo recorrente zero;
5. velocidade de entrega.

Marco consolida as alternativas, impactos e recomendação. Se a escolha mudar promessa de negócio, monetização, marca, mercado ou data, o dono do produto decide explicitamente.

Mudança emergencial pode pular o rito normal somente para impedir resultado incorreto, exposição de dados, quebra de medição ou bloqueio do uso essencial. Mesmo nesse caso, a decisão, o impacto e o plano de correção documental devem ser registrados em seguida.

## 9. Ritmo de trabalho

O projeto opera em ciclos curtos, guiados por marcos e não por cerimônias vazias:

| Momento | Participantes | Resultado |
| --- | --- | --- |
| Abertura de frente | Giam + responsáveis necessários; Marco quando houver prioridade ou trade-off | Escopo, dono, decisão pendente e critérios de aceite |
| Checkpoint de risco | Responsável + Marco + Giam quando mudar aceite | Só ocorre quando houver descoberta que muda decisão, custo ou prazo |
| Revisão de entrega | Giam + responsável + revisores obrigatórios | Evidência, ajustes finais e veredito ou retorno claro |
| Fechamento de marco | Marco + dono do produto | Estado real: pronto, pendente, risco ou próximo passo |

Status deve sempre dizer a verdade: “documentado”, “implementado localmente”, “validado em simulador”, “validado em iPhone físico”, “enviado ao TestFlight” e “publicado” são estados diferentes e não podem ser usados como sinônimos.
