---
name: gate-testflight
description: >-
  Operational action skill to audit and enforce the TestFlight release gate checklist.
  Validates zero crash risk, diagnostic integrity, absence of PII in telemetry,
  visual contrast, and performance on physical iPhone.
---

# TestFlight Release Gate — Action Checklist

This operational skill provides the exact step-by-step checklist to approve or block a build candidate before TestFlight distribution.

## 1. Automated Quality & Build Check
Run from repository root:
```bash
# 1. Generate Xcode project
xcodegen generate

# 2. Run pure domain unit tests
xcodebuild test -project Nolaggy.xcodeproj -scheme NolaggyCoreTests -destination 'generic/platform=iOS Simulator'

# 3. Build for release configuration
xcodebuild clean build -project Nolaggy.xcodeproj -scheme Nolaggy -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO
```

## 2. Diagnostic Integrity Audit (Decision 50 & 55)
- [ ] **Zero Fabricated UDP**: With Wi-Fi disconnected or route blocked, verify the result is strictly `.inconclusive`.
- [ ] **No ICMP/HTTP Fallback**: Verify no HTTP probe is used to compute packet latency or ping.
- [ ] **Dynamic Gateway IP**: Verify gateway discovery uses kernel routing table, never hardcoded `.1`.
- [ ] **Out-of-Order Detection (RFC 4737)**: Verify that packet reordering > 1% modulates verdict to `.caution`.

## 3. Product & UX Guardrails (Decision 64: "Zero Cara de IA / Gamer Não Lê")
- [ ] **Zero Textão**: No block of text longer than 2 lines exists in the critical path.
- [ ] **No Excessive Cards ("Cardlização")**: Confirm interface uses monolithic Dark Competitive panels with 1px hairline border, not floating bubbly cards.
- [ ] **Immediate Verdict**: Confirm semantic verdict (`● PRONTO PARA RANKED` / `▲ EU EVITARIA`) renders instantly.
- [ ] **Test Duration**: Check total measurement duration on Wi-Fi and 5G. Must feel fast and responsive.

## 4. Privacy & Cost Verification
- [ ] **Zero Paid SDKs**: Confirm binary has zero Firebase, zero AdMob, zero third-party analytics.
- [ ] **Worker Telemetry (`POST /v1/telemetry`)**: Inspect payload to guarantee zero IP addresses, zero device names, and zero PII are transmitted.
- [ ] **Cellular Consent**: Verify cellular test prompts for consent before load phase and aborts cleanly if denied.

## 5. Gate Decision
- **PASS**: All 5 sections verified on physical iPhone hardware. Proceed to archive upload.
- **BLOCK**: Any failure halts release candidate immediately. Open Hot lane fix.
