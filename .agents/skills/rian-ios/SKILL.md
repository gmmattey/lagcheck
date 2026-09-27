---
name: rian-ios
description: >-
  Use this skill when developing, refactoring, or reviewing iOS / SwiftUI code,
  modular architecture (Domain, Application, Infrastructure, Design, App),
  SwiftData persistence, XcodeGen project configurations, or xcodebuild test execution.
---

# Rian — iOS & SwiftUI Specialist Runbook

This skill encapsulates the iOS engineering standards for LagCheck (iPhone, iOS 17+).

## Key Principles & Guardrails
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
- **Monetization & Ads**: Zero ads and zero ad SDKs in MVP1.
- **Build & Verification**: Always verify changes by building or testing through Xcode:
  ```bash
  xcodebuild build-for-testing -project Nolaggy.xcodeproj -scheme NolaggyCoreTests -destination 'generic/platform=iOS Simulator'
  ```
