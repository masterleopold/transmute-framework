---
name: audit-security
description: >-
  Performs a multi-agent security audit checking authentication, input validation, data exposure, and infrastructure.
  This skill should be used when the user asks to "audit security",
  "run a security review", "check for vulnerabilities", "security scan",
  "check auth", "find security issues", or "harden security",
  or when the transmute-pipeline agent reaches Stage 6A of the pipeline.
version: 1.0.0
---

# Security Audit — Stage 6A

Lead a multi-agent security audit of the complete codebase against BRD security requirements and PRD security specifications. Identify vulnerabilities and fix them.

## Prerequisite Checks

Before any audit work, verify:

1. Check that `./plancasting/_audits/implementation-completeness/report.md` exists and shows PASS or CONDITIONAL PASS. If missing, warn that Stage 5B is unverified and proceed with caution — flag findings in stub/placeholder code separately. If FAIL, stop immediately and report that implementation gaps must be resolved first.
2. If CONDITIONAL PASS, read the documented Category C issues and skip security auditing for those incomplete features.
3. Read `./CLAUDE.md` and `./plancasting/tech-stack.md` for project conventions.
4. Read the relevant PRD sections for implementation context.

## Inputs

Read and reference these files throughout the audit:

- **Codebase**: Backend directory and `./src/` (adapt paths per tech stack)
- **Tech Stack**: `./plancasting/tech-stack.md`
- **Security Requirements**: `./plancasting/brd/13-security-requirements.md`
- **Compliance Requirements**: `./plancasting/brd/12-regulatory-and-compliance-requirements.md`
- **PRD Security Architecture**: `./plancasting/prd/10-system-architecture.md` (auth/authz section)
- **PRD API Specs**: `./plancasting/prd/12-api-specifications.md` (auth scheme, rate limiting)
- **Project Rules**: `./CLAUDE.md`

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports and user-facing output in that language. Keep code, technical identifiers, and file names in English.

## Stack Adaptation

Prompts reference Convex + Next.js as defaults. Adapt all paths and patterns to the actual stack in `plancasting/tech-stack.md`:
- `convex/` becomes your backend directory
- `convex/schema.ts` becomes your schema/migration files
- Convex functions become your backend functions/endpoints
- `src/app/` becomes your frontend pages directory

Read `CLAUDE.md` Part 2 (Backend Rules, Frontend Rules) for project-specific conventions.

## Phase 1: Analysis and Planning

Complete these steps before spawning any teammates:

1. Read `./CLAUDE.md`, `./plancasting/tech-stack.md`, and all security/compliance requirements from BRD/PRD.
2. Build a **Security Checklist** mapping each BRD security requirement (SR-xxx) to specific code patterns to verify. For each entry include: scope (affected files/functions), check (what to verify), code pattern (correct implementation example), and status.
3. Write `./plancasting/_audits/security/checklist.md` with the full checklist.
4. Create a task list for all teammates with dependency tracking.

## Phase 2: Spawn Audit Teammates

Spawn 4 parallel teammates. Each teammate's prompt must include the security checklist and instructions to read CLAUDE.md first.

### Teammate 1: auth-auditor

Scope: Authentication and authorization.

- Scan every exported backend function (excluding generated code). Verify auth checks are called where required. Flag mutations/actions modifying data without auth. Flag queries returning sensitive data without auth. Verify role/permission checks match BRD requirements.
- Check authorization logic for horizontal and vertical privilege escalation.
- Review middleware/route protection for completeness and role-based access.
- Adapt auth checks to the stack's auth pattern (session-based, JWT-based, or auth provider SDK). For JWT: verify JWKS endpoint security, `alg` whitelist (reject `alg: none`), audience/issuer validation.
- Fix each vulnerability with inline comment: `// SECURITY FIX: [description] — SR-xxx`

### Teammate 2: input-validation-auditor

Scope: Input validation and injection prevention.

- Verify ALL backend function arguments use proper validators. Flag overly permissive validators (e.g., `v.any()`). Verify string length constraints and typed ID validators.
- Scan form components for client-side validation consistency with server.
- Check for XSS vectors: unsafe innerHTML usage, unescaped user content, file upload validation.
- Fix each vulnerability found.

### Teammate 3: data-exposure-auditor

Scope: Data leakage and privacy.

- Flag queries returning entire documents when subsets suffice. Flag queries returning sensitive fields (email, phone, payment info) unnecessarily. Verify PII is not logged or exposed in error messages.
- Verify error messages do not leak internal details (stack traces, table names, query patterns).
- Check for sensitive data in localStorage/sessionStorage, hardcoded API keys, improperly prefixed env vars.
- Fix each issue found.

### Teammate 4: infrastructure-security-auditor

Scope: HTTP security headers, CORS, CSP, dependencies, rate limiting, audit logging.

- Verify Content-Security-Policy, HSTS, X-Frame-Options, X-Content-Type-Options, and Referrer-Policy.
- Check CORS configuration — flag `Access-Control-Allow-Origin: *`.
- Run dependency vulnerability scan (`bun audit`, `npm audit`, or equivalent). Flag critical/high severity issues and known CVEs. Verify lock file integrity.
- Verify rate limiting on authentication endpoints. Flag data-mutation rate limiting gaps for Stage 6G (scope boundary: auth rate limiting is 6A's responsibility, data-mutation rate limiting is 6G's).
- Verify security-sensitive operations are logged and logs contain no sensitive data.
- Fix each issue found.

## Unfixable Violation Protocol

When a violation cannot be fixed without architectural changes or would break another feature:

1. Document the full conflict with evidence.
2. Mark as **REQUIRES HUMAN DECISION** — do not attempt fixes that create regressions.
3. Include recommended approach and estimated effort.
4. If CRITICAL severity: recommend not launching until resolved. Record in `./plancasting/_audits/security/unfixable-violations.md` and summarize in report.md under "Blocking Issues". Critical violations block Stage 6H.
5. Continue with remaining fixable violations.

## Phase 3: Coordination

- Facilitate cross-team findings: auth gaps inform input-validation checks; PII exposure informs auth requirements; CSP gaps inform data-exposure risk; rate limiting gaps inform brute-force risk.
- Resolve file conflicts: first teammate to complete claims the file; second must re-read before applying changes.

## Phase 4: Review and Report

1. Run the full test suite using commands from CLAUDE.md (e.g., `bun run typecheck`, `bun run test`, `bun run test:e2e`). Fix any test failures caused by security changes.
2. If unfixable violations were documented, verify `./plancasting/_audits/security/unfixable-violations.md` exists and is referenced from report.md.
3. Generate `./plancasting/_audits/security/report.md` containing:
   - Executive summary
   - Vulnerabilities by category and severity (Critical/High/Medium/Low)
   - Fixes applied with code references
   - BRD security requirement compliance matrix (SR-xxx to Pass/Fail)
   - Infrastructure security results (HTTP headers, CORS, CSP, dependencies, rate limiting, audit logging)
   - Remaining risks requiring human decision
   - Recommendations for ongoing security practices
4. Include a **Gate Decision**: PASS (all Critical/High fixed, tests pass, no blocking issues), CONDITIONAL PASS (all Critical fixed, remaining High documented with mitigations, Stage 6H review required), or FAIL (Critical vulnerabilities remain, blocks Stage 6H).
5. Output summary: total vulnerabilities found, total fixed, total requiring human review.

## Phase 5: Shutdown

1. Request shutdown for all teammates.
2. Verify all file modifications are saved and committed.

## Severity Definitions

Use these consistently — do not deflate:
- **Critical**: Data breach possible without authentication
- **High**: Privilege escalation possible
- **Medium**: Defense-in-depth gap
- **Low**: Best practice deviation

## Critical Rules

1. NEVER mark a vulnerability as "acceptable risk" without documenting specific threat model justification.
2. NEVER delete a security test to make the suite pass — fix the vulnerability instead.
3. NEVER introduce new auth bypass patterns as part of a fix.
4. ALWAYS run the full test suite after security changes.
5. ALWAYS verify custom API routes have CSRF protection for state-changing operations.
6. ALWAYS check for secrets in git history: `git log --all -p -G "(sk-|sk_|Bearer |password=|PRIVATE KEY)" --max-count=500`. For large repos add `--since='6 months ago'`. Use `-G` with regex alternation, not multiple `-S` flags. If any secret is found, document as CRITICAL in unfixable-violations.md requiring immediate key rotation. Verify `.env.local.example` contains only placeholder values.
7. ALWAYS verify SSRF blocklist: check all outbound `fetch()` or HTTP client calls triggered by user input. Reject private IP ranges, localhost, link-local, IPv6 unique local, and cloud metadata endpoints (169.254.169.254).
8. ALWAYS verify rate limiting on auth endpoints. Flag data-mutation gaps for Stage 6G.
9. Use commands from CLAUDE.md for running tests.
10. Reference Stage 5B output to avoid auditing stub/incomplete features.
