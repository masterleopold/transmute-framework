# Runtime Remediation — Detailed Guide

## Stage 6R: Automated Fix Loop for 6V Verification Failures

This reference contains the full detailed instructions for Stage 6R remediation, including fixability taxonomy, teammate prompts, safety rules, and report templates.

## Why This Stage Exists

Stage 6V finds runtime issues but explicitly does NOT fix them. Without a dedicated remediation stage, the workflow is:
1. 6V finds 30 issues -> writes report
2. Human reads report -> manually prioritizes and fixes each one
3. Human re-runs 6V -> finds 5 regressions from the manual fixes
4. Repeat until clean

This is slow and error-prone. Stage 6R automates the mechanical fixes (typically 60-80% of all 6V failures) and feeds the remaining issues to the human as a structured TODO.

**Stage Sequence**: ... -> 6H (Pre-Launch) -> 6V (Verification) -> **6R (this stage)** -> 6P or 6P-R (Visual Polish or Redesign) -> 7 (Deploy) -> 7V (Production Smoke) -> 7D (User Guide) -> 8 (Feedback) -> 9 (Maintenance)

> **Category System Note**: This stage uses a DIFFERENT category system than Stage 5B:
> - **5B Categories** (size-based): A = <30 lines per file, B = 30-100 lines AND <150 total, C = >=100 lines or unbuilt features
> - **6R Categories** (fixability-based): A = auto-fixable code issue, B = semi-auto fixable, C = needs human judgment
> Classify based on FIXABILITY, not severity. A critical bug that's easy to fix is Category A; a minor issue requiring architectural change is Category C.

## Fixability Taxonomy

Every 6V failure falls into one of three categories:

### Category A: Auto-Fixable (No Judgment Required)
These issues have exactly ONE correct fix.

| Issue Type | Fix Pattern | Example |
|---|---|---|
| Public route blocked by auth middleware | Add route to `PUBLIC_ROUTES` array in middleware | `/privacy` redirects to `/login` -> add to whitelist |
| Dead link to non-existent page (in shared layouts) | Remove the `<Link>` element or create a minimal placeholder page | Footer links to `/about` but no `page.tsx` exists |
| Missing i18n translation key | Add the key to the translation file with the text shown in the component | Component uses `t("settings.title")` but key missing from `en.json` |
| Sub-nav tab pointing to missing page | Create a stub `page.tsx` with proper loading/empty states | Audit tab links to `/audits/performance` but no page exists |
| Console error from missing import | Add the missing import statement | `ReferenceError: X is not defined` where X is an importable module |
| Broken `href` in static link | Fix the `href` to match the correct route constant | `<Link href="/setting/profile">` -> `<Link href="/settings/profile">` |
| Mobile nav missing link that desktop nav has | Add the missing link to mobile nav component, matching desktop | Desktop sidebar has `/help` but mobile bottom bar doesn't |
| TypeScript type error causing runtime crash | Fix the type error (usually a missing field mapping or incorrect cast) | `Cannot read property 'name' of undefined` from unmapped field |
| Loading state missing (shows blank instead of skeleton) | Add loading component using project's existing loading patterns | Page shows white flash during data fetch -- add `loading.tsx` |
| Route constant defined but `page.tsx` in wrong directory | Move the `page.tsx` to the correct directory matching the route | Route is `/projects/[id]/hub` but page is at `/projects/[id]/hub.tsx` (not in a folder) |

### Category B: Semi-Auto-Fixable (Pattern-Based, Needs Verification)
These issues have a likely correct fix based on codebase patterns, but the fix could have side effects.

| Issue Type | Fix Pattern | Verify |
|---|---|---|
| Button onClick calls undefined function | Wire to the correct existing function: (1) Check `handleX` in same component, (2) check project hooks, (3) if neither exists, escalate to C | Verify the function signature matches, the mutation exists |
| Conditional tab incorrectly enabled/disabled | Fix the status check logic | Verify the complete status matrix |
| Form submission has no feedback | Add toast notification or redirect using project's existing patterns | Verify the mutation actually succeeds |
| Auth redirect after login doesn't return to original page | Fix the redirect logic to use the `redirect` query param | Verify the redirect param is properly URL-encoded and doesn't enable open redirect |
| Empty state component not rendering | Check if the condition for "empty" is correct | Verify the empty state CTA navigates correctly |
| Cross-feature navigation passes wrong params | Fix the params based on the receiving page's expected params | Verify the receiving page handles the params correctly |

### Category C: Needs Human Judgment (Cannot Auto-Fix)

| Issue Type | Why It Needs Human | What To Document |
|---|---|---|
| Feature flow broken due to missing backend logic | Backend mutation/action doesn't exist | Which mutation is missing, what the PRD says it should do |
| Visual layout significantly mismatches spec | Design decision -- may be intentional | Screenshot + spec comparison |
| Multiple valid fix approaches exist | Business trade-off | The options, trade-offs of each |
| Security vulnerability found during verification | Security decision -- may require architecture change | Vulnerability details, severity |
| Performance issue (page load > 3s) | Optimization strategy varies | Which page, load time, suspected cause |
| Third-party integration failure | May require API key or provider-side config | Which service, error details |
| Data model mismatch between frontend and backend | API contract decision | Frontend expected shape, backend actual shape |

## Known Failure Patterns

1. **Fix cascade**: Fixing issue A introduces issue B. ALWAYS run typecheck + affected tests after each fix batch.
2. **Middleware whitelist over-broadening**: Adding `/api/*` to PUBLIC_ROUTES instead of specific endpoints. ALWAYS add the EXACT route.
3. **Stub page without proper auth**: Creating a stub `page.tsx` for an authenticated route but forgetting auth guards.
4. **Fix the symptom, not the cause**: Before wiring a button to a function: (1) Verify function exists, (2) check git blame -- if recently deleted with "defer feature", may be intentional, (3) if truly missing, escalate to Category C. Do NOT create stub functions.
5. **Mobile nav divergence**: ALWAYS copy the EXACT same visibility conditions.
6. **i18n key added in English only**: Check `plancasting/tech-stack.md` for supported languages.
7. **Category mis-classification**: ALWAYS verify the fix target actually exists before applying.
8. **Fix introduces routing regression**: ALWAYS run the full re-verification after fixes.
9. **Re-verification scope too narrow**: After applying fixes, verify ALL previously-passing scenarios still pass.
10. **Placeholder pages without states**: Every new page MUST include all required states per CLAUDE.md.

## Teammate Prompts

### Teammate 1: "navigation-routing-fixer"
**Scope**: All navigation, routing, middleware, and link-related fixes (Categories A and B)

Safety Rules:
1. NEVER modify business logic -- only fix routing, navigation, and middleware configuration.
2. ALWAYS use the project's existing patterns.
3. After EACH fix, run `bun run typecheck`.
4. If creating a new page file, include proper auth guards, loading.tsx, error handling, project layout structure.
5. For middleware changes, add ONLY the specific route -- NEVER use wildcards.

Fix types: Public Route Blocked by Middleware, Dead Link in Shared Layout, Broken href, Mobile Nav Missing Links, Sub-Navigation Tab Pointing to Missing Page, Auth Redirect Issues.

For public route / middleware fixes: Use `browser_close` to end the current session, then `browser_navigate` to start a fresh session. Do NOT verify while logged in.

### Teammate 2: "component-ui-fixer"
**Scope**: All UI component, event handler, loading state, empty state, i18n, and button-wiring fixes (Categories A and B)

Safety Rules:
1. NEVER change component visual design or layout.
2. ALWAYS read existing component source BEFORE modifying.
3. After EACH fix, run `bun run typecheck`.
4. For button handler fixes: verify the mutation/action being wired actually EXISTS.
5. For i18n fixes: add keys to ALL language files.
6. Use the project's existing UI primitives for loading/empty states.
7. Use Playwright browser tools for before/after evidence.

Fix types: Button onClick Does Nothing, Missing Loading State, Missing Empty State, Missing i18n Translation Key, Console Error from Missing Import, TypeScript Runtime Error, Confirmation Dialog Missing for Destructive Action.

### Teammate 3: "backend-data-fixer"
**Scope**: Backend function fixes, data flow issues, auth context fixes (Categories A and B only)

Safety Rules:
1. NEVER create new backend functions that implement business logic.
2. NEVER modify database schema.
3. After EACH fix, run `bun run typecheck` and `bun run test`.
4. NEVER weaken auth checks.
5. NEVER edit auto-generated files.

Fix types: Backend Function Returns Wrong Shape, Auth Context Not Propagated, Query Returns Empty When Data Exists, Action/Mutation Missing Error Handling, Real-Time Subscription Not Updating.

## Phase 3: Integration & Verification

1. **Merge and validate**: Verify no file conflicts between teammates. Run `bun run typecheck`, `bun run lint`, `bun run test`. If any check fails that passed in baseline, revert the fix and move to Category C.

2. **Start the dev server**: Check if already running. If not, start with `bun run dev &`. Wait up to 60 seconds. If the server fails to start, mark fixes as "unverifiable" and proceed to report.

3. **Targeted re-verification**: Verify each fix using Playwright browser tools. For public route fixes: use `browser_close` + fresh session. For auth redirect fixes: test both directions. Quick regression sweep of ~5-10 key pages.

   **3-breakpoint verification**: For UI fixes, verify at 1440px, 768px, and 375px to ensure responsive behavior is maintained.

   **Tier-based screenshot handling**:
   - Category A: Single screenshot at primary breakpoint is sufficient
   - Category B: Before/after screenshots at all 3 breakpoints
   - Responsive layout fixes: Always verify at mobile (375px)

   **Regression detection**: Compare NEW failures against original 6V report. If regressions from 6R fixes: revert, move to Category C. If unrelated: document as "New finding (not caused by 6R)".

4. **Update 6V report**: Append remediation results section to `./plancasting/_audits/visual-verification/report.md`. Update the `## Gate Decision` section to reflect post-remediation state.

5. **Generate remediation report** at `./plancasting/_audits/runtime-remediation/report.md`.

6. **Extract verified fix patterns as rules** (see CLAUDE.md 'Path-Scoped Rules'):
   For each verified Category A/B fix, evaluate if the pattern is generalizable:
   - **HIGH confidence** (verified working fix across 2+ features): Append to `.claude/rules/*.md`
   - **MEDIUM confidence** (single-feature but likely generalizable): Append to `plancasting/_rules-candidates.md`
   - 6R rules are inherently higher confidence than 5B rules (battle-tested)

7. **Commit all changes**: `git add src/ <backend-dir>/ plancasting/_audits/runtime-remediation/ plancasting/_audits/visual-verification/report.md .claude/rules/ plancasting/_rules-candidates.md && git commit -m "fix: Stage 6R auto-remediation -- [n] issues resolved, [n] rules extracted"`

8. **Save commit hash**: `git rev-parse HEAD > ./plancasting/_audits/runtime-remediation/last-remediated-commit.txt`

## Unfixable Violation Protocol

If a runtime issue requires architectural changes beyond this stage's scope:
1. Document in `./plancasting/_audits/runtime-remediation/category-c-escalations.md`
2. Mark as 'REQUIRES HUMAN DECISION'
3. Include in final report under 'Category C Escalations'
4. Continue fixing remaining A/B issues -- do not block the loop

## Post-3-Cycles Escalation

After 3 internal fix-verify cycles within a single 6R run, if 6V-A/B issues persist:
- Escalate ALL remaining 6V-A/B to 6V-C
- Update gate to CONDITIONAL PASS
- Create `remaining-blockers.md` as authoritative list of unresolved issues
- Operator must: (a) manually resolve, re-run 6V, then 6R if needed, OR (b) document as known limitations and proceed to 6P
- If 6R gate is FAIL after max cycles, do NOT re-run 6R — manually fix 6V-C issues first, re-run 6V, then 6R if needed

## Report Template

```markdown
# Runtime Remediation Report -- Stage 6R

> **Category System**: This report uses 6R's fixability-based categories (A = auto-fix, B = semi-auto, C = needs human), which are DIFFERENT from Stage 5B's size-based categories.

## Summary
- **Remediation Date**: [date]
- **Commit Hash**: [git rev-parse HEAD]
- **Source**: Stage 6V report from [date]
- **Total 6V Failures**: [n]

## Triage Results
- Category A (auto-fix): [n] attempted, [n] successful, [n] reverted
- Category B (semi-auto): [n] attempted, [n] successful, [n] reverted
- Category C (needs human): [n] (not attempted)
- **Total resolved**: [n] / [total] ([percentage]%)

## Verification
- Typecheck: PASS / FAIL
- Lint: PASS / FAIL
- Test suite: [n]/[n] pass (baseline was [n]/[n])
- 6V re-verification: [n]/[n] fixes confirmed working

## Files Modified
[Complete list]

## Remaining Issues -- Human Action Required
### Critical (blocks deploy)
### High (should fix before deploy)
### Medium (can fix post-deploy)
### Low (nice to have)

## Loop Tracking
- **Current loop**: [N] / 3 (max 3 completed fix-verify loops)
- **Previous loop report**: [path or "N/A -- first loop"]

## Gate Decision
- **PASS**: All critical/high issues resolved
- **CONDITIONAL PASS**: Some high-severity issues remain but documented
- **FAIL**: Critical issues remain that block deployment

**Cycle limit rule**: After 3 internal fix-verify cycles within a single 6R run, if 6V-A/B issues persist, escalate to 6V-C. Update gate to CONDITIONAL PASS and proceed to 6P/6P-R. If 6R gate is FAIL after max cycles, do NOT re-run 6R — manually fix 6V-C issues first, re-run 6V, then 6R if needed.

## Rules Extracted
- HIGH confidence (auto-promoted): [n] rules added to `.claude/rules/`
- MEDIUM confidence (staged): [n] candidates added to `plancasting/_rules-candidates.md`

## Next Steps
- If PASS: proceed to Stage 6P/6P-R -> 7 (Deploy) -> Stage 7V -> Stage 7D
- If CONDITIONAL PASS: human reviews remaining issues
- If FAIL: human resolves Category C critical issues, then re-run 6V -> 6R
```

## Critical Rules

1. NEVER make business logic decisions. Move ambiguous fixes to Category C.
2. NEVER weaken security.
3. ALWAYS preserve the test baseline. Zero test regressions.
4. ALWAYS typecheck after EVERY fix.
5. ALWAYS verify fixes in the running app.
6. NEVER modify auto-generated files.
7. NEVER create database schema changes.
8. If a Category B fix introduces a NEW failure of EQUAL or HIGHER severity, revert and move to Category C.
9. ALWAYS read the component/function context before fixing.
10. ALWAYS check git blame or commit history when a fix seems too simple.
11. For i18n fixes: check ALL language files.
12. For stub pages: ALWAYS include proper auth guards, loading states, and error handling.
13. If 6V report has zero failures, output a clean report and exit.
14. Maximum 3 internal fix-verify cycles per run. Counter tracks COMPLETED cycles:
    - After 1st cycle completes -> file contains `1`
    - After 2nd cycle completes -> file contains `2`
    - After 3rd cycle completes -> file contains `3`
    - When you read `3` at start -> STOP immediately. Do NOT increment to 4.
15. ALWAYS respect the project's file organization conventions.
