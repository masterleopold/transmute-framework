---
description: Template for testing rules — E2E selectors, eventually-consistent assertions, test isolation, credential handling, and test data management for the testing framework.
globs: ["[TEST_DIR]/**", "**/*.test.*", "**/*.spec.*"]
---

# Testing Rules

> **This is a template.** Stage 3 (Scaffold Generation) reads this template and generates `.claude/rules/testing.md` with actual project values. Stage 3 MUST: (1) replace ALL `[BRACKETED]` placeholder markers (e.g., `[TEST_DIR]`, `[TEST_RUNNER]`), (2) replace each `<!-- TODO -->` HTML comment with a proper `<!-- Source: Stage 3 | Evidence: [ref] | Confidence: HIGH -->` annotation (`// TODO:` inside code blocks are code example placeholders — replace those with actual code patterns), and (3) update the globs in frontmatter with actual paths. Stage 4 confirms replacements are complete. After Stage 3 renders this template, verify no placeholders remain: `grep -n '\[.*\]' .claude/rules/testing.md` — the output should be empty (all `[BRACKETED]` markers replaced with actual values). Do not edit this template directly.

## Selectors

<!-- Source: Stage 3 | Evidence: tech-stack.md | Confidence: HIGH -->

- Per CLAUDE.md Part 1 E2E Tests, prefer `getByRole` and `getByText` over CSS class selectors or test IDs — use `getByTestId` only when no accessible role or text is available.
- Never select by CSS class names — they change with styling updates; for complex components, add `aria-label` to make them queryable by role.

```typescript
// TODO: Replace with actual selector examples
// GOOD: page.getByRole("button", { name: "Create Task" })
// GOOD: page.getByText("No tasks yet")
// AVOID: page.locator(".btn-primary")
// LAST RESORT: page.getByTestId("task-list-container")
```

## Eventually-Consistent Assertions

<!-- TODO: Stage 3 — replace with actual async assertion pattern for [BACKEND_FRAMEWORK]. Source: tech-stack.md | Confidence: HIGH -->

- Per CLAUDE.md Part 1 E2E Tests, use async assertion patterns for eventually-consistent backends (Playwright: `expect.poll()`/`expect.toPass()`; Jest/Vitest: custom polling helper) — additionally, never use `page.waitForTimeout()` as a substitute.
- Set reasonable polling intervals and timeouts based on expected backend latency:
  - `expect.poll()`: periodic UI checks — use `{ timeout: 10000, intervals: [100, 200, 500] }` for exponential backoff
  - `expect.toPass()`: complex multi-step assertions — use `{ timeout: 10000 }` for multi-condition checks
  - Local dev: 2–5s timeout. Cloud backends (Convex, Supabase, Firebase): 10–15s timeout.

```typescript
// TODO: Replace with actual eventually-consistent pattern
// await expect.poll(async () => {
//   return await page.getByRole("listitem").count();
// }, { timeout: 10000 }).toBeGreaterThan(0);
```

## Test Isolation

<!-- TODO: Stage 3 — replace with actual setup/teardown pattern -->

- Each test must not depend on state from previous tests — use `beforeEach` to set up required state and `afterEach` to clean up if needed.
- For E2E tests, use unique identifiers (timestamps, UUIDs) to avoid collisions; prefer creating fresh test data over relying on seed data.

## Component Testing

<!-- TODO: Stage 3 — replace with actual component test patterns for [TEST_RUNNER] -->

- Per CLAUDE.md Part 1 Component Tests, test all five states (default, loading, empty, error, disabled) for every component.
- Include axe-core accessibility checks (`[AXE_INTEGRATION]`) in component tests (WCAG AA level minimum; upgrade to AAA if PRD requires it). Framework-specific: Next.js+Jest → `jest-axe`, Vite+Vitest → `@axe-core/react`, Playwright E2E → `@axe-core/playwright`.
- Mock backend hooks (`[HOOK_MOCK_PATTERN]`), not the API layer directly — this tests the component's behavior without coupling to API implementation details.

## Credentials

<!-- TODO: Stage 3 — replace with actual test constants location -->

- Never hardcode credentials in test files — reference test credentials from `[TEST_CONSTANTS_PATH]` (e.g., `e2e/constants.ts`); never log, commit, or share credential values.
- Use separate test accounts for each test suite to avoid auth state leakage.

## Test Data

<!-- TODO: Stage 3 — replace with actual seed/factory pattern -->

- Use seed data scripts or factory functions to generate test data — never use production data in tests.
- Factories should produce minimal valid objects — override only the fields relevant to each test.
- For E2E tests, use the project's seed commands (`[SEED_COMMAND]` — see CLAUDE.md Part 2 § Commands for actual command) to set up baseline data.
