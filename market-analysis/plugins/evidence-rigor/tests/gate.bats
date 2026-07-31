#!/usr/bin/env bats
# Tests for evidence-rigor/hooks/gate.sh.
# Covers:
#   (a) proposal with "## Sources" present -> allow
#   (b) proposal missing sources block -> deny
#   (c) record file with "Evidence appendix" heading present -> allow
#   (d) record file missing it -> deny
#   (e) non-matching path (survey artifact, not the exact record filename) -> always allowed

setup() {
  TMP_REPO="$(mktemp -d)"
  git -C "$TMP_REPO" init -q
  mkdir -p "$TMP_REPO/docs/issue-7/proposals"
  mkdir -p "$TMP_REPO/docs/issue-7/reports/market-analysis"
  export CLAUDE_PROJECT_DIR="$TMP_REPO"
}

teardown() {
  rm -rf "$TMP_REPO"
}

@test "(a) proposal with Sources heading is allowed" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/proposals/plan.md","content":"# Proposal\n\nSome claim.\n\n## Sources\n\n- some source"}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 0 ]
}

@test "(b) proposal missing sources block is denied" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/proposals/plan.md","content":"# Proposal\n\nSome claim with no citation."}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
  [[ "$output" == *"sources"* || "$output" == *"evidence"* ]]
}

@test "(c) record file with Evidence appendix heading is allowed" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/reports/market-analysis.md","content":"# Record\n\nFive forces summary...\n\n## Evidence appendix\n\n- cited source"}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 0 ]
}

@test "(d) record file missing Evidence appendix is denied" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/reports/market-analysis.md","content":"# Record\n\nFive forces summary with no evidence block."}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
  [[ "$output" == *"sources"* || "$output" == *"evidence"* ]]
}

@test "(e) non-matching path is always allowed regardless of content" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/reports/market-analysis/current-state-survey.md","content":"No sources here at all."}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 0 ]
}
