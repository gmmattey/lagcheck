# LagCheck — Decisão 39: seleção automática de rotas próprias elegíveis

**Status:** decidido pelo Dono do Produto; em implementação
**Data:** 19 de setembro de 2026
**Autores / revisores necessários:** Luiz (produto), Marco (produto), Iury (rede), Rian (iOS)

**Complementa e prevalece para seleção de rota própria sobre:** `docs/archive/decisoes/16-decisao-selecao-regional-automatica.md`, `docs/archive/decisoes/29-decisao-infraestrutura-medicao-custo-zero.md`, `docs/archive/decisoes/37-decisao-catalogo-remoto-v3-rotas-prioritarias.md` e `docs/archive/decisoes/38-matriz-viabilizacao-rotas-proprias.md`.

---

## 1. Decisão

Depois de a pessoa escolher jogo e plataforma, o LagCheck escolhe automaticamente a melhor rota própria **entre candidatos explícitos, assinados e autorizados** para aquele contexto. A pessoa não precisa informar IP, porta ou escolher servidor para o uso normal.

O app não faz varredura, não consulta listas abertas em tempo real, não deriva IP de tráfego do jogo e não aceita um host arbitrário como parte da seleção automática. A automação decide somente entre candidatos já presentes no snapshot assinado do catálogo e cuja resposta seja validada pelo driver que já existe no binário.

Nesta decisão, o único driver próprio elegível é **Steam A2S_INFO**, para Counter-Strike 2 comunitário e Rust, após cada candidato ser homologado. RakNet/Bedrock, Palworld e qualquer outro protocolo permanecem `discovery`: podem existir na matriz de viabilização, mas não entram na seleção nem são anunciados como rota própria ativa até terem codec, identidade e validação física aprovados.

Se nenhum candidato próprio válido sobreviver à pré-leitura, o contexto mede o beacon AWS da região de referência. Isso é um fallback automático, identificado como `região de referência`; não é o servidor do jogo.

## 2. Escopo e não-escopo

**Inclui:** seleção silenciosa, validação A2S antes da medição, desempate determinístico, auditoria da decisão e fallback AWS para todos os contextos.

**Não inclui:** descobrir servidores na internet, acessar listas Steam fora do catálogo, escanear faixas de IP/portas, acompanhar a partida em execução, inferir o destino do matchmaking, nem garantir que o servidor selecionado será aquele em que a pessoa jogará.

A escolha manual de servidor não é parte desta jornada. Ela fica como exceção futura para comunidades que queiram medir um servidor específico, mediante decisão própria de produto, limite antiabuso e validação do mesmo protocolo. Ela não substitui a automação.

## 3. Contrato remoto: candidatos declarativos

O catálogo v3 passa a poder declarar uma coleção limitada de candidatos em uma rota própria. O payload fornece dados; ele nunca fornece código, URL de descoberta, intervalo de portas ou instrução de protocolo nova.

```json
{
  "id": "cs2-community-br",
  "kind": "gameOwned",
  "state": "active",
  "protocol": "steamA2S",
  "selection": {
    "mode": "automaticValidatedCandidates",
    "maxCandidates": 3,
    "candidates": [
      {
        "id": "cs2-sp-community-01",
        "host": "cs2.example.org",
        "queryPort": 27015,
        "region": "sa-east-1",
        "priority": 10,
        "expectedIdentity": {
          "appID": 730,
          "gameDirectory": "csgo",
          "namePrefix": "SP Community"
        },
        "operatorEvidenceURL": "https://operator.example.org/lagcheck"
      }
    ]
  }
}
```

### 3.1 Regras de validação do catálogo

Um candidato só é aceito se:

- pertence a uma rota `gameOwned` em estado `active`, com `protocol: steamA2S`;
- tem `id` único, FQDN ou IP literal válido, `queryPort` entre 1 e 65535, região, prioridade e evidência pública do operador;
- tem identidade esperada compatível com o produto: ao menos `appID` e `gameDirectory`; `namePrefix`, quando publicado, é uma restrição adicional, nunca a única prova. Ele é uma string UTF-8 normalizada de no máximo 80 caracteres, não uma expressão regular;
- não repete host/porta em candidatos do mesmo contexto;
- cabe no teto fixo de candidatos do binário (`maxCandidates`), que nesta decisão é **3**. Um envelope com mais candidatos é inválido, não truncado;
- não declara `resolver`, URL, lista externa, CIDR, curinga de host ou intervalo de portas.

O validador recusa o contexto inteiro de rota própria que desrespeitar qualquer regra. O fallback AWS válido do mesmo jogo/plataforma continua elegível.

### 3.2 Estados do candidato

| Estado | Quem pode conter | Efeito na sessão |
| --- | --- | --- |
| `eligible` | candidato de rota `active` com A2S homologado | entra na pré-leitura automática. |
| `rejectedIdentity` | qualquer candidato respondente | resposta não corresponde à identidade esperada; não mede e registra o motivo. |
| `unreachable` | candidato elegível | não retornou resposta UDP válida dentro do limite; não mede. |
| `temporarilySuppressed` | candidato antes elegível | removido da tentativa nesta sessão após falha; não altera o catálogo. |
| `selected` | um único candidato validado | torna-se o alvo imutável da medição. |
| `notSupported` | protocolo ainda sem driver homologado | nunca é materializado como candidato de sessão. |

Esses são estados efêmeros da sessão, não alterações que o app possa escrever no catálogo remoto. A curadoria é a única responsável por promover, retirar ou marcar uma rota como indisponível no envelope seguinte.

## 4. Algoritmo de seleção automática

1. Abrir o snapshot assinado e validado para jogo, plataforma e mercado/região já resolvidos pelas regras vigentes.
2. Ordenar candidatos `eligible` por `priority` crescente e `id` crescente como desempate. Nunca ordenar por IP, geolocalização ou resultado de sessão anterior.
3. Tentar no máximo três candidatos, sem paralelismo, com uma única consulta de identidade A2S por candidato. A ordem e os destinos não aparecem na UI.
4. Para cada candidato, executar A2S_INFO com challenge quando solicitado. Só é válido `S2A_INFO` íntegro que corresponda ao `appID` e `gameDirectory` esperados; se houver `namePrefix`, o nome normalizado também deve começar por ele. Pacote malformado, fragmentado não suportado, challenge inválido ou identidade divergente é rejeição, não amostra de latência.
5. Para todos os candidatos que passaram a identidade, executar a pré-leitura UDP curta da política de rede vigente. Sem amostras válidas suficientes, o candidato é `unreachable`.
6. Escolher o candidato com a menor mediana válida da pré-leitura; empate usa `priority`, depois `id`. A medição formal usa apenas esse alvo e o challenge obtido/refeito conforme o protocolo.
7. Se não houver candidato selecionado, resolver a rota AWS de referência pelo fluxo regional já aprovado. Se ela também não produzir UDP válido suficiente, o resultado é **inconclusivo**, sem score e sem troca para HTTP/ICMP.

O catálogo não controla quantidade de probes, timeouts, fórmula, limiar de aceitação nem codec. Esses parâmetros ficam versionados e testados no app, sob revisão de Iury.

## 5. Contrato específico do A2S

- A porta usada é sempre `queryPort` declarada; `27015` não é pressuposta.
- O challenge A2S é obtido e reutilizado somente dentro da sessão. Um novo challenge solicitado pela resposta é aceito; token nunca é persistido ou compartilhado.
- RTT, jitter e perda da rota dedicada só consideram respostas A2S_INFO válidas da medição formal, conforme a política de aceitação. A consulta de identidade e a pré-leitura não são score.
- Uma resposta que diga ser outro jogo, outro diretório ou não cumpra o contrato é evidência de que o candidato não serve ao contexto, mesmo que responda rápido.
- CS2 comunitário e Rust só podem ser publicados como `active` depois de homologação por candidato em iPhone físico, com evidência do operador e revisão de Iury. Isso não os representa como matchmaking oficial da Valve ou Facepunch.

## 6. RakNet/Bedrock e demais protocolos

Minecraft Bedrock/RakNet não participa deste algoritmo nesta versão. A intenção de produto é idêntica — candidatos explícitos e autorizados, validados automaticamente —, mas a implementação depende de um codec Bedrock/RakNet isolado, contrato de identidade contra BDS e homologação em iPhone físico.

Palworld não é tratado como A2S por associação. Qualquer driver futuro exige contrato observado em servidor próprio/autorizado, testes puros de codec, limites de tráfego e validação de identidade antes de aparecer no enum assinado de protocolos. Jogos com matchmaking fechado continuam exigindo API, beacon ou autorização do publisher; enquanto isso, seguem no fallback AWS.

## 7. Registro e auditabilidade

O resultado e o histórico precisam guardar o snapshot necessário para explicar a rota, sem persistir challenge nem dados desnecessários:

| Campo | Conteúdo |
| --- | --- |
| `catalogVersion`, `routeID`, `candidateID` | qual publicação e qual candidato decidiram a sessão. |
| `routeKind`, `protocol`, `region` | natureza e contexto da rota efetivamente medida. |
| `host`, `queryPort` | destino efetivo, visível apenas nos detalhes técnicos já previstos. |
| `selectionRuleVersion` | nesta decisão, `owned-route-selection-1`. |
| `candidateOutcomes` | IDs e motivo enum (`rejectedIdentity`, `unreachable`, `notAttempted`), sem payload A2S completo. |
| `fallbackReason` | ausência de candidato válido, quando a rota AWS vencer. |

A UI comunica somente o resultado correto: `servidor dedicado` se uma rota A2S foi selecionada, ou `região de referência` se o fallback AWS foi usado. Não expõe ranking, endereço, motivos internos de cada candidato ou uma promessa de servidor da próxima partida.

## 8. Vetores de teste e gates

| Caso | Entrada | Resultado esperado |
| --- | --- | --- |
| candidato A2S válido | AppID, diretório e nome atendem; pré-leitura suficiente | seleciona a rota própria e guarda `candidateID`. |
| resposta de outro jogo | A2S responde, mas AppID ou diretório diverge | `rejectedIdentity`; não entra na medição nem no score. |
| challenge renovado | servidor devolve novo `S2C_CHALLENGE` durante medição | atualiza token na sessão e só aceita INFO válido posterior. |
| candidato sem UDP | timeout ou pacote inválido | tenta o próximo, sem usar HTTP/ICMP. |
| dois candidatos válidos | medianas distintas | menor mediana vence; empate respeita prioridade e ID. |
| nenhum próprio válido | todos rejeitados ou inacessíveis; AWS válida | mede AWS com `fallbackReason`, rotulada como referência. |
| nenhum destino válido | próprios e AWS sem UDP suficiente | `inconclusive`, sem score. |
| envelope abusivo | CIDR, intervalo de portas, URL de resolver, quarto candidato ou protocolo desconhecido | catálogo/rota própria é rejeitado; não abre socket para o valor. |
| Bedrock/RakNet pendente | candidato declarado com protocolo ainda não homologado | `notSupported`; não participa, AWS permanece. |

Antes de publicar candidato `active`: testes unitários do parser A2S e do resolvedor; vetores acima; teste em simulador para fluxo e persistência; teste em iPhone físico para handshake, medição e fallback; revisão de Iury; envelope Ed25519 assinado. Nenhum desses gates é substituído pela mera disponibilidade do servidor.

## 9. Critérios de aceite

1. Para CS2 comunitário e Rust, a pessoa inicia uma medição sem escolher servidor; o app só considera até três candidatos autorizados do catálogo assinado.
2. Uma identidade A2S incompatível jamais gera score de rota própria.
3. AWS é usado automaticamente somente quando não há rota própria válida e aparece como referência regional.
4. O mesmo snapshot e os mesmos dados de pré-leitura produzem a mesma escolha, inclusive nos empates.
5. Nenhum protocolo não homologado, endpoint privado ou resultado de descoberta irrestrita entra em produção.
