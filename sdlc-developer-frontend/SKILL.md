---
name: sdlc-developer-frontend
description: "SDLC Phase 3 — Frontend Developer (Vue/TypeScript). Implements UI components, store logic, and client-side features following the Green Phase TDD approach. Triggers on: 'implement frontend', 'vue', 'typescript', 'component', 'store', 'pinia', 'UI', 'frontend implementation', 'dashboard'."
---

# SDLC Phase 3 — Frontend Developer (Vue/TypeScript)

> The Green Phase: Implement components and store logic to pass failing tests.

## Pipeline Position

Standalone. Load on demand; nothing chains into or out of it.

---

## The Green Phase (Frontend)

### Core Principle

> Implement ONLY what the tests demand. Every line of code must be justified by a failing test.

### Rules

1. **YAGNI** — Do not add UI elements, props, or store actions that no test exercises.
2. **Component-first** — Build from the smallest component upward. Leaf components first, then composites.
3. **Type-safe** — Every prop, emit, ref, and computed must have explicit TypeScript types. No `any`.
4. **Testable** — Components must be testable in isolation. Inject dependencies, don't hardcode them.

### Implementation Sequence

1. Run the failing test suite — confirm all tests are RED
2. Pick the simplest failing test (usually a leaf component)
3. Write the minimum component/store code to make it pass
4. Run the test — confirm it is GREEN
5. Refactor if needed (no behavior change, tests stay green)
6. Repeat until all tests are GREEN
7. Run the full test suite — confirm 100% GREEN

---

## Vue / TypeScript Standards

### Composition API (Preferred)

```vue
<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useUserStore } from '@/stores/userStore';
import type { User } from '@/types/User';

// Props
const props = defineProps<{
  userId: string;
  readonly?: boolean;
}>();

// Emits
const emit = defineEmits<{
  (e: 'update', user: User): void;
  (e: 'cancel'): void;
}>();

// State
const isLoading = ref(false);
const userStore = useUserStore();

// Computed
const displayName = computed(() => {
  const user = userStore.currentUser;
  return user ? `${user.firstName} ${user.lastName}` : '';
});

// Lifecycle
onMounted(() => {
  loadUser();
});
</script>
```

### Type Safety Rules

1. **No `any` type.** Use `unknown` if the type is genuinely unknown, then narrow with type guards.
2. **Define interfaces** for all data shapes in `@/types/` directory.
3. **Use type-only imports** for types: `import type { User } from '@/types/User'`
4. **Readonly injected members.** Mark injected services and store references as `readonly`.

```typescript
// CORRECT
const userStore = useUserStore(); // Composition API — naturally scoped

// WRONG
const data: any = response.data; // ← NO: any
```

5. **Enums** — Prefer `const` objects or union types over TypeScript `enum`:

```typescript
// PREFERRED
const UserStatus = {
  ACTIVE: 'ACTIVE',
  INACTIVE: 'INACTIVE',
  SUSPENDED: 'SUSPENDED',
} as const;

type UserStatus = typeof UserStatus[keyof typeof UserStatus];
```

---

## Component Guidelines

### Small, Reusable Components

- **Single Responsibility** — Each component does ONE thing well
- **Max template size** — If the `<template>` exceeds ~80 lines, extract child components
- **Prop drilling limit** — If props pass through 3+ levels, use provide/inject or a store

### Props Validation

```vue
<script setup lang="ts">
// CORRECT: Fully typed props with defaults
const props = withDefaults(defineProps<{
  title: string;
  count: number;
  variant?: 'primary' | 'secondary' | 'danger';
}>(), {
  variant: 'primary',
});
</script>
```

### Event Listener Cleanup

Prevent memory leaks by always cleaning up manual event listeners:

```vue
<script setup lang="ts">
import { onMounted, onUnmounted } from 'vue';

const handleResize = () => {
  // ... handle window resize
};

onMounted(() => {
  window.addEventListener('resize', handleResize);
});

onUnmounted(() => {
  window.removeEventListener('resize', handleResize);
});
</script>
```

### Rules

1. **Always clean up** — `onUnmounted` must mirror `onMounted` for manual listeners, intervals, subscriptions
2. **Use `v-if` vs `v-show` correctly** — `v-if` for conditional render, `v-show` for frequent toggle
3. **Key bindings** — Always use `:key` on `v-for` with stable, unique identifiers (never index)
4. **No inline complex logic** in templates — Extract to `computed` or methods

---

## State Management

### Pinia Store Pattern

```typescript
// stores/userStore.ts
import { defineStore } from 'pinia';
import { userApi } from '@/api/userApi';
import type { User } from '@/types/User';

export const useUserStore = defineStore('user', {
  state: () => ({
    users: [] as User[],
    currentUser: null as User | null,
    isLoading: false,
    error: null as string | null,
  }),

  getters: {
    activeUsers: (state) => state.users.filter(u => u.status === 'ACTIVE'),
    userCount: (state) => state.users.length,
  },

  actions: {
    async fetchUsers() {
      this.isLoading = true;
      this.error = null;
      try {
        this.users = await userApi.getAll();
      } catch (err) {
        this.error = err instanceof Error ? err.message : 'Failed to fetch users';
      } finally {
        this.isLoading = false;
      }
    },
  },
});
```

### State Management Rules

1. **No direct API calls in components.** All API calls go through store actions or dedicated composables.
2. **Store actions handle errors.** Components read `store.error` for display.
3. **Loading states live in stores.** Components read `store.isLoading` for spinners/skeletons.
4. **Mutations are explicit.** Direct state mutation is allowed in Pinia actions only.
5. **No cross-store direct access.** If Store A needs data from Store B, compose at the component level or use a dedicated composable.

---

## API Integration

### API Layer Pattern

```typescript
// api/userApi.ts
import { httpClient } from '@/api/httpClient';
import type { User, CreateUserRequest } from '@/types/User';

export const userApi = {
  getAll: (): Promise<User[]> =>
    httpClient.get('/api/users').then(res => res.data),

  getById: (id: string): Promise<User> =>
    httpClient.get(`/api/users/${id}`).then(res => res.data),

  create: (request: CreateUserRequest): Promise<User> =>
    httpClient.post('/api/users', request).then(res => res.data),
};
```

### Rules

1. **Centralized HTTP client** with interceptors for auth tokens, error handling, and base URL
2. **Type-safe API responses** — Always type the return value
3. **No raw `axios`/`fetch` in components or stores** — Always go through the API layer

---

## Formatting & Linting

### Pre-Commit Checklist

Before every commit, run:

```bash
# Format all files
npx prettier --write "src/**/*.{ts,vue,css,json}"

# Lint and auto-fix
npm run lint -- --fix

# Run tests
npm run test

# Type check
npx vue-tsc --noEmit
```

### Rules

1. **Prettier** is the single source of formatting truth. No manual formatting overrides.
2. **ESLint** enforces code quality rules. Zero warnings allowed in CI.
3. **vue-tsc** ensures full type safety across templates and scripts.
4. **All three must pass** before a commit is created.

---

## Work Type Variants

| Work Type | Green Phase | Quality Gates | Notes |
|-----------|-------------|---------------|-------|
| **Story** | Full component + store + API integration | All gates mandatory | Implement from architect contracts + pass all QA tests |
| **Bug** | Minimal fix to pass the reproducing test | All gates mandatory | Change as few lines as possible |
| **Improvement** | Refactor with test coverage safety net | All gates mandatory | All existing tests must stay GREEN throughout |
| **Epic** | N/A — delegated to subtask stories | N/A | Epic-level work is decomposed, not implemented directly |

---

## Output Artifact

This phase produces:

1. **Vue components** (`.vue` files) that render correctly and pass all tests
2. **Store modules** (Pinia stores) with typed state, getters, and actions
3. **API layer** (typed HTTP calls) integrated with the backend
4. **Full test suite execution report** — 100% pass rate

The code MUST:
- Pass TypeScript compilation (`vue-tsc --noEmit` — zero errors)
- Pass all tests (`npm run test` — 100% GREEN)
- Pass linting (`npm run lint` — zero violations)
- Pass formatting (`npx prettier --check` — zero issues)

---

## Related skills

Once tests are GREEN, `sdlc-security-gate` audits XSS, input sanitization, token handling and role-based visibility, and `sdlc-code-reviewer-frontend` covers types, lifecycle and accessibility.

> This skill is loaded on demand. There is no phase pipeline and no automatic hand-off —
> the SDLC dispatcher was retired on 2026-08-14 (see `~/.gemini/config/skills-retired/README.md`).
> Load the next skill only if the work actually calls for it.
