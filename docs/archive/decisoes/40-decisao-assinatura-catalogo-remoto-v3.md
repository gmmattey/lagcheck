# LagCheck — Decisão 40: assinatura e ativação do catálogo remoto v3

**Status:** decidido pelo Dono do Produto; ativo no Worker após a publicação desta decisão

**Data:** 19 de setembro de 2026

**Responsáveis:** Luiz (produto), Marco (produto), Iury (rede), Rian (iOS)

**Complementa:** `docs/archive/decisoes/14-decisao-catalogo-remoto-debug.md`, `docs/archive/decisoes/37-decisao-catalogo-remoto-v3-rotas-prioritarias.md` e `docs/archive/decisoes/39-decisao-selecao-automatica-rotas-proprias.md`.

---

## 1. Decisão

O catálogo remoto v3 será publicado no endpoint já autorizado `GET /v1/catalog.json`, assinado em Ed25519. Como não há build distribuído por TestFlight ou App Store, a chave pública do v3 pode ser adotada antes da primeira distribuição do app.

O payload ativo usa `catalog-v3-2026.09.19.1`, schema `3` e validade de 30 dias, até `2026-10-19T15:30:00Z`. O mesmo envelope v3 assinado está empacotado como catálogo-base no binário Release; `DebugCatalogBase.json` é apenas o nome histórico do recurso, não uma restrição a Debug. O Worker somente entrega o envelope já assinado: ele não contém nem gera chave privada.

## 2. Custódia da chave

- A chave privada é criada e mantida no Keychain local do macOS de publicação, no item de serviço `com.buildea.lagcheck.catalog.ed25519.v3` e conta `publisher`.
- Nenhum material privado entra no repositório, no app, no Worker, em logs ou na documentação.
- `worker/scripts/CatalogV3Signer.swift` é a rotina reprodutível de assinatura: lê o payload canônico, recupera a chave no Keychain e grava somente o envelope assinado.
- A chave pública v3 fica embutida no verificador iOS e no verificador do Worker. A chave pública anterior não é fallback do binário de lançamento: o catálogo-base empacotado também é schema 3 e é validado pela chave v3.
- Uma cópia de recuperação da chave privada exige procedimento de cofre aprovado separadamente; nunca deve ser versionada junto ao catálogo.

## 3. Regras de operação

1. Alterar o catálogo canônico e validar schema, regras de negócio, arte, hashes, perfis e rotas.
2. Assinar o payload com a rotina local, informando emissão e expiração explícitas.
3. Validar assinatura com a chave pública v3 e rodar testes do Worker e do iOS antes do deploy.
4. Publicar pelo Worker existente e confirmar que o endpoint remoto devolve o envelope esperado e verificável.
5. Renovar e publicar um novo envelope antes da expiração do vigente. A renovação remota preserva os aparelhos que atualizarem o catálogo a tempo; ela não revalida o envelope v3 já empacotado em um binário instalado.
6. Antes da expiração do catálogo-base empacotado, decidir e preparar uma nova build com base v3 renovada. Se o aparelho estiver offline e tanto o cache quanto a base estiverem expirados, o catálogo fica indisponível e o teste não começa; não há uso indefinido de catálogo vencido nem fallback para schema 1.

### 3.1 Operação de renovação

Para cada renovação, Iury valida a nova validade e a assinatura; Rian valida o consumo pelo app e o comportamento de cache/base. A publicação continua limitada ao Worker já autorizado. A evidência registra versão, emissão, expiração e verificação do endpoint, sem registrar a chave privada.

## 4. Limites

Ativar o catálogo não ativa destinos próprios pendentes, não remove a rota AWS de referência e não distribui o app. O catálogo só orienta uma rota regional de referência: não declara servidor, endpoint ou ping oficial de qualquer jogo, nem promete a latência futura de uma partida. A primeira build iOS distribuída já carrega o envelope v3 como base e pode atualizar para envelope v3 remoto válido; até ela existir, este é apenas o estado publicado da infraestrutura de catálogo.
