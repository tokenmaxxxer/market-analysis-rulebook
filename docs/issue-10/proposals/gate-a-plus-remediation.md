# Proposal — 게이트 A+ 상향 (issue-10)

Phase-1 design proposal only. No gate code changes in this PR; phase 2
implements this design after human Approve. This is a tooling-hardening
proposal about this role's own gates, not a spec-competitiveness
judgment — the MECE phase-1 elements below are restated in that frame per
`docs/handbooks/market-analysis-norms.md` section (a). See
`docs/issue-10/reports/market-analysis/current-state-survey.md` for the
defect inventory this proposal fixes and
`docs/issue-10/reports/market-analysis/scout-brief.md` for the reference
standard this proposal adopts.

## Decision framed

The decision this proposal informs: should this role's 5 PreToolUse gates
(five-forces, evidence-rigor, competitor-mapping, jtbd-fit,
mece-proposal) be raised from grade A- to A+ by re-deriving each fix
independently, or by adopting core's already-landed gate-house standard
(issue-72) by reference? Downstream hand-off: none — this stays inside
market-analysis's own tooling; no other role's write scope changes.

## Framework selected + rationale

Not an industry-attractiveness/competitive-positioning/customer-need-fit
market framework — this proposal's subject is this role's own
enforcement tooling, not a spec's market position. The applicable
analogue is **adoption rationale over reimplementation**: read as
competitive positioning turned inward, does re-deriving a fix compete
with, or lose to, the standard core already proved correct on its own
seven gates? See Adoption rationale below for why "reimplement" loses on
both correctness and duplication grounds — this stands in for framework
selection because the proposal's decision boundary is not a market
question.

## Evidence plan

Primary source: the canon reference itself
(`core/hooks/lib/gate-lib.sh`/`gate-lib.py`,
`docs/handbooks/gate-house-standard.md`,
`docs/handbooks/role-gates-tests.md`), read directly — one primary
source, but it is the authoritative specification for the mechanism being
adopted, not a claim needing independent corroboration. Secondary:
this repo's own gate.sh/gate.bats/README.md, read directly (defects are
directly observable in the code, not claims requiring a second source).
Minimum bar: every defect claim in the survey is backed by a file:line-
level read, not by inference; no external web source is used or needed
(scout-brief.md's stage-count rationale).

## Adoption rationale

Reimplementing each fix independently in this repo would recreate the
same failure pattern issue-72's own audit found: 43 downstream repos each
re-deriving trap/kill-switch/normalize/reconstruct logic with 2-3
different idioms, one of which (this repo's kill-switch polarity) is
already wrong. Adopting `gate-lib.sh`/`gate-lib.py` by reference — never
vendoring a copy — means this role's gates inherit any future fix to the
shared mechanism automatically, and `compliance-check.sh` / canon-manifest
registration catch drift or accidental vendoring mechanically instead of
by review-time vigilance. This is also what the issue body explicitly
requires ("자체 재구현 금지"), so the rationale and the mandate coincide.

## Plugin-reflection plan

What changes: each of the 5 `hooks/gate.sh` files (source `gate-lib.sh`,
load `gate-lib.py`, drop the private trap/kill-switch/resolve/reconstruct
code); a new shared `market-analysis/plugins/lib/section-extract.py`
(in-repo, not core canon); each `tests/gate.bats` (six mandatory case
groups + false-pass regressions); `README.md` (layout + kill-switch
table). What does not change: `directive.sh` in any plugin, `hooks.json`
wiring, the record's required-field shape (§(b) of the norms handbook is
unaffected — this proposal is about how phase-1/phase-2 writes are
*checked*, not what they must *contain*), and no new plugin or gate is
added — the count stays 5.

## 1. Adopt core's gate-house standard by reference (issue-72)

Every one of the 5 gates (`market-analysis/plugins/{five-forces,
evidence-rigor, competitor-mapping, jtbd-fit, mece-proposal}/hooks/gate.sh`)
sources `gate-lib.sh` and loads `gate-lib.py`, replacing its own
hand-rolled copy of each mechanism — never reimplementing:

```bash
# top of each gate.sh, replacing the current __fc()/trap block:
. "${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${FIVE_FORCES_GATE_OFF:-}" || { trap - EXIT; exit 0; }
```

```python
# inside each gate's heredoc Python payload, replacing the private
# resolve()/_apply_replace-style reconstruction:
import importlib.util, os
_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

ev = gate_lib.gate_parse_json_or_deny(raw, deny)
rel = gate_lib.gate_normalize_path(root, path)          # replaces private resolve()/_under()
new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)  # replaces .replace(o, n, 1)
if not ok:
    deny("...")
```

This directly fixes survey items 1 (kill-switch fail-open), 5
(replace_all-ignoring + no-NotebookEdit), 6 (duplicated trap), and 7
(duplicated path-normalize) — by deletion of the duplicated logic, not by
patching each of the 5 copies independently. `CORE_PLUGIN_ROOT` resolution
follows the exact sibling-path shape `role-gates-tests.md` already
documents and flags as unverified against the real marketplace-install
layout; phase 2 verifies it against this repo's actual installed layout
before relying on it, per that same caveat.

`market-analysis/hooks/lib/gate-lib.sh` and `gate-lib.py` do not exist in
this repo and must not be created — the `.` source line resolves to
core's copy at gate-run time. `stub-check.sh`/`compliance-check.sh`
already catch an accidental vendor.

## 2. Semantic checks: substring → section/adjacency/structure

Fixes survey item 2 (buyer/supplier substring merge false-pass) and
generalizes the technique scout-brief.md identifies as this repo's own
best existing instance (competitor-mapping's heading-bounded section
slice) to the other 4 gates, replacing whole-document `re.search` on the
lowered full text.

New shared helper (in-repo, not core canon — this is market-analysis-
specific document structure, not a cross-rulebook mechanism):
`market-analysis/plugins/lib/section-extract.py`, loaded the same
importlib way as `gate_lib`, providing:

- `extract_section(lines, section_pattern)` — locate the first heading
  line matching `section_pattern`, return `(section_lines, start, end)`
  bounded by the next same-or-shallower heading (competitor-mapping's
  current technique, lifted out verbatim and shared).
- `distinct_bullet_mentions(section_lines, phrase_pattern)` — a match
  only counts if `phrase_pattern` is the leading content of its own
  bullet/list-item line (`^\s*[-*]\s...`) or its own paragraph (blank
  line before), not a substring anywhere in a longer line shared with
  another phrase. This is what closes the "supplier/buyer power: X"
  merged-line false pass: two force names on one bullet line no longer
  both count as "found."

five-forces adopts both: locate `## five-forces-summary` via
`extract_section`, then require each of the 5 force phrases as a
*distinct* bullet mention via `distinct_bullet_mentions` — a merged
"supplier/buyer power" line now satisfies at most one force, and the
gate correctly reports the other as missing. evidence-rigor's structure
check stays presence-only per its documented accepted limitation (existing
comment, §4.2 in its own header) but the "Sources" match moves from
whole-document `in` check to requiring a `## Sources` / `Sources:` heading
line rather than any substring occurrence anywhere (closes a parallel
false-accept: "resources: none" currently would satisfy `"sources:" in
low`). jtbd-fit and mece-proposal gates get the same
`extract_section`-based section-bounding for their own structure checks
(current bespoke section-location logic in each, read during phase 2's
migration, replaced with the shared helper).

## 3. Citation-marker strictness

Fixes survey item 4. Replace `CITATION_RE`/`citation_re`'s bare `\[`
alternative with a real link/footnote shape:

```python
CITATION_RE = re.compile(r'https?://|source:|citation|cited|\[[^\]]+\]\([^)]+\)|\[\^[^\]]+\]')
```

`\[[^\]]+\]\([^)]+\)` matches a markdown inline link `[text](url)`;
`\[\^[^\]]+\]` matches a footnote reference `[^n]`. A bare `[` or
`[TODO]` with no following `(...)`/no `^` no longer counts as evidence.
Applied identically in five-forces and competitor-mapping (the two gates
with this pattern today).

## 4. Deny-reason delivery (issue ask item 1, stderr)

Already correct in all 5 gates today (`deny()` writes to `sys.stderr` /
`stderr.write`, confirmed in current-state-survey.md §2) — no change
needed here; phase 2's compliance pass re-confirms rather than assumes.

## 5. Mandatory test cases (issue ask item 3)

Each plugin's `tests/gate.bats` gains the six canon-mandated case groups
from `role-gates-tests.md`, adapted to that gate's own fixture content,
plus the false-pass regression cases this proposal closes:

1. `Edit` with `replace_all: true` against a multiply-occurring
   `old_string` — asserts the *second* occurrence's change is what the
   gate judges, not the first.
2. `MultiEdit` with mixed `replace_all: true`/`false` edits in one call.
3. Malformed JSON (truncated, non-object, empty) — already covered
   informally; formalize as its own named `@test`.
4. Kill switch set to an unrecognized/typo value (e.g.
   `FIVE_FORCES_GATE_OFF=maybe`) — must assert the gate stays **active**
   (denies a bad write), the direct regression test for survey item 1.
5. Absolute `file_path` reaching the same target a relative-path fixture
   already reaches, plus a `./`-prefixed variant.
6. A `Bash`-tool file write reaching the same target — deferred per
   scout-brief.md's adopt/skip call unless phase 2's compliance-check
   pass surfaces an actual Bash-write path to these docs; if deferred,
   the test suite's skip is recorded with the same one-line reason, not
   silently dropped.

Plus, per-gate false-pass regressions:

- five-forces: a single bullet line `Supplier/buyer power: moderate.
  Source: ...` must be denied as missing one of the two forces (not
  accepted as satisfying both) — direct regression for survey item 2.
- five-forces / competitor-mapping: a bare `[TODO]` with no following
  `(url)` must NOT count as a citation — regression for survey item 4.
- evidence-rigor: `Resources: none listed` must NOT satisfy the sources
  check (substring-of-"sources" false accept closed alongside item 4).

"배송 상태에서 전 스위트 green" (issue ask item 3): phase 2's Definition
of Done includes a full `bats` run across all 5 `tests/gate.bats` plus the
adapted `run-gate-lib-tests.sh`-shape six-case suite, and
`compliance-check.sh` run clean against `market-analysis/plugins/*/hooks`,
before the phase-2 record is written — matching gate-house-standard.md's
per-repo migration checklist steps 3-4.

## 6. README realignment (issue ask item 4)

Fixes survey §3. `README.md`'s Layout section is rewritten to match the
real tree:

- Remove the three ghost files (`record-fields-gate.sh`, `trailer-gate.sh`,
  `handbook-trigger-gate.sh`) and the ghost `agents/warrant-hunter.md` —
  none exist in this repo (that canon lives in core, not vendored here).
- Document the real layout: `market-analysis/hooks/{directive.sh,
  hooks.json}` (SessionStart only) plus, per plugin,
  `market-analysis/plugins/<name>/hooks/{gate.sh, directive.sh,
  hooks.json}` and `tests/gate.bats`.
- Add a kill-switch inventory table (`FIVE_FORCES_GATE_OFF`,
  `EVIDENCE_RIGOR_GATE_OFF`, `COMPETITOR_MAPPING_GATE_OFF`,
  `JTBD_FIT_GATE_OFF`, `MECE_PROPOSAL_GATE_OFF`) — currently undocumented
  anywhere.

## 7. Out of scope for this issue (flagged, not decided)

- `gate_bash_write_targets` adoption — scout-brief.md's adopt/skip call;
  left to phase 2's compliance pass to confirm whether it's load-bearing
  here before adding it.
- evidence-rigor's citation-correctness/sufficiency limitation (its own
  header already documents this as accepted, §4.2) — unchanged by this
  proposal; only the section-presence and false-accept fixes above are
  in scope.

## Evidence appendix

- `core/hooks/lib/gate-lib.sh`, `core/hooks/lib/gate-lib.py` (local
  reference copy, issue-72 landed) — canon functions cited in §1.
- `docs/handbooks/gate-house-standard.md`, `docs/handbooks/role-gates-tests.md`
  (local reference copy) — six-case test harness (§5), migration
  checklist (§5 DoD), `CORE_PLUGIN_ROOT` caveat (§1).
- This repo's `market-analysis/plugins/*/hooks/gate.sh`,
  `market-analysis/plugins/*/tests/gate.bats`, `README.md` — read
  directly, defects enumerated in `current-state-survey.md`.

## Sources

- `core/hooks/lib/gate-lib.sh`, `core/hooks/lib/gate-lib.py` (local
  reference copy of core's issue-72-landed canon).
- `docs/handbooks/gate-house-standard.md`,
  `docs/handbooks/role-gates-tests.md` (local reference copy).
