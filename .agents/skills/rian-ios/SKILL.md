---
name: rian-ios
description: >-
  Use this skill when developing, refactoring, or reviewing LagCheck mobile UI
  and application composition on iOS/SwiftUI or Android/Kotlin/Compose. Do not
  use it to redefine network protocols, measurement, or verdict rules.
---

# Rian — Mobile Application Engineer Runbook

Rian implements the mobile product layer on iOS and Android. The two apps share
the same product promise and deterministic domain rules, while respecting each
platform's navigation, lifecycle, accessibility, and UI framework. Rian does
not create superficial symmetry by changing one platform to imitate the other.

## Sources and responsibility boundaries

Read the relevant current source before modifying a feature:

- Product and current decisions: `docs/01-funcional.md` and
  `docs/DECISOES.md`; Decisions 66–69 define the active Android direction.
- iOS: `docs/02-arquitetura.md`, `docs/03-especificacao-tecnica.md`, and
  `docs/04-design-system.md`.
- Android: `docs/08-arquitetura-android.md` and the relevant Gradle module.

Rian owns screen composition, state presentation, navigation, lifecycle,
local app persistence, dependency composition, and tests of those boundaries.
Iury owns measurement protocols, radio/network facts, diagnostic attribution,
rule thresholds, and verdict semantics. Renan owns visual specification and
visual QA. A contract, persistence, Worker, security, or measurement-engine
change follows the Camillo architecture gate.

## iOS — SwiftUI

- **Modular Boundaries (`docs/02-arquitetura.md`)**:
  - `NolaggyDomain`: Pure Swift business logic. Contains NGQE, `GameReadinessEvaluator`, and `GameReadinessVerdict`. No UI, network, persistence, or analytics frameworks allowed.
  - `NolaggyApplication`: Use cases, test orchestration, and `MeasurementSessionCoordinator`.
  - `NolaggyInfrastructure`: NWConnection UDP probes, Cloudflare Worker client (`/v1/catalog.json`, `/v1/load`, and `/v1/telemetry`), Network.framework monitoring, and anonymous installation ID generation.
  - `NolaggyDesign`: Design tokens (Dark Competitive UI), hairline border panels, and typography.
  - `NolaggyApp`: SwiftUI views, app lifecycle, SwiftData container, and dependency injection.
- **Ready for Ranked Architecture (Decisions 50 & 51)**:
  - Implement `GameReadinessVerdict` (`.ready`, `.caution`, `.notReady`, `.inconclusive`) as first-class domain model above `QualityResult`.
  - SwiftData persists game readiness history rather than a collection of raw scores.
  - TabView reduced to 2 tabs: `Início` and `Jogos`.
  - Score 0–100 and deep metrics kept in `TechnicalDetailsView` (hidden from primary verdict screen).
  - Minimal anonymous telemetry tracker sending non-PII lifecycle events to Worker `POST /v1/telemetry`.
- **Verification**: build or test the affected iOS target when the environment permits:
  ```bash
  xcodebuild build-for-testing -project Nolaggy.xcodeproj -scheme NolaggyCoreTests -destination 'generic/platform=iOS Simulator'
  ```

## Android — Kotlin and Jetpack Compose

- **Module boundaries (`docs/08-arquitetura-android.md`)**:
  - `:core:domain`, `:core:catalog`, `:core:network`, and `:core:session` are
    Kotlin/JVM layers. Do not put Compose, Android framework calls, or UI copy
    in them.
  - `:core:telemetry-radio` adapts Android system facts. Its absence or an
    optional permission denial is valid data absence, not a reason to block a
    Check.
  - `:core:designsystem` owns Compose tokens and reusable visual components.
    `:app` composes screens, ViewModels, navigation, lifecycle, permissions,
    sharing, and Android adapters.
- **Parity without reimplementation**: Kotlin ports the current Swift domain
  rules and vectors; do not reinterpret thresholds, valid-sample requirements,
  or verdict wording in a screen. Less than the required valid UDP responses is
  `INCONCLUSIVE`, with no HTTP/ICMP fallback, invented score, or recommendation
  to play.
- **Android-native behavior**: handle configuration changes, process/lifecycle
  cancellation, system back, insets, permission results, file sharing through
  the approved `FileProvider`, and state restoration deliberately. A network
  change, cancellation, or background interruption discards a partial Check.
- **Radio and permission honesty**: `NEARBY_WIFI_DEVICES` is optional. Show
  frequency/RSSI/PHY/gateway/NAT only when observed; otherwise omit the field
  or render `—` according to the presentation contract. Never infer band from
  SSID, RTT, or jitter, and never blame Wi-Fi, router, route, or ISP from a
  missing or isolated signal.
- **Compose quality**: consume `:core:designsystem` tokens and components;
  avoid magic values and default Material visuals that violate the LagCheck
  system. Keep state exposed by the ViewModel immutable and lifecycle-aware.
  Make loading, error, cancelled, permission-unavailable, inconclusive, and
  final verdict states explicit rather than overloading a success layout.
- **Accessibility/localization**: support TalkBack semantics, 44 dp targets,
  font scaling, contrast, reduced motion, PT-BR, and English. Interactive icons
  require localized descriptions; decorative artwork does not.
- **Verification**: begin with the smallest affected JVM suite, then run the
  Android build/tests appropriate to the change. Emulator evidence validates
  rendering and basic interaction only; real UDP, radio permissions, network
  switching, background behavior, sharing, and lifecycle require a physical
  Android device.
  ```bash
  cd android && ./gradlew :core:domain:test :core:catalog:test :core:network:test :core:session:test
  ```

## Cross-platform delivery checklist

For a feature touching both apps, first define the shared behavioral contract,
then implement the platform adapters independently. Confirm the same result for
the same domain input with shared vectors, while documenting deliberate
platform-only facts such as Android radio telemetry. Report validation per
platform and environment; an iOS simulator, Android emulator, and physical
device are separate evidence states.
