#!/usr/bin/env bash
# SessionStart: jtbd-fit plugin's role directive — stub over core canon's
# shared function (core issue #66). Kill-switch and CLAUDE_ROLE guard live
# in core_role_directive now; this file supplies only the four
# plugin-unique values. Structural form enforced by
# core/hooks/tests/stub-check.sh — do not add logic here; put it in
# core/hooks/lib/role-directive.sh instead.
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive \
  "YOU DECIDE: the customer job the spec competes to satisfy, and whether its differentiation holds against the strongest competing alternative for that job" \
  "USE_WHEN: assembling the market-analysis phase-2 record's jtbd-landscape-verdict section" \
  "PRODUCES: the named customer job + a differentiation verdict vs. the strongest competing alternative" \
  "HAND-OFF: n/a, structural gate only."
