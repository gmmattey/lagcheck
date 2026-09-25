# LagCheck — governança e fluxo de trabalho

**Status:** regra operacional do projeto  
**Idioma:** PT-BR  
**Escopo:** V1 para iPhone  
**Documentos relacionados:** [Funcional](./01-funcional.md) · [Arquitetura](./02-arquitetura.md) · [Especificação técnica](./03-especificacao-tecnica.md) · [Sistema de design](./04-design-system.md)

## 1. Objetivo

Esta governança existe para manter o LagCheck simples, confiável e coerente enquanto sai do papel. Ela separa claramente uma conversa exploratória de uma decisão de produto e uma decisão de uma mudança executável.

O objetivo não é criar burocracia. É evitar três erros caros: prometer precisão que a medição não entrega, transformar uma tela em uma solução visual isolada e alterar a fundação técnica sem saber o impacto no resultado para o jogador.

## 2. Time e responsabilidades

| Pessoa | Frente | Responsabilidade principal | Não decide sozinho |
| --- | --- | --- | --- |
| Marco | Produto e integração | Visão, escopo, prioridade, gatekeeper do MVP P0/P1 da iniciativa *Lagcheck Competitive Redesign + Ready Check* | Mudança de marca ou promessa pública sem aprovação do dono do produto |
| Renan | Design de Produto | Design system **Dark Competitive UI**, jornada direta, estados, acessibilidade, assets e QA visual | Regras de veredito/score, escopo funcional ou arquitetura de medição |
| Rian | iOS | Arquitetura SwiftUI, módulos, persistência SwiftData por vereditos/jogos, cliente de telemetria e entrega | Semântica das métricas, calibração de veredito ou alteração de jornada |
| Iury | Qualidade de Rede & Borda | Métricas, `GameReadinessVerdict`, calibração por perfil, integridade diagnóstica e rotas do Cloudflare Worker (`/v1/catalog.json`, `/v1/load`, `/v1/telemetry`) | UI, jornada, aquisição de usuários ou atalhos técnicos fora da medição |
| Dono do produto | Direção de negócio | Validação de hipótese de retenção, mudanças de escopo, monetização, marca e autorização de release | — |

Marco é o ponto único de integração. Nenhuma frente abre trabalho que mude outra fronteira sem registrar a decisão e alinhar com Marco.

## 3. Princípios que não são negociáveis

1. **Honestidade antes de aparência.** O app mede a rota do iPhone até uma infraestrutura de referência; não chama isso de ping real de um jogo sem evidência para tal. Em console ou PC, o resultado é uma estimativa.
2. **Conclusão antes das métricas.** A pessoa vê primeiro se está pronta para jogar e por quê. Os números sustentam a conclusão, não disputam atenção com ela.
3. **Determinismo antes de interpretação.** Score, classe, guardrails, causa e recomendação são calculados por regras versionadas. Não há IA ou regra implícita decidindo o resultado.
4. **Uma mudança, uma dona.** Toda alteração tem uma frente responsável, uma hipótese, critérios de aceite e evidência de validação.
5. **A base não vira monólito.** Domínio, aplicação, infraestrutura, design system, features e composição do app permanecem separados conforme a arquitetura aprovada.
6. **Custo recorrente zero é uma restrição de produto.** Qualquer dependência, serviço ou recurso novo precisa declarar custo presente e futuro antes de entrar no escopo.
7. **iPhone primeiro.** A V1 não inclui iPad ou Android. Decisões que facilitam o futuro são bem-vindas quando não aumentam a complexidade nem atrasam o iPhone. Essa ordem é uma escolha de viabilidade de distribuição (o closed testing do Google Play exige 14 dias com 12 usuários, fricção alta para o tamanho do time), não uma afirmação de que o público iPhone é quem mais sente a dor do produto — detalhe e implicação em [Funcional](./01-funcional.md#1-visão-do-produto).
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
| Jornada, texto de produto, escopo ou monetização | Marco ou Renan | Marco + dono do produto quando alterar negócio | Fluxo, estados e impacto no documento funcional |
| Marca, tokens, componentes compartilhados ou acessibilidade | Renan | Renan + Marco | Especificação visual, contraste e estados afetados |
| Score, perfis, thresholds, spikes, guardrails ou catálogo de regiões | Iury | Iury + Marco | Vetores de teste, versão da regra e linguagem honesta ao usuário |
| Arquitetura, módulos, SDKs, armazenamento, segurança ou integração externa | Rian | Rian + Marco | Impacto técnico, testes e custo operacional |
| Mudança que cruza duas ou mais frentes | Qualquer pessoa | Marco + responsáveis das frentes | Decisão registrada antes do código |
| Publicação, alteração de preço, dados da App Store ou serviço pago | Marco | Dono do produto | Estado real da plataforma e autorização explícita |

## 5. Regras por frente

### 5.1 Design e experiência — Renan

- Nenhuma tela segue para desenvolvimento sem objetivo, fluxo e estados de carregamento, vazio, erro, cancelamento e sucesso necessários.
- A direção **Dark Competitive UI** é a fonte de verdade visual (Decisão 51): fundo quase preto (`#0B0D10`), superfícies grafite, painéis com borda fina de 1px (sem card soup), tipografia pesada, números monoespaçados e Coral Solar (`#FF5A36`) como acento exclusivo de ação primária.
- A wordmark `lagcheck` é a marca oficial. O jogo é o protagonista visual, recebendo artwork autoral amplo em destaque na Home.
- Tokens são a fonte de verdade. Valor de cor, espaço, raio ou tipografia solto na tela exige revisão de design.
- Marca, ícones e artes vêm de arquivo-fonte aprovado e versionado. Não se redesenha, deforma, recolore ou adiciona efeito ad hoc a um asset.
- Todo fluxo cumpre contraste adequado, alvo de toque de pelo menos 44 pt, Dynamic Type, VoiceOver e alternativa que não dependa apenas de cor. O verde (`#22C55E`) é estritamente semântico para condição de prontidão, nunca cor da marca.
- Veredito da partida (`● PRONTO PARA RANKED`, `▲ EU EVITARIA RANKED AGORA`), limitações e impacto sob carga devem ser imediatos e compreensíveis.

### 5.2 iOS e entrega — Rian

- O domínio é puro: `NolaggyDomain` não importa SwiftUI, Network.framework, SwiftData, URLSession ou SDKs de anúncios.
- O modelo de prontidão `GameReadinessVerdict` (`.ready`, `.caution`, `.notReady`, `.inconclusive`) é o contrato semântico principal entregue à UI.
- Há uma única sessão de medição ativa. O `MeasurementSessionCoordinator` é a autoridade para iniciar, cancelar, invalidar e concluir uma sessão.
- Mudança relevante de rede, ida para background, cancelamento explícito ou dados insuficientes encerra a sessão. Resultado parcial não entra no histórico.
- Catálogo remoto só é usado depois de validar assinatura Ed25519, schema, datas e regras de negócio. Tela alguma interpreta JSON remoto diretamente.
- A navegação é simplificada para 2 abas (`Início | Jogos`). Histórico e Ajustes são acessados contextualmente.
- SwiftData guarda o histórico estruturado por jogos e vereditos de prontidão.
- Implementa cliente de telemetria anônima enxuto apontando para `POST /v1/telemetry` no Cloudflare Worker existente.
- Mudança no domínio exige testes determinísticos; integração exige teste de contrato; jornada ou consentimento exige validação manual em iPhone.

### 5.3 Qualidade de rede & Borda — Iury

- A classificação usa apenas dados efetivamente medidos por UDP. Não há fallback de HTTP/ICMP para fabricar um resultado UDP nem inferência inventada de ping de servidor de jogo.
- A região primária só produz veredito com pelo menos 10 respostas UDP válidas. Menos que isso resulta estritamente em **inconclusivo**.
- Regras e perfis de jogo são determinísticos e versionados. Mudança de threshold cria nova versão de regra e preserva compatibilidade do histórico.
- **Integridade Diagnóstica (Decisão 50):** É proibido presumir gateway `.1` em probes locais; tempo de envio na porta 53 sem resposta não é RTT; e RTT/jitter da rota remota (WAN) nunca deve ser repassado ao `WiFiBandEvaluator` para tentar deduzir 2.4 vs 5 GHz.
- O relatório de rede reporta sintomas objetivos no bloco **"O que encontramos"**, sem culpar nós de terceiros sem isolamento comprovado.
- Responsável pelos contratos e schemas do Cloudflare Worker (`/v1/catalog.json`, `/v1/load`, `/v1/telemetry`), mantendo o custo recorrente zero.

## 6. Fluxo de trabalho

```text
Ideia
  → triagem de produto
  → decisão registrada
  → especificação pronta
  → execução isolada
  → revisão entre frentes
  → validação
  → aceite e atualização documental
```

### 6.1 Triagem de produto

Marco recebe a demanda e registra em linguagem simples: problema, pessoa afetada, resultado esperado, restrições e o que explicitamente fica fora. Se for apenas exploração, a conversa para aqui até haver decisão.

### 6.2 Decisão registrada

Antes de iniciar, a frente dona registra a decisão no documento correto:

| Assunto | Fonte de verdade |
| --- | --- |
| Valor, jornada, regras de negócio e métricas visíveis | `docs/01-funcional.md` |
| Limites de módulos, serviços e integração | `docs/02-arquitetura.md` |
| Contratos, algoritmos, endpoints e critérios de validação | `docs/03-especificacao-tecnica.md` |
| Tokens, componentes, brand e comportamento visual | `docs/04-design-system.md`, `design-system/` e `design-system/prototypes/ios-reference/` |
| Regras de colaboração e gates | este documento |

Se uma mudança contradiz um documento anterior, a contradição precisa ser resolvida antes da implementação. Não se “corrige depois no código”.

### 6.3 Definition of Ready

Uma tarefa está pronta para execução quando possui, no mínimo:

- problema e resultado esperado;
- escopo e não-escopo;
- responsável e frentes consultadas;
- referência funcional, técnica ou visual;
- estados de falha relevantes;
- critérios de aceite observáveis;
- plano de validação proporcional ao risco.

### 6.4 Execução e comunicação

Quem executa começa confirmando o entendimento do comportamento esperado, não a solução técnica. Durante o trabalho, atualiza apenas fatos relevantes: descoberta que muda escopo, bloqueio real, decisão necessária e evidência de validação.

Uma frente não altera arquivo de outra por conveniência. Quando for inevitável, a mudança é proposta ao responsável, que revisa a fronteira e aprova a integração.

### 6.5 Revisão cruzada

| Mudança executada | Revisão obrigatória |
| --- | --- |
| Score, métricas, catálogo ou medição | Iury + Rian; Renan revisa linguagem e apresentação quando houver UI |
| Tela, componente ou fluxo | Renan + Rian; Iury participa se explicar um resultado de rede |
| Módulo, persistência, SDK, anúncio ou consentimento | Rian + Marco; Renan revisa se houver impacto visível |
| Escopo, promessa, mercado ou monetização | Marco + dono do produto |

### 6.6 Definition of Done

Uma entrega só está concluída quando:

- o comportamento atende ao critério de aceite;
- os documentos impactados foram atualizados;
- testes e validações aplicáveis foram executados e registrados;
- não há promessa maior que a evidência disponível;
- acessibilidade e localização PT-BR/EN foram revisadas quando houver interface;
- telas e interações de interface foram comparadas ao protótipo iOS canônico, no mesmo viewport;
- o responsável da frente e Marco deram aceite para o tipo de mudança.

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

### 7.4 Antes de comprometer escopo do MVP1.1

1. Período mínimo em produção cumprido e dados agregados de App Store Connect revisados por Marco (sessões, retenção, instalação/desinstalação, avaliações) — ver Funcional §13.1.
2. Decisão registrada sobre o recurso que justifica a assinatura anual do MVP2 (Funcional §14), mesmo que a resposta seja "ainda não sabemos, adiar o MVP2".
3. Decisão registrada sobre se/quando um mecanismo de retorno (notificação, widget ou outro) entra em escopo, e em qual versão.

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
| Abertura de frente | Marco + responsáveis necessários | Escopo, dono, decisão pendente e critérios de aceite |
| Checkpoint de risco | Responsável + Marco | Só ocorre quando houver descoberta que muda decisão, custo ou prazo |
| Revisão de entrega | Responsável + revisores obrigatórios | Evidência, ajustes finais e aceite ou retorno claro |
| Fechamento de marco | Marco + dono do produto | Estado real: pronto, pendente, risco ou próximo passo |

Status deve sempre dizer a verdade: “documentado”, “implementado localmente”, “validado em simulador”, “validado em iPhone físico”, “enviado ao TestFlight” e “publicado” são estados diferentes e não podem ser usados como sinônimos.
