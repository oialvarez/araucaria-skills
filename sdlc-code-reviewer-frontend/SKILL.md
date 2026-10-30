---
name: sdlc-code-reviewer-frontend
description: "SDLC Phase 5 — Frontend Code Reviewer & Auditor. Reviews Vue/TypeScript code against ESLint, formatting, component patterns, accessibility, and staff-level PR review standards. Triggers on: 'review frontend', 'frontend review', 'vue review', 'typescript review', 'PR review frontend', 'eslint', 'component review'."
---

# SDLC Phase 5 — Frontend Code Reviewer & Auditor

The Refactor Phase (Frontend). Clean, DRY, accessible components. This skill reviews Vue/TypeScript frontend code against ESLint rules, formatting standards, component lifecycle patterns, accessibility requirements, performance considerations, and staff-level PR review protocols.

## Pipeline Position

Standalone. Load on demand; nothing chains into or out of it.

---

## 1. The Refactor Phase (Frontend)

The component works. Tests pass. Now make it **clean, accessible, and performant**.

### Refactor Checklist

1. **Read every changed file** end-to-end — components, stores, composables, types
2. **Apply ESLint + Prettier** (see §3)
3. **Check component lifecycle** — are event listeners cleaned up?
4. **Verify typing** — no `any` types, proper interfaces/types defined
5. **Accessibility audit** — ARIA labels, keyboard navigation, contrast
6. **Simplify** — if a computed property needs a comment, rename or extract

> [!IMPORTANT]
> The Refactor Phase is NOT optional. A component that "just works" is not done.

---

## 2. Vue/TypeScript Quality

### Readonly Injected Members

All injected dependencies **must** be `readonly`:

```typescript
// BAD — mutable injected member
export default defineComponent({
  setup() {
    const callService = inject<CallService>('callService');
    // callService could be reassigned
  }
});

// GOOD — readonly injected member
export default defineComponent({
  setup() {
    const callService = inject<CallService>('callService') as CallService;
    // Use readonly ref if storing
    const service: Readonly<CallService> = callService;
  }
});
```

### Proper Typing

```typescript
// BAD — any types
const handleEvent = (event: any) => { ... }
const data: any = response.data;

// GOOD — explicit types
interface CallEvent {
  callId: string;
  status: CallStatus;
  timestamp: Date;
}
const handleEvent = (event: CallEvent) => { ... }
const data: CallResponse = response.data;
```

### Component Lifecycle Cleanup

```typescript
// BAD — event listener leak
onMounted(() => {
  window.addEventListener('resize', handleResize);
  document.addEventListener('keydown', handleKeyDown);
});
// Missing onUnmounted cleanup!

// GOOD — proper cleanup
onMounted(() => {
  window.addEventListener('resize', handleResize);
  document.addEventListener('keydown', handleKeyDown);
});

onUnmounted(() => {
  window.removeEventListener('resize', handleResize);
  document.removeEventListener('keydown', handleKeyDown);
});
```

### Modal-Specific Cleanup

Modals are a common source of event listener leaks:

```typescript
// GOOD — modal with proper cleanup
const showModal = ref(false);

watch(showModal, (isVisible) => {
  if (isVisible) {
    document.addEventListener('keydown', handleEscape);
  } else {
    document.removeEventListener('keydown', handleEscape);
  }
});

onUnmounted(() => {
  document.removeEventListener('keydown', handleEscape);
});
```

---

## 3. Formatting & Linting

### Prettier Compliance

Before any commit, run:

```bash
npx prettier --write <file-or-directory>
```

- Single quotes for strings
- Trailing commas in multiline structures
- 2-space indentation
- 100 character print width (or project-configured width)

### ESLint Compliance

```bash
npm run lint
# or
npx eslint --fix <file-or-directory>
```

### Common Violations to Flag

| Rule | Description | Fix |
|------|-------------|-----|
| `no-unused-vars` | Declared but unused variables | Remove them |
| `@typescript-eslint/no-explicit-any` | Usage of `any` type | Define proper types |
| `vue/no-unused-components` | Imported but unused components | Remove imports |
| `vue/require-default-prop` | Props without defaults | Add default values |
| `vue/no-v-html` | XSS risk with `v-html` | Use text interpolation or sanitize |

---

## 4. Accessibility

### ARIA Labels

```html
<!-- BAD — no accessible label -->
<button @click="closeModal">
  <icon name="close" />
</button>

<!-- GOOD — accessible label -->
<button @click="closeModal" aria-label="Close dialog">
  <icon name="close" />
</button>
```

### Keyboard Navigation

- **All interactive elements** must be reachable via Tab key
- **Modals** must trap focus within the modal when open
- **Escape key** must close modals and dropdowns
- **Enter/Space** must activate buttons and links

### Color Contrast

- Text contrast ratio must meet WCAG AA (4.5:1 for normal text, 3:1 for large text)
- Do not rely on color alone to convey information — use icons, text, or patterns as supplements

---

## 5. Performance

### Lazy Loading

```typescript
// BAD — eager import of heavy component
import HeavyVideoPlayer from '@/components/HeavyVideoPlayer.vue';

// GOOD — lazy loading
const HeavyVideoPlayer = defineAsyncComponent(
  () => import('@/components/HeavyVideoPlayer.vue')
);
```

### Avoid Unnecessary Re-renders

```typescript
// BAD — new object created every render cycle
const style = computed(() => ({
  color: props.isActive ? 'green' : 'red',
  fontSize: '14px', // static — doesn't need to be in computed
}));

// GOOD — separate static and dynamic styles
const staticStyle = { fontSize: '14px' };
const dynamicColor = computed(() => props.isActive ? 'green' : 'red');
```

### Bundle Size Awareness

- **Audit imports** — don't import entire libraries for one utility function
- **Tree-shake** — use named imports: `import { debounce } from 'lodash-es'` not `import _ from 'lodash'`
- **Check bundle** — run `npm run build -- --report` periodically

---

## 6. PR Review Protocol

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
- **Ask, don't tell** — "Have you considered extracting this into a composable?" beats "You should use a composable"
- **Focus on the code, not the coder** — "This component could be simpler" not "You wrote this wrong"

### Review Focus Areas

1. **Correctness** — Does the component behavior match the ticket requirements?
2. **Accessibility** — Can all users interact with this component?
3. **Performance** — Are there unnecessary re-renders or heavy imports?
4. **Simplicity** — Is there a simpler way to achieve the same result?
5. **User Experience** — Does the UI feel responsive and polished?

### Review Checklist

- [ ] Event listeners cleaned up in `onUnmounted`
- [ ] No `any` types — proper TypeScript interfaces defined
- [ ] Prettier + ESLint pass with zero warnings
- [ ] ARIA labels on all interactive elements
- [ ] Keyboard navigation works for all interactive flows
- [ ] Lazy loading used for heavy components
- [ ] Scope matches the ticket — no unrelated changes

---

## Work Type Variants

| Work Type | Scope | Notes |
|-----------|-------|-------|
| **Story** | Full review + refactor + quality report | Standard pipeline |
| **Bug** | Full review + refactor + quality report | Extra attention to regression and UX edge cases |
| **Improvement** | Full review + refactor + quality report | Focus on before/after UX and performance |
| **Epic** | N/A | Delegated to subtask-level reviews |

---

## Output Artifact

### Quality Report (Frontend)

Produce a structured Quality Report containing:

```markdown
## Frontend Quality Report — [TICKET-ID]

### TypeScript Quality
- [ ] No `any` types
- [ ] Readonly injected members
- [ ] Proper interfaces/types defined

### Component Lifecycle
- [ ] Event listeners cleaned up in onUnmounted
- [ ] Modal focus trapping implemented
- [ ] Watchers cleaned up

### Formatting & Linting
- [ ] Prettier compliance (zero issues)
- [ ] ESLint compliance (zero warnings)

### Accessibility
- [ ] ARIA labels on interactive elements
- [ ] Keyboard navigation tested
- [ ] Color contrast meets WCAG AA

### Performance
- [ ] Lazy loading for heavy components
- [ ] No unnecessary re-renders
- [ ] Tree-shaken imports

### PR Review Summary
- [KUDOS] ...
- [SUGGESTION] ...
- [IMPORTANT] ...
- [CRITICAL] ...

### Verdict: ✅ PASS / ❌ FAIL
```

---

## Related skills

`sdlc-observability` covers logging and tracing concerns this review does not.

> This skill is loaded on demand. There is no phase pipeline and no automatic hand-off —
> the SDLC dispatcher was retired on 2026-08-14 (see `~/.gemini/config/skills-retired/README.md`).
> Load the next skill only if the work actually calls for it.
