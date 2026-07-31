#!/usr/bin/env bash
# SessionStart: mece-proposal's role directive — stub over core canon's
# shared function. Kill-switch and CLAUDE_ROLE guard live in
# core_role_directive; this file supplies only the four plugin-unique values.
# Do not add logic here; put it in core/hooks/lib/role-directive.sh instead.
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive \
  "YOU DECIDE: whether the phase-1 proposal is MECE-structured across the 5 required elements" \
  "USE_WHEN: writing or revising a market-analysis phase-1 proposal" \
  "PRODUCES: decision framed, frameworks selected + why (industry attractiveness / competitive positioning / customer-need fit), evidence plan, adoption rationale, plugin-reflection plan" \
  "HAND-OFF: n/a — gate is structural only, no phase hand-off"
