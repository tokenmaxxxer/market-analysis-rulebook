# Phase-2 record — issue-13: gate A+ 최종 마감 (재감사 잔여 결함)

Subject: issue-13. Phase 2 execution, gated on the `APPROVE
issue-13/market-analysis` issue comment (author JiwonJung94, MEMBER),
which followed `docs/issue-13/proposals/gate-a-plus-final-remediation.md`
(Approved).

This is a gate-tooling-hardening record, not a market-analysis verdict
record — same self-block posture as `docs/issue-10/reports/market-analysis.md`
(see Open findings below).

## What was done

Implemented the approved proposal against all 5
`market-analysis/plugins/{five-forces,evidence-rigor,competitor-mapping,
jtbd-fit,mece-proposal}/hooks/gate.sh`, closing every open defect the
2026-08-01 re-audit named (survey items 1, 3, 4, 5; item 2 stays deferred
per issue-10 §7; item 6 confirmed already clean).

### 1. Source-guard fix (survey item 1)

All 5 `gate.sh` source lines replaced:

```
. "${CLAUDE_PLUGIN_ROOT_CORE:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/lib/gate-lib.sh" || { echo "<gate-name>: cannot source gate-lib.sh" >&2; exit 2; }
```

Fixes both confirmed defects: the injected variable is now
`CLAUDE_PLUGIN_ROOT_CORE` (matching on-the-record #182's actual
injection, not the dead `CORE_PLUGIN_ROOT`), and the `||` guard makes a
failed source deny (exit 2) instead of silently leaving every
`gate_kill_switch_active ... || { exit 0; }` call site fail-open on
"command not found" (127).

### 2. Matcher/code alignment (survey item 3)

All 5 `hooks.json` matchers widened to
`"Write|Edit|MultiEdit|NotebookEdit"`, matching each `gate.sh`'s existing
`NotebookEdit` code path and header-comment claim. The 3 READMEs that
previously stated `Write|Edit|MultiEdit` (jtbd-fit, competitor-mapping,
evidence-rigor) were corrected to match.

### 3. Citation regex: `uncited` false-accept closed (survey item 4)

`five-forces/hooks/gate.sh` (`CITATION_RE`) and
`competitor-mapping/hooks/gate.sh` (`citation_re`) both changed from a
bare `cited` substring to a word-boundary, negation-aware form:

```python
re.compile(r'https?://|source:|\bcitation\b|(?<!un)\bcited\b|\[[^\]]+\]\([^)]+\)|\[\^[^\]]+\]')
```

`\bcited\b` alone already excludes "uncited" (no word boundary between
"un" and "cited"); the `(?<!un)` lookbehind is redundant-but-harmless
belt-and-suspenders. Regression tests added: five-forces (v2),
competitor-mapping (g2) — both assert a force/entry marked "Uncited." is
denied, not accepted.

### 4. Missing-core mandatory test (survey item 5)

Each of the 5 `tests/gate.bats` gained a 7th case group asserting: with
`CLAUDE_PLUGIN_ROOT_CORE` unset and `CLAUDE_PLUGIN_ROOT` pointed at a
freshly-created empty directory (no valid core anywhere on the fallback
path), the gate denies (exit 2) with stderr containing "cannot source
gate-lib.sh" — the direct regression proving item 1's guard is
load-bearing, not cosmetic.

### 5. README / manifest ghost-file check (survey item 6)

Confirmed clean, no edit needed beyond item 2's matcher-string
correction: `grep -rl` for `record-fields-gate.sh`, `trailer-gate.sh`,
`handbook-trigger-gate.sh`, `warrant-hunter` across
`market-analysis/plugins/*/README.md` and
`.claude-plugin/marketplace.json` returns zero hits.

## Verification

All five `tests/gate.bats` files run via a local `bats-core` build
(`/tmp/claude-1000/bats-core`, not preinstalled in this checkout), with
`CLAUDE_PLUGIN_ROOT_CORE` already exported session-wide at
`.../tokenmaxxxer-core/core` (the same variable the gate's fixed source
line now reads):

```
$ bats market-analysis/plugins/{five-forces,evidence-rigor,competitor-mapping,jtbd-fit,mece-proposal}/tests/gate.bats
1..85
85/85 ok
```

85 tests total (21 five-forces incl. new (v2)/(w), 15 evidence-rigor incl.
new (m), 18 competitor-mapping incl. new (g2)/(n), 14 jtbd-fit incl. new
(l), 17 mece-proposal incl. new (n)) — all green, including all 5 new
missing-core-deny cases and the 2 new uncited-substring regression cases.

### `compliance-check.sh` — honest finding (unchanged from issue-10)

```
$ bash <core>/hooks/tests/compliance-check.sh market-analysis/plugins/<name>/hooks
compliance-check: no *-gate.sh files found under ... — nothing to check
```

Still a vacuous pass, for the same reason issue-10's record already
recorded: the detector globs `*-gate.sh`, and this repo's gates are named
plainly `gate.sh`. Not fixed here (renaming is not in the approved
proposal's scope and `compliance-check.sh` itself is core canon, outside
this issue's write scope). Verified substantively instead by copying all
5 `gate.sh` files to a scratch dir under synthetic `<name>-gate.sh`
filenames and re-running the checker unmodified:

```
$ bash <core>/hooks/tests/compliance-check.sh <scratch-dir-with-*-gate.sh-copies>
compliance-check: ok — five-forces-gate.sh
compliance-check: ok — evidence-rigor-gate.sh
compliance-check: ok — competitor-mapping-gate.sh
compliance-check: ok — jtbd-fit-gate.sh
compliance-check: ok — mece-proposal-gate.sh
```

All 5 pass both of `compliance-check.sh`'s substantive rules (kill-switch
via `gate_kill_switch_active`, no unguarded `gate-lib.sh` source) once
its glob can actually see the file. `bash -n` syntax-checked all 5
`hooks/gate.sh`; `python3 -m json.tool` parsed all 5 `hooks.json` cleanly.

## Why

Per the approved proposal: adopting core's issue-75-confirmed guard shape
by reference (not re-derived per gate) keeps all 5 gates' source lines
identical and any future canon guard fix propagating the same way. The
matcher widen (not code narrow) preserves already-tested, already-claimed
`NotebookEdit` coverage. The regex fix closes the exact false-accept the
re-audit demonstrated live.

## Upstream basis

- `docs/issue-13/proposals/gate-a-plus-final-remediation.md` (this repo, phase-1, Approved).
- `docs/issue-13/reports/market-analysis/current-state-survey.md` (this repo, phase-1).
- `tokenmaxxxer/tokenmaxxxer-core` `core/hooks/lib/gate-lib.sh` (issue-75, PR #77) and `core/hooks/tests/compliance-check.sh` — read directly from the installed marketplace core plugin; referenced by path at gate-run time, never vendored.
- `docs/issue-10/proposals/gate-a-plus-remediation.md`, `docs/issue-10/reports/market-analysis.md` — prior landed design and record precedent this record extends/repeats where the same gaps recur.

## Open findings

- **`compliance-check.sh`'s glob does not match this repo's `gate.sh`
  naming** — carried forward unresolved from issue-10's record, same
  reason, same out-of-scope call: core canon, not this issue's write
  surface.
- **`gate_bash_write_targets` py-parity adoption** (survey item 2) —
  stays deferred per issue-10 §7; still no live Bash-write path to these
  docs observed during this phase's verification.
- **Self-block possibility, not re-triggered this time.** Unlike
  issue-10's authoring session, this record's own required content (none
  of the 5 content gates' sections apply to a tooling record) did not
  trip a `Write`-tool denial in this run; no Bash-tool workaround was
  needed to land this file.

loop_state: landed

## Next steps

None — loop_state is terminal. The two carried-forward open findings
above are gaps outside this issue's approved scope, left for the
approver to route as follow-up issues.
