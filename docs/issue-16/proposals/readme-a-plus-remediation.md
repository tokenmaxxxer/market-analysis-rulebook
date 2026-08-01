# Proposal — A+ 인증 마감 (issue-16, README-only 잔여 결함)

Phase-1 design proposal only. No file changes land in this PR. See
`docs/issue-16/reports/market-analysis/current-state-survey.md` for the
2-item defect inventory this proposal fixes in phase 2.

Scouting skip record: skipped — the spec leaves no design decision open.
Both fixes are dictated by matching README prose to already-landed,
already-tested code in this repo's own `gate.sh`/`hooks.json`/
`gate-lib.sh` (all covered green by `gate.bats`); there is no external
field to scout for a documentation-accuracy correction.

## Decision framed

Should the two README defects (five-forces: missing-NotebookEdit +
stale bare-`[` citation wording; mece-proposal: stale fail-open
kill-switch wording) be fixed by editing the README prose to match the
code, or by changing the code to match the README? Downstream hand-off:
none — README-only, no gate behavior changes, no other role's write
scope affected.

## Framework selected + rationale

Framework: adoption-rationale-over-reimplementation, read as competitive
positioning turned inward — same non-market frame issue-10/issue-13's
A+ remediation proposals used (the "competing alternative" is stale-doc
vs accurate-doc, not a market question). Industry attractiveness and
customer-need fit don't apply to a docs-only defect with no market or
customer dimension.

## Evidence plan

Primary source: this repo's own code, read directly (full citations in
Sources below). No external web source needed (scouting-skip rationale
above).

## Adoption rationale

Both gates already implement the correct, already-tested behavior (all
38 `gate.bats` cases pass on the unmodified code — see survey's test
log). The defect is that each README describes an earlier, already-
superseded state: five-forces' README undercounts its own matcher and
restates the exact bare-`[` citation laxity issue-13's remediation
already closed; mece-proposal's README restates the exact pre-issue-72
fail-open kill-switch idiom issue-10 already replaced. Editing the code
to match stale docs would be a regression, not a fix — the docs must
move to match the code, matching how issue-10/issue-13 always adopted
core's confirmed fix forward rather than re-deriving.

## Plugin-reflection plan

What changes (phase 2): `five-forces/README.md` — "What it enforces"
section, matcher list adds `NotebookEdit`, citation-marker description
updated to require `[text](url)`/`[^n]`, not bare `[`. `mece-proposal/
README.md` — "Kill switch" section rewritten to state the
`1`/`true`/`yes`/`on`-only on-spelling rule and cite
`gate_kill_switch_active`. What does not change: `gate.sh`, `hooks.json`,
`gate.bats` in either plugin — no code, no test, no gate behavior change;
phase 2 re-runs the existing 38-case `bats` suite unmodified to confirm
it stays green (the README edit touches no file the suite reads).

## Sources

- `market-analysis/plugins/five-forces/hooks/hooks.json:7` — PreToolUse
  matcher string `Write|Edit|MultiEdit|NotebookEdit`.
- `market-analysis/plugins/five-forces/hooks/gate.sh:105-113` — tool
  branch handling `NotebookEdit` via `notebook_path`.
- `market-analysis/plugins/five-forces/hooks/gate.sh:159` —
  `CITATION_RE` pattern (requires `[text](url)` or `[^n]`, not a bare
  `[`).
- `market-analysis/plugins/five-forces/tests/gate.bats` case "(p) bare
  [TODO] with no following (url) does not count as a citation" — passing.
- `core/hooks/lib/gate-lib.sh` (fetched via `CLAUDE_PLUGIN_ROOT_CORE`,
  cached at
  `/tmp/tokenmaxxxer-core-canon-cache/core/hooks/lib/gate-lib.sh`)
  `gate_kill_switch_active`, lines 61-68 — only `1`/`true`/`yes`/`on`
  disable; issue-72's fail-closed-on-garbage fix.
- `market-analysis/plugins/mece-proposal/tests/gate.bats` case "(k) kill
  switch set to an unrecognized value stays ACTIVE" — passing.
- `docs/issue-10/proposals/gate-a-plus-remediation.md` §1 — precedent for
  adopting core's confirmed fix by reference rather than re-deriving.
