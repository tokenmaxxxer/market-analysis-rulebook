# Current-state survey — issue-10 (게이트 A+ 상향)

Scope: the 5 plugin gates under `market-analysis/plugins/*/hooks/gate.sh`
(five-forces, evidence-rigor, competitor-mapping, jtbd-fit, mece-proposal),
their `tests/gate.bats`, and `README.md`. All 5 gate.sh files share one
hand-rolled skeleton (~190-250 lines each, near-identical prologue) with
the same defect classes repeated five times.

## 1. Confirmed defects (per issue #10 body + direct read)

1. **Kill-switch fail-open on unrecognized value.** Every gate:
   `case "${X_GATE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac`.
   Any value other than a recognized off-spelling — including a typo —
   disables the gate. Same bug core's own canon had before issue-72; fixed
   there by `gate_kill_switch_active` (only a recognized on-spelling
   disables).
2. **`buyer power` substring merge false-pass** (five-forces/hooks/gate.sh
   FORCES list, ~L176-182): `buyer bargaining power` accepts alt phrase
   `buyer power`, and nothing checks that the supplier and buyer mentions
   are structurally distinct lines/bullets. A single merged line like
   "supplier/buyer power: moderate" matches both force regexes via
   substring search on the whole lowered document and passes.
3. **Vacuous deny-message test match.** `gate.bats` asserts on substrings
   of the gate's own deny text (e.g. `[[ "$output" == *"missing a
   five-forces-summary section"* ]]`) without an independent oracle for
   *why* the gate should deny — a test that only echoes the implementation
   asserts nothing about correctness (the issue's "vacuous match" note).
4. **Citation regex accepts a bare `[`.** `CITATION_RE = re.compile(r'http|source:|citation|cited|\[')`
   (five-forces) and `citation_re = re.compile(r'https?://|source:|citation|\[')`
   (competitor-mapping): any single `[` character — e.g. a markdown
   footnote marker, a stray bracket in prose, `[TODO]` — counts as
   evidence with no requirement that it open a real `[text](url)` link or
   `[^n]` footnote.
5. **Edit/MultiEdit reconstruction ignores `replace_all` and is
   first-occurrence-only.** All 5 gates: `current.replace(o, n, 1)` for
   `Edit`, and the same per-edit `.replace(o, n, 1)` inside the `MultiEdit`
   loop — `tool_input.get("replace_all")` is never read. An edit that
   relies on `replace_all: true` to fix every occurrence is reconstructed
   as if only the first occurrence changed, silently checking stale
   content. `NotebookEdit` is not matched by any gate at all (`tool in
   ("Write", "Edit", "MultiEdit")`) — a notebook write bypasses every
   gate outright (fail-open, not merely under-checked).
6. **No `gate_trap_fail_closed` reuse; hand-rolled per file.** Each
   gate re-derives the same `__fc()`/`trap __fc EXIT` block instead of
   sourcing the canon `gate_trap_fail_closed`. Currently correct by
   accident (all 5 copies are faithful), but it is 5 independent copies of
   logic issue-72 found rulebooks re-deriving with 2-3 different idioms —
   exactly the shape gate-lib.sh exists to collapse.
7. **Path normalization is *not* the confirmed-fixed shape, but a
   different, arguably weaker one.** Each gate resolves paths through a
   private `resolve()`/`_under()` pair using `os.path.realpath` (touches
   the real filesystem, dereferences symlinks) rather than
   `gate_lib.gate_normalize_path`'s pure string-algebra normalize+prefix
   check. Symlink-following is not itself wrong, but it means every gate
   independently reproduces resolve/root-prefix logic instead of the one
   canon function — same duplication risk as items 2 and 6, and the six
   canon mandatory test cases (absolute path, `./`-prefixed path) are not
   independently exercised against it today.

## 2. What's already solid (do not regress in phase 2)

- Fail-closed EXIT trap is present and correct in all 5 gates today, plus
  a second fail-closed wrapper around the inline Python payload
  (`_fc_rc` check) — two independent fail-closed layers.
- Malformed-JSON / non-dict-payload deny is already present and correct
  in all 5 gates (`gate_parse_json_or_deny`-equivalent, hand-rolled but
  functionally right).
- `command -v python3` guard denies rather than silently no-ops when
  python3 is missing.
- Non-matching-path passthrough (`sys.exit(0)`) is correct and tested.
- competitor-mapping's section-body extraction (heading-level-bounded,
  stops at a same-or-shallower heading) is more structurally aware than
  five-forces'/evidence-rigor's whole-document substring search — a
  useful existing pattern to generalize when raising five-forces and
  evidence-rigor to section/adjacency checks (item 2 of the issue's ask).

## 3. README drift (issue ask item 4)

`README.md`'s Layout section lists `market-analysis/hooks/record-fields-gate.sh`,
`market-analysis/hooks/trailer-gate.sh`, `market-analysis/hooks/handbook-trigger-gate.sh`,
and `market-analysis/agents/warrant-hunter.md` — none exist in the current
tree. The real top-level `market-analysis/hooks/` holds only `directive.sh`
and `hooks.json` (SessionStart only, no PreToolUse wiring at that level);
the actual PreToolUse gates live one level down, per plugin, at
`market-analysis/plugins/<name>/hooks/gate.sh` + `hooks.json`, and there is
no kill-switch or gate inventory documented anywhere in the README.

## 4. Precondition status — core issue #72

Landed and available for reference at `core/hooks/lib/gate-lib.sh` +
`gate-lib.py` (`docs/handbooks/gate-house-standard.md`). Confirmed via a
local reference copy: `gate_trap_fail_closed`, `gate_kill_switch_active`,
`gate_deny`/`gate_allow`, `gate_parse_json_or_deny`, `gate_normalize_path`,
`gate_reconstruct_write` (honors `replace_all` per-edit for
`Edit`/`MultiEdit`, reconstructs `NotebookEdit`), and
`gate_bash_write_targets`. The precondition in the issue body is
satisfied; phase-1 proposes adopting these by reference, not
reimplementing.
