# Scout brief — issue-10 (게이트 A+ 상향)

Deliverable class: PreToolUse gate hardening (infra, not product/market
research). Per scout-directive's role-specific guidance, a non-product
deliverable scouts "the best of its own deliverable's kind" — here that
is core's own gate-house standard (issue-72), which is also the mandatory
precondition this issue names, so scout target and adoption target
coincide. No external web sweep: this is an internal single-repo
standard, not a category with competing products, so a multi-angle web
fan-out has no signal to gather beyond the one authoritative reference
already surveyed in current-state-survey.md §4.

Mode: single targeted read (not a 4-angle sweep) of the canon reference —
1 stage, well under the 5-stage/3min budget. Scope gate: this reduces to
the "spec literally leaves no design decision open" territory only for
*which* library to adopt (issue names it explicitly); it does NOT skip
scouting on *how* to raise the semantic checks from substring to
section/adjacency/structure — that design choice is scouted below against
the one existing in-repo exemplar that already does it better
(competitor-mapping's heading-bounded section extraction, survey §2).

## Must-bes (from gate-house-standard.md, what any A+ gate must do)

- Fail-closed EXIT trap installed via `gate_trap_fail_closed`, first
  statement, before `set -uo pipefail`.
- Kill switch: only a recognized on-spelling (`1`/`true`/`yes`/`on`)
  disables; everything else — including unrecognized/typo values — stays
  active. (`gate_kill_switch_active`)
- Malformed/empty/non-object JSON payload denies, not best-effort parses.
  (`gate_parse_json_or_deny`)
- Path normalization handles absolute, relative, and `./`-prefixed input
  to the same root-relative tail. (`gate_normalize_path`)
- `Edit`/`MultiEdit` reconstruction honors each edit's own `replace_all`
  flag independently; `NotebookEdit` is reconstructed (cell source), not
  silently skipped. (`gate_reconstruct_write`)
- A `Bash`-tool write reaching the same target a `Write`-tool call would
  hit is also caught. (`gate_bash_write_targets`)
- Six mandatory test-case groups (`run-gate-lib-tests.sh`), a
  `compliance-check.sh` detector run against the rulebook's own hooks
  dir, and canon-manifest registration so vendoring is caught.

## Performance axes this repo's gates should compete on

1. **Semantic precision** — section/adjacency/structure checks vs. flat
   substring search over the whole lowered document (issue's explicit
   ask). competitor-mapping's heading-level-bounded section slice is this
   repo's own best current instance; five-forces/evidence-rigor/jtbd-fit/
   mece-proposal should be raised to the same technique, not a novel one.
2. **Duplication** — one canon-sourced copy of trap/kill-switch/
   normalize/reconstruct vs. 5 independently hand-rolled near-identical
   copies (current state).
3. **Evidence-marker strictness** — a real `[text](url)` link or `[^n]`
   footnote vs. a bare `[` character (current false-accept, item 4 of
   survey §1).

## Adopt / skip

- **Adopt**: reference (never vendor) `gate-lib.sh`/`gate-lib.py` for
  trap/kill-switch/parse/normalize/reconstruct — matches issue's explicit
  "자체 재구현 금지." Adopt the six-case mandatory test harness shape and
  `compliance-check.sh` as the phase-2 acceptance gate.
- **Adopt**: generalize competitor-mapping's heading-bounded section
  extraction into a small shared in-repo helper the other 4 gates call,
  rather than hand-writing 4 more bespoke slicers.
- **Skip**: `gate_bash_write_targets` (Bash-write-target scanning) is a
  real gate-lib capability but out of scope for phase-2 unless a survey
  of this repo's actual write patterns shows a Bash-tool write path to
  these docs surfaces exists — current gates only ever see
  Write/Edit/MultiEdit/NotebookEdit tool calls in practice; adding it
  speculatively would be scope beyond the issue's ask. Proposal flags
  this as a phase-2 judgment call, not a decided cut.

## Gap line

Current state already meets: fail-closed trap shape, malformed-JSON deny,
non-matching-path passthrough (matches must-bes 1 and 3 above, informally
but correctly). Missing against must-bes: correct kill-switch polarity
(2), path-normalize via the pure canon function (4, currently a
filesystem-touching private reimplementation — not wrong, but duplicated
5x and untested against the six canon cases), replace_all-honoring
reconstruction and NotebookEdit coverage (5), Bash-write-target
consideration (6, explicitly skipped above), and the six-case mandatory
test harness + compliance-check.sh (7-8).

Sources: `core/hooks/lib/gate-lib.sh`, `core/hooks/lib/gate-lib.py`,
`docs/handbooks/gate-house-standard.md`, `docs/handbooks/role-gates-tests.md`
(all read via local reference copy of core, issue-72 landed); this repo's
own `market-analysis/plugins/*/hooks/gate.sh` and `tests/gate.bats`
(current-state-survey.md).

Stages used: 1 (targeted canon read, no web fan-out — deliverable class
has one authoritative in-repo reference, not a competing-product field).
