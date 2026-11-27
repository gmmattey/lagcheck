# Workflow Ágil da Squad (Processo Simplificado & Qualidade com Prova Real)

Este documento estabelece o fluxo operacional definitivo para **Marcelo**, **Priscila**, **Camillo** e **Renan**. O foco é **eliminar burocracia, acelerar a entrega e blindar a qualidade** com validação automatizada e prova real.

---

## 1. O Fim da Burocracia Cerimonial

Para garantir velocidade e foco no código:
- **Zero arquivos descartáveis:** Não crie arquivos de "missão" ou "plano de arquitetura" que poluem o repositório. O escopo é alinhado diretamente na conversa com o Luiz.
- **Zero diálogos simulados:** Proibido simular reuniões, handoffs teatrais ou fingir que agentes conversaram entre si.
- **Uma entrega por vez (WIP = 1):** Uma demanda é concebida, codificada, testada e encerrada antes de iniciar a próxima.

---

## 2. Fluxo Operacional por Missões (9 Etapas + Ciclo da Squad)

Toda evolução do LagCheck segue o **modelo orientado a missões** (adaptado na Missão 01) integrado ao ciclo ágil de 3 passos da squad:

```text
[1. Enquadramento] ➔ [2. Construção & Auto-Teste] ➔ [3. Prova de Fogo (QA)] ➔ Entrega
    Marcelo                 Camillo (+ Priscila)                Renan
```

1. **Definição do objetivo** *(Marcelo)*: 1 parágrafo curto com o que fazer, o que NÃO fazer e critérios de aceite objetivos.
2. **Reconhecimento do estado existente** *(Camillo)*: ler código, testes e `git status` sem presumir que algo funciona só porque existe código.
3. **Verificação de componentes reutilizáveis** *(Camillo + Priscila)*: priorizar `:core:domain` (KMP), tokens de `shared/design-system/` e componentes existentes.
4. **Registro de decisões (se aplicável)** *(Marcelo)*: atualizar `docs/DECISOES.md` antes de codar quando houver regra nova.
5. **Implementação incremental** *(Camillo)*: mudança cirúrgica com WIP = 1, sem alterar escopo combinado.
6. **Testes** *(Camillo)*: **NUNCA** entregar sem rodar localmente a build e a suíte unitária/contrato aplicável.
7. **Validação funcional** *(Renan)*: validar cenários de borda, fidelidade visual e prova em aparelho físico quando tocar rede, rádio, ciclo de vida ou anúncios; emitir veredito em 1 linha (`✓ APROVADO` ou `✗ BLOQUEADO`).
8. **Atualização do status** *(Marcelo)*: atualizar `docs/ROADMAP.md` e `Obsidian/GMMATTEY/Lagcheck/`.
9. **Entrega de evidências** *(Marcelo + Renan)*: separar **fatos verificados** (implementado × testado × homologado × publicado), **hipóteses** e **próximos passos**.

---

## 3. Estratégia de Validação Rápida (3 Níveis) e Comandos Canônicos

Para evitar burocracia e saber exatamente o que rodar após cada alteração:

| Nível | Quando usar | Objetivo |
| :--- | :--- | :--- |
| **Nível 1 — Desenvolvimento** | Durante edições locais | Feedback rápido de compilação e regras puras (`jvmTest`, `NolaggyUnitTests`, `node --test`, `dotnet test`) |
| **Nível 2 — Integração** | Antes de fechar a missão | Suítes completas por plataforma, contratos KMP (`allTests`), builds (`assembleProductionDebug`, `Nolaggy` + `LagCheckClip`, `LagCheck.WinUI`) e `androidTest` em emulador |
| **Nível 3 — Release** | Antes de TestFlight / Play / Produção | Homologação em **aparelho físico** (roteiro da Missão 02: Wi-Fi, 4G/5G, carga, troca de rede, cancelamento, ciclo de vida, AdMob/UMP, telemetria, share), notas comerciais e aprovação explícita do Luiz |

| Plataforma | Nível 1 (Desenvolvimento) | Nível 2 (Integração) |
| :--- | :--- | :--- |
| **KMP (`:core:domain`)** | `./gradlew :core:domain:jvmTest` (em `apps/android/`) | `./gradlew :core:domain:allTests` (JVM + iOS Simulator + JS) |
| **Android (`apps/android/`)** | `./gradlew :app:testProductionDebugUnitTest` | `./gradlew :core:domain:allTests :core:catalog:test :core:network:test :core:session:test :app:testProductionDebugUnitTest :app:assembleProductionDebug :app:connectedProductionDebugAndroidTest` |
| **iOS (`apps/ios/`)** | `xcodebuild test -project Nolaggy.xcodeproj -scheme NolaggyUnitTests -destination "id=$SIM_ID"` | `xcodebuild test -scheme NolaggyUnitTests` + `xcodebuild build -scheme Nolaggy` (inclui `LagCheckWidget` e `LagCheckClip`) |
| **Windows (`apps/windows/`)** | `dotnet test apps/windows/LagCheck.WinUI.Tests/LagCheck.WinUI.Tests.csproj` | `.github/workflows/windows-ci.yml`: `LagCheck.WinUI.Tests` + `dotnet build LagCheck.WinUI.csproj -c Release -p:Platform=x64` + `./gradlew :engine-host:test :desktop:test` |
| **Worker (`apps/worker/`)** | `npm test --prefix apps/worker` | `.github/workflows/analytics-ci.yml` (`npm test --prefix apps/worker` + `python3 -m unittest discover -s shared/scripts/tests -v`) |

---

## 4. As 3 Regras Inegociáveis de Qualidade

1. **Compilou não é funcionou:** Código só é entregue após prova de comportamento no cenário feliz e no cenário de erro.
2. **Honestidade de dados:** Erro, timeout ou falta de dado **NUNCA** viram zero nem sucesso inventado.
3. **Mudança cirúrgica:** Não toque em arquivos fora do escopo combinado. Menos linhas alteradas = menor chance de quebra.
4. **Rastreabilidade visual obrigatória:** Antes de capturar telas no simulador/emulador, compile em `-derivedDataPath` isolado (ou valide `Info.plist` + data do binário), desinstale builds antigos e registre plataforma, versão/build, commit, scheme e ausência de fixtures. Nunca use `find DerivedData/... | head -n1`.

---

## 5. Delegação a Codex e Antigravity

O Luiz pode pedir que Marcelo delegue partes da missão a agentes externos. O orquestrador divide por especialidade, mantém **donos de pasta disjuntos** e continua responsável pela entrega.

1. **Brief curto e fechado** por agente: objetivo, leitura obrigatória, pastas permitidas e proibidas, contrato público entre as partes, critérios de aceite, formato do relatório (verificado × não verificado). Briefs são temporários e **não entram no repositório**.
2. **Regras fixas:** sem `commit`, `branch`, `push`, deploy, instalação ou segredo; trabalho alheio no working tree é preservado.
3. **Compilar e testar é do orquestrador:** o Codex não roda Gradle/`dotnet` no sandbox. Quem orquestra roda a build e os testes por fora, corrige erros pequenos e devolve os maiores. Só depois disso a entrega vai ao Renan.
4. **Outro repositório = `git worktree`** em branch própria saindo da `main` (o deploy do site é manual e só da `main`).
5. **Conferência:** `git status`, diff de cada agente e capturas (`:desktop:shots`) contra a especificação visual. Entrega que não compila ou que escreveu fora da pasta dele volta para o agente.
6. **Ações externas** (deploy, release, repositório público, console de terceiros, aceite de termos) só com pedido explícito do Luiz, uma a uma.
