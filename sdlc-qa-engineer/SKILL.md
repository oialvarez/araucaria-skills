---
name: sdlc-qa-engineer
description: "SDLC Phase 2 — QA Engineer. Designs test strategy, aligns with user/QA on test plan, and writes failing tests (Red Phase TDD). Triggers on: 'test', 'TDD', 'test design', 'test strategy', 'red phase', 'write tests', 'edge cases', 'test plan', 'coverage'."
---

# SDLC Phase 2 — QA Engineer

> Test Design Alignment + Red Phase TDD

## Pipeline Position

Standalone. Load on demand; nothing chains into or out of it.

---

## Phase 1: Test Design Alignment (MANDATORY GATE)

> **No test code may be written until the user explicitly approves the Test Design Plan.**

Before writing a single test, you MUST create and present a **Test Design Plan** for user/QA approval.

### Test Design Plan Template

Present the following plan to the user in a structured artifact:

```markdown
# Test Design Plan — [TICKET-ID]: [Title]

## 1. Scope & Targets
- **Parent points covered:** (each parent AC, or each Actual Behavior / repro point for a bug, and the test that covers it)
- **Classes/Methods under test:** (list each class and method)
- **Endpoints under test:** (list each REST endpoint, if any)
- **Test types required:** Unit / Slice / Integration (justify each)

## 2. Test Case Inventory

### Happy Path Tests
| # | Test Name | Input | Expected Output | Type |
|---|-----------|-------|-----------------|------|
| 1 | should_createUser_whenValidInput | valid DTO | 201 + user entity | Integration |

### Edge Case Tests
| # | Test Name | Condition | Expected Behavior | Type |
|---|-----------|-----------|-------------------|------|
| 1 | should_throwException_whenNullInput | null DTO | IllegalArgumentException | Unit |

### Security / Role Path Tests
| # | Test Name | Role | Expected Result | Type |
|---|-----------|------|-----------------|------|
| 1 | should_return403_whenUnauthorized | ROLE_USER | 403 Forbidden | Slice |

## 3. Mocking & Context Strategy
- **Mocked dependencies:** (list with justification)
- **Real dependencies:** (list with justification)
- **Test data setup:** (describe builders, fixtures, or factories)
- **Spring context:** (minimal slice vs full context)

## 4. Coverage Targets
- Line coverage target: ≥ 90%
- Branch coverage target: ≥ 85%
- Mutation testing: (if applicable)
```

### Process Gate

1. **Create** the Test Design Plan from the story ACs and architect skeleton
2. **Present** the plan to the user/QA for review
3. **Wait** for explicit approval (`"approved"`, `"looks good"`, `"proceed"`)
4. **Do NOT** write any test code until approval is received
5. If the user requests changes, update the plan and re-present

---

## Phase 2: The Red Phase (TDD)

Once the Test Design Plan is approved, write the failing test suite.

### Rules

1. **Tests MUST fail.** Every test should either fail to compile (missing implementation) or fail at assertion time. If a test passes immediately, it is suspect — question whether it tests real behavior.
2. **One assert per test.** Each test verifies exactly one behavior. Multiple assertions mask failures.
3. **Given / When / Then (BDD structure).** Every test method body follows this pattern:

```java
@Test
void should_returnUser_whenValidIdProvided() {
    // Given
    var userId = UUID.randomUUID();
    var expectedUser = UserFixture.validUser(userId);
    when(userRepository.findById(userId)).thenReturn(Optional.of(expectedUser));

    // When
    var result = userService.findById(userId);

    // Then
    assertThat(result).isEqualTo(expectedUser);
}
```

4. **Naming convention:** `should_[expectedBehavior]_when[condition]`
5. **No test logic.** Tests must not contain `if`, `for`, `while`, or `try/catch`. Tests are linear scripts.

### Test Categories

#### Acceptance Tests (from Story ACs)

- One or more tests per Acceptance Criterion
- Directly traceable: the test name or Javadoc references the AC number
- These are typically Integration or Slice tests

#### Edge Case Tests

- Null inputs → expect specific exception
- Empty collections → expect empty result or specific behavior
- Boundary values → min, max, zero, negative
- Duplicate entries → expect idempotency or conflict error
- Concurrent access → expect AtomicGuard protection (if applicable); seed the minimum data (one waiting item) so the losing thread cannot take a safe branch, and confirm the test fails with the fix reverted

#### Security / Role Path Tests

- Only required if the story modifies REST endpoints
- Test authorized access returns expected result
- Test unauthorized access returns 403
- Test role escalation is impossible

### Test Types Reference

| Type | Annotation | When to Use | Speed |
|------|-----------|-------------|-------|
| **Unit** | `@ExtendWith(MockitoExtension.class)` | Pure logic, no Spring context | Fast |
| **Slice** | `@WebMvcTest(Controller.class)` | Controller layer only | Medium |
| **Integration** | `@SpringBootTest` + `@AutoConfigureMockMvc` | Full flow, DB included | Slow |

### Integration Test Structure

```java
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class UserControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Test
    void should_createUser_whenValidInput() {
        // Given
        var request = UserFixture.validCreateRequest();

        // When
        var result = mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)));

        // Then
        result.andExpect(status().isCreated())
              .andExpect(jsonPath("$.id").exists());
    }
}
```

---

## Work Type Variants

| Work Type | Alignment Phase | Red Phase | Notes |
|-----------|----------------|-----------|-------|
| **Story** | Full Test Design Plan → approval gate | Full TDD: acceptance + edge + security tests | Every AC of the parent story (not just the subtask) must have corresponding tests |
| **Bug** | Minimal: describe the parent's Steps to Reproduce as written | Write one failing test per path that reaches the bug (see the parent coverage in `sdlc-discovery`) | Each test must fail before fix, pass after; manual testing starts from the parent's repro steps |
| **Improvement** | Regression scope only | Regression tests for refactored components | Ensure existing behavior is preserved |
| **Epic** | Full Test Strategy Document (no code) | No test code — strategy only | Defines testing approach for child stories |

---

## Output Artifact

This phase produces two deliverables:

1. **Test Design Plan** (Markdown artifact, approved by user/QA)
2. **Failing Test Suite** (Java test classes, all tests RED)

The test suite MUST:
- Compile (if implementation stubs exist from Architect phase)
- Fail all assertions (no green tests)
- Cover ≥ 90% of the planned test cases from the approved plan
- Follow the naming, structure, and BDD conventions above

---

## Related skills

With the RED suite in place, `sdlc-developer-backend` or `sdlc-developer-frontend` writes the minimal code to turn it GREEN.

> This skill is loaded on demand. There is no phase pipeline and no automatic hand-off —
> the SDLC dispatcher was retired on 2026-08-14 (see `~/.gemini/config/skills-retired/README.md`).
> Load the next skill only if the work actually calls for it.
