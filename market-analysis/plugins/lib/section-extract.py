# Sourceable Python helper for this rulebook's own gates (issue-10 phase-2).
# In-repo, market-analysis-specific — NOT core canon. Generalizes
# competitor-mapping's heading-bounded section slice (its own best existing
# technique, per docs/issue-10/reports/market-analysis/scout-brief.md) so
# five-forces, evidence-rigor, jtbd-fit, and mece-proposal share one copy
# instead of each hand-writing its own bespoke section-location logic.
#
# Loaded via importlib from a gate's own Python payload, the same way
# gate-lib.py is loaded:
#
#   import importlib.util, os
#   _spec = importlib.util.spec_from_file_location(
#       "section_extract", os.environ["SECTION_EXTRACT_PY"])
#   section_extract = importlib.util.module_from_spec(_spec)
#   _spec.loader.exec_module(section_extract)

import re

_HEADING_RE = re.compile(r'^\s{0,3}(#{1,6})\s+(.*)$')
_BULLET_RE = re.compile(r'^\s*(?:[-*]\s+|\d+[.)]\s+)(.*)$')


def extract_section(lines, section_pattern):
    """Locate the first markdown heading line matching `section_pattern`
    (a regex applied case-insensitively to the heading text), and return
    `(section_lines, start, end)` bounded by the next heading of the same
    or shallower level (or EOF) — the heading-level-bounded slice
    competitor-mapping's gate.sh already used for its `competitor-list`
    section, lifted out verbatim as the shared base.

    Returns `(None, None, None)` when no heading matches `section_pattern`.
    Deeper subheadings (e.g. `### Direct` under a `## competitor-list`
    section) are part of the matched section's body, not its terminator.
    """
    pat = re.compile(section_pattern, re.IGNORECASE)
    start = None
    level = None
    for i, ln in enumerate(lines):
        m = _HEADING_RE.match(ln)
        if m and pat.search(m.group(2)):
            start = i
            level = len(m.group(1))
            break
    if start is None:
        return None, None, None

    end = len(lines)
    for i in range(start + 1, len(lines)):
        m = _HEADING_RE.match(lines[i])
        if m and len(m.group(1)) <= level:
            end = i
            break
    return lines[start:end], start, end


def distinct_bullet_mentions(section_lines, phrase_pattern):
    """Count how many times `phrase_pattern` (regex, case-insensitive)
    leads its own bullet/list-item line or its own paragraph within
    `section_lines`.

    A match counts only when `phrase_pattern` matches at the START of a
    line's content (after stripping a leading `-`/`*`/`1.` bullet marker),
    and that line is either itself a bullet/list item or the first line of
    a paragraph (preceded by a blank line or the start of the section).
    This closes the "supplier/buyer power: moderate" merged-line
    false-pass: since the phrase pattern is anchored to the start of the
    line's content, a line whose leading text is "supplier/buyer power"
    does not match an anchored "supplier bargaining power" (or "buyer
    bargaining power") pattern at all — the merged line satisfies at most
    one force's phrase, never two, and a phrase buried mid-sentence on a
    line about something else no longer counts as a mention of that phrase.
    """
    pat = re.compile(phrase_pattern, re.IGNORECASE)
    count = 0
    prev_blank = True
    for ln in section_lines:
        stripped = ln.strip()
        is_blank = stripped == ""
        bm = _BULLET_RE.match(ln)
        if bm:
            content = bm.group(1)
            is_own_line = True
        else:
            content = stripped
            is_own_line = prev_blank and not is_blank
        if is_own_line and content and pat.match(content.strip()):
            count += 1
        prev_blank = is_blank
    return count
