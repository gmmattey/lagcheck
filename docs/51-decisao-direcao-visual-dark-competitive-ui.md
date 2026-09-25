# LagCheck — Decisão 51: Direção Visual Dark Competitive UI e Iniciativa Unificada

**Status:** decidido pelo Dono do Produto; em especificação e implementação  
**Data:** 25 de setembro de 2026  
**Responsáveis:** Luiz (produto), Marco (produto), Renan (design), Rian (iOS), Iury (rede)  
**Consolida e integra:** decisões 04, 21, 24, 25, 34, 35, 42, 47 e 50.  
**Iniciativa Unificada:** *“Lagcheck Competitive Redesign + Ready Check”*.

---

## 1. Contexto e Motivação: O Benchmark NoPing

A análise de referências consagradas no ecossistema gamer de performance (especialmente o [NoPing](https://noping.com/pt)) evidenciou que a direção estética anterior do LagCheck — fortemente ancorada em um padrão "Apple utilitário" com cards cinzas arredondados e semelhança a ferramentas de rede/NOC — afasta o produto da sensação de alta performance que os jogadores valorizam.

O ponto forte do NoPing e produtos análogos não é o neon ou o verde em si, mas o fato de que **tudo se comunica como produto gamer de performance**, e não como utilitário técnico de infraestrutura. A primeira dobra é imediata: fundo escuro profundo, headline orientada a benefício, CTA dominante e o próprio jogo em protagonismo absoluto.

Para o LagCheck, adotamos os mesmos princípios fundamentais de impacto e foco, preservando nossa sobriedade, honestidade diagnóstica e a identidade Coral Solar.

### Matriz Comparativa de Posicionamento Visual

| Elemento | NoPing | LagCheck (Dark Competitive UI) |
|---|---|---|
| **Paleta** | Preto + Verde Neon | Fundo quase preto / Grafite + **Coral Solar** |
| **Headline Central** | “Reduza seu ping” | **“Pronto pra jogar?”** / **“Sua conexão está pronta para jogar?”** |
| **Proposta Central** | Otimização ativa de rota | Diagnóstico determinístico de prontidão (*Readiness*) |
| **Protagonista** | Capas de jogos comerciais | **Artwork abstrato/autoral do jogo em destaque** |
| **Telemetria** | Dashboard de NOC com muitos gauges | **Veredito em 1º lugar + telemetria compacta** |
| **Jornada** | Escolha jogo → Boost | **Escolha jogo → Check → Veredito** |
| **Densidade de Dados** | Muitos números de hardware/rede | Poucas métricas essenciais, contextualizadas |
| **Estética Geral** | Gamer agressivo / RGB | **Gamer premium, limpo, focado em alta performance** |
| **Ação Primária** | Verde neon dominante | **Coral Solar exclusivo para ação** |

---

## 2. Princípios da Dark Competitive UI

A direção visual abandona a fórmula "app técnico escuro + cards arredondados + HIG utilitário" e assume a identidade **Gamer Competitivo Premium**:

1. **Fundo Quase Preto e Superfícies Grafite:** O ambiente visual é imersivo (`#0B0D10`), eliminando gradientes azulados decorativos e o cinza claro de utilitários iOS genéricos.
2. **O Jogo como Protagonista:** O artwork do jogo (usando arte autoral/abstrata gerada, respeitando a ausência de logos proprietários) ocupa o espaço central de prestígio na tela.
3. **Fim do "Card Soup":** Menos cartões soltos empilhados; adoção de **painéis integrados com borda fina** (1px em `rgba(255, 255, 255, 0.08)`).
4. **Tipografia Pesada e Direta:** Títulos grandes, caixa alta compacta para identificadores de métricas (`PING`, `JITTER`, `PERDA`, `REGIÃO`), números estritamente monoespaçados e eliminação de tipografia "arredondada/fofa".
5. **Coral Solar como Assinatura de Ação:** O Coral Solar (`#FF5A36`) é a única cor de ação primária e estados de destaque. O verde não é cor da marca; é restrito semanticamente ao veredito positivo (`● PRONTO PARA RANKED`).
6. **Telemetria Viva sem Ruído:** Animação de pulso/sinal em tempo real durante o teste que comunica performance, sem transformar a tela em um velocímetro de NOC.

---

## 3. Especificação das Telas Principais

### 3.1. Home (Dark Competitive Home)

A Home elimina carrosséis pesados e múltiplos cartões competindo por atenção:

```text
┌─────────────────────────────────────┐
│  lagcheck                       ••• │
│                                     │
│  PRONTO PRA JOGAR?                  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │                               │  │
│  │   [ ARTE ABSTRATA VALORANT ]  │  │
│  │                               │  │
│  └───────────────────────────────┘  │
│  VALORANT                           │
│  São Paulo                          │
│                                     │
│  [        FAZER CHECK        ]      │
│                                     │
│  Último check                       │
│  ● Estável · 28 ms · hoje 18:42     │
│                                     │
│  SEUS JOGOS                         │
│  [CS2]  [LoL]  [Fortnite]  [EA FC] →│
│                                     │
│  Início                        Jogos│
└─────────────────────────────────────┘
```

- **Headline:** `PRONTO PRA JOGAR?` em destaque bold.
- **Painel do Jogo:** Imagem ampla do título atual com nome e região associada.
- **CTA Dominante:** Botão largo em Coral Solar `[ FAZER CHECK ]`.
- **Status do Último Check:** Indicador discreto em linha única com dot semântico.
- **Trilho Rápido:** Lista horizontal compacta com os jogos frequentes do usuário.
- **Navegação Inferior:** Apenas 2 abas: **Início** e **Jogos**.

---

### 3.2. Tela de Check (Live Telemetry Pulse)

Substitui animações utilitárias de "download de internet" por uma tela escura de telemetria de alta precisão com animação de pulso central:

```text
┌─────────────────────────────────────┐
│                                     │
│  VALORANT                           │
│  VERIFICANDO SUA ROTA               │
│                                     │
│  28 ms                              │
│  ───╲_╱──╲_╱──                      │
│                                     │
│  Estabilidade  ●●●●●○○              │
│  Testando São Paulo · 12 segundos   │
│                                     │
│  "Verificando estabilidade..."      │
│                                     │
└─────────────────────────────────────┘
```

- **Animação Central:** Pulso gráfico de sinal ativo `───╲_╱──╲_╱──`.
- **RTT Vivo:** Valor de latência em tempo real com `.monospacedDigit()`.
- **Barra de Estabilidade:** Indicador segmentado simples e limpo.
- **Micro-telemetria rotativa no rodapé:**
  - *"Verificando estabilidade..."*
  - *"Procurando perda de pacotes..."*
  - *"Testando a conexão sob uso..."*
  - *"Comparando com o perfil do Valorant..."*

---

### 3.3. Tela de Resultado (Verdict-first + Compact Telemetry)

Apresenta a decisão de jogo de forma instantânea, com dados técnicos compactados:

#### Caso 1: Conexão Saudável (Pronto para Jogar)
```text
┌─────────────────────────────────────┐
│  VALORANT · SÃO PAULO               │
│                                     │
│  ● PRONTO PARA RANKED               │
│  Sua conexão está estável agora.    │
│                                     │
│  ┌───────────────────────────────┐  │
│  │   28 ms        2 ms       0%  │  │
│  │   PING        JITTER    PERDA │  │
│  └───────────────────────────────┘  │
│                                     │
│  Estabilidade  ━━━━━━━━━━━━━━━━━━━● │
│  Nenhuma oscilação relevante        │
│  encontrada durante o teste.        │
│                                     │
│  [      TESTAR NOVAMENTE      ]     │
│                                     │
│  Entender minha conexão >           │
└─────────────────────────────────────┘
```

#### Caso 2: Conexão Degradada / Risco (Evitar Partida)
```text
┌─────────────────────────────────────┐
│  VALORANT · SÃO PAULO               │
│                                     │
│  ▲ EU EVITARIA RANKED AGORA         │
│  Detectamos perda de pacotes.       │
│                                     │
│  ┌───────────────────────────────┐  │
│  │   41 ms       18 ms     3,2%  │  │
│  │   PING        JITTER    PERDA │  │
│  └───────────────────────────────┘  │
│                                     │
│  O que encontramos                  │
│  ▲ Perda de pacotes                 │
│  ▲ Picos de latência                │
│  ● Resposta do destino normal       │
│                                     │
│  [      TESTAR NOVAMENTE      ]     │
│                                     │
│  Entender o problema >              │
└─────────────────────────────────────┘
```

---

## 4. O Que NÃO Absorvemos do NoPing

Para manter a credibilidade técnica e foco do LagCheck:
1. **Sem Verde Neon na Marca:** O verde neon descaracteriza a identidade LagCheck e soa derivativo. A cor de ação do LagCheck é o **Coral Solar**.
2. **Sem Slogans Impossíveis:** Evitamos "zero lag", "80% menos ping" ou "conexão perfeita". O valor do LagCheck reside na honestidade do diagnóstico.
3. **Sem Inflação de Features:** Não introduzimos VPN, otimizador de FPS, bypass de IP, macros ou aim trainers.
4. **Sem Prova Social Forjada:** Não inventamos contadores de milhões de usuários. Destacamos dados concretos do produto (*"20+ jogos no catálogo"*, *"Rotas competitivas monitoradas"*, *"Ping, Jitter, Perda e Carga medidos em um único Check"*).

---

## 5. Tokens do Design System (Dark Competitive)

```json
{
  "color": {
    "background": {
      "deep": "#0B0D10",
      "surface": "#15181E",
      "panel": "#1E232B"
    },
    "border": {
      "hairline": "rgba(255, 255, 255, 0.08)",
      "focused": "#FF5A36"
    },
    "text": {
      "primary": "#F4F5F7",
      "secondary": "#8A93A0",
      "tertiary": "#555E6C"
    },
    "brand": {
      "coralSolar": "#FF5A36"
    },
    "semantic": {
      "ready": "#22C55E",
      "caution": "#F59E0B",
      "notReady": "#EF4444"
    }
  },
  "typography": {
    "headline": "SF Pro / Display Bold, Tracking Tight",
    "metricsNumber": "SF Pro / Monospaced Heavy",
    "metricsLabel": "SF Pro / Bold, Small Caps, Tracking Wide"
  }
}
```

---

## 6. Unificação do Roadmap: Epic Única

Esta direção visual não será desenvolvida após o reposicionamento funcional, e sim de maneira conjunta:

**`Lagcheck Competitive Redesign + Ready Check`**

As cinco entregas da Decisão 50 (E1 a E5) agora adotam nativamente a **Dark Competitive UI**, entregando o produto refinado em uma única grande iteração visual e técnica.
