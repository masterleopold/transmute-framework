---
name: smoke
description: >-
  Runs production smoke tests to verify the deployed application works correctly in the live environment.
  This skill should be used when the user asks to "run production smoke tests",
  "verify the production deployment", "smoke test the live app",
  "check if production is working", "run post-deployment verification",
  "run stage 7V", or "verify the deployed application",
  or when the transmute-pipeline agent reaches Stage 7V of the pipeline.
version: 1.0.0
---

# Production Smoke Verification — Stage 7V

Read the detailed guide at `${CLAUDE_SKILL_ROOT}/references/smoke-detailed-guide.md` for the full verification checklist, report template, known failure patterns, and rollback guidance.

## Prerequisites

1. Verify the production URL is accessible and responding.
2. Check `./plancasting/_launch/readiness-report.md` exists. If it shows FAIL, stop and report the blocker. If READY or CONDITIONAL PASS with documented minor issues, proceed.
3. Verify `./plancasting/_audits/visual-verification/report.md` or `./plancasting/_audits/visual-polish/report.md` exists. Warn if neither is found.
4. Create output directories:
   ```bash
   mkdir -p ./plancasting/_audits/production-smoke
   mkdir -p ./screenshots/production
   ```
5. Read `CLAUDE.md`, `plancasting/tech-stack.md`, and check `plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports in the specified language.

## Inputs

- **Production URL**: The live application URL
- **Scenario Generation Guide**: `${CLAUDE_SKILL_ROOT}/references/feature-scenario-generation.md` (if not available, use PRD files directly)
- **6V Scenario Matrix** (if exists): `./plancasting/_audits/visual-verification/feature-scenario-matrix.md`
- **6V Report**: `./plancasting/_audits/visual-verification/report.md`
- **6R Report** (if exists): `./plancasting/_audits/runtime-remediation/report.md`
- **6P/6P-R Report** (if exists): `./plancasting/_audits/visual-polish/report.md`
- **PRD files**: `./plancasting/prd/02-feature-map-and-prioritization.md`, `04-epics-and-user-stories.md`, `06-user-flows.md`, `07-information-architecture.md`, `08-screen-specifications.md`
- **Tech Stack**: `./plancasting/tech-stack.md`
- **E2E Config**: `./playwright.config.ts`, `./e2e/constants.ts`

## Execution Flow

This is a single-agent sequential check. Target completion: 25-45 minutes. If the application exceeds 50+ pages or 10+ integrations, consider running a scoped Stage 6V (`critical` mode) against the production URL instead.

### Step 0: Generate Smoke Scenario Matrix

Before any verification, generate a targeted test plan. Save to `./plancasting/_audits/production-smoke/smoke-scenario-matrix.md`.

**If 6V scenario matrix exists**: Filter to P0 + P1 feature scenarios only, happy path, no negative variants. Filter auth contexts to unauthenticated + one authenticated role. Skip entity state and role permission scenarios. Target ~10-15 scenarios.

**If no 6V matrix exists**: Read the scenario generation guide and PRD files. Generate feature scenarios for P0 + P1 features only, one scenario per flow (happy path). Target ~10-15 scenarios.

**If generation fails**: Fall back to hardcoded minimum flows (authentication, core feature, settings).

### Steps 1-3: Infrastructure and Baseline

1. **Infrastructure Checks**: Verify DNS resolution, SSL certificate validity, HTTPS redirect, and security headers. Use CLI tools (`nslookup`, `openssl`, `curl`) if available; fall back to Playwright browser tools.

2. **Environment Variable Spot-Check**: Check for missing or misconfigured env vars. Verify BaaS URLs, auth provider URLs, naming consistency across all `process.env.*` reads, and backend deployment target. Cross-check third-party service tier limits.

3. **Reuse 6V Playwright Tests** (if `e2e/verification/` exists): Run them against production URL with `BASE_URL=https://[domain]`.

### Steps 4-8: Core Verification

4. **Critical Page Load Verification**: Test all public pages in a FRESH browser context (no cookies/localStorage). Verify HTTP 200, correct body content (not login page served with 200), and no auth console errors. Test protected route redirect behavior. Test authenticated pages after logging in as a test user. For each page: verify HTTP 200, no console errors, content renders, CSS loads, JS executes, data loads, take screenshot.

5. **6R Fix Verification** (if 6R report exists): Re-test each auto-fixed issue on production. If any fix is missing, flag as CRITICAL and check deployed commit hash.

6. **6P/6P-R Visual Polish Verification** (if visual polish report exists): Spot-check top 3 most impactful visual changes survived production build. Flag missing changes as MEDIUM severity.

7. **Navigation Smoke Test** (~5 min max): Test desktop sidebar, footer, mobile nav, sub-navigation tabs. Check CSS styling intact at both viewports. Flag invisible/unstyled links as CRITICAL.

8. **Critical User Flow Verification**: Execute P0 scenarios from smoke matrix. Follow dependency graph. If P0 fails, mark dependents as BLOCKED. Fall back to minimum flows if no matrix exists.

### Steps 9-11: Visual, Performance, Integrations

9. **AI Vision Spot-Check**: Screenshot 5 most important pages. Compare against 6V screenshots for visual differences.

10. **Performance Spot-Check**: Measure TTFB and LCP for landing page and dashboard. Flag if >2x slower than dev.

11. **Third-Party Integration Verification**: Verify auth, database, payments, email, analytics, error monitoring, webhooks, real-time connections. **CRITICAL**: Verify AI model IDs first (grep codebase, send minimal test request). Run external API health checks with minimal requests (cost warning: real API calls against production keys). Verify OAuth integration health for each connected service.

## Output

Generate `./plancasting/_audits/production-smoke/report.md` following the report template in the detailed guide. The report includes: summary, infrastructure results, page load results, public route access, protected route redirect, 6R/6P/6P-R verification, navigation smoke test, scenario results, visual comparison, performance, third-party integrations, gate decision, next steps, issues found, and screenshot references.

## Gate Decision

- **PASS**: All critical flows work, all pages load, no console errors, all external APIs respond 2xx. Proceed to Stage 7D (User Guide Generation).
- **FAIL**: Any critical flow broken, pages don't load, critical navigation failure, external API health check fails, or 6R fixes missing from deployment. Immediate action required per rollback guidance.

Stage 7V is binary (PASS or FAIL) -- there is no CONDITIONAL PASS. Non-critical visual issues do not trigger FAIL; document them for Stage 8.

## Critical Rules

1. ALWAYS use the PRODUCTION URL -- never test against localhost.
2. NEVER modify production data beyond test accounts.
3. NEVER test payment flows with real payment methods.
4. Use identifiable test accounts (`smoke-test-*@domain`).
5. If ANY critical flow fails, follow rollback guidance. Do NOT mark as "known issue for later."
6. Keep this stage FAST -- 25-45 minutes max.
7. ALWAYS compare against Stage 6V results for deployment-specific regressions.
8. ALWAYS clean up test accounts after verification.
9. ALWAYS verify test user login works BEFORE authenticated page checks.
10. ALWAYS test public utility routes (`/sitemap.xml`, `/robots.txt`, `/api/health`) WITHOUT authentication.
11. ALWAYS verify 6R fixes BEFORE detailed feature/navigation checks if 6R report exists.
12. ALWAYS test navigation at BOTH desktop and mobile viewports.
13. ALWAYS check deployed commit hash against 6R remediation commit hash if 6R report exists.
14. Spot-check 6P/6P-R visual polish changes if visual polish report exists.
15. NEVER modify application code, production configuration, or database records during this stage (except test account creation/cleanup).
