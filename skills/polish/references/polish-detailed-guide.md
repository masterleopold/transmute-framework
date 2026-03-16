# Visual Polish & UI Refinement — Detailed Guide

## Stage 6P: Automated UI Enhancement Using Frontend Design Expertise

This reference contains the full detailed instructions for Stage 6P visual polish, including refinement categories, teammate prompts, design system integration, and report templates.

## Why This Stage Exists

Stages 6V and 6R ensure the application is **functionally correct** -- every route loads, every button works, every auth flow succeeds. But functional correctness does not equal visual quality. Common issues that survive 6V/6R:

1. **Invisible or low-contrast elements**: Text that renders but is barely visible against its background (e.g., gray-on-white, white-on-light-gradient)
2. **Layout collapse at breakpoints**: Components that work at desktop but stack awkwardly or overflow at tablet/mobile
3. **Inconsistent spacing**: Some pages use tight spacing, others use generous spacing -- no rhythm
4. **Missing micro-interactions**: Buttons that feel dead (no hover state, no press feedback, no transition)
5. **Typography hierarchy gaps**: All text looks the same size/weight -- no visual hierarchy guiding the eye
6. **Empty state aesthetics**: Functional empty states that look like placeholder UI (centered gray text + icon)
7. **Loading state jank**: Skeleton loaders that don't match the final layout, causing content shift
8. **Dark mode gaps**: Light mode looks polished, dark mode has contrast issues or unstyled sections. If the project currently lacks dark mode and the 6V/6R report suggests it should be added, escalate to 6P-R instead of implementing within 6P.
9. **Animation absence**: Page transitions and component reveals feel abrupt -- no entry animations
10. **Generic "AI slop" aesthetics**: The application looks like every other AI-generated SaaS -- Inter font, purple gradients, predictable card layouts

**Stage Sequence**: ... -> 6V (Verification) -> [6R (Runtime Remediation) -- only if 6V found 6V-A/B issues] -> **6P (this stage)** -> 7 (Deploy) -> 7V (Production Smoke) -> 7D (User Guide) -> 8 (Feedback) / 9 (Maintenance)

## Relationship to the `frontend-design` Skill

This stage uses the **`frontend-design` skill** (Claude Code plugin) for all aesthetic decisions. The skill's core principles:
- **Typography**: Distinctive, characterful font choices -- never generic Inter/Roboto/Arial
- **Color & Theme**: Cohesive aesthetic with dominant colors and sharp accents
- **Motion**: High-impact animations at key moments (page load, hover, transitions)
- **Spatial Composition**: Unexpected layouts, asymmetry, generous negative space or controlled density
- **Visual Depth**: Gradient meshes, noise textures, layered transparencies, dramatic shadows

**KEY CONSTRAINT**: This stage operates WITHIN the project's existing design system. You are NOT redesigning from scratch.

**Scope Prioritization**: Focus on HIGH-IMPACT pages first: (1) landing/marketing pages (first impression), (2) auth pages (signup/login -- conversion-critical), (3) primary dashboard (most-used screen), (4) core feature pages (P0/P1 features from PRD). Polish secondary pages (settings, profile, admin) only after key pages pass visual review. Target: 10-15 key screens, not every component in the codebase.

You are elevating, adding, fixing, and enhancing within the design system's vocabulary.

**Component modification decision matrix**:
| Scenario | Action |
|---|---|
| Component needs hover transition but library doesn't support via className | Add transition via wrapper `<div className="transition-colors">`, do NOT replace component |
| Component styling is completely incompatible with design direction | Escalate to Category D (document for design review), do NOT replace component |
| Text contrast fails WCAG AA in dark mode | Adjust color variant via className (e.g., `dark:text-slate-200`), do NOT replace component |

If the project uses a UI library (e.g., Untitled UI, shadcn/ui, Chakra), work WITHIN its component API. Do NOT replace library components with custom implementations unless fixing a specific defect that the library cannot handle. Replace a library component ONLY if: (1) the defect cannot be fixed via the component's API/props, (2) accessibility is broken, AND (3) the change is scoped to a single component. In all other cases, use wrapper components, CSS overrides, or configuration changes.

> **Component modification boundary**: Use the library's component API (className, props, variants) for styling changes. Escalate to Category D if the component API doesn't support the needed styling. NEVER replace a UI library component just for styling -- only escalate for accessibility fixes where the library offers no API path forward.

## Known Failure Patterns

1. **Replacing UI library components wholesale**: Agent replaces Untitled UI / shadcn/ui buttons with custom-styled `<button>` elements to add hover transitions. This breaks accessibility (ARIA), variant consistency, and future library updates. ALWAYS use the library's component API (className, variant props) to add styling -- never replace the component itself.
2. **CSS specificity wars**: Agent adds Tailwind utility classes that are overridden by the UI library's base styles. Fix: use `!important` sparingly and only as a last resort, or add styles via the library's theming/customization API.
3. **Breaking existing dark mode**: Agent fixes a light-mode contrast issue by hardcoding a color value (e.g., `text-gray-900`) without adding the `dark:` variant, breaking dark mode. ALWAYS add both light and dark variants when modifying colors.
4. **Animation performance regression**: Agent adds CSS transitions/animations that trigger layout recalculation (animating `width`, `height`, `top`, `left`). ONLY animate `transform` and `opacity` for performant animations.
5. **Font loading FOUT/FOIT**: Agent adds a distinctive display font via CDN `<link>` without `font-display: swap` or preloading, causing Flash of Unstyled Text or Invisible Text on slow connections. Use `next/font` (or equivalent) with `display: swap`.
6. **Overzealous enhancement scope**: Agent "improves" 50+ components when only 10 key screens need attention. This stage targets high-impact pages -- do not polish every minor component.
7. **Hybrid theme localStorage flicker**: In projects with light/dark mode, using `setTheme()` or similar JS-based theme toggles causes a flash of the wrong theme on page load because `localStorage` is read after initial render. NEVER use `setTheme()` for initial theme -- use CSS `prefers-color-scheme` media query as the default, with `setTheme()` only for user-initiated overrides.

## Refinement Categories

### Category O: Objective Defects (Auto-Fix, No Judgment)
Issues with a clear right/wrong answer. MUST fix these.

| Issue Type | Detection Method | Fix Pattern |
|---|---|---|
| WCAG contrast failure (< 4.5:1 text, < 3:1 large text) | Automated contrast ratio check on screenshots | Adjust text color or background to meet ratio |
| Text invisible or near-invisible against background | AI vision analysis of screenshots | Adjust color, add text-shadow, or change background |
| Layout overflow at any standard breakpoint | Screenshot at 320/768/1024/1440px widths | Fix overflow with proper responsive utilities |
| Content clipped by parent container | AI vision -- text/elements cut off | Fix overflow property or adjust sizing |
| Skeleton loader doesn't match content layout | Compare loading vs loaded screenshots | Adjust skeleton dimensions to match rendered content |
| Focus ring missing on interactive elements | Tab through all interactive elements | Add `focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2` |
| Z-index stacking error (element hidden behind another) | AI vision -- overlapping elements | Fix z-index hierarchy |
| Dark mode unstyled section (default white background persists) | Screenshot in dark mode | Add dark mode variants to unstyled sections |
| Image/icon not rendering (broken src or missing asset) | AI vision -- broken image placeholder visible | Fix asset path or provide fallback |
| Touch target too small (< 44x44px on mobile) | Measure interactive elements in mobile screenshots | Increase padding/size to meet minimum |

**Category boundary guideline**: If the feature is BROKEN or INACCESSIBLE (violates standards, prevents functionality), it's Category O. If it WORKS but FEELS UNPOLISHED (lacks feedback, delight, or visual consistency), it's Category E. Examples -- Category O: missing focus ring (WCAG violation), layout overflow (content hidden). Category E: missing hover state (button works but lacks feedback), no page entry animation.

### Category E: Enhancement (Pattern-Based, Apply & Verify)
Issues where the fix follows established patterns in the codebase.

| Issue Type | Detection | Fix Pattern | Verify |
|---|---|---|---|
| Missing hover state | Interact with element | Add hover transition using existing patterns | Doesn't break layout |
| Missing page transition animation | Navigate between pages | Add entry animation using motion library/CSS | Doesn't delay perceived load |
| Inconsistent spacing | Compare across pages | Standardize to spacing scale tokens | Content fits at all breakpoints |
| Empty state visually weak (just text) | AI vision -- sparse empty state | Enhance with icon or call-to-action using project's existing design system assets (do NOT source new illustrations -- if none exist, document as Category D suggestion instead) | Verify CTA navigation works |
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

Category D suggestions are for POST-LAUNCH review. They do NOT block Stage 7 deployment. The operator may implement them in a future 6P-R run or defer indefinitely.

## Teammate Prompts

### Teammate 1: "objective-defect-fixer"
**Scope**: ALL Category O issues

Rules:
- Use ONLY existing design system tokens (do NOT invent new colors, spacing values, or shadows). **Exception**: 6P may modify `design-tokens.ts` ONLY for: (a) adding a missing size to an existing scale (e.g., `shadow-md` between `shadow-sm` and `shadow-lg`), (b) correcting a token value to meet WCAG AA contrast (>=4.5:1 for text), or (c) fixing a broken variable reference. Do NOT change design direction or aesthetic intent -- only fill technical gaps in the scale. Document any token changes in the report.
- For contrast fixes, prefer adjusting the text color over the background (less visual disruption)
- For responsive fixes, use the project's breakpoint utilities (e.g., `md:`, `lg:` in Tailwind)
- For dark mode fixes, use the project's dark mode pattern (e.g., `dark:` prefix in Tailwind)
- NEVER change functional behavior -- this teammate only changes visual presentation
- For authenticated pages, log in before taking screenshots: use `browser_navigate` to go to the login page, then `browser_fill_form` or `browser_type`/`browser_click` to enter the test user's email and password from `./e2e/constants.ts`. Verify login succeeded before proceeding.
- After fixing each issue, verify visually with Playwright browser tools. Use `browser_console_messages` to check for JavaScript errors. For DOM inspection, use `browser_snapshot` to inspect the accessibility tree.
- Run `bun run typecheck` and `bun run lint` after each batch of fixes

### Teammate 2: "enhancement-applier"
**Scope**: ALL Category E issues

Rules:
- If the design guidelines suggest approaches that conflict with the existing design system tokens, adapt the intent to the system's tokens (e.g., if guidelines suggest "dramatic shadows" but design system has `shadow-sm`/`shadow-md`/`shadow-lg`, use `shadow-lg` not a custom box-shadow)
- Group similar enhancements (e.g., apply hover transitions to ALL buttons at once, not one by one)
- For motion/animation:
  - If the project uses a motion library (Framer Motion, Motion, etc.), use it
  - Otherwise, prefer CSS-only transitions and animations
  - Focus on HIGH-IMPACT moments: page entry reveals, hero animations, card hover lifts
  - Do NOT add animation to every element -- restraint is elegance
- Maximum 3 animation additions per page
- For typography hierarchy: work within the existing type scale, adjusting weights and sizes but not font families (font changes are Category D)
- After applying each enhancement category, use the Playwright browser tools to capture before/after screenshots. Use `browser_console_messages` to check for JavaScript errors. Log in with the test user from `./e2e/constants.ts` if screenshots require authentication.
- Run `bun run typecheck` and `bun run lint` after each batch

### Teammate 3: "responsive-cross-theme-verifier" (runs AFTER Teammates 1 and 2)
**Scope**: Re-verify ALL modified screens at all 3 breakpoints + dark mode

Rules:
- If a fix or enhancement causes a regression at a different breakpoint, flag it immediately (do NOT attempt to fix -- return to lead)
- Use Playwright browser tools to capture comparison screenshots: `browser_navigate` to each modified page, `browser_resize` to each breakpoint (1440, 768, 375), `browser_take_screenshot`. Save to `./screenshots/visual-polish/after/`. Log in with the test user from `./e2e/constants.ts` for authenticated pages.
- Compare with before screenshots in `./screenshots/visual-polish/before/`
- Test mobile touch interactions (tap states, swipe gestures if applicable)
- Verify page load performance hasn't degraded (animations shouldn't delay FCP)
- Focus on HIGHEST-IMPACT screens first in this priority order: (1) landing/home page, (2) dashboard, (3) primary feature page (the core product screen), (4) auth pages (login/signup), (5) settings/billing pages. Verify each at all 3 breakpoints + dark mode before moving to the next. If time permits after the top 5, continue to lower-impact screens. Mark any unverified screens in the report with "SPOT-CHECK ONLY" status. Target: verify at minimum the top 5 screens within 30 minutes.

**Sequencing**: Teammates 1 and 2 run in parallel. Teammate 3 runs AFTER both complete.

## Phase 1: Lead Visual Audit

1. Read project context: `./CLAUDE.md`, `./plancasting/tech-stack.md` (including `Session Language` setting -- generate all reports in that language; code remains in English), `./plancasting/prd/08-screen-specifications.md`, 6V/6R reports
2. Identify the design system: search in order -- `src/styles/design-tokens.ts` (or equivalent), `tailwind.config.ts`, global styles (`globals.css`, `app.css`), `plancasting/tech-stack.md` "Design Direction" section, theme config (for UI libraries), font imports (check `src/app/layout.tsx` or equivalent), animation/transition patterns. **Output a Design System Summary** documenting: color tokens, spacing scale, typography scale, shadow tokens, border-radius tokens, animation patterns, font families, and theme variants (dark mode). If tokens are scattered across multiple files, consolidate into a single summary for teammate reference. (Required output.)
3. Establish validation baseline: `bun run typecheck`, `bun run lint`, `bun run test`. Save results -- all fixes must maintain or improve this baseline.
4. Start the application: check if running (HEAD request to base URL), start if needed. BaaS caveat: if the project uses a BaaS and `bun run dev` fails, set client URL env var(s) manually in `.env.local` and run only the frontend dev server. Wait up to 60 seconds. ABORT if server fails to start.
5. Screenshot all key screens at 3 breakpoints (1440, 768, 375) -- focus on 10-15 most user-facing screens. Public pages first, then authenticated pages (log in with test user from `./e2e/constants.ts`), then dark mode (if supported). Save to `./screenshots/visual-polish/before/`. Reuse 6V screenshots if available and recent.
6. AI Vision Analysis: check for Category O (objective), Category E (enhancement), and Category D (elevation) issues
7. Create Visual Polish Plan at `./plancasting/_audits/visual-polish/plan.md` -- must include Design System Summary, triage, issue tables, and file assignments
8. Invoke `frontend-design` skill for enhancement guidance (if available). Save output as `./plancasting/_audits/visual-polish/design-guidelines.md`. If unavailable, teammates use project's existing design patterns.
9. Assign teammates and prevent file conflicts: group issues by file. If a file has BOTH Category O and Category E changes, assign ALL changes to ONE teammate. Document file assignments in plan. Teammates MUST read this section before modifying any file to verify ownership.

## Phase 3: Integration & Report

1. Collect teammate results. Check for regressions flagged by Teammate 3 and any Category E enhancements that Teammate 3 found problematic.
2. Fix regressions. A **regression** is a NEGATIVE SIDE EFFECT introduced by a polish fix: visual breakage of unrelated elements, functional breakage (button no longer works), accessibility breakage (new contrast failure), or performance degradation. Intentional enhancements (e.g., increased padding for touch targets) are NOT regressions. If Teammate 3 flagged regressions: revert the specific change, re-apply with responsive-safe approach, re-verify at the failing breakpoint. **Max iteration guard**: If regressions persist after 2 revert-and-reapply cycles for the same issue, document as known limitation. Persistent regressions usually indicate a CSS specificity conflict or component library constraint that requires a different approach.
3. Run full validation: `bun run typecheck`, `bun run lint`, `bun run test`. ALL must pass. If any fail, fix the issue or revert the change that caused it.
4. Generate Category D design brief using `frontend-design` skill (if available). Category D is for HUMAN REVIEW ONLY -- do NOT implement. If the frontend-design skill was unavailable (per Prerequisites), note in the report: "Category D design elevation brief not generated (frontend-design skill unavailable)." Save as `./plancasting/_audits/visual-polish/design-elevation-brief.md`.
5. Generate Visual Polish Report at `./plancasting/_audits/visual-polish/report.md`
6. Save comparison screenshots -- **before/after screenshots are required for every change**. Note: Screenshot directories (`./screenshots/`) are for local reference. Add to `.gitignore` -- do not commit large binary files.

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

### Top 3 Suggestions (Summary)
1. [Direction name]: [1-line description] -- [effort estimate]
2. [Direction name]: [1-line description] -- [effort estimate]
3. [Direction name]: [1-line description] -- [effort estimate]

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
- **PASS**: All Category O fixed, Category E applied, no regressions -- ready for Deploy
- **CONDITIONAL PASS**: All critical fixed + Category D brief for optional elevation -- ready for Deploy, consider design review
- **FAIL**: Regressions remain, critical Category O defects unresolved, or validation fails -- investigate before Deploy

## Next Steps
- If PASS or CONDITIONAL PASS: proceed to Stage 7 (Deploy) -> Stage 7V (Production Smoke) -> Stage 7D (User Guide)
- If FAIL: regressions detected -- investigate root cause, fix, and revalidate. Do NOT deploy until 6P PASS or CONDITIONAL PASS
```

## Phase 4: Shutdown

1. Commit: Stage modified files for commit using targeted `git add` (e.g., `git add src/ plancasting/_audits/visual-polish/` -- adapt paths to your project). Avoid `git add -A` which may capture unwanted files (screenshots, temp files). `git commit -m "style: Stage 6P visual polish -- [n] defects fixed, [n] enhancements applied"`
2. Save commit hash: `git rev-parse HEAD > ./plancasting/_audits/visual-polish/last-polished-commit.txt`
3. Request shutdown for all teammates
4. Stop dev server if it was started by this stage (check if it was already running from a prior session -- if so, leave it running)

## Session Recovery

If the session disconnects mid-execution: start a new session, re-paste the prompt. The lead reads the existing report at `./plancasting/_audits/visual-polish/report.md` and the progress tracker to determine which teammates have completed. Resume from the first incomplete teammate.

## Critical Rules

1. **NEVER change functional behavior.** This stage changes ONLY visual presentation. If a fix would alter routing, data flow, API calls, auth, or form submission logic, it is OUT OF SCOPE -- flag it and move on.
2. **NEVER replace design system components with custom implementations.** Work within the existing UI library's API. If a component doesn't support the enhancement you want, use CSS overrides or wrapper components, not replacements.
3. **NEVER introduce new fonts without human approval.** Font changes are Category D (design elevation). Document the suggestion but do NOT apply it.
4. **NEVER introduce new dependencies without checking `package.json`.** If an animation library isn't already installed, use CSS-only animations. Do NOT add Motion, GSAP, or other libraries without checking if they're already in the project.
5. **ALWAYS take before/after screenshots.** Every change must be visually documented. If you can't screenshot it, you can't verify it.
6. **ALWAYS run validation (typecheck + lint + test) after fixes.** A visual improvement that breaks the build is worse than no improvement.
7. **ALWAYS work at all 3 breakpoints.** A fix that looks great at desktop but breaks mobile is a regression, not an improvement.
8. **Teammate 3 scope management**: Teammate 3 focuses on HIGHEST-IMPACT screens first, in this priority order: (1) landing/home page, (2) dashboard, (3) primary feature page, (4) auth pages, (5) settings/billing pages. Verify each at all 3 breakpoints + dark mode before moving to the next. Mark any unverified screens in the report with "SPOT-CHECK ONLY" status. Target: verify at minimum the top 5 screens within 30 minutes.
9. **ALWAYS respect the project's dark mode pattern.** If the project uses `dark:` Tailwind classes, every color change must include the dark mode variant. If the project doesn't support dark mode, don't add it.
10. **Category O before Category E.** Fix objective defects first, then apply enhancements. Never polish what's broken.
11. **The `frontend-design` skill guides INTENT, not implementation.** When the skill says "dramatic shadows," translate that to your design system's shadow tokens. When it says "unexpected layout," interpret within your grid system. The skill's aesthetic vision + your design system's vocabulary = the implementation.
12. **Maximum 3 animation additions per page.** Restraint creates elegance. Do NOT animate every element -- choose the 1-3 highest-impact moments per page (hero reveal, card entry, hover lift).
13. **AVOID modifying shared UI primitive components directly** (e.g., `src/components/ui/` or your framework's equivalent) unless fixing a Category O defect or applying a global Category E enhancement. Prefer page-level or layout-level overrides for page-specific changes.
14. **If the 6R report shows FAIL, STOP.** This stage requires all functional issues to be resolved. If 6R has unresolved critical issues, return to 6R first.
15. **Treat contrast ratios as non-negotiable.** WCAG AA (4.5:1 for normal text, 3:1 for large text) is the MINIMUM. If in doubt, use a higher contrast option.
16. **ALWAYS preserve accessibility.** Focus rings, aria labels, semantic HTML, keyboard navigation -- if an enhancement would compromise any of these, skip it.
17. **The lead invokes `/frontend-design`, teammates read the output.** The lead invokes `/frontend-design` twice: once in Phase 1 Step 8 (enhancement guidelines) and once in Phase 3 Step 4 (design elevation brief). Teammates read the saved output -- they do NOT invoke the skill themselves.
18. **Teammates 1 and 2 run in parallel, Teammate 3 runs AFTER both complete.** Teammate 3 verifies changes from 1 and 2 -- it cannot run concurrently. The lead must wait for Teammates 1 and 2 to finish before spawning Teammate 3.
19. **ALL Playwright browser interactions require the dev server to be running.** If the dev server crashes during the stage, the lead must restart it. Teammates should message the lead -- do not attempt to start the server from a teammate session. Verify accessibility with a HEAD request before each teammate's work begins.
20. **Test user login is required for authenticated page screenshots.** Read `./e2e/constants.ts` for credentials. Use `browser_navigate` to the login page, `browser_fill_form` or `browser_type`/`browser_click` to authenticate. Verify login succeeded before proceeding with screenshots.
21. **ALWAYS check for console errors during screenshots.** After each `browser_take_screenshot`, use `browser_console_messages` to check for JavaScript errors. Log any errors in the report.
22. **Ensure NO two teammates modify the same file.** The lead MUST assign files to teammates in Phase 1 Step 9. If a file needs both Category O and Category E changes, assign all changes for that file to ONE teammate.
23. **ALWAYS include the Design System Summary in the polish plan** -- this is a required output.
