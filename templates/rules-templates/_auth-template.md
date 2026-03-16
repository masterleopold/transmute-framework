---
description: Template for auth rules — middleware configuration, public route whitelisting, session handling, and role-based authorization.
globs: ["[AUTH_DIR]/**", "[MIDDLEWARE_PATH]"]
---

# Auth Rules

> **This is a template.** Glob note: the first glob pattern matches the auth directory recursively, the second matches a single middleware file (e.g., `middleware.ts`). Stage 3 (Scaffold Generation) reads this template and generates `.claude/rules/auth.md` with actual project values. Stage 3 MUST: (1) replace ALL `[BRACKETED]` placeholder markers (e.g., `[AUTH_HELPER]`, `[AUTH_DIR]`, `[MIDDLEWARE_PATH]`, `[PUBLIC_ROUTES_CONFIG]`, `[SESSION_PATTERN]`, `[TOKEN_STORAGE]`, `[PERMISSION_MODEL]`, `[ROLE_DEFINITIONS_PATH]`, `[ERROR_TYPE]` — must match the value in `.claude/rules/backend.md` § Error Handling), (2) replace each `<!-- TODO -->` HTML comment with a proper `<!-- Source: Stage 3 | Evidence: [ref] | Confidence: HIGH -->` annotation (`// TODO:` inside code blocks are code example placeholders — replace those with actual code patterns), (3) update the globs in frontmatter with actual paths, and (4) remove ALL other HTML comments (e.g., `<!-- Glob note: ... -->`) — these are template-only guidance that must not appear in generated rule files. Stage 4 confirms replacements are complete. After Stage 3 renders this template, verify no placeholders remain: `grep -nE '\[[A-Z_]+\]' .claude/rules/auth.md` — the output should be empty (all `[BRACKETED]` markers replaced with actual values). Do not edit this template directly — edit the generated `.claude/rules/auth.md` instead.

## Public Routes

<!-- TODO: Stage 3 — replace with actual public route configuration for [AUTH_DIR]. Source: tech-stack.md | Confidence: HIGH -->

- Add routes to the public whitelist EXPLICITLY in `[PUBLIC_ROUTES_CONFIG]` — never use wildcard patterns (e.g., `/api/*`).
- Every new public route must have a comment explaining why it is public.
- Review the public route list during every security audit.

```typescript
// TODO: Replace with actual public route configuration
// const publicRoutes = [
//   "/",              // Landing page
//   "/sign-in",       // Authentication page
//   "/sign-up",       // Registration page
//   "/api/webhooks",  // External webhook endpoints (verified by signature)
// ];
```

## Auth Guards

<!-- TODO: Stage 3 — replace with actual middleware and auth check pattern. Source: tech-stack.md | Confidence: HIGH -->

- Protected routes must verify BOTH authentication (is the user logged in?) AND authorization (does the user have permission?).
- Middleware at `[MIDDLEWARE_PATH]` handles route-level auth gating.
- Backend functions handle resource-level authorization (e.g., "does this user own this record?").
- Never rely solely on frontend route guards — always enforce auth on the backend.

## Session Handling

<!-- TODO: Stage 3 — replace with session pattern (e.g., JWT in httpOnly cookie, server session, OAuth token). Specify where tokens are stored (httpOnly cookie, not localStorage). Source: tech-stack.md | Confidence: HIGH -->

- Follow the project's session pattern: `[SESSION_PATTERN]`.
- Session tokens must be stored in `[TOKEN_STORAGE]` (e.g., httpOnly cookies, not localStorage).
- Handle token expiration gracefully — redirect to sign-in with a return URL; never expose session tokens in URLs, logs, or error messages.

## Role Checks

<!-- TODO: Stage 3 — replace with actual role/permission model. Source: tech-stack.md, BRD security requirements | Confidence: HIGH -->

- **Permission model**: `[PERMISSION_MODEL]` (e.g., RBAC, ABAC, or Custom) — see `[ROLE_DEFINITIONS_PATH]` for the authoritative role/permission list.
- Verify role or permission before allowing mutations that modify shared resources.
- Role definitions live in `[ROLE_DEFINITIONS_PATH]`. Roles are scoped per-tenant — a user can have different roles in different organizations.
- Use the principle of least privilege — default to denied, explicitly grant access.
- Multi-tenant resources must verify that the authenticated user belongs to the target tenant.

```typescript
// TODO: Replace with actual role check pattern
// [ERROR_TYPE] must match the value in .claude/rules/backend.md § Error Handling
// const member = await getMembership(ctx, { userId: identity.id, orgId });
// if (member.role !== "admin") throw new [ERROR_TYPE]({ code: "FORBIDDEN" });
```
