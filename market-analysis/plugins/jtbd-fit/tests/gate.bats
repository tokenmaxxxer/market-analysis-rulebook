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

@test "(f) Edit with replace_all:true against a multiply-occurring old_string judges the fully-replaced text" {
  printf '## jtbd-landscape-verdict\nPLACEHOLDER Customer job: JTBD: schedule fast. PLACEHOLDER\n' > "$TMP_REPO/docs/issue-7/reports/market-analysis.md"
  payload='{"tool_name":"Edit","tool_input":{"file_path":"docs/issue-7/reports/market-analysis.md","old_string":"PLACEHOLDER","new_string":"Verdict: differentiation holds vs. the strongest competing alternative.","replace_all":true}}'
  run bash -c "cd \"$TMP_REPO\" && printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 0 ]
}

@test "(g) MultiEdit with mixed replace_all true/false edits in one call is judged on the fully-applied text" {
  printf '## jtbd-landscape-verdict\nOLD1 OLD2\n' > "$TMP_REPO/docs/issue-7/reports/market-analysis.md"
  payload=$(python3 -c '
import json
print(json.dumps({
    "tool_name": "MultiEdit",
    "tool_input": {
        "file_path": "docs/issue-7/reports/market-analysis.md",
        "edits": [
            {"old_string": "OLD1", "new_string": "Customer job: JTBD: schedule fast.", "replace_all": False},
            {"old_string": "OLD2", "new_string": "Verdict: differentiation holds vs. the strongest competing alternative.", "replace_all": True},
        ],
    },
}))
')
  run bash -c "cd \"$TMP_REPO\" && printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 0 ]
}

@test "(h1) malformed JSON: truncated payload is denied" {
  run bash -c "printf '%s' '{\"tool_name\":\"Write\",\"tool_in' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(h2) malformed JSON: non-object top level is denied" {
  run bash -c "printf '%s' '42' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(h3) malformed JSON: empty payload is denied" {
  run bash -c "printf '' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(i) kill switch set to an unrecognized value stays ACTIVE (still denies)" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/reports/market-analysis.md","content":"no jtbd content at all"}}'
  JTBD_FIT_GATE_OFF=maybe run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(j1) absolute file_path reaching the same target as the relative fixture is judged the same" {
  payload=$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": sys.argv[1], "content": "no jtbd content at all"}}))
' "$TMP_REPO/docs/issue-7/reports/market-analysis.md")
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(j2) ./-prefixed relative file_path is judged the same as the plain relative fixture" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"./docs/issue-7/reports/market-analysis.md","content":"no jtbd content at all"}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

# (k) Bash-tool write case: deferred per
# docs/issue-10/proposals/gate-a-plus-remediation.md §5 item 6 — no
# gate_bash_write_targets adoption call surfaced by this phase's
# compliance-check.sh pass, so this repo does not add a Bash-tool test yet.
