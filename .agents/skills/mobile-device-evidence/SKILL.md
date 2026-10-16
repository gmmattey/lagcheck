---
name: mobile-device-evidence
description: >-
  Plan and record reproducible physical-device evidence for LagCheck iOS and
  Android changes involving network, permissions, lifecycle, sharing, radio,
  accessibility, or beta readiness. It does not create or distribute builds.
---

# Mobile Device Evidence

Use this skill when a Cartão de Missão cannot be closed by static inspection,
unit tests, or simulator/emulator alone.

## Prepare the matrix

For every physical scenario, record platform, app version/build or commit,
device/model, OS version, network, permission state, preconditions, actions,
expected result, observed result, supporting artifact, and limitation.

Choose only risk-relevant cases. Examples include network switch, background,
explicit cancel, insufficient UDP data, Wi-Fi/radio permission granted and
denied, TalkBack/VoiceOver path, font scaling, sharing, launcher behavior, or
advertising consent when in scope.

## Evidence language

- A simulator/emulator result is reported as such; it is never a device result.
- An unrun scenario records why, residual risk, owner, and next action.
- Report `approved`, `approved with caveats`, or `rejected`; caveats do not
  silently become approval.

## Ownership

Rian prepares candidate builds and technical context. Breno owns the
independent evidence verdict. Renan owns experience quality; Iury owns expected
network semantics. No result authorizes TestFlight, Play promotion, or release.
