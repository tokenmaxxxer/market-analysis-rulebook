# Phase-2 record — issue-2: core canon migration

Subject: issue-2. Phase 2 execution, gated on the `APPROVE issue-2/implementation`
issue comment (2026-07-31T08:45:05Z, author JiwonJung94, MEMBER).

## What was done

Read core's actual landed code (not assumed) at
`tokenmaxxxer-core` commit `d5b544e0` (issue-66, "promote role-agnostic
rulebook gates to core canon") and the `warrant/` plugin tree (issue-63), then
executed the five items in one batch:

1. Deleted `market-analysis/agents/warrant-hunter.md`. Core's `warrant/`
   plugin (issue-63) is a self-contained, role-agnostic plugin — it registers
   its own `hunt-guard.sh`/`scope-gate.sh` globally and does not read any
   per-role stance config or per-role agent file. There is nothing role-unique
   left to re-home: this role's stance set was never enumerated in the first
   place (survey's own finding), so no content was lost by the deletion.
2. Deleted `market-analysis/hooks/trailer-gate.sh`,
   `record-fields-gate.sh`, `handbook-trigger-gate.sh`. Confirmed core's
   `hooks/hooks.json` registers all three globally (`PreToolUse`, matcher
   `.*`) — this repo's copies were pure duplication. Removed the local
   `PreToolUse` block from `market-analysis/hooks/hooks.json` entirely,
   keeping only the `SessionStart` → `directive.sh` entry.
3. Converted `market-analysis/hooks/directive.sh` to a stub: sources
   `core/hooks/lib/role-directive.sh` and calls `core_role_directive` with
   this role's four unique strings (decides / use-when / produces /
   hand-off) on one line each, matching the library's actual 4-positional-arg
   signature and the exact source-line form `core/hooks/tests/stub-check.sh`
   checks for. No local kill-switch/guard logic remains — `core_role_directive`
   derives `MARKET_ANALYSIS_CYCLE_OFF` from `CLAUDE_ROLE` itself.
4. `RECORD_FIELDS_TERMINAL_STATES`: **not set**, as an explicit no-override
   decision. Core's promoted `record-fields-gate.sh` no longer checks any
   role-specific `produces` field list at all — it enforces a generic §20
   structural check (what-was-done / why / upstream-basis / `loop_state` /
   open-findings) against `docs/issue-<n>/reports/${CLAUDE_ROLE}.md`, with
   `TERMINAL` defaulting to `{"landed"}`. This role's `directive.sh` never
   declared a `loop_state` concept and nothing in the survey showed a
   divergent terminal-state set, so the default applies unmodified.
5. Ran `core/hooks/tests/stub-check.sh market-analysis` (the actual landed
   copy at the core commit above) against this role's `hooks/` tree:

   ```
   stub-check: ok — no vendored 'trailer-gate.sh' under market-analysis
   stub-check: ok — no vendored 'record-fields-gate.sh' under market-analysis
   stub-check: ok — no vendored 'handbook-trigger-gate.sh' under market-analysis
   stub-check: ok — no vendored 'parse-check.sh' under market-analysis
   stub-check: ok — market-analysis/hooks/directive.sh is a role-directive stub
   ```

   Exit code 0 — PASS on every check, including the structural directive.sh
   check.

## Why

Per issue-2: core landed a single canon for the warrant-hunt agent (core
#63), the three role-agnostic gates (core #66), and the shared directive
boilerplate (`core/hooks/lib/role-directive.sh`). This rulebook's copies were
confirmed duplicates (survey), so keeping them local is drift risk with no
benefit — core's registration already covers every plugin install.

## Upstream basis

- `docs/issue-2/proposals/core-canon-migration.md` (this repo, phase-1,
  Approved).
- `docs/issue-2/reports/implementation/current-state-survey.md` (this repo,
  phase-1).
- `tokenmaxxxer-core` commit `d5b544e0` ("deliver(implementation): promote
  role-agnostic rulebook gates to core canon") — read directly for
  `core/hooks/lib/role-directive.sh`, `core/hooks/hooks.json`,
  `core/hooks/tests/stub-check.sh`.
- `tokenmaxxxer-core`'s `warrant/` plugin tree (issue-63) — read directly for
  `warrant/hooks/hooks.json`, `warrant/hooks/scope-gate.sh`,
  `warrant/agents/warrant-hunter.md`.

## Deviations from the phase-1 proposal (flagged, not silent)

- Proposal item 2 assumed `record-fields-gate.sh`'s `REQUIRED_FIELDS`
  (`five-forces-summary`, `competitor-list`, `jtbd-landscape-verdict`) would
  need re-homing into a `roles/market-analysis.json`. Reading core's actual
  landed gate shows this is moot: the promoted gate does not read any
  per-role field list — it was redesigned as a role-agnostic §20 structural
  check. No `roles/market-analysis.json` was created; inventing one that
  nothing in core reads would be a fabricated integration point. The
  `REQUIRED_FIELDS` list itself has no home in the new design — it is
  superseded, not migrated.
- Proposal item 3 speculated on `core_role_directive`'s parameter contract
  (flags vs. positional vs. env). The real signature is 4 positional
  arguments (`you_decide use_when produces hand_off`); the stub above uses
  that exact form, confirmed by `stub-check.sh` passing.
- `WRITE_SCOPE: []` (previously its own line in `directive.sh`'s printed
  text) has no slot in `core_role_directive`'s 4-argument signature and is
  not folded into another string. This is a real, intentional information
  loss on core's part (the shared function is deliberately terser than every
  role's old ad-hoc text); noted here rather than silently dropped. Since
  this role's write scope is `[]` (no operational effect either way), the
  loss is inert for `market-analysis` today.

## Ordering constraint

Issue-2 states this migration must land before this rulebook's "룰북
성숙화" issue's phase 2. That other issue's state remains unverified from
this workspace (unchanged from the phase-1 survey's flag) — the approver
accepted phase 2 via the `APPROVE issue-2/implementation` comment without
raising it, so proceeding.

loop_state: landed

## Open findings

None outstanding. The `WRITE_SCOPE` information-loss point above is recorded
as an accepted, inert deviation rather than an open finding requiring
follow-up.
