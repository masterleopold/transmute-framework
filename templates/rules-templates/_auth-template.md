---
description: Template for auth rules — middleware configuration, public route whitelisting, session handling, and role-based authorization.
globs: ["[AUTH_DIR]/**", "[MIDDLEWARE_PATH]"]
---

# Auth Rules

> **This is a template.** Stage 3 (Scaffold Generation) reads this template and generates `.claude/rules/auth.md` with actual project values. Stage 3 MUST: (1) replace ALL `[BRACKETED]` placeholder markers (e.g., `[AUTH_HELPER]`, `[MIDDLEWARE_PATH]`), (2) replace each `<!-- TODO -->` HTML comment with a proper `<!-- Source: Stage 3 | Evidence: [ref] | Confidence: HIGH -->` annotation (`// TODO:` inside code blocks are code example placeholders — replace those with actual code patterns), and (3) update the globs in frontmatter with actual paths. Stage 4 confirms replacements are complete. Do not edit this template directly.

## Public Routes

<!-- Source: Stage 3 | Evidence: tech-stack.md | Confidence: HIGH -->

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

<!-- TODO: Stage 3 — replace with actual middleware and auth check pattern -->

- Protected routes must verify BOTH authentication (is the user logged in?) AND authorization (does the user have permission?).
- Middleware at `[MIDDLEWARE_PATH]` handles route-level auth gating.
- Backend functions handle resource-level authorization (e.g., "does this user own this record?").
- Never rely solely on frontend route guards — always enforce auth on the backend.

## Session Handling

<!-- TODO: Stage 3 — replace with session pattern (e.g., JWT in httpOnly cookie, server session, OAuth token). Specify where tokens are stored (httpOnly cookie, not localStorage). -->

- Follow the project's session pattern: `[SESSION_PATTERN]`.
- Session tokens must be stored in `[TOKEN_STORAGE]` (e.g., httpOnly cookies, not localStorage).
- Handle token expiration gracefully — redirect to sign-in with a return URL.
- Never expose session tokens in URLs, logs, or error messages.

## Role Checks

<!-- TODO: Stage 3 — replace with actual role/permission model -->

- Verify role or permission before allowing mutations that modify shared resources.
- Role definitions live in `[ROLE_DEFINITIONS_PATH]`.
- Use the principle of least privilege — default to denied, explicitly grant access.
- Multi-tenant resources must verify that the authenticated user belongs to the target tenant.

```typescript
// TODO: Replace with actual role check pattern
// const member = await getMembership(ctx, { userId: identity.id, orgId });
// if (member.role !== "admin") throw new [ERROR_TYPE]({ code: "FORBIDDEN" });
```
