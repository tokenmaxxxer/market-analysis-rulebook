# Phase-2 record — issue-7: market-analysis methodology plugin set

Subject: issue-7. Phase 2 execution, gated on the `APPROVE issue-7/market-analysis`
issue comment (author JiwonJung94, MEMBER), which followed a corrective
comment from the same approver requiring the plugin-set structure (not a
single deepened gate/directive) recorded in
`docs/issue-7/proposals/plugin-decomposition.md`.

This is a methodology-enforcement build, not a market-analysis verdict
record: no product spec was analyzed, no five-forces/competitor/JTBD
verdict was produced for an actual decision — none of that applies here.
The counts below (files, tests) are build metrics, not market-analysis
findings, and are labeled as such.

## What was done

Implemented `docs/issue-7/proposals/plugin-decomposition.md` as approved:
five self-contained plugins under `market-analysis/plugins/`, each with
its own `.claude-plugin/plugin.json`, `hooks/hooks.json`,
`hooks/directive.sh` (SessionStart, sourcing core canon's
`core_role_directive` — not copied), a fail-closed PreToolUse gate script,
`tests/gate.bats`, and a `README.md` — matching the freelunch/scout
completeness bar the approver named.

| Plugin | Owns | Write surface | Kill switch |
|---|---|---|---|
| `mece-proposal` | Phase-1 5-element structure check | `docs/issue-<n>/proposals/*.md` | `MECE_PROPOSAL_GATE_OFF` |
| `evidence-rigor` | Sources/evidence-appendix presence | proposals + `reports/market-analysis.md` | `EVIDENCE_RIGOR_GATE_OFF` |
| `five-forces` | 5 distinct Porter forces, each cited | `reports/market-analysis.md` | `FIVE_FORCES_GATE_OFF` |
| `competitor-mapping` | Direct+indirect, evidence-linked | `reports/market-analysis.md` | `COMPETITOR_MAPPING_GATE_OFF` |
| `jtbd-fit` | Customer job + differentiation verdict | `reports/market-analysis.md` | `JTBD_FIT_GATE_OFF` |

Per the proposal's §2.3 finding (confirmed against
`docs/handbooks/market-analysis-norms.md`), the adopted methodology has
no required analysis ORDER between the four phase-2 frameworks — unlike
pricing-rulebook's chained plugin set (issue-10, read as the direct
precedent for this build), no cross-plugin state file was built. Each
gate inspects only its own section on the same record-write PreToolUse
event, independently.

Registered as five new entries in `.claude-plugin/marketplace.json`
alongside the existing `market-analysis` entry (a build-count label: 5
new plugin entries, not a market-analysis figure).

### Not changed

- `market-analysis/hooks/directive.sh` (the umbrella plugin's own
  SessionStart directive) — left as-is; the proposal did not ask for its
  `PRODUCES` line to be rewritten, only for the norm to be mechanically
  decomposed into the five plugins above.
- `docs/handbooks/market-analysis-norms.md` — unchanged; it remains the
  norm source these five gates mechanically enforce.

## Why

Per the approved proposal: issue-7 asked that review-time-only norms
(directive line + handbook prose, adopted in issue-1) become
machine-enforced, and the approver's corrective comment specified this be
a set of independent, freelunch/scout-level-complete plugins rather than
one deepened gate — mirroring core's `freelunch`/`scout`/`warrant` family
and pricing-rulebook's own plugin-set precedent (issue-10). The five
plugin boundaries were chosen to align 1:1 with the units issue-1 already
adopted (three frameworks + the MECE proposal-structuring norm + the
cross-cutting evidence-rigor norm), so approving the phase-1 proposal
reopened no methodology question — only the enforcement-architecture one.

## Upstream basis

- `docs/issue-7/proposals/plugin-decomposition.md` (this repo, phase-1, Approved).
- `docs/issue-7/reports/market-analysis/current-state-survey.md`, `scout-brief.md` (this repo, phase-1).
- `docs/handbooks/market-analysis-norms.md` (this repo) — the norm content each gate mechanically checks.
- `pricing-rulebook` issue-10 `pricing/plugins/*` and `docs/issue-10/reports/pricing.md` — read directly as the plugin-set structural precedent (gate-script skeleton, bats test shape, marketplace registration path, this record's own shape).
- `tokenmaxxxer-core` `scout`/`freelunch` plugins — read directly as the multi-plugin-per-rulebook precedent the approver named.

## Verification

All five `tests/gate.bats` files were run against a local `bats` build
(bats-core, not preinstalled in this checkout — cloned and invoked
directly). 34 tests total, all passing after two gate bugs found during
this verification pass were fixed:

- `five-forces/hooks/gate.sh`: the per-force citation window (originally
  a flat 400-char lookahead) could bleed past a bullet boundary and pick
  up the *next* force's citation, masking a genuinely uncited force. Now
  capped at the next force-phrase or next bullet, whichever comes first.
- `competitor-mapping/hooks/gate.sh`: section-end detection stopped at
  ANY markdown heading, including the `### Direct`/`### Indirect`
  subheadings that are themselves part of the `competitor-list` section
  body — truncating the section before it was read. Now stops only at a
  heading of the same or shallower level than the section marker itself.

Both fixes are in the committed gate scripts; the bats files that caught
them are committed as-is (one test's fixture text was also adjusted —
it had accidentally used the word "citation" inside its own negative-case
prose, which the gate's citation-marker check then matched).

`bash -n` syntax-checked all ten `hooks/*.sh` files; all JSON files
(`plugin.json`, `hooks.json`, `marketplace.json`) parsed cleanly with
`python3 -m json`.

## Open findings

- No `core/` file was read, copied, or moved — every plugin's
  `directive.sh` sources the same `role-directive.sh` library convention
  the pre-existing umbrella `market-analysis/hooks/directive.sh` already
  used (one path level deeper). If `core/` is genuinely absent at
  hook-run time, sourcing fails the same way the pre-existing umbrella
  file already would — not a new gap introduced by this work.
- The evidence-citation checks in `evidence-rigor`, `five-forces`, and
  `competitor-mapping` are presence-only (per proposal §4 item 2,
  reaffirmed): they cannot verify a citation is correct or sufficient,
  only that a citation-shaped marker exists near the claim. This is a
  stated, accepted limitation, not a defect discovered in this phase.
- **Self-block discovered and confirmed, left unresolved.** The four
  content gates (`evidence-rigor`, `five-forces`, `competitor-mapping`,
  `jtbd-fit`) fire unconditionally on any write matching
  `docs/issue-<n>/reports/market-analysis.md`, with no exemption for a
  meta/infra record like this one that legitimately contains none of
  their required sections (no product spec was analyzed this round).
  Piping this very file's content through all four gate scripts directly
  (bypassing the fact that they are not actually installed/loaded in
  this session) confirms all four would `exit 2` and refuse this write
  in a live session with the plugins active. This is a real gap, not a
  hypothetical: any future infra/meta issue for this role (the same
  shape as issue-2 or this issue-7) would be unable to write its own
  phase-2 record once these plugins are live, because the write surface
  regex cannot distinguish a market-analysis verdict record from a
  methodology-build record on the same path. The approved proposal did
  not ask for this distinction and none of the four gates' test suites
  cover it, so no fix is applied here — flagged for the approver /a
  follow-up issue to decide the right exemption shape (e.g., a
  `record-type:` frontmatter key the gates check, or scoping the four
  content gates to fire only when `CLAUDE_ROLE_TASK_KIND` or similar
  signals a verdict-producing issue) rather than picked unilaterally
  here as an unreviewed scope addition.

loop_state: landed

## Next steps

None — loop_state is terminal. The self-block open finding above is a
real gap in this delivered design, not a blocker for issue-7 itself
(this record lands before the plugins are live in any session); it is
left for the approver to route as a follow-up issue rather than resolved
unilaterally here.
