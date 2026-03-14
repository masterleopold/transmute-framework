# Implementation Detailed Guide — Stage 5 Teammate Instructions & Coordination Protocol

This reference contains the full teammate spawn instructions, testing pitfalls, anti-stub quality gates, and coordination protocol for Stage 5: Feature Implementation Orchestrator.

## Stack Adaptation

Replace all `npm run` commands with your project's package manager from `CLAUDE.md` or `plancasting/tech-stack.md`. Adapt all file paths to your actual stack:
- `convex/` -> your backend directory
- `convex/schema.ts` -> your schema/migration files
- Convex functions -> your backend functions/endpoints
- `ConvexError` -> your error handling pattern
- `useQuery`/`useMutation` -> your data fetching hooks
- `npx convex dev` -> your backend dev command
- `src/app/` -> your frontend pages directory

Always read `CLAUDE.md` Part 2 for your project's actual conventions.

---

## Step 1: Feature Analysis (Lead Only)

Read the following PRD/BRD sections filtered to the current feature:
- Feature map (`02-feature-map-and-prioritization.md`)
- Data model (`11-data-model.md`)
- User stories (`04-epics-and-user-stories.md`)
- Screen specifications (`08-screen-specifications.md`)
- API specifications (`12-api-specifications.md`)
- Business rules (`plancasting/brd/14-business-rules-and-logic.md`)
- Security requirements (`plancasting/brd/13-security-requirements.md`)
- User flows (`06-user-flows.md`)
- Interaction patterns (`09-interaction-patterns.md`)

Additionally, for the full-build approach:
- Identify cross-feature dependencies (data consumed from or produced for other features)
- Identify cross-feature integration points (existing features needing updates)
- Check if previously completed features need minor updates

### Cross-Feature Integration Levels

Classify each integration point:
- **Level 1 (Data-only)**: Feature A writes to a table that Feature B reads. No UI changes needed.
- **Level 2 (UI reference)**: Feature A's output appears in Feature B's UI. Requires hook/component updates.
- **Level 3 (Workflow)**: Completing Feature A enables/changes Feature B's behavior. Requires navigation/conditional rendering updates + E2E test updates.

### Feature Implementation Brief

Produce a brief containing: Feature ID/name, priority, queue position, user stories with acceptance criteria, screens/components, backend functions, schema changes, business rules, security considerations, cross-feature integration notes (with levels and affected files), test scenarios, and cross-feature test scenarios.

Save to `./plancasting/_briefs/<feature-id>.md` with YAML frontmatter (featureId, featureName, priority, status, dependencies).

---

## Step 2: Backend Implementation (Teammate: "backend")

Spawn with the Feature Implementation Brief.

### Teammate Instructions

0. **SCAFFOLD INVENTORY** (MANDATORY before writing code):
   - List ALL existing scaffold files for this feature in backend directory
   - Read each file; note which have scaffold bodies vs empty
   - Implement business logic INSIDE existing files. Do NOT create duplicates.
   - Read `plancasting/_scaffold-manifest.md` Backend Functions section if it exists
   - Only create NEW files if genuinely missing from scaffold

1. **SCHEMA CHANGES**: Add new tables/indexes. Additive only — do NOT remove/rename existing. Verify existing functions still work with changes.

2. **BACKEND FUNCTIONS**: For each API endpoint:
   a. Determine function type
   b. Implement full argument validation
   c. Implement authentication checks
   d. Implement business rule validation
   e. Implement COMPLETE handler logic — no stubs, no TODOs
   f. Add JSDoc with PRD/BRD traceability

3. **CROSS-FEATURE INTEGRATION**: Update existing backend functions, add cross-domain functions, verify shared data.

4. **BACKEND TESTS**: One test case per acceptance criterion. Test validation, auth, happy path, errors, edge cases.

### Backend Testing Rules

a. **Module map**: Always import `modules` from test utilities and pass to test setup. Never call without module map.

b. **Soft-delete filter compatibility**: Always include `deletedAt: null` for tables with soft-delete filters.

c. **Environment variables for actions**: Set required env vars in `beforeAll`/`beforeEach`.

d. **Skip vs test classification**: Actions making external HTTP calls should be `it.skip()`. Test internal mutations/queries they delegate to instead.

e. **Schema-first test data**: Always read schema for valid enum values, required fields, index definitions.

f. **Auth error expectations**: Non-member access to resource looked up BEFORE permission check expects `NOT_FOUND`, not `FORBIDDEN`.

g. **Return value verification**: Read the ACTUAL `returns` validator before writing assertions.

h. **OAuth redirect_uri consistency**: MUST be identical in authorization initiation AND callback handler.

i. **External API identifiers**: NEVER invent API model IDs. Always reference official docs.

j. **Error logging for external calls**: Every non-ok `fetch()` MUST log status and body before returning user-friendly fallback.

k. **Environment variable naming consistency**: All references MUST use the EXACT same variable name. Cross-check against `.env.local.example`.

l. **Third-party service limits**: NEVER hardcode timeout/size/rate values without verifying provider's actual limits.

m. **Quota rollback on failure**: If operation increments usage counter BEFORE executing work, it MUST decrement on failure.

5. **VERIFICATION**: Start backend dev server (verify no errors), run feature tests, run ALL backend tests (no regressions).

---

## Step 3: Frontend Implementation (Teammate: "frontend")

Blocked by Step 2 completion. Spawn with brief AND backend teammate's completion message.

### Teammate Instructions

**CRITICAL — Read first**: CLAUDE.md (Design & Visual Identity), plancasting/tech-stack.md Design Direction, design tokens, Feature Brief.

**DESIGN GUIDELINES**: Execute aesthetic direction from plancasting/tech-stack.md. Match design tokens. Use selected UI component library. Avoid generic AI aesthetics.

0. **SCAFFOLD INVENTORY** (MANDATORY):
   - List ALL existing scaffold files: components, hooks, pages
   - Read each file; note scaffold bodies vs real code
   - Read `plancasting/_scaffold-manifest.md` for component-to-page and hook-to-component mappings
   - YOUR RULE: Implement INSIDE existing scaffold files. Do NOT rebuild inline in pages.
   - Only create NEW files if genuinely missing from scaffold
   - If scaffold file + inline page UI exist for same purpose: DELETE inline, use scaffold component

1. **CUSTOM HOOKS**: Create/update hooks wrapping backend functions. Include loading, error, optimistic updates. Update existing hooks if this feature's data appears in already-completed features.

2. **COMPONENTS**: Implement with all states. Interactive behaviors from screen spec. ARIA + keyboard nav. Responsive with INTENTIONAL layout changes. Design quality: tokens only, micro-interactions, matching skeletons, composed empty states, styled error states.

3. **CROSS-FEATURE UI UPDATES**: Update existing components, navigation, dashboard/summary components, shared UI patterns.

4. **PAGES**: Wire components into routes. Add loading.tsx (skeleton), error.tsx (styled boundary). Use SSR data loading where SEO matters. Add metadata exports.

5. **FEATURE FLAGS**: Wrap with FeatureGate where applicable. Implement fallback UIs.

6. **COMPONENT TESTS**: Test all states, interactions, accessibility, cross-feature integrations.

### Frontend Testing Pitfalls

a. **Portal components**: Mock `react-dom` createPortal to render inline instead of into `document.body`.

b. **SVG className**: Use `getAttribute("class")` instead of `.className` in jsdom.

c. **axe + canvas**: Stub `HTMLCanvasElement.prototype.getContext` in test setup.

d. **Multiple role="status"**: Use `getAllByRole("status")` with `.find()`.

e. **exactOptionalPropertyTypes**: Don't pass `prop={undefined}`.

f. **Button visibility vs enablement mismatch**: Verify every render condition state is reachable by enable condition.

7. **STUB ELIMINATION** (CRITICAL):
   a. Grep all files for stub patterns. Zero matches required.
   b. Every component imports/uses hooks or receives real props.
   c. Every component renders meaningful interactive UI.
   d. Every component file is imported by at least one page.
   e. If scaffold component + inline page UI exist: preserve scaffold file, move best code there, refactor page.

8. **I18N**: If enabled, use translation keys for all user-facing strings. If not, use hardcoded strings following conventions.

9. **VERIFICATION**: Run typecheck (full project), lint, feature tests, all component tests, stub scan (zero results).

---

## Step 4: E2E Tests (Teammate: "e2e-tester")

Blocked by Step 3 completion.

### Teammate Instructions

1. **FEATURE E2E TESTS**: Playwright tests in `e2e/<feature-name>.spec.ts`. One per user flow. Cover happy path, alternative paths, error paths. Test responsive on mobile + desktop.

2. **CROSS-FEATURE E2E TESTS**: Write/update tests in `e2e/integration/`. Test integrated journeys spanning features.

3. **REGRESSION CHECK**: Run ALL existing E2E tests. Start dev server first, wait for ready. Categorize failures: intentional change (update test) vs bug (report to lead).

4. **VERIFICATION**: Run `test:e2e -- e2e/<feature-name>.spec.ts` for new tests.

**Test data cleanup**: Ensure tests clean up created data. Use `afterEach`/`afterAll` hooks.

---

## Step 5: Quality Gate (Lead Only)

1. Collect results from all teammates.
2. Run full project typecheck, all tests, all E2E.
3. Fix regressions (spawn fix teammate if needed).
4. Cross-feature verification for files modified in other features.
5. Module map sync check (add new backend files if missing).
6. Traceability check (every user story has backend + frontend + test).
7. Design consistency check (tokens, aesthetic, visual consistency).
8. Update scaffold manifest for new files.
9. Update `plancasting/_progress.md` — mark Done, record cross-feature mods, assumptions, PRD gaps.
10. Shutdown teammates.
11. Proceed to next feature — do NOT stop at priority boundaries.

---

## Handling Failures

- **Build errors**: Send to responsible teammate. Spawn "debugger" if unresolvable.
- **Test failures (regression)**: Never skip/delete tests. Diagnose: intentional change or bug.
- **Dependency conflicts**: Mark as Blocked in `plancasting/_progress.md`. Continue with non-blocked features. After each completion, scan for unblocked features.
- **Schema conflicts**: Lead resolves before spawning backend teammates.
- **Cross-feature breaks**: Highest priority. Fix immediately before proceeding.

---

## Anti-Stub Quality Gates

### Stub Detection Rules

Before marking ANY feature as Done:

1. **No placeholder text**: Grep for `implementation pending`, `pending feature build`, `⚠️ STUB`, `TODO [Stage 5]`, `Coming soon`, `Not yet implemented`, `PLACEHOLDER`. Zero matches.

2. **Functional component bodies**: Import/use hooks or receive real props. Render meaningful UI. Handle all states. Wire interactive elements.

3. **No orphan components**: Every file imported by at least one page.

4. **Page-level data flow**: Real hook data, functional form submissions, real routes.

### Automated Stub Scan

At each quality gate:
```bash
# Scan for stub patterns
grep -rn "implementation pending\|pending feature build\|⚠️ STUB\|TODO \[Stage 5\]\|Coming soon\|Not yet implemented\|PLACEHOLDER" <modified-files> | grep -v 'placeholder="\|Placeholder='

# Scan for orphan components
for file in <new-component-files>; do
  component_name=$(basename "$file" .tsx)
  if ! grep -rl "from.*${component_name}\|import.*${component_name}" src/ --include="*.tsx" --include="*.ts" | grep -v "$file"; then
    echo "ORPHAN: $file is never imported"
  fi
done
```

If either scan finds issues, send back to frontend teammate. Do NOT mark as Done.

---

## Full-Product Completion Sequence

After ALL features are Done:

### 1. Full Integration Test Suite
Run typecheck, lint, all tests, all E2E. All must pass.

### 2. Cross-Feature Integration Sweep
Spawn "cross-feature-auditor" to verify cross-feature user flows, data flows, shared UI aggregations, write additional E2E tests for gaps.

### 3. Onboarding Flow Verification
Spawn "onboarding-auditor" (if PRD specifies onboarding) to verify progressive disclosure, first-time experience, empty states, write onboarding E2E tests.

### 4. Performance Validation
Lightweight sanity check only — not a substitute for Stage 6C. Spawn "performance-auditor" for bundle size, Lighthouse scores, query performance. Flag critical blockers only.

**Post-Audit Gate**: If any auditor reports critical issues, fix before Final Report. Minor issues go to Known Issues section.

### 5. Final Implementation Report

Generate `plancasting/_implementation-report.md` with:
- **Completion Summary**: Features (X of X = 100%), files, backend functions, components, hooks, tests
- **PRD Coverage**: User stories, screen specs, API specs, user flows (target: 100%)
- **Cross-Feature Integration**: Interactions documented, cross-feature E2E tests, issues resolved
- **Quality Metrics**: Zero TS/lint errors, test pass rates, bundle size, Lighthouse scores
- **Assumptions** (consolidated)
- **PRD Gaps** (ambiguities/contradictions)
- **Known Issues / Technical Debt**
- **Launch Readiness Assessment**

---

## Session Recovery

1. Read `plancasting/_progress.md` for feature status.
2. In Progress: check `plancasting/_briefs/` for where implementation stopped.
3. Needs Re-implementation (set by Stage 5B): read audit report for specific gaps. Focus frontend on replacing stubs. Only re-run backend if audit flags backend issues.
4. Blocked: check if dependency is now Done. If yes, unblock and queue.
5. Resume from first incomplete step. Do NOT restart.

---

## Critical Rules

1. NEVER skip a feature.
2. NEVER skip Feature Analysis.
3. NEVER spawn frontend until backend confirms.
4. NEVER spawn E2E until frontend confirms.
5. NEVER proceed to next feature until quality gate passes.
6. NEVER proceed past cross-feature breaks.
7. ALWAYS read CLAUDE.md at startup. NEVER modify Part 1.
8. ALWAYS update `plancasting/_progress.md` after each cycle.
9. ALWAYS run FULL test suite at each quality gate.
10. Split 15+ file features into sub-features.
11. ALWAYS run Full-Product Completion Sequence before final report.
12. Final report must show 100% PRD coverage.

---

## Note on Stage 5B

After Stage 5 completes, Stage 5B will run a FRESH full-codebase audit looking for:

1. **Stub pattern**: Frontend components remain as scaffolds with placeholder text (~80% of issues).
2. **Duplication pattern**: Frontend teammate builds UI inline in page files instead of inside scaffold component files, creating orphan components.

The mandatory SCAFFOLD INVENTORY step is the PRIMARY defense. However, if context window is becoming saturated late in a long feature queue, prioritize BACKEND completeness — backend stubs are harder to fix in 5B.
