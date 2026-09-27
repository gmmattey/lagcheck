# Nolaggy — decisão: Deep Check do piloto

**Status:** implementado localmente; Worker piloto publicado

## Decisão

O Deep Check do piloto compara duas leituras UDP independentes para o mesmo contexto Fortnite / BR / iPhone: uma em repouso e outra enquanto o iPhone transfere uma carga HTTP controlada. O Nolaggy Score exibido é sempre o resultado da fase de repouso. A carga só produz a leitura complementar de impacto sob carga.

O recurso exige Wi-Fi antes do início e durante as duas fases. Mudança de caminho, background ou cancelamento descarta a sessão inteira; não persiste histórico nem mostra métricas parciais. Se a fase de repouso não atingir dez respostas UDP válidas, o Deep Check é inconclusivo, sem score. Se a carga HTTP falhar depois de um repouso válido, o resultado de repouso continua disponível; a interface explica que não foi possível avaliar o impacto sob carga.

## Borda de infraestrutura autorizada

O dono do produto autorizou exclusivamente um Cloudflare Worker gratuito e mínimo para `GET /v1/load`. Não haverá banco, analytics, catálogo remoto, SDK, armazenamento, autenticação, beacon ou outro endpoint nesta entrega.

`/v1/load` devolve um fluxo de bytes sem conteúdo de produto, com `Cache-Control: no-store`. O app cancela a transferência ao atingir 10 MB ou 15 segundos. A resposta não identifica jogo, pessoa, aparelho ou sessão.

O endpoint do piloto é `https://nolaggy-deep-check.buildealabs.workers.dev/v1/load`. Ele foi publicado sem bindings em 2026-09-08; a configuração de build fica isolada em infraestrutura para permitir substituição posterior sem alterar domínio ou interface.

## Composição e copy

Mantemos a composição canônica: introdução com explicação de repouso/carga e requisito de Wi-Fi; execução separada em duas fases; resultado com score de repouso e cartão de impacto sob carga; ações de detalhes e reteste. A tela não trata a carga como novo score nem como ping oficial do Fortnite.

O anel do resultado principal tem 160 pt, exatamente como no HTML canônico. Este registro resolve a divergência com a variante de 216 pt citada no design system: para esta entrega, a composição já desenhada prevalece e não será redesenhada.

PT-BR: “Vamos comparar sua rede em repouso e durante uso intenso. Leva cerca de 30 segundos e usa Wi-Fi.”

EN: “We’ll compare your network at rest and under heavy use. It takes about 30 seconds and uses Wi-Fi.”

## Responsáveis e aceite

- Iury: séries independentes, cálculo do impacto e vetores de teste.
- Rian: sessão iOS, Wi-Fi/ciclo de vida, transporte de carga e persistência final.
- Renan: paridade com o protótipo, estados indisponível/falha e acessibilidade/localização.
- Marco: escopo, promessa e integração.

O aceite exige testes de domínio e sessão, teste local do Worker, comparação interativa no simulador em PT-BR e inglês, e smoke em iPhone físico no Wi-Fi. Este último não é substituído pelo simulador.

## Evidência física registrada

Em 2026-09-08, em iPhone físico no Wi-Fi, um Deep Check concluiu com 30 respostas UDP válidas em repouso e 30 sob carga. O resultado final registrou score 95 (Excelente) em repouso, P50 de 14,55 ms, perda de 0% e impacto sob carga de +0,24 ms (P50 sob carga de 14,79 ms). O histórico local recebeu o snapshot `deep` com métricas agregadas de repouso, carga e impacto, sem amostras brutas.

Esta evidência valida a sessão, a carga HTTP e a persistência local no aparelho; não fecha por si só a inspeção visual, VoiceOver ou Reduzir Movimento.

## Regra de materialidade do impacto sob carga

Fica adotada a regra `deep-load-impact-v1`, de Iury, para classificar exclusivamente o impacto sob carga do piloto. Com as duas séries UDP válidas, calculamos o delta bruto `P50 carga - P50 repouso`, sem usar o valor arredondado exibido na tela. Delta inferior a `+20,0 ms` é **descritivo**: o app mostra a diferença, mas não afirma impacto material. Delta maior ou igual a `+20,0 ms` é **material** e pode receber essa descrição na interface.

Essa classificação não é um segundo score, não muda score, classe ou guardrails do repouso e não resume perda, jitter ou spikes sob carga como uma nova qualidade geral. Se a carga HTTP falhar ou a fase sob carga tiver menos de dez respostas UDP válidas, não há impacto nem classificação.

Cada resultado com impacto persiste o delta, `ruleVersion = deep-load-impact-v1` e a classificação calculada. Vetores DLI-001 a DLI-005 e critérios de aceitação estão na especificação técnica, seção 6.1. Qualquer alteração futura no corte ou na semântica exige uma nova versão da regra, vetores atualizados e revisão de Iury.
