---
name: camillo-engenharia-e-arquitetura
description: Padrões de arquitetura, motores de rede determinísticos, contratos e implementação full-stack (mobile nativo e web) do Camillo.
---

# Skill: camillo-engenharia-e-arquitetura

Esta skill guia o **Camillo** na engenharia de software de ponta a ponta: do motor de rede à montagem das telas.

## 1. Separação de Responsabilidades (Fronteiras Claras)
- **Motor Puro (Engine):** Módulos de medição e rede não conhecem frameworks de interface (SwiftUI, Compose, HTML). Não fazem suposições de layout.
- **Telas & UI:** Telas apenas observam estados reativos (`StateFlow`, `@Observable`, signals/props) e despacham intenções do usuário. Nunca disparam chamadas de rede avulsas ou calculam métricas diretamente.
- **Contratos Compartilhados:** Modelos de domínio possuem esquemas tipados, imutáveis e testáveis.

## 2. Rigor Diagnóstico e de Rede
- **Verdade para o Usuário:** Falha, timeout, desconexão ou ausência de dados **NUNCA** viram zero, nota inventada ou sucesso silencioso.
- **Métricas Determinísticas:** Cada medição possui protocolo (UDP, TCP, ICMP, HTTP), timeout explícito, cancelamento gracioso e tratamento para perda de pacotes.
- **Isolamento de Domínios:** Diferencie estritamente problemas locais (LAN / Wi-Fi / Roteador) de problemas externos (WAN / Operadora / Rota do servidor).

## 3. Disciplina de Código Full-Stack
- **Mudanças Cirúrgicas:** Altere apenas o necessário para a missão aprovada. Não refatore código alheio sem necessidade explícita.
- **Proteção do WIP:** Leia `git status` e preserve alterações em andamento.
- **Auto-Revisão:** Antes de passar para o Renan, revise o próprio diff, execute testes automatizados locais e liste arquivos tocados e eventuais limitações técnicas.

## 4. Motor KMP Único, Windows, Telemetria e Atualização (Decisões 114–120, 134–143)
- **Motor compartilhado (`apps/android/core/domain`):** Kotlin Multiplatform (`commonMain`) gera os alvos `jvm` (Android, desktop e `engine-host`), XCFramework `LagCheckEngine` (iOS) e pacote JS (site). Nenhuma regra numérica de veredito, score, carga, picos ou `stabilitySummary` deve ser duplicada em Swift, C# ou TypeScript (`ENGINE_CONTRACT.md`).
- **Windows WinUI 3 (`apps/windows/LagCheck.WinUI/`):** consome o motor KMP via `apps/android/engine-host/` (`DiagnosticEngineClient` + NDJSON) e `ILibraryBridge` (Decisão 119). A prévia anterior em Compose Desktop (`apps/android/desktop/`) também reaproveita `core:*` sem duplicar regras.
- **Telemetria (Windows):** GA4 Measurement Protocol com os mesmos eventos e parâmetros de `ProductAnalytics.kt` (Android), `client_id` UUID local, um único desfecho por medição, inerte sem ID/segredo e em build de desenvolvimento. O ID de medição e o segredo nunca entram no repositório (público): `~/.gradle/gradle.properties` ou variáveis de ambiente.
- **Atualizador (Gate obrigatório, baixa e executa código):** fonte constante (GitHub Releases deste repositório, tags `windows-vX.Y.Z`), HTTPS, lista fechada de hosts (inclusive em redirecionamento), SHA-256 confere antes de executar, sem downgrade, sem elevação silenciosa, download em streaming, `.msi` por `msiexec /i`, falha de rede silenciosa e sem travar a abertura. A UI diz "verificado por checksum", nunca "assinado".
- **Endpoints do site (fora do Worker):** localização aproximada (`GET /v1/approx-location`, só `request.cf`, arredondado a 0,5°, sem registro) e status de plataformas (`GET /api/status`). O Worker `nolaggy-deep-check` serve somente `/v1/load` e `/v1/telemetry`.
- **Validação local:** `./gradlew :core:domain:allTests :app:testProductionDebugUnitTest` (em `apps/android/`), `xcodebuild test ... -scheme NolaggyUnitTests` (iOS) e `dotnet test apps/windows/LagCheck.WinUI.Tests/LagCheck.WinUI.Tests.csproj` (WinUI) antes de passar ao Renan. Armadilhas Kotlin: `var x` com `fun setX` (colisão JVM), lambda final no parâmetro errado, smart cast entre módulos, imports de animação.
