# Visual Polish & UI Refinement — Detailed Guide

## Stage 6P: Automated UI Enhancement Using Frontend Design Expertise

This reference contains the full detailed instructions for Stage 6P visual polish, including refinement categories, teammate prompts, design system integration, and report templates.

## Why This Stage Exists

Stages 6V and 6R ensure the application is **functionally correct** -- every route loads, every button works, every auth flow succeeds. But functional correctness does not equal visual quality. Common issues that survive 6V/6R:

1. **Invisible or low-contrast elements**: Text that renders but is barely visible against its background
2. **Layout collapse at breakpoints**: Components that work at desktop but stack awkwardly at mobile
3. **Inconsistent spacing**: No rhythm across pages
4. **Missing micro-interactions**: Buttons with no hover state, no press feedback, no transition
5. **Typography hierarchy gaps**: All text looks the same size/weight
6. **Empty state aesthetics**: Functional empty states that look like placeholder UI
7. **Loading state jank**: Skeleton loaders that don't match final layout
8. **Dark mode gaps**: Light mode polished, dark mode has contrast issues
9. **Animation absence**: Page transitions feel abrupt
10. **Generic "AI slop" aesthetics**: The app looks like every other AI-generated SaaS

**Stage Sequence**: ... -> 6V (Verification) -> 6R (Runtime Remediation) -> **6P (this stage)** -> 7 (Deploy) -> 7V (Production Smoke) -> 7D (User Guide)

## Relationship to the `frontend-design` Skill

This stage uses the **`frontend-design` skill** (Claude Code plugin) for all aesthetic decisions. The skill's core principles:
- **Typography**: Distinctive, characterful font choices
- **Color & Theme**: Cohesive aesthetic with dominant colors and sharp accents
- **Motion**: High-impact animations at key moments
- **Spatial Composition**: Unexpected layouts, asymmetry, generous negative space
- **Visual Depth**: Gradient meshes, noise textures, layered transparencies, dramatic shadows

**KEY CONSTRAINT**: This stage operates WITHIN the project's existing design system. You are NOT redesigning from scratch. You are elevating, adding, fixing, and enhancing within the design system's vocabulary.

## Known Failure Patterns

1. **Replacing UI library components wholesale**: ALWAYS use the library's component API to add styling -- never replace the component itself.
2. **CSS specificity wars**: Use `!important` sparingly; prefer the library's theming/customization API.
3. **Breaking existing dark mode**: ALWAYS add both light and dark variants when modifying colors.
4. **Animation performance regression**: ONLY animate `transform` and `opacity`.
5. **Font loading FOUT/FOIT**: Use `next/font` (or equivalent) with `display: swap`.
6. **Overzealous enhancement scope**: Target high-impact pages -- do not polish every minor component.

## Refinement Categories

### Category O: Objective Defects (Auto-Fix, No Judgment)
Issues with a clear right/wrong answer. MUST fix these.

| Issue Type | Detection Method | Fix Pattern |
|---|---|---|
| WCAG contrast failure (< 4.5:1 text, < 3:1 large text) | Automated contrast ratio check | Adjust text color or background |
| Text invisible or near-invisible | AI vision analysis | Adjust color, add text-shadow, or change background |
| Layout overflow at standard breakpoints | Screenshot at 320/768/1024/1440px | Fix with responsive utilities |
| Content clipped by parent container | AI vision -- text/elements cut off | Fix overflow or adjust sizing |
| Skeleton loader doesn't match content layout | Compare loading vs loaded screenshots | Adjust skeleton dimensions |
| Focus ring missing on interactive elements | Tab through elements | Add `focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2` |
| Z-index stacking error | AI vision -- overlapping elements | Fix z-index hierarchy |
| Dark mode unstyled section | Screenshot in dark mode | Add dark mode variants |
| Image/icon not rendering | AI vision -- broken image placeholder | Fix asset path or provide fallback |
| Touch target too small (< 44x44px mobile) | Measure in mobile screenshots | Increase padding/size |

### Category E: Enhancement (Pattern-Based, Apply & Verify)
Issues where the fix follows established codebase patterns.

| Issue Type | Detection | Fix Pattern | Verify |
|---|---|---|---|
| Missing hover state | Interact with element | Add hover transition using existing patterns | Doesn't break layout |
| Missing page transition animation | Navigate between pages | Add entry animation using motion library/CSS | Doesn't delay perceived load |
| Inconsistent spacing | Compare across pages | Standardize to spacing scale tokens | Content fits at all breakpoints |
| Empty state visually weak | AI vision -- sparse | Enhance with icon or CTA using existing design assets | CTA navigation works |
| Typography hierarchy flat | AI vision -- no hierarchy | Apply heading/subheading/body scale | Text doesn't overflow |
| Card/container missing depth | AI vision -- flat | Add shadow or border using design tokens | Consistent with surrounding cards |
| Loading state too plain | Observe loading state | Replace with skeleton matching content layout | Skeleton-to-content transition smooth |
| Form input styling inconsistent | Compare across pages | Standardize to project's form styling | All states still work |

### Category D: Design Elevation (Needs Design Review)
Subjective improvements. Document as suggestions for human review -- do NOT apply.

| Issue Type | What To Document |
|---|---|
| Font pairing opportunity | Suggested pair, visual mockup |
| Color palette feels flat | Suggested accents, gradient direction, mockup |
| Hero/landing section lacks impact | Suggested composition, background, motion concept |
| Illustration style opportunity | Suggested style, example references |
| Micro-interaction opportunity | Interaction description, expected delight factor |
| Overall aesthetic direction | Named direction, rationale, which pages change |

## Teammate Prompts

### Teammate 1: "objective-defect-fixer"
**Scope**: ALL Category O issues

Rules:
- Use ONLY existing design system tokens
- For contrast fixes, prefer adjusting text color over background
- For responsive fixes, use project's breakpoint utilities
- For dark mode fixes, use project's dark mode pattern
- NEVER change functional behavior
- For authenticated pages, log in before taking screenshots
- After fixing each issue, verify visually with Playwright browser tools
- Run `bun run typecheck` and `bun run lint` after each batch

### Teammate 2: "enhancement-applier"
**Scope**: ALL Category E issues

Rules:
- If design guidelines suggest approaches that conflict with design system tokens, adapt the intent to the system's tokens
- Group similar enhancements (e.g., apply hover transitions to ALL buttons at once)
- For motion/animation: use existing motion library if available, otherwise CSS-only
- Focus on HIGH-IMPACT moments: page entry reveals, hero animations, card hover lifts
- Do NOT add animation to every element -- restraint is elegance
- Maximum 3 animation additions per page
- For typography hierarchy: work within the existing type scale
- Capture before/after screenshots with Playwright browser tools
- Run `bun run typecheck` and `bun run lint` after each batch

### Teammate 3: "responsive-cross-theme-verifier" (runs AFTER Teammates 1 and 2)
**Scope**: Re-verify ALL modified screens at all 3 breakpoints + dark mode

Rules:
- If a fix/enhancement causes a regression at a different breakpoint, flag immediately (do NOT attempt to fix)
- Capture comparison screenshots at 1440px, 768px, 375px
- Test mobile touch interactions
- Verify page load performance hasn't degraded
- Log in with test user for authenticated pages

**Sequencing**: Teammates 1 and 2 run in parallel. Teammate 3 runs AFTER both complete.

## Phase 1: Lead Visual Audit

1. Read project context: `./CLAUDE.md`, `./plancasting/tech-stack.md`, `./plancasting/prd/08-screen-specifications.md`, 6V/6R reports
2. Identify the design system: tokens, tailwind config, global styles, theme config, font imports, animation patterns
3. Establish validation baseline: `bun run typecheck`, `bun run lint`, `bun run test`
4. Start the application (or reuse running instance)
5. Screenshot all key screens at 3 breakpoints (1440, 768, 375) -- focus on 10-15 most user-facing screens
6. AI Vision Analysis: check for Category O, E, and D issues
7. Create Visual Polish Plan at `./plancasting/_audits/visual-polish/plan.md`
8. Invoke `frontend-design` skill for enhancement guidance (if available). Save output as `./plancasting/_audits/visual-polish/design-guidelines.md`
9. Assign teammates and prevent file conflicts -- document file assignments in plan

## Phase 3: Integration & Report

1. Collect teammate results, check for regressions
2. Fix regressions: revert the specific change, re-apply with responsive-safe approach
3. Run full validation: `bun run typecheck`, `bun run lint`, `bun run test`
4. Generate Category D design brief using `frontend-design` skill (if available). Save as `./plancasting/_audits/visual-polish/design-elevation-brief.md`
5. Generate Visual Polish Report at `./plancasting/_audits/visual-polish/report.md`
6. Save comparison screenshots

## Report Template

```markdown
# Stage 6P Visual Polish Report

## Summary
- **Date**: [date]
- **Commit**: [git hash before polish]
- **Design System**: [UI library + version]
- **Aesthetic Direction**: [from plancasting/tech-stack.md]

## Results
- Category O (objective defects): [n] found, [n] fixed, [n] could not fix
- Category E (enhancements): [n] found, [n] applied, [n] skipped
- Category D (design elevation): [n] suggestions documented
- Regressions found during verification: [n]

## Category O Fixes Applied
| # | Screen | Issue | Fix | Before | After | Status |
|---|--------|-------|-----|--------|-------|--------|

## Category E Enhancements Applied
| # | Area | Enhancement | Approach | Before | After | Status |
|---|------|------------|---------|--------|-------|--------|

## Category D Design Elevation Brief
See `./plancasting/_audits/visual-polish/design-elevation-brief.md`

## Responsive Verification
| Screen | Desktop (1440) | Tablet (768) | Mobile (375) | Dark Mode |
|--------|---------------|-------------|-------------|-----------|

## Files Modified
[List]

## Validation
- TypeScript: PASS / FAIL
- ESLint: PASS / FAIL
- Tests: PASS / FAIL

## Gate Decision
- **PASS**: All Category O fixed, Category E applied, no regressions
- **CONDITIONAL PASS**: All critical fixed + Category D brief for optional elevation
- **FAIL**: Regressions remain or validation fails

## Next Steps
- PASS or CONDITIONAL PASS: proceed to Stage 7 (Deploy) -> 7V -> 7D
- FAIL: investigate regressions before Deploy
```

## Phase 4: Shutdown

1. Commit: `git add src/ plancasting/_audits/visual-polish/ && git commit -m "style: Stage 6P visual polish -- [n] defects fixed, [n] enhancements applied"`
2. Save commit hash: `git rev-parse HEAD > ./plancasting/_audits/visual-polish/last-polished-commit.txt`
3. Request shutdown for all teammates
4. Stop dev server if it was started by this stage

## Critical Rules

1. NEVER change functional behavior -- only visual presentation.
2. NEVER replace design system components with custom implementations.
3. NEVER introduce new fonts without human approval (Category D).
4. NEVER introduce new dependencies without checking `package.json`.
5. ALWAYS take before/after screenshots.
6. ALWAYS run validation after fixes.
7. ALWAYS work at all 3 breakpoints.
8. Teammate 3 focuses on HIGHEST-IMPACT screens first.
9. ALWAYS respect dark mode pattern.
10. Category O before Category E.
11. The `frontend-design` skill guides INTENT, not implementation.
12. Maximum 3 animation additions per page.
13. AVOID modifying shared UI primitive components directly unless fixing Category O or applying global Category E.
14. If 6R report shows FAIL, STOP.
15. Treat contrast ratios as non-negotiable (WCAG AA minimum).
16. ALWAYS preserve accessibility.
17. The lead invokes `/frontend-design`, teammates read the output.
18. Teammates 1 and 2 parallel, Teammate 3 sequential AFTER both.
19. ALL browser interactions require the dev server to be running.
20. Test user login required for authenticated screenshots.
21. ALWAYS check for console errors during screenshots.
22. Ensure NO two teammates modify the same file.
