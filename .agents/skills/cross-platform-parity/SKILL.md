---
name: cross-platform-parity
description: >-
  Verify the LagCheck iOS and Android clients preserve the same supported
  behavior for shared inputs, while recording approved native differences.
  Do not use it to force pixel-identical UI or redefine network rules.
---

# Cross-Platform Parity

Use this skill for changes that touch shared domain rules, catalog/session
consumption, history semantics, result presentation, or another behavior
implemented in both clients.

## Contract first

- Identify the shared input, expected output, rule/schema version, and source
  of truth. Reuse Swift/Kotlin vectors where they exist.
- State the mandatory shared behavior: score/verdict semantics, reason codes,
  invalidation, persistence meaning, and localization intent.
- State native differences explicitly. Android-only radio facts or approved
  gateway behavior are not regressions when documented; they must not silently
  change the user promise.

## Evidence matrix

For each case, record iOS result, Android result, test/vector or manual path,
and remaining physical validation. Compare the actual rendered state as well as
the domain output when the change is visible.

## Ownership and boundary

Iury owns rule truth; Rian owns client integration; Renan verifies user-facing
parity; Breno independently checks risk paths. This skill does not authorize a
new threshold, protocol, catalog route, or visual redesign.
