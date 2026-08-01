#!/usr/bin/env bash
# PreToolUse gate (Write|Edit|MultiEdit|NotebookEdit) — five-forces plugin.
#
# Target: docs/issue-<n>/reports/market-analysis.md (the phase-2 record
# file only — NOT phase-1 proposals under docs/issue-<n>/proposals/).
#
# On a matching write, reconstructs the resulting content via
# gate-lib.py's gate_reconstruct_write (Write/Edit/MultiEdit/NotebookEdit,
# honoring each Edit's own replace_all flag) and checks handbook item
# (b).1's five-forces-summary shape:
#   1. a `## five-forces-summary` section is present (section-bounded via
#      the shared section-extract.py helper, not a whole-document search);
#   2. all 5 Porter forces are named as distinct bullet/paragraph mentions
#      within that section — supplier bargaining power and buyer
#      bargaining power must lead their own bullet, not be merged into one
#      "supplier/buyer power" line;
#   3. each force phrase has a nearby evidence citation marker (a real
#      http(s) link, source:/citation/cited marker, markdown `[text](url)`
#      link, or `[^n]` footnote — a bare `[` no longer counts) on the same
#      or a same-entry continuation line.
#
# No ordering dependency on other market-analysis plugins — see
# docs/issue-7/proposals/plugin-decomposition.md §2.3.
#
# Trap/kill-switch/path-normalize/reconstruct all come from core's
# gate-house standard (issue-72), referenced by path, never vendored — see
# docs/issue-10/proposals/gate-a-plus-remediation.md §1.
#
# Kill switch: export FIVE_FORCES_GATE_OFF=1
. "${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${FIVE_FORCES_GATE_OFF:-}" || { trap - EXIT; exit 0; }

deny() { echo "five-forces: refused — $1" >&2; exit 2; }

command -v python3 >/dev/null 2>&1 || deny "gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "gate: empty tool-use payload on stdin; cannot evaluate the five-forces gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (five-forces check cannot run)."

SECTION_EXTRACT_PY="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../lib" 2>/dev/null && pwd -P)/section-extract.py"

PG_PAYLOAD="$payload" PG_ROOT="$root" SECTION_EXTRACT_PY="$SECTION_EXTRACT_PY" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import importlib.util, json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("five-forces: refused — %s\n" % m); sys.exit(2)

    _gl_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_gl_spec); _gl_spec.loader.exec_module(gate_lib)

    _se_spec = importlib.util.spec_from_file_location("section_extract", os.environ["SECTION_EXTRACT_PY"])
    section_extract = importlib.util.module_from_spec(_se_spec); _se_spec.loader.exec_module(section_extract)

    raw = os.environ.get("PG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (five-forces).")

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
        sys.exit(0)  # resolves outside the project root — not this gate's business
    if not RECORD_RE.match(rel):
        sys.exit(0)  # not the market-analysis phase-2 record — not this gate's business

    abs_path = posixpath.join(root, rel) if rel else root
    current = None
    if os.path.isfile(abs_path):
        try:
            with open(abs_path, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on five-forces-summary check." % rel)

    new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not ok:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches (honoring replace_all), so the "
            "five-forces-summary can be checked." % (rel, tool)
        )

    lines = new_text.splitlines()

    section_lines, _s, _e = section_extract.extract_section(lines, r'five[- ]forces[- ]summary')
    if section_lines is None:
        deny(
            "the market-analysis phase-2 record is missing a five-forces-summary section "
            "(no '## five-forces-summary' heading found). Per "
            "docs/handbooks/market-analysis-norms.md item (b).1, the record must carry a "
            "per-force verdict for all 5 Porter forces, each evidence-cited."
        )

    FORCES = [
        ("competitive rivalry", r'competitive rivalry'),
        ("threat of new entrants", r'threat of new entrants'),
        ("supplier bargaining power", r'supplier bargaining power|supplier power'),
        ("buyer bargaining power", r'buyer bargaining power|buyer power'),
        ("threat of substitutes", r'threat of substitutes'),
    ]

    missing_forces = [
        name for name, pat in FORCES
        if section_extract.distinct_bullet_mentions(section_lines, pat) < 1
    ]
    if missing_forces:
        deny(
            "the five-forces-summary is missing the following Porter force(s), each named "
            "as its own distinct bullet/paragraph mention (supplier and buyer bargaining "
            "power must be separate mentions, not merged onto one line): %s."
            % ", ".join(missing_forces)
        )

    # Citation-marker strictness (survey item 4): a bare `[` no longer
    # counts — requires a real link/footnote shape.
    CITATION_RE = re.compile(r'https?://|source:|citation|cited|\[[^\]]+\]\([^)]+\)|\[\^[^\]]+\]')
    BULLET_RE = re.compile(r'^\s*(?:[-*]\s+|\d+[.)]\s+)(.*)$')

    def _leading_line_index(pat):
        compiled = re.compile(pat, re.IGNORECASE)
        for idx, ln in enumerate(section_lines):
            bm = BULLET_RE.match(ln)
            content = bm.group(1) if bm else ln.strip()
            if content and compiled.match(content.strip()):
                return idx
        return None

    uncited = []
    for name, pat in FORCES:
        idx = _leading_line_index(pat)
        if idx is None:
            continue  # already reported missing above
        here = bool(CITATION_RE.search(section_lines[idx].lower()))
        nxt = False
        if not here and idx + 1 < len(section_lines):
            nxt_line = section_lines[idx + 1]
            # only a continuation line (not a new bullet, i.e. not another
            # force's own entry) may lend its citation to this force.
            if not BULLET_RE.match(nxt_line):
                nxt = bool(CITATION_RE.search(nxt_line.lower()))
        if not (here or nxt):
            uncited.append(name)

    if uncited:
        deny(
            "the five-forces-summary names the following force(s) without a nearby evidence "
            "citation (need an http(s) link, source:/citation/cited marker, a markdown "
            "`[text](url)` link, or a `[^n]` footnote, on the same or a continuation line): %s."
            % ", ".join(uncited)
        )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "five-forces: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
