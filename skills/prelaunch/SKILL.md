---
name: prelaunch
description: >-
  Performs a comprehensive pre-launch verification checklist before production deployment.
  This skill should be used when the user asks to "run pre-launch checks",
  "verify launch readiness", "check production configuration",
  "validate deployment readiness", "generate launch checklist",
  "are we ready to go live", or "can we ship"
  — or when the transmute-pipeline agent reaches Stage 6H of the pipeline.
version: 1.0.0
---

# Stage 6H: Final Check Before Production Deployment

Lead a multi-agent pre-launch verification project. Perform a comprehensive final check of the COMPLETE product before it goes live. This is the last gate between development and real users.

## Prerequisites

Verify before starting — this stage has the strictest prerequisite checks:

1. `./plancasting/_audits/implementation-completeness/report.md` exists with PASS or CONDITIONAL PASS. If missing, STOP — 5B is a prerequisite gate. CONDITIONAL PASS requires each Category C issue to have a documented workaround. FAIL means STOP.
2. ALL Stage 6 audit reports exist:
   - `./plancasting/_audits/security/report.md` (6A)
   - `./plancasting/_audits/accessibility/report.md` (6B)
   - `./plancasting/_audits/performance/report.md` (6C)
   - `./plancasting/_audits/documentation/report.md` and `./docs/` (6D) — skip if plancasting/tech-stack.md indicates N/A
   - `./plancasting/_audits/refactoring/report.md` (6E)
   - `./seed/README.md` and `./plancasting/_audits/seed-data/report.md` (6F) — skip if plancasting/tech-stack.md indicates N/A
   - `./plancasting/_audits/resilience/report.md` (6G)
   For any missing report (except 6D/6F if skipped), STOP — prerequisite not completed.
3. Check for unfixable violation files from prior stages: `plancasting/_audits/security/`, `plancasting/_audits/accessibility/`, `plancasting/_audits/performance/`, `plancasting/_audits/resilience/` — each may have `unfixable-violations.md`. Treat CRITICAL items as launch blockers.
4. Read `./CLAUDE.md` and `./plancasting/tech-stack.md` for project conventions.

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports in that language. Code and file names remain in English.

## Stack Adaptation

Source examples use Next.js + Convex + Vercel. Adapt ALL references to your actual stack: `next.config.ts` becomes your framework config, `npx convex deploy` becomes your backend deploy command, `npx vercel env ls` becomes your hosting platform's env command, `NEXT_PUBLIC_*` becomes your framework's client-exposed prefix, etc. Skip sections marked "If using [technology]" when your stack does not include that technology.

## Known Failure Patterns

**General (all stacks):**
1. **Missing hosting env vars**: Client-exposed backend URL env vars auto-set by dev server but NOT present on hosting platform — causes blank pages.
2. **Dark mode border contrast**: Button borders using `border-primary-*` produce harsh borders in dark mode — should use `border-border` neutral token.

**If using Next.js:**
3. **CSP blocks scripts**: `script-src 'strict-dynamic'` without nonces blocks ALL script loading.
4. **i18n alias misconfiguration**: Turbopack alias set but webpack alias missing, causing SSR crashes.

**If using Tailwind v4:**
5. **Silent config failure**: Missing `@config` directive after `@import "tailwindcss"` — zero CSS output, no error.
6. **Semantic token lookup**: `border-border` looks up `colors.border` in v4, not `borderColor.DEFAULT`.

## Phase 1: Lead Analysis and Planning

Complete BEFORE spawning teammates:

1. Read `./CLAUDE.md`, `./plancasting/tech-stack.md`, and all audit reports in `./plancasting/_audits/`.
2. Read `./plancasting/_audits/implementation-completeness/report.md` for known issues.
3. Verify all audit reports exist. Missing reports indicate skipped stages — note in readiness report.
4. Read unfixable violation files if they exist. Include critical items in Blocking Issues.
5. Create `./plancasting/_launch/checklist.md` — master pre-launch checklist.

## Phase 2: Spawn Verification Teammates

### Teammate 1: "code-and-test-verifier"

Scope: Code quality, test coverage, build verification.

Tasks:

1. **Build verification**: Run typecheck, lint, build — zero errors each. Verify production build size against performance budgets.

2. **Test suite verification**: Run all unit, integration, and E2E tests — all pass. Verify test count is reasonable. Investigate skipped/pending tests.

3. **Code quality final check**: No `console.log` in production code. No `TODO`/`FIXME`/`HACK` without issue references. No hardcoded secrets. No unexplained `@ts-ignore`/`@ts-expect-error`. No dev-only code (mock data, test backdoors) in production paths.

4. **Dependency audit**: Run `npm audit` (or `bunx audit-ci`/`npx snyk test` for Bun projects). Flag critical/high vulnerabilities. Verify license compatibility.

### Teammate 2: "config-and-environment-verifier"

Scope: Environment configuration, credentials, infrastructure readiness.

Tasks:

1. **Environment variables**: Compare `.env.local.example` against `.env.local`. No dev/test values in production config. No placeholder text. Client-exposed variables contain only safe values. Cross-check hosting platform env vars against `.env.local.example` — verify production equivalents exist. Grep codebase for `process.env.\w+` and verify every referenced var matches `.env.local.example`.

2. **Production configuration**: Verify framework config has production-appropriate settings. For Next.js: validate CSP (no `strict-dynamic` without nonces), i18n aliases (both Turbopack and webpack). For Tailwind v4: verify `@config` bridge and semantic color tokens. Verify backend deployment points to production. Auth provider and email service use production credentials. Feature flags have correct defaults.

3. **CI/CD pipeline**: Config exists. Deploy pipeline runs tests before deploying. Rollback procedure documented. For forward-only backends (Convex): verify backward-compatible schema changes, feature flag strategy, compensating mutations. Preview deployment works.

4. **Monitoring and alerting**: Error monitoring configured. Analytics instrumented. Health check endpoints exist. Logging configured for production (structured, no debug level).

### Teammate 3: "user-facing-verifier"

Scope: User-facing completeness, SEO, legal, documentation.

Tasks:

1. **SEO and metadata**: Every page has `<title>` and `<meta description>`. Open Graph tags set. Sitemap generated. `robots.txt` exists. Canonical URLs set. JSON-LD structured data where appropriate.

2. **Legal and compliance**: Privacy policy page exists and linked. Terms of service exists and linked. Cookie consent mechanism (if required). GDPR data export/deletion (if EU-targeted). Cross-reference BRD compliance requirements.

3. **User-facing content**: No placeholder text ("Lorem ipsum", "[TODO]", "Coming soon" on launched features). Error messages are helpful and non-technical. Empty states have guidance and CTAs. 404 page works with home link. Onboarding flow works for new users.

4. **Cross-browser, responsive, dark mode**: Critical flows work in Chromium, Firefox, Safari. Responsive at 375px, 768px, 1440px. No horizontal scrolling. Dark mode visual check — verify borders use neutral tokens, not harsh primary colors.

5. **Documentation completeness**: `./docs/` exists with help docs, API docs, developer guide (from 6D). README has setup and deployment instructions. ARCHITECTURE.md is up to date (or `docs/developer/architecture.md`).

## Phase 3: Coordination

Escalate critical blockers immediately:
- Failing tests: STOP. Abort all teammates, fix, restart from Phase 1.
- Missing production credentials: STOP. Collect them.
- Legal compliance gaps: STOP. Address before launch.
- Non-critical issues: document for post-launch fixes.

## Phase 4: Launch Readiness Report

Generate `./plancasting/_launch/readiness-report.md`:

**Launch Readiness Summary** (checkmark or X for each):
- Build passes
- All tests pass (unit: X, component: X, E2E: X)
- No critical code quality issues
- No critical dependency vulnerabilities
- All environment variables configured for production
- CI/CD pipeline ready
- Monitoring and alerting configured
- SEO and metadata complete
- Legal and compliance requirements met
- No placeholder content remaining
- Responsive design verified
- Documentation complete

**Launch Decision**: READY / NOT READY (with blockers listed)

**Non-Critical Issues**: Minor items that can be addressed post-launch.

**Post-Launch Checklist**:
- Verify DNS propagation
- Verify SSL certificate
- Run smoke test on production URL
- Verify monitoring dashboards show live data
- Verify error tracking receives test errors
- Send test transactional email from production
- Verify auth flow on production domain

**Next Steps after 6H**:
- If READY, proceed to Stage 6V (Visual and Functional Verification).
- Post-6V: PASS -> skip 6R, proceed to 6P. CONDITIONAL PASS (Cat A/B) -> 6R. CONDITIONAL PASS (Cat C only) -> skip 6R, proceed to 6P. FAIL -> fix manually, re-run 6V.
- Post-6R: PASS/CONDITIONAL PASS -> 6P. FAIL -> resolve, re-run 6V -> 6R.
- Post-6P: PASS -> Stage 7 (Deploy) -> 7V (Production Smoke) -> 7D (User Guide).
- Do NOT skip Stage 6V or Stage 7V.

## Critical Rules

1. NEVER launch with failing tests.
2. NEVER launch with critical/high dependency vulnerabilities unaddressed.
3. NEVER assume env vars are set just because they exist in `.env.local` — verify on hosting platform.
4. NEVER launch without a tested rollback procedure.
5. Readiness report MUST be saved before deployment begins.
6. ALWAYS verify ALL prior stage audit reports exist.
7. For forward-only schema backends: verify backward compatibility and feature flag strategy.
8. ALWAYS verify CORS headers allow the production frontend domain.
9. After this stage passes, proceed to Stage 6V as the final live-app gate.
