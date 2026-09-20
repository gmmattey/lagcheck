# LagCheck — Decisão 43: jornada única de Deep Check

**Status:** decidido pelo Dono do Produto; implementação em andamento

**Data:** 19 de setembro de 2026

**Responsáveis:** Luiz (produto), Marco (produto), Renan (design), Rian (iOS), Iury (rede)

**Revisa:** a jornada de Quick Check descrita em `docs/01`, `docs/10`, `docs/22`, `docs/36` e `docs/42`.

---

## 1. Decisão

O LagCheck não oferece Quick Check. Há uma única jornada de medição visível: a pessoa escolhe um jogo, escolhe a plataforma e o vínculo externo quando aplicável e inicia o **Deep Check**.

O Deep Check mede a rota em repouso e, após o consentimento obrigatório em rede móvel, também sob carga. O resultado é válido somente quando a evidência UDP atender às regras vigentes; caso contrário, é inconclusivo e não recebe score.

## 2. Jornada

1. A Home convida a escolher um jogo ou abre o jogo da última medição para um novo Deep Check.
2. A tela do jogo confirma plataforma e, para console ou PC, o vínculo declarado do equipamento externo.
3. A pessoa inicia o Deep Check.
4. Em rede móvel, ela consente com o teto de dados antes de qualquer probe UDP ou transferência sob carga, ou cancela. Não há medição alternativa reduzida, resultado, histórico ou reteste parcial.
5. O resultado, o histórico e qualquer reteste preservam essa mesma jornada.

## 3. Limites de implementação

`QuickCheckPlan` e outros nomes internos podem continuar existindo enquanto representam somente a coleta UDP reutilizada pelo Deep Check. Eles não podem aparecer em copy, acessibilidade, identificadores de teste, navegação, telas, histórico ou documentação de produto como uma funcionalidade separada.

## 4. Aceite

1. Nenhuma ação visível inicia ou oferece Quick Check.
2. Toda seleção válida de jogo/plataforma chega ao Deep Check, sem resultado intermediário.
3. Em rede móvel, recusar o consentimento cancela a jornada; nenhum probe UDP ou transferência sob carga é iniciado e não há resultado ou histórico.
4. Testes de interface verificam Deep Check a partir da seleção do jogo e não dependem de identificadores de Quick Check.
