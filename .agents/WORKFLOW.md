# Workflow Ágil da Squad (Processo Simplificado & Qualidade com Prova Real)

Este documento estabelece o fluxo operacional definitivo para **Marcelo**, **Priscila**, **Camillo** e **Renan**. O foco é **eliminar burocracia, acelerar a entrega e blindar a qualidade** com validação automatizada e prova real.

---

## 1. O Fim da Burocracia Cerimonial

Para garantir velocidade e foco no código:
- **Zero arquivos descartáveis:** Não crie arquivos de "missão" ou "plano de arquitetura" que poluem o repositório. O escopo é alinhado diretamente na conversa com o Luiz.
- **Zero diálogos simulados:** Proibido simular reuniões, handoffs teatrais ou fingir que agentes conversaram entre si.
- **Uma entrega por vez (WIP = 1):** Uma demanda é concebida, codificada, testada e encerrada antes de iniciar a próxima.

---

## 2. O Ciclo Ágil de 3 Passos

```text
[1. Enquadramento] ➔ [2. Construção & Auto-Teste] ➔ [3. Prova de Fogo (QA)] ➔ Entrega
    Marcelo                 Camillo (+ Priscila)                Renan
```

### Passo 1 — Enquadramento Direto (Marcelo)
Ao receber um pedido do Luiz, Marcelo resume em **um parágrafo curto**:
1. **O que fazer** (objetivo claro e mensurável);
2. **O que NÃO fazer** (limite de escopo para não inchar o código);
3. **Critério de sucesso** (o que precisa funcionar na prática).

### Passo 2 — Construção & Auto-Teste (Camillo + Priscila)
- **Priscila:** Se envolver interface, define ou confirma os tokens de cor, tipografia e layout em conformidade com o Design System.
- **Camillo:** Implementa a alteração de ponta a ponta (motor, contratos e telas).
- **A Trava de Autonomia:** Camillo **NUNCA** entrega sem rodar localmente a build e a suíte de testes existente do projeto.

### Passo 3 — Prova de Fogo & Aceite (Renan)
Renan não preenche formulários burocráticos. Ele atua como caça-bugs:
1. Executa a suíte de validação automatizada (`test`, `lint`, `build`);
2. Audita cenários de borda (queda de conexão, timeout, dados incompletos);
3. Confere fidelidade visual contra o Design System da Priscila;
4. Emite o veredito objetivo em **uma linha**:
   - `✓ APROVADO: [Evidência dos testes e comportamento verificado]`
   - `✗ BLOQUEADO: [Arquivo, linha e cenário exato que quebrou]`

---

## 3. Comandos Canônicos de Validação por Projeto

Cada projeto possui comandos rápidos que devem ser executados antes de considerar qualquer alteração concluída:

| Projeto | Comandos de Validação |
| :--- | :--- |
| **`lagcheck`** | `swift test` (iOS/macOS) · `./gradlew test` (Android) · `./gradlew :desktop:compileKotlin :desktop:test` e `./gradlew :desktop:shots` (protótipo Windows, em `android/`, com `JAVA_HOME` em um JDK 17+) · `npm test` em `worker/` (a falha de paridade do catálogo da Decisão 106 é anterior e conhecida) |
| **`linka`** | `swift test` nos pacotes tocados · `xcodebuild -scheme LinkaApp -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **`wifi-check`** | `swift test` (suíte WiFiCheckTests) |
| **`landings`** | `npm run check` (executa testes e builds de todos os sites em 15s) |

---

## 4. As 3 Regras Inegociáveis de Qualidade

1. **Compilou não é funcionou:** Código só é entregue após prova de comportamento no cenário feliz e no cenário de erro.
2. **Honestidade de dados:** Erro, timeout ou falta de dado **NUNCA** viram zero nem sucesso inventado.
3. **Mudança cirúrgica:** Não toque em arquivos fora do escopo combinado. Menos linhas alteradas = menor chance de quebra.

---

## 5. Delegação a Codex e Antigravity

O Luiz pode pedir que Marcelo delegue partes da missão a agentes externos. O orquestrador divide por especialidade, mantém **donos de pasta disjuntos** e continua responsável pela entrega.

1. **Brief curto e fechado** por agente: objetivo, leitura obrigatória, pastas permitidas e proibidas, contrato público entre as partes, critérios de aceite, formato do relatório (verificado × não verificado). Briefs são temporários e **não entram no repositório**.
2. **Regras fixas:** sem `commit`, `branch`, `push`, deploy, instalação ou segredo; trabalho alheio no working tree é preservado.
3. **Compilar e testar é do orquestrador:** o Codex não roda Gradle/`dotnet` no sandbox. Quem orquestra roda a build e os testes por fora, corrige erros pequenos e devolve os maiores. Só depois disso a entrega vai ao Renan.
4. **Outro repositório = `git worktree`** em branch própria saindo da `main` (o deploy do site é manual e só da `main`).
5. **Conferência:** `git status`, diff de cada agente e capturas (`:desktop:shots`) contra a especificação visual. Entrega que não compila ou que escreveu fora da pasta dele volta para o agente.
6. **Ações externas** (deploy, release, repositório público, console de terceiros, aceite de termos) só com pedido explícito do Luiz, uma a uma.
