# Current-state survey — issue-13 재감사 잔여 결함

Scope: the 5 gates under `market-analysis/plugins/{five-forces,
evidence-rigor, competitor-mapping, jtbd-fit, mece-proposal}/hooks/`,
their `hooks.json`, and their `README.md`, as they stand after
`docs/issue-10`'s phase-2 landing (core issue-72 adoption). Read directly,
file:line-level, no inference.

## 1. Source line: wrong var name, no `||` guard (core issue-75 gap)

All 5 `gate.sh` files, identical shape (e.g.
`market-analysis/plugins/five-forces/hooks/gate.sh:29`):

```
. "${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/lib/gate-lib.sh"
```

Two defects confirmed against core's issue-75-landed canon
(`tokenmaxxxer-core` commit `52bdc15`, PR #77):

- **Wrong variable.** The canon's injected variable (on-the-record #182,
  landed) is `CLAUDE_PLUGIN_ROOT_CORE`; this repo's 5 gates read
  `CORE_PLUGIN_ROOT`, which #182 never sets. Every gate falls through to
  the `$CLAUDE_PLUGIN_ROOT/../core` relative fallback unconditionally —
  the injected override is silently dead in all 5 gates.
- **No `||` guard.** Core's confirmed issue-75 fix
  (`docs/handbooks/gate-house-standard.md` transition note, canon `.sh`
  comment) makes the source line's `||` fallback mandatory: an unguarded
  `. "$path"` that fails when core is unreachable defines no `gate_*`
  function, and the resulting "command not found" (127) reads as the kill
  switch being off at every `gate_kill_switch_active ... || { exit 0; }`
  call site — silently allowing everything. None of the 5 gates here
  carry the guard.

Same file (`five-forces/hooks/gate.sh:30-31` and identical lines in the
other 4) already runs `gate_trap_fail_closed` / `set -uo pipefail` right
after the unguarded source, so the fail-closed trap is itself only
installed if the source succeeded — the exact issue-75-confirmed gap.

## 2. `gate_bash_write_targets` py parity — not consumed

None of the 5 gates' Python payloads call `gate_lib.gate_bash_write_targets`
(grep across `market-analysis/plugins/*/hooks/gate.sh` for the symbol:
zero hits) and none of the 5 `hooks.json` matchers include `Bash`. Core's
issue-75 landing ported the function to `gate-lib.py` specifically so a
gate that only matches `Write|Edit|MultiEdit`-family tools can also see a
`Bash`-based file write. Bash-tool coverage is out of scope per
`docs/issue-10/proposals/gate-a-plus-remediation.md` §7 ("deferred...
unless phase 2's compliance-check pass surfaces an actual Bash-write
path") — that deferral stands; the parity gap noted here is tracked for
completeness, not re-opened.

## 3. Matcher/code mismatch: `NotebookEdit`

Every `hooks.json` (`market-analysis/plugins/*/hooks/hooks.json`)
declares:

```
"matcher": "Write|Edit|MultiEdit"
```

Every `gate.sh`'s Python payload branches on `elif tool == "NotebookEdit":`
(e.g. `five-forces/hooks/gate.sh:111`) and the file's own header comment
claims `PreToolUse gate (Write|Edit|MultiEdit|NotebookEdit)` (line 2) —
`gate-lib.py`'s `gate_reconstruct_write` is also documented as handling
`NotebookEdit` (`five-forces/hooks/gate.sh:8`). Since the hook only fires
on the matcher's tool set, `NotebookEdit` never reaches the gate at
runtime: the code path and both README claims
(`market-analysis/plugins/{jtbd-fit,competitor-mapping,evidence-rigor}/README.md`
all state `Write|Edit|MultiEdit` only, consistent with `hooks.json` but
inconsistent with `gate.sh`'s own header/code) describe a coverage the
wiring doesn't deliver. This is the issue's "matcher-코드 정합" item and
the NotebookEdit-vs-matcher item together: two claims (code comment,
`gate_reconstruct_write` doc) assert coverage; two artifacts (`hooks.json`
matcher, README prose) assert a narrower set; the two groups disagree.

## 4. Citation regex satisfied by its own negation

`five-forces/hooks/gate.sh:175` and `competitor-mapping/hooks/gate.sh:172`:

```python
CITATION_RE = re.compile(r'https?://|source:|citation|cited|\[[^\]]+\]\([^)]+\)|\[\^[^\]]+\]')
```

The bare `cited` alternative is a substring match with no boundary. Text
reading `"...supplier power: high. Uncited."` contains `cited` as a
substring of `Uncited` and the regex matches — the gate reads an explicit
negation of evidence as evidence present. This is the issue's `'uncited'가
citation 만족(부정 취약)` item, confirmed live in both gates that use this
pattern (five-forces, competitor-mapping); evidence-rigor and jtbd-fit
don't use `CITATION_RE` and are unaffected by this specific defect.

## 5. Missing-core test case

Neither `run-gate-lib-tests.sh`-shape suite exists in this repo (the 6
canon-mandated cases from `docs/issue-10/proposals/gate-a-plus-remediation.md`
§5 were folded into each plugin's own `tests/gate.bats`) nor any of the 5
`tests/gate.bats` files contain a case that points
`CLAUDE_PLUGIN_ROOT_CORE`/the fallback path at a nonexistent core and
asserts **deny** (exit 2). Core's issue-75 landing makes this the 7th
mandatory case group (`gate-house-standard.md` transition note: "must
assert deny, not the pre-issue-75 silent-allow bug"). Grep confirms: no
`gate.bats` file in any of the 5 plugins references a missing/nonexistent
core path scenario.

## 6. README / manifest — ghost files, old role names

`market-analysis/plugins/*/README.md` (5 files) and
`.claude-plugin/marketplace.json`: no occurrence of
`record-fields-gate.sh`, `trailer-gate.sh`, `handbook-trigger-gate.sh`, or
`warrant-hunter` (grep across both, zero hits) — the ghost-file/old-role-name
cleanup from `docs/issue-10`'s phase-2 already covers this repo's surface
completely. **No open defect here** for this repo; item 4 of the issue
body's requirement list is already satisfied and phase-2 only needs to
confirm-and-record it, not fix anything.

## Summary table

| # | Defect | File(s) | Status |
|---|--------|---------|--------|
| 1 | wrong core-root var + no `\|\|` guard | 5× `hooks/gate.sh` | open |
| 2 | `gate_bash_write_targets` py parity unconsumed | 5× `hooks/gate.sh` | tracked, deferred (issue-10 §7 stands) |
| 3 | matcher excludes `NotebookEdit`, code/README claim it | 5× `hooks.json`, 5× `gate.sh`, 3× README | open |
| 4 | `cited` substring matches `uncited` | five-forces, competitor-mapping `gate.sh` | open |
| 5 | no missing-core deny test case | 5× `tests/gate.bats` | open |
| 6 | ghost files / old role names in README/manifest | README×5, manifest.json | none found — already clean |

## Sources

- `tokenmaxxxer-core` commit `52bdc15` (PR #77, issue-75 delivered),
  `docs/handbooks/gate-house-standard.md` transition note (local read of
  `core` canon cache, fetched from
  `https://github.com/tokenmaxxxer/tokenmaxxxer-core`).
- This repo's `market-analysis/plugins/*/hooks/{gate.sh,hooks.json}`,
  `*/README.md`, `.claude-plugin/marketplace.json` — read directly.
- `docs/issue-10/proposals/gate-a-plus-remediation.md` — prior landed
  design this survey extends.
