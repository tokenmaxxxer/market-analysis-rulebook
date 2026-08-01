# Current-state survey — issue-16 (A+ 인증 마감, 2026-08-01 차단 사유)

Scope: the two named README defects only. Code (`gate.sh`, `hooks.json`,
`gate.bats`) is not the audit target this time — it already implements
the correct behavior; only the READMEs have drifted from it.

## Defect 1 — `five-forces/README.md`

Read `market-analysis/plugins/five-forces/hooks/hooks.json:7` and
`hooks/gate.sh:1,105-113`:

- `hooks.json` matcher: `"Write|Edit|MultiEdit|NotebookEdit"`.
- `gate.sh` branches on `tool in ("Write","Edit","MultiEdit")` vs
  `tool == "NotebookEdit"` (reading `notebook_path`) — NotebookEdit is
  live-handled.
- README's "What it enforces" section (pre-fix) said only
  "`Write`/`Edit`/`MultiEdit`" — omitted NotebookEdit, contradicting the
  actual matcher/code.
- `CITATION_RE` at `gate.sh:159` is
  `r'https?://|source:|\bcitation\b|(?<!un)\bcited\b|\[[^\]]+\]\([^)]+\)|\[\^[^\]]+\]'`
  — a bare `[` does **not** match this (needs `[text](url)` or `[^n]`).
  README's pre-fix wording ("...or a markdown link `[`") described the
  bare-`[` behavior the issue-13 remediation already removed (confirmed
  by `gate.bats` case "(p) bare [TODO] with no following (url) does not
  count as a citation", passing).

## Defect 2 — `mece-proposal/README.md`

Read `core/hooks/lib/gate-lib.sh` (fetched via
`CLAUDE_PLUGIN_ROOT_CORE`, cached locally at
`/tmp/tokenmaxxxer-core-canon-cache/core/hooks/lib/gate-lib.sh`),
`gate_kill_switch_active` (line 61-68):

```
case "$v" in
  1|true|yes|on) return 1 ;;
  *) return 0 ;;
esac
```

Only the case-insensitive on-spellings `1`/`true`/`yes`/`on` disable the
gate (return 1 → caller's `|| exit 0`); every other value — including
unrecognized/typo values — keeps the gate active (return 0). This is the
issue-72 fail-closed-on-garbage fix, adopted into this repo per
`docs/issue-10/proposals/gate-a-plus-remediation.md` §1.

README's pre-fix wording ("any non-empty, non-'off'-like value disables
the gate") described the opposite, pre-issue-72 fail-open idiom — stale
relative to the code this plugin actually sources.

## Scouting skip record

Skipped — both fixes are dictated by matching README prose to already-
landed, already-tested code in this same repo (`gate.sh`/`hooks.json`/
`gate-lib.sh`, all passing `gate.bats`). No design decision is open and
no external field exists to scout; the fix is a documentation-accuracy
correction, not a build decision.

## Test/probe log

```
$ /tmp/claude-1000/bats-core/bin/bats \
    market-analysis/plugins/five-forces/tests/gate.bats \
    market-analysis/plugins/mece-proposal/tests/gate.bats
1..38
ok 1..38  (all pass, including citation-strictness case (p)/(v2) and
           kill-switch case (t)/(k))
```

Confirms the code behavior the README fix must match; the README-only
change makes no code edit so this suite stays green as-is (baseline
proof, re-run identically after the README edit lands in phase 2).
