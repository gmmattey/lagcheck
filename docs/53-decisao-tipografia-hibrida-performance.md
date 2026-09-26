# 53 — Decisão de tipografia: Arquitetura Híbrida de Performance (Benchmark NoPing)

**Status:** decidido pelo Dono do Produto (Luiz); implementado  
**Data:** 25 de setembro de 2026  
**Responsáveis:** Luiz (Dono do produto), Marco (Produto), Renan (Design), Rian (Engenharia iOS)  
**Alinhamento Estratégico:** Decisões 50 (Ready for Ranked), 51 (Dark Competitive UI) e 52 (Dual-Node Vector)

---

## 1. Contexto e Motivação: Benchmark NoPing

A análise da tipografia utilizada no ecossistema e blog do [NoPing](https://noping.com/pt/blog) demonstrou que a sensação de alta performance e agressividade competitiva não decorre da aplicação de uma fonte decorativa em todos os textos da interface — o que destruiria a legibilidade de artigos e diagnósticos —, mas sim de uma **hierarquia tipográfica com papéis estritamente separados**:

1. **Headlines e Vereditos:** Tipografia densa, pesada (*Heavy / Black*), caixa-alta e tracking ajustado para impacto imediato de início de partida.
2. **Cockpit e Telemetria:** Leituras numéricas estritamente monoespaçadas com peso pesado, transmitindo precisão instrumental de hardware e bancada. Rótulos técnicos em *Small Caps* com tracking aberto (*wide*).
3. **Corpo e Diagnóstico:** Tipografia de sistema neutra e limpa (SF Pro Text no iOS) para conforto de leitura, zero fadiga visual e suporte nativo ao Dynamic Type da Apple.

---

## 2. Decisões Tomadas

### 2.1 Adoção da Arquitetura Tipográfica Híbrida
Fica formalmente adotada a divisão em três camadas tipográficas no app LagCheck:

| Camada | Tokens no Design System | Estilo Visual | Aplicação Prática |
| :--- | :--- | :--- | :--- |
| **1. Display & Veredito** | `NLTypography.competitiveHero`<br>`NLTypography.verdictHeadline`<br>`NLTypography.heroGameTitle` | Caixa-alta, peso Black/Heavy, tracking compacto (`-0.8` / `-0.5`) | `PRONTO PRA JOGAR?`, `● PRONTO PARA RANKED`, nome do jogo no card |
| **2. Ação & Cockpit** | `NLTypography.ctaButton`<br>`NLTypography.metricsNumberLarge`<br>`NLTypography.metricsLabel`<br>`NLTypography.sectionHeader` | Botões em caixa-alta (`+0.8`), números `.monospacedDigit()`, labels em Small Caps (`+1.5`) | `[ FAZER CHECK ]`, `28 ms`, `0%`, `PING`, `JITTER`, `PERDA`, `SEUS JOGOS` |
| **3. Leitura & Suporte** | `NLTypography.body`<br>`NLTypography.callout`<br>`NLTypography.footnote`<br>`NLTypography.caption` | SF Pro Text nativo, caixa natural, entrelinha confortável | Explicações de rede, diagnósticos sob carga, termos de consentimento, histórico |

### 2.2 Eliminação Definitiva da Tipografia "Rounded"
- É terminantemente proibido o uso de `design: .rounded` no app ou em componentes do `NolaggyDesign`.
- O estilo arredondado remetia a utilitários casuais infantis ou apps genéricos de produtividade. Todos os valores de score, latência e veredito foram migrados para `design: .default` com pesos pesados e dígitos monoespaçados.

---

## 3. Implementação e Tokens (`NLTypography.swift`)

```swift
public enum NLTypography {
    // MARK: - Dark Competitive Typography (NoPing Benchmark)
    public static let competitiveHero = Font.system(size: 32, weight: .black, design: .default)
    public static let verdictHeadline = Font.system(size: 28, weight: .heavy, design: .default)
    public static let heroGameTitle = Font.system(size: 22, weight: .heavy, design: .default)
    public static let ctaButton = Font.system(size: 16, weight: .heavy, design: .default)

    public static let metricsNumberLarge = Font.system(size: 32, weight: .heavy, design: .default).monospacedDigit()
    public static let metricsNumber = Font.system(size: 22, weight: .bold, design: .default).monospacedDigit()
    public static let metricsLabel = Font.system(size: 11, weight: .bold, design: .default)
    public static let sectionHeader = Font.system(size: 13, weight: .heavy, design: .default)
    public static let statusLine = Font.system(size: 13, weight: .medium, design: .default)

    // MARK: - Tracking Tokens
    public static let heroTracking: CGFloat = -0.8
    public static let verdictTracking: CGFloat = -0.5
    public static let metricsLabelTracking: CGFloat = 1.5
    public static let ctaTracking: CGFloat = 0.8
    public static let sectionTracking: CGFloat = 1.0
}
```

---

## 4. Impacto em Acessibilidade e Engenharia

1. **Acessibilidade Preservada:** Os textos de diagnóstico e corpo continuam 100% integrados ao **Dynamic Type** da Apple e ao VoiceOver sem distorções de renderização.
2. **Zero Overhead de Bundle:** A solução utiliza a versatilidade dos pesos e tracking do motor tipográfico nativo da Apple (SF Pro), sem adicionar arquivos TTF/OTF desnecessários ao binário do app.
3. **Consistência Visual:** Alinha a Home, a telemetria ao vivo e o resultado à nova identidade de alta performance.
