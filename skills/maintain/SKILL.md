---
name: maintain
description: >-
  Updates dependencies, applies security patches, and manages package versions on a regular cadence.
  This skill should be used when the user asks to "update dependencies",
  "run dependency maintenance", "check for outdated packages",
  "apply security patches", "update npm packages", "run stage 9",
  "check for vulnerabilities", or "upgrade dependencies",
  or when the transmute-pipeline agent reaches Stage 9 of the pipeline.
version: 1.0.0
---

# Dependency Maintenance — Stage 9

## Context

Designed to be run on a regular cadence (monthly or quarterly) to keep the codebase healthy. Outdated dependencies accumulate security vulnerabilities, miss performance improvements, and eventually create painful migration cliffs.

## Prerequisites

1. Read `CLAUDE.md` and `plancasting/tech-stack.md`.
2. Ensure `git status` shows a clean working directory. Commit or stash all uncommitted changes.
3. Check `plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports in the specified language.

## Inputs

- **Codebase**: Complete project directory
- **Tech Stack**: `./plancasting/tech-stack.md`
- **Project Rules**: `./CLAUDE.md`
- **Lock file**: `package-lock.json`, `bun.lockb`, or `pnpm-lock.yaml`

## Stack Adaptation

Examples use `bun` commands. Adapt to your package manager:
- `npm audit` -> Bun has no built-in audit. Use `npm audit` if `package-lock.json` exists; otherwise use `bunx audit-ci` or `npx snyk test`.
- `npm update` -> `bun update`
- `npm outdated` -> `bun outdated` or `npx npm-check-updates`
Always read `CLAUDE.md` and `plancasting/tech-stack.md` for actual conventions.

## Execution Flow

### Phase 1: Lead Analysis and Planning

**Branch safety**: Create a dedicated branch: `git checkout -b chore/dependency-update-$(date +%Y-%m-%d)`. Do NOT commit directly to main.

1. Read `CLAUDE.md` and `plancasting/tech-stack.md`.
2. Verify clean working directory.
3. Create maintenance directory: `mkdir -p ./plancasting/_maintenance`
4. Record the current baseline:
   ```bash
   bun run typecheck
   bun run lint
   bun run test
   bun run test:e2e
   bun run build
   ```
   Save results to `./plancasting/_maintenance/baseline-$(date +%Y-%m-%d).md`. If baseline tests fail, STOP: "Pre-existing test failures detected. Fix test failures before running dependency maintenance."

5. Analyze current dependencies:
   ```bash
   npx npm-check-updates > ./plancasting/_maintenance/outdated.txt
   npm audit --json > ./plancasting/_maintenance/audit.json
   ```
   If no outdated dependencies and no vulnerabilities, generate a brief report and exit early.

6. Categorize updates:
   - **Security patches** (any severity): MUST update
   - **Patch versions** (x.y.Z): Low risk
   - **Minor versions** (x.Y.z): Medium risk
   - **Major versions** (X.y.z): High risk

7. Create `./plancasting/_maintenance/update-plan.md` with ordered updates (security first), risk assessments, and parallelizable batches. For major versions, search for migration guides and breaking change notes.

8. Create task list for teammates.

### Phase 2: Spawn Maintenance Teammates

Spawn 3 teammates SEQUENTIALLY (low risk -> medium -> high risk).

**Teammate 1 -- "security-and-patch-updater"**: Apply security patches and patch version updates. For each vulnerability: update to patched version or research alternatives. Run typecheck, test, and lint after each batch. Run test:e2e if updates touch auth libraries, HTTP clients, or test frameworks.

**Teammate 2 -- "minor-version-updater"** (BLOCKED by Teammate 1): Apply minor version updates. Check changelogs for deprecations and behavioral changes. Handle environment variable changes (update `.env.local.example`, NEVER commit `.env.local`). Replace deprecated API usage. Run verification after each update. If Playwright was updated, run `bunx playwright install` before E2E tests.

**Teammate 3 -- "major-version-updater"** (BLOCKED by Teammate 2): Apply major version updates ONE AT A TIME. Follow migration guides. Run full verification suite (typecheck, lint, test, test:e2e, build) after EACH major update. Handle framework updates with extra care (check config file changes). For backend SDK updates: re-run code generation immediately (e.g., `bunx convex codegen` for Convex, `npx prisma generate` for Prisma). If update is too complex, revert and document.

### Phase 3: Coordination

Monitor progress. Enforce sequential dependency. Help research breaking changes.

### Phase 4: Final Verification and Report

1. Run COMPLETE test suite. Compare to baseline.
2. **Runtime version check**: If major updates changed `engines` requirements, verify Node.js/Bun version compatibility.
3. Re-run security audit. Compare to baseline.
4. Generate `./plancasting/_maintenance/report-$(date +%Y-%m-%d).md`:
   - Updates applied (security, patch, minor, major counts)
   - Deferred updates with rationale
   - Test results: baseline vs post-update
   - Security audit: before vs after vulnerability count
   - Recommendations for future updates
   - Next maintenance date suggestion
5. Update `plancasting/tech-stack.md` with new version numbers for core dependencies.
6. Update CLAUDE.md Part 2 if major framework versions changed.
7. Note affected features in `plancasting/_progress.md` if behavioral code changes were made.
8. Merge maintenance branch: `git checkout main && git merge chore/dependency-update-YYYY-MM-DD`. If merge fails due to lock file conflicts, rebase, reinstall, re-verify, retry.
9. Output summary.

## Gate Decision

- **PASS**: All tests pass post-update, no remaining critical/high vulnerabilities, build succeeds. Proceed to deployment and Stage 7V.
- **CONDITIONAL PASS**: Tests pass but some major updates deferred. Schedule follow-up.
- **FAIL**: Test suite fails and cannot be resolved, or critical vulnerabilities remain unpatched.

## Known Failure Patterns

1. **Peer dependency conflicts**: Package A requires React 18, Package B requires React 19. Find compatible versions first; AVOID `--legacy-peer-deps`.
2. **Lock file regeneration**: NEVER delete the lock file. See Lock File Strategy below.
3. **Type definition mismatches**: ALWAYS update `@types/*` alongside runtime packages.
4. **PostCSS/Tailwind breakage**: CSS toolchain is fragile across versions. Test styling thoroughly.
5. **Backend SDK updates**: May require schema migration or codegen re-runs.
6. **Build-only breakage**: Tests pass but production build fails. ALWAYS run `build` after major updates.
7. **Node.js/Bun version requirements**: New versions may require newer runtime.
8. **Environment variable changes**: Auth/payment SDK updates may rename env vars.
9. **Playwright browser binary mismatch**: Run `bunx playwright install` after updating Playwright.

## Lock File Strategy

- NEVER delete the lock file to resolve conflicts.
- Commit the updated lock file after each successful update batch.
- For `bun.lockb` (binary): verify by running `bun install` twice (should be idempotent).
- If lock file conflicts arise, remove only the conflicting package and re-install.

To verify `bun.lockb` integrity:
1. Record hash before update: `shasum -a 256 bun.lockb`
2. After `bun install`, run `bun install` again (should produce no changes)
3. If the lock file changes on the second install, dependency resolution is unstable

## Running Cadence

- **Monthly**: Products with strict security requirements or rapidly evolving dependencies.
- **Quarterly**: Most products in active development.
- **On trigger**: When `npm audit` reports a critical vulnerability.

Each run produces a report in `./plancasting/_maintenance/` with the date, building a maintenance history.

## Cross-Stage References

- UI regressions from updates: run **Stage 6V** (Visual & Functional Verification).
- After deploying updates: run **Stage 7V** (Production Smoke Verification).
- User-reported issues from dependency changes: process through **Stage 8** (Feedback Loop).
- If UI component library updated, consider re-running Stage 7D screenshot recapture.

## Critical Rules

1. NEVER update all dependencies at once -- batch by risk tier (security -> patch -> minor -> major).
2. AVOID `--legacy-peer-deps` to force-resolve conflicts. Document if absolutely necessary.
3. NEVER delete the lock file to resolve conflicts.
4. ALWAYS commit to the maintenance branch after each successful tier for granular rollback.
5. ALWAYS run `build` (not just `test`) after major updates.
6. ALWAYS run `lint` after updates -- new plugin versions may introduce rules.
7. Re-run backend code generation after backend SDK updates (e.g., `bunx convex codegen`).
8. For major framework updates, recommend re-running Stage 6V.
9. After deploying, run Stage 7V.
10. Co-dependent packages must be updated together (e.g., `react` + `@types/react`, all `@radix-ui/*`).
