# jtbd-fit

Phase-2 record-gate for market-analysis's Jobs-to-be-Done customer-need-fit
verdict. Enforces `docs/handbooks/market-analysis-norms.md` item (b).3:
the `jtbd-landscape-verdict` section must state the customer job the spec
competes to satisfy, and whether the spec's differentiation holds against
the strongest competing alternative for that job.

See `docs/handbooks/market-analysis-norms.md`'s "Deliverable rules
(issue-1199)" section for why the verdict cites at least two
independent evidence points and separates preference from reach.

## Write surface

`PreToolUse` on `Write|Edit|MultiEdit|NotebookEdit` targeting
`docs/issue-<n>/reports/market-analysis.md` (the phase-2 record file only —
not proposals). Non-matching paths always pass.

On a matching write, the gate reconstructs the resulting file content and
checks (case-insensitive) for three elements:

1. A `jtbd-landscape-verdict` section marker.
2. A customer-job statement (e.g. "job to be done", "customer job",
   "hired to", "jtbd:").
3. A differentiation-verdict clause against the strongest competing
   alternative (e.g. "differentiation holds", "strongest competing
   alternative", "verdict:").

Missing elements deny the write (exit 2) naming which element is absent:
`missing-section`, `missing-job-statement`, or `missing-verdict-clause`.

## Kill switch

`export JTBD_FIT_GATE_OFF=1`

## Composition

No ordering dependency on other plugins. Combines independently with
`five-forces`, `competitor-mapping`, and `evidence-rigor` on the same
write surface — market-analysis has no plugin sequencing constraint
(unlike pricing's chain). See
`docs/issue-7/proposals/plugin-decomposition.md` §2.3.

## Canon reference

`hooks/directive.sh` is a thin stub over core canon's
`core_role_directive` (see `market-analysis/hooks/directive.sh` for the
top-level precedent this follows one directory deeper).

## Tests

```
bats market-analysis/plugins/jtbd-fit/tests/gate.bats
```
