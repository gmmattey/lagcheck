# Apple App Store — referência de ASO

Limites conhecidos (confirme no App Store Connect antes de afirmar como definitivo):

| Campo | Limite | Indexado na busca? | Notas |
|---|---|---|---|
| Nome do app | 30 car. | Sim (peso alto) | Marca + 1 termo forte. Sem preço/“grátis”/claims. |
| Subtítulo | 30 car. | Sim | Benefício + termo secundário; não repita palavras do nome. |
| Palavras-chave | 100 car. | Sim (oculto) | Separadas por vírgula, **sem espaços**; sem repetir termos do nome/subtítulo; singular/plural geralmente tratados juntos; sem nomes de concorrentes. |
| Texto promocional | 170 car. | Não | Editável sem nova versão; bom para campanhas. |
| Descrição | 4000 car. | Não (para busca) | Converte, não ranqueia. 1ª linha vale ouro (aparece antes do “mais”). |
| O que há de novo | 4000 car. | Não | Mostra manutenção; seja específico. |
| Screenshots | até 10 por tamanho | Sim, indiretamente via conversão | Primeiras 2–3 aparecem nos resultados de busca. |
| Vídeo de prévia | até 3 | — | Autoplay mudo: a mensagem tem que funcionar sem som. |

Também existem: **nomes de compras no app/assinaturas** (podem aparecer e ser indexados), **categorias** (primária pesa mais), **Product Page Optimization** (testes A/B de ícone, prints e vídeo, até 3 tratamentos) e **Custom Product Pages** (páginas por campanha/público, com URL própria). Verifique disponibilidade e regras atuais.

## Como montar
1. **Nome** = marca + palavra-chave de maior intenção (“Marca: Comparar Celulares”). Teste 2 variações.
2. **Subtítulo** = promessa concreta + termo que não está no nome.
3. **Campo de palavras-chave**: liste candidatos → remova o que já está no nome/subtítulo → remova palavras genéricas (“app”, “grátis”) → priorize intenção de busca real → preencha até 100 car. Ordem não é fator conhecido; vírgula sem espaço economiza caracteres.
4. **Descrição**: 1ª linha = proposta de valor; depois 3–5 blocos de benefícios com bullets curtos; prova real (prêmios/imprensa **só se verdadeiros**); chamada final. Sem repetir palavra-chave artificialmente (não ajuda e piora conversão).
5. **Screenshots**: 1ª = promessa principal; 2ª–3ª = funcionalidades que decidem; legendas curtas e legíveis em miniatura; mostrar a interface real (regra de revisão). Local: legenda em pt-BR para o Brasil.
6. **Ícone**: simples, legível pequeno, distinto dos concorrentes na busca.
7. **Avaliações**: use `SKStoreReviewController`/pedido nativo no momento certo (após sucesso do usuário), nunca incentivando nota positiva. Responda reviews públicos.

## Conformidade (App Store Review Guidelines, seção 2.3 – Metadados precisos)
- Metadados devem refletir o app real; screenshots devem mostrar o app em uso, não só arte de marketing.
- Proibido: nomes de outros apps/marcas sem autorização, termos irrelevantes ou enganosos nas palavras-chave, preços ou promoções no nome/subtítulo, referências a outras plataformas (ex.: “também no Android”) em metadados.
- Classificação etária e categoria corretas; política de privacidade (URL) e “rótulos de privacidade” coerentes com o que o app coleta.
Confirme o texto atual das diretrizes antes de citar números de seção.
