# Current-state survey — issue-19 (spec-vocabulary alignment)

Scouting skip record: skipped — the spec (`market-analysis.spec.json`,
read from `~/.claude/plugins/marketplaces/tokenmaxxxer/roles/specs/`)
already fixes the exact field names, enum values, and loop_state
vocabulary; there is no market/exemplar field to scout because the
decision is "where do these already-fixed names land in this rulebook's
existing docs/hooks," not "what should the vocabulary be." Same posture
as `docs/issue-13/proposals/gate-a-plus-final-remediation.md`.

## Spec, read verbatim

`required_fields`: `force` (enum: new-entrants, supplier-power,
buyer-power, substitutes, rivalry), `assessment` (enum: low, medium,
high), `evidence` (string).

`reference_resolution`: evidence citing a competitor must resolve to a
tracked competitor entry — `checked_by:
on-the-record/hooks/role-spec-reference-guard.sh`. That guard lives in
`on-the-record`, not this rulebook; grep of this repo confirms no such
script exists here (`find . -iname 'role-spec-reference-guard.sh'` →
empty).

`recomputation`: assessment recomputed from current evidence each market
review — spec itself marks `checked_by: TBD (follow-up)`, explicitly
out of scope for now.

`write_scope`: `docs/issue-<n>/reports/market-analysis.md`.

`loop_state`: progress `researching, assessing`; terminal `landed`;
refusal `evidence-undeclared`; error `market-data-unreachable`.

## What this rulebook already has

- `docs/handbooks/market-analysis-norms.md` (b).1 requires a
  `five-forces-summary` section, "per-force verdict for all five Porter
  forces," each "with an evidence citation, not a bare rating."
- `market-analysis/plugins/five-forces/hooks/gate.sh` mechanically
  requires the 5 named forces (competitive rivalry, threat of new
  entrants, supplier bargaining power, buyer bargaining power, threat of
  substitutes) as distinct bullets, each with a nearby citation marker
  (URL / `source:`/`citation`/`cited` / markdown link / footnote).
- `market-analysis/plugins/evidence-rigor/hooks/gate.sh` requires a
  `## Sources` / `Sources:` heading (proposals) or an "evidence
  appendix" heading (phase-2 record).
- `market-analysis/plugins/competitor-mapping/hooks/gate.sh` requires a
  `competitor-list` section with ≥1 direct + ≥1 indirect competitor,
  each evidence-linked.
- `market-analysis/hooks/directive.sh` states role identity, use-when,
  produces, hand-off — no loop_state, no field-name vocabulary.
- `grep -rn "loop_state" docs/ README.md market-analysis/` → **zero
  hits**. This rulebook currently defines no loop_state vocabulary for
  the market-analysis record at all — it is not in the sanctioned
  9-kind table in `tokenmaxxxer-core/core/contract/role-handoff-contract.md`
  either (that table lists product/coding/qa/feasibility/ux-design/
  review/verify/ops/reflect only), so `market-analysis` loop_state is
  this rulebook's own thing to define, not inherited from core.
- Record path already matches spec `write_scope` exactly:
  `docs/issue-<n>/reports/market-analysis.md`.

## Field-by-field mapping (write set this survey aims the proposal at)

| spec field/state | existing rulebook concept | gap |
|---|---|---|
| `force` (enum, 5 values) | the 5 Porter force bullet labels already enforced by five-forces gate | vocabulary not spelled out anywhere as the literal enum strings (`new-entrants` etc.) — handbook/README use prose names only |
| `assessment` (enum low/medium/high) | "per-force verdict" language in handbook (b).1; gate only checks a citation exists, not a rating value | **no existing concept enforces or even names a low/medium/high rating** — closest gap of the three |
| `evidence` (string) | citation-marker requirement in five-forces gate + Sources/evidence-appendix requirement in evidence-rigor gate | concept exists, name doesn't — handbook says "evidence citation," never the literal field name `evidence` |
| `reference_resolution` (competitor orphan check) | competitor-mapping gate checks presence of a competitor list, not that evidence *citing* a competitor resolves to a tracked entry | this specific check is out of this rulebook's write scope (lives in on-the-record); rulebook can only document the expectation, not gate it |
| `recomputation` (assessment recomputed each review) | none | spec marks this its own follow-up (`checked_by: TBD`) — genuinely no home needed yet |
| `loop_state: researching, assessing, landed, evidence-undeclared, market-data-unreachable` | none | entirely new; no vocabulary currently exists to conflict with or extend |

## Files this proposal expects to touch

- `docs/handbooks/market-analysis-norms.md` — name the three field labels
  and the loop_state vocabulary as standing convention.
- `market-analysis/hooks/directive.sh` — surface the field-name vocabulary
  in the role directive text (argument to `core_role_directive`).
- `README.md` — document the loop_state vocabulary and field names for a
  first-time reader.
- New: `docs/issue-19/proposals/spec-vocabulary-alignment.md` (this
  proposal).
- Out of write scope for phase 2 as currently scoped: no gate.sh changes
  (mechanical enforcement of enum values / loop_state is a separate,
  larger gate-authoring effort than "align vocabulary," and the spec's
  own `recomputation.checked_by` shows the spec's authors already treat
  granular enforcement as a deliberately separate follow-up).
