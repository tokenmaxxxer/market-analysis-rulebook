---
proposal: docs/proposals/2026-08-09-spec-vocabulary-alignment.md
---

# Hunt record — spec-vocabulary-alignment

## after-proposal — stance 0: gate/role-ownership bypass hunt

Verdict: NO FINDING
Seed: docs/issue-19/proposals/spec-vocabulary-alignment.md, docs/issue-19/reports/implementation/survey.md (docs-only, 2 new files)
cap_seconds: 60
tier: size:docs-only
diff_stat_lines: 2 files added
started_at: 2026-08-09T00:00:00Z
ended_at: 2026-08-09T00:02:30Z

Investigated board-gate.sh (found at /home/jwjung/tokenmaxxxer-core/core/hooks/board-gate.sh,
sourced from tokenmaxxxer-core since no such script exists inside this repo)
for R5 (reports/ ownership) and R1 (layout) bypass. The proposal's own
`files:` frontmatter lists only standing-bucket paths (docs/handbooks/...,
README.md) and a non-docs/ path (market-analysis/hooks/directive.sh), none
of which are docs/issue-N/reports/ paths, so R5 never applies to them.
survey.md was written to docs/issue-19/reports/implementation/survey.md,
which matches R5's own-subtree rule (tail[0] == role "implementation")
exactly.

Reproduced the specific bypass the stance asks about directly: simulated a
Write to docs/issue-19/reports/market-analysis.md (the market-analysis
role's write_scope path per the spec) under this repo's own
CLAUDE_ROLE=implementation / branch issue-19/implementation, via:

    CLAUDE_ROLE=implementation CLAUDE_PROJECT_DIR="$(pwd)" bash -c
    'echo "{ tool_name: Write, tool_input: { file_path: docs/issue-19/reports/market-analysis.md } }"
    | board-gate.sh; echo exit=$?'

Observed: refused as expected -- "board-gate: docs/issue-19/reports/market-analysis.md
belongs to another role. implementation writes only implementation.md,
implementation/** -- never a foreign record. (contract v3 s11)" (exit 2).
No bypass found: R5's ownership check is keyed off CLAUDE_ROLE plus the
actual write target, not off anything the proposal or survey.md *claims*
it will touch, so a mismatch between the proposal's stated intent and the
gate's real enforcement cannot arise -- the gate never reads proposal or
survey content at all. No proposal-shape-gate.sh or survey-order-gate.sh
exists in this repo to check against either.
