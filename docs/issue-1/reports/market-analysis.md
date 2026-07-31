# Phase-2 record — issue-1: market-analysis methodology & deliverable norms

Subject: issue-1. Phase 2 execution, gated on the `APPROVE issue-1/market-analysis`
issue comment (2026-07-31T12:33:07Z, author JiwonJung94, MEMBER).

## What was done

1. Updated `market-analysis/hooks/directive.sh`'s `PRODUCES` argument to
   `core_role_directive` in place, adding the evidence-citation requirement
   inline: `"five-forces summary (each force evidence-cited), competitor list
   (each item evidence-cited), JTBD-landscape verdict, evidence appendix"`.
   No structural change to the stub — it remains a thin call into
   `core_role_directive` (core issue #66); only the role-unique string
   argument changed.
2. Added `docs/handbooks/market-analysis-norms.md`, the standing norm for
   this role's future phase-1 proposals (a) and phase-2 deliverables (b),
   carried over verbatim from the approved proposal, plus an explicit
   **enforcement status** section stating the norms are review-time, not
   mechanically gated.
3. Did not create `roles/market-analysis.json` or any role-local gate script.
   Confirmed against `docs/issue-2/reports/implementation.md` (already landed
   on this branch, `3d1fe74`): core's promoted `record-fields-gate.sh` checks
   a role-agnostic §20 structural template only and reads no per-role
   `produces` field list at all. Inventing a `roles/market-analysis.json`
   that nothing in core reads would be a fabricated integration point, so
   the proposal's conditional item (d)(ii) resolves to: evidence-rigor
   enforcement stays a handbook-documented review norm, not a mechanical
   gate — this is recorded plainly per the proposal's own risk flag, not
   claimed as gated.
4. Added no new gate logic. Per issue-2 (already merged), the three
   role-local gates were removed in favor of core's global registration;
   this issue adds no PRODUCES field list for a gate to read, since none
   exists to read it.

## Why

Per the approved proposal (`docs/issue-1/proposals/methodology-and-deliverable-norms.md`):
evidence traceability is the single highest-leverage norm for this role's
actual decision boundary ("경쟁 구도에서 이 스펙이 서는가" — a gate output is
only as trustworthy as its weakest cited claim). No new required output
categories (sizing, SWOT) were added — the existing three `PRODUCES` names
already match the field's own must-be separation (industry attractiveness /
competitive positioning / customer-need fit); the gap was evidence rigor, not
missing categories.

## Upstream basis

- `docs/issue-1/proposals/methodology-and-deliverable-norms.md` (this repo, phase-1, Approved).
- `docs/issue-1/reports/market-analysis/current-state-survey.md`, `scout-brief.md` (this repo, phase-1).
- `docs/issue-2/reports/implementation.md` (this repo, merged `3d1fe74`) — read directly to confirm core's actual `record-fields-gate.sh` design before deciding not to create `roles/market-analysis.json`.

## Deviations from the phase-1 proposal (flagged, not silent)

- Proposal item (d)(i) conditionally asked to "confirm or create
  `roles/market-analysis.json`... once core's actual interface is readable."
  That interface was already read and recorded in this repo by issue-2
  (merged before this phase-2, per the ordering constraint both proposals
  flagged): core's gate is role-agnostic and reads no such file. Per the
  proposal's own fallback clause (d)(ii), this resolves as: no such file is
  created, and the evidence-rigor requirement is a handbook norm only. This
  is the same finding issue-2's record made for its own `REQUIRED_FIELDS`
  question — not a new gap, a reapplication of an already-settled one.
- No other deviation. The `directive.sh` wording change matches proposal (d)
  verbatim in intent; the handbook content matches proposal (a)/(b) verbatim.

## Ordering constraint

Issue-1's proposal noted the core-canon migration (issue-2) must land first.
Confirmed landed on this branch at `3d1fe74` before this phase-2 work began.

loop_state: landed

## Open findings

None outstanding.
