# Handbook — market-analysis methodology & deliverable norms

Standing convention for this role, adopted per issue-1 (approved
`docs/issue-1/proposals/methodology-and-deliverable-norms.md`). Applies to
every future issue this role works, not just issue-1.

## Enforcement status

Core's `record-fields-gate.sh` (per `tokenmaxxxer-core` commit `d5b544e0`,
confirmed in `docs/issue-2/reports/implementation.md`) enforces a
role-agnostic §20 structural check only (what-was-done / why / upstream-basis
/ `loop_state` / open-findings) against `docs/issue-<n>/reports/market-analysis.md`.
It does not read any per-role field list and cannot check evidence-citation
presence. The norms below are therefore **review-time norms, not mechanically
gated ones** — the approver and the author must check them by hand at PR
review, same as any other documentation-level requirement. No
`roles/market-analysis.json` exists or is being introduced; inventing one that
nothing in core reads would be a fabricated integration point (issue-2's
finding, reconfirmed here).

## (a) Phase-1 proposal norm

MECE, recommendation-first structure. A market-analysis phase-1 proposal must
contain:

1. **Decision framed** — the spec/positioning question this proposal informs and the downstream hand-off target.
2. **Frameworks selected + why each answers a distinct question** — each framework named must map to one of: industry attractiveness, competitive positioning, or customer-need fit. No framework may be included "because it's standard."
3. **Evidence plan** — expected source types (primary/secondary) and the minimum independent-source bar per non-trivial claim.
4. **Adoption rationale** — the logical argument tying the chosen methodology to this role's decision boundary, not a generic best-practice citation.
5. **Plugin-reflection plan** — what changes in `directive.sh` / record fields / gates, and what does not.

**Evidence format:** every methodological claim carries a source (URL or named
standard); unsourced claims are explicitly labeled as assumptions.

## (b) Phase-2 deliverable norm

Bottom-up-first evidence gathering (source named + method noted); top-down
used only for framing/context. `docs/issue-<n>/reports/market-analysis.md` must
contain:

1. **`five-forces-summary`** — per-force verdict for all five Porter forces (competitive rivalry, threat of new entrants, supplier bargaining power, buyer bargaining power — two distinct forces, not one merged "supplier/buyer power" line — and threat of substitutes), each with an evidence citation, not a bare rating.
2. **`competitor-list`** — direct + indirect competitors, each claimed fact backed by an evidence link (pricing page, filing, product doc).
3. **`jtbd-landscape-verdict`** — the customer job the spec competes to satisfy, and whether the spec's differentiation holds against the strongest competing alternative for that job.
4. **Evidence appendix** — flat list of every source used across 1–3.

No sizing (TAM/SAM/SOM) or full per-competitor SWOT is required — this role's
decision boundary ("경쟁 구도에서 이 스펙이 서는가") is a competitive gate, not
a market-sizing or product-discovery task; adding those would serve a
different role's decision, not this one's.

## (c) Spec vocabulary (realized `market-analysis.spec.json`, issue-19)

The realized marketplace spec's three required deliverable fields map onto
the existing `five-forces-summary` requirement above — they are not new
content, they are the literal field labels for what (a)/(b) already
require:

- **`force`** — one of the five Porter forces named in (b).1 (competitive
  rivalry, threat of new entrants, supplier bargaining power, buyer
  bargaining power, threat of substitutes).
- **`assessment`** — the per-force verdict (low/medium/high) already
  required by (b).1's "per-force verdict."
- **`evidence`** — the citation already required by (b).1's "evidence
  citation, not a bare rating" and by (b).2's "evidence link."

**`loop_state` vocabulary** (spec-declared, exact five values — no stale or
extra states):

| value | meaning |
|---|---|
| `researching` | gathering evidence for five-forces / competitor-list / JTBD before any verdict is drafted |
| `assessing` | verdicts drafted, evidence being cited/checked per (b) |
| `landed` | deliverable complete and merged (terminal) |
| `evidence-undeclared` | a claim exists with no evidence citation — blocks `landed` per (b)'s "not a bare rating" / "backed by an evidence link" requirements |
| `market-data-unreachable` | a required source could not be reached/found; state this explicitly rather than silently omitting the force/competitor/JTBD item |

**Spec fields deferred, not silently dropped:**

- `reference_resolution`'s checker (`role-spec-reference-guard.sh`) lives in
  `on-the-record`, outside this repo's write scope — this handbook can only
  document the expectation, not gate it.
- `recomputation`'s `checked_by: TBD` is the spec's own declared
  follow-up, not something this rulebook closes.

## Tool learnings (issue-1199)

Five design moves borrowed from the surveyed competitive-intelligence
tool landscape, each a checklist upgrade — not a tool endorsement or a
dependency. Full adoption-evidence trail:
`docs/issue-1199/reports/market-analysis/scout-brief.md` in
`on-the-record`.

1. **Klue** (battlecard + win/loss portal; ~$45M ARR estimate, per a
   multi-source competitive-intelligence market survey). Problem: a
   competitor-list entry written as free prose omits the fields a
   decision actually needs (price point, positioning claim, why deals
   are won/lost against them). How: a battlecard format with named,
   fixed fields per competitor rather than a paragraph. Upgrades
   **(b).2** — every `competitor-list` entry states pricing,
   positioning, and win/loss-reason as distinct labeled fields, not
   folded into one sentence.
2. **Crayon** (website/pricing change-tracking; ~$70M ARR estimate,
   same survey). Problem: a competitor pricing-page citation goes
   stale silently — the same URL can support a true claim today and a
   false one next quarter. How: continuous change-tracking, so every
   captured fact carries the date it was observed. Upgrades the
   **evidence-format norm** (top of this handbook) and **(b).4** —
   every citation states the date the source was read, not only the
   URL.
3. **SimilarWeb** (traffic/market-share estimation; an
   industry-standard competitive-benchmarking input per its own and
   third-party competitor-analysis guides). Problem: a Porter's-forces
   verdict of "high"/"low" can rest on impression alone, with no way
   to check it later. How: a quantified proxy metric (traffic share,
   market-share estimate) behind every competitive-strength claim.
   Upgrades **(b).1** — competitive-rivalry and
   threat-of-new-entrants verdicts must cite a quantified proxy metric
   (traffic, revenue estimate, funding count), not only a qualitative
   source.
4. **G2** (Score = (Market Satisfaction + Market Presence) / 2, gated
   on a minimum review count and a shared category before a product
   appears in a comparison grid). Problem: a JTBD differentiation
   verdict can rest on a single favorable data point, and conflates
   "customers prefer it" with "customers can find/reach it." How: a
   dual-axis score plus a minimum-evidence-volume floor before a
   verdict is allowed to stand. Upgrades **(b).3** — the
   `jtbd-landscape-verdict` must cite at least two independent
   evidence points, and separately address preference (why chosen)
   and reach (how discovered/accessed).
5. **AlphaSense** (enterprise market-intelligence search, primary +
   secondary sourcing; 4,000+ enterprise clients including 88% of the
   S&P 100, per the vendor's own published adoption figures). Problem:
   an "evidence plan" that just says "we'll gather sources" doesn't
   tell a reviewer whether a claim rests on a primary interview/filing
   or a secondary aggregator repeating someone else's number. How: an
   explicit primary-vs-secondary source split, with primary sourcing
   tracked as its own evidence class. Upgrades **(a).3** — the
   phase-1 "Evidence plan" element names, per claim category, whether
   primary or secondary sourcing is expected, and the minimum
   independent-source count for each.

Skipped: Owler (community-verified company graph) — surveyed, but its
0.20% Market Research segment share (vs. Crunchbase's 7.42%, same
source) signals materially weaker adoption, and its core
direct-vs-indirect idea is already covered by Klue's structured-field
pattern above.

## Source

`docs/issue-1/proposals/methodology-and-deliverable-norms.md`,
`docs/issue-1/reports/market-analysis/scout-brief.md`,
`docs/issue-1199/reports/market-analysis/scout-brief.md` (in
`on-the-record`, tool-learnings section above).
