---
code_under_review: TBD
loop_state: landed
type: docs
breaking: false
verdict: pass
---

# Implementation record — issue-19 phase 2

## What was done

Applied `docs/issue-19/proposals/spec-vocabulary-alignment.md` (approved via
`APPROVE issue-19/implementation`, single-account mode) exactly as scoped:

1. `docs/handbooks/market-analysis-norms.md` — added `## (c) Spec
   vocabulary` mapping the realized `market-analysis.spec.json`'s three
   required deliverable fields (`force`, `assessment`, `evidence`) onto the
   existing `five-forces-summary` requirement in (b).1, plus a `loop_state`
   table naming the exact five spec values (`researching, assessing,
   landed, evidence-undeclared, market-data-unreachable`) with a one-line
   meaning each, and a note that `reference_resolution` /
   `recomputation` stay deferred/out-of-repo (not silently dropped).
2. `market-analysis/hooks/directive.sh` — extended the `PRODUCES` argument
   text passed to `core_role_directive` (4-arg signature confirmed in
   `core/hooks/lib/role-directive.sh`; no 5th-arg option exists) to name
   the field vocabulary and loop_state set so a session reads it at
   SessionStart.
3. `README.md` — added a `spec vocabulary` bullet naming the three field
   labels and the loop_state set, pointing to the handbook section for
   the full mapping.

No `gate.sh` changes were made, matching the proposal's Out of scope.

## Why

Issue-19 required the spec's field names and loop_state vocabulary to
appear in rulebook docs (acceptance: `grep -ri <field> docs/ README.md`)
and the loop_state set to match the spec exactly, with no deletion of
existing methodology. Layering onto the existing `five-forces-summary`
requirement (rather than adding parallel new sections) keeps the change
documentation-only and reviewable in one pass, per the proposal's
Rationale.

## Upstream basis

`docs/issue-19/proposals/spec-vocabulary-alignment.md` (approved), drafted
from `docs/issue-19/reports/implementation/survey.md`.

## Acceptance verification (executed this session)

- `grep -ri force docs/ README.md` → hit (`docs/handbooks/market-analysis-norms.md:58`).
- `grep -ri assessment docs/ README.md` → hit (handbook + README).
- `grep -ri evidence docs/ README.md` → hit (already passing pre-change,
  still passing).
- `grep -rn "loop_state" docs/ README.md market-analysis/` → the five
  spec values (`researching, assessing, landed, evidence-undeclared,
  market-data-unreachable`) all present, no extra/stale values introduced
  by this change. (Pre-existing per-record `loop_state: landed` lines in
  `docs/issue-*/reports/*.md` are individual record values, not vocabulary
  declarations, and are unaffected.)
- Test suite: no `pytest` config and no `tests/*.sh` exist in this repo.
  `find . -iname '*.bats'` finds 5 existing gate suites under
  `market-analysis/plugins/*/tests/gate.bats` (pre-existing, untouched by
  this docs-only change); the `bats` binary is not installed in this
  environment (`bats: 명령어를 찾을 수 없음`), so these could not be executed
  this session. Stating per the issue's acceptance clause:
  `unverifiable: no test suite present` for a form pytest/tests/*.sh
  would recognize — the pre-existing bats suites are untouched by this
  change and out of this issue's write set.

## What did not work

None — no write, undo, or expectation mismatch occurred during this
build.

## Open findings

None carried forward from phase 1. The after-proposal warrant-hunt
(`docs/reports/2026-08-09-hunt-spec-vocabulary-alignment.md`) reported no
finding for this transition; per the proposal's docs-only write set, the
before-landing hunt dispatch is skipped per the docs-only fast path.

## Doc-placement ladder

- [x] `docs/handbooks/market-analysis-norms.md` updated (standing
      methodology convention change) — same turn as the code change.
- No new env var, dependency, migration, or setup step introduced — no
  handbook entry needed beyond the above.
- No library-or-format choice or changed public signature/wire format —
  no `docs/issue-19/decisions/` entry needed.
- No benchmark/investigation numbers produced — no
  `docs/issue-19/reports/` entry needed beyond this record itself.
