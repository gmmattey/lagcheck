---
name: systemic-change-gate
description: >-
  Triage and govern LagCheck systemic changes across iOS, Android, Worker,
  persistence, security, or the UDP engine with a proportional architecture
  decision and evidence trail. Do not use it for local UI or copy fixes.
---

# Systemic Change Gate

Use this skill before code when a change affects an API/Worker contract,
protocol, catalog schema, persistence migration, security/privacy boundary,
measurement engine, or responsibility between core modules.

## Gate input

Start with the Cartão de Missão, current contract/schema, compatibility target,
affected iOS/Android modules, version/vector plan, privacy/cost impact, and
migration or rollback strategy. If these are absent, return `cannot begin`.

## Gate output

Camillo returns exactly one outcome:

- `can proceed`;
- `can proceed with listed constraints`; or
- `cannot begin`.

The proportional Architecture Plan records shared required behavior, permitted
native divergence, compatibility/rollback, constraints, and traceability from
constraint to implementation, test/vector, and remaining physical evidence.

## Boundaries

This gate does not calibrate score/thresholds, perform independent QA, decide
product scope, or authorize a release. Those remain with Iury, Breno,
Marco/Luiz, and the applicable distribution gate.
