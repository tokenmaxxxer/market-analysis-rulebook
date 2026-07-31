# Proposal — issue-1: market-analysis methodology & deliverable norms

Subject: issue-1. Phase 1 proposal only — no execution/plugin changes in this
PR. Based on `docs/issue-1/reports/market-analysis/current-state-survey.md`
and `docs/issue-1/reports/market-analysis/scout-brief.md`.

## (a) Phase-1 proposal norm — for future market-analysis proposals

**Methodology:** MECE, recommendation-first structure (per the consulting-firm
convention this scout confirmed: deliverables lead with the decision-relevant
finding, not a chronological narrative of the analysis process).

**Required sections for a market-analysis phase-1 proposal:**

1. **Decision framed** — what spec/positioning question this proposal informs, and who the hand-off (pricing/marketing/etc.) is for.
2. **Frameworks selected + why each answers a distinct question** — no framework may be included "because it's standard"; each must map to one of: industry attractiveness, competitive positioning, or customer-need fit. (Rationale: the scout's core finding is that no single framework is sufficient and every strong analysis states which question each framework is doing work for.)
3. **Evidence plan** — for each required output component, name the expected source types (primary/secondary) and the cross-referencing bar (minimum independent sources per non-trivial claim).
4. **Adoption rationale** — the logical argument tying the chosen methodology to this role's actual decision boundary (see (c) below), not a generic "best practice" citation.
5. **Plugin-reflection plan** — see (d).

**Evidence format:** every methodological claim in the proposal must carry a
source (URL or named standard); unsourced claims must be explicitly labeled
as assumptions. (Directly adopts the scout's evidence-traceability must-be —
this proposal itself follows that rule via its Sources list below.)

## (b) Phase-2 deliverable norm — for the market-analysis record

**Methodology:** bottom-up-first evidence gathering (source named + method
noted) with top-down used only for framing/context, per the market-sizing
scout finding generalized to all three output components — not just sizing.

**Required components of `docs/issue-<n>/reports/market-analysis.md`:**

1. **`five-forces-summary`** — per-force verdict (competitive rivalry, new-entrant threat, supplier/buyer power, substitute threat) with an evidence citation per force, not a bare rating.
2. **`competitor-list`** — direct + indirect competitors, each with an evidence link (pricing page, filing, product doc) per claimed fact about that competitor — no competitor entry may rest on unsourced assertion.
3. **`jtbd-landscape-verdict`** — the customer job this spec competes to satisfy, and whether the spec's differentiation holds against the strongest competing alternative for that job.
4. **Evidence appendix** — flat list of every source used across 1–3, so a reviewer can audit sourcing without re-deriving it from inline citations.

No new required component (e.g. TAM/SAM/SOM sizing, full per-competitor SWOT)
is being added — the scout brief's gap line found the current three
`PRODUCES` names already framework-appropriate for this role's actual
decision boundary ("경쟁 구도에서 이 스펙이 서는가"); the gap is evidence
rigor, not missing output categories. This keeps scope inside issue-1's
literal ask (regulate existing outputs) rather than silently expanding it.

## (c) Adoption rationale — why this fits the role's intended value

The role's decision boundary is "경쟁 구도에서 이 스펙이 서는가" (does this
spec stand up in the competitive landscape) — a yes/no gate a downstream
role (pricing/marketing) will act on. A gate output is only as trustworthy as
its weakest cited claim, so the single highest-leverage norm for *this specific
role* is evidence traceability, not framework breadth (the role already has
framework breadth — five forces for attractiveness, competitor list for direct
comparison, JTBD for need-fit — matching exactly the three questions the
scout found strong practice separates). Adding sizing or persona-research
requirements would serve a market-sizing or product-discovery role, not a
competitive-gate role; keeping scope narrow to evidence rigor is therefore the
logically-forced choice given this role's specific decision boundary, not an
arbitrary trim.

## (d) Plugin-reflection plan

Per issue-1's constraint and the precedent already merged (core-canon
migration, `3d1fe74`), all mechanics route through core canon — no role-local
copies.

- **`directive.sh` (`market-analysis/hooks/directive.sh`):** no structural
  change to the stub form. Update the `PRODUCES` string's wording to state
  the evidence requirement inline (e.g. append "(each item evidence-cited)")
  so the directive text itself reflects norm (a)/(b) without adding role-local
  logic — the stub stays a thin call into `core_role_directive` per issue-2's
  landed contract.
- **Record required fields:** per issue-2's current-state survey, required-field
  enforcement moved to core (`roles/market-analysis.json`'s `produces`, read by
  core's registration — exact mechanism still unconfirmed from this repo, same
  gap issue-2 flagged). Phase 2 of *this* issue must, once core's actual
  interface is readable: (i) confirm or create `roles/market-analysis.json`
  with the four required components from (b) as the `produces` field, (ii)
  confirm whether core's gate mechanism supports a per-component
  evidence-citation check or only a field-presence check — if only presence,
  the evidence-rigor requirement becomes a review-time norm documented in the
  handbook rather than a mechanically-gated one, and that limitation must be
  recorded plainly rather than claimed as enforced.
- **Gate:** no new role-local gate script (issue-2 already removed the three
  role-local gates in favor of core registration). This proposal adds no gate
  logic in this repo; it only supplies the field list and evidence-format
  requirement that core's gate (if any) should check.

## Risk / open questions for the approver

- Same core-interface uncertainty flagged by issue-2's survey applies here:
  whether core's per-role gate can check *evidence citation presence* (not
  just field presence) is unconfirmed from this workspace. If it cannot,
  item (d)'s enforcement claim for evidence rigor is a documentation norm, not
  a mechanical gate, until core adds that capability.
- Scope decision in (b) — not adding TAM/SAM/SOM or per-competitor SWOT as
  required components — is a deliberate narrowing based on this role's
  decision boundary, not an oversight; flagging for explicit approver sign-off
  since it declines part of what the broader field considers best practice.

## Not proposing in this PR

No code or `directive.sh` edits are made in this PR. Phase-1 output only, per
contract v3 s19. The `directive.sh` wording change in (d) is a phase-2 action
gated on Approve.

## Sources

See `docs/issue-1/reports/market-analysis/scout-brief.md` for the full source
list used to derive (a)–(d).
