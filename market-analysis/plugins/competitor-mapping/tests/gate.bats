#!/usr/bin/env bats
# Tests for competitor-mapping/hooks/gate.sh.
# Covers the proposal's three test cases (docs/issue-7/proposals/plugin-decomposition.md
# §2.1 competitor-mapping row) plus the direct/indirect and non-matching-path checks.

setup() {
  TMP_REPO="$(mktemp -d)"
  git -C "$TMP_REPO" init -q
  mkdir -p "$TMP_REPO/docs/issue-7/reports" "$TMP_REPO/docs/issue-7/proposals"
  export CLAUDE_PROJECT_DIR="$TMP_REPO"
}

teardown() {
  rm -rf "$TMP_REPO"
}

@test "(a) competitor-list with cited direct+indirect entries is allowed" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/reports/market-analysis.md","content":"## competitor-list\n### Direct\n- **Acme Corp** — pricing at https://acme.example/pricing\n### Indirect\n- **Widget Inc** — Source: 10-K filing 2025"}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 0 ]
}

@test "(b) missing competitor-list section entirely is denied" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/reports/market-analysis.md","content":"## five-forces-summary\nSome content."}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
  [[ "$output" == *"missing-section"* ]]
}

@test "(c) section present but no direct marker is denied" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/reports/market-analysis.md","content":"## competitor-list\n### Indirect\n- **Widget Inc** — Source: 10-K filing 2025"}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
  [[ "$output" == *"missing-direct"* ]]
}

@test "(d) section present but no indirect marker is denied" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/reports/market-analysis.md","content":"## competitor-list\n### Direct\n- **Acme Corp** — pricing at https://acme.example/pricing"}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
  [[ "$output" == *"missing-indirect"* ]]
}

@test "(e) entry without a citation marker is denied" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/reports/market-analysis.md","content":"## competitor-list\n### Direct\n- **Acme Corp** — leading competitor, no source given\n### Indirect\n- **Widget Inc** — Source: 10-K filing 2025"}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
  [[ "$output" == *"entry-without-citation"* ]]
}

@test "(f) non-matching path (proposal file) is always allowed regardless of content" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/proposals/plugin-decomposition.md","content":"no competitor-list section at all"}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 0 ]
}
