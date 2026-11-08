# LagCheck — Decisão 41: separar vínculo do equipamento externo da rede observada no iPhone

**Status:** decidido pelo Dono do Produto; implementação em andamento

**Data:** 19 de setembro de 2026

**Responsáveis:** Luiz (produto), Marco (produto), Iury (rede), Rian (iOS), Renan (design)

**Revisa a terminologia de:** `docs/archive/decisoes/26-decisao-catalogo-console.md` e `docs/archive/decisoes/36-decisao-check-completo-wifi-e-rede-movel.md`.

---

## 1. Problema resolvido

Dois fatos diferentes vinham sendo chamados de `equipmentConnection`: o vínculo declarado do console/PC com a rede e a interface realmente usada pelo iPhone durante a medição. Eles não são intercambiáveis. Um console pode estar em Ethernet enquanto o iPhone que executa o teste está no Wi-Fi ou na rede móvel.

## 2. Modelo decidido

- `declaredExternalLink` é o vínculo informado para o equipamento externo: `wifi` ou `ethernet`. É opcional e só existe para console ou PC; não se aplica ao iPhone.
- `observedPhoneNetwork` é a interface observada no iPhone no começo da sessão: `wifi` ou `cellular`. Ela é um fato de medição, não uma escolha antecipada de tela.
- A sessão registra ambos no snapshot imutável, junto da versão `connectionFactsVersion`.
- O coordenador de medição só preenche `observedPhoneNetwork`; ele nunca altera `declaredExternalLink`.

## 3. Histórico e comparações

Snapshots anteriores a esta decisão podem não ter os dois fatos. Eles permanecem visíveis como registros legados, sem reinterpretação nem preenchimento inventado.

Um resultado legado, incompleto ou sem versão desses fatos não entra em média, tendência, comparação automática ou recomendação comparativa. Uma comparação só é elegível quando ambos os resultados têm respostas UDP válidas suficientes e coincidem em jogo, plataforma, região, versão da regra, vínculo externo declarado e rede observada no iPhone.

## 4. Interface e linguagem

Na tela do jogo, a seleção Wi-Fi/Ethernet descreve exclusivamente o equipamento externo e explica o escopo da estimativa. Trilha de medição, consentimento de dados, diagnóstico de faixa Wi-Fi, resultado e filtro de Histórico descrevem exclusivamente a rede observada no iPhone.

Quando o fato não foi registrado, a interface diz que a conexão não foi registrada; ela não assume Wi-Fi, Ethernet ou rede móvel.

## 5. Limites

Esta decisão não muda o contrato de score, não adiciona serviço, endpoint, permissão ou coleta nova e não transforma a medição do iPhone em ping real de console ou PC. A troca de rede continua descartando integralmente a sessão, conforme `docs/36`.

## 6. Aceite

1. Um check de console/PC preserva o vínculo externo declarado mesmo quando o iPhone observa outra interface.
2. Um check de iPhone não oferece nem persiste vínculo externo.
3. Histórico antigo continua legível, sem comparação indevida.
4. Histórico novo não compara Wi-Fi e rede móvel do iPhone, nem Wi-Fi e Ethernet declarados para o mesmo equipamento externo.
