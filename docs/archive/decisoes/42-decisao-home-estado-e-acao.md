# LagCheck — Decisão 42: Home de estado e ação

**Status:** decidido pelo Dono do Produto; implementação em andamento

**Data:** 19 de setembro de 2026

**Responsáveis:** Luiz (produto), Marco (produto), Renan (design), Rian (iOS), Iury (rede)

**Revisa para a Home:** a composição de Hero Carousel e Shelf de `docs/24` e aplica a direção de simplicidade de `docs/21`.

---

## 1. Decisão

A Home responde primeiro à pergunta “posso jogar agora?”. Ela não é uma vitrine de catálogo.

O primeiro bloco da tela é único e representa o estado mais relevante da pessoa:

- medição válida e recente: conclusão, jogo/plataforma, horário e ação “Testar de novo”;
- medição antiga ou inconclusiva: orientação neutra para fazer uma nova medição, sem reapresentar score como atual;
- nenhuma medição: convite direto para escolher um jogo e iniciar o primeiro check.

Para a Home, “recente” significa uma medição concluída há no máximo 24 horas, com `p50Milliseconds` presente, data não futura e pelo menos 10 respostas UDP válidas. Esse limite só determina a apresentação do estado atual; não reescreve nem descarta o Histórico.

## 2. Continuação da tela

Depois do estado, a Home mostra uma lista curta de jogos, priorizando o último jogo quando houver. A pessoa pode abrir a aba Jogos por “Ver todos os jogos”. Histórico aparece somente como link contextual junto de uma medição existente; ele não disputa atenção como um card independente.

Não entram na Home Hero Carousel, prateleiras horizontais, pôsteres grandes, busca expansível, filtros de categoria ou mais de um card de decisão concorrendo na primeira dobra.

## 3. Rigor da evidência

Score, conclusão positiva e CTA de reteste só usam uma entrada concluída com evidência UDP válida. Menos de 10 respostas, inclusive de 1 a 9, é inconclusivo. A Home reflete a tentativa mais recente do mesmo escopo; ela não promove uma medição válida antiga se a tentativa posterior foi inconclusiva. Uma entrada inconclusiva, incompleta ou sem dados atuais não é promovida a sinal de que a pessoa pode jogar.

O recheck recria o contexto de jogo com mercado, plataforma e vínculo externo declarado da entrada, mas resolve novamente região e rota no catálogo atual. Ele não reaproveita endpoint, score ou rota históricos. Escolher outro jogo passa pela aba Jogos.

## 4. Limites

Esta decisão não altera catálogo, critérios de score, regras de validade de medição, navegação de tabs, serviços, endpoints ou arte do catálogo. Ela altera exclusivamente a hierarquia e os estados apresentados pela Home.

## 5. Aceite

1. Cada estado da Home tem uma única ação primária compreensível.
2. Uma medição inconclusiva não exibe score nem linguagem positiva.
3. Não há busca, filtro, shelf ou hero de catálogo na Home.
4. A lista curta encaminha claramente para Jogos e o acesso ao Histórico é contextual.
5. Todos os controles mantêm alvo mínimo de 44 pt, Dynamic Type e rótulos de VoiceOver.
