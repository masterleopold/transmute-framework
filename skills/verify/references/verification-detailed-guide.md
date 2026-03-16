# Visual & Functional Verification — Detailed Guide

## Stage 6V: Live App Verification Against PRD Specifications

This reference contains the full detailed instructions for Stage 6V verification, including teammate prompts, failure patterns, and report templates.

## Why This Stage Exists

All prior stages (5B, 6A-6H) are static code analysis -- they read source files but never launch the application. This creates a critical blind spot: code that looks correct in files may fail at runtime due to broken imports, missing data hooks, SSR hydration errors, incorrect routing, invisible components, or mismatched API contracts. This stage closes that gap by running the app in the DEV environment and verifying every feature works as specified.

Production-specific deployment issues (env vars, CDN, CSP) are covered separately in Stage 7V (Production Smoke Verification). After deploying to production, ALWAYS run Stage 7V to catch environment-specific failures that don't exist in dev.

**Stage Sequence**: Stage 5B -> 6A (Security) -> 6B (Accessibility) -> 6C (Performance) -> 6E (Refactor) -> 6F (Seed Data) -> 6G (Resilience) -> 6D (Documentation) -> 6H (Pre-Launch) -> **6V (this stage)** -> 6R (Runtime Remediation, only if 6V finds failures) -> 6P or 6P-R (Visual Polish or Redesign) -> Deploy -> 7V (Production Smoke) -> 7D (User Guide)

## Known Failure Patterns

Based on observed AI-assisted build outcomes, these are the most common runtime issues that static analysis misses, ordered by frequency (categories may overlap):

### Frontend Runtime Failures (~60% of issues)
1. **SSR hydration mismatches**: Server renders one state, client hydrates with another -- causes flickering, missing content, or React errors in console
2. **Broken data hooks**: Component renders but `useQuery` returns `undefined` indefinitely -- shows permanent loading spinner or blank section
3. **Missing route segments**: Page file exists but URL returns 404 -- usually a misnamed directory or missing `page.tsx` in a nested route
4. **CSS/Tailwind purge gaps**: Classes used in dynamic expressions (`bg-${color}-500`) get purged -- elements render without expected styles
5. **Missing i18n keys at runtime**: Component calls `t("key.that.does.not.exist")` -- renders the raw key string or throws
6. **Event handlers not wired**: Button renders but `onClick` does nothing -- handler references a mutation that was never imported or is called incorrectly
7. **Auth redirect loops**: Protected page redirects to login, login redirects back -- infinite loop with no visible error
8. **Modal/dialog not rendering**: Trigger button exists but the modal component was never mounted in the page tree -- click does nothing

### Backend Runtime Failures (~25% of issues)
1. **Real-time subscription failures**: Query returns data initially but never updates -- real-time features appear broken
2. **Action timeout**: External API call in an action takes too long -- user sees loading spinner forever
3. **Auth context mismatch**: Frontend sends auth token but backend rejects it -- 401 errors on pages that should work
4. **Seed data dependency**: Feature works only with specific data shape -- crashes or shows empty on fresh database
5. **Soft-delete filter mismatch in tests**: Test data inserted directly without `deletedAt: null` will be invisible to queries that filter on that field

### Test Data & Seeding Failures (~15% of issues -- blocks ALL authenticated verification)
1. **Seed endpoint not implemented**: `globalSetup.ts` may reference a seed API endpoint that was never built
2. **Test users not in auth provider**: Users must be created through the auth provider's API or the app's signup flow -- not by directly inserting database records
3. **Dev server startup in non-interactive mode**: BaaS dev servers often require interactive terminal input
4. **Missing BaaS URL env var**: Frontend framework client throws immediately if its URL env var is undefined

### Navigation & Routing Failures (~20% of issues)
1. **Dead links in shared layouts**: Sidebar, header, footer, and mobile nav contain links to routes that don't exist
2. **Conditional navigation state errors**: Tab navigations that enable/disable based on entity status may be incorrectly configured
3. **Auth middleware redirect failures**: Public routes not whitelisted in middleware get caught by auth guards
4. **Redirect loops**: Protected page -> `/login` -> session check -> redirect back -- infinite loop
5. **Button click does nothing**: Button renders and is clickable but `onClick` handler is broken
6. **Sub-navigation tab 404s**: Tabbed layouts have links to sub-routes where the `page.tsx` was never created
7. **Mobile-only navigation gaps**: Mobile bottom bar or hamburger menu contains different links than the desktop sidebar

### Integration Failures (~15% of issues)
1. **Cross-feature navigation dead ends**: Feature A links to Feature B but uses wrong URL or passes wrong params
2. **Dashboard aggregation showing zeros**: Dashboard widgets query data that hasn't been seeded or the query joins are broken
3. **Form -> backend -> UI feedback gap**: Form submits successfully but the success toast or redirect doesn't fire

**Screenshot baseline**: Establish a visual baseline by capturing screenshots of all Feature Scenario pages at the START of 6V. Store in `./screenshots/visual-verification/baseline/`. These enable regression comparison.

## Execution Modes

This stage uses BOTH execution methods in every session:

### Mode A: Generate & Run Playwright Tests
- Read PRD specs -> generate Playwright test files -> execute via the project's test runner
- Produces reusable test artifacts saved to `e2e/verification/`
- Generated tests MUST: use `getByRole`/`getByText`/`getByLabel` selectors (preferred), or `getByTestId` as fallback; reuse existing helpers from `e2e/helpers/`; handle eventually-consistent data with `expect.poll()` or `expect.toPass()`

### Mode B: Direct Browser Interaction (AI Vision)
- Use Playwright browser tools to navigate pages directly
- Take screenshots, check DOM elements, verify interactions in real-time
- Analyze screenshots using AI vision capabilities to catch visual/aesthetic issues that DOM assertions miss

## Scope Modes

- **`full`** -- All screens in `plancasting/prd/08-screen-specifications.md`. ~30-60 min.
- **`critical`** -- P0/P1 features only. ~15-30 min.
- **`diff`** -- Only screens related to files changed since last verification. ~10-20 min. Falls back to `full` if `last-verified-commit.txt` does not exist.

Default: `full`.

## Teammate Architecture

### Teammate 1: "automated-page-verifier"
**Scope**: Systematic page-by-page verification -- console errors, HTTP errors, key elements, accessibility

Tasks:
0. Unauthenticated Public Route Verification (MUST run FIRST -- before logging in)
1. Navigation & Load Verification -- navigate to each screen, verify load, capture console errors, take screenshots
2. Component Presence Verification -- check expected elements exist and are visible
3. State Verification -- verify default, empty, loading, error states
4. Link Integrity Crawl -- extract ALL links from each page, verify destinations load
5. Sub-Navigation Completeness Check -- click EVERY tab in settings, entity detail views, etc.
6. Accessibility Quick Check -- run axe-core
7. Generate Playwright Test Files (Mode A)

### Teammate 2: "acceptance-criteria-verifier"
**Scope**: Execute Given/When/Then acceptance criteria from user stories

Tasks:
1. Parse Acceptance Criteria from Feature Scenarios (FS-NNN) and Negative Scenarios (NS-NNN)
2. Execute Each Criterion -- use Playwright or direct browser interaction
3. Generate Playwright Test Files
4. Cross-Feature Flow Verification -- execute complete flows end-to-end
5. Dead Route Detection -- navigate to EVERY route constant
6. Auth Redirect Verification -- test middleware/auth layer redirect behavior

### Teammate 3: "visual-ai-reviewer"
**Scope**: AI Vision review of screenshots against screen specifications
**Dependency**: Spawns AFTER Teammate 1 completes.

Tasks:
1. Collect Screenshots at 3 breakpoints (Desktop 1440px, Tablet 768px, Mobile 375px)
2. Visual Spec Compliance Review -- layout, component, content, responsive, design consistency
3. Dark Mode Review (if applicable)

### Teammate 4: "responsive-and-interaction-verifier"
**Scope**: Interactive behavior, keyboard navigation, and cross-browser verification

Tasks:
1. Interactive Behavior Verification -- forms, modals, dropdowns, tabs, pagination, search, drag & drop
2. Systematic Button Action Verification -- find ALL buttons and verify each one's action
3. Keyboard Navigation -- tab order, focus rings, Enter/Space, Escape, arrow keys
4. Responsive Functional Testing -- test interactions at mobile breakpoints
5. Cross-Browser Quick Check -- Chromium, Firefox, WebKit

**Sequencing**: Spawn Teammates 1, 2, and 4 immediately in parallel. Wait for Teammate 1 to complete, then spawn Teammate 3.

## Unauthenticated Route Verification (Phase 1 Step 4)

This step catches middleware/auth guard issues that ONLY affect unauthenticated users. The lead MUST perform this check in a clean browser session with NO auth cookies/tokens.

a. Identify all public routes from middleware and PRD
b. Open a fresh browser context (no cookies, no localStorage, no session tokens)
c. Navigate to EVERY public route and verify: HTTP 200 (NOT 302 redirect), correct content, no auth console errors
d. Test unauthenticated access to PROTECTED routes -- verify proper redirect to login
e. Record results in the Unauthenticated Access section
f. Flag ANY public route that incorrectly redirects to login as CRITICAL

Minimum public routes to test:
| Route | Expected |
|-------|----------|
| `/` | Landing page loads |
| `/login` | Login form renders |
| `/signup` | Signup form renders |
| `/pricing` | Pricing content loads |
| `/privacy` | Privacy policy text loads |
| `/terms` | Terms of service text loads |
| `/forgot-password` | Password reset form renders |
| `/help` | Help center content loads |
| `/sitemap.xml` | Valid XML response |
| `/robots.txt` | Text response with rules |
| `/api/health` | JSON status response |

## Test User Verification (Phase 1 Step 5)

If login fails, try these approaches in order:
a. Seed endpoint (check globalSetup.ts)
b. Auth provider CLI (create users through signup action directly)
c. UI signup (use Playwright to navigate to `/signup`)

If all three methods fail, ABORT and report.

## Navigation Inventory (Phase 1 Step 6)

a. Route constants -- list ALL defined routes, cross-reference against page files
b. Shared layout navigation -- read ALL layout components with `<Link>` or `router.push()`
c. Middleware route protection -- extract PUBLIC_ROUTES arrays, cross-reference
d. Compile Navigation Checklist with every unique href/route

## Teammate Assignment & Test User Isolation (Phase 1 Step 7)

- Teammate 1: read-only test user (basic/starter tier)
- Teammate 2: write-access test user (pro/advanced tier)
- Teammate 3: same user as Teammate 1 (read-only)
- Teammate 4: elevated permissions test user (enterprise/admin tier)

## Gate Decision (Dual System)

The gate uses TWO systems -- the final gate is the WORSE of the two:

**Percentage-based system**:
- **PASS**: Zero critical failures, >90% acceptance criteria pass, all pages load
- **CONDITIONAL PASS**: 1-3 high-severity issues, >80% criteria pass
- **FAIL**: Any critical failure (page won't load, core flow broken, auth broken)

**Fixability-based category system** (uses `6V-` prefix):
- **6V-A** (auto-fixable): broken links, dead code, incorrect imports
- **6V-B** (semi-auto): stub components, missing loading states. Fixable by: adding component logic + local state, wiring existing hooks to components, adding inline handlers. NOT fixable (escalate to C) if it requires: restructuring state management, creating new hooks, changing API contracts, or modifying database schema.
- **6V-C** (human judgment): architectural issues, design decisions

These categories classify *fixability*, not severity. A critical bug that's easy to fix is 6V-A; a minor issue requiring architectural change is 6V-C. Components with mixed categories are classified by most severe issue.

**Dual-system decision matrix** -- use the WORSE of the two systems:

| Percentage | Categories Present | Final Gate | Next Stage |
|---|---|---|---|
| PASS (>90%) | None (zero issues) | PASS | -> 6P/6P-R |
| PASS (>90%) | A/B only | CONDITIONAL PASS | -> 6R -> 6P/6P-R |
| PASS (>90%) | C only | PASS | -> 6P/6P-R (document C for human) |
| PASS (>90%) | Mixed A/B + C | CONDITIONAL PASS | -> 6R -> 6P/6P-R (document remaining C) |
| CONDITIONAL (80-90%) | A/B present | CONDITIONAL PASS | -> 6R -> 6P/6P-R |
| CONDITIONAL (80-90%) | C only | CONDITIONAL PASS | -> 6P/6P-R (document C for human) |
| FAIL (<80%) | Any | FAIL | Manual fix + re-run 6V |

## Flaky Scenario Handling

A flaky scenario fails inconsistently (fails once, passes on retest).
- Retest a failing scenario once. If it passes on retest: mark as "FLAKY -- cause TBD" in the Issues table.
- In 6V: flaky scenarios are informational (do not count toward gate failure).
- In 7V (production): flaky scenarios count as FAIL -- production must be deterministic.

## Phase 4: Verification Report

### Report Template

```markdown
# Visual & Functional Verification Report -- Stage 6V

## Summary
- **Verification Date**: [date]
- **Scope**: full / critical / diff
- **Base URL**: [dev server or production URL]
- **Screens Verified**: [n] / [total in scope]
- **Acceptance Criteria Tested**: [n] / [total in scope]

## Scenario Generation Summary
- Feature Scenarios (FS): [n] generated, [n] executed
- Auth Context Scenarios (AS): [n] generated, [n] executed
- Entity State Scenarios (ES): [n] generated, [n] executed
- Role Permission Scenarios (RS): [n] generated, [n] executed
- Negative Scenarios (NS): [n] generated, [n] executed
- Standalone page checks (gap-fill): [n]
- **Total test scenarios**: [n]

## Results Overview

### Feature Scenario Results (PRIMARY)
- Scenarios passing (all steps): [n] / [total]
- Scenarios failing: [n] / [total]
- Scenarios blocked: [n] / [total]

### Page-Level Results (SECONDARY)
- Pages loading without errors: [n]
- Pages with load failures: [n]
- Pages with console errors: [n]

### Unauthenticated Access Results
- Public routes tested: [n]
- Public routes loading correctly: [n]
- Public routes incorrectly redirecting to login: [n]

### Acceptance Criteria Results
- Criteria passing: [n] / [total]
- Criteria failing: [n] / [total]
- Criteria blocked: [n] / [total]

### Visual Compliance Results
- Screens matching spec: [n]
- Minor deviations: [n]
- Significant mismatches: [n]

### Navigation & Link Integrity Results
- Total links crawled: [n]
- Broken links: [n]
- Dead route constants: [n]
- Public routes blocked by middleware: [n]

### Button Action Results
- Total buttons tested: [n]
- No visible action on click: [n]
- Crashes/errors on click: [n]

### Sub-Navigation Results
- Tabbed layouts tested: [n]
- Broken tabs: [n]

### Responsive & Interaction Results
- Interactive elements tested: [n]
- Broken interactions: [n]
- Responsive issues: [n]
- Cross-browser issues: [n]

## Critical Failures (must fix before deploy)
[List all Critical/High severity issues]

## Issue Details by Feature
### FEAT-NNN: [Feature Name]
[Grouped issues with screenshots and AC references]

## Generated Test Artifacts
- Playwright test files: `e2e/verification/*.spec.ts`
- Screenshots: `./screenshots/automated/`, `./screenshots/criteria/`, `./screenshots/vision/`

## Gate Decision
[Apply dual-system decision matrix -- use the WORSE of percentage and category systems]

## Failure Categorization (for 6R routing)

**Category definitions** (for 6R routing):
- **6V-A** (auto-fixable): broken links, dead code, incorrect imports -- 6R fixes automatically
- **6V-B** (semi-auto): stub components, missing loading states -- 6R fixes with effort. Fixable by: adding component logic + local state, wiring existing hooks to components, adding inline handlers. NOT fixable (escalate to C) if it requires: restructuring state management, creating new hooks, changing API contracts, or modifying database schema.
- **6V-C** (human judgment): architectural issues, design decisions -- 6R cannot fix

| # | Ref | Issue | Category | Rationale |
|---|-----|-------|----------|-----------|
| 1 | SC-NNN | [description] | 6V-A (auto-fix) | [why auto-fixable] |

- Category 6V-A (auto-fixable): [n]
- Category 6V-B (semi-auto): [n]
- Category 6V-C (human judgment): [n]

## Next Steps
- If PASS: skip 6R -> proceed to Stage 6P or 6P-R (Visual Polish or Redesign)
- If CONDITIONAL PASS with 6V-A/6V-B issues: proceed to Stage 6R
- If CONDITIONAL PASS with ONLY 6V-C issues: skip 6R -> proceed to Stage 6P or 6P-R
- If FAIL: fix critical issues manually, then re-run Stage 6V

## Recommendations
[Specific fixes needed, grouped by priority]
```

## Critical Rules

1. ALWAYS start the dev server and verify it's accessible before spawning teammates. If the server doesn't start within 60 seconds, ABORT.
2. NEVER skip the AI vision review (Teammate 3).
3. NEVER mark a page as PASS if it has console ERRORS. Console WARNINGS from third-party libraries or framework dev-mode messages should be noted but do not constitute a FAIL.
4. ALWAYS test with seeded data.
5. ALWAYS take screenshots on failure.
6. ALWAYS map findings back to PRD identifiers (SC-NNN, US-NNN, FEAT-NNN).
7. ALWAYS generate Playwright test files (Mode A) even when using direct browser interaction (Mode B).
8. If a screen requires a specific user role, log in as that role.
9. This stage FINDS issues -- it does NOT fix them. Fixes happen in Stage 6R.
10. NEVER let one teammate's actions corrupt state for another.
11. If a page does not load within 30 seconds, mark as FAIL and move on.
12. For eventually-consistent backends, use `expect.poll()` or retry assertions with up to 10-second timeouts.
13. ALWAYS verify test user seeding succeeded BEFORE spawning teammates.
14. ALWAYS crawl links from shared layouts (sidebar, header, footer, mobile nav).
15. ALWAYS test navigation at BOTH desktop and mobile viewports.
16. ALWAYS click buttons and verify their action -- do NOT just check that the button exists in the DOM.
17. ALWAYS test auth middleware redirects for ALL public routes.
18. ALWAYS test conditional navigation states with entities in DIFFERENT lifecycle stages.
19. ALWAYS test public routes from a FRESH unauthenticated browser context BEFORE logging in.
