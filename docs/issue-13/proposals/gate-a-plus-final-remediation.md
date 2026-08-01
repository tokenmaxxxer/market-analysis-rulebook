# Proposal — 게이트 A+ 최종 마감 (issue-13, 재감사 잔여 결함)

Phase-1 design proposal only. No gate code changes in this PR; phase 2
implements this design after human Approve. See
`docs/issue-13/reports/market-analysis/current-state-survey.md` for the
defect inventory (6 items, one already clean) this proposal fixes.

Scouting skip record: skipped — the spec leaves no design decision open.
Every open item's fix is dictated by adopting core's already-landed,
already-confirmed canon fix (issue-75, `tokenmaxxxer-core` PR #77) by
reference, the same posture `docs/issue-10/proposals/gate-a-plus-remediation.md`
took for issue-72; there is no field to scout because the reference
standard is a single authoritative upstream commit, not a market of
comparable implementations.

## Decision framed

Should the 5 remaining re-audit defects (source-guard/var-name, matcher/
NotebookEdit mismatch, `cited`-substring false-accept, missing-core test
gap) be fixed by re-deriving each independently in this repo, or by
pulling core's issue-75-confirmed fix forward the same way issue-10
pulled issue-72 forward? Downstream hand-off: none — stays inside this
role's own tooling; no other role's write scope changes.

## Framework selected + rationale

Same non-market frame as issue-10: adoption-rationale-over-reimplementation,
read as competitive positioning turned inward. The decision boundary is
"does re-deriving beat reusing an already-audited fix," not a market
question, so Porter/JTBD/MECE-market frameworks don't apply here either.

## Evidence plan

Primary source: `tokenmaxxxer-core` commit `52bdc15` (PR #77, issue-75)
and its `docs/handbooks/gate-house-standard.md` transition note, read
directly from the fetched core canon — the authoritative specification
for the guard shape and the 7th mandatory test case, not a claim needing
corroboration. Secondary: this repo's own `gate.sh`/`hooks.json`/
`gate.bats`/README, read directly — every defect in the survey is a
file:line-level read, not inference. No external web source needed
(scouting-skip rationale above).

## Adoption rationale

Issue-75's own fix log records the exact failure this repo currently has
live: an unguarded source silently fails open on a missing core. Patching
each of the 5 gates' source line independently would risk re-deriving a
slightly different guard message or var-name fix per gate; pulling the
canon's literal guarded-source shape means all 5 gates read identically
and any future canon fix to the guard propagates the same way issue-10's
adoption already made routine. This is also the issue body's own frame
("공통 항목은 core #75의 확정 가드/규칙을 참조 적용") — reference application,
not reimplementation.

## Plugin-reflection plan

What changes: each of the 5 `hooks/gate.sh` files' source line (var name +
guard), each `hooks.json`'s `PreToolUse` matcher, the `CITATION_RE`/
`citation_re` pattern in five-forces and competitor-mapping, and each
plugin's `tests/gate.bats` (new 7th case group). What does not change:
`directive.sh`, the record's required-field shape, plugin/gate count
(stays 5), and README/manifest content (survey item 6: already clean,
phase 2 only re-confirms via `compliance-check.sh`, no edit needed).

## 1. Source line: adopt issue-75's guarded form, fix the var name

Replace, in all 5 `hooks/gate.sh` (e.g. `five-forces/hooks/gate.sh:29`):

```bash
. "${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/lib/gate-lib.sh"
```

with the canon's confirmed shape, corrected to the variable on-the-record
#182 actually injects:

```bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/lib/gate-lib.sh" || { echo "<gate-name>: cannot source gate-lib.sh" >&2; exit 2; }
```

`<gate-name>` substituted per-gate (`five-forces`, `evidence-rigor`,
`competitor-mapping`, `jtbd-fit`, `mece-proposal`), matching each gate's
own `deny()` prefix already in file. This closes survey item 1 in full:
the wrong-variable dead-fallback and the fail-open-on-missing-core defect
both trace to this one line per gate.

## 2. Matcher/code alignment: add `NotebookEdit`

Survey item 3 has two possible resolutions — narrow the code to match the
matcher, or widen the matcher to match the code. The code path already
exists, is tested against `gate_reconstruct_write`'s documented
`NotebookEdit` handling, and the header comment on all 5 gates already
claims this coverage; narrowing would mean deleting working, documented
code and walking back a coverage claim made in-file for over a phase.
Widen the matcher instead, in all 5 `hooks.json`:

```
"matcher": "Write|Edit|MultiEdit|NotebookEdit"
```

This makes the `hooks.json` matcher, the `gate.sh` header comment, and the
`gate_reconstruct_write` handling agree — the exact "matcher-코드 완전
정합" the issue asks for. The 3 READMEs that currently state
`Write|Edit|MultiEdit` (jtbd-fit, competitor-mapping, evidence-rigor) are
corrected to `Write|Edit|MultiEdit|NotebookEdit` in the same phase-2 pass,
so the prose claim tracks the wiring instead of the pre-fix matcher.

## 3. Citation regex: close the `uncited` false-accept

Survey item 4. Replace, in `five-forces/hooks/gate.sh:175` and
`competitor-mapping/hooks/gate.sh:172`:

```python
CITATION_RE = re.compile(r'https?://|source:|citation|cited|\[[^\]]+\]\([^)]+\)|\[\^[^\]]+\]')
```

with a negative-lookbehind-guarded form so `cited`/`citation` can't match
as the tail of a longer negated word:

```python
CITATION_RE = re.compile(r'https?://|source:|(?<![a-z])(?:un)?cited\b(?<!uncited)|citation|\[[^\]]+\]\([^)]+\)|\[\^[^\]]+\]')
```

Simpler and equally correct: drop the bare substring entirely and require
a word boundary plus an explicit negative check for the `un-` prefix:

```python
CITATION_RE = re.compile(r'https?://|source:|\bcitation\b|(?<!un)\bcited\b|\[[^\]]+\]\([^)]+\)|\[\^[^\]]+\]')
```

Phase 2 picks whichever of the two passes a dedicated regression case
(below) without over- or under-matching against the existing fixture
corpus in each gate's `gate.bats` — this proposal fixes the mechanism
(boundary + negation-aware), not the exact byte pattern, since the exact
regex is an implementation detail phase 2 verifies against fixtures, not
a design choice. `evidence-rigor` and `jtbd-fit` don't use this pattern
(survey item 4) and are unaffected.

## 4. Missing-core mandatory test (7th case group)

Survey item 5. Each of the 5 `tests/gate.bats` gains the case core's
issue-75 landing made mandatory: point the core-root resolution at a
nonexistent path with no valid relative fallback and assert **deny**
(exit 2), not silent-allow. Concretely, a case that sets
`CLAUDE_PLUGIN_ROOT_CORE=/nonexistent/path` (or unsets it entirely while
`CLAUDE_PLUGIN_ROOT/../core` also doesn't resolve, e.g. by running with a
plugin root outside the real repo layout) and asserts the gate's exit
code is 2 and stderr contains the `cannot source gate-lib.sh` message
from item 1's guard — this is the direct regression proving item 1's fix
is load-bearing, not just cosmetic.

## 5. README / manifest: confirm-clean (no edit needed beyond item 2)

Survey item 6: no ghost files or old role names found in any of the 5
plugin READMEs or `.claude-plugin/marketplace.json`. Phase 2's
Definition of Done still runs the check (issue ask item 4: "옛 이름은
하드 에러") via `compliance-check.sh`/`stub-check.sh` and records the
clean result, rather than skipping the confirmation because the survey
already looked — a green record needs the tool run, not just this
proposal's read.

## 6. Definition of done (issue ask item 3)

Phase 2 runs, before writing `docs/issue-13/reports/market-analysis.md`:
`bats` across all 5 `tests/gate.bats` (including each new missing-core
case) green, plus `compliance-check.sh` clean against
`market-analysis/plugins/*/hooks` — matching
`gate-house-standard.md`'s per-repo migration checklist and this issue's
own item 3 requirement ("missing-core 케이스 포함 전 스위트 배송 상태 green +
compliance-check 통과 record 기록").

## Out of scope for this issue (flagged, not decided)

- `gate_bash_write_targets` py-parity adoption (survey item 2) — stays
  deferred per `docs/issue-10/proposals/gate-a-plus-remediation.md` §7;
  no Bash-tool write path into these docs has been observed, and this
  issue's ask list doesn't name it. Left for a future compliance pass if
  one surfaces.

## Evidence appendix

- `tokenmaxxxer-core` commit `52bdc15` (PR #77, issue-75 delivered) —
  `hooks/lib/gate-lib.sh`/`gate-lib.py` diff, `compliance-check.sh` guard
  rule, `gate-house-standard.md` transition note (7th mandatory case,
  guarded-source requirement) — read directly from the fetched core
  canon.
- This repo's `market-analysis/plugins/*/hooks/{gate.sh,hooks.json}`,
  `*/README.md`, `.claude-plugin/marketplace.json`,
  `*/tests/gate.bats` — read directly, defects enumerated in
  `docs/issue-13/reports/market-analysis/current-state-survey.md`.
- `docs/issue-10/proposals/gate-a-plus-remediation.md` — prior landed
  design this proposal extends by reference.

## Sources

- `tokenmaxxxer-core` (`https://github.com/tokenmaxxxer/tokenmaxxxer-core`),
  commit `52bdc15`, PR #77 (issue-75 delivered) — local fetched copy.
- `docs/handbooks/gate-house-standard.md` (core canon, local fetched
  copy) — transition note.
