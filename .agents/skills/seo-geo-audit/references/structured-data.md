# Dados estruturados (JSON-LD)

Dados estruturados ajudam buscadores a entender a página e habilitam resultados enriquecidos quando elegíveis. Não são um "fator de ranking de IA". Use JSON-LD, descreva só o que está visível na página e nunca invente avaliações, preços ou autores.

## Qual schema usar

| Tipo de página | Schema | Observação |
|---|---|---|
| Home / institucional | `Organization` (+ `WebSite`) | `name`, `url`, `logo`, `sameAs` (perfis oficiais). Uma vez, na home. |
| Artigo / blog | `Article` ou `BlogPosting` | `headline`, `datePublished`, `dateModified`, `author` (`Person` com `url`), `image`. |
| Produto / comparativo de produto | `Product` (+ `Offer`, `AggregateRating` só se houver avaliações reais e visíveis) | Preço e disponibilidade devem bater com a página. |
| Receita, evento, vaga, curso | `Recipe`, `Event`, `JobPosting`, `Course` | Só se a página realmente é isso. |
| Hierarquia / navegação | `BreadcrumbList` | Reflete as migalhas visíveis. |
| Negócio local | `LocalBusiness` (subtipo adequado) | NAP idêntico ao Perfil da Empresa no Google. |
| App (web ou mobile) | `SoftwareApplication` / `MobileApplication` | `applicationCategory`, `operatingSystem`, `offers`, e `aggregateRating` só se real. Link para as lojas via `url`/`sameAs`. |
| Perguntas e respostas | `FAQPage` | Os rich results de FAQ são bem restritos hoje; use apenas se as perguntas estão visíveis e quando o schema ainda for elegível. Confirme no doc oficial. |
| Vídeo | `VideoObject` | Ajuda a indexar vídeo. |

## Regras
1. O conteúdo marcado precisa estar visível ao usuário na mesma página.
2. Use `@id` estáveis para ligar entidades (ex.: `author` → `Person` → `Organization`).
3. Campos obrigatórios/recomendados mudam; confirme em developers.google.com/search/docs/appearance/structured-data.
4. Valide no Rich Results Test e no Schema Markup Validator (validator.schema.org). Erros bloqueiam elegibilidade; avisos são opcionais.
5. Não marque conteúdo enganoso, spam de review ou itens que o usuário não vê: viola as políticas e pode gerar ação manual.

## Exemplo mínimo (Article)
```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Título exato do H1",
  "datePublished": "2026-01-15",
  "dateModified": "2026-03-02",
  "author": { "@type": "Person", "name": "Nome Real", "url": "https://exemplo.com.br/autores/nome" },
  "image": ["https://exemplo.com.br/img/capa-1200x630.jpg"],
  "publisher": { "@type": "Organization", "name": "Marca", "logo": { "@type": "ImageObject", "url": "https://exemplo.com.br/logo.png" } }
}
```
