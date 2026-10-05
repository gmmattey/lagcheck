# Implementação no Next.js (App Router)

Confirme a versão do Next no `package.json` e consulte a doc da versão instalada (`node_modules/next/dist/docs` quando existir, ou nextjs.org/docs) — APIs mudam. Abaixo, os padrões estáveis do App Router.

## Onde olhar primeiro
`app/layout.tsx` (metadata global, `<html lang>`) · `app/**/page.tsx` e `generateMetadata` · `app/sitemap.ts` · `app/robots.ts` · `next.config.*` (redirects, headers, `images`) · `middleware`/`proxy` (redirecionamentos e `X-Robots-Tag`) · `public/` (robots.txt/sitemap estáticos duplicados?).

## Metadados
```ts
// app/layout.tsx
export const metadata: Metadata = {
  metadataBase: new URL('https://exemplo.com.br'),
  title: { default: 'Marca — proposta de valor', template: '%s | Marca' },
  description: '…≤155 car.…',
  openGraph: { type: 'website', locale: 'pt_BR', siteName: 'Marca' },
  alternates: { canonical: '/' },
};

// app/blog/[slug]/page.tsx
export async function generateMetadata({ params }): Promise<Metadata> {
  const { slug } = await params;            // params é assíncrono nas versões recentes
  const post = await getPost(slug);
  if (!post) return { robots: { index: false } };
  return {
    title: post.seoTitle,
    description: post.seoDescription,
    alternates: { canonical: `/blog/${slug}` },
    openGraph: { title: post.seoTitle, images: [post.cover] },
  };
}
```
Erros comuns: canonical herdado do layout apontando para a home em todas as páginas; mesmo `title` em todas as rotas dinâmicas; `generateMetadata` sem `notFound()` para slugs inexistentes (vira soft 404).

## Sitemap e robots
```ts
// app/sitemap.ts
export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const posts = await getAllPosts();
  return [
    { url: 'https://exemplo.com.br', lastModified: new Date() },
    ...posts.map(p => ({ url: `https://exemplo.com.br/blog/${p.slug}`, lastModified: p.updatedAt })),
  ];
}
// app/robots.ts
export default function robots(): MetadataRoute.Robots {
  return { rules: [{ userAgent: '*', allow: '/', disallow: ['/api/', '/admin/'] }],
           sitemap: 'https://exemplo.com.br/sitemap.xml' };
}
```
Evite sitemap/robots duplicados (arquivo estático em `public/` + rota). Em preview/staging, bloqueie indexação (`noindex`/proteção de deploy), nunca em produção.

## JSON-LD
```tsx
<script type="application/ld+json"
  dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd).replace(/</g, '\\u003c') }} />
```
O `replace` evita quebrar o HTML/XSS se algum campo vier de dados do usuário ou CMS. Gere o objeto no servidor.

## Renderização e performance
- Prefira Server Components/SSG/ISR para conteúdo que deve ser indexado; evite `'use client'` em páginas inteiras só por conveniência.
- `next/image` com `width/height` ou `fill` + `sizes`, `priority` na imagem de LCP, `alt` descritivo.
- `next/font` com subset `latin` e `display: 'swap'`.
- Scripts de terceiros com `next/script` e `strategy="afterInteractive"` ou `lazyOnload`.

## Redirects e internacionalização
- `redirects()` em `next.config` com `permanent: true` (308) para mudanças definitivas de URL.
- i18n: `<html lang="pt-BR">`, `alternates.languages` para hreflang, rotas por idioma (`/pt-br`, `/en`).

## Ponte com apps (quando o projeto tem app nas lojas)
- iOS: meta `apple-itunes-app` (Smart App Banner), Universal Links via `/.well-known/apple-app-site-association`.
- Android: App Links via `/.well-known/assetlinks.json`.
- Badges das lojas com links diretos e `SoftwareApplication`/`MobileApplication` na página do app. Veja `aso-store-listing` para o lado da loja.
