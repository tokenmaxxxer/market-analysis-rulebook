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

@test "(g) bare [TODO] with no following (url) does not count as a citation" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/reports/market-analysis.md","content":"## competitor-list\n### Direct\n- **Acme Corp** — [TODO]\n### Indirect\n- **Widget Inc** — Source: 10-K filing 2025"}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
  [[ "$output" == *"entry-without-citation"* ]]
}

@test "(h) Edit with replace_all:true against a multiply-occurring old_string judges the fully-replaced text" {
  printf '## competitor-list\n### Direct\n- **Acme Corp** — PLACEHOLDER\n### Indirect\n- **Widget Inc** — PLACEHOLDER\n' > "$TMP_REPO/docs/issue-7/reports/market-analysis.md"
  payload='{"tool_name":"Edit","tool_input":{"file_path":"docs/issue-7/reports/market-analysis.md","old_string":"PLACEHOLDER","new_string":"Source: https://example.com/x","replace_all":true}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 0 ]
}

@test "(h2) the same Edit without replace_all leaves the second entry uncited and is denied" {
  printf '## competitor-list\n### Direct\n- **Acme Corp** — PLACEHOLDER\n### Indirect\n- **Widget Inc** — PLACEHOLDER\n' > "$TMP_REPO/docs/issue-7/reports/market-analysis.md"
  payload='{"tool_name":"Edit","tool_input":{"file_path":"docs/issue-7/reports/market-analysis.md","old_string":"PLACEHOLDER","new_string":"Source: https://example.com/x"}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(i) MultiEdit with mixed replace_all true/false edits judges the fully-applied text" {
  printf '## competitor-list\n### Direct\n- **Acme Corp** — OLDHEADING\n### Indirect\n- **Widget Inc** — PLACEHOLDER\n' > "$TMP_REPO/docs/issue-7/reports/market-analysis.md"
  payload=$(python3 -c '
import json
print(json.dumps({
    "tool_name": "MultiEdit",
    "tool_input": {
        "file_path": "docs/issue-7/reports/market-analysis.md",
        "edits": [
            {"old_string": "OLDHEADING", "new_string": "Source: https://acme.example/pricing", "replace_all": False},
            {"old_string": "PLACEHOLDER", "new_string": "Source: https://example.com/x", "replace_all": True},
        ],
    },
}))
')
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 0 ]
}

@test "(j1) malformed JSON: truncated payload is denied" {
  run bash -c "printf '%s' '{\"tool_name\":\"Write\",\"tool_in' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(j2) malformed JSON: non-object top level is denied" {
  run bash -c "printf '%s' '[]' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(j3) malformed JSON: empty payload is denied" {
  run bash -c "printf '' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(k) kill switch set to an unrecognized value stays ACTIVE (still denies)" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/reports/market-analysis.md","content":"## five-forces-summary\nSome content."}}'
  COMPETITOR_MAPPING_GATE_OFF=maybe run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(l1) absolute file_path reaching the same target as the relative fixture is judged the same" {
  payload=$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": sys.argv[1], "content": "## five-forces-summary\nSome content."}}))
' "$TMP_REPO/docs/issue-7/reports/market-analysis.md")
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(l2) ./-prefixed relative file_path is judged the same as the plain relative fixture" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"./docs/issue-7/reports/market-analysis.md","content":"## five-forces-summary\nSome content."}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

# (m) Bash-tool write case: deferred per
# docs/issue-10/proposals/gate-a-plus-remediation.md §5 item 6 — no
# gate_bash_write_targets adoption call surfaced by this phase's
# compliance-check.sh pass, so this repo does not add a Bash-tool test yet.
