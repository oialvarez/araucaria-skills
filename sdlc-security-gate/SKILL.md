---
name: sdlc-security-gate
description: "SDLC Phase 4 — Security Gate (MANDATORY). Reviews security implications of every change. Checks endpoint protection, role-based access, data exposure, injection risks, and OWASP compliance. Triggers on: 'security', 'auth', 'roles', 'permissions', 'endpoint protection', 'OWASP', 'vulnerability', 'security review', 'access control'."
---

# SDLC Phase 4 — Security Gate (MANDATORY)

> Every code change passes through security review. No exceptions.

## Pipeline Position

Standalone. Load on demand; nothing chains into or out of it.

---

## 1. Endpoint Security Checklist

### Every New/Modified REST Endpoint

| Check | Rule | Severity |
|-------|------|----------|
| **Explicit authorization** | Every endpoint MUST have `@PreAuthorize`, `@Secured`, or explicit authority check | 🔴 BLOCKER |
| **Symmetric security** | If PUT/POST/DELETE is protected, GET on the same resource MUST be too | 🔴 BLOCKER |
| **No open endpoints** | Any unauthenticated endpoint requires explicit justification in PR description | 🟡 WARNING |
| **Method-level security** | Prefer method-level `@PreAuthorize` over URL-pattern security config | 🟢 BEST PRACTICE |
| **Rate limiting** | Public endpoints must have rate limiting configured | 🟡 WARNING |

### Audit Template

```markdown
### Endpoint Security Audit

| Endpoint | Method | Auth Required | Roles | Rate Limited | Status |
|----------|--------|--------------|-------|--------------|--------|
| /api/users | GET | ✅ | ADMIN, MANAGER | ✅ | ✅ PASS |
| /api/users | POST | ✅ | ADMIN | ✅ | ✅ PASS |
| /api/health | GET | ❌ (justified) | — | ✅ | ✅ PASS |
```

---

## 2. Data Protection

### PII in Logs

| Check | Rule | Severity |
|-------|------|----------|
| **No PII in logs** | Names, emails, SSNs, phone numbers must NEVER appear in log statements | 🔴 BLOCKER |
| **Log UUIDs only** | Reference entities by internal ID, never by personal identifiers | 🔴 BLOCKER |
| **No request body logging** | Do not log full request/response bodies in production code | 🟡 WARNING |

### Input Sanitization

| Check | Rule | Severity |
|-------|------|----------|
| **Validate all inputs** | Every `@RequestBody` must have `@Valid` with Bean Validation annotations | 🔴 BLOCKER |
| **String length limits** | All String fields must have `@Size(max=...)` constraints | 🟡 WARNING |
| **No raw HTML** | User-provided strings must be sanitized before rendering | 🔴 BLOCKER |

### Error Responses

| Check | Rule | Severity |
|-------|------|----------|
| **No stack traces** | Error responses must never expose stack traces to clients | 🔴 BLOCKER |
| **No internal details** | Error messages must not reveal database structure, class names, or internal paths | 🔴 BLOCKER |
| **Consistent error format** | All errors must use the project's standard `ErrorResponse` DTO | 🟢 BEST PRACTICE |

### Secrets Management

| Check | Rule | Severity |
|-------|------|----------|
| **No hardcoded credentials** | No passwords, API keys, or tokens in source code | 🔴 BLOCKER |
| **No secrets in config files** | Use environment variables or secret managers (Vault, AWS Secrets Manager) | 🔴 BLOCKER |
| **No secrets in logs** | Auth tokens, session IDs must never appear in log output | 🔴 BLOCKER |

---

## 3. Role-Based Access Control (RBAC)

### Identity Provider Group Mappings (Okta, Keycloak, ...)

```java
// CORRECT: Role strings extracted to constants
public final class Roles {
    public static final String ADMIN = "hasAuthority('ROLE_ADMIN')";
    public static final String MANAGER = "hasAuthority('ROLE_MANAGER')";
    public static final String OPERATOR = "hasAuthority('ROLE_OPERATOR')";
    public static final String ADMIN_OR_MANAGER = "hasAnyAuthority('ROLE_ADMIN', 'ROLE_MANAGER')";

    private Roles() {} // Utility class
}

// Usage
@PreAuthorize(Roles.ADMIN_OR_MANAGER)
public UserDto createUser(CreateUserRequest request) { ... }
```

```java
// WRONG: Inline role strings
@PreAuthorize("hasAuthority('ROLE_ADMIN')") // ← NO: inline string, easy to typo
public UserDto createUser(CreateUserRequest request) { ... }
```

### RBAC Audit Checklist

| Check | Rule | Severity |
|-------|------|----------|
| **Constants for roles** | All role strings extracted to a `Roles` utility class | 🟡 WARNING |
| **Test authorized paths** | Every protected endpoint has a test verifying successful access with correct role | 🔴 BLOCKER |
| **Test unauthorized paths** | Every protected endpoint has a test verifying 403 with wrong role | 🔴 BLOCKER |
| **No role escalation** | Verify users cannot access resources above their permission level | 🔴 BLOCKER |
| **Ownership verification** | Users can only modify their own resources (unless admin) | 🔴 BLOCKER |

---

## 4. Injection Prevention

### SQL Injection

| Check | Rule | Severity |
|-------|------|----------|
| **Parameterized queries only** | All `@Query` annotations must use `:paramName` binding, never string concatenation | 🔴 BLOCKER |
| **No raw SQL** | No `EntityManager.createNativeQuery()` with concatenated strings | 🔴 BLOCKER |
| **JPA Criteria API** | If dynamic queries are needed, use JPA Criteria API or Specifications | 🟢 BEST PRACTICE |

```java
// CORRECT: Parameterized query
@Query("SELECT u FROM User u WHERE u.email = :email")
Optional<User> findByEmail(@Param("email") String email);

// WRONG: String concatenation (SQL injection risk)
@Query("SELECT u FROM User u WHERE u.email = '" + email + "'") // ← NEVER
```

### XSS (Cross-Site Scripting)

| Check | Rule | Severity |
|-------|------|----------|
| **Sanitize frontend inputs** | All user-provided text must be escaped before rendering in DOM | 🔴 BLOCKER |
| **Use `v-text` not `v-html`** | Vue templates must use `v-text` or `{{ }}` (auto-escaped), never `v-html` with user data | 🔴 BLOCKER |
| **Content-Type headers** | API responses must set correct `Content-Type` headers | 🟡 WARNING |

### CSRF (Cross-Site Request Forgery)

| Check | Rule | Severity |
|-------|------|----------|
| **CSRF token handling** | State-changing endpoints must validate CSRF tokens (if session-based auth) | 🟡 WARNING |
| **SameSite cookies** | Session cookies must have `SameSite=Strict` or `SameSite=Lax` | 🟡 WARNING |
| **JWT exception** | If using stateless JWT auth, CSRF protection may be relaxed (document justification) | 🟢 BEST PRACTICE |

---

## 5. Dependency Security

### Vulnerability Scanning

| Check | Rule | Severity |
|-------|------|----------|
| **No known CVEs** | `mvn dependency-check:check` or `npm audit` must report zero HIGH/CRITICAL CVEs | 🔴 BLOCKER |
| **No unnecessary dependencies** | Every dependency in `pom.xml` or `package.json` must be justified | 🟡 WARNING |
| **Transitive dependency audit** | Check transitive dependencies for known vulnerabilities | 🟡 WARNING |
| **Version pinning** | All dependencies must have explicit version numbers (no `LATEST` or `RELEASE`) | 🟢 BEST PRACTICE |

### Commands

```bash
# Java/Maven
mvn org.owasp:dependency-check-maven:check

# Node/npm
npm audit --audit-level=high

# Node/yarn
yarn audit --level high
```

---

## 6. Security Test Requirements

### Mandatory Security Tests

Every code change that modifies endpoints or security configuration MUST include:

```java
// Test: Unauthorized access returns 403
@Test
void should_return403_whenUserLacksRequiredRole() {
    // Given
    var token = generateTokenForRole("ROLE_USER"); // insufficient role

    // When
    var result = mockMvc.perform(post("/api/admin/users")
            .header("Authorization", "Bearer " + token)
            .contentType(MediaType.APPLICATION_JSON)
            .content(validRequestBody()));

    // Then
    result.andExpect(status().isForbidden());
}

// Test: Unauthenticated access returns 401
@Test
void should_return401_whenNoAuthToken() {
    // When
    var result = mockMvc.perform(get("/api/users"));

    // Then
    result.andExpect(status().isUnauthorized());
}

// Test: Role escalation is impossible
@Test
void should_return403_whenUserTriesToAccessOtherUsersData() {
    // Given
    var userAToken = generateTokenForUser("user-a");

    // When
    var result = mockMvc.perform(get("/api/users/user-b/profile")
            .header("Authorization", "Bearer " + userAToken));

    // Then
    result.andExpect(status().isForbidden());
}
```

---

## Work Type Variants

| Work Type | Security Review Scope | Depth | Output |
|-----------|----------------------|-------|--------|
| **Story** | Full review of all new/modified endpoints, RBAC, data flows | Deep | Security Audit Report (full checklist) |
| **Bug** | Verify the fix does NOT introduce new vulnerabilities | Targeted | Security Audit Report (targeted checks) |
| **Improvement** | Re-audit refactored security boundaries, verify no regressions | Medium | Security Audit Report (regression focus) |
| **Epic** | Security architecture review document for the feature | Strategic | Security Architecture Review |

---

## Output Artifact

This phase produces a **Security Audit Report**:

```markdown
# Security Audit Report — [TICKET-ID]: [Title]

## Summary
- **Auditor:** sdlc-security-gate
- **Date:** [date]
- **Verdict:** ✅ PASS / ❌ FAIL / ⚠️ CONDITIONAL PASS

## Endpoint Security
| Endpoint | Method | Auth | Roles | Status |
|----------|--------|------|-------|--------|
| ... | ... | ... | ... | ✅/❌ |

## Data Protection
- [ ] No PII in logs
- [ ] Inputs validated
- [ ] Error responses sanitized
- [ ] No hardcoded secrets

## RBAC
- [ ] Role constants used
- [ ] Authorized paths tested
- [ ] Unauthorized paths tested (403)
- [ ] Ownership verification in place

## Injection Prevention
- [ ] Parameterized queries only
- [ ] No v-html with user data
- [ ] CSRF handled

## Dependencies
- [ ] No HIGH/CRITICAL CVEs
- [ ] No unnecessary dependencies

## Security Tests
- [ ] 403 tests present
- [ ] 401 tests present
- [ ] Role escalation tests present

## Blockers Found
(list any BLOCKER-severity issues that must be resolved)

## Recommendations
(list any WARNING or BEST PRACTICE suggestions)
```

### Verdict Rules

| Verdict | Condition |
|---------|-----------|
| ✅ **PASS** | Zero BLOCKER issues found |
| ⚠️ **CONDITIONAL PASS** | Zero BLOCKERs, but WARNING items should be addressed |
| ❌ **FAIL** | One or more BLOCKER issues found — code MUST be fixed before proceeding |

---

## Related skills

A FAIL verdict sends the work back to `sdlc-developer-backend` / `sdlc-developer-frontend`; re-audit after the fix. The code reviewers are a separate concern and can run independently.

> This skill is loaded on demand. There is no phase pipeline and no automatic hand-off —
> the SDLC dispatcher was retired on 2026-08-14 (see `~/.gemini/config/skills-retired/README.md`).
> Load the next skill only if the work actually calls for it.
