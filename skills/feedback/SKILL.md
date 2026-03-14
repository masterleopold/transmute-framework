---
name: feedback
description: >-
  Processes user feedback batches through the spec-update-code-test-docs chain.
  This skill should be used when the user asks to "process user feedback",
  "run the feedback loop", "analyze user feedback", "implement feedback changes",
  "triage support tickets", "run stage 8", "process feedback batch",
  or "update specs from feedback",
  or when the transmute-pipeline agent reaches Stage 8 of the pipeline.
version: 1.0.0
---

# User Feedback Loop — Stage 8

## Critical Concept: Living Documents

The BRD and PRD are NOT frozen artifacts. They are living documents that evolve with the product. This skill maintains the chain: Feedback -> Spec Update -> Code Change -> Test Update -> Doc Update, ensuring every layer stays consistent.

## Prerequisites

1. Read `CLAUDE.md` and `plancasting/tech-stack.md`.
2. Verify `./feedback/input.md` exists. If not, stop: "No feedback to process. Create `./feedback/input.md` with feedback items before running Stage 8."
3. Check `plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports in the specified language.

## Inputs

- **User Feedback**: `./feedback/input.md` (structured feedback -- see format below)
- **Existing Specs**: `./plancasting/brd/`, `./plancasting/prd/`
- **Tech Stack**: `./plancasting/tech-stack.md`
- **Codebase**: Backend directory, `./src/`, `./e2e/` (adapt to your stack)
- **Project Rules**: `./CLAUDE.md`
- **Progress Tracker**: `./plancasting/_progress.md` (if exists)
- **User Guide** (if exists): `./user-guide/` (Mintlify docs from Stage 7D)

## Stack Adaptation

Examples use Convex + Next.js paths. Adapt to your stack:
- `convex/` -> your backend directory
- `src/` -> your frontend directory
- `npm run` -> your package manager command
Always read `CLAUDE.md` and `plancasting/tech-stack.md` for actual conventions.

## Preparing the Feedback Input

Create `./feedback/input.md` with structured feedback:

```markdown
# User Feedback Batch — [Date]

## Source: Support Tickets (Jan 15-31)

### TICKET-001: Users cannot find the export function
- **Frequency**: 12 tickets in 2 weeks
- **User Quote**: "I've looked everywhere but can't figure out how to export my data"
- **Affected Feature**: Data Export (FEAT-015)

## Source: Analytics (Jan 1-31)

### ANALYTICS-001: 60% drop-off on onboarding step 3
- **Metric**: Funnel completion rate
- **Current**: 40% complete onboarding
- **Target**: 80% (from PRD)

## Source: Stakeholder Request

### STAKEHOLDER-001: Add bulk delete capability
- **Requester**: Operations Team Lead
- **Justification**: "Manually deleting items one by one is taking hours"
- **Priority Request**: High
```

## Execution Flow

### Phase 1: Lead Analysis — Feedback Triage

**Branch safety**: Create a dedicated branch before starting: `git checkout -b feedback/batch-$(date +%Y-%m-%d)`.

1. Read `./CLAUDE.md`, `./plancasting/tech-stack.md`, and `./feedback/input.md`.
2. Read `./plancasting/prd/_context.md` (or `plancasting/prd/README.md`) and `./plancasting/brd/_context.md` (or `plancasting/brd/00-cover-and-metadata.md`) for existing feature inventory. Extract maximum existing requirement IDs.
3. **Categorize each feedback item**:

   | Category | Description | Action |
   |---|---|---|
   | Bug | Product doesn't match existing spec | Fix code to match spec |
   | UX Issue | Product matches spec but spec is wrong | Update spec + fix code |
   | Missing Feature | Capability not in current spec | Add to spec + implement |
   | Performance | Doesn't meet NFR targets | Optimize (use Stage 6C) |
   | Enhancement | Existing feature needs improvement | Update spec + modify code |
   | Documentation | User guide unclear, missing, or incorrect | Update `user-guide/` and `docs/` |

4. **Trace to existing specs**: For each item, find related PRD feature/user story/screen spec, BRD requirement, and code files. If implementing would change a key BRD constraint, escalate as `STAKEHOLDER_DECISION_REQUIRED`.

5. Create `./feedback/analysis.md` with triage table, impact assessment, and effort estimates (XS/S/M/L/XL).

   If APPROVED items exceed 15, split into priority-ordered batches (15 items per batch). Process only the first batch.

### Conflict Detection and Resolution

Before creating the change plan:
1. Group feedback by affected feature (FEAT-NNN)
2. Check for opposing requests within each group
3. For conflicts: prioritize by frequency, then BRD alignment
4. Document resolution rationale
5. Unresolvable conflicts: mark as `STAKEHOLDER_DECISION_REQUIRED` and defer both items

**Spec file limit**: If a single item requires changes to >5 spec files, flag as 'complex' and recommend a dedicated session.

6. **Assign status markers**: `APPROVED`, `STAKEHOLDER_DECISION_REQUIRED`, or `DEFERRED`. Include in change plan.

7. Create `./feedback/change-plan.md` with ordered changes list. Each entry includes: status marker, spec changes, code changes, test changes, documentation changes.

8. Create task list for teammates.

### Phase 2: Spawn Improvement Teammates

Spawn 3 teammates SEQUENTIALLY (spec -> code -> test/docs). Each teammate skips items marked `STAKEHOLDER_DECISION_REQUIRED` or `DEFERRED`.

**Teammate 1 -- "spec-updater"**: Update BRD and PRD based on feedback. Add new requirements with next available IDs. Modify acceptance criteria. Add traceability markers (`Updated based on user feedback [TICKET-001]`). Update version tracking in cover/metadata files. Run consistency check after all updates.

**Teammate 2 -- "code-implementer"** (BLOCKED by Teammate 1): Implement code changes against updated specs. Fix bugs to match spec. Modify UI/backend for UX issues and enhancements. Implement missing features. Add traceability comments (`// FEEDBACK FIX: [feedback-id]`). The `FEEDBACK FIX` comment supplements (does not replace) the standard `@traces` header.

**Teammate 3 -- "test-and-docs-updater"** (BLOCKED by Teammate 2): Update existing tests to match new specs. Add new tests for each new feature/behavior. Update developer docs (`./docs/`). Update user guide (`./user-guide/`) if it exists -- journey pages, FAQ, troubleshooting, changelog. Validate docs.json navigation. Run full verification suite: typecheck, lint, test, test:e2e, build.

### Phase 3: Coordination During Execution

1. Monitor progress.
2. Enforce dependency ordering -- Teammate 2 starts only after Teammate 1 completes, Teammate 3 after Teammate 2.
3. If Teammate 2 finds spec insufficient: relay to Teammate 1 for clarification. Max 2 coordination rounds per item; escalate to DEFERRED if exceeded.

### Phase 4: Review and Close Loop

1. Run full test suite.
2. Update `plancasting/_progress.md` if it exists and features changed.
3. Generate `./feedback/resolution.md` with resolution table, summary statistics, and recommendations.
4. Archive processed feedback:
   ```bash
   mkdir -p ./feedback/archive
   cp ./feedback/input.md ./feedback/archive/$(date +%Y-%m-%d-%H%M%S)-input.md
   ```
5. Update `plancasting/tech-stack.md` if new dependencies were added.
6. Output summary.

## Gate Decision

- **PASS**: All APPROVED items resolved, tests pass, specs consistent, docs updated. Proceed to re-deployment (Stage 7) and re-verification (Stage 7V). Consider re-running Stage 6V if UI changes were made.
- **CONDITIONAL PASS**: Some items deferred due to complexity but all attempted items resolved. Document deferred items. Schedule follow-up Stage 8 session.
- **FAIL**: Test suite fails, spec inconsistency detected, or APPROVED items left unresolved. Do NOT proceed to Stage 7 until PASS or CONDITIONAL PASS.

## Known Failure Patterns

1. **Conflicting feedback**: User A wants removal, User B wants expansion. Resolve by frequency, escalate to stakeholder, or document trade-off.
2. **Feature requests contradicting BRD**: ALWAYS check BRD business rules before accepting.
3. **Spec drift**: Cumulative changes make BRD/PRD inconsistent. Verify consistency after every change.
4. **Cross-cutting feedback**: "The app is slow" affects multiple features. Triage into specific, actionable items per feature.
5. **Architectural changes needed**: Defer to a separate Stage 5 re-run rather than patching.
6. **i18n key breakage**: ALWAYS update message files when changing user-facing text.

## Running This Prompt Repeatedly

Designed for regular cadence (weekly, biweekly, monthly). Each run processes a new batch, updates living docs, implements changes, archives feedback. Over time, `./feedback/archive/` builds a complete audit trail.

## Cross-Stage References

- Dependency updates: defer to **Stage 9** (Dependency Maintenance).
- UI changes: re-run **Stage 6V** (Visual & Functional Verification).
- After deploying: run **Stage 7V** (Production Smoke Verification).
- User guide auto-deploys via GitHub on push if Mintlify GitHub App is configured.
- If user guide is fundamentally outdated, consider re-running **Stage 7D** instead of patching.

## Critical Rules

1. NEVER implement feedback contradicting a BRD business rule without spec-updater resolution first.
2. NEVER modify a spec without updating all cross-references.
3. ALWAYS defer architectural changes to a separate Stage 5 re-run.
4. ALWAYS run the full test suite after code changes.
5. ALWAYS update i18n message files when changing user-facing text.
6. For batches >15 items, split into multiple runs (max 15 APPROVED items per run).
7. After UI changes, recommend re-running Stage 6V.
8. After deploying, run Stage 7V.
9. NEVER skip the traceability chain -- every code change must trace to a spec.
10. Resolve conflicting feedback BEFORE implementing either side.
11. If deployment causes production failures, revert with `git revert` (not `git reset --hard`), re-run 7V, investigate before re-attempting.
