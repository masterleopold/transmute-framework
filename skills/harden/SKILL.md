---
name: harden
description: >-
  Hardens error handling, network failure recovery, and edge case resilience across the product.
  This skill should be used when the user asks to "harden error handling",
  "add resilience", "handle network failures", "add retry logic",
  "add circuit breakers", "handle edge cases", or "improve error recovery"
  — or when the transmute-pipeline agent reaches Stage 6G of the pipeline.
version: 1.0.0
---

# Stage 6G: Error Handling, Network Failures, and Edge Cases

Lead a multi-agent error resilience hardening project. Systematically review the COMPLETE product for error handling gaps, network failure scenarios, race conditions, and edge cases that individual feature implementations may have missed.

## Prerequisites

Verify before starting:

1. `./plancasting/_audits/implementation-completeness/report.md` exists with PASS or CONDITIONAL PASS. If missing, WARN and proceed — flag findings in stub code separately.
2. `./plancasting/_audits/refactoring/report.md` (6E) exists. If missing, WARN that 6G is recommended after 6E for cleaner patterns. Proceed with warning documented.
3. Read `./CLAUDE.md` and `./plancasting/tech-stack.md` for project conventions.
4. If `./plancasting/_audits/security/report.md` (6A) exists, include in teammate prompts. If missing, WARN about rate limiting scope boundaries.

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports in that language. Code and file names remain in English. Replace all command references with the project's package manager from `CLAUDE.md`.

## Stack Adaptation

Source examples use Convex + Next.js. Adapt all paths and patterns to the actual tech stack: `convex/` becomes your backend directory, Convex OCC becomes your concurrency control, `src/app/` becomes your frontend pages, etc.

## Known Failure Patterns

1. **Retry on non-idempotent operations**: Causes duplicate data. ALWAYS verify idempotency before adding retries.
2. **Permanently open circuit breakers**: Never reset after transient outage. ALWAYS include a reset mechanism.
3. **Error boundaries that lose state**: Form data lost when boundary catches error. ALWAYS preserve user input.
4. **Over-aggressive timeouts**: 3-second timeouts on 10+ second operations. Match timeouts to actual characteristics.
5. **Silent error swallowing**: Errors caught but logged silently. Every caught error must be re-thrown, logged, or communicated.
6. **Graceful degradation that hides features**: Show degraded state with explanation, not blank space.

## Phase 1: Lead Analysis and Planning

Complete BEFORE spawning teammates:

1. Read `./CLAUDE.md`, `./plancasting/tech-stack.md`, BRD non-functional requirements, and PRD `15-non-functional-specifications.md`. Read `./plancasting/_audits/performance/report.md` if it exists for timeout baselines.
2. Map all external dependencies: third-party APIs, auth provider, file storage, email service, other services from `plancasting/tech-stack.md`.
3. Identify all multi-step operations (workflows involving multiple mutations/actions in sequence).
4. Create `./plancasting/_audits/resilience/plan.md` with analysis and task assignments.
5. Decide execution order: parallel (default, low-risk API changes) or sequential (if high-risk API contract changes affecting 5+ endpoints — spawn Teammate 1 first, then 2+3 after completion).

## Phase 2: Spawn Hardening Teammates

### Teammate 1: "backend-resilience"

Scope: Backend error handling, external service failures, data consistency.

Tasks:

1. **External service failure handling**: For each external API call, verify try/catch, timeout configuration (fast APIs: 3-5s, file ops: 30s, AI calls: 60-120s), retry with exponential backoff (max 3 retries, delay = `min(2^attempt * 1000ms, 30000ms)`, honor `Retry-After` headers for 429s), circuit breaker pattern (CLOSED -> OPEN after 5 failures -> HALF-OPEN after 60s cooldown). For serverless environments, use database-persisted state or simpler retry-with-backoff pattern. Circuit breakers on QUERY paths return cached/fallback data; on mutation paths return graceful error messages.

2. **Multi-step operation safety**: Verify failure at step N does not leave inconsistent state. Implement idempotency where appropriate. If full rollback not possible, ensure partial state is detectable and recoverable. For long-running workflows: verify step failure retry, explicit timeouts, idempotency keys, progress checkpoints, compensation logic, persistent workflow state.

3. **Data validation hardening**: Verify business rule violations throw clear typed errors. Handle concurrent modification scenarios with retry prompts. Add stale-data validation for check-then-act patterns.

4. **Rate limiting**: Check if 6A already added rate limiting (6A covers AUTH endpoints, 6G covers DATA-MUTATION endpoints). Verify mutations have rate limiting. Verify file uploads have server-side size limits.

**Idempotency rule**: Only add automatic retries for idempotent mutations (set X = 5). Non-idempotent mutations (INSERT, increment) must surface errors to the user with a manual retry option.

**API contract changes**: Document any changes with before/after examples. Lead reconciles in Phase 3.

If an issue requires architectural changes beyond this stage's scope, document in `plancasting/_audits/resilience/unfixable-violations-backend.md` and continue.

### Teammate 2: "frontend-resilience"

Scope: UI error states, network failure UX, offline behavior.

Tasks:

1. **Error boundary completeness**: Every route has an error boundary with user-friendly message and "try again" action. Nested boundaries for independent page sections.

2. **Network failure UX**: Every mutation has error handling. User sees feedback on failure. Retry mechanism exists. Form data preserved on submission failure.

3. **Loading and timeout states**: All queries show loading state. Timeout handling after 10 seconds with retry option. Adapt to data layer (REST: AbortController, reactive backends: check undefined for 10+ seconds). Safe navigation during loading (no unmount errors).

4. **Backend connection resilience**: Graceful handling of connection loss with "reconnecting" indicator. Automatic recovery on reconnection. No data loss during disconnection.

5. **Optimistic update rollback**: Verify rollback path works. User notified on failure. No UI flash (optimistic -> rollback -> error).

If an issue requires architectural changes, document in `plancasting/_audits/resilience/unfixable-violations-frontend.md` and continue.

### Teammate 3: "edge-case-hardener"

Scope: Cross-cutting edge cases, concurrent usage, boundary conditions.

Tasks:

1. **Concurrent usage**: Two users editing same entity (handle concurrency rejection gracefully). User viewing entity that another deletes (show deleted state, redirect, or disable actions). Permission changes during active usage.

2. **Empty and boundary conditions**: 0 items, 1 item (singular/plural), maximum items (pagination), max-length text (truncation/overflow), negative/zero/large numbers, timezone handling.

3. **Authentication edge cases**: Session expiry mid-operation. Logout in another tab. Deep links with unauthenticated users. Invitation flow edge cases (expired invites, registered emails).

4. **Navigation edge cases**: Back/forward navigation preserving state. Direct URL access (deep linking). Unsaved changes confirmation. 404 for invalid routes and entity IDs.

5. **E2E tests**: Write tests for critical edge cases in `e2e/resilience/`. Focus on data loss and user confusion scenarios.

If an issue requires architectural changes, document in `plancasting/_audits/resilience/unfixable-violations-edge-cases.md` and continue.

## Phase 3: Post-Completion Reconciliation

After all teammates complete:
- Review cross-team findings and reconcile (retry logic needs UI feedback, concurrent edit scenarios need server-side resolution).
- Resolve shared-file conflicts.
- Merge per-teammate unfixable-violations files into `plancasting/_audits/resilience/unfixable-violations.md`. Delete per-teammate files.

## Phase 4: Verification and Report

1. Run full test suite:
   ```bash
   bun run typecheck
   bun run lint
   bun run test
   bun run test:e2e
   ```
   All existing tests must pass. New resilience tests must also pass.

2. Generate `./plancasting/_audits/resilience/report.md` with:
   - External service failure handling patterns implemented
   - Multi-step operation safety measures
   - UI error handling improvements
   - Edge cases addressed
   - New E2E tests added
   - Remaining risks and recommendations
   - Reference to `unfixable-violations.md` under Blocking Issues (if any exist)

## Gate Decision

- **PASS**: All external calls have error handling and retry/circuit breaker patterns; all multi-step operations have consistency guarantees; new resilience tests pass.
- **CONDITIONAL PASS**: Core features are resilient; non-critical features have documented gaps.
- **FAIL**: Critical user flows lack error handling; multi-step operations can leave data inconsistent.

## Critical Rules

1. NEVER add retry logic to non-idempotent mutations — fix idempotency first.
2. NEVER swallow errors silently — re-throw, log, or communicate to user.
3. NEVER add circuit breakers without a reset mechanism.
4. Retry backoff MUST use exponential backoff with jitter: `min(2^attempt * 1000ms, 30000ms) + random(0, 1000ms)`. Maximum 3 retries.
5. ALWAYS preserve user input across error recovery.
6. ALWAYS run the full test suite after resilience changes.
7. Match timeout values to actual operation characteristics.
8. Reference Stage 5B output to avoid hardening incomplete features.
9. For long-running workflows: verify step failure handling, timeout handling, and resume-from-failure capability.
