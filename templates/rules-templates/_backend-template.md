---
description: Template for backend rules — argument validation, error handling, auth guards, query filtering, and index usage for the backend framework.
globs: ["[BACKEND_DIR]/**"]
---

# Backend Rules

> **This is a template.** Stage 3 (Scaffold Generation) reads this template and generates `.claude/rules/backend.md` with actual project values. Stage 3 MUST: (1) replace ALL `[BRACKETED]` placeholder markers (e.g., `[BACKEND_DIR]`, `[ERROR_TYPE]`), (2) replace each `<!-- TODO -->` HTML comment with a proper `<!-- Source: Stage 3 | Evidence: [ref] | Confidence: HIGH -->` annotation (`// TODO:` inside code blocks are code example placeholders — replace those with actual code patterns), and (3) update the globs in frontmatter with actual paths. Stage 4 confirms replacements are complete. Do not edit this template directly — edit the generated `.claude/rules/backend.md` instead.

## Validation

<!-- Source: Stage 3 | Evidence: tech-stack.md | Confidence: HIGH -->

- Always validate arguments using `[VALIDATOR_SYSTEM]` before any business logic — define argument schemas co-located with the function, not inline.
- Validate at the boundary (mutation/action entry point), not deep inside helpers.

```typescript
// TODO: Replace with actual validation pattern for [BACKEND_FRAMEWORK]
// Example:
// args: { title: v.string(), priority: v.union(v.literal("P0"), v.literal("P1")) }
```

## Error Handling

<!-- TODO: Stage 3 — replace with actual error type -->

- Use `[ERROR_TYPE]` for all user-facing errors — never throw raw strings; include an error code and a human-readable message in every error.
- Log internal errors with context (function name, arguments) before re-throwing — never expose internal stack traces or database details in error responses.

```typescript
// TODO: Replace with actual error pattern
// throw new [ERROR_TYPE]({ code: "NOT_FOUND", message: "Task not found" });
```

## Auth Guards

<!-- TODO: Stage 3 — replace with actual auth helper -->

- Every mutation and action must call `[AUTH_HELPER]` as the first operation — never skip auth checks, even for "internal" functions.
- Store the authenticated user identity in a local variable and pass it explicitly to helpers.

```typescript
// TODO: Replace with actual auth guard pattern
// const identity = await [AUTH_HELPER](ctx);
// if (!identity) throw new [ERROR_TYPE]({ code: "UNAUTHENTICATED" });
```

## Query Filters

<!-- TODO: Stage 3 — replace with actual soft-delete field and filter pattern -->

- Always apply soft-delete filter (`[SOFT_DELETE_FIELD] === null` or equivalent) on all queries (see data-model rules for field name).
- Never return soft-deleted records to the frontend unless explicitly requested by an admin view.
- Apply tenant isolation filters (org/workspace scoping) on every query.

## Index Usage

<!-- TODO: Stage 3 — replace with actual index definition pattern -->

- Prefer indexed queries over full-table scans for any collection with >100 expected records.
- Every query pattern must have a supporting index — see data-model rules § Indexes for definition patterns and conventions.
- When adding a new query pattern, add the supporting index in the same commit.
