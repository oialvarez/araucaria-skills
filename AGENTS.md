# AGENTS.md — Global Agent Configuration

This file configures **Claude Code** (`~/.claude/CLAUDE.md`) and **Gemini / Antigravity**
(`~/.gemini/GEMINI.md`) globally. Both are symlinks to `AGENTS.md` in
`~/workspace/araucaria-skills`, the versioned, portable harness. It applies to **all
repositories** on this machine.

Anything tied to one company (systems, URLs, domain skills, ticket prefixes) lives in the
**company overlay** `~/.gemini/config/company.md`, imported at the end of this file. If your
client does not expand `@` imports, read that file yourself at the start of a session.

---

## Communication Style ("Zero Grasa")

- **Lead with the outcome** and what requires a decision. Keep answers conversational, plain and
  proportional — no walls of text mixing code references, hashes and narration.
- **No recaps** of work the user just watched happen, and **no closing menus** of optional next
  steps. If nothing requires action, state the result in one line and stop.
- **Never repeat standing environment quirks** the user already knows (e.g. non-executable
  `.husky/pre-commit`, Jest haste-map warnings, Dependabot push banners).
- **Never use the section-sign character** in any language; write "section 2.3" / "sección 2.3".

---

## Verification Protocol

Applies to every claim about how a system behaves — in chat, in a code comment, in a commit
message, in a Jira ticket, in a PR description.

### Search first, claim second

Never state how the system works without verifying it against a source of truth first.

| Uncertain about... | Verify with |
|:---|:---|
| How a class or method works | `grep` or semantic search in the codebase |
| What events are dispatched | Trace the call chain from the trigger point |
| What a DB column stores | The entity class **and** the Liquibase migration |
| Whether a pattern already exists | Search by name or by key method signature |
| What happened at runtime | Production logs through the log skill the company overlay names — never inference |
| How a sibling repo behaves | `git fetch origin --prune` in that repo first, then read its integration branch on origin (`origin/master` unless the overlay says otherwise) — never a stale local branch |

### Source of truth hierarchy

1. **Running code** — what the system *currently does*
2. **Jira story / ACs** — what it *should do* (business intent)
3. **README / architecture docs** — design intent; valid for context, not for behavior
4. **Agent-generated notes** — lowest authority, always re-verify

> Code and ACs diverge? That is the definition of a **bug**. Do not rewrite the ACs to match
> broken code. Code and docs diverge? The docs are stale — flag them, trust the code.
>
> **Parent coverage rule**: The parent bug or story always overrides its subtasks. Before writing
> code, map every point of the parent's Actual/Expected Behavior, Steps to Reproduce, ACs and
> comment decisions to subtasks. Any unmapped point is a **blocker** to raise before coding.

### Label what you cannot find

If the search comes back empty, do **not** fill the gap with inference:

```text
VERIFIED:   CallService.java:L88 — state transitions happen via AtomicGuard
UNVERIFIED: could not locate the queue removal logic — flagged for manual review
UNKNOWN:    no code found for this claim — do not implement on assumption
```

Presenting an UNKNOWN as a VERIFIED fact is the most dangerous failure mode there is.
A search with no results never means *"I can implement it however I want."*

### Escalate instead of guessing

Stop, state exactly what is unknown and where the search failed, and ask a specific question.

> Good: *"I can't find where the session UUID is assigned. I searched `SessionService`,
> `CallService` and `SessionRepository` — no UUID generation anywhere. Where should I look?"*
>
> Bad: *"I assumed the session UUID is generated in the service layer. Here's the implementation..."*

### No agent-authored prose in team channels & confirm before external writes

Do not draft Jira descriptions, acceptance criteria, ticket comments, PR descriptions,
changelogs, release notes or Confluence updates unless asked for that specific text.
**Never write to Jira or Confluence (edits, comments, status changes) without stating the exact
target and text and getting explicit confirmation first.**
When asked to draft: every technical claim carries its `file:line` or log reference, and anything
unverified is labeled rather than smoothed over. Never invent payload fixtures — quote the
contract or say it is missing. **Never mark a verification checkbox that was not actually run** —
paste the command output instead.

---

## Engineering & Workflow Skills (on demand)

Skills come in two layers, merged in one folder, `~/.gemini/config/skills/`, which Claude reads
through the symlink `~/.claude/skills` and Antigravity through `~/.gemini/antigravity/skills`:

- **Portable** skills (this table) live in `~/workspace/araucaria-skills/skills/` and are
  symlinked into the merged folder by `install.sh`. Edit them there and commit.
- **Company** skills are real folders in the merged folder, listed in the company overlay.

A new skill goes in the repo if it would still be useful at another company, and in the merged
folder otherwise. Pure Markdown, identical in Claude and Gemini. Load one when the work calls for it.
**There is no dispatcher, no mandatory phase sequence, and no automatic chaining between them.**

> **Repo Convention Precedence**: When a repository has its own `CLAUDE.md` or `AGENTS.md` (including
> stack-specific files like `src/main/java/CLAUDE.md` and `src/main/webapp/CLAUDE.md`), its stack
> versions, framework idioms (e.g. Vue 2.6 + Vuex 3 vs Vue 3 + Pinia, JHipster `BadRequestAlertException`,
> selective `AbstractAuditingEntity`, URL-level security) and commit/formatting rules (`commit-message`)
> **override** generic template defaults in the `sdlc-*` skills.

| Skill | Load when |
|:---|:---|
| `sdlc-discovery` | Mapping existing architecture or tracing a bug through logs and code |
| `sdlc-architect` | Defining interfaces, DTOs and contracts before implementing |
| `sdlc-qa-engineer` | Designing the test plan / writing failing tests (TDD red) |
| `sdlc-developer-backend` | Implementing Java/Spring (TDD green) |
| `sdlc-developer-frontend` | Implementing Vue/TypeScript (TDD green) |
| `sdlc-security-gate` | Auditing a diff for auth, RBAC, PII and secrets |
| `sdlc-code-reviewer-backend` | Backend clean-code, concurrency/race guards and SOLID review |
| `sdlc-code-reviewer-frontend` | Frontend review — types, lifecycle, accessibility |
| `sdlc-dba` | Schema changes, migrations, query performance |
| `sdlc-observability` | Logging, tracing, metrics, alerting |
| `ticket-definition` | Breaking a shell ticket into implementable Jira tasks |
| `teammate-comments` | Writing paste-ready replies for PRs, Confluence, Jira or Slack |
| `commit-message` | Formatting any git commit message (`Problem:` + `Solution:` bullets + `Jira ticket:`) |

The reviewer, security, DBA and observability skills emit checkbox-style reports. Those
checkboxes are governed by the Verification Protocol above: run the command, paste the output.

> **Retired 2026-08-14** — `sdlc-pipeline-router`, `sdlc-product-owner`, `sdlc-pr-description`,
> `sdlc-tech-writer`, `sdlc-release-ops` and `sdlc-comms` were archived
> (see `docs/retired-pipeline.md` in the harness repo for why). Do not reintroduce a
> phase pipeline that drafts ticket or PR text ahead of verification.

---

## Domain Knowledge Skills

Domain skills (technical reference for one company's systems) live in the merged skills folder,
not in the repos: a repo's `.agents/` is gitignored, so skills there only reach one checkout. They
are reference material, not process skills; the company overlay lists them. Load them when the
task touches their domain. Never create `.agents/skills/` in a repo.

---

## Universal Rules

- **Never push directly to `master` or `main`** — use feature branches + PRs always (branch from the integration branch the overlay names, if any)
- **Commit & push flow**: Always follow `commit-message` (`<JIRA-KEY>: <Imperative summary>`, `Problem:` paragraph, `Solution:` bullets, `Jira ticket:` URL, one commit per story via amend, hooks off so Prettier never reformats existing files; offer push only; `gh` is fine for PRs, CI runs and `gh workflow run`, but never to create a PR)
- **Test coverage**: 90% minimum on all new code
- **Never commit agent internals** to project repos: `.agents/`, `.claude/`, `.gemini/`, or `SKILL.md` files
  (the harness repo `araucaria-skills` is the one place they are versioned)
- **Security review is not optional** — audit the diff before every PR, on every work type.
  With the pipeline gone nothing triggers it automatically: load `sdlc-security-gate` yourself,
  and its report must cite real findings, not checked boxes

---

## Company overlay

@~/.gemini/config/company.md
