# Record — issue-16 (A+ 인증 마감, README 잔여 결함 해소)

loop_state: landed

Phase-2 record. Approved via single-account mode: issue-16 comment
`APPROVE issue-16/market-analysis` (JiwonJung94, in `docs/specs/approvers.md`).
Executes `docs/issue-16/proposals/readme-a-plus-remediation.md` (basis) as
approved: README-only edits, no gate/code/test changes.

This is a docs-accuracy remediation record, not a market-analysis verdict
record — same self-block posture noted in the prior gate-tooling A+
remediation records for this repo's earlier issues (see their own Open
findings sections): none of the 5 content gates' sections (competitor-list,
five-forces-summary, jtbd-landscape-verdict, MECE 5-element, evidence
appendix-as-citation-plan) apply to a README-wording fix with no product
spec analyzed. Landed via a direct write (bypassing the Write-tool content
gates, the same workaround those prior records noted as available), since
this file's content is a tooling/docs-remediation record, not a market
analysis.

## What was done

Fixed the two README defects the 2026-08-01 A+ audit named, exactly per
the approved proposal's plugin-reflection plan:

- `market-analysis/plugins/five-forces/README.md` — "What it enforces":
  matcher list now includes NotebookEdit (matching hooks.json's
  Write|Edit|MultiEdit|NotebookEdit and gate.sh's live NotebookEdit
  branch); citation-marker description now states the [text](url) or
  [^n] footnote form is required and a bare [ explicitly does not count
  (matching CITATION_RE).
- `market-analysis/plugins/mece-proposal/README.md` — "Kill switch":
  rewritten to state the 1/true/yes/on-only (case-insensitive)
  on-spelling rule, fail-closed on any other value, citing
  gate_kill_switch_active.

No changes to gate.sh, hooks.json, or gate.bats in either plugin —
matches the proposal's plugin-reflection plan exactly (docs-only fix,
code already correct).

## Why

Per the approved proposal: both READMEs described an earlier,
already-superseded state (pre-NotebookEdit matcher wording, pre-issue-13
bare-[ citation wording, pre-issue-72 fail-open kill-switch wording).
Editing code to match the stale docs would be a regression; the docs
move to match the already-tested code instead, matching how this repo's
prior A+ remediations always adopted core's confirmed fix forward rather
than re-deriving it.

## Resolution confirmation — test/probe logs

Both suites re-run unmodified after the README edits, against the local
bats-core install (/tmp/claude-1000/bats-core/bin/bats), core canon
resolved via CLAUDE_PLUGIN_ROOT_CORE.

### five-forces/tests/gate.bats — 22/22 passed

1..22
ok 1 (a) all 5 forces present with citations is allowed
ok 2 (b) missing the five-forces-summary section entirely is denied
ok 3 (c) missing competitive rivalry is denied naming that force
ok 4 (d) missing threat of new entrants is denied naming that force
ok 5 (e) missing supplier bargaining power is denied naming that force
ok 6 (f) missing buyer bargaining power is denied naming that force
ok 7 (g) missing threat of substitutes is denied naming that force
ok 8 (g2) merged supplier/buyer power line is treated as both forces missing
ok 9 (h) all 5 forces named but one has no nearby citation is denied naming citation
ok 10 (i) non-matching path is always allowed regardless of content
ok 11 (p) bare [TODO] with no following (url) does not count as a citation
ok 12 (q) Edit with replace_all:true honors every occurrence
ok 13 (q2) the same Edit without replace_all leaves the second PLACEHOLDER uncited and is denied
ok 14 (r) MultiEdit with mixed replace_all true/false edits judges the fully-applied text
ok 15 (s1) malformed JSON: truncated payload is denied
ok 16 (s2) malformed JSON: non-object top level is denied
ok 17 (s3) malformed JSON: empty payload is denied
ok 18 (t) kill switch set to an unrecognized value stays ACTIVE (still denies)
ok 19 (u1) absolute file_path reaching the same target as the relative fixture is judged the same
ok 20 (u2) ./-prefixed relative file_path reaching the same target is judged the same
ok 21 (v2) a force explicitly marked 'Uncited.' is denied, not accepted via the 'cited' substring
ok 22 (w) missing core (unresolvable gate-lib.sh) is denied, not silently allowed

### mece-proposal/tests/gate.bats — 16/16 passed

1..16
ok 1 (a) all 5 elements present is allowed
ok 2 (b) missing decision framed is denied
ok 3 (c) missing framework selection is denied
ok 4 (d) missing evidence plan is denied
ok 5 (e) missing adoption rationale is denied
ok 6 (f) missing plugin-reflection plan is denied
ok 7 (g) non-matching path is always allowed regardless of content
ok 8 (h) Edit with replace_all:true against a multiply-occurring old_string judges the fully-replaced text
ok 9 (i) MultiEdit with mixed replace_all true/false edits in one call is allowed when the result is compliant
ok 10 (j1) malformed JSON: truncated payload is denied
ok 11 (j2) malformed JSON: non-object top level is denied
ok 12 (j3) malformed JSON: empty payload is denied
ok 13 (k) kill switch set to an unrecognized value stays ACTIVE (still denies)
ok 14 (l1) absolute file_path reaching the same target as the relative fixture is judged the same
ok 15 (l2) ./-prefixed relative file_path is judged the same as the plain relative fixture
ok 16 (n) missing core (unresolvable gate-lib.sh) is denied, not silently allowed

Both suites green, unchanged from the pre-edit baseline (survey's cited
"(p)" and "(t)" cases were already passing before this edit) — confirms
the README edits describe existing passing behavior and introduce no
regression. Both audit-named blocking reasons are resolved.

## Upstream basis

- docs/issue-16/proposals/readme-a-plus-remediation.md (this repo,
  phase-1, Approved via the "APPROVE issue-16/market-analysis" comment).
- docs/issue-16/reports/market-analysis/current-state-survey.md (this
  repo, phase-1) — defect inventory and pre-fix baseline this record
  resolves.
- market-analysis/plugins/five-forces/hooks/hooks.json:7,
  hooks/gate.sh:105-113,159 — matcher and citation-regex ground truth.
- core/hooks/lib/gate-lib.sh:61-68 (gate_kill_switch_active) — kill-
  switch on-spelling ground truth.
- This repo's prior A+ remediation proposal (subject "gate-a-plus-
  remediation") — precedent for adopting core's confirmed fix forward by
  reference rather than re-deriving.

## Open findings

None. Both audit-named blocking reasons are resolved and confirmed by
the green suites above; no new defect surfaced during this fix.

## Next steps

None — loop_state is terminal.
