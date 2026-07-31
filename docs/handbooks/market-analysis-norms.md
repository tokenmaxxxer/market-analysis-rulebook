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

1. **`five-forces-summary`** — per-force verdict (competitive rivalry, new-entrant threat, supplier/buyer power, substitute threat), each with an evidence citation, not a bare rating.
2. **`competitor-list`** — direct + indirect competitors, each claimed fact backed by an evidence link (pricing page, filing, product doc).
3. **`jtbd-landscape-verdict`** — the customer job the spec competes to satisfy, and whether the spec's differentiation holds against the strongest competing alternative for that job.
4. **Evidence appendix** — flat list of every source used across 1–3.

No sizing (TAM/SAM/SOM) or full per-competitor SWOT is required — this role's
decision boundary ("경쟁 구도에서 이 스펙이 서는가") is a competitive gate, not
a market-sizing or product-discovery task; adding those would serve a
different role's decision, not this one's.

## Source

`docs/issue-1/proposals/methodology-and-deliverable-norms.md`,
`docs/issue-1/reports/market-analysis/scout-brief.md`.
