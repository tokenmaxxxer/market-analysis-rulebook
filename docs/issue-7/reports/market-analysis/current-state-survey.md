# Current-state survey — issue #7 (plugin decomposition)

## What exists today in this repo

- `market-analysis/.claude-plugin/plugin.json` registers a single plugin, `market-analysis`, in `.claude-plugin/marketplace.json`.
- `market-analysis/hooks/directive.sh` + `hooks.json` implement one role-wide PreToolUse directive stub (a thin wrapper calling a shared core canon function, same pattern as other rulebooks in this ecosystem).
- `docs/handbooks/market-analysis-norms.md` (adopted in issue-1) states the phase-1 proposal norm (5 required sections, MECE/recommendation-first) and the phase-2 record norm (five-forces-summary, competitor-list, jtbd-landscape-verdict, evidence appendix) as **review-time** norms only.
- Core's `record-fields-gate.sh` (referenced, not vendored, per canon-scripts.md) mechanically checks only role-agnostic §20 record structure (what/why/upstream-basis/loop_state/open-findings). It does not know about market-analysis's role-specific required sections or about evidence-citation presence.

## What is missing relative to issue #7's ask

1. No mechanical enforcement of the phase-1 proposal's 5-section structure, nor of the phase-2 record's 4 required sections — both currently rely on human review only.
2. No enforcement of the evidence-traceability discipline (issue-1's highest-leverage finding) at write time.
3. No plugin-per-methodology decomposition — today's single `market-analysis` plugin is monolithic, unlike core's `freelunch`/`scout`/`warrant` pattern where each adopted methodology is its own independently registered plugin.
4. No gate test suite (pass/reject cases) for any of the above, since no such gates exist yet.
5. No agents/checklists for the adopted frameworks.

## Correction: the issue's "methodology-gate.sh" reference

Issue #7 cites `pricing-rulebook`'s `methodology-gate.sh` as the reference pattern for a section-presence PreToolUse gate. Inspecting `pricing-rulebook-issue-5-implementation` directly:

```
find <pricing-rulebook-issue-5-implementation> -path '*/hooks/*' -type f
  hooks/tests/stub-check.sh
  pricing/hooks/directive.sh
  pricing/hooks/hooks.json
```

No file named `methodology-gate.sh` exists anywhere in that worktree. `pricing/hooks/directive.sh` is the same thin canon-calling directive stub pattern used by this repo's `market-analysis/hooks/directive.sh`; `hooks/tests/stub-check.sh` is a stub-presence test, not a methodology-section gate. **The issue's naming appears imprecise** — there is currently no working example anywhere in this ecosystem of a PreToolUse gate that mechanically checks required-section presence in a proposal/record document. This proposal's plugin gates (see `docs/issue-7/proposals/plugin-decomposition.md`) would be the first such gate in this family of rulebooks, not a copy of an existing one.

## Ecosystem precedent for plugin decomposition

`tokenmaxxxer-core-issue-69-implementation/{core,terse,freelunch,warrant,scout}/` each stand as independent top-level plugins, each with its own `.claude-plugin/plugin.json`, `hooks/`, and (for `freelunch`, `warrant`) `agents/`. This is the "one rulebook, multiple plugins, each freelunch-level complete" precedent issue #7's mandatory comment names explicitly.

## Sources

- `market-analysis/.claude-plugin/plugin.json`, `market-analysis/hooks/directive.sh`, `market-analysis/hooks/hooks.json`, `.claude-plugin/marketplace.json` (this repo)
- `docs/handbooks/market-analysis-norms.md` (this repo)
- `/home/jwjung/.tokenmaxxxer/work/pricing-rulebook-issue-5-implementation/pricing/hooks/{directive.sh,hooks.json}`, `/home/jwjung/.tokenmaxxxer/work/pricing-rulebook-issue-5-implementation/hooks/tests/stub-check.sh` (verified via `find`, 2026-07-31)
- `/home/jwjung/.tokenmaxxxer/work/tokenmaxxxer-core-issue-69-implementation/{core,terse,freelunch,warrant,scout}/.claude-plugin/plugin.json`
- `docs/specs/approvers.md` (single approver, single-account mode)
