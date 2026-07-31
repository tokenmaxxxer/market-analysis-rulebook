# Scout brief — issue #7 (plugin decomposition)

## Why no web sweep

This is an internal-convention design question ("how does this codebase's own plugin registration and gating convention work"), not a market/product-category comparison question. There is no external market to scout — the design must match this ecosystem's own precedent for how a rulebook decomposes into multiple independently-registered plugins. Web search is therefore skipped as out-of-scope for this sub-step, not as a shortcut; the exemplars scouted below are internal filesystem precedents, inspected directly, with must-bes extracted the same way an external scout pass would extract them from products.

## Exemplars inspected

1. **Core canon plugin family** (`tokenmaxxxer-core-issue-69-implementation/{core,terse,freelunch,warrant,scout}/`) — five independently top-level plugins under one repo. Each has its own `.claude-plugin/plugin.json` (name/description/author), its own `hooks/`. `freelunch` and `warrant` additionally carry `agents/`. Must-be: one plugin = one self-contained methodology; a rulebook is free to register N plugins, not just one.
2. **pricing-rulebook plugin layout** (`pricing-rulebook-issue-5-implementation/pricing/{.claude-plugin,hooks}`) — single-plugin rulebook today, same directive-stub pattern as this repo's `market-analysis`. Verified directly (see current-state-survey.md) that no `methodology-gate.sh` exists there; only a directive stub + a stub-presence test exist. Must-be: this repo cannot copy an existing section-gate script — none exists yet in this family; the gate design here is new, not ported.
3. **This repo's issue-1 norms doc** (`docs/handbooks/market-analysis-norms.md`) — supplies the actual methodology content (which sections, which frameworks) that each plugin must gate. Must-be: plugin boundaries should map 1:1 onto the frameworks/disciplines already adopted there (MECE-proposal, evidence-rigor, five-forces, competitor-mapping, JTBD-fit), not invent new methodology.
4. **docs/issue-1/proposals/methodology-and-deliverable-norms.md** — carries the original adoption rationale, including the finding that evidence-traceability is the single highest-leverage cross-cutting norm. Must-be: the plugin decomposition should preserve that cross-cutting status (one shared plugin used by both phase norms) rather than duplicating evidence-checking logic once per framework plugin.

## Sources

- `tokenmaxxxer-core-issue-69-implementation/{freelunch,scout,warrant,core,terse}/.claude-plugin/plugin.json`
- `pricing-rulebook-issue-5-implementation/pricing/.claude-plugin/plugin.json`, `pricing-rulebook-issue-5-implementation/pricing/hooks/`, `pricing-rulebook-issue-5-implementation/hooks/tests/stub-check.sh`
- `docs/handbooks/market-analysis-norms.md`
- `docs/issue-1/proposals/methodology-and-deliverable-norms.md`
