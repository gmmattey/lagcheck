# Continuidade no Mac — catálogo e artes remotos

## Transferência

Origem: worktree Windows iniciado em HEAD destacado `feec6ef`. A entrega será salva na branch `codex/remote-catalog-artwork`, incluindo arquivos novos e artes PNG. No Mac, selecionar essa branch; clonar apenas a branch principal não leva esta entrega. Não copiar o arquivo `.git` do worktree para o Mac: ele aponta para o checkout Windows.

Caminho recomendado: buscar a branch `codex/remote-catalog-artwork` no remoto `origin`, após o push. Alternativa offline: clonar o bundle Git fornecido nesta sessão. O resultado efetivo de commit, push e verificação do bundle fica na resposta de entrega. Se transferir arquivos manualmente, usar um checkout da mesma revisão e incluir tanto modificados quanto novos; não copiar apenas o diff textual, pois há binários e arquivos não rastreados.

Em checkout existente no Mac: `git fetch origin codex/remote-catalog-artwork` e `git switch --track origin/codex/remote-catalog-artwork` (preservar mudanças preexistentes; se a branch local já existir, inspecionar antes). Em clone novo: `git clone --branch codex/remote-catalog-artwork https://github.com/gmmattey/lagcheck.git`.

## Estado e escopo

Luiz autorizou catálogo e artes baixados remotamente em iOS/Android, sem conferir hash do conteúdo de imagens. Assinatura Ed25519 do catálogo permanece obrigatória. Decisões 70/71 e `.agents/architecture-plan.md` descrevem escopo e gate.

Implementação local:
- iOS conecta o loader à UI; cache de disco, limites de bytes/dimensões, fallback, cancelamento/pausa durante preparação/Check/background; cache remoto válido vence base inválida/expirada.
- Android descobre jogos a partir do catálogo validado e carrega arte remota na Home/lista/favoritos/histórico. Novos IDs não exigem edição da lista local.
- Quatro jogos e artes originais preparados no candidato de 26 jogos: Dead by Daylight, For Honor, Borderlands 3 e New World: Aeternum. Envelope ativo continua com 22 jogos.
- Android: APK Debug gerado e 116 testes JVM de catálogo/sessão verdes. Emulador recusou instalação por falta de espaço; sem runtime/QA visual. iOS ainda sem build/testes Xcode.
- Revisão arquitetural independente realizada; bug de retomada das imagens após cancelar Check corrigido. Não houve publicação, alteração de chave, TestFlight, App Store ou prova física.

## Sequência no Mac

1. Ler `AGENTS.md`, Decisões 70/71, architecture-plan e `audits/remote-catalog-artwork-2026-10-03.md`; conferir `git status` e arquivos transferidos.
2. Conferir Xcode selecionado e simuladores instalados. Gerar/atualizar projeto com o fluxo existente de `project.yml` (XcodeGen, se disponível); não instalar ferramentas automaticamente.
3. Compilar o app e executar `NolaggyCoreTests` em simulador instalado. Priorizar `RemoteCatalogRepositoryTests` e `RemoteArtworkLoaderTests`; corrigir incompatibilidades Swift 6/concorrência/ImageIO reveladas pelo Xcode.
4. Validar em runtime arte remota, cache offline, falha/MIME/tamanho, fallback, atualização de catálogo, seleção/histórico por ID, cancelamento/retorno à Home e ausência de downloads de arte durante Check. Depois, prova em iPhone físico para rede e ciclo de vida.
5. Preparar assinatura do candidato com a chave vigente do Mac de publicação. Serviço Keychain: `com.buildea.lagcheck.catalog.ed25519.v3`; conta `publisher`. Confirmar existência sem imprimir/exportar segredo. **O signer atual cria uma chave se não encontrar a existente: não executar em Mac sem a chave vigente.** Não trocar a chave pública para contornar ausência.
6. Assinar os bytes LF exatos de `worker/catalog/catalog-v3.candidate.json`, com emissão/expiração explícitas e validade máxima de 30 dias, usando `worker/scripts/CatalogV3Signer.swift`. Validar com `worker/scripts/verify-catalog-envelope.mjs` antes de substituir qualquer envelope.
7. Após assinatura verificada: coordenar fonte canônica/Worker/base iOS/base Android e testes que ainda esperam versão antiga/22 jogos. Atualizar prateleira de referência/testes para refletir a descoberta dinâmica. Publicação Cloudflare e distribuição de builds exigem autorização explícita própria; não inferir a partir da implementação.

## Prompt de retomada

Continue a implementação de catálogo e artes remotos do LagCheck a partir de audits/mac-continuation-2026-10-03.md. Preserve Ed25519 do catálogo e não confira hash dos bytes das imagens, conforme Decisão 71. Primeiro valide a transferência, compile e execute os testes iOS no Xcode, depois faça QA de cache/fallback e pausa dos downloads durante Check. Preserve as mudanças existentes. Não crie nem rotacione chave, publique Cloudflare, envie TestFlight ou App Store sem minha autorização explícita. Informe separadamente implementação, build, testes, aparelho e publicação.
