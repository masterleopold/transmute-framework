# CLAUDE.md — Transmute Project Conventions & Rules

<!-- Pipeline Execution Guide | Part 1: Immutable Rules | Part 2: Project Config (extend only) -->

## Pipeline Execution Guide

<!-- This section is for pipeline execution only. After all stages complete,
     it can be removed or collapsed — it is NOT needed for day-to-day development. -->

> This project uses the **Transmute Framework** plugin for Claude Code.
> Run `/transmute` to start the full pipeline, or `/transmute <stage>` for individual stages.
> See `plancasting/_progress.md` for current pipeline state.

### Pipeline Overview

```
Business Plan → Tech Stack → BRD → PRD → Spec Validation → Scaffold → Implementation → Completeness Audit → QA & Hardening → Pre-Launch → Live Verification → Remediation → Visual Polish → Deploy → Production Smoke → User Guide → Feedback / Maintenance
   [Input]        [0]       [1]   [2]      [2B]           [3+4]        [5]                [5B]              [6A–6G]         [6H]           [6V]               [6R]           [6P]       [7]        [7V]              [7D]        [8] / [9]
```

All stages follow the **Transmute Full-Build Approach**: every feature described in the Business Plan is built. No MVP, no phased delivery. You plan cast the entire product at once.

### Prerequisites

- **Business Plan**: Place files at `./plancasting/businessplan/` before starting. This directory is read-only input for all stages. Supports `.md` and `.pdf` files (single or multiple).
- **Claude Code**: Installed and authenticated (`claude --version`)
- **Transmute Plugin**: Installed (`claude --plugin-dir /path/to/transmute-framework`)
- **Node.js**: v18+ (`node --version`). Stage 7D requires Node.js v20.17.0+.

### Key Gates & Recovery

**Credential gates** — verify no placeholders: `grep -E 'YOUR_.*_HERE|TODO_.*|CHANGE_ME|^[A-Z_]+=\s*$' .env.local`
- 🔴 Before Stage 3: pipeline credentials obtained + deployed to backend
- 🟡 Before Stage 5: product service credentials real
- 🟠 Before Stage 7: deployment credentials configured

**5B gate**: PASS → Stage 6. CONDITIONAL PASS → Stage 6. FAIL → re-run Stage 5 for affected features.

**Post-6V routing**: PASS → 6P. CONDITIONAL PASS (A/B) → 6R → 6P. CONDITIONAL PASS (C only) → 6P. FAIL → fix manually.

**7V gate**: PASS before 7D. FAIL → hotfix + re-deploy.

**Recovery**: All stages except 0 are idempotent — re-run the stage. Stage 5 resumes from `plancasting/_progress.md`.

---

## Part 1: Immutable Transmute Framework Rules

<!-- ⛔ DO NOT MODIFY OR DELETE ANYTHING IN PART 1 ⛔ -->
<!-- These rules are core to the Transmute framework and must be preserved -->
<!-- across all projects. Stage 3/4 may ADD project-specific rules in Part 2, -->
<!-- but must NEVER remove, replace, or weaken any rule in Part 1. -->

### Reference Documents

Always read the relevant PRD/BRD files BEFORE implementing any feature:

| What you need | Where to find it |
|---|---|
| Product overview & personas | `./plancasting/prd/01-product-overview.md` |
| Feature list & priorities | `./plancasting/prd/02-feature-map-and-prioritization.md` |
| Release plan & feature flags | `./plancasting/prd/03-release-plan.md` |
| User stories & acceptance criteria | `./plancasting/prd/04-epics-and-user-stories.md` |
| Job stories | `./plancasting/prd/05-job-stories.md` |
| User flows | `./plancasting/prd/06-user-flows.md` |
| Information architecture | `./plancasting/prd/07-information-architecture.md` |
| Screen specifications | `./plancasting/prd/08-screen-specifications.md` |
| Interaction patterns | `./plancasting/prd/09-interaction-patterns.md` |
| System architecture | `./plancasting/prd/10-system-architecture.md` |
| Data model | `./plancasting/prd/11-data-model.md` |
| API specifications | `./plancasting/prd/12-api-specifications.md` |
| Technical specifications | `./plancasting/prd/13-technical-specifications.md` |
| Testing strategy | `./plancasting/prd/14-testing-strategy.md` |
| Non-functional specs | `./plancasting/prd/15-non-functional-specifications.md` |
| Operational readiness | `./plancasting/prd/16-operational-readiness.md` |
| Dependencies & risks | `./plancasting/prd/17-dependencies-and-risks.md` |
| Glossary & cross-references | `./plancasting/prd/18-glossary-and-cross-references.md` |
| Business requirements | `./plancasting/brd/06-business-requirements.md` |
| Functional requirements | `./plancasting/brd/07-functional-requirements.md` |
| Business rules | `./plancasting/brd/14-business-rules-and-logic.md` |
| Security requirements | `./plancasting/brd/13-security-requirements.md` |
| Compliance requirements | `./plancasting/brd/12-regulatory-and-compliance-requirements.md` |

### Component Rules (All Frameworks)

1. ALWAYS implement all states: default, loading, empty, error, disabled.
2. ALWAYS include ARIA attributes for interactive elements.
3. ALWAYS support keyboard navigation.
4. NEVER use inline styles. Use the project's CSS framework (Tailwind, etc.).
5. Props interfaces must be explicitly typed and exported.

### Design & Visual Identity

<!-- ⛔ DO NOT DELETE THIS SECTION — it is critical for design quality ⛔ -->

**CRITICAL**: Before writing ANY frontend code, check if the skill file exists at `/mnt/skills/public/frontend-design/SKILL.md`. If available, read it and follow its guidelines for every component, page, and layout. If not available (e.g., local CLI environment), use the design direction in `src/styles/design-tokens.ts` and the guidelines below as the design authority.

**Design Direction**: This project has a defined design direction stored in `src/styles/design-tokens.ts` (or equivalent) and referenced in `plancasting/tech-stack.md` (Design Direction section from Stage 0). All UI code must follow this direction consistently. If the design direction does not yet exist, establish one before building components by:
1. Reading the PRD product overview and persona definitions.
2. Choosing a BOLD aesthetic direction that matches the product's personality and target users.
3. Documenting the direction in `src/styles/design-tokens.ts` with CSS variables, color palettes, typography choices, spacing scales, and animation patterns.

**Anti-Patterns — NEVER do these**:
- Generic AI-generated aesthetics: overused font families (Inter, Roboto, Arial, system-ui), cliched purple-on-white gradients, predictable card-grid layouts, cookie-cutter component styles.
- Default Tailwind without customization. Always configure `tailwind.config.ts` with custom colors, fonts, and spacing that match the design direction.
- Uniform spacing and sizing everywhere. Use intentional variation — generous whitespace in some areas, controlled density in others.
- Bland, evenly-distributed color palettes. Use dominant colors with sharp accents.

**Must-Have Design Qualities**:
- **Typography**: Choose distinctive, characterful fonts. Pair a display font with a body font. Import via `next/font` (or equivalent) for performance. Never default to system fonts.
- **Color & Theme**: Define a cohesive palette in CSS variables. Commit to it across all components. Use light/dark mode if specified in PRD.
- **Motion & Micro-interactions**: Use CSS transitions for hover states, focus rings, and state changes. Use staggered reveal animations on page load. Keep animations purposeful — enhance understanding, don't decorate.
- **Spatial Composition**: Break predictable grid layouts where appropriate. Use asymmetry, overlap, generous negative space. Every page should feel intentionally composed, not auto-generated.
- **Backgrounds & Depth**: Avoid flat solid-color backgrounds. Add subtle textures, gradient meshes, shadows, or layered transparencies that create atmosphere.

**Consistency**: Once the design direction is established, EVERY component must follow it. A single off-brand component breaks the entire experience.

### API Contract Alignment

<!-- ⛔ DO NOT DELETE THIS SECTION — prevents production type mismatch bugs ⛔ -->

- Frontend types MUST match the ACTUAL backend response shape — NOT the database schema.
- Create SEPARATE types for projections (e.g., `OrganizationSummary` for list view, `Organization` for detail view).
- NEVER use `as unknown as Type` casts to force type compatibility — use explicit field mapping.
- When backend returns renamed or computed fields, frontend hooks MUST map them explicitly.
- If the backend returns `orgId` but the frontend expects `_id`, the hook must transform — never cast.

### Scaffold Inventory

<!-- ⛔ DO NOT DELETE THIS SECTION — prevents the duplication pattern ⛔ -->

Before writing ANY code for a feature, the implementing agent MUST:
1. List ALL existing scaffold files for the feature (backend functions, components, pages, hooks).
2. Read `plancasting/_scaffold-manifest.md` if it exists — it maps which components are used by which pages.
3. EXTEND existing scaffold files. NEVER create duplicate files alongside them.
4. If a page already imports `ComponentX` from the scaffold, do NOT create a new `ComponentXInline` inside the page.

This prevents the "duplication pattern" where Stage 5 agents rebuild UI inline instead of using scaffold components, creating orphan files and bloated pages.

### TypeScript Rules

- Strict mode (`strict: true`). No exceptions.
- No `any` types. No `@ts-ignore`. No `@ts-expect-error` (unless with explanation).
- Explicit return types for all exported functions.
- Use `type` for object shapes. Use `interface` only when extension is intended.

### Testing Rules

#### Backend Function Tests
- One test file per backend function file.
- Test cases derived from PRD acceptance criteria (Given-When-Then).
- Must cover: argument validation, auth checks, happy path, error cases, edge cases, business rules.

#### Component Tests
- Test all component states (default, loading, empty, error).
- Include accessibility checks (axe-core).
- Mock backend hooks, not the API directly.

#### E2E Tests
- One test file per user flow from PRD `06-user-flows.md`.
- Cover happy path, key alternative paths, and critical error paths.
- Use `getByRole`/`getByText` selectors (not CSS classes).
- For eventually-consistent backends: use `expect.poll()` or `expect.toPass()`.

### Traceability Rules

Every file must include a header comment block with PRD/BRD traceability:

```typescript
/**
 * @module TaskList
 * @description Displays the user's task list with filtering and sorting.
 *
 * @prd SC-012, SC-013 (Screen Specifications)
 * @prd US-003, US-004 (User Stories)
 * @brd FR-007 (Functional Requirements)
 */
```

When the PRD does not provide enough detail for an implementation decision, document the assumption inline:

```typescript
// ⚠️ ASSUMPTION: Default sort order is by creation date descending.
// PRD SC-012 specifies sorting but does not define the default.
```

### Progress Tracking

<!-- ⛔ DO NOT DELETE THIS SECTION — the Feature Orchestrator depends on it ⛔ -->

Implementation progress is tracked in `./plancasting/_progress.md`. Update this file after completing each feature:

```markdown
| Feature ID | Feature Name | Priority | Status | Backend | Frontend | Tests | Notes |
|---|---|---|---|---|---|---|---|
| FEAT-001 | User Authentication | P0 | ✅ Done | ✅ | ✅ | ✅ | — |
| FEAT-002 | Task Management | P0 | 🔧 In Progress | ✅ | 🔧 | ⬜ | Blocked on file upload |
| FEAT-003 | Dashboard | P1 | ⬜ Not Started | ⬜ | ⬜ | ⬜ | Depends on FEAT-002 |
```

Valid status values: `⬜ Not Started`, `🔧 In Progress`, `✅ Done`, `🔄 Needs Re-implementation` (set by operator after 5B FAIL to trigger re-build in next Stage 5 session).

### Git Conventions

#### Branch Naming
- `feat/<feature-id>-<short-description>` (e.g., `feat/US-003-task-list`)
- `fix/<issue-description>`
- `refactor/<scope>`

#### Commit Messages
Format: `<type>(<scope>): <description> [PRD-ID]`

Examples:
- `feat(tasks): implement task list query [US-003]`
- `fix(auth): handle expired token in middleware [SR-003]`
- `test(tasks): add E2E test for task creation flow [US-005]`

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`

### Universal Prohibitions

- DO NOT skip loading/error states in any page or component.
- DO NOT implement a feature without first reading the corresponding PRD section.
- DO NOT store secrets in code. Use environment variables.
- DO NOT remove or weaken any rule in Part 1 of this file.
- DO NOT rewrite this file from scratch. ONLY extend Part 2.

---

## Part 2: Project-Specific Configuration

<!-- Stage 3 fills [PLACEHOLDER]s with actual values. Stage 4 verifies. Extend only, do not delete. -->

### Project Overview

**[PROJECT_NAME]** — [One-sentence project description].

- **Full tech stack reference**: `./plancasting/tech-stack.md`
- **Business plan files**: `./plancasting/businessplan/`
- **PRD**: [N] features, [N] API endpoints, ~[N] screens
- **BRD**: [N] business rules
- **Data model**: [N] tables

### Technology Stack

| Category | Technology | Purpose |
|---|---|---|
| Runtime | [e.g., Bun / Node.js] | JS/TS runtime + package manager |
| Frontend | [e.g., Next.js 16 (App Router)] | SSR/RSC React framework |
| UI Components | [e.g., shadcn/ui] | Component library |
| CSS | [e.g., Tailwind CSS v4.1] | Styling |
| Backend | [e.g., Convex / Supabase] | Backend-as-a-Service |
| Auth | [e.g., WorkOS / Clerk] | Authentication |
| AI | [e.g., Claude Agent SDK] | AI integration |
| Payments | [e.g., Stripe] | Billing |
| Hosting | [e.g., Vercel] | Deployment |

### Architecture

**Multi-tenant**: [Describe tenant boundary]

**Auth helpers**: [List auth helper functions and locations]

**Soft delete**: [Describe soft-delete pattern if applicable]

**Deployment**: [Describe deployment order and production URLs]

**Testing**: [Describe test runner config]

### Commands

```bash
# Development
bun run dev              # [describe what this starts]

# Testing
bun run test             # Unit + integration tests
bun run test:e2e         # E2E tests (Playwright)

# Quality
bun run lint             # Linter
bun run typecheck        # TypeScript type checking

# Deployment
bun run build            # Production build
bun run deploy           # Full deployment
```

### Backend Rules

<!-- Stage 3: Add backend-specific rules extending Part 1 -->

### Frontend Rules

<!-- Stage 3: Add frontend-specific rules extending Part 1 -->

### Security Rules

<!-- Stage 3: Add security patterns -->

### Project-Specific Prohibitions

<!-- Stage 3: Add stack-specific prohibitions extending Part 1 -->
