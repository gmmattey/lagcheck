# Checklist técnico de SEO

Use como lista de verificação; reporte só o que de fato encontrou. Severidade: 🔴 bloqueia indexação/rastreio · 🟡 prejudica sinais · 🟢 refinamento.

## 1. Rastreio e indexação
- 🔴 `robots.txt` não bloqueia CSS/JS/rotas importantes; não existe `Disallow: /` esquecido de staging.
- 🔴 Nenhum `noindex` (meta robots ou header `X-Robots-Tag`) em páginas que devem ranquear. Cheque layouts e `metadata.robots`.
- 🔴 Páginas indexáveis retornam 200. Páginas removidas retornam 404/410, não 200 com "não encontrado" (soft 404).
- 🟡 Redirects 301/308 diretos, sem cadeias; um único host canônico (www vs. não-www, http→https, barra final).
- 🟡 `sitemap.xml` lista só URLs canônicas, indexáveis e com 200; está referenciado no `robots.txt`; `lastmod` só muda quando o conteúdo muda de verdade.
- 🟡 Páginas importantes são alcançáveis por links `<a href>` rastreáveis (não só `onClick`/botões/JS) a poucos cliques da home.
- 🟡 Cada tela/estado relevante de um app web tem URL própria (sem depender de `#` ou de estado em memória).
- 🟢 Paginação com links reais; filtros/parâmetros que geram duplicatas controlados por canonical.

## 2. Canonical, duplicação e idioma
- 🔴 Cada página tem `rel=canonical` absoluto apontando para si mesma (ou para a versão preferida real). Nunca para a home por padrão.
- 🟡 Conteúdo duplicado (versões com/sem parâmetro, www, http) consolidado.
- 🟡 Multi-idioma: `<html lang>` correto (`pt-BR`), `hreflang` recíproco com `x-default`, sem traduzir só o template.

## 3. Metadados e HTML
- 🟡 `<title>` único por página, ≈ ≤ 60 caracteres, palavra principal perto do início, com motivo para clicar. O Google pode reescrever títulos; escreva para humanos.
- 🟡 `meta description` única, ≈ ≤ 155 caracteres, resume o benefício. Não é fator de ranking, mas influencia o clique.
- 🟡 Um `<h1>` descritivo; H2/H3 refletem a estrutura real, sem pular níveis só por estilo.
- 🟡 Open Graph e Twitter Cards (`og:title`, `og:description`, `og:image` 1200×630, `og:url`, `og:locale`) — afetam compartilhamento, não ranking.
- 🟢 Texto alternativo descritivo em imagens relevantes; vazio (`alt=""`) em decorativas.
- 🟢 URLs curtas, legíveis, minúsculas, com hífen.
- 🟢 Links internos com âncora descritiva (não "clique aqui"); páginas órfãs eliminadas.

## 4. Renderização (JavaScript)
- 🔴 O conteúdo principal, links e dados estruturados estão no HTML renderizado do servidor, ou o Google consegue renderizá-los. Compare "ver código-fonte" com o DOM final.
- 🟡 Nada essencial depende de scroll, clique ou login para aparecer.
- 🟡 Erros de hidratação ou 5xx intermitentes não escondem conteúdo do bot.

## 5. Experiência da página (Core Web Vitals)
- 🟡 LCP ≲ 2,5 s, INP ≲ 200 ms, CLS ≲ 0,1 em dados de campo (CrUX/Search Console), não só no laboratório.
- 🟡 Imagem de LCP priorizada (`priority`/`fetchpriority`), tamanhos explícitos (sem layout shift), formatos modernos (WebP/AVIF), fontes com `display: swap` e preload do essencial.
- 🟡 JS de terceiros (analytics, chat, pixels) carregado com `async`/`defer`/após interação.
- 🟡 Mobile-first: viewport correto, alvos de toque adequados, sem pop-ups intrusivos cobrindo o conteúdo.
- 🟢 HTTPS em tudo, sem conteúdo misto; cache e compressão ativos.

## 6. Conteúdo e intenção (julgamento, não checklist)
- A página responde à intenção de busca (informacional, comparação, transacional, navegacional)?
- Tem informação que um concorrente genérico não tem (dados, experiência própria, exemplos reais, autoria)?
- Autor, data de atualização e fontes visíveis onde a confiança importa (saúde, finanças, tecnologia que o usuário vai comprar)?
- Evita páginas finas ou geradas em massa quase idênticas (por cidade, por modelo etc.)?

## Como validar
Search Console (Inspeção de URL, Páginas, Sitemaps, Core Web Vitals) · Rich Results Test · PageSpeed Insights · `curl -I` para status/headers · "ver código-fonte" para HTML inicial.
