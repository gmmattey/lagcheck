# Assets editoriais do catálogo

As imagens em `games/` são artes editoriais próprias do LagCheck. Elas não são
capas, logos, personagens, cenários, interfaces, fan art nem imagens obtidas de
publishers ou lojas. O catálogo deve referenciá-las pelo manifesto
`../artwork-manifest.json`, incluindo hash e dimensão.

As artes de `rainbow-six-mobile.png` e `rocket-league-sideswipe.png` foram
criadas como composições editoriais abstratas originais: a primeira prioriza
uma rota tática e a segunda uma arena cinética. Elas não representam cenas,
personagens, objetos, logos ou interfaces das franquias.

## Expansão de 3 de outubro de 2026 (Decisão 70)

`dead-by-daylight.png`, `for-honor.png`, `borderlands-3.png` e `new-world.png`
são novas artes geradas pela ferramenta integrada de imagens, sem importação de
materiais oficiais. Estão prontas para revisão (`ready`) no manifesto. O payload
`../catalog-v3.candidate.json` permanece não assinado e não é servido pelo Worker.
Para reconstruir o candidato e as cópias nativas: `node worker/scripts/prepare-catalog-expansion.mjs`
a partir da raiz. Não altera o envelope vigente.

Prompts: composição cinematográfica horizontal, protagonista original à direita,
cenário legível em miniatura, sem texto, logos, HUD ou personagens reconhecíveis.
- Dead by Daylight: sobrevivente original com lanterna junto a gerador quebrado,
  floresta noturna com névoa azul e silhueta ameaçadora distante; sem gore.
- For Honor: cavaleiro original em ponte de fortaleza sob chuva, silhuetas de
  samurai e viking, aço e luz quente de tochas.
- Borderlands 3: explorador original de ficção científica em cânion alienígena,
  estruturas industriais, traço cel-shaded, ocre e teal.
- New World: explorador original com armadura histórica em ilha de fantasia,
  ruínas, floresta e névoa mágica turquesa ao nascer do sol.
