# CLAUDE.md — Transmute Project Conventions & Rules

<!-- Pipeline Execution Guide | Part 1: Immutable Rules | Part 2: Project Config (extend only) -->

> **Plan Casting**: The end-to-end process of using Transmute to autonomously transform a Business Plan into a production-ready product through the stages below (0–9 plus sub-stages).

## Pipeline Execution Guide

<!-- This section is for pipeline execution only. After all stages complete,
     it can be removed or collapsed — it is NOT needed for day-to-day development. -->

> For comprehensive details, see `plancasting/transmute-framework/execution-guide.md` (canonical source for all definitions and recovery procedures). This section is a quick reference.

### Pipeline Overview

```
Business Plan → Tech Stack → BRD → PRD → Spec Validation → Scaffold → Implementation → Completeness Audit → QA & Hardening → Pre-Launch → Live Verification → Remediation → Visual Polish or Redesign → Deploy → Production Smoke → User Guide → Feedback / Maintenance
   [Input]        [0]       [1]   [2]      [2B]           [3+4]        [5]                [5B]              [6A–6G]         [6H]           [6V]               [6R]              [6P / 6P-R]          [7]        [7V]              [7D]        [8] / [9]
```

> **Notation**: `+` means sequential stages sharing a single Claude Code session (3+4 = paste Stage 3 prompt, let it complete scaffold + populate CLAUDE.md Part 2, then verify Part 2 before exiting — all in one session). `/` means "sequential, never simultaneous" — for alternatives (6P / 6P-R), run exactly one; for sequential stages (8 / 9), run both but one at a time. `[6A–6G]` is simplified — within it: 6A/6B/6C run in parallel (each in a separate session), then 6E → 6F → 6G → 6D run sequentially. See "Stage 6 ordering" below for the full breakdown.

All stages follow the **Transmute Full-Build Approach**: every feature described in the Business Plan is built. No MVP, no phased delivery. You plan cast the entire product at once. Features are implemented in priority order (P0 → P3), so the product is functional at any interruption point — but the goal is always to complete all features. Priority levels are defined in `plancasting/prd/02-feature-map-and-prioritization.md`: P0 = foundational, P1 = launch-required, P2 = nice-to-have, P3 = polish. Your Business Plan can be rough or incomplete — Stage 0 is interactive and will ask clarifying questions.

> **Stage reference table**: See `plancasting/transmute-framework/execution-guide.md` § "Transmute Pipeline Overview" for the full stage table (prompt files, inputs, outputs, durations).

**Stage 6 ordering**: Parallel: 6A + 6B + 6C (commit each before proceeding). Sequential: 6E → 6F → 6G → 6D → 6H → 6V → 6R (only if 6V finds 6V-A/B issues) → 6P or 6P-R → 7 (Deploy) → 7V → 7D. 6D (Internal Documentation) runs after 6G (all code changes finalized) per the recommended ordering. **Alternative** (for large projects): run 6D after 5B PASS for an early draft, then re-run after 6E–6G if code changed — this is a two-pass approach, not the default. See execution-guide.md for full ordering details. **Parallel safety**: When running 6A+6B+6C in parallel across separate sessions, shared config files (e.g., `next.config.ts`, `middleware.ts`) can be overwritten silently. Mitigate by: (a) committing each stage's changes immediately upon completion, or (b) running 6A first (it modifies config files most), committing, then 6B+6C in parallel.

### Prerequisites

> See `plancasting/transmute-framework/execution-guide.md` § "Prerequisites" for full setup (Claude Code, Node.js, Playwright, tmux, package manager).

**Credential tiers** — verify no placeholders: `grep -E 'YOUR_.*_HERE|TODO_.*|CHANGE_ME|PLACEHOLDER|^[A-Z_]+=\s*$' .env.local`
- 🔴 Obtain before Stage 3, deploy to backend after Stage 3: pipeline infrastructure (`TRANSMUTER_ANTHROPIC_API_KEY`, `E2B_API_KEY`, `SANDBOX_AUTH_TOKEN`)
- 🟡 Before Stage 5 (preferably before Stage 3): product services (auth, payments, email, AI)
- 🟠 Before Stage 7: deployment (hosting, domains, CDN)
- 🔵 Before Stage 7D: documentation (Mintlify, optional)

> **Full credential details**: See `execution-guide.md` § "Prerequisites" for the complete credential table, platform-specific deployment commands, validation procedures, and safety rules.

**`.env.local` timing**: Stage 0 generates `.env.local` with placeholder values. Populate all 🔴 pipeline infrastructure credentials in `.env.local` with real values BEFORE starting Stage 3 — Stage 3's pre-flight validates that no placeholders remain and will STOP if any 🔴 credentials are missing. Note: 🔴 credentials must be *in `.env.local`* before Stage 3, but *deploying them to the backend environment* can wait until after Stage 3 creates the backend (if Stage 0 did not initialize it). See execution-guide.md § "Prerequisites" for the full timing details.

**Backend deployment timing**: After Stage 3 generates the backend, immediately deploy all 🔴 pipeline infrastructure credentials to your hosting platform (e.g., `bunx convex env set E2B_API_KEY <value>` for Convex, or via dashboard for Railway/Render/AWS). See execution-guide.md § "Prerequisites" for platform-specific commands.

**Adding credentials mid-pipeline**: If a credential is missing at its required stage, the stage will fail validation. To add: (1) obtain the credential, (2) add to `.env.local`, (3) deploy to backend environment if applicable (e.g., `bunx convex env set KEY <value>`), (4) re-run the failed stage in a new session. No earlier stages need re-running — credentials are forward-only dependencies.

### CLI Workflow

Each stage: `cd ~/project` → `claude --dangerously-skip-permissions` (allows autonomous execution without per-action permission prompts — required for agent teams) → paste prompt from `plancasting/transmute-framework/` → `/exit` → `git add -A && git commit -m "chore: complete Stage N (description)"`. Pipeline stage commits use a simplified `chore:` format without scope or PRD-ID — see Git Conventions below for the full format used during feature development. See execution-guide.md for per-stage details.

**Pre-Stage 3 Setup**: The scaffold generation (Stage 3) reads rule templates from `plancasting/transmute-framework/rules-templates/` to generate starter `.claude/rules/` files. These templates must be accessible in the project's `./plancasting/transmute-framework/rules-templates/` directory during Stage 3. If starting from a clean directory (not cloned from the Transmute Framework Template), copy the `rules-templates/` directory before running Stage 3.

**Pre-6V Setup** (two steps — both required before pasting the 6V prompt):
1. Copy `feature_scenario_generation.md` into your project's `./plancasting/transmute-framework/` directory before the first 6V/7V run. This file is a reusable, project-agnostic algorithm for extracting test scenarios from PRD — do NOT modify it. The 6V and 7V prompts read it internally.
2. Verify the dev server port is available: `lsof -i :3000` — if output shows a process, kill it with `kill -9 <PID>`. The 6V prompt starts the dev server internally; a busy port causes immediate failure.
See execution-guide.md § "Pre-6V Setup" for full instructions.

### Critical Per-Stage Warnings

> Full session conventions in execution-guide.md: fresh sessions (§ "Safety Rules" #6), stack adaptation (each prompt file's "Stack Adaptation" section), review checkpoints (§ per-stage "Human Review Checkpoints"), package manager (§ "Prerequisites").

- **Stage 0**: Interactive — stay at terminal. **Outputs**: `plancasting/tech-stack.md`, `.env.local`, `.env.local.example`, initial project scaffold (optional). Skip only if `plancasting/tech-stack.md` is fully populated (all sections filled: Product Type, Technology Stack table, Session Language, Specifications, Model Specifications, Design Direction, and Credential Inventory). See execution-guide.md § "0.5 Skip This Stage" for the template.
- **Stage 3 prerequisite**: Stage 2B must be PASS or CONDITIONAL PASS. Stage 3's pre-flight validates `.env.local` credentials — see § Prerequisites above. Check `plancasting/tech-stack.md` for the specific backend deployment command for your platform.
- **Stages 1–2B**: No critical warnings. **Assumption review timing** (between Stages 1 and 2B): After Stage 1 completes, read `./plancasting/brd/_review-log.md` § "Assumption Review Status". If assumption volume ≥ 30%, operator MUST review assumptions in BRD files and update the review status to `Operator reviewed: YES` before running Stage 2B. If < 30%, proceed directly. Stage 2B gate rule 2 checks this marker. See execution-guide.md for standard stage procedures.
- **Stage 4** (manual verification, no prompt file): Verify Part 1 intact (no edits to immutable rules), Part 2 filled — search for `[PROJECT_NAME]`, `[N]`, `[e.g.,` markers (none should remain). If verification fails: (1) manually populate Part 2 using Stage 0 outputs and `plancasting/tech-stack.md`, (2) search Part 2 for remaining placeholders (all `[` in Part 2 are placeholders): `sed -n '/^## Part 2/,$p' CLAUDE.md | grep -n '\['`, (3) commit: `git add CLAUDE.md && git commit -m "chore: complete Stage 4 (CLAUDE.md verification)"`.
- **Stage 5 pre-flight**: `grep -E 'YOUR_.*_HERE|TODO_.*|CHANGE_ME|PLACEHOLDER|^[A-Z_]+=\s*$' .env.local` must return empty. Stop dev server first.
- **Stage 5 session limit**: Orchestrator resumes from `_progress.md`. If limit reached, start new session and re-paste prompt.
- **Stage 5 large features**: Split features that span 15+ source files (backend + frontend + tests combined) into sub-features (FEAT-003a, FEAT-003b). Count files from `_scaffold-manifest.md` or estimate from PRD screen/endpoint count.
- **Stage 6A/6G rate limiting scope**: 6A = auth-related rate limiting (login attempts, password resets, password changes, token refresh, email verification, MFA device management, account linking, signup, logout); 6G = data-mutation rate limiting (user profile updates, API writes, bulk operations, file uploads). **Decision rule**: Does the operation's PRIMARY purpose change authentication state? If YES → 6A. If NO → 6G. If BOTH equally → 6A (auth takes precedence). Edge cases: password change = 6A (auth operation), user profile update = 6G (data mutation), password-reset email send = 6A (auth flow). See execution-guide.md § "6A. Security Audit" for the full scope boundary.
- **Stage 6V/6R/6P/6P-R**: The prompt includes dev server startup as part of its execution. Before running: `lsof -i :3000` — if port is busy, kill the existing process with `kill -9 <PID>`. Do NOT start the dev server manually before pasting the prompt.
- **Stage 6P-R**: Interactive (Phases 0–2), autonomous (Phase 3+). Creates branch `redesign/frontend-elevation`. If abandoned or switching back to 6P, delete the branch if not needed: `git branch -D redesign/frontend-elevation`.
- **Stage 6P-R Hybrid theme**: NEVER use `setTheme()` — causes localStorage flicker. Use CSS `prefers-color-scheme` instead.
- **Stage 6P-R → 7D**: After merge, always re-run 7D to recapture screenshots. Verify image paths: `grep -r 'src="' user-guide/ --include='*.mdx'`.
- **Stage 6V modes** (applies to 6V only, not 7V — 7V always runs SMOKE scope: P0+P1 features only, max 15 scenarios): Append scope on a new line when pasting the prompt, or type it as a separate follow-up message. Default is `full`.
  - `MODE: full` — Comprehensive verification of all components, pages, API routes, and state management (default). Use for first verification or after major changes.
  - `MODE: critical` — Verification of P0/P1 features and critical user flows only. Use for time-constrained runs.
  - `MODE: diff` — Verification of only screens/components affected by recent changes since the last 6V run. Use for incremental re-verification.
- **Stage 6R**: Max 3 internal fix-verify cycles within a single 6R run; persistent issues escalate to 6V-C. After 3 cycles: (a) operator may manually fix remaining issues, re-run 6V to confirm, then proceed to 6P or 6P-R, OR (b) document remaining issues as known limitations and proceed to 6P or 6P-R. If 6R gate is FAIL after max cycles, do NOT re-run 6R — manually fix 6V-C issues first, re-run 6V, then 6R if needed.
- **Recovery**: All stages except 0 are idempotent — re-run prompt in new session. Stage 5 resumes from `_progress.md`.

### Key Gates & Recovery

> **Full details**: See `execution-guide.md` § "Gate Decision Outcomes (Universal)" for all gate definitions, category systems, routing tables, thresholds, and recovery procedures. This section is a compact summary.

**Gate outcomes by stage** (see execution-guide.md for conditions and routing):
- **2B**: PASS / CONDITIONAL PASS / FAIL (coverage + issue counts + BRD assumption review). FAIL if: unresolved CRITICAL issues OR BRD assumption volume ≥30% not operator-reviewed OR P0 coverage <95% OR overall coverage <90%. CONDITIONAL PASS if: CRITICAL=0, HIGH≤3 (none P0-blocking, each with fix plan), P0≥95%, overall≥90% — also possible if assumptions ≥30% but operator has confirmed review. PASS if: CRITICAL=0, HIGH=0, coverage≥95%. Note: "coverage" here means BRD→PRD requirement traceability (each FR has US + SC + API), not code coverage — Stage 3 uses "scaffold coverage" which is a different metric. See `prompt_validate_specs.md` for the full 8-rule decision tree.
- **3**: PASS / CONDITIONAL PASS / FAIL (scaffold coverage ≥95% / ≥80% / <80%; PASS also requires CLAUDE.md Part 2 populated, `_progress.md` lists all features, and `.claude/rules/` generated from templates)
- **5B**: PASS / CONDITIONAL PASS / FAIL-RETRY / FAIL-ESCALATE (size-based categories A/B/C — A: <30 lines, B: 30–100 lines per file AND <150 total, C: ≥100 lines or ≥150 total). PASS: 0 A/B, 0 C. CONDITIONAL PASS (first matching condition wins): (a) 0 A/B + 1–3 C each with workaround, (b) 1–2 A/B documented + 0 C, (c) mixed A/B + C where A/B ≤ 2 AND C ≤ 3 each with workaround. FAIL-RETRY: 3+ unfixed A/B, OR 4–5 Category C, OR total unfixed > 5. FAIL-ESCALATE: 6+ Category C, OR 6+ total unfixed across all categories combined. Per-feature escalation: if a single feature (same FEAT-ID) reports FAIL-RETRY three consecutive times across separate 5B runs (tracked per-feature, not globally — other features' results are irrelevant), it automatically escalates to FAIL-ESCALATE. Recovery: set `🔄` on affected features in `_progress.md` (mark ONLY the features listed in the 5B report), re-run Stage 5, then re-run 5B (fresh scan). Also produces rule candidates and updates `.claude/rules/` (HIGH confidence patterns only). See execution-guide.md § "Gate Decision Outcomes (Universal)" for the full threshold table and per-feature tracking rules.
- **6A–6G**: PASS / CONDITIONAL PASS / FAIL (criteria differ per stage — see each prompt's `## Gate Decision` section for specifics)
- **6H**: READY / NOT READY (binary pre-launch gate)
- **6V**: PASS / CONDITIONAL PASS / FAIL (dual system: percentage-based ≥90%/80–90%/<80% AND fixability-based categories 6V-A/6V-B/6V-C — gate is the worse of the two). Categories: 6V-A = auto-fixable (broken links, dead code, incorrect imports), 6V-B = semi-auto (stub components, missing loading states), 6V-C = human judgment (architectural issues, design decisions). Routing: PASS (zero issues) → skip 6R, CONDITIONAL PASS with 6V-A/B → run 6R, CONDITIONAL PASS with only 6V-C → skip 6R. Flaky scenarios: excluded from gate percentage; informational in 6V, FAIL in 7V. Stages 6V and 6R MUST use `6V-` prefix in reports to distinguish from Stage 5B's size-based categories. Note: 6A–6G use their own stage-specific category systems — the `6V-` prefix applies only to 6V and 6R.
- **6R**: PASS / CONDITIONAL PASS / FAIL (max 3 internal fix-verify cycles per run; FAIL → fix 6V-C manually, re-run 6V, then 6R if needed). Same fixability-based category system as 6V (uses `6V-` prefix).
- **6P**: PASS / CONDITIONAL PASS / FAIL (visual defect categories: O = objective defects, E = enhancements, D = design elevation)
- **6P-R**: PASS / CONDITIONAL PASS / FAIL (Critical/Major/Minor severity — distinct from 6P's O/E/D categories)
- **7V**: PASS / FAIL (binary; flaky = FAIL in production, informational in 6V)
- **7D**: PASS / WARN / FAIL (WARN replaces CONDITIONAL PASS for this stage — documentation quality issues that don't block launch; skip 7D entirely if `tech-stack.md` Documentation section indicates user documentation is not needed)
- **8**: PASS / CONDITIONAL PASS / FAIL (feedback resolution completeness)
- **9**: PASS / CONDITIONAL PASS / FAIL (dependency update safety)

**CONDITIONAL PASS cascading**: A CONDITIONAL PASS in any Stage 6[A–G] does NOT automatically block 6H's READY decision. The 6H lead must evaluate each inherited CONDITIONAL PASS condition: if the condition is a documented workaround that doesn't block core functionality, 6H proceeds as READY; if the condition is an unresolved blocker awaiting human decision, 6H must be NOT READY unless the operator explicitly accepts the risk. Document the override in the readiness report with: reason, accepted blockers, risk assessment, and mitigation plan.

**Key rules**: Never skip 6V, 6P/6P-R, or 7V. 6R CAN be skipped if 6V returns PASS (zero issues) or CONDITIONAL PASS with only 6V-C issues (6R cannot fix human-judgment issues). If 6R is skipped, 6P/6P-R uses the 6V report as input instead of a 6R report. Exactly one of 6P or 6P-R always runs. 6P and 6P-R are mutually exclusive — to switch from 6P to 6P-R: (1) commit all current work including 6P changes: `git add -A && git commit -m "chore: Stage 6P changes"`, (2) revert the 6P commit: `git revert <6P-commit-hash>` (creates a new commit reversing 6P — safer than `git checkout -- src/`), (3) start a new session and run 6P-R. Max 3 internal fix-verify cycles per 6R run. Default to 6P (20–40 min) for styling fixes (contrast, hover states, spacing, typography adjustments); use 6P-R (2–4 hrs, interactive) only for full design overhaul, rebranding, or when the product has zero design identity. See execution-guide.md § "6P vs 6P-R" for the full decision table. For 6P-R: if 6V found 6V-A/B issues, 6R must PASS or CONDITIONAL PASS before running 6P-R. If 6V found only 6V-C issues, skip 6R and proceed to 6P or 6P-R.

**Stage 7 prerequisites**: 6H READY + 6V complete + 6P or 6P-R PASS/CONDITIONAL PASS (one always runs, even if 6V passes clean) + 6D complete (recommended; if skipped, Stage 7 falls back to hosting provider documentation).
**Stage 8 prerequisite**: Stage 7V PASS (production live and verified).
**Stage 8 + 9**: **NEVER concurrent** — both modify `package.json` and lock files. Run one, commit, then the other. See execution-guide.md § "Safety Rules".

> **Stage skip conditions**: See `execution-guide.md` § "Stage Skip Logic" for the canonical table (e.g., skip 6R if 6V PASS, skip 7D if not needed).
>
> **Tips, troubleshooting, project structure**: See `plancasting/transmute-framework/execution-guide.md` § "Tips for Successful Plan Casting", "Safety Rules", "Troubleshooting", and "Transmute Project Structure".

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
6. NEVER use inline SVG `<path>` elements for standard UI icons. Use the project's icon library (see `plancasting/tech-stack.md` "Icon library" field and the project's icon registry file). Inline SVGs are permitted ONLY for product logos, brand marks, or custom illustrations unavailable in any icon library.

### Design & Visual Identity

<!-- ⛔ DO NOT DELETE THIS SECTION — it is critical for design quality ⛔ -->

**CRITICAL**: Before writing ANY frontend code, use the design direction in `src/styles/design-tokens.ts` and the guidelines below as the primary design authority. Additionally, check if `/mnt/skills/public/frontend-design/SKILL.md` exists (typically available only in Anthropic's hosted cloud environment, not local CLI) — if available, use its guidelines to supplement the local design tokens (the local design-tokens.ts remains the primary authority; the skill file provides additional patterns and techniques).

**Design Direction**: This project has a defined design direction stored in `src/styles/design-tokens.ts` (or equivalent) and referenced in `plancasting/tech-stack.md` (Design Direction section from Stage 0). All UI code must follow this direction consistently. If the design direction does not yet exist, establish one before building components by:
1. Reading the PRD product overview and persona definitions.
2. Choosing a BOLD aesthetic direction that matches the product's personality and target users.
3. Documenting the direction in `src/styles/design-tokens.ts` with CSS variables, color palettes, typography choices, spacing scales, and animation patterns.

**Anti-Patterns — NEVER do these**:
- Generic AI-generated aesthetics: defaulting to common font families without intentional selection, clichéd purple-on-white gradients, predictable card-grid layouts, cookie-cutter component styles. Choose fonts that match the product's personality — even widely-used fonts can work if deliberately chosen for a reason.
- Default Tailwind without customization. Always configure the Tailwind theme (via `tailwind.config.ts` or `@theme` directive in CSS, per your Tailwind version) with custom colors, fonts, and spacing that match the design direction.
- Uniform spacing and sizing everywhere. Use intentional variation — generous whitespace in some areas, controlled density in others.
- Bland, evenly-distributed color palettes. Use dominant colors with sharp accents.

**Must-Have Design Qualities**:
- **Typography**: Choose distinctive, characterful fonts. Pair a display font with a body font. Import via the framework's font optimization (e.g., `next/font` for Next.js, `@fontsource` for Vite/Remix) for performance. Never default to system fonts.
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
- No `any` types. No `@ts-ignore`. No `@ts-expect-error` (unless with an explanation comment).
- Explicit return types for all exported functions.
- Use `type` for object shapes. Use `interface` only when extension is intended.

### Testing Rules

#### Backend Function Tests
- One test file per backend function file.
- Test cases derived from PRD acceptance criteria (Given-When-Then).
- Must cover: argument validation, auth checks, happy path, error cases, edge cases, business rules.

#### Component Tests
- Test all component states (default, loading, empty, error, disabled).
- Include accessibility checks (axe-core).
- Mock backend hooks, not the API directly.

#### E2E Tests
- One test file per user flow from PRD `plancasting/prd/06-user-flows.md`.
- Cover happy path, key alternative paths, and critical error paths.
- Use `getByRole`/`getByText` selectors (not CSS classes).
- For eventually-consistent backends (e.g., Convex): use `expect.poll()` or `expect.toPass()`.

#### Test Count Preservation
- Test count must never decrease during refactoring — if a refactoring reduces test count, it is a regression. Implementation-detail tests may be restructured, but user-facing behavior tests must remain.

### Traceability Rules

Every file must include a header comment block with PRD/BRD traceability:

```typescript
/**
 * @module TaskList
 * @description Displays the user's task list with filtering and sorting.
 *
 * @traces PRD:08-screen-specifications.md#SC-012
 * @traces PRD:08-screen-specifications.md#SC-013
 * @traces PRD:04-epics-and-user-stories.md#US-003
 * @traces PRD:04-epics-and-user-stories.md#US-004
 * @traces BRD:07-functional-requirements.md#FR-007
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
| FEAT-002 | Task Management | P0 | 🔧 In Progress | ✅ | 🔧 | ⬜ | Frontend pending |
| FEAT-003 | Dashboard | P1 | ⬜ Not Started | ⬜ | ⬜ | ⬜ | Depends on FEAT-002 |
```

Valid status values: `⬜ Not Started`, `🔧 In Progress`, `✅ Done`, `🔄 Needs Re-implementation` (set by operator after 5B FAIL to trigger re-build in next Stage 5 session), `⏸ Blocked` (feature blocked by dependency or external issue — document blocker in Notes column). File location: `plancasting/_progress.md`.

**Valid state transitions**: `⬜` → `🔧` (Stage 5 starts feature) → `✅` (Stage 5 completes feature) → `🔄` (operator sets after 5B FAIL) → `🔧` (Stage 5 re-run picks up feature) → `✅`. Also: `⬜`/`🔧` → `⏸` (blocked) → `🔧` (unblocked). When transitioning `🔧` → `⏸`, preserve sub-status columns (Backend/Frontend/Tests) as-is — they indicate which layers were completed before the blocker. When unblocked (`⏸` → `🔧`), Stage 5 resumes from the first incomplete layer.

**Stage 5 resumption**: The Feature Orchestrator (Stage 5) reads this file at startup and resumes from the first `⬜ Not Started` or `🔄 Needs Re-implementation` feature, skipping all `✅ Done` and `⏸ Blocked` features. Features marked `🔧 In Progress` from a crashed session are inspected for sub-status (backend/frontend/tests completeness) and resumed from the first incomplete layer — see `prompt_feature_orchestrator.md` § "Session Recovery" and execution-guide.md § "Stage 5" for details. (`⏸ Blocked` features are treated like `✅ Done` for resumption purposes but retain their `⏸` status so the operator can unblock and re-run later.) This enables multi-session execution when the feature count exceeds the session limit.

### Path-Scoped Rules (`.claude/rules/`)

<!-- ⛔ DO NOT DELETE THIS SECTION — enables self-evolving development knowledge ⛔ -->

Claude Code natively reads `.claude/rules/` files and applies matching rules based on `globs` frontmatter. This section defines how the Transmute pipeline uses path-scoped rules to accumulate implementation knowledge across sessions.

**What rules are**: Concise, actionable directives scoped to specific file paths. They complement CLAUDE.md (which holds universal project rules) with targeted, tech-stack-specific guidance that evolves as implementation proceeds.

**Generation points**:
- **Stage 3** (Scaffold): Generates **starter rules** from `tech-stack.md` using the templates in `plancasting/transmute-framework/rules-templates/` — known patterns, gotchas, and best practices for the selected stack. These are tech-stack knowledge (theoretical). Templates: `_backend-template.md`, `_frontend-template.md`, `_api-contracts-template.md`, `_auth-template.md`, `_data-model-template.md`, `_testing-template.md`.
- **Stage 5B** (Audit): Extracts **implementation lessons** from recurring audit findings — patterns that caused stubs, duplication, or gaps across 2+ features. These are observed patterns (empirical).
- **Stage 6R** (Remediation): Captures **verified fix patterns** from successful 6V-A/B fixes — confirmed working solutions to runtime issues. These have the highest confidence (battle-tested).

**Confidence hierarchy**: Rules generated later in the pipeline carry higher inherent confidence — Stage 3 rules are theoretical (tech-stack knowledge), Stage 5B rules are empirical (observed across features), and Stage 6R rules are battle-tested (verified working fixes). When rules from different stages conflict, prefer the later stage's rule.

**Quality gate**: Every rule requires:
- **Evidence**: Issue ID (e.g., `SC-012`), commit hash, or PRD reference
- **Confidence**: HIGH (auto-promoted to `.claude/rules/`), MEDIUM/LOW (staged to `plancasting/_rules-candidates.md` for operator review)
- HIGH confidence threshold: 2+ distinct features (separate FEAT-IDs from `plancasting/prd/02-feature-map-and-prioritization.md`) affected with a clear, repeatable pattern. Two occurrences within the same feature count as 1 feature.

**Candidate staging**: Rules that don't meet the HIGH confidence threshold are staged in `plancasting/_rules-candidates.md` for operator review. Operator can promote (move to `.claude/rules/`), edit, or discard candidates.

**Limits**:
- Maximum **15 rules per file** — split into a new file if exceeded
- Maximum **8 rule files** total — consolidate related rules if exceeded
- Each individual rule (bullet point) must be ≤ 3 sentences (directive, not explanation). A section may contain multiple rules as separate bullets.

**Staleness review**: During Stage 9 (Dependency Maintenance), review all rules for staleness. Remove rules that reference deprecated APIs, outdated patterns, or resolved issues. Update rules that reference changed file paths or renamed functions.

**Rule file format** (`.claude/rules/*.md`):
```markdown
---
description: Brief description of what these rules cover
globs: ["src/backend/**", "convex/**"]
---

# Backend Rules

## [Rule Title]
<!-- Source: Stage [3/5B/6R] | Evidence: [ref] | Confidence: HIGH -->
- [Rule text — concise, actionable directive]
- [Additional rule in same section, if any]
```

### Git Conventions

#### Branch Naming
- `feat/<feature-id>-<short-description>` (e.g., `feat/US-003-task-list`)
- `fix/<issue-description>`
- `refactor/<scope>`
- `chore/<scope>` (e.g., `chore/dependency-update-2026-03-16` — used by Stage 9)
- `feedback/<scope>` (e.g., `feedback/batch-2026-03-16` — used by Stage 8)
- `docs/<scope>` (e.g., `docs/api-reference` — for documentation changes outside the pipeline)
- `redesign/<scope>` (e.g., `redesign/frontend-elevation` — used by Stage 6P-R)

#### Commit Messages
Format: `<type>(<scope>): <description> [PRD-ID]`

Examples:
- `feat(tasks): implement task list query [US-003]`
- `fix(auth): handle expired token in middleware [SR-003]`
- `test(tasks): add E2E test for task creation flow [US-005]`

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`

### Universal Prohibitions

- DO NOT omit required component states (default, loading, empty, error, disabled) — see Component Rules #1.
- DO NOT implement a feature without first reading the corresponding PRD section.
- DO NOT store secrets in code. Use environment variables.
- DO NOT remove or weaken any rule in Part 1 of this file.
- DO NOT rewrite this file from scratch. ONLY extend Part 2.
- DO NOT log, commit, or share test credentials in reports — reference by name only (e.g., "the basic-tier test user from `e2e/constants.ts`").
- DO NOT write credential values into any file other than `.env.local` (includes markdown, reports, code comments, commits). Reference by variable name only (e.g., `STRIPE_SECRET_KEY`).
- DO NOT display, echo, log, or repeat credential values in output. Use non-revealing checks (e.g., `wc -c`) to verify presence without exposing values.
- DO NOT copy credential values between files — each service reads from `.env.local` or the hosting platform's environment variable configuration.
- DO NOT use `console.log(process.env)` or log entire config/env objects in application code — log only specific non-sensitive fields. Error handlers MUST sanitize connection strings and tokens before logging.

---

## Part 1 vs Part 2 Lifecycle

- **Part 1** (above): Immutable Transmute Framework rules. Never modified after initial template placement. These are universal rules that apply to all Transmute projects regardless of tech stack.
- **Part 2** (below): Project-specific configuration. Stage 3 (Scaffold) populates this section with actual project details. The operator may customize after Stage 4 verification.

---

## Part 2: Project-Specific Configuration

<!-- Stage 3 fills [PLACEHOLDER]s with actual values. Stage 4 verifies. Extend only, do not delete. -->
<!-- ⚠️ TEMPLATE: Bracketed values below ([PROJECT_NAME], [N], [e.g., ...]) are placeholders.
     Stage 3 populates them with actual project values. Stage 4 verifies no placeholders remain.
     If reading this in a project and placeholders are still present, run Stage 4 verification. -->

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
| Icons | [e.g., Lucide / Heroicons / Tabler / framework default] | Icon library (see icon registry file) |
| CSS | [e.g., Tailwind CSS v4.1] | Styling |
| Backend | [e.g., Convex / Supabase / Firebase] | Backend-as-a-Service |
| Auth | [e.g., WorkOS / Clerk / NextAuth] | Authentication |
| AI | [e.g., Claude Agent SDK / OpenAI SDK] | AI integration |
| Payments | [e.g., Stripe] | Billing |
| E2E Testing | [e.g., Playwright] | End-to-end testing |
| Hosting | [e.g., Vercel / Cloudflare] | Deployment |

### Architecture

**Multi-tenant**: [Describe tenant boundary — org-based, user-based, workspace-based, etc.]

**Auth helpers**: [List the actual auth helper functions and their locations]

**Soft delete**: [Describe the soft-delete pattern if applicable, including field name and retention period]

**Deployment**: [Describe deployment order and production URLs]

**Testing**: [Describe test runner config, workspace setup, E2E tags]

### Commands

> Commands below use `bun run` as default. Adapt to your package manager per `plancasting/tech-stack.md`.

```bash
# Development
bun run dev              # [describe what this starts]
bun run dev:backend      # Backend only (if separate; adapt command name to your stack)

# Testing
bun run test             # Unit + integration tests
bun run test:e2e         # E2E tests (Playwright)
bun run test:e2e:critical # Critical path E2E only (if applicable)

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
bun run seed:empty       # Empty-state users (no data) for UI verification
bun run seed:verify      # Referential integrity check on seeded data
bun run seed:reset       # Clear all data and re-seed
```

### Backend Rules

<!-- Stage 3: Add backend-specific summary rules here (validation patterns, error handling, auth guards); full rules are in .claude/rules/backend.md -->

### Frontend Rules

<!-- Stage 3: Add frontend-specific summary rules here (component states, design tokens, responsive patterns); full rules are in .claude/rules/frontend.md -->

### Security Rules

<!-- Stage 3: Add security summary patterns here (auth middleware, public routes, session handling); full rules are in .claude/rules/auth.md -->

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

See `docs/developer/conventions.md` (generated by Stage 6D; not available before that stage) for: design guidelines, TypeScript rules, testing details, traceability format, git conventions, naming conventions, inline style exceptions.
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
