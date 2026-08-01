# competitor-mapping

Phase-2 record-gate plugin for the market-analysis role. Enforces the
`competitor-list` shape required by
`docs/handbooks/market-analysis-norms.md` item (b).2: a direct + indirect
competitor inventory, each claimed fact backed by an evidence link
(pricing page, filing, product doc).

## Write surface

`PreToolUse` on `Write|Edit|MultiEdit|NotebookEdit` targeting
`docs/issue-<n>/reports/market-analysis.md` (the phase-2 record file only —
NOT phase-1 proposals under `docs/issue-<n>/proposals/`). Any other path is
allowed unconditionally.

## What it checks

1. A `competitor-list` section marker is present (heading or label,
   case-insensitive). Missing → deny `missing-section`.
2. Within that section, at least one direct-competitor marker
   (`direct competitor` / `### Direct`) and at least one
   indirect-competitor marker (`indirect competitor` / `### Indirect`).
   Missing either → deny `missing-direct` / `missing-indirect`.
3. Every competitor-entry-looking line (`- ...` or `**Name** ...`) within
   the section carries — on that line or the immediately following line —
   a citation marker (`http(s)://`, `Source:`, `citation`, or a markdown
   `[` link). One entry with none → deny `entry-without-citation`.

No ordering dependency on other plugins — combines independently with
`five-forces` / `jtbd-fit` / `evidence-rigor` on the same write surface
(market-analysis has no plugin sequencing constraint, unlike pricing's
chain — see `docs/issue-7/proposals/plugin-decomposition.md` §2.3).

## Kill switch

`export COMPETITOR_MAPPING_GATE_OFF=1`

## Running tests

```
bats market-analysis/plugins/competitor-mapping/tests/gate.bats
```

## Heuristic limitation

The citation check is a simple per-line/next-line text heuristic, not a
markdown parser — it cannot verify that a citation is *correct* or that it
actually supports the specific claim on that line, only that some citation
marker is present nearby. This matches the same mechanical-enforcement
limit already flagged for `evidence-rigor` in the plugin-decomposition
proposal (§4.2): presence, not sufficiency, is what a gate can check.

## Canon reference

`hooks/directive.sh` sources core canon's `core_role_directive` (via
`core/hooks/lib/role-directive.sh`) rather than duplicating hook-dispatch
logic locally, per canon-scripts.md's reference-only constraint.
