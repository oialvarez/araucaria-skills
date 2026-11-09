---
name: sdlc-developer-backend
description: "SDLC Phase 3 — Backend Developer (Java/Spring & Elixir/OTP). Implements the Green Phase for backend services: writes minimal production code to pass failing tests. Enforces Clean Code, SOLID, Java 25 & Elixir standards. Triggers on: 'implement backend', 'java', 'spring', 'elixir', 'phoenix', 'green phase', 'write code', 'service layer', 'repository', 'controller', 'JPA', 'backend implementation'."
---

# SDLC Phase 3 — Backend Developer

> The Green Phase: Make every test pass with the simplest correct code.

## Pipeline Position

Standalone. Load on demand; nothing chains into or out of it.

> **Repository Convention Precedence**: When the active repository has a `CLAUDE.md` or `AGENTS.md` (e.g. `src/main/java/CLAUDE.md`), its architecture, exception handling, concurrency helpers (`AtomicGuard`, `LockService`), and commit/formatting rules (`commit-message`, `husky-commit`) **override** the generic defaults below.

---

## The Green Phase

### Core Principle

> Write ONLY the code necessary to make failing tests pass. Nothing more.

### Rules

1. **YAGNI** — You Ain't Gonna Need It. Do not add functionality that no test demands.
2. **SOLID** — Every class has one reason to change. Depend on abstractions. Open for extension, closed for modification.
3. **Small methods** — No method exceeds 20 lines. If it does, extract a private helper or a new collaborator.
4. **Meaningful names** — Variables, methods, and classes must reveal intent. No abbreviations. No single-letter variables (except lambdas).
5. **No side effects** — A method named `getX()` must not modify state. A method named `calculateX()` must not persist data.
6. **Return early** — Prefer guard clauses over deep nesting.

### Implementation Sequence

1. Run the failing test suite — confirm all tests are RED
2. Pick the simplest failing test
3. Write the minimum code to make it pass
4. Run the test — confirm it is GREEN
5. Refactor if needed (no behavior change, tests stay green)
6. Repeat until all tests are GREEN
7. Run the full test suite — confirm 100% GREEN

---

## Java Quality Gates

### Hard Gates (MUST pass before any commit)

| Gate | Command | Threshold |
|------|---------|-----------|
| **Compilation** | `mvn compile` | Zero errors |
| **Full test suite** | `mvn test` | 100% pass |
| **Code coverage** | JaCoCo report | ≥ 90% line coverage |
| **Linting** | Checkstyle / SpotBugs | Zero violations |

### Java 25 Standards

- **Runtime:** Java 25 (confirm with `java --version`)
- **Records:** Use `record` for immutable DTOs and value objects
- **Sealed classes:** Use `sealed` for restricted type hierarchies
- **Pattern matching:** Use `instanceof` pattern matching and switch expressions
- **Text blocks:** Use `"""` for multi-line strings (SQL, JSON templates)
- **Virtual threads:** Prefer virtual threads for I/O-bound operations where applicable

### Import Rules

- **No fully qualified names (FQNs) in code.** Always use `import` statements.
- **No wildcard imports.** Each import must be explicit.
- **No unused imports.** IDE or Checkstyle must enforce this.
- **Organize imports:** `java.*` → `jakarta.*` → `org.*` → `com.*` → project packages

### Javadoc & Comment Policy

- **No boilerplate Javadoc** on simple DTOs, entities, records, or exception classes
- **DO add Javadoc** to public service methods explaining business intent (not implementation)
- **No commented-out code.** Delete it. Git remembers.
- **No TODO comments** without a ticket reference: `// TODO PROJ-1234: description`

---

## Concurrency Standards

### AtomicGuard Pattern

For any state transition or concurrent update on shared entities:

```java
// CORRECT: Atomic update via @Modifying query
@Modifying
@Query("UPDATE Interpreter i SET i.status = :newStatus WHERE i.id = :id AND i.status = :expectedStatus")
int atomicUpdateStatus(@Param("id") UUID id,
                       @Param("expectedStatus") Status expectedStatus,
                       @Param("newStatus") Status newStatus);
```

### Concurrency Rules

1. **Never load-then-save** shared entities. Use `@Modifying` queries with WHERE guards.
2. **Never call `.save()` directly** on entities that may be concurrently modified.
3. **Check the return value** of atomic updates. If `0` rows affected, the transition was contested — handle gracefully.
4. **Use `@Version`** (optimistic locking) on entities with concurrent write patterns when full atomic queries are impractical.
5. **No `synchronized` blocks** in Spring beans. Use database-level atomicity.

---

## Clean Code Culture

### Boy Scout Rule

> Leave the code cleaner than you found it.

If you touch a file, fix minor style issues you notice (naming, formatting, dead code). Do NOT refactor unrelated large sections — that is a separate ticket.

### Mimetism

> Match the existing style of the codebase.

Before writing new code, examine 2-3 similar classes in the same package. Mirror their:
- Naming patterns
- Method organization
- Exception handling style
- Annotation usage

### The Grandmother Test

> Can you explain what this code does to a non-technical person?

If a method name or class name requires a comment to understand, rename it.

### Evidence-Based Troubleshooting

> Logs > Guesses.

When debugging:
1. Read the logs FIRST
2. Reproduce the issue with a test
3. Form a hypothesis based on evidence
4. Verify with targeted logging or debugging
5. Never guess. Never assume. Always verify.

---

## Logging Standards

### MDC (Mapped Diagnostic Context)

Every request/operation must have MDC context set at the entry point:

```java
MDC.put("requestId", UUID.randomUUID().toString());
MDC.put("userId", SecurityUtils.getCurrentUserId());
MDC.put("operation", "createUser");
```

### What to Log

| Level | When | Example |
|-------|------|---------|
| **INFO** | Business milestones | `"User created successfully: {userId}"` |
| **WARN** | Recoverable issues | `"Retry attempt {n} for external service call"` |
| **ERROR** | Unrecoverable failures | `"Failed to process payment: {errorCode}"` |
| **DEBUG** | Development diagnostics | `"Query returned {count} results"` |

### What NOT to Log

- No PII (names, emails, SSNs, phone numbers)
- No passwords, tokens, or API keys
- No full request/response bodies in production
- No log-and-throw (log OR throw, never both)

---

## Caller Context

### SecurityUtils in Service Layer

```java
// CORRECT: Service layer extracts caller context
@Service
public class UserService {
    public UserDto createUser(CreateUserRequest request) {
        var callerId = SecurityUtils.getCurrentUserId();
        var callerRole = SecurityUtils.getCurrentRole();
        // ... business logic using caller context
    }
}

// WRONG: Controller extracts and passes caller context
@RestController
public class UserController {
    @PostMapping("/users")
    public ResponseEntity<UserDto> createUser(
            @RequestBody CreateUserRequest request,
            @AuthenticationPrincipal UserDetails principal) { // ← NO
        return userService.createUser(request, principal.getId()); // ← NO
    }
}
```

### Rules

1. **Controllers** are thin — validate input, delegate to service, return response
2. **Services** own business logic AND caller context extraction
3. **Repositories** never access security context

---

## PR Hygiene

- **One PR = One Commit** (squash/amend before pushing; follow the repo's `commit-message` and `husky-commit` skills if present)
- **Commit message format:** `PROJ-XXXX: Short imperative description`
- **Branch naming:** `feature/PROJ-XXXX-short-description` or `bugfix/PROJ-XXXX-short-description`
- **No merge commits** in feature branches (rebase on main)

---

## Work Type Variants

| Work Type | Green Phase | Quality Gates | Notes |
|-----------|-------------|---------------|-------|
| **Story** | Full implementation from architect skeleton + pass all QA tests | All gates mandatory | Implement every interface and method from the skeleton |
| **Bug** | Minimal fix to pass the reproducing test | All gates mandatory | Change as few lines as possible. Boy Scout Rule applies. |
| **Improvement** | Refactor with test safety net | All gates mandatory | All existing tests must stay GREEN throughout |
| **Epic** | N/A — delegated to subtask stories | N/A | Epic-level work is decomposed, not implemented directly |

---

## Output Artifact

This phase produces:

1. **Production code** that passes ALL tests from the QA Engineer phase
2. **Refactored code** (if any) with tests still GREEN
3. **Full test suite execution report** — 100% pass rate, ≥ 90% coverage

The code MUST:
- Compile cleanly (`mvn compile` — zero errors)
- Pass all tests (`mvn test` — 100% GREEN)
- Meet coverage threshold (JaCoCo ≥ 90%)
- Follow all Clean Code, concurrency, and logging standards above

---

## Related skills

Once tests are GREEN, `sdlc-security-gate` audits endpoint protection, data exposure, RBAC and injection risks, and `sdlc-code-reviewer-backend` covers clean-code and SOLID.

> This skill is loaded on demand. There is no phase pipeline and no automatic hand-off —
> the SDLC dispatcher was retired on 2026-08-14 (see `~/.gemini/config/skills-retired/README.md`).
> Load the next skill only if the work actually calls for it.
