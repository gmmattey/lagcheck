---
name: seo-content-brief
description: Planeja e escreve conteúdo otimizado para busca e para respostas de IA — briefing de pauta, análise de intenção e lacunas contra os primeiros resultados, clusters de tópicos, redação ou reescrita de artigos/landing pages, E-E-A-T (autoria e confiança) e blocos prontos para citação. Use sempre que o usuário pedir artigo de blog, pauta, brief, "o que escrever para ranquear", reescrever página que não performa, cluster de conteúdo, texto de landing page, FAQ ou conteúdo para aparecer no Google/ChatGPT, mesmo sem dizer "SEO". Não use para auditoria técnica (use seo-geo-audit) nem para textos de loja de apps (use aso-store-listing).
---

# SEO Content Brief & Writer

Transforma uma ideia em um brief verificável e, se pedido, no texto final. O objetivo é conteúdo que ajuda de verdade quem busca. Isso serve tanto ao Google quanto às respostas de IA.

## Princípios

1. **Pesquise o resultado real.** Intenção e lacunas saem de ler as páginas que já ranqueiam, não de intuição. Se não conseguir buscar/abrir uma página, diga e não suponha o que ela cobre.
2. **Ganho de informação.** Cada peça precisa de algo que os concorrentes não têm: dado próprio, teste, preço atualizado, critério claro, experiência de primeira mão, exemplo real. Sem isso, não vale publicar; sugira outro ângulo.
3. **Fatos não inventados.** Números, preços, especificações, citações e depoimentos só entram com fonte (link + data) ou marcados `[VERIFICAR]`. Nunca fabrique estatísticas, autores ou avaliações.
4. **Escrito para pessoas, estruturado para máquinas.** Resposta direta no começo de cada seção, títulos descritivos, tabelas para comparação, listas para passos. Isso é bom para leitor e fácil de citar por IA.
5. **Voz humana e específica.** Evite clichês de texto genérico (“no mundo atual”, “é importante ressaltar”, listas de três adjetivos vazios, introdução que repete o título). Prefira frases concretas e exemplos.
6. **Confiança proporcional ao risco.** Em temas de saúde, dinheiro, segurança ou compra cara, exija autor com credencial, fontes primárias, data de revisão e aviso adequado. Se o usuário não tem especialista, sinalize a limitação.

## Fluxo

1. **Entrada**: tema ou URL; público; objetivo (tráfego, lead, venda); idioma/região; site de destino (tom de voz, páginas existentes para linkar). Pergunte só o que faltar.
2. **Intenção e SERP**: identifique a palavra-chave principal e a intenção (informacional, comparação, transacional, navegacional). Leia os 3–5 primeiros resultados: formato, ângulo, profundidade, o que cobrem e o que faltam. Veja “As pessoas também perguntam” e buscas relacionadas.
3. **Lacunas**: liste ≥ 3 lacunas concretas (subtemas, dados, formatos, objeções) que sua peça pode cobrir. Veja `references/brief-template.md`.
4. **Brief**: preencha o template (título, H1, estrutura H2/H3 com a resposta de cada seção, entidades e perguntas a cobrir, links internos/externos, schema sugerido, prova/dados necessários, CTA).
5. **Redação** (se pedida): escreva seguindo o brief e `references/writing-rules.md`; marque `[VERIFICAR]` onde faltar fonte.
6. **Revisão**: rode o controle de qualidade abaixo e entregue título (≤ 60 car.), meta description (≤ 155 car.), slug e sugestão de schema (veja `seo-geo-audit/references/structured-data.md`).
7. **Cluster** (se for um tema amplo): proponha 1 página pilar + 5–10 páginas de apoio, cada uma com intenção distinta (sem canibalização) e mapa de links internos.

## Saída
- *Brief*: o template de `references/brief-template.md` preenchido.
- *Texto*: artigo em Markdown pronto para o CMS, com título, description, slug, estrutura e lista de fontes.
- *Reescrita*: antes/depois dos trechos alterados + justificativa curta.

## Controle de qualidade
- Li de fato os concorrentes citados? Tem ≥ 3 lacunas específicas?
- A peça tem ao menos um elemento de ganho de informação real?
- Toda afirmação factual tem fonte ou está marcada `[VERIFICAR]`?
- Cada H2 começa respondendo? O leitor tem o essencial em 10 segundos?
- Título, description e H1 coerentes e dentro dos limites? Palavra-chave natural, sem repetição forçada?
- Zero conteúdo enganoso (reviews, números, autor inventados)?
