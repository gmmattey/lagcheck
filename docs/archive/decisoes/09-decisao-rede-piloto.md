# Nolaggy — decisão de rede do piloto Quick Check

**Status:** decisão executável do piloto
**Dona:** Iury — Qualidade de Rede
**Revisão obrigatória para implementação:** Rian + Marco
**Data:** 8 de setembro de 2026

## 1. Decisão e limite da promessa

O primeiro corte mede a rota entre o **iPhone** e o beacon UDP público da AWS GameLift em **São Paulo (`sa-east-1`)**. O contexto inicial é **Fortnite · iPhone · BR**, com o perfil `BATTLE_ROYALE_COMPETITIVE`.

Isso é uma **referência regional**, não uma medição de servidor oficial do Fortnite, nem prova de que o jogador será alocado nessa região. Enquanto não houver evidência documentada do mapa Fortnite → região, a estratégia do piloto é `genericRegion` e a confiança é `medium`. O texto de resultado não pode chamar o RTT de “ping do Fortnite”; deve qualificá-lo como rota regional de referência.

O destino configurado é `gamelift-ping.sa-east-1.api.aws:7770` (UDP). A escolha não cria infraestrutura própria nem altera o limite de custo operacional recorrente zero. O dono do produto confirmou uma execução funcional em iPhone físico; a confirmação não substitui a evidência auditável de disponibilidade, resposta e comportamento por tipo de rede exigida neste documento.

## 2. Contrato do Quick Check

- Início: `t0` é o instante monotônico imediatamente antes do primeiro envio.
- Janela de envio: `[t0, t0 + 15 s)`, com 30 probes, sequências `0...29`, a cada 500 ms.
- Timeout individual: 2 s a partir do envio.
- Drenagem: nenhum probe é enviado após `t0 + 15 s`; respostas pendentes podem ser aceitas até `t0 + 17 s`.
- Fechamento: em `t0 + 17 s`, todos os probes pendentes são marcados como timeout e a sessão é avaliada uma única vez.
- Resultado: são necessárias pelo menos 10 respostas UDP válidas da região primária. Com menos de 10, o estado é `inconclusive(insufficientUDPResponses)`, sem score, classe positiva, recomendação para jogar ou persistência de histórico.

A sessão permanece visualmente uma checagem de aproximadamente 15 segundos; a drenagem é encerramento técnico, não uma nova fase de medição. Qualquer apresentação desse encerramento deve ser revisada por Renan antes de entrar na interface.

## 3. Payload e correlação do beacon

Cada probe usa 33 bytes, todos em ordem big-endian:

| Campo | Tamanho | Regra |
| --- | ---: | --- |
| magic | 4 bytes | ASCII `NLPG` |
| versão | 1 byte | `0x01` |
| sessionID | 16 bytes | valor aleatório criptograficamente seguro, único por sessão |
| sequência | 4 bytes | `UInt32`, de `0` a `29` |
| nonce | 8 bytes | valor aleatório criptograficamente seguro, único por probe |

O payload é não vazio e fica abaixo de 300 bytes. Uma resposta só é válida se vier do host/porta configurados, chegar antes do timeout individual e da drenagem, e repetir **exatamente** os 33 bytes enviados. Respostas duplicadas, de outro destino, com bytes diferentes ou após o prazo são inválidas; não produzem RTT e não contam como sucesso.

Essa exigência de eco integral é deliberada: como há probes simultaneamente pendentes, não é aceitável associar uma resposta apenas pela ordem de chegada. A AWS documenta que o corpo UDP pode conter dados arbitrários não vazios; o eco integral desse formato no `NWConnection` do iPhone ainda precisa ser comprovado no gate físico. Se o beacon não devolver bytes suficientes para a correlação, não se cria heurística de associação: a implementação para e a decisão volta para Iury e Rian.

## 4. Métricas, normalização e score do piloto

### 4.1 Regras comuns

RTT é `receivedAt - sentAt` para cada resposta válida. P50, P95 e P99 usam interpolação linear em RTTs ordenados, na posição `(n - 1) × p`. Jitter é a média de `abs(RTT[n] - RTT[n-1])` entre RTTs válidos consecutivos na ordem de sequência de envio. Uma resposta UDP correlacionada que chegue fora de ordem continua válida para o seu probe, mas não reordena essa série. Perda é `timeouts / 30 × 100`; resposta inválida não é RTT nem sucesso e permanece classificada separadamente no diagnóstico local.

Todos os cálculos intermediários usam `Double`. Somente o score bruto é arredondado uma vez, por arredondamento para o inteiro mais próximo com metades afastadas de zero. Não há RTT artificial para timeout.

Para uma métrica menor-é-melhor, `component(x; E, O, I, R)` usa quatro nós explícitos:

| Intervalo | Componente |
| --- | --- |
| `x <= E` | `100` |
| `E < x <= O` | interpolação linear de `100` a `80` |
| `O < x <= I` | interpolação linear de `80` a `60` |
| `I < x < R` | interpolação linear de `60` a `0` |
| `x >= R` | `0` |

O quarto nó `R` resolve a ambiguidade anterior entre o teto Instável e o início de Risco: o componente não dá um salto no primeiro valor acima de `I`. A classe final continua sendo limitada por guardrails; `R` é uma âncora de normalização, não uma promessa de que somente naquele ponto existe risco.

### 4.2 Nós do perfil `BATTLE_ROYALE_COMPETITIVE`

| Componente | E | O | I | R |
| --- | ---: | ---: | ---: | ---: |
| Latência P50 (ms) | 40 | 60 | 90 | 100 |
| Jitter (ms) | 8 | 15 | 25 | 40 |
| Perda (%) | 0 | 1 | 3 | 5 |
| Relação P95/P50 | 1.10 | 1.35 | 1.75 | 2.50 |
| Taxa de spikes (%) | 0 | 3 | 10 | 20 |

Quando `P50` é zero, a relação P95/P50 é definida como `1` somente se P95 também for zero; caso contrário ela é `+infinito`. Esse caso é mantido para determinismo, embora RTT zero não seja esperado na prova física.

### 4.3 Componente de spikes e consistência

Um spike é um RTT válido `> P50 + 30 ms` **e** `>= 80 ms`. Um spike severo é `> P50 + 80 ms` **e** `>= 150 ms`.

O componente de spikes é `component(taxaDeSpikes; 0, 3, 10, 20)`. A taxa é `spikes / respostasVálidas × 100`. Não se inventa spike para timeout; perda já é medida separadamente.

O componente de cauda é `component(P95/P50; 1.10, 1.35, 1.75, 2.50)`. A consistência é:

```text
consistência = clamp(0, 100,
  0.40 × componenteJitter +
  0.30 × componenteCauda +
  0.20 × componenteSpikes +
  0.10 × componentePerda)
```

O componente de estabilidade é `min(componenteSpikes, consistência)`. A repetição controlada de perda e jitter na consistência é intencional: o score preserva o peso direto dessas métricas e a estabilidade impede que uma média favorável esconda cauda, picos ou perda recorrente.

```text
scoreBruto = arredondar(0.35 × componenteP50 +
                        0.30 × componentePerda +
                        0.20 × componenteJitter +
                        0.15 × componenteEstabilidade)
```

Guardrails alteram o teto numérico do score para manter score e classe coerentes:

| Condição | Teto do score final |
| --- | ---: |
| perda `> 3%` ou P50 `> 100 ms` | 59 |
| dois ou mais spikes severos | 74 |

Se mais de um guardrail se aplicar, vale o menor teto. Sem guardrail, `scoreFinal = scoreBruto`. A classe vem exclusivamente do score final: 90–100 Excelente, 75–89 Ótimo, 60–74 Instável, 0–59 Risco de lag.

## 5. Vetores determinísticos mínimos

Os vetores abaixo são requisitos para os testes puros do domínio. `× n` significa repetição consecutiva; não são capturas de rede física.

| ID | Entradas | Saída esperada |
| --- | --- | --- |
| `BR-001-estavel` | 30 RTTs de `30 ms`; 0 timeouts | P50/P95/P99 `30`; jitter `0`; perda `0%`; 0 spikes; consistência `100`; score bruto/final `100`; Excelente. |
| `BR-002-perda-guardrail` | 20 RTTs de `30 ms`; 10 timeouts | P50/P95/P99 `30`; jitter `0`; perda `33.333333%`; 0 spikes; consistência `90`; score bruto `69`; score final `59`; Risco de lag. |
| `BR-003-spikes-severos` | 28 RTTs de `30 ms`, seguidos de 2 RTTs de `160 ms`; 0 timeouts | P50 `30`; P95 `101.5`; P99 `160`; jitter `4.482759 ms`; 2 spikes severos; taxa `6.666667%`; componente spikes `69.52381`; consistência `63.90476`; score bruto `95`; score final `74`; Instável. |
| `BR-004-inconclusivo` | 9 RTTs de `30 ms`; 21 timeouts | `inconclusive(insufficientUDPResponses)`; métricas podem ser mostradas apenas como diagnóstico técnico; sem score, classe, causa, recomendação ou histórico. |
| `BR-005-limite-drenagem` | probe 29 enviado em `t0 + 14.5 s`, resposta correlacionada em `t0 + 16.499 s` | resposta válida. |
| `BR-006-resposta-tardia` | probe 29 enviado em `t0 + 14.5 s`, resposta correlacionada em `t0 + 16.501 s` | timeout; não entra em percentil, jitter ou sucesso. |
| `BR-007-resposta-invalida` | payload de resposta com um byte diferente, antes do timeout | `invalidResponse`; não entra em RTT nem sucesso; o diagnóstico preserva a ocorrência. |

Os vetores de percentil adotam posição zero-indexada `(n - 1) × p`, interpolando o valor entre os dois índices adjacentes. Para `BR-003`, isso produz P95 `101.5` e P99 `160`.

## 6. Gate de prova física

Em 8 de setembro de 2026, foram registradas seis capturas físicas de Quick Check em **iPhone 17**, **iOS 26.6.1**, build **Debug**, contra o destino regional de referência configurado no piloto. As capturas finais são evidência de três execuções em cada tipo de rede:

| Rede | Execução | Resultado final capturado |
| --- | ---: | --- |
| Wi-Fi | 1 | Score 59, Risco de lag; ping 16 ms; jitter 24 ms; perda 3%; 1 pico. |
| Wi-Fi | 2 | Score 99, Excelente; ping 5 ms; jitter 5 ms; perda 0%; 0 picos. |
| Wi-Fi | 3 | Score 59, Risco de lag; ping 22 ms; jitter 6 ms; perda 3%; 0 picos. |
| Celular | 1 | Score 68, Instável; ping 42 ms; jitter 54 ms; perda 0%; 2 picos. |
| Celular | 2 | Score 39, Risco de lag; ping 74 ms; jitter 31 ms; perda 10%; 3 picos. |
| Celular | 3 | Score 57, Risco de lag; ping 75 ms; jitter 65 ms; perda 0%; 5 picos. |

Também permanecem comprovados em iPhone físico: UI test aprovado para cancelamento explícito e outro para entrada em segundo plano, ambos descartando a leitura parcial sem score; e a observação manual do dono de que desligar o Wi-Fi durante “Verificando” exibiu a mensagem de conexão alterada e a ação de reinício.

As seis capturas fecham a evidência de três Quick Checks em Wi-Fi e três em celular, mas **não fecham por si sós todo o gate de validação auditável**. Elas não provam eco integral do `NLPG/1`, validação bruta de sessão/sequência/nonce, detalhes da resolução do destino, nem os casos físicos adversariais de resposta duplicada, tardia ou malformada. Também não substituem o gate visual, de VoiceOver e de Reduced Motion. As capturas são evidência local do resultado final, não telemetria.

Antes de declarar a validação física completa ou habilitar o piloto para testes de produto, Rian e Iury precisam registrar evidência de:

1. A captura física de resultado final em Wi-Fi e celular demonstra seis Quick Checks contra a referência regional; ainda falta evidência do datagrama e da resolução efetiva do destino.
2. A resposta permite validar integralmente o payload, sessão, sequência e nonce descritos na seção 3.
3. As três execuções por tipo de rede estão registradas acima; ainda falta evidência que correlacione cada execução à janela de envio, timeout e drenagem. Não há requisito de score positivo: uma rede que bloqueie UDP deve terminar inconclusiva de forma honesta.
4. Cancelamento explícito e background estão comprovados; a recuperação visível após mudança de rede foi observada manualmente. Ainda falta evidência auditável completa para a mudança Wi-Fi ↔ celular e para ausência de persistência.
5. Um destino inválido, resposta tardia, duplicada ou com bytes diferentes não é aceito como RTT válido em caso físico adversarial.

O teste físico deve registrar somente agregados e eventos técnicos necessários para a prova; não deve introduzir telemetria remota, dados pessoais ou amostras brutas persistentes além da sessão atual.

## 7. Impacto e próximos responsáveis

Esta decisão fecha a fronteira de qualidade de rede do piloto. Rian implementa o transporte, coordenador e testes de integração sem alterar as fórmulas. Renan precisa aprovar a composição de inconclusivo/cancelamento e qualquer indicação de encerramento técnico. Marco confirma a linguagem de referência regional antes de qualquer resultado visível.

Para expandir além do piloto, cada novo jogo/região exige: evidência do mapa jogo → região, estratégia e confiança compatíveis, versão de catálogo/perfil e vetores correspondentes. Nenhuma região alternativa é selecionada silenciosamente.
