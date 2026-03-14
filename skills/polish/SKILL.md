---
name: polish
description: >-
  Applies visual polish and UI refinements to elevate aesthetic quality before deployment.
  This skill should be used when the user asks to "run visual polish",
  "polish the UI", "run Stage 6P", "fix visual defects", "enhance the UI",
  "improve the app aesthetics", "run UI refinement", "apply visual
  enhancements", or "fix contrast and layout issues", or when the
  transmute-pipeline agent reaches Stage 6P of the pipeline.
version: 1.0.0
---

# Stage 6P: Visual Polish & UI Refinement

Analyze the RUNNING application's visual quality, identify UI issues (visibility, layout, typography, spacing, motion, responsiveness), and automatically refine the frontend to production-grade aesthetic quality. Lead a multi-agent visual polish project using Claude Code Agent Teams.

Read the detailed guide at `${CLAUDE_SKILL_ROOT}/references/polish-detailed-guide.md` for full refinement categories, teammate prompts, design system integration, and report templates.

## Prerequisites

1. **`frontend-design` plugin** (recommended, has fallback): Check if `/mnt/skills/public/frontend-design/SKILL.md` exists. If not, use project's existing design patterns instead.

2. **Stage 6R must PASS or CONDITIONAL PASS** (if 6R was required):
   - If 6R report exists: check Gate Decision. FAIL -> STOP, return to 6R.
   - If 6R report does NOT exist: check 6V report:
     - 6V PASS -> proceed (6R correctly skipped)
     - 6V FAIL -> STOP: run 6R first
     - 6V CONDITIONAL PASS with only Category C -> proceed (6R correctly skipped)
     - 6V CONDITIONAL PASS with Category A/B -> STOP: run 6R first
   - If NEITHER report exists: verify with operator.

3. **Dev server**: This stage needs the live application. The lead starts it in Phase 1.

4. Create output directories:
   ```bash
   mkdir -p ./plancasting/_audits/visual-polish
   mkdir -p ./screenshots/visual-polish/before
   mkdir -p ./screenshots/visual-polish/after
   ```

## Input

- **6V/6R Screenshots**: `./screenshots/`
- **6V Report**: `./plancasting/_audits/visual-verification/report.md`
- **6R Report**: `./plancasting/_audits/runtime-remediation/report.md`
- **Design System**: Identified from `plancasting/tech-stack.md`
- **Codebase**: `./src/` (frontend components, styles, layouts)
- **PRD Screen Specs**: `./plancasting/prd/08-screen-specifications.md`
- **Tech Stack**: `./plancasting/tech-stack.md`
- **Project Rules**: `./CLAUDE.md`
- **E2E Constants**: `./e2e/constants.ts`

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports in that language. Code and file names remain in English.

## Stack Adaptation

Adapt to your `plancasting/tech-stack.md`: CSS framework, UI library, component directory, design token location, animation library. Replace `npm run` with your project's package manager per `CLAUDE.md`.

## Refinement Categories

### Category O: Objective Defects (Auto-Fix)
Issues with a clear right/wrong answer: WCAG contrast failures, invisible text, layout overflow, clipped content, skeleton mismatch, missing focus rings, z-index errors, dark mode unstyled sections, broken images, small touch targets. MUST fix all.

### Category E: Enhancement (Pattern-Based, Apply & Verify)
Follow established codebase patterns: missing hover states, missing page transitions, inconsistent spacing, weak empty states, flat typography hierarchy, missing card depth, plain loading states, inconsistent form inputs. Apply then verify visually.

### Category D: Design Elevation (Document Only)
Subjective improvements for human review: font pairing, color palette, hero visual impact, illustration style, micro-interaction opportunities, overall aesthetic direction. Document as suggestions -- do NOT apply.

## Phase 1: Lead Visual Audit

Complete BEFORE spawning teammates:

1. **Read project context**: `./CLAUDE.md`, `./plancasting/tech-stack.md`, `./plancasting/prd/08-screen-specifications.md`, 6V/6R reports

2. **Identify the design system**: Search in order -- design tokens file, tailwind config, global CSS, plancasting/tech-stack.md design direction, theme config, font imports, animation patterns. Output a Design System Summary.

3. **Establish validation baseline**: `bun run typecheck`, `bun run lint`, `bun run test`

4. **Start the application**: Check if running, start if needed. BaaS caveat: set client URL env var manually if BaaS dev server fails. ABORT if server fails to start.

5. **Screenshot key screens at 3 breakpoints** (1440, 768, 375):
   - Public pages first (no auth)
   - Authenticated pages (log in with test user from `./e2e/constants.ts`)
   - Dark mode (if supported)
   - Reuse 6V screenshots if available and recent

6. **AI Vision Analysis**: For each screenshot, check for Category O (objective), Category E (enhancement), and Category D (elevation) issues.

7. **Create Visual Polish Plan** at `./plancasting/_audits/visual-polish/plan.md` with design system summary, triage, and issue tables.

8. **Invoke `frontend-design` skill** (if available): Generate enhancement guidelines. Save to `./plancasting/_audits/visual-polish/design-guidelines.md`. If unavailable, teammates use project's existing design patterns.

9. **Assign teammates and prevent file conflicts**: Document file assignments in plan. NO two teammates may modify the same file.

## Phase 2: Spawn Teammates

Teammates 1 and 2 run in **parallel**. Teammate 3 runs **AFTER** both complete.

### Teammate 1: "objective-defect-fixer"
Fix ALL Category O issues. Use ONLY existing design tokens. Prefer adjusting text color over background for contrast. Include dark mode variants. NEVER change functional behavior. Verify visually with Playwright. Run typecheck + lint after each batch.

### Teammate 2: "enhancement-applier"
Apply ALL Category E enhancements following `design-guidelines.md` (or existing design patterns if unavailable). Group similar enhancements. Focus on HIGH-IMPACT moments for animation. Maximum 3 animations per page. Work within existing type scale. Verify with before/after screenshots.

### Teammate 3: "responsive-cross-theme-verifier" (after 1+2)
Re-verify ALL modified screens at 1440px, 768px, 375px plus dark mode. Flag regressions immediately (do NOT fix). Compare with before screenshots. Test mobile touch interactions. Verify performance not degraded.

## Phase 3: Integration & Report

1. Collect teammate results. Check for regressions from Teammate 3.
2. Fix regressions: revert specific change, re-apply with responsive-safe approach, re-verify.
3. Run full validation: `bun run typecheck`, `bun run lint`, `bun run test`. ALL must pass.
4. Generate Category D design brief using `frontend-design` skill (if available). Save as `./plancasting/_audits/visual-polish/design-elevation-brief.md`.
5. Generate Visual Polish Report at `./plancasting/_audits/visual-polish/report.md`.
6. Save comparison screenshots to `./screenshots/visual-polish/before/` and `./screenshots/visual-polish/after/`.

## Phase 4: Shutdown

1. Commit:
   ```bash
   git add src/ plancasting/_audits/visual-polish/
   git commit -m "style: Stage 6P visual polish -- [n] defects fixed, [n] enhancements applied"
   ```
2. Save commit hash:
   ```bash
   git rev-parse HEAD > ./plancasting/_audits/visual-polish/last-polished-commit.txt
   ```
3. Request shutdown for all teammates.
4. Stop dev server if started by this stage.

## Gate Decision

- **PASS**: All Category O fixed, Category E applied, no regressions -- ready for Deploy
- **CONDITIONAL PASS**: All critical fixed + Category D brief for optional elevation -- ready for Deploy
- **FAIL**: Regressions remain or validation fails -- investigate before Deploy

## Next Steps

- PASS or CONDITIONAL PASS: proceed to Stage 7 (Deploy) -> 7V (Production Smoke) -> 7D (User Guide)
- FAIL: investigate regressions, fix, revalidate. Do NOT deploy until 6P PASS or CONDITIONAL PASS.

## Critical Rules

1. NEVER change functional behavior -- only visual presentation.
2. NEVER replace design system components with custom implementations. Work within the UI library's API.
3. NEVER introduce new fonts without human approval (Category D).
4. NEVER introduce new dependencies without checking `package.json`.
5. ALWAYS take before/after screenshots for every change.
6. ALWAYS run validation (typecheck + lint + test) after fixes.
7. ALWAYS work at all 3 breakpoints (1440, 768, 375).
8. ALWAYS respect dark mode pattern -- every color change needs a dark mode variant.
9. Category O before Category E. Fix defects first, then enhance.
10. The `frontend-design` skill guides INTENT, not implementation. Translate aesthetic vision to design system tokens.
11. Maximum 3 animation additions per page. Restraint is elegance.
12. AVOID modifying shared UI primitives directly unless fixing Category O or applying global Category E.
13. If 6R report shows FAIL, STOP.
14. WCAG AA contrast ratios are non-negotiable (4.5:1 normal text, 3:1 large text).
15. ALWAYS preserve accessibility -- focus rings, aria labels, semantic HTML, keyboard nav.
16. Ensure NO two teammates modify the same file.
17. ALWAYS check for console errors during screenshots.
18. Test user login required for authenticated page screenshots.

## Output Specification

| Artifact | Path |
|----------|------|
| Visual Polish Plan | `./plancasting/_audits/visual-polish/plan.md` |
| Design Guidelines | `./plancasting/_audits/visual-polish/design-guidelines.md` |
| Design Elevation Brief | `./plancasting/_audits/visual-polish/design-elevation-brief.md` |
| Visual Polish Report | `./plancasting/_audits/visual-polish/report.md` |
| Last Polished Commit | `./plancasting/_audits/visual-polish/last-polished-commit.txt` |
| Before Screenshots | `./screenshots/visual-polish/before/` |
| After Screenshots | `./screenshots/visual-polish/after/` |
