#!/usr/bin/env bats
# Tests for mece-proposal/hooks/gate.sh.
# Covers: (a) all 5 elements present -> allow; (b)-(f) one missing element
# each -> deny naming that element's slug; (g) non-matching path -> allow
# regardless of content.

setup() {
  TMP_REPO="$(mktemp -d)"
  git -C "$TMP_REPO" init -q
  mkdir -p "$TMP_REPO/docs/issue-7/proposals" "$TMP_REPO/docs/issue-7/reports"
  export CLAUDE_PROJECT_DIR="$TMP_REPO"
}

teardown() {
  rm -rf "$TMP_REPO"
}

complete_text='Decision framed: whether to enter market X.
Framework: Porter Five Forces maps to industry attractiveness; JTBD maps to customer-need fit; competitive positioning via feature matrix.
Evidence plan: primary interviews plus secondary filings, minimum two independent sources per claim.
Adoption rationale: this methodology directly answers the spec decision boundary.
Plugin-reflection plan: directive.sh unchanged; record field five-forces-summary added.'

@test "(a) all 5 elements present is allowed" {
  payload=$(python3 -c "import json,sys; print(json.dumps({'tool_name':'Write','tool_input':{'file_path':'docs/issue-7/proposals/plan.md','content':sys.argv[1]}}))" "$complete_text")
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 0 ]
}

@test "(b) missing decision framed is denied" {
  text=${complete_text/'Decision framed: whether to enter market X.'/'We looked at market X.'}
  payload=$(python3 -c "import json,sys; print(json.dumps({'tool_name':'Write','tool_input':{'file_path':'docs/issue-7/proposals/plan.md','content':sys.argv[1]}}))" "$text")
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
  [[ "$output" == *"decision-framed"* ]]
}

@test "(c) missing framework selection is denied" {
  text=${complete_text/'Framework: Porter Five Forces maps to industry attractiveness; JTBD maps to customer-need fit; competitive positioning via feature matrix.'/'We used some standard tools.'}
  payload=$(python3 -c "import json,sys; print(json.dumps({'tool_name':'Write','tool_input':{'file_path':'docs/issue-7/proposals/plan.md','content':sys.argv[1]}}))" "$text")
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
  [[ "$output" == *"framework-selection"* ]]
}

@test "(d) missing evidence plan is denied" {
  text=${complete_text/'Evidence plan: primary interviews plus secondary filings, minimum two independent sources per claim.'/'We will gather some sources.'}
  payload=$(python3 -c "import json,sys; print(json.dumps({'tool_name':'Write','tool_input':{'file_path':'docs/issue-7/proposals/plan.md','content':sys.argv[1]}}))" "$text")
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
  [[ "$output" == *"evidence-plan"* ]]
}

@test "(e) missing adoption rationale is denied" {
  text=${complete_text/'Adoption rationale: this methodology directly answers the spec decision boundary.'/'This is standard practice.'}
  payload=$(python3 -c "import json,sys; print(json.dumps({'tool_name':'Write','tool_input':{'file_path':'docs/issue-7/proposals/plan.md','content':sys.argv[1]}}))" "$text")
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
  [[ "$output" == *"adoption-rationale"* ]]
}

@test "(f) missing plugin-reflection plan is denied" {
  text=${complete_text/'Plugin-reflection plan: directive.sh unchanged; record field five-forces-summary added.'/'No changes noted.'}
  payload=$(python3 -c "import json,sys; print(json.dumps({'tool_name':'Write','tool_input':{'file_path':'docs/issue-7/proposals/plan.md','content':sys.argv[1]}}))" "$text")
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
  [[ "$output" == *"plugin-reflection-plan"* ]]
}

@test "(g) non-matching path is always allowed regardless of content" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/reports/market-analysis.md","content":"nothing relevant here at all"}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 0 ]
}

@test "(h) Edit with replace_all:true against a multiply-occurring old_string judges the fully-replaced text" {
  printf 'PLACEHOLDER PLACEHOLDER\n' > "$TMP_REPO/docs/issue-7/proposals/plan.md"
  payload='{"tool_name":"Edit","tool_input":{"file_path":"docs/issue-7/proposals/plan.md","old_string":"PLACEHOLDER","new_string":"filler","replace_all":true}}'
  run bash -c "cd \"$TMP_REPO\" && printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
  [[ "$output" == *"decision-framed"* ]]
}

@test "(i) MultiEdit with mixed replace_all true/false edits in one call is allowed when the result is compliant" {
  printf 'TOK_A TOK_B TOK_C TOK_D TOK_E\n' > "$TMP_REPO/docs/issue-7/proposals/plan.md"
  payload=$(python3 -c '
import json
print(json.dumps({
    "tool_name": "MultiEdit",
    "tool_input": {
        "file_path": "docs/issue-7/proposals/plan.md",
        "edits": [
            {"old_string": "TOK_A", "new_string": "Decision framed: whether to enter market X.", "replace_all": False},
            {"old_string": "TOK_B", "new_string": "Framework: Porter Five Forces maps to industry attractiveness.", "replace_all": True},
            {"old_string": "TOK_C", "new_string": "Evidence plan: two independent sources per claim.", "replace_all": False},
            {"old_string": "TOK_D", "new_string": "Adoption rationale: answers the decision boundary.", "replace_all": False},
            {"old_string": "TOK_E", "new_string": "Plugin-reflection plan: no plugin changes.", "replace_all": False},
        ],
    },
}))
')
  run bash -c "cd \"$TMP_REPO\" && printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 0 ]
}

@test "(j1) malformed JSON: truncated payload is denied" {
  run bash -c "printf '%s' '{\"tool_name\":\"Write\",\"tool_in' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(j2) malformed JSON: non-object top level is denied" {
  run bash -c "printf '%s' 'true' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(j3) malformed JSON: empty payload is denied" {
  run bash -c "printf '' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(k) kill switch set to an unrecognized value stays ACTIVE (still denies)" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-7/proposals/plan.md","content":"nothing relevant here"}}'
  MECE_PROPOSAL_GATE_OFF=maybe run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(l1) absolute file_path reaching the same target as the relative fixture is judged the same" {
  payload=$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": sys.argv[1], "content": "nothing relevant here"}}))
' "$TMP_REPO/docs/issue-7/proposals/plan.md")
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

@test "(l2) ./-prefixed relative file_path is judged the same as the plain relative fixture" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"./docs/issue-7/proposals/plan.md","content":"nothing relevant here"}}'
  run bash -c "printf '%s' '$payload' | \"$BATS_TEST_DIRNAME/../hooks/gate.sh\""
  [ "$status" -eq 2 ]
}

# (m) Bash-tool write case: deferred per
# docs/issue-10/proposals/gate-a-plus-remediation.md §5 item 6 — no
# gate_bash_write_targets adoption call surfaced by this phase's
# compliance-check.sh pass, so this repo does not add a Bash-tool test yet.
