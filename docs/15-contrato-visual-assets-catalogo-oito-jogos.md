# Contrato visual e de assets — capas do catálogo de oito jogos

**Data:** 9 de setembro de 2026  
**Responsável:** Renan  
**Estado:** substituído para a V1 pela [Decisão de identidade visual neutra dos jogos](./18-decisao-identidade-visual-neutra-de-jogos.md)

## Propósito e limite de escopo

Este documento registra o contrato de artes licenciadas que não será adotado na V1. Ele não autoriza baixar, copiar, gerar, editar, publicar ou embutir imagens. A referência operacional atual é a identidade neutra definida na decisão 18.

Uma arte aprovada não torna seu jogo testável. Elegibilidade de jogo, mercado, plataforma, região, destino, estratégia e confiança continua exclusivamente no catálogo validado e nas decisões de Marco e Iury. O catálogo Debug v2 publicado contém os oito contextos BR/iPhone; ainda assim, a interface só expõe os contextos que o repositório validado entregar como disponíveis.

## Variantes, proporções e recorte

Cada jogo precisa de duas artes finais, sem texto promocional, preço, rating, logo do Nolaggy, selo de score ou composição que dependa de idioma:

| Variante | Uso | Proporção e entrega | Recorte seguro |
| --- | --- | --- | --- |
| `cover-3x4` | `GameTile.grid`, carrossel de recentes e busca | 3:4, WebP sem transparência, 780 × 1040 px | Assunto principal no centro de 70% da área; não colocar rosto, logo essencial ou informação necessária nos 10% externos. |
| `context-banner-3x1` | topo da seleção de contexto | 3:1, WebP sem transparência, 1200 × 400 px | Assunto principal no centro de 76% da largura e 70% da altura; a composição deve sobreviver à redução para 120 pt de altura. |

Essas dimensões são fontes de entrega, não tamanhos de renderização. A interface preserva os tokens atuais: capa 3:4 com raio `avatarOrGameArt` e grid de no mínimo 104 pt; banner no raio `cardLarge`. Não usar estiramento, `aspectFit` com faixas vazias, crop dinâmico que ignore o ponto focal, filtro de cor, blur ou recolorimento para “unificar” as capas. Se o material de origem não permitir recorte seguro, aprovar uma variante editorial própria com a mesma licença antes de publicar.

## Schema de metadados de imagem

O catálogo assinado referencia somente uma arte já aprovada por `assetID` e revisão imutável. A UI nunca usa URL, nome, alt ou licença recebidos de fonte não validada. O contrato abaixo é o mínimo; os valores de origem/licença pertencem ao manifesto de assets versionado e auditável, não precisam aparecer na interface.

```json
{
  "artwork": {
    "assetID": "fortnite",
    "revision": "2026-09-09.1",
    "cover": {
      "variant": "cover-3x4",
      "url": "https://<origem-aprovada>/games/fortnite/cover-3x4-2026-09-09.1.webp",
      "sha256": "<hash-hex-de-64-caracteres>",
      "width": 780,
      "height": 1040,
      "mimeType": "image/webp",
      "focalPoint": { "x": 0.50, "y": 0.45 }
    },
    "contextBanner": {
      "variant": "context-banner-3x1",
      "url": "https://<origem-aprovada>/games/fortnite/context-banner-3x1-2026-09-09.1.webp",
      "sha256": "<hash-hex-de-64-caracteres>",
      "width": 1200,
      "height": 400,
      "mimeType": "image/webp",
      "focalPoint": { "x": 0.50, "y": 0.45 }
    },
    "sourceRecordID": "GAMEART-FORTNITE-001"
  }
}
```

Regras de schema:

- `assetID` é minúsculo, estável e igual ao ID canônico do jogo; não contém nome localizado, URL ou versão.
- `revision`, URLs, dimensões, MIME, hash e ponto focal são obrigatórios para cada variante. A mudança de qualquer byte gera nova `revision` e novo hash; nunca sobrescrever um arquivo de mesma revisão.
- URLs usam HTTPS e origem previamente allowlisted. Não há redirecionamento, URL de loja, página editorial, query que altere conteúdo, SVG remoto ou dados embutidos.
- Só aceitar WebP opaco, nas dimensões e proporções exatas deste contrato. A ausência de uma variante, hash divergente, tamanho excessivo, MIME errado ou ponto focal fora de `0...1` invalida a arte, não o catálogo de medição inteiro.
- `sourceRecordID` aponta para o manifesto interno de direitos; não é copy para a pessoa usuária nem prova de parceria.

## Fallback, cache e versão

O app só tenta resolver a arte depois que o catálogo correspondente já foi validado. A imagem baixada só entra no cache se hash, MIME, dimensões, proporção e origem forem compatíveis com a variante referenciada.

- Chave de cache: `assetID + variant + revision`. Uma arte nunca substitui outra por URL ou nome sozinho.
- Se o catálogo local válido continuar ativo e o cache tiver a mesma revisão, usar a cópia local offline. Se não houver cópia, mostrar o fallback de capa e continuar a descoberta; nunca bloquear seleção ou medição por falha de imagem.
- Se a revisão nova não carregar ou não passar integridade, manter a revisão anterior somente enquanto ela ainda for a referência do catálogo em uso. Com catálogo novo, não reutilizar arte de revisão antiga como se representasse o novo pacote.
- O fallback é uma superfície `background.raised` com padrão discreto do design system, ícone/símbolo neutro e nome localizado do jogo em texto. Não inventar personagem, logotipo ou capa parecida; não mostrar placeholder quebrado.
- A limpeza do cache pode remover versões que não pertencem ao catálogo em uso; a política exata de limite em bytes e purga é decisão de Rian, desde que não remova uma imagem exibida nem altere a medição/histórico.
- Falha de rede, licença pendente, integridade reprovada ou asset ausente não é `catalogUnavailable`: é apenas fallback visual. Se o contexto de medição também for inválido, prevalece o estado de catálogo indisponível definido na decisão de descoberta.

## Auditoria do repositório — 9 de setembro de 2026

O repositório continha `FortniteContextBanner.imageset` e `FortniteCover.imageset`, com arquivos locais de capa, mas sem `sourceRecordID`, manifesto de direitos, licença ou aprovação registrada. Eles não são ativos aprovados e não podem aparecer na descoberta, contexto ou seleção do MVP1.

**Atualização — 9 de setembro de 2026:** os dois imagesets legados foram removidos de `Sources/NolaggyApp/Assets.xcassets/`, já que nenhum código Swift os referenciava e a decisão 18 substituiu o contrato de arte licenciada pela identidade visual neutra. A limpeza prevista neste documento está concluída.

Até que os campos exigidos neste contrato sejam aprovados, a composição usa somente `GameArtwork(image: nil, sourceRecordID: nil, ...)`: superfície neutra Nolaggy, símbolo de controle e nome localizado. Esse fallback mantém os oito jogos selecionáveis e não altera a elegibilidade vinda do catálogo assinado. Os arquivos legados permanecem fora da composição enquanto a origem não for comprovada; a sua eventual remoção física será uma limpeza rastreável posterior, sem reintrodução por nome de asset.

## Acessibilidade e localização

O nome do jogo vem do catálogo localizado e é o label primário do cartão. A capa é decorativa para VoiceOver quando o nome já aparece na mesma ação; não ler filename, URL, licença, descrição editorial ou texto presente na própria imagem. O cartão anuncia `{nome do jogo}, {categoria}, disponível` e, quando aplicável, a última medição válida em seguida.

O fallback usa exatamente o mesmo label, ordem de leitura e alvo de toque de no mínimo 44 pt da capa carregada. Nome, categoria, estado indisponível e notas de região são texto localizável; a arte não contém copy que precise de versão PT-BR/EN. Dynamic Type pode expandir o nome e o card, mas nunca recorta o label para preservar a imagem. Contraste da sobreposição de nome é garantido por scrim tokenizado, não por escurecer permanentemente o arquivo de origem.

## Fonte, licença e aprovação

Cada variante precisa de um registro no manifesto interno de assets antes de entrar no catálogo. O registro deve conter `sourceRecordID`, jogo, variante, revisão, hash, URL/arquivo-fonte original, titular, tipo de licença, escopo de uso (app iOS/Debug), territórios, prazo, restrições de alteração, data de obtenção, responsável que verificou e aprovação de Renan + Marco. Se o direito depender de atribuição, a obrigação e a superfície apropriada devem ser aprovadas antes da integração; não adicionar atribuição escondida sobre a capa.

Fontes aceitas: kit oficial de imprensa/desenvolvedor com licença compatível, autorização escrita do titular ou biblioteca comercial cujo contrato cubra uso no app e o recorte/derivação pretendido. Capturas de loja, Google Images, redes sociais, fan art, wikis, páginas de download, resultados de busca e arte extraída do jogo não são fonte aprovada. Material fornecido pelo titular não pode ser comprimido, recortado ou convertido além do que a licença permitir.

Renan aprova qualidade visual, crop, contraste e paridade com o sistema; Marco aprova uso de marca/conteúdo e escopo comercial; Rian só integra uma referência com `sourceRecordID` aprovado; Iury não precisa aprovar a arte, mas continua responsável pela elegibilidade de região/medição. Qualquer troca de imagem, mesmo do mesmo jogo, é uma nova revisão e passa pelo mesmo gate.

## Lista de imagens necessárias

Nenhuma imagem da tabela foi obtida nesta tarefa. Cada linha requer as duas variantes acima e um registro de direitos aprovado.

| `assetID` | Jogo | `cover-3x4` | `context-banner-3x1` | Direitos/arte |
| --- | --- | --- | --- | --- |
| `fortnite` | Fortnite | necessária | necessária | pendente de fonte e aprovação |
| `call-of-duty-mobile` | Call of Duty: Mobile | necessária | necessária | pendente de fonte e aprovação |
| `free-fire` | Free Fire | necessária | necessária | pendente de fonte e aprovação |
| `pubg-mobile` | PUBG MOBILE | necessária | necessária | pendente de fonte e aprovação |
| `brawl-stars` | Brawl Stars | necessária | necessária | pendente de fonte e aprovação |
| `wild-rift` | League of Legends: Wild Rift | necessária | necessária | pendente de fonte e aprovação |
| `roblox` | Roblox | necessária | necessária | pendente de fonte e aprovação |
| `minecraft` | Minecraft | necessária | necessária | pendente de fonte e aprovação |

**Não faz parte desta entrega:** ícones de app, wordmark, imagens de publicidade, screenshots de App Store, wallpapers, arte de resultado, geração por IA, compra de licença, download de press kit ou publicação em qualquer origem remota.

## Gate de aceite

Antes de integrar qualquer uma das 16 variantes: validar schema e hash, checar a capa nos três usos (`grid`, `carousel`, `row`) e o banner na seleção, conferir crop em iPhone pequeno e grande, fallback offline, cache com revisão nova, PT-BR/EN, Dynamic Type AX3/AX5, VoiceOver, contraste e Reduzir Movimento. O aceite documental não é prova de licença adquirida, arte integrada, build gerado ou catálogo publicado.
