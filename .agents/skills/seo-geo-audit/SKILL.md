---
name: seo-geo-audit
description: Audita e melhora SEO tradicional e visibilidade em buscas com IA (Google AI Overviews/AI Mode, ChatGPT, Perplexity — também chamado de GEO/AEO) em sites e web apps, lendo o código do projeto (Next.js/React) e/ou a URL publicada. Use sempre que o usuário falar de SEO, ranqueamento, indexação, sitemap, robots, canonical, meta tags, Open Graph, schema/JSON-LD, dados estruturados, Core Web Vitals, "aparecer no Google", "aparecer no ChatGPT", GEO, AEO, llms.txt ou pedir uma auditoria/checklist de SEO — mesmo sem citar a palavra "SEO". Também serve para audit/implement SEO, structured data, AI search visibility. Não use para ASO de apps (use aso-store-listing) nem para escrever artigos (use seo-content-brief).
---

# SEO + GEO Audit

Audita um site e entrega correções priorizadas e, quando houver código, as próprias edições. Pensado para nossos projetos web (Next.js/React, vários em português do Brasil).

## Princípios (leia antes de agir)

1. **Busca com IA é busca.** Google AI Overviews e AI Mode usam o índice, ranking e sistemas de qualidade do Google. Não existe "schema para IA" nem arquivo mágico. GEO/AEO são rótulos de mercado: o trabalho real é ser rastreável, indexável, útil e citável. Isso evita gastar esforço em atalhos que não funcionam.
2. **Evidência antes de opinião.** Cada achado cita onde está (arquivo:linha ou URL + trecho). Nunca afirme o que uma página contém sem tê-la lido; se um fetch falhar, diga isso e peça o HTML/conteúdo colado.
3. **Sem promessas.** Nenhuma otimização garante rastreamento, indexação, posição ou citação por IA. Fale em "aumenta a elegibilidade/clareza", não em "vai ranquear".
4. **Somente leitura por padrão.** Audite primeiro; só edite arquivos se o usuário pedir implementação. Nunca peça nem grave chaves, tokens ou credenciais do Search Console/GA. Se o usuário quiser usar dados do GSC, peça que cole o export.
5. **Orientações mudam.** Para "regra atual", limites ou citações exatas, confirme nas fontes oficiais (developers.google.com/search, schema.org, docs do Next.js) antes de afirmar.
6. **O projeto manda no texto e na marca.** Antes de propor copy (título, descrição, claims), leia `AGENTS.md`/`CLAUDE.md`/docs de voz do projeto: eles podem proibir promessas (ex.: "ping do jogo"), fixar grafia da marca ou limitar escopo. Se a sugestão de SEO conflitar com isso, o projeto vence; sinalize o conflito em vez de contorná-lo.
7. **Meça antes de afirmar peso.** Peso de imagens e SVGs vem de `curl` (bytes reais) ou do arquivo local, não de suposição. Um SVG grande costuma ter bitmap embutido (base64).

## Fluxo

1. **Classificar o pedido**: auditoria completa · auditoria de uma página · implementação · checagem de mito ("preciso de llms.txt?") · plano/roadmap.
2. **Coletar contexto mínimo**: onde está o código (pasta) ou a URL; público e idioma (pt-BR? multi-idioma?); tipo de site (marketing, e-commerce, blog, SaaS, app web); objetivo (tráfego, leads, citações). Pergunte só o que não dá para descobrir.
3. **Inspecionar**:
   - *Com código*: framework e roteamento, `generateMetadata`/`metadata`, `sitemap`, `robots`, `<link rel=canonical>`, JSON-LD, rotas dinâmicas, redirects, `next.config`, imagens (`next/image`, alt), fontes, renderização (SSR/SSG/CSR). Comece por `references/nextjs-implementation.md`.
   - *Com URL*: busque a página e leia o HTML renderizado (título, descrição, H1–H3, canonical, robots meta, links internos, JSON-LD, OG). Cheque `/robots.txt` e `/sitemap.xml`.
   - O conteúdo crítico está no HTML inicial? Se só aparece após JS/scroll, é um achado.
   - *Core Web Vitals*: tente o PageSpeed Insights; se a API pública devolver erro de cota (429), não peça chave nem credencial. Peça ao usuário que cole o relatório do PageSpeed/Lighthouse, ou estime pelo peso dos recursos e declare "não medido" no relatório.
   - *Site estático ou landing de pré-lançamento* (poucas URLs, sem blog, app ainda fora das lojas): leia `references/landing-prelaunch.md`.
4. **Aplicar os checklists** (carregue só o necessário):
   - `references/technical-checklist.md` — rastreio, indexação, canonical, status HTTP, performance, mobile.
   - `references/structured-data.md` — qual schema usar por tipo de página e como validar.
   - `references/geo-aeo.md` — citabilidade por IA, crawlers de IA, mitos.
   - `references/nextjs-implementation.md` — como implementar cada correção no App Router.
5. **Entregar** no formato abaixo.
6. **Se for implementar**: antes de editar, confira se o projeto tem testes/validadores que travam texto ou arquivos (ex.: `validate.js` com título exato) e atualize-os junto. Faça edições pequenas e focadas, rode build/lint/testes, confira o resultado no navegador e liste como validar (Rich Results Test, URL Inspection, PageSpeed Insights). Não faça commit nem deploy sem pedido. Não mexa em ativos de marca fora do necessário (gere variantes, preserve a fonte da verdade).

## Formato do relatório

```
# Auditoria SEO/GEO — <site ou página>
Contexto: <tipo, idioma, objetivo, o que foi lido> · Limitações: <o que não deu para verificar>

## Resumo (3 linhas)
## Placar
| Área | Nota /10 | Prioridade |   (Rastreio e indexação · Conteúdo e intenção · Metadados · Dados estruturados · Performance/UX · Citabilidade por IA)
## Achados prioritários
🔴 Crítico / 🟡 Importante / 🟢 Melhoria — cada um com: evidência (arquivo:linha/URL) · por que importa · correção exata (diff ou texto pronto) · como validar
## 5 ganhos rápidos
## 5 melhorias estratégicas
## Textos reescritos (title ≤ 60 car., description ≤ 155 car., H1) — com contagem de caracteres
## O que NÃO fazer (mitos descartados que o usuário perguntou)
```

## Controle de qualidade (antes de entregar)

- Todo achado tem evidência concreta? Nada foi inferido de página não lida?
- Os textos reescritos respeitam o idioma e o tom do site e cabem nos limites?
- Separei o que é impacto real (indexação, canonical, conteúdo) do que é cosmético?
- Evitei prometer ranking e evitei os mitos de `references/geo-aeo.md`?
- Um dev conseguiria executar cada correção sem perguntar nada?
