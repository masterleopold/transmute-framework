---
name: refactor
description: >-
  Audits the codebase for code quality issues and refactors without changing external behavior.
  This skill should be used when the user asks to "refactor the codebase",
  "clean up code quality", "eliminate duplication", "improve abstractions",
  "enforce consistency", "remove dead code", or "optimize architecture"
  — or when the transmute-pipeline agent reaches Stage 6E of the pipeline.
version: 1.0.0
---

# Stage 6E: Code Quality and Architecture Refinement

Lead a multi-agent code refactoring project. Audit the COMPLETE codebase for code quality, eliminate duplication, improve abstractions, enforce consistency, and optimize architecture — without changing any external behavior.

## Cardinal Rule

**NO BEHAVIORAL CHANGES.** Refactoring changes internal structure without altering external behavior. Every test that passed before refactoring MUST still pass after. If a refactoring would require changes to tests that validate external behavior (API contracts, acceptance criteria), the behavior is changing — stop and reconsider. Tests validating implementation details (private functions, internal state) may be restructured.

## Prerequisites

Verify before starting:

1. `./plancasting/_audits/implementation-completeness/report.md` exists with PASS or CONDITIONAL PASS. If missing or FAIL, STOP — Stage 5B must pass first.
2. Read `./CLAUDE.md` and `./plancasting/tech-stack.md` for project conventions.
3. Check that `./plancasting/_audits/security/report.md` (6A), `./plancasting/_audits/accessibility/report.md` (6B), and `./plancasting/_audits/performance/report.md` (6C) exist. If any are missing, WARN and document in the report.

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports in that language. Code and file names remain in English. Replace all `npm run` / `bun run` commands with the project's package manager from `CLAUDE.md`.

## Stack Adaptation

Source examples use Convex + Next.js. Adapt all paths and patterns to the actual tech stack in `plancasting/tech-stack.md`: `convex/` becomes your backend directory, Convex functions become your backend functions, `src/app/` becomes your frontend pages, etc. Read `CLAUDE.md` Part 2 for actual conventions.

## Phase 1: Lead Analysis and Planning

Complete BEFORE spawning teammates:

1. Read `./CLAUDE.md`, `./plancasting/tech-stack.md`, `./ARCHITECTURE.md` (if exists), and `./plancasting/_audits/implementation-completeness/report.md`.
2. Run the full test suite and save baseline to `./plancasting/_audits/refactoring/baseline-test-results.md`:
   ```bash
   bun run typecheck
   bun run test
   bun run test:e2e
   ```
   Verify test counts are non-zero. If ALL test suites return 0 test files, STOP — do not refactor without tests. If baseline tests fail, STOP and resolve failures first.
3. Count total files, functions, components, hooks, and lines of code. Identify largest files and highest-coupling files.
4. Analyze the codebase for refactoring opportunities across seven categories: Duplication, Abstraction, Consistency, Schema, Coupling, Dead code, and File structure.
5. Create `./plancasting/_audits/refactoring/plan.md` with prioritized opportunities, affected files, risk levels, and parallelizable work packages.

Read the detailed guide at `${CLAUDE_SKILL_ROOT}/references/refactor-detailed-guide.md` for the complete teammate spawn prompts, coordination protocols, and analysis criteria.

## Phase 2: Spawn Refactoring Teammates

Spawn 4 teammates. Each spawn prompt MUST include the refactoring plan and the cardinal rule.

**Teammate 1 — "backend-refactorer"**: Backend functions, schema, server-side code. Tasks: function deduplication, schema optimization (index cleanup with verification), consistency enforcement (error handling, auth, validation patterns), dead code removal (with string-reference search), file splitting for 300+ line files.

**Teammate 2 — "frontend-component-refactorer"**: React components and pages. Tasks: component deduplication into shared directory, pattern extraction (forms, lists, modals, state components), prop interface cleanup (no `any`, consistent naming), file splitting, design token compliance. Do NOT create hooks — send hook requirements to Teammate 3.

**Teammate 3 — "hooks-and-logic-refactorer"**: Custom hooks, utilities, types, shared logic. Tasks: hook deduplication (generic parameterized hooks), utility consolidation, type consolidation into shared files, import cleanup (unused imports, path aliases, ordering), dead code removal.

**Teammate 4 — "test-and-structure-refactorer"**: Test quality, E2E tests, project structure. Tasks: test deduplication (shared fixtures), test quality (clear descriptions, single-assertion, Given-When-Then), E2E optimization (journey consolidation, page objects), project structure (naming, no circular deps), traceability audit. Test count must be >= baseline.

Each teammate runs verification (`bun run typecheck && bun run test`) after ALL changes and reverts any change that causes test failures.

## Phase 3: Coordination

Monitor progress and facilitate cross-team dependencies:
- Backend extractions affect hook call patterns — notify Teammate 3.
- Frontend component extractions affect hook return types — notify Teammate 3.
- Utility moves affect imports everywhere — notify Teammates 2 and 4.
- For shared-file conflicts: assign priority to the more structural change; other teammate waits.
- After each teammate completes, run `bun run typecheck && bun run test` immediately.

## Phase 4: Integration Verification

After all teammates complete:

1. Run COMPLETE test suite and compare to baseline. Pass count must be >= baseline. Zero regressions.
2. Run `bun run lint` and fix lint errors introduced by refactoring.
3. If E2E tests lack coverage for critical pages, start dev server and manually verify.
4. Update `ARCHITECTURE.md` if refactoring changed module boundaries.
5. Generate `./plancasting/_audits/refactoring/report.md` with:
   - Metrics before vs after (files, lines, duplications eliminated, shared modules created, dead code removed, largest file, unused indexes removed)
   - Changes by category
   - Test results (baseline vs post-refactoring, zero regressions required)
   - Remaining technical debt with rationale
   - Recommendations to prevent re-accumulation

## Gate Decision

Include in the report:

- **PASS**: All tests pass, zero regressions, lint errors resolved, code quality metrics improved.
- **CONDITIONAL PASS**: All tests pass, minor refactoring opportunities remain documented.
- **FAIL**: Test regressions introduced, or behavioral changes detected.

## Phase 5: Shutdown

Request shutdown for all teammates. Verify all modifications are saved and committed.

## Critical Rules

1. NEVER refactor and add features in the same change.
2. NEVER delete a public export without verifying zero external consumers.
3. NEVER refactor code without test coverage — add tests first.
4. NEVER remove database indexes without verifying all query patterns including production logs.
5. ALWAYS commit after each logical refactoring unit.
6. ALWAYS run the full test suite after every refactoring step.
7. If refactoring reduces test count, it is a regression — investigate.
8. Adding new tests during refactoring is acceptable. Removing tests that validate user-facing behavior is NOT.
9. Reference Stage 5B output to avoid refactoring incomplete features.

## Cross-Stage References

- Runs AFTER 6A-6C. Do not refactor patterns intentionally introduced by those audits.
- If re-running after a prior 6V pass, run a targeted 6V subset to verify no regressions.
- If deploying refactored code to production, run Stage 7V afterward.
