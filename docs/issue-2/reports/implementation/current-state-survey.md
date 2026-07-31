# Current-state survey — issue-2

Subject: issue-2. Scope: what exists today in this rulebook that issue-2 asks to retire or replace.

## Scout skip record

Skipped. Reason: issue-2 is an internal cross-repo canon-reference migration with a
fully-specified target shape (function name, stub format, config key name, test
script path all named in the issue body) — no external product/UX decision is
open, only mechanical extraction. Per scout-directive's skip conditions, this
qualifies as "the spec literally leaves no design decision open."

## Inventory of files in scope

| File | Role today | Disposition per issue |
|---|---|---|
| `market-analysis/agents/warrant-hunter.md` | Full copy of implementation-rulebook's warrant-hunter agent, adapted with this role's decision boundary and hand-off targets. Explicitly labeled "adapted from implementation-rulebook's `agents/warrant-hunter.md`" — i.e. a known-duplicated copy, not role-original. | Remove; replace with a reference to core's `warrant/` plugin (core issue #63). |
| `market-analysis/hooks/trailer-gate.sh` | Full gate implementation. Header comment: "Adapted from implementation-rulebook's trailer-gate.sh, role name substituted only (this file's logic is role-agnostic)" — confirms it is a role-agnostic copy. | Remove file + its `hooks.json` registration; superseded by core's registration (core issue #66). |
| `market-analysis/hooks/record-fields-gate.sh` | Gate logic is role-agnostic (JSON parse, target-path check, required-field diff) but `REQUIRED_FIELDS` (`five-forces-summary`, `competitor-list`, `jtbd-landscape-verdict`) and `RECORD_SUFFIX` are role-specific, sourced from `roles/market-analysis.json`'s `produces`. | Remove file + registration; role-specific field list must be preserved via whatever role-config mechanism core's copy reads (see gap below). |
| `market-analysis/hooks/handbook-trigger-gate.sh` | Placeholder verdict (`exit 0`) — logic not yet implemented for this role. Role-agnostic skeleton. | Remove file + registration; superseded by core's registration. |
| `market-analysis/hooks/hooks.json` | Registers all three gates above (`PreToolUse`) plus `directive.sh` (`SessionStart`). | Remove the three gate registrations (core registers them per core issue #66); keep `SessionStart` → `directive.sh`. |
| `market-analysis/hooks/directive.sh` | Freestanding script: kill-switch handling, `CLAUDE_ROLE` guard, then a heredoc printing this role's directive text (decides/use_when/produces/write_scope/hand-off/boundary-case/record path). No shared-boilerplate extraction — the kill-switch and role-guard logic is duplicated per role. | Convert to a stub: source `core/hooks/lib/role-directive.sh`, call `core_role_directive` with this role's fields as arguments/env, keep only the role-unique text. |

## Role-unique content that must survive the cut

- Decision boundary: "경쟁 구도에서 이 스펙이 서는가"
- `USE_WHEN`, `PRODUCES`, `WRITE_SCOPE: []`, `HAND-OFF` text in `directive.sh`
- `REQUIRED_FIELDS` list in `record-fields-gate.sh` (`five-forces-summary`, `competitor-list`, `jtbd-landscape-verdict`) and the record path `docs/issue-<n>/reports/market-analysis.md`
- warrant-hunter's mandate line and out-of-scope hand-off targets (currently a stance-set skeleton, not yet enumerated — issue text says "enumerate this role's own stance set before shipping"; this repo has not done so yet)
- This role currently declares no loop-state terminal-state deviation (`directive.sh` doesn't reference `loop_state` at all) — item 4 in the issue ("if a real difference exists") appears to be conditionally not applicable here, pending confirmation of what core's default terminal-state set is.

## Gaps — core canon is not present in this repo/workspace

`core/hooks/lib/role-directive.sh`, `core_role_directive`'s exact call signature, the
`warrant/` plugin's registration mechanism, the three gates' core registration, and
`core/hooks/tests/stub-check.sh` are all referenced by issue-2 but live in core
(core issues #63/#66), not in this repository or this workspace. They could not be
read directly. The proposal below is written against the issue text's description
of the target shape; exact call signatures/paths must be confirmed against core's
actual landed code during phase 2, not assumed from this proposal alone.

## Ordering constraint

Per issue body: this transition must land before this rulebook's "룰북 성숙화" issue
phase 2. No evidence in this repo of that other issue's state (not present in git
history or open PRs visible to this session) — flagged for the approver to confirm
sequencing is still clear before approving phase 2 of this issue.
