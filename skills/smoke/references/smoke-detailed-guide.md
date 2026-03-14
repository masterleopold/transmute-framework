# Production Smoke Verification — Detailed Guide

## Why This Stage Exists

Stage 6V verifies the app against the dev server, and Stage 6R auto-fixes mechanical issues found by 6V. But production deployments can introduce failures that don't exist in development:
- Missing or misconfigured environment variables on the hosting platform
- CDN/edge caching causing stale assets
- CSP headers blocking scripts that worked in dev
- Database connection pooling differences
- Auth provider configuration pointing to wrong environment
- DNS/SSL issues on the production domain
- Serverless function cold-start timeouts
- Tailwind CSS class purging removing classes used in dynamic expressions

This is a LIGHTER pass than 6V — it focuses on "does the deployed app work?" not "does it match every spec detail?"

**Stage Sequence**: ... → 6V (Verification) → 6R (Runtime Remediation) → 6P (Visual Polish) → 7 (Deploy) → **7V (this stage)** → 7D (User Guide) → 8 (Feedback) / 9 (Maintenance)

## Known Failure Patterns

These patterns were identified from real deployments and are invisible to dev/test environments:

1. **Environment variable naming mismatch**: One file reads `ANTHROPIC_API_KEY` while others read `MYAPP_ANTHROPIC_API_KEY` (a prefixed variant) — the mismatched reference silently returns `undefined`, passes all tests (which mock env vars), and only fails in production.
2. **Backend deployment target wrong**: Frontend's backend URL env var points to the dev backend instead of production — all production requests go to dev data.
3. **AI model ID hallucination**: Stage 5 agents may use non-existent or outdated model IDs. These pass tests (which mock API calls) but fail with 400/404 in production.
4. **OAuth redirect URI mismatch**: The `redirect_uri` constructed during OAuth init differs from the one used in the callback handler — the provider rejects the request.
5. **Service tier limit exceeded**: Sandbox timeout set to 2 hours but the free tier cap is 1 hour — API returns 400, feature silently fails.
6. **Tailwind CSS class purging**: Dynamic class names (template literals, conditional joins) get purged in production builds, causing layout breaks that don't appear in dev.
7. **Auth provider not configured for production domain**: Redirect URIs, CORS origins, and webhook URLs still point to localhost or the preview domain.
8. **Middleware edge vs. node behavior difference**: Auth middleware that runs as Node.js middleware in dev may run as Edge middleware in production (Vercel, Cloudflare). Edge runtime has different API availability — `crypto.timingSafeEqual`, `Buffer`, and some Node built-ins may not exist, causing middleware to crash silently and block ALL routes.
9. **Navigation CSS purge**: Sidebar, footer, and mobile nav components use dynamic Tailwind classes that get purged in production builds. Navigation links become invisible or lose active state styling.
10. **Public route middleware mismatch between dev and production**: Middleware `PUBLIC_ROUTES` array may be correct in code, but edge middleware caching on the hosting platform serves a stale version — routes that were recently added to the whitelist are still blocked in production.
11. **6R fixes not deployed**: Stage 6R fixes middleware, creates stub pages, wires button handlers — but if the deployment was triggered BEFORE 6R completed (or from a branch that doesn't include 6R fixes), all remediated issues reappear in production.

## Stack Adaptation

This prompt is intentionally stack-agnostic — it verifies the deployed application via browser and standard HTTP tools. Adapt these references to your stack:
- Infrastructure commands: use alternatives if `curl`/`nslookup`/`openssl` are unavailable
- Test runner: use your project's Playwright command (e.g., `bunx playwright test` vs `npx playwright test`)
- Backend deployment: adapt rollback commands to your BaaS/backend (Convex, Supabase, Firebase, etc.)
- Hosting platform: adapt env var checks to your host (Vercel, Netlify, Cloudflare, etc.)
Always read `CLAUDE.md` and `plancasting/tech-stack.md` for your project's actual conventions.

## Detailed Verification Checklist

### 0. Generate Smoke Scenario Matrix (MUST run FIRST)

Before any verification, generate a targeted test plan for production smoke testing.

**If the 6V scenario matrix exists** (`./plancasting/_audits/visual-verification/feature-scenario-matrix.md`):
1. Read the 6V matrix
2. Filter to P0 + P1 Feature Scenarios only (happy path, no negative variants)
3. Filter Auth Context Scenarios to: unauthenticated column + one authenticated role only
4. Skip Entity State and Role Permission scenarios (too detailed for smoke testing)
5. Result: ~10-15 scenarios

**If NO 6V scenario matrix exists** (first deployment, or 6V was skipped):
1. Read the feature scenario generation guide (bundled in this skill's references) for the generation algorithm
2. Read PRD files: `plancasting/prd/02-feature-map-and-prioritization.md` (feature priorities), `plancasting/prd/06-user-flows.md` (critical flows), `plancasting/prd/07-information-architecture.md` (routes + auth)
3. Scan codebase: route constants, middleware PUBLIC_ROUTES, page files
4. Generate Feature Scenarios for P0 + P1 features only
5. Result: ~10-15 scenarios

**If scenario generation fails**: Fall back to the hardcoded minimum flows in the "Critical User Flow Verification" section below (Section 8). Note the failure in the report.

**Save to** `./plancasting/_audits/production-smoke/smoke-scenario-matrix.md`:
```markdown
# Production Smoke Scenario Matrix
- **Generated**: [date]
- **Source**: 6V matrix (filtered) / generated from PRD
- **Production URL**: [url]

## Smoke Scenarios (P0 — must all pass)
| ID | Scenario | Source | Steps | Est. Time |
|----|----------|--------|-------|-----------|
| SS-001 | Signup -> Onboarding -> Dashboard | UF-001, FEAT-001 | 8 steps | 3 min |
| SS-002 | Project Creation -> BP Upload | UF-002, FEAT-003/004 | 6 steps | 2 min |
| ... |

## Smoke Scenarios (P1 — should pass)
| ID | Scenario | Source | Steps | Est. Time |
| ... |

## Auth Context Checks
| Route | Unauthenticated Expected | Authenticated Expected |
| ... |

## Total: [n] scenarios, est. [n] minutes
```

### 1. Infrastructure Checks

**Primary approach** (if CLI tools are available):
```bash
# DNS resolves correctly
nslookup [production-domain]

# SSL certificate is valid and not expiring soon
echo | openssl s_client -servername [domain] -connect [domain]:443 2>/dev/null | openssl x509 -noout -dates

# Site responds with 200 and check security headers
curl -sI https://[domain] | head -20
```

**Fallback approach** (if CLI tools are unavailable):
- Use `browser_navigate` to the production URL — if it loads, DNS and SSL are working
- Use `browser_evaluate` to inspect `window.location.protocol` — verify it starts with `https:`
- Use `browser_evaluate` to read security headers via `fetch(url, { method: 'HEAD' }).then(r => Object.fromEntries(r.headers))`
- Use `browser_console_messages` to check for CSP violations or blocked script errors

Checklist:
- Verify DNS resolves to the correct IP/CDN
- Verify SSL certificate is valid (not self-signed, not expired)
- Verify HTTPS redirect works (HTTP -> HTTPS)
- Verify the response includes expected security headers (CSP, X-Frame-Options, etc.)

### 2. Environment Variable Spot-Check

Before testing pages, check for common env var issues:
- Navigate to the app and view page source or `__NEXT_DATA__` (for Next.js) — check that `NEXT_PUBLIC_*` values are present and not `"undefined"` or empty
- If the hosting platform CLI is available, cross-check against `.env.local.example`
- Check the browser console for errors like "API URL is undefined" or "Missing configuration"
- **Common miss**: BaaS URL (e.g., `NEXT_PUBLIC_CONVEX_URL`) is auto-set by the BaaS dev server in development but must be manually configured on the hosting platform. If this is missing, the frontend client constructor throws immediately and NO pages will render.
- **Auth provider URLs**: Auth callback URLs, JWKS endpoints, and OIDC discovery URLs must point to the production domain, not localhost.
- **Environment variable naming consistency** (Pattern #1): Grep the codebase for all `process.env.*` reads of each critical secret. Verify every file uses the EXACT same variable name.
- **Backend deployment target verification (CRITICAL)** (Pattern #2): Verify the frontend's backend URL env var points to the PRODUCTION backend, not the dev backend.
- **Third-party service tier limits** (Pattern #5): For each external service used at runtime, verify that configuration values are within the service tier's actual limits.

### 3. Reuse Stage 6V Playwright Tests (if available)

If Stage 6V generated Playwright test files in `e2e/verification/`, run them against the production URL:
```bash
BASE_URL=https://[production-domain] bunx playwright test e2e/verification/ --grep "@verification" --retries=2
```
Verify `playwright.config.ts` reads `BASE_URL` from environment. If no test files exist, skip and proceed with manual checks.

### 4. Critical Page Load Verification

**Public pages** (MUST use a FRESH browser context — no cookies, no localStorage, no session tokens):

CRITICAL: Use `browser_close` to end any existing session, then `browser_navigate` to start fresh. Do NOT merely "skip login" in the same context where you previously logged in.

Test these pages:
- Landing/home page (`/`)
- Login page (`/login`)
- Signup page (`/signup`)
- Pricing page (`/pricing`, if applicable)
- Forgot password (`/forgot-password`)
- Legal pages (`/privacy`, `/terms`)
- Help pages (`/help`, `/help/troubleshoot`)
- Utility routes: `/sitemap.xml`, `/robots.txt`, `/api/health`, `/.well-known/openid-configuration`

**Verification method** for EACH public page — check ALL THREE:
1. HTTP response status is **200** (not 302 redirect to `/login`)
2. Response body is the **expected page content** (not an HTML login page served with 200 status)
3. No auth-related console errors (`token undefined`, `session expired`, `unauthorized`)

Also verify protected route redirect: Navigate to `/dashboard` and `/settings/profile` in the same unauthenticated context — verify they redirect to `/login?redirect=[path]`.

If ANY public page redirects to login, this is a **CRITICAL** failure — the auth middleware is blocking public routes in production.

**Authenticated pages** (log in as test user):

Production test users MUST exist BEFORE running smoke tests. Check `e2e/constants.ts` for a `PRODUCTION_TEST_USERS` section. If test users don't exist, create them via auth provider admin API, BaaS CLI, or app signup flow. If all methods fail, FAIL this stage with "BLOCKED: Cannot create production test users."

Test authenticated pages: Dashboard, main feature page, settings, billing. For each: verify HTTP 200, no console errors, content renders, CSS loads, JS executes, data loads. Take screenshot as evidence.

### 5. Stage 6R Fix Verification (if 6R report exists)

Read the 6R report "Auto-Fixed (Category A)" and "Semi-Auto-Fixed (Category B)" tables. For EACH fix listed as "Verified: PASS":

| Fix Type | Re-Test Method |
|---|---|
| Public route added to middleware whitelist | Navigate to the route without auth — must load, not redirect to `/login` |
| Dead link removed from layout | Navigate to the page — verify the link is gone |
| Stub page created for missing route | Navigate to the route — must load the stub page content |
| Button handler wired | Navigate to the page, click the button — verify the action occurs |
| Loading state added | Navigate to the page — verify skeleton/spinner appears during load |
| i18n key added | Navigate to the page — verify translated text appears, not raw key string |
| Broken href fixed | Click the link — verify it navigates to the correct destination |

If ANY 6R fix is NOT present in production, flag as **CRITICAL**. Check deployed commit hash vs. 6R report commit hash.

### 6. Stage 6P Visual Polish Verification (if 6P report exists)

Quick visual spot-check (3-5 minutes max):
1. Read the 6P report's applied changes tables
2. Pick the TOP 3 most impactful changes
3. For each: navigate, screenshot, compare with 6P "after" screenshot

| Check | Pass Criteria |
|---|---|
| Contrast fixes visible | Text has the corrected color |
| Hover transitions working | Smooth color/shadow transition occurs |
| Typography hierarchy intact | Heading sizes/weights match 6P report |
| Dark mode enhancements | Dark mode fixes from 6P are present |

Missing visual polish = **MEDIUM** severity (functional app, visual regression only).

### 7. Navigation Smoke Test

~5 minutes max. Test highest-traffic navigation paths only.

**7a. Desktop**: From dashboard, click each sidebar link, each footer link, the logo/home link, and breadcrumbs. Verify each destination loads.

**7b. Mobile** (375px width): Open hamburger menu, click each link, verify destinations load, verify menu closes after navigation.

**7c. Sub-Navigation**: Test one instance of each major tabbed navigation (settings tabs, project detail tabs).

**7d. CSS Purge Check**: Inspect navigation for styling issues — visible links with icons, active state indicators, hover/focus states, adequate touch targets on mobile. Invisible/unstyled navigation links = **CRITICAL** (likely Tailwind CSS purging).

### 8. Critical User Flow Verification (Scenario-Driven)

Execute P0 Feature Scenarios from the smoke scenario matrix. Follow the dependency graph — P0 first, then P1. If P0 fails, mark dependents as BLOCKED.

For each scenario:
1. Check prerequisites
2. Execute each step on the PRODUCTION URL
3. Verify expected result matches actual result at each step
4. Screenshot and record errors on failure; mark remaining steps BLOCKED

**Fallback flows** (if no scenario matrix):
- **Flow 1: Authentication**: Sign up / log in, verify session persists, log out
- **Flow 2: Core Feature**: Navigate to main feature, perform primary action, verify result saved
- **Flow 3: Settings/Account**: Navigate to settings, verify profile and org data loads

### 9. AI Vision Spot-Check

Screenshot the 5 most important pages. Compare against Stage 6V screenshots for visual differences, missing assets, and layout inconsistencies.

### 10. Performance Spot-Check

For landing page and dashboard:
- **TTFB**: `curl -o /dev/null -w "%{time_starttransfer}" https://[domain]` or `browser_evaluate` with `performance.timing`
- **LCP**: `browser_evaluate` with PerformanceObserver or `bunx lighthouse`
- Flag if >2x slower than dev
- Check for failed network requests

### 11. Third-Party Integration Verification

#### 11.1 AI Model ID Verification (CRITICAL — MUST COMPLETE FIRST)

1. Search codebase: `grep -rE 'claude-|gpt-|gemini-' [backend-dir]/ --include='*.ts' --include='*.js' | grep -v node_modules | grep -v test`
2. For each unique model ID, send a minimal test request (1-token prompt)
3. If any model returns 400/404, flag as **CRITICAL** — likely hallucinated model ID
4. Always verify against the provider's current model documentation

#### 11.2 External API Health Check (CRITICAL)

> **Cost warning**: Use minimal requests (1-token completions, smallest payloads). Each check should cost fractions of a cent.

For each external API action:
1. Verify API key env var is set and non-empty
2. Send minimal test request
3. Verify 2xx response — not 400 (bad model ID), 401 (bad key), or 404 (bad endpoint)

Examples:
- **Anthropic**: `messages.create({ model: "<model-id>", max_tokens: 10, messages: [{ role: "user", content: "Say OK" }] })`
- **Stripe**: Verify key starts with `sk_test_`. NEVER use `sk_live_` during smoke testing.
- **Auth provider**: GET user list endpoint — verify 200

#### 11.3 OAuth Integration Health Check

For each OAuth integration:
1. Verify `*_CLIENT_ID` and `*_CLIENT_SECRET` env vars exist
2. Verify `redirect_uri` in init matches callback handler code
3. Verify `redirect_uri` is registered in OAuth provider settings
4. Click "Connect" button — verify provider auth page loads
5. Complete full round-trip with test account if possible

## Report Template

Generate `./plancasting/_audits/production-smoke/report.md`:

```markdown
# Production Smoke Verification Report — Stage 7V

## Summary
- **Verification Date**: [date]
- **Production URL**: [url]
- **Deployment Commit**: [git hash]
- **Hosting Platform**: [e.g., Vercel]
- **Backend Deployment**: [e.g., Convex production-instance-name]
- **Region**: [e.g., iad1 / us-east-1]

## Infrastructure
- DNS: PASS / FAIL
- SSL: PASS / FAIL (expires: [date])
- HTTPS Redirect: PASS / FAIL
- Security Headers: PASS / FAIL
- Environment Variables: PASS / FAIL / WARN ([details])

## Page Load Results
| Page | Status | Console Errors | Renders | CSS | JS | Data |
|------|--------|---------------|---------|-----|-----|------|
| Landing | PASS/FAIL | PASS/FAIL | PASS/FAIL | PASS/FAIL | PASS/FAIL | PASS/FAIL |
| Login | ... | ... | ... | ... | ... | ... |
| Dashboard | ... | ... | ... | ... | ... | ... |

## Unauthenticated Public Route Access (tested in fresh context, no auth)
| Route | Expected | HTTP Status | Body Check | Console Errors | Status |
|-------|----------|------------|------------|----------------|--------|
| / | Landing page | ... | ... | ... | PASS/FAIL |
| /login | Login form | ... | ... | ... | PASS/FAIL |
| /signup | Signup form | ... | ... | ... | PASS/FAIL |
| /pricing | Pricing content | ... | ... | ... | PASS/FAIL |
| /privacy | Privacy policy | ... | ... | ... | PASS/FAIL |
| /terms | Terms of service | ... | ... | ... | PASS/FAIL |
| /help | Help center | ... | ... | ... | PASS/FAIL |
| /forgot-password | Reset form | ... | ... | ... | PASS/FAIL |
| /sitemap.xml | Valid XML | ... | ... | ... | PASS/FAIL |
| /robots.txt | Text rules | ... | ... | ... | PASS/FAIL |
| /api/health | JSON 200 | ... | ... | ... | PASS/FAIL |

## Protected Route Redirect (tested in fresh context, no auth)
| Route | Expected | Actual | Redirect Loop | Status |
|-------|----------|--------|--------------|--------|
| /dashboard | 302 -> /login?redirect=/dashboard | ... | No | PASS/FAIL |
| /settings/profile | 302 -> /login?redirect=... | ... | No | PASS/FAIL |

## 6R Fix Verification (if applicable)
- Total 6R fixes: [n]
- Verified in production: [n]
- Missing in production: [n] — [list]
- Deployment commit matches 6R: YES / NO

## 6P Visual Polish Verification (if applicable)
- Total 6P changes: [n]
- Spot-checked: [n]
- Present in production: [n]
- Missing in production: [n] — [list]

## Navigation Smoke Test
| Area | Links Tested | Working | Broken | Issues |
|------|-------------|---------|--------|--------|
| Desktop sidebar | [n] | [n] | [n] | [list] |
| Footer | [n] | [n] | [n] | [list] |
| Mobile nav | [n] | [n] | [n] | [list] |
| Sub-nav tabs | [n] | [n] | [n] | [list] |
| CSS styling | -- | -- | -- | Intact / [issues] |

## Smoke Scenario Results (Dynamically Generated)
- Scenarios generated: [n] (P0: [n], P1: [n])
- Source: 6V matrix (filtered) / generated from PRD
| Scenario ID | Name | Priority | Steps | Passed Steps | Result | Failure Point | Error |
|-------------|------|----------|-------|-------------|--------|--------------|-------|
| SS-001 | [name] | P0 | [n] | [n]/[n] | PASS/FAIL/BLOCKED | [step] | [error] |

## Critical Flow Results (Fallback — only if no scenario matrix)
| Flow | Result | Failure Point | Error Details |
|------|--------|--------------|---------------|
| Authentication | PASS/FAIL | [step] | [error] |
| Core Feature | PASS/FAIL | [step] | [error] |
| Settings | PASS/FAIL | [step] | [error] |

## Visual Comparison (Dev vs Production)
- [Any visual differences noted]

## Performance
| Page | TTFB | LCP | vs Dev |
|------|------|-----|--------|
| Landing | [ms] | [ms] | [comparison] |
| Dashboard | [ms] | [ms] | [comparison] |

## Third-Party Integrations
| Service | Status | Notes |
|---------|--------|-------|
| Auth | PASS/FAIL | |
| Database | PASS/FAIL | |
| Payments | PASS/FAIL | |
| Email | PASS/FAIL | |
| Analytics | PASS/FAIL | |
| Error Monitoring | PASS/FAIL | |
| Webhooks | PASS/FAIL | |
| AI Models | PASS/FAIL | |
| OAuth | PASS/FAIL | |

## Gate Decision
- **PASS**: All critical flows work, all pages load, no console errors, all external APIs respond 2xx
- **FAIL**: Any critical flow broken OR pages don't load OR critical navigation failure OR external API health check fails — immediate action required

## Next Steps
- If PASS: proceed to Stage 7D (User Guide Generation)
- If FAIL due to deployment config: fix config, redeploy, re-run 7V
- If FAIL due to code regression: rollback deployment (git revert), investigate, fix, redeploy, re-run 7V

## Issues Found
[Detailed list of any issues with severity and recommended action]

## Screenshots
[Reference to screenshot files in ./screenshots/production/]
```

## Rollback Guidance

If a critical failure is found:

1. **Configuration-only** (env var, DNS, CDN cache):
   - Fix the configuration directly on the hosting platform
   - Re-run the failing checks to verify the fix
   - No code rollback needed

2. **Code regression** (something that passed in 6V but fails in production):
   - **Vercel**: `bunx vercel rollback` or redeploy the previous known-good commit
   - **Convex**: Redeploy the previous known-good backend version
   - **Other hosts**: Use the hosting platform's rollback mechanism or `git revert` + redeploy
   - Document the rollback in the report

3. **After rollback or fix**:
   - Re-run this smoke check against the corrected deployment
   - Document the root cause for future prevention

## Test Account Cleanup

**Production data hygiene**: Minimize test data in production. Use clearly identifiable names (e.g., `smoke-test-YYYY-MM-DD-xxxxx`). Clean up immediately after verification.

After verification completes:
- Delete or deactivate any test accounts/organizations created during the smoke test
- If the app uses soft delete, mark test entities with `deletedAt` immediately
- If cleanup is not possible without admin access, document the test account details for manual cleanup
