# LagCheck — documentação funcional

**Status:** rascunho inicial para V1  
**Idioma do documento:** PT-BR  
**Sistema mínimo:** iOS 17  
**Base:** conversa de concepção do produto compartilhada pela equipe em 7 de setembro de 2026

> **Decisão de plataforma:** o LagCheck nasce para iPhone. Uma versão Android está planejada para o futuro, mas não integra o escopo, a data ou a promessa de paridade da V1.
>
> **Motivo registrado (2026-09-10):** a escolha é de viabilidade de distribuição, não de validação de público-alvo. Testar no Android exige closed testing de 14 dias com 12 usuários antes de qualquer disponibilização mais ampla — fricção desproporcional para um time pequeno validando um conceito. A App Store permite lançar e iterar de forma mais direta. **Isso não significa que o público iPhone BR/US seja quem mais sente a dor que o LagCheck resolve** — jogadores em Android, dados móveis limitados e Wi-Fi doméstico compartilhado provavelmente têm mais incerteza sobre a própria conexão do que o público iPhone típico desses dois mercados. A equipe aceita conscientemente que a V1 valida o conceito e a qualidade técnica nesse subconjunto, não a tese completa de mercado do produto. Quando o Android entrar em escopo, os aprendizados de retenção e comportamento da V1 devem ser tratados como indicativos, não como prova de que funcionam para o público de maior necessidade.

## 1. Visão do produto

LagCheck responde, de forma simples e honesta, a uma pergunta que jogadores fazem antes de entrar em uma partida: **"minha conexão está boa para jogar isso agora?"**

O aplicativo mede a qualidade da rota de rede do dispositivo até regiões de infraestrutura gamer relevantes para o jogo selecionado. Em vez de apresentar um painel técnico de banda larga, transforma a medição em uma conclusão imediata, o **LagCheck Score**, explica qualquer risco de lag e permite investigar quando necessário.

LagCheck não promete otimizar rota, acelerar a conexão, substituir uma VPN gamer ou medir o ping exato de um jogo quando não houver um destino oficial que permita isso.

## 2. Problema que resolve

Jogadores normalmente descobrem uma conexão ruim no meio da partida. Aplicativos de speed test privilegiam download e upload, métricas que não explicam sozinhas responsividade, picos de latência, instabilidade ou perda de pacotes em jogos.

LagCheck reduz essa incerteza antes da partida. Ele avalia latência, estabilidade e perda para uma região gamer compatível com o jogo, comunica o grau de confiança da estimativa e indica o próximo passo quando a qualidade não for suficiente.

## 3. Público e contexto de uso

O público primário da V1 são pessoas que usam iPhone, especialmente para títulos mobile competitivos e populares. Elas querem uma resposta rápida, sem precisar entender jargão de rede. A V1 estabelece a experiência e as regras de produto que uma futura versão Android deverá avaliar e adaptar às capacidades da plataforma, sem assumir implementação idêntica.

O produto também atende quem joga em PlayStation, Xbox, PC ou Nintendo, desde que trate o resultado como estimativa quando o aparelho testado não for o mesmo que joga. A qualidade da rota de internet pode ser representativa; a conexão local do console ou computador pode não ser.

## 4. Proposta de valor

Em menos de 30 segundos desde abrir o app, uma pessoa deve conseguir:

1. Escolher um jogo e a plataforma em que joga.
2. Rodar um **Quick Check** de aproximadamente 15 segundos.
3. Entender se está pronta para jogar, qual o risco de lag e por quê.
4. Iniciar um **Deep Check** se precisar de um diagnóstico mais completo.

O princípio de interface é: **a conclusão vem antes das métricas**. Os detalhes existem para quem quiser aprofundar, sem bloquear a decisão principal.

## 5. Escopo da V1

A V1 inclui:

- iOS: iPhone;
- oito jogos populares no catálogo inicial: Fortnite, Call of Duty Mobile, Free Fire, PUBG Mobile, Brawl Stars, Roblox, Minecraft e Wild Rift;
- escolha de plataforma: iPhone, PlayStation, Xbox, PC e Nintendo;
- Quick Check;
- Deep Check;
- LagCheck Score determinístico;
- identificação de causa de lag e recomendação prática;
- detecção de picos de latência;
- comparação entre regiões gamer;
- histórico salvo apenas no dispositivo;
- catálogo remoto de jogos, perfis e regiões;
- interface em PT-BR e inglês. A monetização por anúncios fica explicitamente fora do MVP1 e entra no MVP1.1.

O aplicativo pode ser disponibilizado globalmente na App Store, mas o catálogo com suporte oficial da V1 cobre inicialmente **Brasil e Estados Unidos**. Fora desses mercados, o app não deve prometer disponibilidade de jogo, região ou calibração até que o catálogo inclua o contexto correspondente.

O catálogo é **mobile-first, não mobile-only**. Jogos multiplataforma podem oferecer escolha de PlayStation, Xbox, PC ou Nintendo já na V1. Nesses contextos, o resultado é comunicado como estimativa da rota de internet quando o iPhone não é o aparelho que joga.

Ficam explicitamente fora da V1:

- aplicativo Android; a plataforma é uma evolução planejada, sem prazo definido nesta fase;
- criação obrigatória de conta;
- VPN ou alteração/otimização de rota;
- servidor próprio de speed test;
- promessa de ping exato para jogos sem medição oficial;
- diagnóstico baseado em LLM;
- sincronização em nuvem obrigatória do histórico.

## 6. Conceitos funcionais

| Conceito | Definição para o usuário |
| --- | --- |
| LagCheck Score | Nota resumida da qualidade da conexão para o contexto selecionado. |
| Quick Check | Checagem curta para decidir se vale jogar agora. |
| Deep Check | Investigação mais completa de estabilidade e comportamento sob carga. |
| Região gamer | Região de infraestrutura usada como referência para avaliar a rota. Não é necessariamente o servidor do jogo. |
| Confiança | Grau de proximidade entre a medição e a experiência real esperada no jogo. |
| Spike | Pico pontual de latência que pode causar travadas, atraso ou teleporte no jogo. |

## 7. Jornada principal

```text
Abrir app → escolher jogo → informar plataforma → Quick Check → resultado
                                                        ├→ testar de novo
                                                        ├→ ver detalhes
                                                        └→ Deep Check, se houver risco ou curiosidade
```

Não haverá onboarding longo antes do primeiro teste. Permissões e perguntas aparecem apenas quando forem necessárias para executar ou qualificar a medição.

### 7.1 Home

Objetivo: levar o usuário rapidamente a um jogo e a uma nova medição.

Conteúdo e comportamento, nesta ordem:

1. **Última medição**, quando houver: jogo, último score e atalho para retestar o mesmo contexto. O jogo não é hardcoded; o texto usa o título localizado vindo do catálogo.
2. **Escolha de jogo**: busca sob demanda, categorias e vitrine horizontal para trocar de partida.
3. **Pronto para medir**: jogo selecionado, plataforma, região de referência e ação para iniciar a jornada de Quick Check.

O Histórico completo permanece em Configurações. A Home oferece continuidade para quem volta ao mesmo jogo e descoberta para quem quer jogar outra coisa.

A Home não é um dashboard de rede e não mostra download, upload ou uma grade de métricas técnicas como foco principal.

### 7.2 Seleção do jogo e do contexto

Ao selecionar um jogo, o usuário escolhe onde joga: iPhone, PlayStation, Xbox, PC ou Nintendo.

O catálogo determina quais plataformas aparecem para cada jogo; o app não oferece uma plataforma que não esteja configurada como compatível. Isso permite suporte a consoles e PC sem fazer alegações de precisão indevidas para todo o catálogo.

Para console ou computador, quando influenciar a interpretação do resultado, o app pergunta de forma curta como o equipamento está conectado: Wi-Fi ou Ethernet.

- Se o jogo ocorre no próprio iPhone, a medição tem a maior representatividade possível: mesmo dispositivo, interface e conexão.
- Se o console/PC usa Wi-Fi, a estimativa é mais próxima da experiência real.
- Se usa Ethernet, o app informa que a rota de internet tem alta confiança, mas que a conexão local é estimada.

O usuário pode iniciar o Quick Check com uma única ação depois dessas escolhas.

### 7.3 Quick Check

Objetivo: entregar uma resposta confiável e rápida, em aproximadamente 15 segundos.

Durante o teste, a tela mostra:

- jogo e região em avaliação;
- latência atual;
- gráfico vivo simples da latência;
- perda de pacotes e quantidade de spikes até o momento;
- estados de progresso, por exemplo: "Medindo latência", "Verificando estabilidade" e "Procurando picos de lag".

O gráfico é parte da explicação: um pico relevante deve ser visualmente percebido enquanto acontece. Não haverá velocímetro nem excesso de indicadores.

Se a conexão de rede mudar durante o teste, por exemplo de Wi-Fi para rede celular, o teste é cancelado. O app explica que a conexão mudou durante a medição e oferece reinício. Resultados de caminhos de rede diferentes nunca são misturados.

### 7.4 Resultado do Quick Check

O resultado começa sempre pela decisão, seguido das métricas e da explicação.

Exemplo de resultado saudável:

> **92 — Excelente**  
> Pronto para jogar.

Em seguida, o app mostra jogo, plataforma, região de referência, ping, jitter, perda e spikes. Uma explicação curta traduz o achado, como: "Sua conexão parece responsiva e estável para jogar Fortnite. Encontramos um pequeno pico que não deve ser perceptível na partida."

Exemplo de resultado com risco:

> **58 — Risco de lag**  
> A perda de pacotes pode prejudicar sua partida.

As ações disponíveis são:

- **Testar novamente**;
- **Ver detalhes**;
- **Fazer Deep Check**, prioritário quando houver indício relevante de problema.

### 7.5 Deep Check

Objetivo: explicar a origem provável da instabilidade quando o Quick Check não for suficiente.

O Deep Check ocorre em duas fases:

1. **Em repouso (15 s):** acompanha a latência e a estabilidade para a região gamer.
2. **Sob carga controlada (15 s):** simula uma pequena transferência enquanto continua observando a latência.

O Deep Check dura aproximadamente 30 segundos no total. Cada fase realiza até dois probes UDP por segundo; a comparação só usa as distribuições separadas de cada fase.

O Deep Check só fica disponível em Wi-Fi na V1, pois a fase sob carga transfere dados. Ela dura até 15 segundos e transfere no máximo 10 MB. Em 4G/5G, o app mantém o Quick Check disponível e informa que a investigação sob carga requer Wi-Fi.

O resultado compara a condição em repouso com a condição sob carga. Por exemplo, uma latência que salta de 26 ms para 93 ms permite explicar: "Sua conexão fica instável quando está ocupada. Downloads ou streaming na rede podem causar lag."

Além da conclusão, o Deep Check pode apresentar melhor região disponível, detalhes de estabilidade, causa provável e recomendação acionável.

### 7.6 Detalhes da conexão

Esta área atende pessoas que querem evidência técnica sem poluir o resultado principal. Pode mostrar:

- série temporal da latência;
- latência mediana (P50), P95 e P99;
- jitter;
- perda de pacotes;
- quantidade e pior spike;
- região e tipo de destino usado na medição;
- confiança da estimativa;
- comparação entre latência em repouso e sob carga, quando houver Deep Check.

### 7.7 Histórico

O histórico é local e organizado por experiência de jogo, não como uma lista genérica de speed tests. Cada jogo mantém no máximo 100 medições e resultados com mais de 90 dias são removidos automaticamente. A pessoa pode apagar todo o histórico nas configurações.

Para cada jogo, o usuário vê o último score, evolução recente e, após dados suficientes, média de sete dias. A visualização permite perceber pioras ou melhoras e iniciar uma nova checagem do mesmo jogo.

### 7.8 Navegação e configurações

O controle no topo da Home e do Histórico abre Configurações como uma tela própria, nunca uma gaveta lateral. Configurações usa a lista agrupada nativa do iPhone, sobre o fundo visual do LagCheck, e concentra o acesso ao Histórico. O Histórico não abre como modal. Nas telas de jornada, a wordmark permanece centralizada e os controles de navegação ocupam a mesma altura.

Configurações mostra o idioma do sistema, permite apagar o histórico local mediante confirmação, identifica a versão instalada e oferece Suporte e Política de privacidade. Os endereços de suporte e privacidade são configurados por ambiente de build e precisam estar públicos e funcionais antes da submissão à App Store. Não há conta no MVP1, portanto apagar histórico não é apresentado como exclusão de conta.

Notificações, publicidade, UMP, ATT e “Opções de privacidade” permanecem fora do MVP1.

## 8. Critérios de confiança e linguagem honesta

LagCheck deve explicitar internamente o tipo de alvo medido e traduzir isso em confiança proporcional. A UI normal usa linguagem simples; detalhes técnicos ficam na tela de detalhes.

| Nível | Situação | Confiança | Como comunicar |
| --- | --- | --- | --- |
| A — jogo oficial | Há endpoint oficial do fabricante para medir latência. | Muito alta | Latência medida para o jogo. |
| B — infraestrutura do jogo | Há infraestrutura específica e uso legítimo/documentado para medição. | Alta | Estimativa de alta confiança para o jogo. |
| C — proxy regional gamer | O jogo opera na região e a medição usa infraestrutura gamer regional. | Média/alta | Latência regional estimada para o jogo. |
| D — região genérica | Não há informação confiável sobre a hospedagem do jogo. | Média | Qualidade estimada para jogar na região. |

O app jamais afirma "seu ping no Fortnite é 24 ms" se não mediu um destino oficial ou específico do Fortnite. Nesses casos, usa expressões como **"latência regional: 26 ms"** ou **"estimativa para Fortnite: 24–31 ms"**.

## 9. Métricas e interpretação

O motor calcula métricas de rede, mas a tela principal mostra somente as que ajudam a decisão:

- latência;
- jitter;
- perda de pacotes;
- spikes.

O score também considera percentis, frequência e gravidade dos spikes, consistência e, no Deep Check, a degradação sob carga. A fórmula e os limites por perfil são decisões de produto configuráveis; o resultado precisa permanecer determinístico e reproduzível para as mesmas amostras e perfil.

Cada resultado deve conter uma causa principal, quando identificável, e uma recomendação compreensível. Exemplos de causas: perda de pacotes, latência alta, jitter elevado, picos severos ou bufferbloat/saturação sob carga.

## 10. Catálogo de jogos e regiões

O catálogo remoto define, por jogo e mercado:

- identificador, nome e arte do jogo;
- plataformas compatíveis;
- gênero/perfil de qualidade esperado;
- regiões relevantes;
- tipo de medição e confiança;
- limites usados pelo score e recursos habilitados.

Isso permite atualizar regiões, perfis e limites sem exigir uma nova versão do aplicativo. O catálogo não altera a promessa de medição: ele apenas seleciona o contexto correto e como o resultado deve ser comunicado.

### 10.1 Regras de negócio para classificação dos jogos

A classificação de um jogo tem três objetivos diferentes e não intercambiáveis:

| Classificação | Finalidade | Impacto no produto |
| --- | --- | --- |
| Categoria de descoberta | Ajudar a pessoa a encontrar o jogo. | Organiza busca e Home: FPS, Battle Royale, MOBA, Casual e Cloud. |
| Perfil de exigência de rede | Definir quanto latência, jitter, perda e spikes afetam a experiência. | Seleciona os limites do LagCheck Score, as causas e os textos de recomendação. |
| Estratégia de medição | Definir quais regiões e destinos podem representar o jogo naquele mercado. | Define o alvo do teste, a confiança e a linguagem de precisão permitida. |

Um jogo pode pertencer a uma única categoria principal de descoberta e ter múltiplas etiquetas secundárias, mas deve ter **um único perfil de rede ativo por combinação de jogo, plataforma e mercado**. Isso impede que o mesmo teste seja avaliado contra regras conflitantes.

Os perfis ativos da V1 são:

| Perfil | Uso | Princípio de avaliação |
| --- | --- | --- |
| `BATTLE_ROYALE_COMPETITIVE` | Battle royale competitivo, como Fortnite. | Rigor alto para estabilidade e spikes, além de latência. |
| `MOBILE_REALTIME` | Jogos mobile de ação em tempo real, como COD Mobile, Free Fire e Wild Rift. | Prioriza consistência e resposta rápida no próprio dispositivo. |
| `CASUAL_REALTIME` | Jogos casuais com interação em tempo real. | Aceita limites menos severos, sem ocultar perda ou instabilidade relevantes. |

O mapeamento inicial é: Fortnite, Call of Duty Mobile, Free Fire e PUBG Mobile em `BATTLE_ROYALE_COMPETITIVE`; Brawl Stars e Wild Rift em `MOBILE_REALTIME`; Roblox e Minecraft em `CASUAL_REALTIME`. Perfis de FPS competitivo e Cloud Gaming ficam reservados para uma ampliação futura do catálogo.

Os nomes e os limites numéricos desses perfis serão definidos no catálogo remoto e podem evoluir sem atualização do app. A categoria não define se uma conexão é boa: o perfil de rede é quem define a régua.

### 10.2 Elegibilidade de um jogo no catálogo

Um jogo só pode aparecer como testável em um mercado quando houver, para aquele contexto:

1. Pelo menos uma plataforma suportada;
2. Um perfil de rede ativo;
3. Uma ou mais regiões de referência;
4. Uma estratégia de medição permitida;
5. Um nível de confiança e uma mensagem de precisão compatível;
6. Textos de resultado e recomendação nos idiomas publicados.

Se faltar qualquer um desses elementos, o jogo não inicia teste nesse contexto. Ele pode ser omitido da busca ou aparecer como indisponível, com explicação curta; a decisão de UX será única para todo o catálogo. A V1 não usa destinos obtidos de forma obscura nem testa infraestrutura de terceiros sem autorização/documentação apropriada.

### 10.3 Seleção de região e alvo da medição

Ao iniciar o teste, o app resolve o contexto nesta ordem:

1. Jogo selecionado;
2. Mercado/país do catálogo;
3. Plataforma informada;
4. Perfil de rede;
5. Regiões candidatas permitidas pelo catálogo assinado;
6. Melhor estratégia de medição disponível, de nível A a D;
7. Região de referência escolhida pela pré-leitura UDP ou pela escolha manual da pessoa.

Na V1, o mercado reconhecido para esse processo é Brasil ou Estados Unidos. A localidade do sistema só ordena mercados já publicados; não fixa mercado, região ou destino. A disponibilidade global na App Store não substitui a elegibilidade de catálogo para iniciar uma medição.

A pré-leitura é parte da mesma sessão e escolhe somente a região de referência antes do Quick Check ou do Deep Check. Ela não escolhe servidor do jogo, não muda matchmaking e não autoriza prometer ping oficial.

**Atualização de UX (2026-09-10):** a seleção deixou de ter uma tela de confirmação/escolha no meio da jornada de medição — ao tocar em "Iniciar", a pré-leitura resolve o candidato e a medição já começa, sem segundo toque. A escolha manual não é mais feita por sessão: é uma preferência persistida em Configurações (menu nativo "Região de referência"), aplicada automaticamente a toda sessão futura enquanto o candidato escolhido continuar válido para o jogo/mercado/plataforma medidos. Se deixar de ser válido, a sessão volta para automático em vez de falhar. Sem candidato viável (automático ou preferido), o resultado continua inconclusivo, sem troca silenciosa de destino. A regra de seleção em si (desempate, privacidade, gates) não mudou e está em [Decisão de seleção regional automática](./16-decisao-selecao-regional-automatica.md).

O Quick Check mede a região assim escolhida. O Deep Check mede essa mesma região no repouso e sob carga; impacto sob carga continua complementar e não altera o score principal. Uma referência mais rápida não altera automaticamente a região real usada pelo jogo e não deve ser apresentada como recomendação de troca de servidor sem evidência de que essa troca é possível no jogo.

### 10.4 Regras de plataforma e representatividade

| Contexto selecionado | Regra funcional de confiança |
| --- | --- |
| iPhone no próprio aparelho | O teste representa diretamente o dispositivo e a interface usados para jogar. É o cenário de maior confiança permitido pela estratégia de medição. |
| Console/PC em Wi-Fi | O teste representa a rota de internet e a conexão local de forma próxima, desde que o telefone esteja na mesma rede Wi-Fi. |
| Console/PC em Ethernet | O teste representa bem a rota de internet; a parte local do equipamento é estimada. |
| Aparelho em outra rede | O teste não é representativo e não deve ser tratado como teste daquele console ou PC. |

Se a pessoa declarar Wi-Fi para o equipamento externo, o app assume que ele está na mesma rede do iPhone até que haja evidência contrária. Essa é uma simplificação consciente da V1 e deve ser comunicada como estimativa quando necessário.

### 10.5 Regras de classificação do resultado

Para cada medição, o motor aplica exclusivamente o perfil ativo do jogo e classifica a qualidade usando latência, jitter, perda, spikes, consistência e, no Deep Check, degradação sob carga.

- O score é determinístico: mesmas amostras e mesmo perfil produzem o mesmo resultado.
- A classificação nominal — por exemplo, Excelente, Bom, Risco de lag — vem do score e dos guardrails do perfil.
- Guardrails prevalecem sobre uma média aparentemente boa. Perda de pacotes, picos severos ou instabilidade sob carga podem limitar a classificação e precisam aparecer na explicação.
- A causa principal é a condição com maior impacto observada. Se houver várias, o resultado principal usa uma só causa e os detalhes mostram as demais.
- O catálogo pode alterar limites por perfil, mas não pode remover a indicação de confiança nem permitir uma promessa de precisão superior ao nível de medição disponível.

### 10.6 Contrato funcional das métricas

Cada resultado precisa guardar e poder exibir as métricas abaixo. Os valores são calculados a partir de amostras válidas do mesmo teste e da mesma rota; não se combinam amostras de redes, regiões ou execuções diferentes.

| Métrica | Cálculo/definição | Unidade | Uso no produto |
| --- | --- | --- | --- |
| Latência por amostra | Tempo de ida e volta de uma transação de probe válida. | ms | Alimenta o gráfico vivo e a distribuição de latência. |
| Latência mediana (P50) | Valor abaixo do qual ficam 50% das amostras válidas. | ms | É o "ping" principal apresentado no resultado. Evita que um pico isolado distorça a leitura. |
| P95 | Valor abaixo do qual ficam 95% das amostras válidas. | ms | Mostra a latência ruim recorrente, mesmo quando a mediana parece boa. Fica em Detalhes e no Deep Check. |
| P99 | Valor abaixo do qual ficam 99% das amostras válidas. | ms | Expõe a cauda mais severa; é diagnóstico avançado em Detalhes. |
| Jitter | Variação entre amostras consecutivas de latência válidas; a V1 usa a média das diferenças absolutas consecutivas. | ms | Indica instabilidade contínua. Pode aparecer no resumo e influencia score/causa. |
| Perda de pacotes | Proporção de probes enviados que não tiveram resposta válida dentro do tempo configurado: `timeouts / probes enviados × 100`. | % | É uma métrica crítica: mesmo baixa, pode limitar a classificação em perfis competitivos. |
| Spike | Amostra válida que ultrapassa o limite de pico do perfil, considerando um limite absoluto e/ou desvio relevante em relação à mediana do próprio teste. | contagem | Mostrado no resumo e no gráfico. A regra exata é configurável por perfil. |
| Spike severo | Spike que ultrapassa o limite severo do perfil. | contagem | Aciona guardrail mais forte e aparece como causa prioritária quando relevante. |
| Taxa de spikes | `spikes / amostras válidas × 100`. | % | Distingue um pico isolado de instabilidade repetida. Fica em Detalhes e alimenta consistência. |
| Pior spike | Maior latência válida observada no teste. | ms | Explica o pior evento no Deep Check/Detalhes. Não substitui P95 ou P99. |
| Consistência | Indicador derivado de jitter, P95/P50, taxa de spikes e perda, normalizado pelo perfil ativo. | 0–100 | Alimenta o score e pode apoiar uma explicação simples como "conexão instável". Não substitui as métricas brutas. |
| Latência sob carga | P50 calculado durante a fase de carga controlada do Deep Check. | ms | Avalia se uso concorrente da rede prejudica a partida. |
| Aumento sob carga | `P50 sob carga − P50 em repouso`. | ms | Identifica degradação sob carga; embasa a recomendação sobre downloads e streaming. |

#### Regras de coleta e validade

- Uma amostra só é válida quando a resposta corresponde ao probe enviado e chega dentro do timeout do teste. Respostas inválidas, duplicadas ou tardias não entram em P50, P95, P99 ou jitter.
- Um timeout conta para perda, mas não recebe uma latência artificial. Isso impede que a mediana esconda perda e evita contaminar percentis com valores inventados.
- O Quick Check planeja até 30 probes, com timeout de 2 segundos por probe. Com pelo menos 10 respostas válidas, gera score e contabiliza os timeouts como perda. Com menos de 10 respostas válidas, o resultado é **inconclusivo**, não uma nota baixa.
- O MVP não troca UDP por HTTP ou ICMP quando os probes falham. Sem respostas UDP suficientes, o app explica que não foi possível medir a rota gamer naquela conexão e sugere tentar outra rede.
- O Deep Check calcula as métricas de repouso e sob carga separadamente. Nunca usa as duas fases como uma única distribuição.
- Mudança de caminho de rede, interrupção explícita, erro do destino ou quantidade insuficiente de amostras torna o teste cancelado ou inconclusivo; não gera LagCheck Score.
- Cada resultado persiste versão do perfil, região, tipo de alvo e versão da fórmula. Isso torna histórico e suporte auditáveis quando o catálogo evoluir.

#### Regras de apresentação

| Superfície | Métricas exibidas | Regra |
| --- | --- | --- |
| Durante o Quick Check | Latência atual, perda acumulada, spikes acumulados e gráfico. | Valores parciais não recebem score nem conclusão antes do encerramento. |
| Resultado principal | P50 como Ping, jitter, perda e número de spikes. | Mostra primeiro a conclusão, depois até quatro métricas. |
| Detalhes | P50, P95, P99, jitter, perda, spikes, pior spike, taxa de spikes, região, alvo e confiança. | Expõe dados brutos e derivados para quem quer investigar. |
| Resultado do Deep Check | Todas as métricas relevantes, score em repouso, P50 em repouso, P50 sob carga e impacto sob carga. | Deve explicar se a carga alterou materialmente a experiência sem reescrever o score de repouso. |

#### Regras de score e guardrails

O **LagCheck Score** varia de 0 a 100 e é uma avaliação do contexto selecionado, não um indicador genérico de internet. Ele combina componentes de latência, estabilidade, perda e spikes, ponderados pelo perfil de rede do jogo.

No Deep Check, o score principal continua representando a conexão em repouso. A fase sob carga gera uma leitura separada de **impacto sob carga**, expressa pelo aumento de latência e pela classificação de estabilidade. Ela nunca reescreve o score de repouso; o resultado pode, por exemplo, mostrar "92 — Excelente em repouso" e "Sob carga: +67 ms, risco de lag".

Os pesos, limites de faixa e valores de guardrail ficam no catálogo remoto versionado. Eles precisam ser publicados por perfil e testáveis, mas não ficam hardcoded na interface. A fórmula-base da V1 atribui 35% à latência (P50), 30% à perda de pacotes, 20% ao jitter e 15% a spikes/consistência. As seguintes regras são invariantes na V1:

1. Perda de pacotes, spikes severos e instabilidade sob carga podem limitar a classificação mesmo com P50 baixa.
2. Um score alto não pode ocultar uma causa crítica observada; a explicação precisa mencioná-la.
3. Confiança da medição não entra no score de qualidade. Ela qualifica quão diretamente o teste representa o jogo.
4. Resultado inconclusivo, cancelado ou sem amostras suficientes não recebe score, classificação positiva nem recomendação de jogar.
5. A classificação textual é derivada do score limitado pelos guardrails do perfil: `90–100 Excelente`, `75–89 Ótimo`, `60–74 Instável` e `0–59 Risco de lag`.

| Faixa | Classificação | Mensagem principal |
| --- | --- | --- |
| 90–100 | Excelente | Pronto para jogar. |
| 75–89 | Ótimo | Pronto para jogar. |
| 60–74 | Instável | Você pode sentir lag. |
| 0–59 | Risco de lag | Vale investigar antes de jogar. |

#### Calibração inicial: `BATTLE_ROYALE_COMPETITIVE`

| Métrica | Excelente | Ótimo | Instável | Risco de lag |
| --- | ---: | ---: | ---: | ---: |
| P50 | ≤ 40 ms | ≤ 60 ms | ≤ 90 ms | > 90 ms |
| Jitter | ≤ 8 ms | ≤ 15 ms | ≤ 25 ms | > 25 ms |
| Perda | 0% | até 1% | até 3% | > 3% |

Guardrails deste perfil:

- Perda acima de 3% limita o resultado a **Risco de lag**.
- Dois ou mais spikes severos limitam o resultado a **Instável**.
- P50 acima de 100 ms limita o resultado a **Risco de lag**.
- Um spike é uma amostra acima de `P50 + 30 ms` e de pelo menos 80 ms.
- Um spike severo é uma amostra acima de `P50 + 80 ms` e de pelo menos 150 ms.

Esses limites são a calibração inicial de lançamento e permanecem versionados no catálogo para validação e ajuste posterior com medições reais.

#### Calibração inicial: `MOBILE_REALTIME`

| Métrica | Excelente | Ótimo | Instável | Risco de lag |
| --- | ---: | ---: | ---: | ---: |
| P50 | ≤ 50 ms | ≤ 80 ms | ≤ 120 ms | > 120 ms |
| Jitter | ≤ 12 ms | ≤ 20 ms | ≤ 35 ms | > 35 ms |
| Perda | 0% | até 1% | até 5% | > 5% |

Guardrails deste perfil:

- Perda acima de 5% limita o resultado a **Risco de lag**.
- Dois ou mais spikes severos limitam o resultado a **Instável**.
- P50 acima de 130 ms limita o resultado a **Risco de lag**.
- Um spike é uma amostra acima de `P50 + 40 ms` e de pelo menos 100 ms.
- Um spike severo é uma amostra acima de `P50 + 100 ms` e de pelo menos 200 ms.

#### Calibração inicial: `CASUAL_REALTIME`

| Métrica | Excelente | Ótimo | Instável | Risco de lag |
| --- | ---: | ---: | ---: | ---: |
| P50 | ≤ 70 ms | ≤ 110 ms | ≤ 170 ms | > 170 ms |
| Jitter | ≤ 20 ms | ≤ 35 ms | ≤ 50 ms | > 50 ms |
| Perda | 0% | até 1% | até 3% | > 3% |

Guardrails deste perfil:

- Perda acima de 3% limita o resultado a **Risco de lag**.
- Três ou mais spikes severos limitam o resultado a **Instável**.
- P50 acima de 180 ms limita o resultado a **Risco de lag**.
- Um spike é uma amostra acima de `P50 + 60 ms` e de pelo menos 140 ms.
- Um spike severo é uma amostra acima de `P50 + 140 ms` e de pelo menos 300 ms.

## 11. Monetização — arco MVP1 → MVP1.1 → MVP2

**Decisão registrada (2026-09-10):** a monetização do LagCheck segue um arco em três etapas, não um modelo único fixado desde já.

1. **MVP1 — sem monetização.** Nenhuma biblioteca de anúncio, SDK de consentimento, unidade de anúncio, identificador publicitário ou preço entra no binário inicial. O objetivo do MVP1 é validar medição, catálogo e qualidade técnica, não receita.
2. **MVP1.1 — anúncios como ponte.** Banner discreto em Home e Histórico (regras completas abaixo), suficiente para cobrir operação enquanto o produto ainda está provando conceito, sem exigir compromisso de compra do usuário.
3. **MVP2 — assinatura anual como modelo principal.** A intenção é migrar a monetização primária de anúncios para uma assinatura anual, condicionada a recursos que ainda não existem no MVP1/MVP1.1. **O recurso (ou conjunto de recursos) que justifica o pagamento anual é uma decisão pendente** — listada em §14 — e precisa estar definida antes de o MVP2 entrar em escopo de arquitetura. Anúncios podem continuar coexistindo com a assinatura (ex.: removidos para assinantes) ou serem descontinuados; isso também é decisão do MVP2, não desta versão do documento.

Nada neste arco compromete os princípios de §8 e §9: confiança do resultado, causa e recomendação nunca dependem do que o usuário paga.

### 11.1 Publicidade — MVP1.1

Publicidade não faz parte do MVP1 e nenhuma biblioteca de anúncio, SDK de consentimento, unidade de anúncio ou identificador publicitário entra no binário inicial. O app pode ser distribuído sem anúncios enquanto a medição, o catálogo e a promessa de resultado são validados.

No MVP1.1, o LagCheck poderá ser monetizado com anúncios sem comprometer a confiança na medição ou atrasar a resposta que trouxe a pessoa ao app.

Formato previsto para o MVP1.1: **banner discreto apenas na Home e no Histórico**. Não haverá anúncio em tela cheia, anúncio recompensado ou publicidade na tela de resultado.

Rede de publicidade prevista para o MVP1.1: **Google AdMob**, sem mediação. O app usa somente banners adaptativos dessa rede.

Privacidade de publicidade prevista para o MVP1.1: o app usa o **Google User Messaging Platform (UMP)** para obter e gerenciar consentimento quando aplicável ao mercado, expõe "Opções de privacidade" quando necessário e não solicita App Tracking Transparency (ATT). Sem ATT, o app usa anúncios contextuais ou limitados conforme o estado de consentimento e as regras aplicáveis.

Regras do MVP1.1:

- Nenhum anúncio é exibido durante o Quick Check ou o Deep Check.
- Um anúncio nunca cobre latência ao vivo, estado do teste, resultado, causa de lag, recomendação ou ações de "Testar novamente", "Ver detalhes" e "Fazer Deep Check".
- Anúncios só aparecem na Home e no Histórico, em área reservada e sem deslocar ou cobrir conteúdo essencial.
- Publicidade não altera score, classificação, confiança, catálogo de jogos nem recomendação. A mesma medição produz o mesmo resultado com ou sem anúncio.
- O app identifica conteúdos patrocinados de forma clara e não apresenta anúncio como sugestão técnica do LagCheck.
- A experiência UMP de consentimento/privacidade é avaliada antes da inicialização do AdMob quando exigida pelo mercado. Ela preserva as regras acima e está disponível em PT-BR e inglês quando for exibida ao usuário.

Anúncios recompensados e qualquer recurso que venda "otimização" ficam fora de escopo em qualquer versão. Assinatura paga fica fora do MVP1 e do MVP1.1; ela é a aposta de monetização principal do MVP2, conforme §11.

## 12. Requisitos de experiência e linguagem

- Dark mode é a experiência visual principal, sem estética gamer estereotipada, excesso de neon, gauges ou muitos cards.
- O jogo é o protagonista; a ferramenta de rede fica em segundo plano.
- Capas dos jogos trazem cor e contexto. O LagCheck Score é o elemento visual distintivo de resultado.
- A linguagem é direta e útil: o que aconteceu, o que isso significa para a partida e o que fazer agora.
- A interface suporta PT-BR e inglês desde a V1. Isso inclui onboarding eventual, estados de erro, resultados, detalhes, histórico, privacidade/consentimento e identificação publicitária.
- A marca oficial é **LagCheck**. O wordmark é a assinatura principal; o "gg" em forma de infinito é o símbolo compacto da marca.

## 13. Critérios de aceite do MVP

1. Uma pessoa consegue abrir o app, escolher um jogo/plataforma e receber um Quick Check em aproximadamente 15 segundos, sem conta.
2. O resultado traz score, classificação, conclusão em linguagem comum e métricas resumidas.
3. Uma mudança de Wi-Fi para celular durante a medição cancela o teste e não gera resultado misto.
4. Para medições indiretas, a UI deixa claro que o dado é uma estimativa regional, sem alegar ping exato do jogo.
5. Um resultado com risco oferece uma ação clara para novo teste ou investigação por Deep Check.
6. O histórico local permite retestar um jogo e acompanhar sua evolução recente.
7. O catálogo pode mudar jogos, regiões e perfis sem atualização do app.
8. Todas as superfícies do MVP1 funcionam em PT-BR e inglês.

Os requisitos de publicidade acima não são critério de aceite do MVP1; passam a ser critérios do MVP1.1.

Estes oito critérios são exclusivamente funcionais e técnicos. **O MVP1 não tem critério de aceite de retenção, engajamento ou modelo de negócio** — isso é deliberado: o objetivo desta versão é fundação técnica sólida, superfície enxuta e identidade de produto definida, não prova de que o produto se sustenta comercialmente. Notificação, widget, Live Activity ou qualquer outro mecanismo de retorno ao app foram avaliados e conscientemente adiados para depois do MVP1 (ver §7.8); a ausência deles no MVP1 não deve ser lida como falha de escopo, e o eventual baixo retorno de usuários no MVP1 não deve ser lido, sozinho, como invalidação do conceito.

### 13.1 Critério de saída do MVP1

Antes de comprometer escopo do MVP1.1, a equipe revisa os dados agregados já autorizados por §9 da arquitetura (App Store Connect: sessões, retenção, taxa de instalação/desinstalação, avaliações) depois de um período mínimo em produção. Essa revisão, e não a qualidade técnica do código, é o sinal que decide se o MVP1.1 segue como planejado, é ajustado ou é adiado. Nenhuma telemetria própria é criada para essa revisão; ela usa somente o que a App Store já fornece, preservando a regra de zero telemetria do MVP1.

## 14. Decisões pendentes

- Lista inicial dos cerca de dez jogos e seus mercados prioritários.
- Textos de recomendação por causa e por idioma.
- Critérios para oferecer automaticamente o Deep Check.
- Qual recurso (ou conjunto de recursos) do MVP2 justifica cobrança de assinatura anual — ver §11. Sem essa definição, o MVP2 não entra em escopo de arquitetura.
- Se/quando notificação, widget ou outro mecanismo de retorno entram em escopo, e em qual versão — hoje intencionalmente fora do MVP1 (ver §13).
