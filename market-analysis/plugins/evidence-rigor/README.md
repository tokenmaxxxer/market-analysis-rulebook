# evidence-rigor

Enforces market-analysis's highest-leverage cross-cutting norm from issue-1:
every methodological/factual claim must carry a source, or be explicitly
labeled an assumption. A `PreToolUse` gate on `Write|Edit|MultiEdit|NotebookEdit` checks
that the resulting document content contains an evidence block before the
write is allowed to land.

## Why this is the one cross-cutting plugin

Per `docs/issue-7/proposals/plugin-decomposition.md` §2.1/§2.2, this is the
**single plugin shared across both phase-1 and phase-2** compositions —
every other plugin in this rulebook (`mece-proposal`, `five-forces`,
`competitor-mapping`, `jtbd-fit`) is phase-specific. It is implemented once
and reused rather than duplicated per framework, directly operationalizing
issue-1's finding that evidence traceability was the single highest-leverage
norm across both phases.

See `docs/handbooks/market-analysis-norms.md`'s "Tool learnings
(issue-1199)" section (Crayon entry) for why every citation should
state the date the source was read, not only the URL.

## Write surfaces gated

- `docs/issue-<n>/proposals/*.md` — phase-1 proposals. Requires a
  `Sources:`/`## Sources` block (matching the norms handbook's own
  convention, and the existing `plugin-decomposition.md` proposal).
- `docs/issue-<n>/reports/market-analysis.md` — phase-2 record. Requires an
  `Evidence appendix` heading (handbook item (b).4).

Any other path is not this gate's business and passes through untouched.

## No ordering dependency

Unlike pricing's `scope-gate -> method-family -> design-rigor ->
verdict-report` chain, market-analysis methodology has no required plugin
sequencing (proposal §2.3) — this gate inspects only its own write, with no
state read from or written for any other plugin.

## Kill switch

`EVIDENCE_RIGOR_GATE_OFF=1`

## Mechanical limitation (accepted, not a defect)

This is a **presence-only** check: it detects whether an evidence block
exists, not whether individual citations are correct or sufficient. Per
proposal §4 item 2, this gap is accepted as inherent to mechanical
enforcement, matching the same limitation issue-1 already flagged for this
norm.

## Canon reference

`hooks/directive.sh` sources core canon's `core_role_directive` rather than
copying directive logic, following the same stub pattern used by
`market-analysis/hooks/directive.sh` and the pricing plugin family.

## Tests

```
bats market-analysis/plugins/evidence-rigor/tests/gate.bats
```
