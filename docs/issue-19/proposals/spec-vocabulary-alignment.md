---
status: proposed
files:
  - docs/handbooks/market-analysis-norms.md
  - market-analysis/hooks/directive.sh
  - README.md
---

# Proposal — align rulebook vocabulary with realized market-analysis spec (issue-19)

Phase-1 proposal only. No file changes in this PR beyond this proposal
and its survey; phase 2 applies the mapping below after human Approve.
See `docs/issue-19/reports/implementation/survey.md` for the field-by-field
gap inventory this proposal is drafted from.

Scouting skip record: skipped — the spec (`roles/specs/market-analysis.spec.json`)
already fixes every field name, enum value, and loop_state string; there
is no exemplar market to scout because the decision is placement inside
already-existing rulebook docs, not invention of new vocabulary.

## Request

Layer `market-analysis.spec.json`'s three required deliverable fields
(`force`, `assessment`, `evidence`) and its five loop_state values
(`researching`, `assessing`, `landed`, `evidence-undeclared`,
`market-data-unreachable`) onto this rulebook's existing methodology
docs and role directive, strengthening what already exists rather than
replacing it. No gate/hook logic changes in this pass.

## Constraints

- Never delete existing methodology (five-forces, JTBD, competitor-list,
  MECE-proposal norms all stay as-is).
- The `write_scope` in the spec (`docs/issue-<n>/reports/market-analysis.md`)
  already matches this rulebook's convention exactly — no path change.
- `reference_resolution`'s checker (`role-spec-reference-guard.sh`) lives
  in `on-the-record`, outside this repo's write scope — this rulebook can
  only document the expectation, not gate it.
- `recomputation`'s `checked_by: TBD` is the spec's own declared
  follow-up — not this issue's job to close.
- No gate.sh changes: enforcing the enum values or loop_state
  mechanically is materially larger scope than "align vocabulary" and
  isn't asked for by the acceptance criteria (which check field-name
  presence via `grep`, and loop_state-set correctness, not mechanical
  enum enforcement in a gate).

## Rationale

Considered mechanically gating the three fields and loop_state values
in `gate.sh` (i.e., have five-forces/evidence-rigor gates additionally
require the literal `force:`/`assessment:`/`evidence:` field labels and
reject any loop_state string outside the spec's five). Rejected: the
acceptance criteria only ask that the field names *appear* in the docs
(`grep -ri <field> docs/ README.md`) and that the loop_state vocabulary
*match the spec set exactly* in the rulebook's own documentation — they
do not ask for new mechanical enforcement, and the spec's own
`recomputation.checked_by: TBD` explicitly treats deeper enforcement as
a separate future step. Building gate code now would be scope not
requested, harder to review in one pass, and risks colliding with the
existing five-forces/evidence-rigor gates' already-audited citation
logic for no acceptance-criteria benefit. Documentation-first alignment
is the smaller, reviewable, exactly-sufficient change.

## What will be done

1. `docs/handbooks/market-analysis-norms.md`: add a short subsection
   naming the spec's three required field labels (`force`, `assessment`,
   `evidence`) as the literal vocabulary for the existing
   five-forces-summary verdict/evidence-citation requirement — i.e.,
   state explicitly that each five-forces-summary entry names its
   `force` (one of the 5 enum values), its `assessment`
   (low/medium/high), and its `evidence` (the citation already
   required). Add a `loop_state` subsection listing the exact five
   values (`researching, assessing, landed, evidence-undeclared,
   market-data-unreachable`) with a one-line meaning for each, and note
   `reference_resolution`/`recomputation` as spec-declared, checked
   outside this repo/deferred respectively — not silently dropped.
2. `market-analysis/hooks/directive.sh`: extend the `PRODUCES` argument
   text (or add a fifth argument if `core_role_directive`'s signature
   allows) to name the field vocabulary so a session reads it at
   SessionStart, not only in a handbook a session may not open.
3. `README.md`: add the loop_state vocabulary and the three field names
   to the existing "produces" bullet / a short new bullet list, so a
   first-time reader sees the spec-aligned vocabulary without opening
   the handbook.

## Out of scope

- No `gate.sh` changes (see Constraints/Rationale).
- No new `roles/market-analysis.json` or similar fabricated integration
  point — the handbook's existing enforcement-status note (core's
  `record-fields-gate.sh` is role-agnostic) still holds; this proposal
  doesn't change what's mechanically checked.
- `reference_resolution`'s guard script and `recomputation`'s enforcement
  — both explicitly deferred/out-of-repo per the spec itself.
- No TAM/SAM/SOM or SWOT additions — unrelated to this issue.

## How you'll know it worked

- `grep -ri force docs/ README.md`, `grep -ri assessment docs/ README.md`,
  `grep -ri evidence docs/ README.md` each return at least one hit after
  phase 2 (the `evidence` grep already passes today; `force` and
  `assessment` currently do not as literal field-name mentions with
  the spec's meaning — phase 2 must add those).
- `grep -rn "loop_state" docs/ README.md market-analysis/` shows exactly
  the five spec states (`researching, assessing, landed,
  evidence-undeclared, market-data-unreachable`) and no others.
- No existing test suite exists in this repo beyond `hooks/*.bats`; if
  phase 2 touches no gate code, `find . -iname '*.bats'` run count stays
  unchanged and bats suite (if invoked) still passes unmodified —
  otherwise state `unverifiable: no test suite present` for the
  documentation-only changes per the issue's acceptance criteria.
