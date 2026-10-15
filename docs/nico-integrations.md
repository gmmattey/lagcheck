# Nico — matriz de integrações

Estado desta matriz: 15 de outubro de 2026. Ela descreve o que Nico
pode preparar; nenhuma integração foi configurada por esta entrega e nenhuma
credencial deve entrar no repositório.

| Integração | Uso legítimo | Permissão / escopo mínimo | Limites e custo | Alternativa sem conexão | Estado |
| --- | --- | --- | --- | --- | --- |
| App Store Connect API | ler ficha, builds, analytics permitidos; preparar rascunhos | chave de API com papel mínimo e acesso apenas ao app | quotas/papéis da Apple; não presumir acesso a todo analytics | export/captura fornecida pelo responsável, página pública | não configurada |
| Google Play Developer API | ler tracks, releases e relatórios autorizados | service account com menor papel no app | quotas/políticas Google; mudança de release é externa | export do Play Console e página pública | não configurada |
| GitHub | relacionar release, issue e evidência de código | leitura do repositório; escrita só com pedido | rate limits do provedor; sem criar PR/issue automaticamente | checkout local e links fornecidos | não configurada nesta skill |
| GitHub Actions | consultar artefatos ou status de CI | leitura do workflow/artefatos autorizados | execução pode consumir minutos e modificar estado | logs de CI fornecidos e testes locais | não configurada |
| Firebase Analytics | analisar evento/funil já instrumentado | leitura do projeto/dataset mínimo | retenção, sampling e custos dependem da conta | export CSV ou analytics existente | não configurada; não adicionar SDK por growth |
| Google Analytics | analisar aquisição e landing pages | leitura da propriedade mínima | definições podem divergir de loja; privacidade/consentimento | export CSV, logs agregados | não configurada |
| Cloudflare | confirmar páginas, redirect/deep links e Worker já aprovado | token de leitura por zona/recurso | não criar endpoint/Worker novo; respeitar custo zero do LagCheck | URLs públicas, arquivos versionados | Worker existente fora do escopo desta entrega |
| Vercel | verificar deploy e analytics autorizados | acesso somente leitura ao projeto | dados dependem do plano e consentimento | URL pública e logs/export fornecidos | não configurada |
| Discord | acompanhar feedback voluntário ou preparar anúncio | canal/bot com menor permissão; envio só com ordem | rate limits e regras do servidor; não automatizar spam | feedback exportado ou texto fornecido | não configurada |

## Regra de credenciais

Tokens, chaves privadas, arquivos de service account e certificados ficam no
secret manager ou no ambiente seguro aprovado. Antes de conectar qualquer item,
registre objetivo, dados lidos/escritos, escopo, responsável, custo possível,
opção reversível e condição de parada. Conexão de leitura não é permissão para
publicar, alterar preço, responder review ou fazer rollout.
