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

@test "(f) 'Resources: none listed' does NOT satisfy the sources check" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/proposals/plan.md","content":"# Proposal\n\nResources: none listed.\n\nSome claim with no real sources block."}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(g) Edit with replace_all:true against a multiply-occurring old_string judges the fully-replaced text" {
  printf '# Proposal\n\nfoo\n\nfoo\n\n## Sources\n\n- x\n' > "$TMP_REPO/docs/issue-7/proposals/plan.md"
  payload=$(python3 -c '
import json
print(json.dumps({
    "tool_name": "Edit",
    "tool_input": {
        "file_path": "docs/issue-7/proposals/plan.md",
        "old_string": "## Sources",
        "new_string": "## Resources",
        "replace_all": True,
    },
}))
')
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(h) MultiEdit with mixed replace_all true/false edits judges the fully-applied text" {
  printf '# Proposal\n\nfoo\n\n## Sources\n\n- x\n' > "$TMP_REPO/docs/issue-7/proposals/plan.md"
  payload=$(python3 -c '
import json
print(json.dumps({
    "tool_name": "MultiEdit",
    "tool_input": {
        "file_path": "docs/issue-7/proposals/plan.md",
        "edits": [
            {"old_string": "foo", "new_string": "bar", "replace_all": False},
            {"old_string": "## Sources", "new_string": "## Resources", "replace_all": True},
        ],
    },
}))
')
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(i1) malformed JSON: truncated payload is denied" {
  run bash -c "printf '%s' '{\"tool_name\":\"Write\"' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(i2) malformed JSON: non-object top level is denied" {
  run bash -c "printf '%s' '\"just a string\"' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(i3) malformed JSON: empty payload is denied" {
  run bash -c "printf '' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(j) kill switch set to an unrecognized value stays ACTIVE (still denies)" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/proposals/plan.md","content":"# Proposal\n\nno sources here"}}'
  EVIDENCE_RIGOR_GATE_OFF=maybe run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(k1) absolute file_path reaching the same target as the relative fixture is judged the same" {
  payload=$(python3 -c '
import json, sys
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": sys.argv[1] + "/docs/issue-7/proposals/plan.md", "content": "# Proposal\n\nno sources"},
}))
' "$TMP_REPO")
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(k2) ./-prefixed relative file_path reaching the same target is judged the same" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"./docs/issue-7/proposals/plan.md","content":"# Proposal\n\nno sources"}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

# (l) Bash-tool write case: deferred per
# docs/issue-10/proposals/gate-a-plus-remediation.md §5 item 6 — no
# gate_bash_write_targets adoption call surfaced by this phase's
# compliance-check.sh pass, so this repo does not add a Bash-tool test yet.
