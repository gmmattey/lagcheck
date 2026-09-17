# Nolaggy — decisão: seleção regional automática BR/EUA

**Status:** decisão, regra de domínio, integração ao coordenador/catálogo e UI implementadas em código; pendente somente a validação em iPhone físico listada nos gates ao final deste documento antes de release.

**Atualização de UX (2026-09-10):** a UI de confirmação/escolha manual no meio da jornada de medição (tela "Região sugerida" / "Mudar região") foi removida — a auditoria de UX apontou que ela adicionava uma tela e um segundo toque a toda medição sem valor de decisão real quando há um único candidato, o caso de todo o catálogo Debug hoje. A seleção agora é sempre automática ao tocar "Iniciar", sem tela intermediária. A escolha manual continua possível, mas como preferência persistida em Configurações (menu "Região de referência"), aplicada a toda sessão futura enquanto o candidato escolhido for válido para o contexto medido; se deixar de ser válido, a sessão cai para automático em vez de falhar. A regra `regional-selection-1` abaixo (pré-leitura, desempate, privacidade) não muda — só a superfície de onde a escolha manual é feita.
**Regra:** `regional-selection-1`  
**Responsável de domínio:** Iury

**Compatibilidade de catálogo:** o Debug publicado usa schema 1, no qual `primaryRegion` equivale a candidato único de prioridade zero. O schema 2 local adiciona `candidateRegionIDs` e `candidatePriorities`; ele só pode entrar em um envelope assinado de schema 2 e não altera o payload Debug vigente.

## Problema e limite da promessa

Uma localidade configurada no iPhone não revela por si só qual referência de rede está mais responsiva naquele instante. A pessoa pode viajar, usar VPN ou preferir deliberadamente outra referência. Por isso, o nolaggy não fixa uma região por idioma, país do aparelho, GPS ou IP.

A seleção automática escolhe somente a **região de referência da medição**. Ela não descobre, troca nem recomenda servidor do jogo e não transforma um beacon AWS em endpoint ou ping oficial de qualquer jogo. A precisão continua sendo a declarada no contexto assinado; no Debug v2 atual, `genericRegion` / `medium` / `regionalReference` para São Paulo.

## Escopo, snapshot e candidatos permitidos

1. No início de cada Quick Check ou Deep Check, o coordenador cria um snapshot imutável do catálogo cujo envelope, schema, validade e regras de negócio já foram validados.
2. A localidade do sistema apenas ordena os mercados publicados (`BR` e `US`). Ela não confirma o mercado e não decide a região.
3. Para jogo, plataforma e perfil selecionados, entram na pré-leitura somente os `candidateRegionIDs` do contexto `available` daquele mercado no snapshot. Cada candidato precisa referenciar região existente, com host, porta UDP, estratégia, confiança, `precisionKey` e prioridade declarados e coerentes.
4. A sessão nunca monta hostname, porta, região ou estratégia por código, IP, DNS descoberto, geolocalização, resultado anterior ou conteúdo não assinado. Uma atualização de catálogo no meio da sessão só vale na próxima.

O payload Debug v2 `debug-2026.09.08.2` tem somente `BR`/iPhone e um candidato: `sa-east-1`. Portanto, hoje não existe disputa automática entre regiões. Esta regra só passa a escolher entre candidatos depois de nova versão assinada incluir dois ou mais destinos no contexto.

## Pré-leitura UDP dentro da sessão

A pré-leitura antecede a janela que gera score e usa o mesmo protocolo UDP autenticável e correlacionável da medição. Não entra no cálculo de P50/P95, perda, jitter, spikes, score, histórico ou recomendação.

Para cada candidato são enviados três probes UDP, no máximo um por segundo, com timeout individual de 2 s. Um candidato é elegível somente com pelo menos duas respostas UDP válidas e correlacionadas. Em escolha automática, candidatos podem ser lidos em paralelo, sempre respeitando a cadência por candidato. Em escolha manual, a leitura ocorre apenas contra o candidato escolhido. Mudança de rede, segundo plano, cancelamento ou expiração do snapshot descarta pré-leitura e sessão inteira; não há reaproveitamento parcial.

## Escolha, desempate e override

Para cada candidato elegível, calcula-se o P50 das respostas válidas:

1. Se um candidato tiver P50 pelo menos 6 ms menor que todos os demais, ele vence.
2. Caso contrário, consideram-se os candidatos a até 5 ms do menor P50; vence o de maior número de respostas válidas.
3. Persistindo empate, vence a menor prioridade numérica declarada no catálogo.
4. Persistindo empate, vence o menor `regionID` em ordem lexicográfica.

O resultado registra `selectionRuleVersion`, `selectionMode` (`automatic` ou `manual`), região escolhida e versão de catálogo. As amostras brutas da pré-leitura não ficam no histórico.

A pessoa pode escolher qualquer candidato assinado em Configurações; a escolha não vira sugestão de servidor de jogo. Isso separa dois tipos de falha do candidato preferido:

- **Não é candidato deste contexto** (jogo/mercado/plataforma diferentes do que a preferência foi salva para representar): a sessão cai para escolha automática nesse candidato, sem perguntar de novo nem travar a medição por causa de uma preferência que ficou desatualizada.
- **É candidato válido do contexto, mas não respondeu o suficiente na pré-leitura** (falha real de rede): a sessão é inconclusiva; o app não volta silenciosamente para a escolha automática nesse caso, porque isso mascararia um problema real de rede como se fosse ausência de preferência.

## Falha e privacidade

Sem candidato elegível, ou se o contexto não existir, vencer ou deixar de validar, o estado é `inconclusive(noViableRegionalCandidate)`: sem score, classificação positiva, recomendação para jogar, HTTP ou ICMP como fallback. A interface explica que a rota regional de referência não pôde ser confirmada e oferece nova tentativa ou outro candidato publicado.

Não há GPS, permissão de localização, geocodificação, inferência por IP, armazenamento de coordenadas ou envio dessas informações ao Worker. A localidade do sistema é somente sinal local de ordenação; o Worker não recebe telemetria de probes.

## Evidência de rotas EUA e estado de catálogo

| Mercado candidato | Região AWS | Destino UDP documentado | Estratégia/confiança permitida hoje | Estado |
| --- | --- | --- | --- | --- |
| EUA | `us-east-1` — N. Virginia | `gamelift-ping.us-east-1.api.aws:7770` | `genericRegion` / `medium` / `regionalReference` | evidência de rota; fora do catálogo Debug |
| EUA | `us-east-2` — Ohio | `gamelift-ping.us-east-2.api.aws:7770` | `genericRegion` / `medium` / `regionalReference` | evidência de rota; fora do catálogo Debug |

A AWS documenta que os ping beacons são endpoints UDP fixos para medir latência até localidades de hosting e lista N. Virginia e Ohio com os destinos acima. Isso sustenta exclusivamente uma referência regional genérica; não há nesta decisão evidência de endpoint oficial, matchmaking ou ping de jogo.

Antes de promover qualquer rota EUA a `available`, é obrigatório inserir o contexto com `candidateRegionIDs`, incrementar schema/versão quando necessário, assinar envelope, validar regras de negócio e passar pelos gates abaixo. Até lá, `US` não fica testável por causa desta evidência.

Fontes primárias:

- [AWS GameLift Servers — UDP ping beacons](https://docs.aws.amazon.com/gameliftservers/latest/developerguide/reference-udp-ping-beacons.html)
- [AWS General Reference — endpoints e ping beacons GameLift](https://docs.aws.amazon.com/general/latest/gr/gamelift.html)

## Vetores e gates de aceite

| Vetor | Entrada | Resultado obrigatório |
| --- | --- | --- |
| Um candidato BR | `sa-east-1` válido, três respostas | escolhe `sa-east-1`; pré-leitura não altera score nem métricas finais. |
| Dois candidatos, diferença clara | P50 31 ms e 38 ms | escolhe 31 ms pela regra de 6 ms. |
| Faixa de empate | P50 31 ms e 35 ms; válidas 2 e 3 | escolhe o segundo pela maior contagem. |
| Empate de qualidade | mesmo P50 e contagem; prioridades 20 e 10 | escolhe prioridade 10. |
| Empate completo | mesmo P50, contagem e prioridade | escolhe menor `regionID` lexicográfico. |
| Resposta insuficiente | cada candidato com 0 ou 1 resposta válida | `inconclusive(noViableRegionalCandidate)`, sem score/fallback. |
| Override inválido | candidato fora do contexto/snapshot | recusa antes de UDP; não inicia sessão. |
| Override sem resposta | três probes sem duas respostas válidas | inconclusivo; não alterna automaticamente. |
| Envelope inválido ou trocado | assinatura/validade inválida ou catálogo novo | não usa candidatos; descarta sessão conforme o momento. |
| Caminho muda, segundo plano ou cancelamento | evento durante pré-leitura | descarta seleção e sessão, sem persistir resultado. |
| Privacidade | GPS/IP/localização precisa disponíveis | não são lidos nem enviados; localidade apenas ordena mercados publicados. |

Gates antes de implementação: revisão de Iury para regra, thresholds e vetores; revisão de Rian para contrato, coordenação de sessão e estados; revisão de Renan para cópia/composição do inconclusivo; testes puros de regra e contrato adversarial; validação em iPhone físico para UDP, mudança de caminho, segundo plano e cancelamento. A promoção de `US` exige também envelope assinado e validação física contra ambos os beacons, sem chamar o resultado de ping de jogo.
