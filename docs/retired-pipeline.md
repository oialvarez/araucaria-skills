# Retired SDLC pipeline — what went wrong

Retired on **2026-08-14** after a team retro flagged two problems: AI-generated prose was
reaching Jira tickets unverified — without checking the sources of truth (code, logs) — and
the refinement it produced left gaps that surfaced as production issues.

The skill bodies quoted company systems and stayed with the company. This page keeps the
lesson. Nothing loads them automatically anymore: the dispatcher section that chained them was
removed from the global instructions (`AGENTS.md`).

| Skill | Why it was retired |
|:---|:---|
| `sdlc-product-owner` | Root cause. Ran as Phase 0, two phases *before* Discovery verified anything, yet wrote Jira ACs and "Technical Details" naming exact class handlers, queue names and DB columns. Rule D forced a "realistic JSON payload fixture" on every API/AMQP/WebSocket subtask (a plausible payload, not one read from the contract). Rule E forced Confluence contract updates before "Ready to Do". Rule F forced decomposition across every repo prefix — writing subtasks against repos nobody had opened. |
| `sdlc-pr-description` | Shipped its template with the Verification checkboxes pre-marked `[x]` and sample metrics ("147 passed", "94% on new code", "Manual testing performed"). |
| `sdlc-tech-writer` | ADRs, changelogs, release notes and API docs generated from templates. |
| `sdlc-release-ops` | Deliverable was three blocks of ✅/❌ checkboxes with no requirement to paste real command output. |
| `sdlc-comms` | Drafted Jira comments, standups and Slack messages. The practice itself is what was retired, not the writing advice. |
| `sdlc-pipeline-router` | Mandated 9 sequential phases per ticket, each with a required artifact — up to 14 documents per story. This was the fatigue source. |

## What was rescued before archiving

Two things in here were the *antidote* to the retro's complaint, not the cause. Both were
lifted into the Verification Protocol in `AGENTS.md`:

- `sdlc-pipeline-router` — the Global Epistemic Protocol (search first / claim second,
  `VERIFIED` `UNVERIFIED` `UNKNOWN` labels, escalate instead of guess).
- `sdlc-discovery` — the Source of Truth hierarchy. That skill is still active; only the
  hierarchy was promoted so it applies everywhere, not just in one phase.

## Still active

`sdlc-architect`, `sdlc-discovery`, `sdlc-qa-engineer`, `sdlc-developer-backend`,
`sdlc-developer-frontend`, `sdlc-security-gate`, `sdlc-code-reviewer-backend`,
`sdlc-code-reviewer-frontend`, `sdlc-dba`, `sdlc-observability` — loaded on demand, never chained.

The last four still emit checkbox-style reports. That pattern is now governed by the rule in
`AGENTS.md`: never mark a checkbox that was not actually run — paste the command output.
