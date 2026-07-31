#!/usr/bin/env bash
# SessionStart: five-forces's role directive — stub over core canon's
# shared function (core issue #66). Kill-switch and CLAUDE_ROLE guard live
# in core_role_directive now; this file supplies only the four role-unique
# values. Structural form enforced by core/hooks/tests/stub-check.sh — do
# not add logic here; put it in core/hooks/lib/role-directive.sh instead.
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive \
  "YOU DECIDE: industry attractiveness across all 5 distinct Porter forces, each evidence-backed" \
  "USE_WHEN: assembling the market-analysis phase-2 record's five-forces-summary section" \
  "PRODUCES: per-force verdict for all 5 forces — competitive rivalry, threat of new entrants, supplier bargaining power, buyer bargaining power kept distinct, threat of substitutes — each with an evidence citation" \
  "HAND-OFF: n/a, structural gate only"
