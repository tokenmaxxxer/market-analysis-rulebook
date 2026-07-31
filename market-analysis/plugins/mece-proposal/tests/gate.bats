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
