---
name: renan-design
description: >-
  Use this skill when designing or implementing UI components, checking visual
  parity with canonical iOS prototypes, reviewing design tokens in NolaggyDesign,
  ensuring accessibility compliance, or handling brand assets.
---

# Renan — Product Design & UI/UX Runbook

This skill encapsulates design system stewardship, UI consistency, Dark Competitive UI, and accessibility for LagCheck.

## Key Principles & Guardrails
- **Visual Direction (`docs/51` — Dark Competitive UI)**:
  - High-performance gamer aesthetic, clean and premium (inspired by performance benchmarks like NoPing, avoiding generic "Apple utility" gray cards).
  - Palette: Deep almost-black background (`#0B0D10`), graphite surfaces (`#15181E`), dark panels (`#1E232B`), warm white text (`#F4F5F7`), cool secondary gray (`#8A93A0`).
  - Action Accent: **Coral Solar (`#FF5A36`)** is the sole primary action color. Green (`#22C55E`) is strictly semantic for ready state (`● PRONTO PARA RANKED`), never brand/action color.
  - Fine Hairline Borders (1px `rgba(255, 255, 255, 0.08)`): Eliminates "card soup" in favor of unified, sharp panels.
  - Typography: Heavy headlines in SF Pro Display Bold, `.monospacedDigit()` for live telemetries, uppercase tracking for technical labels (`PING`, `JITTER`, `PERDA`). No cutesy/rounded fonts.
- **Key Screens**:
  - **Home**: `PRONTO PRA JOGAR?`, hero game artwork (own/abstract, no third-party licensed logos/art), game name + region, dominant Coral CTA `[ FAZER CHECK ]`, 1-line last check dot, horizontal `SEUS JOGOS`, and 2 tabs only (`Início | Jogos`).
  - **Live Check**: Deep black background, central live signal pulse `───╲_╱──╲_╱──`, RTT mono, stability bar, rotating micro-telemetry.
  - **Result**: Decision first (`● PRONTO PARA RANKED` / `▲ EU EVITARIA RANKED AGORA`), compact 3-metric row, stability bar, and "What we found" checklist. Score 0–100 hidden in technical details.
- **Neutral Game Identity (`docs/18`)**: Never use official licensed covers or trademarked third-party logos.
- **Accessibility**: 44pt minimum tap target, high contrast, Dynamic Type scaling, VoiceOver labels, and color-independent state indicators.
