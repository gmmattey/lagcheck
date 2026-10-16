---
name: lagcheck-ui-handoff
description: >-
  Turn a LagCheck UI change into a compact, testable iOS/Android handoff with
  states, copy, tokens, native interaction notes, and acceptance evidence.
  Do not use it to define network rules or implement the screen.
---

# LagCheck UI Handoff

Use this skill whenever a visible screen, component, navigation path, or
user-facing state changes. Start from the Cartão de Missão and produce the
smallest handoff that lets Renan, Rian, Iury, and Breno agree on behavior before
implementation.

## Required handoff

- User decision supported and non-scope.
- State matrix: initial, loading/measuring, success, error, cancelled,
  inconclusive, and any permission/network-change state that applies.
- Token/component mapping; no local visual values.
- PT-BR and English copy, including recovery action and diagnostic limits.
- iOS and Android interaction notes: navigation/back, insets/sheets, focus,
  and any intentional platform difference.
- Acceptance cases for Dynamic Type/font scale, VoiceOver/TalkBack, contrast,
  touch target, reduced motion, and evidence expected from simulator/emulator
  versus physical hardware.

## Diagnostic boundary

Consume the domain contract supplied by Iury/Rian. Do not convert absent radio
data, insufficient UDP samples, or an estimate into a cause, score, or promise.
Use `—` or the approved inconclusive state where evidence is absent.

## Completion

Attach the handoff to the Cartão de Missão. Renan approves the experience
specification; Rian confirms implementation understanding before code begins.
