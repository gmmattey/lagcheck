# Catálogo e arte remotos — evidência local

Escopo autorizado por Luiz na Decisão 71: catálogo assinado e imagens remotas sem conferência do hash do conteúdo, iOS e Android. Não houve publicação nem rotação de chave.

## Implementação

- iOS: fluxo de catálogo remoto existente mantido; cache remoto válido agora funciona mesmo com base inválida/expirada. Arte remota conectada à UI, cache de disco e fallback local. Loader lê fluxo limitado a 8 MiB e dimensões 4096×4096; pausa/cancelamento no Check e background.
- Android: lista de jogos e plataformas derivada do payload validado, novos IDs sem registro local. Home, favoritos, lista e grupos do histórico carregam arte remota com fallback local/neutro. Cache de 50 MiB, revalidação de 24 h, limite de transferência/decode, cancelamento por tela e pausa durante Check/background.
- Ed25519 do catálogo intacta. Campo SHA do schema 3 permanece como metadado compatível; bytes de imagem não são comparados a ele. Hash interno de URL serve somente para nomear arquivo de cache.
- Segunda opinião arquitetural independente revisou o plano e a implementação. Encontrou pausa permanente após cancelar Check no Android; corrigida com permissão derivada da tela/foreground e reexecução da tarefa de imagem. Revisão final sem novo bloqueador concreto.

## Validação

- Android: `:core:session:test :core:catalog:test` — 116 testes JVM verdes. Inclui três novos testes de apresentação: jogo desconhecido, remoção do catálogo e contextos indisponíveis/plataformas desconhecidas.
- Android: `:app:assembleDebug` e `:app:compileDebugKotlin` bem-sucedidos, usando Java/Gradle/SDK já instalados, offline. Há warnings existentes de APIs depreciadas/opt-in nos módulos; não declarar warning-free.
- iOS: testes adicionados para cache remoto com base inválida, imagem cujo conteúdo não coincide com digest, cache offline e URLs/caminhos recusados. **Não executados**: host Windows sem Xcode/SDK iOS. Revisão estática não equivale a build.
- Tentativa de smoke no AVD `Pixel_10`: boot concluído, instalação recusada com `INSTALL_FAILED_INSUFFICIENT_STORAGE`. Não apagamos dados do AVD. Conectividade restaurada e instância iniciada nesta sessão encerrada. Nenhuma validação visual ou de download em runtime obtida.
- `git diff --check` sem erro de whitespace; Git emitiu aviso de conversão LF/CRLF.

## Pendências de distribuição

Uma build inicial com esta implementação precisa ser instalada em cada plataforma. A expansão de quatro jogos continua em `worker/catalog/catalog-v3.candidate.json` (26 jogos, não assinado). Assinar no Mac com a chave vigente e publicar envelope/arquivos de arte no Worker existente são etapas externas distintas. Com o envelope válido publicado, esta implementação passa a receber jogos e artes sem nova edição da lista local. Não há prova de publicação, TestFlight, App Store ou aparelho físico.

## Complemento: validação iOS no Mac

Em 3 de outubro de 2026, app Debug compilado com Xcode 27.0 e executado em iPhone 17 Pro simulado / iOS 26.5. Suíte `NolaggyCoreTests`: 326 aprovados, 2 ignorados, zero falhas. Depois da ampliação dos testes de cache, respostas inválidas, limites e cancelamento durante transferência, a execução dirigida de catálogo/artes passou em 17 testes (contagem sobreposta à suíte completa). Nenhuma mudança no loader de produção foi necessária.

Downloads reais preencheram o cache do simulador com 22 artes. A inspeção visual confirmou a lista e as miniaturas. Os novos testes usam transporte controlado para falhas, offline e cancelamento; não comprovam condições de rádio ou ausência de tráfego durante probes no iPhone físico. Evidências, comandos-base e pendências estão no adendo de `mac-continuation-2026-10-03.md`.
