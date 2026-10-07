# Architecture Plan — LagCheck Fase 3 (P2): Ecossistema & Fricção Zero

> Documento mantido por **Camillo** (Principal Engineer / System Architect) e **Marco** (Product Lead) conforme Decisões 63 e 76, governança Buildea (`AGENTS.md` e `.agents/WORKFLOW.md`).

---

## 1. Contexto & Problema
A Fase 3 (P2) do LagCheck estende a experiência do produto para o ecossistema iOS e elimina barreiras de adoção no Discord:
1. **Item 7 — In-App Events Sazonais:** Definição de eventos editoriais e roteamento universal (`https://lagcheck.app/check?game={id}`) para capturar tráfego orgânico na App Store.
2. **Item 8 — Spotlight Search & Siri Shortcuts:** Indexação local via `CoreSpotlight` (`CSSearchableItem`) dos jogos suportados e rotas com palavras-chave relevantes, além de App Shortcuts para Siri por voz e busca nativa.
3. **Item 9 — App Clip Instantâneo (`LagCheckClip`):** Uma experiência autônoma e ultraleve (< 15 MB) ativada por links compartilhados (`https://lagcheck.app/check?game=valorant` ou `lagcheck://check?game=valorant`). O jogador recebe a avaliação imediata sem instalar o aplicativo principal.

---

## 2. Escopo Arquitetural e Limites dos Módulos

```
                                    ┌────────────────────────────────────────────────────────┐
                                    │                     NolaggyApp                         │
                                    │  - Home, Result, Seletor, TechnicalDetailsView        │
                                    │  - SpotlightIndexCoordinator                           │
                                    └───────────────┬────────────────────────┬───────────────┘
                                                    │                        │
                    ┌───────────────────────────────▼────────┐      ┌────────▼───────────────────────┐
                    │          LagCheckClip (Novo)           │      │      LagCheckWidget (Fase 2)   │
                    │  - App Clip Target (< 15 MB)           │      │  - Lock Screen & Home Screen   │
                    │  - Standalone Single Screen Runner     │      │  - App Intents                 │
                    │  - Onboarding & Upsell to Main App     │      └────────────────────────────────┘
                    └───────────────┬────────────────────────┘
                                    │
                                    │ (Sem SwiftData / Sem Persistência Pesada)
                                    ▼
┌───────────────────────────────────▼────────────────────────────────────────────────────────┐
│                                    NolaggyApplication                                      │
│  - MeasurementTransportFactory                                                             │
│  - SpotlightIndexingDomainService                                                          │
│  - MeasurementSessionCoordinator                                                           │
└───────────────────────────────────┬────────────────────────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────────────────────────┐
│                                      NolaggyDomain                                         │
│  - DeepLinkParser: interpreta URLs (scheme e universal) extraindo gameID e plataforma     │
│  - SpotlightIndexableGame: modelo imutável de metadados para busca                         │
│  - GameReadinessVerdict, QualityMetrics & NGQE                                             │
└───────────────────────────────────┬────────────────────────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────────────────────────┐
│                                  NolaggyInfrastructure                                     │
│  - UDPMeasurementEngine & BSDWiFiLocalGatewayProber                                        │
│  - URLSessionRemoteCatalogFetcher & RemoteCatalogVerifier                                  │
│  - CoreSpotlightIndexer (Adapter com fail-safe para CoreSpotlight)                         │
└────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Especificação do App Clip (`LagCheckClip`)

### 3.1 Restrições Rigorosas da Apple & Custo Zero
- **Limite de Tamanho:** < 15 MB descompactado após compilação.
- **Dependências Permitidas:**
  - `NolaggyDomain` (lógica pura);
  - `NolaggyDesign` (Dark Competitive UI e tokens);
  - `NolaggyInfrastructure` (motor UDP e probe local);
  - Frameworks do sistema: `SwiftUI`, `Network`, `AppClip`.
- **Dependências Proibidas no Clip:**
  - `SwiftData` e repositórios de histórico de longo prazo (evita sobrecarga de schema e memória);
  - SDKs de analytics de terceiros (usamos zero analytics no Clip ou evento leve ao Worker único existente).

### 3.2 Identificadores e Entitlements
- **Bundle ID do Clip:** `com.lagcheck.app.Clip`
- **Parent Application Identifier:** `com.lagcheck.app`
- **Entitlements:**
  - `com.apple.developer.parent-application-identifiers`: `["$(AppIdentifierPrefix)com.lagcheck.app"]`
  - `com.apple.developer.associated-appclip-app-identifiers`: `["$(AppIdentifierPrefix)com.lagcheck.app.Clip"]`

### 3.3 Experiência de Usuário no Clip
1. Abre em `< 2s` na tela de medição instantânea do jogo recebido no parâmetro `?game={id}` (fallback para jogo em destaque ou rota de referência se parâmetro ausente).
2. Executa a medição de 3 fases UDP reais com animação esportiva.
3. Exibe o veredito semântico (`● PRONTO PARA RANKED` / `▲ EVITARIA RANKED AGORA`).
4. Exibe banner/card de conversão: *"Para histórico de partidas, gráficos detalhados e widgets na tela de bloqueio, baixe o LagCheck completo."*

---

## 4. Spotlight & Siri Shortcuts (Item 8)

### 4.1 Parser de Deep Links (`DeepLinkParser`)
Em `NolaggyDomain`:
- Suporta URLs tanto do esquema nativo quanto Universal Links:
  - `lagcheck://check?game=valorant&platform=pc`
  - `https://lagcheck.app/check?game=valorant`
  - `lagcheck://quicktest`
  - `lagcheck://network`
- Devolve enum determinístico:
  ```swift
  public enum AppDeepLink: Equatable, Sendable {
      case quickCheck(gameID: String?, platform: Platform?)
      case networkCockpit
      case gamesCatalog
      case home
  }
  ```

### 4.2 CoreSpotlight Indexing
- O `SpotlightIndexCoordinator` indexa os jogos populares e títulos disponíveis no catálogo local com:
  - Título: `LagCheck: {Nome do Jogo}`
  - Descrição: `Verificar ping e rota para {Nome do Jogo} antes da Ranked`
  - Palavras-chave: `[nome do jogo, "ping", "lag", "rota", "ranked", "conexão", "servidor"]`
  - Identificador único: `game-{game_id}`

---

## 5. Plano de Execução da Squad

| Agente | Responsabilidade |
| :--- | :--- |
| **Camillo** | Revisão dos targets XcodeGen, limites do App Clip e conformidade com Apple HIG. |
| **Rian (iOS)** | Implementação do `DeepLinkParser` no domínio, `SpotlightIndexCoordinator` e target `LagCheckClip`. |
| **Renan (Design)** | Layout Dark Competitive UI compacto para a tela única do App Clip e banner de conversão para o app principal. |
| **Iury (Rede)** | Validação de que a execução do Clip reutiliza o motor UDP sem duplicação de sockets. |
| **Breno (QA)** | Testes unitários para `DeepLinkParser`, validação de build limpo de todos os targets e auditoria pré-commit. |
| **Marco (Produto)** | Aceite funcional, texto dos atalhos e voz do produto nos banners de conversão. |

---

## 6. Critérios de Aceite & Conclusão
1. [x] Gate arquitetural aprovado e documentado;
2. [x] Decisão 76 registrada e indexada em `docs/DECISOES.md`;
3. [x] `DeepLinkParser` com testes unitários cobrindo todos os cenários de URL e parâmetros;
4. [x] `SpotlightIndexCoordinator` indexando itens sem travar a thread principal;
5. [x] Target `LagCheckClip` configurado e compilando com sucesso no Xcode;
6. [x] Suíte de testes `NolaggyUnitTests` e Gradle passando 100% verdes;
7. [x] Parecer de aprovação da auditoria independente Claude Code CLI antes de commit e push (Aprovado com B1, B2 e B3 sanados).
