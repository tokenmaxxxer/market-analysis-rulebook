#!/usr/bin/env bats
# Tests for jtbd-fit/hooks/gate.sh.
# Covers: (a) pass, (b) reject-missing-section, (c) reject-missing-job-statement,
# (d) reject-missing-verdict-clause, (e) non-matching path always allowed.

setup() {
  TMP_REPO="$(mktemp -d)"
  git -C "$TMP_REPO" init -q
  mkdir -p "$TMP_REPO/docs/issue-7/reports"
  mkdir -p "$TMP_REPO/docs/issue-7/proposals"
  export CLAUDE_PROJECT_DIR="$TMP_REPO"
}

teardown() {
  rm -rf "$TMP_REPO"
}

@test "(a) jtbd-landscape-verdict with job statement and verdict clause is allowed" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/reports/market-analysis.md","content":"## jtbd-landscape-verdict\nCustomer job: JTBD: schedule a meeting fast. Verdict: differentiation holds vs. the strongest competing alternative."}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 0 ]
}

@test "(b) missing the jtbd-landscape-verdict section entirely is denied" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/reports/market-analysis.md","content":"## five-forces-summary\nsome content"}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
  [[ "$output" == *"missing-section"* ]]
}

@test "(c) section present but no job-statement marker is denied" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/reports/market-analysis.md","content":"## jtbd-landscape-verdict\nVerdict: differentiation holds vs. the strongest competing alternative."}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
  [[ "$output" == *"missing-job-statement"* ]]
}

@test "(d) section with job statement but no verdict-clause marker is denied" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/reports/market-analysis.md","content":"## jtbd-landscape-verdict\nCustomer job: JTBD: schedule a meeting fast. No clause here."}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
  [[ "$output" == *"missing-verdict-clause"* ]]
}

@test "(e) non-matching path (proposal) is always allowed regardless of content" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/proposals/plugin-decomposition.md","content":"no jtbd content at all"}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 0 ]
}
