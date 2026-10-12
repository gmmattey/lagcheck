# Monitoramento oficial: Vercel → Discord

## Fonte de dados
- SignallQ: projeto Vercel `signallq-web` (`prj_XxQs4bRAtAczAwULNqDzAWgQTkpE`)
- Lagcheck: projeto Vercel `lagcheck` (`prj_GuijE4Exyc2TplaUG6a22XlbK2gU`)
- Linka: projeto Vercel `linka` (`prj_7BpZVVugGOf644g81XxOCLKnDRe0`)
- Equipe Vercel: `team_VCRx5oIQ20HUO84QLL62RStN`
- Web Analytics é a fonte oficial de **visitantes** e **visualizações**; as páginas do Lagcheck recebem o script `/_vercel/insights/script.js`.
- Cliques na App Store do Lagcheck continuam em `POST /v1/click` e no KV local. **Cliques não equivalem a instalações.** O plano Hobby não fornece eventos personalizados de Web Analytics.

## Worker existente
O Worker `nolaggy-deep-check` possui cron `0 12 * * *` (9h Brasília em UTC-3).
O relatório chama a API oficial `/v1/query/web-analytics/visits/{count,aggregate}` para os três projetos (SignallQ, Lagcheck e Linka) e publica **um** relatório por dia no Discord. Não cria banco de visitas adicional.

### Segredos (Cloudflare; nunca comitar em `wrangler.jsonc`)
- `VERCEL_TOKEN`: token da Vercel com acesso à equipe e aos dois projetos.
- `DISCORD_WEBHOOK_URL`: webhook do canal de relatórios.
- `REPORT_TEST_TOKEN` (opcional): protege o endpoint manual `POST /v1/report/test`. Sem esse segredo, a rota rejeita os pedidos; o cron continua funcionando.

O endpoint legado `POST /v1/visit` continua retornando 200 para compatibilidade, mas **não** grava novas visitas no KV. Esse contador histórico não será usado como substituto para erros da API da Vercel.

### Confirmação de ambiente
Na conta Cloudflare correta, confirmar que o Worker publicado é o que atende a `nolaggy-deep-check.buildealabs.workers.dev`. Uma entrada de Worker sem deployments pode ser um recurso diferente; **não** publicar às cegas.
Confirmar que `VERCEL_TOKEN` e `DISCORD_WEBHOOK_URL` estão configurados como Secrets **no Worker publicado**, não apenas em outro Worker com o mesmo nome.

## Ordem segura para entrar em produção
1. Revisar as PRs e validar o layout SignallQ e as 26 páginas estáticas Lagcheck com o script Vercel.
2. Publicar os dois sites; conferir em DevTools que o script oficial retorna HTTP 200 e que a API Web Analytics recebe páginas após novas visitas reais.
3. Validar `VERCEL_TOKEN` na equipe correta e `DISCORD_WEBHOOK_URL` como Secret do Worker ativo.
4. Publicar o Worker correspondente a este repositório com Wrangler somente após confirmar conta, Worker e ambiente. **Não publicar automaticamente** por esta PR.
5. Conferir o relatório do dia civil seguinte, usando a fonte Vercel para visitantes e pageviews.
6. Opcionalmente, cadastrar `REPORT_TEST_TOKEN` e testar o endpoint com cabeçalho `Authorization: Bearer <REPORT_TEST_TOKEN>` sem expor o segredo.

## Limitações e integridade
- O monitoramento só reúne dados de visitas **após** a instrumentação ser publicada. Não inventar dados históricos.
- Falhas/403/429 na API Vercel aparecem como **dados indisponíveis**, nunca como zero.
- As métricas de UX (Core Web Vitals) pertencem ao Speed Insights; **não** confundi-las com Web Analytics nem afirmar que estão habilitadas sem validação.
- Não registrar tokens, IPs ou outros dados sensíveis nos relatórios.
- Para validar: `node scripts/build_web.mjs && node web/validate.js` na raiz e `npm test --prefix worker` em ambiente com dependências instaladas.
