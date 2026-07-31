#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — competitor-mapping plugin.
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
# Kill switch: export COMPETITOR_MAPPING_GATE_OFF=1
set -uo pipefail

deny() { echo "competitor-mapping: refused — $1" >&2; exit 2; }

case "${COMPETITOR_MAPPING_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

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
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
fi
if [ -z "$root" ]; then
  d="$_target"; [ -n "$d" ] || d="$(pwd -P)"; [ -d "$d" ] || d="$(dirname "$d")"
  root="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && deny "no project root could be determined; failing closed (competitor-mapping check cannot run)."

PG_PAYLOAD="$payload" PG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("competitor-mapping: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("PG_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; the gate cannot judge the competitor-list section on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on competitor-mapping check.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (competitor-mapping).")

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
        sys.exit(0)  # not the market-analysis phase-2 record write surface — not this gate's business

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on competitor-mapping check." % rel)

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
            "Edit/MultiEdit whose old_string matches, so the competitor-list section can be "
            "checked." % (rel, tool)
        )

    lines = new_text.splitlines()
    low_lines = [ln.lower() for ln in lines]

    # (1) locate the competitor-list section marker
    section_re = re.compile(r'competitor[\s\-]?list')
    section_start = None
    for i, ln in enumerate(low_lines):
        if section_re.search(ln):
            section_start = i
            break
    if section_start is None:
        deny(
            "competitor-mapping write is missing a `competitor-list` section. Per "
            "docs/handbooks/market-analysis-norms.md (b).2, the phase-2 record must contain "
            "a competitor-list section naming direct and indirect competitors, each "
            "evidence-linked. (missing-section)"
        )

    # section body: from the marker line to the next heading of the SAME or
    # SHALLOWER level (or EOF) — deeper subheadings like "### Direct" /
    # "### Indirect" are part of this section's body, not its terminator.
    section_heading_m = re.match(r'^\s{0,3}(#{1,6})\s', lines[section_start])
    section_level = len(section_heading_m.group(1)) if section_heading_m else 6
    section_end = len(lines)
    heading_re = re.compile(r'^\s{0,3}(#{1,6})\s')
    for i in range(section_start + 1, len(lines)):
        m = heading_re.match(lines[i])
        if m and len(m.group(1)) <= section_level:
            section_end = i
            break
    section_lines = lines[section_start:section_end]
    section_low = [ln.lower() for ln in section_lines]
    section_text_low = "\n".join(section_low)

    missing = []

    # (2) direct / indirect markers
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

    # (3) evidence-linking: every competitor-entry-looking line must carry (or be
    # immediately followed by a line carrying) a citation marker. Simple,
    # testable per-line heuristic — not full markdown parsing.
    citation_re = re.compile(r'https?://|source:|citation|\[')
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
            "evidence citation (http link, `Source:`, `citation`, or a markdown link). Per "
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
