---
name: sdlc-discovery
description: "SDLC Phase 1b — Technical Discovery & Verification. Maps existing architecture, verifies system behavior claims against codebase, and prevents assumptions. Triggers on: 'discover', 'explore', 'verify', 'trace', 'how does X work', 'architecture map', 'existing patterns', 'reuse'."
---

# SDLC Phase 1b: Technical Discovery & Verification

The Discovery phase maps the existing architecture, verifies all assumptions against the codebase, and identifies patterns to reuse. **Nothing in the implementation plan should be based on guesses.**

---

## Source of Truth Hierarchy

When documentation and code conflict, apply this hierarchy:

| Priority | Source | Authority for |
| :---: | :--- | :--- |
| 1 | **Running code** (Java, TypeScript, SQL) | What the system *currently does* |
| 2 | **Jira story / ACs** | What the system *should do* (business intent) |
| 3 | **README / architecture docs** | Design intent — valid for context, not for behavior |
| 4 | **Agent-generated docs** (`.agents/stories/`) | Working notes — lowest authority, must be re-verified |

### The critical distinction

> **Code vs. ACs diverge?** → That is the definition of a **bug**. The code describes what *is*; the ACs describe what *must be*. Do NOT update the ACs to match broken code.
>
> **Code vs. `.agents/stories/` diverge?** → The code wins. Update the agent docs to reflect reality.
>
> **Code vs. README diverge?** → Treat the README as **stale**. Flag it for update. The code is what runs in production.

### Discrepancy Protocol

When any source conflicts with another, **never silently adopt one over the other**. Instead:

1. **Document the conflict** explicitly: *"The README states X, but `ClassName.java:L42` implements Y."*
2. **Apply the hierarchy** to determine which source wins.
3. **Escalate to the user** when Jira ACs conflict with code — this is almost always a bug report, not a docs issue.
4. **Update stale docs** after confirming which source is authoritative.

---



## Pipeline Position

Standalone. Load on demand; nothing chains into or out of it.

---

## Work Type Variants

| Work Type | Variant | What Happens |
| :--- | :--- | :--- |
| **Story** | Full | Full discovery of affected components, patterns, and constraints |
| **Bug** | Trace | **Start with log triage** → trace the exact failure path through logs and code |
| **Improvement** | Lite | Lite discovery of refactoring targets and dependency impact |
| **Epic** | Full Scan | Complete architecture scan and component map across all affected systems |

### Parent coverage (Bug and Story, before any code)

The parent bug or story always overrides its subtasks, especially subtasks we wrote. Subtasks are
a starting point, never the scope.

1. List what the parent asks for. Bug: every point of Actual Behavior, Steps to Reproduce and
   Expected Behavior. Story: every acceptance criterion. Both: every scope question or decision in
   the body and comments.
2. Inventory every code path that touches what changes. Bug: grep every writer of the affected
   fields (e.g. every `setXxx` / `UPDATE` on those columns, jobs and cleanups included). Story:
   every screen, service or job that reads or writes what changes.
3. Map each parent point and each path to a subtask. Anything unmapped is a **blocker**: raise it
   before implementing and before review, never as an optional follow-up.

---

## 1. Core Patterns Reference

Before implementing new logic, check if these common patterns already exist in the codebase and can be reused:

### Atomic Updates
- Look for existing atomic update utilities (e.g., compare-and-swap, optimistic locking, atomic database queries).
- Pattern: Single `@Modifying` query that updates state **only if** the current state matches expected value.
- Prevents race conditions in concurrent environments.

### Distributed Locking
- Look for existing lock services (e.g., Redis-based locks, database advisory locks).
- Pattern: Acquire lock → execute critical section → release lock, with timeout protection.
- Use for cross-instance synchronization.

### Event Handling
- Look for existing event strategy patterns (e.g., strategy pattern for different event types, handler factories).
- Pattern: Event dispatcher routes to type-specific handlers.
- Identify the event taxonomy (what events exist, what triggers them).

### Utilities & Helpers
- Look for existing helper services for common operations (status verification, data transformation, audit logging).
- Reuse before creating new utilities.

---

## 2. Layered Constraints

Identify and respect the architectural layer boundaries in the codebase:

### Common Layer Rules
- **Controllers/Handlers** → should only call **Services**
- **Services** → should only call **Repositories** and other **Services**
- **Repositories/DAOs** → should only access the **database**
- **Jobs/Schedulers** → should only call **Services**, never access domain entities directly

### Constraint Detection Protocol
1. Search for architectural test rules (e.g., ArchUnit, eslint-plugin-boundaries, dependency-cruiser).
2. Check for documented layer constraints in project README or architecture docs.
3. Verify by scanning import statements in existing code for layer violation patterns.

**If architectural rules exist in the codebase, document them in the Discovery Report. Violations of these rules will cause build failures.**

---

## 3. Verification Protocol

Step-by-step process for verifying system behavior claims:

### Step 1: Locate the Triggering Code
- Use `grep` or semantic search to find the class or method handling the core transition or event.
- Search for: method names, event names, status enum values, message types.

### Step 2: Verify the Conditions
- Read the branch logic, null guards, and database queries.
- Verify scope: Does a condition apply to all users, a specific role, a specific state?
- Check for feature flags, environment-specific behavior, or conditional configurations.

### Step 3: Trace Side-Effects
- What database updates are written? Check for ORM versioning (optimistic locking).
- What events are published? (message queues, WebSocket, HTTP callbacks)
- What logs are emitted? (for observability and debugging)
- What caches are updated or invalidated?

### Step 4: Reference Source Files
- For every verified claim, include a file link: `[ClassName.java](file:///path/to/file#L42-L58)`
- If a claim cannot be verified, mark it as **UNVERIFIED** and flag it for manual review.

---

## 4. Discovery Checklist

Before any implementation work begins, verify:

- [ ] **Existing Patterns**: Are there reusable patterns for the type of work being done?
- [ ] **Layer Boundaries**: Are there architectural rules that constrain where code can be placed?
- [ ] **Event Taxonomy**: What events exist in the system? What triggers them? What handles them?
- [ ] **Database Schema**: What tables/collections are affected? What are the constraints and indexes?
- [ ] **External Dependencies**: What external services or APIs are involved? What are their contracts?
- [ ] **Configuration**: Are there feature flags, environment variables, or config files that affect behavior?
- [ ] **Concurrency**: Are there concurrent access patterns that require locking or atomic operations?
- [ ] **Test Infrastructure**: What test utilities, fixtures, or mocks already exist?

---

## 5. Standard Identifiers & Conventions

Document the codebase's conventions for:

### ID Formats
- What UUID format is used? (v4, v7, custom)
- Are there composite keys or natural keys?
- What is the primary identifier for external API communications?

### Timestamp Conventions
- What timezone is used for storage? (UTC recommended)
- Are there "trust rules" (e.g., trust timestamp fields over status enums for determining actual state)?
- What date/time library is standard? (java.time, dayjs, date-fns, etc.)

### Naming Conventions
- Package/module naming patterns
- Class/function naming patterns
- Database table/column naming patterns (snake_case, camelCase, etc.)

---

## 6. Architecture Discovery Report Template

The output of this phase is a structured report:

```markdown
# Discovery Report: [TICKET-ID] — [Title]

## Affected Components

| Component | Type | Impact | Source |
| :--- | :--- | :--- | :--- |
| [ClassName] | Service | Modified | [link to file] |
| [TableName] | Database | New column | [link to migration] |

## Patterns to Reuse
- **[Pattern Name]**: [Description] — [link to existing implementation]

## Architectural Constraints
- [Constraint 1]: [Source of truth — link to ArchUnit test or doc]
- [Constraint 2]: [Source]

## Verified Behaviors
- [Claim 1]: VERIFIED — [link to source]
- [Claim 2]: VERIFIED — [link to source]
- [Claim 3]: UNVERIFIED — requires manual review

## Event Flow Map
```text
[Trigger] → [Handler/Strategy] → [Side-effects]
```

## Risks & Open Questions
- [Risk 1]
- [Open Question 1]
```

---

## Bug Trace Variant

For **Bug** work types, the Discovery phase focuses on tracing the failure:

### Step 0: Log Triage (MANDATORY FIRST STEP)

Before touching any code, **extract timestamps and identifiers from the bug report and Jira comments**:

1. **Scan the ticket** for: timestamps ("happened at 2:30pm EST"), UUIDs (callId, sessionId, sessionUUID), environment (prod/qa/staging), and reporter timezone
2. **Convert to UTC** — Jira comments show local times. EST = UTC-5, EDT = UTC-4, PDT = UTC-7
3. **Pull the logs** from the project's log platform (Datadog, CloudWatch, Loki, ...). Use a log-fetching skill or script if one is installed; otherwise ask the user for access instead of guessing. Choose the query mode:

```text
# If ticket has a UUID → filter by it (relative window is fine):
service:<service> @<idField>:<UUID>        last 1h

# If ticket has a known timestamp → absolute window (±15 min buffer):
service:<service> env:prod                 2026-06-30T14:15:00Z → 2026-06-30T14:45:00Z

# If no timestamp or UUID → fallback to relative window:
service:<service> env:prod                 last 30m
```

Search order: start with the service that received the request, then follow the call downstream.

### Step 1: Reproduce the Path
- Using the log evidence, identify the exact code path from trigger to failure.

### Step 2: Code Trace
- Grep for the relevant class, method, or event handler identified in the logs.
- Verify conditions: branch logic, null guards, DB queries.

### Step 3: State Inspection
- Check database state at the time of failure (status enums, timestamps, flags).
- Cross-reference with log timestamps to reconstruct the sequence of events.

### Step 4: Root Cause
- Identify the exact line or condition that causes the defect, backed by log evidence.
- Never guess — mark claims as UNVERIFIED if log evidence is absent.

### Step 5: Blast Radius
- Determine what else could be affected by the same root cause.
- Identify related code paths that share the same faulty logic.

Output: A **Trace Report** (includes log evidence, code path, and root cause) instead of a full Discovery Report.

---

## Output Artifact

- **Type**: Architecture Discovery Report
- **Location**: `.agents/stories/[TICKET-ID]/[TICKET-ID]_discovery.md`
- **Contents**:
  - Components affected with source links
  - Patterns to reuse
  - Architectural constraints to respect
  - Verified vs. unverified behavior claims
  - Event flow map
  - Risks and open questions

For **Bug** work type, the output is a **Trace Report** at `.agents/stories/[TICKET-ID]/trace.md`.
It must always include a **Session Handoff Block** as the first section:

```markdown
## Session Handoff

- **Status**: IN PROGRESS | BLOCKED | NEEDS REVIEW | DONE
- **Branch**: `git/PROJ-1234-short-description`
- **Last session**: 2026-06-30 (conversation ID: xxxx-xxxx)
- **Last completed step**: Step 2 — Code Trace (identified CallService.java:L88 as suspect)
- **Next action**: Step 3 — verify DB state at time of failure via a log query
- **Blocked on**: (if BLOCKED) waiting for production log access / QA env availability / etc.

### Open Questions
- [ ] Is the null check missing in ALL environments or only prod?
- [ ] Does the race condition affect the Transfer flow as well?

### What Was Tried (and failed)
- Added null guard at CallService.java:L88 → did NOT resolve the issue (root cause was upstream)
```

**Update this block at the END of every session, before closing the conversation.**
This is the contract between sessions — a new conversation reads this block first to restore context.

---

## Related skills

When the discovery report is done, `sdlc-qa-engineer` turns the verified behaviors into failing tests.

> This skill is loaded on demand. There is no phase pipeline and no automatic hand-off —
> the SDLC dispatcher was retired on 2026-08-14 (see `~/.gemini/config/skills-retired/README.md`).
> Load the next skill only if the work actually calls for it.
