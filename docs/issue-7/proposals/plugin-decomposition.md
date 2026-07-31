# Proposal: plugin decomposition for market-analysis (issue #7, phase 1)

Status: PHASE-1 PROPOSAL ONLY. No plugin code, gate scripts, or `marketplace.json` changes are included in this PR. This document, if approved, becomes the design basis for a phase-2 implementation PR.

## 1. Decision framed

Issue #7 asks that the adopted market-analysis methodologies (from issue-1) be turned from review-time-only norms into machine-enforced gates, and — per the issue's mandatory corrective comment — that this be organized as a **set of independent plugins**, one per methodology, following the precedent set by core's `freelunch`/`scout`/`warrant` family (one rulebook registering multiple freelunch-level-complete plugins) rather than as a single deepened gate/directive.

This document decides: **which independent plugins should exist, what each owns, and how they combine to reconstitute the phase-1 and phase-2 norms already adopted in issue-1.** It does not implement any of them. The output that phase 2 (a follow-up implementation PR, gated by the standard Approve mechanism) will build against is the plugin list and composition below.

## 2. Design

### 2.1 Plugin list

| name | owning methodology | components | composition |
|---|---|---|---|
| `mece-proposal` | MECE, recommendation-first phase-1 structuring (issue-1 §a) | directive: N/A (folds into gate); gate script: PreToolUse on `docs/issue-<n>/proposals/*.md` checking presence of the 5 required section headers; tests: pass case (all 5 present), reject cases (each section individually missing); agent/checklist: N/A (structural check only, no procedure) | Phase-1 norm only. Combines with `evidence-rigor` on the same write surface. |
| `evidence-rigor` | Evidence-traceability discipline (issue-1's highest-leverage cross-cutting finding: every methodological/factual claim sourced or labeled assumption) | directive: N/A; gate script: PreToolUse on both `docs/issue-<n>/proposals/*.md` and `docs/issue-<n>/reports/market-analysis.md` checking presence of a `Sources:`/evidence-appendix block (structural presence check only — see §4 on limits); tests: pass (sources block present), reject (absent) for each write surface; agent/checklist: N/A | Shared/cross-cutting — participates in BOTH phase-1 and phase-2 norms. The only plugin appearing in both compositions. |
| `five-forces` | Porter's Five Forces industry-attractiveness framework (issue-1 §b, adopted framework 1 of 3) | directive: N/A; gate script: PreToolUse on `docs/issue-<n>/reports/market-analysis.md` requiring a `five-forces-summary` section with 4 named sub-verdicts (rivalry, new-entrant threat, supplier/buyer power, substitute threat), each carrying an evidence citation; tests: pass, reject-missing-section, reject-missing-one-force, reject-force-without-citation; agent/checklist: lightweight checklist embedded in plugin docs (see §5), not an agent | Phase-2 norm only. Combines with `competitor-mapping`, `jtbd-fit`, `evidence-rigor` on the same write surface, independently (no ordering constraint — see §3). |
| `competitor-mapping` | Direct+indirect competitor evidence-linked inventory (competitive-positioning framework, issue-1 §b, adopted framework 2 of 3) | directive: N/A; gate script: PreToolUse on the same record file requiring a `competitor-list` section with at least one direct and the presence of an indirect-competitor subsection, each entry evidence-linked; tests: pass, reject-missing-section, reject-entry-without-citation; agent/checklist: lightweight checklist | Phase-2 norm only. Combines with `five-forces`, `jtbd-fit`, `evidence-rigor`, independently. |
| `jtbd-fit` | Jobs-to-be-done customer-need-fit verdict (issue-1 §b, adopted framework 3 of 3) | directive: N/A; gate script: PreToolUse on the same record file requiring a `jtbd-landscape-verdict` section stating the customer job and a differentiation verdict vs. the strongest competing alternative; tests: pass, reject-missing-section, reject-missing-verdict-clause; agent/checklist: lightweight checklist | Phase-2 norm only. Combines with `five-forces`, `competitor-mapping`, `evidence-rigor`, independently. |

### 2.2 Compositions (the actual design content)

- **Phase-1 (기획서) norm = `mece-proposal` ⊕ `evidence-rigor`.** Both gate the same write surface, `docs/issue-<n>/proposals/*.md`. Each is independently sufficient to check its own concern; a proposal write must pass both to satisfy the phase-1 norm as adopted in issue-1.
- **Phase-2 (산출물) norm = `five-forces` ⊕ `competitor-mapping` ⊕ `jtbd-fit` ⊕ `evidence-rigor`.** All four gate the same write surface, `docs/issue-<n>/reports/market-analysis.md`. Together they reconstitute exactly the four required record sections from `docs/handbooks/market-analysis-norms.md` item (phase-2): five-forces-summary, competitor-list, jtbd-landscape-verdict, evidence appendix.
- `evidence-rigor` is deliberately the single plugin shared across both compositions, reflecting issue-1's finding that evidence traceability was the single highest-leverage norm across both phases — it is implemented once and reused, not duplicated per-framework.

### 2.3 Ordering / state-tracking

Issue #7 asks that, "if 순서 제약이 있으면", ordering be enforced via state tracking. Checked against the adopted methodology (`docs/handbooks/market-analysis-norms.md`): none of `five-forces`, `competitor-mapping`, `jtbd-fit`, `evidence-rigor` has a required analysis order relative to the others — the norm requires all four sections present in the final record write, not that forces be analyzed before competitors, etc. **This component of the issue's ask does not apply** to the currently adopted methodology; no cross-plugin state-tracking gate is proposed. Each gate independently inspects its own section on the same record-write PreToolUse event. This is stated here as a considered-and-rejected option rather than left silent, so the approver can see it was evaluated, not skipped.

### 2.4 Target `marketplace.json` shape (informational only, not changed by this PR)

Phase 2 would register 5 entries where today there is 1:

```
"plugins": [
  { "name": "mece-proposal", ... },
  { "name": "evidence-rigor", ... },
  { "name": "five-forces", ... },
  { "name": "competitor-mapping", ... },
  { "name": "jtbd-fit", ... }
]
```

replacing the current single `market-analysis` entry. Exact schema fields (source, strict, etc.) are unconfirmed from this workspace and would need to be set to match the core/pricing conventions in phase 2.

### 2.5 Canon-reference constraint

Each plugin's gate script must be a thin role-plugin script that calls a shared core canon library function for the mechanical PreToolUse hook wiring — following the same stub pattern `market-analysis/hooks/directive.sh` already uses to call a `core_role_directive`-style function — not a raw copy of core's hook-dispatch code, per canon-scripts.md's reference-only constraint. **Open risk:** the exact core interface for a generic "section-presence gate helper" is unconfirmed from this workspace; no such helper was found during the survey (see current-state-survey.md — pricing-rulebook has no equivalent gate to reference either). This is the same category of gap issue-2 already flagged for `record-fields-gate.sh`. Flagged here as an open question for the approver, not claimed as resolved.

### 2.6 Agents/checklist justification

`five-forces`, `competitor-mapping`, `jtbd-fit` are single-pass analytical frameworks: "gather evidence per force/competitor/job, write a verdict." None of the adopted methodology descriptions in issue-1 specify an iterative, multi-turn, or stateful procedure that would justify a full agent (the pattern `freelunch`/`warrant` use agents for). Proposing instead: a lightweight checklist embedded in each plugin's own docs (e.g. a `CHECKLIST.md` inside the plugin directory), not a new `agents/` directory. This satisfies issue #7 item 4 ("반복 절차 있으면 agents/ 또는 체크리스트") on the "체크리스트" branch, since no repeatable multi-step procedure exists to warrant the "agents/" branch.

## 3. Adoption rationale

This decomposition is not new methodology — it is a mechanical-enforcement mapping of methodology already adopted and approved in issue-1. The plugin boundaries were chosen to align 1:1 with the units issue-1 already established as independently adopted (three frameworks + the proposal-structuring norm + the evidence-rigor norm), so that approving this proposal does not reopen any methodology question, only the enforcement-architecture question. The cross-cutting placement of `evidence-rigor` directly operationalizes issue-1's own conclusion that evidence traceability was the highest-leverage single norm — reusing one plugin across both phases rather than re-deriving evidence-checking per framework.

## 4. Open questions / risks (for the approver)

1. **Core interface gap:** no confirmed core canon helper exists for section-presence PreToolUse gates (§2.5). Phase-2 implementation may need to either propose a new core canon helper (separate core-side approval) or implement the check locally per plugin without a shared helper, at some duplication cost. This proposal does not resolve which; it flags the choice for phase 2.
2. **Mechanical limits of `evidence-rigor`:** the gate can only check for the *presence* of a sources/evidence-appendix block, not the correctness or sufficiency of any individual citation — matching the same limitation issue-1 already flagged for this norm. Approving this proposal accepts that gap as inherent to mechanical enforcement, not a defect of this design.
3. **Single-account approval mode applies** (`docs/specs/approvers.md` lists one approver, JiwonJung94): phase 2 opens via that account posting the exact approval comment on this issue, per the repo's standard gate convention — no cross-account review path exists here.

## 5. Not proposing in this PR

- No plugin directories, `plugin.json`, `hooks/`, gate scripts, checklists, or `agents/` are created.
- No changes to `.claude-plugin/marketplace.json`.
- No changes to `market-analysis/hooks/directive.sh` or any existing hook.
- No approval of anything — this document is the proposal artifact awaiting the approver's Approve action.

## Sources

- `docs/handbooks/market-analysis-norms.md` (this repo) — phase-1 and phase-2 adopted norm content
- `docs/issue-1/proposals/methodology-and-deliverable-norms.md` (this repo) — original adoption rationale, evidence-rigor finding
- `docs/issue-7/reports/market-analysis/current-state-survey.md`, `docs/issue-7/reports/market-analysis/scout-brief.md` (this PR) — current-state and exemplar findings this design is built on
- `tokenmaxxxer-core-issue-69-implementation/{core,terse,freelunch,warrant,scout}/.claude-plugin/plugin.json` — multi-plugin-per-rulebook precedent
- `pricing-rulebook-issue-5-implementation/pricing/hooks/`, `pricing-rulebook-issue-5-implementation/hooks/tests/stub-check.sh` — verified absence of an existing section-gate script to copy
- `docs/specs/approvers.md` (this repo) — single-account approval mode
