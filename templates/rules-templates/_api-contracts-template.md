---
description: Template for API contract rules — ensures frontend types match backend responses; coordinates field mapping, projections, and type alignment between frontend and backend.
globs: ["[BACKEND_DIR]/**", "[HOOKS_DIR]/**", "[FRONTEND_TYPES_DIR]/**"]
---

# API Contract Rules

> **This is a template.** Stage 3 (Scaffold Generation) reads this template and generates `.claude/rules/api-contracts.md` with actual project values. Stage 3 MUST: (1) replace ALL `[BRACKETED]` placeholder markers (e.g., `[BACKEND_DIR]`, `[HOOKS_DIR]`), (2) replace each `<!-- TODO -->` HTML comment with a proper `<!-- Source: Stage 3 | Evidence: [ref] | Confidence: HIGH -->` annotation (`// TODO:` inside code blocks are code example placeholders — replace those with actual code patterns), and (3) update the globs in frontmatter with actual paths. Stage 4 confirms replacements are complete. Do not edit this template directly.

## Type Alignment

<!-- Source: Stage 3 | Evidence: tech-stack.md | Confidence: HIGH -->

- Enforce CLAUDE.md Part 1 "API Contract Alignment" rules using these project-specific paths:
- Backend response types live in `[BACKEND_DIR]` — frontend types that mirror them live in `[HOOKS_DIR]` or `[FRONTEND_TYPES_DIR]`.
- When the backend adds or removes a field, update the frontend type in the same PR.
- Run type checking (`[TYPECHECK_COMMAND]`) before committing any API-related change.

## Projection Types

<!-- TODO: Stage 3 — replace with actual projection pattern -->

- Create SEPARATE types for different views of the same entity:
  - List view: lightweight projection (e.g., `[ENTITY]Summary`) with only the fields displayed in lists.
  - Detail view: full projection (e.g., `[ENTITY]Detail`) with all fields.
  - Form view: input type (e.g., `[ENTITY]Input`) matching the mutation arguments.
- Never use the full schema type for list views — it fetches unnecessary data and creates coupling.

```typescript
// TODO: Replace with actual projection types
// type TaskSummary = { id: string; title: string; status: string; };
// type TaskDetail = TaskSummary & { description: string; assignee: UserSummary; comments: Comment[]; };
// type TaskInput = { title: string; description?: string; priority: Priority; };
```

## Field Mapping

<!-- TODO: Stage 3 — replace with actual field mapping examples -->

- When the backend returns renamed or computed fields, hooks MUST map them explicitly.
- Never use `as unknown as Type` casts to force type compatibility.
- Document any field name divergence between backend and frontend with a comment.

```typescript
// TODO: Replace with actual mapping pattern
// Backend returns `_id`, frontend expects `id`:
// const mapped = { id: raw._id, ...rest };
// NOT: const mapped = raw as unknown as FrontendType;
```

## Null Handling

<!-- TODO: Stage 3 — replace with actual loading/null patterns -->

- Distinguish between `undefined` (not yet loaded → show loading), `null` (intentionally absent → show empty/default), and present values — never treat them as interchangeable.
- Backend functions must return `null` (not `undefined`) for "not found" responses to make the distinction explicit.
- Frontend components must handle all three states separately in their render logic.
