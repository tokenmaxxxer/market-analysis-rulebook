#!/usr/bin/env bash
# PreToolUse gate (Write|Edit|MultiEdit|NotebookEdit) — evidence-rigor plugin.
#
# Targets: docs/issue-<n>/proposals/*.md (phase-1 proposals) and
# docs/issue-<n>/reports/market-analysis.md (phase-2 record) — the two
# write surfaces this plugin shares across both phases (see
# docs/issue-7/proposals/plugin-decomposition.md §2.1/§2.2).
#
# Requires the resulting content contain an evidence/sources block: an
# actual `## Sources` / `Sources:` heading LINE (phase-1 proposal style —
# no longer a whole-document substring match, which previously let
# "Resources: none listed" false-accept, survey/proposal §3) OR an
# "evidence appendix" heading (phase-2 record style). Presence-only check
# — cannot verify citation correctness or sufficiency (accepted
# limitation, see docs/issue-7/proposals/plugin-decomposition.md §4.2).
# Fails closed when absent.
#
# Trap/kill-switch/path-normalize/reconstruct come from core's gate-house
# standard (issue-72), referenced by path, never vendored — see
# docs/issue-10/proposals/gate-a-plus-remediation.md §1.
#
# Kill switch: export EVIDENCE_RIGOR_GATE_OFF=1
. "${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${EVIDENCE_RIGOR_GATE_OFF:-}" || { trap - EXIT; exit 0; }

deny() { printf "evidence-rigor: refused — %s\n" "$1" >&2; exit 2; }

command -v python3 >/dev/null 2>&1 || deny "gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "evidence-rigor: empty tool-use payload on stdin; cannot evaluate the evidence gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (evidence-rigor check cannot run)."

PG_PAYLOAD="$payload" PG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import importlib.util, json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("evidence-rigor: refused — %s\n" % m); sys.exit(2)

    _gl_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_gl_spec); _gl_spec.loader.exec_module(gate_lib)

    raw = os.environ.get("PG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (evidence-rigor).")

    root = posixpath.normpath(os.environ["PG_ROOT"].replace("\\", "/"))
    PROPOSAL_RE = re.compile(r'^docs/issue-([0-9]+)/proposals/.*\.md$')
    RECORD_RE = re.compile(r'^docs/issue-([0-9]+)/reports/market-analysis\.md$')

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

    m_proposal = PROPOSAL_RE.match(rel)
    m_record = RECORD_RE.match(rel)
    if not (m_proposal or m_record):
        sys.exit(0)  # not an evidence-rigor write surface — not this gate's business
    surface = "proposal" if m_proposal else "record"

    abs_path = posixpath.join(root, rel) if rel else root
    current = None
    if os.path.isfile(abs_path):
        try:
            with open(abs_path, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on evidence-rigor." % rel)

    new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not ok:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches (honoring replace_all), so the "
            "evidence-rigor result can be checked." % (rel, tool)
        )

    lines = new_text.splitlines()
    low = new_text.lower()

    # A real Sources heading line — "## Sources" (any heading level) or a
    # bare "Sources:" label line — not any substring occurrence anywhere in
    # the document. Closes the "Resources: none listed" false-accept
    # (survey/proposal §3): that line is neither a "sources" heading nor an
    # exact "Sources:" label, so it no longer satisfies this check.
    SOURCES_HEADING_RE = re.compile(r'^\s{0,3}#{1,6}\s*sources\b', re.IGNORECASE)
    SOURCES_LABEL_RE = re.compile(r'^\s*sources\s*:\s*$', re.IGNORECASE)
    has_sources_heading = any(
        SOURCES_HEADING_RE.match(ln) or SOURCES_LABEL_RE.match(ln) for ln in lines
    )
    has_evidence_appendix = "evidence appendix" in low

    if not (has_sources_heading or has_evidence_appendix):
        deny(
            "%s at %s must carry an evidence block — an actual `## Sources` / `Sources:` "
            "heading line (phase-1 proposal style) or an `Evidence appendix` heading "
            "(phase-2 record style) covering the claims used. None was found." % (surface, rel)
        )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "evidence-rigor: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
