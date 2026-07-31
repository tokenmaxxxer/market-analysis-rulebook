#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — five-forces plugin.
#
# Target: docs/issue-<n>/reports/market-analysis.md (the phase-2 record
# file only — NOT phase-1 proposals under docs/issue-<n>/proposals/).
#
# On a matching write, reconstructs the resulting content (Write/Edit/
# MultiEdit reconstruction, same approach as pricing-verdict-report's
# report-gate.sh) and checks handbook item (b).1's five-forces-summary
# shape:
#   1. a five-forces-summary section marker is present;
#   2. all 5 Porter forces are named as distinct phrases — supplier
#      bargaining power and buyer bargaining power must appear as two
#      separate mentions, not merged into one "supplier/buyer power" line;
#   3. each force phrase has a nearby evidence citation marker within a
#      ~400-char window after it (http, source:, citation, cited, or a
#      markdown link).
#
# No ordering dependency on other market-analysis plugins — see
# docs/issue-7/proposals/plugin-decomposition.md §2.3.
#
# Kill switch: export FIVE_FORCES_GATE_OFF=1
set -uo pipefail

deny() { echo "five-forces: refused — $1" >&2; exit 2; }

case "${FIVE_FORCES_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

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
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
fi
if [ -z "$root" ]; then
  d="$_target"; [ -n "$d" ] || d="$(pwd -P)"; [ -d "$d" ] || d="$(dirname "$d")"
  root="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && deny "no project root could be determined; failing closed (five-forces check cannot run)."

PG_PAYLOAD="$payload" PG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("five-forces: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("PG_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; the gate cannot judge the five-forces-summary on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on five-forces-summary check.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (five-forces).")

    root = posixpath.normpath(os.environ["PG_ROOT"].replace("\\", "/"))
    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/market-analysis\.md$')

    def resolve(p):
        n = p.replace("\\", "/")
        a = n if posixpath.isabs(n) else posixpath.join(root, n)
        a = posixpath.normpath(a)
        try:
            return posixpath.normpath(os.path.realpath(a).replace("\\", "/"))
        except OSError:
            return a

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    r = resolve(path)
    if not r.startswith(root + "/"):
        sys.exit(0)
    rel = r[len(root):].lstrip("/")
    if not RECORD_RE.match(rel):
        sys.exit(0)  # not the market-analysis phase-2 record — not this gate's business

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on five-forces-summary check." % rel)

    new_text = None
    if tool == "Write":
        c = ti.get("content")
        if isinstance(c, str):
            new_text = c
    elif tool == "Edit":
        o, n_ = ti.get("old_string"), ti.get("new_string")
        if isinstance(o, str) and isinstance(n_, str) and current is not None and o in current:
            new_text = current.replace(o, n_, 1)
    elif tool == "MultiEdit":
        edits = ti.get("edits")
        text = current
        if isinstance(edits, list) and text is not None:
            ok = True
            for e in edits:
                if not isinstance(e, dict):
                    ok = False; break
                o, n_ = e.get("old_string"), e.get("new_string")
                if not isinstance(o, str) or not isinstance(n_, str) or o not in text:
                    ok = False; break
                text = text.replace(o, n_, 1)
            if ok:
                new_text = text

    if new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the five-forces-summary can be "
            "checked." % (rel, tool)
        )

    low = new_text.lower()

    # 1. section marker
    if not re.search(r'five[- ]forces[- ]summary', low):
        deny(
            "the market-analysis phase-2 record is missing a five-forces-summary section "
            "(no 'five-forces-summary' / 'five forces summary' heading or label found). Per "
            "docs/handbooks/market-analysis-norms.md item (b).1, the record must carry a "
            "per-force verdict for all 5 Porter forces, each evidence-cited."
        )

    # 2. the 5 distinct forces — each as its own phrase.
    FORCES = [
        ("competitive rivalry", [r'competitive rivalry']),
        ("threat of new entrants", [r'threat of new entrants']),
        ("supplier bargaining power", [r'supplier bargaining power', r'supplier power']),
        ("buyer bargaining power", [r'buyer bargaining power', r'buyer power']),
        ("threat of substitutes", [r'threat of substitutes']),
    ]

    missing_forces = []
    force_spans = {}  # name -> (start, end) of first match in low
    for name, alts in FORCES:
        found_span = None
        for alt in alts:
            m = re.search(alt, low)
            if m:
                found_span = m.span()
                break
        if found_span is None:
            missing_forces.append(name)
        else:
            force_spans[name] = found_span

    if missing_forces:
        deny(
            "the five-forces-summary is missing the following Porter force(s), each named "
            "as its own distinct phrase (supplier and buyer bargaining power must be "
            "separate mentions, not merged): %s." % ", ".join(missing_forces)
        )

    # 3. each force phrase has a nearby citation within ~400 chars after it,
    # but the window is capped at the start of the next bullet/force mention
    # so a long uncited sentence can't borrow a citation from the next force.
    CITATION_RE = re.compile(r'http|source:|citation|cited|\[')
    BULLET_RE = re.compile(r'\n\s*[-*]\s')
    all_starts = sorted(s for s, _e in force_spans.values())
    uncited = []
    for name, (start, end) in force_spans.items():
        window_end = end + 400
        next_force_start = next((s for s in all_starts if s > start), None)
        if next_force_start is not None:
            window_end = min(window_end, next_force_start)
        bullet_m = BULLET_RE.search(low, end)
        if bullet_m:
            window_end = min(window_end, bullet_m.start())
        window = low[end:max(end, window_end)]
        if not CITATION_RE.search(window):
            uncited.append(name)

    if uncited:
        deny(
            "the five-forces-summary names the following force(s) without a nearby evidence "
            "citation (need http/source:/citation/cited/a markdown link within ~400 chars "
            "after the force phrase): %s." % ", ".join(uncited)
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
