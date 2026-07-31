#!/usr/bin/env bash
# SessionStart: market-analysis's role directive — stub over core canon's
# shared function (core issue #66). Kill-switch and CLAUDE_ROLE guard live
# in core_role_directive now; this file supplies only the four role-unique
# values. Structural form enforced by core/hooks/tests/stub-check.sh — do
# not add logic here; put it in core/hooks/lib/role-directive.sh instead.
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive "YOU DECIDE: 경쟁 구도에서 이 스펙이 서는가" "USE WHEN: product 스펙 확정 후, 경쟁 구도가 걸린 결정일 때" "PRODUCES: five-forces summary (each force evidence-cited), competitor list (each item evidence-cited), JTBD-landscape verdict, evidence appendix" "HAND-OFF: 가격 정책이 걸리면 → pricing; 포지셔닝 메시지가 걸리면 → marketing"
