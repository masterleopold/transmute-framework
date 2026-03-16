# Transmute — Feature Scenario Generation Guide

## Shared Reference for Stages 6V and 7V

> **NOTE**: This is a shared reference guide read by the verify skill (Stage 6V, Phase 1) and the smoke skill (Stage 7V, Phase 1). It is not invoked directly — the parent skill loads it via `${CLAUDE_SKILL_ROOT}/references/`.

This document defines how to dynamically generate comprehensive test scenarios from PRD specifications and codebase analysis. It is referenced by:
- **Stage 6V** (Visual & Functional Verification) — generates FULL scenario matrix
- **Stage 7V** (Production Smoke Verification) — generates SMOKE scenario matrix (P0/P1 only)

Note: Stage 6R (Runtime Remediation) uses the 6V scenario matrix output (`./plancasting/_audits/visual-verification/feature-scenario-matrix.md`) to verify fixes. 6R does NOT re-generate the scenario matrix — it reuses the 6V matrix to re-test fixed issues.

## Why Dynamic Scenarios Instead of Static Page Lists

Static page lists ("check /dashboard loads, check /settings loads") miss:
- **Multi-step workflows**: A project creation flow spans 5 pages and 12 button clicks — testing each page in isolation doesn't verify the flow works end-to-end
- **Entity state dependencies**: The Deploy page only works when a project is in `ready_to_deploy` status — a page-load test with a `draft` project passes trivially but misses the real functionality
- **Role-based access variations**: An admin sees different buttons than a viewer on the same page — testing with one role misses permission issues
- **Auth context transitions**: The signup flow transitions from unauthenticated to authenticated — testing only authenticated pages misses the transition

Dynamic scenarios solve this by generating test **sequences** that mirror real user journeys, with explicit auth context, entity prerequisites, and expected outcomes at each step.

## Scenario Types

### Type 1: Feature Scenarios (FS-NNN)
Complete end-to-end workflows that test a feature from start to finish.
- **Source**: User Flows (`plancasting/prd/06-user-flows.md`) + User Stories (`plancasting/prd/04-epics-and-user-stories.md`)
- **Structure**: Multi-step sequence following a user flow's happy path
- **Example**: "First-Time Signup → Onboarding → Dashboard" (UF-001)

### Type 2: Auth Context Scenarios (AS-NNN)
Test the same routes/features from different authentication states.
- **Source**: Information Architecture (`plancasting/prd/07-information-architecture.md`) + Middleware analysis
- **Structure**: Matrix of routes × auth states (unauthenticated, each role)
- **Example**: "Visit /dashboard as unauthenticated → expect redirect; as starter → expect dashboard; as admin → expect admin features visible"

### Type 3: Entity State Scenarios (ES-NNN)
Test features that behave differently based on entity lifecycle state.
- **Source**: Feature Map (`plancasting/prd/02-feature-map-and-prioritization.md`) + Schema analysis
- **Structure**: Matrix of features × entity states
- **Example**: "Project tabs at each status: draft (3 tabs enabled), configuring (4 tabs), casting (5 tabs), ..., deployed (9 tabs)"

### Type 4: Role Permission Scenarios (RS-NNN)
Test that RBAC rules are enforced correctly.
- **Source**: User Stories with role-specific criteria + Backend auth helpers
- **Structure**: Matrix of actions × roles (owner, admin, member, viewer)
- **Example**: "Delete project: owner=allowed, admin=allowed, member=denied, viewer=denied"

### Type 5: Negative Scenarios (NS-NNN)
Test error handling, validation, and edge cases.
- **Source**: Acceptance criteria error cases + Screen spec error states
- **Structure**: Trigger → expected error behavior
- **Example**: "Submit empty business plan → validation error shown; Upload 20MB file → file size error shown"

## Generation Algorithm

### Step 1: Read All PRD Sources

Read these files and extract structured data:

| File | Extract |
|------|---------|
| `plancasting/prd/02-feature-map-and-prioritization.md` | All FEAT-NNN with priority (P0-P3), dependencies, effort |
| `plancasting/prd/04-epics-and-user-stories.md` | All US-NNN with acceptance criteria (Given/When/Then), persona, role requirements |
| `plancasting/prd/06-user-flows.md` | All UF-NNN with entry/exit points, happy path steps, alternative paths, error cases |
| `plancasting/prd/07-information-architecture.md` | All routes with auth requirements, navigation contexts, entity state prerequisites |
| `plancasting/prd/08-screen-specifications.md` | All SC-NNN with component inventories, states, responsive behavior |

### Step 2: Read Codebase Sources

Supplement PRD data with actual implementation:

**Stack Adaptation**: The paths below use Next.js + Convex conventions. Replace with your project's equivalent paths per `plancasting/tech-stack.md` (e.g., `[backend-dir]/auth.*` instead of `convex/auth.ts`).

| Source | Extract |
|--------|---------|
| Route constants (e.g., `src/lib/constants.ts`) | All defined routes — may include routes not in PRD |
| Page files (`src/app/**/page.tsx`) | All implemented pages — may differ from PRD routes |
| Middleware (`src/middleware.ts`) | PUBLIC_ROUTES array, auth redirect logic |
| Auth helpers (e.g., `convex/auth.ts`) | Role definitions, permission checks |
| Schema (e.g., `convex/schema.ts`) | Entity status enums, role enums |
| Layout components | Navigation links, conditional tab logic |
| Hooks directory (`src/hooks/`) | Available data operations per domain |
| E2E tests (`e2e/` or equivalent) | Existing test scenarios — avoid duplicating existing E2E coverage |

### Step 3: Build the Feature Graph

Create a directed graph of features and their dependencies. Dependencies are extracted from:
1. **Explicit dependency fields** in `plancasting/prd/02-feature-map-and-prioritization.md` (if present — look for "Depends on" or "Prerequisites" columns)
2. **User story prerequisites**: If US-005 requires data from FEAT-002, then features behind US-005 depend on FEAT-002
3. **Implicit dependencies**: If FEAT-010 (Deploy) requires FEAT-005 (Implementation) to have run, infer the edge

The following is an illustrative example from a hypothetical project — your product's feature graph should be derived from the PRD feature map (`plancasting/prd/02-feature-map-and-prioritization.md`).

```
FEAT-001 (Auth, P0)
  ↓ enables
FEAT-002 (Org Management, P0) + FEAT-003 (Project Management, P0)
  ↓ enables
FEAT-004 (Business Plan Input, P0) + FEAT-014 (Billing, P1)
  ↓ enables
FEAT-005 (Tech Discovery, P1) → FEAT-006 (Cloud Setup, P1) → FEAT-007 (Pipeline, P1)
  ↓ enables
FEAT-009 (Review, P1) → FEAT-010 (Code Browser, P2) → FEAT-011 (Audits, P1)
  ↓ enables
FEAT-012 (Deploy, P1) → FEAT-013 (Post-Launch, P2)
```

This graph determines:
- **Scenario ordering**: P0 features must be tested before P1 (they're prerequisites)
- **Entity state setup**: To test FEAT-012 (Deploy), you need a project that has passed through FEAT-004→005→006→007→009→011
- **Failure cascade**: If FEAT-001 (Auth) fails, ALL other scenarios are blocked

### Step 4: Generate Feature Scenarios (FS-NNN)

For each User Flow (UF-NNN):

1. **Map to features**: Which FEAT-NNN does this flow exercise? If a user flow references a FEAT-NNN not found in the feature map, include the scenario but flag the discrepancy in the matrix output as a WARN-level note.
2. **Inherit priority**: Use the highest priority of the mapped features
3. **Extract happy path**: Convert the Mermaid flowchart steps into a linear test sequence
4. **Identify auth context**: Does the flow start unauthenticated? Which role is needed?
5. **Identify entity prerequisites**: What entity states must exist before the flow starts?
6. **Map to screens**: Which SC-NNN screens are visited during the flow?
7. **Identify buttons/actions**: What buttons are clicked, what forms are filled at each step?
8. **Define expected outcomes**: What should happen after each step? (page transition, data change, toast, redirect)

**Output format for each Feature Scenario**:
```markdown
### FS-NNN: [Scenario Name]
- **Source**: UF-NNN, FEAT-NNN, US-NNN
- **Priority**: P0 / P1 / P2 / P3
- **Auth Context**: unauthenticated → authenticated / role: [role] / admin
- **Prerequisites**: [entity states, data conditions]
- **Test User**: [which test user account to use]

| Step | Page (SC-NNN) | Action | Expected Result |
|------|--------------|--------|-----------------|
| 1 | /signup (SC-003) | Fill email, password, name. Check terms. Click "Create Account". | Redirect to /onboarding (SC-005). |
| 2 | /onboarding (SC-005) | Answer 3 quiz questions. Click "Continue". | Redirect to /dashboard (SC-010). |
| 3 | /dashboard (SC-010) | Verify personal org created. Verify Starter plan badge. | Dashboard loads with empty project list. |
| ... | ... | ... | ... |

**Acceptance Criteria Covered**: US-001 AC-1, AC-2, AC-3; US-005 AC-1
**Buttons Clicked**: "Create Account", "Next" ×3, "Get Started"
**Forms Filled**: Signup form (email, password, name), Onboarding quiz (3 selects)
**Negative Variants**:
- FS-NNN-E1: Submit with invalid email → validation error shown
- FS-NNN-E2: Submit with weak password → password strength error
- FS-NNN-E3: Submit with existing email → duplicate account error
```

### Step 5: Generate Auth Context Scenarios (AS-NNN)

Build an auth matrix from middleware analysis + route list:

```markdown
### Auth Context Matrix

| Route | Unauthenticated | Starter | Pro | Enterprise | Admin |
|-------|----------------|---------|-----|-----------|-------|
| / | 200 (landing) | 200 (landing) | 200 (landing) | 200 (landing) | 200 (landing) |
| /dashboard | 302 → /login | 200 (dashboard) | 200 (dashboard) | 200 (dashboard) | 200 (dashboard) |
| /settings/billing | 302 → /login | 200 (starter limits) | 200 (pro features) | 200 (enterprise) | 200 (all features) |
| /admin/dashboard | 302 → /login | 403 | 403 | 403 | 200 (admin panel) |
| /projects/[id]/deploy | 302 → /login | 200 (if owner) | 200 (if owner) | 200 | 200 |
```

For 6V: Test EVERY cell in the matrix.
For 7V: Test only the diagonal + unauthenticated column.

### Step 6: Generate Entity State Scenarios (ES-NNN)

For entities with lifecycle states (e.g., project status), generate a scenario per meaningful state:

The following is an illustrative example from a hypothetical project — your product's entity states should be derived from the schema analysis (Step 2).

```markdown
### ES-001: Project Pipeline Tab Availability

| Project Status | Expected Enabled Tabs | Expected Disabled Tabs |
|---------------|----------------------|----------------------|
| draft | Plan, Discovery | Setup, Progress, Review, Code, Audits, Deploy, Hub |
| configuring | Plan, Discovery, Setup | Progress, Review, Code, Audits, Deploy, Hub |
| casting | Plan, Discovery, Setup, Progress | Review, Code, Audits, Deploy, Hub |
| review_needed | Plan, Discovery, Setup, Progress, Review | Code, Audits, Deploy, Hub |
| building | Plan, Discovery, Setup, Progress, Review, Code | Audits, Deploy, Hub |
| quality_check | Plan, Discovery, Setup, Progress, Review, Code, Audits | Deploy, Hub |
| ready_to_deploy | Plan, Discovery, Setup, Progress, Review, Code, Audits, Deploy | Hub |
| deployed | All 9 tabs enabled | None |

**Test method**: Create or use projects in each status. Navigate to the project page. Verify correct tabs are enabled/disabled. Click each enabled tab — verify content loads. Click each disabled tab — verify no navigation occurs.
```

### Step 7: Generate Role Permission Scenarios (RS-NNN)

For each action that has role restrictions:

The following is an illustrative example — your product's roles and actions should be derived from the auth helper analysis (Step 2) and user stories.

```markdown
### RS-001: Project Actions by Role

| Action | Owner | Admin | Member | Viewer |
|--------|-------|-------|--------|--------|
| Create project | ✅ | ✅ | ✅ | ❌ |
| Edit project | ✅ | ✅ | ✅ (own) | ❌ |
| Delete project | ✅ | ✅ | ❌ | ❌ |
| Invite member | ✅ | ✅ | ❌ | ❌ |
| Change member role | ✅ | ✅ (not self) | ❌ | ❌ |
| Deploy | ✅ | ✅ | ❌ | ❌ |
| View project | ✅ | ✅ | ✅ | ✅ |

**Test method**: Log in as each role. Attempt each action. Verify allowed actions succeed and denied actions show appropriate error/disabled state.
```

### Step 8: Generate Negative Scenarios (NS-NNN)

Extract from acceptance criteria error cases and screen spec error states:

The following is an illustrative example — your product's form validations and error cases should be derived from acceptance criteria and screen specifications.

```markdown
### NS-001: Form Validation Errors

| Form | Field | Invalid Input | Expected Error |
|------|-------|--------------|---------------|
| Signup | email | "not-an-email" | "Please enter a valid email" |
| Signup | password | "123" | "Password must be at least 8 characters" |
| Create Project | name | "" (empty) | "Project name is required" |
| Business Plan | file | 20MB PDF | "File size must be under 10MB" |
| Invite Member | email | existing member | "User is already a member" |
```

### Step 9: Prioritize and Filter

**ID convention**: When Stage 7V filters Feature Scenarios for smoke testing, it re-numbers them as SS-NNN (Smoke Scenario) in the smoke scenario matrix. The original FS-NNN source ID is preserved in the 'Source' column for traceability.

**For 6V (Full)**:
- Generate ALL scenario types for ALL features (P0-P3)
- Total: typically 50-100+ scenarios. If the total scenario count exceeds 150, apply these trimming steps in order:
  1. Remove P3 scenarios entirely
  2. Remove P2 negative variants for non-critical features (target 100-120)
  3. Remove P2 Entity State and Role Permission scenarios, keeping only Feature Scenarios for P2
  4. Consolidate related Feature Scenarios that share the same feature into multi-step test scenarios
  5. Split the test execution across multiple teammates rather than reducing coverage further
  6. **Terminal condition**: If count still exceeds 150 after all steps, cap at 150 by keeping ONLY Feature Scenarios (P0+P1+P2) + Auth Context (P0+P1). Remove all Role Permission and Entity State scenarios entirely.
- Estimated time: 30-60 minutes

**For 7V (Smoke — Quick Production Validation)**:
- Generate Feature Scenarios for P0 + P1 features ONLY (happy path only, no negative variants)
- Generate Auth Context Scenarios for unauthenticated + 1 authenticated role only. For Auth Context, test only the diagonal — meaning test each route once with the role that is the primary intended user of that route (e.g., admin dashboard with admin, user settings with regular user), rather than testing every route × every role combination.
- Skip Entity State and Role Permission scenarios entirely (too detailed for smoke test).
- Maximum 15 scenarios to fit within 20-40 minute window
- **Selection criteria**: (1) P0 Feature Scenarios first (typically 5-8), (2) P1 Feature Scenarios if space permits (top 3-5 by user impact), (3) Auth Context: test /login, /dashboard, /settings for unauthenticated and 1 authenticated role. Do NOT include Negative Scenarios in smoke tests — they're too detailed for production validation.

### Step 10: Save the Scenario Matrix

Save the matrix to the appropriate path based on which stage is running:
- **Stage 6V**: `./plancasting/_audits/visual-verification/feature-scenario-matrix.md`
- **Stage 7V**: `./plancasting/_audits/production-smoke/smoke-scenario-matrix.md`

```markdown
# Feature Scenario Matrix
- **Generated**: [date]
- **Scope**: full / smoke
- **PRD Sources**: [list of files read]
- **Code Sources**: [list of files scanned]

## Summary
- Feature Scenarios (FS): [n]
- Auth Context Scenarios (AS): [n]
- Entity State Scenarios (ES): [n]
- Role Permission Scenarios (RS): [n]
- Negative Scenarios (NS): [n]
- **Total scenarios**: [n]
- **Estimated time**: [n] minutes

## Feature Dependency Graph
[Mermaid diagram or text representation]

## Scenarios by Priority
### P0 (must test)
[FS/AS/ES/RS/NS scenarios]

### P1 (should test)
[scenarios]

### P2 (test if time permits)
[scenarios]

### P3 (skip for now)
[scenarios]

## Scenario Details
[Full scenario definitions]
```

## Mapping Scenarios to Teammates (6V Only)

When distributing scenarios to teammates:

| Teammate | Scenario Types | Auth Context |
|----------|---------------|--------------|
| Teammate 1 (automated-page-verifier) | Auth Context (AS), Entity State (ES) — page load and component checks per auth/state | TEST_USER_STARTER |
| Teammate 2 (acceptance-criteria-verifier) | Feature Scenarios (FS), Negative Scenarios (NS) — multi-step flow execution | TEST_USER_PRO |
| Teammate 3 (visual-ai-reviewer) | Reviews screenshots from Teammates 1+2; performs visual/accessibility spot-checks (no new scenario execution) | TEST_USER_STARTER |
| Teammate 4 (responsive-and-interaction-verifier) | Role Permission (RS), buttons/interactions from all FS — interaction testing | TEST_USER_ENTERPRISE |

Note: This teammate mapping applies to Stage 6V only. Stage 7V is a single-agent stage that executes all scenario types itself. Teammate names reference Stage 6V's default naming. If your 6V session uses different teammate names, map accordingly.

Test user assignments are primary defaults. Teammates testing Auth Context (AS) or Role Permission (RS) scenarios must use multiple test accounts to cover the auth matrix. All teammates should have access to all test user credentials.

**Key rule**: Feature Scenarios are the PRIMARY test unit. Page-level checks (from the old verification matrix) are SECONDARY — they fill gaps where no Feature Scenario covers a screen. Every screen SHOULD be covered by at least one Feature Scenario. If a screen has no scenario, add a standalone page-load check.

## Scenario Execution Rules

1. **Run P0 scenarios first.** If a P0 scenario fails (e.g., Auth fails), mark ALL dependent scenarios as BLOCKED — don't waste time running them. More broadly, if ANY scenario fails, consult the Feature Dependency Graph to identify all transitively dependent scenarios and mark them as BLOCKED.
   - **Exception for 7V (smoke scope)**: Mark only immediate dependents as BLOCKED — do not transitively cascade, as the smoke test has too few scenarios for deep cascade analysis.
2. **Use the Feature Dependency Graph** to determine execution order. A scenario for FEAT-012 (Deploy) cannot run before FEAT-003 (Project Management) passes.
3. **Share entity state across scenarios when possible.** If FS-003 creates a project and FS-005 needs a project, use the same project — don't recreate. But ensure scenarios that MODIFY entities use separate instances.
4. **Record button clicks and page transitions.** Every button clicked, every form filled, every page navigated to should be logged. This data feeds the link integrity and button action reports.
5. **Screenshot at each step, not just the final state.** Feature scenarios are multi-step — a failure at step 5 of 8 needs a screenshot at step 5.
6. **Map results back to acceptance criteria.** When a Feature Scenario step corresponds to a US-NNN acceptance criterion, record PASS/FAIL against that criterion.
