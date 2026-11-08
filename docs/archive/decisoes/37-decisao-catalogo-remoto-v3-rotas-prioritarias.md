# LagCheck — Decisão 37: Catálogo remoto v3 com rotas prioritárias e fallback AWS

**Status:** decidido pelo Dono do Produto; em implementação

**Data:** 19 de setembro de 2026

**Autores / revisores necessários:** Luiz (produto), Marco (produto), Iury (rede), Rian (iOS), Renan (design)

**Complementa:** `docs/archive/decisoes/14-decisao-catalogo-remoto-debug.md`, `docs/archive/decisoes/18-decisao-identidade-visual-neutra-de-jogos.md`, `docs/archive/decisoes/29-decisao-infraestrutura-medicao-custo-zero.md`, `docs/archive/decisoes/31-decisao-catalogo-editorial-notas-requisitos.md` e `docs/archive/decisoes/36-decisao-check-completo-wifi-e-rede-movel.md`.

---

## 1. Decisão

O catálogo remoto passa a ser a fonte assinada de conteúdo e de roteamento para todos os jogos. Ele deve permitir adicionar ou atualizar, sem nova versão do app, o produto correto, plataformas, arte editorial criada para o LagCheck, avaliação com fonte, perfil de thresholds já suportado e a política de destinos de medição.

Todo jogo do catálogo é testável. Para cada combinação jogo/plataforma, a resolução segue esta ordem:

1. **Rota própria:** servidor, beacon ou mecanismo oficialmente documentado para aquele jogo, ou servidor dedicado que o próprio jogador escolheu.
2. **Fallback AWS:** beacon GameLift da região de referência definida para o mercado ou selecionada pela pessoa, quando a rota própria ainda não está ativa, está temporariamente indisponível ou não existe para aquele produto.

AWS é um fallback válido de qualidade de rota regional; não pode ser chamado de servidor daquele jogo. Uma pendência de rota própria não bloqueia o teste nem encerra a investigação: ela continua visível no registro operacional com responsável, evidência faltante e data de revisão.

## 2. Conteúdo obrigatório do schema v3

O envelope assinado deve conter apenas dados; codecs, limites de aceitação e fórmulas continuam no binário iOS, em versões conhecidas e testadas.

```json
{
  "schemaVersion": 3,
  "games": [{
    "id": "cs2",
    "artwork": {
      "kind": "lagcheckEditorial",
      "asset": "games/cs2-v1.webp",
      "sha256": "..."
    },
    "platforms": [{
      "id": "pc",
      "thresholdProfile": "fpsCompetitive-v1",
      "routes": [
        {
          "id": "community-server",
          "priority": 1,
          "kind": "playerSelectedDedicated",
          "state": "discovery",
          "protocol": "steamA2S",
          "resolver": "validatedServerSelection",
          "evidence": [{ "url": "https://partner.steamgames.com/doc/api/isteammatchmakingservers" }]
        },
        {
          "id": "aws-sa-east-1",
          "priority": 99,
          "kind": "awsFallback",
          "state": "active",
          "protocol": "gameLiftPing",
          "region": "sa-east-1"
        }
      ]
    }]
  }]
}
```

Regras inegociáveis:

- `artwork.kind` só aceita `lagcheckEditorial`; é arte original do app inspirada no universo do jogo, nunca capa, logo, personagem ou asset licenciado de terceiro.
- `thresholdProfile` referencia uma versão já aceita pelo domínio. Um perfil novo exige release iOS, revisão de Iury e vetores de teste; ajustar a seleção de um perfil existente não exige.
- Uma rota `official` ou `playerSelectedDedicated` só pode passar a `active` após teste UDP real, validação de identidade da resposta e revisão de Iury.
- Rota dinâmica guarda o método de descoberta, não uma lista de IPs colhidos sem autorização.
- O resultado e o histórico guardam `routeID`, `routeKind`, host/porta efetivamente usados, protocolo, região, versão do catálogo e perfil de threshold. Se cair no fallback, a UI diz explicitamente `São Paulo · região de referência`.

## 3. Estados da rota própria

| Estado | Significado | Comportamento de produto |
| --- | --- | --- |
| `active` | Destino e protocolo foram validados em iPhone físico e a evidência segue válida. | Medir primeiro nesta rota. AWS continua como contingência. |
| `discovery` | Há mecanismo legítimo para descobrir/selecionar o destino, mas ainda falta implementar ou homologar. | Usar AWS e manter a tarefa de viabilização aberta. |
| `publisherAuthorizationRequired` | O destino de matchmaking é privado; é preciso API, credencial de título ou autorização do publisher. | Usar AWS; não inferir host por tráfego, DNS ou engenharia reversa. |
| `temporarilyUnavailable` | Uma rota antes ativa falhou no monitoramento ou expirou. | Usar AWS e abrir incidente para a rota própria. |

`unavailable` não é estado permitido para um jogo: cada item tem, no mínimo, um fallback AWS ativo.

## 4. Operação do catálogo

1. Curadoria atualiza o conteúdo em fonte versionada: jogo, arte editorial, plataformas, avaliação, thresholds e rotas.
2. O validador recusa IDs repetidos, plataforma incompatível, arte sem hash, rating sem URL/data, profile desconhecido, rota própria sem evidência ou fallback AWS inválido.
3. Uma etapa externa de assinatura Ed25519 assina o envelope. A chave privada não entra em repositório, Worker ou app.
4. O Worker autorizado entrega o catálogo assinado e os assets editoriais validados. Atualizar o catálogo não requer atualizar o app; publicar um novo driver/protocolo, sim.
5. Antes de promover uma rota própria, a equipe registra captura de teste, validação de identidade, região, taxa de amostragem e data de revisão na matriz operacional.

## 5. Limites da promessa

Uma rota própria só autoriza falar em medição daquele servidor ou infraestrutura quando o protocolo responde e a identidade foi confirmada. Um beacon AWS mede somente a rota regional de referência. ICMP e HTTP servem, no máximo, para investigação humana; não alimentam score, perda ou recomendação do LagCheck.

## 6. Critérios de aceite

1. Um novo jogo com arte editorial, plataformas, rating, thresholds existentes e fallback AWS aparece após atualizar o catálogo assinado, sem nova versão do app.
2. Todo contexto resolve pelo menos o fallback AWS.
3. Uma rota própria ativa vence o fallback e deixa rastro auditável no resultado e histórico.
4. Rota privada pendente mostra AWS como referência, mas permanece na matriz com ação objetiva e próxima revisão.
5. Nenhum payload remoto executa código ou cria um protocolo desconhecido no iPhone.
