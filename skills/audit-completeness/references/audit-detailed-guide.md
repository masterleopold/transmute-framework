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
- **Implementation Report**: `./plancasting/_implementation-report.md` (may not exist if Stage 5 was interrupted)

**Language**: Check `./plancasting/tech-stack.md` for `Session Language` setting. Generate all reports in the specified language. Code and file names remain in English.

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
grep -rn "implementation pending\|pending feature build\|⚠️ STUB\|TODO \[Stage 5\]\|Coming soon\|Not yet implemented\|PLACEHOLDER" "$FRONTEND_DIR" "$BACKEND_DIR" --include="*.tsx" --include="*.ts" --include="*.jsx" --include="*.js" | grep -v 'placeholder="\|Placeholder='
```

### 2. Minimal Component Detection (< 20 lines)

```bash
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

### Category A — Quick Fix (< 30 non-blank non-comment lines per file)
- Stub text replacement (placeholder -> real content)
- Missing onClick/onSubmit handlers (wire to existing hooks)
- Missing loading/error/empty states (add using existing patterns)
- Simple orphan cleanup (delete redundant component, or add one import)
- Missing i18n keys
- Dead href="#" links (replace with real routes)
- Missing responsive classes

### Category B — Medium Fix (30-100 lines per file AND <150 lines total across all affected files)
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
1. Requires creating entirely new hooks or backend functions that the scaffold should have created (check `plancasting/_scaffold-manifest.md` or `plancasting/_codegen-context.md` as source of truth)
2. A single file needs more than 100 lines of net-new code
3. Entire features where frontend is completely unbuilt (scaffold files exist but implementation entirely missing)
4. Features where both backend AND frontend are stubs
- Features requiring significant new component architecture
- Mark in `plancasting/_progress.md` as Needs Re-implementation with detailed notes

**Category C example**: `useUserProfile` hook is listed in `_codegen-context.md` but was never created. Creating it requires a new backend query, frontend hook, and 150+ lines of component code. This is NOT a stub fix — it's a missing feature requiring Stage 5 re-implementation.

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

Read CLAUDE.md first (especially Frontend Rules and Design & Visual Identity). Read `plancasting/tech-stack.md` for design direction and UI component library. Read the audit report at `./plancasting/_audits/implementation-completeness/report.md`.

**MANDATE**: Replace every stub with a FUNCTIONAL implementation. You are NOT writing new features — the backend is already complete. You are connecting frontend components to the existing backend.

**CRITICAL BOUNDARY**: If a component needs a backend function/hook that doesn't exist, DO NOT create it. Report it as a Category C issue to the lead. Missing backend functions indicate Stage 3 or Stage 5 incompleteness.

### Fix Patterns

**Stub Components (scaffold body -> real UI)**:
1. Read feature brief at `./plancasting/_briefs/<feature-id>.md`
2. Read screen specification in `./plancasting/prd/08-screen-specifications.md`
3. Read existing hook in `src/hooks/`
4. Implement FULL component: import/use correct hook, render all states (loading skeleton, error boundary, empty guidance + CTA, full data UI), add all interactive elements, wire to hook mutations/actions, add ARIA + keyboard nav, use design tokens, implement responsive behavior

**Unconnected Hooks (useState -> useQuery)**:
1. Find correct custom hook in `src/hooks/`
2. Replace useState/mock with hook's return value
3. Add loading/error state handling
4. If hook doesn't exist, check `_codegen-context.md` / `_scaffold-manifest.md`. If listed (should have been scaffolded), escalate as Category C. If not listed, create if <100 lines; otherwise escalate.

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
- Page already implements UI inline: DELETE the orphan (verify no other files import it first)
- Duplicates another: DELETE and update imports

**Duplication Pattern (inline page UI + orphan component)**:
1. Read both page file and orphan component file
2. Determine which has BETTER implementation (usually page's inline version)
3. Move better implementation INTO scaffold component file
4. Refactor page to import and render component
5. Delete inline UI from page
6. Verify component is imported and rendered correctly

**Bloated Pages (monolithic -> composed)**:
1. Identify logical sections (each with own hooks/state)
2. Check scaffold component files exist (`plancasting/_scaffold-manifest.md`)
3. Move each section into corresponding scaffold component
4. Page imports and composes components, passing only needed props

**Missing i18n Keys**:
- Add to the project's i18n message file (check CLAUDE.md or tech-stack.md for path). Follow existing convention.

### Verification (Non-Negotiable)

After ALL fixes:
1. Run full stub scan — MUST return zero results
2. Run typecheck — zero errors
3. Run lint — zero errors
4. Run frontend tests — all pass
5. Verify no orphan components remain

If any test fails: (a) caused by fix (new behavior) -> update test; (b) genuine regression -> escalate immediately.

Report to lead: components fixed, orphans deleted, i18n keys added, files modified, any Category C discoveries, verification results.

---

## Teammate 2: "backend-stub-fixer"

**Scope**: Fix all backend stubs and integration gaps

Read CLAUDE.md (Backend Rules). Read audit report — focus on backend and integration sections.

**MANDATE**: Every backend function must have REAL business logic, not placeholder returns.

### Fix Patterns

**Action Stubs (log -> real API call)**:
1. Read feature brief
2. Read BRD business rules for validation
3. Implement actual external API call with error handling
4. Add retry logic for transient failures

**Missing Validation**:
1. Read `plancasting/brd/14-business-rules-and-logic.md`
2. Add proper error throws with backend error type and codes
3. Add argument validation

**Integration Gaps**:
1. Verify cross-feature data flows
2. Fix queries aggregating from multiple features but only querying one
3. Fix mutations that should trigger side effects in other features

### Verification
1. Run backend dev server — verify all functions deploy
2. Run backend tests — all pass
3. Verify function exports match frontend hook expectations

---

## Teammate 3: "e2e-verification" (ALWAYS Run Last)

**Scope**: Run full E2E suite to verify fixes don't break anything

Read CLAUDE.md (Commands and Testing). Start dev server before running E2E tests. Wait for server ready. Stop after verification.

### Tasks

1. **Full test suite**:
   - typecheck
   - lint
   - test (all unit + integration)
   - test:e2e (all E2E)

2. **Test failure diagnosis**:
   - Test mocking old behavior -> UPDATE mock/assertion
   - Component interface changed -> UPDATE test assertions
   - Feature that was working is now broken -> REPORT as genuine regression

3. **Final stub scan**: Must return zero results EXCEPT features explicitly in PRD `03-release-plan.md` as "Future Scope".

4. **Orphan component scan**: Report any remaining orphans.

5. **Spot-check** ALL pages with Category B fixes + additional random pages (coverage by feature count: <10 features = all pages; 10-30 = 50% every 2nd page alphabetically; >30 = 30% every 3rd page alphabetically, plus all Category B pages):
   a. Open page source
   b. Verify component imports from `[components-dir]`
   c. Verify no raw `useState()` for server-derived data
   d. Verify page JSX renders imported components
   e. Verify sibling `loading.tsx` and `error.tsx` exist
   f. Run app, navigate, verify no blank screens or console errors
   g. Verify responsive behavior at 3 breakpoints (375px, 768px, 1440px)

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

**Mandatory file conflict prevention**: Before spawning, assign mutually exclusive file sets to Teammates 1 and 2. If shared files exist, assign them to Teammate 1 exclusively. Teammate 2 MUST NOT modify frontend-owned files.

1. Monitor for Category C escalations — document in `plancasting/_progress.md`
2. If FAIL-ESCALATE gate triggered (6+ Cat C, OR 6+ total unfixed, OR 3 consecutive FAIL-RETRY): note systemic frontend failure in audit report, recommend FULL Stage 5 re-run rather than targeted fixes
3. Resolve conflicts between backend and frontend fixes. If both modify same file, lead reviews and merges.
4. If teammate stuck on fix exceeding Category B scope (>100 lines), reclassify as Category C and move on.

---

## Phase 4: Audit Report Format

Save to `./plancasting/_audits/implementation-completeness/report.md`:

```markdown
# Implementation Completeness Audit Report — Stage 5B

## Summary
- **Audit Date**: [date]
- **Run Number**: [1 | 2 | 3 | 4+]
- **Total Issues Found**: [N]
  - Category A (Quick Fix): [n] -> [n] fixed
  - Category B (Medium Fix): [n] -> [n] fixed
  - Category C (Needs Re-implementation): [n] -> escalated to plancasting/_progress.md
- **Frontend Issues**: [n]
- **Backend Issues**: [n]
- **Integration Issues**: [n]

## Fix Summary
- Components fixed: [n]
- Orphan files deleted: [n]
- i18n keys added: [n]
- Backend functions fixed: [n]
- Files modified: [total]

## Verification Results
- TypeScript: pass/fail (0 errors)
- Lint: pass/fail (0 errors)
- Unit Tests: pass/fail ([n] pass, [n] fail)
- E2E Tests: pass/fail ([n] pass, [n] fail)
- Stub Scan: pass/fail (0 remaining stubs)
- Orphan Scan: pass/fail (0 orphan components)

## Gate Decision
- **PASS**: All A/B fixed, zero Cat C, all tests pass, zero stubs -> Stage 6
- **CONDITIONAL PASS**: All A/B fixes attempted; 0-2 A/B remain unfixed, OR all A/B fixed AND 1-3 Cat C documented -> Stage 6 with known gaps
- **FAIL-RETRY**: 3+ A/B unfixed, OR test failures from 5B fixes, OR 4-5 Cat C -> re-run 5B (max 3 runs; 3 consecutive FAIL-RETRY = auto-escalate)
- **FAIL-ESCALATE**: 6+ Cat C, OR 6+ total unfixed, OR 3 consecutive FAIL-RETRY -> re-run Stage 5 for affected features
- **FAIL recovery actions**:
  - Unfixed A/B: Diagnose root cause, re-run 5B with targeted fixes
  - 4-5 Cat C: Operator addresses or sets features to Needs Re-implementation, re-run 5B to re-scan
  - 6+ Cat C: Set features to Needs Re-implementation, re-run Stage 5, then re-run 5B
  - Test failures: Diagnose — if 5B fixes caused it, fix tests; if pre-existing, escalate

## Category C Escalations (if any)
[List features needing Stage 5 re-run with specific gaps]

## Issues by Feature
[Detailed breakdown per feature]
```

---

## Early Exit Decision Table

| Cat A/B count | Cat C count | Gate Decision | Lead Action |
|---|---|---|---|
| 0 | 0 | PASS | Skip Phase 2-3 -> generate report -> Stage 6 |
| 0 | 1-3 | CONDITIONAL PASS | Skip Phase 2-3, document Cat C -> Stage 6 |
| 0 | 4-5 | FAIL-RETRY | Skip Phase 2-3, document Cat C -> re-run 5B (max 3 runs) |
| 0 | 6+ (or total unfixed >=6) | FAIL-ESCALATE | Skip Phase 2-3, document Cat C -> re-run Stage 5 |
| 1+ | any | *(after fixes)* | Spawn teammates for A/B fixes, document Cat C |
| any (Run 4+) | any | FAIL-ESCALATE | Skip Phase 2 auto-fixes, reclassify all remaining A/B as Cat C |

When skipping Phase 2-3, the lead MUST still generate the audit report with gate decision and Category C details. Phase 4 (report) and Phase 5 (rule extraction) ALWAYS run regardless of early exit. Downstream stages check for this file's existence.

---

## Phase 5: Rule Extraction (Post-Gate)

After gate decision, extract implementation lessons as path-scoped rules:

1. **Scan audit findings for repeatable patterns**: Group by root cause (e.g., "missing soft-delete filter in 4 queries", "useState instead of useQuery in 3 components"). Only extract tech-stack-specific, generalizable patterns.

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

3. **Route by confidence**:
   - **HIGH** (2+ features with clear pattern): Append to `.claude/rules/*.md` with evidence comment
   - **MEDIUM** (single feature but generalizable): Append to `plancasting/_rules-candidates.md`
   - **LOW** (edge case): Append to `plancasting/_rules-candidates.md`

4. Update CLAUDE.md Part 2 Path-Scoped Rules table if HIGH rules added. Do NOT modify Part 1.

5. Stage updated `.claude/rules/` files and `plancasting/_rules-candidates.md` in the audit commit.

---

## Session Recovery

1. Check if `./plancasting/_audits/implementation-completeness/report.md` exists
2. If report has Fix Summary + Verification Results: Phase 2+3 completed -> skip to Phase 4 for gate decision
3. If report has Fix Summary but no Verification Results: check which teammates finished. Re-spawn incomplete teammates, then spawn Teammate 3.
4. If report has Issues Found but no Fix Summary: Phase 2 not started -> proceed to Phase 2
5. If report does not exist: restart from Phase 1
6. Check `plancasting/_progress.md` for features already marked as Needs Re-implementation
7. Determine Run Number: If existing report has Run Number, increment by 1. If Run 4+ (third re-run), skip Phase 2 auto-fixes — escalate all remaining A/B to Category C.

---

## Critical Rules

1. NEVER skip the automated stub scan. Scan catches explicit text-pattern stubs (high confidence). THEN manually review thin components by cross-referencing PRD screen spec — a thin component is a stub only if it implements fewer states/interactions than spec requires.
2. NEVER mark a stub as "acceptable" — stubs are ALWAYS bugs. Only "Coming soon" acceptable for features in PRD future scope.
3. NEVER delete test files to make suite pass. Fix the code.
4. ALWAYS read feature brief and PRD screen spec before fixing a component.
5. ALWAYS follow CLAUDE.md conventions when writing fix code.
6. ALWAYS run full verification suite before declaring complete.
7. Frontend fixes are PRIMARY focus (70% effort).
8. If component fix requires non-existent backend changes, classify as Category C.
9. Goal is completeness, not perfection. Every feature FUNCTIONAL. Polish happens in Stage 6.
10. Fix, don't redesign. Maintain Stage 5's architectural decisions.

**5B Quality Standard**: 5B fixes should bring components from 'scaffold' to 'working' — happy path complete, loading/error states present, no obvious bugs. This is NOT production polish (Stage 6P handles that). The bar is: 'does this work as described in the PRD?'
