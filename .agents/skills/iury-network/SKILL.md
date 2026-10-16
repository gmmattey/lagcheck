---
name: iury-network
description: >-
  Use this skill when calibrating network measurement algorithms, score formulas,
  evaluating UDP latency/jitter/packet loss, managing Cloudflare Worker endpoints,
  or updating game catalogs and regional routing contracts.
---

# Iury — Network & Metrics Specialist Runbook

This skill encapsulates network measurement, scoring rules, regional
infrastructure, and diagnostic integrity for LagCheck on iOS and Android.

## Cross-platform contract

- Read `docs/08-arquitetura-android.md` alongside `docs/03-especificacao-tecnica.md` whenever a change can reach both clients.
- Shared Kotlin/Swift vectors, rule versions, sample validity, route eligibility,
  verdict semantics, and catalog validation are the proof of deterministic
  parity. A matching screen is not parity.
- Android may expose additional observed radio facts. They never change a claim
  about Wi-Fi band, router, route, or provider unless the documented isolated
  evidence exists; absence of optional permission is simply unavailable data.
- Before accepting a network change, require the task's Cartão de Missão to name
  platform impact, rule version, vectors, contract tests, and the physical
  validation still required.

## Key Principles & Guardrails
- **Deterministic & Grounded Verdicts (`docs/03-especificacao-tecnica.md`, `docs/50`)**:
  - Verdicts and scores must be strictly derived from real UDP round-trips to target game infrastructure.
  - Less than 10 valid UDP samples strictly produces **Inconclusive** — never invent a score or verdict, never use HTTP/ICMP fallbacks.
  - Map network outcomes to `GameReadinessVerdict`:
    - `.ready`: Optimal latency, near-zero loss, solid stability.
    - `.caution`: Moderate jitter, sporadic spikes, or load degradation.
    - `.notReady`: Harmful packet loss (>1% in competitive), bad latency, severe spikes.
    - `.inconclusive`: Insufficient UDP responses.
- **Diagnostic Integrity (Decision 50 — Critical Bug Fixes)**:
  - **No Assumption of `.1` Gateway**: `WiFiLocalGatewayProber` must not blindly probe `.1`. Must discover local gateway via system routing tables.
  - **UDP Port 53 Send Callbacks != RTT**: Measuring send callback completion without a response packet does NOT constitute router RTT.
  - **Do NOT Feed WAN Latency to Wi-Fi Band Evaluator**: Never use remote destination P50/jitter to diagnose local Wi-Fi 2.4 vs 5 GHz. External internet fluctuations belong to WAN.
  - **Honest Symptom Checklist**: Report "What we found" without claiming causal blame on ISP or router without real isolated evidence.
- **Infrastructure Limits (`docs/12`, `docs/14`, `docs/50`)**:
  - Authorized Cloudflare Worker (`nolaggy-deep-check`):
    - `GET /v1/catalog.json` (signed Ed25519)
    - `GET /v1/load` (load phase up to 10 MB)
    - `POST /v1/telemetry` (anonymous product retention events, no PII/IP)
  - Zero paid external services.
- **Rules Versioning**: Any update to thresholds, profiles, or formulas requires version increment and unit tests.
