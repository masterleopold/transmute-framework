---
name: audit-a11y
description: >-
  Performs a multi-agent WCAG accessibility audit of the frontend codebase.
  This skill should be used when the user asks to "audit accessibility",
  "check WCAG compliance", "run an accessibility review", "a11y audit",
  "check screen reader support", "fix accessibility issues",
  or "verify keyboard navigation",
  or when the transmute-pipeline agent reaches Stage 6B of the pipeline.
version: 1.0.0
---

# Accessibility Audit — Stage 6B

Lead a multi-agent accessibility audit of the complete frontend codebase against BRD/PRD WCAG requirements. Identify violations and fix them.

## Prerequisite Checks

Before any audit work, verify:

1. Check that `./plancasting/_audits/implementation-completeness/report.md` exists and shows PASS or CONDITIONAL PASS. If missing, warn that Stage 5B is unverified and proceed — flag findings in stub code separately. If FAIL, stop and report that implementation gaps must be resolved first.
2. If CONDITIONAL PASS, read documented Category C issues and skip accessibility auditing for those incomplete features.
3. Read `./CLAUDE.md` and `./plancasting/tech-stack.md` for project conventions.
4. Read relevant PRD sections for implementation context.

## Inputs

- **Codebase**: `./src/` (adapt paths per tech stack)
- **Tech Stack**: `./plancasting/tech-stack.md`
- **BRD Accessibility Requirements**: `./plancasting/brd/08-non-functional-requirements.md` (WCAG section). If not found, search: `grep -rlE "WCAG|accessibility" ./plancasting/brd/`
- **BRD UX Requirements**: `./plancasting/brd/11-user-experience-requirements.md`
- **PRD Screen Specs**: `./plancasting/prd/08-screen-specifications.md` (accessibility annotations)
- **PRD Interaction Patterns**: `./plancasting/prd/09-interaction-patterns.md`
- **Project Rules**: `./CLAUDE.md`
- **Implementation Completeness**: `./plancasting/_audits/implementation-completeness/report.md`

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate reports in that language. Keep code and file names in English.

## Stack Adaptation

Adapt references to your actual stack:
- `src/app/` becomes your pages/routes directory
- `src/components/` becomes your component directory
- React Aria patterns become your accessibility library's patterns
- `npm run` becomes your package manager command (e.g., `bun run`)

If using a component library with built-in accessibility (React Aria, HeadlessUI, Radix), do NOT add redundant ARIA attributes that conflict with the library's built-in handling.

## Phase 1: Analysis and Planning

Complete before spawning teammates:

1. Read `./CLAUDE.md`, `./plancasting/tech-stack.md`, and BRD/PRD accessibility requirements. Check both `./plancasting/brd/08-non-functional-requirements.md` and `plancasting/prd/15-non-functional-specifications.md` for WCAG version and conformance level. If they conflict, PRD takes precedence. Defaults: WCAG 2.1, AA conformance. Check WCAG 2.2 criteria as forward-looking best practices.
2. Build an **Accessibility Checklist** organized by WCAG principle (Perceivable, Operable, Understandable, Robust).
3. Write `./plancasting/_audits/accessibility/checklist.md` with the full checklist.
4. Create a task list for all teammates with dependency tracking.

## Phase 2: Spawn Audit Teammates

Spawn 3 parallel teammates. Each prompt must include the accessibility checklist and target WCAG level.

### Teammate 1: semantic-structure-auditor

Scope: Semantic HTML, headings, landmarks, document structure.

- **Heading hierarchy**: Scan every page. Verify one h1 per page (or `aria-label` on main landmark). Verify sequential heading levels (h1 to h2 to h3). Sibling sections may restart hierarchy. Verify headings use semantic elements, not styled divs.
- **Landmarks**: Verify every page has exactly one `<main>`, `<nav>` with `aria-label` for each navigation region, `<header>` and `<footer>` where appropriate, and no significant content outside landmarks.
- **Semantic HTML**: Flag `<div>`/`<span>` where semantic elements should be used (`<button>`, `<a>`, `<nav>`, `<article>`, `<section>`, `<form>`, `<table>`, `<ul>`/`<ol>`/`<li>`). Verify lists, tables, links, and buttons use correct elements.
- Fix each violation found.

### Teammate 2: interactive-elements-auditor

Scope: Keyboard navigation, focus management, interactive components.

- **Keyboard navigation**: Verify all interactive elements are Tab-reachable. Verify custom components follow correct keyboard patterns (dropdowns: arrow keys + Enter/Space/Escape; modals: focus trap + Escape + focus return; tabs: arrow keys between tabs). Flag onClick without onKeyDown. Flag tabIndex > 0.
- **Focus management**: Verify visible focus on all interactive elements (no `outline: none` without replacement). Verify logical focus movement after dynamic content changes. Verify skip-to-main-content link exists.
- **ARIA on interactives**: Verify buttons have accessible names. Verify icon-only buttons have `aria-label`. Verify toggle buttons use `aria-pressed`/`aria-expanded`. Verify form inputs have associated labels. Verify error states use `aria-live`/`aria-describedby`. Verify loading states use `aria-live="polite"`/`role="status"`.
- Fix each issue found.

### Teammate 3: content-and-media-auditor

Scope: Text alternatives, color contrast, responsive accessibility.

- **Text alternatives**: Verify all `<img>` have meaningful alt text (or `alt=""` for decorative). Verify SVG icons have `aria-hidden="true"` or accessible labels. Verify video/audio have captions/transcripts.
- **Color and contrast**: Extract actual hex/RGB values from design tokens or CSS variable definitions. Flag combinations failing WCAG AA contrast ratio (4.5:1 normal text, 3:1 large text). Use relative luminance formula or `npx wcag-contrast`. If dark mode exists, verify both themes pass. Verify information is not conveyed by color alone.
- **Responsive accessibility**: Verify readability at 200% zoom without horizontal scrolling. Verify touch target minimum sizes (WCAG 2.2 AA: 24x24px; WCAG 2.1 AAA: 44x44px; mobile-first: 44x44px recommended). Verify no content hidden at different breakpoints.
- **Empty and error states**: Verify empty states have descriptive text. Verify error messages use `aria-describedby`. Verify form validation errors are announced.
- **Motion sensitivity**: Check all animation types (CSS, JS, SVG). Verify `@media (prefers-reduced-motion: reduce)` is used. For JS animations verify `matchMedia` check. Verify no auto-playing animations without control. Verify `scroll-behavior: smooth` respects reduced motion preference.
- **Language**: Verify `<html lang="...">` is set correctly. Verify `dir` attribute for RTL if applicable.
- Fix each issue found.

## Unfixable Violation Protocol

When a violation cannot be fixed without architectural changes:

1. Document the full conflict with evidence.
2. Mark as **REQUIRES HUMAN DECISION**.
3. Include recommended approach and estimated effort.
4. If WCAG Level A: mark CRITICAL and flag as potential launch blocker.
5. Record unfixable Level A violations in `./plancasting/_audits/accessibility/unfixable-violations.md` and summarize in report.md under "Blocking Issues".
6. Continue with remaining fixable violations.

## Phase 3: Coordination

- If semantic-structure-auditor changes a div to a button, notify interactive-elements-auditor for keyboard handler review.
- If content-and-media-auditor finds contrast issues, notify semantic-structure-auditor for landmark styling adjustments.
- Resolve conflicts when multiple teammates modify the same component.

## Phase 4: Automated Testing and Report

1. Install and run axe-core automated tests as final verification. Install the appropriate package for your E2E framework (`@axe-core/playwright`, `cypress-axe`, or `@axe-core/webdriverio`). If installation fails, proceed with manual review and document the limitation.
2. Check for an existing accessibility test file before creating one. If none exists, create `e2e/accessibility.spec.ts`. Run axe on every page and report violations.
3. Run accessibility tests: `bun run test:e2e -- e2e/accessibility.spec.ts`
4. Run the full test suite: `bun run typecheck`, `bun run test`, `bun run test:e2e`
5. Generate `./plancasting/_audits/accessibility/report.md` containing:
   - WCAG conformance level achieved
   - Violations by principle (Perceivable/Operable/Understandable/Robust) and severity
   - Fixes applied with code references
   - Automated test results (axe-core)
   - Remaining issues requiring manual testing (screen reader, cognitive review)
   - BRD NFR accessibility compliance matrix
6. Include a **Gate Decision**: PASS (no Level A violations, all Level AA fixed or verified as false positives), CONDITIONAL PASS (all Level A fixed, remaining Level AA requiring manual verification), or FAIL (Level A violations remain unresolved; document in unfixable-violations.md and escalate to Stage 6H).
7. Output summary: total violations found, total fixed, automated test pass rate.

## Phase 5: Shutdown

1. Request shutdown for all teammates.
2. Verify all file modifications are saved and committed.

## Known Failure Patterns

Avoid these common mistakes:

1. **Redundant ARIA on library components**: Do not add `aria-label`, `role`, or `aria-expanded` to components that already handle these via their accessibility library. Always check library handling first.
2. **`aria-hidden="true"` to suppress violations**: Never hide elements from the accessibility tree instead of fixing the issue. Only use for genuinely decorative elements.
3. **`role="button"` on div**: Always prefer semantic HTML (`<button>`) over ARIA roles.
4. **Inconsistent focus styles**: Always use the project's established focus ring pattern from CLAUDE.md.
5. **Layout breaks from semantic changes**: Verify visual appearance after changing `<div>` to `<section>` or `<nav>`.
6. **Missing `lang` attribute**: Always check `<html lang="...">` (WCAG 3.1.1 Level A).

## Critical Rules

1. ALWAYS prefer semantic HTML over ARIA roles.
2. NEVER add `aria-hidden="true"` to suppress axe violations.
3. NEVER add ARIA attributes that conflict with your component library's built-in accessibility.
4. ALWAYS use the project's focus ring convention from CLAUDE.md. If unspecified, define one and document it.
5. ALWAYS verify visual layout is preserved after semantic HTML changes.
6. ALWAYS check `<html lang="...">` matches the session language.
7. ALWAYS verify `prefers-reduced-motion` is respected for animations.
8. ALWAYS run the full test suite after changes.
9. Use commands from CLAUDE.md for testing.
10. Reference Stage 5B output to identify incomplete features — skip auditing them entirely. Calculate compliance percentages based on audited features only (e.g., "Audited 12/15 features; 3 skipped as incomplete per Stage 5B").
