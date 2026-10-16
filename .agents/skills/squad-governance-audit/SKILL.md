---
name: squad-governance-audit
description: >-
  Audit LagCheck squad governance for conflicting ownership, stale platform scope,
  missing gates, or evidence claims before they create delivery risk. Do not use
  for ordinary feature implementation.
---

# Squad Governance Audit

Use this skill when a decision, role, workflow, release rule, or skill may have
drifted from the current product. Its outcome is a small, evidence-backed
correction plan — not a new layer of process.

## Read in this order

1. `docs/DECISOES.md` for later decisions.
2. `docs/05-governanca-e-fluxo-de-trabalho.md` for the operating rule.
3. `AGENTS.md`, `.agents/WORKFLOW.md`, relevant skills, and `docs/06-fluxo-de-release.md` for implementation of that rule.

## Audit

- Compare product scope, platform ownership, approval rights, gates, and release
  claims. A later decision wins; flag the older wording rather than silently
  choosing one.
- Check that each active lane has one delivery owner, required reviewers, an
  evidence standard, and a clear external-authority boundary.
- Check that a skill's trigger and non-scope do not duplicate another skill or
  create a competing owner.
- Report only material findings as `blocked`, `needs correction`, or `aligned`,
  with the exact sources and smallest safe correction.

## Boundaries

Do not rewrite product decisions, authorize release, create a new agent, or
make feature changes. Escalate a genuine product conflict to Marco/Luiz; route
systemic technical conflicts through Camillo.
