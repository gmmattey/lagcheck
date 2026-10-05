# Landing de pré-lançamento / site estático

Contexto típico: 1 página indexável, lista de espera, app ainda fora das lojas, HTML/CSS/JS puro ou gerador estático (Vercel, Netlify, Cloudflare Pages). Aqui o conteúdo é pouco; os ganhos vêm de **peso, metadados, compartilhamento e fundamentos**.

## Verificações específicas
1. **Peso real dos arquivos** (`curl -sSL -o /dev/null -w "%{size_download}"`). Alvos: HTML < 100 KB, cada imagem de hero < ~150 KB, logo < 30 KB.
   - Captura de tela em PNG enorme → gerar WebP (cwebp `-q 80 -resize <2x da largura exibida>`), usar `<picture>` com o PNG como fallback. `<picture>` é inline: não quebra imagens com `position:absolute`.
   - SVG pesado = quase sempre bitmap base64 embutido. Reduza a resolução ao dobro do tamanho exibido e prefira WebP dentro do SVG (ou vetor limpo).
   - Imagem do hero (LCP): `fetchpriority="high"`, **sem** `loading="lazy"`; confira se está acima da dobra antes de sugerir lazy-load. Só abaixo da dobra leva `loading="lazy"`.
2. **Cache** de imagens/ícones: `Cache-Control` explícito. Sem hash no nome do arquivo, use `max-age=86400, stale-while-revalidate=604800`; com hash, `max-age=31536000, immutable`. Em Vercel: chave `headers` no `vercel.json` (mantenha `rewrites` existentes).
3. **Sitemap × noindex**: sitemap só com URLs indexáveis. Páginas legais/suporte com `noindex` ficam fora do sitemap (continuam acessíveis para as lojas).
4. **Imagem social 1200×630** (< 300 KB), com `og:image:width/height/alt` e `twitter:image:alt`. Screenshot vertical de celular como og:image é cortado em chats.
5. **Ícones**: `favicon.ico` (16/32/48), `favicon.svg`, `apple-touch-icon.png` 180×180 opaco (iOS arredonda sozinho). Use o ícone do app (não o wordmark) e parta da fonte da marca no repositório.
6. **Schema**: `MobileApplication` (ou `SoftwareApplication`) com **uma** `applicationCategory`; `WebSite`; só adicione `Organization`/`sameAs` com dados confirmados pelo dono. Sem `aggregateRating` antes de existir avaliação real. `FAQPage` não gera rich result para a maioria dos sites, mas descreve bem o conteúdo visível.
7. **Termos de busca no título**: confirme se título/H1 trazem o vocabulário que o público digita (ex.: "teste de lag"), sem violar as regras de promessa do projeto. Trate como hipótese a testar no Search Console.
8. **Pré-lançamento → lançamento**: botões "Entrar no TestFlight/Play Beta" que são `<button>` viram `<a href>` com links das lojas quando existirem; adicionar Smart App Banner (`apple-itunes-app`), `apple-app-site-association`, `assetlinks.json` e `sameAs` com as páginas das lojas. Use `aso-store-listing` para a ficha.
9. **Conteúdo para crescer**: uma URL só limita o alcance. Planeje 3–5 páginas de guia com informação própria (dados de medição, metodologia) via `seo-content-brief`. Páginas por jogo/cidade só quando houver substância real, nunca em massa.

## Armadilhas
- `trailingSlash`/`cleanUrls` no Vercel junto de `rewrites` para uma API (ex.: `/v1/*` → Worker) pode alterar o método/caminho das requisições (ex.: POST de formulário). Não ative sem testar; a canonical já resolve duplicatas como `/index.html`.
- Meta `keywords` é ignorada pelo Google: não gaste tempo nela.
- Testes/validadores do projeto podem travar o título e a descrição exatos: atualize-os junto da mudança.
- Imagens com arte de terceiros (capas de jogos) podem ser vedadas pelas regras de marca do projeto: sinalize, não decida.
