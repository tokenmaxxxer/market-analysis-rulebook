#!/usr/bin/env bash
# SessionStart: evidence-rigor's role directive — stub over core canon's
# shared function (core issue #66). Kill-switch and CLAUDE_ROLE guard live
# in core_role_directive now; this file supplies only the four role-unique
# values. Structural form enforced by core/hooks/tests/stub-check.sh — do
# not add logic here; put it in core/hooks/lib/role-directive.sh instead.
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive \
  "YOU DECIDE: whether every methodological/factual claim in this proposal or record carries a source or is explicitly labeled an assumption" \
  "USE_WHEN: writing/revising either a market-analysis phase-1 proposal or the phase-2 record" \
  "PRODUCES: a Sources: list (phase-1) or Evidence appendix (phase-2) covering every claim used" \
  "HAND-OFF: gate is structural presence-only — it cannot verify citation correctness or sufficiency, only that the block exists"
