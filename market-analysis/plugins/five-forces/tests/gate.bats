#!/usr/bin/env bats
# Tests for five-forces/hooks/gate.sh.
# Covers docs/issue-7/proposals/plugin-decomposition.md §2.1's five-forces
# test-case list: pass, reject-missing-section, reject-missing-one-force
# (run once per force, including separately for supplier power and buyer
# power), reject-force-without-citation, and non-matching-path passthrough.

setup() {
  TMP_REPO="$(mktemp -d)"
  git -C "$TMP_REPO" init -q
  mkdir -p "$TMP_REPO/docs/issue-7/reports" "$TMP_REPO/docs/issue-7/proposals"
  export CLAUDE_PROJECT_DIR="$TMP_REPO"
}

teardown() {
  rm -rf "$TMP_REPO"
}

complete_content='## five-forces-summary

- Competitive rivalry: high. Source: https://example.com/rivalry
- Threat of new entrants: low. Source: https://example.com/entrants
- Supplier bargaining power: moderate. Source: https://example.com/supplier
- Buyer bargaining power: high. Source: https://example.com/buyer
- Threat of substitutes: low. Source: https://example.com/substitutes
'

run_gate() {
  local content="$1"
  payload=$(python3 -c '
import json, sys
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": "docs/issue-7/reports/market-analysis.md", "content": sys.argv[1]},
}))
' "$content")
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
}

@test "(a) all 5 forces present with citations is allowed" {
  run_gate "$complete_content"
  [ "$status" -eq 0 ]
}

@test "(b) missing the five-forces-summary section entirely is denied" {
  content='Competitive rivalry: high. Source: https://example.com/rivalry
Threat of new entrants: low. Source: https://example.com/entrants
Supplier bargaining power: moderate. Source: https://example.com/supplier
Buyer bargaining power: high. Source: https://example.com/buyer
Threat of substitutes: low. Source: https://example.com/substitutes'
  run_gate "$content"
  [ "$status" -eq 2 ]
  [[ "$output" == *"missing-section"* || "$output" == *"missing a five-forces-summary section"* ]]
}

@test "(c) missing competitive rivalry is denied naming that force" {
  content='## five-forces-summary

- Threat of new entrants: low. Source: https://example.com/entrants
- Supplier bargaining power: moderate. Source: https://example.com/supplier
- Buyer bargaining power: high. Source: https://example.com/buyer
- Threat of substitutes: low. Source: https://example.com/substitutes'
  run_gate "$content"
  [ "$status" -eq 2 ]
  [[ "$output" == *"competitive rivalry"* ]]
}

@test "(d) missing threat of new entrants is denied naming that force" {
  content='## five-forces-summary

- Competitive rivalry: high. Source: https://example.com/rivalry
- Supplier bargaining power: moderate. Source: https://example.com/supplier
- Buyer bargaining power: high. Source: https://example.com/buyer
- Threat of substitutes: low. Source: https://example.com/substitutes'
  run_gate "$content"
  [ "$status" -eq 2 ]
  [[ "$output" == *"threat of new entrants"* ]]
}

@test "(e) missing supplier bargaining power is denied naming that force" {
  content='## five-forces-summary

- Competitive rivalry: high. Source: https://example.com/rivalry
- Threat of new entrants: low. Source: https://example.com/entrants
- Buyer bargaining power: high. Source: https://example.com/buyer
- Threat of substitutes: low. Source: https://example.com/substitutes'
  run_gate "$content"
  [ "$status" -eq 2 ]
  [[ "$output" == *"supplier bargaining power"* ]]
}

@test "(f) missing buyer bargaining power is denied naming that force" {
  content='## five-forces-summary

- Competitive rivalry: high. Source: https://example.com/rivalry
- Threat of new entrants: low. Source: https://example.com/entrants
- Supplier bargaining power: moderate. Source: https://example.com/supplier
- Threat of substitutes: low. Source: https://example.com/substitutes'
  run_gate "$content"
  [ "$status" -eq 2 ]
  [[ "$output" == *"buyer bargaining power"* ]]
}

@test "(g) missing threat of substitutes is denied naming that force" {
  content='## five-forces-summary

- Competitive rivalry: high. Source: https://example.com/rivalry
- Threat of new entrants: low. Source: https://example.com/entrants
- Supplier bargaining power: moderate. Source: https://example.com/supplier
- Buyer bargaining power: high. Source: https://example.com/buyer'
  run_gate "$content"
  [ "$status" -eq 2 ]
  [[ "$output" == *"threat of substitutes"* ]]
}

@test "(g2) merged supplier/buyer power line is treated as both forces missing" {
  content='## five-forces-summary

- Competitive rivalry: high. Source: https://example.com/rivalry
- Threat of new entrants: low. Source: https://example.com/entrants
- Supplier/buyer power: moderate. Source: https://example.com/supplier-buyer
- Threat of substitutes: low. Source: https://example.com/substitutes'
  run_gate "$content"
  [ "$status" -eq 2 ]
  [[ "$output" == *"supplier bargaining power"* ]]
  [[ "$output" == *"buyer bargaining power"* ]]
}

@test "(h) all 5 forces named but one has no nearby citation is denied naming citation" {
  content='## five-forces-summary

- Competitive rivalry: high. Source: https://example.com/rivalry
- Threat of new entrants: low, just a bare assertion with nothing backing it, no evidence given at all, plainly stated and left entirely unsupported by anything else in this bullet.
- Supplier bargaining power: moderate. Source: https://example.com/supplier
- Buyer bargaining power: high. Source: https://example.com/buyer
- Threat of substitutes: low. Source: https://example.com/substitutes'
  run_gate "$content"
  [ "$status" -eq 2 ]
  [[ "$output" == *"threat of new entrants"* ]]
  [[ "$output" == *"citation"* ]]
}

@test "(i) non-matching path is always allowed regardless of content" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/proposals/plugin-decomposition.md","content":"no five forces content here at all"}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 0 ]
}
