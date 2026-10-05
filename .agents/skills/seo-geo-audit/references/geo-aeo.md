# GEO / AEO — visibilidade em buscas com IA

Base: sistemas de IA de busca (Google AI Overviews/AI Mode, Bing Copilot, Perplexity, ChatGPT search) recuperam páginas da web e as citam. Ser citado depende de ser **encontrável, entendível e confiável**. Quase tudo isso é SEO bem feito.

## O que realmente ajuda
1. **Rastreável e indexável** (ver `technical-checklist.md`). Se o bot não vê, a IA não cita.
2. **Responder direto.** Comece seções com a resposta em 1–2 frases, depois detalhe. Perguntas como títulos (H2/H3) quando forem as perguntas reais do usuário.
3. **Informação própria e verificável**: dados, testes, preços atualizados, comparativos com critérios explícitos, experiência de primeira mão. Conteúdo commodity (que qualquer modelo escreve) raramente é escolhido.
4. **Entidade clara**: nome da marca consistente, página "Sobre" com pessoas reais, autores com bio, `Organization` + `sameAs` para perfis oficiais, dados de empresa corretos.
5. **Fatos atualizados e datados**: `dateModified` honesto, números com fonte e data.
6. **Estrutura legível**: tabelas para comparações, listas para passos, definições curtas. Boa para humanos e fácil de extrair.
7. **Menções reais**: ser citado por fontes independentes (imprensa, comunidades, parceiros). Conquiste, não fabrique.
8. **Mídia útil** (imagens/vídeos originais com texto alternativo e transcrição quando fizer sentido).

## Crawlers de IA (decisão de negócio, não técnica)
`robots.txt` controla o acesso. Agentes comuns: `Googlebot` (Busca e AI Overviews), `Google-Extended` (controle de uso para Gemini/treino; não afeta o ranking na Busca), `GPTBot` (treino OpenAI), `OAI-SearchBot` (busca do ChatGPT), `ChatGPT-User`, `ClaudeBot`/`Claude-SearchBot`/`Claude-User` (Anthropic), `PerplexityBot`, `Bingbot`. Nomes e função mudam — confirme na documentação de cada empresa.
- Quer ser citado em respostas de IA? Não bloqueie os bots de **busca/usuário**.
- Quer evitar treino? Bloqueie os de **treino** (decisão do dono do site; apresente o trade-off, não decida sozinho).
- Bloquear tudo "por precaução" reduz visibilidade; liberar tudo expõe o conteúdo a treino. Pergunte a preferência.

## Mitos a descartar (explique por quê)
- **"Preciso de `llms.txt`."** Não é requisito do Google nem comprovadamente usado pelos grandes mecanismos. Pode existir sem mal, mas não é prioridade.
- **"Quebre o conteúdo em pedacinhos para IA."** Escreva para pessoas; páginas fragmentadas ou quase duplicadas para cada variação de pergunta prejudicam.
- **"Existe schema especial para IA."** Não. Schema ajuda a entender o conteúdo, só isso.
- **"Reescreva tudo no estilo de IA."** Reescrever só para o modelo, sem valor novo, não ajuda.
- **"Comprar menções/reviews."** Fabricar sinais viola políticas e a confiança da marca.
- **"Garantia de aparecer na resposta."** Ninguém garante. Meça, não prometa.

## Como medir (sem prometer)
- Search Console: impressões/cliques de consultas em formato de pergunta; páginas indexadas.
- Testes manuais periódicos: faça 10–20 perguntas reais do seu público nas ferramentas de IA e registre se a marca/URL aparece, em qual posição e com que fonte. Repita mensalmente; trate como amostra, não como métrica exata.
- Referrers de IA nas análises do site (ex.: `chatgpt.com`, `perplexity.ai`, `gemini.google.com`, `copilot.microsoft.com`).
