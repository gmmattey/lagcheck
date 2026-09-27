# Nolaggy — decisão 24: adoção definitiva do Design System Apple Games Editorial Hub

**Status:** decisão aprovada pelo dono do produto (Luiz) e implementada no binário iOS  
**Data:** 18 de setembro de 2026  
**Substitui / Atualiza:** `docs/04-design-system.md` (seções 1 e 2), `docs/10-decisao-experiencia-piloto.md`, `docs/21-decisao-direcao-visual-simplicidade.md`, `docs/22-decisao-jornada-lista-nativa-e-background-check.md`  
**Referência Canônica:** `design-system/prototypes/ios-reference/source/Nolaggy iOS Prototype.dc.html` e `design-system/tokens/`  

---

## 1. Contexto e Motivação

O usuário e o dono do produto identificaram que as versões anteriores do app apresentavam divergências com a experiência nativa iOS: listas simples sem hierarquia visual, ícones genéricos em cinza e elementos com estética que não correspondia ao padrão editorial premium do ecossistema Apple Games.

Após a criação do protótipo canônico **Apple Games Editorial Hub** e avaliação independente de design (nota 9.5/10), formalizou-se a transição definitiva da arquitetura visual do Nolaggy para a linha editorial nativa do iOS (Apple Games / App Store).

---

## 2. Pilares da Direção Visual (Apple Games HIG)

1. **Tipografia 100% Nativa SF Pro**:
   - Remoção completa de fontes externas (`Oxanium`), eliminando ruído gamer clichê.
   - Adoção estrita de pesos e tamanhos do SF Pro Display / SF Pro Text:
     - Large Title (`34pt bold`) para os títulos principais das abas.
     - Titles (`20-24pt bold`) para seções editoriais e cards de destaque.
     - Headline / Subheadline (`15-16pt semibold/regular`) para títulos de jogos e listas.
     - Footnote / Caption (`11-13pt`) com `NLColor.textSecondary` (`#8E8E93`) para metadados e rotas.

2. **Padronização Rígida de Cabeçalhos**:
   - Conforme diretriz do usuário, os cabeçalhos de todas as abas principais utilizam **exclusivamente o Large Title do sistema** ("Início", "Jogos", "Histórico", "Ajustes"), sem subtítulos descritivos anexados ao topo (como "qualidade da rota").
   - Apenas ações contextuais mínimas no topo: botão circular de refresh na Home.

3. **Paleta de Cores e Superfícies Nativas (True Black & Inset Cards)**:
   - Fundo base: True Black OLED (`#000000`).
   - Superfície elevada (`NLColor.backgroundRaised`): `#1C1C1E` (Apple Dark Mode Secondary).
   - Superfície terciária (`NLColor.backgroundOverlay`): `#2C2C2E`.
   - Divisores e bordas: `rgba(84, 84, 88, 0.35)` e contornos sutis com opacidade suave.
   - Acento primário: iOS Blue (`#007AFF`).
   - Sem halos, neons ou glows artificiais.

4. **Escala de Arredondamento (Apple HIG Corner Radii)**:
   - Cards e Inset Lists: `12pt` (`NLRadius.card`).
   - Hero Carousel Cards: `26pt` (`NLRadius.hero`).
   - Botões de Ação: `14pt` (`NLRadius.button`).
   - Modais / Sheets: `16pt` (`NLRadius.sheet`).
   - Controles e Chips: `8-10pt` (`NLRadius.controlSmall` / `NLRadius.controlMedium`).

---

## 3. Composição de Telas e Navegação

1. **Navegação Raiz via TabView Nativa**:
   - O app adota um `TabView` permanente com 4 abas no padrão HIG:
     - **Início** (`house.fill`): Editorial Hub com Card de Status de Rede, Carrossel "Em Destaque", Shelf "Mais Jogados no Brasil" e Lista Rápida.
     - **Jogos** (`gamecontroller.fill`): Catálogo completo com Search Bar nativa, filtros por chips de categoria (Todos, Battle Royale, Competitivo, Casual) e lista Inset Grouped de alta densidade.
     - **Histórico** (`clock.arrow.circlepath`): Histórico de medições em repouso e sob carga.
     - **Ajustes** (`gearshape.fill`): Configurações de região, diagnóstico de beacon UDP, detalhes do catálogo assinado e suporte.

2. **Artes dos Jogos e Resolução Dinâmica**:
   - O componente `GameArtwork` resolve dinamicamente as capas limpas em alta fidelidade (`GameFortnite`, `GameWildRift`, `GameCodm`, `GameRoblox`, `GameFreeFire`, `GameBrawlStars`, `GamePubg`, `GameMinecraft`) cadastradas em `Assets.xcassets`.
   - Elimina o fallback persistente para ícones cinzas genéricos de controle.

3. **Fluxo do Jogo e Diagnóstico com IA**:
   - Ao tocar em qualquer jogo em qualquer aba, abre a `GameDetailView` dedicada:
     - Anel de score determinístico e veredito contextualizado.
     - Seletor nativo de plataforma (iPhone, PS5, Xbox, PC, Switch) e tipo de conexão (Wi-Fi vs Cabo).
     - Acionamento direto para o **Deep Check** sob carga.
     - No resultado do Deep Check, acionamento para o **Gemini Connection Booster** via `ConnectionBoosterSheet`.

---

## 4. Evidência Técnica e Confiabilidade

- **Alvos compilados**: `NolaggyDesign`, `NolaggyDomain`, `NolaggyApplication`, `NolaggyInfrastructure`, `Nolaggy` (`** BUILD SUCCEEDED **`).
- **Testes Unitários**: 45/45 testes aprovados (`NolaggyApplicationTests`: 28/28, `NolaggyInfrastructureTests`: 17/17) (`** TEST SUCCEEDED **`).
- O determinismo das medições de rede e a integridade do cálculo de score permanecem rigorosamente inalterados.
