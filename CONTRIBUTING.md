# Como contribuir

Obrigado pelo interesse. O repositório não tem licença aberta (veja o [aviso de uso](NOTICE.md)), então o caminho é combinar antes.

## Bugs e ideias

Abra uma [issue](https://github.com/gmmattey/lagcheck/issues/new/choose). Diga o aparelho, a versão do sistema e o que você viu. Não cole segredos, chaves nem dados pessoais.

## Código

1. **Abra uma issue antes** descrevendo a mudança. Sem alinhamento, o PR pode ser recusado.
2. Ao enviar código, você concorda que o dono do projeto pode usá-lo no LagCheck sob os mesmos termos do restante do repositório.
3. Mudanças de score, veredito, thresholds ou catálogo precisam de versão da regra e vetores de teste.
4. Rode os testes antes de abrir o PR: `Cmd + U` no Xcode, `./gradlew test` em `android/`, `npm test` em `worker/`.
5. Siga a voz do produto em [`docs/07-voz-do-produto.md`](docs/07-voz-do-produto.md): direto, calmo e sem promessa de "zero lag".

## O que não entra

- Serviço pago, SDK novo ou infraestrutura nova sem decisão registrada em [`docs/DECISOES.md`](docs/DECISOES.md).
- Capas, logos ou artes de jogos de terceiros.
- Anúncio fora das telas já definidas.
