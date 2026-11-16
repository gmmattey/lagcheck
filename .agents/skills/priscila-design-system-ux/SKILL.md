---
name: priscila-design-system-ux
description: Diretrizes de design, UX/UI, tokens semânticos, acessibilidade e auditoria visual da Priscila para plataformas Apple (iOS), Android, Windows e Web.
---

# Skill: priscila-design-system-ux

Esta skill guia a **Priscila** na definição de jornadas, fidelidade de protótipos e auditoria visual.

## 1. Princípios de Experiência
- **Protagonismo do Dado:** O veredito vem antes das métricas; o número medido, o mapa ou o status são a estrela. Zero ornamentos vazios, zero "card soup" ou linhas de contorno desnecessárias (Decisão 128).
- **Ergonomia por Plataforma:**
  - **iPhone / Android (Mobile):** Área de alcance do polegar, 4 abas (`Início`, `Jogos`, `Histórico`, `Ajustes`/`Configurações`), títulos de tela sempre em **CAIXA ALTA** (Decisão 145), barra de busca padronizada (`#15181E`, `12 px`, sem borda/sombra), Hero edge-to-edge com `TESTAR AGORA` (`#7C3AED`, altura `46`), `Populares` 2×3 e `Jogos` em 3 colunas (Decisões 144 e 145).
  - **Windows (WinUI 3):** Janela nativa sem sidebar (`Este PC` e contexto por jogo, atalhos no topo — Decisões 141 e 142), adaptação documentada em `apps/windows/DESIGN.md`.
  - **Web:** Responsividade fluida, carregamento instantâneo e mesma tríade tipográfica e paleta (`shared/design-system/DESIGN.md`).

## 2. Design System & Tokens
- **Cores & Camadas Tonais:** Fundo `#0B0D10`, superfície `#15181E`, painel `#1E232B`. Hierarquia visual construída por contraste entre superfícies e elevação sutil, não por linhas de contorno em cards, pílulas, busca ou anúncios (Decisão 128). `#7C3AED` é exclusivo do CTA principal.
- **Tipografia:** Tríade unificada (Decisão 125) — **Barlow Semi Condensed** (títulos e vereditos), **Barlow** (corpo e controles) e **Chakra Petch** (métricas e kickers com algarismos tabulares `tnum`).
- **Dark Mode Exclusivo:** Fundo `#0B0D10` em todas as telas mobile e web (e preto `#000000` estrutural no Windows — Decisão 138).

## 3. Acessibilidade (A11y) Inegociável
- **Conformidade WCAG AA:** Relação mínima de contraste de 4.5:1 para textos essenciais (`#606873` restrito a metadados/apoio).
- **Dynamic Type:** Todos os textos escalam com as preferências do sistema.
- **Independência de Cor:** Nenhuma informação depende exclusivamente de cor; use ícones e rótulos textuais claros.
- **Alvos de Toque:** Mínimo de 44 × 44 pt (iOS) / 44–48 dp (Android) / 40–44 px (Windows) para todos os botões e controles interativos.

## 4. Auditoria Visual
- Compare a tela real aberta com `shared/design-system/DESIGN.md` e `apps/windows/DESIGN.md`.
- Audite todos os estados: vazio (empty state), carregando (loading), resultado bem-sucedido, inconclusivo, erro e modais.
- Se o Camillo encontrar um caso de borda não previsto, a especificação volta para alinhamento antes do código.

## 5. Windows (protótipo interno, Decisões 114–120 e 137–143)
- A especificação vigente para **WinUI 3** fica em `apps/windows/DESIGN.md` (`apps/windows/LagCheck.WinUI/Styles/Theme.xaml` e `Controls/Typography.cs`), herdando o núcleo de `shared/design-system/DESIGN.md`.
- A prévia anterior em Compose Desktop (`apps/android/desktop/`) e `docs/09-design-system-windows.md` seguem preservados para referência histórica; capturas via `./gradlew :desktop:shots` em `apps/android/`.
