# Proposal — issue-2: switch to core canon references

Subject: issue-2. Phase 1 proposal only — no execution in this PR. Based on
`docs/issue-2/reports/implementation/current-state-survey.md`.

## Plan, per issue's 5 items

1. **Remove `agents/warrant-hunter.md`.** Delete the file entirely. Nothing role-unique
   needs preservation as a *file* — the role-unique content (decision boundary,
   hand-off targets, stance set) is metadata that core's `warrant/` plugin (core
   issue #63) is expected to read from `roles/market-analysis.json`, not from a
   role-local agent file. If core's plugin instead expects a small per-role
   config fragment (not a full agent doc), add that fragment in whatever location
   core's contract specifies — deferred to phase 2 once core's actual interface
   is confirmed (see survey's Gaps section).

2. **Remove the three gate scripts and their `hooks.json` registrations.**
   - Delete `hooks/trailer-gate.sh`, `hooks/record-fields-gate.sh`,
     `hooks/handbook-trigger-gate.sh`.
   - Edit `hooks/hooks.json`: drop the `PreToolUse` block entirely (both matchers);
     keep the `SessionStart` block unchanged.
   - Role-specific data that must not be lost in the deletion:
     - `record-fields-gate.sh`'s `REQUIRED_FIELDS` (`five-forces-summary`,
       `competitor-list`, `jtbd-landscape-verdict`) and target path
       (`docs/issue-<n>/reports/market-analysis.md`) — these must be re-homed
       wherever core's registration reads per-role required fields from (expected:
       `roles/market-analysis.json`'s `produces`, per the current file's own
       comment). This repo does not yet have a `roles/market-analysis.json` —
       phase 2 must create or confirm it as part of the cutover, not leave the
       field list undeclared anywhere.
     - `handbook-trigger-gate.sh` currently has a placeholder `exit 0` verdict —
       no real logic to lose.

3. **Convert `directive.sh` to a stub.** Target shape:
   - `source` (or equivalent plugin-relative load of) `core/hooks/lib/role-directive.sh`.
   - Call `core_role_directive` with this role's unique fields — decision
     boundary, `USE_WHEN`, `PRODUCES`, `WRITE_SCOPE: []`, `HAND-OFF` text, and the
     record path — passed as whatever the function's actual parameter contract is
     (positional args vs. env vars vs. a config file — unconfirmed from core,
     flagged in survey Gaps).
   - Keep the `MARKET_ANALYSIS_CYCLE_OFF` kill-switch and `CLAUDE_ROLE` guard only
     if `core_role_directive` does not already provide them generically; if core's
     shared function subsumes this boilerplate (which the issue's phrasing
     "shared function source + call + role-unique part only" implies), drop the
     duplicated guard logic from this file and rely on core's.

4. **`RECORD_FIELDS_TERMINAL_STATES` for loop-state divergence.** Current
   `directive.sh` has no loop-state / terminal-state concept at all — this role
   does not appear to diverge from whatever core's default terminal-state set is.
   Proposal: do not set `RECORD_FIELDS_TERMINAL_STATES` unless phase-2 discovers
   this role's actual terminal states differ from core's default once core's
   default is known. Record this as an explicit "no override" decision in the
   phase-2 record rather than silently omitting it.

5. **`core/hooks/tests/stub-check.sh`.** Run it against the stubbed `directive.sh`
   during phase 2 and record pass/fail in `docs/issue-2/reports/implementation.md`
   (phase-2 record, gated on Approve per contract v3 s19). Not run in phase 1
   since the stub does not exist yet.

## Risk / open questions for the approver

- Core's exact interface (`role-directive.sh`'s function signature, `warrant/`
  plugin's per-role config format, the two gates' core-side registration
  mechanism) could not be verified from this workspace — core issues #63/#66 are
  external to this repo. Phase 2 execution depends on reading core's actual
  landed code at that time, not on assumptions in this proposal.
- No `roles/market-analysis.json` currently exists in this repo; item 2's
  required-fields preservation implies phase 2 must also create/populate it,
  which is a small scope addition beyond the issue's literal 5 items — flagging
  rather than silently expanding scope.
- Ordering constraint from the issue (must land before this rulebook's "룰북
  성숙화" phase 2) — no visibility into that issue's state from this session;
  approver should confirm before granting Approve.

## Not proposing in this PR

No code changes are made in this PR. Phase 1 output only, per contract v3 s19.
