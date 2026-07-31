# mece-proposal

Enforces the MECE 5-section structure required of a market-analysis
phase-1 proposal, per `docs/handbooks/market-analysis-norms.md` section (a)
(the norm adopted in issue-1) — mechanically, as a PreToolUse gate, per the
issue-7 plugin-decomposition mapping (`docs/issue-7/proposals/plugin-decomposition.md`
§2.1).

## What it enforces

A phase-1 proposal must state all 5 required elements before the write is
allowed to land:

1. **Decision framed** — the spec/positioning question this proposal informs.
2. **Framework selection + rationale** — each framework named must map to
   industry attractiveness, competitive positioning, or customer-need fit.
3. **Evidence plan** — expected source types and the independent-source bar.
4. **Adoption rationale** — why this methodology fits this decision boundary.
5. **Plugin-reflection plan** — what changes in `directive.sh` / record
   fields / gates, and what does not.

Missing any element denies the write (exit 2) and names the missing
element(s) by slug (e.g. `decision-framed`, `framework-selection`,
`evidence-plan`, `adoption-rationale`, `plugin-reflection-plan`).

## Write surface

`docs/issue-<n>/proposals/*.md` (regex `^docs/issue-[0-9]+/proposals/.*\.md$`).
Any other path is not this gate's business and is always allowed.

## Kill switch

`MECE_PROPOSAL_GATE_OFF=1` (any non-empty, non-"off"-like value) disables
the PreToolUse gate.

## Ordering

Independent. Unlike pricing's `scope-gate → method-family → design-rigor →
verdict-report` chain, the market-analysis methodology has no plugin
ordering constraint — this plugin runs standalone.

## Tests

```
bats market-analysis/plugins/mece-proposal/tests/gate.bats
```

## Canon reference, not copy

Per the plugin-decomposition proposal's canon-reference constraint (§2.6),
`hooks/directive.sh` sources core canon's `core_role_directive` rather than
duplicating role-directive logic. `hooks/gate.sh` writes its own
JSON-parsing / path-matching logic directly (no core helper exists yet for
this — a gap §2.6 flags), but does not copy core's PreToolUse dispatch
mechanism; it is wired in only via `hooks.json`'s `${CLAUDE_PLUGIN_ROOT}`
convention.
