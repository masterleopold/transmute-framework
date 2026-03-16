# Audit Detailed Guide — Stage 5B Teammate Instructions, Scan Scripts & Fix Patterns

This reference contains the full automated stub scan scripts, teammate fix instructions, classification rules, and coordination protocol for Stage 5B: Implementation Completeness Audit.

## Input Files

- **Codebase**: Complete project directory (post-Stage 5)
- **PRD**: `./plancasting/prd/` (source of truth for what should exist)
- **BRD**: `./plancasting/brd/` (business rules that should be enforced)
- **Tech Stack**: `./plancasting/tech-stack.md`
- **Project Rules**: `./CLAUDE.md`
- **Progress Tracker**: `./plancasting/_progress.md`
- **Feature Briefs**: `./plancasting/_briefs/`
- **Code Generation Context**: `./plancasting/_codegen-context.md`
- **Scaffold Manifest**: `./plancasting/_scaffold-manifest.md` (may not exist in older projects)
- **Implementation Report**: `./plancasting/_implementation-report.md` (optional — if missing, e.g. Stage 5 session was interrupted, the audit proceeds by scanning the codebase directly instead of cross-referencing the report). If it exists, compare its claims against your scan results in Phase 1 and note any discrepancies in the audit report (e.g., report claims 100% coverage but scan found stubs).

**Language**: Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports and user-facing output in the specified language. Code, technical identifiers, and file names remain in English.

---

## Phase 1: Automated Stub Scan Scripts

Replace ALL placeholder paths before running. Set variables based on `plancasting/tech-stack.md`:
- `BACKEND_DIR` — e.g., `convex/`
- `FRONTEND_DIR` — e.g., `src/`
- `COMPONENTS_DIR` — e.g., `src/components/features/`
- `PAGES_DIR` — e.g., `src/app/`
- `HOOKS_DIR` — e.g., `src/hooks/`
- `PAGE_FILE` — e.g., `page.tsx` (Next.js App Router), `+page.svelte` (SvelteKit), `route.tsx` (Remix)

### Guard: Verify Placeholders Were Replaced

```bash
set -e
BACKEND_DIR="[backend-dir]"
FRONTEND_DIR="[frontend-dir]"
COMPONENTS_DIR="[components-dir]"
PAGES_DIR="[pages-dir]"
HOOKS_DIR="[hooks-dir]"
PAGE_FILE="page.tsx"
for placeholder in "$BACKEND_DIR" "$FRONTEND_DIR" "$COMPONENTS_DIR" "$PAGES_DIR" "$HOOKS_DIR"; do
  if echo "$placeholder" | grep -q '^\['; then
    echo "ERROR: $placeholder was not replaced. See Stack Adaptation section." && exit 1
  fi
done
# Verify directories actually exist
for dir in "$BACKEND_DIR" "$FRONTEND_DIR" "$COMPONENTS_DIR" "$PAGES_DIR" "$HOOKS_DIR"; do
  if [ ! -d "$dir" ]; then
    echo "WARNING: Directory $dir does not exist. Check your Stack Adaptation values."
  fi
done
```

### 1. Text-Pattern Stub Detection

```bash
# Note: Adjust --include filters to match your framework's file types (e.g., .svelte, .vue, .jsx)
# Note: Exclude HTML attribute matches (e.g., placeholder="Enter email") — focus on
# standalone text like 'This is a placeholder' or 'PLACEHOLDER CONTENT'.
# WARNING: [backend-dir] is a placeholder. You MUST replace it with your actual backend
# directory path (e.g., convex/). Running this command with the literal placeholder will
# silently skip backend scanning.
grep -rn "implementation pending\|pending feature build\|⚠️ STUB\|TODO \[Stage 5\]\|Coming soon\|Not yet implemented\|PLACEHOLDER" "$FRONTEND_DIR" "$BACKEND_DIR" --include="*.tsx" --include="*.ts" --include="*.jsx" --include="*.js" | grep -v 'placeholder="\|Placeholder='
```

### 2. Minimal Component Detection (< 20 lines)

```bash
# Prefer file line count over regex — regex will match legitimate components
# Adapt file extensions to your framework: .tsx (React), .vue (Vue), .svelte (Svelte), .jsx (JSX)
for file in $(find "$COMPONENTS_DIR" \( -name "*.tsx" -o -name "*.vue" -o -name "*.svelte" -o -name "*.jsx" \) -not -name "*.test.*" -not -name "index.ts"); do
  lines=$(wc -l < "$file")
  if [ "$lines" -lt 20 ]; then
    echo "THIN COMPONENT: $file ($lines lines)"
  fi
done
```

### 3. Orphan Component Detection

```bash
for file in $(find "$COMPONENTS_DIR" \( -name "*.tsx" -o -name "*.vue" -o -name "*.svelte" -o -name "*.jsx" \) -not -name "*.test.*" -not -name "index.ts"); do
  component_name=$(basename "$file" | sed 's/\.[^.]*$//')
  import_count=$(grep -rn "from.*${component_name}\|import.*${component_name}" "$FRONTEND_DIR" --include="*.tsx" --include="*.ts" --include="*.vue" --include="*.svelte" --include="*.jsx" -l | grep -v "$file" | grep -v ".test." | wc -l)
  if [ "$import_count" -eq 0 ]; then
    echo "ORPHAN: $file (imported by 0 files)"
  fi
done
```

Note: This scan may produce false positives for components consumed through barrel re-exports (index.ts). Before marking as ORPHAN, verify it is not re-exported via an index.ts barrel file.

### 4. Dead onClick / href="#" Detection

```bash
grep -rn 'href="#"\|onClick={() => {}}\|onClick={() => null)\|onSubmit={(e) => { e.preventDefault' "$FRONTEND_DIR" --include="*.tsx"
```

### 5. Mock Data in Production Components

```bash
grep -rn "mockData\|Mock.*=\|MOCK_\|sampleData\|dummyData\|fakeData" "$FRONTEND_DIR" --include="*.tsx" --include="*.ts" | grep -v "__tests__\|.test.\|.spec.\|stories\|seed"
```

### 6. Unconnected Hooks

```bash
grep -rn "useState(\[\])\|useState(\"\")\|useState(0)\|useState(false)\|useState(null)" "$COMPONENTS_DIR" --include="*.tsx"
```

Note: `useState([])`, `useState(false)` are legitimate for local UI state (accordion open/closed, filter selections). Focus on components where useState initializes data that SHOULD come from a backend query. Cross-reference with the component's screen spec.

### 7. Missing Loading/Error States

Requires manual inspection — flag files that use useQuery but don't check isLoading.

### 8. Empty or Near-Empty Page Files

```bash
for file in $(find "$PAGES_DIR" -name "$PAGE_FILE"); do
  lines=$(wc -l < "$file")
  if [ "$lines" -lt 20 ]; then
    echo "THIN PAGE (likely stub): $file ($lines lines — investigate: pages <20 lines with 3+ hook imports but empty renders are stubs)"
  fi
done
```

### 9. Duplication Pattern: Bloated Pages with Zero Component Imports

```bash
for file in $(find "$PAGES_DIR" -name "$PAGE_FILE"); do
  hook_imports=$(grep -c "from.*hooks/" "$file" 2>/dev/null || echo 0)
  component_imports=$(grep -c "from.*$COMPONENTS_DIR" "$file" 2>/dev/null || echo 0)
  lines=$(wc -l < "$file")
  if [ "$hook_imports" -gt 2 ] && [ "$component_imports" -eq 0 ] && [ "$lines" -gt 50 ]; then
    echo "DUPLICATION SUSPECT: $file ($lines lines, $hook_imports hook imports, 0 component imports)"
  fi
done
```

### 10. Scaffold Manifest Cross-Reference

```bash
if [ -f "./plancasting/_scaffold-manifest.md" ]; then
  echo "--- Scaffold Manifest Cross-Reference ---"
  grep "$COMPONENTS_DIR" ./plancasting/_scaffold-manifest.md | while read -r line; do
    component_path=$(echo "$line" | grep -o "$COMPONENTS_DIR[^ |]*")
    if [ -n "$component_path" ] && [ -f "$component_path" ]; then
      component_name=$(basename "$component_path" .tsx)
      import_count=$(grep -rn "from.*${component_name}\|import.*${component_name}" "$FRONTEND_DIR" --include="*.tsx" --include="*.ts" -l | grep -v "$component_path" | grep -v ".test." | wc -l)
      if [ "$import_count" -eq 0 ]; then
        echo "MANIFEST ORPHAN: $component_path (listed in manifest but imported by 0 files)"
      fi
    fi
  done
fi
```

---

## Issue Classification Rules

### Category A — Quick Fix (< 30 non-blank non-comment lines per file — count only executable code lines, excluding imports, comments, and whitespace)
- Stub text replacement (placeholder -> real content)
- Missing onClick/onSubmit handlers (wire to existing hooks)
- Missing loading/error/empty states (add using existing patterns)
- Simple orphan cleanup (delete redundant component, or add one import)
- Missing i18n keys
- Dead href="#" links (replace with real routes)
- Missing responsive classes

### Category B — Medium Fix (30-100 lines per file AND <150 lines total across all affected files — same counting method as Category A, est. 15–45 min per file)
- Components needing real UI (replace scaffold body with functional component)
- Hooks needing real data connections (replace useState mock with useQuery)
- Forms needing real submission logic
- Modals/dialogs needing real content and behavior
- Pages needing to compose real components instead of inline placeholders
- **Duplication fixes**: Page has inline UI + orphan component -> move inline code into component, refactor page to import
- **Bloated page decomposition**: Page with 200+ lines -> extract into scaffold components

### Category C — Large Gap (escalate; 1-3 = CONDITIONAL PASS, 4-5 = FAIL-RETRY, 6+ = FAIL-ESCALATE)

This threshold is a HARD gate. Do NOT classify 4 Category C issues as CONDITIONAL PASS. If a 4th Category C issue is found mid-audit, the gate automatically becomes FAIL.

Escalate if ANY of these are true:
1. Requires creating entirely new hooks or backend functions that the scaffold should have created but that don't exist. A hook/function "should have" been created if it maps to an API endpoint in `./plancasting/prd/12-api-specifications.md` or a component in `./plancasting/prd/08-screen-specifications.md` that needs to fetch/submit data. Check `plancasting/_scaffold-manifest.md` or `plancasting/_codegen-context.md` as the source of truth for what was scaffolded (PRD defines what should exist; the manifest defines what was created).
2. A single file needs more than 100 lines of net-new code to complete a feature.
3. Entire features where frontend is completely unbuilt — scaffold files exist but implementation is entirely missing. This indicates a Stage 5 session was interrupted or incompletely run. Escalate to the lead immediately.
4. Features where both backend AND frontend are stubs — scaffold files exist but contain only placeholder logic (backend functions log "not implemented" and return empty data, AND frontend components render only placeholder divs with no real data bindings).
- Features requiring significant new component architecture
- Mark these in `plancasting/_progress.md` as Needs Re-implementation with detailed notes

**Note**: Category A/B/C in Stage 5B classify by CODE SIZE (lines per file). This differs from Stage 6V/6R, which classify by FIXABILITY (auto-fixable vs manual). Do not confuse the two systems — see execution-guide.md § "Gate Decision Outcomes" → "Category Systems" for the 6V/6R system.

**Category C example**: `useUserProfile` hook is listed in `_codegen-context.md` but was never created. Creating it requires a new backend query, frontend hook, and 150+ lines of component code to consume it. This is NOT a stub fix — it's a missing feature requiring Stage 5 re-implementation.

### Multi-File Classification Rule
Category A — all files need <30 lines each. Category B — largest file needs <100 lines AND total across all files <150 lines. Category C — largest file needs >=100 lines OR total >=150 lines across all affected files. If ambiguous, default to the higher category. Multiple independent issues in same feature classified separately.

### Scope Boundaries — What 5B Does NOT Audit
- Design quality (that's 6P/6P-R)
- Security (6A)
- Performance (6C)
- 5B focuses strictly on implementation completeness

---

## Teammate 1: "frontend-stub-fixer" (PRIMARY)

**Scope**: Fix all Category A and Category B frontend issues

Read CLAUDE.md first (especially Frontend Rules and Design & Visual Identity sections).
Check `./plancasting/tech-stack.md` for the `Session Language` setting. Code remains in English; report messages and user-facing strings follow the session language.
Also read `./plancasting/tech-stack.md` for the design direction and UI component library. Read the audit report at `./plancasting/_audits/implementation-completeness/report.md`.

**MANDATE**: Replace every stub with a FUNCTIONAL implementation. You are NOT writing new features — the backend is already complete. You are connecting frontend components to the existing backend.

**CRITICAL BOUNDARY**: If a component needs a backend function/hook that doesn't exist, DO NOT create it. Report it as a Category C issue to the lead. Missing backend functions indicate Stage 3 or Stage 5 incompleteness.

### Fix Patterns

**Stub Components (scaffold body -> real UI)**:
1. Read feature brief at `./plancasting/_briefs/<feature-id>.md` for what this component should do. If no brief exists, read `./plancasting/prd/02-feature-map-and-prioritization.md` and `./plancasting/prd/04-epics-and-user-stories.md` to understand what this feature should do.
2. Read screen specification in `./plancasting/prd/08-screen-specifications.md`
3. Read existing hook in `src/hooks/`
4. Implement FULL component: import/use correct hook, render all states (loading skeleton, error boundary, empty guidance + CTA, full data UI), add all interactive elements, wire to hook mutations/actions, add ARIA + keyboard nav, use design tokens, implement responsive behavior

**Unconnected Hooks (useState -> useQuery)**:
1. Find correct custom hook in `src/hooks/`
2. Replace useState/mock with hook's return value
3. Add loading/error state handling
4. If the hook doesn't exist, check if it's listed in `_codegen-context.md` or `_scaffold-manifest.md`. If listed (should have been scaffolded), escalate as Category C. If not listed (genuinely new need discovered during implementation), create if <100 lines; otherwise escalate as Category C.

**Dead Handlers (noop -> real)**:
1. Find mutation/action in `src/hooks/` and backend dir
2. Wire handler to correct mutation with correct arguments
3. Add optimistic updates if supported
4. Add error handling (toast or inline error)

**Missing States**:
1. Loading: Skeleton components matching component layout
2. Error: ErrorDisplay component with retry action
3. Empty: EmptyState component with icon, message, CTA
4. Follow patterns from already-completed features

**Orphan Components**:
- SHOULD be rendered: find correct page and import it
- Page already implements UI inline: DELETE the orphan file. (Verify no other files import the orphan before deleting. If other files do import it, resolve those imports first.)
- Duplicates another: DELETE and update imports

**Duplication Pattern (inline page UI + orphan component)**:
This is NOT the same as a stub. The component file has a real (or scaffold) body AND the page has inline UI for the same purpose. Fix strategy:
1. Read both the page file and the orphan component file
2. Determine which has the BETTER implementation (usually the page's inline version, since Stage 5 wrote it)
3. Move the better implementation INTO the scaffold component file (preserving the component's file location and exports)
4. Refactor the page to import and render the component instead of inline UI
5. Delete the inline UI from the page. The page should compose components, not contain business logic.
6. Verify the component is imported and rendered correctly
This preserves the architectural intent (pages compose components) while keeping the working code.

**Bloated Pages (monolithic -> composed)**:
1. Identify logical sections (each with own hooks/state)
2. Check scaffold component files exist (`plancasting/_scaffold-manifest.md`)
3. Move each section into corresponding scaffold component
4. Page imports and composes components, passing only needed props

**Missing i18n Keys**:
- Add all missing translation keys to the project's i18n message file (check CLAUDE.md or `plancasting/tech-stack.md` for the actual path — common locations: `src/messages/en.json`, `src/locales/en.ts`, `public/locales/en/common.json`).
- Follow the existing key naming convention.

### Verification (Non-Negotiable)

After ALL fixes, if any test fails, diagnose each failure: (a) if caused by a fix you just applied (new behavior replacing a stub), update the test to match the new behavior; (b) if a genuine regression (a fix broke unrelated code), escalate to the lead immediately with details. Do NOT skip or delete failing tests.

Set `FRONTEND_DIR` to your frontend root (e.g., `FRONTEND_DIR=src/`) and `BACKEND_DIR` to your actual backend directory path (e.g., `BACKEND_DIR=convex/`) before running these commands.

1. Run the full stub scan again — MUST return zero results
2. Run typecheck (e.g., `bun run typecheck`) — zero errors (adapt to your package manager per CLAUDE.md)
3. Run lint (e.g., `bun run lint`) — zero errors (adapt to your package manager per CLAUDE.md)
4. Run frontend tests (e.g., `bun run test -- src/`) — all pass (adapt to your package manager per CLAUDE.md)
5. Verify no orphan components remain (re-run the orphan scan)

Report to lead: components fixed (Category A + B), orphans deleted, i18n keys added, files modified (full list), any Category C discoveries (components that need more than 100 lines), verification results (stub scan, typecheck, lint, tests).

---

## Teammate 2: "backend-stub-fixer"

**Scope**: Fix all backend stubs and integration gaps

Read CLAUDE.md first (especially Backend Rules).
Check `./plancasting/tech-stack.md` for the `Session Language` setting. Code remains in English; report messages follow the session language.
Read the audit report at `./plancasting/_audits/implementation-completeness/report.md` — focus on the backend and integration sections.

**MANDATE**: Every backend function must have REAL business logic, not placeholder returns.

### Fix Patterns

**Action Stubs (log -> real API call)**:
1. Read feature brief
2. Read BRD business rules for validation
3. Implement actual external API call with error handling
4. Add retry logic for transient failures

**Missing Validation**:
1. Read `plancasting/brd/14-business-rules-and-logic.md`
2. Add proper error throws with your backend error type (e.g., `ConvexError` for Convex) and error codes from your error codes module.
3. Add argument validation with your backend's validators (e.g., `v` validators for Convex).

**Integration Gaps**:
1. Verify cross-feature data flows
2. Fix queries aggregating from multiple features but only querying one
3. Fix mutations that should trigger side effects in other features

### Verification
1. Run backend dev server (or equivalent backend validation command per tech-stack.md; e.g., `bunx convex dev`, `bun run dev:backend`, `npx prisma validate`, etc.) — verify all functions deploy
2. Run backend tests (e.g., `bun run test -- [your backend test directory]`) — all pass
3. Verify all function exports match what frontend hooks expect

---

## Teammate 3: "e2e-verification" (ALWAYS Run Last)

**Scope**: Run full E2E suite to verify fixes don't break anything

Read CLAUDE.md first (especially the Commands and Testing sections).
Check `./plancasting/tech-stack.md` for the `Session Language` setting. Report messages follow the session language.

Note: E2E tests require a running dev server. Check CLAUDE.md for the dev server port. First check if one is already running (`lsof -ti:<port>`). If not, start it: `bun run dev &` (or equivalent per CLAUDE.md). Wait for the server to be ready: `bunx wait-on http://localhost:<port> --timeout 60000` (or poll with `until curl -s http://localhost:<port> > /dev/null 2>&1; do sleep 1; done`). Stop the dev server after verification: `lsof -ti:<port> | xargs kill 2>/dev/null`.

### Tasks

1. **Full test suite**:
   - typecheck
   - lint
   - test (all unit + integration)
   - test:e2e (all E2E)

2. **Test failure diagnosis**:
   - **Test was mocking old behavior** that no longer exists (e.g., test checks for "Loading..." but component now shows "Processing...") -> UPDATE the mock/assertion to match new behavior
   - **Component interface changed** (props renamed, return type changed) -> UPDATE the test assertions to match the new interface
   - **A feature that was working before is now broken** (e.g., a query hook returns null when it should return data) -> REPORT to the lead immediately as a genuine regression
   To distinguish: read the test failure message and the code change side-by-side. Interface changes (cases 1-2) show assertion mismatches; regressions (case 3) show functional failures.

3. **Final stub scan** (set `FRONTEND_DIR` to your frontend root and `BACKEND_DIR` to your actual backend directory path before running): Must return zero results EXCEPT for features explicitly marked as "Future Scope" in `./plancasting/prd/03-release-plan.md`. Any stub pattern in features listed in `./plancasting/prd/02-feature-map-and-prioritization.md` (the current build scope) is a bug.

4. **Orphan component scan**: Report any remaining orphans.

5. **Spot-check** ALL pages with Category B fixes + additional random pages (coverage by feature count: <10 features = all pages; 10-30 = 50% every 2nd page alphabetically; >30 = 30% every 3rd page alphabetically, plus all Category B pages):
   a. Open page source
   b. Verify component imports from `[components-dir]`
   c. Verify no raw `useState()` for server-derived data
   d. Verify page JSX renders imported components
   e. Verify sibling `loading.tsx` and `error.tsx` exist
   f. Run app, navigate, verify no blank screens or console errors
   g. Verify responsive behavior at 3 breakpoints (375px mobile, 768px tablet, 1440px desktop). If a dev server is running and Playwright is available, use viewport sizing for verification. Otherwise, verify responsive CSS classes/media queries exist in the source code (check for `sm:`, `md:`, `lg:` breakpoint prefixes or equivalent `@media` queries). Flag components that break layout or overflow at mobile width as Category A (add responsive CSS) or Category B (needs layout refactor).

Report in exact format:
- TypeScript: pass/fail (error count)
- Lint: pass/fail (error count)
- Unit Tests: pass/fail (pass/fail counts)
- E2E Tests: pass/fail (pass/fail counts)
- Stub scan: pass/fail (remaining count)
- Orphan scan: pass/fail (orphan count)
- Spot-check results
- Any remaining issues

---

## Phase 3: Coordination

**Mandatory file conflict prevention**: Before spawning, assign mutually exclusive file sets to Teammates 1 and 2. If shared files exist (type definitions, shared utilities, barrel exports), assign them to Teammate 1 (frontend) exclusively — Teammate 2 (backend) MUST NOT modify frontend-owned files. If Teammate 2 discovers a type mismatch in a shared file, report it to the lead for manual fix after Teammate 1 completes. For files in the backend directory, Teammate 2 has exclusive ownership. For shared files, Teammate 2 should read the latest version after Teammate 1 completes.

1. After each teammate completes, review their completion message for Category C escalations — if found, document them in `plancasting/_progress.md`.
2. If the FAIL-ESCALATE gate is triggered (6+ Category C issues, OR 6+ total unfixed issues, OR 3 consecutive FAIL-RETRY outcomes), add a note to the audit report recommending a FULL Stage 5 re-run for affected features rather than targeted fixes — this volume of Category C issues indicates systemic frontend failure, not just isolated gaps. For FAIL-RETRY (4–5 Category C), recommend re-running 5B with targeted fixes.
3. Resolve any conflicts between backend and frontend fixes. If teammates 1 and 2 modify the same file, the lead must review both change sets and merge. If a teammate is stuck on a fix exceeding Category B scope (needs >100 lines of new code), reclassify as Category C and move on.

---

## Phase 4: Audit Report Format

Ensure output directory exists: `mkdir -p ./plancasting/_audits/implementation-completeness/`

Save to `./plancasting/_audits/implementation-completeness/report.md`:

```markdown
# Implementation Completeness Audit Report — Stage 5B

## Summary
- **Audit Date**: [date]
- **Run Number**: [1 | 2 | 3 | 4+]
- **Total Issues Found**: [N]
  - Category A (Quick Fix): [n] → [n] fixed
  - Category B (Medium Fix): [n] → [n] fixed
  - Category C (Needs Re-implementation): [n] → escalated to plancasting/_progress.md
- **Frontend Issues**: [n] (expected to be the majority)
- **Backend Issues**: [n]
- **Integration Issues**: [n]

## Fix Summary
- Components fixed: [n]
- Orphan files deleted: [n]
- i18n keys added: [n]
- Backend functions fixed: [n]
- Files modified: [total]

## Verification Results
- TypeScript: ✅ / ❌ (0 errors)
- Lint: ✅ / ❌ (0 errors)
- Unit Tests: ✅ / ❌ ([n] pass, [n] fail)
- E2E Tests: ✅ / ❌ ([n] pass, [n] fail)
- Stub Scan: ✅ / ❌ (0 remaining stubs)
- Orphan Scan: ✅ / ❌ (0 orphan components)

## Gate Decision
- **PASS**: All Category A/B fixed, zero Category C issues, all tests pass, zero stubs remain → proceed to Stage 6
- **CONDITIONAL PASS**: All Category A/B fixes attempted; 0–2 A/B issues remain unfixed (each documented with explanation why the fix failed), OR all A/B fixed AND 1–3 Category C issues documented with clear descriptions and workarounds. If BOTH unfixed A/B AND Category C issues exist, apply CONDITIONAL PASS only if total unfixed (A/B + C) ≤ 3; otherwise apply FAIL-RETRY → proceed to Stage 6 with known gaps noted
- **FAIL-RETRY** (re-run 5B): ANY of: (a) 3+ Category A/B issues remain unfixed, (b) test failures from 5B fixes, (c) 4–5 Category C issues. Before re-running, diagnose WHY the fix failed — re-running without diagnosis will loop. Maximum 3 re-runs of 5B (Run Number 4 = final attempt). If A/B issues persist after Run 3, escalate all remaining A/B issues to Category C. If Run 4+, skip Phase 2 and escalate all remaining A/B issues to Category C in Phase 4.
- **FAIL-ESCALATE** (re-run Stage 5): 6+ Category C issues, OR 6+ total unfixed issues across all categories combined, OR 3 consecutive FAIL-RETRY outcomes (indicates systemic implementation failure)
- **FAIL recovery actions**: Specific steps by failure type:
  - **Unfixed A/B issues**: Diagnose the root cause, then re-run Stage 5B with targeted fixes for the specific files
  - **4–5 Category C issues**: Operator should manually address or set affected features to `🔄 Needs Re-implementation` in `_progress.md`, then re-run 5B to re-scan. 5B cannot fix Category C issues itself — the re-run verifies operator fixes reduced the count. If Category C count still exceeds 3 after operator intervention, escalate to FAIL-ESCALATE
  - **6+ Category C issues**: Set affected features to `🔄 Needs Re-implementation` in `_progress.md`, re-run Stage 5 for those features, then re-run Stage 5B
  - **Test failures**: Diagnose regression source — if caused by 5B fixes, fix the tests; if pre-existing, escalate to Stage 5 re-run

## Category C Escalations (if any)
[List features needing Stage 5 re-run with specific gaps]

## Issues by Feature
[Detailed breakdown per feature]
```

---

## Early Exit Decision Table

**Note**: This table applies when determining whether to spawn Phase 2 teammates. It covers the early-exit cases where no teammate spawning is needed. If Category A/B issues ARE found (count >= 1), proceed to Phase 2 teammate spawning regardless of this table.

| Category A/B count | Category C count | Gate Decision | Lead Action |
|---|---|---|---|
| 0 | 0 | **PASS** | Skip Phase 2/3. Generate report. Proceed to Stage 6. |
| 0 | 1–3 | **CONDITIONAL PASS** | Skip Phase 2/3. Generate report with Category C list. Document in `_progress.md`. Proceed to Stage 6. |
| 0 | 4–5 | **FAIL-RETRY** | Skip Phase 2/3. Generate report with Category C list. Document in `_progress.md`. Re-run 5B (max 3 runs before escalation). |
| 0 | 6+ (or total unfixed >= 6) | **FAIL-ESCALATE** | Skip Phase 2/3. Generate report with Category C list. Document in `_progress.md`. STOP — instruct operator to re-run Stage 5 for affected features. |
| 1+ | any | *(determined after fixes)* | Spawn Phase 2 teammates to fix A/B. Document Category C in `_progress.md`. After Phase 3, proceed to Phase 4 for gate decision. |
| any (Run 4+) | any | **FAIL-ESCALATE** | Run 4+ reached. Skip Phase 2 auto-fixes. Reclassify all remaining A/B issues as Category C. Proceed to Phase 4 to generate report with FAIL-ESCALATE gate. Set `🔄` in `_progress.md` for affected features. |

**Per-feature escalation rule**: If a single feature (same FEAT-ID) reports FAIL-RETRY three consecutive times across 5B re-runs (fail → operator sets `🔄` → Stage 5 re-runs feature → 5B fails again, repeated 3×), that feature automatically escalates to FAIL-ESCALATE regardless of overall category counts. Track per-feature run counts in the audit report's feature table. This prevents infinite retry loops on features that consistently fail due to deeper architectural issues.

**Note**: This table determines whether Phase 2 teammate spawning is necessary. Phase 4 (report generation) and Phase 5 (rule extraction) ALWAYS run regardless of early exit — the report is required by downstream stages (6A–6G, 6H), and rule extraction captures any patterns found during the Phase 1 scan even if no fixes were needed. Save the report to `./plancasting/_audits/implementation-completeness/report.md` with the gate decision and Category C details.

---

## Phase 5: Rule Extraction (Post-Gate)

After gate decision, extract implementation lessons as path-scoped rules:

1. **Scan audit findings for repeatable patterns**:
   - Review all Category A/B issues that were fixed. Group by root cause pattern (e.g., "missing soft-delete filter in 4 queries", "useState instead of useQuery in 3 components").
   - Review Category C issues for tech-stack limitations (e.g., "Convex does not support server-side redirects").
   - Only extract patterns that are tech-stack-specific and generalizable — not one-off bugs.

2. **Generate rule candidates**:
   ```markdown
   ### [Pattern Title]
   - **Source Stage**: 5B
   - **Evidence**: [Category/finding IDs]
   - **Trigger**: [File paths/patterns]
   - **Rule Text**: [Concise directive — max 3 sentences]
   - **Target File**: [.claude/rules/*.md]
   - **Confidence**: HIGH / MEDIUM / LOW
   - **Affected Features**: [FEAT-IDs]
   ```

3. **Classify confidence and route**:
   - **HIGH** (2+ features affected with clear pattern): Append the rule directly to the appropriate `.claude/rules/*.md` file. Include the evidence comment.
   - **MEDIUM** (single feature but generalizable): Append the candidate to `plancasting/_rules-candidates.md`.
   - **LOW** (edge case or uncertain): Append the candidate to `plancasting/_rules-candidates.md`.

4. **Update ONLY CLAUDE.md Part 2** Path-Scoped Rules table with updated rule counts if any HIGH confidence rules were added. Do NOT modify Part 1.

5. Stage updated `.claude/rules/` files and `plancasting/_rules-candidates.md` in the audit commit.

---

## Session Recovery

1. Check if `./plancasting/_audits/implementation-completeness/report.md` already exists (from a previous partial run).
2. If it exists, check its contents:
   - (a) If it contains a 'Fix Summary' section AND a 'Verification Results' section with test results → Phase 2+3 completed — skip to Phase 4 to regenerate the gate decision.
   - (b) If it contains a 'Fix Summary' but no 'Verification Results' → some fix teammates completed but verification did not. Check the Fix Summary: if the 'Components fixed:' line exists in the report (regardless of count), Teammate 1 completed. If 'Backend functions fixed:' line exists, Teammate 2 completed. If a line is MISSING entirely, that teammate did not complete. Re-spawn any incomplete fix teammate(s). After all re-spawned fix teammates complete, spawn Teammate 3 (verification).
   - (c) If it contains an 'Issues Found' section but no 'Fix Summary' → Phase 1 scan completed but Phase 2 did not start. Skip to Phase 2 using the existing scan results.
   - (d) If no 'Issues Found' section exists → Phase 1 scan did not complete. Re-run Phase 1 from step 1.
3. If the report file does not exist at all, restart from Phase 1 step 1.
4. Check `plancasting/_progress.md` for any features already marked as 🔄 — these were identified in a previous partial run.
5. Determine the Run Number: If the existing report contains a 'Run Number' field, increment it by 1 for this run. If no report exists, this is Run 1. Run 1 = initial audit. Run 2 = first re-run after fixes. Run 3 = second re-run. If Run Number reaches 4 (third re-run), skip Phase 2 auto-fixes — escalate all remaining A/B issues to Category C and document: 'Escalation — Run 4+: Repeated fix attempts indicate systemic issue. Recommend full Stage 5 re-run for affected features.' Common causes for reaching Run 4: (a) backend dependencies still missing (escalate to Stage 5 re-run), (b) teammate repeatedly making identical mistakes (escalate to lead for direct intervention).

---

## Critical Rules

1. NEVER skip the automated stub scan. It is the objective foundation of this audit. The scan catches explicit text-pattern stubs (high confidence). THEN manually review components with fewer than 20 lines by cross-referencing the PRD screen specification: a thin component is a stub only if it implements fewer states/interactions than the spec requires. A legitimately simple read-only widget may be under 20 lines and NOT a stub. Also check components that import hooks but don't use their return values.
2. NEVER mark a stub as "acceptable" — stubs are ALWAYS bugs at this stage. The only acceptable "Coming soon" is for features explicitly marked as future scope in the PRD (not in the current feature map).
3. NEVER delete test files to make the suite pass. Fix the code, not the tests.
4. ALWAYS read the feature brief and PRD screen spec before fixing a component — understand what it SHOULD do before writing code.
5. ALWAYS follow CLAUDE.md conventions when writing fix code — this is not a shortcut stage.
6. ALWAYS run the full verification suite before declaring the audit complete.
7. Frontend fixes are the PRIMARY focus. Allocate 70% of effort to frontend-stub-fixer.
8. If a component fix requires backend changes that don't exist, this is a Category C issue — do NOT create backend stubs to unblock frontend.
9. The goal is NOT perfection — it is completeness. Every feature should be FUNCTIONAL. Polish happens in Stage 6.
10. This stage should fix, not redesign. Maintain the architectural decisions made in Stage 5.

**5B Quality Standard**: 5B fixes should bring components from 'scaffold' to 'working' — happy path complete, loading/error states present, no obvious bugs. This is NOT production polish (Stage 6P handles that). The bar is: 'does this work as described in the PRD?'
