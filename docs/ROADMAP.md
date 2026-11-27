# LagCheck — Roadmap, Backlog e Estado Atual

**Última atualização:** 2026-11-27 (Missão 01 — Foundation)  
**Fonte de diagnóstico:** Auditoria da Missão 00 (fatos verificados no repositório e suítes locais)

---

## 1. Estado Atual por Plataforma

Diferenciação explícita entre o que existe no código (**Implementado**), o que tem cobertura automatizada (**Testado**), o que passou por prova em hardware/ambiente real (**Homologado**) e o que está entregue aos usuários (**Publicado**).

| Plataforma | Implementado | Testado (automatizado) | Homologado (prova física / real) | Publicado / Tags |
| :--- | :--- | :--- | :--- | :--- |
| **Motor KMP (`:core:domain`)** | `readiness-v3.0`, `deep-load-impact-v4`, `load-transfer-v3`, `sample-quality-v2`, `spike-pattern-v2`, `stability-summary-v2`, `root-cause-v2`, `use-cases-v1` | `22` arquivos de teste (`6` `commonTest` + `16` `jvmTest`); artefatos pré-compilados (`XCFrameworks/debug`, `dist/js`, JVM) | Paridade lógica validada por vetores normativos; prova física das regras v3 pendente nos apps | Consumido em produção por iOS, Android e Site; Windows em protótipo |
| **iOS (`apps/ios/`)** | 4 abas, Check UDP + carga HTTP, mapa, histórico SwiftData, share (cards + vídeo 14s), PDF, Widget, App Clip, Spotlight/Intents, Host Duel, AdMob Native + UMP, Firebase Analytics | `60` arquivos de teste (`30` Domain, `8` Application, `2` Design, `17` Infrastructure, `3` UI) | Simulador validado em entregas anteriores; **prova em iPhone físico pendente** para Decisões 135, 136 e 147 | Tag mais recente: `ios-v1.2-b13`; `project.yml` em `1.1 (12)` |
| **Android (`apps/android/`)** | 4 abas, Check UDP + carga HTTP + rádio Wi-Fi, catálogo remoto `ETag`, histórico JSON, share (cards + vídeo 14s), PDF, Widget, auto-updater (`directApk` vs Play), Host Duel, AdMob Native + UMP, Firebase Analytics | `13` arquivos unitários em `app/src/test` + suítes `:core:*`. **`app/src/androidTest` inexistente** (0 testes instrumentados) | Emulador validado em entregas anteriores; **prova em Android físico pendente** para Decisões 135, 136 e 147 | Tag mais recente: `android-v1.3-b12` (Play `alpha` sem ads; APK GitHub com ads) |
| **Windows (`apps/windows/` + `engine-host`)** | Protótipo WinUI 3 (`Este PC`, Biblioteca Steam/Epic/Xbox, Galeria, Check contextual, Histórico `stability-summary-v2`, Status `/api/status`, i18n, Inno Setup). GA4 inativo no pacote WinUI | `13` arquivos xUnit (`LagCheck.WinUI.Tests`), `1` arquivo / `6` testes (`ProtocolTest.kt`), `21` arquivos (`:desktop`). Sem CI no GitHub Actions | Pendente de validação visual/DPI em Windows real (Decisões 139–142) | Protótipo **não publicável** sem autorização explícita; tag `windows-v0.3.0` |
| **Worker (`apps/worker/`)** | `GET /v1/load`, `POST /v1/telemetry`, além de rotas legadas fora do contrato (`/v1/waitlist`, `/v1/click`, `/v1/visit`, `/v1/report/test`, `/artwork/games/*`, cron Workers AI) | `59/59` testes `node --test` passando (executados em 2026-11-27) | Em produção (`nolaggy-deep-check`) | Publicado em Cloudflare Workers |
| **Site (`pages/lagcheck`)** | Landing, guias de jogos/plataformas, blog, status, comparador de operadoras, `/check`, `/squad`, `/v1/approx-location`, `/api/catalog-v3.json`, `/api/status`; consome `lagcheck-engine` JS | Suítes `vitest`, `astro check` e `check-site.mjs` presentes (não executadas nesta missão) | Publicado no domínio `lagcheck.signallq.com` | Publicado em Cloudflare Pages |

---

## 2. Estratégia de Testes

- **Domínio KMP (`:core:domain`):** Toda regra de veredito, score, carga, picos ou estabilidade exige vetores normativos em `commonTest`/`jvmTest` antes de qualquer alteração nos apps.
- **Clientes Mobile (iOS e Android):**
  - *Unitários / Contrato:* Obrigatórios a cada entrega (`NolaggyUnitTests` no iOS; `:core:domain:allTests` e `:app:testProductionDebugUnitTest` no Android).
  - *Instrumentados / UI:* iOS possui 3 arquivos em `NolaggyUITests`; Android precisa estabelecer cobertura mínima de smoke test em `androidTest` (Missão 04).
  - *Aparelho Físico (Gate Obrigatório):* Simulador/emulador não valida UDP real, troca Wi-Fi ↔ 4G/5G, permissões de rádio, UMP/AdMob ou ciclo de vida em background. Nenhuma versão avança para distribuição sem prova física registrada.
- **Windows:** `LagCheck.WinUI.Tests` (contrato NDJSON, persistência, estabilidade) + `:engine-host:test` + conferência visual em Windows real (100%–200% DPI).
- **Worker & Scripts:** `npm test --prefix apps/worker` e `python3 -m unittest discover -s shared/scripts/tests -v` via CI (`analytics-ci.yml`).

---

## 3. Roadmap Oficial (Missões 01–08)

| Missão | Nome | Objetivo | Critério de saída | Status |
| :--- | :--- | :--- | :--- | :--- |
| **01** | **Foundation** | Consolidar modelo operacional por missões, fontes únicas de verdade, roadmap, backlog e Obsidian | Documentação coerente, instruções centralizadas, zero código alterado | **Concluída** |
| **02** | **Integrity** | Corrigir desvios comprovados de telemetria, check geral, marca, segurança `Secrets.plist` e preparar prova física | Correções implementadas e testadas; `GEMINI_API_KEY` revogada (27/11/2026); **homologação física pendente** | **Implementada / Testada** |
| **03** | **Cleanup** | Eliminar código morto no iOS (Gemini Booster, views mortas), Android e rota `/v1/visit` no Worker; mapear catálogo | Código morto removido e testado; Worker/catálogo mapeados; **homologação física pendente** | **Implementada / Testada** |
| **04** | **Reliability** | Criar smoke tests instrumentados (`androidTest`) no Android e CI automatizado para Windows | `6/6` `androidTest` no emulador; `.github/workflows/windows-ci.yml` criado (não executado remotamente); `:core:domain:allTests` verde | **Implementada / Testada** |
| **05** | **Experience** | Avaliar experiência real (iOS/Android/Site), corrigir UI tests iOS e propor evolução de jornada, 64s, catálogo, NAT e métricas | UI tests PT/EN corrigidos; capturas reais coletadas; proposta consolidada | **Reconciliada pela 05A** |
| **05A** | **Production Baseline** | Investigar divergência da captura iOS na Missão 05, estabelecer baseline de produção (`1.2`) e regra de rastreabilidade | Causa comprovada (`DerivedData` `1.0.3 (9)`), build isolado capturado (`ios_m05a_home.png`), governança atualizada | **Concluída** |
| **05B** | **Experience Refinement** | Compactar Favoritos vazios e tirar I/O da Main Thread no Android; baseline progressivo; early-exit pré-leitura; eventos GA4; corrigir share UI test iOS | Home iOS preservada; `androidTest` `8/8`; `CheckCompletoResultUITests` `4/4`; `NolaggyUnitTests`, `:core:*` e APK verdes | **Implementada / Testada** |
| **06** | **Release** | Consolidar RCs iOS `1.3 (15)` e Android `1.4 (15)`, notas comerciais, checklists de lojas e gate de homologação física | RCs gerados e assinados (`94b88d3`), suítes verdes; **homologação em aparelho físico e autorização do Luiz pendentes** | **RC Gerado / Pendente Homologação Física** |
| **07** | **Desktop** | Consolidar WinUI 3, desacoplar scanners do legado `:desktop`, validar DPI 100–200% e decidir GA4/auto-update | Protótipo Windows limpo, testado em Windows real e pronto para eventual autorização | Planejada |
| **08** | **Growth** | Evoluir retenção, compartilhamento viral, ASO e comparador de operadoras com base em métricas reais | Experimentos mensuráveis no funil sem quebrar custo zero ou integridade diagnóstica | Planejada |

---

## 4. Backlog Priorizado (Insumos da Missão 00)

> **Regra de classificação:** Achados observados em código estão marcados como **Fato verificado**. Riscos potenciais de segurança/privacidade ainda não explorados em runtime estão classificados como **Hipótese** até comprovação.

### Missão 02 — Integrity (Implementada / Testada · Homologação física pendente)
- **[Concluído · Segurança iOS]** `Secrets/Secrets.plist` removido de `apps/ios/project.yml` e `Nolaggy.xcodeproj`; **`GEMINI_API_KEY` revogada pelo Luiz em 27/11/2026** (sem geração de nova chave).
- **[Concluído · Android]** Corrigido `analyticsGamePlatform` (`Platform.MOBILE -> "mobile"`) em `ProductAnalytics.kt` / `MainViewModel.kt` com teste de regressão em `ProductAnalyticsEventTest.kt`.
- **[Concluído · Android]** Unificado `onStartGeneralCheck` em `MainActivity.kt` para usar `viewModel.startGeneralCheck()` (`OfficialGameCatalog.genericGaming`), com teste em `GeneralCheckContractTest.kt`.
- **[Concluído · Android]** Removidas funções mortas em `VerdictScreen.kt` e excluído `LagCheckDiscordCardExporter.kt`; compartilhamento consolidado em `ShareMediaRenderer`.
- **[Concluído · iOS]** Atualizado `LagCheckClip.swift` para wordmark oficial `"Lagcheck"`.
- **[Pendente · Hardware físico]** Executar roteiro de homologação física (Wi-Fi, 4G/5G, consentimento, carga, troca de rede, cancelamento, ciclo de vida, AdMob/UMP, telemetria, compartilhamento) em iPhone e Android reais.

### Missão 03 — Cleanup (Implementada / Testada)
- **[Concluído · iOS]** Removida pilha morta do Gemini Booster (6 arquivos + wiring em `DeepCheckFeatureView`/`CheckCompletoResultView`/`VocabularyGuardrail`) e 3 views/exportadores mortos (`DeepCheckResultView`, `DeepCheckDetailsView`, `LagCheckDiscordCardExporter`) + stub `startBackgroundQuickCheck()`.
- **[Concluído · Android]** Removido fluxo morto `Screen.NetworkCockpit`, `NetworkReportPdfExporter`, composables `HomeTopBar`/`SecondaryScreenHeader`/`GameArtworkView`, `setSelectedConnectionType`, `reminderEnabled()`, drawables obsoletos e deps `ui.tooling`.
- **[Concluído · Worker]** Removido endpoint no-op `/v1/visit`; preservados `/v1/load`, `/v1/telemetry`, `/v1/click`, `/artwork/games/*`, `WAITLIST_KV` e `/v1/waitlist` (pendente atualização de `privacy/index.astro` no site).
- **[Pendente · Missão 05]** Consolidar catálogo único (site `124` jogos vs apps `56` vs desktop/worker `54`, `ruleVersion` `2026.09.08.1` → `2026.11.14.1` e `assetBaseURL`).

### Missão 03 — Cleanup
- **[Fato] Pilha Gemini Booster morta no iOS:** Remover `GeminiConnectionBoosterService.swift`, `ConnectionBoosterCoordinator.swift`, `ConnectionBoosterSheet.swift`, `BoosterComponents.swift`, `ConnectionBoosterTests.swift` e desacoplar `DeepCheckFeatureView.swift`.
- **[Fato / Hipótese de segurança] `Secrets/Secrets.plist` no bundle iOS:** Verificar dependências residuais de `Secrets/Secrets.plist` em `apps/ios/project.yml` e removê-lo se pertencer apenas ao Gemini morto (*hipótese: exposição desnecessária de chaves em bundle se houver valor configurado*).
- **[Fato] Telas mortas no iOS:** Limpar `DeepCheckResultView.swift`, `DeepCheckDetailsView.swift`, `ResultFeatureView.swift` e `QuickCheckBackgroundMeasurement.swift` (stub vazio), mantendo apenas a casca necessária em `QuickCheckFeatureView.swift`.
- **[Fato / Hipótese de privacidade] Worker fora do contrato:** Remover `/v1/waitlist` (`WAITLIST_KV` com e-mail/PII — *hipótese de risco de privacidade/conformidade caso dados ainda existam em produção*), `/v1/click`, `/v1/visit`, `/v1/report/test`, `/artwork/games/*` e cron `growth-intelligence.js` após checar referências no site (`pages/lagcheck`).
- **[Fato] Catálogo e regras legadas:** Alinhar ou limpar `apps/worker/catalog/catalog-v3.candidate.json` (`*-2026.09.08.1`) e avaliar remoção de `DeepCheckLoadImpactRuleV1` se não for mais necessária para compatibilidade histórica.

### Missão 04 — Reliability (Implementada / Testada · CI Windows não executado remotamente)
- **[Concluído · Android]** Criados `LagCheckAppSmokeTest.kt` e `VerdictAndHistorySmokeTest.kt` em `apps/android/app/src/androidTest`; `6/6` aprovados no emulador `signallq_validacao` (`1m 6s`).
- **[Concluído · Windows CI]** Criado `.github/workflows/windows-ci.yml` (`LagCheck.WinUI.Tests` + build WinUI + `:engine-host:test` + `:desktop:test`). Pendente execução remota no GitHub Actions.
- **[Concluído · KMP]** `:core:domain:allTests` (JVM, iOS Simulator Arm64, JS Browser e JS Node) + `:engine-host:test` + `:desktop:test` aprovados (`41s`).
- **[Concluído · Processo]** Estratégia de validação em 3 níveis documentada em `.agents/WORKFLOW.md`.
- **[Insumo · Missão 05]** `CheckCompletoResultUITests` (UI test pré-existente no iOS) falhou no simulador e precisa de alinhamento na Missão 05.

### Missão 05 — Experience
- **[Fato] NAT fixado em `false` no iOS:** Avaliar ativação ou remoção do indicador em `CheckCompletoResultDomain.swift:200` (`natEvaluated = false`).
- **[Hipótese de produto] Duração do Check (~64s):** Monitorar taxa de abandono após Decisão 135 (60 probes por fase) para decidir se há necessidade de ajuste de UX na espera.

### Missão 07 — Desktop
- **[Fato] Acoplamento `:engine-host` → `:desktop`:** Extrair scanners/preferências para módulo não-UI próprio e aposentar a UI Compose Desktop (`0.1.0`).
- **[Fato] GA4 inativo e auto-update parcial no WinUI:** Decidir ativação de `Ga4Config` no empacotamento WinUI e suporte a download/instalação de release no `DiagnosticEngineClient`.
