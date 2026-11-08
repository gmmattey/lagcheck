# LagCheck — Decisão 35: Tela de Resultado HIG com Trilha Consolidada e Unificação da Jornada

**Status:** Decisão aprovada pelo Dono do Produto (Luiz) e implementada no binário iOS  
**Data:** 18 de setembro de 2026  
**Autores / Revisores:** Luiz (Dono do Produto), Marco (Produto), Renan (Design), Rian (iOS), Iury (Rede)  
**Complementa:** `docs/01-funcional.md`, `docs/02-arquitetura.md`, `docs/04-design-system.md`, `docs/07-voz-do-produto.md`, `docs/archive/decisoes/24-decisao-adocao-design-system-apple-games.md`, `docs/archive/decisoes/25-decisao-marca-lagcheck-coral-solar.md`, `docs/archive/decisoes/27-decisao-diagnostico-frequencia-wifi.md`, `docs/archive/decisoes/34-decisao-trilha-viva-medicao-e-estresse.md`

---

## 1. Contexto e Motivação de Produto (Marco)

Na evolução contínua da experiência do **LagCheck**, duas decisões de produto foram formalizadas pelo Dono do Produto:

1. **Eliminação do Conceito de "Quick Check":**  
   O usuário não deve escolher entre um teste preliminar incompleto e um "Deep Check". A experiência é unificada em um único teste direto: o **LagCheck**, que avalia a linha de base em repouso e a estabilidade sob carga controlada sem bifurcações artificiais na interface.
2. **Substituição do Anel Circular pelo Wireframe Editorial HIG:**  
   Durante a medição, a **Trilha Viva (`MeasurementLiveTrail`)** expõe os 3 nós da conexão em tempo real. No resultado, essa experiência se transforma no **Atestado da Rota (`RouteTrailSummaryCard`)**, complementado por um Hero editorial, Grid de Métricas 2x2 e Diagnóstico de Partida.

---

## 2. Wireframe Canônico Aprovado (Apple HIG)

A tela de resultado segue rigorosamente a hierarquia aprovada:

```
┌────────────────────────────────────────────────────────┐
│                        RESULTADO                       │
├────────────────────────────────────────────────────────┤
│                                                        │
│   [ 92 · EXCELENTE ]  ← Pílula semântica no topo       │
│                                                        │
│   Pronto para jogar                                    │
│   Sua rota para São Paulo está rápida e estável.      │
│   Fortnite · iPhone · São Paulo (AWS)                  │
│                                                        │
├────────────────────────────────────────────────────────┤
│  ATESTADO DA ROTA (Trilha Consolidada)                 │
│                                                        │
│   (✓) Seu iPhone          Dispositivo de teste         │
│        │                                               │
│   (✓) Wi-Fi local         5 GHz · Excelente (< 2 ms)   │
│        │                                               │
│   (✓) São Paulo (AWS)     Respondendo · 24 ms          │
│                                                        │
├────────────────────────────────────────────────────────┤
│  MÉTRICAS DETALHADAS (Grid 2x2 HIG)                    │
│  ┌───────────────────────┬──────────────────────────┐  │
│  │ 24 ms                 │ 1.2 ms                   │  │
│  │ Ping (Mediana P50)    │ Jitter (Variação)        │  │
│  ├───────────────────────┼──────────────────────────┤  │
│  │ 0%                    │ 0                        │  │
│  │ Perda de Pacotes      │ Picos de Latência        │  │
│  └───────────────────────┴──────────────────────────┘  │
│                                                        │
├────────────────────────────────────────────────────────┤
│  [Ícone Info] Diagnóstico de Partida                   │
│  Nenhuma interferência encontrada no seu Wi-Fi nem     │
│  na rota da internet. Aproveite a partida!             │
│                                                        │
│  [ BOTAO PRINCIPAL CORAL SOLAR: Testar Novamente ]     │
│                                                        │
│  [ Ver Detalhes Técnicos ]    [ Otimizar Conexão ]     │
└────────────────────────────────────────────────────────┘
```

---

## 3. Padrão Visual e Componentes Apple HIG (Renan)

* **Hero Editorial (Veredito Imediato):**
  - Pílula semântica no topo (`Capsule` com borda hairline de 0.5pt): exibe exclusivamente `[ 92 · EXCELENTE ]`, eliminando rótulos de fase técnica.
  - Título do veredito: tipografia `.system(size: 28, weight: .bold, design: .rounded)`.
  - Explicação amigável em `NLTypography.callout`.
  - Linha de contexto: `\(jogo) · \(plataforma) · \(região)` (ex.: `Fortnite · iPhone · São Paulo (AWS)`).

* **Atestado da Rota (`RouteTrailSummaryCard`):**
  - Três nós verticais encapsulados em cartão `RoundedRectangle(cornerRadius: 16, style: .continuous)` com bordas de 0.5pt.
  - Selos semânticos de validação ótica:
    - Verde (`checkmark.circle.fill`): nó saudável.
    - Âmbar (`exclamationmark.triangle.fill`): oscilação / instabilidade (ex.: Wi-Fi 2.4 GHz).
    - Coral Solar (`exclamationmark.triangle.fill`): gargalo severo ou perda.
  - Conectores visuais verticais contínuos integrando os saltos.

* **Grid de Métricas 2x2 HIG:**
  - Título de seção em caixa alta discreta: `MÉTRICAS DETALHADAS`.
  - Quatro cartões modulares com cantos contínuos de 12pt (`NLRadius.card`):
    - `Ping (Mediana P50)` (ms)
    - `Jitter (Variação)` (ms)
    - `Perda de Pacotes` (%)
    - `Picos de Latência` (quantidade)
  - Numerais destacados com `.monospacedDigit()` e design arredondado.
  - Realce automático de cor na borda e no valor caso uma métrica represente a causa primária de instabilidade.

* **Diagnóstico de Partida (`InsightBanner`):**
  - Card integrado com ícone semântico (`checkmark.shield.fill`, `info.circle.fill` ou `exclamationmark.triangle.fill`) traduzindo a saúde observada para a partida.

* **Barra de Ações:**
  - **Ação Primária (Coral Solar `#FF6B35`):** "Testar novamente" (`PrimaryButton`).
  - **Ações Secundárias (Linha de 2 Botões):**
    - "Ver Detalhes Técnicos" (abre `DeepCheckDetailsView` com dados aprofundados e impacto sob carga).
    - "Otimizar Conexão" (abre o Gemini Connection Booster).
  - Removido qualquer botão ou menção a "Fazer Deep Check".

---

## 4. Arquitetura e Implementação iOS (Rian)

1. **`DeepCheckResultView.swift`:**
   - Reescrito para implementar integralmente o wireframe canônico HIG.
   - Recebe contexto resolvido com `platform` e `regionFriendlyName` (`GlobalProbeRegistry.friendlyLabel`).
   - Apresenta o Atestado da Rota, Grid 2x2, Diagnóstico e Ações balanceadas.
2. **`ResultFeatureView.swift`:**
   - Atualizado com os mesmos títulos de métricas e remoção de qualquer menção a Quick/Deep Check.
3. **`Localizable.strings` (pt-BR, en, es):**
   - Chaves oficiais adicionadas: `result.title`, `result.route_trail.title`, `result.metrics.title`, `result.metric.ping`, `result.metric.jitter`, `result.metric.loss`, `result.metric.spikes`, `result.action.optimize`, `result.action.details`, `result.diagnostic.title`.
