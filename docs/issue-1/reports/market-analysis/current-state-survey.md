# Current-state survey — issue-1

Subject: issue-1. Scope: what this rulebook's `market-analysis` plugin already
encodes about method/deliverable norms, and where it is silent or unsourced.

## Existing write surfaces

| Surface | Current content | Source of the content |
|---|---|---|
| `market-analysis/hooks/directive.sh` | Decision boundary: "경쟁 구도에서 이 스펙이 서는가". `USE_WHEN`: 스펙 확정 후, 경쟁 구도가 걸린 결정일 때. `PRODUCES`: five-forces summary, competitor list w/ evidence links, JTBD-landscape verdict. `HAND-OFF`: pricing / marketing. | Stub over core canon (`core_role_directive`, core issue #63/#66 rollout, landed via #4). No citation to any external methodology standard — the three `PRODUCES` items were asserted, not derived from a sourced survey. |
| Record path convention | `docs/issue-<n>/reports/market-analysis.md`, required fields implied by `PRODUCES` (`five-forces-summary`, `competitor-list`, `jtbd-landscape-verdict`) | Same directive stub; no separate `roles/market-analysis.json` or gate file exists in this repo (record-fields gate was removed under issue-2's core-canon migration — enforcement now lives in core, out of this repo's view). |
| Phase-1 proposal norms | None — no prior proposal in this repo's `docs/issue-*/proposals/` sets a precedent for market-analysis specifically. `docs/issue-2/proposals/core-canon-migration.md` is a migration proposal, not a market-analysis-methodology one — same author role, different subject matter, not reusable as a methodology template. | n/a |
| Phase-2 deliverable norms | None — no market-analysis phase-2 record exists yet in this repo (`docs/issue-<n>/reports/market-analysis.md` is not yet populated for any issue). | n/a |

## Gaps this issue asks to close

1. **No sourced rationale for the three `PRODUCES` items.** Five-forces, competitor list, JTBD-landscape verdict were set when the role was scaffolded (`e957b95` "Seed rulebook skeleton"), pre-dating any domain survey. Issue-1 requires that the eventual set be justified by "논리적 이유" tied to the role's intended value, not carried over unexamined.
2. **No phase-1 proposal-document norm.** There is no house standard for what a market-analysis phase-1 proposal must contain (required sections, evidence format) — this issue is the first to define one.
3. **No phase-2 deliverable norm.** Same gap for the phase-2 record: no required-component list beyond the three `PRODUCES` strings, and no methodology attached to how each is to be produced (e.g. is competitor list top-down or bottom-up sourced? what counts as "evidence links"?).
4. **No plugin-enforcement plan.** `directive.sh` currently states `PRODUCES` as free text; there is no gate that checks a phase-2 record actually contains the required components, and no defined "record required fields" list post-issue-2 migration (that enforcement moved to core, whose per-role config format is itself unconfirmed — same gap flagged in `docs/issue-2/reports/implementation/current-state-survey.md`).

## Constraint carried over from issue-2

warrant-hunter and the three role-local gate scripts were removed under issue-2 (core canon references, core issue #63/#66). This issue's plugin-reflection plan (item d) must reference core canon for any warrant/gate mechanics — no local copies, per issue-1's explicit constraint and the precedent already merged (`3d1fe74`).
