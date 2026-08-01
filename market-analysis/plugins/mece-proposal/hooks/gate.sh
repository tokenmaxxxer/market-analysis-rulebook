#!/usr/bin/env bash
# PreToolUse gate (Write|Edit|MultiEdit|NotebookEdit) — mece-proposal plugin.
#
# Targets: docs/issue-<n>/proposals/*.md (market-analysis phase-1 proposals).
#
# Requires the resulting proposal text to contain all 5 elements required by
# docs/handbooks/market-analysis-norms.md section (a):
#   1. decision framed
#   2. framework selected + rationale (industry attractiveness /
#      competitive positioning / customer-need fit)
#   3. evidence plan
#   4. adoption rationale
#   5. plugin-reflection plan
# Fails closed when any are absent.
#
# Section location goes through the shared `market-analysis/plugins/lib/
# section-extract.py` helper (`extract_section`) — this proposal format
# has no internal heading structure of its own (checked fixtures are flat
# prose), so extract_section's "no matching heading" result falls back to
# treating the whole document as the checked scope, same behavior as
# before, but through the one shared helper instead of a private search —
# see docs/issue-10/proposals/gate-a-plus-remediation.md §2/§3.
#
# Trap/kill-switch/path-normalize/reconstruct come from core's gate-house
# standard (issue-72), referenced by path, never vendored — §1 of the
# same proposal.
#
# Kill switch: export MECE_PROPOSAL_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/lib/gate-lib.sh" || { echo "mece-proposal: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${MECE_PROPOSAL_GATE_OFF:-}" || { trap - EXIT; exit 0; }

deny() { printf "mece-proposal: refused — %s\n" "$1" >&2; exit 2; }

command -v python3 >/dev/null 2>&1 || deny "gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "mece-proposal: empty tool-use payload on stdin; cannot evaluate the gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (mece-proposal gate cannot run)."

SECTION_EXTRACT_PY="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../lib" 2>/dev/null && pwd -P)/section-extract.py"

PG_PAYLOAD="$payload" PG_ROOT="$root" SECTION_EXTRACT_PY="$SECTION_EXTRACT_PY" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import importlib.util, json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("mece-proposal: refused — %s\n" % m); sys.exit(2)

    _gl_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_gl_spec); _gl_spec.loader.exec_module(gate_lib)

    _se_spec = importlib.util.spec_from_file_location("section_extract", os.environ["SECTION_EXTRACT_PY"])
    section_extract = importlib.util.module_from_spec(_se_spec); _se_spec.loader.exec_module(section_extract)

    raw = os.environ.get("PG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (mece-proposal).")

    root = posixpath.normpath(os.environ["PG_ROOT"].replace("\\", "/"))
    PROPOSAL_RE = re.compile(r'^docs/issue-([0-9]+)/proposals/.*\.md$')

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

    if not PROPOSAL_RE.match(rel):
        sys.exit(0)  # not a mece-proposal write surface — not this gate's business

    abs_path = posixpath.join(root, rel) if rel else root
    current = None
    if os.path.isfile(abs_path):
        try:
            with open(abs_path, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on mece-proposal." % rel)

    new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not ok:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches (honoring replace_all), so the MECE "
            "check can be performed." % (rel, tool)
        )

    lines = new_text.splitlines()

    # This proposal format has no internal heading of its own (fixtures are
    # flat prose with no "# "/"## " markers), so a pattern that never
    # matches falls back to treating the whole document as the scope —
    # still routed through the one shared helper rather than a private
    # whole-doc search.
    section_lines, _s, _e = section_extract.extract_section(lines, r'(?!)')
    if section_lines is None:
        section_lines = lines

    low = "\n".join(ln.lower() for ln in section_lines)

    def has_any(*needles):
        return any(nd in low for nd in needles)

    missing = []
    if not has_any("decision framed"):
        missing.append("decision-framed")
    if not (has_any("framework") and has_any(
        "industry attractiveness", "competitive positioning",
        "customer-need fit", "customer need fit",
    )):
        missing.append("framework-selection")
    if not has_any("evidence plan"):
        missing.append("evidence-plan")
    if not has_any("adoption rationale"):
        missing.append("adoption-rationale")
    if not has_any("plugin-reflection plan", "plugin reflection plan"):
        missing.append("plugin-reflection-plan")

    if missing:
        deny(
            "phase-1 proposal at %s is missing required MECE element(s): %s "
            "(see docs/handbooks/market-analysis-norms.md section (a))."
            % (rel, ", ".join(missing))
        )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "mece-proposal: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
