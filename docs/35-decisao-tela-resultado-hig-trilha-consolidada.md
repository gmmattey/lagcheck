# LagCheck — Decisão 35: Tela de Resultado HIG com Trilha Consolidada e Grid de Métricas

**Status:** Decisão aprovada pelo Dono do Produto (Luiz); em implementação  
**Data:** 18 de setembro de 2026  
**Autores / Revisores:** Luiz (Dono do Produto), Marco (Produto), Renan (Design), Rian (iOS), Iury (Rede)  
**Complementa:** `docs/01-funcional.md`, `docs/04-design-system.md`, `docs/07-voz-do-produto.md`, `docs/10-decisao-experiencia-piloto.md`, `docs/11-decisao-detalhes-e-historico-local.md`, `docs/24-decisao-adocao-design-system-apple-games.md`, `docs/25-decisao-marca-lagcheck-coral-solar.md`, `docs/27-decisao-diagnostico-frequencia-wifi.md`, `docs/34-decisao-trilha-viva-medicao-e-estresse.md`

---

## 1. Contexto e Motivação de Produto (Marco)

A experiência de medição do LagCheck foi aprimorada pela **Trilha Viva de Medição (`MeasurementLiveTrail`)**, que ilustra o fluxo de pacotes em tempo real através dos 3 nós da rede.

Na transição para a tela de **Resultado**, o usuário recebia um anel de score circular e uma lista vertical de métricas, criando uma descontinuidade visual com a trilha observada durante o teste.

Para elevar a experiência ao padrão das **Human Interface Guidelines (HIG) da Apple** e ao estilo **Apple Games Editorial Hub**, a tela de resultado é reestruturada em torno de 4 componentes integrados:
1. **Hero Editorial (Veredito Imediato):** Pílula semântica com o LagCheck Score e conclusão verbal em destaque.
2. **Atestado da Rota (Trilha Consolidada):** Os 3 nós da medição convertidos em um atestado visual com selos de status (`checkmark.circle.fill` / `exclamationmark.triangle.fill`), permitindo identificar em 1 segundo a saúde de cada salto.
3. **Grid de Métricas 2x2 HIG:** Cards agrupados compactos com curvatura contínua de 12pt, tipografia `.monospacedDigit()` e realce de cor para a causa raiz.
4. **Painel de Ações Contextual:** Priorização inteligente da próxima ação (ex.: Deep Check em caso de instabilidade; novo teste em caso de sucesso).

---

## 2. Padrão Visual Apple HIG (Renan)

* **Cards e Contêineres:** `RoundedRectangle(cornerRadius: 16, style: .continuous)` com borda sutil hairline de 0.5pt.
* **Tipografia:** SF Pro nativo com Dynamic Type. Números e valores usam `.monospacedDigit()` com design arredondado (`.system(..., design: .rounded)`).
* **Selos de Status Semânticos:**
  * Sucesso / Conforme: `NLColor.scoreExcellent` (`#34C759`)
  * Atenção / Instabilidade: `NLColor.scoreUnstable` (`#FFD60A`)
  * Risco de Lag / Falha: `NLColor.coralSolarRed` (`#FF3823`)
* **Acessibilidade:** Suporte completo ao VoiceOver com leitura ordenada do veredito, atestado de cada trecho e métricas individuais.

---

## 3. Arquitetura e Componentes iOS (Rian)

* **Novo Componente:** `RouteTrailSummaryCard` em `NolaggyDesign` (ou extensão de Resultado) para renderizar a trilha consolidada de 3 saltos.
* **Refatoração:** `ResultFeatureView.swift` atualizado com o layout Hero Editorial, Trilha Consolidada, Grid 2x2 e Action Bar.
