# Cartão de Missão — reconciliação das decisões com o código

## Enquadramento

- **Problema da pessoa:** a squad não pode decidir, implementar ou liberar baseada em um registro que descreve contratos e estados diferentes do que está no repositório.
- **Resultado esperado observável:** `docs/DECISOES.md` distingue o que está apenas no fonte, o que está alinhado à decisão vigente e o que permanece em conflito ou sem evidência de runtime.
- **Fora de escopo:** alterar clientes, Worker, SDKs, segredos, console, builds, publicação, ou transformar implementação local em validação física.
- **Lane:** revisão documental de governança, com achado sistêmico bloqueante para qualquer mudança futura de Worker/privacidade.
- **Fonte de verdade:** `AGENTS.md`, `docs/DECISOES.md`, o fonte versionado em `main` no commit `c540cf45` e os testes locais aplicáveis.

## Donos e aceite

- **Aceite operacional:** Giam.
- **Estratégia e escalonamento:** Marco para Luiz.
- **Próxima frente para correção de contrato:** Camillo/Iury, antes de qualquer alteração no Worker ou no caminho Gemini.
- **Critério de aceite:** nenhuma linha afirma conformidade, aparelho, distribuição ou publicação sem prova; divergências de contrato ficam explícitas com próximo passo e dono.

## Evidência planejada

- inspeção dos repositórios de catálogo iOS/Android e do envelope assinado;
- inspeção das rotas efetivamente declaradas no Worker e dos clientes que as consomem;
- testes de contrato de catálogo e suites focadas, quando executáveis localmente;
- comparação com as Decisões 14, 23, 45, 61, 71 e 99.

## Risco principal

Tratar endpoints ou IA presentes no fonte como autorização vigente violaria custo zero, privacidade e o limite de infraestrutura. O registro deve expor o descompasso; a correção de código exige missão sistêmica posterior.
