---
name: sdlc-architect
description: "SDLC Phase 1a — Software Architect. Defines interfaces, contracts, DTOs, and creates verified implementation plans. Ensures Dependency Inversion (DIP) before any logic is written. Triggers on: 'design', 'architecture', 'interface', 'contract', 'DTO', 'plan', 'blueprint', 'DIP', 'decouple'."
---

# SDLC Phase 1a: Software Architect (The Planner)

The Architect phase defines **The What**, not **The How**. It produces the structural skeleton (interfaces, contracts, DTOs) and a verified implementation plan. No production logic is written in this phase.

---

## Pipeline Position

Standalone. Load on demand; nothing chains into or out of it.

---

## Work Type Variants

| Work Type | Variant | What Happens |
| :--- | :--- | :--- |
| **Story** | Full | Complete architecture + verified implementation plan |
| **Bug** | Patch | Identify affected contracts, assess blast radius, patch-level analysis |
| **Improvement** | Full | Full redesign plan with migration strategy |
| **Epic** | Blueprint | High-level architecture overview — system boundaries, integration points, component relationships. No implementation details. |

---

## 1. Dependency Inversion (DIP) Checklist

Before writing any implementation logic, ensure these are defined:

- [ ] **Interfaces First**: Never implement logic without an interface if the component is a service, repository, or strategy.
- [ ] **DTO Definition**: Define all Request/Response DTOs before starting implementation. DTOs cross layer boundaries — domain entities do not.
- [ ] **Decoupling**: Ensure the domain layer does not depend on infrastructure (persistence, controllers, messaging frameworks).
- [ ] **Inversion Direction**: High-level modules must not depend on low-level modules. Both must depend on abstractions.

### Language-Specific Notes
- **Java/Spring**: Interfaces for services and repositories. DTOs as records or POJOs.
- **TypeScript/Node**: Interfaces or types for service contracts. DTOs as plain objects or classes.
- **Python**: Abstract base classes (ABC) or Protocol classes for contracts.
- **Go**: Interfaces defined by the consumer, not the provider.

---

## 2. Interface Segregation Principle (ISP)

- **Small Interfaces**: Each interface should represent a single capability or responsibility.
- **Role-Based Splitting**: If a service has 10 methods but a consumer only needs 2, define a focused interface for those 2.
- **No God Interfaces**: If an interface grows beyond 5-7 methods, evaluate whether it can be split.

---

## 3. Contract Clarity

Every interface and public method must have clear contract documentation:

- **Pre-conditions**: What must be true before calling this method? (e.g., "entity must exist", "user must be authenticated")
- **Post-conditions**: What is guaranteed after successful execution? (e.g., "status updated to ACTIVE", "event published")
- **Invariants**: What must always be true? (e.g., "session cannot have negative duration")
- **Error Contracts**: What exceptions or error states can occur? Document them explicitly.

### Contract Documentation Template

```text
Method: [method signature]
  Pre-conditions:
    - [condition 1]
    - [condition 2]
  Post-conditions:
    - [outcome 1]
    - [outcome 2]
  Error States:
    - [error 1]: [when it occurs]
    - [error 2]: [when it occurs]
```

---

## 4. Verified Planning

The implementation plan must follow the **no-assumptions rule**: all descriptions of existing system behavior must be verified in the code before being included in the plan.

### Core Principles

- **No Inventions/Guesses**: Never assume how a service, event, or database state behaves. If a plan states "when X happens, Y occurs," there must be a corresponding method, query, or configuration in the codebase that proves it.
- **Trace Every Event**: For event-driven flows (WebSocket messages, message queue events, webhooks), trace the exact handler or strategy that processes the event. Do not assume implicit transitions.
- **Explicit Conditions**: Detail the exact business rules and logic boundaries.

### Plan Structure

A verified implementation plan must include:

1. **Objective**: One-sentence summary of what the plan achieves.
2. **Affected Components**: List of files/classes/modules that will be created or modified, with source links.
3. **Interface & DTO Definitions**: The skeleton produced by this phase.
4. **Step-by-Step Implementation**: Ordered list of changes, each referencing verified source files.
5. **Verification Evidence**: For each claim about existing behavior, include the source file and line reference.
6. **Risk Assessment**: What could go wrong? What are the edge cases?
7. **Test Strategy Summary**: High-level outline of what tests are needed (detailed test design is Phase 2).

### Verification Steps

Before drafting or finalizing any implementation plan:

1. **Locate the Triggering Code**: Use search to find the class or method handling the core transition or event.
2. **Verify the Conditions**: Check the branch logic, null guards, and database queries. Verify scope (does a condition apply to all participants, a specific role, etc.).
3. **Trace Side-Effects**: Verify what updates are written to the database and what events are published.
4. **Reference Source Files**: Add file links to the verified files (e.g., `[ServiceImpl.java](file:///path/to/ServiceImpl.java)`).

---

## 5. Plan Review Checklist

When auditing a plan, ask these verification questions:

- [ ] Are all interfaces defined before implementation steps?
- [ ] Are DTOs defined for all cross-layer data transfers?
- [ ] Is every claim about existing system behavior backed by a source reference?
- [ ] Are the database status values and reasons checked against the actual enums or constants?
- [ ] Are all events matching the exact event names in the codebase?
- [ ] Does the plan specify which tests need to be written or updated?
- [ ] Are error states and edge cases explicitly addressed?
- [ ] Is the plan free of assumptions about behavior that hasn't been verified?

---

## 6. Epic Blueprint Format

For Epics, the Architect produces a **Blueprint** instead of a full implementation plan:

```text
# Epic Blueprint: [EPIC-ID] — [Title]

## System Boundaries
- [Service/Component 1]: [responsibility]
- [Service/Component 2]: [responsibility]

## Integration Points
- [System A] ↔ [System B]: [protocol/contract]

## Component Relationships
[High-level dependency diagram or description]

## Architecture Decisions
- Decision 1: [rationale]
- Decision 2: [rationale]

## Constraints
- [constraint 1]
- [constraint 2]

## Open Questions
- [question requiring further discovery]
```

---

## Output Artifact

- **Type**: Interfaces, DTOs (The Skeleton) + Verified Implementation Plan
- **Location**: `.agents/stories/[TICKET-ID]/[TICKET-ID]_plan.md`
- **Contents**:
  - Interface definitions (language-appropriate)
  - DTO definitions
  - Verified step-by-step implementation plan with source references
  - For Epics: Blueprint document

---

## Related skills

Once the skeleton exists, `sdlc-discovery` is the natural follow-up: it verifies the plan against the codebase before anyone writes production code.

> This skill is loaded on demand. There is no phase pipeline and no automatic hand-off —
> the SDLC dispatcher was retired on 2026-08-14 (see `~/.gemini/config/skills-retired/README.md`).
> Load the next skill only if the work actually calls for it.
