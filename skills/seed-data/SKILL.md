---
name: seed-data
description: >-
  Generates comprehensive, realistic seed data for all environments (dev, test, demo, stress).
  This skill should be used when the user asks to "generate seed data",
  "create test data", "populate the database", "create demo data",
  "generate edge case data", or "set up seed scripts"
  — or when the transmute-pipeline agent reaches Stage 6F of the pipeline.
version: 1.0.0
---

# Stage 6F: Realistic Test Data for All Environments

Lead a multi-agent seed data generation project. Generate comprehensive, realistic seed data covering all entities in the data model, supporting all user flows, and enabling meaningful testing and demonstrations of the COMPLETE product.

## Prerequisites

Verify before starting:

1. `./plancasting/_audits/implementation-completeness/report.md` exists with PASS or CONDITIONAL PASS. If missing, WARN and proceed noting seed data for stub features may need regeneration.
2. `./plancasting/_audits/refactoring/report.md` (6E) exists. If missing, WARN that seed data may need regeneration if 6E introduces schema changes. If present, read to understand schema changes.
3. Read `./CLAUDE.md` and `./plancasting/tech-stack.md` for project conventions.
4. If `./plancasting/_audits/security/report.md` (6A) exists, read for auth requirements affecting seed data.

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports in that language. Code and file names remain in English. Replace all command references with the project's package manager from `CLAUDE.md`.

## Stack Adaptation

Source examples use Convex + Next.js. Adapt all paths and patterns to your actual tech stack: `convex/` becomes your backend directory, Convex mutations become your backend mutation functions, etc.

## Known Failure Patterns

1. **Foreign key reference failures**: Use actual returned IDs through shared state, never hardcode.
2. **Identical timestamps**: Add increments (`Date.now() - i * 86400000`) for realistic distributions.
3. **Business rule violations**: Always go through backend mutation functions, not direct inserts. Create internal/admin seed functions if auth is required.
4. **Non-idempotent seeds**: Implement upsert logic or require `seed:reset` before re-seeding.
5. **Auth credential gaps**: Consider the full auth flow when creating persona users.
6. **Missing soft-deleted records**: Include some records with `deletedAt` set to verify query filtering.
7. **Orphaned references**: Child records referencing deleted parents — include integrity verification.

## Phase 1: Lead Analysis and Planning

Complete BEFORE spawning teammates:

1. Read `./CLAUDE.md`, `./plancasting/tech-stack.md`, your schema file, and PRD `11-data-model.md`.
2. Read PRD `01-product-overview.md` for personas and `06-user-flows.md` for journeys.
3. Read BRD `14-business-rules-and-logic.md` for validation rules.
4. Build a Seed Data Plan mapping every table to needed seed data:
   - **Dev tier**: 5-20 records per table for rapid iteration.
   - **Test tier**: 50-200 records per table for thorough testing including pagination.
   - **Demo tier**: Curated scenarios with realistic names and relationships.
   - **Stress tier**: 500-1,000 records per major table for performance testing.
   - **Empty-state tier**: Users with NO associated data for empty state UI verification.
   - Persona-based data sets for each PRD persona.
   - Edge case data: empty states, max-length strings, special characters, Unicode, boundary values.
   - Dependency map: which tables must be seeded first.
   - **Mutation function emphasis**: ALL data insertion must use backend mutation functions, not direct database inserts. This ensures validators, auth checks, and business rules are respected.
5. Create `./seed/README.md` with the seed data plan.

## Phase 2: Spawn Seed Data Teammates

Spawn Teammate 1 first. Wait for completion and validate `.seed-ids.json` per the Synchronization Protocol. Only after validation, spawn Teammates 2 and 3 in parallel.

### Teammate 1: "core-data-seeder"

Scope: Foundational entities (users, organizations, roles, settings).

Tasks:
- Create `./seed/core.ts` with production environment safety check at the top of all seed functions. Adapt the check to your backend's environment detection.
- Use backend mutation functions to insert data respecting all schema validators.
- Create persona user accounts with realistic names, emails, complete profiles, appropriate roles.
- Include at least one admin user and one user per distinct role.
- Handle auth provider integration: implement programmatic creation if SDK available, or document manual steps in `./seed/MANUAL_SETUP.md`.
- Generate three tiers: `seedCoreDev()` (2-3 users, 1 org), `seedCoreTest()` (10-15 users, 3 orgs), `seedCoreDemo()` (5-8 personas, 2 orgs).
- Include edge case users (max-length name, Unicode, minimal fields, deactivated).
- Include 2-3 soft-deleted records per entity type.
- Write created IDs to `./seed/.seed-ids.json`. Verify it is in `.gitignore`.

### Teammate 2: "feature-data-seeder"

Scope: Feature-specific entities. Blocked by Teammate 1.

Tasks:
- Create `./seed/features.ts` for EVERY feature-specific table.
- Cover happy paths of every user flow. Include various states (draft/active/completed/archived). Use realistic content, not "Test Item 1". Respect business rules. Create proper relationships via backend IDs. Include realistic timestamp distributions.
- Three tiers: `seedFeaturesDev()` (3-5 items per feature per user), `seedFeaturesTest()` (20-50 items, enough for pagination), `seedFeaturesDemo()` (hand-crafted showcase scenarios).
- Demo data must include a completed end-to-end scenario, compelling dashboard data, cross-feature data.
- Include 2-3 soft-deleted items per feature.

### Teammate 3: "edge-case-seeder"

Scope: Edge case and stress test data. Blocked by Teammate 1.

Tasks:
- Create `./seed/edge-cases.ts` with boundary records: empty/minimal, maximum-length, special characters (Unicode, emoji, RTL, HTML entities, SQL injection strings as data), boundary values, all state combinations, soft-deleted edge cases.
- Create `./seed/stress.ts` with `seedStress()`: 500-1,000 records per major table. Use batch operations for rate-limited backends. Realistic distributions (80/20 ownership for stress, even spread for demo). Realistic timestamp distributions.
- Create `./seed/empty-state.ts` with `seedEmptyState()`: users with NO associated data for empty state UI verification.

## Synchronization Protocol

IDs are shared via `./seed/.seed-ids.json`. Only Teammate 1 writes this file. Teammates 2 and 3 read but do not modify it.

After Teammate 1 completes, validate:
- File exists and parses as valid JSON.
- Contains expected top-level keys (`users`, `organizations`, etc.).
- Each key maps to a non-empty object of `{ label: id }` pairs.
- IDs are database IDs (for foreign keys), not auth-provider IDs.

If validation fails, do NOT spawn Teammates 2/3 — re-spawn Teammate 1 with fix instructions. Fallback: extract IDs from completion message and write the file manually.

## Phase 3: Integration and Seed Script

After all teammates complete:

1. Create `./seed/index.ts` — master orchestrator for all seed tiers (dev, test, demo, stress, empty, reset).
2. Create `./seed/reset.ts` — clear all tables with confirmation parameter and production safety check.
3. Add seed commands to `package.json`: `seed:dev`, `seed:test`, `seed:demo`, `seed:stress`, `seed:empty`, `seed:verify`, `seed:reset`.
4. Test each seed tier and verify no schema validation errors.
5. Run `bun run typecheck && bun run test` to verify no regressions.
6. Run E2E tests against test seed data if test credentials are configured.
7. Create `./seed/verify-integrity.ts` checking: referential integrity, no orphaned records, soft-delete filtering, valid enum/status values. Add as `seed:verify` command.
8. Update `./seed/README.md` with run instructions, persona credentials, data volumes, reset procedure.

### Integrity Check Failure Recovery

- **Minor constraint violation**: Document as known limitation. Proceed.
- **Referential integrity failure**: Reset and re-execute the failing seed script. If repeated, escalate for manual fix.
- **Schema mismatch**: Flag as BLOCKING. Pause all teammates. Verify schema against current codebase. Report to pipeline orchestrator.

## Output

Generate `./plancasting/_audits/seed-data/report.md` containing:
- Data volume summary per tier
- Persona accounts with credentials
- Integrity verification results
- Edge cases covered
- Constraints or manual steps required

## Gate Decision

- **PASS**: All tiers generated successfully, referential integrity verified, seed data renders correctly in UI.
- **CONDITIONAL PASS**: Generated with documented constraints (e.g., auth users need manual creation, deferred features have no seed data).
- **FAIL**: Schema mismatches, missing core entities, or referential integrity failures.

## Critical Rules

1. NEVER use real personal data in seed data.
2. NEVER bypass schema validators — all data goes through backend mutation functions.
3. NEVER hardcode document IDs — use IDs returned from insert operations.
4. Seed scripts MUST be idempotent or provide `seed:reset`.
5. ALWAYS include soft-deleted records to verify query filtering.
6. ALWAYS verify seed data renders correctly in the UI, not just that it inserts.
7. ALWAYS include realistic timestamps with proper chronological ordering.
8. Demo data dates should be relative to "now" so demos always look current.
9. If auth provider requires API calls to create users, document as manual step or implement in seed script.
