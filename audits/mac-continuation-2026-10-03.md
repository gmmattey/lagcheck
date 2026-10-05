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

## Retomada no Mac — 3 de outubro de 2026

- Branch conferida e selecionada: `codex/remote-catalog-artwork`, commit de entrada `4195f32`. Arquivos locais não rastreados preservados. A branch não inclui os três commits posteriores da `main`; não houve merge nesta validação.
- Xcode 27.0 (27A266a), Swift 6, simulador iPhone 17 Pro / iOS 26.5. `xcodegen generate` incluiu `RemoteArtworkLoaderTests.swift` no projeto, que ainda não referenciava esse arquivo.
- App Debug: **BUILD SUCCEEDED**. `NolaggyCoreTests`: **326 aprovados, 2 ignorados, 0 falhas**. Ignorados: smoke de rede física e filtro de plataforma substituído pelo catálogo atual.
- Após ampliar a cobertura e corrigir os testes, execução dirigida de `RemoteArtworkLoaderTests` + `RemoteCatalogRepositoryTests`: **17 aprovados, 0 falhas**. Essa contagem sobrepõe parte da suíte completa; não deve ser somada como testes únicos.
- Cobertura adicionada: MIME/status/corpo inválidos, tamanho declarado, stream acima de 8 MiB sem EOF (interrupção antes do timeout HTTP), dimensões 4097, cache vencido com falha e preservação da idade, cancelamento durante corpo parcial, pausa e retomada. Dois testes de catálogo agora realmente ultrapassam 24h e confirmam uma chamada ao fetcher.
- Runtime: catálogo de 22 jogos exibido; cache do app no simulador com 22 artes / 22.092.696 bytes. Worker consultado por `curl`: catálogo e arte Fortnite HTTP 200; envelope remoto validado com o verificador Ed25519 vigente. Captura: `audits/ios-remote-catalog-simulator-2026-10-03.png`.
- Sem alteração no código de produção. Build contém avisos preexistentes de variável não usada, APIs depreciadas, assets de ícone não atribuídos e extração de AppIntents; não declarar warning-free.
- Artefatos locais: `/tmp/lagcheck-remote-artwork-build.log`, `/tmp/lagcheck-remote-artwork-core.xcresult`, `/tmp/lagcheck-remote-artwork-focused-final.xcresult`.

### Próximos gates

- iPhone físico listado como indisponível. Rede real, troca Wi-Fi/celular e ausência de sobreposição de tráfego de arte com probes ainda exigem prova física. Os testes de cancelamento usam URLProtocol controlado; não equivalem a captura de pacotes no aparelho.
- Poda do cache de 50 MiB e catálogo novo/removido em UI ainda sem prova dedicada nesta rodada. Cache offline/falha foi validado no loader; não houve desligamento da rede do Mac.
- Item de publicação encontrado no Keychain apenas por consulta de existência. Não foi lida/exportada a chave, nem executado o signer. A correspondência dessa chave com a pública vigente ainda precisa ser conferida ao assinar.
- Candidato de 26 jogos permanece não assinado/inativo. Os dois testes de expansão passaram (IDs/plataformas e artes/cópias), sem substituição dos envelopes.
- Sem deploy Cloudflare, upload TestFlight/App Store, commit ou push nesta retomada.
