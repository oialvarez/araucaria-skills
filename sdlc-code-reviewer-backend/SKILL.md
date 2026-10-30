---
name: sdlc-code-reviewer-backend
description: "SDLC Phase 5 — Backend Code Reviewer & Auditor. Reviews Java/Spring code against Sonar rules, SOLID, performance, JPA auditing, exception handling, and staff-level PR review standards. Triggers on: 'review backend', 'code review', 'audit', 'sonar', 'quality gate', 'refactor phase', 'PR review backend', 'java review'."
---

# SDLC Phase 5 — Backend Code Reviewer & Auditor

The Refactor Phase. Polish code until it reads like clean art. This skill reviews Java/Spring backend code against Sonar rules, SOLID principles, JPA auditing standards, exception handling patterns, logging conventions, and staff-level PR review protocols.

## Pipeline Position

Standalone. Load on demand; nothing chains into or out of it.

---

## 1. The Refactor Phase

The code works. Tests pass. Now make it **clean**.

### Refactor Checklist

1. **Read every changed file** end-to-end — don't just spot-check
2. **Apply Sonar rules** (see §2)
3. **Verify 90% coverage** on all new/changed code
4. **Detect N+1 queries** — any `findBy*` inside a loop is a red flag
5. **Check SOLID violations** — Single Responsibility first, then the rest
6. **Simplify** — if a method needs a comment to explain it, rename or extract

> [!IMPORTANT]
> The Refactor Phase is NOT optional. Code that "just works" is not done.

---

## 2. Quality & Compliance (Sonar Rules)

### Mandatory Checks

| Rule | Description | Action |
|------|-------------|--------|
| **Unused variables** | No declared-but-unused locals or fields | Remove them |
| **DRY literals** | No magic strings repeated > 1 time | Extract to `static final` constants |
| **Cognitive complexity** | Methods must stay below threshold (≤15) | Extract helper methods |
| **Dead code** | Unreachable branches, commented-out code | Delete it |
| **Mutable injected fields** | `@Autowired` on mutable fields | Use constructor injection |
| **Raw types** | Generic types used without parameters | Add type parameters |

### Coverage Gate

- **90% line coverage** on all new/changed classes
- **Branch coverage** must include error paths, not just happy paths
- Run: `./mvnw test jacoco:report` and inspect `target/site/jacoco/index.html`

### N+1 Query Detection

```java
// BAD — N+1 query pattern
for (Call call : calls) {
    Operator interp = operatorRepository.findById(call.getOperatorId()); // ← DB hit per iteration
}

// GOOD — batch fetch
List<Long> operatorIds = calls.stream().map(Call::getOperatorId).toList();
List<Operator> operators = operatorRepository.findAllById(operatorIds);
```

---

## 3. Domain & JPA Standards

### AbstractAuditingEntity Inheritance

All JPA entities **must** extend `AbstractAuditingEntity`:

```java
@Entity
@Table(name = "my_entity")
public class MyEntity extends AbstractAuditingEntity {
    // entity fields — createdBy, createdDate, lastModifiedBy, lastModifiedDate
    // are inherited automatically
}
```

### Liquibase Audit Columns

Every new table migration **must** include:

```xml
<column name="created_by" type="varchar(50)">
    <constraints nullable="false"/>
</column>
<column name="created_date" type="timestamp" defaultValueComputed="CURRENT_TIMESTAMP">
    <constraints nullable="false"/>
</column>
<column name="last_modified_by" type="varchar(50)"/>
<column name="last_modified_date" type="timestamp"/>
```

---

## 4. Code Cleanliness

### Javadocs Policy

- **DO NOT** add Javadocs to: DTOs, entities, exception classes, obvious getters/setters
- **DO** add Javadocs to: public service methods with non-trivial business logic, utility methods with edge cases
- If the method name says it all, a Javadoc is noise

### Import & Naming

- **No fully-qualified class names** (FQNs) inline — always import
- **No wildcard imports** (`import java.util.*`) — use specific imports
- **Remove unused imports** before every commit
- **Clean naming**: `OperatorAssignmentService` not `OpAssgnSvc`

### Constants

- Extract role strings to constants: `Role.ROLE_ADMIN` not `"ROLE_ADMIN"`
- Extract repeated status strings: `CallStatus.ACTIVE` not `"ACTIVE"`
- Symmetric endpoint security — if you protect GET, protect PUT/DELETE too

---

## 5. Exception Handling

### Global Exception Strategy

All exceptions **must** be mapped through `@RestControllerAdvice`:

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(EntityNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(new ErrorResponse("ENTITY_NOT_FOUND", ex.getMessage()));
    }
}
```

### Anti-Patterns to Flag

```java
// BAD — wrapping in controller
@PostMapping
public ResponseEntity<?> create(@RequestBody CreateCallDto dto) {
    try {
        return ResponseEntity.ok(callService.create(dto));
    } catch (Exception e) {
        throw new BadRequestAlertException(e.getMessage(), "call", "error"); // ← REMOVE THIS
    }
}

// GOOD — let GlobalExceptionHandler catch it
@PostMapping
public ResponseEntity<CallDto> create(@RequestBody @Valid CreateCallDto dto) {
    return ResponseEntity.ok(callService.create(dto));
}
```

---

## 6. Logging Standards

### Controller Layer

- **NO request/response logging** in controllers — this is infrastructure concern
- If you need request tracing, use a filter or interceptor

### Service Layer

- **Descriptive business-centric logs**:

```java
// BAD
log.info("method called");
log.debug("processing...");

// GOOD
log.info("Assigning operator {} to call {} (language: {})", operatorId, callId, language);
log.warn("Operator {} rejected call {} — already in active session", operatorId, callId);
```

### MDC for Traceability

```java
MDC.put("callId", callId.toString());
MDC.put("operatorId", operatorId.toString());
try {
    // business logic
} finally {
    MDC.clear();
}
```

---

## 7. Event Payloads

### Centralized in NotificationUtils

All WebSocket/event payloads **must** be constructed through `NotificationUtils`:

```java
// BAD — raw map construction in service
Map<String, Object> payload = new HashMap<>();
payload.put("callId", call.getId());
payload.put("status", call.getStatus());
messagingService.send(topic, payload);

// GOOD — centralized payload construction
CallNotification notification = NotificationUtils.buildCallStatusNotification(call);
messagingService.send(topic, notification);
```

- No raw `Map<String, Object>` payloads in service classes
- All notification DTOs live alongside `NotificationUtils`

---

## 8. Testing Quality

### AssertJ Chained Assertions

```java
// BAD — multiple independent assertions
assertEquals("ACTIVE", call.getStatus());
assertNotNull(call.getAssignedOperator());
assertEquals(Language.ASL, call.getLanguage());

// GOOD — chained AssertJ
assertThat(call)
    .satisfies(c -> {
        assertThat(c.getStatus()).isEqualTo("ACTIVE");
        assertThat(c.getAssignedOperator()).isNotNull();
        assertThat(c.getLanguage()).isEqualTo(Language.ASL);
    });
```

### Coverage Expectations

- **Happy path** — basic success case
- **Edge cases** — null inputs, empty lists, boundary values
- **Error paths** — exceptions thrown, validation failures
- **Concurrency** — AtomicGuard scenarios where applicable, seeded with the minimum data so the losing thread cannot take a safe branch
- **No flaky tests** — if a test fails intermittently, fix the root cause

---

## 9. PR Review Protocol

### Review Tags

Use these tags to categorize feedback:

| Tag | Meaning | Action Required |
|-----|---------|-----------------|
| `[KUDOS]` | Something done well | None — positive reinforcement |
| `[SUGGESTION]` | Optional improvement | Author decides |
| `[IMPORTANT]` | Should be addressed before merge | Fix expected |
| `[CRITICAL]` | Must be fixed — blocks merge | Fix required |

### Staff Voice Guidelines

- **Be direct** — say what you mean, no hedging
- **Plain English** — no jargon walls, no passive-aggressive phrasing
- **Ask, don't tell** — "Have you considered X?" beats "You should do X"
- **Focus on the code, not the coder** — "This method could be simpler" not "You wrote this wrong"

### Review Focus Areas

1. **Correctness** — Does the logic actually do what the ticket requires?
2. **Observability** — Can we debug this in production with current logging?
3. **Security** — Endpoint protection, input validation, SQL injection prevention
4. **Simplicity** — Is there a simpler way to achieve the same result?

### State Guards and Races

From a real review where each of these let a request get stranded. Check them on any
diff that adds a conditional write (`UPDATE ... WHERE status IN ...`) or a "skip unless" guard.

1. **NULL rows.** `col IN (...)` and `col <> X` are never true for NULL. Find where the row is created
   (entity constructor, `save` of a new entity, Liquibase default). If the column can start NULL, the guard
   needs `col IS NULL OR ...`, plus a test that runs the guarded path on a freshly created row.
2. **Every writer of the same state.** A guard on one write path proves nothing about the others. grep
   every method that writes the same status or re-queues the same resource, and for each one decide
   whether it must be guarded or is meant to be unconditional. Say which in the review.
3. **Failure paths that hand work back.** When a failure path returns work to a waiting state and then
   throws, check who picks it up again. Async executors and `@Async` dispatchers usually just log the
   exception, so the work sits there and can block everything queued behind it.
4. **Race tests that cannot fail.** Read the fixture of every concurrency test. If the losing thread finds
   a second resource, it takes the safe branch and the test passes without the fix. Seed the minimum data
   (one waiting item) and confirm the test fails with the main change reverted.

### Review Checklist

- [ ] AtomicGuard used for concurrent state transitions
- [ ] Conditional writes handle NULL rows, every writer of the same state was checked, and failure paths that return work to waiting re-dispatch it (State Guards and Races)
- [ ] Logging is descriptive and uses MDC
- [ ] Tests cover happy path + edge cases + error paths
- [ ] Scope matches the ticket — no unrelated changes
- [ ] No commented-out code or TODOs without ticket references

---

## Work Type Variants

| Work Type | Scope | Notes |
|-----------|-------|-------|
| **Story** | Full review + refactor + quality report | Standard pipeline |
| **Bug** | Full review + refactor + quality report | Extra attention to regression tests |
| **Improvement** | Full review + refactor + quality report | Focus on before/after performance metrics |
| **Epic** | N/A | Delegated to subtask-level reviews |

---

## Output Artifact

### Quality Report

Produce a structured Quality Report containing:

```markdown
## Quality Report — [TICKET-ID]

### Coverage
- New code coverage: XX%
- Branch coverage: XX%

### Sonar Compliance
- [ ] No unused variables
- [ ] No magic strings
- [ ] Cognitive complexity within limits
- [ ] No dead code

### JPA & Domain
- [ ] Entities extend AbstractAuditingEntity
- [ ] Liquibase audit columns present

### Exception Handling
- [ ] Global handler covers all custom exceptions
- [ ] No BadRequestAlertException wrapping in controllers

### Logging
- [ ] No controller-level request logs
- [ ] Service logs are business-descriptive
- [ ] MDC used for traceability

### Testing
- [ ] AssertJ chained assertions
- [ ] Edge cases covered
- [ ] No flaky tests

### PR Review Summary
- [KUDOS] ...
- [SUGGESTION] ...
- [IMPORTANT] ...
- [CRITICAL] ...

### Verdict: ✅ PASS / ❌ FAIL
```

---

## Related skills

`sdlc-dba` covers schema and query concerns, `sdlc-observability` covers logging and tracing. Neither is implied by this review.

> This skill is loaded on demand. There is no phase pipeline and no automatic hand-off —
> the SDLC dispatcher was retired on 2026-08-14 (see `~/.gemini/config/skills-retired/README.md`).
> Load the next skill only if the work actually calls for it.
