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
Business Plan → Tech Stack → BRD → PRD → Spec Validation → Scaffold → Implementation → Completeness Audit → QA & Hardening → Pre-Launch → Live Verification → Remediation → Visual Polish or Redesign → Deploy → Production Smoke → User Guide → Feedback / Maintenance
   [Input]        [0]       [1]   [2]      [2B]           [3+4]        [5]                [5B]              [6A–6G]         [6H]           [6V]               [6R]              [6P / 6P-R]          [7]        [7V]              [7D]        [8] / [9]
```

> **Notation**: `+` means sequential stages sharing a single Claude Code session (3+4). `/` means "sequential, never simultaneous" — for alternatives (6P / 6P-R), run exactly one; for sequential stages (8 / 9), run both but one at a time. `[6A–6G]` = 6A/6B/6C (parallel) then 6E → 6F → 6G → 6D (sequential).

All stages follow the **Transmute Full-Build Approach**: every feature described in the Business Plan is built. No MVP, no phased delivery. You plan cast the entire product at once.

**Stage 6 ordering**: Parallel: 6A + 6B + 6C. Sequential: 6E → 6F → 6G → 6D → 6H → 6V → 6R (only if 6V finds Category A/B issues) → 6P or 6P-R → 7 → 7V → 7D.

### Prerequisites

- **Business Plan**: Place files at `./plancasting/businessplan/` before starting. This directory is read-only input for all stages. Supports `.md` and `.pdf` files (single or multiple).
- **Claude Code**: Installed and authenticated (`claude --version`)
- **Transmute Plugin**: Installed (`claude --plugin-dir /path/to/transmute-framework`)
- **Node.js**: v18+ (`node --version`). Stage 7D requires Node.js v20.17.0+.

**Credential tiers** — verify no placeholders: `grep -E 'YOUR_.*_HERE|TODO_.*|CHANGE_ME|PLACEHOLDER|^[A-Z_]+=\s*$' .env.local`
- 🔴 Before Stage 3: pipeline infrastructure credentials
- 🟡 Before Stage 5 (preferably before Stage 3): product service credentials (auth, payments, email, AI)
- 🟠 Before Stage 7: deployment credentials (hosting, domains, CDN)
- 🔵 Before Stage 7D: documentation credentials (Mintlify, optional)

**Backend deployment timing**: After Stage 3 generates the backend, immediately deploy 🔴 credentials to your hosting platform.

**Adding credentials mid-pipeline**: If a credential is missing at its required stage, the stage will fail validation. To add: (1) obtain the credential, (2) add to `.env.local`, (3) deploy to backend environment if applicable, (4) re-run the failed stage. No earlier stages need re-running.

### Critical Per-Stage Warnings

- **Stage 0**: Interactive — stay at terminal.
- **Stage 4** (manual verification): Verify Part 1 intact, Part 2 filled — search for `[PROJECT_NAME]`, `[N]`, `[e.g.,` markers (none should remain).
- **Stage 5**: Credential check must pass. Stop dev server first. Session limit: orchestrator resumes from `_progress.md`.
- **Stage 6V/6P/6P-R**: The prompt starts the dev server automatically. Do NOT start it manually.
- **Stage 6P-R**: Interactive (Phases 0–2), autonomous (Phase 3+). Creates branch `redesign/frontend-elevation`. NEVER use `setTheme()` for Hybrid themes — causes localStorage flicker.
- **Stage 6P-R → 7D**: After merge, always re-run 7D to recapture screenshots.
- **Stage 6R**: Max 3 completed loops; persistent issues escalate to Category C.

### Key Gates & Recovery

**5B gate**: PASS → Stage 6. CONDITIONAL PASS → Stage 6. FAIL → re-run Stage 5 for affected features. FAIL-ESCALATE: 6+ Category C issues OR 6+ total unfixed.

**Post-6V routing**: PASS → 6P or 6P-R. CONDITIONAL PASS (A/B) → 6R → 6P or 6P-R. CONDITIONAL PASS (C only) → 6P or 6P-R. FAIL → fix manually.

**Post-6R**: PASS/CONDITIONAL PASS → 6P or 6P-R. FAIL → resolve, re-run 6V → 6R.

**Post-6P/6P-R**: PASS → Stage 7. 6P-R PASS → merge `redesign/frontend-elevation` to main, Stage 7 → 7V → 7D (re-run). 6P-R Phase 2 rejected → fall back to standard 6P.

**Key rules**: Never skip 6H, 6V, 6P/6P-R, or 7V. Exactly one of 6P or 6P-R always runs. 6P and 6P-R are mutually exclusive — revert 6P before switching to 6P-R.

**Stage 7 prerequisites**: 6H READY + 6P or 6P-R PASS/CONDITIONAL PASS.

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
6. NEVER use inline SVG `<path>` elements for standard UI icons. Use the project's icon library (see `plancasting/tech-stack.md` "Icon library" field and `src/components/ui/icons.ts`). Inline SVGs are permitted ONLY for product logos, brand marks, or custom illustrations unavailable in any icon library.

### Design & Visual Identity

<!-- ⛔ DO NOT DELETE THIS SECTION — it is critical for design quality ⛔ -->

**CRITICAL**: Before writing ANY frontend code, use the design direction in `src/styles/design-tokens.ts` and the guidelines below as the primary design authority. Additionally, in cloud environments, check if `/mnt/skills/public/frontend-design/SKILL.md` exists — if available, use its guidelines to supplement the local design tokens.

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
- `chore/<scope>` (e.g., `chore/dependency-update-YYYY-MM-DD` — used by Stage 9)
- `feedback/<scope>` (e.g., `feedback/batch-YYYY-MM-DD` — used by Stage 8)
- `redesign/<scope>` (e.g., `redesign/frontend-elevation` — used by Stage 6P-R)

#### Commit Messages
Format: `<type>(<scope>): <description> [PRD-ID]`

Examples:
- `feat(tasks): implement task list query [US-003]`
- `fix(auth): handle expired token in middleware [SR-003]`
- `test(tasks): add E2E test for task creation flow [US-005]`

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`

### Path-Scoped Rules (`.claude/rules/`)

Claude Code natively reads `.claude/rules/` files and applies matching rules based on `globs` frontmatter. This section defines how the Transmute pipeline uses path-scoped rules.

**Generation points**:
- **Stage 3** (Scaffold): Generates starter rules from `tech-stack.md` — known patterns, gotchas, and best practices for the selected stack.
- **Stage 5B** (Audit): Extracts implementation lessons from recurring audit findings.
- **Stage 6R** (Remediation): Captures verified fix patterns from successful Category A/B fixes.

**Quality gate**: Every rule requires evidence (issue ID, commit hash, or PRD reference) and a confidence level. HIGH confidence rules go to `.claude/rules/`; MEDIUM/LOW are staged in `plancasting/_rules-candidates.md` for operator review.

**Limits**: Maximum 15 rules per file, maximum 8 rule files total.

### Universal Prohibitions

- DO NOT omit loading/error states — see Component Rules #1 for the full list of required states.
- DO NOT implement a feature without first reading the corresponding PRD section.
- DO NOT store secrets in code. Use environment variables.
- DO NOT remove or weaken any rule in Part 1 of this file.
- DO NOT rewrite this file from scratch. ONLY extend Part 2.
- DO NOT log, commit, or share test credentials in reports — reference by name only (e.g., "the basic-tier test user from `e2e/constants.ts`").
- DO NOT write credential values into any file other than `.env.local`. Reference by variable name only (e.g., `STRIPE_SECRET_KEY`).
- DO NOT display, echo, log, or repeat credential values in output. Use non-revealing checks (e.g., `wc -c`) to verify presence without exposing values.
- DO NOT copy credential values between files — each service reads from `.env.local` or the hosting platform's environment variable configuration.
- DO NOT use `console.log(process.env)` or log entire config/env objects in application code — log only specific non-sensitive fields.
- DO NOT store raw credentials in reports, code comments, or commits.

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
| Frontend | [e.g., Next.js (App Router)] | SSR/RSC React framework |
| UI Components | [e.g., Untitled UI React / shadcn/ui] | Component library |
| Icons | [e.g., Lucide / Heroicons / Tabler / framework default] | Icon library (see `src/components/ui/icons.ts`) |
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

# Seed Data (after Stage 6F)
bun run seed:dev         # Minimal data for development
bun run seed:test        # Moderate data for testing
bun run seed:demo        # Curated data for demonstrations
bun run seed:stress      # High-volume data for performance testing
bun run seed:empty       # Empty-state users for UI verification
bun run seed:verify      # Referential integrity check
bun run seed:reset       # Clear all data and re-seed
```

### Backend Rules

<!-- Stage 3: Add backend-specific rules extending Part 1 -->

### Frontend Rules

<!-- Stage 3: Add frontend-specific rules extending Part 1 -->

### Security Rules

<!-- Stage 3: Add security patterns -->

### Project-Specific Prohibitions

<!-- Stage 3: Add stack-specific prohibitions extending Part 1 -->

### Key Reference Documents

See Part 1 § "Reference Documents" for the complete PRD/BRD reference table. Key files for daily development:
- Acceptance criteria — `plancasting/prd/04-epics-and-user-stories.md`
- UI specs — `plancasting/prd/08-screen-specifications.md`
- API specs — `plancasting/prd/12-api-specifications.md`
- Business rules — `plancasting/brd/14-business-rules-and-logic.md`
- Security requirements — `plancasting/brd/13-security-requirements.md`

### Conventions

See `docs/developer/conventions.md` (generated by Stage 6D) for: design guidelines, TypeScript rules, testing details, traceability format, git conventions, naming conventions.
See `plancasting/_progress.md` for feature tracking.

### Path-Scoped Rules

<!-- Stage 3: Populate with actual rule files generated from tech stack -->

| Rule File | Globs | Generated By | Rule Count |
|---|---|---|---|
| `.claude/rules/backend.md` | `[BACKEND_DIR]/**` | Stage 3 | [N] |
| `.claude/rules/frontend.md` | `[FRONTEND_DIR]/**` | Stage 3 | [N] |
| `.claude/rules/api-contracts.md` | `[BACKEND_DIR]/**`, `[HOOKS_DIR]/**`, `[FRONTEND_TYPES_DIR]/**` | Stage 3 | [N] |
| `.claude/rules/auth.md` | `[AUTH_DIR]/**`, `[MIDDLEWARE_PATH]` | Stage 3 | [N] |
| `.claude/rules/testing.md` | `[TEST_DIR]/**`, `**/*.test.*`, `**/*.spec.*` | Stage 3 | [N] |
| `.claude/rules/data-model.md` | `[SCHEMA_DIR]/**`, `[MIGRATION_DIR]/**` | Stage 3 | [N] |

**Candidate staging file**: `plancasting/_rules-candidates.md` (MEDIUM/LOW confidence rules awaiting operator review)
