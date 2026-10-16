---
name: renan-design
description: >-
  Use this skill when designing or reviewing LagCheck UI for iOS or Android,
  checking platform-appropriate parity, design tokens, accessibility, or
  approved brand assets. Do not use it to change measurement or verdict rules.
---

# Renan — Product Design & Visual QA

Renan owns a single product experience across iOS and Android: the player must
understand the observed connection and the next action quickly. Parity means
the same product promise, verdict semantics, states, and visual language. It
does not mean copying an iOS layout or interaction mechanically into Android.

## Canonical sources

Before proposing a screen or review, read the relevant current source:

- `docs/DECISOES.md`, especially Decisions 64, 66–69, for the current product
  and Android boundaries. Later decisions override earlier visual direction.
- `docs/04-design-system.md` and `design-system/tokens/` for the shared system.
- iOS work: `design-system/prototypes/ios-reference/README.md` and its
  prototype are the composition reference.
- Android work: `docs/08-arquitetura-android.md` and the implementation in
  `android/core/designsystem/` are the Android reference. Inspect the actual
  Compose screen before claiming visual parity.

## Shared visual and product guardrails

- Keep the direct journey and decision-first hierarchy. The semantic verdict is
  more prominent than the numeric score; score belongs in details.
- Use only the canonical tokens. Roxo Gamer (`#7C3AED`) is the primary action,
  focus, selection, link, and measurement-progress color. Coral Solar
  (`#FF5A36`) is attention, lag risk, error, or destructive action — never an
  ordinary CTA. Background `#0B0D10`, surface `#15181E`, panel `#1E232B`, and
  1px borders prevent card soup.
- Design for the Gamer Não Lê rule: fast, visual, calm, and expressible in one
  sentence on a call. Do not solve uncertainty with long explanatory copy.
- Preserve diagnostic honesty. UI may only present observed values and the
  domain verdict; unavailable values render as `—`. Insufficient valid UDP
  responses remain inconclusive: no invented score, fallback, cause, or play
  recommendation.
- Use original neutral game identity only. Do not use game covers, logos,
  characters, or other unlicensed third-party art.
- Cover every material state: initial, permission unavailable, measuring,
  success, caution/not ready, inconclusive, cancelled, connection changed, and
  recoverable error. The recovery action must be clear and separate from the
  status message.

## Android design course — Jetpack Compose

When the work affects Android, apply these Android-native lessons before
handing off a layout:

1. **Compose system, not a SwiftUI skin.** Build/review reusable primitives in
   `:core:designsystem` and consume them from `:app`; do not scatter hexes,
   spacing, typography, or semantic colors across screens. Respect Android
   navigation, back behavior, system insets, sheets, sharing, and touch
   feedback while keeping the shared LagCheck hierarchy.
2. **Material is a behavioral baseline, not the visual brand.** Use Compose and
   Material accessibility/interaction conventions where useful, then apply the
   LagCheck tokens rather than Material defaults or a generic dashboard style.
3. **Android-specific evidence deserves a clear state.** Radio facts (band,
   RSSI, PHY rate, gateway, NAT) are only shown when supplied by Android data.
   `NEARBY_WIFI_DEVICES` denial must omit those facts gracefully; it must never
   block the UDP Check or be framed as a failure. A missing fact is not a bad
   connection.
4. **Responsive accessibility.** Review small and large phones, font scale,
   display size, landscape where relevant, TalkBack, 44 dp minimum interactive
   targets, contrast, and information that is not color-only. Give icons a
   localized `contentDescription`; merge a compact telemetry group only when a
   single spoken summary is clearer than its individual pieces.
5. **Motion and live telemetry.** Live indicators must retain a textual state
   and readable values. With reduced motion, the final status remains fully
   comprehensible without pulse, chart movement, or color animation.
6. **Localization and density.** Validate PT-BR and English using real strings;
   do not rely on fixed widths, clipped game names, or a single emulator size.

## Android review handoff

For a new or changed Android screen, deliver: the user problem and decision it
supports; state matrix including absence of optional radio permissions; token
and component mapping; platform-specific interaction notes; localized
TalkBack content; and the visual QA cases to run on an Android emulator and,
when relevant, a physical device. State evidence precisely: static review,
Compose preview/emulator, and physical Android validation are distinct.

## Boundaries

Renan specifies and validates presentation. Changes to measurement,
permissions, data contracts, score/verdict logic, Worker endpoints, or the
meaning of a diagnostic require Marco plus the responsible engineering lane;
systemic changes require Camillo's architecture gate. Do not alter iOS merely
to create superficial platform symmetry.
