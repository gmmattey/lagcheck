# Criativos da App Store — PT-BR

Data: 07/10/2026. Proposta de campanha para revisão de Luiz; não é decisão aprovada, publicação ou teste em execução.

## Conteúdo

### Entrega específica por posição (usar estes arquivos)

- **Cabeçalho:** `cabecalho-3840x1646.png` — Antes da ranked, confira sua conexão.
- **Resultado de busca:** `resultado-busca-1920x1280.png` — Teste sua conexão para jogar.

São duas composições próprias para posições diferentes, não variantes A/B entre si. A busca foi recomposta em 3:2 com mensagem direta; o cabeçalho, em 21:9. Arquivos PNG RGB opacos. Produção por image_gen e exportação dimensional por sips; os originais estão em `originals/cabecalho.png` e `originals/busca.png`. Houve ampliação dos originais para as dimensões finais, não geração nativa nessas resoluções. Texto e composição conferidos visualmente, dimensões e ausência de alpha verificadas. Ainda precisam de conferência na Prévia da Apple. Prompts em `prompts-por-posicao.md`.

### Propostas universais anteriores (preservadas)

- A: **Antes da ranked, confira sua conexão.**
- B: **Sua conexão está pronta para jogar?**
- Texto promocional sugerido: **Antes da partida, confira sua conexão. O LagCheck mede latência, estabilidade e perda de pacotes para ajudar você a decidir se vale jogar agora.**

As artes são criativos de campanha abstratos, não screenshots, medições ou prova de desempenho. A composição usa preto, grafite e roxo conforme a Decisão 66. Não contém personagens de jogos, métricas inventadas, promessa de reduzir ping ou garantia de desempenho. Os ativos oficiais da marca não foram redesenhados.

## Aplicação e formatos

O formato universal PNG de 5244 × 2950 px é aceito para cabeçalho e resultados de busca. Usar arquivos opacos, sem canal alpha. A existência de um arquivo compatível não comprova aprovação pela Apple. Conferir cortes e legibilidade na Prévia do App Store Connect antes de publicar. As novas posições aparecem no iOS/iPadOS 27 ou posterior; as screenshots continuam necessárias para outras apresentações.

## Experimento proposto

Hipótese: a mensagem específica sobre ranked gera mais conversão que a pergunta geral sobre jogar.

1. Revisar as duas peças e selecionar a composição base.
2. Se a página atual ainda não tiver cabeçalho, aplicar A como base e registrar a data; não confundir essa alteração inicial com resultado do teste de texto.
3. Criar um único tratamento B no Product Page Optimization, mudando apenas o cabeçalho. Manter o ativo de busca, screenshots, ícone e metadados iguais entre grupos.
4. Proposta de divisão: 50% controle A e 50% tratamento B na localização PT-BR. Conferir elegibilidade e estimativa de duração no painel antes de iniciar.
5. Acompanhar conversão, melhoria estimada, amostra e confiança reportadas pela Apple. Não escolher vencedor por variações dos primeiros dias. A duração depende do tráfego, com limite de 90 dias.
6. Depois, testar o ativo de busca separadamente. Se a geração das imagens introduzir diferenças visuais além do texto, considerar o teste como comparação de duas peças completas, não causalidade isolada da headline.

Sem acesso às métricas nesta entrega: nenhuma previsão de aumento de downloads ou prazo para significância foi feita. Nenhum upload, alteração na loja ou início de teste está incluído na geração local.

## Fontes oficiais consultadas

- [Formatos de criativos](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications)
- [Boas práticas e áreas seguras](https://developer.apple.com/app-store/asset-best-practices/)
- [Configuração dos tratamentos](https://developer.apple.com/help/app-store-connect/create-product-page-optimization-tests/configure-test-treatments)
- [Product Page Optimization](https://developer.apple.com/app-store/product-page-optimization/)

## Produção

Geração pelo recurso integrado image_gen. Prompts preservados em prompts.md. Revisão visual local não substitui a Prévia do App Store Connect nem a revisão da Apple.

### Arquivos entregues

| Arquivo | Uso | Dimensões |
| --- | --- | --- |
| `a-ranked-universal.png` | Cabeçalho ou busca, proposta A | 5244 × 2950 px |
| `b-jogar-universal.png` | Cabeçalho ou busca, proposta B | 5244 × 2950 px |
| `originals/a-ranked.png` | Original gerado A | 1672 × 941 px |
| `originals/b-jogar.png` | Original gerado B | 1672 × 941 px |

Texto promocional sugerido acima: **144 caracteres**.

As exportações universais foram ampliadas com `sips` a partir dos originais; não são geração nativa em 5K. O ajuste para o formato exato altera a proporção em menos de 0,05%. PNG RGB sem alpha confirmado por inspeção de metadados. Texto e composição revisados visualmente nas duas gerações. A edição B mantém a composição, mas diferenças sutis de geração podem existir; não foi comprovada igualdade pixel a pixel fora do texto.

Revisar nitidez e recorte na Prévia da Apple antes de usar. Não houve captura do app, validação em dispositivo, upload, aprovação ou publicação. Para a composição da loja, o ícone e o nome do app acompanham estes criativos; nenhum novo logotipo foi criado.
