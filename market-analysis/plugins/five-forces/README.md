# five-forces

Porter's Five Forces phase-2 record-gate for market-analysis.

## What it enforces

Per `docs/handbooks/market-analysis-norms.md` item (b).1, the market-analysis
phase-2 record must carry a `five-forces-summary` section with a per-force
verdict for all five Porter forces — competitive rivalry, threat of new
entrants, supplier bargaining power, buyer bargaining power, threat of
substitutes — each backed by an evidence citation, not a bare rating.

On a matching `Write`/`Edit`/`MultiEdit`/`NotebookEdit`, the gate reconstructs
the resulting document content and checks, case-insensitively:

1. a `five-forces-summary` (or "five forces summary") section marker exists;
2. all 5 force phrases are present as **distinct** substrings;
3. each force phrase has a citation marker (`http`, `source:`, `citation`,
   `cited`, or a markdown link `[text](url)`/`[^n]`) within roughly 400
   characters after it — a bare `[` with no following `(url)` or footnote
   marker does not count.

Missing the section denies with `missing-section`; a force phrase absent
entirely denies naming which force(s); a force present but uncited denies
naming which force(s) lack a nearby citation.

## Why supplier/buyer power stay distinct

Issue-7's WEAK-review fix: an earlier draft merged supplier and buyer
bargaining power into a single "supplier/buyer power" line, collapsing two
of Porter's five forces into one and understating the analysis. The gate
requires each to appear as its own separate phrase — a merged line is
treated as **both** forces missing, not one.

See `docs/handbooks/market-analysis-norms.md`'s "Tool learnings
(issue-1199)" section (SimilarWeb entry) for why competitive-rivalry
and threat-of-new-entrants verdicts should cite a quantified proxy
metric, not only a qualitative source.

See the same handbook's "2026-08-14 plugin-ecosystem rework" section
(`VoltAgent/awesome-claude-code-subagents` entry) for why a force
verdict needs an explicit "checked" marker, and (`phuryn/pm-skills`
entry) for why a market-size figure backing a verdict needs a second
independent source or derivation.

## Write surface

`docs/issue-<n>/reports/market-analysis.md` only — the phase-2 record file,
not phase-1 proposals (`docs/issue-<n>/proposals/*.md`).

## Ordering

No dependency on other market-analysis plugins. Unlike pricing's
scope-gate → method-family → design-rigor → verdict-report chain,
market-analysis methodology has no required plugin sequencing (see
`docs/issue-7/proposals/plugin-decomposition.md` §2.3) — this gate combines
independently with `competitor-mapping`/`jtbd-fit`/`evidence-rigor` on the
same write surface.

## Kill switch

`export FIVE_FORCES_GATE_OFF=1`

## Tests

```
bats market-analysis/plugins/five-forces/tests/gate.bats
```

## Canon reference

Structural form (SessionStart directive stub, fail-closed PreToolUse gate
skeleton) follows core canon's `core_role_directive` and the pricing
rulebook's `report-gate.sh` precedent — do not hand-roll directive logic
here; extend `core/hooks/lib/role-directive.sh` instead.
