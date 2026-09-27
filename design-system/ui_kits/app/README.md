# Kit aplicado LagCheck

## Estrutura

- `index.html` compõe Home, Resultado e Catálogo com navegação lateral.
- `components.html` é uma folha de anatomia para ações, sheet e estados.
- `components/kit-components.css` concentra estilos reutilizáveis de chip, CTA, evidência e linha de jogo.
- `components/kit-shell.js` monta o chip de telemetria no kit aplicado.

## Uso

Importe primeiro `../../colors_and_type.css`, depois `components/kit-components.css`. Carregue `components/kit-shell.js` quando a superfície precisar montar o chip de telemetria com dados observados. Reuse a marcação de `index.html` para compor a tela, mantendo uma CTA principal e deixando a evidência abaixo do veredito.

## Notas de design e origem

O kit deriva de `lagcheck-modo-pronto.html` e `lagcheck-selecao-de-jogo.html`. Ele mantém fundo profundo, bordas discretas, tipo mono para contexto técnico e roxo para ação. Wordmark e capas vêm de `../../assets/`; não trocar por arte oficial de jogo. Estados inconclusivos continuam neutros e explicativos.
