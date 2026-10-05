---
name: aso-store-listing
description: Otimiza a página do app na App Store (iOS) e no Google Play (Android) — ASO (App Store Optimization): título, subtítulo, campo de palavras-chave, descrição curta e longa, screenshots, ícone, localização pt-BR/en, testes A/B e auditoria de ficha contra concorrentes. Use sempre que o usuário falar de ASO, App Store, Play Store, Google Play, ficha/listing do app, palavras-chave de app, ranking na loja, conversão de página de app, screenshots, "aparecer na busca da loja", lançamento ou atualização de app, mesmo sem dizer "ASO". Também serve para App Store Connect, Play Console, store listing, keyword field. Não use para SEO de sites (use seo-geo-audit).
---

# ASO — App Store + Google Play

Cria ou audita a ficha de um app nas duas lojas, com textos prontos, dentro dos limites de caracteres e das políticas de cada loja. Serve para nossos apps iOS/Android e para a ponte com o site.

## Princípios

1. **Duas lojas, dois algoritmos.** Apple indexa título, subtítulo e o campo oculto de palavras-chave (a descrição longa **não** é indexada para busca). O Google Play indexa título, descrição curta e a descrição longa (repetir palavra-chave com naturalidade importa lá, mas sem spam). Não copie o texto de uma loja na outra.
2. **Conversão importa tanto quanto descoberta.** Ícone, primeiras 2 screenshots, nota e primeira linha da descrição decidem a instalação. Palavra-chave sem conversão não paga.
3. **Política antes de otimização.** Texto que viola regra derruba o app. Sem nomes de concorrentes/marcas de terceiros, sem alegações não comprováveis ("nº 1", "melhor do mundo"), sem preço/promoção/"grátis" no título, sem palavras repetidas só para ranquear, sem emojis/ALL CAPS decorativos no Play, sem prints que não mostram o app real. Detalhes em `references/apple-app-store.md` e `references/google-play.md`.
4. **Limites mudam.** Os limites de caracteres e campos nos arquivos de referência são os conhecidos; confirme no App Store Connect/Play Console ou na documentação oficial antes de entregar algo "definitivo", e diga isso.
5. **Sem fabricar prova social.** Nunca sugira comprar reviews/instalações nem inventar números, prêmios ou depoimentos. Só use o que o usuário comprova.
6. **Sem credenciais.** Não peça nem use acesso ao App Store Connect/Play Console. Trabalhe com o que o usuário colar ou com as páginas públicas das lojas.

## Fluxo

1. **Briefing mínimo** (pergunte só o que faltar): nome do app e plataformas; o que faz e para quem (1 frase); diferencial real; categoria; idiomas/países; público; concorrentes diretos (2–5); termos que o usuário já sabe que importam; fase (lançamento, atualização, queda de downloads). Se houver código do app no projeto, leia `Info.plist`/`AndroidManifest`/`strings`/README para extrair nome, features e idiomas.
2. **Pesquisa de palavras-chave** → `references/keyword-research.md` (classificar por relevância × volume × dificuldade; sem dados de ferramenta, deixe claro que volumes são estimativas qualitativas).
3. **Auditoria da ficha atual** (se existir): leia a página pública da loja (título, subtítulo/descrição curta, descrição, screenshots, nota, últimas versões). Compare com 3–5 concorrentes: o que prometem nos 2 primeiros prints, quais termos usam no título.
4. **Redigir por loja**:
   - iOS: `references/apple-app-store.md`
   - Android: `references/google-play.md`
5. **Localização** → `references/keyword-research.md` (seção pt-BR). Não traduza literal: pesquise os termos que o usuário local realmente digita.
6. **Plano de teste** → 1 hipótese por vez (Product Page Optimization na Apple; Store Listing Experiments no Google Play), com métrica e tempo mínimo.
7. **Ponte com o site**: se o produto tem site, indique Smart App Banner, links universais/App Links e badges (veja `seo-geo-audit/references/nextjs-implementation.md`).

## Formato de saída

```
# ASO — <app> (<iOS|Android|ambos>) · idioma(s)
Contexto e limitações (o que li / o que faltou)

## Diagnóstico (se há ficha atual)
Placar: Metadados · Palavras-chave · Criativos (ícone/prints/vídeo) · Conversão (nota, descrição) · Localização · Conformidade com políticas   (cada /10, com 1 linha de evidência)

## Mapa de palavras-chave
| Termo | Intenção | Relevância | Concorrência (estimada) | Onde usar |

## iOS
Nome (≤30): … [n car.]   Subtítulo (≤30): … [n car.]   Palavras-chave (≤100): … [n car.]
Texto promocional (≤170): …   Descrição (≤4000): primeira linha forte + blocos   O que há de novo: …
## Android
Título (≤30): … [n car.]   Descrição curta (≤80): … [n car.]   Descrição completa (≤4000): …
## Criativos
Sequência de screenshots 1→N (mensagem de cada uma, em 1 frase) · ícone · vídeo/feature graphic
## Experimentos (próximos 30–60 dias)
## Checagem de política (lista do que foi verificado)
```
Sempre inclua a contagem de caracteres de cada campo e alternativas (A/B) para título/subtítulo.

## Controle de qualidade
- Nenhum campo excede o limite? Contagem conferida (não estimada).
- Nenhuma palavra repetida entre título, subtítulo e keywords na Apple (desperdício)?
- Nenhuma marca de terceiros, claim não comprovável ou termo proibido?
- Cada loja recebeu texto próprio e o pt-BR soa natural?
- O usuário consegue colar tudo direto no console, sem editar?
