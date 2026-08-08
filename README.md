# market-analysis-rulebook

Rulebook for the `market-analysis` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion and
generated as skeleton scaffolding by issue-170.

- **decides**: 경쟁 구도에서 이 스펙이 서는가
- **use_when**: product 스펙 확정 후, 경쟁 구도가 걸린 결정일 때
- **produces**: five-forces summary, competitor list w/ evidence links, JTBD-landscape verdict
- **write_scope**: []
- **hand-off**: 가격 정책이 걸리면 → pricing; 포지셔닝 메시지가 걸리면 → marketing
- **spec vocabulary** (`market-analysis.spec.json`): required deliverable fields `force`, `assessment`, `evidence` (per five-forces entry); `loop_state` values `researching, assessing, landed, evidence-undeclared, market-data-unreachable` — see `docs/handbooks/market-analysis-norms.md` (c) for the full mapping.

## Install

```
claude plugin marketplace add tokenmaxxxer/market-analysis-rulebook
claude plugin install market-analysis
```

## Layout

- `market-analysis/.claude-plugin/plugin.json` — root plugin manifest
- `market-analysis/hooks/hooks.json` — SessionStart wiring (role directive only)
- `market-analysis/hooks/directive.sh` — SessionStart role directive
- `market-analysis/plugins/lib/section-extract.py` — shared in-repo helper
  (heading-bounded section slice + distinct-bullet-mention check) used by
  the five plugin gates below; not core canon.
- `market-analysis/plugins/<name>/` — one directory per PreToolUse gate
  plugin: `five-forces`, `evidence-rigor`, `competitor-mapping`,
  `jtbd-fit`, `mece-proposal`. Each contains:
  - `.claude-plugin/plugin.json` — plugin manifest
  - `hooks/hooks.json` — PreToolUse wiring
  - `hooks/directive.sh` — plugin-scoped directive
  - `hooks/gate.sh` — the PreToolUse gate itself; sources core's
    `gate-lib.sh`/loads `gate-lib.py` (issue-72 gate-house standard,
    referenced never vendored — see
    `docs/issue-10/proposals/gate-a-plus-remediation.md`) for the shared
    fail-closed-trap / kill-switch / path-normalize / Write-Edit-MultiEdit-
    NotebookEdit reconstruction machinery, and its own domain-specific
    semantic check on top.
  - `tests/gate.bats` — that gate's test suite.
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

### Kill switches

Each gate has its own kill switch env var. Per `gate_kill_switch_active`,
only a recognized on-spelling (`1`/`true`/`yes`/`on`, case-insensitive)
disables the gate — empty, a recognized off-spelling, or any unrecognized
value all leave the gate **active**.

| Plugin | Kill switch |
| --- | --- |
| five-forces | `FIVE_FORCES_GATE_OFF` |
| evidence-rigor | `EVIDENCE_RIGOR_GATE_OFF` |
| competitor-mapping | `COMPETITOR_MAPPING_GATE_OFF` |
| jtbd-fit | `JTBD_FIT_GATE_OFF` |
| mece-proposal | `MECE_PROPOSAL_GATE_OFF` |

This is scaffolding, not a finished rulebook: fill in doctrine detail,
handoff enforcement, and any role-specific progress gate before treating
it as load-bearing.
