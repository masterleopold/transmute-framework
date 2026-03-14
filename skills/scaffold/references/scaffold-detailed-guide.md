# Scaffold Detailed Guide — Stage 3 Teammate Instructions & Code Generation Guidelines

This reference contains the full teammate spawn instructions, backend principles, code generation guidelines, and coordination protocol for Stage 3: Project Code Skeleton Generation.

## Backend Principles (ALL Teammates — Adapt to Your Stack)

These principles apply to your chosen backend. The examples use Convex syntax — if using a different backend per `plancasting/tech-stack.md`, follow equivalent patterns.

### If Using Convex (per plancasting/tech-stack.md):
1. Backend code lives in `convex/`. Each file exports query/mutation/action functions that become API endpoints named `api.<filename>.<exportName>`.
2. Schema is defined in `convex/schema.ts` using `defineSchema`, `defineTable`, and `v` validators. Migrations are automatic on deploy.
3. Queries are reactive and automatically re-run when dependent data changes. Mutations are transactional with serializable isolation.
4. Actions can call external APIs and perform side effects but are NOT transactional. Use actions for third-party integrations, AI calls, etc.
5. Internal functions (`internalQuery`, `internalMutation`, `internalAction`) are not exposed as public API — use for server-to-server logic, cron jobs, and scheduled functions.
6. Arguments and return values are validated using `v` validators (`v.string()`, `v.number()`, `v.id("tableName")`, `v.optional(...)`, `v.object({...})`, `v.array(...)`, `v.union(...)`, etc.).
7. Use `ctx.db.query("tableName")` for reads, `ctx.db.insert()`, `ctx.db.patch()`, `ctx.db.replace()`, `ctx.db.delete()` for writes.
8. Indexes are defined in the schema and queried with `.withIndex("indexName", q => q.eq("field", value))`.
9. File storage uses `ctx.storage.store()`, `ctx.storage.getUrl()`.
10. Scheduled functions use `ctx.scheduler.runAfter()` and `ctx.scheduler.runAt()`. Cron jobs are defined in `convex/crons.ts`.

### No-Frontend Products
If `plancasting/tech-stack.md` indicates a CLI, API-only, or backend-only product with no frontend, skip Teammates 2 and 3. Teammate 4 should skip frontend-specific files (middleware, useFeatureFlag hook, FeatureGate component) and only generate backend feature flag logic and environment config. Adapt Teammate 5's test infrastructure to omit frontend-specific files.

---

## Teammate 1: "backend-schema-and-functions"

**Domain**: Backend — schema/models, read functions, write functions, side-effect functions

### Files to Generate

**Schema file** (e.g., `convex/schema.ts`, `prisma/schema.prisma`, `drizzle/schema.ts`):
- COMPLETE schema derived from PRD `11-data-model.md` — ALL entities, ALL tables/models, ALL indexes
- For each entity in the PRD data model (no exceptions):
  - Define the table/model with all fields using appropriate type validators
  - Add indexes for all query patterns explicitly mentioned in PRD (screen specs, API specs, user flows). Do NOT speculate on indexes for hypothetical future queries
  - Include field-level comments referencing PRD entity definitions
- The schema must be designed for the complete product from day one. No tables or fields are deferred.

**Domain function files** (one per functional domain/module):
- For EVERY API endpoint in PRD `12-api-specifications.md`, generate the corresponding backend function:
  - Determine function type: read / write / side-effect
  - Include full argument/input validation
  - Include authorization checks
  - Include business rule validation
  - Implement handler logic with proper error handling structure. Core business logic contains a reasonable first-pass; complex business rules may use `// ⚠️ STUB: <description>` markers for Stage 5 refinement
  - Add JSDoc comments with PRD/BRD traceability
- Generate files for ALL domains

**Internal function files** (server-only functions):
- ALL server-to-server logic, background processing across ALL features
- Functions called by scheduled jobs or cron jobs
- Data aggregation and maintenance tasks
- Cross-feature internal functions

**Cron/scheduled job definitions** (e.g., `convex/crons.ts`):
- ALL cron/scheduled job definitions derived from PRD `13-technical-specifications.md`

**HTTP endpoints** (e.g., `convex/http.ts`, `src/app/api/webhooks/`):
- ALL HTTP endpoints for webhooks from ALL external services

**Auth helper functions** (e.g., `convex/auth.ts`, `src/lib/auth-helpers.ts`):
- Shared auth helper functions: `requireAuth()`, `requireOrgMembership()`, `requireProjectRole()`, `requirePlanTier()`, etc.
- These helpers are consumed by every domain file's mutations and sensitive queries
- Note: Auth CONFIGURATION files (provider setup, role definitions) belong to Teammate 4. Auth HELPER functions (runtime permission checks) belong to Teammate 1.

**Spawn prompt must emphasize**: The schema must be COMPLETE — every table/model for every feature. Every backend function file must cover ALL endpoints for its domain. Pay special attention to cross-domain reads and writes.

---

## Teammate 2: "frontend-pages-and-routing"

**Domain**: Frontend pages, layouts, and routing

### Files to Generate

**Route structure** (e.g., `src/app/` for Next.js App Router):
- Derived from PRD `07-information-architecture.md` — COMPLETE IA for the full product
- For EVERY screen in PRD `08-screen-specifications.md`:
  - Page component with data loading
  - Shared layouts for route groups
  - Loading states (skeleton screens per PRD interaction patterns)
  - Error boundaries with PRD-specified error states
  - 404 states where applicable

**Root layout** (e.g., `src/app/layout.tsx`):
- Backend/data provider setup
- Auth provider wrapping
- Global metadata (including favicon and app icon references)
- Font and theme configuration
- Navigation structure accommodating ALL features

**Favicon & App Icons** (from product logo in `plancasting/tech-stack.md`):
- If logo file provided: use in header/sidebar, create `icon.svg`, generate metadata config
- If no logo provided: generate text-based SVG favicon using product name initials and brand color
- For Next.js App Router: use Metadata File API convention

**Backend client provider component**

**Server vs Client rendering decision**: Default to Server Components for static content; use Client Components when hooks/interactivity needed.

**Spawn prompt must emphasize**: Routing must include pages for ALL features. Root layout navigation must accommodate all features without future restructuring. Do NOT generate middleware — Teammate 4 owns middleware exclusively.

---

## Teammate 3: "ui-components"

**Domain**: Design direction, reusable UI components, hooks, and utilities

### Critical First Step — Design Direction Intake

Before writing ANY component code:

1. Read `plancasting/tech-stack.md` "Design Direction" section for:
   - UI Component Library selection
   - Aesthetic direction
   - Product logo (extract brand colors)
   - Design reference URLs (visit to extract visual patterns)
   - Figma designs (highest-authority source)
   - Typography & color direction

2. Follow Frontend Design Guidelines:
   - Commit to the aesthetic direction and execute with precision
   - Choose distinctive, beautiful fonts — avoid generic defaults
   - Use CSS variables for color consistency; dominant colors with sharp accents
   - Apply purposeful motion and micro-interactions
   - Use unexpected layouts, asymmetry, generous negative space
   - Create atmosphere with gradients, textures, shadows, depth
   - Avoid generic AI aesthetics

### Files to Generate

**`src/styles/design-tokens.ts`** (GENERATE FIRST):
- Color palette, typography (2 distinctive fonts), spacing scale, border radius, shadows, animation tokens, component-level tokens
- Read `plancasting/tech-stack.md` Design Direction and PRD product overview for guidance

**`tailwind.config.ts`** (CUSTOMIZE — never use defaults):
- Extend with design tokens. Custom colors, fonts, spacing, border-radius, shadows, animations.
- **Tailwind v4 semantic color tokens (CRITICAL)**: Add `border`, `ring`, `card`, `background`, `foreground` etc. as top-level entries in `theme.extend.colors`. In v4, these resolve from `colors` palette, NOT from `borderColor`/`ringColor`.

**`src/styles/globals.css`** (Tailwind v4 config bridge):
- MUST include `@config "../../tailwind.config.ts";` after `@import "tailwindcss";`
- Without this, ALL custom theme extensions are silently ignored
- CSS variable declarations, base typography, custom animation keyframes, background textures

**`src/components/` directory**:
- Organized by domain/feature — ALL features:
  - `ui/` — generic reusable primitives
  - `forms/` — form components with validation
  - `layouts/` — header, sidebar, footer
  - `features/` — feature-specific compound components (auth, dashboard, all features)
  - `feedback/` — toast, modal, alert
  - `onboarding/` — progressive disclosure, guided tours
- For EVERY screen component: TypeScript interface, all states (default, loading, empty, error, disabled, hover, active, focused), responsive behavior, accessibility, micro-interactions, skeleton screens, JSDoc with PRD traceability
- **Dark mode border discipline**: Never use primary/accent-colored borders for non-primary variants. Use neutral `border-border` token for secondary/outline variants.

**`src/hooks/` directory**:
- Custom hooks wrapping backend operations — one hook per domain/feature area
- Include optimistic update patterns, error handling, loading state management
- Cross-feature hooks where data flows between features

**`src/lib/` directory**:
- `utils.ts`, `constants.ts`, `validators.ts`, `types.ts` — all covering the COMPLETE product

---

## Teammate 4: "feature-flags-and-config"

**Domain**: Feature flag system, environment config, and middleware

### Files to Generate

**Backend feature flag functions** (e.g., `convex/featureFlags.ts`):
- Schema table for feature flags
- Read/write functions
- Flag types: Ops (kill switches), Experiment (A/B), Permission (role/plan-based) — NO release flags

**`src/hooks/useFeatureFlag.ts`**: React hook with TypeScript-safe flag name enum

**`src/components/features/FeatureGate.tsx`**: Declarative component (flag, fallback, children)

**`src/middleware.ts`** (Teammate 4 owns exclusively):
- Route protection for ALL routes
- Permission-flag-based route access
- Locale detection (if i18n specified)

**Auth setup files**: Provider configuration, role/permission definitions

**Environment configuration**: `.env.local.example`, `.env.production.example`

---

## Teammate 5: "testing-and-ci-cd"

**Domain**: Testing infrastructure, CI/CD pipeline, and project configuration

### Files to Generate

**Testing setup**:
- `vitest.config.ts` (or `jest.config.ts` if project uses Jest)
- `playwright.config.ts`
- `src/__tests__/setup.ts`

**Test Infrastructure Files (CRITICAL — generate at scaffold time)**:

1. **`src/test/setup.ts`** — Vitest setup with jest-dom matchers, canvas prototype stub for axe-core

2. **Backend test utilities** (e.g., `convex/__tests__/convex-modules.test-utils.ts`):
   - Explicit module map listing ALL generated backend function files
   - Include sync instructions header comment

3. **Shared test utilities** (e.g., `convex/__tests__/setup.test-utils.ts`):
   - `setupTestContext()`, `mockIdentity()`, `mockProject()`, etc.
   - `expectBackendError()` helper
   - All test data factories MUST include `deletedAt: null` for soft-delete tables

**Tests**:
- Backend function tests for ALL features
- Component tests for ALL features
- E2E tests for ALL user flows from PRD `06-user-flows.md`
- Cross-feature user flow tests
- Visual regression test setup

**CI/CD pipeline** (`.github/workflows/`):
- `ci.yml` — PR pipeline (typecheck, lint, tests, E2E, bundle size, Lighthouse CI)
- `deploy.yml` — Production deployment (full tests, deploy, post-deployment health checks for ALL features)
- `preview.yml` — Preview deployment for PRs

**Project configuration**:
- `package.json` — dependencies and scripts for the COMPLETE product
- `tsconfig.json`, `next.config.ts`, ESLint config, `.prettierrc`, `.gitignore`

**next.config.ts Critical Configuration**:
1. Content-Security-Policy: Do NOT include `'strict-dynamic'` without nonce-based CSP
2. i18n Plugin Aliases: Add BOTH Turbopack (relative paths) and webpack (absolute paths) aliases
3. Environment Variables: `.env.local` is NOT auto-synced to hosting providers

**`README.md`**: Setup, development, testing, deployment guide

**`plancasting/_progress.md`**: Pre-populated with ALL features from PRD, all marked Not Started

---

## Phase 3: Coordination During Execution

While teammates work:
1. Monitor progress via shared task list.
2. Facilitate cross-team dependencies:
   - Teammate 1 finalizes schema/signatures -> notify Teammates 2, 3, 4, 5
   - Teammate 2 finalizes routes -> notify Teammates 3, 5
   - Teammate 3 finalizes component interfaces -> notify Teammates 2, 5
   - Teammate 4 finalizes feature flag schema -> notify Teammate 1; finalizes FeatureGate -> notify Teammate 3
3. Resolve import path conflicts and shared type definitions.
4. Ensure backend function names match pages/hooks references.
5. Verify cross-feature consistency for shared data patterns.

---

## Phase 4: Review & Integration

After all teammates complete:

1. **Comprehensive consistency review**:
   - Full-scope coverage: every PRD SC-xxx has a component, every API-xxx has a backend function, every data entity has a schema table
   - Import validation, backend API references, schema completeness, index coverage
   - Type consistency, PRD traceability, state coverage, auth checks, test coverage
   - Cross-feature data flows, feature flag coverage
   - No phase artifacts

2. **Finalize `plancasting/_scaffold-manifest.md`**: Map every component to its target page, every hook to its consuming components, every backend function to its feature.

   ```markdown
   # Scaffold Manifest
   ## Generated by Stage 3 — DO NOT DELETE until Stage 5B completes

   ### Components -> Page Mapping
   | Component File | Target Page | Purpose |
   |---|---|---|

   ### Hooks -> Component Mapping
   | Hook File | Consuming Components | Backend Functions |
   |---|---|---|

   ### Backend Functions
   | Backend File | Functions | Feature |
   |---|---|---|

   ### Pages (with expected component composition)
   | Page File | Expected Components (from this manifest) |
   |---|---|
   ```

3. **Generate `ARCHITECTURE.md`**: System architecture diagram (mermaid), directory structure, data flow diagrams, cross-feature data flow, auth flow, feature flag flow, PRD-to-code traceability matrix.

4. **Update `CLAUDE.md` Part 2 ONLY**: Fill in placeholder sections. NEVER modify Part 1.

5. **Fix inconsistencies**.

6. **Output final summary**: File counts, PRD coverage percentages (target: 100%), cross-feature touchpoints, test file counts, feature flags, unresolved issues.

---

## Code Generation Guidelines (Include in ALL Teammate Spawn Prompts)

1. **Full Scope**: Scaffold ALL features from the PRD. Nothing is deferred.
2. **PRD Traceability**: Every file starts with `@traces` comment block:
   ```typescript
   /**
    * @module ComponentName
    * @description Brief description.
    *
    * @traces PRD:08-screen-specifications.md#SC-015
    * @traces PRD:04-epics-and-user-stories.md#US-023
    * @traces BRD:06-business-requirements.md#FR-007
    */
   ```
3. **TypeScript Strict Mode**: All code compiles under `strict: true`. No `any`, no `@ts-ignore`.
4. **Backend Patterns**: Always validate arguments, check auth, use indexed queries, return only necessary fields.
5. **Component Patterns**: Default to Server Components. Implement ALL states. Include ARIA and keyboard nav.
6. **Design Quality**: Read `plancasting/tech-stack.md` Design Direction. Use design tokens. Build with selected UI library. Avoid generic AI aesthetics. Apply Tailwind v4 `@config` bridge and semantic color tokens.
7. **Error Handling**: Backend throws typed errors (e.g., `ConvexError`). Components use error boundaries for unexpected, inline states for expected errors.
8. **Cross-Feature Awareness**: Verify all cross-references when touching multi-feature data.
9. **Naming Conventions**: Follow `plancasting/_codegen-context.md`.
10. **File Size**: Keep under 300 lines. Split if larger.
11. **Structurally Complete Functions**: Correct signatures, validators, auth, error handling. Business logic has reasonable first-pass with `// ⚠️ STUB:` markers for Stage 5. No empty functions, no `// TODO` stubs.
12. **No Phase References**: All features ship enabled. Conditional rendering only via feature flags.
13. **CLAUDE.md Protection**: Never rewrite from scratch. Only extend Part 2.
14. **Scaffold Manifest**: Every generated file must be listed in `plancasting/_scaffold-manifest.md`.

---

## Session Recovery

If resuming a previously interrupted scaffold:
1. Check which files already exist.
2. Check if `plancasting/_codegen-context.md` and `plancasting/_progress.md` exist (Phase 1+ completed).
3. Check if `ARCHITECTURE.md` exists (Phase 4 reached).
4. Resume from earliest incomplete phase.
5. Only respawn teammates whose files are missing/incomplete.
6. Clean up incomplete files before re-spawning. Incomplete = empty, imports-only, or no exports.
7. Re-spawned teammates regenerate from scratch and append to `plancasting/_scaffold-manifest.md`.
