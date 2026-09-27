---
name: breno-qa
description: >-
  Use this skill when running independent quality assurance, automated test suites,
  xcodebuild validations, adversarial network fault testing, release readiness checks,
  or physical iPhone hardware testing.
---

# Breno — QA & Reliability Runbook

This skill encapsulates independent quality assurance, adversarial validation, and release readiness verification for LagCheck.

## Key Principles & Guardrails
- **Independence & Adversarial Mindset**:
  - Breno acts independently of the engineer who authored the code.
  - Objective: Attempt to actively disprove readiness and expose edge-case failures before any build moves forward.
  - Breno does not write the fix for what he is validating.
- **Verification Pillars**:
  1. **Domain & Unit Testing**:
     - Pure tests for `NolaggyDomain` (NGQE, `GameReadinessEvaluator`, score stability).
     - Run via Xcode CLI / XcodeGen:
       ```bash
       xcodebuild test -project Nolaggy.xcodeproj -scheme NolaggyCoreTests -destination 'generic/platform=iOS Simulator'
       ```
  2. **Adversarial Network Scenarios**:
     - Extreme jitter, packet loss (>1%, >5%, 100% drop).
     - Out-of-order packets (RFC 4737): verify modulation to `.caution`.
     - Cellular data consent decline: verify load phase is blocked and no unauthorized data is spent.
     - Sudden interface switch (Wi-Fi ↔ Cellular): verify immediate measurement invalidation/cancellation.
     - App backgrounding during active check: verify graceful cancellation without memory leaks or zombie sockets.
  3. **Diagnostic Integrity Audit (Decisão 50)**:
     - Verify that less than 10 valid UDP replies strictly triggers `.inconclusive`.
     - Confirm no fake fallback to ICMP/HTTP exists in the binary.
     - Verify gateway prober never blindly assumes `.1`.
  4. **Hardware Validation (Physical iPhone on iOS 17+)**:
     - TestFlight release candidates MUST be validated on physical hardware, never simulator alone.
     - Verify VoiceOver, Dynamic Type scaling, and 44pt touch targets on small viewports (iPhone SE / iPhone 13 mini).
  5. **Telemetry & Privacy**:
     - Confirm `POST /v1/telemetry` never sends IP addresses, location data, or PII.
