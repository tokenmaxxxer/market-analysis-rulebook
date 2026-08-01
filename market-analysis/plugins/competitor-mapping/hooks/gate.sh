#!/usr/bin/env bash
# PreToolUse gate (Write|Edit|MultiEdit|NotebookEdit) — competitor-mapping plugin.
#
# Target: docs/issue-<n>/reports/market-analysis.md (the phase-2 record file
# only, NOT proposals). Requires a `competitor-list` section naming at
# least one direct and one indirect competitor, each evidence-linked.
#
# Per docs/handbooks/market-analysis-norms.md (b).2 and
# docs/issue-7/proposals/plugin-decomposition.md §2.1's competitor-mapping
# row. Combines independently with five-forces/jtbd-fit/evidence-rigor on
# the same write surface — no ordering dependency (§2.3).
#
# This gate's heading-bounded section slice was this repo's own best
# existing technique (current-state-survey.md §2); it has been lifted out
# verbatim into the shared `market-analysis/plugins/lib/section-extract.py`
# helper (`extract_section`), which this gate now calls instead of keeping
# a private copy — see docs/issue-10/proposals/gate-a-plus-remediation.md §2/§3.
#
# Trap/kill-switch/path-normalize/reconstruct come from core's gate-house
# standard (issue-72), referenced by path, never vendored — §1 of the
# same proposal.
#
# Kill switch: export COMPETITOR_MAPPING_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/lib/gate-lib.sh" || { echo "competitor-mapping: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${COMPETITOR_MAPPING_GATE_OFF:-}" || { trap - EXIT; exit 0; }

deny() { echo "competitor-mapping: refused — $1" >&2; exit 2; }

command -v python3 >/dev/null 2>&1 || deny "gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "gate: empty tool-use payload on stdin; cannot evaluate the competitor-mapping gate."

_target="$(printf '%s' "$payload" | python3 -c '
import json,sys
try: e=json.loads(sys.stdin.read())
except Exception: sys.exit(0)
ti=e.get("tool_input") if isinstance(e,dict) else None
if isinstance(ti,dict):
    for k in ("file_path","notebook_path"):
        v=ti.get(k)
        if isinstance(v,str) and v: print(v); break
' 2>/dev/null || true)"

_plausible() { [ -n "$1" ] && [ -d "$1" ] && { [ -e "$1/.git" ] || [ -f "$1/docs/specs/role-handoff-contract.md" ]; }; }
_under() {
  [ -z "$2" ] && return 0
  python3 -c '
import os,posixpath,sys
r,t=sys.argv[1],sys.argv[2]
try: rr=posixpath.normpath(os.path.realpath(r).replace("\\","/"))
except Exception: sys.exit(1)
n=t.replace("\\","/"); a=n if posixpath.isabs(n) else posixpath.join(rr,n)
a=posixpath.normpath(a); real=posixpath.normpath(os.path.realpath(a).replace("\\","/"))
sys.exit(0 if (real==rr or real.startswith(rr+"/")) else 1)
' "$1" "$2"
}

root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && _plausible "$CLAUDE_PROJECT_DIR" && _under "$CLAUDE_PROJECT_DIR" "$_target"; then
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd)"
fi
if [ -z "$root" ]; then
  d="$_target"; [ -n "$d" ] || d="$(pwd -P)"; [ -d "$d" ] || d="$(dirname "$d")"
  root="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && deny "no project root could be determined; failing closed (competitor-mapping check cannot run)."

SECTION_EXTRACT_PY="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../lib" 2>/dev/null && pwd -P)/section-extract.py"

PG_PAYLOAD="$payload" PG_ROOT="$root" SECTION_EXTRACT_PY="$SECTION_EXTRACT_PY" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import importlib.util, json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("competitor-mapping: refused — %s\n" % m); sys.exit(2)

    _gl_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_gl_spec); _gl_spec.loader.exec_module(gate_lib)

    _se_spec = importlib.util.spec_from_file_location("section_extract", os.environ["SECTION_EXTRACT_PY"])
    section_extract = importlib.util.module_from_spec(_se_spec); _se_spec.loader.exec_module(section_extract)

    raw = os.environ.get("PG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (competitor-mapping).")

    root = posixpath.normpath(os.environ["PG_ROOT"].replace("\\", "/"))
    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/market-analysis\.md$')

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    elif tool == "NotebookEdit":
        p = ti.get("notebook_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    rel = gate_lib.gate_normalize_path(root, path)
    if rel is None:
        sys.exit(0)
    if not RECORD_RE.match(rel):
        sys.exit(0)  # not the market-analysis phase-2 record write surface — not this gate's business

    abs_path = posixpath.join(root, rel) if rel else root
    current = None
    if os.path.isfile(abs_path):
        try:
            with open(abs_path, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on competitor-mapping check." % rel)

    new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not ok:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches (honoring replace_all), so the "
            "competitor-list section can be checked." % (rel, tool)
        )

    lines = new_text.splitlines()

    section_lines, section_start, _end = section_extract.extract_section(lines, r'competitor[\s\-]?list')
    if section_lines is None:
        deny(
            "competitor-mapping write is missing a `competitor-list` section. Per "
            "docs/handbooks/market-analysis-norms.md (b).2, the phase-2 record must contain "
            "a competitor-list section naming direct and indirect competitors, each "
            "evidence-linked. (missing-section)"
        )

    section_low = [ln.lower() for ln in section_lines]

    missing = []

    # (1) direct / indirect markers
    direct_re = re.compile(r'direct\s*competitor|###?\s*direct\b')
    indirect_re = re.compile(r'indirect\s*competitor|###?\s*indirect\b')
    has_direct = any(direct_re.search(ln) for ln in section_low)
    has_indirect = any(indirect_re.search(ln) for ln in section_low)
    if not has_direct:
        missing.append("missing-direct")
    if not has_indirect:
        missing.append("missing-indirect")

    if missing:
        deny(
            "competitor-mapping write's competitor-list section is missing required "
            "element(s): %s. Per docs/handbooks/market-analysis-norms.md (b).2, the "
            "competitor-list must name at least one direct and one indirect competitor." % ", ".join(missing)
        )

    # (2) evidence-linking: every competitor-entry-looking line must carry (or be
    # immediately followed by a line carrying) a citation marker. Citation-marker
    # strictness (survey item 4): a bare `[` no longer counts — requires a real
    # link/footnote shape.
    citation_re = re.compile(r'https?://|source:|\bcitation\b|(?<!un)\bcited\b|\[[^\]]+\]\([^)]+\)|\[\^[^\]]+\]')
    entry_re = re.compile(r'^\s*[-*]\s+\S|^\s*\*\*[^*]+\*\*')

    entry_without_citation = False
    n = len(section_lines)
    for i in range(n):
        ln = section_lines[i]
        low_ln = ln.lower()
        if direct_re.search(low_ln) or indirect_re.search(low_ln):
            continue  # subheading/label lines aren't competitor entries themselves
        if entry_re.match(ln):
            here = bool(citation_re.search(low_ln))
            nxt = bool(citation_re.search(section_lines[i + 1].lower())) if i + 1 < n else False
            if not (here or nxt):
                entry_without_citation = True
                break

    if entry_without_citation:
        deny(
            "competitor-mapping write's competitor-list section has an entry without an "
            "evidence citation (http(s) link, `Source:`, `citation`/`cited`, a markdown "
            "`[text](url)` link, or a `[^n]` footnote). Per "
            "docs/handbooks/market-analysis-norms.md (b).2, every claimed competitor fact "
            "must be backed by an evidence link — pricing page, filing, product doc. "
            "(entry-without-citation)"
        )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "competitor-mapping: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
